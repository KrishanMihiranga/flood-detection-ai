import 'shelter_models.dart';

/// Static Kelani corridor demo inventory for UI / walkthrough.
abstract final class DemoSheltersData {
  DemoSheltersData._();

  static const List<ShelterSite> openShelters = [
    ShelterSite(
      markerId: 'shelter_1',
      name: 'Community hall shelter',
      areaDescription:
          'Kaduwela municipal segment • dry-floor hall with north-side ramp ingress',
      isOpen: true,
      currentOccupancy: 174,
      seatedCapacity: 240,
      amenitiesSummary: 'Medical desk, purified water pallets, SEP charging strip (demo)',
      floodedStreetsToAvoid: [
        'Old bund service lane east of ward 04 (ankle–knee surge reported)',
        'Low apron under pedestrian flyover pinch C (CCTV sluggish drain)',
      ],
      navigationSteps: [
        'Leave your block via the LHS embankment service road — stays above yesterday’s crest line.',
        'At Ward 03 rotary, bypass the sunken plaza; follow “high ring” decals toward the teal shelter icon.',
        'Cross the grated storm channel using the pedestrian bridge only — the mid-block ford is flagged.',
        'Check in west reception; stewards scan household chips and allocate mat zones.',
      ],
    ),
    ShelterSite(
      markerId: 'shelter_2',
      name: 'School evacuation point',
      areaDescription:
          'Malabe connector foothill • auditorium stack with upper mezzanine overflow',
      isOpen: true,
      currentOccupancy: 312,
      seatedCapacity: 420,
      amenitiesSummary:
          'First-aid, ORS station, multilingual desk, pet tether bay outdoors (demo)',
      floodedStreetsToAvoid: [
        'School spine sump curve — southbound sump covers lifting on models',
        'Service cut-through behind stadium LED board (sensor shows sheet flow)',
      ],
      navigationSteps: [
        'Start on R‑102 heading east; activate “safe corridors” tint on Flood Guard Map if available.',
        'Exit before the flagged underpass — take the slip marked “alternate high route”.',
        'Merge onto spine road crest; hug the lighted jersey barriers until GIS shelter pins align.',
        'Use the auditorium ramp (north); mezzanine opens automatically above 280 seated count.',
      ],
    ),
    ShelterSite(
      markerId: 'shelter_3_demo',
      name: 'Ward readiness gymnasium',
      areaDescription:
          'Biyagama industrial buffer • converted sports hall cooling tunnel active',
      isOpen: true,
      currentOccupancy: 89,
      seatedCapacity: 180,
      amenitiesSummary:
          'Fans + mist wall, sanitation trailer row C, guarded logistics yard (demo)',
      floodedStreetsToAvoid: [
        'Connector slip near logistics gate (wax trailer queue + pooled oils)',
      ],
      navigationSteps: [
        'Use the arterial marked blue on Flood Guard dashboards — avoid canalside merges.',
        'At the coolant plant billboard, peel north onto the porous-paver lane.',
        'Check-in via rolling doors B; occupancy LED shows live mat availability.',
      ],
    ),
  ];

  /// Broader multimodal corridors (not pinned to single shelter arrivals).
  static const List<SafeRouteCorridor> corridors = [
    SafeRouteCorridor(
      id: 'corridor_lhs_emb',
      title: 'Kelani LHS embankment path',
      summaryLine: 'Higher berm alignment — lit gabion sections overnight',
      estimatedKm: 2.1,
      avoidFloodedAreas: [
        'Canalside commuter cut-through beside ward market',
        'Unlit ford at bund maintenance gate (auto-closed barrier)',
      ],
      turnByTurnSteps: [
        'Align to the berm cycle track from your origin; ascend where yellow reflectors tighten.',
        'Stay crest-side of the corrugated flood wall for 900 m.',
        'Descend only at kiosk P12 where gravel drains are scavenged hourly.',
      ],
    ),
    SafeRouteCorridor(
      id: 'corridor_r102_bridge',
      title: 'R‑102 → Old bridge alternate',
      summaryLine: 'Multi-leg bypass of monitored underpasses',
      estimatedKm: 3.8,
      avoidFloodedAreas: [
        'Central underpass CCTV pair (stack height below safe SUV sill)',
      ],
      turnByTurnSteps: [
        'Bear right onto R‑102 before the hydrophone gantry slowdown.',
        'Use the roundabout third exit aiming for ridge-line streetlights.',
        'Rejoin mainline only past the masonry arch where sensors read “clear”.',
      ],
    ),
    SafeRouteCorridor(
      id: 'corridor_school_spine',
      title: 'School spine road',
      summaryLine: 'Short hop with shelters en route on map overlays',
      estimatedKm: 1.4,
      avoidFloodedAreas: [
        'Playground sump curve after afternoon burst clusters',
      ],
      turnByTurnSteps: [
        'Enter spine via the staffed cone lane — skips sheet flow from parking grid.',
        'Pause at zebra H for marshals updating pulsing LED detours.',
        'Shelter podium visible at 280 m crest on the LHS.',
      ],
    ),
  ];
}
