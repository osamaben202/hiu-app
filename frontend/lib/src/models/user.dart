/**
 * 用户模型
 */
class User {
    final String id;
    final String account;
    final String? email;
    String nickname;
    String avatar;
    String gender;
    String role;
    String signature;
    double coinBalance;
    double diamondBalance;
    double textPrice;
    double imagePrice;
    double videoPrice;
    final DateTime? createdAt;
    final DateTime? lastLoginAt;

    User({
        required this.id,
        required this.account,
        this.email,
        this.nickname = '',
        this.avatar = '',
        this.gender = 'unknown',
        this.role = 'user',
        this.signature = '',
        this.coinBalance = 0,
        this.diamondBalance = 0,
        this.textPrice = 1,
        this.imagePrice = 5,
        this.videoPrice = 10,
        this.createdAt,
        this.lastLoginAt,
    });

    factory User.fromJson(Map<String, dynamic> json) {
        return User(
            id: json['id'] ?? '',
            account: json['account'] ?? '',
            email: json['email'],
            nickname: json['nickname'] ?? '',
            avatar: json['avatar'] ?? '',
            gender: json['gender'] ?? 'unknown',
            role: json['role'] ?? 'user',
            signature: json['signature'] ?? '',
            coinBalance: double.tryParse(json['coin_balance']?.toString() ?? '0') ?? 0,
            diamondBalance: double.tryParse(json['diamond_balance']?.toString() ?? '0') ?? 0,
            textPrice: double.tryParse(json['text_price']?.toString() ?? '1') ?? 1,
            imagePrice: double.tryParse(json['image_price']?.toString() ?? '5') ?? 5,
            videoPrice: double.tryParse(json['video_price']?.toString() ?? '10') ?? 10,
            createdAt: json['created_at'] != null 
                ? DateTime.tryParse(json['created_at']) 
                : null,
            lastLoginAt: json['last_login_at'] != null 
                ? DateTime.tryParse(json['last_login_at']) 
                : null,
        );
    }

    Map<String, dynamic> toJson() {
        return {
            'id': id,
            'account': account,
            'email': email,
            'nickname': nickname,
            'avatar': avatar,
            'gender': gender,
            'role': role,
            'signature': signature,
            'coin_balance': coinBalance,
            'diamond_balance': diamondBalance,
            'text_price': textPrice,
            'image_price': imagePrice,
            'video_price': videoPrice,
        };
    }

    User copyWith({
        String? id,
        String? account,
        String? email,
        String? nickname,
        String? avatar,
        String? gender,
        String? role,
        String? signature,
        double? coinBalance,
        double? diamondBalance,
        double? textPrice,
        double? imagePrice,
        double? videoPrice,
    }) {
        return User(
            id: id ?? this.id,
            account: account ?? this.account,
            email: email ?? this.email,
            nickname: nickname ?? this.nickname,
            avatar: avatar ?? this.avatar,
            gender: gender ?? this.gender,
            role: role ?? this.role,
            signature: signature ?? this.signature,
            coinBalance: coinBalance ?? this.coinBalance,
            diamondBalance: diamondBalance ?? this.diamondBalance,
            textPrice: textPrice ?? this.textPrice,
            imagePrice: imagePrice ?? this.imagePrice,
            videoPrice: videoPrice ?? this.videoPrice,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
        );
    }
}
