import 'package:flutter/material.dart';

import '../../core/notifications/alert_history_repository.dart';
import '../../core/notifications/broadcast_announcements_notifier.dart';
import '../../core/notifications/flood_alert_record.dart';
import '../../core/theme/app_colors.dart';

/// Lists persisted push-style bulletins; tap a row for full issued time and area.
class AlertsNotificationHistoryScreen extends StatefulWidget {
  const AlertsNotificationHistoryScreen({super.key});

  @override
  State<AlertsNotificationHistoryScreen> createState() =>
      _AlertsNotificationHistoryScreenState();
}

class _AlertsNotificationHistoryScreenState
    extends State<AlertsNotificationHistoryScreen> {
  late Future<List<FloodAlertRecord>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = AlertHistoryRepository.loadAlerts();
    BroadcastAnnouncementNotifier.addListener(_pulseReloadAlerts);
  }

  @override
  void dispose() {
    BroadcastAnnouncementNotifier.removeListener(_pulseReloadAlerts);
    super.dispose();
  }

  void _pulseReloadAlerts() {
    if (mounted) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _alertsFuture = AlertHistoryRepository.loadAlerts();
    });
    await _alertsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.dashboardCanvas,
      appBar: AppBar(
        title: const Text('Alerts & notification history'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<FloodAlertRecord>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Could not load history.',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.35,
                  ),
                  Center(
                    child: Text(
                      'No alerts yet.\nAutomatic notifications will appear here.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: alerts.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = alerts[i];
                return _AlertListTile(
                  record: a,
                  onTap: () => _openDetail(context, a),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, FloodAlertRecord record) {
    final textTheme = Theme.of(context).textTheme;
    final loc = MaterialLocalizations.of(context);
    final issued = record.issuedAt.toLocal();
    final issuedLine =
        '${loc.formatMediumDate(issued)} · ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(issued))}';
    final sev = _severityStyle(record.severity);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.paddingOf(ctx).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: sev.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        sev.label,
                        style: textTheme.labelSmall?.copyWith(
                          color: sev.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Issued',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issuedLine,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Area',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 22,
                      color: AppColors.ctaBackground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.area,
                        style: textTheme.bodyLarge?.copyWith(
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Details',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.summary,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertListTile extends StatelessWidget {
  const _AlertListTile({
    required this.record,
    required this.onTap,
  });

  final FloodAlertRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sev = _severityStyle(record.severity);
    final relative = _relativeTime(record.issuedAt);

    return Material(
      color: AppColors.background,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sev.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      sev.short,
                      style: textTheme.labelSmall?.copyWith(
                        color: sev.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                record.summary,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.area,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    relative,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeverityStyle {
  const _SeverityStyle({
    required this.label,
    required this.short,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String short;
  final Color background;
  final Color foreground;
}

_SeverityStyle _severityStyle(AlertSeverity s) {
  switch (s) {
    case AlertSeverity.warning:
      return const _SeverityStyle(
        label: 'Warning',
        short: 'Warn',
        background: Color(0xFFFFF0F0),
        foreground: Color(0xFFB42318),
      );
    case AlertSeverity.watch:
      return const _SeverityStyle(
        label: 'Watch',
        short: 'Watch',
        background: Color(0xFFFFF6E8),
        foreground: Color(0xFFB54708),
      );
    case AlertSeverity.advisory:
      return const _SeverityStyle(
        label: 'Advisory',
        short: 'Advise',
        background: Color(0xFFFFF8EB),
        foreground: Color(0xFFA15C07),
      );
    case AlertSeverity.info:
      return const _SeverityStyle(
        label: 'Info',
        short: 'Info',
        background: Color(0xFFEFF9FA),
        foreground: Color(0xFF0B6470),
      );
  }
}

String _relativeTime(DateTime issuedAt) {
  final d = DateTime.now().difference(issuedAt);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 48) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
