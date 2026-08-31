#!/bin/bash
# Captures the menu bar with Shifty's menu open, into the sizes the README and
# the docs site expect.
#
#   Scripts/screenshot-menu.sh            capture, using REGION below
#   Scripts/screenshot-menu.sh --measure  full screen grab, to find REGION
#
# Only needs Screen Recording permission for whatever runs it. Opening a menu
# is the one step that can't be scripted without Accessibility access, so the
# capture is on a timer: run it, then click the Shifty icon and hold the menu
# open until it fires.

set -euo pipefail

cd "$(dirname "$0")/.."

# x,y,w,h in points, origin top left of the main display. Find these once with
# --measure: the menu bar strip plus the open menu, ~20pt margin for its shadow.
REGION="900,0,707,453"
DELAY=8
OUT_DIR="docs/en/images"
LARGE_WIDTH=1413   # matches the sizes the site's responsive swap expects
SMALL_WIDTH=1061

if [ "${1:-}" = "--measure" ]; then
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
trap 'rm -rf "$TMP"' EXIT

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
