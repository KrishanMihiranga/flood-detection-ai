import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/reports/flood_report_record.dart';
import '../../core/reports/flood_reports_repository.dart';
import '../../core/reports/moderation_supabase_sync.dart';
import '../../core/reports/water_level_choice.dart';
import '../../core/theme/app_colors.dart';

/// Full-screen moderator review (`admin` only). Commits verdict locally + mirrors Supabase.
class AdminReportVerificationScreen extends StatefulWidget {
  const AdminReportVerificationScreen({super.key, required this.report});

  final CitizenFloodReport report;

  @override
  State<AdminReportVerificationScreen> createState() =>
      _AdminReportVerificationScreenState();
}

class _AdminReportVerificationScreenState
    extends State<AdminReportVerificationScreen> {
  bool _gateDenied = false;
  bool _loadingGate = true;
  bool _processing = false;
  File? _photoFile;

  CitizenFloodReport get _r => widget.report;

  bool get _isPending => _r.status == FloodReportWorkflowStatus.pending;

  @override
  void initState() {
    super.initState();
    unawaited(_initGateAndPhoto());
  }

  Future<void> _initGateAndPhoto() async {
    final admin = await AuthSessionRepository.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _loadingGate = false;
      _gateDenied = !admin;
    });

    final f = await FloodReportsRepository.resolvePhoto(_r);
    if (!mounted) return;
    setState(() => _photoFile = f);
  }

  Future<void> _commit(FloodReportWorkflowStatus decision) async {
    if (!_isPending || _processing || _gateDenied) return;
    setState(() => _processing = true);
    try {
      final persisted = await FloodReportsRepository.applyModerationDecision(
        _r.id,
        decision,
      );
      if (!persisted || !mounted) {
        throw StateError('Unable to persist moderation outcome.');
      }

      final remoteStatus = await ModerationSupabaseSync.pushModerationDecision(
        report: _r.copyWith(status: decision),
        decision: decision,
      );

      if (!mounted) return;

      final msg = switch (decision) {
        FloodReportWorkflowStatus.approved => switch (remoteStatus) {
            ModerationRemoteSync.sent =>
              'Approved — alert mirrored to Supabase; map refreshed for pilots.',
            ModerationRemoteSync.failed =>
              'Approved locally — Supabase uplink failed (check network / schema). Map updated here.',
            ModerationRemoteSync.skippedMissingConfig =>
              'Approved locally — add SUPABASE_URL + SUPABASE_ANON_KEY to mirror cloud-wide.',
          },
        FloodReportWorkflowStatus.rejected => switch (remoteStatus) {
            ModerationRemoteSync.sent => 'Marked as rejected / spam · Supabase updated.',
            ModerationRemoteSync.failed =>
              'Marked locally — Supabase sync failed.',
            ModerationRemoteSync.skippedMissingConfig =>
              'Marked locally — configure Supabase to fan out rejects.',
          },
        _ => 'Updated.',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)),
      );

      if (mounted && context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _confirmRejectAsSpam() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject / spam?'),
        content: const Text(
          'This hides the submission from moderators and will not broadcast a map pin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (go == true && mounted) await _commit(FloodReportWorkflowStatus.rejected);
  }

  String _formattedWhen(MaterialLocalizations loc, DateTime t) {
    final d = t.toLocal();
    return '${loc.formatMediumDate(d)} · '
        '${loc.formatTimeOfDay(TimeOfDay.fromDateTime(d))}';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);

    if (_loadingGate) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_gateDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administrators only')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 48),
                const SizedBox(height: 12),
                Text(
                  'This verification console is restricted to moderator accounts.',
                  style: textTheme.bodyLarge?.copyWith(height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.dashboardCanvas,
      appBar: AppBar(
        title: const Text('Verify report'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isPending)
            Material(
              color: const Color(0xFFFFF6E8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Text(
                  'This submission was already moderated (${_r.status.name}). '
                  'Returning to pending queue will not show duplicate cards.',
                  style: textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              children: [
                Text(
                  'Evidence narrative',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  _r.description,
                  style: textTheme.titleSmall?.copyWith(
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _MetaRow(icon: Icons.schedule_outlined, text: _formattedWhen(loc, _r.submittedAt)),
                const SizedBox(height: 10),
                _MetaRow(
                  icon: Icons.phone_android_outlined,
                  text: _r.reporterPhone,
                  emphasize: true,
                ),
                const SizedBox(height: 10),
                _MetaRow(
                  icon: Icons.place_outlined,
                  text:
                      '${_r.latitude.toStringAsFixed(5)}, ${_r.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 10),
                _MetaRow(
                  icon: _r.observedLevel.icon,
                  text:
                      '${_r.observedLevel.compactLabel} water · ${_r.observedLevel.pickerLabel}',
                ),
                const SizedBox(height: 20),
                Text(
                  'AI suggested classification',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.ctaBackground.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.psychology_outlined,
                          color: AppColors.ctaBackground),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _r.aiSuggestedRiskLabel,
                          style: textTheme.bodyMedium?.copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Uploaded photo',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                if (_photoFile != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.file(_photoFile!, fit: BoxFit.cover),
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: SizedBox(
                      height: 160,
                      child: Center(
                        child: Text(
                          'No photo attached.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 10, 20, 14 + bottomInset),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: _isPending
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: _processing
                            ? null
                            : () => _commit(
                                  FloodReportWorkflowStatus.approved,
                                ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.ctaBackground,
                          foregroundColor: AppColors.ctaForeground,
                        ),
                        icon: Icon(Icons.notifications_active_rounded),
                        label: Text(
                          _processing ? 'Publishing…' : 'Approve & broadcast alert',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _processing ? null : _confirmRejectAsSpam,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                          side: const BorderSide(color: Color(0xFFB42318)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(Icons.report_off_rounded),
                        label: Text(
                          _processing ? 'Please wait…' : 'Reject / mark as spam',
                        ),
                      ),
                    ],
                  )
                : OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 20,
            color: emphasize ? AppColors.ctaBackground : AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: (emphasize ? t.titleSmall : t.bodyMedium)?.copyWith(
                  fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
                  height: 1.35,
                ),
          ),
        ),
      ],
    );
  }
}
