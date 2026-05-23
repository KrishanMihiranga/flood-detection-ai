import 'package:flutter/foundation.dart';

class _ApprovedReportsBroadcaster extends ChangeNotifier {
  void pulse() => notifyListeners();
}

/// Fires when moderator decisions arrive — map merges approved pins instantly.
abstract final class ApprovedReportsMapNotifier {
  ApprovedReportsMapNotifier._();

  static final _ApprovedReportsBroadcaster _impl =
      _ApprovedReportsBroadcaster();

  static void bump() => _impl.pulse();

  static void addListener(VoidCallback listener) =>
      _impl.addListener(listener);

  static void removeListener(VoidCallback listener) =>
      _impl.removeListener(listener);
}
