import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class MissingChildScreen extends StatelessWidget {
  const MissingChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missing Child Alert')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AppCard(
              color: AppColors.lightRed,
              borderColor: AppColors.red,
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: AppColors.red,
                    size: 44,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lost a child?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Save a report with the child's details and last-seen location. This does not contact nearby families or authorities.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Create Missing Child Alert',
              color: AppColors.red,
              icon: Icons.add_alert,
              onPressed: () => Navigator.pushNamed(context, '/child-details'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: AppDataService.instance.missingReports,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Could not load alerts: ${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reports = snapshot.data!.docs
                    .map(MissingReport.fromDocument)
                    .toList(growable: false);
                if (reports.isEmpty) return const Text('No reports yet.');
                return Column(
                  children: reports.map((report) {
                    final active = report.status == 'Active';
                    return AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.grey,
                            backgroundImage: report.photoUrl.isEmpty
                                ? null
                                : NetworkImage(report.photoUrl),
                            child: report.photoUrl.isEmpty
                                ? Icon(
                                    Icons.child_care,
                                    color: AppColors.muted,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${report.name} (${report.age})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Last seen: ${report.lastSeen}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: active ? AppColors.red : AppColors.green,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              report.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
