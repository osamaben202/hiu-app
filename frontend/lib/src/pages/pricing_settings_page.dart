/**
 * 聊天定价设置页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class PricingSettingsPage extends StatefulWidget {
    const PricingSettingsPage({super.key});

    @override
    State<PricingSettingsPage> createState() => _PricingSettingsPageState();
}

class _PricingSettingsPageState extends State<PricingSettingsPage> {
    final _textPriceController = TextEditingController();
    final _imagePriceController = TextEditingController();
    final _videoPriceController = TextEditingController();
    bool _isLoading = false;

    @override
    void initState() {
        super.initState();
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        _textPriceController.text = user?.textPrice.toInt().toString() ?? '1';
        _imagePriceController.text = user?.imagePrice.toInt().toString() ?? '5';
        _videoPriceController.text = user?.videoPrice.toInt().toString() ?? '10';
    }

    @override
    void dispose() {
        _textPriceController.dispose();
        _imagePriceController.dispose();
        _videoPriceController.dispose();
        super.dispose();
    }

    Future<void> _save() async {
        setState(() => _isLoading = true);

        final success = await Provider.of<UserProvider>(context, listen: false)
            .updatePricing(
                textPrice: double.tryParse(_textPriceController.text),
                imagePrice: double.tryParse(_imagePriceController.text),
                videoPrice: double.tryParse(_videoPriceController.text),
            );

        setState(() => _isLoading = false);

        if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pricing updated'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Chat Pricing'),
                actions: [
                    TextButton(
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                ),
                            )
                            : const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text(
                            'Set your chat prices',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                            ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                            'Male users will pay these prices to chat with you',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                            ),
                        ),
                        const SizedBox(height: 30),

                        // 文字消息价格
                        _PriceInput(
                            controller: _textPriceController,
                            icon: Icons.chat_bubble,
                            label: 'Text Message',
                            subtitle: 'Price per text message',
                            iconColor: Colors.blue,
                        ),
                        const SizedBox(height: 20),

                        // 图片消息价格
                        _PriceInput(
                            controller: _imagePriceController,
                            icon: Icons.image,
                            label: 'Image Message',
                            subtitle: 'Price per image',
                            iconColor: Colors.green,
                        ),
                        const SizedBox(height: 20),

                        // 视频通话价格
                        _PriceInput(
                            controller: _videoPriceController,
                            icon: Icons.videocam,
                            label: 'Video Call',
                            subtitle: 'Price per minute',
                            iconColor: Colors.purple,
                        ),
                        const SizedBox(height: 40),

                        // 提示
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: const Row(
                                children: [
                                    Icon(Icons.info_outline, color: Colors.amber),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                            'You will receive diamonds equal to the coins paid by male users.',
                                            style: TextStyle(fontSize: 13),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}

/**
 * 价格输入组件
 */
class _PriceInput extends StatelessWidget {
    final TextEditingController controller;
    final IconData icon;
    final String label;
    final String subtitle;
    final Color iconColor;

    const _PriceInput({
        required this.controller,
        required this.icon,
        required this.label,
        required this.subtitle,
        required this.iconColor,
    });

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
                children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: iconColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(
                                    label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                    subtitle,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                    ),
                                ),
                            ],
                        ),
                    ),
                    SizedBox(
                        width: 80,
                        child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                ),
                                prefixText: '',
                                suffixText: '💰',
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
}
