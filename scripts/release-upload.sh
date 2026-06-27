#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=${WORKSPACE:-"Scan Tip.xcworkspace"}
SCHEME=${SCHEME:-"Scan Tip"}
CONFIGURATION=${CONFIGURATION:-Release}
SDK=${SDK:-iphoneos}
DESTINATION=${DESTINATION:-"generic/platform=iOS"}
TEAM_ID=${TEAM_ID:-64FN52KV6J}
ARCHIVE_PATH=${ARCHIVE_PATH:-"$PWD/build/ScanTip.xcarchive"}
EXPORT_PATH=${EXPORT_PATH:-"$PWD/build/AppStoreExport"}
EXPORT_OPTIONS=${EXPORT_OPTIONS:-"$PWD/ExportOptions.plist"}
MAX_UPLOAD_ATTEMPTS=${MAX_UPLOAD_ATTEMPTS:-3}
AUTO_INCREMENT_BUILD=${AUTO_INCREMENT_BUILD:-0}
SIGNING_CERTIFICATE=${SIGNING_CERTIFICATE:-}

if [[ -f "$PWD/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$PWD/.env"
  set +a
fi

: "${ASC_API_KEY_ID:?Set ASC_API_KEY_ID to your App Store Connect API key ID.}"
: "${ASC_API_ISSUER_ID:?Set ASC_API_ISSUER_ID to your App Store Connect issuer ID.}"
: "${ASC_APPLE_ID:?Set ASC_APPLE_ID to the numeric App Store Connect Apple ID for the app.}"

if [[ -z "${ASC_API_KEY_PATH:-}" ]]; then
  if [[ -f "$PWD/AuthKey_${ASC_API_KEY_ID}.p8" ]]; then
    ASC_API_KEY_PATH="$PWD/AuthKey_${ASC_API_KEY_ID}.p8"
  elif [[ -f "$PWD/ApiKey_${ASC_API_KEY_ID}.p8" ]]; then
    ASC_API_KEY_PATH="$PWD/ApiKey_${ASC_API_KEY_ID}.p8"
  else
    echo "Set ASC_API_KEY_PATH or place AuthKey_${ASC_API_KEY_ID}.p8 in the project root." >&2
    exit 1
  fi
fi

if [[ ! -f "$ASC_API_KEY_PATH" ]]; then
  echo "API key file not found: $ASC_API_KEY_PATH" >&2
  exit 1
fi

authentication_args=(
  -authenticationKeyPath "$ASC_API_KEY_PATH"
  -authenticationKeyID "$ASC_API_KEY_ID"
  -authenticationKeyIssuerID "$ASC_API_ISSUER_ID"
)

signing_args=()
if [[ -n "$SIGNING_CERTIFICATE" ]]; then
  signing_args+=(CODE_SIGN_IDENTITY="$SIGNING_CERTIFICATE")
fi

echo "Using Xcode:"
xcodebuild -version
echo "Using SDKs:"
xcodebuild -showsdks

if [[ "$AUTO_INCREMENT_BUILD" == "1" ]]; then
  echo "Incrementing build number..."
  "$PWD/scripts/bump-build-number.sh"
fi

echo "Cleaning previous archive/export..."
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

echo "Archiving $SCHEME..."
archive_args=(
  -workspace "$WORKSPACE" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk "$SDK" \
  -destination "$DESTINATION" \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  -allowProvisioningUpdates \
  "${authentication_args[@]}"
)
if [[ "${#signing_args[@]}" -gt 0 ]]; then
  archive_args+=("${signing_args[@]}")
fi
archive_args+=(
  clean archive
)
xcodebuild "${archive_args[@]}"

echo "Exporting App Store Connect IPA..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_OPTIONS" \
  -allowProvisioningUpdates \
  "${authentication_args[@]}"

IPA_PATH=$(find "$EXPORT_PATH" -maxdepth 1 -name "*.ipa" -print -quit)
if [[ -z "$IPA_PATH" ]]; then
  echo "No IPA found in $EXPORT_PATH" >&2
  exit 1
fi

echo "Validating $IPA_PATH..."
xcrun altool --validate-app \
  -f "$IPA_PATH" \
  -t ios \
  --apple-id "$ASC_APPLE_ID" \
  --api-key "$ASC_API_KEY_ID" \
  --api-issuer "$ASC_API_ISSUER_ID" \
  --p8-file-path "$ASC_API_KEY_PATH"

attempt=1
while true; do
  echo "Uploading attempt $attempt of $MAX_UPLOAD_ATTEMPTS..."
  if xcrun altool --upload-app \
    -f "$IPA_PATH" \
    -t ios \
    --apple-id "$ASC_APPLE_ID" \
    --api-key "$ASC_API_KEY_ID" \
    --api-issuer "$ASC_API_ISSUER_ID" \
    --p8-file-path "$ASC_API_KEY_PATH"; then
    echo "Upload completed. Check App Store Connect for Processing/Ready status."
    exit 0
  fi

  if [[ "$attempt" -ge "$MAX_UPLOAD_ATTEMPTS" ]]; then
    echo "Upload failed after $MAX_UPLOAD_ATTEMPTS attempts." >&2
    exit 1
  fi

  sleep_seconds=$((attempt * 60))
  echo "Upload failed. Retrying in ${sleep_seconds}s..."
  sleep "$sleep_seconds"
  attempt=$((attempt + 1))
done
