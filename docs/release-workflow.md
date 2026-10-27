# Flutterbytes release workflow lab

Use Blurly to practice the talk **Release with Confidence: Engineering
AI-Assisted Flutter Releases with CodeRabbit & Codemagic**. Start with one green
build, then add signing and distribution. CodeRabbit review and executable
checks provide different evidence: a useful review does not make failing tests
pass, and passing tests only cover the scenarios we wrote.

## 1. Understand the stages and environments

```text
feature branch → PR: CodeRabbit + automated tests → reviewed commit
                                                   ↓
                                       signed release AAB
                                                   ↓
                                      staging: Play internal testing
                                                   ↓
                                      production: promote that AAB
```

| Deployment stage | Who uses it | Build and destination |
| --- | --- | --- |
| Development | You and contributors | `flutter run`, or the `android-debug` APK |
| Staging | Invited testers | Signed release AAB on Google Play's `internal` track |
| Production | App users | Promote the tested release to the `production` track in Play Console |

Blurly has no backend URLs or environment-specific accounts. These are release
stages for the same `com.topzee.blurly` application. Promoting the staging AAB
preserves the exact binary testers used. The development APK uses a debug
signing key and is not the release artifact; it may require uninstalling an
existing store installation before it can be installed.

Flutter **flavors** become useful when we need separate installed apps such as
`com.topzee.blurly.dev`, different API endpoints, or different configuration.
Adding them would also require separate Play app entries and Shorebird setup.
They are not required just to have internal testing and production tracks.

Three other uses of "environment" in CI mean something different:

- `environment.flutter` and `environment.java`: tools installed on the runner.
- `environment.vars`: ordinary script variables, such as `FLUTTER_VERSION`.
- `environment.groups`: saved Codemagic variable groups. `shorebird` holds an
  API key; `play_store` holds Google Play credentials. They are not deployment
  stages, and the checks/debug workflows do not import them.

## 2. Know what each test proves

| Kind | Example in this repo | What a failure tells us |
| --- | --- | --- |
| Unit | `test/core/background_blur_processor_test.dart` | Mask, resize or compositing logic changed |
| Unit | `test/features/blur/presentation/blur_controller_test.dart` | Cancellation, retry or controller state is wrong |
| Widget | `test/features/blur/presentation/blur_page_test.dart` | A button, slider, dialog or editor interaction regressed |
| Golden | `test/goldens/blur_page_golden_test.dart` | The light/dark editor pixels changed from the approved baseline |
| Device integration | `integration_test/blur_flow_test.dart` | The multi-step UI flow failed on a device with a fake repository |
| Native integration | `integration_test/image_pipeline_test.dart` | The real model asset, TFLite runtime, repository or isolate failed |

The native integration test supplies an image instead of opening the OS picker
and records the save instead of writing into a person's gallery. It runs the
real processing pipeline. Neither integration test proves that camera UI,
gallery permissions, sharing extensions or store installation work. Check
those on a physical device during internal testing, including denied
permissions and cancelled selection. A synthetic image also does not measure
portrait segmentation quality; inspect representative real photos separately.

### Fakes, stubs and mocks

- **Fake:** a small working alternative. `FakeBlurRepository` returns valid
  image bytes without invoking native plugins. Useful for many UI scenarios.
- **Stub:** supplies a chosen response. `_CancellablePickerStub` returns `null`
  for cancellation; `_FailingSaveStub` throws a known error to test recovery.
- **Mock:** verifies an interaction contract, such as "save this exact image
  once and never share it." Use one when the interaction is the behavior you
  need to protect. No mocking dependency is needed for our current tests.

The fake's call counters also act as **spies**: they record what was called.
A double's role depends on how a test uses it, not just its class name.
Replacing every layer would leave us testing only the doubles; this is why we
also run the real TFLite pipeline on a device.

## 3. Run the checks locally

Use Flutter **3.41.2**, matching `.fvmrc`, GitHub Actions and Codemagic. A newer
global Flutter installation does not automatically use `.fvmrc`. If you use
FVM, prefix the commands with `fvm`; otherwise select the pinned SDK directly.
The lockfile is resolved for that SDK too. `--enforce-lockfile` makes CI fail
instead of silently choosing a different set of dependencies.

