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
        final isLoggedIn = await userProvider.autoLogin();
        
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => isLoggedIn ? const HomePage() : const LoginPage(),
            ),
        );
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
