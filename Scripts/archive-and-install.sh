#!/bin/bash
# Archives a Release build and installs it to /Applications.
#
#   Scripts/archive-and-install.sh
#
# Archives land in build/archives, which is gitignored, so old builds stay
# around to roll back to.

set -euo pipefail

cd "$(dirname "$0")/.."

ARCHIVE_DIR="build/archives"
ARCHIVE="$ARCHIVE_DIR/Shifty-$(date +%Y%m%d-%H%M%S).xcarchive"
INSTALLED="/Applications/Shifty.app"

mkdir -p "$ARCHIVE_DIR"

xcodebuild \
    -workspace Shifty.xcworkspace \
    -scheme Shifty \
    -configuration Release \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    archive

APP="$ARCHIVE/Products/Applications/Shifty.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP/Contents/Info.plist")

# Keep the copy we're replacing the first time, in case it was someone else's
# signed release rather than one of ours.
if [ -d "$INSTALLED" ] && [ ! -d "$ARCHIVE_DIR/Shifty-replaced.app" ]; then
    cp -R "$INSTALLED" "$ARCHIVE_DIR/Shifty-replaced.app"
    echo "kept the previous $INSTALLED as $ARCHIVE_DIR/Shifty-replaced.app"
fi

pkill -f "Shifty.app/Contents/MacOS/Shifty" 2>/dev/null || true
sleep 1

rm -rf "$INSTALLED"
cp -R "$APP" "$INSTALLED"
codesign --verify --verbose=1 "$INSTALLED"

echo
echo "installed Shifty $VERSION ($BUILD) to $INSTALLED"
echo "archs: $(lipo -archs "$INSTALLED/Contents/MacOS/Shifty")"
echo "archive: $ARCHIVE"

open "$INSTALLED"
