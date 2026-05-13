/**
 * 个人中心页面
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hiu_app/src/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
                                    _AccountCard(user: user),
                                    const SizedBox(height: 20),

                                    // 货币信息
                                    _BalanceCard(user: user),
                                    const SizedBox(height: 20),

                                    // 设置菜单
                                    _SettingsSection(user: user),
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

    const _AccountCard({required this.user});

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
                    CircleAvatar(
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
                    const SizedBox(height: 12),

                    // 昵称
                    Text(
                        user.nickname.isEmpty ? 'Not set' : user.nickname,
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

                    // 性别标签
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
                            // 金币
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
                            // 钻石
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
 * 设置菜单
 */
class _SettingsSection extends StatelessWidget {
    final dynamic user;

    const _SettingsSection({required this.user});

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

                            // 账号信息
                            _SettingsItem(
                                icon: Icons.badge,
                                iconColor: Colors.purple,
                                title: 'Account Info',
                                subtitle: 'View your account and password',
                                onTap: () => _showAccountInfoDialog(context),
                            ),

                            // 修改密码
                            _SettingsItem(
                                icon: Icons.lock,
                                iconColor: Colors.orange,
                                title: 'Change Password',
                                subtitle: 'Update your login password',
                                onTap: () => _showChangePasswordDialog(context),
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

    void _showAccountInfoDialog(BuildContext context) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final account = userProvider.localAccount ?? userProvider.currentUser?.account ?? '';
        final password = userProvider.password ?? '';

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Row(
                    children: [
                        Icon(Icons.info, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Account Info'),
                    ],
                ),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Row(
                                children: [
                                    Icon(Icons.warning, color: Colors.orange, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                        child: Text(
                                            'Please save your account and password!',
                                            style: TextStyle(color: Colors.orange, fontSize: 13),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Account', account),
                        const SizedBox(height: 8),
                        _buildInfoRow('Password', password.isNotEmpty ? password : '(not saved)'),
                        const SizedBox(height: 12),
                        Row(
                            children: [
                                Expanded(
                                    child: TextButton.icon(
                                        onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                text: 'Account: \$account\nPassword: \$password',
                                            ));
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Copied to clipboard')),
                                            );
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: const Text('Copy All'),
                                    ),
                                ),
                            ],
                        ),
                    ],
                ),
                actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                    ),
                ],
            ),
        );
    }

    Widget _buildInfoRow(String label, String value) {
        return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
                children: [
                    Text(
                        '\$label: ',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    Expanded(
                        child: Text(
                            value,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                        onPressed: () {
                            Clipboard.setData(ClipboardData(text: value));
                        },
                    ),
                ],
            ),
        );
    }

    void _showChangePasswordDialog(BuildContext context) {
        final oldPasswordController = TextEditingController();
        final newPasswordController = TextEditingController();
        final confirmPasswordController = TextEditingController();

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                title: const Text('Change Password'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        TextField(
                            controller: oldPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Current Password',
                                border: OutlineInputBorder(),
                            ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            controller: newPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(),
                            ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                            controller: confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Confirm New Password',
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
                            if (newPasswordController.text != confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passwords do not match')),
                                );
                                return;
                            }
                            if (newPasswordController.text.length < 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password must be at least 6 characters')),
                                );
                                return;
                            }
                            try {
                                final api = ApiService();
                                await api.changePassword(
                                    oldPassword: oldPasswordController.text,
                                    newPassword: newPasswordController.text,
                                );
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('local_password', newPasswordController.text);
                                
                                if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Password changed successfully!'),
                                            backgroundColor: Colors.green,
                                        ),
                                    );
                                }
                            } catch (e) {
                                if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text('Failed: \$e'),
                                            backgroundColor: Colors.red,
                                        ),
                                    );
                                }
                            }
                        },
                        child: const Text('Change'),
                    ),
                ],
            ),
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
                            // TODO: 实现绑定邮箱
                            Navigator.pop(context);
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
