# ZeroScroll — Comprehensive Test Plan & Verification Matrix

## 1. Testing Philosophy & Automated CI Gateways

ZeroScroll is designed for privacy, intentional digital consumption, and absolute containment of algorithmic distractions. To uphold these guarantees, tests are structured across automated unit tests, widget interaction tests, mock DOM fixtures, and structured manual test procedures for physical Android devices.

Every commit and release candidate must satisfy two mandatory automated gates:
1. `flutter analyze` must report **0 issues found**.
2. `flutter test` must achieve a **100% pass rate** across all unit and widget test suites.

---

## 2. Test Suite Structure

```
test/
├── core/
│   ├── config/                          # AppFlavor and FlavorConfig tests
│   └── database/                        # Drift database migrations & schema tests
├── features/
│   ├── webview/                         # Guarded WebView routing, URL interceptors, JS handlers
│   ├── shell/                           # NavigationBar, dynamic tabs, IndexedStack state
│   ├── notifications/                   # Notification listener bridge and storage
│   ├── limits/                          # Session tracking, reel & story budgets, focus schedules
│   ├── settings/                        # Feature preferences, Drift persistence, toggles
│   ├── onboarding/                      # Setup walkthrough and permission checks
│   ├── remote_config/                   # FeatureGroup merging (all 24 toggle permutations), CSS sanitization
│   ├── security/                        # Biometric app lock, timeout logic, FLAG_SECURE
│   ├── stories/                         # Stories tab rendering, fail-closed isolation, post story modal
│   └── updater/                         # Sideload APK updater, SHA-256 verification, cert check
├── fixtures/
│   ├── story_mock.html                  # DOM fixture with tray, feed, and auto-advance scripts
│   └── test_config.json                 # Sample feature group JSON payload
└── helpers/
    └── test_webview_platform.dart       # Mock InAppWebView platform channel implementation
```

---

## 3. Stories Verification Matrix

Stories are **strictly OFF by default** and subject to single-user session locks, fail-closed feed isolation, and daily budgets.

| ID | Test Scenario | Preconditions / Config | Expected Behavior | Automated Test Reference |
| :--- | :--- | :--- | :--- | :--- |
| **ST-01** | Stories Off by Default | Clean install or default `FeaturePreferences` (`storiesViewMode: off`) | Only 3 bottom tabs displayed (Messages, Activity, Settings). Navigating to `/stories/` is blocked and redirects to `/direct/inbox/`. Story tray CSS selector is hidden. | `test/features/stories/stories_shell_and_settings_test.dart` |
| **ST-02** | Stories from DMs Only | `storiesViewMode: fromDmsOnly` | Bottom navigation remains 3 tabs. Tapping a story link from inside a DM thread allows the viewer to open `/stories/<user>/<id>/`. Direct navigation without a DM referrer is blocked. Story tray remains hidden. | `test/features/remote_config/route_config_merge_test.dart` |
| **ST-03** | Stories from Following (Dynamic Tab) | `storiesViewMode: fromFollowing` | Bottom navigation dynamically adds 4th "Stories" tab between Activity and Settings. Tapping Stories switches active tab and mounts `StoriesTrayScreen`. | `test/features/stories/stories_shell_and_settings_test.dart` |
| **ST-04** | Fail-Closed Home Feed Isolation | Stories tab active, home page `/` loads | Injected CSS hides `article` and `[role="feed"]`. If any feed item is detected or tray is missing after 5 seconds, WebView unmounts and native "Stories Feed Hidden" shield appears. Algorithmic feed is never visible. | `test/fixtures/story_mock.html` & `StoriesTrayScreen` |
| **ST-05** | Single-User Session Lock (Same User) | User viewing `/stories/alice/101/` | Tapping next slide to advance to `/stories/alice/102/` is permitted because the username matches the active session. | `assets/js/guard.js` & `test/fixtures/story_mock.html` |
| **ST-06** | Single-User Session Lock (Auto-Advance Block) | User reaches final slide of `/stories/alice/` and attempts to advance to `/stories/bob/` | Intercepted in both Dart (Layer 1 URL guard) and JS (Layer 2 `pushState` / DOM mutation). Navigation cancelled, viewer closes, and toast displays: *"That was the last story from @alice."* User never reaches bob's story automatically. | `assets/js/guard.js` (`onNextStoryUserBlocked`) |
| **ST-07** | Persistent Story Viewer Overlay | Story viewer active | High-contrast persistent top bar displays prominent Close button, author username, and progress indicator (`Story 3 / 10`). Tapping Close returns immediately to previous safe route. | `lib/features/webview/presentation/widgets/webview_container.dart` |
| **ST-08** | Story Daily Budget Enforcement | `dailyStoryLimit: 3`, 3 stories viewed today | Opening a 4th story triggers the blocking "Daily Story Limit Reached" screen. Viewing is blocked until midnight reset. | `test/features/settings/feature_preferences_test.dart` |
| **ST-09** | Story Stats Tracking | Stories opened throughout the day | `StatsScreen` renders `_StoriesStatsCard` displaying accurate counts for Today, 7-day total, 30-day total, and avoided stories. Persisted in Drift `story_events`. | `test/features/settings/feature_preferences_test.dart` |
| **ST-10** | External App Posting Handoff Modal | `storiesPostingEnabled: true`, User taps "Post Story" in Settings | An explicit "External App Handoff" warning dialog is displayed: *"ZeroScroll cannot verify official app behavior outside this sandbox."* Requires explicit confirmation before launching external intent. | `test/features/stories/stories_shell_and_settings_test.dart` |
| **ST-11** | External Posting Disabled by Default | `storiesPostingEnabled: false` | Post Story action is hidden or disabled; in-app creation web routes are blocked by `RouteConfig`. | `test/features/remote_config/route_config_merge_test.dart` |
| **ST-12** | Feature Group Permutation Verification | 24 combinations of reels, stories, posts, and posting toggles | Table-driven tests verify all 24 permutations compute valid, non-colliding `RouteConfig` rules with zero unhandled route exceptions. | `test/features/remote_config/route_config_merge_test.dart` |

