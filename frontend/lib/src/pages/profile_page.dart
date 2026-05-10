/**
 * 个人中心页面
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'login_page.dart';
import 'edit_profile_page.dart';
import 'pricing_settings_page.dart';
import 'coin_distribution_page.dart';

class ProfilePage extends StatefulWidget {
    const ProfilePage({super.key});

    @override
    State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
    bool _obscurePassword = true;

    @override
    void initState() {
        super.initState();
        _refreshData();
    }

    Future<void> _refreshData() async {
        await Provider.of<UserProvider>(context, listen: false).refreshUser();
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Profile'),
                actions: [
                    IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const EditProfilePage(),
                                ),
                            );
                        },
                    ),
                ],
            ),
            body: Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                    final user = userProvider.currentUser;
                    if (user == null) {
                        return const Center(child: CircularProgressIndicator());
                    }

                    return RefreshIndicator(
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    // 账号信息卡片
                                    _AccountCard(user: user, userProvider: userProvider),
                                    const SizedBox(height: 12),

                                    // 密码卡片（始终显示）
                                    _PasswordCard(userProvider: userProvider, obscurePassword: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                                    const SizedBox(height: 12),

                                    // 货币信息
                                    _BalanceCard(user: user),
                                    const SizedBox(height: 12),

                                    // 个人介绍
                                    if (user.signature.isNotEmpty)
                                        _SignatureCard(signature: user.signature),
                                    if (user.signature.isNotEmpty)
                                        const SizedBox(height: 12),

                                    // 设置菜单
                                    _SettingsSection(user: user, userProvider: userProvider),
                                ],
                            ),
                        ),
                    );
                },
            ),
        );
    }
}

/**
 * 账号信息卡片
 */
class _AccountCard extends StatelessWidget {
    final dynamic user;
    final UserProvider userProvider;

    const _AccountCard({required this.user, required this.userProvider});

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C5CE7), Color(0xFF8B7CF7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                    ),
                ],
            ),
            child: Column(
                children: [
                    // 头像
                    GestureDetector(
                        onTap: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const EditProfilePage()),
                            );
                        },
                        child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                                (user.nickname.isEmpty ? user.account : user.nickname)[0].toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                ),
                            ),
                        ),
                    ),
                    const SizedBox(height: 12),

                    // 昵称
                    Text(
                        user.nickname.isEmpty ? 'Tap to set nickname' : user.nickname,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                        ),
                    ),
                    const SizedBox(height: 4),

                    // 账号
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(
                                'ID: ${user.account}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                                icon: const Icon(Icons.copy, size: 16),
                                color: Colors.white,
                                onPressed: () {
                                    Clipboard.setData(ClipboardData(text: user.account));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Account copied')),
                                    );
                                },
                            ),
                        ],
                    ),
                    const SizedBox(height: 8),

                    // 性别标签 + 修改按钮
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                    _getGenderLabel(user.gender),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                    ),
                                ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                                onTap: () => _showGenderDialog(context),
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                        'Change',
                                        style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        );
    }

    String _getGenderLabel(String gender) {
        switch (gender) {
            case 'male':
                return '👨 Male';
            case 'female':
                return '👩 Female';
            default:
                return '❓ Unknown';
        }
    }

    void _showGenderDialog(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Select Gender'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        ListTile(
                            leading: const Text('👨', style: TextStyle(fontSize: 24)),
                            title: const Text('Male'),
                            onTap: () async {
                                await userProvider.updateProfile(gender: 'male');
                                Navigator.pop(context);
                            },
                        ),
                        ListTile(
                            leading: const Text('👩', style: TextStyle(fontSize: 24)),
                            title: const Text('Female'),
                            onTap: () async {
                                await userProvider.updateProfile(gender: 'female');
                                Navigator.pop(context);
                            },
                        ),
                        ListTile(
                            leading: const Text('❓', style: TextStyle(fontSize: 24)),
                            title: const Text('Unknown'),
                            onTap: () async {
                                await userProvider.updateProfile(gender: 'unknown');
                                Navigator.pop(context);
                            },
                        ),
                    ],
                ),
            ),
        );
    }
}

/**
 * 密码卡片 - 始终显示账号和密码
 */
class _PasswordCard extends StatelessWidget {
    final UserProvider userProvider;
    final bool obscurePassword;
    final VoidCallback onToggle;

    const _PasswordCard({
        required this.userProvider,
        required this.obscurePassword,
        required this.onToggle,
    });

    @override
    Widget build(BuildContext context) {
        final account = userProvider.localAccount ?? '';
        final password = userProvider.localPassword ?? '';

        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        children: [
                            Icon(Icons.lock_outline, color: Colors.orange.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                                'Your Login Info',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade700,
                                ),
                            ),
                        ],
                    ),
                    const SizedBox(height: 12),
                    // 账号行
                    Row(
                        children: [
                            const SizedBox(
                                width: 70,
                                child: Text('Account:', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Expanded(
                                child: Text(
                                    account,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                                ),
                            ),
                            IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                    Clipboard.setData(ClipboardData(text: account));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Account copied')),
                                    );
                                },
                            ),
                        ],
                    ),
                    // 密码行
                    Row(
                        children: [
                            const SizedBox(
                                width: 70,
                                child: Text('Password:', style: TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Expanded(
                                child: Text(
                                    obscurePassword ? '••••••••' : password,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
                                ),
                            ),
                            IconButton(
                                icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off, size: 18),
                                onPressed: onToggle,
                            ),
                            IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () {
                                    Clipboard.setData(ClipboardData(text: password));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Password copied')),
                                    );
                                },
                            ),
                        ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '⚠️ Please save your account and password!',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    ),
                ],
            ),
        );
    }
}

