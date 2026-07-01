# Release Checklist

Status: NEEDS_INPUT

## Build And Project

- [x] Bundle identifier documented: `com.chiragkular.SwiftUI-TipEasy`
- [x] Version documented: `1.2`
- [x] Build number documented: `8`
- [x] Target device families documented: iPhone and iPad
- [ ] Version bump confirmed for release
- [ ] Build number bump confirmed for release
- [ ] Signing verified
- [ ] Archive succeeds
- [ ] TestFlight build processing succeeds

## App Store Metadata

- [x] App name drafted
- [x] Subtitle drafted
- [x] Description drafted
- [x] Keywords drafted
- [x] What's New drafted
- [ ] Primary category confirmed
- [ ] Secondary category confirmed
- [ ] Pricing and availability confirmed
- [ ] Release mode confirmed
- [ ] Content rights confirmed
- [ ] Age rating answers confirmed
- [x] Routing app coverage file marked not applicable

## Privacy And Compliance

- [ ] Privacy policy URL live
- [ ] Support URL live
- [ ] Marketing URL live, if used
- [ ] App Privacy questionnaire completed from confirmed data practices
- [ ] User Messaging Platform / consent behavior confirmed
- [ ] Camera permission rationale reviewed
- [x] User-facing local data deletion option implemented
- [ ] Apple Intelligence/on-device processing note reviewed

## Screenshots

- [x] Existing iPhone screenshots inventoried
- [x] Existing iPad screenshots inventoried
- [x] Final iPhone screenshot set captured at accepted App Store dimensions
- [x] Final iPad screenshot set captured at accepted App Store dimensions
- [ ] Screenshot captions/copy approved
- [ ] Ad banner screenshot treatment confirmed

## TestFlight

- [x] Beta notes drafted
- [ ] Internal tester group selected
- [ ] External tester group selected, if needed
- [ ] TestFlight smoke test complete
- [ ] Known issues reviewed

## App Review

- [x] Reviewer walkthrough drafted
- [x] Login instructions documented as not required
- [x] Camera permission explanation drafted
- [ ] Support contact confirmed
- [ ] Final review notes approved
- [ ] Submit-ready flag confirmed by human

## Blockers

- NEEDS_CONFIRMATION: privacy policy URL
- NEEDS_CONFIRMATION: support URL and support contact
- NEEDS_CONFIRMATION: final pricing, regions, categories, release mode, and age rating
- NEEDS_CONFIRMATION: final App Store screenshot set

## Branching And Tagging Strategy

Use `main` as the ongoing development branch and use GitHub tags as the permanent record of each App Store release. A release branch is useful while a version is being stabilized, but the tag is the source of truth for the exact code that shipped.

### Branch Roles

- `main`: Current development branch. After version 1.0 is shipped/tagged, new 1.1+ work can continue here.
- `release/X.Y-description`: Temporary stabilization branch for a specific release, for example `release/1.1-game-packs`. Use this when a release needs final QA, metadata, screenshot, StoreKit, or TestFlight polish while `main` keeps moving.
- `feature/short-description`: Optional experiment branch for trying ideas before deciding whether they belong in the next release.
- `hotfix/X.Y.Z-description`: Emergency fix branch cut from the shipped tag when the App Store version needs a focused patch.

### Recommended Flow

1. Finish and submit version 1.0 from the current known-good commit.
2. Create an annotated Git tag for the shipped build:

   ```sh
   git tag -a v1.0.0 -m "Count & Sprout 1.0.0"
   git push origin v1.0.0
   ```

3. Continue new work on `main` or short-lived `feature/*` branches.
4. When version 1.1 is feature-complete, cut a release branch:

   ```sh
   git switch main
   git pull
   git switch -c release/1.1-game-packs
   git push -u origin release/1.1-game-packs
   ```

5. On the release branch, make only release-focused changes: bug fixes, App Store metadata, screenshots, StoreKit configuration checks, localization fixes, and final version/build bumps.
6. Submit the release build from the release branch.
7. After App Store approval, tag the exact commit that was submitted or approved:

   ```sh
   git tag -a v1.1.0 -m "Count & Sprout 1.1.0"
   git push origin v1.1.0
   ```

8. Merge the release branch back into `main` so final release fixes and documentation are not lost:

   ```sh
   git switch main
   git pull
   git merge --no-ff release/1.1-game-packs
   git push
   ```

### When To Cut The Release Branch

Prefer cutting `release/X.Y-*` after the planned features are mostly complete. This keeps day-to-day development simple and avoids maintaining a long-lived release branch. Cut the branch earlier only when `main` needs to keep receiving unrelated experimental work while the release is still in QA.

For experiments, use `feature/*` branches from `main`. If the experiment works, merge it into `main`; if it does not, leave it unmerged or delete it. Do not tag experiments unless they are shipped builds.

### Patch Releases

If version 1.0 or 1.1 needs an urgent App Store fix after shipping, branch from the shipped tag:

```sh
git switch -c hotfix/1.0.1-fix-name v1.0.0
```

Apply only the patch, bump the patch version/build, test, submit, then tag the approved commit as `v1.0.1`. Merge or cherry-pick the fix back into `main` afterward.

### Tag Naming

- Use annotated tags named `vMAJOR.MINOR.PATCH`, for example `v1.0.0`, `v1.1.0`, or `v1.1.1`.
- Create the tag only for builds submitted to App Store Connect or approved for release.
- Keep build numbers in Xcode/App Store Connect, but keep Git tags tied to marketing versions.

## Release Tasks

- [ ] Version bumped
- [ ] Build number bumped
- [ ] Release branch created if stabilization is happening away from `main`
- [ ] Shipped version tag created or planned
- [ ] Signing verified