---

## 4. Core Features Test Matrix

| ID | Feature | Test Scope | Verification Method |
| :--- | :--- | :--- | :--- |
| **CF-01** | Route Guard (Layer 1) | Attempting navigation to `/explore`, `/reels/`, `/stories/` (when off), or profile pages | Cancelled in `shouldOverrideUrlLoading`; redirected to fallback `/direct/inbox/`. |
| **CF-02** | Single Reel Viewer | Opening `/reel/<id>/` from a DM thread | Viewer mode activated; touch-scrolling and swipe gestures locked; next reel UI and suggested content hidden; persistent Close button returns to DM. |
| **CF-03** | Sideload Flavor Isolation | Building and testing `play` vs `sideload` | `REQUEST_INSTALL_PACKAGES` permission present only in sideload manifest; updater code returns `null` safely in play flavor. |
| **CF-04** | Biometric Security | App lock enabled with timeout (immediate, 1m, 5m) | Blocking lock screen displayed before any WebView content renders; `FLAG_SECURE` prevents app previews in Android recents screen. |
| **CF-05** | Remote Config Cache | Validating remote JSON, sanitizing CSS, and version fallback | Rejects configs > 50KB or containing `url()` / `@import`; falls back gracefully to cached or bundled config on failure. |
| **CF-06** | Notification Listener | Capturing incoming Instagram notifications in Kotlin | Background service captures only `com.instagram.android`; classifies DMs vs activity; stores in local Room SQLite; respects privacy rules. |
| **CF-07** | Screen Time & Focus | Daily usage limits and focus schedules | Displays blocking "Done for today" screen when daily limit is exhausted; emergency 5-minute unlock allowed max 2 times per day. |

---

## 5. Physical Device Manual Verification Checklist

Before publishing or distributing any release candidate (play or sideload), QA or the release engineer must verify each of the following sections on a physical Android device.

---

### Step 1: Fresh Install & First Launch Experience
- [ ] **Install Clean APK:** Install a release build on a physical device with no prior ZeroScroll data (`adb install -r -d app-sideload-release.apk`).
- [ ] **Onboarding Carousel:** Verify the 6-step onboarding walkthrough loads:
  1. *Welcome & Philosophy:* Verify plain-language privacy pledge ("We can't see your messages and nothing leaves your phone").
  2. *Feature Preferences:* Select preset (Strict, Balanced, or Custom). Verify choice is saved to Drift storage.
  3. *Instagram Login Guidance:* Clear instructions on authenticating securely via official Instagram web endpoints.
  4. *Notification Access:* Verify tap opens system notification listener settings.
  5. *POST_NOTIFICATIONS (Android 13+):* Prompt requested and granted.
  6. *Security & Limits:* Optional biometric lock and initial daily limits.
- [ ] **State Persistence:** Kill app mid-onboarding; verify relaunch resumes at current step without data loss.

---

