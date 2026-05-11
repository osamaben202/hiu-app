/**
 * 语音房页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../providers/user_provider.dart';
import '../providers/room_provider.dart';
import '../providers/friend_provider.dart';
import '../models/room.dart';
import '../models/gift.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'gift_panel.dart';

class RoomPage extends StatefulWidget {
    final String roomId;

    const RoomPage({super.key, required this.roomId});

    @override
    State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
    final _messageController = TextEditingController();
    final _scrollController = ScrollController();
    final List<ChatMessage> _messages = [];
    
    io.Socket? _socket;
    bool _isConnected = false;

    @override
    void initState() {
        super.initState();
        _loadRoom();
        _initSocket();
    }

    Future<void> _loadRoom() async {
        await Provider.of<RoomProvider>(context, listen: false).fetchRoomDetail(widget.roomId);
        await Provider.of<RoomProvider>(context, listen: false).fetchGifts();
    }

    void _initSocket() {
        final api = ApiService();
        final token = api.token;
        
        if (token == null) {
            debugPrint('No token available for socket connection');
            return;
        }

        _socket = io.io(
            ApiService.baseHost,
            io.OptionBuilder()
                .setTransports(['websocket'])
                .disableAutoConnect()
                .setAuth({'token': token})
                .build(),
        );

        _socket?.onConnect((_) {
            debugPrint('Socket connected');
            setState(() => _isConnected = true);
            // 加入房间
            _socket?.emit('join_room', {'room_id': widget.roomId});
        });

        _socket?.onDisconnect((_) {
            debugPrint('Socket disconnected');
            setState(() => _isConnected = false);
        });

        _socket?.onError((error) {
            debugPrint('Socket error: $error');
        });

        // 监听聊天消息
        _socket?.on('chat_message', (data) {
            debugPrint('Received chat message: $data');
            if (data != null) {
                final message = ChatMessage(
                    id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    roomId: data['room_id']?.toString(),
                    senderId: data['sender_id']?.toString() ?? '',
                    senderNickname: data['sender_nickname']?.toString(),
                    senderAvatar: data['sender_avatar']?.toString(),
                    type: data['type']?.toString() ?? 'text',
                    content: data['content']?.toString() ?? '',
                    createdAt: data['created_at'] != null
                        ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
                        : DateTime.now(),
                );
                setState(() {
                    _messages.add(message);
                });
                // 滚动到底部
                WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                        );
                    }
                });
            }
        });

        // 监听错误消息
        _socket?.on('error', (data) {
            debugPrint('Socket error event: $data');
            if (data != null && data['message'] != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data['message'].toString()), backgroundColor: Colors.red),
                );
            }
        });

        // 连接
        _socket?.connect();
    }

    @override
    void dispose() {
        // 离开房间并断开连接
        _socket?.emit('leave_room', {'room_id': widget.roomId});
        _socket?.disconnect();
        _socket?.dispose();
        _messageController.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    Future<void> _leaveRoom() async {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Leave Room'),
                content: const Text('Are you sure you want to leave this room?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                        ),
                        child: const Text('Leave', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
        );

        if (confirmed == true && mounted) {
            // 离开房间
            _socket?.emit('leave_room', {'room_id': widget.roomId});
            await Provider.of<RoomProvider>(context, listen: false).leaveRoom(widget.roomId);
            if (mounted) {
                Navigator.of(context).pop();
            }
        }
    }

    void _sendMessage() {
        if (_messageController.text.isEmpty) return;
        if (_socket == null || !_isConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not connected to chat'), backgroundColor: Colors.orange),
            );
            return;
        }
        
        // 通过 Socket 发送消息
        _socket?.emit('chat_message', {
            'room_id': widget.roomId,
            'content': _messageController.text.trim(),
            'type': 'text',
        });
        
        _messageController.clear();
    }

    void _showGiftPanel() {
        final room = Provider.of<RoomProvider>(context, listen: false).currentRoom;
        if (room == null) return;

        // 找出麦上的人
        final seats = room.seats.where((s) => s.isOccupied).toList();
        if (seats.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No one on mic to send gift to')),
            );
            return;
        }

        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => GiftPanel(
                receivers: seats.map((s) => {
                    'id': s.userId!,
                    'nickname': s.nickname ?? 'Unknown',
                    'avatar': s.avatar ?? '',
                }).toList(),
            ),
        );
    }

    void _showUserProfileCard(RoomSeat seat) async {
        if (seat.userId == null) return;
        
        try {
            final api = ApiService();
            final userInfo = await api.getUserInfo(seat.userId!);
            
            if (!mounted) return;
            
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _SeatUserProfileCard(
                    user: userInfo,
                    seat: seat,
                ),
            );
        } catch (e) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to load user info: $e'), backgroundColor: Colors.red),
                );
            }
        }
    }

    void _showRoomSettings() {
        // TODO: 显示房间设置
    }

    @override
    Widget build(BuildContext context) {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        final room = roomProvider.currentRoom;

        if (room == null) {
            return Scaffold(
                appBar: AppBar(title: const Text('Loading...')),
                body: const Center(child: CircularProgressIndicator()),
            );
        }

        final isOwner = room.ownerId == user?.id;

        return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            appBar: AppBar(
                backgroundColor: const Color(0xFF1A1A2E),
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            room.name,
                            style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                            children: [
                                Text(
                                    '${room.onlineCount} online',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                    ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isConnected ? Colors.green : Colors.red,
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
                actions: [
                    if (isOwner)
                        IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () => _showRoomSettings(),
                        ),
                    IconButton(
                        icon: const Icon(Icons.exit_to_app),
                        onPressed: _leaveRoom,
                    ),
                ],
            ),
            body: Column(
                children: [
                    // 麦位区域
                    Expanded(
                        flex: 2,
                        child: _SeatsArea(
                            seats: room.seats,
                            isOwner: isOwner,
                            roomId: widget.roomId,
                            onUserTap: _showUserProfileCard,
                        ),
                    ),

                    // 聊天区域
                    Expanded(
                        flex: 3,
                        child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                ),
                            ),
                            child: Column(
                                children: [
                                    // 消息列表
                                    Expanded(
                                        child: _MessagesList(
                                            messages: _messages,
                                            scrollController: _scrollController,
                                        ),
                                    ),

                                    // 输入栏
                                    _MessageInput(
                                        controller: _messageController,
                                        onSend: _sendMessage,
                                        onGift: _showGiftPanel,
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}

/**
 * 麦位区域
 */
