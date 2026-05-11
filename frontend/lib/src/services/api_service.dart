/**
 * API服务 - 封装所有HTTP请求
 */
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/gift.dart';
import '../models/message.dart';
import '../models/friend.dart';

class ApiService {
    static const String baseUrl = 'https://hiu-backend-production.up.railway.app/api';
    static const String baseHost = 'https://hiu-backend-production.up.railway.app';
    
    String? _token;
    String? _refreshToken;

    static final ApiService _instance = ApiService._internal();
    factory ApiService() => _instance;
    ApiService._internal();

    /// 检测后端是否可用（直接检测，不做本地缓存）
    static Future<bool> checkBackendAvailable() async {
        try {
            final uri = Uri.parse('$baseHost/health');
            final response = await http.get(uri).timeout(const Duration(seconds: 5));
            return response.statusCode == 200;
        } catch (_) {
            try {
                final uri = Uri.parse('$baseUrl/auth/health');
                final response = await http.get(uri).timeout(const Duration(seconds: 5));
                return response.statusCode == 200;
            } catch (_) {
                return false;
            }
        }
    }

    /// 生成随机账号ID
    static String generateAccountId() {
        final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
        return 'U$random';
    }

    /// 生成随机密码
    static String generatePassword() {
        const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        final random = DateTime.now().millisecondsSinceEpoch;
        return List.generate(8, (i) => chars[(random + i * 7) % chars.length]).join();
    }

    // 设置Token
    void setToken(String token, [String? refreshToken]) {
        _token = token;
        _refreshToken = refreshToken;
        _saveToken();
    }

    String? get token => _token;

