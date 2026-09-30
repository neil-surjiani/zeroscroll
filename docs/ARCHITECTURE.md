# ZeroScroll — System Architecture & Technical Specification

## 1. Architectural Overview & Philosophy

**ZeroScroll** is an Android-first Flutter application engineered with one strict objective: providing a focused, distraction-free interface displaying **ONLY** the Direct Messages and Notifications/Activity sections of the user's account inside a guarded WebView container.

All algorithmic discovery mechanisms—including the Home Feed, Explore/Search tab, Reels feed, Stories tray, and external profile browsing—are structurally prevented, filtered, or blocked.

### Core Non-Negotiable Tenets
1. **Zero External Backend & Absolute Privacy:**
   - No app-specific backend exists.
   - All session data, authentication state, cookies, usernames, message bodies, and notification details remain strictly on-device in secure storage and Drift SQLite.
   - Zero analytics, crash reporting, or telemetry SDKs are bundled.
2. **Deterministic Flavor Isolation:**
   - Two distinct distribution flavors: `play` and `sideload`.
   - Any self-updating code and permissions (`REQUEST_INSTALL_PACKAGES`) are strictly isolated to the `sideload` flavor and omitted from `play`.
3. **Resilient DOM Selectors:**
   - No hardcoded dynamic or obfuscated CSS classes.
   - Selectors rely on semantic attributes (`href`, `aria-label`, `role`) and externalized remote configuration so updates never require breaking binary patches.

---

## 2. Directory & Layer Organization

The project follows a **Feature-First Clean Architecture**:

```
ZeroScroll/
├── android/
│   └── app/
│       ├── build.gradle.kts                      # Gradle build config with play & sideload flavors
│       ├── proguard-rules.pro                   # R8/ProGuard shrinking & obfuscation rules
│       └── src/
│           ├── main/
│           │   ├── AndroidManifest.xml          # Base Android manifest (INTERNET, ACCESS_NETWORK_STATE)
│           │   └── kotlin/com/apexventures/zeroscroll/MainActivity.kt
│           ├── play/
│           │   └── AndroidManifest.xml          # Play store manifest (no updater permissions)
│           └── sideload/
│               └── AndroidManifest.xml          # Sideload manifest (REQUEST_INSTALL_PACKAGES)
├── lib/
│   ├── main.dart                                # Universal Flutter entrypoint
│   ├── main_play.dart                           # Dedicated Play flavor entrypoint
│   ├── main_sideload.dart                       # Dedicated Sideload flavor entrypoint
│   ├── core/
│   │   ├── config/                              # AppFlavor & FlavorConfig providers
│   │   ├── constants/                           # AppConstants (IDs, URLs, SDK versions)
│   │   ├── database/                            # Drift SQLite database definition
│   │   ├── router/                              # GoRouter declarative navigation
│   │   └── theme/                               # Material 3 light and dark theme definitions
│   └── features/
│       ├── webview/                             # Guarded WebView orchestration & content injection
│       ├── shell/                               # Root navigation scaffold & bottom destination bar
│       ├── notifications/                       # In-app notifications & account activity
│       ├── limits/                              # Session tracking & daily usage limits
│       ├── settings/                            # User preferences & customization
│       ├── stories/                             # Isolated story tray, single-user lock, fail-closed guard
│       ├── onboarding/                          # Privacy manifesto & initial walkthrough
│       ├── remote_config/                       # Remote selector rules & security patterns
│       ├── security/                            # Biometric authentication (local_auth)
│       └── updater/                             # Sideload in-app APK updater
├── test/                                        # Unit & widget tests
└── docs/
    └── ARCHITECTURE.md                          # This architecture specification
```

---

## 3. The Layered Structure

Each feature inside `lib/features/<feature>/` adheres to the following three layers:

