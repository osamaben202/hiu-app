/**
 * API服务 - 封装所有HTTP请求
 */
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../models/gift.dart';
import '../models/message.dart';

class ApiService {
    // 基础URL，生产环境需要修改
    static const String baseUrl = 'http://localhost:3000/api';
    
    String? _token;
    String? _refreshToken;
    static bool _backendAvailable = true;

    static final ApiService _instance = ApiService._internal();
    factory ApiService() => _instance;
    ApiService._internal();

    /// 检测后端是否可用
    static Future<bool> checkBackendAvailable() async {
        try {
            final uri = Uri.parse('$baseUrl/health');
            final response = await http.get(uri).timeout(
                const Duration(seconds: 3),
            );
            _backendAvailable = response.statusCode == 200;
        } catch (e) {
            _backendAvailable = false;
        }
        return _backendAvailable;
    }

    /// 后端是否可用
    static bool get backendAvailable => _backendAvailable;

    /// 生成随机账号ID
    static String generateAccountId() {
        final random = Random();
        final number = random.nextInt(900000) + 100000;
        return 'U$number';
    }

    /// 生成随机密码
    static String generatePassword() {
        const chars = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
        final random = Random();
        return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
    }

    // 设置Token
    void setToken(String token, [String? refreshToken]) {
        _token = token;
        _refreshToken = refreshToken;
        _saveToken();
    }

    // 获取Token
    String? get token => _token;

