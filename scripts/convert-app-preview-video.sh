#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 5 ]]; then
  cat >&2 <<'USAGE'
Usage:
  ./scripts/convert-app-preview-video.sh <input-video> <output-video> [iphone|ipad] [portrait|landscape] [fps]

Backwards-compatible shorthand:
  ./scripts/convert-app-preview-video.sh <input-video> <output-video> [portrait|landscape] [fps]

Examples:
  ./scripts/convert-app-preview-video.sh \
    screenshots/CreativeAssets/ScanTipAppStorePromo.mp4 \
    screenshots/app-store/iphone-6.9/ScanTipProductVideo-app-preview-iphone-6.9.mp4 \
    iphone \
    portrait

  ./scripts/convert-app-preview-video.sh \
    docs/media/ScanTipProductVideo.mp4 \
    screenshots/app-store/ipad-13/ScanTipProductVideo-app-preview-ipad-13.mp4 \
    ipad \
    landscape
USAGE
  exit 2
fi

INPUT="$1"
OUTPUT="$2"
PROFILE="iphone"
ORIENTATION="portrait"
FPS="30"

if [[ $# -ge 3 ]]; then
  case "$3" in
    iphone|ipad)
      PROFILE="$3"
      ORIENTATION="${4:-portrait}"
      FPS="${5:-30}"
      ;;
    portrait|landscape)
      ORIENTATION="$3"
      FPS="${4:-30}"
      ;;
    *)
      echo "Third argument must be 'iphone', 'ipad', 'portrait', or 'landscape'." >&2
      exit 2
      ;;
  esac
fi

case "$PROFILE:$ORIENTATION" in
  iphone:portrait)
    TARGET_WIDTH=886
    TARGET_HEIGHT=1920
    ;;
  iphone:landscape)
    TARGET_WIDTH=1920
    TARGET_HEIGHT=886
    ;;
  ipad:portrait)
    TARGET_WIDTH=1200
    TARGET_HEIGHT=1600
    ;;
  ipad:landscape)
    TARGET_WIDTH=1600
    TARGET_HEIGHT=1200
    ;;
  *)
    echo "Profile/orientation must be iphone|ipad and portrait|landscape." >&2
    exit 2
    ;;
esac

command -v ffmpeg >/dev/null || {
  echo "ffmpeg is required. Install with: brew install ffmpeg" >&2
  exit 1
}

mkdir -p "$(dirname "$OUTPUT")"

INPUT_ABS="$(cd "$(dirname "$INPUT")" && pwd)/$(basename "$INPUT")"
OUTPUT_ABS="$(cd "$(dirname "$OUTPUT")" && pwd)/$(basename "$OUTPUT")"
if [[ "$INPUT_ABS" == "$OUTPUT_ABS" ]]; then
  echo "Input and output must be different paths. Write to build/... first, then replace the original after verifying." >&2
  exit 2
fi

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
