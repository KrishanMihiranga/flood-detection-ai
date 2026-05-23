import 'package:flutter/foundation.dart';

class _BroadcastAnnouncementHub extends ChangeNotifier {
  /// Only [BroadcastAnnouncementNotifier.takeQueuedSnackOverlay] consumes this.
  String? _queuedSnackTail;

  /// Alerts list reload without surfacing dashboard snack HUD.
  void pulseReloadListsOnly() => notifyListeners();

  void scheduleSnackSummary(String snippet) {
    final t = snippet.trim();
    if (t.isEmpty) {
      _queuedSnackTail = 'Official broadcast';
    } else if (t.length > 140) {
      _queuedSnackTail = '${t.substring(0, 137)}…';
    } else {
      _queuedSnackTail = t;
    }
    notifyListeners();
  }

  String? takeQueuedSnackOverlay() {
    final s = _queuedSnackTail;
    _queuedSnackTail = null;
    return s;
  }
}

/// Alerts list listens for reload pulses; Dashboard shell peels snack copy once.
abstract final class BroadcastAnnouncementNotifier {
  BroadcastAnnouncementNotifier._();

  static final _BroadcastAnnouncementHub _impl = _BroadcastAnnouncementHub();

  static void pulseListsAndSnack(String snippetForSnack) {
    _impl.scheduleSnackSummary(snippetForSnack);
  }

  /// Same list reload pulse as [pulseListsAndSnack] without enqueueing banner snack copy.
  static void pulseListsOnly() => _impl.pulseReloadListsOnly();

  static String? takeQueuedSnackOverlay() => _impl.takeQueuedSnackOverlay();

  static void addListener(VoidCallback l) => _impl.addListener(l);

  static void removeListener(VoidCallback l) => _impl.removeListener(l);
}