```mermaid
graph TD
    UI[Presentation Layer: Screens & Widgets] -->|Watch / Read| Notifier[Presentation Layer: Riverpod Notifiers]
    Notifier -->|Invoke Use Cases / Repositories| Domain[Domain Layer: Entities, Contracts, Policies]
    Data[Data Layer: Local Storage, Drift DB, APIs] -->|Implement Contracts| Domain
    Notifier -->|Read State| UI
```

### 3.1 Domain Layer (`domain/`)
- Contains pure Dart business entities, value objects, and repository interfaces.
- Completely free of external framework dependencies (Flutter widgets, HTTP clients, Drift implementations).
- Defines contracts that describe what operations are possible without specifying how they are implemented.

### 3.2 Data Layer (`data/`)
- Implements the repository interfaces defined in the domain layer.
- Handles interactions with low-level data sources:
  - Drift (SQLite) database for persistent state and usage metrics.
  - `SharedPreferences` for user preferences and feature flags.
  - Native platform channels (via `local_auth` and `flutter_inappwebview`).
  - Read-only HTTPS client for remote config and version checks.

### 3.3 Presentation Layer (`presentation/`)
- Built entirely using Riverpod (`StateNotifierProvider`, `FutureProvider`, `Provider`).
- Implements Material 3 responsive UI components.
- Reacts directly to immutable state changes without managing imperative widget state.

---

## 4. Unidirectional Data Flow

The app enforces a strict unidirectional reactive data flow:

```mermaid
sequenceDiagram
    participant User
    participant Widget as Presentation: Widget
    participant Provider as Presentation: Riverpod Notifier
    participant Repo as Data: Repository
    participant Storage as Drift / Local Storage

    User->>Widget: Interacts (e.g. set limit, lock app)
    Widget->>Provider: Dispatches Intent / Method call
    Provider->>Repo: Executes repository action
    Repo->>Storage: Persists change locally
    Storage-->>Repo: Returns updated data
    Repo-->>Provider: Emits new domain state
    Provider-->>Widget: Emits updated AsyncValue/State
    Widget->>User: Re-renders updated UI
```

---

## 5. Feature Map & Responsibilities

| Feature | Responsibility | Key Components |
| :--- | :--- | :--- |
| **`webview`** | Displays the guarded web container; injects CSS/JS rules; intercepts URLs; restricts media viewer to one item at a time. | `WebviewMode`, `WebviewRepository`, `webviewNotifierProvider` |
| **`shell`** | Manages the root scaffold, bottom navigation, and top bar; exposes flavor badges. | `ShellTab`, `ShellRepository`, `HomeScreen`, `activeShellTabProvider` |
| **`notifications`** | Aggregates and displays account notifications and message alerts in-app. | `NotificationItem`, `NotificationsRepository`, `notificationsListProvider` |
| **`limits`** | Tracks daily screen time inside messages and alerts user when limits are reached. | `UsageLimit`, `LimitsRepository`, `limitsProvider` |
| **`settings`** | Manages theme mode, biometric locks, clearing cache, and developer inspection info. | `AppSettings`, `SettingsRepository`, `settingsNotifierProvider` |
| **`onboarding`** | Introduces the app's privacy-first posture and guides the user through setup. | `OnboardingPageData`, `OnboardingRepository`, `onboardingStateProvider` |
| **`remote_config`** | Fetches and caches remote route rules and DOM selectors without app binary updates. | `RemoteConfigModel`, `RemoteConfigRepository`, `remoteConfigProvider` |
| **`security`** | Manages app-level biometric unlocking via `local_auth` and prevents unauthorized access. | `SecurityStatus`, `SecurityRepository`, `securityProvider` |
| **`stories`** | Manages isolated story tray display, single-user lock, story budget tracking, and external posting handoff. | `StoriesTrayScreen`, `StoryBudgetService`, `storyBudgetServiceProvider`, `featurePreferencesProvider` |
| **`updater`** | Checks for APK updates and prompts installations (strictly active on `sideload` flavor). | `UpdateInfo`, `UpdaterRepository`, `updateCheckProvider` |

