import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../data/app_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';

class MissingChildReportScreen extends StatefulWidget {
  const MissingChildReportScreen({super.key});

  @override
  State<MissingChildReportScreen> createState() =>
      _MissingChildReportScreenState();
}

class _MissingChildReportScreenState extends State<MissingChildReportScreen> {
  bool _submitted = false;
  bool _submitting = false;
  String? _submitError;
  Map<String, dynamic> _report = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) _report = arguments;
  }

  String _d(String key) {
    final value = _report[key];
    return value is String && value.isNotEmpty ? value : 'Not provided';
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await AppDataService.instance.submitMissingReport(_report);
      if (mounted) setState(() => _submitted = true);
    } catch (error) {
      if (mounted) {
        final message =
            error is FirebaseException && error.code == 'object-not-found'
            ? 'Firebase Storage could not find the uploaded photo. Check that '
                  'Storage is enabled for project safecircle-e1236, the bucket '
                  'safecircle-e1236.firebasestorage.app exists, and Storage '
                  'rules are deployed. Then try submitting again.'
            : 'Could not submit report: $error';
        setState(() => _submitError = message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: AppColors.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Missing Child Report')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_submitted)
              const AppCard(
                color: AppColors.lightRed,
                borderColor: AppColors.red,
                child: Column(
                  children: [
                    Icon(Icons.campaign, color: AppColors.red, size: 46),
                    SizedBox(height: 6),
                    Text(
                      'Alert Status: ACTIVE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.red,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Nearby families and authorities have been notified.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  _row('Name', _d('name')),
                  _row('Age', _d('age')),
                  _row('Description', _d('description')),
                  if (_report['photoBytes'] is Uint8List) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _report['photoBytes'] as Uint8List,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ] else
                    _row('Photo', 'Not provided'),
                  _row('Last seen', _d('lastSeen')),
                  _row('Time', _d('time')),
                ],
              ),
            ),
            if (_submitError != null)
              AppCard(
                color: AppColors.lightRed,
                borderColor: AppColors.red,
                child: Text(
                  _submitError!,
                  style: const TextStyle(color: AppColors.text),
                ),
              ),
            const SizedBox(height: 6),
            if (!_submitted)
              AppButton(
                label: _submitting ? 'Submitting...' : 'Submit Report',
                color: AppColors.red,
                icon: Icons.send,
                onPressed: _submitting ? null : _submit,
              )
            else
              AppButton(
                label: 'Back to Alerts',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/missing-child',
                  ModalRoute.withName('/home'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
