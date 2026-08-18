import 'package:firebase_messaging/firebase_messaging.dart';

/// Parses FCM [data] / notification fields into user-visible title and body.
class NotificationPayloadUtil {
  NotificationPayloadUtil._();

  static String titleFrom(RemoteMessage message, Map<String, dynamic> data) {
    final fromNotification = message.notification?.title?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }
    final fromData = data['title']?.toString().trim();
    if (fromData != null && fromData.isNotEmpty) return fromData;

    final type = _typeKey(data);
    if (type.isNotEmpty) return _humanizeType(type);
    // Return empty so callers can detect a truly content-free payload and skip display.
    return '';
  }

  static String bodyFrom(RemoteMessage message, Map<String, dynamic> data) {
    final fromNotification = message.notification?.body?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }
    for (final key in ['body', 'message', 'description', 'content']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }

    final orderId = data['orderId'] ?? data['order_id'];
    if (orderId != null) return 'Order #$orderId';

    final status = data['status']?.toString().trim();
    if (status != null && status.isNotEmpty) {
      return 'Status: $status';
    }

    final type = _typeKey(data);
    if (type.isNotEmpty) return _humanizeType(type);
    return '';
  }

  static String _typeKey(Map<String, dynamic> data) {
    return (data['type'] ?? data['notification_type'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
  }

  static String _humanizeType(String type) {
    return type
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
