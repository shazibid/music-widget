#!/bin/bash
# Assembles MusicWidget.app from a release SwiftPM build.
#
# SwiftPM executables aren't app bundles, so this stitches one together by
# hand: build the binary, drop it (plus its resource bundle and Info.plist)
# into the standard macOS app layout, then ad-hoc sign it so Gatekeeper
# doesn't flag it as internally inconsistent.
#
# Ad-hoc signing does NOT satisfy Gatekeeper for a binary downloaded from
# the internet (that needs a paid Developer ID cert + notarization) — a
# fresh download of this .app will still need "right-click > Open" once.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="MusicWidget"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "Building release binary..."
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"

echo "Assembling $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Packaging/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

cp "Sources/MusicWidget/Resources/ipod-body.png" "$APP_BUNDLE/Contents/Resources/ipod-body.png"

echo "Ad-hoc signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done: $APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE"
