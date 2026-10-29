#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

NAME="干掉刘海"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
APP="/Applications/$NAME.app"
DIST="dist"
STAGE="$DIST/stage"
DMG="$DIST/FuckBangs-$VERSION.dmg"

if [ ! -d "$APP" ]; then
  echo "找不到 $APP，先跑 ./build.sh"
  exit 1
fi

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"

cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

hdiutil create -quiet -volname "$NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "打包完成: $DMG"
shasum -a 256 "$DMG" | awk '{print "SHA256: " $1}'
du -h "$DMG" | awk '{print "体积: " $1}'
