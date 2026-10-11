import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class CrowdLevelScreen extends StatelessWidget {
  const CrowdLevelScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Crowd Level')),
        body: SafeArea(
          child: StreamBuilder(
            stream: AppDataService.instance.crowdLevels,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('Could not load crowd data: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              final data = docs.isEmpty ? null : docs.first.data();
              final percent = (data?['percent'] as num?)?.toInt();
              final area = data?['locationName'] as String?;
              final color = percent == null
                  ? AppColors.muted
                  : percent >= 70
                      ? AppColors.red
                      : percent >= 40
                          ? AppColors.orange
                          : AppColors.green;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (percent == null)
                    const AppCard(
                      child: Text(
                        'No crowd data is available yet. A trusted data source must publish records to Firestore before crowd levels can be shown.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    AppCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(area ?? 'Area name unavailable',
                              style: const TextStyle(color: AppColors.muted)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: CircularProgressIndicator(
                                    value: percent.clamp(0, 100) / 100,
                                    strokeWidth: 12,
                                    backgroundColor: AppColors.grey,
                                    color: color,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('$percent%',
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800)),
                                    Text(
                                        percent >= 70
                                            ? 'High'
                                            : percent >= 40
                                                ? 'Medium'
                                                : 'Low',
                                        style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Row(
                    children: [
                      Expanded(
                          child: _Legend('Low', '0-39%', AppColors.green)),
                      SizedBox(width: 10),
                      Expanded(
                          child:
                              _Legend('Medium', '40-69%', AppColors.orange)),
                      SizedBox(width: 10),
                      Expanded(child: _Legend('High', '70%+', AppColors.red)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AppButton(
                    label: 'View Safety Zone',
                    icon: Icons.radar,
                    onPressed: () => Navigator.pushNamed(context, '/safety-zone'),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

class _Legend extends StatelessWidget {
  final String label;
  final String range;
  final Color color;
  const _Legend(this.label, this.range, this.color);

  @override
  Widget build(BuildContext context) => AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          CircleAvatar(radius: 6, backgroundColor: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(range,
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      );
}
