/// Demo shelters + safe-route corridors — no backend; pairs with markers in [DemoGeo].
class ShelterSite {
  const ShelterSite({
    required this.markerId,
    required this.name,
    required this.areaDescription,
    required this.isOpen,
    required this.currentOccupancy,
    required this.seatedCapacity,
    required this.amenitiesSummary,
    required this.floodedStreetsToAvoid,
    required this.navigationSteps,
  });

  /// Matches `MarkerId` on the Google Map (`shelter_1`, `shelter_2`).
  final String markerId;
  final String name;
  final String areaDescription;
  final bool isOpen;
  /// People currently sheltered (demo telemetry).
  final int currentOccupancy;
  /// Seated mat / hall capacity baseline (demo).
  final int seatedCapacity;
  final String amenitiesSummary;
  /// Human crossings / segments flagged as inundated — instruct user to skirt.
  final List<String> floodedStreetsToAvoid;
  final List<String> navigationSteps;

  double get occupancyRatio {
    if (seatedCapacity <= 0) return 0;
    return (currentOccupancy / seatedCapacity).clamp(0.0, 1.0);
  }

  String get capacityLine =>
      '$currentOccupancy / $seatedCapacity seated (${(occupancyRatio * 100).round()}% occupancy)';
}

class SafeRouteCorridor {
  const SafeRouteCorridor({
    required this.id,
    required this.title,
    required this.summaryLine,
    required this.estimatedKm,
    required this.avoidFloodedAreas,
    required this.turnByTurnSteps,
  });

  final String id;
  final String title;
  final String summaryLine;
  final double estimatedKm;
  final List<String> avoidFloodedAreas;
  final List<String> turnByTurnSteps;
}

/// Normalized fields for shared detail UI — built from shelter or corridor.
class ShelterGuideViewModel {
  const ShelterGuideViewModel({
    required this.headline,
    required this.heroLine,
    required this.avoidFloodedBullets,
    required this.turnByTurnSteps,
    this.isOpenShelter,
    this.occupancyLabel,
    this.occupancyRatio,
    this.amenitiesLine,
  });

  factory ShelterGuideViewModel.fromShelter(ShelterSite s) {
    return ShelterGuideViewModel(
      headline: s.name,
      heroLine: s.areaDescription,
      isOpenShelter: s.isOpen,
      occupancyRatio: s.occupancyRatio,
      occupancyLabel: s.capacityLine,
      amenitiesLine: s.amenitiesSummary,
      avoidFloodedBullets: s.floodedStreetsToAvoid,
      turnByTurnSteps: s.navigationSteps,
    );
  }

  factory ShelterGuideViewModel.fromCorridor(SafeRouteCorridor c) {
    return ShelterGuideViewModel(
      headline: c.title,
      heroLine:
          '~${c.estimatedKm.toStringAsFixed(1)} km • ${c.summaryLine}',
      isOpenShelter: null,
      occupancyRatio: null,
      occupancyLabel: null,
      amenitiesLine: null,
      avoidFloodedBullets: c.avoidFloodedAreas,
      turnByTurnSteps: c.turnByTurnSteps,
    );
  }

  final String headline;
  final String heroLine;
  /// `null` — not applicable (corridor). `false` temporarily closed banner.
  final bool? isOpenShelter;
  final double? occupancyRatio;
  final String? occupancyLabel;
  final String? amenitiesLine;
  final List<String> avoidFloodedBullets;
  final List<String> turnByTurnSteps;
}
