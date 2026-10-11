import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/member_card.dart';
import '../widgets/member_map_pins.dart';

class FamilySafetyScreen extends StatefulWidget {
  const FamilySafetyScreen({super.key});

  @override
  State<FamilySafetyScreen> createState() => _FamilySafetyScreenState();
}

class _FamilySafetyScreenState extends State<FamilySafetyScreen> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>?> _familyStream;
  Timer? _loadingTimer;
  bool _timedOut = false;
  bool _creatingInviteCode = false;
  bool _leavingFamily = false;

  @override
  void initState() {
    super.initState();
    _startFamilyLoad();
  }

  void _startFamilyLoad() {
    _familyStream = AppDataService.instance.family;
    _timedOut = false;
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _retry() {
    AppDataService.instance.refreshFamilyStreams();
    setState(_startFamilyLoad);
  }

  Future<void> _createInviteCode() async {
    setState(() => _creatingInviteCode = true);
    try {
      await AppDataService.instance.createFamilyInviteCode();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create invite code: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingInviteCode = false);
    }
  }

  Future<void> _leaveFamily() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave family?'),
        content: const Text(
          'You will stop sharing family locations and details. If you are '
          'the owner, ownership will move to the earliest-joined connected '
          'member. If no other connected member remains, the next person to '
          'join becomes the owner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Leave family',
              style: TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _leavingFamily = true);
    try {
      await AppDataService.instance.leaveFamily();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You left the family.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not leave family: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _leavingFamily = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Safety'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const AppBottomNav(index: 1),
      body: StreamBuilder(
        stream: _familyStream,
        builder: (context, familySnapshot) {
          if (familySnapshot.hasError) {
            _loadingTimer?.cancel();
            return _loadError('Could not load family: ${familySnapshot.error}');
          }
          if (!familySnapshot.hasData) {
            return _timedOut
                ? _loadError(
                    'Firebase has not responded. Check your internet connection and Firestore Rules, then retry.',
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            AppButton(
                              label: 'Create Family / Group',
                              icon: Icons.group_add,
                              onPressed: () => Navigator.pushNamed(
                                context,
                                '/create-family',
                              ),
                            ),
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Join a Family',
                              icon: Icons.key,
                              outlined: true,
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/join-family'),
                            ),
                          ],
                        ),
                      ),
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  );
          }
          final familyData = familySnapshot.data?.data();
          final familyId = familySnapshot.data?.id;
          if (familyData == null || familyId == null) {
            _loadingTimer?.cancel();
            return _emptyFamily(context);
          }
          return StreamBuilder(
            stream: AppDataService.instance.familyMembers(familyId),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.hasError) {
                _loadingTimer?.cancel();
                return Center(
                  child: Text(
                    'Could not load family members: ${membersSnapshot.error}',
                  ),
                );
              }
              if (!membersSnapshot.hasData) {
                return _timedOut
                    ? _loadError(
                        'Firebase has not returned the family members. Check your connection and Firestore Rules, then retry.',
                      )
                    : const Center(child: CircularProgressIndicator());
              }
              _loadingTimer?.cancel();
              final members = membersSnapshot.data!.docs
                  .map(Member.fromDocument)
                  .toList(growable: false);
              final locatedMembers = members
                  .where((member) => member.hasLocation)
                  .toList(growable: false);
              final mapCenter = locatedMembers.isEmpty
                  ? null
                  : LatLng(
                      locatedMembers.first.lat!,
                      locatedMembers.first.lng!,
                    );
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  MapPlaceholder(
                    height: 200,
                    locateCurrent: false,
                    position: mapCenter,
                    pins: memberMapPins(locatedMembers),
                    includePositionInFit: true,
                    caption: locatedMembers.isEmpty
                        ? 'No shared family locations yet'
                        : '${locatedMembers.length} member${locatedMembers.length == 1 ? '' : 's'} sharing location',
                  ),
                  AppButton(
                    label: 'Family Safe Zone',
                    icon: Icons.radar,
                    outlined: true,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/safety-zone'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    familyData['name'] as String? ?? 'Family',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if ((familyData['destination'] as String? ?? '').isNotEmpty)
                    Text(
                      familyData['destination'] as String,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  if ((familyData['inviteCode'] as String? ?? '').isNotEmpty)
                    AppCard(
                      color: AppColors.lightGreen,
                      borderColor: AppColors.green,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connect a family member',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Share this invite code. They can join with their own SafeCircle account.',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  familyData['inviteCode'] as String,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copy invite code',
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(
                                      text: familyData['inviteCode'] as String,
                                    ),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Invite code copied'),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if ((familyData['inviteCode'] as String? ?? '').isEmpty)
                    AppButton(
                      label: _creatingInviteCode
                          ? 'Creating invite code...'
                          : 'Create Family Invite Code',
                      icon: Icons.key,
                      onPressed: _creatingInviteCode ? null : _createInviteCode,
                    ),
                  const SizedBox(height: 10),
                  if (members.isEmpty)
                    const Text('No family members yet.')
                  else
                    ...members.map(
                      (member) => MemberCard(
                        member: member,
                        onTap: () =>
                            Navigator.pushNamed(context, '/member-tracking'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Family Alerts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _FamilyAlerts(familyId: familyId),
                  const SizedBox(height: 6),
                  AppButton(
                    label: 'Add a Member Profile',
                    icon: Icons.group_add,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/add-members'),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: 'View Shared Locations',
                    icon: Icons.gps_fixed,
                    outlined: true,
                    onPressed: () =>
                        Navigator.pushNamed(context, '/member-tracking'),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: _leavingFamily
                        ? 'Leaving family...'
                        : 'Leave Family',
                    icon: Icons.logout,
                    color: AppColors.red,
                    outlined: true,
                    onPressed: _leavingFamily ? null : _leaveFamily,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _loadError(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: AppColors.muted, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppButton(
            label: 'Create Family / Group',
            icon: Icons.group_add,
            onPressed: () => Navigator.pushNamed(context, '/create-family'),
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Join a Family',
            icon: Icons.key,
            outlined: true,
            onPressed: () => Navigator.pushNamed(context, '/join-family'),
          ),
          const SizedBox(height: 8),
          AppButton(label: 'Retry', onPressed: _retry),
        ],
      ),
    ),
  );

  Widget _emptyFamily(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const AppCard(
        child: Text(
          'You have not created or joined a family yet. Create a family to add members and share data.',
          textAlign: TextAlign.center,
        ),
      ),
      AppButton(
        label: 'Create Family',
        icon: Icons.group_add,
        onPressed: () => Navigator.pushNamed(context, '/create-family'),
      ),
      const SizedBox(height: 10),
      AppButton(
        label: 'Join a Family',
        icon: Icons.key,
        outlined: true,
        onPressed: () => Navigator.pushNamed(context, '/join-family'),
      ),
    ],
  );
}

class _FamilyAlerts extends StatelessWidget {
  final String familyId;

  const _FamilyAlerts({required this.familyId});

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: AppDataService.instance.familyNotifications(familyId),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return AppCard(
          child: Text('Could not load family alerts: ${snapshot.error}'),
        );
      }
      if (!snapshot.hasData) {
        return const AppCard(child: Center(child: CircularProgressIndicator()));
      }
      final alerts = snapshot.data!.docs
          .map(AppNotification.fromDocument)
          .toList(growable: false);
      if (alerts.isEmpty) {
        return const AppCard(child: Text('No family alerts yet.'));
      }
      return Column(
        children: alerts
            .map(
              (alert) => AppCard(
                color: alert.alert ? AppColors.lightRed : Colors.white,
                borderColor: alert.alert ? AppColors.red : AppColors.border,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alert.alert ? Icons.error : Icons.notifications,
                      color: alert.alert ? AppColors.red : AppColors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(alert.body),
                          Text(
                            alert.time,
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
            .toList(growable: false),
      );
    },
  );
}
