/**
 * 用户状态管理
 */
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
    final ApiService _api = ApiService();
    
    User? _currentUser;
    bool _isLoading = false;
    String? _error;
    String? _password; // 注册后的密码

    User? get currentUser => _currentUser;
    bool get isLoading => _isLoading;
    String? get error => _error;
    String? get password => _password;
    bool get isLoggedIn => _currentUser != null;
    String? get token => _api.token;

    /// 自动登录（加载本地Token并获取用户信息）
    Future<bool> autoLogin() async {
        try {
            await _api.loadToken();
            if (_api.token == null) {
                return false;
            }
            
            _currentUser = await _api.getCurrentUser();
            notifyListeners();
            return true;
        } catch (e) {
            return false;
        }
    }

    /// 注册
    Future<bool> register() async {
        _isLoading = true;
        _error = null;
        notifyListeners();

        try {
            final data = await _api.register();
            _password = data['password'];
            _currentUser = User.fromJson(data['user']);
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
        _error = null;
        notifyListeners();

        try {
            final data = await _api.login(account, password);
            _currentUser = User.fromJson(data['user']);
            _password = null; // 登录不返回密码
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

    /// 登出
    Future<void> logout() async {
        await _api.clearToken();
        _currentUser = null;
        _password = null;
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
    }) async {
        try {
            _currentUser = await _api.updateProfile(
                nickname: nickname,
                avatar: avatar,
                signature: signature,
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
