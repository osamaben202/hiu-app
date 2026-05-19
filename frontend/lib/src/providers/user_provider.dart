/**
 * 用户状态管理
 */
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
    final ApiService _api = ApiService();
    
    User? _currentUser;
    bool _isLoading = false;
    String? _error;

    User? get currentUser => _currentUser;
    bool get isLoading => _isLoading;
    String? get error => _error;

    String? _localAccount;
    String? _password;

    String? get localAccount => _localAccount;
    String? get password => _password;

    /// 检查是否有本地账号
    Future<void> hasLocalAccount() async {
        try {
            final prefs = await SharedPreferences.getInstance();
            _localAccount = prefs.getString('local_account');
        } catch (e) {
            _localAccount = null;
        }
    }

    /// 检查是否已注册（本地是否有保存的账号）
    Future<bool> isRegistered() async {
        try {
            final prefs = await SharedPreferences.getInstance();
            _localAccount = prefs.getString('local_account');
            _password = prefs.getString('local_password');
            final token = prefs.getString('token');
            return _localAccount != null && token != null;
        } catch (e) {
            return false;
        }
    }

    /// 注册（silent=true时自动生成账号密码）
    Future<bool> register({bool silent = false}) async {
        _isLoading = true;
        notifyListeners();

        try {
            final data = await _api.register();
            if (data != null) {
                // 保存账号信息到本地
                final prefs = await SharedPreferences.getInstance();
                final account = data['user']?['account'] ?? data['account'] ?? '';
                final pwd = data['password'] ?? '';
                
                if (account.isNotEmpty) {
                    await prefs.setString('local_account', account);
                    _localAccount = account;
                }
                if (pwd.isNotEmpty) {
                    await prefs.setString('local_password', pwd);
                    _password = pwd;
                }

                _currentUser = User.fromJson(data['user'] ?? data);
                _error = null;
                notifyListeners();
                return true;
            }
            return false;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 自动登录（使用本地保存的token）
    Future<bool> autoLogin() async {
        try {
            final prefs = await SharedPreferences.getInstance();
            _localAccount = prefs.getString('local_account');
            _password = prefs.getString('local_password');
            
            // 确保token被加载到ApiService中
            await _api.loadToken();
            final token = _api.token;
            if (token != null) SocketService().init(token);
            
            // 尝试用 token 获取用户信息
            _currentUser = await _api.getCurrentUser();
            if (_currentUser != null) {
                notifyListeners();
                return true;
            }
            return false;
        } catch (e) {
            // token 可能过期，尝试用账号密码重新登录
            try {
                if (_localAccount != null && _password != null) {
                    return await login(_localAccount!, _password!);
                }
            } catch (e2) {
                // ignore
            }
            return false;
        }
    }

    /// 加载当前用户
    Future<void> loadCurrentUser() async {
        _isLoading = true;
        notifyListeners();

        try {
            _currentUser = await _api.getCurrentUser();
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 加载用户资料
    Future<void> loadProfile() async {
        _isLoading = true;
        notifyListeners();

        try {
            _currentUser = await _api.getProfile();
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 更新个人资料
    Future<bool> updateProfile({
        String? nickname,
        String? avatar,
        String? signature,
        String? gender,
    }) async {
        _isLoading = true;
        notifyListeners();

        try {
            final user = await _api.updateProfile(
                nickname: nickname,
                avatar: avatar,
                signature: signature,
                gender: gender,
            );
            _currentUser = user;
            _error = null;
            notifyListeners();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 登录
    Future<bool> login(String account, String password) async {
        _isLoading = true;
        notifyListeners();

        try {
            final data = await _api.login(account, password);
            if (data != null) {
                _currentUser = User.fromJson(data['user'] ?? data);
                _error = null;
                notifyListeners();
                return true;
            }
            return false;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 刷新用户信息
    Future<void> refreshUser() async {
        await loadProfile();
    }

    /// 绑定邮箱
    Future<bool> bindEmail(String email, String password) async {
        try {
            await _api.bindEmail(email, password);
            return true;
        } catch (e) {
            _error = e.toString();
            return false;
        }
    }

    /// 获取金币余额
    Future<double> getCoinBalance() async {
        try {
            return await _api.getCoinBalance();
        } catch (e) {
            return 0;
        }
    }

    /// 获取钻石余额
    Future<double> getDiamondBalance() async {
        try {
            return await _api.getDiamondBalance();
        } catch (e) {
            return 0;
        }
    }

    /// 更新定价
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
            return true;
        } catch (e) {
            _error = e.toString();
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

    /// 登出
    Future<void> logout() async {
        await _api.clearToken();
        _currentUser = null;
        notifyListeners();
    }

    /// 清除状态
    void clear() {
        _currentUser = null;
        _error = null;
        notifyListeners();
    }
}
