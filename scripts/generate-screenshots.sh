#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${WORKSPACE:-$ROOT_DIR/Scan Tip.xcworkspace}"
SCHEME="${SCHEME:-Scan Tip}"
RESULTS_DIR="${RESULTS_DIR:-$ROOT_DIR/build/screenshot-results}"
SCREENSHOT_ROOT="${SCREENSHOT_ROOT:-$ROOT_DIR/screenshots/app-store}"

IPHONE_DESTINATION="${IPHONE_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.5}"
IPAD_DESTINATION="${IPAD_DESTINATION:-platform=iOS Simulator,name=iPad Pro 13-inch (M5),OS=26.5}"

command -v jq >/dev/null || {
  echo "jq is required to read xcresult attachment manifests." >&2
  exit 1
}

run_for_device() {
  local device_prefix="$1"
  local destination="$2"
  local output_dir="$SCREENSHOT_ROOT/$device_prefix"
  local derived_data="$RESULTS_DIR/$device_prefix-derived"
  local attachment_dir="$RESULTS_DIR/$device_prefix-attachments"

  echo "==> Capturing $device_prefix screenshots"
  echo "    Destination: $destination"

  mkdir -p "$output_dir" "$RESULTS_DIR"
  find "$output_dir" -maxdepth 1 \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -delete
  rm -rf "$derived_data" "$attachment_dir"

  xcodebuild test \
    -quiet \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$destination" \
    -only-testing:"Scan TipUITests/AppStoreScreenshotUITests" \
    -enableCodeCoverage NO \
    -collect-test-diagnostics never \
    -derivedDataPath "$derived_data"

  local result_bundle
  result_bundle="$(find "$derived_data/Logs/Test" -maxdepth 1 -name '*.xcresult' -type d -print | sort | tail -n 1)"
  if [[ -z "$result_bundle" ]]; then
    echo "No xcresult bundle found in $derived_data/Logs/Test" >&2
    exit 1
  fi

  echo "==> Exporting $device_prefix screenshot attachments"
  xcrun xcresulttool export attachments \
    --path "$result_bundle" \
    --output-path "$attachment_dir"

  jq -r '.[] | .attachments[] | [.exportedFileName, .suggestedHumanReadableName] | @tsv' "$attachment_dir/manifest.json" |
    while IFS=$'\t' read -r exported_file suggested_name; do
      screenshot_name="${suggested_name%%_0_*}"
      cp "$attachment_dir/$exported_file" "$output_dir/$device_prefix-$screenshot_name.png"
    done

  echo "==> Wrote $device_prefix screenshots:"
  find "$output_dir" -name '*.png' -maxdepth 1 -print | sort
}

run_for_device "iphone-6.9" "$IPHONE_DESTINATION"
run_for_device "ipad-13" "$IPAD_DESTINATION"

echo "Screenshots written to $SCREENSHOT_ROOT/iphone-6.9 and $SCREENSHOT_ROOT/ipad-13"
