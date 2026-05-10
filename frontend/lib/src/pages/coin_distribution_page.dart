/**
 * 金币分发页面
 */
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CoinDistributionPage extends StatefulWidget {
    const CoinDistributionPage({super.key});

    @override
    State<CoinDistributionPage> createState() => _CoinDistributionPageState();
}

class _CoinDistributionPageState extends State<CoinDistributionPage> {
    final _accountController = TextEditingController();
    final _amountController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _isLoading = false;
    String? _error;

    @override
    void dispose() {
        _accountController.dispose();
        _amountController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Future<void> _distribute() async {
        if (_accountController.text.isEmpty || 
            _amountController.text.isEmpty || 
            _passwordController.text.isEmpty) {
            setState(() => _error = 'Please fill in all fields');
            return;
        }

        final amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) {
            setState(() => _error = 'Invalid amount');
            return;
        }

        setState(() {
            _isLoading = true;
            _error = null;
        });

        try {
            await ApiService().distributeCoins(
                account: _accountController.text,
                amount: amount,
                distributePassword: _passwordController.text,
            );

            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Coins distributed successfully!'),
                        backgroundColor: Colors.green,
                    ),
                );
                // 清空输入
                _accountController.clear();
                _amountController.clear();
                _passwordController.clear();
            }
        } catch (e) {
            setState(() => _error = e.toString());
        } finally {
            setState(() => _isLoading = false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Distribute Coins'),
            ),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // 说明
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: const Color(0xFF6C5CE7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                                children: [
                                    Icon(Icons.info_outline, color: Color(0xFF6C5CE7)),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Text(
                                            'Enter the user account and amount to distribute coins.',
                                            style: TextStyle(fontSize: 13),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        const SizedBox(height: 30),

                        // 用户账号
                        TextField(
                            controller: _accountController,
                            decoration: const InputDecoration(
                                labelText: 'User Account',
                                hintText: 'Enter user account (e.g. U100001)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                            ),
                        ),
                        const SizedBox(height: 16),

                        // 金币数量
                        TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Amount',
                                hintText: 'Enter coin amount',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.monetization_on, color: Colors.amber),
                            ),
                        ),
                        const SizedBox(height: 16),

                        // 分配密码
                        TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Distribution Password',
                                hintText: 'Enter your distribution password',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                            ),
                        ),
                        const SizedBox(height: 8),

                        // 错误信息
                        if (_error != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.red, fontSize: 13),
                                ),
                            ),
                        const SizedBox(height: 24),

                        // 分发按钮
                        SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                onPressed: _isLoading ? null : _distribute,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C5CE7),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        'Distribute',
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
