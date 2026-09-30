# ZeroScroll — Agent Guidelines & Project Rules

## Project Overview

**ZeroScroll** is an Android-first Flutter application that displays **ONLY** the Direct Messages and Notifications/Activity area of the user's own account inside a guarded WebView.
- **Allowed views:** Direct Messages (inbox & conversations) and Notifications/Activity.
- **Blocked/Removed:** Home feed, Search/Explore, Reels tab, Stories, and general profile browsing.
- **Media constraints:** Reels/posts sent in DMs can be viewed one at a time, strictly with no swiping or continuous scrolling to further content.

---

## Permanent Project Rules

1. **Naming & Identity**
   - **Package ID:** `com.apexventures.zeroscroll`
   - **App Name:** `ZeroScroll`
   - Never use "Instagram", "Insta", "IG", or Meta logos/colors in the app name, launcher icon, package ID, or store-facing strings.
   - Descriptive mentions in in-app help text or documentation are permitted.

2. **Privacy (Strict & Absolute)**
   - Never send Instagram content, session cookies, usernames, credentials, message text, or notification text to any remote server or external service.
   - All user session data and content must remain strictly on-device.
   - No third-party analytics, tracking, or crash-reporting SDKs in v1.

3. **Backend & Allowed Network Traffic**
   - **No backend** in v1.
   - The only permitted network calls outside of the embedded WebView are:
     - HTTPS GET of a remote configuration JSON.
     - HTTPS GET of a `version.json` (for update checks in supported builds).

4. **DOM Selectors, Route Patterns & Styling**
   - Never hardcode obfuscated or dynamic CSS class names.
   - Use stable attributes: `href`, `aria-label`, `role`, and resilient structural selectors.
   - Keep all selectors, route patterns, and injected CSS/JS rules in a centralized configuration file so updates can be applied without breaking code changes.

5. **Technology Stack**
   - **Framework:** Flutter (stable channel)
   - **Language:** Dart with strict null-safety
   - **State Management:** Riverpod
   - **WebView:** `flutter_inappwebview`
   - **Local Database:** Drift (SQLite)
   - **Authentication:** `local_auth` for biometrics
   - **Android Native Code:** Kotlin

6. **Directory & Architectural Structure**
   - **Feature-first architecture:**
     ```
     lib/
     ├── core/                       # Shared utilities, config, base themes, services
     └── features/
         └── <feature>/
             ├── data/               # Repositories, data sources, models
             ├── domain/             # Entities, use cases, interfaces
             └── presentation/       # Riverpod providers, screens, widgets
     ```
   - **Android Native Root:** `android/app/src/main/kotlin/com/apexventures/zeroscroll/`

7. **Build Flavors**
   - Maintain two distinct build flavors: `play` and `sideload`.
   - Any functionality or permissions specific to sideload distribution (such as the in-app APK updater and the `REQUEST_INSTALL_PACKAGES` permission) must be strictly isolated to the `sideload` flavor and excluded from the `play` flavor.

8. **Task Completion & Verification Workflow**
   - After completing every coding task:
     1. Run `flutter analyze` and resolve all warnings and errors.
     2. Run `flutter test` and ensure all tests pass.
     3. Provide a clear summary of what changed.
     4. List explicit manual test steps that must be verified on a physical device.

9. **Code Quality & Maintenance Standards**
   - Write small, modular, well-commented, and testable functions.
   - Never leave incomplete code or `TODO` items that break the build or test suite.
