/**
 * 用户状态管理
 */
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
    final ApiService _api = ApiService();
    
    User? _currentUser;
    bool _isLoading = false;
    String? _error;
    String? _password; // 注册后的密码
    String? _localAccount; // 本地账号
    String? _localPassword; // 本地密码

    User? get currentUser => _currentUser;
    bool get isLoading => _isLoading;
    String? get error => _error;
    String? get password => _password;
    bool get isLoggedIn => _currentUser != null;
    String? get token => _api.token;
    String? get localAccount => _localAccount;
    String? get localPassword => _localPassword;

    /// 检查是否已注册
    Future<bool> isRegistered() async {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool('is_registered') ?? false;
    }

    /// 检查是否有本地账号数据
    Future<bool> hasLocalAccount() async {
        final prefs = await SharedPreferences.getInstance();
        _localAccount = prefs.getString('local_account');
        _localPassword = prefs.getString('local_password');
        return _localAccount != null && _localPassword != null;
    }

    /// 自动登录（加载本地Token并获取用户信息）
    Future<bool> autoLogin() async {
        // 先检查是否有本地账号
        await hasLocalAccount();
        
        // 如果没有本地账号，尝试后端注册
        if (_localAccount == null) {
            // 检测后端是否可用
            final backendAvailable = await ApiService.checkBackendAvailable();
            if (backendAvailable) {
                try {
                    final data = await _api.register();
                    _password = data['password'];
                    _currentUser = User.fromJson(data['user']);
                    _localAccount = _currentUser!.account;
                    _localPassword = _password;
                    await _saveLocalAccount();
                    notifyListeners();
                    return true;
                } catch (e) {
                    // 后端注册失败，使用本地账号
                }
            }
            return false;
        }
        
        // 有本地账号，尝试后端登录
        final backendAvailable = await ApiService.checkBackendAvailable();
        if (backendAvailable) {
            try {
                final data = await _api.login(_localAccount!, _localPassword!);
                _currentUser = User.fromJson(data['user']);
                _password = null;
                notifyListeners();
                return true;
            } catch (e) {
                // 后端登录失败，使用本地账号
            }
        }
        
        // 使用本地数据登录
        await _loadLocalUserData();
        return _currentUser != null;
    }

    /// 注册（支持本地和后端）
    Future<bool> register({bool silent = false}) async {
        _isLoading = true;
        _error = null;
        notifyListeners();

        try {
            // 先检测后端是否可用
            final backendAvailable = await ApiService.checkBackendAvailable();
            
            if (backendAvailable) {
                try {
                    // 尝试后端注册
                    final data = await _api.register();
                    _password = data['password'];
                    _currentUser = User.fromJson(data['user']);
                    _localAccount = _currentUser!.account;
                    _localPassword = _password;
                    await _saveLocalAccount();
                    notifyListeners();
                    _isLoading = false;
                    notifyListeners();
                    return true;
                } catch (e) {
                    // 后端注册失败，继续使用本地注册
                    debugPrint('后端注册失败，使用本地注册: $e');
                }
            }
            
            // 本地注册
            return await _localRegister(silent: silent);
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 本地注册
    Future<bool> _localRegister({bool silent = false}) async {
        // 生成账号密码
        _localAccount = ApiService.generateAccountId();
        _localPassword = ApiService.generatePassword();
        
        // 创建本地用户
        _currentUser = User(
            id: _localAccount!,
            account: _localAccount!,
            nickname: _localAccount!,
            gender: 'unknown',
            role: 'user',
            coinBalance: 0,
            diamondBalance: 0,
        );
        _password = _localPassword;
        
        // 保存本地账号
        await _saveLocalAccount();
        
        // 尝试同步到后端
        if (await ApiService.checkBackendAvailable()) {
            try {
                await _api.register();
                // 同步成功
            } catch (e) {
                // 同步失败，继续使用本地账号
            }
        }
        
        notifyListeners();
        return true;
    }

    /// 登录
    Future<bool> login(String account, String password) async {
        _isLoading = true;
        _error = null;
        notifyListeners();

        try {
            // 先检测后端是否可用
            final backendAvailable = await ApiService.checkBackendAvailable();
            
            if (backendAvailable) {
                try {
                    // 尝试后端登录
                    final data = await _api.login(account, password);
                    _currentUser = User.fromJson(data['user']);
                    _password = null;
                    
                    // 保存为本地账号
                    _localAccount = account;
                    _localPassword = password;
                    await _saveLocalAccount();
                    
                    notifyListeners();
                    _isLoading = false;
                    notifyListeners();
                    return true;
                } catch (e) {
                    // 后端登录失败
                    debugPrint('后端登录失败: $e');
                }
            }
            
            // 后端不可用，尝试本地登录
            return await _localLogin(account, password);
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 本地登录
    Future<bool> _localLogin(String account, String password) async {
        // 加载本地用户数据
        await hasLocalAccount();
        
        if (_localAccount == account && _localPassword == password) {
            await _loadLocalUserData();
            notifyListeners();
            return _currentUser != null;
        }
        
        _error = '账号或密码错误';
        notifyListeners();
        return false;
    }

    /// 保存本地账号到 SharedPreferences
    Future<void> _saveLocalAccount() async {
        final prefs = await SharedPreferences.getInstance();
        if (_localAccount != null) {
            await prefs.setString('local_account', _localAccount!);
        }
        if (_localPassword != null) {
            await prefs.setString('local_password', _localPassword!);
        }
        await prefs.setBool('is_registered', true);
        
        // 保存用户数据
        if (_currentUser != null) {
            await prefs.setString('local_user_data', jsonEncode(_currentUser!.toJson()));
        }
    }

    /// 加载本地用户数据
    Future<void> _loadLocalUserData() async {
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('local_user_data');
        if (userDataStr != null) {
            try {
                final userData = jsonDecode(userDataStr);
                _currentUser = User.fromJson(userData);
            } catch (e) {
                // 数据损坏，使用默认数据
                _currentUser = User(
                    id: _localAccount ?? '',
                    account: _localAccount ?? '',
                    nickname: _localAccount ?? '',
                );
            }
        } else {
            _currentUser = User(
                id: _localAccount ?? '',
                account: _localAccount ?? '',
                nickname: _localAccount ?? '',
            );
        }
    }

    /// 登出
    Future<void> logout() async {
        await _api.clearToken();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('local_account');
        await prefs.remove('local_password');
        await prefs.remove('local_user_data');
        await prefs.setBool('is_registered', false);
        _currentUser = null;
        _password = null;
        _localAccount = null;
        _localPassword = null;
        notifyListeners();
    }

    /// 刷新用户信息
    Future<void> refreshUser() async {
        try {
            _currentUser = await _api.getCurrentUser();
            notifyListeners();
        } catch (e) {
            // 忽略错误
        }
    }

    /// 更新个人资料
    Future<bool> updateProfile({
        String? nickname,
        String? avatar,
        String? signature,
        String? gender,
    }) async {
        try {
            _currentUser = await _api.updateProfile(
                nickname: nickname,
                avatar: avatar,
                signature: signature,
                gender: gender,
            );
            notifyListeners();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 绑定邮箱
    Future<bool> bindEmail(String email, String password) async {
        try {
            await _api.bindEmail(email, password);
            await refreshUser();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 设置聊天定价
    Future<bool> updatePricing({
        double? textPrice,
        double? imagePrice,
        double? videoPrice,
    }) async {
        try {
            await _api.updatePricing(
                textPrice: textPrice,
                imagePrice: imagePrice,
                videoPrice: videoPrice,
            );
            await refreshUser();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 更新金币余额
    void updateCoinBalance(double newBalance) {
        if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(coinBalance: newBalance);
            notifyListeners();
        }
    }

    /// 更新钻石余额
    void updateDiamondBalance(double newBalance) {
        if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(diamondBalance: newBalance);
            notifyListeners();
        }
    }

    /// 清除密码（显示后清除）
    void clearPassword() {
        _password = null;
        notifyListeners();
    }
}
