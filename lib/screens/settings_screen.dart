import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _preferences = {
    'pushNotifications': false,
    'shareLocation': false,
    'autoSafetyZone': false,
    'alertSound': false,
  };
  bool _loading = true;
  bool _sharingNow = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await AppDataService.instance.getUserProfile();
      final stored = profile['preferences'];
      if (stored is Map) {
        for (final key in _preferences.keys) {
          final value = stored[key];
          if (value is bool) _preferences[key] = value;
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load settings: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPreference(String key, bool value) async {
    final previous = _preferences[key]!;
    setState(() => _preferences[key] = value);
    var preferenceSaved = false;
    try {
      await AppDataService.instance.savePreference(key, value);
      preferenceSaved = true;
      if (key == 'shareLocation' && value) {
        await _publishCurrentLocation();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your current location was shared.')),
          );
        }
      }
    } catch (error) {
      Object? rollbackError;
      if (preferenceSaved) {
        try {
          await AppDataService.instance.savePreference(key, previous);
        } catch (restoreError) {
          rollbackError = restoreError;
        }
      }
      if (mounted) {
        setState(() => _preferences[key] = previous);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              rollbackError == null
                  ? 'Could not enable location sharing: $error'
                  : 'Could not enable location sharing: $error. '
                        'Could not restore the previous setting: $rollbackError',
            ),
          ),
        );
      }
    }
  }

  Future<void> _publishCurrentLocation() async {
    final result = await LocationService.getCurrent();
    final position = result.position;
    if (position == null) {
      throw StateError(result.error ?? 'Could not get your location.');
    }
    await AppDataService.instance.publishCurrentLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _shareLocationNow() async {
    setState(() => _sharingNow = true);
    try {
      await _publishCurrentLocation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your current location was shared.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share your location: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sharingNow = false);
    }
  }

  Widget _switch(
      String label, IconData icon, String key, bool enabled) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(width: 14),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Switch(
            value: _preferences[key]!,
            activeTrackColor: AppColors.green,
            onChanged: enabled ? (value) => _setPreference(key, value) : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _switch('Push notifications', Icons.notifications_none,
                        'pushNotifications', !_loading),
                    _switch('Share my location', Icons.location_on_outlined,
                        'shareLocation', !_loading),
                    if (_preferences['shareLocation']!)
                      AppButton(
                        label: _sharingNow
                            ? 'Sharing current location...'
                            : 'Share current location',
                        icon: Icons.my_location,
                        onPressed: _sharingNow ? null : _shareLocationNow,
                      ),
                    _switch('Auto safety zone', Icons.radar, 'autoSafetyZone',
                        !_loading),
                    _switch('Alert sound', Icons.volume_up_outlined,
                        'alertSound', !_loading),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Logout',
                      color: AppColors.red,
                      outlined: true,
                      icon: Icons.logout,
                      onPressed: () async {
                        try {
                          await AppDataService.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                                context, '/login', (r) => false);
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not log out: $error')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
      );
}
