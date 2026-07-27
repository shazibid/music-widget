#!/bin/bash
# Assembles Miniplayer.app from a SwiftPM build.
#
# SwiftPM executables aren't app bundles, so this stitches one together by
# hand: build the binary, drop it (plus its resource bundle and Info.plist)
# into the standard macOS app layout, then ad-hoc sign it so Gatekeeper
# doesn't flag it as internally inconsistent.
#
# Ad-hoc signing does NOT satisfy Gatekeeper for a binary downloaded from
# the internet (that needs a paid Developer ID cert + notarization) — a
# fresh download of this .app will still need "right-click > Open" once.
#
# Pass --debug to build the debug configuration instead, as
# dist/Miniplayer-Debug.app. Used by Tests/MiniplayerUITests: the debug
# config is the only one that compiles in the #if DEBUG fake-player harness
# (see FakeMediaAppController.swift) that lets XCUITest drive the app
# without a live Spotify/Music session. The default (no flag) release build
# — the one people actually download and run — never includes that code.
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Miniplayer"
DIST_DIR="dist"
CONFIG="release"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

if [[ "${1:-}" == "--debug" ]]; then
    CONFIG="debug"
    APP_BUNDLE="$DIST_DIR/$APP_NAME-Debug.app"
fi

echo "Building $CONFIG binary..."
swift build -c "$CONFIG"
BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"

echo "Assembling $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Packaging/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

if [[ "$CONFIG" == "debug" ]]; then
    # Distinct bundle ID so LaunchServices can't confuse this test build
    # with (and route XCUITest's launch request to) an already-running
    # real install of the app under its normal com.shazibid.Miniplayer ID.
    plutil -replace CFBundleIdentifier -string "com.shazibid.Miniplayer.debug" "$APP_BUNDLE/Contents/Info.plist"
fi

cp "Sources/Miniplayer/Resources/ipod-body.png" "$APP_BUNDLE/Contents/Resources/ipod-body.png"

echo "Ad-hoc signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done: $APP_BUNDLE"
codesign --verify --verbose "$APP_BUNDLE"
