# ZiggyBites Delivery — Project Structure

| Field   | Value                                            |
| ------- | ------------------------------------------------ |
| Package | `webview_master_app`                             |
| App     | ZiggyBites Delivery (`com.ziggybites.delivery`)  |
| Version | `2.1.17+18`                                      |
| URL     | `https://www.ziggybites.com/food/delivery/login` |

**Summary:** Flutter is only the shell (splash, push, location, permissions). Every partner screen is the website inside `WebViewScreen`.

Launch: `SplashScreen` → `WebViewScreen`.

---

## Flutter modules (`lib/`)

| Module                                   | WebView? | Summary                                                |
| ---------------------------------------- | -------- | ------------------------------------------------------ |
| `main.dart`                              | No       | App start, Firebase, notifications, background service |
| `config/app_config.dart`                 | No       | Name, URL, API, colors, alert channels                 |
| `config/theme_config.dart`               | No       | Light / dark theme                                     |
| `screens/splash_screen.dart`             | No       | Logo splash, then opens WebView                        |
| `screens/onboarding_screen.dart`         | No       | 3 slides. Not used on launch                           |
| `screens/webview_screen.dart`            | **Yes**  | Loads the delivery website                             |
| `services/api_service.dart`              | No       | Saves FCM token                                        |
| `services/system_overlay_service.dart`   | No       | Overlay helper (not started)                           |
| `utils/notification_service.dart`        | No       | Push and local alerts                                  |
| `utils/fcm_background_handler.dart`      | No       | Pushes when the app is closed                          |
| `utils/new_order_notification_util.dart` | No       | Ringing new-order alert                                |
| `utils/silent_notification_util.dart`    | No       | Quiet status updates                                   |
| `utils/background_service_util.dart`     | No       | Background location                                    |
| `utils/download_service.dart`            | No       | File / receipt downloads                               |
| `utils/in_app_update_service.dart`       | No       | Play Store update prompt                               |
| `utils/permission_handler_util.dart`     | No       | Camera, location, notifications                        |
| `utils/prefs_util.dart`                  | No       | Token, phone, theme                                    |
| `utils/connectivity_util.dart`           | No       | Online / offline                                       |
| `utils/status_bar_util.dart`             | No       | Status bar colors                                      |
| `widgets/offline_screen.dart`            | No       | Offline screen over the WebView                        |
| `widgets/exit_dialog.dart`               | No       | Exit confirmation                                      |

---

## Website modules (inside the WebView)

| Module           | WebView? | Route                              | Summary                           |
| ---------------- | -------- | ---------------------------------- | --------------------------------- |
| Welcome          | Yes      | `/food/delivery/welcome`           | Intro before login                |
| Login            | Yes      | `/food/delivery/login`             | Phone login. App opens here       |
| OTP              | Yes      | `/food/delivery/otp`               | Enter SMS code                    |
| Signup details   | Yes      | `/food/delivery/signup/details`    | Partner and vehicle details       |
| Signup documents | Yes      | `/food/delivery/signup/documents`  | Aadhaar, PAN, licence             |
| Feed             | Yes      | `/food/delivery`                   | Map, online/offline, active order |
| Pocket           | Yes      | `/food/delivery/pocket`            | Earnings wallet                   |
| Payout           | Yes      | `/food/delivery/pocket/payout`     | Withdraw to bank                  |
| Statement        | Yes      | `/food/delivery/pocket/statement`  | Pocket statement                  |
| Deductions       | Yes      | `/food/delivery/pocket/deductions` | Deductions                        |
| Cash limit       | Yes      | `/food/delivery/pocket/cash-limit` | COD cash limit                    |
| History          | Yes      | `/food/delivery/history`           | Past trips                        |
| Profile          | Yes      | `/food/delivery/profile`           | Profile, logout                   |
| Bank             | Yes      | `/food/delivery/profile/bank`      | Bank details                      |
| Documents        | Yes      | `/food/delivery/profile/documents` | Uploaded documents                |
| Notifications    | Yes      | `/food/delivery/notifications`     | In-app inbox                      |
| Support          | Yes      | `/food/delivery/help/tickets`      | Support tickets                   |
| ID card          | Yes      | `/food/delivery/help/id-card`      | Partner ID card                   |
| Terms            | Yes      | `/food/delivery/terms`             | Terms page                        |
| Privacy          | Yes      | `/food/delivery/profile/privacy`   | Privacy page                      |
