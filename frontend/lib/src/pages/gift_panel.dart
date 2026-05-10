/**
 * 礼物面板
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../providers/user_provider.dart';
import '../models/gift.dart';

class GiftPanel extends StatefulWidget {
    final List<Map<String, String>> receivers; // 接收者列表

    const GiftPanel({super.key, required this.receivers});

    @override
    State<GiftPanel> createState() => _GiftPanelState();
}

class _GiftPanelState extends State<GiftPanel> {
    Gift? _selectedGift;
    int _count = 1;
    String? _selectedReceiver;

    @override
    void initState() {
        super.initState();
        if (widget.receivers.isNotEmpty) {
            _selectedReceiver = widget.receivers.first['id'];
        }
    }

    Future<void> _sendGift() async {
        if (_selectedGift == null || _selectedReceiver == null) return;

        final roomProvider = Provider.of<RoomProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        final result = await roomProvider.sendGift(
            giftId: _selectedGift!.id,
            receiverId: _selectedReceiver!,
            count: _count,
        );

        if (result != null && mounted) {
            // 更新余额
            final newBalance = double.tryParse(result['sender_coin_balance']?.toString() ?? '0') ?? 0;
            userProvider.updateCoinBalance(newBalance);

            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Gift sent! Cost: ${result['total_coins']} coins'),
                    backgroundColor: Colors.green,
                ),
            );
            Navigator.of(context).pop();
        } else if (roomProvider.error != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(roomProvider.error!),
                    backgroundColor: Colors.red,
                ),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
                children: [
                    // 标题栏
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                        ),
                        child: Row(
                            children: [
                                const Text(
                                    'Send Gift',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                                const Spacer(),
                                IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => Navigator.of(context).pop(),
                                ),
                            ],
                        ),
                    ),

                    // 选择接收者
                    if (widget.receivers.length > 1) ...[
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        'Send to:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                        height: 50,
                                        child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: widget.receivers.length,
                                            itemBuilder: (context, index) {
                                                final receiver = widget.receivers[index];
                                                final isSelected = receiver['id'] == _selectedReceiver;
                                                
                                                return Padding(
                                                    padding: const EdgeInsets.only(right: 8),
                                                    child: ChoiceChip(
                                                        label: Text(receiver['nickname'] ?? ''),
                                                        selected: isSelected,
                                                        onSelected: (selected) {
                                                            setState(() {
                                                                _selectedReceiver = receiver['id'];
                                                            });
                                                        },
                                                        selectedColor: const Color(0xFF6C5CE7),
                                                        labelStyle: TextStyle(
                                                            color: isSelected ? Colors.white : Colors.black,
                                                        ),
                                                    ),
                                                );
                                            },
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],

                    // 礼物列表
                    Expanded(
                        child: Consumer<RoomProvider>(
                            builder: (context, provider, _) {
                                if (provider.gifts.isEmpty) {
                                    return const Center(
                                        child: CircularProgressIndicator(),
                                    );
                                }

                                return GridView.builder(
                                    padding: const EdgeInsets.all(12),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                    ),
                                    itemCount: provider.gifts.length,
                                    itemBuilder: (context, index) {
                                        final gift = provider.gifts[index];
                                        final isSelected = _selectedGift?.id == gift.id;

                                        return GestureDetector(
                                            onTap: () {
                                                setState(() {
                                                    _selectedGift = gift;
                                                });
                                            },
                                            child: Container(
                                                decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(0xFF6C5CE7).withOpacity(0.1)
                                                        : Colors.grey[100],
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                        color: isSelected
                                                            ? const Color(0xFF6C5CE7)
                                                            : Colors.transparent,
                                                        width: 2,
                                                    ),
                                                ),
                                                child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                        // 礼物图标
                                                        Container(
                                                            width: 45,
                                                            height: 45,
                                                            decoration: BoxDecoration(
                                                                color: Colors.white,
                                                                shape: BoxShape.circle,
                                                                boxShadow: [
                                                                    BoxShadow(
                                                                        color: Colors.grey.withOpacity(0.2),
                                                                        blurRadius: 5,
                                                                    ),
                                                                ],
                                                            ),
                                                            child: Center(
                                                                child: Text(
                                                                    _getGiftEmoji(gift.name),
                                                                    style: const TextStyle(fontSize: 24),
                                                                ),
                                                            ),
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                            gift.name,
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.bold,
                                                            ),
                                                        ),
                                                        Text(
                                                            '${gift.price}',
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors.grey[600],
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ),
                                        );
                                    },
                                );
                            },
                        ),
                    ),

                    // 底部操作栏
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                                BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, -5),
                                ),
                            ],
                        ),
                        child: SafeArea(
                            child: Row(
                                children: [
                                    // 数量选择
                                    Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                            children: [
                                                IconButton(
                                                    icon: const Icon(Icons.remove),
                                                    onPressed: _count > 1
                                                        ? () => setState(() => _count--)
                                                        : null,
                                                ),
                                                Text(
                                                    '$_count',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                    ),
                                                ),
                                                IconButton(
                                                    icon: const Icon(Icons.add),
                                                    onPressed: () => setState(() => _count++),
                                                ),
                                            ],
                                        ),
                                    ),
                                    const SizedBox(width: 12),

                                    // 总价
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                                Text(
                                                    'Total: ${(_selectedGift?.price ?? 0) * _count}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                    ),
                                                ),
                                                Consumer<UserProvider>(
                                                    builder: (context, user, _) {
                                                        return Text(
                                                            'Balance: ${user.currentUser?.coinBalance.toInt() ?? 0}',
                                                            style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors.grey[600],
                                                            ),
                                                        );
                                                    },
                                                ),
                                            ],
                                        ),
                                    ),

                                    // 发送按钮
                                    ElevatedButton(
                                        onPressed: _selectedGift != null ? _sendGift : null,
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6C5CE7),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                            ),
                                        ),
                                        child: const Text(
                                            'Send',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        );
    }

    String _getGiftEmoji(String name) {
        switch (name.toLowerCase()) {
            case 'flower':
                return '🌸';
            case 'heart':
                return '❤️';
            case 'gift box':
                return '🎁';
            case 'trophy':
                return '🏆';
            case 'rocket':
                return '🚀';
            case 'crown':
                return '👑';
            default:
                return '🎁';
        }
    }
}
