import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter both email and password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';
      if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else if (e.code == 'user-not-found') {
        message = 'No account found for this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password. Please try again.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const SafeLogo(size: 90),
              const SizedBox(height: 32),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email',
                icon: Icons.email_outlined,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              AppTextField(
                label: 'Password',
                icon: Icons.lock_outline,
                controller: _passwordController,
                obscure: true,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: AppColors.green),
                  ),
                ),
              ),
              AppButton(
                label: _isLoading ? 'Signing in...' : 'Login',
                onPressed: _isLoading ? null : _login,
              ),
              const SizedBox(height: 16),
              const Text('or', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              AppButton(
                label: 'Continue with Google',
                icon: Icons.g_mobiledata,
                color: AppColors.red,
                outlined: true,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: 'Continue with Facebook',
                icon: Icons.facebook,
                color: AppColors.blue,
                outlined: true,
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/home'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text(
                      'Sign Up',
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
