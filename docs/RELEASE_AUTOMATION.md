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

This repo also includes a GitHub Actions CI gate at `.github/workflows/ci.yml`. It installs pods, runs `./scripts/release-doctor.sh`, and builds the app without signing. This is useful for pull requests and normal pushes because it requires no App Store Connect secrets.

For GitHub Actions release uploads, store the API key, issuer ID, numeric Apple ID, and certificate/profile material as GitHub encrypted secrets. Never commit `.p8`, `.mobileprovision`, `.cer`, `.p12`, or passwords.

## Release Doctor

Run the lightweight local gate before release commits:

```bash
./scripts/release-doctor.sh
```

By default it checks release docs and project version consistency. Include a local build check when Xcode is ready:

```bash
RUN_XCODEBUILD=1 ./scripts/release-doctor.sh
```
