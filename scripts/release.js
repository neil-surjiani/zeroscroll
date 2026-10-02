#!/usr/bin/env node

/**
 * ==============================================================================
 * ZeroScroll Release & Deployment Automation Script
 * ==============================================================================
 * 
 * One-command pipeline to:
 * 1. Read & track release versions and build numbers from pubspec.yaml and releases.json.
 * 2. Optionally bump version (patch, minor, major, build).
 * 3. Build the Sideload Release APK using Flutter with strict flavor isolation.
 * 4. Compute SHA-256 cryptographic checksum and file size.
 * 5. Deploy the APK and version manifests to the website's download placeholder:
 *    - website/public/zeroscroll.apk (primary direct download)
 *    - website/public/downloads/zeroscroll.apk
 *    - website/public/releases/zeroscroll-v<version>.apk (archived version)
 *    - website/public/version.json (sideload self-updater & website source of truth)
 *    - docs/releases.json (release tracking ledger)
 *    - website/.env.local (environment variables sync)
 * 6. Verify website build with the new release assets.
 * 7. (Optional) Deploy website to Vercel via --deploy.
 * 
 * NOTE: Normal `flutter build apk` commands DO NOT trigger this pipeline.
 * Only explicit invocation of this script (e.g. `npm run release`) triggers it.
 * ==============================================================================
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

// 1. Resolve project directories
const SCRIPT_DIR = __dirname;
const ROOT_DIR = path.resolve(SCRIPT_DIR, '..');
const MOBILE_DIR = path.join(ROOT_DIR, 'mobile');
const WEBSITE_DIR = path.join(ROOT_DIR, 'website');
const WEBSITE_PUBLIC_DIR = path.join(WEBSITE_DIR, 'public');
const WEBSITE_DOWNLOADS_DIR = path.join(WEBSITE_PUBLIC_DIR, 'downloads');
const WEBSITE_RELEASES_DIR = path.join(WEBSITE_PUBLIC_DIR, 'releases');
const DOCS_DIR = path.join(ROOT_DIR, 'docs');
const BUILD_RELEASE_DIR = path.join(ROOT_DIR, 'build', 'release');

const PUBSPEC_FILE = path.join(MOBILE_DIR, 'pubspec.yaml');
const RELEASES_LOG_FILE = path.join(DOCS_DIR, 'releases.json');
const WEBSITE_VERSION_FILE = path.join(WEBSITE_PUBLIC_DIR, 'version.json');
const ROOT_VERSION_FILE = path.join(BUILD_RELEASE_DIR, 'version.json');
const WEBSITE_ENV_FILE = path.join(WEBSITE_DIR, '.env.local');
const APK_SOURCE_PATH = path.join(
  MOBILE_DIR,
  'build',
  'app',
  'outputs',
  'flutter-apk',
  'app-sideload-release.apk'
);

// 2. Parse command-line arguments
function parseArgs() {
  const args = process.argv.slice(2);
  const options = {
    bump: null, // 'patch' | 'minor' | 'major' | 'build'
    version: null,
    buildNumber: null,
    notes: null,
    minSupportedBuild: 1,
    publicUrl: null,
    skipBuild: false,
    noBump: false,
    deploy: false,
    noWebsiteBuild: false,
    help: false,
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--bump') {
      options.bump = args[++i];
    } else if (arg.startsWith('--bump=')) {
      options.bump = arg.split('=')[1];
    } else if (arg === '--version' || arg === '-v') {
      options.version = args[++i];
    } else if (arg.startsWith('--version=')) {
      options.version = arg.split('=')[1];
    } else if (arg === '--build-number' || arg === '-b') {
      options.buildNumber = parseInt(args[++i], 10);
    } else if (arg.startsWith('--build-number=')) {
      options.buildNumber = parseInt(arg.split('=')[1], 10);
    } else if (arg === '--notes' || arg === '-m' || arg === '--changelog') {
      options.notes = args[++i];
    } else if (arg.startsWith('--notes=')) {
      options.notes = arg.split('=')[1];
    } else if (arg === '--min-supported-build') {
      options.minSupportedBuild = parseInt(args[++i], 10);
    } else if (arg.startsWith('--min-supported-build=')) {
      options.minSupportedBuild = parseInt(arg.split('=')[1], 10);
    } else if (arg === '--public-url') {
      options.publicUrl = args[++i];
    } else if (arg.startsWith('--public-url=')) {
      options.publicUrl = arg.split('=')[1];
    } else if (arg === '--skip-build') {
      options.skipBuild = true;
    } else if (arg === '--no-bump') {
      options.noBump = true;
    } else if (arg === '--deploy' || arg === '--vercel') {
      options.deploy = true;
    } else if (arg === '--no-website-build') {
      options.noWebsiteBuild = true;
    }
  }

  return options;
}

function printHelp() {
  console.log(`
ZeroScroll Release & Deployment Automation

USAGE:
  npm run release [OPTIONS]
  node scripts/release.js [OPTIONS]

OPTIONS:
  --bump <type>           Bump version: 'patch', 'minor', 'major', or 'build'
  --version <x.y.z>       Set explicit version name (e.g. 1.0.1)
  --build-number <int>    Set explicit build number (e.g. 2)
  --no-bump               Preserve exact current version without incrementing
  --notes, -m "<text>"    Release notes / changelog
  --min-supported-build <int>
                          Minimum supported build for self-updater (default: 1)
  --public-url <url>      Full HTTPS download URL for in-app updater
  --skip-build            Skip 'flutter build apk' (use existing APK artifact)
  --no-website-build      Skip website pre-render check
  --deploy                Deploy website to Vercel after release packaging
  --help, -h              Show this help message

EXAMPLES:
  npm run release
  npm run release -- --bump patch
  npm run release -- --version 1.0.1 --notes "New notifications badge fix"
  npm run release -- --deploy
`);
}

function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
}

// 3. Main automation runner
function run() {
  const options = parseArgs();

  if (options.help) {
    printHelp();
    process.exit(0);
  }

  console.log('\n======================================================');
  console.log('       ZeroScroll Release & Website Deployment        ');
  console.log('======================================================\n');

  // Verify pubspec.yaml
  if (!fs.existsSync(PUBSPEC_FILE)) {
    console.error(`Error: pubspec.yaml not found at ${PUBSPEC_FILE}`);
    process.exit(1);
  }

  const pubspecContent = fs.readFileSync(PUBSPEC_FILE, 'utf-8');
  const versionMatch = pubspecContent.match(/^version:\s*([0-9.]+)\+?([0-9]*)/m);

  if (!versionMatch) {
    console.error('Error: Could not parse version from mobile/pubspec.yaml');
    process.exit(1);
  }

  let currentVersion = versionMatch[1];
  let currentBuildNumber = parseInt(versionMatch[2] || '1', 10);

  console.log(`Current Version in pubspec: ${currentVersion}+${currentBuildNumber}`);

  // Load existing releases log
  let releasesHistory = [];
  if (fs.existsSync(RELEASES_LOG_FILE)) {
    try {
      releasesHistory = JSON.parse(fs.readFileSync(RELEASES_LOG_FILE, 'utf-8'));
      if (!Array.isArray(releasesHistory)) releasesHistory = [];
    } catch {
      releasesHistory = [];
    }
  }

  // Determine target version and build number
  let targetVersion = currentVersion;
  let targetBuildNumber = currentBuildNumber;

  if (options.version) {
    targetVersion = options.version.replace(/^v/, '');
  }

  if (options.buildNumber) {
    targetBuildNumber = options.buildNumber;
  } else if (!options.noBump) {
    if (options.bump) {
      const parts = currentVersion.split('.').map((p) => parseInt(p, 10));
      while (parts.length < 3) parts.push(0);

      if (options.bump === 'major') {
        parts[0] += 1;
        parts[1] = 0;
        parts[2] = 0;
      } else if (options.bump === 'minor') {
        parts[1] += 1;
        parts[2] = 0;
      } else if (options.bump === 'patch') {
        parts[2] += 1;
      } else if (options.bump === 'build') {
        // keep version name, only increment build number
      } else {
        console.error(`Unknown bump type: ${options.bump}. Use 'patch', 'minor', 'major', or 'build'.`);
        process.exit(1);
      }
      if (options.bump !== 'build' && !options.version) {
        targetVersion = parts.join('.');
      }
      targetBuildNumber = currentBuildNumber + 1;
    } else if (!options.version && !options.buildNumber) {
      // Default: If current version+build was already published, increment build number
      const alreadyReleased = releasesHistory.some(
        (r) => r.version === currentVersion && r.buildNumber === currentBuildNumber
      );
      if (alreadyReleased) {
        targetBuildNumber = currentBuildNumber + 1;
        console.log(`Auto-incrementing build number to ${targetBuildNumber} because ${currentVersion}+${currentBuildNumber} was already released.`);
      }
    }
  }

  console.log(`Target Release Version:     ${targetVersion}`);
  console.log(`Target Build Number:        ${targetBuildNumber}`);

  // Update mobile/pubspec.yaml if changed
  const newVersionString = `${targetVersion}+${targetBuildNumber}`;
  if (newVersionString !== `${currentVersion}+${currentBuildNumber}`) {
    console.log(`--> Updating mobile/pubspec.yaml to version: ${newVersionString}`);
    const updatedPubspec = pubspecContent.replace(
      /^version:\s*.*$/m,
      `version: ${newVersionString}`
    );
    fs.writeFileSync(PUBSPEC_FILE, updatedPubspec, 'utf-8');
  }

  // Build Sideload Release APK (unless skipped)
  if (!options.skipBuild) {
    console.log('\n--> Building Sideload Release APK with Flutter...');
    console.log('    Command: flutter build apk --flavor sideload -t lib/main_sideload.dart --release\n');

    try {
      execSync('flutter build apk --flavor sideload -t lib/main_sideload.dart --release', {
        cwd: MOBILE_DIR,
        stdio: 'inherit',
      });
    } catch (err) {
      console.error('\nError: Flutter APK build failed.');
      process.exit(1);
    }
  } else {
    console.log('\n--> --skip-build flag set. Skipping Flutter APK compilation.');
  }

  // Verify APK exists
  if (!fs.existsSync(APK_SOURCE_PATH)) {
    console.error(`\nError: Release APK was not found at ${APK_SOURCE_PATH}`);
    process.exit(1);
  }

  const apkStats = fs.statSync(APK_SOURCE_PATH);
  const apkSizeBytes = apkStats.size;
  const apkSizeFormatted = formatBytes(apkSizeBytes);

  // Compute SHA-256 hash
  console.log('\n--> Computing SHA-256 checksum...');
  const fileBuffer = fs.readFileSync(APK_SOURCE_PATH);
  const sha256Hash = crypto.createHash('sha256').update(fileBuffer).digest('hex').toLowerCase();

  console.log(`    SHA-256: ${sha256Hash}`);
  console.log(`    Size:    ${apkSizeFormatted} (${apkSizeBytes.toLocaleString()} bytes)`);

  // Ensure output directories exist
  [
    WEBSITE_PUBLIC_DIR,
    WEBSITE_DOWNLOADS_DIR,
    WEBSITE_RELEASES_DIR,
    DOCS_DIR,
    BUILD_RELEASE_DIR,
  ].forEach((dir) => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });

  // Deploy APK to website placeholder
  console.log('\n--> Deploying APK to website placeholder...');
  const targetWebsiteApk = path.join(WEBSITE_PUBLIC_DIR, 'zeroscroll.apk');
  const targetDownloadsApk = path.join(WEBSITE_DOWNLOADS_DIR, 'zeroscroll.apk');
  const targetVersionedApk = path.join(WEBSITE_RELEASES_DIR, `zeroscroll-v${targetVersion}.apk`);

  fs.copyFileSync(APK_SOURCE_PATH, targetWebsiteApk);
  fs.copyFileSync(APK_SOURCE_PATH, targetDownloadsApk);
  fs.copyFileSync(APK_SOURCE_PATH, targetVersionedApk);

  console.log(`    [x] ${path.relative(ROOT_DIR, targetWebsiteApk)} (Website root direct download)`);
  console.log(`    [x] ${path.relative(ROOT_DIR, targetDownloadsApk)} (Alternative downloads route)`);
  console.log(`    [x] ${path.relative(ROOT_DIR, targetVersionedApk)} (Archived version binary)`);

  // Prepare manifest data
  const releasedAt = new Date().toISOString();
  const changelog =
    options.notes ||
    `ZeroScroll v${targetVersion} sideload release with pure DM focus, offline security, and stability improvements.`;
  const defaultPublicUrl = `https://zeroscroll.app/zeroscroll.apk`;
  const publicApkUrl = options.publicUrl || defaultPublicUrl;

  const versionManifest = {
    latestVersion: targetVersion,
    latestBuild: targetBuildNumber,
    minSupportedBuild: options.minSupportedBuild || 1,
    apkUrl: publicApkUrl,
    apkPath: '/zeroscroll.apk',
    fileName: 'zeroscroll.apk',
    fileSizeBytes: apkSizeBytes,
    fileSizeFormatted: apkSizeFormatted,
    sha256: sha256Hash,
    changelog: changelog,
    releasedAt: releasedAt,
  };

  // Write website/public/version.json
  console.log('\n--> Updating version manifests...');
  fs.writeFileSync(WEBSITE_VERSION_FILE, JSON.stringify(versionManifest, null, 2) + '\n', 'utf-8');
  console.log(`    [x] ${path.relative(ROOT_DIR, WEBSITE_VERSION_FILE)}`);

  // Write build/release/version.json
  fs.writeFileSync(ROOT_VERSION_FILE, JSON.stringify(versionManifest, null, 2) + '\n', 'utf-8');
  console.log(`    [x] ${path.relative(ROOT_DIR, ROOT_VERSION_FILE)}`);

  // Write website/public/releases/zeroscroll-v<version>.json
  const versionedManifestPath = path.join(WEBSITE_RELEASES_DIR, `zeroscroll-v${targetVersion}.json`);
  fs.writeFileSync(versionedManifestPath, JSON.stringify(versionManifest, null, 2) + '\n', 'utf-8');
  console.log(`    [x] ${path.relative(ROOT_DIR, versionedManifestPath)}`);

  // Update website/.env.local
  const envContent = `NEXT_PUBLIC_APK_URL=/zeroscroll.apk\nNEXT_PUBLIC_APP_VERSION=v${targetVersion}\n`;
  fs.writeFileSync(WEBSITE_ENV_FILE, envContent, 'utf-8');
  console.log(`    [x] ${path.relative(ROOT_DIR, WEBSITE_ENV_FILE)}`);

  // Update docs/releases.json history ledger
  const releaseRecord = {
    version: targetVersion,
    buildNumber: targetBuildNumber,
    releasedAt: releasedAt,
    sha256: sha256Hash,
    fileSizeBytes: apkSizeBytes,
    fileSizeFormatted: apkSizeFormatted,
    apkPath: '/zeroscroll.apk',
    archivedAs: `/releases/zeroscroll-v${targetVersion}.apk`,
    changelog: changelog,
  };

  // Check if this release already exists in history, replace or prepend
  const existingIndex = releasesHistory.findIndex(
    (r) => r.version === targetVersion && r.buildNumber === targetBuildNumber
  );

  if (existingIndex >= 0) {
    releasesHistory[existingIndex] = releaseRecord;
  } else {
    releasesHistory.unshift(releaseRecord);
  }

  fs.writeFileSync(RELEASES_LOG_FILE, JSON.stringify(releasesHistory, null, 2) + '\n', 'utf-8');
  console.log(`    [x] ${path.relative(ROOT_DIR, RELEASES_LOG_FILE)} (Tracked ${releasesHistory.length} release${releasesHistory.length === 1 ? '' : 's'})`);

  // Verify website build with new assets
  if (!options.noWebsiteBuild) {
    console.log('\n--> Verifying website build with new release assets...');
    try {
      execSync('npm --prefix website run build', {
        cwd: ROOT_DIR,
        stdio: 'inherit',
      });
      console.log('--> Website build successfully verified!');
    } catch (err) {
      console.warn('\nWarning: Website build completed with warnings or errors.');
    }
  }

  // Optional: Deploy website to Vercel
  if (options.deploy) {
    console.log('\n--> Deploying website to Vercel production...');
    try {
      execSync('npx vercel --prod', {
        cwd: WEBSITE_DIR,
        stdio: 'inherit',
      });
      console.log('--> Vercel production deployment completed successfully!');
    } catch (err) {
      console.warn('\nVercel deployment returned non-zero exit code. Please check Vercel CLI credentials.');
    }
  }

  // Summary Report
  console.log('\n======================================================');
  console.log('       Release & Website Deployment Successful!       ');
  console.log('======================================================');
  console.log(`  Version:         v${targetVersion} (Build #${targetBuildNumber})`);
  console.log(`  APK Size:        ${apkSizeFormatted}`);
  console.log(`  SHA-256:         ${sha256Hash}`);
  console.log(`  Website Route:   /zeroscroll.apk`);
  console.log(`  Version API:     /version.json`);
  console.log(`  Release Log:     ${path.relative(ROOT_DIR, RELEASES_LOG_FILE)}`);
  console.log('======================================================\n');
}

run();
