/**
 * 好友模型
 */
class Friend {
    final String id;
    final String odId;
    final String account;
    final String nickname;
    final String avatar;
    final String gender;
    final String signature;
    final String status;
    final DateTime? createdAt;

    Friend({
        required this.id,
        required this.odId,
        required this.account,
        required this.nickname,
        required this.avatar,
        required this.gender,
        required this.signature,
        required this.status,
        this.createdAt,
    });

    factory Friend.fromJson(Map<String, dynamic> json) {
        return Friend(
            id: json['id'] ?? '',
            odId: json['user_id'] ?? '',
            account: json['account'] ?? '',
            nickname: json['nickname'] ?? '',
            avatar: json['avatar'] ?? '',
            gender: json['gender'] ?? 'unknown',
            signature: json['signature'] ?? '',
            status: json['status'] ?? 'pending',
            createdAt: json['created_at'] != null
                ? DateTime.tryParse(json['created_at'])
                : null,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'user_id': odId,
            'account': account,
            'nickname': nickname,
            'avatar': avatar,
            'gender': gender,
            'signature': signature,
            'status': status,
            'created_at': createdAt?.toIso8601String(),
        };
    }
}
