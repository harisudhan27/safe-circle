import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.green,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ],
    );
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color, width: 1.5),
                  shape: shape),
              child: content,
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: shape),
              child: content,
            ),
    );
  }
}