```sh
flutter --version
flutter config --enable-swift-package-manager
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --coverage
flutter devices
flutter test integration_test -d <android-device-id>
```

`flutter test` runs files under `test/`; it does not run `integration_test/`.
`--coverage` writes `coverage/lcov.info`. Coverage identifies unexercised code;
we do not treat a percentage as proof of release readiness.

The first Android device run also downloads/builds native dependencies before
the tests execute. `android/gradle.properties` limits Gradle to a 2 GB heap,
Kotlin to 1 GB and Gradle to two workers, leaving memory for Flutter and an
emulator on smaller machines. A timeout while `assembleDebug` is running is a
build/setup failure, not evidence that a UI assertion failed.

Golden tests fix the viewport, pixel ratio, target platform, theme and text
scale. They load the committed Roboto test fonts and the pinned SDK's Material
icons so the baseline is readable and independent of installed system fonts.
Keep the Flutter version and macOS host consistent when regenerating:

```sh
flutter test test/goldens --update-goldens
flutter test test/goldens
```

Open the changed PNGs before committing them. If the change was unintended,
fix the UI. If intended, commit the reviewed PNGs with the UI change. CI only
compares; it never regenerates baselines. A failed comparison writes expected,
actual and difference PNGs under `test/goldens/failures/`.

## 4. Read codemagic.yaml as a recipe

| YAML key | Meaning here |
| --- | --- |
| `workflows` | Independently selectable jobs; one workflow does not automatically run the others |
| `instance_type` | Machine where commands run; Android builds can use macOS, Android emulators use Linux here |
| `environment` | SDK versions and variables available to the commands |
| `android_signing` | Reference to the keystore uploaded to Codemagic |
| `cache` | Reused dependency downloads; not a test result or release artifact |
| `scripts` | Commands run in order; any failed command stops the workflow |
| `test_report` | Machine-readable test output shown in the Codemagic UI |
| `artifacts` | Files kept for download, including coverage and golden differences |
| `publishing` | Upload the generated AAB to Google Play after scripts succeed |
| `triggering` | Repository events that start a workflow automatically |
| `inputs` | Values you choose when starting a build, such as the Play track |

`&flutter_env` defines a YAML anchor; `*flutter_env` reuses it. `<<:` merges a
shared mapping into a workflow. These are YAML features, not Flutter commands.
`set -euo pipefail` makes errors, missing shell variables and failed piped
commands stop the script. In particular, `tee` must not hide a failing test.

| Workflow ID | Purpose | Required account setup |
| --- | --- | --- |
| `flutter-checks` | Format, analyze, unit/widget/golden tests and coverage | Repo connection; webhook for PR triggers |
| `android-debug` | Same checks, then downloadable debug APK | Repo connection only |
| `android-integration` | Android UI and real TFLite tests; run fast checks separately on macOS | Codemagic Linux runner access; billing enabled |
| `android-signing-check` | Validate the store password, alias and private key password only | Upload keystore; no Shorebird/Play credentials |
| `android-shorebird-build-aab` | Checks, signing validation, signed Shorebird AAB | Upload keystore + `shorebird` group |
| `android-shorebird-publish` | Same release checks, then upload a Play draft | Also `play_store` group and Play API access |
| `android-shorebird-patch` | Checks, then patch an explicitly selected existing release | Upload keystore + `shorebird` group |

Only `flutter-checks` has a Codemagic automatic trigger. Release and patch
workflows are manual. GitHub Actions also runs checks and Android integration
on PRs and pushes to `main`. Make both GitHub checks required in branch
protection if you want them to block merging. Then start release workflows
from the reviewed commit that passed both checks. Codemagic's macOS release
jobs rerun the fast tests; they do not run the separate Android device job or
automatically enforce its GitHub status. Do not substitute a green fast-check
run for a green device run when selecting a release.

Android emulators cannot run inside Codemagic's Apple silicon macOS runners.
The separate Linux workflow covers that case. If Linux billing is unavailable,
use the GitHub Android job or run on a connected local Android device.
Golden comparisons stay in the macOS workflows, where their baselines were
generated; the Linux device workflow does not compare macOS-rendered PNGs.

## 5. Fix the signing failure you saw

