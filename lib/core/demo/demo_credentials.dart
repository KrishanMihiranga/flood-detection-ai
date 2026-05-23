/// Pre-filled demo values for QA / prototype flows — not for production builds.
abstract final class DemoCredentials {
  DemoCredentials._();

  static const String email = 'demo@floodguard.ai';

  /// Shown on the dashboard greeting.
  static const String displayName = 'Priya';

  /// Meets validators (≥ 8 chars).
  static const String password = 'demo12345';

  /// OTP when [length] is 6.
  static const String otp6 = '424242';

  /// Sign in with **[adminEmail]** to unlock moderator tools (offline demo heuristic).
  static const String adminEmail = 'admin@floodguard.ai';

  /// Pre-filled on the citizen flood report form for QA.
  static const String demoReporterPhone = '+94 71 555 0192';

  /// OTP when [length] is 4.
  static const String otp4 = '4242';

  static String otpForLength(int length) {
    return length == 4 ? otp4 : otp6;
  }
}