### Step 2: Login Flow (Standard & Two-Factor Authentication)
- [ ] **Official Login Page:** Confirm WebView loads `https://www.instagram.com/accounts/login/` securely with HTTPS.
- [ ] **Standard Login:** Enter username and password. Confirm session establishes and automatically redirects to `/direct/inbox/`.
- [ ] **2FA via Authenticator / SMS:**
  - Enter credentials for an account with 2FA enabled.
  - Confirm two-factor verification code screen loads and accepts TOTP/SMS tokens.
  - Confirm "Trust this device" prompt functions.
  - Confirm successful authentication routes directly to Direct Messages inbox without exposing the home feed.
- [ ] **Failed Login:** Enter invalid credentials. Confirm Instagram inline error messages display and app does not crash.

---

### Step 3: Inbox Loading & Thread Navigation
- [ ] **Inbox Render:** Confirm message threads, profile avatars, and preview text render cleanly.
- [ ] **Unread Badge:** Verify app bar / bottom navigation tab displays accurate unread badge count matching active DMs.
- [ ] **Thread Navigation:** Tap a thread to enter conversation. Confirm message history scrolls smoothly without jitter.
- [ ] **Pull to Refresh:** Pull down on inbox list; confirm inbox refreshes smoothly.

---

### Step 4: Message Interactions (Text, Image, Voice)
- [ ] **Send Text Message:** Type a message and send. Confirm immediate optimistic display and delivery confirmation.
- [ ] **Send Photo / Camera:**
  - Tap the media attachment / camera icon in a chat thread.
  - Verify system permission prompt for Camera / Photos appears.
  - Select or capture a photo. Confirm upload progress and successful delivery in thread.
- [ ] **Send Voice Note:**
  - Hold microphone icon to record audio message.
  - Confirm Android audio recording permission prompt.
  - Release to send; confirm audio message plays back properly in the thread.

---

### Step 5: Single Reel Viewer & Gesture Interception
- [ ] **Open Reel from DM:** In a conversation, tap an incoming shared reel link (`/reel/<id>/`).
- [ ] **Viewer Mode Activation:**
  - Confirm single-item viewer UI activates with persistent top bar.
  - Confirm Close button (>=48dp touch target) is visible and accessible.
  - Confirm reel counter reads `Reels today: N`.
- [ ] **Continuous Swipe Prevention (Anti-Distraction):**
  - Swipe UP forcefully on the playing reel.
  - **Verification:** Confirm the viewport **does not** advance to the next suggested reel. The gesture must be completely intercepted and absorbed.
  - Swipe DOWN forcefully. Confirm viewport remains strictly locked to the single shared reel.
- [ ] **Close Button:** Tap the persistent Close button. Confirm viewer unmounts and returns immediately to the exact DM thread.

---

### Step 6: Blocked Route Defense (Algorithmic Shielding)
Verify that attempting to reach any blocked route fails safe and redirects to `/direct/inbox/`:
- [ ] **Home Feed:** Attempt to navigate to `https://www.instagram.com/` -> Blocked; redirect to `/direct/inbox/` with a shield toast.
- [ ] **Explore / Search:** Attempt to open `/explore/` -> Blocked; redirected to `/direct/inbox/`.
- [ ] **Reels Tab:** Attempt to navigate to `/reels/` -> Blocked; redirected to `/direct/inbox/`.
- [ ] **Stories (When Disabled):** When `storiesViewMode: off`, tapping any story link -> Blocked with toast notice.
- [ ] **Profile Pages:** Tapping an account username or avatar leading to `/<user>/` -> Blocked; user stays in chat thread.
- [ ] **Bio / External Links:** Tapping an external link in a message -> Displays explicit "Open External Link?" confirmation dialog before launching system browser.

---

### Step 7: System Back Button Behavior
- [ ] **In Single Reel / Story Viewer:** Pressing hardware back button must close viewer and return to DMs (never opens previous suggested reel).
- [ ] **In Message Thread:** Pressing hardware back button returns to `/direct/inbox/`.
- [ ] **At Inbox Root:** Pressing hardware back button minimizes the app cleanly (`SystemNavigator.pop()`) without closing session.
- [ ] **In Settings Sub-screens:** Pressing back button pops back to Settings root.

---

### Step 8: Offline Mode & Reconnection
- [ ] **Offline Detection:** Enable Airplane mode on physical device.
- [ ] **Error Overlay:** Navigate or refresh inbox. Confirm `_OfflineErrorOverlay` appears with friendly "No Internet Connection" illustration and Retry button.
- [ ] **Reconnection:** Disable Airplane mode, wait for Wi-Fi/cellular connection, and tap **Retry**. Confirm inbox reloads seamlessly.

---

