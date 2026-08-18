import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:webview_master_app/config/app_config.dart';

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  AudioPlayer? audioPlayer;
  bool isRinging = false;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    // Set initial notification content once
    service.setForegroundNotificationInfo(
      title: "ZiggyBites Delivery Service Active",
      content: "Waiting for new orders...",
    );

    // Listen for ringtone start.
    // NOTE: Do NOT call setForegroundNotificationInfo here.
    // The foreground-service notification (ID 888) must stay as the generic
    // "service is running" indicator. Changing it to order-related text creates
    // a second notification that looks identical to the critical order alert
    // already shown by showOrderNotification() — the duplicate the user sees.
    service.on('startRingtone').listen((event) async {
      if (!isRinging) {
        debugPrint('🔔 Background Service: Starting Ringtone');
        isRinging = true;
        // Create a fresh player each time so there is no stale ExoPlayer state.
        // Set the audio context on the new instance BEFORE loading the source so
        // the notification-stream AudioAttributes are applied during preparation —
        // this prevents the brief full-volume burst that occurs when attributes
        // are applied after ExoPlayer has already started audio output.
        audioPlayer = AudioPlayer();
        await audioPlayer!.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notification,
              audioFocus: AndroidAudioFocus.gainTransient,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.ambient,
            ),
          ),
        );
        await audioPlayer!.setReleaseMode(ReleaseMode.loop);
        // setSource prepares the player (AudioAttributes already in place),
        // then resume starts output — volume is correct from the very first frame.
        await audioPlayer!.setSource(AssetSource('audio/iphone-remix-68028.mp3'));
        await audioPlayer!.resume();
      }
    });

    // Listen for ringtone stop
    service.on('stopRingtone').listen((event) async {
      if (isRinging) {
        debugPrint('🔕 Background Service: Stopping Ringtone');
        isRinging = false;
        await audioPlayer?.stop();
        await audioPlayer?.dispose();
        audioPlayer = null;

        // Reset notification info
        service.setForegroundNotificationInfo(
          title: "ZiggyBites Delivery Service Active",
          content: "Waiting for new orders...",
        );
      }
    });
  }

  service.on('stopService').listen((event) async {
    await audioPlayer?.dispose();
    audioPlayer = null;
    service.stopSelf();
  });

  // Location tracking logic (remains same)
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) {
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        
        debugPrint('📍 Background Location: ${position.latitude}, ${position.longitude}');
        
        // Broadcast location update
        service.invoke('update', {
          "latitude": position.latitude,
          "longitude": position.longitude,
        });
      } catch (e) {
        debugPrint('❌ Background Location Error: $e');
      }
    }
  });
}

@pragma('vm:entry-point')
class BackgroundServiceUtil {
  static const int notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConfig.silentChannelId,
        initialNotificationTitle: 'Restaurant service active',
        initialNotificationContent: 'Waiting for new orders...',
        foregroundServiceNotificationId: notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
    }
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stopService');
    }
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}
