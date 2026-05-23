import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/maps/demo_geo.dart';
import '../../core/maps/verified_report_markers.dart';
import '../../core/reports/approved_reports_map_notifier.dart';
import '../../core/reports/flood_reports_repository.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../report/flood_report_screen.dart';
import '../shelters/shelter_safe_route_hub_screen.dart';

/// Live-ish Google Map hub: zones, shelters, demo reports + quick actions.
class FloodMapTab extends StatefulWidget {
  const FloodMapTab({super.key});

  @override
  State<FloodMapTab> createState() => _FloodMapTabState();
}

class _FloodMapTabState extends State<FloodMapTab> {
  GoogleMapController? _controller;

  CameraPosition get _fallbackCamera => const CameraPosition(
        target: DemoGeo.kelaniCorridorCenter,
        zoom: DemoGeo.defaultZoom,
      );

  final Set<Polygon> _polygons = DemoGeo.floodRiskPolygons();
  late Set<Marker> _markers;
  RealtimeChannel? _moderationRealtime;

  LatLng _mapGuessCenter = DemoGeo.kelaniCorridorCenter;
  Position? _lastFix;
  bool _locationLayerEnabled = false;

  static const Color _legendRed = Color(0xFFD32F2F);
  static const Color _legendAmber = Color(0xFFF9A825);
  static const Color _legendGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _markers = {...DemoGeo.shelterAndReportMarkers()};
    ApprovedReportsMapNotifier.addListener(_onApprovedPinsChanged);
    unawaited(_initLocation());
    unawaited(_mergeVerifiedPins());
    _subscribeModerationMirror();
  }

  void _onApprovedPinsChanged() {
    unawaited(_mergeVerifiedPins());
  }

  Future<void> _mergeVerifiedPins() async {
    final approved =
        await FloodReportsRepository.loadApprovedForBroadcastMap();
    if (!mounted) return;
    setState(() {
      _markers = {
        ...DemoGeo.shelterAndReportMarkers(),
        ...VerifiedReportMarkers.fromApprovedReports(approved),
      };
    });
  }

  void _subscribeModerationMirror() {
    if (!SupabaseConfig.isConfigured) return;
    try {
      _moderationRealtime = Supabase.instance.client
          .channel('moderation_fanout_mobile')
          .onPostgresChanges(
            schema: 'public',
            table: SupabaseConfig.moderationTable,
            event: PostgresChangeEvent.all,
            callback: (_) => ApprovedReportsMapNotifier.bump(),
          )
          .subscribe();
    } catch (_) {
      /* Realtime/table may not be provisioned yet */
    }
  }

  @override
  void dispose() {
    ApprovedReportsMapNotifier.removeListener(_onApprovedPinsChanged);
    try {
      _moderationRealtime?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initLocation() async {
    final ok = await _ensurePermission();
    if (!mounted || !ok) return;
    try {
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _lastFix = fix;
        _locationLayerEnabled = true;
        _mapGuessCenter = LatLng(fix.latitude, fix.longitude);
      });
      await _animateTo(_mapGuessCenter);
    } catch (_) {
      if (!mounted) return;
      _toast('Using demo map center — GPS fix timed out or was unavailable.');
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _toast('Turn on Location Services to see your position on the map.');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _toast('Location permission denied — demo overlays still available.');
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      _toast('Location blocked in system settings — enable to use GPS.');
      return false;
    }
    return true;
  }

  Future<void> _animateTo(LatLng target) async {
    final c = _controller;
    if (c == null) return;
    await c.animateCamera(
      CameraUpdate.newLatLngZoom(target, DemoGeo.defaultZoom),
    );
  }

  Future<LatLng> _visibleCenter() async {
    final c = _controller;
    if (c == null) return _mapGuessCenter;
    try {
      final region = await c.getVisibleRegion();
      return LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      );
    } catch (_) {
      return _mapGuessCenter;
    }
  }

  Future<void> _recenterOnUser() async {
    final ok = await _ensurePermission();
    if (!ok || !mounted) return;
    try {
      final fix = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );
      if (!mounted) return;
      final target = LatLng(fix.latitude, fix.longitude);
      setState(() {
        _lastFix = fix;
        _locationLayerEnabled = true;
      });
      await _animateTo(target);
    } catch (_) {
      _toast('Could not refresh GPS.');
    }
  }

  Future<void> _presentReportComposer() async {
    final gps = (_lastFix != null)
        ? LatLng(_lastFix!.latitude, _lastFix!.longitude)
        : await _visibleCenter();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FloodReportScreen(
          prefillLatLng: gps,
          embeddedInTabbedShell: false,
        ),
      ),
    );
  }

  Future<void> _presentSafeRoutes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ShelterSafeRouteHubScreen(),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top + 8;
    // Sit just above frosted nav (compact actions — less vertical lift than full-width buttons).
    final actionStackBottom = mq.padding.bottom + 56;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: _fallbackCamera,
            myLocationEnabled: _locationLayerEnabled,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            polygons: _polygons,
            markers: _markers,
            onMapCreated: (c) {
              _controller = c;
              if (_lastFix != null) {
                final t = LatLng(_lastFix!.latitude, _lastFix!.longitude);
                unawaited(
                  c.animateCamera(
                    CameraUpdate.newLatLngZoom(t, DemoGeo.defaultZoom),
                  ),
                );
              }
            },
            onCameraIdle: () async {
              final ctr = await _visibleCenter();
              if (mounted) {
                setState(() => _mapGuessCenter = ctr);
              }
            },
          ),
        ),

        Positioned(
          left: 12,
          top: topInset,
          child: Card(
            elevation: 2,
            color: Colors.white.withValues(alpha: 0.94),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendDot(_legendRed),
                      const SizedBox(width: 6),
                      Text(
                        'High-risk zone',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendDot(_legendAmber),
                      const SizedBox(width: 6),
                      Text(
                        'Elevated risk',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _legendDot(_legendGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Verified report (approved)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          right: 10,
          top: topInset,
          child: Material(
            color: Colors.white,
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _recenterOnUser,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.my_location_rounded, color: AppColors.ctaBackground),
              ),
            ),
          ),
        ),

        Positioned(
          right: 10,
          bottom: actionStackBottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Report a flood',
                child: Material(
                  color: AppColors.ctaBackground,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _presentReportComposer,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.crisis_alert_outlined,
                        size: 22,
                        color: AppColors.ctaForeground,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Tooltip(
                message: 'Safe routes',
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _presentSafeRoutes,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.alt_route_rounded,
                        size: 22,
                        color: AppColors.ctaBackground,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color c) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
      ),
    );
  }
}
