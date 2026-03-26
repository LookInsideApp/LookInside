#!/bin/bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_ROOT="${1:-$ROOT/build/AppKitProbe/LookInsideAppKitProbe.app}"
BIN_DIR="$APP_ROOT/Contents/MacOS"
RES_DIR="$APP_ROOT/Contents/Resources"

mkdir -p "$BIN_DIR" "$RES_DIR"

cat >"$APP_ROOT/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LookInsideAppKitProbe</string>
    <key>CFBundleIdentifier</key>
    <string>local.lookinside.appkitprobe</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>LookInsideAppKitProbe</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

xcrun swiftc \
    -target arm64-apple-macos14.0 \
    -framework AppKit \
    "$ROOT/Scripts/AppKitProbe/main.swift" \
    -o "$BIN_DIR/LookInsideAppKitProbe"

chmod +x "$BIN_DIR/LookInsideAppKitProbe"
echo "$APP_ROOT"
