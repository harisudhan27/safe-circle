import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_text_field.dart';

class LastSeenScreen extends StatefulWidget {
  const LastSeenScreen({super.key});

  @override
  State<LastSeenScreen> createState() => _LastSeenScreenState();
}

class _LastSeenScreenState extends State<LastSeenScreen> {
  final _place = TextEditingController();
  final _time = TextEditingController();
  Map<String, dynamic> _report = {};
  bool _gettingLocation = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) _report = arguments;
  }

  @override
  void dispose() {
    _place.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Last Seen Location')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const MapPlaceholder(
              height: 200,
              caption: 'Map of current GPS location',
            ),
            AppTextField(
              label: 'Last seen place / landmark',
              icon: Icons.place_outlined,
              controller: _place,
            ),
            AppTextField(
              label: 'Time last seen (e.g. 4:15 PM)',
              icon: Icons.access_time,
              controller: _time,
            ),
            AppButton(
              label: 'Use my current location',
              icon: Icons.my_location,
              outlined: true,
              onPressed: _gettingLocation ? null : _useCurrentLocation,
            ),
            const SizedBox(height: 10),
            AppButton(label: 'Next', color: AppColors.red, onPressed: _next),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      _place.text =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _next() {
    final place = _place.text.trim();
    if (place.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter or locate the last-seen place.')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      '/missing-report',
      arguments: {..._report, 'lastSeen': place, 'time': _time.text.trim()},
    );
  }
}
