import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

class ChildDetailsScreen extends StatefulWidget {
  const ChildDetailsScreen({super.key});

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _desc = TextEditingController();
  final _imagePicker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoContentType;
  bool _pickingPhoto = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Child Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: AppColors.grey,
                    backgroundImage: _photoBytes == null
                        ? null
                        : MemoryImage(_photoBytes!),
                    child: _photoBytes == null
                        ? const Icon(
                            Icons.add_a_photo,
                            size: 42,
                            color: AppColors.muted,
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _photoBytes == null
                        ? 'Add a recent photo of the child'
                        : 'Child photo selected',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickingPhoto ? null : _pickPhoto,
                    icon: Icon(
                      _photoBytes == null ? Icons.photo_library : Icons.edit,
                    ),
                    label: Text(
                      _pickingPhoto
                          ? 'Loading photo...'
                          : _photoBytes == null
                          ? 'Choose Photo'
                          : 'Change Photo',
                    ),
                  ),
                  if (_photoBytes != null)
                    TextButton(
                      onPressed: () => setState(() {
                        _photoBytes = null;
                        _photoContentType = null;
                      }),
                      child: const Text('Remove photo'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
                label: "Child's name",
                icon: Icons.child_care,
                controller: _name),
            AppTextField(
                label: 'Age',
                icon: Icons.cake_outlined,
                controller: _age,
                keyboardType: TextInputType.number),
            AppTextField(
                label: 'Description (clothes, height, marks)',
                icon: Icons.description_outlined,
                controller: _desc,
                maxLines: 3),
            AppButton(
              label: 'Next',
              color: AppColors.red,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    final name = _name.text.trim();
    final age = _age.text.trim();
    if (name.isEmpty || age.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter the child's name and age.")),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      '/last-seen',
      arguments: {
        'name': name,
        'age': age,
        'description': _desc.text.trim(),
        'photo': '',
        'photoBytes': _photoBytes,
        'photoContentType': _photoContentType,
      },
    );
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoContentType = image.mimeType ?? 'image/jpeg';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not select photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }
}
