import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AppDataService.instance.getUserProfile();
      if (!mounted) return;
      _name.text = profile['displayName'] as String? ?? '';
      _email.text = profile['email'] as String? ?? '';
      _phone.text = profile['phone'] as String? ?? '';
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await AppDataService.instance.saveUserProfile(
        displayName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save profile: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.camera_alt, size: 36, color: AppColors.green),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
                label: 'Full name',
                icon: Icons.person_outline,
                controller: _name),
            AppTextField(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _email,
                readOnly: true,
                keyboardType: TextInputType.emailAddress),
            AppTextField(
                label: 'Phone',
                icon: Icons.phone_outlined,
                controller: _phone,
                keyboardType: TextInputType.phone),
            AppButton(
              label: _saving ? 'Saving...' : 'Save Changes',
              onPressed: _saving ? null : _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
