/**
 * 闪屏页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_page.dart';
import 'home_page.dart';

class SplashPage extends StatefulWidget {
    const SplashPage({super.key});

    @override
    State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<double> _fadeAnimation;
    late Animation<double> _scaleAnimation;

    @override
    void initState() {
        super.initState();
        
        _controller = AnimationController(
            duration: const Duration(milliseconds: 1500),
            vsync: this,
        );
        
        _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
            ),
        );
        
        _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
            ),
        );
        
        _controller.forward();
        _checkLogin();
    }

    Future<void> _checkLogin() async {
        await Future.delayed(const Duration(seconds: 2));
        
        if (!mounted) return;
        
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // 检查是否已注册
        final isRegistered = await userProvider.isRegistered();
        
        if (!mounted) return;
        
        if (!isRegistered) {
            // 首次使用，自动注册
            final success = await userProvider.register(silent: true);
            if (mounted) {
                if (success && userProvider.currentUser != null) {
                    // 注册成功，显示密码对话框
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const HomePage(),
                        ),
                    );
                    // 显示密码提示
                    _showPasswordDialog();
                } else {
                    // 注册失败，进入登录页
                    Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                }
            }
        } else {
            // 已有账号，自动登录
            final isLoggedIn = await userProvider.autoLogin();
            
            if (!mounted) return;
            
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (_) => isLoggedIn ? const HomePage() : const LoginPage(),
                ),
            );
        }
    }

    void _showPasswordDialog() {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // 延迟显示密码对话框
        Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
                showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                        title: const Row(
                            children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 10),
                                Text('注册成功'),
                            ],
                        ),
                        content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                const Text(
                                    '请牢记您的账号和密码，建议截图保存',
                                    style: TextStyle(color: Colors.orange),
                                ),
                                const SizedBox(height: 20),
                                _PasswordRow(label: '账号', value: userProvider.localAccount ?? ''),
                                const SizedBox(height: 10),
                                _PasswordRow(label: '密码', value: userProvider.password ?? ''),
                            ],
                        ),
                        actions: [
                            TextButton(
                                onPressed: () {
                                    Navigator.of(context).pop();
                                },
                                child: const Text('我已保存'),
                            ),
                        ],
                    ),
                );
            }
        });
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: Container(
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                            Color(0xFF6C5CE7),
                            Color(0xFF8B7CF7),
                            Color(0xFF6C5CE7),
                        ],
                    ),
                ),
                child: Center(
                    child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                            return Opacity(
                                opacity: _fadeAnimation.value,
                                child: Transform.scale(
                                    scale: _scaleAnimation.value,
                                    child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            // Logo
                                            Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(30),
                                                    boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.black.withOpacity(0.2),
                                                            blurRadius: 20,
                                                            offset: const Offset(0, 10),
                                                        ),
                                                    ],
                                                ),
                                                child: const Icon(
                                                    Icons.mic,
                                                    size: 60,
                                                    color: Color(0xFF6C5CE7),
                                                ),
                                            ),
                                            const SizedBox(height: 30),
                                            // App名称
                                            const Text(
                                                'HIU',
                                                style: TextStyle(
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 10,
                                                ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                                'Voice Room Social',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.white.withOpacity(0.9),
                                                    letterSpacing: 2,
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            );
                        },
                    ),
                ),
            ),
        );
    }
}

/**
 * 密码行组件
 */
class _PasswordRow extends StatelessWidget {
    final String label;
    final String value;

    const _PasswordRow({
        required this.label,
        required this.value,
    });

    @override
    Widget build(BuildContext context) {
        return Row(
            children: [
                SizedBox(
                    width: 50,
                    child: Text(
                        '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ),
                Expanded(
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                            children: [
                                Expanded(
                                    child: Text(
                                        value,
                                        style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 16,
                                        ),
                                    ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.copy, size: 18),
                                    onPressed: () {
                                        // 复制功能
                                    },
                                ),
                            ],
                        ),
                    ),
                ),
            ],
        );
    }
}
