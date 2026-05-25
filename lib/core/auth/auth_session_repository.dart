import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../demo/demo_credentials.dart';
import '../supabase/supabase_config.dart';
import 'user_role.dart';

/// Stores the signed-in email after auth flows; integrates with Supabase Auth when configured.
abstract final class AuthSessionRepository {
  AuthSessionRepository._();

  static const _emailKey = 'flood_guard_signed_in_email_v1';

  static Future<void> persistSignedInEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email.trim());
  }

  static Future<String?> signedInEmail() async {
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) return user.email;
    }
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
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final data = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          if (data != null && data['role'] == 'admin') {
            return UserRole.admin;
          }
        } catch (_) {
          // Fallback to email check if network fails or profile does not exist yet
          return roleForEmail(user.email);
        }
      }
    }
    final e = await signedInEmail();
    return roleForEmail(e);
  }

  static Future<bool> isCurrentUserAdmin() async {
    final role = await currentRole();
    return role == UserRole.admin;
  }

  static Future<String> displayName() async {
    if (SupabaseConfig.isConfigured) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final data = await Supabase.instance.client
              .from('profiles')
              .select('display_name')
              .eq('id', user.id)
              .maybeSingle();
          if (data != null && data['display_name'] != null) {
            final name = data['display_name'].toString().trim();
            if (name.isNotEmpty) return name;
          }
        } catch (_) {}
        
        final metaName = user.userMetadata?['display_name']?.toString().trim();
        if (metaName != null && metaName.isNotEmpty) return metaName;
        
        if (user.email != null) {
          final prefix = user.email!.split('@').first;
          if (prefix.isNotEmpty) {
            return prefix[0].toUpperCase() + prefix.substring(1);
          }
        }
      }
    }
    return DemoCredentials.displayName;
  }

  /// Clears session (either Supabase or local mock session).
  static Future<void> clearSession() async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
  }
}
