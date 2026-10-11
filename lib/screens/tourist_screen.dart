import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/bottom_nav.dart';

class TouristScreen extends StatefulWidget {
  const TouristScreen({super.key});

  @override
  State<TouristScreen> createState() => _TouristScreenState();
}

class _TouristScreenState extends State<TouristScreen>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<bool>? _preferenceSubscription;
  bool _loading = true;
  bool _startingLocationStream = false;
  bool _sharingEnabled = false;
  Position? _position;
  String? _locationError;
  Future<void> _pendingLocationWrite = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preferenceSubscription = AppDataService.instance.locationSharingPreference
        .listen(
          (enabled) {
            if (!mounted) return;
            setState(() {
              _sharingEnabled = enabled;
              _locationError = null;
            });
            if (enabled) {
              _startLocationSharing();
            } else {
              _stopLocationSharing();
              setState(() => _loading = false);
            }
          },
          onError: (Object error) {
            if (mounted) {
              setState(() {
                _locationError =
                    'Could not read location-sharing setting: $error';
                _loading = false;
              });
            }
          },
        );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_sharingEnabled) _startLocationSharing();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopLocationSharing();
    }
  }

  Future<void> _startLocationSharing() async {
    if (_locationSubscription != null || _startingLocationStream) return;
    _startingLocationStream = true;
    setState(() {
      _loading = true;
      _locationError = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Turn on Location in your device settings.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted.');
      }

      if (!mounted || !_sharingEnabled) return;
      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 25,
            ),
          ).listen(
            _onLocationChanged,
            onError: (Object error) {
              if (mounted) {
                setState(() {
                  _locationError = 'Location updates failed: $error';
                  _loading = false;
                });
              }
              _stopLocationSharing();
            },
          );
      if (mounted) {
        setState(() => _loading = false);
        unawaited(_publishCurrentLocation());
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _locationError = error.toString();
          _loading = false;
        });
      }
    } finally {
      _startingLocationStream = false;
    }
  }

  Future<void> _publishCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted || !_sharingEnabled) return;
      _onLocationChanged(position);
    } catch (error) {
      if (mounted && _sharingEnabled) {
        setState(
          () => _locationError = 'Could not get current GPS location: $error',
        );
      }
    }
  }

  void _onLocationChanged(Position position) {
    if (!mounted || !_sharingEnabled) return;
    setState(() {
      _position = position;
      _locationError = null;
    });
    _pendingLocationWrite = _pendingLocationWrite
        .then((_) async {
          if (!mounted || !_sharingEnabled) return;
          await AppDataService.instance.publishCurrentLocation(
            latitude: position.latitude,
            longitude: position.longitude,
          );
        })
        .catchError((Object error) {
          if (mounted) {
            setState(() => _locationError = 'Could not share location: $error');
          }
        });
  }

  void _stopLocationSharing() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _retryLocationSharing() {
    _stopLocationSharing();
    _startLocationSharing();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _preferenceSubscription?.cancel();
    _stopLocationSharing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tourist Area'),
      automaticallyImplyLeading: false,
    ),
    bottomNavigationBar: const AppBottomNav(index: 2),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        MapPlaceholder(
          height: 220,
          locateCurrent: false,
          position: _position == null
              ? null
              : LatLng(_position!.latitude, _position!.longitude),
          caption: _position == null ? null : 'Current GPS position',
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (!_sharingEnabled)
          AppCard(
            child: Column(
              children: [
                const Text(
                  'Turn on Share my location in Profile → Settings to share live updates while SafeCircle is open.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Open Settings',
                  icon: Icons.settings,
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            ),
          )
        else if (_locationError != null)
          AppCard(
            color: AppColors.lightRed,
            borderColor: AppColors.red,
            child: Column(
              children: [
                Text(_locationError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Retry location sharing',
                  icon: Icons.refresh,
                  onPressed: _retryLocationSharing,
                ),
              ],
            ),
          )
        else
          const AppCard(
            color: AppColors.lightGreen,
            borderColor: AppColors.green,
            child: Text(
              'Live location sharing is active while SafeCircle is open.',
              textAlign: TextAlign.center,
            ),
          ),
        if (_position != null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.place, color: AppColors.green),
                    SizedBox(width: 8),
                    Text(
                      'Current GPS position',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Latitude: ${_position!.latitude}'),
                Text('Longitude: ${_position!.longitude}'),
                Text('Accuracy: ${_position!.accuracy.toStringAsFixed(1)} m'),
                Text(
                  'Updated: ${TimeOfDay.fromDateTime(_position!.timestamp).format(context)}',
                ),
              ],
            ),
          ),
        const AppCard(
          child: Text(
            'Your current location is shared when you enable sharing. Live updates continue while the Tourist screen is open. Background sharing is off.',
          ),
        ),
      ],
    ),
  );
}
