#!/usr/bin/env bash
# ==============================================================================
# ZeroScroll Sideload Release Script
# Builds the sideload release APK, tracks version & build number, computes SHA-256,
# and deploys artifacts to the website download placeholder.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run Node.js release automation engine
node "${SCRIPT_DIR}/release.js" "$@"
