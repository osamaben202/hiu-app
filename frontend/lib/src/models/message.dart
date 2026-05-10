/**
 * 消息模型
 */
class ChatMessage {
    final String id;
    final String? roomId;
    final String senderId;
    final String? senderNickname;
    final String? senderAvatar;
    final String type; // text, image, gift, system
    final String content;
    final String? receiverId;
    final String? giftName;
    final int? giftCount;
    final DateTime createdAt;

    ChatMessage({
        required this.id,
        this.roomId,
        required this.senderId,
        this.senderNickname,
        this.senderAvatar,
        required this.type,
        required this.content,
        this.receiverId,
        this.giftName,
        this.giftCount,
        required this.createdAt,
    });

    factory ChatMessage.fromJson(Map<String, dynamic> json) {
        return ChatMessage(
            id: json['id'] ?? '',
            roomId: json['room_id'],
            senderId: json['sender_id'] ?? '',
            senderNickname: json['sender_nickname'],
            senderAvatar: json['sender_avatar'],
            type: json['type'] ?? 'text',
            content: json['content'] ?? '',
            receiverId: json['receiver_id'],
            giftName: json['gift_name'],
            giftCount: json['gift_count'] ?? json['count'],
            createdAt: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
                : DateTime.now(),
        );
    }
}

/**
 * 私聊消息模型
 */
class PrivateMessage {
    final String id;
    final String senderId;
    final String receiverId;
    final String type; // text, image
    final String content;
    final bool isRead;
    final double costCoins;
    final String? senderNickname;
    final String? senderAvatar;
    final String? receiverNickname;
    final String? receiverAvatar;
    final DateTime createdAt;

    PrivateMessage({
        required this.id,
        required this.senderId,
        required this.receiverId,
        required this.type,
        required this.content,
        this.isRead = false,
        this.costCoins = 0,
        this.senderNickname,
        this.senderAvatar,
        this.receiverNickname,
        this.receiverAvatar,
        required this.createdAt,
    });

    factory PrivateMessage.fromJson(Map<String, dynamic> json) {
        return PrivateMessage(
            id: json['id'] ?? '',
            senderId: json['sender_id'] ?? '',
            receiverId: json['receiver_id'] ?? '',
            type: json['type'] ?? 'text',
            content: json['content'] ?? '',
            isRead: json['is_read'] ?? false,
            costCoins: double.tryParse(json['cost_coins']?.toString() ?? '0') ?? 0,
            senderNickname: json['sender_nickname'],
            senderAvatar: json['sender_avatar'],
            receiverNickname: json['receiver_nickname'],
            receiverAvatar: json['receiver_avatar'],
            createdAt: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
                : DateTime.now(),
        );
    }
}

/**
 * 会话模型
 */
class Conversation {
    final String oderId;
    final String nickname;
    final String avatar;
    final String gender;
    final String role;
    ChatMessage? lastMessage;
    int unreadCount;

    Conversation({
        required this.oderId,
        required this.nickname,
        this.avatar = '',
        this.gender = 'unknown',
        this.role = 'user',
        this.lastMessage,
        this.unreadCount = 0,
    });

    factory Conversation.fromJson(Map<String, dynamic> json) {
        return Conversation(
            oderId: json['user_id'] ?? '',
            nickname: json['nickname'] ?? '',
            avatar: json['avatar'] ?? '',
            gender: json['gender'] ?? 'unknown',
            role: json['role'] ?? 'user',
            lastMessage: json['last_message'] != null 
                ? ChatMessage.fromJson(json['last_message']) 
                : null,
            unreadCount: json['unread_count'] ?? 0,
        );
    }
}
