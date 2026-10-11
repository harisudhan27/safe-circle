import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscure;
  final bool readOnly;
  final int maxLines;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.label,
    this.icon,
    this.controller,
    this.obscure = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
          filled: true,
          fillColor: AppColors.grey,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.green, width: 1.5),
          ),
        ),
      ),
    );
  }
}
