import 'package:flutter/services.dart';

/// System bars match the white app chrome (no black bands behind status / nav).
abstract final class AppSystemUi {
  AppSystemUi._();

  /// Opaque white bars + dark icons (readable clock, battery, 3-button nav).
  static const SystemUiOverlayStyle lightWhiteBars = SystemUiOverlayStyle(
    statusBarColor: Color(0xFFFFFFFF),
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFFFFFFF),
    systemNavigationBarDividerColor: Color(0xFFE8E8E8),
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  );

  static Future<void> initLightChrome() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(lightWhiteBars);
  }
}
