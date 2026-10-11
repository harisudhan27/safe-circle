import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/member_card.dart';
import '../widgets/member_map_pins.dart';

class MemberTrackingScreen extends StatefulWidget {
  const MemberTrackingScreen({super.key});

  @override
  State<MemberTrackingScreen> createState() => _MemberTrackingScreenState();
}

class _MemberTrackingScreenState extends State<MemberTrackingScreen> {
  Timer? _loadingTimer;
  Timer? _stayTimeTimer;
  bool _timedOut = false;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startLoadingTimeout();
    _stayTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _startLoadingTimeout() {
    _timedOut = false;
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _retry() {
    AppDataService.instance.refreshFamilyStreams();
    setState(_startLoadingTimeout);
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _stayTimeTimer?.cancel();
    super.dispose();
  }

  String _stayDuration(DateTime? startedAt) {
    if (startedAt == null) return 'Waiting for next GPS update';
    final elapsed = _now.difference(startedAt);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Less than 1 min';
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours hr';
    return '$hours hr $minutes min';
  }

  String _lastUpdated(DateTime? updatedAt) {
    if (updatedAt == null) return 'No GPS update yet';
    final elapsed = _now.difference(updatedAt);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) {
      final minutes = elapsed.inMinutes % 60;
      return minutes == 0
          ? '${elapsed.inHours} hr ago'
          : '${elapsed.inHours} hr $minutes min ago';
    }
    return '${elapsed.inDays} day(s) ago';
  }

  Widget _loadingOrTimeout(String message) {
    if (!_timedOut) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            AppButton(label: 'Retry', icon: Icons.refresh, onPressed: _retry),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member GPS Tracking')),
      body: StreamBuilder(
        stream: AppDataService.instance.family,
        builder: (context, familySnapshot) {
          if (familySnapshot.hasError) {
            _loadingTimer?.cancel();
            return Center(
              child: Text('Could not load family: ${familySnapshot.error}'),
            );
          }
          final familyId = familySnapshot.data?.id;
          if (!familySnapshot.hasData) {
            return _loadingOrTimeout(
              'Firebase has not responded. Check your connection and Firestore Rules, then retry.',
            );
          }
          if (familyId == null) {
            _loadingTimer?.cancel();
            return const Center(
              child: Text('Create a family to view locations.'),
            );
          }
          return StreamBuilder(
            stream: AppDataService.instance.familyMembers(familyId),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.hasError) {
                _loadingTimer?.cancel();
                return Center(
                  child: Text(
                    'Could not load locations: ${membersSnapshot.error}',
                  ),
                );
              }
              if (!membersSnapshot.hasData) {
                return _loadingOrTimeout(
                  'Firebase has not returned family members. Check your connection and Firestore Rules, then retry.',
                );
              }
              _loadingTimer?.cancel();
              final members = membersSnapshot.data!.docs
                  .map(Member.fromDocument)
                  .toList(growable: false);
              if (members.isEmpty) {
                return const Center(child: Text('No family members yet.'));
              }
              final locatedMembers = members
                  .where((member) => member.hasLocation)
                  .toList(growable: false);
              final pins = memberMapPins(locatedMembers);
              final mapCenter = locatedMembers.isEmpty
                  ? null
                  : LatLng(
                      locatedMembers.first.lat!,
                      locatedMembers.first.lng!,
                    );
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const AppCard(
                    child: Text(
                      'All family members who have shared a GPS location appear on this map. Nearby pins are spaced apart visually so they do not hide one another; the coordinates below are the actual GPS locations. GPS updates require Share my location and SafeCircle open.',
                    ),
                  ),
                  MapPlaceholder(
                    height: 260,
                    locateCurrent: false,
                    position: mapCenter,
                    pins: pins,
                    caption: locatedMembers.isEmpty
                        ? 'No family locations shared yet'
                        : '${locatedMembers.length} member${locatedMembers.length == 1 ? '' : 's'} on map',
                  ),
                  const Text(
                    'Family Members',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  for (final member in members) ...[
                    MemberCard(member: member),
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, color: AppColors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Time in current area: ${_stayDuration(member.stayStartedAt)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (member.hasLocation)
                      AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Actual GPS: ${member.lat!.toStringAsFixed(6)}, ${member.lng!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last update: ${_lastUpdated(member.locationUpdatedAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    member.locationUpdatedAt != null &&
                                        _now
                                                .difference(
                                                  member.locationUpdatedAt!,
                                                )
                                                .inMinutes >
                                            10
                                    ? AppColors.red
                                    : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 6),
                  AppButton(
                    label: 'Detect Tourist Area',
                    icon: Icons.travel_explore,
                    onPressed: () => Navigator.pushNamed(context, '/tourist'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