---

## 6. Build Flavor Isolation

| Dimension | Play Store Flavor (`play`) | Sideload Flavor (`sideload`) |
| :--- | :--- | :--- |
| **Application ID** | `com.apexventures.zeroscroll` | `com.apexventures.zeroscroll` |
| **App Title** | `ZeroScroll` | `ZeroScroll (Sideload)` |
| **Updater Code** | Disabled (returns `null` safely) | Enabled (reads `version.json`, downloads APK) |
| **Permissions** | `INTERNET`, `ACCESS_NETWORK_STATE` | `INTERNET`, `ACCESS_NETWORK_STATE`, `REQUEST_INSTALL_PACKAGES` |
| **Launch Entrypoint** | `lib/main_play.dart` | `lib/main_sideload.dart` |
| **CLI Run Command** | `flutter run --flavor play -t lib/main_play.dart` | `flutter run --flavor sideload -t lib/main_sideload.dart` |

---

## 7. Verification & Continuous Integration (CI)

Every commit and pull request must execute:
1. `flutter analyze` — Enforces strict Dart linting rules with zero warnings.
2. `flutter test` — Runs all unit and widget tests across domain logic, providers, and presentation.
3. R8 code shrinking and optimization checks during release builds.

---

## 8. Optional Stories Architecture & Mindful Guardrails

Stories in ZeroScroll are **strictly OFF by default** (`StoriesViewMode.off`). When explicitly enabled by the user in Settings, Stories are governed by the same mindful principles that protect against infinite scrolling and algorithmic traps:

```mermaid
flowchart TD
    Pref{Stories View Mode}
    Pref -->|off| Blocked[Stories Blocked Everywhere & Hidden Tray]
    Pref -->|fromDmsOnly| DmOnly[Allow /stories/ from DM threads only; Tray Hidden]
    Pref -->|fromFollowing| FollTab[Dynamic 4th 'Stories' Tab in Bottom Bar]

    FollTab --> Tray[Load / in Tray-Only Isolation Mode]
    Tray --> CheckFeed{Watchdog: Feed Post detected OR Tray Timeout > 5s?}
    CheckFeed -->|Yes| FailClosed[Fail-Closed: Unmount WebView & Display Fallback Shield]
    CheckFeed -->|No| OpenStory[User Taps Story Bubble]

    OpenStory --> StoryViewer[Enter Story Viewer Mode]
    StoryViewer --> Lock[Single-User Session Lock Active]
    StoryViewer --> Budget[Check & Decrement Daily Story Budget]
    StoryViewer --> UIOverlay[Persistent High-Contrast Close Bar + Counter]

    StoryViewer --> NextAction{Next Story Action}
    NextAction -->|Same User Next Segment| Allow[Allow Slide Transition]
    NextAction -->|Attempt Advance to Different User| Intercept[Block Advance, Close Viewer, Toast: Last story from @user]
    NextAction -->|Daily Budget Reached| LimitScreen[Display 'Daily Story Limit Reached' Overlay]
    NextAction -->|Tap Close Button| ReturnInbox[Return to Previous Safe Route]
```

### 8.1 Feature Preferences & Local Storage
Stories and content toggles are encapsulated in `FeaturePreferences` (`lib/features/settings/domain/feature_preferences.dart`) and stored on-device in Drift SQLite:
- `storiesViewMode`: `off` (default), `fromDmsOnly`, `fromFollowing`.
- `dailyStoryLimit`: Default `10` (or `null` for unlimited).
- `storiesPostingEnabled`: Default `false`.
- `reelsFromDmsEnabled`: Default `true`.
- `sharedPostsFromDmsEnabled`: Default `true`.

