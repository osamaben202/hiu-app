/**
 * 排行榜页面
 */
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RankingsPage extends StatefulWidget {
    const RankingsPage({super.key});

    @override
    State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> with SingleTickerProviderStateMixin {
    late TabController _tabController;
    String _period = 'all';
    List<Map<String, dynamic>> _charmList = [];
    List<Map<String, dynamic>> _contributionList = [];
    bool _isLoading = true;

    @override
    void initState() {
        super.initState();
        _tabController = TabController(length: 2, vsync: this);
        _loadData();
    }

    @override
    void dispose() {
        _tabController.dispose();
        super.dispose();
    }

    Future<void> _loadData() async {
        setState(() => _isLoading = true);
        try {
            final api = ApiService();
            final charmResult = await api.getCharmRanking(period: _period);
            final contributionResult = await api.getContributionRanking(period: _period);
            if (mounted) {
                setState(() {
                    _charmList = charmResult;
                    _contributionList = contributionResult;
                    _isLoading = false;
                });
            }
        } catch (e) {
            debugPrint('Load rankings error: $e');
            if (mounted) {
                setState(() => _isLoading = false);
            }
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Rankings'),
                bottom: TabBar(
                    controller: _tabController,
                    tabs: const [
                        Tab(text: 'Charm', icon: Icon(Icons.favorite)),
                        Tab(text: 'Contribution', icon: Icon(Icons.star)),
                    ],
                ),
                actions: [
                    PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: (value) {
                            setState(() => _period = value);
                            _loadData();
                        },
                        itemBuilder: (context) => [
                            PopupMenuItem(value: 'all', child: Row(
                                children: [
                                    if (_period == 'all') const Icon(Icons.check, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('All Time'),
                                ],
                            )),
                            PopupMenuItem(value: 'month', child: Row(
                                children: [
                                    if (_period == 'month') const Icon(Icons.check, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('This Month'),
                                ],
                            )),
                            PopupMenuItem(value: 'week', child: Row(
                                children: [
                                    if (_period == 'week') const Icon(Icons.check, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('This Week'),
                                ],
                            )),
                            PopupMenuItem(value: 'day', child: Row(
                                children: [
                                    if (_period == 'day') const Icon(Icons.check, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Today'),
                                ],
                            )),
                        ],
                    ),
                ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                        _RankingList(
                            list: _charmList,
                            scoreLabel: 'Charm Score',
                            emptyMessage: 'No data available',
                        ),
                        _RankingList(
                            list: _contributionList,
                            scoreLabel: 'Contributed',
                            emptyMessage: 'No data available',
                        ),
                    ],
                ),
        );
    }
}

class _RankingList extends StatelessWidget {
    final List<Map<String, dynamic>> list;
    final String scoreLabel;
    final String emptyMessage;

    const _RankingList({
        required this.list,
        required this.scoreLabel,
        required this.emptyMessage,
    });

    @override
    Widget build(BuildContext context) {
        if (list.isEmpty) {
            return Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        Icon(Icons.emoji_events, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
                    ],
                ),
            );
        }

        return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                    final item = list[index];
                    final rank = item['rank'] as int;
                    final nickname = item['nickname'] ?? 'Unknown';
                    final avatar = item['avatar'] ?? '';
                    final score = item['charm_score'] ?? item['contribution_score'] ?? 0;

                    return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                            leading: _buildRankBadge(rank),
                            title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('$scoreLabel: $score'),
                            trailing: avatar.isNotEmpty
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(avatar),
                                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                )
                                : CircleAvatar(
                                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                    child: Text(nickname[0].toUpperCase(),
                                        style: const TextStyle(color: Color(0xFF6C5CE7))),
                                ),
                        ),
                    );
                },
            ),
        );
    }

    Widget _buildRankBadge(int rank) {
        Color bgColor;
        IconData? icon;

        if (rank == 1) {
            bgColor = const Color(0xFFFFD700); // Gold
            icon = Icons.emoji_events;
        } else if (rank == 2) {
            bgColor = const Color(0xFFC0C0C0); // Silver
            icon = Icons.emoji_events;
        } else if (rank == 3) {
            bgColor = const Color(0xFFCD7F32); // Bronze
            icon = Icons.emoji_events;
        } else {
            bgColor = Colors.grey[300]!;
            icon = null;
        }

        return CircleAvatar(
            backgroundColor: bgColor,
            radius: 24,
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 24)
                : Text(
                    '#$rank',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                    ),
                ),
        );
    }
}
