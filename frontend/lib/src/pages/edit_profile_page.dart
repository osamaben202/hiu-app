/**
 * 编辑资料页面
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class EditProfilePage extends StatefulWidget {
    const EditProfilePage({super.key});

    @override
    State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
    final _nicknameController = TextEditingController();
    final _signatureController = TextEditingController();
    bool _isLoading = false;

    @override
    void initState() {
        super.initState();
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        _nicknameController.text = user?.nickname ?? '';
        _signatureController.text = user?.signature ?? '';
    }

    @override
    void dispose() {
        _nicknameController.dispose();
        _signatureController.dispose();
        super.dispose();
    }

    Future<void> _save() async {
        setState(() => _isLoading = true);

        final success = await Provider.of<UserProvider>(context, listen: false)
            .updateProfile(
                nickname: _nicknameController.text,
                signature: _signatureController.text,
            );

        setState(() => _isLoading = false);

        if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Edit Profile'),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        // 头像
                        Stack(
                            children: [
                                Consumer<UserProvider>(
                                    builder: (context, user, _) {
                                        return CircleAvatar(
                                            radius: 50,
                                            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                            child: Text(
                                                (user.currentUser?.nickname.isEmpty ?? true
                                                    ? user.currentUser?.account[0] ?? 'U'
                                                    : user.currentUser!.nickname[0]).toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6C5CE7),
                                                ),
                                            ),
                                        );
                                    },
                                ),
                                Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                            color: Color(0xFF6C5CE7),
                                            shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                        ),
                                    ),
                                ),
                            ],
                        ),
                        const SizedBox(height: 30),

                        // 昵称
                        TextField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                                labelText: 'Nickname',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                            ),
                        ),
                        const SizedBox(height: 16),

                        // 个性签名
                        TextField(
                            controller: _signatureController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                                labelText: 'Signature',
                                hintText: 'Tell something about yourself',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.edit_note),
                                alignLabelWithHint: true,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
