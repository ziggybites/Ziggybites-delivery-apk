import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:webview_master_app/config/app_config.dart';

/// Wraps the Google Play In-App Update API (in_app_update v4.x).
///
/// Two update flows are supported:
///   • Immediate — full-screen Play Store overlay, blocks the app.
///                 Used when the developer sets update priority ≥ 4 in
///                 the Play Console release.
///   • Flexible  — silent background download; a [MaterialBanner] is shown
///                 once the download finishes so the user can restart at will.
///
/// Usage
/// -----
///   // On screen init (after a short delay so the UI is ready):
///   InAppUpdateService().checkAndUpdate(context);
///
///   // On every AppLifecycleState.resumed event (rate-limited internally):
///   InAppUpdateService().checkAndUpdate(context);
///
///   // On screen dispose:
///   InAppUpdateService().dispose();
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  bool _isChecking = false;
  DateTime? _lastFullCheckTime;

  // Stream<InstallStatus> — the actual type emitted by installUpdateListener.
  StreamSubscription<InstallStatus>? _installStateSubscription;

  /// Minimum gap between full Play-Store API calls.
  /// Bypassed when a flexible download is already in progress so we can
  /// detect the "downloaded" state on app resume.
  static const Duration _checkInterval = Duration(hours: 1);

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Check for an available update and start the appropriate flow.
  ///
  /// Safe to call on every [AppLifecycleState.resumed] — internal
  /// rate-limiting prevents hammering the Play Store API.
  Future<void> checkAndUpdate(BuildContext context) async {
    if (!Platform.isAndroid) return;
    if (_isChecking) return;

    final bool hasActiveDownload = _installStateSubscription != null;

    // Skip rate-limited full checks unless we have an active download to poll.
    if (!hasActiveDownload) {
      if (_lastFullCheckTime != null &&
          DateTime.now().difference(_lastFullCheckTime!) < _checkInterval) {
        return;
      }
    }

    _isChecking = true;
    try {
      debugPrint('🔄 [Update] Checking for app update...');
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      debugPrint('🔄 [Update] availability=${info.updateAvailability}, '
          'priority=${info.updatePriority}, '
          'installStatus=${info.installStatus}, '
          'immediate=${info.immediateUpdateAllowed}, '
          'flexible=${info.flexibleUpdateAllowed}');

      // A flexible download that completed while the app was backgrounded
      // will surface as InstallStatus.downloaded on the next checkForUpdate().
      if (info.installStatus == InstallStatus.downloaded) {
        if (!context.mounted) return;
        _showRestartBanner(context);
        return;
      }

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        _lastFullCheckTime = DateTime.now();

        if (info.immediateUpdateAllowed && info.updatePriority >= 4) {
          // Critical update — block the app and force install now.
          await _runImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          // Normal update — download silently, prompt when done.
          if (!context.mounted) return;
          _runFlexibleUpdate(context);
        }
      } else if (info.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        // A flexible update was started in a previous session and is resuming.
        _lastFullCheckTime = DateTime.now();
        if (info.flexibleUpdateAllowed) {
          if (!context.mounted) return;
          _runFlexibleUpdate(context);
        }
      } else {
        _lastFullCheckTime = DateTime.now();
      }
    } on Exception catch (e) {
      // Swallow all errors — update checks must never crash the app.
      // Common non-fatal causes: debug/sideloaded build, no network,
      // Play Store not available on device.
      debugPrint('⚠️ [Update] Check skipped: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Cancel the active install-state subscription.
  /// Call this from the widget's [dispose].
  void dispose() {
    _installStateSubscription?.cancel();
    _installStateSubscription = null;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  Future<void> _runImmediateUpdate() async {
    try {
      debugPrint('🔄 [Update] Starting immediate update...');
      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
      debugPrint('🔄 [Update] Immediate update result: $result');
    } on Exception catch (e) {
      debugPrint('⚠️ [Update] Immediate update failed: $e');
    }
  }

  void _runFlexibleUpdate(BuildContext context) {
    // Cancel any stale subscription before starting a fresh one.
    _installStateSubscription?.cancel();

    debugPrint('🔄 [Update] Starting flexible update download...');

    // installUpdateListener is Stream<InstallStatus> — no wrapper object.
    _installStateSubscription =
        InAppUpdate.installUpdateListener.listen((InstallStatus status) {
      debugPrint('🔄 [Update] Install status: $status');
      if (status == InstallStatus.downloaded && context.mounted) {
        _showRestartBanner(context);
      }
    }, onError: (Object e) {
      debugPrint('⚠️ [Update] Install listener error: $e');
    });

    InAppUpdate.startFlexibleUpdate().then((AppUpdateResult result) {
      debugPrint('🔄 [Update] Flexible update started: $result');
      if (result == AppUpdateResult.userDeniedUpdate) {
        _installStateSubscription?.cancel();
        _installStateSubscription = null;
        debugPrint('🔄 [Update] User declined flexible update.');
      }
    }).catchError((Object e) {
      debugPrint('⚠️ [Update] startFlexibleUpdate failed: $e');
      _installStateSubscription?.cancel();
      _installStateSubscription = null;
    });
  }

  /// Shows a persistent [MaterialBanner] at the top of the screen.
  /// The user can restart immediately or dismiss and update later.
  void _showRestartBanner(BuildContext context) {
    if (!context.mounted) return;

    debugPrint('🔄 [Update] Download complete — showing restart banner.');

    // Clear any previously shown banner before showing a fresh one.
    ScaffoldMessenger.of(context).clearMaterialBanners();

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: const Icon(Icons.system_update_rounded, color: Colors.white),
        backgroundColor: AppConfig.primaryColor,
        content: const Text(
          'A new version is ready to install.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).clearMaterialBanners(),
            child: const Text(
              'LATER',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).clearMaterialBanners();
              InAppUpdate.completeFlexibleUpdate().catchError((Object e) {
                debugPrint('⚠️ [Update] completeFlexibleUpdate failed: $e');
              });
            },
            child: const Text(
              'RESTART NOW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