class _SeatsArea extends StatelessWidget {
    final List<RoomSeat> seats;
    final bool isOwner;
    final String roomId;
    final Function(RoomSeat) onUserTap;

    const _SeatsArea({
        required this.seats,
        required this.isOwner,
        required this.roomId,
        required this.onUserTap,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                    final seat = seats.length > index ? seats[index] : null;
                    return _SeatItem(
                        seatIndex: index,
                        seat: seat,
                        isOwner: isOwner,
                        roomId: roomId,
                        onUserTap: onUserTap,
                    );
                },
            ),
        );
    }
}

/**
 * 麦位单项
 */
class _SeatItem extends StatelessWidget {
    final int seatIndex;
    final RoomSeat? seat;
    final bool isOwner;
    final String roomId;
    final Function(RoomSeat) onUserTap;

    const _SeatItem({
        required this.seatIndex,
        this.seat,
        required this.isOwner,
        required this.roomId,
        required this.onUserTap,
    });

    @override
    Widget build(BuildContext context) {
        final isOccupied = seat?.isOccupied ?? false;
        final isMuted = seat?.isMuted ?? true;
        final isLocked = seat?.isLocked ?? false;

        return GestureDetector(
            onTap: () => _handleTap(context),
            onLongPress: isOccupied ? () => onUserTap(seat!) : null,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Stack(
                        alignment: Alignment.center,
                        children: [
                            // 头像
                            Container(
                                width: 55,
                                height: 55,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isOccupied
                                            ? const Color(0xFF6C5CE7)
                                            : Colors.grey.withOpacity(0.3),
                                        width: 2,
                                    ),
                                    color: isOccupied
                                        ? const Color(0xFF6C5CE7).withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                ),
                                child: seat?.avatar != null && seat!.avatar!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                            seat!.avatar!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                                        ),
                                    )
                                    : _buildDefaultAvatar(),
                            ),
                            // 闭麦标记
                            if (isOccupied && isMuted)
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.mic_off,
                                            size: 12,
                                            color: Colors.white,
                                        ),
                                    ),
                                ),
                            // 锁定标记
                            if (isLocked)
                                Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.lock,
                                            size: 12,
                                            color: Colors.white,
                                        ),
                                    ),
                                ),
                        ],
                    ),
                    const SizedBox(height: 4),
                    // 昵称
                    Text(
                        isOccupied
                            ? (seat?.nickname ?? 'User')
                            : (isLocked ? 'Locked' : 'Empty'),
                        style: TextStyle(
                            fontSize: 11,
                            color: isOccupied ? Colors.white : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),
                ],
            ),
        );
    }

    Widget _buildDefaultAvatar() {
        return Center(
            child: isOccupied
                ? Text(
                    (seat?.nickname ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C5CE7),
                    ),
                )
                : Icon(
                    Icons.add,
                    color: Colors.grey[400],
                ),
        );
    }

    void _handleTap(BuildContext context) {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        
        if (seat?.isLocked ?? false) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This seat is locked')),
            );
            return;
        }

        if (seat?.isOccupied ?? false) {
            // 点击已占麦位
            if (seat?.userId == user?.id) {
                // 自己的麦位，下麦
                Provider.of<RoomProvider>(context, listen: false).leaveSeat(seatIndex);
            } else if (isOwner) {
                // 房主踢人
                _showKickDialog(context);
            } else {
                // 长按显示资料卡
                onUserTap(seat!);
            }
        } else {
            // 空麦位，上麦
            Provider.of<RoomProvider>(context, listen: false).joinSeat(seatIndex);
        }
    }

    void _showKickDialog(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Kick User'),
                content: Text('Kick ${seat?.nickname} from this seat?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () {
                            Navigator.pop(context);
                            Provider.of<RoomProvider>(context, listen: false)
                                .kickSeat(seatIndex);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Kick', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
        );
    }
}

