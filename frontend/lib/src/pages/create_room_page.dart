/**
 * 创建房间页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import 'room_page.dart';

class CreateRoomPage extends StatefulWidget {
    const CreateRoomPage({super.key});

    @override
    State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
    final _nameController = TextEditingController();
    final _descriptionController = TextEditingController();
    bool _isPublic = true;
    final _passwordController = TextEditingController();
    String _selectedTag = 'chat';
    bool _isLoading = false;

    // 预设的房间标签
    static const List<Map<String, dynamic>> _roomTags = [
        {'id': 'chat', 'name': 'Chat', 'icon': Icons.chat},
        {'id': 'music', 'name': 'Music', 'icon': Icons.music_note},
        {'id': 'game', 'name': 'Gaming', 'icon': Icons.sports_esports},
        {'id': 'dating', 'name': 'Dating', 'icon': Icons.favorite},
        {'id': 'study', 'name': 'Study', 'icon': Icons.school},
        {'id': 'asr', 'name': 'ASR', 'icon': Icons.mic},
    ];

    @override
    void dispose() {
        _nameController.dispose();
        _descriptionController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Future<void> _createRoom() async {
        if (_nameController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter room name')),
            );
            return;
        }

        if (!_isPublic && _passwordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter room password')),
            );
            return;
        }

        setState(() => _isLoading = true);

        final provider = Provider.of<RoomProvider>(context, listen: false);
        final room = await provider.createRoom(
            name: _nameController.text,
            description: _descriptionController.text,
            isPublic: _isPublic,
            password: _isPublic ? null : _passwordController.text,
            tags: _selectedTag,
        );

        setState(() => _isLoading = false);

        if (room != null && mounted) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => RoomPage(roomId: room.id)),
            );
        } else if (provider.error != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.error!), backgroundColor: Colors.red),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Create Room'),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // 房间名称
                        TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                                labelText: 'Room Name',
                                hintText: 'Enter room name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.meeting_room),
                            ),
                        ),
                        const SizedBox(height: 20),

                        // 房间描述
                        TextField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'Enter room description',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                            ),
                        ),
                        const SizedBox(height: 20),

                        // 房间标签选择
                        const Text(
                            'Room Category',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _roomTags.map((tag) {
                                final isSelected = _selectedTag == tag['id'];
                                return GestureDetector(
                                    onTap: () {
                                        setState(() => _selectedTag = tag['id']);
                                    },
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF6C5CE7)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF6C5CE7)
                                                    : Colors.grey[300]!,
                                            ),
                                        ),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                Icon(
                                                    tag['icon'],
                                                    size: 20,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                    tag['name'],
                                                    style: TextStyle(
                                                        color: isSelected
                                                            ? Colors.white
                                                            : Colors.grey[700],
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                );
                            }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // 公开/私密
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                                children: [
                                    const Icon(Icons.lock, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                const Text(
                                                    'Private Room',
                                                    style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                    'Only invited users can join',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    Switch(
                                        value: !_isPublic,
                                        onChanged: (value) {
                                            setState(() {
                                                _isPublic = !value;
                                            });
                                        },
                                        activeColor: const Color(0xFF6C5CE7),
                                    ),
                                ],
                            ),
                        ),

                        // 密码输入
                        if (!_isPublic) ...[
                            const SizedBox(height: 16),
                            TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Room Password',
                                    hintText: 'Enter password',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.password),
                                ),
                            ),
                        ],
                        const SizedBox(height: 30),

                        // 创建按钮
                        SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                onPressed: _isLoading ? null : _createRoom,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C5CE7),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Create Room',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                        ),
                                    ),
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
