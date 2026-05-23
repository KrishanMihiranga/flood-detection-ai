import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Stronger blur + translucent fill (“glass”) over scrolled content underneath.
class FrostedBottomNav extends StatelessWidget {
  const FrostedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.map_outlined, 'Map'),
    _NavItem(Icons.person_outline_rounded, 'Profile'),
  ];

  static const Color _hairlineOuter = Color(0x73FFFFFF); // translucent white rim
  static const Color _hairlineInner = Color(0x2E000000); // faint inner edge

  /// Outer rounded-rect radius for the frosted glass capsule.
  static const double _pillRadius = 30;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Wider horizontal inset now that only three tabs sit in the pill.
    final sideInset = (w * 0.14).clamp(44.0, 72.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(sideInset, 0, sideInset, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_pillRadius),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_pillRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.52),
                  Colors.white.withValues(alpha: 0.28),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _GlassEdgePainter(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      _NavButton(
                        item: _items[i],
                        selected: i == currentIndex,
                        onTap: () => onSelect(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light hairline shimmer on outer edge (readable on light & blurred bg).
class _GlassEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      const Radius.circular(FrostedBottomNav._pillRadius - 1),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = FrostedBottomNav._hairlineOuter,
    );
    canvas.drawRRect(
      r.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = FrostedBottomNav._hairlineInner,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: selected
                      ? AppColors.ctaBackground
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.92),
                      fontSize: 10,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.85),
                          blurRadius: 3,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
