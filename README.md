# ZiggyBites Delivery — Delivery Partner App

Flutter app for ZiggyBites delivery partners. It wraps the delivery dashboard at [ziggybites.com/food/delivery](https://www.ziggybites.com/food/delivery/login) in a native WebView and adds new-order alerts, background location and native device features.

| | |
|---|---|
| App name | ZiggyBites Delivery |
| Android package / iOS bundle ID | `com.ziggybites.delivery` |
| Website loaded | `https://www.ziggybites.com/food/delivery/login` |
| API base | `https://ziggybites.com/api` |
| Version | see `version:` in `pubspec.yaml` |

## Features

- **New-order alerts:** Firebase Cloud Messaging plus a ringing alert on the high-priority channel `critical_order_alerts_v6`, using the `order_ringtone` sound. It brings the app to the front when an order arrives.
- **Silent channel by default:** FCM delivers to `silent_notifications_v1`, so only real new-order pushes ring. Data-only pushes are handled in `fcm_background_handler.dart`.
- **Background service:** `flutter_background_service` (location and media playback) keeps alerts working and reads the rider's location while the app is in the background.
- **In-app updates:** prompts for Play Store updates (`in_app_update`).
- Full-screen WebView of the delivery dashboard (`flutter_inappwebview`)
- Native Google Sign-In, camera and gallery uploads (proof of delivery, documents), downloads
- Phone, WhatsApp, maps and UPI links opened in native apps
- Splash, onboarding, offline screen, exit confirmation, light and dark theme

## Project structure

```
lib/
├── main.dart                          # App entry, Firebase and background service init
├── config/
│   ├── app_config.dart                # App name, URLs, colours, notification channels
│   └── theme_config.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   └── webview_screen.dart            # WebView, JS handlers, URL routing, uploads
├── services/
│   ├── api_service.dart               # Backend API (FCM token registration, etc.)
│   └── system_overlay_service.dart
├── utils/
│   ├── fcm_background_handler.dart    # Handles pushes when app is backgrounded/closed
│   ├── new_order_notification_util.dart
│   ├── silent_notification_util.dart
│   ├── notification_service.dart
│   ├── notification_payload_util.dart
│   ├── background_service_util.dart
│   ├── in_app_update_service.dart
│   └── …                              # permissions, connectivity, downloads, prefs, status bar
└── widgets/                           # Exit dialog, offline screen
```

Ringtones are in `android/app/src/main/res/raw/` (Android), `ios/Runner/order_ringtone.mp3` (iOS) and `assets/audio/`.

> If you change a notification channel's sound or importance, bump its ID (for example `critical_order_alerts_v6` → `v7`). Android doesn't let an app change an existing channel's settings.

## Getting started

Requirements: Flutter (stable), Xcode for iOS builds, Android Studio or the Android SDK for Android builds.

```bash
flutter pub get
flutter run
```

Firebase is already configured for project `ziggybites-79bfc`:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

To test order alerts, send a data push from the backend or the Firebase console. Check it with the app in the foreground, in the background, and closed.

## Release builds and signing

Signing keys are **not** stored in this repo. The release build reads them from a folder next to the repo:

```
ZiggyBites/
├── Ziggybites-delivery-apk/   # this repo
└── signing-keys/
    └── delivery/
        ├── key.properties     # storePassword, keyPassword, keyAlias, storeFile
        └── ziggybites_delivery.jks
```

To keep the keys elsewhere, set `ZIGGYBITES_SIGNING_DIR` to the folder that holds `key.properties` and the keystore.

```bash
flutter build appbundle --release   # Play Store
flutter build apk --release
flutter build ipa --release         # iOS
```

Release builds use R8 minification. The keep rules in `android/app/proguard-rules.pro` stop the ringtone, background service and notifications from breaking in release builds. Keep them when adding plugins.

## Security notes

- Never commit `key.properties`, `*.jks` or `*.keystore`; they are listed in `.gitignore`.
- Automatic VS Code tasks are turned off in `.vscode/settings.json`. Don't add tasks that run on folder open.
- The app only allows HTTPS traffic: cleartext is disabled on Android, and iOS uses the default App Transport Security.
