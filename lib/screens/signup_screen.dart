import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _loadingMessage = 'Creating account...';

  Future<void> _signUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all required fields.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters long.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) setState(() => _loadingMessage = 'Saving your profile...');
      await AppDataService.instance.saveUserProfile(
        displayName: fullName,
        email: email,
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed. Please try again.';
      if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'network-request-failed') {
        message =
            'Could not reach Firebase. Check your internet and try again.';
      } else {
        message =
            '${e.code}: ${e.message ?? 'Firebase authentication failed.'}';
      }
      _showMessage(message);
    } catch (e) {
      _showMessage('Unexpected error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            children: [
              const SafeLogo(size: 80),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Create account',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Full name',
                icon: Icons.person_outline,
                controller: _fullNameController,
              ),
              AppTextField(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              AppTextField(
                label: 'Phone number',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              AppTextField(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _passwordController,
                obscure: true,
              ),
              const SizedBox(height: 6),
              AppButton(
                label: _isLoading ? _loadingMessage : 'Sign Up',
                onPressed: _isLoading ? null : _signUp,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
