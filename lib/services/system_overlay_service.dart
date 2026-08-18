// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';

// /// Service to manage system-level overlay that works over other apps
// class SystemOverlayService {
//   static const MethodChannel _channel =
//       MethodChannel('com.ziggybites.delivery/overlay');

//   /// Check if overlay permission is granted
//   static Future<bool> checkOverlayPermission() async {
//     try {
//       final result =
//           await _channel.invokeMethod<bool>('checkOverlayPermission');
//       return result ?? false;
//     } catch (e) {
//       debugPrint('❌ Error checking overlay permission: $e');
//       return false;
//     }
//   }

//   /// Request overlay permission (opens system settings)
//   static Future<void> requestOverlayPermission() async {
//     try {
//       await _channel.invokeMethod('requestOverlayPermission');
//     } catch (e) {
//       debugPrint('❌ Error requesting overlay permission: $e');
//     }
//   }

//   /// Start the overlay service (will show overlay over other apps)
//   /// Automatically requests permission if not granted
//   /// Only shows overlay if app is in background
//   static Future<bool> startOverlay() async {
//     try {
//       // Check overlay permission first
//       final hasPermission = await checkOverlayPermission();

//       if (!hasPermission) {
//         // Request permission (opens settings)
//         await requestOverlayPermission();
//         // Wait a bit for user to grant permission
//         await Future.delayed(const Duration(seconds: 1));
//         // Check again
//         final granted = await checkOverlayPermission();
//         if (!granted) {
//           debugPrint('⚠️ Overlay permission not granted');
//           return false;
//         }
//       }

//       // Start the overlay service (service will check if app is in foreground)
//       final result = await _channel.invokeMethod<bool>('startOverlay');
//       return result ?? false;
//     } catch (e) {
//       debugPrint('❌ Error starting overlay: $e');
//       return false;
//     }
//   }

//   /// Stop the overlay service
//   static Future<bool> stopOverlay() async {
//     try {
//       final result = await _channel.invokeMethod<bool>('stopOverlay');
//       return result ?? false;
//     } catch (e) {
//       debugPrint('❌ Error stopping overlay: $e');
//       return false;
//     }
//   }

//   /// Toggle the overlay service
//   static Future<bool> toggleOverlay() async {
//     try {
//       final hasPermission = await checkOverlayPermission();

//       if (!hasPermission) {
//         await requestOverlayPermission();
//         await Future.delayed(const Duration(seconds: 1));
//         final granted = await checkOverlayPermission();
//         if (!granted) {
//           return false;
//         }
//       }

//       final result = await _channel.invokeMethod<bool>('toggleOverlay');
//       return result ?? false;
//     } catch (e) {
//       debugPrint('❌ Error toggling overlay: $e');
//       return false;
//     }
//   }
// }
