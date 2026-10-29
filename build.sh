#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

NAME="干掉刘海"
APP="/Applications/$NAME.app"
BUILD=".build"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

SOURCES=(
  src/main.swift
  src/Settings.swift
  src/Overlay.swift
  src/Theme.swift
  src/SettingsView.swift
  src/QuickPanel.swift
  src/StatusPanel.swift
  src/Corner.swift
  src/PanelWindow.swift
  src/SelfTest.swift
  src/DebugRender.swift
  src/Diagnostics.swift
)

for old in "/Applications/NotchBlack.app" "/Applications/刘海砍掉.app" "/Applications/干掉刘海不留疤.app"; do
  if [ -d "$old" ]; then
    rm -rf "$old"
    "$LSREGISTER" -u "$old" >/dev/null 2>&1 || true
  fi
done

rm -rf "$BUILD" "$APP"
mkdir -p "$BUILD" "$APP/Contents/MacOS" "$APP/Contents/Resources"

if [ -f "Assets/AppIcon.icns" ]; then
  cp "Assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

echo "编译 arm64..."
swiftc -O -swift-version 5 -target arm64-apple-macos13.0 \
  -o "$BUILD/nb-arm64" "${SOURCES[@]}" -framework Cocoa

echo "编译 x86_64..."
swiftc -O -swift-version 5 -target x86_64-apple-macos13.0 \
  -o "$BUILD/nb-x86_64" "${SOURCES[@]}" -framework Cocoa

lipo -create -output "$APP/Contents/MacOS/NotchBlack" "$BUILD/nb-arm64" "$BUILD/nb-x86_64"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
"$LSREGISTER" -f "$APP" >/dev/null 2>&1 || true

echo "构建完成: $APP"
lipo -info "$APP/Contents/MacOS/NotchBlack"
