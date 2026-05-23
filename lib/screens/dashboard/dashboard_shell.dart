import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/alert_history_repository.dart';
import '../../core/notifications/broadcast_announcements_notifier.dart';
import '../../core/notifications/broadcast_supabase_sync.dart';
import '../../core/notifications/flood_alert_record.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/dashboard/frosted_bottom_nav.dart';
import '../map/flood_map_tab.dart';
import 'dashboard_home_tab.dart';
import 'dashboard_profile_tab.dart';

/// Post-auth shell: frosted bottom nav wrapping Home, Map, Profile (demo / no backend).
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  /// Clears the stack and shows the dashboard (demo flow).
  static void openReplaceAll(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const DashboardShell()),
      (route) => false,
    );
  }

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;
  RealtimeChannel? _broadcastChannel;

  @override
  void initState() {
    super.initState();
    BroadcastAnnouncementNotifier.addListener(_onBroadcastHud);
    unawaited(_subscribeBroadcastRealtime());
  }

  @override
  void dispose() {
    BroadcastAnnouncementNotifier.removeListener(_onBroadcastHud);
    try {
      _broadcastChannel?.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  void _onBroadcastHud() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final line = BroadcastAnnouncementNotifier.takeQueuedSnackOverlay();
      if (line == null) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Official broadcast · $line'),
        ),
      );
    });
  }

  Future<void> _subscribeBroadcastRealtime() async {
    if (!SupabaseConfig.isConfigured) return;
    try {
      _broadcastChannel?.unsubscribe();
      _broadcastChannel =
          Supabase.instance.client.channel('shell_broadcast_fanout').onPostgresChanges(
                schema: 'public',
                table: SupabaseConfig.broadcastTable,
                event: PostgresChangeEvent.insert,
                callback: _onRemoteBroadcastInserted,
              )
              ..subscribe();
    } catch (_) {
      /* Publication / privileges may lag table creation */
    }
  }

  void _onRemoteBroadcastInserted(dynamic payload) async {
    final nr = payload.newRecord;
    if (nr == null || nr is! Map) return;
    final row = Map<String, dynamic>.from(nr);

    FloodAlertRecord? mapped;
    try {
      mapped = BroadcastSupabaseSync.recordFromRealtimeRow(Map<String, dynamic>.from(row));
    } catch (_) {
      mapped = null;
    }
    if (mapped == null) return;
    final added =
        await AlertHistoryRepository.mergeInboundBroadcastIfNew(mapped);
    if (!added || !mounted) return;
    BroadcastAnnouncementNotifier.pulseListsAndSnack(mapped.summary);
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _index.clamp(0, 2);

    return Material(
      color: AppColors.dashboardCanvas,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.dashboardCanvas,
          extendBody: true,
          body: IndexedStack(
            index: tabIndex,
            children: const [
              DashboardHomeTab(),
              FloodMapTab(),
              DashboardProfileTab(),
            ],
          ),
          bottomNavigationBar: Material(
            type: MaterialType.transparency,
            child: FrostedBottomNav(
              currentIndex: tabIndex,
              onSelect: (i) => setState(() => _index = i),
            ),
          ),
        ),
      ),
    );
  }
}
