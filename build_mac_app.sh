#!/bin/zsh
set -e

APP_DIR="output/番茄钟.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
FRAME_DIR="$RES_DIR/tomato_frames"
SOURCE_SHEET="assets/tomato-run-sequence.png"

export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/private/tmp/pomodoro-clang-cache}"
export SWIFT_MODULE_CACHE_PATH="${SWIFT_MODULE_CACHE_PATH:-/private/tmp/pomodoro-swift-cache}"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

python3 scripts/prepare_tomato_sprite.py \
  "$SOURCE_SHEET" \
  "$FRAME_DIR" \
  "output/番茄钟-跑步动图.gif" \
  "output/番茄钟-logo.png" \
  "$RES_DIR/AppIcon.icns"

# Static tomato images for the timer view (red base + green variant).
cp "assets/tomato-static.png" "$RES_DIR/"
cp "assets/tomato-static-green.png" "$RES_DIR/"

swiftc src/PomodoroNative.swift \
  -framework AppKit \
  -framework UserNotifications \
  -o "$MACOS_DIR/番茄钟"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>番茄钟</string>
  <key>CFBundleDisplayName</key>
  <string>番茄钟</string>
  <key>CFBundleIdentifier</key>
  <string>local.codex.pomodoro</string>
  <key>CFBundleVersion</key>
  <string>1.1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.1</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>番茄钟</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "$APP_DIR"
