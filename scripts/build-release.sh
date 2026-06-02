#!/usr/bin/env bash
# Mirrors the GitHub Actions Release/Build workflow. Run on macOS before tagging.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA="${DERIVED_DATA:-/tmp/AIIMEOverlay-build}"

cd "$ROOT"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "error: xcodebuild not found. Run this script on a Mac with Xcode installed." >&2
  exit 1
fi

echo "Building AIIMEOverlay (Release) → $DERIVED_DATA"
xcodebuild \
  -project AIIMEOverlay.xcodeproj \
  -scheme AIIMEOverlay \
  -configuration Release \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="-" \
  DEVELOPMENT_TEAM=""

APP_PATH="$DERIVED_DATA/Build/Products/Release/AIIMEOverlay.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "error: expected app bundle at $APP_PATH" >&2
  exit 1
fi

echo "BUILD SUCCEEDED"
echo "App: $APP_PATH"
