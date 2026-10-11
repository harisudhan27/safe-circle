import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/app_data_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class SafetyZoneScreen extends StatefulWidget {
  const SafetyZoneScreen({super.key});

  @override
  State<SafetyZoneScreen> createState() => _SafetyZoneScreenState();
}

class _SafetyZoneScreenState extends State<SafetyZoneScreen> {
  Timer? _loadingTimer;
  Timer? _membersLoadingTimer;
  bool _timedOut = false;
  bool _membersTimedOut = false;
  LatLng? _selectedCenter;
  int? _selectedRadiusMeters;
  bool? _selectedEnabled;
  bool _gettingLocation = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _startLoadingTimeout();
  }

  void _startLoadingTimeout() {
    _timedOut = false;
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _retryLoading() {
    AppDataService.instance.refreshFamilyStreams();
    setState(() {
      _startLoadingTimeout();
      _startMembersLoadingTimeout();
    });
  }

  void _startMembersLoadingTimeout() {
    _membersTimedOut = false;
    _membersLoadingTimer?.cancel();
    _membersLoadingTimer = Timer(const Duration(seconds: 15), () {
      _membersLoadingTimer = null;
      if (mounted) setState(() => _membersTimedOut = true);
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _membersLoadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    final result = await LocationService.getCurrent();
    if (!mounted) return;
    final position = result.position;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Could not get your location.')),
      );
    } else {
      setState(() {
        _selectedCenter = LatLng(position.latitude, position.longitude);
        _selectedEnabled = true;
      });
    }
    setState(() => _gettingLocation = false);
  }

  Future<void> _save({
    required LatLng? center,
    required int radiusMeters,
    required bool enabled,
  }) async {
    setState(() => _saving = true);
    try {
      await AppDataService.instance.saveFamilySafeZone(
        latitude: center?.latitude,
        longitude: center?.longitude,
        radiusMeters: radiusMeters,
        enabled: enabled,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Family safe zone saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save safe zone: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _lastUpdated(DateTime? updatedAt) {
    if (updatedAt == null) return 'No GPS update yet';
    final elapsed = DateTime.now().difference(updatedAt);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} hr ago';
    return '${elapsed.inDays} day(s) ago';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Family Safe Zone')),
    body: SafeArea(
      child: StreamBuilder(
        stream: AppDataService.instance.family,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _loadingTimer?.cancel();
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Could not load family safe zone: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: _retryLoading,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            if (!_timedOut) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Family data has not loaded. Check your internet connection and confirm you are signed in and connected to a family.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      onPressed: _retryLoading,
                    ),
                  ],
                ),
              ),
            );
          }
          _loadingTimer?.cancel();
          final familyData = snapshot.data?.data();
          if (familyData == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Create or join a family before setting a shared safe zone.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final storedLat = (familyData['safeZoneLat'] as num?)?.toDouble();
          final storedLng = (familyData['safeZoneLng'] as num?)?.toDouble();
          final storedCenter = storedLat == null || storedLng == null
              ? null
              : LatLng(storedLat, storedLng);
          final center = _selectedCenter ?? storedCenter;
          final storedRadius =
              (familyData['safeZoneRadiusMeters'] as num?)?.toInt() ?? 500;
          final radius = _selectedRadiusMeters ?? storedRadius;
          final enabled =
              _selectedEnabled ?? familyData['safeZoneEnabled'] == true;
          final isOwner = AppDataService.instance.isCurrentUserFamilyOwner(
            familyData,
          );
          final familyId = snapshot.data?.id;
          if (familyId == null) {
            return const Center(
              child: Text('Family information is unavailable.'),
            );
          }

          return StreamBuilder(
            stream: AppDataService.instance.familyMembers(familyId),
            builder: (context, membersSnapshot) {
              if (membersSnapshot.hasError) {
                _membersLoadingTimer?.cancel();
                _membersLoadingTimer = null;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load family member records: ${membersSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Retry',
                          icon: Icons.refresh,
                          onPressed: _retryLoading,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (membersSnapshot.hasData) {
                _membersLoadingTimer?.cancel();
                _membersLoadingTimer = null;
              } else if (_membersTimedOut) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Family member records have not loaded. Check your connection and Firestore access. Member GPS cannot be shown until those records load.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Retry',
                          icon: Icons.refresh,
                          onPressed: _retryLoading,
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                if (_membersLoadingTimer == null) {
                  _startMembersLoadingTimeout();
                }
              }
              final members =
                  membersSnapshot.data?.docs
                      .map(Member.fromDocument)
                      .toList(growable: false) ??
                  const <Member>[];
              final locatedMembers = members
                  .where((member) => member.hasLocation)
                  .toList(growable: false);
              const locationFreshness = Duration(minutes: 10);
              final memberInsideZone = <String, bool?>{};
              for (final member in locatedMembers) {
                final updatedAt = member.locationUpdatedAt;
                final isFresh =
                    updatedAt != null &&
                    DateTime.now().difference(updatedAt) <= locationFreshness;
                if (!enabled || center == null || !isFresh) {
                  memberInsideZone[member.id] = null;
                  continue;
                }
                memberInsideZone[member.id] =
                    Geolocator.distanceBetween(
                      center.latitude,
                      center.longitude,
                      member.lat!,
                      member.lng!,
                    ) <=
                    radius;
              }
              final insideCount = memberInsideZone.values
                  .where((inside) => inside == true)
                  .length;
              final outsideCount = memberInsideZone.values
                  .where((inside) => inside == false)
                  .length;
              final unknownCount = memberInsideZone.values
                  .where((inside) => inside == null)
                  .length;
              const pinColors = [
                AppColors.red,
                AppColors.blue,
                AppColors.orange,
                AppColors.darkGreen,
              ];

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (center == null)
                    const AppCard(
                      child: Text(
                        'No safe-zone center has been set. The family owner can use their current location as the center.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    MapPlaceholder(
                      height: 250,
                      locateCurrent: false,
                      position: center,
                      circleRadiusMeters: enabled ? radius.toDouble() : null,
                      includePositionInFit: true,
                      pins: locatedMembers
                          .map(
                            (member) => MapPin(
                              position: LatLng(member.lat!, member.lng!),
                              label: member.name.isEmpty
                                  ? 'Member'
                                  : member.name,
                              color: memberInsideZone[member.id] == true
                                  ? AppColors.green
                                  : memberInsideZone[member.id] == false
                                  ? AppColors.red
                                  : pinColors[locatedMembers.indexOf(member) %
                                        pinColors.length],
                            ),
                          )
                          .toList(growable: false),
                      caption: locatedMembers.isEmpty
                          ? 'No shared member locations'
                          : enabled
                          ? '$insideCount inside • $outsideCount outside • $unknownCount unknown/stale'
                          : '${locatedMembers.length} locations • Safe zone not active',
                    ),
                  if (locatedMembers.isNotEmpty)
                    const AppCard(
                      child: Text(
                        'Green pins are inside, red pins are outside. Unknown/stale means the safe zone is off or that member’s last GPS update is over 10 minutes old.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  if (!membersSnapshot.hasData)
                    const AppCard(
                      child: Text(
                        'Loading family member locations...',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else if (members.isEmpty)
                    const AppCard(
                      child: Text(
                        'No family members are connected yet.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else ...[
                    const Text(
                      'Family member locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final member in members)
                      AppCard(
                        child: Row(
                          children: [
                            Icon(
                              member.hasLocation
                                  ? Icons.location_on
                                  : Icons.location_off,
                              color: member.hasLocation
                                  ? AppColors.green
                                  : AppColors.muted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name.isEmpty
                                        ? 'Family member'
                                        : member.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    member.hasLocation
                                        ? 'GPS: ${member.lat!.toStringAsFixed(6)}, ${member.lng!.toStringAsFixed(6)}'
                                        : member.isConnected
                                        ? 'No GPS location shared — enable sharing and keep SafeCircle open'
                                        : 'Not connected to a SafeCircle account',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (member.hasLocation)
                                    Text(
                                      'Updated ${_lastUpdated(member.locationUpdatedAt)}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (member.hasLocation &&
                                      enabled &&
                                      center != null)
                                    Text(
                                      memberInsideZone[member.id] == null
                                          ? 'Zone status unknown — waiting for a fresh GPS update'
                                          : memberInsideZone[member.id]!
                                          ? 'Inside safe zone'
                                          : 'OUTSIDE safe zone',
                                      style: TextStyle(
                                        color:
                                            memberInsideZone[member.id] == true
                                            ? AppColors.green
                                            : memberInsideZone[member.id] ==
                                                  false
                                            ? AppColors.red
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (isOwner) ...[
                    AppButton(
                      label: _gettingLocation
                          ? 'Getting location...'
                          : 'Set Center to Current Location',
                      icon: Icons.my_location,
                      onPressed: _gettingLocation ? null : _useCurrentLocation,
                    ),
                    const SizedBox(height: 10),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Radius: $radius m',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Slider(
                            value: radius.toDouble().clamp(100, 2000),
                            min: 100,
                            max: 2000,
                            divisions: 19,
                            label: '$radius m',
                            activeColor: AppColors.green,
                            onChanged: (value) => setState(() {
                              _selectedRadiusMeters = value.round();
                            }),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Enable safe-zone alerts'),
                            value: enabled,
                            activeTrackColor: AppColors.green,
                            onChanged: (value) =>
                                setState(() => _selectedEnabled = value),
                          ),
                        ],
                      ),
                    ),
                    AppButton(
                      label: _saving ? 'Saving...' : 'Save Safe Zone',
                      icon: Icons.save_outlined,
                      onPressed: _saving || (enabled && center == null)
                          ? null
                          : () => _save(
                              center: center,
                              radiusMeters: radius,
                              enabled: enabled,
                            ),
                    ),
                  ] else
                    const AppCard(
                      child: Text(
                        'Only the family owner can set or change this boundary.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const AppCard(
                    child: Text(
                      'The family owner receives an in-app notification when a member crosses outside the boundary. Each member must enable Share my location and keep SafeCircle open for GPS updates. Background tracking and system push alerts are not enabled.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Monitor Family Members',
                    icon: Icons.visibility,
                    outlined: true,
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/family-safety',
                      (route) => false,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    ),
  );
}
