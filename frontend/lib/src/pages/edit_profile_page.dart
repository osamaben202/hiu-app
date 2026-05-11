/**
 * 编辑资料页面
 */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class EditProfilePage extends StatefulWidget {
    const EditProfilePage({super.key});

    @override
    State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
    final _nicknameController = TextEditingController();
    final _signatureController = TextEditingController();
    bool _isLoading = false;
    String? _avatarUrl;
    String _selectedGender = 'unknown';

    @override
    void initState() {
        super.initState();
        final user = Provider.of<UserProvider>(context, listen: false).currentUser;
        _nicknameController.text = user?.nickname ?? '';
        _signatureController.text = user?.signature ?? '';
        _avatarUrl = user?.avatar ?? '';
        _selectedGender = user?.gender ?? 'unknown';
    }

    @override
    void dispose() {
        _nicknameController.dispose();
        _signatureController.dispose();
        super.dispose();
    }

    Future<void> _pickAvatar() async {
        try {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 80,
            );
            if (picked == null) return;

            setState(() => _isLoading = true);

            // Upload avatar to server
            final api = ApiService();
            final uploadedUrl = await api.uploadAvatar(File(picked.path));
            
            if (uploadedUrl != null) {
                // Update profile with new avatar
                final success = await Provider.of<UserProvider>(context, listen: false)
                    .updateProfile(avatar: uploadedUrl);
                
                if (success) {
                    setState(() => _avatarUrl = uploadedUrl);
                    if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Avatar updated'), backgroundColor: Colors.green),
                        );
                    }
                }
            }
        } catch (e) {
            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                );
            }
        } finally {
            if (mounted) setState(() => _isLoading = false);
        }
    }

    Future<void> _save() async {
        setState(() => _isLoading = true);

        final success = await Provider.of<UserProvider>(context, listen: false)
            .updateProfile(
                nickname: _nicknameController.text,
                signature: _signatureController.text,
                gender: _selectedGender,
            );

        setState(() => _isLoading = false);

        if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
        } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red),
            );
        }
    }

    @override
    Widget build(BuildContext context) {
        final user = Provider.of<UserProvider>(context).currentUser;
        final displayAvatar = _avatarUrl ?? user?.avatar ?? '';

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
                        // 头像 - 可点击上传
                        GestureDetector(
                            onTap: _isLoading ? null : _pickAvatar,
                            child: Stack(
                                children: [
                                    CircleAvatar(
                                        radius: 50,
                                        backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
                                        backgroundImage: displayAvatar.isNotEmpty 
                                            ? NetworkImage(displayAvatar) as ImageProvider
                                            : null,
                                        child: displayAvatar.isEmpty
                                            ? Text(
                                                (user?.nickname.isEmpty ?? true
                                                    ? user?.account[0] ?? 'U'
                                                    : user!.nickname[0]).toUpperCase(),
                                                style: const TextStyle(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6C5CE7),
                                                ),
                                            )
                                            : null,
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
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Tap to change avatar',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                        const SizedBox(height: 16),

                        // 性别选择
                        Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[400]!),
                                borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    const Text(
                                        'Gender',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                        ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                        children: [
                                            _GenderOption(
                                                label: 'Male',
                                                icon: Icons.male,
                                                isSelected: _selectedGender == 'male',
                                                onTap: () => setState(() => _selectedGender = 'male'),
                                            ),
                                            const SizedBox(width: 16),
                                            _GenderOption(
                                                label: 'Female',
                                                icon: Icons.female,
                                                isSelected: _selectedGender == 'female',
                                                onTap: () => setState(() => _selectedGender = 'female'),
                                            ),
                                            const SizedBox(width: 16),
                                            _GenderOption(
                                                label: 'Secret',
                                                icon: Icons.question_mark,
                                                isSelected: _selectedGender == 'unknown',
                                                onTap: () => setState(() => _selectedGender = 'unknown'),
                                            ),
                                        ],
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

class _GenderOption extends StatelessWidget {
    final String label;
    final IconData icon;
    final bool isSelected;
    final VoidCallback onTap;

    const _GenderOption({
        required this.label,
        required this.icon,
        required this.isSelected,
        required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
        return GestureDetector(
            onTap: onTap,
            child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey[300]!,
                    ),
                ),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                        Icon(
                            icon,
                            size: 18,
                            color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                            label,
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                        ),
                    ],
                ),
            ),
        );
    }
}
