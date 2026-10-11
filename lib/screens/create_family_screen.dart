import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _name = TextEditingController();
  final _destination = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Family')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.family_restroom,
                    size: 54, color: AppColors.green),
              ),
              const SizedBox(height: 24),
              AppTextField(
                  label: 'Family name',
                  icon: Icons.home_outlined,
                  controller: _name),
              AppTextField(
                  label: 'Trip / destination',
                  icon: Icons.place_outlined,
                  controller: _destination),
              const Spacer(),
              AppButton(
                label: _saving ? 'Creating...' : 'Create & Share Invite Code',
                onPressed: _saving ? null : _createFamily,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createFamily() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a family name')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AppDataService.instance.createFamily(
        name: name,
        destination: _destination.text.trim(),
      );
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/family-safety',
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create family: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
