/**
 * 聊天页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/user_provider.dart';
import '../models/message.dart';

class ChatPage extends StatefulWidget {
    final String oderId;
    final String nickname;
    final String avatar;
    final String gender;

    const ChatPage({
        super.key,
        required this.oderId,
        required this.nickname,
        required this.avatar,
        required this.gender,
    });

    @override
    State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
    final _messageController = TextEditingController();
    final _scrollController = ScrollController();
    List<PrivateMessage> _messages = [];

    @override
    void initState() {
        super.initState();
        _loadMessages();
    }

    @override
    void dispose() {
        _messageController.dispose();
        _scrollController.dispose();
        super.dispose();
    }

    Future<void> _loadMessages() async {
        final messages = await Provider.of<ChatProvider>(context, listen: false)
            .fetchMessages(widget.oderId);
        setState(() {
            _messages = messages;
        });
    }

    Future<void> _sendMessage() async {
        if (_messageController.text.isEmpty) return;

        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final content = _messageController.text;
        _messageController.clear();

        final message = await chatProvider.sendMessage(
            receiverId: widget.oderId,
            type: 'text',
            content: content,
        );

        if (message != null) {
            setState(() {
                _messages.add(message);
            });
            _scrollToBottom();

            // 更新余额
            final balance = userProvider.currentUser!.coinBalance - message.costCoins;
            userProvider.updateCoinBalance(balance);
        }
    }

    void _scrollToBottom() {
        Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
                _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                );
            }
        });
    }

    @override
    Widget build(BuildContext context) {
        final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
        final isMaleToFemale = currentUser?.gender == 'male' && widget.gender == 'female';

        return Scaffold(
            appBar: AppBar(
                title: Row(
                    children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                                widget.nickname[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                            ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        widget.nickname,
                                        style: const TextStyle(fontSize: 16),
                                    ),
                                    if (isMaleToFemale)
                                        Text(
                                            'This chat costs coins',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.white.withOpacity(0.7),
                                            ),
                                        ),
                                ],
                            ),
                        ),
                    ],
                ),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.videocam),
                        onPressed: () {
                            // TODO: 发起视频通话
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Video call coming soon')),
                            );
                        },
                    ),
                ],
            ),
            body: Column(
                children: [
                    // 消息列表
                    Expanded(
                        child: _messages.isEmpty
                            ? Center(
                                child: Text(
                                    'Start a conversation!',
                                    style: TextStyle(color: Colors.grey[400]),
                                ),
                            )
                            : RefreshIndicator(
                                onRefresh: _loadMessages,
                                child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        final isMe = message.senderId == currentUser?.id;
                                        return _MessageBubble(
                                            message: message,
                                            isMe: isMe,
                                        );
                                    },
                                ),
                            ),
                    ),

                    // 费用提示
                    if (isMaleToFemale)
                        Consumer<UserProvider>(
                            builder: (context, user, _) {
                                return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    color: Colors.amber.withOpacity(0.1),
                                    child: Row(
                                        children: [
                                            const Icon(Icons.info_outline, 
                                                size: 16, color: Colors.amber),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(
                                                    'Cost: ${user.currentUser?.textPrice.toInt() ?? 1} coins/message | Balance: ${user.currentUser?.coinBalance.toInt() ?? 0}',
                                                    style: const TextStyle(fontSize: 12),
                                                ),
                                            ),
                                        ],
                                    ),
                                );
                            },
                        ),

                    // 输入框
                    Container(
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
                                        icon: const Icon(Icons.image),
                                        color: const Color(0xFF6C5CE7),
                                        onPressed: () {
                                            // TODO: 发送图片
                                        },
                                    ),
                                    Expanded(
                                        child: TextField(
                                            controller: _messageController,
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
                                            onSubmitted: (_) => _sendMessage(),
                                        ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                        icon: const Icon(Icons.send),
                                        color: const Color(0xFF6C5CE7),
                                        onPressed: _sendMessage,
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
 * 消息气泡
 */
class _MessageBubble extends StatelessWidget {
    final PrivateMessage message;
    final bool isMe;

    const _MessageBubble({
        required this.message,
        required this.isMe,
    });

    @override
    Widget build(BuildContext context) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                    if (!isMe) ...[
                        CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                            child: Text(
                                (message.senderNickname ?? 'U')[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6C5CE7),
                                ),
                            ),
                        ),
                        const SizedBox(width: 8),
                    ],
                    Flexible(
                        child: Container(
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                            ),
                            decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF6C5CE7) : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        message.content,
                                        style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black,
                                        ),
                                    ),
                                    if (message.costCoins > 0 && isMe)
                                        Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                                '-${message.costCoins.toInt()}',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white.withOpacity(0.7),
                                                ),
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
