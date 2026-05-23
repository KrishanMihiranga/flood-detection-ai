import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Heads-up previews for moderator bulletins (no FCM). Android/iOS focused.
abstract final class LocalPushService {
  LocalPushService._();

  static const _channelId = 'official_broadcast_v1';

  /// Drawable name of [android/app/src/main/res/drawable/notification_small_icon.xml].
  /// The plugin resolves small icons via the `drawable` bucket only (not `@mipmap/...`).
  static const _androidSmallIconName = 'notification_small_icon';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static int _sequentialNotifyId = 1;

  /// Call once during app bootstrap.
  static Future<void> init() async {
    if (kIsWeb) return;

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_androidSmallIconName),
        iOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      ),
      onDidReceiveNotificationResponse: (_) {},
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          'Official broadcasts',
          description: 'Urgent bulletins authored by coordinators',
          importance: Importance.high,
        ),
      );
      await androidImpl?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Surfaces moderator copy as the closest thing to push without backends.
  static Future<void> showOfficialBroadcast({
    required String title,
    required String summary,
    String? areaSuffix,
  }) async {
    if (kIsWeb) return;

    final body = summary.length > 400 ? '${summary.substring(0, 397)}…' : summary;

    try {
      final area = areaSuffix?.trim();
      final subtitle = area != null && area.isNotEmpty ? area : null;

      if (Platform.isAndroid) {
        await _ensureAndroidNotificationsEnabled();
        // Fresh id each send so repeats are not swallowed as "same notification".
        final notifyId =
            ((_sequentialNotifyId++ & 0xffff) ^ DateTime.now().millisecondsSinceEpoch) &
            0x7fffffff;

        await _plugin.show(
          id: notifyId == 0 ? 1 : notifyId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              'Official broadcasts',
              icon: _androidSmallIconName,
              channelDescription: 'Urgent bulletins authored by coordinators',
              importance: Importance.high,
              priority: Priority.high,
              styleInformation: subtitle != null
                  ? BigTextStyleInformation('$body\n\n— $subtitle')
                  : BigTextStyleInformation(body),
              visibility: NotificationVisibility.public,
              ticker: title,
              autoCancel: true,
            ),
          ),
        );
        return;
      }

      if (Platform.isIOS) {
        final notifyId =
            ((_sequentialNotifyId++ & 0xffff) ^ DateTime.now().millisecondsSinceEpoch) &
            0x7fffffff;
        await _plugin.show(
          id: notifyId == 0 ? 1 : notifyId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            iOS: DarwinNotificationDetails(
              subtitle: subtitle,
              presentBanner: true,
              presentAlert: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.active,
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('Local notification failed: $e\n$st');
    }
  }

  static Future<void> _ensureAndroidNotificationsEnabled() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    final enabled = await androidImpl.areNotificationsEnabled();
    if (enabled == false) {
      await androidImpl.requestNotificationsPermission();
    }
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}
