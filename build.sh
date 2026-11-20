#!/bin/zsh
# WakeUp.app 빌드 스크립트 (Xcode 불필요, Command Line Tools만 필요)
set -euo pipefail
cd "$(dirname "$0")"

APP="build.noindex/WakeUp.app"
TMP="build.noindex/.tmp"
rm -rf "$APP" "$TMP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$TMP"

# 앱 아이콘 생성 (tools/make_icon.swift -> AppIcon.icns)
swiftc -O tools/make_icon.swift -o "$TMP/make_icon"
"$TMP/make_icon" "$TMP/AppIcon.iconset"
iconutil -c icns "$TMP/AppIcon.iconset" -o "$APP/Contents/Resources/AppIcon.icns"

swiftc -O -parse-as-library -swift-version 5 \
  -target "$(uname -m)-apple-macos13.0" \
  Sources/*.swift \
  -o "$APP/Contents/MacOS/WakeUp"

cp Info.plist "$APP/Contents/Info.plist"
rm -rf "$TMP"
codesign --force --sign - "$APP"

echo "빌드 완료: $APP"
echo "실행: open $APP"
echo "응용프로그램 폴더에 설치: ./install.sh"
