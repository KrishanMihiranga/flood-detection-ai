import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import 'local_push_service.dart';

/// Service managing Firebase Cloud Messaging (FCM) registration, topics, and token uplink to Supabase.
abstract final class FcmService {
  FcmService._();

  static bool _initialized = false;

  /// Initializes FCM and requests push notification permissions.
  /// Fails gracefully if native Firebase configs are not present.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Initialize Firebase App (fails gracefully if google-services config is missing)
      await Firebase.initializeApp();

      // 2. Request Notification Permission
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // 3. Subscribe to the global topic "all_users"
      await messaging.subscribeToTopic('all_users');
      debugPrint('FCM: Subscribed to all_users topic.');

      // 4. Handle foreground messages (delegate to LocalPushService)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM: Foreground message received: ${message.messageId}');
        final notification = message.notification;
        if (notification != null) {
          LocalPushService.showOfficialBroadcast(
            title: notification.title ?? 'Official broadcast',
            summary: notification.body ?? '',
            areaSuffix: message.data['area'] as String?,
          );
        }
      });

      // 5. Handle background message tap/action
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM: App opened from notification: ${message.messageId}');
      });

      _initialized = true;
      debugPrint('FCM: Initialized successfully.');

      // Sync token if user is already logged in
      await registerDeviceToken();
    } catch (e, st) {
      debugPrint('FCM: Initialization skipped or failed (unconfigured native client): $e\n$st');
    }
  }

  /// Registers the current device token to Supabase under public.user_device_tokens.
  static Future<void> registerDeviceToken() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('FCM: Skipping token upload (user not logged in).');
        return;
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint('FCM: No device token resolved.');
        return;
      }

      debugPrint('FCM: Registering device token to Supabase for user: ${user.id}');
      await Supabase.instance.client.from('user_device_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'token',
      );
      debugPrint('FCM: Token sync complete.');
    } catch (e, st) {
      debugPrint('FCM: Token sync failed: $e\n$st');
    }
  }
}