Your build stopped in **Verify Android signing identity**, before compiling or
uploading an app. The JKS proprietary-format warning is advisory. JKS supports
two passwords: the keystore password opens the container; the private key
password unlocks the alias inside it. Successfully listing an alias does not
validate its private key password.

In Codemagic's **Code signing identities**, edit `blurly_upload_keystore`:

1. Confirm it is the original intended upload keystore.
2. Set **Keystore password** to that file's store password.
3. Set **Key alias** to the actual alias, normally `blurly` for this project's
   creation command.
4. Set **Key password** to that alias's private key password. If you pressed
   Enter to accept the default when creating the key, use the store password.
5. Run `android-signing-check` first. It validates the identity without creating
   a Shorebird release or uploading an app.

`tool/ci/check_android_signing.sh` checks both passwords. It keeps the original
keytool error visible on failure and uses a temporary PKCS12 destination whose
password is the store password. That avoids confusing JKS's two-password model
with PKCS12's single-password model. It does not migrate or modify your source
keystore. A credential value stored in Codemagic must be corrected there; a
repository change cannot recover an unknown password.

If your local `android/key.properties` can sign with the same keystore, use
those values as the reference when correcting Codemagic. Keep the values in
your local file and Codemagic, not in chat or git.

The Android Gradle check now rejects unsigned **release tasks** in CI, while
allowing debug builds and integration tests without release credentials.

## 6. Rehearse a release

1. Run the local checks. Read one unit test, one widget test, the two golden
   baselines and the real-pipeline integration test before the demo.
2. Include any release version bump in the PR. Work through CodeRabbit findings
   and wait for both GitHub checks on the exact commit you intend to release.
3. In Codemagic, select YAML configuration and the correct branch/commit. Run
   `flutter-checks`, then `android-debug`. Download and install the APK. An APK
   installs directly; an AAB is an input to Google Play distribution.
4. Correct the signing identity using the steps above. Add a current Shorebird
   API key as secure `SHOREBIRD_TOKEN` in group `shorebird`.
5. Confirm the PR's `version:` in `pubspec.yaml` is new, for example `1.0.0+8`
   only if build code 8 has not already been used. `1.0.0` is the visible
   version, `8` is the Android version code. The workflows preserve this value
   rather than silently inventing another number. Every new Play upload needs a
   higher code, and a Shorebird release version must be new too. If it needs
   changing, make that change in a PR and rerun checks before releasing.
6. Run `android-shorebird-build-aab`. This also registers a release with
   Shorebird; it is not merely a local file build. For the first Play upload,
   download the AAB and upload it manually to internal testing.
7. After the first upload, add the Google Play service account JSON as secure
   `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` in `play_store`, with access to this
   Play app. For subsequent releases run `android-shorebird-publish` with
   `play_track = internal`. The workflow uploads a **draft**; review and roll
   it out in Play Console before expecting testers to receive it.
8. Install via the internal opt-in link and check real picker, camera,
   processing, refinement, save/share and denied-permission behavior.
9. Promote that tested AAB to production in Play Console when ready. Selecting
   `play_track = production` instead builds a new binary and uploads a new
   draft; that option is not promotion of an existing internal artifact.

Shorebird is an optional code-update layer already configured in this project.
`shorebird release android` builds the initial release and registers its patch
baseline. Codemagic/Play still distribute the AAB. A later Dart-only fix can use
`android-shorebird-patch` against an exact installed release version. Native,
asset and engine changes need a new store release. A patch can reach installed
users, so treat it as a release action too. Play testing tracks and Shorebird
patch tracks are separate: the current patch workflow uses Shorebird's stable
track. If internal testers and production users have the same release version,
that patch can reach both groups. The Play internal track alone does not isolate
code-push updates.

## References

- [Flutter testing overview](https://docs.flutter.dev/testing/overview)
- [Codemagic YAML configuration](https://docs.codemagic.io/yaml-basic-configuration/yaml-getting-started/)
- [Codemagic Android signing](https://docs.codemagic.io/yaml-code-signing/signing-android/)
- [Codemagic device tests and runner limits](https://docs.codemagic.io/yaml-testing/testing/)
- [Codemagic Google Play publishing and first upload](https://docs.codemagic.io/yaml-publishing/google-play/)
- [Shorebird Codemagic integration](https://docs.shorebird.dev/code-push/ci/codemagic/)
