#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
  cat >&2 <<'USAGE'
Usage:
  ./scripts/convert-app-preview-video.sh <input-video> <output-video> [portrait|landscape] [fps]

Examples:
  ./scripts/convert-app-preview-video.sh \
    screenshots/CreativeAssets/ScanTipAppStorePromo.mp4 \
    screenshots/app-store/iphone-6.9/ScanTipProductVideo-app-preview-iphone-6.9.mp4 \
    portrait

  ./scripts/convert-app-preview-video.sh \
    docs/media/ScanTipProductVideo.mp4 \
    screenshots/app-store/iphone-6.9/ScanTipProductVideo-app-preview-iphone-6.9.mp4 \
    landscape
USAGE
  exit 2
fi

INPUT="$1"
OUTPUT="$2"
ORIENTATION="${3:-portrait}"
FPS="${4:-30}"

case "$ORIENTATION" in
  portrait)
    TARGET_WIDTH=886
    TARGET_HEIGHT=1920
    ;;
  landscape)
    TARGET_WIDTH=1920
    TARGET_HEIGHT=886
    ;;
  *)
    echo "Orientation must be 'portrait' or 'landscape'." >&2
    exit 2
    ;;
esac

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is required. Install with: brew install ffmpeg" >&2
  exit 1
}

mkdir -p "$(dirname "$OUTPUT")"

ffmpeg -y \
  -i "$INPUT" \
  -map 0:v:0 \
  -map 0:a? \
  -vf "scale=${TARGET_WIDTH}:${TARGET_HEIGHT}:force_original_aspect_ratio=increase,crop=${TARGET_WIDTH}:${TARGET_HEIGHT},setsar=1,fps=${FPS},format=yuv420p" \
  -c:v libx264 \
  -profile:v high \
  -level 4.0 \
  -pix_fmt yuv420p \
  -movflags +faststart \
  -c:a aac \
  -b:a 128k \
  -ac 2 \
  "$OUTPUT"

if command -v ffprobe >/dev/null; then
  ffprobe -v error \
    -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate,duration \
    -of default=noprint_wrappers=1 \
    "$OUTPUT"
fi
