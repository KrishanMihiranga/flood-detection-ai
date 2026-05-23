import 'package:flutter/material.dart';

import '../../core/auth/auth_session_repository.dart';
import '../../core/demo/demo_credentials.dart';
import '../../core/notifications/alert_history_repository.dart';
import '../../core/notifications/broadcast_announcements_notifier.dart';
import '../../core/notifications/broadcast_supabase_sync.dart';
import '../../core/notifications/flood_alert_record.dart';
import '../../core/notifications/local_push_service.dart';
import '../../core/theme/app_colors.dart';

/// Admin composer for basin-wide bulletin text mirrored as alert-history + Supabase fan-out.
class AdminBroadcastAnnouncementScreen extends StatefulWidget {
  const AdminBroadcastAnnouncementScreen({super.key});

  @override
  State<AdminBroadcastAnnouncementScreen> createState() =>
      _AdminBroadcastAnnouncementScreenState();
}

class _AdminBroadcastAnnouncementScreenState
    extends State<AdminBroadcastAnnouncementScreen> {
  final _msg = TextEditingController();
  final _area = TextEditingController(
    text: 'Entire Flood Guard pilot polygon',
  );
  AlertSeverity _severity = AlertSeverity.warning;
  bool _loadingGate = true;
  bool _denied = false;
  bool _sending = false;

  Future<void> _gate() async {
    final ok = await AuthSessionRepository.isCurrentUserAdmin();
    if (!mounted) return;
    setState(() {
      _loadingGate = false;
      _denied = !ok;
    });
  }

  @override
  void initState() {
    super.initState();
    _gate();
  }

  @override
  void dispose() {
    _msg.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _onSendBulletinPressed() async {
    FocusScope.of(context).unfocus();
    final summary = _msg.text.trim();
    if (summary.length < 12) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Message should be at least ~12 characters.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send bulletin?'),
        content: const Text(
          'This saves to alert history on this device and shows a heads-up notification. '
          'You can hook Supabase later for cross-device sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _sendBulletinConfirmed();
  }

  Future<void> _sendBulletinConfirmed() async {
    setState(() => _sending = true);
    try {
      final summary = _msg.text.trim();
      final record = await AlertHistoryRepository.prependOfficialBroadcast(
        summary: summary,
        area: _area.text,
        severity: _severity,
      );

      BroadcastAnnouncementNotifier.pulseListsOnly();

      await LocalPushService.showOfficialBroadcast(
        title: record.title,
        summary: record.summary,
        areaSuffix: record.area,
      );

      await BroadcastSupabaseSync.publish(record);

      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Could not broadcast: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_loadingGate) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_denied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administrators only')),
        body: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'Only signed-in moderator accounts (${DemoCredentials.adminEmail}) '
                'can issue manual broadcasts.',
                style: textTheme.bodyLarge?.copyWith(height: 1.38),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dashboardCanvas,
      appBar: AppBar(
        title: const Text('Urgent broadcast'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFB54708).withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Human operator bulletin',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'After you confirm, the bulletin is saved locally, the alerts list '
                    'refreshes, and a device notification is shown. Supabase / FCM '
                    'can be wired later for other installs.',
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Message body',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _msg,
            minLines: 4,
            maxLines: 10,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText:
                  'e.g., Shelter A is full — proceed to Shelter B via embankment path.',
              alignLabelWithHint: true,
              filled: true,
              fillColor: AppColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Applies to (area)',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _area,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Watershed · ward segment',
              filled: true,
              fillColor: AppColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Severity band',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: AlertSeverity.values.map((sev) {
              final selected = _severity == sev;
              return ChoiceChip(
                label: Text(sev.name.toUpperCase()),
                selected: selected,
                selectedColor:
                    AppColors.ctaBackground.withValues(alpha: 0.28),
                onSelected: (_) => setState(() => _severity = sev),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),
          FilledButton.icon(
            onPressed: _sending ? null : _onSendBulletinPressed,
            icon: Icon(
              Icons.send_rounded,
              color:
                  _sending ? Colors.white54 : Colors.white,
            ),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _sending ? 'Publishing…' : 'Send bulletin now',
              ),
            ),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              backgroundColor: AppColors.ctaBackground,
              foregroundColor: AppColors.ctaForeground,
            ),
          ),
        ],
      ),
    );
  }
}
