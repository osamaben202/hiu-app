/**
 * 好友页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/friend_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class FriendsPage extends StatefulWidget {
    const FriendsPage({super.key});

    @override
    State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
    late TabController _tabController;
    final _searchController = TextEditingController();

    @override
    void initState() {
        super.initState();
        _tabController = TabController(length: 3, vsync: this);
        _loadData();
    }

    @override
    void dispose() {
        _tabController.dispose();
        _searchController.dispose();
        super.dispose();
    }

    Future<void> _loadData() async {
        final provider = Provider.of<FriendProvider>(context, listen: false);
        await provider.loadFriends();
        await provider.loadPendingRequests();
    }

    void _showUserSearchDialog() {
        showDialog(
            context: context,
            builder: (context) => _UserSearchDialog(
                onUserSelected: (user) => _showUserProfileCard(user),
            ),
        );
    }

    void _showUserProfileCard(dynamic user) {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _UserProfileCard(user: user),
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Friends'),
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                actions: [
                    IconButton(
                        icon: const Icon(Icons.person_add),
                        onPressed: _showUserSearchDialog,
                    ),
                ],
                bottom: TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: const [
                        Tab(text: 'Friends'),
                        Tab(text: 'Requests'),
                        Tab(text: 'Blocked'),
                    ],
                ),
            ),
            body: TabBarView(
                controller: _tabController,
                children: [
                    _FriendsList(onUserTap: _showUserProfileCard),
                    _PendingRequestsList(),
                    _BlockedList(),
                ],
            ),
        );
    }
}

class _FriendsList extends StatelessWidget {
    final Function(dynamic) onUserTap;

    const _FriendsList({required this.onUserTap});

    @override
    Widget build(BuildContext context) {
        return Consumer<FriendProvider>(
            builder: (context, provider, _) {
                if (provider.isLoading && provider.friends.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                }

                if (provider.friends.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                    'No friends yet',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'Search for users to add friends',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                ),
                            ],
                        ),
                    );
                }

                return RefreshIndicator(
                    onRefresh: () => provider.loadFriends(),
                    child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.friends.length,
                        itemBuilder: (context, index) {
                            final friend = provider.friends[index];
                            return _FriendCard(
                                friend: friend,
                                onTap: () => onUserTap(friend),
                                onDelete: () => provider.deleteFriend(friend.odId),
                            );
                        },
                    ),
                );
            },
        );
    }
}

class _FriendCard extends StatelessWidget {
    final dynamic friend;
    final VoidCallback onTap;
    final VoidCallback onDelete;

    const _FriendCard({
        required this.friend,
        required this.onTap,
        required this.onDelete,
    });

    @override
    Widget build(BuildContext context) {
        return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                    backgroundImage: friend.avatar.isNotEmpty
                        ? NetworkImage(friend.avatar) as ImageProvider
                        : null,
                    child: friend.avatar.isEmpty
                        ? Text(
                            (friend.nickname.isEmpty ? 'U' : friend.nickname[0]).toUpperCase(),
                            style: const TextStyle(color: Color(0xFF6C5CE7)),
                        )
                        : null,
                ),
                title: Text(friend.nickname.isEmpty ? friend.account : friend.nickname),
                subtitle: Text(friend.signature.isEmpty ? friend.account : friend.signature),
                trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showOptions(context),
                ),
                onTap: onTap,
            ),
        );
    }

    void _showOptions(BuildContext context) {
        showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ListTile(
                            leading: const Icon(Icons.chat),
                            title: const Text('Send Message'),
                            onTap: () {
                                Navigator.pop(context);
                                // TODO: Navigate to chat
                            },
                        ),
                        ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('View Profile'),
                            onTap: () {
                                Navigator.pop(context);
                                onTap();
                            },
                        ),
                        ListTile(
                            leading: const Icon(Icons.block, color: Colors.red),
                            title: const Text('Block User', style: TextStyle(color: Colors.red)),
                            onTap: () async {
                                Navigator.pop(context);
                                final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                        title: const Text('Block User'),
                                        content: const Text('Are you sure you want to block this user?'),
                                        actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                child: const Text('Block', style: TextStyle(color: Colors.white)),
                                            ),
                                        ],
                                    ),
                                );
                                if (confirmed == true) {
                                    await Provider.of<FriendProvider>(context, listen: false).blockUser(friend.odId);
                                }
                            },
                        ),
                        ListTile(
                            leading: const Icon(Icons.person_remove, color: Colors.red),
                            title: const Text('Remove Friend', style: TextStyle(color: Colors.red)),
                            onTap: () async {
                                Navigator.pop(context);
                                onDelete();
                            },
                        ),
                    ],
                ),
            ),
        );
    }
}

class _PendingRequestsList extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Consumer<FriendProvider>(
            builder: (context, provider, _) {
                if (provider.isLoading && provider.pendingRequests.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                }

                if (provider.pendingRequests.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                    'No pending requests',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                            ],
                        ),
                    );
                }

                return RefreshIndicator(
                    onRefresh: () => provider.loadPendingRequests(),
                    child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.pendingRequests.length,
                        itemBuilder: (context, index) {
                            final request = provider.pendingRequests[index];
                            return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                        backgroundImage: request.avatar.isNotEmpty
                                            ? NetworkImage(request.avatar) as ImageProvider
                                            : null,
                                        child: request.avatar.isEmpty
                                            ? Text(
                                                (request.nickname.isEmpty ? 'U' : request.nickname[0]).toUpperCase(),
                                                style: const TextStyle(color: Color(0xFF6C5CE7)),
                                            )
                                            : null,
                                    ),
                                    title: Text(request.nickname.isEmpty ? request.account : request.nickname),
                                    subtitle: Text('ID: ${request.account}'),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            IconButton(
                                                icon: const Icon(Icons.check, color: Colors.green),
                                                onPressed: () => provider.acceptRequest(request.id),
                                            ),
                                            IconButton(
                                                icon: const Icon(Icons.close, color: Colors.red),
                                                onPressed: () => provider.rejectRequest(request.id),
                                            ),
                                        ],
                                    ),
                                ),
                            );
                        },
                    ),
                );
            },
        );
    }
}

class _BlockedList extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Consumer<FriendProvider>(
            builder: (context, provider, _) {
                if (provider.isLoading && provider.blockedUsers.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                }

                if (provider.blockedUsers.isEmpty) {
                    return Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.block_outlined, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                    'No blocked users',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                ),
                            ],
                        ),
                    );
                }

                return RefreshIndicator(
                    onRefresh: () => provider.loadBlockedUsers(),
                    child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.blockedUsers.length,
                        itemBuilder: (context, index) {
                            final user = provider.blockedUsers[index];
                            return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: Colors.grey[300],
                                        backgroundImage: user.avatar.isNotEmpty
                                            ? NetworkImage(user.avatar) as ImageProvider
                                            : null,
                                        child: user.avatar.isEmpty
                                            ? Text(
                                                (user.nickname.isEmpty ? 'U' : user.nickname[0]).toUpperCase(),
                                                style: const TextStyle(color: Colors.grey),
                                            )
                                            : null,
                                    ),
                                    title: Text(user.nickname.isEmpty ? user.account : user.nickname),
                                    subtitle: const Text('Blocked'),
                                    trailing: TextButton(
                                        onPressed: () => provider.unblockUser(user.odId),
                                        child: const Text('Unblock'),
                                    ),
                                ),
                            );
                        },
                    ),
                );
            },
        );
    }
}

class _UserSearchDialog extends StatefulWidget {
    final Function(dynamic) onUserSelected;

    const _UserSearchDialog({required this.onUserSelected});

    @override
    State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
    final _accountController = TextEditingController();
    User? _searchedUser;
    bool _isLoading = false;
    String? _error;

    Future<void> _search() async {
        final account = _accountController.text.trim();
        if (account.isEmpty) return;

        setState(() {
            _isLoading = true;
            _error = null;
            _searchedUser = null;
        });

        try {
            final api = ApiService();
            final result = await api.searchUserByAccount(account);
            setState(() {
                _searchedUser = result;
                _isLoading = false;
            });
        } catch (e) {
            setState(() {
                _error = e.toString();
                _isLoading = false;
            });
        }
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('Search User by ID'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    TextField(
                        controller: _accountController,
                        decoration: const InputDecoration(
                            labelText: 'Account / ID',
                            hintText: 'Enter user account',
                            border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _search(),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                        const CircularProgressIndicator()
                    else if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red))
                    else if (_searchedUser != null)
                        _SearchResultCard(
                            user: _searchedUser!,
                            onTap: () {
                                Navigator.pop(context);
                                widget.onUserSelected(_searchedUser);
                            },
                        ),
                ],
            ),
            actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                ),
                ElevatedButton(
                    onPressed: _isLoading ? null : _search,
                    child: const Text('Search'),
                ),
            ],
        );
    }
}

class _SearchResultCard extends StatelessWidget {
    final User user;
    final VoidCallback onTap;

    const _SearchResultCard({required this.user, required this.onTap});

    @override
    Widget build(BuildContext context) {
        return Card(
            child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                    backgroundImage: user.avatar.isNotEmpty
                        ? NetworkImage(user.avatar) as ImageProvider
                        : null,
                    child: user.avatar.isEmpty
                        ? Text(
                            (user.nickname.isEmpty ? 'U' : user.nickname[0]).toUpperCase(),
                            style: const TextStyle(color: Color(0xFF6C5CE7)),
                        )
                        : null,
                ),
                title: Text(user.nickname.isEmpty ? user.account : user.nickname),
                subtitle: Text('ID: ${user.account}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: onTap,
            ),
        );
    }
}

class _UserProfileCard extends StatelessWidget {
    final dynamic user;

    const _UserProfileCard({required this.user});

    @override
    Widget build(BuildContext context) {
        final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
        final isSelf = user.odId == currentUser?.id;

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
                                                await provider.sendFriendRequest(user.odId);
                                                if (context.mounted) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Friend request sent')),
                                                    );
                                                }
                                            },
                                        ),
                                        _ActionButton(
                                            icon: Icons.chat,
                                            label: 'Message',
                                            onTap: () {
                                                Navigator.pop(context);
                                                // TODO: Navigate to chat
                                            },
                                        ),
                                        _ActionButton(
                                            icon: Icons.block,
                                            label: 'Block',
                                            color: Colors.red,
                                            onTap: () async {
                                                final confirmed = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                        title: const Text('Block User'),
                                                        content: const Text('Are you sure?'),
                                                        actions: [
                                                            TextButton(
                                                                onPressed: () => Navigator.pop(context, false),
                                                                child: const Text('Cancel'),
                                                            ),
                                                            ElevatedButton(
                                                                onPressed: () => Navigator.pop(context, true),
                                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                                child: const Text('Block', style: TextStyle(color: Colors.white)),
                                                            ),
                                                        ],
                                                    ),
                                                );
                                                if (confirmed == true) {
                                                    await Provider.of<FriendProvider>(context, listen: false).blockUser(user.odId);
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
