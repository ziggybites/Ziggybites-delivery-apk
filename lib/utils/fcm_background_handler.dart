import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:webview_master_app/utils/new_order_notification_util.dart';
import 'package:webview_master_app/utils/notification_service.dart';
import 'package:webview_master_app/utils/notification_payload_util.dart';

/// Background message handler for Firebase Cloud Messaging.
/// Must be a top-level function — runs when app is backgrounded or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  try {
    debugPrint('📨 [BG] Background message received');
    debugPrint('🔍 [BG] RAW FCM PAYLOAD MAP: ${message.toMap()}');
    
    Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      if (!data.containsKey('title') || data['title'] == null) {
        data['title'] = notification.title;
      }
      if (!data.containsKey('body') || data['body'] == null) {
        data['body'] = notification.body;
      }
    }

    final isNewOrder = NotificationService.isNewOrderNotification(data);
    debugPrint('🔔 [BG] isNewOrder: $isNewOrder');

    final title = NewOrderNotificationUtil.titleFrom(message, data);
    final body = NewOrderNotificationUtil.bodyFrom(message, data);

    if (isNewOrder) {
      debugPrint('🔔 [BG] New order confirmed — showing system tray notification and sounding alarm.');

      final serviceInstance = NotificationService();
      await serviceInstance.initialize(isBackground: true);

      // When the FCM payload includes a `notification` object, the Android OS
      // auto-displays it on the default (silent) channel BEFORE this handler runs.
      // Cancel that auto-notification so only the critical-channel version appears.
      if (message.notification != null) {
        debugPrint('ℹ️ [BG] FCM notification payload present — cancelling auto-shown notification before showing critical alert.');
        // Wait a short delay to ensure the Android OS has fully rendered the auto-displayed notification before we cancel it
        await Future.delayed(const Duration(milliseconds: 600));
        await serviceInstance.cancelAllNotifications();
      }

      String notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

      await serviceInstance.showOrderNotification(
        title: title.isNotEmpty ? title : 'New Order',
        body: body.isNotEmpty ? body : 'You have a new delivery order',
        notificationId: notificationId,
        orderData: data,
      );

      try {
        final service = FlutterBackgroundService();
        final orderPayload = {
          'title': title,
          'body': body,
          'data': data,
        };
        
        if (await service.isRunning()) {
          service.invoke('startRingtone', orderPayload);
        } else {
          await service.startService();
          await Future.delayed(const Duration(milliseconds: 1500));
          service.invoke('startRingtone', orderPayload);
        }
      } catch (e) {
        debugPrint('❌ [BG] Error invoking background service ringtone logic: $e');
      }
      return;
    }

    debugPrint('🔕 [BG] Status/other notification captured — forcing silent tray insertion.');
    
    // FCM automatically displays background notifications if the payload contains a "notification" object.
    if (message.notification != null) {
      final autoTitle = (message.notification!.title ?? '').trim();
      final autoBody  = (message.notification!.body  ?? '').trim();

      if (autoTitle.isEmpty && autoBody.isEmpty) {
        // The FCM payload carried an empty notification object. Android OS
        // auto-showed a blank notification before this handler ran. Cancel it.
        final svc = NotificationService();
        await svc.initialize(isBackground: true);
        // Wait a short delay to ensure the Android OS has fully rendered the auto-displayed notification before we cancel it
        await Future.delayed(const Duration(milliseconds: 600));
        await svc.cancelAllNotifications();
        debugPrint('ℹ️ [BG] Cancelled blank auto-FCM notification (empty title+body).');
      } else {
        debugPrint('ℹ️ [BG] Non-blank FCM notification payload — Android OS already displayed it silently. Skipping duplicate manual show.');
      }
      return;
    }

    final silentTitle = NotificationPayloadUtil.titleFrom(message, data);
    final silentBody = NotificationPayloadUtil.bodyFrom(message, data);
    
    // Skip truly empty payloads. titleFrom() now returns '' (not 'Notification')
    // when there is no real content, so this guard now works correctly.
    if (silentTitle.isEmpty && silentBody.isEmpty) {
      debugPrint('ℹ️ [BG] Empty non-order payload, skipping system notification stack.');
      return;
    }

    final serviceInstance = NotificationService();
    await serviceInstance.initialize(isBackground: true);

    String notificationId = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    await serviceInstance.showSimpleNotification(
      title: silentTitle.isNotEmpty ? silentTitle : silentBody,
      body: silentTitle.isNotEmpty ? silentBody : '',
      notificationId: notificationId,
    );

  } catch (e, stack) {
    debugPrint('❌ [BG] FATAL ERROR: $e');
    debugPrint('❌ [BG] STACK: $stack');
  }
}