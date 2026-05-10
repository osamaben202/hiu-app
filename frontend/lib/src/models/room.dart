/**
 * 房间模型
 */
class Room {
    final String id;
    final String ownerId;
    final String name;
    final String cover;
    final String description;
    final bool isPublic;
    final String status;
    final int maxSeats;
    final int currentCount;
    final String tags;
    final String? ownerNickname;
    final String? ownerAvatar;
    final DateTime? createdAt;
    List<RoomSeat> seats;
    int onlineCount;

    Room({
        required this.id,
        required this.ownerId,
        required this.name,
        this.cover = '',
        this.description = '',
        this.isPublic = true,
        this.status = 'active',
        this.maxSeats = 8,
        this.currentCount = 0,
        this.tags = '',
        this.ownerNickname,
        this.ownerAvatar,
        this.createdAt,
        this.seats = const [],
        this.onlineCount = 0,
    });

    factory Room.fromJson(Map<String, dynamic> json) {
        return Room(
            id: json['id'] ?? '',
            ownerId: json['owner_id'] ?? '',
            name: json['name'] ?? '',
            cover: json['cover'] ?? '',
            description: json['description'] ?? '',
            isPublic: json['is_public'] ?? true,
            status: json['status'] ?? 'active',
            maxSeats: json['max_seats'] ?? 8,
            currentCount: json['current_count'] ?? 0,
            tags: json['tags'] ?? '',
            ownerNickname: json['owner_nickname'],
            ownerAvatar: json['owner_avatar'],
            createdAt: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at']) 
                : null,
            onlineCount: json['online_count'] ?? 0,
            seats: (json['seats'] as List<dynamic>?)
                ?.map((e) => RoomSeat.fromJson(e))
                .toList() ?? [],
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'owner_id': ownerId,
            'name': name,
            'cover': cover,
            'description': description,
            'is_public': isPublic,
            'status': status,
            'max_seats': maxSeats,
            'current_count': currentCount,
            'tags': tags,
        };
    }
}

/**
 * 麦位模型
 */
class RoomSeat {
    final String id;
    final String roomId;
    final int seatIndex;
    final String? userId;
    final String? nickname;
    final String? avatar;
    final String? gender;
    bool isMuted;
    bool isLocked;
    bool isSpeaking;
    final DateTime? joinAt;

    RoomSeat({
        required this.id,
        required this.roomId,
        required this.seatIndex,
        this.userId,
        this.nickname,
        this.avatar,
        this.gender,
        this.isMuted = true,
        this.isLocked = false,
        this.isSpeaking = false,
        this.joinAt,
    });

    factory RoomSeat.fromJson(Map<String, dynamic> json) {
        return RoomSeat(
            id: json['id'] ?? '',
            roomId: json['room_id'] ?? '',
            seatIndex: json['seat_index'] ?? 0,
            userId: json['user_id'],
            nickname: json['nickname'],
            avatar: json['avatar'],
            gender: json['gender'],
            isMuted: json['is_muted'] ?? true,
            isLocked: json['is_locked'] ?? false,
            isSpeaking: json['is_speaking'] ?? false,
            joinAt: json['join_at'] != null 
                ? DateTime.tryParse(json['join_at']) 
                : null,
        );
    }

    bool get isEmpty => userId == null || userId!.isEmpty;
    bool get isOccupied => !isEmpty;
}
