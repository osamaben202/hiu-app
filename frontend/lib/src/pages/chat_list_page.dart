/**
 * 聊天列表页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
    const ChatListPage({super.key});

    @override
    State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
    @override
    void initState() {
        super.initState();
        _refresh();
    }

    Future<void> _refresh() async {
        await Provider.of<ChatProvider>(context, listen: false).fetchConversations();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Messages'),
            ),
            body: Consumer<ChatProvider>(
                builder: (context, chatProvider, _) {
                    if (chatProvider.isLoading && chatProvider.conversations.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                    }

                    if (chatProvider.conversations.isEmpty) {
                        return Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(
                                        Icons.chat_bubble_outline,
                                        size: 80,
                                        color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                        'No conversations yet',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                        ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Start chatting with others!',
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
                            itemCount: chatProvider.conversations.length,
                            itemBuilder: (context, index) {
                                final conversation = chatProvider.conversations[index];
                                return _ConversationTile(
                                    conversation: conversation,
                                    onTap: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) => ChatPage(
                                                    oderId: conversation.oderId,
                                                    nickname: conversation.nickname,
                                                    avatar: conversation.avatar,
                                                    gender: conversation.gender,
                                                ),
                                            ),
                                        );
                                    },
                                );
                            },
                        ),
                    );
                },
            ),
        );
    }
}

/**
 * 会话项
 */
class _ConversationTile extends StatelessWidget {
    final dynamic conversation;
    final VoidCallback onTap;

    const _ConversationTile({
        required this.conversation,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        final unreadCount = conversation.unreadCount ?? 0;

        return ListTile(
            leading: Stack(
                children: [
                    CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                        child: Text(
                            conversation.nickname.isEmpty 
                                ? 'U' 
                                : conversation.nickname[0].toUpperCase(),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C5CE7),
                            ),
                        ),
                    ),
                    // 性别标记
                    Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                                color: conversation.gender == 'female' 
                                    ? Colors.pink 
                                    : (conversation.gender == 'male' ? Colors.blue : Colors.grey),
                                shape: BoxShape.circle,
                            ),
                            child: Icon(
                                conversation.gender == 'female' 
                                    ? Icons.female 
                                    : (conversation.gender == 'male' ? Icons.male : Icons.person),
                                size: 12,
                                color: Colors.white,
                            ),
                        ),
                    ),
                ],
            ),
            title: Text(
                conversation.nickname,
                style: TextStyle(
                    fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
            ),
            subtitle: Text(
                conversation.lastMessage?.content ?? 'No messages',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                ),
            ),
            trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    if (conversation.lastMessage != null)
                        Text(
                            _formatTime(conversation.lastMessage.createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                            ),
                        ),
                    const SizedBox(height: 4),
                    if (unreadCount > 0)
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7),
                                borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                ),
                            ),
                        ),
                ],
            ),
            onTap: onTap,
        );
    }

    String _formatTime(DateTime? time) {
        if (time == null) return '';
        
        final now = DateTime.now();
        final diff = now.difference(time);
        
        if (diff.inMinutes < 1) return 'Just now';
        if (diff.inHours < 1) return '${diff.inMinutes}m';
        if (diff.inDays < 1) return '${diff.inHours}h';
        if (diff.inDays < 7) return '${diff.inDays}d';
        return '${time.month}/${time.day}';
    }
}
