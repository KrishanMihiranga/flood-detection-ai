import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Compact circular control (Airbnb-style back / close).
class AppRoundIconButton extends StatelessWidget {
  const AppRoundIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppColors.textPrimary),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}
