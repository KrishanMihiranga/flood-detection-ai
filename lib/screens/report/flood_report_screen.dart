import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/maps/demo_geo.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/reports/flood_reports_repository.dart';
import '../../core/reports/water_level_choice.dart';
import '../../core/theme/app_colors.dart';
class FloodReportScreen extends StatefulWidget {
  const FloodReportScreen({
    super.key,
    this.prefillLatLng,
    this.embeddedInTabbedShell = false,
  });

  final LatLng? prefillLatLng;
  final bool embeddedInTabbedShell;

  @override
  State<FloodReportScreen> createState() => _FloodReportScreenState();
}

class _FloodReportScreenState extends State<FloodReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtl = TextEditingController();
  final _phoneCtl =
      TextEditingController(text: DemoCredentials.demoReporterPhone);
  WaterLevelChoice _level = WaterLevelChoice.medium;

  LatLng _pin = DemoGeo.kelaniCorridorCenter;
  bool _pinLockedFromMap = false;
  XFile? _attachment;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefillLatLng != null) {
      _pin = widget.prefillLatLng!;
    } else {
      unawaited(_captureGps());
    }
  }

  @override
  void dispose() {
    _descriptionCtl.dispose();
    _phoneCtl.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    if (_pinLockedFromMap) return;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return;
      setState(() {
        _pin = LatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {
      /* non-fatal for prototype */
    }
  }

  String _coordsLabel(LatLng p) =>
      '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';

  Future<void> _pickImage(ImageSource src) async {
    try {
      final file = await ImagePicker().pickImage(
        source: src,
        maxWidth: 1800,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _attachment = file);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Could not reach camera/gallery (${e.code})')),
      );
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => FloodCoordinatePickScreen(initial: _pin),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _pin = result;
      _pinLockedFromMap = true;
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await FloodReportsRepository.submitReport(
        reporterPhone: _phoneCtl.text.trim(),
        description: _descriptionCtl.text,
        observedLevel: _level,
        latitude: _pin.latitude,
        longitude: _pin.longitude,
        photoFileMaybe:
            _attachment != null ? File(_attachment!.path) : null,
      );
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            'Queued as pending moderation (${_coordsLabel(_pin)} • ${_level.pickerLabel})',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('$e\n$st');
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Could not save report: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      primary: !widget.embeddedInTabbedShell,
      appBar: AppBar(
        title: const Text('Report a flood'),
        automaticallyImplyLeading: !widget.embeddedInTabbedShell,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 108),
          children: [
            Text(
              'Your contact phone',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneCtl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Used only for field follow-up',
                prefixIcon: Icon(Icons.phone_android_outlined),
              ),
              validator: (v) {
                final digits = RegExp(r'\d').allMatches(v ?? '').length;
                if (digits < 9) return 'Enter at least ~9 digits / a valid local number';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Describe what you are seeing.',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionCtl,
              minLines: 4,
              maxLines: 8,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Road blockage, debris, depth, stranded people…',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length < 14) return 'Please add at least ~14 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Observed water level',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SegmentedButton<WaterLevelChoice>(
              multiSelectionEnabled: false,
              showSelectedIcon: false,
              emptySelectionAllowed: false,
              segments: WaterLevelChoice.values.map((e) {
                return ButtonSegment<WaterLevelChoice>(
                  value: e,
                  tooltip: e.pickerLabel,
                  icon: Icon(e.icon, size: 18),
                  label: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(e.compactLabel),
                  ),
                );
              }).toList(),
              selected: {_level},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) return;
                setState(() => _level = selection.first);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _level.pickerLabel,
                style:
                    textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Photo (optional)',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
                if (_attachment != null)
                  TextButton(
                    onPressed: () => setState(() => _attachment = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            if (_attachment != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.file(File(_attachment!.path), fit: BoxFit.cover),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Text(
              'Location',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap “Pick on map” to refine the marker. Refresh GPS resets to handset fix unless you pinned manually.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _coordsLabel(_pin),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickOnMap,
                          child: const Text('Pick on map'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        tooltip: 'Use GPS fix',
                        onPressed: () {
                          setState(() => _pinLockedFromMap = false);
                          unawaited(_captureGps());
                        },
                        icon: const Icon(Icons.gps_fixed_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.ctaBackground,
                foregroundColor: AppColors.ctaForeground,
              ),
              onPressed: _saving ? null : () => _submit(),
              icon: _saving
                  ? SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ctaForeground,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _saving ? 'Saving…' : 'Submit report (offline demo)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight full-screen picker for dropping a latitude/longitude marker.
class FloodCoordinatePickScreen extends StatefulWidget {
  const FloodCoordinatePickScreen({super.key, required this.initial});

  final LatLng initial;

  @override
  State<FloodCoordinatePickScreen> createState() =>
      _FloodCoordinatePickScreenState();
}

class _FloodCoordinatePickScreenState extends State<FloodCoordinatePickScreen> {
  late LatLng _draft;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  Marker get _handle => Marker(
        markerId: const MarkerId('draft_pin'),
        position: _draft,
        draggable: true,
        onDragEnd: (p) => setState(() => _draft = p),
        infoWindow: const InfoWindow(title: 'Report will use this coordinate'),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adjust coordinate'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_draft),
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('Use here', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.initial,
                zoom: DemoGeo.defaultZoom + 2,
              ),
              markers: {_handle},
              onMapCreated: (c) => _controller = c,
              onTap: (latLng) {
                setState(() => _draft = latLng);
                _controller?.animateCamera(CameraUpdate.newLatLng(latLng));
              },
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'Tap the map or drag the pin.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
