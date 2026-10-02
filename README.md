# ZeroScroll

**ZeroScroll** is an Android-first application and website engineered for intentional, distraction-free communication: displaying **ONLY** your Instagram Direct Messages and Notifications, with no algorithmic feeds, Search/Explore, Reels tab, or Stories.

This monorepo is organized into two distinct subfolders:

```text
ZeroScroll/
├── mobile/     # Android Flutter Application
├── website/    # Next.js Landing Page & Web Application
├── docs/       # Architecture & Specification Documents
├── AGENTS.md   # Project rules and agent guidelines
└── logo.png    # Official ZeroScroll brand mark
```

---

## 📱 Mobile App (`mobile/`)

Built with **Flutter (stable)**, **Riverpod**, and **Drift (SQLite)** for Android.

### Features
- Guarded WebView container filtering out all feeds, reels, stories, and algorithmic discovery.
- Messages inbox and direct conversations only.
- Account activity and notifications only.
- Single-play reels from DMs with zero swipe-up continuous scrolling.
- Daily reel budget and intentional time limits.
- Biometric lock (`local_auth`) and local-only SQLite storage (`drift`).
- Zero external backend, zero analytics, absolute privacy.

### Quick Start
```bash
cd mobile
flutter pub get
flutter run --flavor sideload -t lib/main_sideload.dart
```
See [`mobile/README.md`](mobile/README.md) for more build details.

---

## 🌐 Website (`website/`)

Built with **Next.js (App Router)**, **TypeScript**, and **Tailwind CSS**, ready to deploy on **Vercel**.

### Features
- Minimalist landing page with CSS/SVG phone mockup, features, blocked surfaces, privacy pillars, and FAQ.
- Dedicated `/privacy` and `/terms` pages.
- System dark mode support, deep teal accent, and fast static generation (Lighthouse 95+ target).
- Zero cookies, zero analytics, zero external tracking scripts.

### Quick Start
```bash
# Run from repository root
npm run dev

# Or run directly in website/
cd website
npm install
npm run dev
```

### Building & Deploying to Vercel
```bash
# Production build from root
npm run build
```

When importing this repository into Vercel, set the **Root Directory** to `website`.
See [`website/README.md`](website/README.md) for full deployment instructions and environment variables.

---

## 🚀 One-Command Release & Website Deployment (`npm run release`)

To compile the latest sideload release APK, record version/build tracking, compute SHA-256 checksum, and deploy the artifact directly into the website placeholder:

```bash
# Standard release (reads pubspec.yaml & docs/releases.json)
npm run release

# Or via PowerShell on Windows:
.\scripts\release.ps1

# Options:
npm run release -- --bump patch        # Bump patch version & increment build
npm run release -- --version 1.1.0     # Explicit version
npm run release -- --notes "Changelog" # Custom release notes
npm run release -- --deploy            # Deploy website to Vercel production
npm run release -- --skip-build        # Fast deploy with existing APK
```

> **Note on Standard Builds:** General development commands such as `flutter build apk` or `flutter run` will **NEVER** trigger release tracking or website deployment. Only explicitly running `npm run release` (or `.\scripts\release.ps1` / `scripts/release.sh`) triggers the release pipeline.

