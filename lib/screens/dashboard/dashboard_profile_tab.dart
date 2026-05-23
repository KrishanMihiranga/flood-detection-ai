import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/theme/app_colors.dart';
import '../admin/admin_broadcast_announcement_screen.dart';
import '../admin/admin_pending_reports_screen.dart';
import '../shelters/shelter_safe_route_hub_screen.dart';
import '../auth/email_auth_screen.dart';

/// Airbnb-style profile: hero header, overlapping avatar, soft cards on grey canvas.
/// Flood Guard AI copy + mock stats (no backend).
class DashboardProfileTab extends StatefulWidget {
  const DashboardProfileTab({super.key});

  @override
  State<DashboardProfileTab> createState() => _DashboardProfileTabState();
}

class _DashboardProfileTabState extends State<DashboardProfileTab> {
  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  /// Mock report counts for the current week (demo).
  static const List<int> _weekReports = [8, 14, 9, 11, 7, 10, 6];
  int _highlightIndex = 1; // “peak” day (Tue in reference)

  late final Future<bool> _adminFuture =
      AuthSessionRepository.isCurrentUserAdmin();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: AppColors.dashboardCanvas,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _ProfileHeader(textTheme: textTheme)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ReportsChartCard(
                  dayLabels: _dayLabels,
                  values: _weekReports,
                  highlightIndex: _highlightIndex,
                  onBarTap: (i) => setState(() => _highlightIndex = i),
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  onShelterTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShelterSafeRouteHubScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<bool>(
                  future: _adminFuture,
                  builder: (context, snap) {
                    final adminReady =
                        snap.connectionState == ConnectionState.done &&
                            snap.data == true;
                    if (!adminReady) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                      children: [
                        Material(
                          color: AppColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: AppColors.divider),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AdminPendingReportsScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.ctaBackground.withValues(
                                          alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.manage_accounts_rounded,
                                      color: AppColors.ctaBackground,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Admin · pending reports',
                                          style:
                                              textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Review citizen submissions, attachments, '
                                          'and heuristic risk buckets.',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: AppColors.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: AppColors.divider),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const AdminBroadcastAnnouncementScreen(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF6E8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.campaign_rounded,
                                      color: Color(0xFFB54708),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Admin · urgent broadcast',
                                          style:
                                              textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Send shelter / corridor bulletins '
                                          '(alerts inbox + Supabase fan-out when enabled).',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: AppColors.textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _LogoutRow(textTheme: textTheme),
                const SizedBox(height: 20),
                _SettingsTeaser(textTheme: textTheme),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    const avatarSize = 92.0;
    /// Half the avatar overlaps the cover; half sits on the grey canvas below.
    const overlap = avatarSize / 2;
    const headerHeight = 158.0;
    /// Shift avatar up on the cover (visual polish).
    const avatarNudgeUp = 38.0;
    final stackHeight = headerHeight - overlap + avatarSize - avatarNudgeUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: stackHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              ClipPath(
                clipper: const _CoverCurvyBottomClipper(
                  topCornerRadius: 22,
                  bottomCenterLift: 40,
                  bottomSideCornerRadius: 26,
                ),
                child: Container(
                  height: headerHeight,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0B6470),
                        Color(0xFF0A7A8C),
                        Color(0xFF6BB3BC),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Flood Guard',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: headerHeight - overlap - avatarNudgeUp,
                left: 16,
                right: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _GlassCircleIcon(
                      icon: Icons.edit_outlined,
                      onTap: () => _toast(context, 'Edit profile — coming soon'),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: ColoredBox(
                              color: AppColors.surfaceMuted,
                              child: Center(
                                child: Text(
                                  _initials(DemoCredentials.displayName),
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ctaBackground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _GlassCircleIcon(
                      icon: Icons.ios_share_rounded,
                      onTap: () =>
                          _toast(context, 'Share preparedness card — demo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
          child: Column(
            children: [
              Text(
                DemoCredentials.displayName,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Kelani River basin • Sri Lanka',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'River & rain alerts • Watch zone active',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.single;
      return s.length >= 2 ? '${s[0]}${s[1]}'.toUpperCase() : s[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

/// Rounded top corners + curvy bottom side corners where sides meet the dip + centre scoop.
class _CoverCurvyBottomClipper extends CustomClipper<Path> {
  const _CoverCurvyBottomClipper({
    required this.topCornerRadius,
    required this.bottomCenterLift,
    this.bottomSideCornerRadius = 24,
  });

  final double topCornerRadius;
  /// How far the middle of the bottom edge moves up toward the avatar (dip depth).
  final double bottomCenterLift;
  /// Rounds BL/BR transitions from vertical edge into the scooped baseline (Airbnb sides).
  final double bottomSideCornerRadius;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final rt = topCornerRadius.clamp(0.0, mathMin(w / 2, h / 2));
    // Soft BL/BR fillets — cap so inner span stays wide enough for the dip curve.
    final maxCorner = mathMin(
      mathMin(w * 0.22, h * 0.32),
      w > 104 ? (w - 88) / 2 : mathMin(w * 0.16, h * 0.28),
    );
    final br = bottomSideCornerRadius.clamp(0.0, maxCorner);
    final xLeft = br;
    final xRight = w - br;
    final innerSpan = xRight - xLeft;

    final path = Path();

    path.moveTo(0, rt);
    path.quadraticBezierTo(0, 0, rt, 0);
    path.lineTo(w - rt, 0);
    path.quadraticBezierTo(w, 0, w, rt);

    path.lineTo(w, h - br);
    path.quadraticBezierTo(w, h, xRight, h);

    path.cubicTo(
      xRight - innerSpan * 0.24,
      h - bottomCenterLift,
      xLeft + innerSpan * 0.24,
      h - bottomCenterLift,
      xLeft,
      h,
    );

    path.quadraticBezierTo(0, h, 0, h - br);
    path.lineTo(0, rt);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _CoverCurvyBottomClipper old) =>
      old.topCornerRadius != topCornerRadius ||
      old.bottomCenterLift != bottomCenterLift ||
      old.bottomSideCornerRadius != bottomSideCornerRadius;

  static double mathMin(double a, double b) => a < b ? a : b;
}

class _GlassCircleIcon extends StatelessWidget {
  const _GlassCircleIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.38),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.95)),
        ),
      ),
    );
  }
}

class _ReportsChartCard extends StatelessWidget {
  const _ReportsChartCard({
    required this.dayLabels,
    required this.values,
    required this.highlightIndex,
    required this.onBarTap,
  });

  final List<String> dayLabels;
  final List<int> values;
  final int highlightIndex;
  final ValueChanged<int> onBarTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final maxV = values.reduce((a, b) => a > b ? a : b);
    assert(dayLabels.length == values.length);

    return Material(
      color: AppColors.background,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.water_damage_rounded,
                      size: 22,
                      color: AppColors.ctaBackground,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Community reports',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _WeeklyChip(
                    onSelected: (v) {
                      if (v != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Range: $v (demo)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 132,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: _BarColumn(
                            label: dayLabels[i],
                            value: values[i],
                            maxValue: maxV,
                            highlighted: i == highlightIndex,
                            onTap: () => onBarTap(i),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Neighbourhood flood observations shared this week (demo data).',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyChip extends StatelessWidget {
  const _WeeklyChip({required this.onSelected});

  final void Function(String? value) onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'Weekly', child: Text('Weekly')),
        PopupMenuItem(value: 'Monthly', child: Text('Monthly')),
        PopupMenuItem(value: 'Monsoon season', child: Text('Monsoon season')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'Weekly',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final int value;
  final int maxValue;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final t = ((value / maxValue).clamp(0.15, 1.0)).toDouble();
    final barFill = highlighted ? AppColors.ctaBackground : AppColors.divider;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight * t;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    if (highlighted)
                      Positioned(
                        bottom: h + 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ctaBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$value',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: h < 10.0 ? 10.0 : h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: barFill,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: highlighted
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.ctaBackground.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              fontWeight:
                  highlighted ? FontWeight.w800 : FontWeight.w600,
              color:
                  highlighted ? AppColors.ctaBackground : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.onShelterTap});

  final VoidCallback onShelterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniMetricCard(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFD14343),
            value: '3',
            title: 'Active alerts',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniMetricCard(
            icon: Icons.add_task_rounded,
            iconColor: const Color(0xFF2BB673),
            value: '12',
            title: 'Your reports',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniMetricCard(
            icon: Icons.maps_home_work_outlined,
            iconColor: const Color(0xFF4078F2),
            value: '2.1 km',
            title: 'Nearest shelter',
            onTap: onShelterTap,
          ),
        ),
      ],
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );

    final box = Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );

    final interaction = onTap;
    if (interaction == null) return box;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: interaction,
        child: box,
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  const _LogoutRow({required this.textTheme});

  final TextTheme textTheme;

  Future<void> _signOut(BuildContext context) async {
    final rootNav = Navigator.of(context, rootNavigator: true);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will return to sign in. Your local reports and '
          'saved alerts stay on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await AuthSessionRepository.clearSession();
    if (!context.mounted) return;
    rootNav.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const EmailAuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _signOut(context),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.textPrimary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log out',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'End this session on this device',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
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

class _SettingsTeaser extends StatelessWidget {
  const _SettingsTeaser({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account & emergency contacts',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Evacuation contacts and alert preferences will live here.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(message),
    ),
  );
}
