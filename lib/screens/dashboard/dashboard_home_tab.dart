import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/dashboard/section_header.dart';
import '../alerts/alerts_notification_history_screen.dart';
import 'mock_dashboard_data.dart';

/// Main scrollable home — layout inspired by modern card dashboards.
class DashboardHomeTab extends StatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  State<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<DashboardHomeTab> {
  int _selectedCategory = 0;
  String _displayName = DemoCredentials.displayName;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final name = await AuthSessionRepository.displayName();
    if (mounted) {
      setState(() => _displayName = name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final focusLabel = MockDashboardData.focusCategories[_selectedCategory];
    final areaUpdates =
        MockDashboardData.updatesForFocusIndex(_selectedCategory);

    final searchBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.divider),
    );

    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            // Extra bottom space so lists scroll clear of the overlapping glass nav.
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $_displayName!',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Let's stay flood-ready from today onward.",
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceMuted,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const AlertsNotificationHistoryScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                TextField(
                  readOnly: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text(
                          'Search will filter alerts & shelters (demo).',
                        ),
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'Search alerts, shelters, or locations…',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                    ),
                    border: searchBorder,
                    enabledBorder: searchBorder,
                    focusedBorder: searchBorder.copyWith(
                      borderSide: const BorderSide(
                        color: AppColors.textPrimary,
                        width: 1.2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                DashboardSectionHeader(
                  title: 'Browse by focus',
                  actionLabel: 'See all',
                  onAction: () {},
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: MockDashboardData.focusCategories.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final selected = _selectedCategory == i;
                      final label = MockDashboardData.focusCategories[i];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.ctaBackground
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected
                                  ? AppColors.ctaBackground
                                  : AppColors.divider,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 26),
                DashboardSectionHeader(
                  title: 'Updates near you · $focusLabel',
                  actionLabel: 'See all',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const AlertsNotificationHistoryScreen(),
                      ),
                    );
                  },
                ),
                SizedBox(
                  key: ValueKey(_selectedCategory),
                  height: 158,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: areaUpdates.length,
                    separatorBuilder: (context, i) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final u = areaUpdates[i];
                      return SizedBox(width: 220, child: _UpdateCard(data: u));
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Preparedness today',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _PreparednessHeroCard(),
              ]),
            ),
          ),
        ],
      );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {},
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.water_damage_rounded,
                        color: AppColors.ctaBackground,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  ],
                ),
                const Spacer(),
                Text(
                  data['title']!,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data['detail']!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  data['meta']!,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparednessHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final progress = MockDashboardData.preparednessProgress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppColors.ctaBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  MockDashboardData.preparednessTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(10),
                ),
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            MockDashboardData.preparednessSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
