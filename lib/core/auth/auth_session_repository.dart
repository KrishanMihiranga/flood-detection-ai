import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo_credentials.dart';
import 'user_role.dart';

/// Stores the signed-in email after stub auth flows; role is inferred from email.
abstract final class AuthSessionRepository {
  AuthSessionRepository._();

  static const _emailKey = 'flood_guard_signed_in_email_v1';

  static Future<void> persistSignedInEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim());
  }

  static Future<String?> signedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailKey)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// Treats **[DemoCredentials.adminEmail]** as the only admin inbox for QA.
  static UserRole roleForEmail(String? email) {
    final match = email?.trim().toLowerCase();
    if (match == DemoCredentials.adminEmail.toLowerCase()) {
      return UserRole.admin;
    }
    return UserRole.citizen;
  }

  static Future<UserRole> currentRole() async {
    final e = await signedInEmail();
    return roleForEmail(e);
  }

  static Future<bool> isCurrentUserAdmin() async {
    final e = await signedInEmail();
    return roleForEmail(e) == UserRole.admin;
  }

  /// Clears stub session (signed-in email). Local data like reports is kept.
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
  }
}