/**
 * 座位用户资料卡
 */
class _SeatUserProfileCard extends StatelessWidget {
    final User user;
    final RoomSeat seat;

    const _SeatUserProfileCard({
        required this.user,
        required this.seat,
    });

    @override
    Widget build(BuildContext context) {
        final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
        final isSelf = user.id == currentUser?.id;

        return Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        const SizedBox(height: 20),
                        // 头像
                        CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                            backgroundImage: user.avatar.isNotEmpty
                                ? NetworkImage(user.avatar) as ImageProvider
                                : null,
                            child: user.avatar.isEmpty
                                ? Text(
                                    (user.nickname.isEmpty ? 'U' : user.nickname[0]).toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 36,
                                        color: Color(0xFF6C5CE7),
                                    ),
                                )
                                : null,
                        ),
                        const SizedBox(height: 16),
                        // 昵称
                        Text(
                            user.nickname.isEmpty ? user.account : user.nickname,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 8),
                        // ID
                        Text(
                            'ID: ${user.account}',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                            ),
                        ),
                        const SizedBox(height: 8),
                        // 签名
                        if (user.signature.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                    user.signature,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                    ),
                                ),
                            ),
                        const SizedBox(height: 24),
                        // 操作按钮
                        if (!isSelf)
                            Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                        _ActionButton(
                                            icon: Icons.person_add,
                                            label: 'Add Friend',
                                            onTap: () async {
                                                final provider = Provider.of<FriendProvider>(context, listen: false);
                                                await provider.sendFriendRequest(user.id);
                                                if (context.mounted) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Friend request sent')),
                                                    );
                                                }
                                            },
                                        ),
                                        _ActionButton(
                                            icon: Icons.card_giftcard,
                                            label: 'Send Gift',
                                            onTap: () {
                                                Navigator.pop(context);
                                                showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor: Colors.transparent,
                                                    builder: (ctx) => GiftPanel(
                                                        receivers: [{
                                                            'id': user.id,
                                                            'nickname': user.nickname.isEmpty ? user.account : user.nickname,
                                                            'avatar': user.avatar,
                                                        }],
                                                    ),
                                                );
                                            },
                                        ),
                                        _ActionButton(
                                            icon: Icons.block,
                                            label: 'Block',
                                            color: Colors.red,
                                            onTap: () async {
                                                final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                        title: const Text('Block User'),
                                                        content: const Text('Are you sure?'),
                                                        actions: [
                                                            TextButton(
                                                                onPressed: () => Navigator.pop(ctx, false),
                                                                child: const Text('Cancel'),
                                                            ),
                                                            ElevatedButton(
                                                                onPressed: () => Navigator.pop(ctx, true),
                                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                                child: const Text('Block', style: TextStyle(color: Colors.white)),
                                                            ),
                                                        ],
                                                    ),
                                                );
                                                if (confirmed == true) {
                                                    await Provider.of<FriendProvider>(context, listen: false).blockUser(user.id);
                                                    if (context.mounted) {
                                                        Navigator.pop(context);
                                                    }
                                                }
                                            },
                                        ),
                                    ],
                                ),
                            ),
                        const SizedBox(height: 32),
                    ],
                ),
            ),
        );
    }
}

