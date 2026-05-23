abstract final class CredentialsValidator {
  static final RegExp _emailLoose =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return 'Enter your email.';
    if (!_emailLoose.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? passwordSignIn(String raw) {
    if (raw.isEmpty) return 'Enter your password.';
    if (raw.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  /// Sign-up: reuse same minimum rule; extend later (uppercase, etc.).
  static String? passwordSignUp(String raw) {
    if (raw.isEmpty) return 'Choose a password.';
    if (raw.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? confirmPassword({
    required String password,
    required String confirm,
  }) {
    if (confirm.isEmpty) return 'Re-enter your password.';
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }
}
