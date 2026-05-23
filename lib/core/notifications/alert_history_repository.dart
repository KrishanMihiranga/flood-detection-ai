import 'package:shared_preferences/shared_preferences.dart';

import 'flood_alert_record.dart';

/// Persists alerts on-device (SharedPreferences). No Firebase in this milestone.
abstract final class AlertHistoryRepository {
  AlertHistoryRepository._();

  static const _prefsKey = 'flood_guard_alert_history_v1';

  /// Guaranteed one row per [AlertSeverity] for UI demos — merged on load when missing.
  static List<FloodAlertRecord> demoSeedsAllSeverities() => [
        FloodAlertRecord(
          id: 'demo_alert_type_warning',
          title: '[Demo] Reservoir release coordination',
          summary:
              'Hydrology forecasts a supervised release spike within 6–12 hours. Low-lying quay berths should clear vehicles and moorings; listen for ward SMS blast.',
          area: 'Kotte retention basin outlet · wetland apron',
          issuedAt:
              DateTime.now().subtract(const Duration(minutes: 18)),
          severity: AlertSeverity.warning,
        ),
        FloodAlertRecord(
          id: 'demo_alert_type_watch',
          title: '[Demo] Gauged stage crossing watch thresholds',
          summary:
              'Two upstream gauges trended upward for three consecutive telemetry windows. Overnight ponding likely at known pinch crossings—avoid underpass dips.',
          area: 'Kelani River corridor · Kaduwela municipal segment',
          issuedAt:
              DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
          severity: AlertSeverity.watch,
        ),
        FloodAlertRecord(
          id: 'demo_alert_type_advisory',
          title: '[Demo] 72-hour burst rainfall ensemble',
          summary:
              'Ensemble centroid shows >90 mm plausible across western hill feeders. Sump checks and drain selfies help response teams prioritize visits.',
          area: 'Kelani basin headwaters · western hill catchments',
          issuedAt:
              DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
          severity: AlertSeverity.advisory,
        ),
        FloodAlertRecord(
          id: 'demo_alert_type_info',
          title: '[Demo] Telemetry mesh sync complete',
          summary:
              'All pilot nodes ACK’d within SLA. Basin dashboards refreshed; safe-corridor routing overlays are current for your saved home polygon.',
          area: 'Entire Flood Guard pilot polygon',
          issuedAt:
              DateTime.now().subtract(const Duration(hours: 5, minutes: 44)),
          severity: AlertSeverity.info,
        ),
      ];

  static List<FloodAlertRecord> seedsForFirstLaunch() => [
        FloodAlertRecord(
          id: 'seed_kel_watch_01',
          title: 'Kelani tributary discharge elevated',
          summary:
              'Automated gauging flagged rising stage. Residents near low crossings should monitor roadway ponding overnight.',
          area: 'Kelani River corridor · Kaduwela municipal segment',
          issuedAt: DateTime.now().subtract(const Duration(hours: 4, minutes: 12)),
          severity: AlertSeverity.watch,
        ),
        FloodAlertRecord(
          id: 'seed_burst_72h',
          title: '72-hour burst rainfall advisory',
          summary:
              'IMD-style cluster shows >90 mm plausible in basin headwaters. Clearing drains and sump checks recommended.',
          area: 'Kelani basin headwaters · western hill catchments',
          issuedAt: DateTime.now().subtract(const Duration(hours: 8, minutes: 41)),
          severity: AlertSeverity.advisory,
        ),
        FloodAlertRecord(
          id: 'seed_shel_route',
          title: 'Shelter routes pre-staged',
          summary:
              'DR teams flagged two corridors with partial debris history. Alternate northbound lane kept clear for evacuation drills.',
          area: 'Biyagama · Malabe connector',
          issuedAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 2, minutes: 55)),
          severity: AlertSeverity.info,
        ),
        FloodAlertRecord(
          id: 'seed_prep_kit',
          title: 'Peak-season kit completeness',
          summary:
              'Reminder: hydrate documents contacts to 100%. Local ward desk open 08:00–18:00 for sealable pouches.',
          area: 'Colombo Metro East watch zone',
          issuedAt:
              DateTime.now().subtract(const Duration(days: 1, hours: 19, minutes: 10)),
          severity: AlertSeverity.info,
        ),
        FloodAlertRecord(
          id: 'seed_hwy_br',
          title: 'Underpass queue risk',
          summary:
              'Automated CCTV stack reports slow drainage at flagged underpass pair. Routing engine updated for “safe corridors” overlay.',
          area: 'Kolonnawa interchange · low-lying apron',
          issuedAt:
              DateTime.now().subtract(const Duration(days: 2, hours: 6, minutes: 33)),
          severity: AlertSeverity.watch,
        ),
        FloodAlertRecord(
          id: 'seed_wave_sync',
          title: 'Hydrology model sync OK',
          summary:
              'Open telemetry mesh reconciled against manual spotters. Confidence high for basin-wide dashboards next 48 h.',
          area: 'Entire Flood Guard pilot polygon',
          issuedAt:
              DateTime.now().subtract(const Duration(days: 3, hours: 1, minutes: 5)),
          severity: AlertSeverity.info,
        ),
      ];

  /// Ensures canonical `demo_alert_type_*` rows exist so every severity appears in History.
  /// Returns `true` if any demo row was inserted.
  static bool mergeMissingDemoSeverityRows(List<FloodAlertRecord> into) {
    final ids = into.map((e) => e.id).toSet();
    var merged = false;
    for (final demo in demoSeedsAllSeverities()) {
      if (!ids.contains(demo.id)) {
        into.add(demo);
        ids.add(demo.id);
        merged = true;
      }
    }
    return merged;
  }

  static Future<List<FloodAlertRecord>> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) {
      final seeded = [...demoSeedsAllSeverities(), ...seedsForFirstLaunch()];
      seeded.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      await saveAlerts(seeded);
      return List.from(seeded);
    }
    final list = FloodAlertRecord.decodeList(raw);
    final merged = mergeMissingDemoSeverityRows(list);
    list.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    if (merged) await saveAlerts(list);
    return list;
  }

  static Future<void> saveAlerts(List<FloodAlertRecord> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = List<FloodAlertRecord>.from(alerts)
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    await prefs.setString(_prefsKey, FloodAlertRecord.encodeList(sorted));
  }

  /// Admin-issued bulletin (prepends chronologically sorted store).
  static Future<FloodAlertRecord> prependOfficialBroadcast({
    required String summary,
    required String area,
    AlertSeverity severity = AlertSeverity.warning,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final list =
        raw == null || raw.isEmpty ? <FloodAlertRecord>[] : FloodAlertRecord.decodeList(raw);
    final record = FloodAlertRecord(
      id: 'official_bc_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Official broadcast',
      summary: summary.trim(),
      area: area.trim().isEmpty ? 'Basin-wide' : area.trim(),
      issuedAt: DateTime.now(),
      severity: severity,
    );
    list.add(record);
    await saveAlerts(list);
    return record;
  }

  /// Deduped merge when Supabase Realtime delivers a bulletin from another moderator app.
  static Future<bool> mergeInboundBroadcastIfNew(FloodAlertRecord remote) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final list =
        raw == null || raw.isEmpty ? <FloodAlertRecord>[] : FloodAlertRecord.decodeList(raw);
    if (list.any((e) => e.id == remote.id)) return false;
    list.add(remote);
    await saveAlerts(list);
    return true;
  }
}
