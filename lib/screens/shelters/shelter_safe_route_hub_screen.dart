import 'package:flutter/material.dart';

import '../../core/shelters/demo_shelters_data.dart';
import '../../core/shelters/shelter_models.dart';
import '../../core/theme/app_colors.dart';
import 'shelter_guidance_detail_screen.dart';

/// Hub: emergency shelters + safe corridors with capacity and navigable drills.
class ShelterSafeRouteHubScreen extends StatelessWidget {
  const ShelterSafeRouteHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.dashboardCanvas,
      appBar: AppBar(
        title: const Text('Shelters & safe routes'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.ctaBackground.withValues(alpha: 0.28)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.alt_route_rounded, color: AppColors.ctaBackground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilot navigation view',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Lists open shelters with live-ish capacity placeholders and '
                          'turn‑by‑turn instructions that skirt inundated crossings. '
                          'Map pins use the same names — switch to Map to orient.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Open emergency shelters',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...DemoSheltersData.openShelters.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShelterCard(
                site: s,
                onOpenDetail: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ShelterGuidanceDetailScreen(
                        vm: ShelterGuideViewModel.fromShelter(s),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Safe corridors (whole segment)',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Multi-hop paths that dodge known flood pockets — open for full choreography.',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          ...DemoSheltersData.corridors.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CorridorCard(
                corridor: c,
                onOpenDetail: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ShelterGuidanceDetailScreen(
                        vm: ShelterGuideViewModel.fromCorridor(c),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShelterCard extends StatelessWidget {
  const _ShelterCard({
    required this.site,
    required this.onOpenDetail,
  });

  final ShelterSite site;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final open = site.isOpen;
    final ratio = site.occupancyRatio;

    return Material(
      color: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.maps_home_work_outlined, color: AppColors.ctaBackground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          site.areaDescription,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: open ? const Color(0xFFE8F8EE) : const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      open ? 'Open' : 'Closed',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: open ? const Color(0xFF1F7A3E) : const Color(0xFFB42318),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${site.currentOccupancy} / ${site.seatedCapacity} seated',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ratio >= 0.9 ? const Color(0xFFD14343) : AppColors.ctaBackground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Step‑by‑step route',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctaBackground,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.ctaBackground),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CorridorCard extends StatelessWidget {
  const _CorridorCard({
    required this.corridor,
    required this.onOpenDetail,
  });

  final SafeRouteCorridor corridor;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(Icons.turn_sharp_right_outlined, color: AppColors.ctaBackground, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      corridor.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~${corridor.estimatedKm.toStringAsFixed(1)} km · ${corridor.summaryLine}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
