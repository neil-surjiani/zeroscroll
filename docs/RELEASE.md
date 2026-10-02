# ZeroScroll — Release Signing & Distribution Guide

This document outlines the security architecture, signing configuration, keystore backup procedures, and build pipelines for **ZeroScroll**.

---

## 1. Signing Architecture & Key Management

ZeroScroll uses Android release signing via standard Gradle configuration reading from `mobile/android/key.properties`.

### Security Guarantees
- `key.properties` and keystore files (`*.keystore`, `*.jks`) are strictly excluded from version control in `.gitignore`.
- Under no circumstances must signing keys or passwords be checked into Git.
- Local developer builds default gracefully to the debug signing configuration when `key.properties` is absent, preventing build breakage for new contributors.

### Keystore Generation Procedure
To generate a production signing key pair:

```bash
keytool -genkeypair -v \
  -keystore mobile/android/app/release.keystore \
  -alias zeroscroll \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass <STRONG_STORE_PASSWORD> \
  -keypass <STRONG_KEY_PASSWORD> \
  -dname "CN=ZeroScroll, OU=ApexVentures, O=ApexVentures, L=San Francisco, ST=CA, C=US"
```

### Local Setup
1. Copy `mobile/android/key.properties.example` to `mobile/android/key.properties`:
   ```bash
   cp mobile/android/key.properties.example mobile/android/key.properties
   ```
2. Populate the real keystore credentials:
   ```properties
   storePassword=<STRONG_STORE_PASSWORD>
   keyPassword=<STRONG_KEY_PASSWORD>
   keyAlias=zeroscroll
   storeFile=release.keystore
   ```

---

## 2. Keystore Backup & Disaster Recovery

The production keystore represents cryptographic proof of identity. If the keystore is lost:
- Existing sideload users **cannot** install updates (Android package installer will fail with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
- Google Play App Signing key reset requires manual intervention with Google Play Console support.

### Backup Protocol
1. **Encrypted Archive:** Store an encrypted copy of `release.keystore` and `key.properties` in a dedicated organizational secret manager (e.g., 1Password Team Vault or Google Cloud KMS/Secret Manager).
2. **Offline Cold Storage:** Export the keystore to an air-gapped, encrypted hardware token (e.g. YubiKey / encrypted USB) stored in a secure physical location.
3. **Fingerprint Recording:** Record and verify the SHA-256 fingerprint:
   ```bash
   keytool -list -v -keystore mobile/android/app/release.keystore -alias zeroscroll
   ```

---

## 3. Build Flavors & Flavor Isolation

ZeroScroll maintains two strictly isolated flavors:

| Dimension | `play` Flavor | `sideload` Flavor |
| :--- | :--- | :--- |
| **Target Distribution** | Google Play Store | GitHub Releases / Direct Download |
| **Artifact Format** | Android App Bundle (`.aab`) | Universal APK (`.apk`) |
| **`REQUEST_INSTALL_PACKAGES`** | **Strictly Excluded** (Play Policy compliant) | **Included** (in `src/sideload/AndroidManifest.xml`) |
| **Self-Updater (`lib/features/updater`)** | Disabled / returns `null` safely | Enabled (background version checks & APK install) |
| **Application Label** | `ZeroScroll` | `ZeroScroll (Sideload)` |

---

## 4. Production Build Commands

All release builds execute with resource shrinking (`isShrinkResources = true`) and R8 minification (`isMinifyEnabled = true`) enabled.

### Sideload Release APK
To build the signed sideload APK:
```bash
flutter build apk --flavor sideload -t lib/main_sideload.dart --release
```
**Output Artifact:**
`mobile/build/app/outputs/flutter-apk/app-sideload-release.apk`

### Google Play App Bundle
To build the signed Play Store bundle:
```bash
flutter build appbundle --flavor play -t lib/main_play.dart --release
```
**Output Artifact:**
`mobile/build/app/outputs/bundle/playRelease/app-play-release.aab`

---

## 5. Automated Release & Website Deployment (Single Command)

ZeroScroll provides a dedicated, single-command release automation pipeline.

### Command Execution
From the project root:
```bash
npm run release
```
or via PowerShell:
```powershell
.\scripts\release.ps1
```
or via Bash:
```bash
./scripts/release.sh
```

### Decoupling from Standard Development Builds
> [!IMPORTANT]
> General development commands such as `flutter build apk` or `flutter run` will **NEVER** trigger release tracking, website updates, or deployment. The release pipeline runs **only** when explicitly invoked via `npm run release` or `./scripts/release.*`.

### What the Release Automation Does:
1. **Tracks Release Version & Build Number:**
   - Reads `mobile/pubspec.yaml` and historical releases in `docs/releases.json`.
   - Auto-increments build number if the version was already released, or accepts explicit bump flags (`--bump patch`, `--bump minor`, `--bump major`, `--version <x.y.z>`).
2. **Builds Sideload Release APK:**
   - Executes `flutter build apk --flavor sideload -t lib/main_sideload.dart --release`.
3. **Cryptographic Checksum & Size:**
   - Computes lowercase 64-character SHA-256 hash and exact file size.
4. **Deploys to Website Placeholder:**
   - Copies APK directly to `website/public/zeroscroll.apk` (served directly at `/zeroscroll.apk`).
   - Copies backup to `website/public/downloads/zeroscroll.apk` and archived `website/public/releases/zeroscroll-v<version>.apk`.
   - Generates/updates `website/public/version.json` for both the website UI and the in-app self-updater.
   - Appends release record to `docs/releases.json`.
   - Updates `website/.env.local`.
5. **Verifies Website Build:**
   - Runs `npm --prefix website run build` to verify website prerendering with the new release assets.
6. **Optional Vercel Deployment:**
   - Passing `--deploy` runs `npx vercel --prod` to deploy the updated website and APK directly.

### Advanced Flags:
```bash
# Bump patch version (e.g. 1.0.0 -> 1.0.1) and auto-increment build number
npm run release -- --bump patch

# Set explicit version and release notes
npm run release -- --version 1.1.0 --notes "Enhanced notification badges and smoother DM transitions"

# Deploy release and publish to Vercel
npm run release -- --deploy

# Fast packaging / deploy using existing compiled APK without rebuilding Flutter
npm run release -- --skip-build
```

---

## 6. Post-Build Verification Checklist

Before publishing any release artifact:
1. Verify SHA-256 checksum:
   ```bash
   Get-FileHash -Algorithm SHA256 build/app/outputs/flutter-apk/app-sideload-release.apk
   ```
2. Verify package name and permissions:
   ```bash
   aapt dump permissions build/app/outputs/flutter-apk/app-sideload-release.apk
   ```
3. For the `play` flavor, ensure `android.permission.REQUEST_INSTALL_PACKAGES` is **NOT** present in `playRelease/app-play-release.aab`.
4. Verify signature on APK:
   ```bash
   apksigner verify --verbose build/app/outputs/flutter-apk/app-sideload-release.apk
   ```
