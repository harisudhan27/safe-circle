import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _inviteCode = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await AppDataService.instance.joinFamily(_inviteCode.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/family-safety',
        (route) => false,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join family: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a Family')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Enter the invite code shared by your family member. Your SafeCircle account will be connected to their family group.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Family invite code',
              icon: Icons.key,
              controller: _inviteCode,
              keyboardType: TextInputType.visiblePassword,
            ),
            AppButton(
              label: _joining ? 'Joining...' : 'Join Family',
              icon: Icons.group_add,
              onPressed: _joining ? null : _join,
            ),
          ],
        ),
      ),
    );
  }
}
