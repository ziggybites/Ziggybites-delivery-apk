import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:webview_master_app/config/app_config.dart';
import 'package:webview_master_app/utils/notification_payload_util.dart';

/// Silent tray notifications (status updates, accept/complete, etc.).
class SilentNotificationUtil {
  SilentNotificationUtil._();

  static bool _channelReady = false;

  static Future<void> ensureSilentChannel(
    AndroidFlutterLocalNotificationsPlugin? android,
  ) async {
    if (android == null || _channelReady) return;
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConfig.silentChannelId,
        AppConfig.silentChannelName,
        description: AppConfig.silentChannelDescription,
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );
    _channelReady = true;
  }

  static const NotificationDetails details = NotificationDetails(
    android: AndroidNotificationDetails(
      AppConfig.silentChannelId,
      AppConfig.silentChannelName,
      channelDescription: AppConfig.silentChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
      icon: AppConfig.notificationIcon,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    ),
  );

  static Future<void> show(
    FlutterLocalNotificationsPlugin plugin, {
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await ensureSilentChannel(android);

    await plugin.show(id, title, body, details, payload: payload);
    debugPrint('🔕 Silent notification posted: $title');
  }

  static Future<void> showFromMessage(
    FlutterLocalNotificationsPlugin plugin,
    RemoteMessage message, {
    required String payload,
  }) async {
    final data = Map<String, dynamic>.from(message.data);
    final title = NotificationPayloadUtil.titleFrom(message, data);
    final body = NotificationPayloadUtil.bodyFrom(message, data);
    if (title.isEmpty && body.isEmpty) return;

    final id = (message.messageId ?? '$title$body').hashCode.abs() % 2147483647;
    await show(
      plugin,
      id: id,
      title: title,
      body: body,
      payload: payload,
    );
  }
}
