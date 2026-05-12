/**
 * 首页 - 房间列表
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/room_provider.dart';
import '../providers/chat_provider.dart';
import 'login_page.dart';
import 'room_list_page.dart';
import 'friends_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';
import 'create_room_page.dart';

class HomePage extends StatefulWidget {
    const HomePage({super.key});

    @override
    State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
    int _currentIndex = 0;

    final List<Widget> _pages = [
        const RoomListPage(),
        const ChatListPage(),
        const FriendsPage(),
        const ProfilePage(),
    ];

    @override
    void initState() {
        super.initState();
        _loadData();
    }

    Future<void> _loadData() async {
        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        
        await Future.wait([
            roomProvider.fetchRooms(),
            chatProvider.fetchConversations(),
            chatProvider.fetchUnreadCount(),
        ]);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: IndexedStack(
                index: _currentIndex,
                children: _pages,
            ),
            bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                items: [
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                    ),
                    BottomNavigationBarItem(
                        icon: Consumer<ChatProvider>(
                            builder: (context, chat, child) {
                                return Badge(
                                    isLabelVisible: chat.unreadCount > 0,
                                    label: Text(
                                        chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                                        style: const TextStyle(fontSize: 10),
                                    ),
                                    child: const Icon(Icons.chat),
                                );
                            },
                        ),
                        label: 'Chat',
                    ),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.people),
                        label: 'Friends',
                    ),
                    const BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                    ),
                ],
            ),
            floatingActionButton: _currentIndex == 0
                ? FloatingActionButton(
                        onPressed: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CreateRoomPage()),
                            );
                        },
                        backgroundColor: const Color(0xFF6C5CE7),
                        child: const Icon(Icons.add, color: Colors.white),
                    )
                : null,
        );
    }
}
