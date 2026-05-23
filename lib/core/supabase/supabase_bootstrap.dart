import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

abstract final class SupabaseBootstrap {
  SupabaseBootstrap._();

  /// No-op unless [SupabaseConfig.isConfigured].
  static Future<void> initializeIfConfigured() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('Supabase: skipped (SUPABASE_URL / SUPABASE_ANON_KEY not set).');
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('Supabase client initialized (${SupabaseConfig.url}).');
  }
}
