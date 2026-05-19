/**
 * 房间列表页面
 */
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:hiu_app/src/services/socket_service.dart';
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
    String? _selectedTag;
    // Using global SocketService

    // 标签列表
    static const List<Map<String, dynamic>> _roomTags = [
        {'id': null, 'name': 'All'},
        {'id': 'chat', 'name': 'Chat'},
        {'id': 'music', 'name': 'Music'},
        {'id': 'game', 'name': 'Gaming'},
        {'id': 'dating', 'name': 'Dating'},
        {'id': 'study', 'name': 'Study'},
        {'id': 'asr', 'name': 'ASR'},
    ];

    @override
    void initState() {
        super.initState();
        _initSocketListener();
        WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<RoomProvider>(context, listen: false).fetchRooms();
        });
    }
    
    @override
    void didChangeDependencies() {
        super.didChangeDependencies();
        // 每次页面重新可见时刷新房间列表（解决关闭房间后仍在列表的问题）
        Provider.of<RoomProvider>(context, listen: false).fetchRooms();
    }



    void _onRoomUpdate(dynamic data) {
        debugPrint('Room update: $data');
        if (mounted) {
            Provider.of<RoomProvider>(context, listen: false).fetchRooms();
        }
    }

    void _initSocketListener() {
        final api = ApiService();
        final token = api.token;
        if (token != null) {
            SocketService().init(token);
            SocketService().on('room_update', _onRoomUpdate);
            SocketService().on('room_closed', _onRoomUpdate);
            SocketService().on('room_deleted', _onRoomUpdate);
        }
    }

    @override
    void dispose() {
        
        if (mounted) { SocketService().off('room_update', _onRoomUpdate); SocketService().off('room_closed', _onRoomUpdate); SocketService().off('room_deleted', _onRoomUpdate); }
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

    void _filterByTag(String? tag) {
        setState(() => _selectedTag = tag);
        // TODO: 实现标签筛选（后端需支持）
        _search();
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
                    
                    // 标签筛选
                    SizedBox(
                        height: 40,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _roomTags.length,
                            itemBuilder: (context, index) {
                                final tag = _roomTags[index];
                                final isSelected = _selectedTag == tag['id'];
                                return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                        label: Text(tag['name']),
                                        selected: isSelected,
                                        onSelected: (_) => _filterByTag(tag['id']),
                                        selectedColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                        checkmarkColor: const Color(0xFF6C5CE7),
                                        labelStyle: TextStyle(
                                            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[700],
                                        ),
                                    ),
                                );
                            },
                        ),
                    ),
                    const SizedBox(height: 8),
                    
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
                ).then((_) {
                    // 从房间返回后刷新列表
                    if (mounted) {
                        Provider.of<RoomProvider>(context, listen: false).fetchRooms();
                    }
                });
            }
        } else {
            final success = await provider.joinRoom(room.id);
            if (success && mounted) {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => RoomPage(roomId: room.id),
                    ),
                ).then((_) {
                    if (mounted) {
                        Provider.of<RoomProvider>(context, listen: false).fetchRooms();
                    }
                });
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
                                                if (room.tags.isNotEmpty) ...[
                                                    const SizedBox(width: 4),
                                                    _buildTagChip(room.tags),
                                                ],
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

    Widget _buildTagChip(String tag) {
        Color chipColor;
        switch (tag) {
            case 'music':
                chipColor = Colors.pink;
                break;
            case 'game':
                chipColor = Colors.green;
                break;
            case 'dating':
                chipColor = Colors.red;
                break;
            case 'study':
                chipColor = Colors.blue;
                break;
            case 'asr':
                chipColor = Colors.orange;
                break;
            default:
                chipColor = Colors.purple;
        }
        
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: chipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                tag.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    color: chipColor,
                    fontWeight: FontWeight.bold,
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
                Icon(icon, size: 14, color: Colors.grey),
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
