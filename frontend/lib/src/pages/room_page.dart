/**
 * 语音房页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hiu_app/src/services/socket_service.dart';
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
    SocketService get socketService => SocketService();
    final _scrollController = ScrollController();
    final List<ChatMessage> _messages = [];
    
    // Using global SocketService instead of local socket
    bool _isConnected = false;
    bool _isLoading = true;
    Room? _room;
    RoomProvider? _roomProvider;

    @override
    void initState() {
        super.initState();
        _loadRoom();
        _initSocketAndJoinRoom();
    }

    Future<void> _loadRoom() async {
        _roomProvider = Provider.of<RoomProvider>(context, listen: false);
        await _roomProvider!.fetchRoomDetail(widget.roomId);
        await _roomProvider!.fetchGifts();
        if (mounted) {
            setState(() {
                _room = _roomProvider!.currentRoom;
                _isLoading = false;
            });
        }
    }



    void _showSeatRequestDialog(Map<String, dynamic> data) {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (user == null || _room == null) return;
        if (_room!.ownerId != user.id) return; // 只有房主能收到

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Seat Request'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                            backgroundImage: data['requester_avatar'] != null && data['requester_avatar'].toString().isNotEmpty
                                ? NetworkImage(data['requester_avatar'].toString()) as ImageProvider
                                : null,
                            child: data['requester_avatar'] == null || data['requester_avatar'].toString().isEmpty
                                ? Text((data['requester_nickname'] ?? 'U')[0].toUpperCase())
                                : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                            '${data['requester_nickname'] ?? 'Unknown'} wants to join seat ${(data['seat_index'] ?? 0) + 1}',
                            textAlign: TextAlign.center,
                        ),
                    ],
                ),
                actions: [
                    TextButton(
                        onPressed: () {
                            Navigator.pop(context);
                            socketService.rejectSeat(widget.roomId, data['requester_id'].toString());
                        },
                        child: const Text('Reject'),
                    ),
                    ElevatedButton(
                        onPressed: () {
                            Navigator.pop(context);
                            socketService.approveSeat(widget.roomId, data['requester_id'].toString(), data['seat_index'] as int);
                        },
                        child: const Text('Approve'),
                    ),
                ],
            ),
        );
    }

    @override
    void dispose() {
        // 离开房间并断开连接
        SocketService().leaveRoom(widget.roomId);
        // SocketService is global, don't dispose here
        _removeSocketListeners();
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
            socketService.leaveRoom(widget.roomId);
            await _roomProvider?.leaveRoom(widget.roomId);
            if (mounted) {
                Navigator.of(context).pop();
            }
        }
    }

    void _sendMessage() async {
        if (_messageController.text.isEmpty) return;
        final text = _messageController.text.trim();
        _messageController.clear();
        
        // 优先通过 Socket 发送消息
        if (SocketService().isConnected) {
            socketService.sendChatMessage(widget.roomId, text);
        } else {
            // Socket 未连接时使用 HTTP API 发送
            try {
                await ApiService().sendRoomMessage(widget.roomId, text);
            } catch (e) {
                debugPrint('HTTP message send failed: $e');
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.red),
                    );
                }
            }
        }
    }

    void _initSocketAndJoinRoom() {
        final api = ApiService();
        final token = api.token;
        if (token != null) {
            SocketService().init(token);
            _setupSocketListeners();
            // 使用 onConnected 确保连接成功后再加入房间
            SocketService().onConnected(() {
                SocketService().joinRoom(widget.roomId);
            });
        }
    }

    void _setupSocketListeners() {
        socketService.on('chat_message', _onChatMessage);
        socketService.on('seat_request', _onSeatRequest);
        socketService.on('seat_request_sent', _onSeatRequestSent);
        socketService.on('seat_approved', _onSeatApproved);
        socketService.on('seat_rejected', _onSeatRejected);
        socketService.on('seat_update', _onSeatUpdate);
        socketService.on('user_joined', _onUserJoined);
        socketService.on('user_left', _onUserLeft);
        socketService.on('room_closed', _onRoomClosed);
    }

    void _removeSocketListeners() {
        socketService.off('chat_message', _onChatMessage);
        socketService.off('seat_request', _onSeatRequest);
        socketService.off('seat_request_sent', _onSeatRequestSent);
        socketService.off('seat_approved', _onSeatApproved);
        socketService.off('seat_rejected', _onSeatRejected);
        socketService.off('seat_update', _onSeatUpdate);
        socketService.off('user_joined', _onUserJoined);
        socketService.off('user_left', _onUserLeft);
        socketService.off('room_closed', _onRoomClosed);
    }

    void _onChatMessage(dynamic data) {
        debugPrint('Received chat message: $data');
        if (data != null && data['content'] != null) {
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
            if (mounted) {
                setState(() {
                    _messages.add(message);
                });
                _scrollToBottom();
            }
        }
    }

    void _onSeatRequest(dynamic data) {
        debugPrint('Received seat request: $data');
        if (data != null && mounted) {
            _showSeatRequestDialog(data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data));
        }
    }

    void _onSeatRequestSent(dynamic data) {
        debugPrint('Seat request sent: $data');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request sent, waiting for approval...')),
            );
        }
    }

    void _onSeatApproved(dynamic data) {
        debugPrint('Seat approved: $data');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your seat request was approved!'), backgroundColor: Colors.green),
            );
            _roomProvider?.fetchRoomDetail(widget.roomId);
        }
    }

    void _onSeatRejected(dynamic data) {
        debugPrint('Seat rejected: $data');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your seat request was rejected'), backgroundColor: Colors.orange),
            );
        }
    }

    void _onSeatUpdate(dynamic data) {
        debugPrint('Seat update: $data');
        if (mounted) {
            _roomProvider?.fetchRoomDetail(widget.roomId);
        }
    }

    void _onUserJoined(dynamic data) {
        debugPrint('User joined: $data');
        if (data != null && mounted) {
            final msg = ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                roomId: widget.roomId,
                senderId: '',
                senderNickname: null,
                type: 'system',
                content: '${data['nickname']} joined the room',
                createdAt: DateTime.now(),
            );
            setState(() => _messages.add(msg));
        }
    }

    void _onUserLeft(dynamic data) {
        debugPrint('User left: $data');
        if (data != null && mounted) {
            final msg = ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                roomId: widget.roomId,
                senderId: '',
                senderNickname: null,
                type: 'system',
                content: '${data['nickname']} left the room',
                createdAt: DateTime.now(),
            );
            setState(() => _messages.add(msg));
        }
    }

    void _onRoomClosed(dynamic data) {
        debugPrint('Room closed: $data');
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room has been closed by the host'), backgroundColor: Colors.red),
            );
            Navigator.of(context).pop();
        }
    }

    void _scrollToBottom() {
        Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
                _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                );
            }
        });
    }

    void _showGiftPanel() {
        if (_room == null) return;

        // 找出麦上的人
        final seats = _room!.seats.where((s) => s.isOccupied).toList();
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
                receivers: seats.map((s) => <String, String>{
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
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (user == null || _room == null) return;
        
        final isOwner = _room!.ownerId == user.id;
        
        showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
                decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Room Settings'),
                                onTap: isOwner ? () {
                                    Navigator.pop(context);
                                    // TODO: Navigate to room settings
                                } : null,
                            ),
                            if (isOwner)
                                ListTile(
                                    leading: const Icon(Icons.close, color: Colors.red),
                                    title: const Text('Close Room', style: TextStyle(color: Colors.red)),
                                    onTap: () async {
                                        Navigator.pop(context);
                                        await _showCloseRoomDialog();
                                    },
                                ),
                            ListTile(
                                leading: const Icon(Icons.exit_to_app),
                                title: const Text('Leave Room'),
                                onTap: () {
                                    Navigator.pop(context);
                                    _leaveRoom();
                                },
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    Future<void> _showCloseRoomDialog() async {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Close Room'),
                content: const Text('Are you sure you want to close this room? All users will be removed.'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
        );

        if (confirmed == true && mounted) {
            final success = await _roomProvider?.closeRoom();
            if (success == true && mounted) {
                Navigator.of(context).pop();
            }
        }
    }

    void _onSeatTap(RoomSeat seat) {
        if (seat.isOccupied) {
            _showUserProfileCard(seat);
        } else if (!seat.isLocked) {
            // 空座位，点击申请上麦
            _showJoinSeatDialog(seat.seatIndex);
        }
    }

    void _showJoinSeatDialog(int seatIndex) async {
        final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Join Seat'),
                content: Text('Do you want to request to join seat ${seatIndex + 1}?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Request'),
                    ),
                ],
            ),
        );

        if (confirmed == true && mounted) {
            // 通过 socket 发送上麦申请
            socketService.requestSeat(widget.roomId, seatIndex);
        }
    }

    void _onMicToggle(RoomSeat seat) async {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        if (user == null || _room == null) return;
        
        final isOwner = _room!.ownerId == user.id;
        final isMe = seat.userId == user.id;
        
        if (isMe) {
            // 自己下麦
            await _roomProvider?.leaveSeat(seat.seatIndex);
        } else if (isOwner) {
            // 房主可以闭麦
            await _roomProvider?.muteSeat(seat.seatIndex, !seat.isMuted);
        }
    }

    @override
    Widget build(BuildContext context) {
        if (_isLoading) {
            return Scaffold(
                backgroundColor: const Color(0xFF1A1A2E),
                body: const Center(child: CircularProgressIndicator()),
            );
        }

        return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            body: SafeArea(
                child: Column(
                    children: [
                        // 顶部栏
                        _buildTopBar(),
                        // 麦位区域
                        _buildSeatsArea(),
                        // 消息列表
                        Expanded(
                            child: _MessagesList(
                                messages: _messages,
                                scrollController: _scrollController,
                            ),
                        ),
                        // 输入框
                        _MessageInput(
                            controller: _messageController,
                            onSend: _sendMessage,
                            onGift: _showGiftPanel,
                        ),
                    ],
                ),
            ),
        );
    }

    Widget _buildTopBar() {
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        final isOwner = _room?.ownerId == user?.id;

        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF16213E),
            child: Row(
                children: [
                    IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                            if (isOwner) {
                                _showOwnerLeaveDialog();
                            } else {
                                _leaveRoom();
                            }
                        },
                    ),
                    Expanded(
                        child: Column(
                            children: [
                                Text(
                                    _room?.name ?? 'Voice Room',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                                Text(
                                    'Online: ${_room?.onlineCount ?? 0}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                    ),
                                ),
                            ],
                        ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: _showRoomSettings,
                    ),
                ],
            ),
        );
    }

    Future<void> _showOwnerLeaveDialog() async {
        final action = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Room Owner Leaving'),
                content: const Text('As the room owner, what would you like to do?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('Cancel'),
                    ),
                    TextButton(
                        onPressed: () => Navigator.pop(context, 'transfer'),
                        child: const Text('Transfer Owner'),
                    ),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(context, 'close'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Close Room', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
        );

        if (action == 'close' && mounted) {
            await _showCloseRoomDialog();
        } else if (action == 'transfer' && mounted) {
            await _showTransferOwnerDialog();
        }
    }

    Future<void> _showTransferOwnerDialog() async {
        if (_room == null) return;
        
        final seatsOnMic = _room!.seats.where((s) => s.isOccupied).toList();
        if (seatsOnMic.isEmpty) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No one on mic to transfer to')),
                );
            }
            return;
        }

        final selectedUser = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Transfer Owner'),
                content: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: seatsOnMic.length,
                        itemBuilder: (context, index) {
                            final seat = seatsOnMic[index];
                            return ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                    backgroundImage: seat.avatar != null && seat.avatar!.isNotEmpty
                                        ? NetworkImage(seat.avatar!) as ImageProvider
                                        : null,
                                    child: seat.avatar == null || seat.avatar!.isEmpty
                                        ? Text((seat.nickname ?? 'U')[0].toUpperCase())
                                        : null,
                                ),
                                title: Text(seat.nickname ?? 'Unknown'),
                                onTap: () => Navigator.pop(context, seat.userId),
                            );
                        },
                    ),
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                    ),
                ],
            ),
        );

        if (selectedUser != null && mounted) {
            try {
                // 调用转移房主API
                await ApiService().transferRoomOwner(_room!.id, selectedUser);
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Owner transferred successfully')),
                    );
                    await _roomProvider?.leaveRoom(_room!.id);
                    if (mounted) {
                        Navigator.of(context).pop();
                    }
                }
            } catch (e) {
                if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Transfer failed: $e'), backgroundColor: Colors.red),
                    );
                }
            }
        }
    }

    Widget _buildSeatsArea() {
        if (_room == null) {
            return const SizedBox(height: 200);
        }

        return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
                children: [
                    // 房间信息
                    if (_room!.cover != null && _room!.cover!.isNotEmpty)
                        Container(
                            height: 100,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                    image: NetworkImage(_room!.cover!),
                                    fit: BoxFit.cover,
                                ),
                            ),
                        ),
                    // 麦位网格
                    GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                        ),
                        itemCount: _room!.seats.length,
                        itemBuilder: (context, index) {
                            final seat = _room!.seats[index];
                            return _buildSeatItem(seat);
                        },
                    ),
                ],
            ),
        );
    }

    Widget _buildSeatItem(RoomSeat seat) {
        final isOccupied = seat.isOccupied;
        final isLocked = seat.isLocked;
        final isMuted = seat.isMuted;

        return GestureDetector(
            onTap: () => _onSeatTap(seat),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    // 头像/空位
                    Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.grey.withOpacity(0.3)
                                : isOccupied
                                    ? const Color(0xFF6C5CE7).withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isOccupied ? const Color(0xFF6C5CE7) : Colors.grey.withOpacity(0.3),
                                width: 2,
                            ),
                        ),
                        child: isLocked
                            ? const Icon(Icons.lock, color: Colors.grey)
                            : isOccupied
                                ? ClipOval(
                                    child: seat.avatar != null && seat.avatar!.isNotEmpty
                                        ? Image.network(seat.avatar!, fit: BoxFit.cover)
                                        : Center(
                                            child: Text(
                                                (seat.nickname ?? 'U')[0].toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    color: Color(0xFF6C5CE7),
                                                ),
                                            ),
                                        ),
                                )
                                : Icon(Icons.add, color: Colors.grey.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 4),
                    // 昵称/座位号
                    Text(
                        isOccupied
                            ? (seat.nickname ?? 'User')
                            : isLocked
                                ? 'Locked'
                                : 'Seat ${seat.seatIndex + 1}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                    ),
                    // 麦克风状态
                    if (isOccupied)
                        Icon(
                            isMuted ? Icons.mic_off : Icons.mic,
                            size: 16,
                            color: isMuted ? Colors.red : Colors.green,
                        ),
                ],
            ),
        );
    }
}

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
                        CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                            backgroundImage: user.avatar.isNotEmpty
                                ? NetworkImage(user.avatar) as ImageProvider
                                : null,
                            child: user.avatar.isEmpty
                                ? Text(
                                    (user.nickname.isEmpty ? 'U' : user.nickname[0]).toUpperCase(),
                                    style: const TextStyle(fontSize: 36, color: Color(0xFF6C5CE7)),
                                )
                                : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                            user.nickname.isEmpty ? user.account : user.nickname,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'ID: ${user.account}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
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
                        child: Icon(icon, color: color ?? const Color(0xFF6C5CE7)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        label,
                        style: TextStyle(fontSize: 12, color: color ?? Colors.grey[700]),
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
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF6C5CE7)),
                                )
                                : null,
                        ),
                        const SizedBox(width: 8),
                    ],
                    Flexible(
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF6C5CE7) : Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    if (!isMe)
                                        Text(
                                            message.senderNickname ?? 'Unknown',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                        ),
                                    Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
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
                    BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, -2)),
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
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
