import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../reports/flood_report_record.dart';

/// Map pins for moderator-approved submissions (shown to all users locally).
abstract final class VerifiedReportMarkers {
  VerifiedReportMarkers._();

  static Set<Marker> fromApprovedReports(List<CitizenFloodReport> approved) {
    BitmapDescriptor hue(double h) =>
        BitmapDescriptor.defaultMarkerWithHue(h);

    return approved.map((r) {
      final snippet = _snippet(r.description, 76);
      return Marker(
        markerId: MarkerId('verified_broadcast_${r.id}'),
        position: LatLng(r.latitude, r.longitude),
        icon: hue(BitmapDescriptor.hueGreen),
        consumeTapEvents: true,
        infoWindow: InfoWindow(
          title: 'Verified community report',
          snippet: snippet,
        ),
      );
    }).toSet();
  }

  static String _snippet(String raw, int maxChars) {
    final t = raw.trim();
    if (t.length <= maxChars) return t.isEmpty ? 'Approved · see moderator feed' : t;
    return '${t.substring(0, maxChars - 1)}…';
  }
}
