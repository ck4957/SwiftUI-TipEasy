#!/usr/bin/env bash
set -euo pipefail

PROJECT_FILE=${PROJECT_FILE:-"Scan Tip.xcodeproj/project.pbxproj"}
WORKSPACE=${WORKSPACE:-"Scan Tip.xcworkspace"}
SCHEME=${SCHEME:-"Scan Tip"}
DESTINATION=${DESTINATION:-"generic/platform=iOS Simulator"}
REQUIRED_DOCS=(
  "docs/APP_STORE_METADATA.md"
  "docs/APP_PRIVACY_MATRIX.md"
  "docs/SCREENSHOT_PLAN.md"
  "docs/TESTFLIGHT_NOTES.md"
  "docs/REVIEW_NOTES.md"
  "docs/RELEASE_CHECKLIST.md"
  "docs/RELEASE_AUTOMATION.md"
)

failures=0

check_file() {
  local path=$1
  if [[ ! -s "$path" ]]; then
    echo "missing: $path" >&2
    failures=$((failures + 1))
  fi
}

for path in "${REQUIRED_DOCS[@]}"; do
  check_file "$path"
done

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "missing: $PROJECT_FILE" >&2
  failures=$((failures + 1))
else
  marketing_versions=$(grep -E "MARKETING_VERSION = [^;]+;" "$PROJECT_FILE" | sed -E 's/.*= ([^;]+);/\1/' | sort -u)
  build_numbers=$(grep -E "CURRENT_PROJECT_VERSION = [0-9]+;" "$PROJECT_FILE" | sed -E 's/.*= ([0-9]+);/\1/' | sort -u)

  if [[ $(printf "%s\n" "$marketing_versions" | sed '/^$/d' | wc -l | tr -d ' ') != "1" ]]; then
    echo "MARKETING_VERSION values are inconsistent:" >&2
    printf "%s\n" "$marketing_versions" >&2
    failures=$((failures + 1))
  fi

  if [[ $(printf "%s\n" "$build_numbers" | sed '/^$/d' | wc -l | tr -d ' ') != "1" ]]; then
    echo "CURRENT_PROJECT_VERSION values are inconsistent:" >&2
    printf "%s\n" "$build_numbers" >&2
    failures=$((failures + 1))
  fi
fi

if [[ -n "${RUN_XCODEBUILD:-}" ]]; then
  xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "$DESTINATION" \
    CODE_SIGNING_ALLOWED=NO \
    build
else
  echo "Skipping xcodebuild. Set RUN_XCODEBUILD=1 to include a build check."
fi

if [[ "$failures" -gt 0 ]]; then
  echo "Release doctor found $failures issue(s)." >&2
  exit 1
fi

echo "Release doctor passed."
