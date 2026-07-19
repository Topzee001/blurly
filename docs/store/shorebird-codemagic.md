# Shorebird And Codemagic Deployment

Use this checklist for the first Android release and later Shorebird patches.

## One-Time Shorebird Setup

Shorebird is initialized for this app. Keep `shorebird.yaml` committed because
it contains the public app ID used by the updater.

```sh
shorebird doctor
```

The app must also keep `shorebird.yaml` listed under `flutter.assets` in
`pubspec.yaml`.

Shorebird needs internet access to check for and download patches. Photo
processing remains on-device; photos are not uploaded for app updates.

## One-Time Android Signing

Create and store a release upload keystore safely. Do not commit the keystore or
`android/key.properties`.

```sh
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias blurly
```

For local signed release builds, copy `android/key.properties.example` to
`android/key.properties` and fill in the real values.

## Codemagic Setup

Use the committed `codemagic.yaml`.

In the app Workflow Editor, switch to YAML configuration. Shorebird's Codemagic
integration needs `codemagic.yaml`; the visual Workflow Editor cannot fully
represent the Shorebird release command.

The workflow enables Flutter Swift Package Manager support before `flutter pub
get` because `receive_sharing_intent` requires it on CI, even for Android-only
release builds.

The workflow also patches the Android Gradle file in the fresh
`receive_sharing_intent` pub-cache copy. This keeps Codemagic aligned with the
local Android build fix: apply the Kotlin Android plugin and compile the plugin
against Android SDK 36.

In Codemagic, create these environment groups:

- `shorebird`
  - `SHOREBIRD_TOKEN`: create this in Shorebird Console under Account > API
    Keys.
- `play_store`
  - `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`: the Google Play service account JSON.

In Codemagic Team settings > codemagic.yaml settings > Code signing identities,
upload the Android keystore using this reference name:

```text
blurly_upload_keystore
```

Codemagic will expose the keystore as `CM_KEYSTORE_PATH`,
`CM_KEYSTORE_PASSWORD`, `CM_KEY_ALIAS`, and `CM_KEY_PASSWORD`.

References:

- Codemagic Google Play publishing:
  https://docs.codemagic.io/yaml-publishing/google-play/
- Codemagic Android signing:
  https://docs.codemagic.io/yaml-code-signing/signing-android/
- Codemagic build inputs:
  https://docs.codemagic.io/knowledge-codemagic/build-inputs/

## Play Console Setup

Create the Play Console app manually before trying automated publishing.

Use these values:

- App name: Blurly
- Package name after first upload: `com.topzee.blurly`
- App or game: App
- Free or paid: Free
- Category: Photography

Complete the manual setup sections in Play Console:

- Main store listing
- Privacy policy
- App access
- Ads
- Content rating
- Target audience and content
- Data safety
- Government apps
- Financial features, if shown
- Health apps, if shown
- Testing tester lists

The store listing copy, data safety notes, and asset paths live in
`docs/store/play-store-listing.md`.

## First Internal Testing Release

Google Play and Codemagic both expect the first app upload to be completed
manually in Play Console. Still use Codemagic to build the AAB so it is signed
with the upload keystore and registered as a Shorebird release.

1. Confirm `pubspec.yaml` has the version you want to publish.
2. Push the repo changes, including `shorebird.yaml` and `codemagic.yaml`.
3. Run `android-shorebird-build-aab` manually in Codemagic.
4. Download `app-release.aab` from the build artifacts.
5. In Play Console, go to Testing > Internal testing.
6. Create a new release and upload the Codemagic-built AAB.
7. Release name: `1.0.0+1`.
8. Release notes: `Initial internal test release for Blurly.`
9. Add your internal testers, copy the opt-in link, and roll out to internal
   testing.

Internal testing is for fast QA. It is not the 14-day production-access test.

## Closed Testing

For new personal developer accounts, Google requires a closed test before
production access. At the time of writing, the requirement is at least 12
testers opted in continuously for 14 days before applying for production access.

Reference:
https://support.google.com/googleplay/android-developer/answer/14151465?hl=en

Recommended flow:

1. In Play Console, go to Testing > Closed testing.
2. Use the default closed testing track, or create a custom closed testing
   track. The default API track is usually `alpha`.
3. Add your tester email list or Google Group.
4. If the internal build is good, promote the internal release to closed testing
   manually in Play Console.
5. If you need a new binary, bump `version:` in `pubspec.yaml`, then run
   `android-shorebird-publish` in Codemagic with `play_track = alpha`.
6. Keep at least 12 testers opted in for 14 consecutive days.
7. Ask testers to install and actually use the app. Collect feedback and fix
   issues.

For Dart-only fixes during testing, use `android-shorebird-patch` instead of a
new Play release. For native, dependency, asset, permission, or icon changes,
ship a new Play release with a higher version code.

## Production

After the closed testing requirement is satisfied:

1. In Play Console, apply for production access from the Dashboard.
2. Answer Google's questions about the closed test, tester feedback, app
   readiness, and changes made.
3. After access is granted, either promote the approved closed testing release
   to production manually, or bump the version and run `android-shorebird-publish`
   with `play_track = production`.
4. The Codemagic workflow uploads releases as drafts, so review the release in
   Play Console, add final release notes, and submit it yourself.

## Future Updates

For Dart-only fixes that do not change native Android/iOS files or app assets,
run the `android-shorebird-patch` workflow. Use:

```text
latest
```

for the `release_version` input unless you intentionally need to patch a
specific version such as `1.0.0+1`.

For native changes, dependency changes with native code, permission changes, app
icon changes, or asset changes, make a new store release instead of a Shorebird
patch.
