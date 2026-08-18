import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:webview_master_app/config/app_config.dart';
import 'package:webview_master_app/utils/prefs_util.dart';
import 'dart:io' show Platform;

/// API Service - Handles all API calls to the backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Get the full API URL for an endpoint
  String _getApiUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '${AppConfig.apiBaseUrl}/$cleanEndpoint';
  }

  /// Save FCM token to backend for the currently logged-in account + device.
  ///
  /// Sends [phone] and [appRole] so status updates reach the correct physical
  /// device when user, restaurant, and delivery use separate phones.
  Future<bool> saveFCMToken({
    required String token,
    String? phone,
    String? platform,
    String? appRole,
  }) async {
    try {
      final platformValue =
          platform ?? (Platform.isAndroid ? 'android' : 'ios');

      if (phone != null &&
          phone.isNotEmpty &&
          (phone.length != 10 || !RegExp(r'^\d{10}$').hasMatch(phone))) {
        debugPrint(
            '❌ Invalid phone number format. Expected 10 digits, got: $phone');
        return false;
      }

      if (token.isEmpty) {
        debugPrint('❌ FCM token is empty');
        return false;
      }

      final url = _getApiUrl('/v1/fcm-tokens/mobile/save');

      final accessToken = PrefsUtil.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('⚠️ Access token not found. Cannot save FCM token.');
        return false;
      }

      final role = appRole ?? AppConfig.appRole;

      final requestBody = <String, dynamic>{
        'token': token,
        // 'fcmToken': token,
        'platform': platformValue,
        'appRole': role,
        // 'appType': role,
        // 'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      debugPrint('📤 Saving FCM token to: $url (role=$role)');

      final response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('❌ Request timeout while saving FCM token');
          throw Exception('Request timeout');
        },
      );

      debugPrint('📥 FCM save body: $requestBody');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ FCM token saved successfully');
        return true;
      } else {
        debugPrint(
            '❌ Failed to save FCM token. Status: ${response.statusCode}');
        debugPrint('❌ Error: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving FCM token: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return false;
    }
  }
}
