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

    User? get currentUser => _currentUser;
    bool get isLoading => _isLoading;
    String? get error => _error;

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