class _ActionButton extends StatelessWidget {
    final IconData icon;
    final String label;
    final VoidCallback onTap;
    final Color? color;

    const _ActionButton({
        required this.icon,
        required this.label,
        required this.onTap,
        this.color,
    });

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onTap,
            child: Column(
                children: [
                    Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: (color ?? const Color(0xFF6C5CE7)).withOpacity(0.1),
                            shape: BoxShape.circle,
                        ),
                        child: Icon(
                            icon,
                            color: color ?? const Color(0xFF6C5CE7),
                        ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        label,
                        style: TextStyle(
                            fontSize: 12,
                            color: color ?? Colors.grey[700],
                        ),
                    ),
                ],
            ),
        );
    }
}

/**
 * 消息列表
 */
class _MessagesList extends StatelessWidget {
    final List<ChatMessage> messages;
    final ScrollController scrollController;

    const _MessagesList({
        required this.messages,
        required this.scrollController,
    });

    @override
    Widget build(BuildContext context) {
        if (messages.isEmpty) {
            return Center(
                child: Text(
                    'No messages yet',
                    style: TextStyle(color: Colors.grey[400]),
                ),
            );
        }

        return ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
                final msg = messages[index];
                return _MessageBubble(message: msg);
            },
        );
    }
}

/**
 * 消息气泡
 */
class _MessageBubble extends StatelessWidget {
    final ChatMessage message;

    const _MessageBubble({required this.message});

    @override
    Widget build(BuildContext context) {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        final isMe = message.senderId == user?.id;

        return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    if (!isMe) ...[
                        CircleAvatar(
                            radius: 15,
                            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                            backgroundImage: message.senderAvatar != null && message.senderAvatar!.isNotEmpty
                                ? NetworkImage(message.senderAvatar!) as ImageProvider
                                : null,
                            child: message.senderAvatar == null || message.senderAvatar!.isEmpty
                                ? Text(
                                    (message.senderNickname ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6C5CE7),
                                    ),
                                )
                                : null,
                        ),
                        const SizedBox(width: 8),
                    ],
                    Flexible(
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                            ),
                            decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFF6C5CE7)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    if (!isMe)
                                        Text(
                                            message.senderNickname ?? 'Unknown',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey[600],
                                            ),
                                        ),
                                    Text(
                                        message.content,
                                        style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                    if (isMe) const SizedBox(width: 8),
                ],
            ),
        );
    }
}

/**
 * 消息输入框
 */
class _MessageInput extends StatelessWidget {
    final TextEditingController controller;
    final VoidCallback onSend;
    final VoidCallback onGift;

    const _MessageInput({
        required this.controller,
        required this.onSend,
        required this.onGift,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                    ),
                ],
            ),
            child: SafeArea(
                child: Row(
                    children: [
                        IconButton(
                            icon: const Icon(Icons.card_giftcard),
                            color: const Color(0xFF6C5CE7),
                            onPressed: onGift,
                        ),
                        Expanded(
                            child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                    hintText: 'Type a message...',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(25),
                                        borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                    ),
                                ),
                            ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                            icon: const Icon(Icons.send),
                            color: const Color(0xFF6C5CE7),
                            onPressed: onSend,
                        ),
                    ],
                ),
            ),
        );
    }
}

// 简单的消息类型用于UI显示
class ChatMessage {
    final String id;
    final String? roomId;
    final String senderId;
    final String? senderNickname;
    final String? senderAvatar;
    final String type;
    final String content;
    final DateTime createdAt;

    ChatMessage({
        required this.id,
        this.roomId,
        required this.senderId,
        this.senderNickname,
        this.senderAvatar,
        required this.type,
        required this.content,
        required this.createdAt,
    });
}
