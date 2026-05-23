import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Full-width rounded CTA — supports default dark or branded colors.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 52,
    this.borderRadius = 12,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.ctaBackground;
    final fg = foregroundColor ?? AppColors.ctaForeground;
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: fg);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.divider,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: style),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 20, color: fg),
            ],
          ],
        ),
      ),
    );
  }
}