    Future<void> _saveToken() async {
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) await prefs.setString('token', _token!);
        if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
    }

    Future<void> loadToken() async {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('token');
        _refreshToken = prefs.getString('refresh_token');
    }

    Future<void> clearToken() async {
        _token = null;
        _refreshToken = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('refresh_token');
    }

    Map<String, String> get _headers {
        final headers = <String, String>{'Content-Type': 'application/json'};
        if (_token != null) headers['Authorization'] = 'Bearer $_token';
        return headers;
    }

    // 通用请求方法 - 带自动刷新token
    Future<Map<String, dynamic>> _request(
        String method, String path, {
        Map<String, dynamic>? body,
        Map<String, String>? queryParams,
        bool isRetry = false,
    }) async {
        Uri uri = Uri.parse('$baseUrl$path');
        if (queryParams != null) uri = uri.replace(queryParameters: queryParams);

        http.Response response;
        final options = _headers;

        try {
            switch (method.toUpperCase()) {
                case 'GET':
                    response = await http.get(uri, headers: options);
                    break;
                case 'POST':
                    response = await http.post(uri, headers: options, body: body != null ? jsonEncode(body) : null);
                    break;
                case 'PUT':
                    response = await http.put(uri, headers: options, body: body != null ? jsonEncode(body) : null);
                    break;
                case 'DELETE':
                    response = await http.delete(uri, headers: options);
                    break;
                default:
                    throw Exception('Unsupported HTTP method');
            }

            // 如果token过期，自动刷新重试
            if (response.statusCode == 401 && !isRetry && _refreshToken != null) {
                try {
                    await refreshToken();
                    return _request(method, path, body: body, queryParams: queryParams, isRetry: true);
                } catch (_) {
                    // 刷新失败，继续抛出原始错误
                }
            }

            final data = jsonDecode(response.body);
            if (data['code'] == 0) return data;
            throw ApiException(data['message'] ?? 'Request failed');
        } catch (e) {
            if (e is ApiException) rethrow;
            throw ApiException('Network error: $e');
        }
    }

    // ============ 认证模块 ============

    Future<Map<String, dynamic>> register() async {
        final result = await _request('POST', '/auth/register');
        if (result['data'] != null) {
            setToken(result['data']['token'], result['data']['refreshToken']);
        }
        return result['data'];
    }

    Future<Map<String, dynamic>> login(String account, String password) async {
        final result = await _request('POST', '/auth/login', body: {
            'account': account,
            'password': password,
        });
        if (result['data'] != null) {
            setToken(result['data']['token'], result['data']['refreshToken']);
        }
        return result['data'];
    }

    Future<User> getCurrentUser() async {
        final result = await _request('GET', '/auth/me');
        return User.fromJson(result['data']);
    }

    Future<void> bindEmail(String email, String password) async {
        await _request('POST', '/auth/bind-email', body: {'email': email, 'password': password});
    }

    Future<void> refreshToken() async {
        if (_refreshToken == null) throw ApiException('No refresh token');
        final result = await _request('POST', '/auth/refresh', body: {'refreshToken': _refreshToken});
        if (result['data'] != null) {
            setToken(result['data']['token'], result['data']['refreshToken']);
        }
    }

    // ============ 用户模块 ============

    Future<User> getProfile() async {
        final result = await _request('GET', '/users/profile');
        return User.fromJson(result['data']);
    }

    Future<User> updateProfile({String? nickname, String? avatar, String? signature, String? gender}) async {
        final body = <String, dynamic>{};
        if (nickname != null) body['nickname'] = nickname;
        if (avatar != null) body['avatar'] = avatar;
        if (signature != null) body['signature'] = signature;
        if (gender != null) body['gender'] = gender;
        final result = await _request('PUT', '/users/profile', body: body);
        return User.fromJson(result['data']);
    }

    Future<void> updatePricing({double? textPrice, double? imagePrice, double? videoPrice}) async {
        final body = <String, dynamic>{};
        if (textPrice != null) body['text_price'] = textPrice;
        if (imagePrice != null) body['image_price'] = imagePrice;
        if (videoPrice != null) body['video_price'] = videoPrice;
        await _request('PUT', '/users/pricing', body: body);
    }

    Future<User> getUserInfo(String oderId) async {
        final result = await _request('GET', '/users/$oderId');
        return User.fromJson(result['data']);
    }

    /// 上传头像
    Future<String?> uploadAvatar(File imageFile) async {
        try {
            final uri = Uri.parse('$baseUrl/upload/avatar');
            final request = http.MultipartRequest('POST', uri);
            if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
            final ext = imageFile.path.split('.').last.toLowerCase();
            final mimeType = ext == 'png' ? 'image/png' : ext == 'gif' ? 'image/gif' : 'image/jpeg';
            request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path, contentType: MediaType.parse(mimeType)));
            final streamedResponse = await request.send();
            final response = await http.Response.fromStream(streamedResponse);
            final data = jsonDecode(response.body);
            if (data['code'] == 0 && data['data'] != null) {
                final url = data['data']['url'];
                if (url.startsWith('http')) return url;
                return '$baseHost$url';
            }
            return null;
        } catch (e) {
            debugPrint('Upload avatar error: $e');
            return null;
        }
    }

    // ============ 房间模块 ============

    Future<List<Room>> getRooms({int page = 1, int limit = 20, String? keyword, String sort = 'created'}) async {
        final params = <String, String>{'page': page.toString(), 'limit': limit.toString(), 'sort': sort};
        if (keyword != null) params['keyword'] = keyword;
        final result = await _request('GET', '/rooms', queryParams: params);
        final list = result['data']['list'] as List;
        return list.map((e) => Room.fromJson(e)).toList();
    }

    Future<Room> getRoomDetail(String roomId) async {
        final result = await _request('GET', '/rooms/$roomId');
        return Room.fromJson(result['data']);
    }

    Future<Room> createRoom({required String name, String? cover, String? description, bool isPublic = true, String? password, String? tags}) async {
        final result = await _request('POST', '/rooms', body: {
            'name': name, 'cover': cover ?? '', 'description': description ?? '',
            'is_public': isPublic, 'password': password ?? '', 'tags': tags ?? '',
        });
        return Room.fromJson(result['data']);
    }

    Future<Map<String, dynamic>> joinRoom(String roomId, {String? password}) async {
        final body = <String, dynamic>{};
        if (password != null) body['password'] = password;
        final result = await _request('POST', '/rooms/$roomId/join', body: body);
        return result['data'];
    }

    Future<void> leaveRoom(String roomId) async => await _request('POST', '/rooms/$roomId/leave');
    Future<void> joinSeat(String roomId, int seatIndex) async => await _request('POST', '/rooms/$roomId/seat/$seatIndex/join');
    Future<void> leaveSeat(String roomId, int seatIndex) async => await _request('POST', '/rooms/$roomId/seat/$seatIndex/leave');
    Future<void> kickSeat(String roomId, int seatIndex) async => await _request('POST', '/rooms/$roomId/seat/$seatIndex/kick');

    Future<void> muteSeat(String roomId, int seatIndex, bool isMuted) async {
        await _request('PUT', '/rooms/$roomId/seat/$seatIndex/mute', body: {'is_muted': isMuted});
    }

    Future<void> lockSeat(String roomId, int seatIndex, bool isLocked) async {
        await _request('PUT', '/rooms/$roomId/seat/$seatIndex/lock', body: {'is_locked': isLocked});
    }

    Future<void> closeRoom(String roomId) async => await _request('DELETE', '/rooms/$roomId');

    /// 转移房主
    Future<void> transferRoomOwner(String roomId, String newOwnerId) async =>
        await _request(POST, /rooms//transfer-owner, body: {new_owner_id: newOwnerId});

    // ============ 礼物模块 ============

    Future<List<Gift>> getGifts() async {
        final result = await _request('GET', '/gifts');
        final list = result['data'] as List;
        return list.map((e) => Gift.fromJson(e)).toList();
    }

    Future<Map<String, dynamic>> sendGift({required String giftId, required String receiverId, String? roomId, int count = 1}) async {
        final result = await _request('POST', '/gifts/$giftId/send', body: {
            'receiver_id': receiverId, 'room_id': roomId, 'count': count,
        });
        return result['data'];
    }

    Future<List<GiftRecord>> getGiftRecords({int page = 1, int limit = 20, String? type}) async {
        final params = <String, String>{'page': page.toString(), 'limit': limit.toString()};
        if (type != null) params['type'] = type;
        final result = await _request('GET', '/gifts/records', queryParams: params);
        final list = result['data']['list'] as List;
        return list.map((e) => GiftRecord.fromJson(e)).toList();
    }

    // ============ 金币模块 ============

    Future<double> getCoinBalance() async {
        final result = await _request('GET', '/coins/balance');
        return double.tryParse(result['data']['coin_balance']?.toString() ?? '0') ?? 0;
    }

    Future<void> distributeCoins({required String account, required double amount, required String distributePassword}) async {
        await _request('POST', '/coins/distribute', body: {'account': account, 'amount': amount, 'distribute_password': distributePassword});
    }

    // ============ 钻石模块 ============

    Future<double> getDiamondBalance() async {
        final result = await _request('GET', '/diamonds/balance');
        return double.tryParse(result['data']['diamond_balance']?.toString() ?? '0') ?? 0;
    }

    Future<void> withdraw({required double amount, required String paymentAddress, String paymentMethod = 'usdt'}) async {
        await _request('POST', '/diamonds/withdraw', body: {'amount': amount, 'payment_address': paymentAddress, 'payment_method': paymentMethod});
    }

    Future<int> getWithdrawRate() async {
        final result = await _request('GET', '/diamonds/withdraw/rate');
        return int.tryParse(result['data']['exchange_rate']?.toString() ?? '10000') ?? 10000;
    }

    // ============ 1对1聊天模块 ============

    Future<List<Conversation>> getConversations() async {
        final result = await _request('GET', '/chat/conversations');
        final list = result['data']['list'] as List;
        return list.map((e) => Conversation.fromJson(e)).toList();
    }

    Future<List<PrivateMessage>> getMessages(String oderId, {int page = 1, int limit = 50}) async {
        final result = await _request('GET', '/chat/messages/$oderId', queryParams: {'page': page.toString(), 'limit': limit.toString()});
        final list = result['data']['list'] as List;
        return list.map((e) => PrivateMessage.fromJson(e)).toList();
    }

    Future<Map<String, dynamic>> sendMessage({required String receiverId, required String type, required String content}) async {
        final result = await _request('POST', '/chat/send', body: {'receiver_id': receiverId, 'type': type, 'content': content});
        return result['data'];
    }

    Future<int> getUnreadCount() async {
        final result = await _request('GET', '/chat/unread');
        return result['data']['unread_count'] ?? 0;
    }

    // ============ 视频通话模块 ============

    Future<Map<String, dynamic>> startVideoCall(String receiverId) async {
        final result = await _request('POST', '/video/call', body: {'receiver_id': receiverId});
        return result['data'];
    }

    Future<void> acceptVideoCall(String callId) async => await _request('PUT', '/video/call/$callId/accept');
    Future<void> rejectVideoCall(String callId) async => await _request('PUT', '/video/call/$callId/reject');

    // ============ 好友模块 ============

    Future<List<Friend>> getFriends() async {
        final result = await _request('GET', '/friends');
        final list = result['data'] as List;
        return list.map((e) => Friend.fromJson(e)).toList();
    }

    Future<List<Friend>> getPendingFriendRequests() async {
        final result = await _request('GET', '/friends', queryParams: {'status': 'pending'});
        final list = result['data'] as List;
        return list.map((e) => Friend.fromJson(e)).toList();
    }

    Future<List<Friend>> getSentFriendRequests() async {
        final result = await _request('GET', '/friends/sent');
        final list = result['data'] as List;
        return list.map((e) => Friend.fromJson(e)).toList();
    }

    Future<void> sendFriendRequest(String userId) async {
        await _request('POST', '/friends/request', body: {'user_id': userId});
    }

    Future<void> acceptFriendRequest(String requestId) async {
        await _request('POST', '/friends/accept/$requestId');
    }

    Future<void> rejectFriendRequest(String requestId) async {
        await _request('POST', '/friends/reject/$requestId');
    }

    Future<void> blockUser(String userId) async {
        await _request('POST', '/friends/block/$userId');
    }

    Future<void> unblockUser(String userId) async {
        await _request('POST', '/friends/unblock/$userId');
    }

    Future<void> deleteFriend(String friendId) async {
        await _request('DELETE', '/friends/$friendId');
    }

    Future<List<Friend>> getBlockedUsers() async {
        final result = await _request('GET', '/friends/blocked');
        final list = result['data'] as List;
        return list.map((e) => Friend.fromJson(e)).toList();
    }

    Future<User> searchUserByAccount(String account) async {
        final result = await _request('GET', '/users/search', queryParams: {'account': account});
        final data = result['data'];
        // 后端返回列表，取第一个
        if (data is List && data.isNotEmpty) {
            return User.fromJson(data[0]);
        } else if (data is Map) {
            return User.fromJson(data);
        }
        throw ApiException('用户不存在');
    }

    Future<List<User>> searchUsers(String keyword) async {
        final result = await _request('GET', '/users/search', queryParams: {'keyword': keyword});
        final data = result['data'];
        if (data is List) {
            return data.map((e) => User.fromJson(e)).toList();
        }
        return [];
    }
}

class ApiException implements Exception {
    final String message;
    ApiException(this.message);
    @override
    String toString() => message;
}
