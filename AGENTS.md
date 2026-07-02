# AGENTS.md - SwiftUI-TipEasy

## Project Role

You are working in an Apple-platform project. Prefer Apple-native patterns, Swift, SwiftUI, and first-party frameworks unless the task explicitly calls for something else.

## Implementation Style

- Inspect the existing project structure before making large edits.
- Preserve the current architecture unless there is a clear reason to change it.
- Keep changes focused, testable, and easy to review.
- Do not add credentials, API keys, secrets, or real private user data.
- Use sample or synthetic data for prototypes and tests.
- Build or test after meaningful changes when possible.

## Apple Platform Skill Routing

Use the relevant installed Codex skills for Apple-platform work:

- Use `swiftui-pro` or `swiftui-expert-skill` for SwiftUI layout, navigation, state, previews, animation, accessibility, and performance.
- Use `swift-concurrency` for async/await, actors, Sendable, task cancellation, MainActor, and data-race risks.
- Use `swift-testing-expert` for new tests, XCTest migration, async tests, test isolation, and tags/traits.
- Use `core-data-expert` for Core Data stacks, migrations, fetches, CloudKit sync, background contexts, and persistence tests.
- Use `xcode-build-orchestrator` for broad build diagnostics, project settings, slow builds, and optimization strategy.
- Use `xcode-project-analyzer` for project-file and build-setting audits.
- Use `xcode-compilation-analyzer` for compiler bottlenecks and type-checking issues.
- Use `spm-build-analysis` for Swift Package Manager dependency and pin analysis.
- Use `xcode-build-benchmark` when measuring build times before and after changes.
- Use `xcode-build-fixer` when applying targeted fixes for build failures or build-performance problems.

## Release Automation Routing

Keep release work script-first and prompt-light:

- For App Store screenshots, prefer deterministic Xcode UI tests over AI-generated or manually navigated captures. Add launch arguments, synthetic fixtures, stable accessibility labels/identifiers, and scripts that write simulator screenshots to the App Store screenshot folders.
- Before release screenshot refreshes, run `./scripts/generate-screenshots.sh` when available; keep screenshots generated from the app UI, with synthetic data and no secrets.
- Use `ios-app-store-release` only when changing App Store/TestFlight docs, privacy notes, screenshot plans, review notes, or release checklists.
- Use `./scripts/bump-build-number.sh` before another upload for the same marketing version.
- Use `./scripts/release-doctor.sh` before release commits or App Store upload attempts.
- Use `./scripts/release-upload.sh` only from a trusted local machine with `.env` configured. Do not put App Store Connect keys or signing material in repo files.
- Prefer Xcode Cloud for hosted release uploads. Use GitHub Actions as a non-secret CI gate unless signing and App Store Connect credentials are intentionally configured as encrypted secrets.

Avoid adding new repo-local `AGENTS.md` files unless a subdirectory needs materially different rules. Avoid creating a project skill unless the workflow needs reusable scripts/assets beyond this repo.
