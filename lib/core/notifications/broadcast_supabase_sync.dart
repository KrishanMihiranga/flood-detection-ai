import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import 'flood_alert_record.dart';

abstract final class BroadcastSupabaseSync {
  BroadcastSupabaseSync._();

  static Future<BroadcastFanoutStatus> publish(FloodAlertRecord alert) async {
    if (!SupabaseConfig.isConfigured) {
      return BroadcastFanoutStatus.skippedNoClient;
    }
    try {
      await Supabase.instance.client.from(SupabaseConfig.broadcastTable).insert({
        'id': alert.id,
        'title': alert.title,
        'summary': alert.summary,
        'area': alert.area,
        'severity': alert.severity.name,
        'issued_at': alert.issuedAt.toUtc().toIso8601String(),
      });
      return BroadcastFanoutStatus.sent;
    } catch (e, st) {
      debugPrint('broadcast insert failed: $e\n$st');
      return BroadcastFanoutStatus.failed;
    }
  }

  /// Maps a Realtime Postgres payload into [FloodAlertRecord] (`newRecord`).
  static FloodAlertRecord? recordFromRealtimeRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    try {
      return FloodAlertRecord(
        id: row['id'] as String? ?? '',
        title: row['title'] as String? ?? 'Official broadcast',
        summary: row['summary'] as String? ?? '',
        area: row['area'] as String? ?? '',
        issuedAt:
            DateTime.tryParse(row['issued_at'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        severity: _parseSeverity(row['severity'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  static AlertSeverity _parseSeverity(String? raw) {
    for (final v in AlertSeverity.values) {
      if (v.name == raw) return v;
    }
    return AlertSeverity.warning;
  }
}

enum BroadcastFanoutStatus {
  sent,
  failed,
  skippedNoClient,
}
