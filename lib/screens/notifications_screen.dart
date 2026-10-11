import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: StreamBuilder(
          stream: AppDataService.instance.notifications,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                  child: Text('Could not load notifications: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!.docs
                .map(AppNotification.fromDocument)
                .toList(growable: false);
            if (items.isEmpty) {
              return const Center(child: Text('No notifications yet.'));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: items
                  .map((notification) => AppCard(
                        color: notification.alert
                            ? AppColors.lightRed
                            : Colors.white,
                        borderColor: notification.alert
                            ? AppColors.red
                            : AppColors.border,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                notification.alert
                                    ? Icons.error
                                    : Icons.notifications,
                                color: notification.alert
                                    ? AppColors.red
                                    : AppColors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notification.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(notification.body,
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(notification.time,
                                      style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      );
}
