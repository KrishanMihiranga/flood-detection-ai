import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Kelani corridor–adjacent demo shapes (offline / no backend).
abstract final class DemoGeo {
  DemoGeo._();

  /// Fallback when GPS is unavailable.
  static const LatLng kelaniCorridorCenter = LatLng(6.9152, 79.9625);

  static const double defaultZoom = 13.15;

  static Set<Polygon> floodRiskPolygons() {
    const yellowStroke = Color(0xFFC49000);
    const redStroke = Color(0xFFC62828);
    const yellowSurface = Color(0x54FFCA28);
    const redSurface = Color(0x66EF5350);

    return {
      Polygon(
        polygonId: const PolygonId('elevated_yellowzone'),
        points: const [
          LatLng(6.8988, 79.9435),
          LatLng(6.9312, 79.9435),
          LatLng(6.9325, 79.9865),
          LatLng(6.9135, 79.9925),
          LatLng(6.8965, 79.9745),
        ],
        consumeTapEvents: true,
        fillColor: yellowSurface,
        strokeColor: yellowStroke,
        strokeWidth: 2,
      ),
      Polygon(
        polygonId: const PolygonId('high_red_zone'),
        points: const [
          LatLng(6.9072, 79.9575),
          LatLng(6.9178, 79.9575),
          LatLng(6.9198, 79.9745),
          LatLng(6.9135, 79.9835),
          LatLng(6.9045, 79.9745),
        ],
        consumeTapEvents: true,
        fillColor: redSurface,
        strokeColor: redStroke,
        strokeWidth: 2,
      ),
    };
  }

  static Set<Marker> shelterAndReportMarkers() {
    BitmapDescriptor hue(double h) =>
        BitmapDescriptor.defaultMarkerWithHue(h);

    return {
      Marker(
        markerId: const MarkerId('shelter_1'),
        position: const LatLng(6.9114, 79.9572),
        icon: hue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Community hall shelter',
          snippet: 'Capacity ~240 · dry-floor zone',
        ),
      ),
      Marker(
        markerId: const MarkerId('shelter_2'),
        position: const LatLng(6.9195, 79.9743),
        icon: hue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'School evacuation point',
          snippet: 'First-aid & water (demo)',
        ),
      ),
      Marker(
        markerId: const MarkerId('shelter_3_demo'),
        position: const LatLng(6.9046, 79.9745),
        icon: hue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: 'Ward readiness gymnasium',
          snippet: 'Open · 89 / 180 seated (demo)',
        ),
      ),
      Marker(
        markerId: const MarkerId('report_72h_1'),
        position: const LatLng(6.9127, 79.9645),
        icon: hue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'Community flood report',
          snippet: 'High water debris on approach road (demo)',
        ),
      ),
      Marker(
        markerId: const MarkerId('report_72h_2'),
        position: const LatLng(6.9172, 79.9622),
        icon: hue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: 'Community flood report',
          snippet: 'Slow drainage near bund (demo)',
        ),
      ),
      Marker(
        markerId: const MarkerId('report_72h_3'),
        position: const LatLng(6.9065, 79.9645),
        icon: hue(BitmapDescriptor.hueRose),
        infoWindow: const InfoWindow(
          title: 'Verified sensor + report',
          snippet: 'River gauge elevated (demo)',
        ),
      ),
    };
  }
}
