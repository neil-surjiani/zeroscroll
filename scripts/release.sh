#!/usr/bin/env bash
# ==============================================================================
# ZeroScroll Sideload Release Script
# Builds the sideload release APK, computes its SHA-256 checksum,
# and outputs the formatted version.json manifest.
# ==============================================================================

set -euo pipefail

# 1. Resolve project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MOBILE_DIR="${ROOT_DIR}/mobile"

echo "=== ZeroScroll Sideload Release Automation ==="
echo "Project Root: ${ROOT_DIR}"
echo "Mobile Directory: ${MOBILE_DIR}"

# 2. Extract or accept version arguments
PUBSPEC_FILE="${MOBILE_DIR}/pubspec.yaml"
if [[ ! -f "${PUBSPEC_FILE}" ]]; then
  echo "Error: pubspec.yaml not found at ${PUBSPEC_FILE}" >&2
  exit 1
fi

# Read version string from pubspec.yaml (e.g. 1.0.0+1)
RAW_VERSION=$(grep '^version:' "${PUBSPEC_FILE}" | awk '{print $2}' | tr -d '\r')
VERSION_NAME="${1:-${RAW_VERSION%+*}}"
BUILD_NUMBER="${2:-${RAW_VERSION#*+}}"

echo "Target Version: ${VERSION_NAME}"
echo "Build Number:   ${BUILD_NUMBER}"

# 3. Clean and build the Sideload release APK
cd "${MOBILE_DIR}"
echo ""
echo "--> Compiling Sideload Release APK via Flutter..."
flutter build apk --flavor sideload -t lib/main_sideload.dart --release

APK_PATH="${MOBILE_DIR}/build/app/outputs/flutter-apk/app-sideload-release.apk"
if [[ ! -f "${APK_PATH}" ]]; then
  echo "Error: Release APK was not found at ${APK_PATH}" >&2
  exit 1
fi

APK_SIZE_BYTES=$(wc -c < "${APK_PATH}" | tr -d ' ')
echo ""
echo "--> Build successful!"
echo "APK Location: ${APK_PATH}"
echo "APK Size:     $(( APK_SIZE_BYTES / 1024 / 1024 )) MB (${APK_SIZE_BYTES} bytes)"

# 4. Compute SHA-256 Checksum
if command -v sha256sum >/dev/null 2>&1; then
  SHA256_HASH=$(sha256sum "${APK_PATH}" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
  SHA256_HASH=$(shasum -a 256 "${APK_PATH}" | awk '{print $1}')
elif command -v certutil.exe >/dev/null 2>&1; then
  SHA256_HASH=$(certutil.exe -hashfile "${APK_PATH}" SHA256 | sed -n '2p' | tr -d ' \r\n' | tr '[:upper:]' '[:lower:]')
else
  echo "Error: No SHA-256 hashing utility found (sha256sum, shasum, or certutil)." >&2
  exit 1
fi

echo "SHA-256 Hash: ${SHA256_HASH}"

# 5. Generate version.json content
RELEASED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
OUTPUT_DIR="${ROOT_DIR}/build/release"
mkdir -p "${OUTPUT_DIR}"
VERSION_JSON_FILE="${OUTPUT_DIR}/version.json"

# Default changelog or accept optional parameter
CHANGELOG="${3:-ZeroScroll v${VERSION_NAME} sideload update: Performance improvements and stability updates.}"
DEFAULT_APK_URL="https://raw.githubusercontent.com/apexventures/zeroscroll-config/main/releases/zeroscroll-sideload-v${VERSION_NAME}.apk"
APK_URL="${4:-${DEFAULT_APK_URL}}"
MIN_SUPPORTED_BUILD="${5:-1}"

cat <<EOF > "${VERSION_JSON_FILE}"
{
  "latestVersion": "${VERSION_NAME}",
  "latestBuild": ${BUILD_NUMBER},
  "minSupportedBuild": ${MIN_SUPPORTED_BUILD},
  "apkUrl": "${APK_URL}",
  "sha256": "${SHA256_HASH}",
  "changelog": "${CHANGELOG}",
  "releasedAt": "${RELEASED_AT}"
}
EOF

echo ""
echo "=== Generated version.json (${VERSION_JSON_FILE}) ==="
cat "${VERSION_JSON_FILE}"
echo ""
echo "=== Release artifacts ready! ==="
