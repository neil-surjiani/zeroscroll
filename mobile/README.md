# ZeroScroll Mobile App

ZeroScroll is an Android-first Flutter application engineered with one strict objective: providing a focused, distraction-free interface displaying **ONLY** the Direct Messages and Notifications/Activity sections of your account inside a guarded WebView container.

## Architecture

Follows feature-first clean architecture:
- `lib/core`: Shared database (Drift SQLite), configuration, themes, routing.
- `lib/features`:
  - `webview`: Guarded WebView orchestration & content filtering
  - `notifications`: Account activity and notifications
  - `limits`: Session tracking and daily reel budget limits
  - `settings`: Preferences and customizations
  - `security`: Biometric authentication (`local_auth`)
  - `updater`: Sideload APK updater

## Build Flavors

- `play`: Google Play Store flavor (no updater permissions)
- `sideload`: Sideload flavor with self-updater and `REQUEST_INSTALL_PACKAGES`

## Running the App

```bash
# Get dependencies
flutter pub get

# Run sideload flavor (debug)
flutter run --flavor sideload -t lib/main_sideload.dart

# Build sideload release APK
flutter build apk --flavor sideload -t lib/main_sideload.dart
```
