/**
 * 房间列表页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../providers/room_provider.dart';
import '../models/room.dart';
import '../services/api_service.dart';
import 'room_page.dart';

class RoomListPage extends StatefulWidget {
    const RoomListPage({super.key});

    @override
    State<RoomListPage> createState() => _RoomListPageState();
}

class _RoomListPageState extends State<RoomListPage> {
    final _searchController = TextEditingController();
    String _sortBy = 'created';
    io.Socket? _socket;

    @override
    void initState() {
        super.initState();
        _initSocket();
    }

    void _initSocket() {
        final api = ApiService();
        final token = api.token;
        
        if (token == null) return;

        _socket = io.io(
            ApiService.baseHost,
            io.OptionBuilder()
                
                .disableAutoConnect()
                .setAuth({'token': token})
                .build(),
        );

        _socket?.onConnect((_) {
            debugPrint('RoomList: Socket connected');
        });

        // 监听新房间创建
        _socket?.on('new_room', (data) {
            debugPrint('New room created: $data');
            if (data != null) {
                final newRoom = Room.fromJson(data);
                // 添加到房间列表
                final provider = Provider.of<RoomProvider>(context, listen: false);
                if (!mounted) return;
                // 检查是否已存在
                final exists = provider.rooms.any((r) => r.id == newRoom.id);
                if (!exists) {
                    setState(() {
                        provider.rooms.insert(0, newRoom);
                    });
                }
            }
        });

        // 监听房间删除
        _socket?.on('room_deleted', (data) {
            debugPrint('Room deleted: $data');
            if (data != null && data['room_id'] != null) {
                final provider = Provider.of<RoomProvider>(context, listen: false);
                setState(() {
                    provider.rooms.removeWhere((r) => r.id == data['room_id']);
                });
            }
        });

        _socket?.connect();
    }

    @override
    void dispose() {
        _socket?.disconnect();
        _socket?.dispose();
        _searchController.dispose();
        super.dispose();
    }

    Future<void> _refresh() async {
        await Provider.of<RoomProvider>(context, listen: false).fetchRooms(
            keyword: _searchController.text.isEmpty ? null : _searchController.text,
            sort: _sortBy,
        );
    }

    void _search() {
        Provider.of<RoomProvider>(context, listen: false).fetchRooms(
            keyword: _searchController.text.isEmpty ? null : _searchController.text,
            sort: _sortBy,
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Voice Rooms'),
                actions: [
                    PopupMenuButton<String>(
                        icon: const Icon(Icons.sort),
                        onSelected: (value) {
                            setState(() => _sortBy = value);
                            _search();
                        },
                        itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'created',
                                child: Row(
                                    children: [
                                        if (_sortBy == 'created')
                                            const Icon(Icons.check, size: 18),
                                        const SizedBox(width: 8),
                                        const Text('Latest'),
                                    ],
                                ),
                            ),
                            PopupMenuItem(
                                value: 'hot',
                                child: Row(
                                    children: [
                                        if (_sortBy == 'hot')
                                            const Icon(Icons.check, size: 18),
                                        const SizedBox(width: 8),
                                        const Text('Popular'),
                                    ],
                                ),
                            ),
                        ],
                    ),
                ],
            ),
            body: Column(
                children: [
                    // 搜索栏
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                                hintText: 'Search rooms...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                        _searchController.clear();
                                        _search();
                                    },
                                ),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                            ),
                            onSubmitted: (_) => _search(),
                        ),
                    ),
                    
                    // 房间列表
                    Expanded(
                        child: Consumer<RoomProvider>(
                            builder: (context, provider, _) {
                                if (provider.isLoading && provider.rooms.isEmpty) {
                                    return const Center(
                                        child: CircularProgressIndicator(),
                                    );
                                }
                                
                                if (provider.rooms.isEmpty) {
                                    return Center(
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                Icon(
                                                    Icons.meeting_room,
                                                    size: 80,
                                                    color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                    'No rooms available',
                                                    style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 16,
                                                    ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                    'Create a new room!',
                                                    style: TextStyle(
                                                        color: Colors.grey[400],
                                                        fontSize: 14,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    );
                                }
                                
                                return RefreshIndicator(
                                    onRefresh: _refresh,
                                    child: ListView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        itemCount: provider.rooms.length,
                                        itemBuilder: (context, index) {
                                            return _RoomCard(
                                                room: provider.rooms[index],
                                                onTap: () => _joinRoom(provider.rooms[index]),
                                            );
                                        },
                                    ),
                                );
                            },
                        ),
                    ),
                ],
            ),
        );
    }

    Future<void> _joinRoom(Room room) async {
        final provider = Provider.of<RoomProvider>(context, listen: false);
        
        // 如果是私密房间，需要输入密码
        if (!room.isPublic) {
            final password = await showDialog<String>(
                context: context,
                builder: (context) => _PasswordDialog(roomName: room.name),
            );
            
            if (password == null) return;
            
            final success = await provider.joinRoom(room.id, password: password);
            if (success && mounted) {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RoomPage(roomId: room.id),
                    ),
                );
            }
        } else {
            final success = await provider.joinRoom(room.id);
            if (success && mounted) {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RoomPage(roomId: room.id),
                    ),
                );
            }
        }
        
        if (provider.error != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(provider.error!),
                    backgroundColor: Colors.red,
                ),
            );
        }
    }
}

/**
 * 房间卡片组件
 */
