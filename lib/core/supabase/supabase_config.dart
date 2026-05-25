/// Compile-time overrides — pass `--dart-define=SUPABASE_URL=...` builds.
abstract final class SupabaseConfig {
  SupabaseConfig._();

  /// Project URL (`https://xxxxx.supabase.co`).
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Public anon key (tighten RLS in prod).
  static const anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Rows written when an admin verifies a report (`upsert`).
  static const moderationTable = 'flood_report_moderation';

  /// Bulletin inserts admins fan out via Realtime (see `broadcast_supabase_sync.dart`).
  static const broadcastTable = 'broadcast_announcements';

  /// Storage bucket for citizen report photo uploads.
  static const reportsBucket = 'report_photos';

  static bool get isConfigured =>
      url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
