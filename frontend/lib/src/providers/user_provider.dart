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
    String? _password; // 注册后的密码（展示一次后清除）
    String? _localAccount;
    String? _localPassword;

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

    /// 自动登录
    Future<bool> autoLogin() async {
        await _api.loadToken();
        await hasLocalAccount();
        
        // 有本地账号，用后端登录
        if (_localAccount != null && _localPassword != null) {
            try {
                final data = await _api.login(_localAccount!, _localPassword!);
                _currentUser = User.fromJson(data['user']);
                _password = null;
                notifyListeners();
                return true;
            } catch (e) {
                debugPrint('Auto login failed: $e');
            }
        }
        
        // 有token但没有本地账号，尝试用token获取用户信息
        if (_api.token != null) {
            try {
                _currentUser = await _api.getCurrentUser();
                notifyListeners();
                return true;
            } catch (e) {
                debugPrint('Token login failed: $e');
            }
        }
        
        return false;
    }

    /// 注册
    Future<bool> register({bool silent = false}) async {
        _isLoading = true;
        _error = null;
        notifyListeners();

        try {
            final data = await _api.register();
            _password = data['password'];
            _currentUser = User.fromJson(data['user']);
            _localAccount = _currentUser!.account;
            _localPassword = _password;
            await _saveLocalAccount();
            _isLoading = false;
            notifyListeners();
            return true;
        } catch (e) {
            _error = '注册失败: $e';
            _isLoading = false;
            notifyListeners();
            return false;
        }
    }

    /// 登录
    Future<bool> login(String account, String password) async {
        _isLoading = true;
        _error = null;
        notifyListeners();

        try {
            final data = await _api.login(account, password);
            _currentUser = User.fromJson(data['user']);
            _localAccount = account;
            _localPassword = password;
            _password = null;
            await _saveLocalAccount();
            _isLoading = false;
            notifyListeners();
            return true;
        } catch (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
            return false;
        }
    }

    /// 保存本地账号
    Future<void> _saveLocalAccount() async {
        final prefs = await SharedPreferences.getInstance();
        if (_localAccount != null) await prefs.setString('local_account', _localAccount!);
        if (_localPassword != null) await prefs.setString('local_password', _localPassword!);
        await prefs.setBool('is_registered', true);
        if (_currentUser != null) {
            await prefs.setString('local_user_data', jsonEncode(_currentUser!.toJson()));
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
            debugPrint('Refresh user failed: $e');
        }
    }

    /// 更新个人资料
    Future<bool> updateProfile({String? nickname, String? avatar, String? signature}) async {
        try {
            _currentUser = await _api.updateProfile(
                nickname: nickname, avatar: avatar, signature: signature,
            );
            notifyListeners();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 设置聊天定价
    Future<bool> updatePricing({double? textPrice, double? imagePrice, double? videoPrice}) async {
        try {
            await _api.updatePricing(textPrice: textPrice, imagePrice: imagePrice, videoPrice: videoPrice);
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
