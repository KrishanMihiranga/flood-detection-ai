import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import 'approved_reports_map_notifier.dart';
import 'flood_report_record.dart';
import 'water_level_choice.dart';

/// Local queue of citizen submissions (offline pilot).
abstract final class FloodReportsRepository {
  FloodReportsRepository._();

  static const _prefsKey = 'flood_guard_citizen_reports_v1';

  static Future<List<CitizenFloodReport>> loadAll() async {
    if (SupabaseConfig.isConfigured) {
      try {
        final response = await Supabase.instance.client
            .from(SupabaseConfig.moderationTable)
            .select()
            .order('moderated_at', ascending: false);
        return (response as List)
            .map((e) => CitizenFloodReport.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to load reports from Supabase: $e');
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    return CitizenFloodReport.decodeList(raw);
  }

  /// Pending queue **for moderator UI** — also merges illustrative rows once missing.
  ///
  /// Not used on citizen flows so unsubmitted installs stay clean.
  static Future<List<CitizenFloodReport>> loadPendingForModeration() async {
    final merged = await _withMergedDemoQueue(await loadAll());
    return merged
        .where((e) => e.status == FloodReportWorkflowStatus.pending)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  /// Demo moderators always see illustrative pending rows keyed by prefix.
  static Future<List<CitizenFloodReport>> _withMergedDemoQueue(
      List<CitizenFloodReport> list) async {
    final ids = list.map((e) => e.id).toSet();
    var mutated = false;
    for (final demo in demoAdminQueue()) {
      if (!ids.contains(demo.id)) {
        list.add(demo);
        ids.add(demo.id);
        mutated = true;
      }
    }
    if (mutated) {
      await saveReports(list);
    }
    return list;
  }

  /// Seeded moderator workload — merges once per missing id like alert demos.
  static List<CitizenFloodReport> demoAdminQueue() {
    final t = DateTime.now();
    return [
      CitizenFloodReport(
        id: 'demo_admin_queue_01',
        submittedAt: t.subtract(const Duration(hours: 2, minutes: 14)),
        reporterPhone: '+94 71 392 8841',
        description:
            'Rapid shear across Kelani LHS service spur — corrugated bund splashover, scooters pushed sideways. Sump covers lifting near produce stalls.',
        observedLevel: WaterLevelChoice.high,
        latitude: 6.9131,
        longitude: 79.9598,
        aiSuggestedRiskLabel: FloodReportAiSuggestion.labelFor(
          WaterLevelChoice.high,
          'Rapid shear across Kelani LHS service spur',
        ),
        status: FloodReportWorkflowStatus.pending,
        storedPhotoRelativePath: null,
      ),
      CitizenFloodReport(
        id: 'demo_admin_queue_02',
        submittedAt: t.subtract(const Duration(hours: 5, minutes: 43)),
        reporterPhone: '+94 76 554 9022',
        description:
            'Mid-block culvert choked with debris after night squall — sheet flow widening into row-house apron. Volunteers placed cones.',
        observedLevel: WaterLevelChoice.medium,
        latitude: 6.9182,
        longitude: 79.9644,
        aiSuggestedRiskLabel: FloodReportAiSuggestion.labelFor(
          WaterLevelChoice.medium,
          'culvert choked with debris after night squall',
        ),
        status: FloodReportWorkflowStatus.pending,
        storedPhotoRelativePath: null,
      ),
      CitizenFloodReport(
        id: 'demo_admin_queue_03',
        submittedAt: t.subtract(const Duration(days: 1, hours: 3)),
        reporterPhone: '+94 70 883 4410',
        description:
            'Playground sump slow to clear but water now ankle deep only; asking if pumps en route.',
        observedLevel: WaterLevelChoice.low,
        latitude: 6.9068,
        longitude: 79.9612,
        aiSuggestedRiskLabel: FloodReportAiSuggestion.labelFor(
          WaterLevelChoice.low,
          'Playground sump slow to clear',
        ),
        status: FloodReportWorkflowStatus.pending,
        storedPhotoRelativePath: null,
      ),
    ];
  }

  static Future<void> saveReports(List<CitizenFloodReport> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, CitizenFloodReport.encodeList(rows));
  }

  /// Persists JPEG bytes under application documents or uploads to Supabase.
  static Future<CitizenFloodReport> submitReport({
    required String reporterPhone,
    required String description,
    required WaterLevelChoice observedLevel,
    required double latitude,
    required double longitude,
    required File? photoFileMaybe,
  }) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}_r';

    final aiLabel = FloodReportAiSuggestion.labelFor(
      observedLevel,
      description.trim(),
    );

    String? relative;
    String? remoteUrl;

    if (photoFileMaybe != null && await photoFileMaybe.exists()) {
      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/report_photos');
      await folder.create(recursive: true);
      final dest = File('${folder.path}/$id.jpg');
      await photoFileMaybe.copy(dest.path);
      relative = 'report_photos/$id.jpg';
    }

    if (SupabaseConfig.isConfigured) {
      if (photoFileMaybe != null && await photoFileMaybe.exists()) {
        try {
          final path = '$id.jpg';
          await Supabase.instance.client.storage
              .from(SupabaseConfig.reportsBucket)
              .upload(path, photoFileMaybe);
          remoteUrl = Supabase.instance.client.storage
              .from(SupabaseConfig.reportsBucket)
              .getPublicUrl(path);
        } catch (e) {
          debugPrint('Failed to upload photo to Supabase storage: $e');
        }
      }

      try {
        final reporterId = Supabase.instance.client.auth.currentUser?.id;
        await Supabase.instance.client.from(SupabaseConfig.moderationTable).insert({
          'report_id': id,
          'status': 'pending',
          'latitude': latitude,
          'longitude': longitude,
          'description': description.trim(),
          'reporter_phone': reporterPhone.trim(),
          'ai_label': aiLabel,
          'observed_water_level': observedLevel.name,
          'moderated_at': DateTime.now().toUtc().toIso8601String(),
          'broadcast_to_map': false,
          'photo_url': remoteUrl,
          'reporter_id': reporterId,
        });
      } catch (e) {
        debugPrint('Failed to insert report into Supabase: $e');
      }
    }

    final report = CitizenFloodReport(
      id: id,
      submittedAt: DateTime.now(),
      reporterPhone: reporterPhone.trim(),
      description: description.trim(),
      observedLevel: observedLevel,
      latitude: latitude,
      longitude: longitude,
      aiSuggestedRiskLabel: aiLabel,
      storedPhotoRelativePath: remoteUrl ?? relative,
      status: FloodReportWorkflowStatus.pending,
    );

    if (!SupabaseConfig.isConfigured) {
      final all = await loadAll();
      all.add(report);
      await saveReports(all);
    }
    return report;
  }

  /// Marks a known id with a moderator outcome and pings map listeners.
  static Future<bool> applyModerationDecision(
    String id,
    FloodReportWorkflowStatus outcome,
  ) async {
    final ok = await updateReportStatus(id, outcome);
    if (ok) {
      ApprovedReportsMapNotifier.bump();
    }
    return ok;
  }

  static Future<bool> updateReportStatus(
    String id,
    FloodReportWorkflowStatus outcome,
  ) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client
            .from(SupabaseConfig.moderationTable)
            .update({
              'status': outcome.name,
              'broadcast_to_map': outcome == FloodReportWorkflowStatus.approved,
            })
            .eq('report_id', id);
      } catch (e) {
        debugPrint('Failed to update status on Supabase: $e');
        return false;
      }
    }

    final rows = await loadAll();
    final ix = rows.indexWhere((e) => e.id == id);
    if (ix < 0) return false;
    rows[ix] = rows[ix].copyWith(status: outcome);
    await saveReports(rows);
    return true;
  }

  /// Approved rows rendered as pins for every user session (offline source of truth).
  static Future<List<CitizenFloodReport>> loadApprovedForBroadcastMap() async {
    final rows = await loadAll();
    return rows
        .where((r) => r.status == FloodReportWorkflowStatus.approved)
        .toList();
  }

  /// Resolves persisted relative path (`report_photos/…`) against app documents dir.
  static Future<File?> resolvePhoto(CitizenFloodReport r) async {
    final rel = r.storedPhotoRelativePath;
    if (rel == null || rel.trim().isEmpty) return null;
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$rel');
    if (!await file.exists()) return null;
    return file;
  }
}