/**
 * 余额卡片
 */
class _BalanceCard extends StatelessWidget {
    final dynamic user;

    const _BalanceCard({required this.user});

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                    ),
                ],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text(
                        'Balance',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                        ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                        children: [
                            Expanded(
                                child: _BalanceItem(
                                    icon: Icons.monetization_on,
                                    iconColor: Colors.amber,
                                    label: 'Coins',
                                    value: user.coinBalance.toInt().toString(),
                                ),
                            ),
                            Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey[300],
                            ),
                            Expanded(
                                child: _BalanceItem(
                                    icon: Icons.diamond,
                                    iconColor: Colors.lightBlue,
                                    label: 'Diamonds',
                                    value: user.diamondBalance.toInt().toString(),
                                ),
                            ),
                        ],
                    ),
                ],
            ),
        );
    }
}

/**
 * 余额项
 */
class _BalanceItem extends StatelessWidget {
    final IconData icon;
    final Color iconColor;
    final String label;
    final String value;

    const _BalanceItem({
        required this.icon,
        required this.iconColor,
        required this.label,
        required this.value,
    });

    @override
    Widget build(BuildContext context) {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            label,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                            ),
                        ),
                        Text(
                            value,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                            ),
                        ),
                    ],
                ),
            ],
        );
    }
}

/**
 * 个人介绍卡片
 */
class _SignatureCard extends StatelessWidget {
    final String signature;
    const _SignatureCard({required this.signature});

    @override
    Widget build(BuildContext context) {
        return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                    ),
                ],
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    const Text(
                        'About Me',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(signature, style: const TextStyle(fontSize: 15)),
                ],
            ),
        );
    }
}

/**
 * 设置菜单
 */
class _SettingsSection extends StatelessWidget {
    final dynamic user;
    final UserProvider userProvider;

    const _SettingsSection({required this.user, required this.userProvider});

    @override
    Widget build(BuildContext context) {
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                const Text(
                    'Settings',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                    ),
                ),
                const SizedBox(height: 12),
                Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                            BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                            ),
                        ],
                    ),
                    child: Column(
                        children: [
                            // 编辑资料
                            _SettingsItem(
                                icon: Icons.person,
                                iconColor: Colors.purple,
                                title: 'Edit Profile',
                                subtitle: 'Change avatar, nickname, signature',
                                onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => const EditProfilePage(),
                                        ),
                                    );
                                },
                            ),

                            // 异性聊天定价（仅女性显示）
                            if (user.gender == 'female')
                                _SettingsItem(
                                    icon: Icons.sell,
                                    iconColor: Colors.pink,
                                    title: 'Chat Pricing',
                                    subtitle: 'Set your chat prices',
                                    onTap: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) => const PricingSettingsPage(),
                                            ),
                                        );
                                    },
                                ),

                            // 代理分发金币
                            if (user.role == 'agent' || user.role == 'admin')
                                _SettingsItem(
                                    icon: Icons.send,
                                    iconColor: Colors.green,
                                    title: 'Distribute Coins',
                                    subtitle: 'Distribute coins to users',
                                    onTap: () {
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (_) => const CoinDistributionPage(),
                                            ),
                                        );
                                    },
                                ),

                            // 绑定邮箱
                            _SettingsItem(
                                icon: Icons.email,
                                iconColor: Colors.blue,
                                title: 'Bind Email',
                                subtitle: user.email ?? 'Not bound',
                                onTap: () => _showBindEmailDialog(context),
                            ),

                            // 退出登录
                            _SettingsItem(
                                icon: Icons.logout,
                                iconColor: Colors.red,
                                title: 'Logout',
                                subtitle: 'Sign out of your account',
                                onTap: () => _showLogoutDialog(context),
                            ),
                        ],
                    ),
                ),
            ],
        );
    }

    void _showBindEmailDialog(BuildContext context) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Bind Email'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                            ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                            ),
                        ),
                    ],
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () async {
                            try {
                                await userProvider.bindEmail(emailController.text, passwordController.text);
                                if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Email bound successfully')),
                                    );
                                }
                            } catch (e) {
                                if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                                    );
                                }
                            }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C5CE7),
                        ),
                        child: const Text('Bind', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
        );
    }

    void _showLogoutDialog(BuildContext context) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                        onPressed: () async {
                            await Provider.of<UserProvider>(context, listen: false).logout();
                            if (context.mounted) {
                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const LoginPage()),
                                    (route) => false,
                                );
                            }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                ],
            ),
        );
    }
}

/**
 * 设置项
 */
class _SettingsItem extends StatelessWidget {
    final IconData icon;
    final Color iconColor;
    final String title;
    final String subtitle;
    final VoidCallback onTap;

    const _SettingsItem({
        required this.icon,
        required this.iconColor,
        required this.title,
        required this.subtitle,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        return ListTile(
            leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
            ),
            title: Text(title),
            subtitle: Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
        );
    }
}
