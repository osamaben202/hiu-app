/**
 * 礼物模型
 */
class Gift {
    final String id;
    final String name;
    final String nameEn;
    final String icon;
    final String animation;
    final int price;

    Gift({
        required this.id,
        required this.name,
        required this.nameEn,
        this.icon = '',
        this.animation = '',
        required this.price,
    });

    factory Gift.fromJson(Map<String, dynamic> json) {
        return Gift(
            id: json['id'] ?? '',
            name: json['name'] ?? '',
            nameEn: json['name_en'] ?? '',
            icon: json['icon'] ?? '',
            animation: json['animation'] ?? '',
            price: json['price'] ?? 0,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'name': name,
            'name_en': nameEn,
            'icon': icon,
            'animation': animation,
            'price': price,
        };
    }
}

/**
 * 礼物记录模型
 */
class GiftRecord {
    final String id;
    final String giftId;
    final String senderId;
    final String receiverId;
    final String? roomId;
    final int count;
    final double totalCoins;
    final double totalDiamonds;
    final String? giftName;
    final String? giftIcon;
    final String? senderNickname;
    final String? senderAvatar;
    final String? receiverNickname;
    final String? receiverAvatar;
    final String? roomName;
    final DateTime createdAt;

    GiftRecord({
        required this.id,
        required this.giftId,
        required this.senderId,
        required this.receiverId,
        this.roomId,
        this.count = 1,
        required this.totalCoins,
        required this.totalDiamonds,
        this.giftName,
        this.giftIcon,
        this.senderNickname,
        this.senderAvatar,
        this.receiverNickname,
        this.receiverAvatar,
        this.roomName,
        required this.createdAt,
    });

    factory GiftRecord.fromJson(Map<String, dynamic> json) {
        return GiftRecord(
            id: json['id'] ?? '',
            giftId: json['gift_id'] ?? '',
            senderId: json['sender_id'] ?? '',
            receiverId: json['receiver_id'] ?? '',
            roomId: json['room_id'],
            count: json['count'] ?? 1,
            totalCoins: double.tryParse(json['total_coins']?.toString() ?? '0') ?? 0,
            totalDiamonds: double.tryParse(json['total_diamonds']?.toString() ?? '0') ?? 0,
            giftName: json['gift_name'],
            giftIcon: json['gift_icon'],
            senderNickname: json['sender_nickname'],
            senderAvatar: json['sender_avatar'],
            receiverNickname: json['receiver_nickname'],
            receiverAvatar: json['receiver_avatar'],
            roomName: json['room_name'],
            createdAt: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at']) 
                : DateTime.now(),
        );
    }
}