class _RoomCard extends StatelessWidget {
    final Room room;
    final VoidCallback onTap;

    const _RoomCard({
        required this.room,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                        children: [
                            // 房间封面
                            Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                ),
                                child: room.cover.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                            room.cover,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                                Icons.mic,
                                                size: 30,
                                                color: Color(0xFF6C5CE7),
                                            ),
                                        ),
                                    )
                                    : const Icon(
                                        Icons.mic,
                                        size: 30,
                                        color: Color(0xFF6C5CE7),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            
                            // 房间信息
                            Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        Row(
                                            children: [
                                                Expanded(
                                                    child: Text(
                                                        room.name,
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                    ),
                                                ),
                                                if (!room.isPublic)
                                                    const Icon(
                                                        Icons.lock,
                                                        size: 16,
                                                        color: Colors.grey,
                                                    ),
                                            ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            'by ${room.ownerNickname ?? 'Unknown'}',
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 13,
                                            ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                            children: [
                                                _InfoChip(
                                                    icon: Icons.people,
                                                    label: '${room.currentCount}',
                                                ),
                                                const SizedBox(width: 12),
                                                _InfoChip(
                                                    icon: Icons.mic,
                                                    label: '${room.maxSeats}',
                                                ),
                                            ],
                                        ),
                                    ],
                                ),
                            ),
                            
                            // 进入按钮
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7),
                                    borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Text(
                                    'Join',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                    ),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}

/**
 * 信息标签
 */
class _InfoChip extends StatelessWidget {
    final IconData icon;
    final String label;

    const _InfoChip({
        required this.icon,
        required this.label,
    });

    @override
    Widget build(BuildContext context) {
        return Row(
            children: [
                Icon(
                    icon,
                    size: 14,
                    color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                    label,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                    ),
                ),
            ],
        );
    }
}

/**
 * 密码输入对话框
 */
class _PasswordDialog extends StatefulWidget {
    final String roomName;

    const _PasswordDialog({required this.roomName});

    @override
    State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
    final _passwordController = TextEditingController();

    @override
    void dispose() {
        _passwordController.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: Text('Enter Password for "${widget.roomName}"'),
            content: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                ),
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                ),
                ElevatedButton(
                    onPressed: () {
                        Navigator.of(context).pop(_passwordController.text);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                    ),
                    child: const Text('Join', style: TextStyle(color: Colors.white)),
                ),
            ],
        );
    }
}
