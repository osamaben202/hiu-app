/**
 * 登录页面 - 用于老用户登录或登录失败后重试
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
    const LoginPage({super.key});

    @override
    State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
    final _accountController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _obscurePassword = true;

    @override
    void initState() {
        super.initState();
        // 自动填充本地账号
        _loadLocalAccount();
    }

    Future<void> _loadLocalAccount() async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.hasLocalAccount();
        if (mounted && userProvider.localAccount != null) {
            setState(() {
                _accountController.text = userProvider.localAccount!;
            });
        }
    }

    @override
    void dispose() {
        _accountController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Future<void> _submit() async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        if (_accountController.text.isEmpty || _passwordController.text.isEmpty) {
            _showError('请输入账号和密码');
            return;
        }
        
        final success = await userProvider.login(
            _accountController.text,
            _passwordController.text,
        );
        
        if (success && mounted) {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomePage()),
            );
        } else if (mounted) {
            _showError(userProvider.error ?? '登录失败');
        }
    }

    void _showError(String message) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
            ),
        );
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
                        ],
                    ),
                ),
                child: SafeArea(
                    child: Center(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(30),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    // Logo
                                    Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: const Icon(
                                            Icons.mic,
                                            size: 50,
                                            color: Color(0xFF6C5CE7),
                                        ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                        'HIU',
                                        style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                        ),
                                    ),
                                    const SizedBox(height: 50),
                                    
                                    // 表单卡片
                                    Container(
                                        padding: const EdgeInsets.all(25),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black.withOpacity(0.1),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 10),
                                                ),
                                            ],
                                        ),
                                        child: Column(
                                            children: [
                                                const Text(
                                                    '登录账号',
                                                    style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                    ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                    '请使用您的账号和密码登录',
                                                    style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                    ),
                                                ),
                                                const SizedBox(height: 30),
                                                
                                                // 账号输入
                                                TextField(
                                                    controller: _accountController,
                                                    decoration: InputDecoration(
                                                        labelText: '账号',
                                                        hintText: '输入账号',
                                                        prefixIcon: const Icon(Icons.person),
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                        ),
                                                    ),
                                                ),
                                                const SizedBox(height: 20),
                                                
                                                // 密码输入
                                                TextField(
                                                    controller: _passwordController,
                                                    obscureText: _obscurePassword,
                                                    decoration: InputDecoration(
                                                        labelText: '密码',
                                                        hintText: '输入密码',
                                                        prefixIcon: const Icon(Icons.lock),
                                                        suffixIcon: IconButton(
                                                            icon: Icon(
                                                                _obscurePassword 
                                                                    ? Icons.visibility_off 
                                                                    : Icons.visibility,
                                                            ),
                                                            onPressed: () {
                                                                setState(() {
                                                                    _obscurePassword = !_obscurePassword;
                                                                });
                                                            },
                                                        ),
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(10),
                                                        ),
                                                    ),
                                                ),
                                                const SizedBox(height: 30),
                                                
                                                // 提交按钮
                                                Consumer<UserProvider>(
                                                    builder: (context, provider, _) {
                                                        return SizedBox(
                                                            width: double.infinity,
                                                            height: 50,
                                                            child: ElevatedButton(
                                                                onPressed: provider.isLoading ? null : _submit,
                                                                style: ElevatedButton.styleFrom(
                                                                    backgroundColor: const Color(0xFF6C5CE7),
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(10),
                                                                    ),
                                                                ),
                                                                child: provider.isLoading
                                                                    ? const CircularProgressIndicator(color: Colors.white)
                                                                    : const Text(
                                                                        '登录',
                                                                        style: TextStyle(
                                                                            fontSize: 16,
                                                                            color: Colors.white,
                                                                        ),
                                                                    ),
                                                            ),
                                                        );
                                                    },
                                                ),
                                                
                                                const SizedBox(height: 15),
                                                Text(
                                                    '后端不可用时，请使用首次注册时的账号密码',
                                                    style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                        ),
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
                                        Clipboard.setData(ClipboardData(text: value));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('已复制')),
                                        );
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
