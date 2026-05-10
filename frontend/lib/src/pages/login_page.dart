/**
 * 登录/注册页面
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
    bool _isLogin = true; // true: 登录, false: 注册
    bool _obscurePassword = true;

    @override
    void dispose() {
        _accountController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

    Future<void> _submit() async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        if (_isLogin) {
            // 登录
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
        } else {
            // 注册
            _showRegisterDialog();
        }
    }

    Future<void> _showRegisterDialog() async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // 显示注册对话框
        final result = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => const RegisterDialog(),
        );
        
        if (result == true && mounted) {
            // 检查是否有密码需要显示
            if (userProvider.password != null) {
                _showPasswordDialog(userProvider.password!);
            } else {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage()),
                );
            }
        }
    }

    void _showPasswordDialog(String password) {
        showDialog(
            context: context,
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
                        _PasswordRow(label: '账号', value: Provider.of<UserProvider>(context, listen: false).currentUser?.account ?? ''),
                        const SizedBox(height: 10),
                        _PasswordRow(label: '密码', value: password),
                    ],
                ),
                actions: [
                    TextButton(
                        onPressed: () {
                            Navigator.of(context).pop();
                            Provider.of<UserProvider>(context, listen: false).clearPassword();
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const HomePage()),
                            );
                        },
                        child: const Text('我已保存'),
                    ),
                ],
            ),
        );
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
                                                // 切换按钮
                                                Row(
                                                    children: [
                                                        Expanded(
                                                            child: GestureDetector(
                                                                onTap: () => setState(() => _isLogin = true),
                                                                child: Container(
                                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                                    decoration: BoxDecoration(
                                                                        color: _isLogin 
                                                                            ? const Color(0xFF6C5CE7) 
                                                                            : Colors.grey[200],
                                                                        borderRadius: const BorderRadius.horizontal(
                                                                            left: Radius.circular(10),
                                                                        ),
                                                                    ),
                                                                    child: Text(
                                                                        '登录',
                                                                        textAlign: TextAlign.center,
                                                                        style: TextStyle(
                                                                            color: _isLogin ? Colors.white : Colors.grey,
                                                                            fontWeight: FontWeight.bold,
                                                                        ),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                        Expanded(
                                                            child: GestureDetector(
                                                                onTap: () => setState(() => _isLogin = false),
                                                                child: Container(
                                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                                    decoration: BoxDecoration(
                                                                        color: !_isLogin 
                                                                            ? const Color(0xFF6C5CE7) 
                                                                            : Colors.grey[200],
                                                                        borderRadius: const BorderRadius.horizontal(
                                                                            right: Radius.circular(10),
                                                                        ),
                                                                    ),
                                                                    child: Text(
                                                                        '注册',
                                                                        textAlign: TextAlign.center,
                                                                        style: TextStyle(
                                                                            color: !_isLogin ? Colors.white : Colors.grey,
                                                                            fontWeight: FontWeight.bold,
                                                                        ),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ],
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
                                                                    : Text(
                                                                        _isLogin ? '登录' : '注册新账号',
                                                                        style: const TextStyle(
                                                                            fontSize: 16,
                                                                            color: Colors.white,
                                                                        ),
                                                                    ),
                                                            ),
                                                        );
                                                    },
                                                ),
                                                
                                                if (!_isLogin) ...[
                                                    const SizedBox(height: 15),
                                                    Text(
                                                        '注册后将自动生成账号密码',
                                                        style: TextStyle(
                                                            color: Colors.grey[600],
                                                            fontSize: 12,
                                                        ),
                                                    ),
                                                ],
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
 * 注册对话框
 */
class RegisterDialog extends StatefulWidget {
    const RegisterDialog({super.key});

    @override
    State<RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
    bool _isLoading = false;

    Future<void> _register() async {
        setState(() => _isLoading = true);
        
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final success = await userProvider.register();
        
        if (mounted) {
            Navigator.of(context).pop(success);
        }
    }

    @override
    Widget build(BuildContext context) {
        return AlertDialog(
            title: const Text('创建新账号'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const Icon(
                        Icons.add_circle_outline,
                        size: 60,
                        color: Color(0xFF6C5CE7),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                        '系统将自动为您生成账号和密码',
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                        '请妥善保管您的账号信息',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                        ),
                    ),
                ],
            ),
            actions: [
                TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                ),
                ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                            ),
                        )
                        : const Text('确认注册'),
                ),
            ],
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
