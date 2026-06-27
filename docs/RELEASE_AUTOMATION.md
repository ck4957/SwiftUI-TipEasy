# Release Automation

This project can archive, export, validate, and upload an App Store Connect build from the command line without committing any secrets.

## One-Time Setup

Use stable Xcode for App Store uploads:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

Keep App Store Connect API keys out of git. The repository ignores `*.p8`, `private_keys/`, `.env`, and build outputs.

Required local values:

- `ASC_API_KEY_ID`: App Store Connect API key ID.
- `ASC_API_ISSUER_ID`: App Store Connect issuer ID.
- `ASC_APPLE_ID`: Numeric Apple ID for the app record in App Store Connect.
- `ASC_API_KEY_PATH`: Path to the local `.p8` key. Optional if `AuthKey_<KEY_ID>.p8` or `ApiKey_<KEY_ID>.p8` is in the repo root.

## Upload

```bash
cp .env.example .env
```

Fill in `.env`, then run:

```bash
./scripts/release-upload.sh
```

The script:

1. Removes the previous local archive/export.
2. Archives with automatic signing and provisioning updates.
3. Exports an App Store Connect IPA.
4. Validates the IPA with `altool`.
5. Uploads the IPA, retrying transient upload failures.

## Build Numbers

App Store Connect requires every upload for the same version to use a higher build number. If upload fails with `previousBundleVersion`, increment `CURRENT_PROJECT_VERSION` in the Xcode project and rerun the script.

Use the helper instead of editing the project file by hand:

```bash
./scripts/bump-build-number.sh
```

To choose a specific next build number:

```bash
./scripts/bump-build-number.sh 5
```

To have the upload script increment the build number before archiving:

```bash
AUTO_INCREMENT_BUILD=1 ./scripts/release-upload.sh
```

The bundle identifier for this existing App Store listing must remain:

```text
com.chiragkular.SwiftUI-TipEasy
```

The app display name can still be `Scan Tip`.

## CI/CD Options

The safest hosted option is Xcode Cloud because Apple manages signing and App Store Connect authentication. Use it when you want no private key material in GitHub or local scripts.

This repo includes a manual GitHub Actions release workflow at `.github/workflows/release-ios-appstore.yml`. It runs on GitHub's `macos-26` runner, prints the host macOS, Xcode, and SDK metadata, archives the app, exports an App Store Connect IPA, validates it, uploads it, and prints the archive metadata including `BuildMachineOSBuild`.

When re-uploading the same marketing version after a local/beta-host upload, run the workflow with a `build_number` input greater than the last uploaded build number.

Required GitHub encrypted secrets:

- `ASC_API_KEY_ID`: App Store Connect API key ID.
- `ASC_API_ISSUER_ID`: App Store Connect issuer ID.
- `ASC_APPLE_ID`: Numeric Apple ID for the app record in App Store Connect.
- `ASC_API_KEY_P8`: Contents of the App Store Connect `.p8` private key.
- `APPLE_TEAM_ID`: Apple Developer Team ID. Optional if it remains `64FN52KV6J`.
- `APPLE_DISTRIBUTION_CERTIFICATE_P12_BASE64`: Base64-encoded Apple Distribution `.p12` signing certificate.
- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`: Password for the `.p12` certificate.
- `KEYCHAIN_PASSWORD`: Temporary CI keychain password.
- `APPSTORE_PROVISIONING_PROFILE_BASE64`: Optional base64-encoded App Store provisioning profile. The workflow can also request provisioning updates with the App Store Connect API key.

Never commit `.p8`, `.mobileprovision`, `.cer`, `.p12`, or passwords.

### Creating GitHub Secrets

In GitHub, open the repository and go to:

```text
Settings > Secrets and variables > Actions > New repository secret
```

Create these text secrets from App Store Connect:

- `ASC_API_KEY_ID`: The key ID from App Store Connect > Users and Access > Integrations > App Store Connect API.
- `ASC_API_ISSUER_ID`: The issuer ID shown on the same App Store Connect API page.
- `ASC_APPLE_ID`: The numeric Apple ID for the app record in App Store Connect.
- `ASC_API_KEY_P8`: The full contents of the downloaded `AuthKey_<KEY_ID>.p8` file.
- `APPLE_TEAM_ID`: The Apple Developer Team ID, currently `64FN52KV6J`.

Export an Apple Distribution certificate from Keychain Access as a `.p12` file, then encode it for GitHub:

```bash
base64 -i /path/to/AppleDistribution.p12 | pbcopy
```

Paste the clipboard value into:

- `APPLE_DISTRIBUTION_CERTIFICATE_P12_BASE64`

Also create:

- `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD`: The password used when exporting the `.p12`.
- `KEYCHAIN_PASSWORD`: Any strong temporary password used only by the GitHub Actions keychain.

If you have an App Store provisioning profile, encode it too:

```bash
base64 -i /path/to/profile.mobileprovision | pbcopy
```

Paste that value into:

- `APPSTORE_PROVISIONING_PROFILE_BASE64`

This provisioning profile secret is optional because the workflow also passes the App Store Connect API key to `xcodebuild -allowProvisioningUpdates`. If automatic provisioning fails in CI, add the profile secret and rerun the workflow.

## Release Doctor

Run the lightweight local gate before release commits:

```bash
./scripts/release-doctor.sh
```

By default it checks release docs and project version consistency. Include a local build check when Xcode is ready:

```bash
RUN_XCODEBUILD=1 ./scripts/release-doctor.sh
```