### 8.2 Configuration Feature Groups
Remote configuration (`RouteConfig`) is refactored from a monolithic regex list into 7 distinct feature groups:
1. `dms`: Direct message inboxes and message threads (always-on).
2. `activity`: Notifications and activity feeds (always-on).
3. `reels`: Single reel viewing from DMs (controlled by `reelsFromDmsEnabled`).
4. `storiesView`: Story viewer routes (active when `storiesViewMode != off`).
5. `storiesFromFollowing`: Story tray and home routing in tray mode (active when `storiesViewMode == fromFollowing`).
6. `storiesCreate`: Story creation / posting routes (active when `storiesPostingEnabled == true`).
7. `sharedPosts`: Single shared post viewer routes (controlled by `sharedPostsFromDmsEnabled`).

The app's `effectiveRouteConfigProvider` dynamically recomputes the active configuration whenever `featurePreferencesProvider` changes, ensuring zero configuration drift.

### 8.3 Story Viewer Mode & Single-User Lock
When viewing a story (e.g., `/stories/alice/123/`):
- **Dart Layer (Layer 1):** `shouldOverrideUrlLoading` and `onLoadStart` track `_currentStoryUsername`. If navigation changes the username to `bob`, navigation is cancelled, the viewer closes, and a notification toast displays: *"That was the last story from @alice."*
- **JavaScript Layer (Layer 2):** In `assets/js/guard.js`, DOM mutations, History API methods (`pushState`, `replaceState`), and popstate events are intercepted. Any attempt to advance to a different user invokes the Flutter JavaScript handler `onNextStoryUserBlocked`, halting execution immediately.
- **Friction & Overlays:** The story viewer displays a persistent top bar featuring a prominent Close button and progress indicator (`Story 3 / 10`). Auto-advancing past the current creator is structurally prohibited.

### 8.4 Fail-Closed Home Feed Isolation (`StoriesTrayScreen`)
Loading stories from following requires navigating to `/` where the web story tray resides:
- All algorithmic feed elements (`article`, `[role="feed"]`, explore cards) are immediately hidden via injected CSS.
- An active 5-second watchdog timer monitors the DOM.
- **Fail-Closed Guarantee:** If any feed post element becomes visible in the layout, or if the story tray fails to render within 5 seconds, the WebView is immediately unmounted and replaced with a native fallback shield screen (*"Stories Feed Hidden"*). Algorithmic posts are never exposed to the user.

### 8.5 Story Posting & External App Handoff
To preserve sandbox integrity and prevent exposure to web creation flows that could leak feeds or capture unintended camera streams:
- In-app story posting is strictly disabled.
- When `storiesPostingEnabled` is active and the user taps "Post Story", ZeroScroll displays an **External App Handoff** modal warning: *"ZeroScroll cannot verify official app behavior outside this sandbox."*
- Upon explicit confirmation, an Android Intent is dispatched to the native camera or the official app, keeping ZeroScroll's sandboxed WebView completely isolated.

---

## 9. Threat Modeling & Isolation Safeguards

| Threat Vector | Severity | ZeroScroll Countermeasure |
| :--- | :--- | :--- |
| **Algorithmic Feed Leak on Mobile Home** | High | Injected CSS hides all `article` and `[role="feed"]` containers; 5-second watchdog unmounts WebView immediately if feed elements or timeout occurs. |
| **Endless Story Auto-Advancement Across Accounts** | High | Dual-layer single-user session lock (Dart URL interceptor + JS pushState interception); stops and closes viewer on username mismatch. |
| **Data Exfiltration of User Story Habits** | Critical | All story views, budgets, and timestamps are stored exclusively in local Drift SQLite table `story_events`; no network pings or telemetry. |
| **Malicious Web View File/Camera Access** | High | Story posting web routes are blocked; posting is delegated via Intent handoff to external apps with explicit user warning dialog. |
| **Configuration Inconsistency Across Toggles** | Medium | Table-driven unit tests verify all 24 toggle permutations for `RouteConfig` feature groups, ensuring fail-closed defaults. |

