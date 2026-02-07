#!/bin/bash
# Build script for ClaudeBar

set -e

APP_NAME="ClaudeBar"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."
swift build -c release

echo "Creating app bundle..."
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

RESOURCE_BUNDLE=".build/$TRIPLE/release/ClaudeBar_ClaudeBar.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -r "$RESOURCE_BUNDLE" "$APP_BUNDLE/"
fi

echo ""
echo "Build complete: $APP_BUNDLE"
echo ""
echo "Run:     open $APP_BUNDLE"
echo "Install: cp -r $APP_BUNDLE /Applications/"
