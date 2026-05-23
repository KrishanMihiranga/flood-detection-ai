import 'package:flutter/material.dart';

import '../../core/shelters/shelter_models.dart';
import '../../core/theme/app_colors.dart';

/// Drill-in: floods to avoid + step-by-step approach for a shelter or corridor.
class ShelterGuidanceDetailScreen extends StatelessWidget {
  const ShelterGuidanceDetailScreen({super.key, required this.vm});

  final ShelterGuideViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.dashboardCanvas,
      appBar: AppBar(
        title: Text(vm.headline),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            vm.heroLine,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          if (vm.isOpenShelter != null) ...[
            const SizedBox(height: 16),
            _StatusCapacityCard(vm: vm),
          ],
          if (vm.avoidFloodedBullets.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Bypass flooded crossings',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...vm.avoidFloodedBullets.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.water_damage_outlined,
                      size: 20,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e,
                        style: textTheme.bodyMedium?.copyWith(height: 1.42),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Recommended approach',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...vm.turnByTurnSteps.asMap().entries.map((e) {
            final i = e.key + 1;
            final step = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.ctaBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$i',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        step,
                        style: textTheme.bodyMedium?.copyWith(height: 1.45),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Routing is illustrative for this pilot — always follow marshall '
            'signage and municipal instructions.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCapacityCard extends StatelessWidget {
  const _StatusCapacityCard({required this.vm});

  final ShelterGuideViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final open = vm.isOpenShelter == true;
    final ratio = vm.occupancyRatio ?? 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: open ? const Color(0xFFE8F8EE) : const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    open ? 'Open' : 'Temporarily paused',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: open ? const Color(0xFF1F7A3E) : const Color(0xFFB42318),
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.people_alt_outlined, color: AppColors.ctaBackground),
              ],
            ),
            if (vm.occupancyLabel != null) ...[
              const SizedBox(height: 14),
              Text(
                vm.occupancyLabel!,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ratio >= 0.9
                        ? const Color(0xFFD14343)
                        : AppColors.ctaBackground,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ratio >= 0.92
                    ? 'Near seated capacity — mezzanine / overflow protocols may activate.'
                    : 'Mat allocation counter refreshed every few minutes (demo telemetry).',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            if (vm.amenitiesLine != null) ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: AppColors.ctaBackground),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vm.amenitiesLine!,
                      style: textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
