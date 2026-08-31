#!/bin/bash
# Captures the menu bar with Shifty's menu open, into the sizes the README and
# the docs site expect.
#
#   Scripts/screenshot-menu.sh            capture, using REGION below
#   Scripts/screenshot-menu.sh --measure  full screen grab, to find REGION
#
# Hides desktop icons for the duration, since they show through the translucent
# menu, and puts them back afterwards even if you interrupt it.
#
# Only needs Screen Recording permission for whatever runs it. Opening a menu
# is the one step that can't be scripted without Accessibility access, so the
# capture is on a timer: run it, then click the Shifty icon and hold the menu
# open until it fires.
#
# Not automated: the wallpaper behind the menu, and the other icons in the menu
# bar. Setting the wallpaper needs Automation permission, and menu bar items
# belong to the apps that own them. Both are one-time arrangements rather than
# per-screenshot steps.

set -euo pipefail

cd "$(dirname "$0")/.."

# x,y,w,h in points, origin top left of the main display.
#
# This display is 2056x1329 points at 2x, so 707x453 points captures as
# 1414x906 pixels, which is the 1413px wide image the site expects. x is flush
# against the right edge (2056 - 707 = 1349), since the status item sits in the
# right hand cluster and the menu drops from it, and 453pt covers the menu bar
# plus the whole menu.
#
# On another display, or after rearranging the menu bar, re-find it with
# --measure, halving the pixel figures if that display is Retina.
REGION="1349,0,707,453"
DELAY=8
OUT_DIR="docs/en/images"
LARGE_WIDTH=1413   # matches the sizes the site's responsive swap expects
SMALL_WIDTH=1061

# Restore to whatever it was, including absent, rather than assuming a default.
if DESKTOP_WAS=$(defaults read com.apple.finder CreateDesktop 2>/dev/null); then
    restore_desktop() { defaults write com.apple.finder CreateDesktop -bool "$DESKTOP_WAS"; killall Finder 2>/dev/null || true; }
else
    restore_desktop() { defaults delete com.apple.finder CreateDesktop 2>/dev/null || true; killall Finder 2>/dev/null || true; }
fi

hide_desktop() {
    defaults write com.apple.finder CreateDesktop -bool false
    killall Finder 2>/dev/null || true
    sleep 1
}

if [ "${1:-}" = "--measure" ]; then
    trap restore_desktop EXIT
    hide_desktop
    echo "Full screen in $DELAY seconds. Open the Shifty menu now."
    screencapture -T "$DELAY" -x /tmp/shifty-measure.png
    echo "saved /tmp/shifty-measure.png ($(sips -g pixelWidth -g pixelHeight /tmp/shifty-measure.png | tail -2 | tr -d ' \n'))"
    echo "Read the menu's bounds off it, halve them if this is a Retina display,"
    echo "and put them in REGION at the top of this script."
    open /tmp/shifty-measure.png
    exit 0
fi

mkdir -p "$OUT_DIR"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"; restore_desktop' EXIT

hide_desktop

echo "Capturing $REGION in $DELAY seconds. Click the Shifty icon and leave the menu open."
screencapture -T "$DELAY" -x -R "$REGION" "$TMP/shot.png"

read -r W H < <(sips -g pixelWidth -g pixelHeight "$TMP/shot.png" | awk '/pixel/ {printf "%s ", $2} END {print ""}')
echo "captured ${W}x${H}"

if [ "$W" -lt "$LARGE_WIDTH" ]; then
    echo "warning: ${W}px is narrower than the ${LARGE_WIDTH}px the site expects."
    echo "         Capture on a Retina display, or widen REGION."
fi

cp "$TMP/shot.png" "$OUT_DIR/shifty-screenshot-large.png"
sips --resampleWidth "$LARGE_WIDTH" "$OUT_DIR/shifty-screenshot-large.png" >/dev/null
cp "$TMP/shot.png" "$OUT_DIR/shifty-screenshot-small.png"
sips --resampleWidth "$SMALL_WIDTH" "$OUT_DIR/shifty-screenshot-small.png" >/dev/null

echo
for f in "$OUT_DIR/shifty-screenshot-large.png" "$OUT_DIR/shifty-screenshot-small.png"; do
    echo "$f  $(sips -g pixelWidth -g pixelHeight "$f" | tail -2 | tr -d ' \n')"
done