    // 保存Token到本地
    Future<void> _saveToken() async {
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
            await prefs.setString('token', _token!);
        }
        if (_refreshToken != null) {
            await prefs.setString('refresh_token', _refreshToken!);
        }
    }

    // 从本地加载Token
    Future<void> loadToken() async {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString('token');
        _refreshToken = prefs.getString('refresh_token');
    }

    // 清除Token
    Future<void> clearToken() async {
        _token = null;
        _refreshToken = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('refresh_token');
    }

    // HTTP请求头
    Map<String, String> get _headers {
        final headers = <String, String>{
            'Content-Type': 'application/json',
        };
        if (_token != null) {
            headers['Authorization'] = 'Bearer $_token';
        }
        return headers;
    }

    // 通用请求方法
    Future<Map<String, dynamic>> _request(
        String method,
        String path, {
        Map<String, dynamic>? body,
        Map<String, String>? queryParams,
    }) async {
        Uri uri = Uri.parse('$baseUrl$path');
        if (queryParams != null) {
            uri = uri.replace(queryParameters: queryParams);
        }

        http.Response response;
        final options = _headers;

        try {
            switch (method.toUpperCase()) {
                case 'GET':
                    response = await http.get(uri, headers: options);
                    break;
                case 'POST':
                    response = await http.post(
                        uri,
                        headers: options,
                        body: body != null ? jsonEncode(body) : null,
                    );
                    break;
                case 'PUT':
                    response = await http.put(
                        uri,
                        headers: options,
                        body: body != null ? jsonEncode(body) : null,
                    );
                    break;
                case 'DELETE':
                    response = await http.delete(uri, headers: options);
                    break;
                default:
                    throw Exception('Unsupported HTTP method');
            }

            final data = jsonDecode(response.body);
            
            if (data['code'] == 0) {
                return data;
            } else {
                throw ApiException(data['message'] ?? 'Request failed');
            }
        } catch (e) {
            if (e is ApiException) rethrow;
            throw ApiException('Network error: $e');
        }
    }

    // ============ 认证模块 ============

    /// 自动注册
    Future<Map<String, dynamic>> register() async {
        final result = await _request('POST', '/auth/register');
        if (result['data'] != null) {
            setToken(result['data']['token'], result['data']['refreshToken']);
        }
        return result['data'];
    }

    /// 登录
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

    /// 获取当前用户
    Future<User> getCurrentUser() async {
        final result = await _request('GET', '/auth/me');
        return User.fromJson(result['data']);
    }

    /// 绑定邮箱
    Future<void> bindEmail(String email, String password) async {
        await _request('POST', '/auth/bind-email', body: {
            'email': email,
            'password': password,
        });
    }

    /// 刷新Token
    Future<void> refreshToken() async {
        if (_refreshToken == null) {
            throw ApiException('No refresh token');
        }
        final result = await _request('POST', '/auth/refresh', body: {
            'refreshToken': _refreshToken,
        });
        if (result['data'] != null) {
            setToken(result['data']['token'], result['data']['refreshToken']);
        }
    }

    // ============ 用户模块 ============

    /// 获取个人资料
    Future<User> getProfile() async {
        final result = await _request('GET', '/users/profile');
        return User.fromJson(result['data']);
    }

    /// 更新个人资料
    Future<User> updateProfile({
        String? nickname,
        String? avatar,
        String? signature,
    }) async {
        final body = <String, dynamic>{};
        if (nickname != null) body['nickname'] = nickname;
        if (avatar != null) body['avatar'] = avatar;
        if (signature != null) body['signature'] = signature;
        
        final result = await _request('PUT', '/users/profile', body: body);
        return User.fromJson(result['data']);
    }

    /// 设置聊天定价
    Future<void> updatePricing({
        double? textPrice,
        double? imagePrice,
        double? videoPrice,
    }) async {
        final body = <String, dynamic>{};
        if (textPrice != null) body['text_price'] = textPrice;
        if (imagePrice != null) body['image_price'] = imagePrice;
        if (videoPrice != null) body['video_price'] = videoPrice;
        
        await _request('PUT', '/users/pricing', body: body);
    }

    /// 获取其他用户信息
    Future<User> getUserInfo(String oderId) async {
        final result = await _request('GET', '/users/$oderId');
        return User.fromJson(result['data']);
    }

    // ============ 房间模块 ============

    /// 获取房间列表
    Future<List<Room>> getRooms({
        int page = 1,
        int limit = 20,
        String? keyword,
        String sort = 'created',
    }) async {
        final params = <String, String>{
            'page': page.toString(),
            'limit': limit.toString(),
            'sort': sort,
        };
        if (keyword != null) params['keyword'] = keyword;
        
        final result = await _request('GET', '/rooms', queryParams: params);
        final list = result['data']['list'] as List;
        return list.map((e) => Room.fromJson(e)).toList();
    }

    /// 获取房间详情
    Future<Room> getRoomDetail(String roomId) async {
        final result = await _request('GET', '/rooms/$roomId');
        return Room.fromJson(result['data']);
    }

    /// 创建房间
    Future<Room> createRoom({
        required String name,
        String? cover,
        String? description,
        bool isPublic = true,
        String? password,
        String? tags,
    }) async {
        final result = await _request('POST', '/rooms', body: {
            'name': name,
            'cover': cover ?? '',
            'description': description ?? '',
            'is_public': isPublic,
            'password': password ?? '',
            'tags': tags ?? '',
        });
        return Room.fromJson(result['data']);
    }

    /// 加入房间
    Future<Map<String, dynamic>> joinRoom(String roomId, {String? password}) async {
        final body = <String, dynamic>{};
        if (password != null) body['password'] = password;
        
        final result = await _request('POST', '/rooms/$roomId/join', body: body);
        return result['data'];
    }

    /// 离开房间
    Future<void> leaveRoom(String roomId) async {
        await _request('POST', '/rooms/$roomId/leave');
    }

    /// 上麦
    Future<void> joinSeat(String roomId, int seatIndex) async {
        await _request('POST', '/rooms/$roomId/seat/$seatIndex/join');
    }

    /// 下麦
    Future<void> leaveSeat(String roomId, int seatIndex) async {
        await _request('POST', '/rooms/$roomId/seat/$seatIndex/leave');
    }

    /// 踢人下麦
    Future<void> kickSeat(String roomId, int seatIndex) async {
        await _request('POST', '/rooms/$roomId/seat/$seatIndex/kick');
    }

    /// 闭麦/开麦
    Future<void> muteSeat(String roomId, int seatIndex, bool isMuted) async {
        await _request('PUT', '/rooms/$roomId/seat/$seatIndex/mute', body: {
            'is_muted': isMuted,
        });
    }

    /// 锁定/解锁麦位
    Future<void> lockSeat(String roomId, int seatIndex, bool isLocked) async {
        await _request('PUT', '/rooms/$roomId/seat/$seatIndex/lock', body: {
            'is_locked': isLocked,
        });
    }

    /// 关闭房间
    Future<void> closeRoom(String roomId) async {
        await _request('DELETE', '/rooms/$roomId');
    }

    // ============ 礼物模块 ============

    /// 获取礼物列表
    Future<List<Gift>> getGifts() async {
        final result = await _request('GET', '/gifts');
        final list = result['data'] as List;
        return list.map((e) => Gift.fromJson(e)).toList();
    }

    /// 发送礼物
    Future<Map<String, dynamic>> sendGift({
        required String giftId,
        required String receiverId,
        String? roomId,
        int count = 1,
    }) async {
        final result = await _request('POST', '/gifts/$giftId/send', body: {
            'receiver_id': receiverId,
            'room_id': roomId,
            'count': count,
        });
        return result['data'];
    }

    /// 获取礼物记录
    Future<List<GiftRecord>> getGiftRecords({
        int page = 1,
        int limit = 20,
        String? type,
    }) async {
        final params = <String, String>{
            'page': page.toString(),
            'limit': limit.toString(),
        };
        if (type != null) params['type'] = type;
        
        final result = await _request('GET', '/gifts/records', queryParams: params);
        final list = result['data']['list'] as List;
        return list.map((e) => GiftRecord.fromJson(e)).toList();
    }

    // ============ 金币模块 ============

    /// 获取金币余额
    Future<double> getCoinBalance() async {
        final result = await _request('GET', '/coins/balance');
        return double.tryParse(result['data']['coin_balance']?.toString() ?? '0') ?? 0;
    }

    /// 代理分发金币
    Future<void> distributeCoins({
        required String account,
        required double amount,
        required String distributePassword,
    }) async {
        await _request('POST', '/coins/distribute', body: {
            'account': account,
            'amount': amount,
            'distribute_password': distributePassword,
        });
    }

    // ============ 钻石模块 ============

    /// 获取钻石余额
    Future<double> getDiamondBalance() async {
        final result = await _request('GET', '/diamonds/balance');
        return double.tryParse(result['data']['diamond_balance']?.toString() ?? '0') ?? 0;
    }

    /// 申请提现
    Future<void> withdraw({
        required double amount,
        required String paymentAddress,
        String paymentMethod = 'usdt',
    }) async {
        await _request('POST', '/diamonds/withdraw', body: {
            'amount': amount,
            'payment_address': paymentAddress,
            'payment_method': paymentMethod,
        });
    }

    /// 获取提现汇率
    Future<int> getWithdrawRate() async {
        final result = await _request('GET', '/diamonds/withdraw/rate');
        return int.tryParse(result['data']['exchange_rate']?.toString() ?? '10000') ?? 10000;
    }

    // ============ 1对1聊天模块 ============

    /// 获取会话列表
    Future<List<Conversation>> getConversations() async {
        final result = await _request('GET', '/chat/conversations');
        final list = result['data']['list'] as List;
        return list.map((e) => Conversation.fromJson(e)).toList();
    }

    /// 获取聊天记录
    Future<List<PrivateMessage>> getMessages(
        String oderId, {
        int page = 1,
        int limit = 50,
    }) async {
        final result = await _request('GET', '/chat/messages/$oderId', queryParams: {
            'page': page.toString(),
            'limit': limit.toString(),
        });
        final list = result['data']['list'] as List;
        return list.map((e) => PrivateMessage.fromJson(e)).toList();
    }

    /// 发送消息
    Future<Map<String, dynamic>> sendMessage({
        required String receiverId,
        required String type,
        required String content,
    }) async {
        final result = await _request('POST', '/chat/send', body: {
            'receiver_id': receiverId,
            'type': type,
            'content': content,
        });
        return result['data'];
    }

    /// 获取未读消息数
    Future<int> getUnreadCount() async {
        final result = await _request('GET', '/chat/unread');
        return result['data']['unread_count'] ?? 0;
    }

    // ============ 视频通话模块 ============

    /// 发起视频通话
    Future<Map<String, dynamic>> startVideoCall(String receiverId) async {
        final result = await _request('POST', '/video/call', body: {
            'receiver_id': receiverId,
        });
        return result['data'];
    }

    /// 接听通话
    Future<void> acceptVideoCall(String callId) async {
        await _request('PUT', '/video/call/$callId/accept');
    }

    /// 拒绝通话
    Future<void> rejectVideoCall(String callId) async {
        await _request('PUT', '/video/call/$callId/reject');
    }

    /// 结束通话
    Future<void> endVideoCall(String callId, int duration) async {
        await _request('PUT', '/video/call/$callId/end', body: {
            'duration': duration,
        });
    }
}

/**
 * API异常
 */
class ApiException implements Exception {
    final String message;
    ApiException(this.message);
    
    @override
    String toString() => message;
}
