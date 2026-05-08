#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/.DerivedData/Build/Products/Debug/今历.app"
OUTPUT_DIR="$ROOT_DIR/Releases"
OUTPUT_DMG="$OUTPUT_DIR/MenuBarCalendar.dmg"
RW_DMG="$OUTPUT_DIR/MenuBarCalendar-temp.dmg"
STAGING_DIR="/private/tmp/MenuBarCalendar-dmg-root"
BACKGROUND_DIR="$STAGING_DIR/.background"
BACKGROUND_PNG="$BACKGROUND_DIR/dmg-background.png"
VOLUME_NAME="今历"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found at $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$BACKGROUND_DIR"
mkdir -p "$OUTPUT_DIR"

cp -R "$APP_PATH" "$STAGING_DIR/今历.app"
ln -s /Applications "$STAGING_DIR/Applications"

swift "$ROOT_DIR/Tools/generate_dmg_background.swift" "$BACKGROUND_PNG"

rm -f "$RW_DMG" "$OUTPUT_DMG"
hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOLUME_NAME" -fs HFS+ -format UDRW "$RW_DMG" >/dev/null

DEVICE_INFO="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
DEVICE="$(echo "$DEVICE_INFO" | awk '/Apple_HFS/ {print $1}')"
MOUNT_POINT="/Volumes/$VOLUME_NAME"

cleanup() {
  if mount | grep -q "$MOUNT_POINT"; then
    hdiutil detach "$DEVICE" -quiet || true
  fi
  rm -f "$RW_DMG"
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

osascript <<EOF
tell application "Finder"
  tell disk "$VOLUME_NAME"
    open
    delay 1
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {160, 140, 880, 560}
    set opts to the icon view options of container window
    set arrangement of opts to not arranged
    set icon size of opts to 112
    set text size of opts to 14
    set background color of opts to {64507, 63222, 61166}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
EOF

hdiutil detach "$DEVICE" -quiet
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -o "$OUTPUT_DMG" >/dev/null
rm -f "$RW_DMG"
trap - EXIT
rm -rf "$STAGING_DIR"

echo "Created $OUTPUT_DMG"
