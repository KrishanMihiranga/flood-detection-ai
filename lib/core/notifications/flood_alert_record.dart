import 'dart:convert';

/// One saved push / bulletin item (offline demo + local persistence until FCM/backend).
class FloodAlertRecord {
  const FloodAlertRecord({
    required this.id,
    required this.title,
    required this.summary,
    required this.area,
    required this.issuedAt,
    required this.severity,
  });

  final String id;
  final String title;
  final String summary;
  /// Human-readable watershed / ward label.
  final String area;
  final DateTime issuedAt;
  final AlertSeverity severity;

  FloodAlertRecord copyWith({
    String? id,
    String? title,
    String? summary,
    String? area,
    DateTime? issuedAt,
    AlertSeverity? severity,
  }) {
    return FloodAlertRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      area: area ?? this.area,
      issuedAt: issuedAt ?? this.issuedAt,
      severity: severity ?? this.severity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'area': area,
        'issuedAt': issuedAt.toIso8601String(),
        'severity': severity.name,
      };

  static FloodAlertRecord fromJson(Map<String, dynamic> json) {
    return FloodAlertRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Alert',
      summary: json['summary'] as String? ?? '',
      area: json['area'] as String? ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt'] as String? ?? '') ??
          DateTime.now(),
      severity: _parseSeverity(json['severity'] as String?),
    );
  }

  static AlertSeverity _parseSeverity(String? raw) {
    for (final v in AlertSeverity.values) {
      if (v.name == raw) return v;
    }
    return AlertSeverity.watch;
  }

  static String encodeList(List<FloodAlertRecord> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<FloodAlertRecord> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((e) => FloodAlertRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

enum AlertSeverity {
  info,
  advisory,
  watch,
  warning,
}
