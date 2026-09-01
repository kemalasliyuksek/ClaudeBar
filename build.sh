#!/bin/bash
# Build script for ClaudeBar

set -e

APP_NAME="ClaudeBar"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    TRIPLE="arm64-apple-macosx"
else
    TRIPLE="x86_64-apple-macosx"
fi

# The SwiftPM resource bundle must live under Contents/Resources: anything else at the
# bundle root is "unsealed content" and codesign refuses to seal the app.
# Localization.swift looks there first and falls back to Bundle.module for `swift run`.
RESOURCE_BUNDLE=".build/$TRIPLE/release/ClaudeBar_ClaudeBar.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -r "$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
fi

# Ad-hoc signature: gives the bundle a stable identity so UNUserNotificationCenter
# and Keychain ACL prompts are attributed to ClaudeBar instead of an unsigned binary.
echo "Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE"
codesign --verify --deep --strict "$APP_BUNDLE"
echo "Signature verified."

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "Run:     open $APP_BUNDLE"
echo "Install: cp -r $APP_BUNDLE /Applications/"
