import 'dart:convert';

import 'water_level_choice.dart';

enum FloodReportWorkflowStatus {
  pending,
  approved,
  rejected,
}

/// One citizen submission stored locally until a backend exists.
class CitizenFloodReport {
  const CitizenFloodReport({
    required this.id,
    required this.submittedAt,
    required this.reporterPhone,
    required this.description,
    required this.observedLevel,
    required this.latitude,
    required this.longitude,
    required this.aiSuggestedRiskLabel,
    required this.status,
    this.storedPhotoRelativePath,
  });

  final String id;
  final DateTime submittedAt;

  /// E.164-ish or spaced local format from reporter.
  final String reporterPhone;

  /// Free-form scene description from citizen.
  final String description;

  final WaterLevelChoice observedLevel;

  final double latitude;
  final double longitude;

  /// Heuristic caption — placeholder for ML service.
  final String aiSuggestedRiskLabel;

  /// `null` = no attachment saved.
  final String? storedPhotoRelativePath;

  final FloodReportWorkflowStatus status;

  CitizenFloodReport copyWith({
    String? id,
    DateTime? submittedAt,
    String? reporterPhone,
    String? description,
    WaterLevelChoice? observedLevel,
    double? latitude,
    double? longitude,
    String? aiSuggestedRiskLabel,
    String? storedPhotoRelativePath,
    FloodReportWorkflowStatus? status,
  }) {
    return CitizenFloodReport(
      id: id ?? this.id,
      submittedAt: submittedAt ?? this.submittedAt,
      reporterPhone: reporterPhone ?? this.reporterPhone,
      description: description ?? this.description,
      observedLevel: observedLevel ?? this.observedLevel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      aiSuggestedRiskLabel:
          aiSuggestedRiskLabel ?? this.aiSuggestedRiskLabel,
      storedPhotoRelativePath:
          storedPhotoRelativePath ?? this.storedPhotoRelativePath,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'submittedAt': submittedAt.toUtc().toIso8601String(),
        'reporterPhone': reporterPhone,
        'description': description,
        'observedLevel': observedLevel.name,
        'latitude': latitude,
        'longitude': longitude,
        'aiSuggestedRiskLabel': aiSuggestedRiskLabel,
        'storedPhotoRelativePath': storedPhotoRelativePath,
        'status': status.name,
      };
  static CitizenFloodReport fromJson(Map<String, dynamic> json) {
    return CitizenFloodReport(
      id: json['report_id'] as String? ?? json['id'] as String? ?? '',
      submittedAt:
          DateTime.tryParse(json['moderated_at'] as String? ?? json['submittedAt'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      reporterPhone: json['reporter_phone'] as String? ?? json['reporterPhone'] as String? ?? '',
      description: json['description'] as String? ?? '',
      observedLevel: _parseWaterLevel(json['observed_water_level'] as String? ?? json['observedLevel'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      aiSuggestedRiskLabel:
          json['ai_label'] as String? ?? json['aiSuggestedRiskLabel'] as String? ?? 'Unclassified',
      storedPhotoRelativePath:
          json['photo_url'] as String? ?? json['storedPhotoRelativePath'] as String?,
      status: _parseStatus(json['status'] as String?),
    );
  }

  static WaterLevelChoice _parseWaterLevel(String? raw) {
    for (final v in WaterLevelChoice.values) {
      if (v.name == raw) return v;
    }
    return WaterLevelChoice.medium;
  }

  static FloodReportWorkflowStatus _parseStatus(String? raw) {
    for (final v in FloodReportWorkflowStatus.values) {
      if (v.name == raw) return v;
    }
    return FloodReportWorkflowStatus.pending;
  }

  static String encodeList(List<CitizenFloodReport> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<CitizenFloodReport> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((e) => CitizenFloodReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Lightweight risk bucket copy for moderator triage until a classifier is wired.
abstract final class FloodReportAiSuggestion {
  FloodReportAiSuggestion._();

  static String labelFor(WaterLevelChoice level, String descriptionTrimmed) {
    final d = descriptionTrimmed.toLowerCase();
    if (d.contains('stranded') ||
        d.contains('trapped') ||
        d.contains('rescue')) {
      return 'Critical · life-safety signals (verify immediately)';
    }
    if (d.contains('collapsed') ||
        d.contains('debris jam') ||
        d.contains('landslide')) {
      return 'Severe · infrastructure / blockage cluster';
    }
    if (d.contains('rising fast') ||
        d.contains('swept') ||
        level == WaterLevelChoice.high) {
      return 'High inundation likelihood · dispatch field unit';
    }
    if (d.contains('stagnant') || d.contains('drain blocked')) {
      return 'Elevated sanitary / drainage hazard';
    }
    if (level == WaterLevelChoice.medium) {
      return 'Moderate surface flooding · corridor watch';
    }
    return 'Lower priority · nuisance / informational';
  }
}
