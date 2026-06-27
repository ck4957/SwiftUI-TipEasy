#!/usr/bin/env bash
set -euo pipefail

PROJECT_FILE=${PROJECT_FILE:-"Scan Tip.xcodeproj/project.pbxproj"}
REQUESTED_BUILD=${1:-}

if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Project file not found: $PROJECT_FILE" >&2
  exit 1
fi

current_builds=$(grep -E "CURRENT_PROJECT_VERSION = [0-9]+;" "$PROJECT_FILE" | sed -E 's/.*= ([0-9]+);/\1/' | sort -u)
build_count=$(printf "%s\n" "$current_builds" | sed '/^$/d' | wc -l | tr -d ' ')

if [[ "$build_count" != "1" ]]; then
  echo "Expected exactly one CURRENT_PROJECT_VERSION value, found:" >&2
  printf "%s\n" "$current_builds" >&2
  exit 1
fi

current_build=$(printf "%s\n" "$current_builds" | sed -n '1p')

if [[ -n "$REQUESTED_BUILD" ]]; then
  if ! [[ "$REQUESTED_BUILD" =~ ^[0-9]+$ ]]; then
    echo "Build number must be a positive integer." >&2
    exit 1
  fi
  next_build="$REQUESTED_BUILD"
else
  next_build=$((current_build + 1))
fi

if (( next_build <= current_build )); then
  echo "New build number ($next_build) must be greater than current build ($current_build)." >&2
  exit 1
fi

tmp_file=$(mktemp)
sed -E "s/CURRENT_PROJECT_VERSION = ${current_build};/CURRENT_PROJECT_VERSION = ${next_build};/g" "$PROJECT_FILE" > "$tmp_file"
mv "$tmp_file" "$PROJECT_FILE"

echo "Updated CURRENT_PROJECT_VERSION: ${current_build} -> ${next_build}"
