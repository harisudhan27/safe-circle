import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(index: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to SafeCircle',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Stay safe on your trip',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none, size: 28),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.lightGreen,
              borderColor: AppColors.green,
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    color: AppColors.green,
                    size: 34,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Safety status unavailable',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'Waiting for real location and crowd data.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _BigTile(
                    color: AppColors.green,
                    icon: Icons.family_restroom,
                    title: 'Family Safety',
                    subtitle: 'View family data',
                    onTap: () => Navigator.pushNamed(context, '/family-safety'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BigTile(
                    color: AppColors.red,
                    icon: Icons.warning_amber_rounded,
                    title: 'Missing Child',
                    subtitle: 'Report & alerts',
                    onTap: () => Navigator.pushNamed(context, '/missing-child'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SmallTile(
                    icon: Icons.travel_explore,
                    label: 'Tourist Safety',
                    onTap: () => Navigator.pushNamed(context, '/tourist'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallTile(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _RecentAlerts(),
          ],
        ),
      ),
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: AppDataService.instance.notifications,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Text('Could not load alerts: ${snapshot.error}');
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final alerts = snapshot.data!.docs
          .take(2)
          .map(AppNotification.fromDocument);
      if (alerts.isEmpty) return const Text('No recent alerts.');
      return Column(
        children: alerts
            .map(
              (notification) => AppCard(
                child: Row(
                  children: [
                    Icon(
                      notification.alert ? Icons.error : Icons.info_outline,
                      color: notification.alert
                          ? AppColors.red
                          : AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            notification.body,
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            notification.time,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class _BigTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _BigTile({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: color,
      borderColor: color,
      onTap: onTap,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 38),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Icon(icon, color: AppColors.green, size: 30),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
