import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Yes, Logout', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await AppDataService.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not log out: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: const Text('Profile'), automaticallyImplyLeading: false),
        bottomNavigationBar: const AppBottomNav(index: 3),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.person, size: 54, color: AppColors.green),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder(
                    stream: AppDataService.instance.userProfile,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                            'Could not load profile: ${snapshot.error}');
                      }
                      final data = snapshot.data?.data();
                      final user = FirebaseAuth.instance.currentUser;
                      return Column(children: [
                        Text(
                          data?['displayName'] as String? ??
                              user?.displayName ??
                              'Your profile',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          data?['email'] as String? ?? user?.email ?? '',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ]);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _item(context, Icons.edit_outlined, 'Edit Profile', '/edit-profile'),
            _item(context, Icons.family_restroom, 'My Family', '/family-safety'),
            _item(context, Icons.notifications_none, 'Notifications',
                '/notifications'),
            _item(context, Icons.settings_outlined, 'Settings', '/settings'),
            AppCard(
              color: AppColors.lightRed,
              borderColor: AppColors.red,
              onTap: () => _logout(context),
              child: const Row(children: [
                Icon(Icons.logout, color: AppColors.red),
                SizedBox(width: 14),
                Text('Logout',
                    style: TextStyle(
                        color: AppColors.red, fontWeight: FontWeight.w700)),
              ]),
            ),
          ],
        ),
      );

  Widget _item(
      BuildContext context, IconData icon, String label, String route) {
    return AppCard(
      onTap: () => Navigator.pushNamed(context, route),
      child: Row(
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