### Step 9: App Kill & State Restoration
- [ ] **Background Kill:** Put ZeroScroll in background while in a chat thread. Open terminal and run `adb shell am kill com.apexventures.zeroscroll`.
- [ ] **Relaunch:** Reopen ZeroScroll.
- [ ] **Verification:** Confirm user session remains authenticated (cookies preserved in sandbox), local database items load instantly, and no crash occurs.

---

### Step 10: Notification Capture, Classification & Re-Posting
- [ ] **Permission Setup:** Ensure ZeroScroll is enabled in Android **Settings > Special app access > Notification access**.
- [ ] **Receive Instagram DM:** Send a test DM to the account from another phone.
  - Verify ZeroScroll captures notification in native SQLite.
  - Confirm notification displays sender handle and message text in ZeroScroll **Activity** tab.
- [ ] **Receive Instagram Like / Comment:** Have another account like a post.
  - When `isMessagesOnly: true`, confirm notification is silently filtered and not stored.
  - When `isMessagesOnly: false`, confirm notification is categorized under Activity.
- [ ] **ZeroScroll Re-posting:** Enable "Re-post notifications" in Settings. Verify ZeroScroll posts an alert under its own notification channel.

---

### Step 11: Limits, Budgets & Reply Friction
- [ ] **Daily Reel Budget:**
  - Set Daily Reel Budget to `2` in Limits settings.
  - Open 2 reels from DMs.
  - Attempt to open a 3rd reel.
  - **Verification:** Confirm "Daily Reel Limit Reached" blocking screen appears. Video playback halts.
- [ ] **Daily Time Limit & Emergency Unlock:**
  - Set Daily Time Limit to `1 minute` for testing.
  - Use app for 60 seconds.
  - Confirm full-screen "Done for today" overlay blocks interaction.
  - Tap **Emergency 5-Minute Unlock**. Confirm temporary 5-minute extension granted.
  - Verify emergency unlock count increments and max unlocks per day (default 2) is enforced.
- [ ] **Focus Schedule:**
  - Create a Focus Schedule covering the current time and weekday.
  - Confirm app transitions to "Focus Session Active" locked screen.
- [ ] **Reply Friction (5-Second Pause):**
  - Enable "Reply Friction" in Limits settings.
  - Tap a reel link in DMs.
  - Confirm 5-second countdown dialog appears with "Wait 5s" before allowing reel to open.

---

### Step 12: Biometric App Lock & Privacy Shield
- [ ] **Enable Biometric Lock:** In **Settings > Security & Privacy**, enable App Lock.
- [ ] **Lock on Launch:** Force stop app and launch. Confirm `AppLockScreen` renders before any WebView content or DMs are painted.
- [ ] **Authenticate:** Authenticate with fingerprint or PIN. Confirm instant unlock to inbox.
- [ ] **Timeout (Immediate / 1 min / 5 min):** Background app for configured timeout; verify app re-locks upon resumption.
- [ ] **FLAG_SECURE Toggle:** Enable "Hide screen in recents & block screenshots".
  - Press Android Recents / Overview button: Confirm app snapshot is blanked out.
  - Attempt device screenshot: Confirm Android blocks screenshot capture.

---

### Step 13: Log Out & Complete Data Wipe
- [ ] **Log Out Action:** In **Settings > Privacy**, tap **Log Out & Clear All Data**.
- [ ] **Confirmation Prompt:** Confirm destructive dialog warns that session cookies, notification archives, and cached limits will be purged.
- [ ] **Verification:**
  - WebView cookies and cache cleared.
  - Drift databases (`limits`, `preferences`) and native notification database (`zeroscroll_notifications.db`) wiped.
  - App redirects to clean Login screen.

---

### Step 14: Remote Config Kill Switch & Hot-Reload
- [ ] **Kill Switch Test:**
  - Publish test config with `"killSwitch": { "enabled": true, "message": "Emergency maintenance in progress." }`.
  - Launch app or trigger config refresh.
  - **Verification:** WebView is unmounted immediately; friendly maintenance card displays; no web requests sent to Instagram.
- [ ] **Live CSS Hot-Reload:**
  - Publish config with updated `hideSelectors`.
  - Verify WebView dynamically applies selectors without restarting app.

---

### Step 15: Sideload In-App Updater Flow
- [ ] **Version Check:** On launch with `sideload` flavor, verify app queries `version.json`.
- [ ] **Update Available Card:** If remote build > current build, verify non-blocking "Update available" card appears with changelog.
- [ ] **SHA-256 Checksum Validation:** Trigger APK download. Verify SHA-256 is checked before installer intent is launched.
- [ ] **PackageInstaller Intent:** Confirm system PackageInstaller sheet opens. Verify app installs cleanly without signature mismatch.

