/**
 * 好友状态管理
 */
import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../services/api_service.dart';

class FriendProvider extends ChangeNotifier {
    final ApiService _api = ApiService();
    
    List<Friend> _friends = [];
    List<Friend> _pendingRequests = [];
    List<Friend> _sentRequests = [];
    List<Friend> _blockedUsers = [];
    bool _isLoading = false;
    String? _error;

    List<Friend> get friends => _friends;
    List<Friend> get pendingRequests => _pendingRequests;
    List<Friend> get sentRequests => _sentRequests;
    List<Friend> get blockedUsers => _blockedUsers;
    bool get isLoading => _isLoading;
    String? get error => _error;

    /// 加载好友列表
    Future<void> loadFriends() async {
        _isLoading = true;
        notifyListeners();

        try {
            final result = await _api.getFriends();
            _friends = result;
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 加载待处理的好友申请
    Future<void> loadPendingRequests() async {
        _isLoading = true;
        notifyListeners();

        try {
            final result = await _api.getPendingFriendRequests();
            _pendingRequests = result;
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 加载我发起的申请
    Future<void> loadSentRequests() async {
        try {
            final result = await _api.getSentFriendRequests();
            _sentRequests = result;
            notifyListeners();
        } catch (e) {
            _error = e.toString();
        }
    }

    /// 加载黑名单
    Future<void> loadBlockedUsers() async {
        _isLoading = true;
        notifyListeners();

        try {
            final result = await _api.getBlockedUsers();
            _blockedUsers = result;
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 发送好友申请
    Future<bool> sendFriendRequest(String odId) async {
        try {
            await _api.sendFriendRequest(odId);
            await loadSentRequests();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 接受好友申请
    Future<bool> acceptRequest(String requestId) async {
        try {
            await _api.acceptFriendRequest(requestId);
            await loadPendingRequests();
            await loadFriends();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 拒绝好友申请
    Future<bool> rejectRequest(String requestId) async {
        try {
            await _api.rejectFriendRequest(requestId);
            await loadPendingRequests();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 拉黑用户
    Future<bool> blockUser(String odId) async {
        try {
            await _api.blockUser(odId);
            await loadFriends();
            await loadBlockedUsers();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 解除拉黑
    Future<bool> unblockUser(String odId) async {
        try {
            await _api.unblockUser(odId);
            await loadBlockedUsers();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 删除好友
    Future<bool> deleteFriend(String friendId) async {
        try {
            await _api.deleteFriend(friendId);
            await loadFriends();
            return true;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return false;
        }
    }

    /// 清除状态
    void clear() {
        _friends = [];
        _pendingRequests = [];
        _sentRequests = [];
        _blockedUsers = [];
        _error = null;
        notifyListeners();
    }
}
