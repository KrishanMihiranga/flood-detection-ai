import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import 'flood_report_record.dart';

abstract final class ModerationSupabaseSync {
  ModerationSupabaseSync._();

  /// Mirrors moderator decisions for realtime / edge automations downstream.
  static Future<ModerationRemoteSync> pushModerationDecision({
    required CitizenFloodReport report,
    required FloodReportWorkflowStatus decision,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return ModerationRemoteSync.skippedMissingConfig;
    }
    try {
      await Supabase.instance.client.from(SupabaseConfig.moderationTable).upsert(
        {
          'report_id': report.id,
          'status': decision.name,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'description': report.description,
          'reporter_phone': report.reporterPhone,
          'ai_label': report.aiSuggestedRiskLabel,
          'observed_water_level': report.observedLevel.name,
          'moderated_at': DateTime.now().toUtc().toIso8601String(),
          'broadcast_to_map':
              decision == FloodReportWorkflowStatus.approved ? true : false,
        },
        onConflict: 'report_id',
      );
      return ModerationRemoteSync.sent;
    } catch (e, st) {
      debugPrint('Moderation Supabase upsert failed: $e\n$st');
      return ModerationRemoteSync.failed;
    }
  }
}

enum ModerationRemoteSync {
  sent,
  failed,
  skippedMissingConfig,
}
