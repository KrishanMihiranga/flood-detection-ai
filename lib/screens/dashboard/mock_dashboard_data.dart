/// Static copy for Flood Guard dashboards (no backend).
abstract final class MockDashboardData {
  MockDashboardData._();

  static const List<String> focusCategories = [
    'River levels',
    'Shelters',
    'Safe routes',
    'Community',
  ];

  /// One horizontal row of cards per entry in [focusCategories] (same order).
  static final List<List<Map<String, String>>> areaUpdatesByFocus = [
    // River levels
    [
      {
        'title': 'Kelani River basin',
        'detail': 'Watch · Elevated discharge',
        'meta': '+12 km · Gauge auto · 26m ago',
      },
      {
        'title': 'Attanagalu Oya',
        'detail': 'Advisory · Trend rising',
        'meta': '+18 km · DMC feed · 1h ago',
      },
      {
        'title': 'Colombo surge watch',
        'detail': 'Tide + runoff overlap',
        'meta': 'Estuary sensors · Updated 41m ago',
      },
    ],
    // Shelters
    [
      {
        'title': 'Wattala evacuation hall',
        'detail': 'Open · 142 spaces',
        'meta': '+4 km · Verified by users',
      },
      {
        'title': 'Kadawatha community hall',
        'detail': 'Open · Beds + dry rations',
        'meta': '+9 km · Red Cross staffed',
      },
      {
        'title': 'Hendala school annex',
        'detail': 'Near capacity · 12 spaces',
        'meta': '+6 km · Shuttle from pier',
      },
    ],
    // Safe routes
    [
      {
        'title': 'Embankment A → Shelter B',
        'detail': 'Clear · Elevated berm path',
        'meta': '+2 km · No reported washouts',
      },
      {
        'title': 'Old bridge at Rajagiriya',
        'detail': 'Avoid · Local detour via Borella',
        'meta': 'Municipal flag · 35m ago',
      },
      {
        'title': 'Coastal road segment',
        'detail': 'Caution · Salt spray / debris',
        'meta': '+15 km · Night travel discouraged',
      },
    ],
    // Community
    [
      {
        'title': 'Monsoon swell advisory',
        'detail': 'Medium · Forecast 48h',
        'meta': 'Districtwide · IMD bulletin',
      },
      {
        'title': 'Ward WhatsApp nets',
        'detail': 'Active · SOS + logistics',
        'meta': '12 blocks · Moderator-reviewed',
      },
      {
        'title': 'Volunteer sandbag run',
        'detail': 'Sat 07:00 · Meet City Hall lot',
        'meta': '48 signed up · Equipment provided',
      },
    ],
  ];

  static List<Map<String, String>> updatesForFocusIndex(int index) {
    if (areaUpdatesByFocus.isEmpty) return [];
    final i = index.clamp(0, areaUpdatesByFocus.length - 1);
    return areaUpdatesByFocus[i];
  }

  static const double preparednessProgress = 0.72;
  static const String preparednessTitle = '72% kit ready';
  static const String preparednessSubtitle =
      'Add documents & contacts to reach 100% before peak season.';
}
