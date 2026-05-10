/**
 * 聊天状态管理
 */
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class ChatProvider extends ChangeNotifier {
    final ApiService _api = ApiService();
    
    List<Conversation> _conversations = [];
    Map<String, List<PrivateMessage>> _messages = {}; // oderId -> messages
    Map<String, User> _chatUsers = {}; // oderId -> user info
    bool _isLoading = false;
    String? _error;
    int _unreadCount = 0;

    List<Conversation> get conversations => _conversations;
    Map<String, List<PrivateMessage>> get messages => _messages;
    Map<String, User> get chatUsers => _chatUsers;
    bool get isLoading => _isLoading;
    String? get error => _error;
    int get unreadCount => _unreadCount;

    /// 获取会话列表
    Future<void> fetchConversations() async {
        _isLoading = true;
        notifyListeners();

        try {
            _conversations = await _api.getConversations();
            _error = null;
        } catch (e) {
            _error = e.toString();
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 获取聊天记录
    Future<List<PrivateMessage>> fetchMessages(String oderId) async {
        _isLoading = true;
        notifyListeners();

        try {
            final msgs = await _api.getMessages(oderId);
            _messages[oderId] = msgs;
            _error = null;
            
            // 清除该会话的未读数
            final index = _conversations.indexWhere((c) => c.oderId == oderId);
            if (index != -1) {
                _conversations[index].unreadCount = 0;
            }
            
            return msgs;
        } catch (e) {
            _error = e.toString();
            return [];
        } finally {
            _isLoading = false;
            notifyListeners();
        }
    }

    /// 发送消息
    Future<PrivateMessage?> sendMessage({
        required String receiverId,
        required String type,
        required String content,
    }) async {
        try {
            final data = await _api.sendMessage(
                receiverId: receiverId,
                type: type,
                content: content,
            );
            
            final message = PrivateMessage.fromJson(data['message']);
            
            // 添加到本地消息列表
            if (_messages[receiverId] != null) {
                _messages[receiverId]!.add(message);
            } else {
                _messages[receiverId] = [message];
            }
            
            // 更新会话列表
            final index = _conversations.indexWhere((c) => c.oderId == receiverId);
            if (index != -1) {
                _conversations[index].lastMessage = ChatMessage(
                    id: message.id,
                    senderId: message.senderId,
                    type: message.type,
                    content: message.content,
                    createdAt: message.createdAt,
                );
            }
            
            notifyListeners();
            return message;
        } catch (e) {
            _error = e.toString();
            notifyListeners();
            return null;
        }
    }

    /// 获取未读消息数
    Future<void> fetchUnreadCount() async {
        try {
            _unreadCount = await _api.getUnreadCount();
            notifyListeners();
        } catch (e) {
            // 忽略错误
        }
    }

    /// 添加收到的新消息
    void addMessage(String senderId, PrivateMessage message) {
        if (_messages[senderId] != null) {
            _messages[senderId]!.add(message);
        } else {
            _messages[senderId] = [message];
        }
        
        // 更新会话列表
        final index = _conversations.indexWhere((c) => c.oderId == senderId);
        if (index != -1) {
            _conversations[index].lastMessage = ChatMessage(
                id: message.id,
                senderId: message.senderId,
                type: message.type,
                content: message.content,
                createdAt: message.createdAt,
            );
        }
        
        notifyListeners();
    }

    /// 设置聊天用户信息
    void setChatUser(String oderId, User user) {
        _chatUsers[oderId] = user;
        notifyListeners();
    }

    /// 获取聊天用户信息
    User? getChatUser(String oderId) {
        return _chatUsers[oderId];
    }

    /// 获取与某人的消息列表
    List<PrivateMessage> getMessages(String oderId) {
        return _messages[oderId] ?? [];
    }

    /// 清除状态
    void clear() {
        _conversations = [];
        _messages = {};
        _chatUsers = {};
        _unreadCount = 0;
        notifyListeners();
    }
}
