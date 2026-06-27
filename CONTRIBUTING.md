# Contributing

Thanks for considering a contribution to Blurly.

Blurly is an early open-source MVP. The most valuable contributions right now
are improvements to segmentation quality, mask refinement, mobile performance,
and real-device testing.

## Before You Start

Please read:

- [README.md](README.md)
- [docs/TRADEOFFS.md](docs/TRADEOFFS.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Development Setup

```sh
flutter pub get
flutter analyze
flutter test
```

Use the same architecture boundaries already in the project:

- Domain code should not depend on Flutter widgets or plugins.
- Data code should wrap platform plugins and model loading.
- Heavy image processing should stay in `lib/core/isolate`.
- UI changes should avoid rebuilding the whole page on slider updates.

## Good First Contributions

- Improve docs and examples.
- Add tests for mask edge cases.
- Add benchmark images and quality notes.
- Improve the centered fallback mask.
- Add better validation around TFLite output shapes.
- Improve UI copy for mode explanations.

## High-Impact Contributions

- Add a general object segmentation model.
- Add a depth-estimation model.
- Add manual brush/mask refinement.
- Add golden-image regression tests.
- Add Android/iOS performance benchmarks.
- Replace the vendored gallery saver dependency with a maintained alternative.

## Pull Request Checklist

Before opening a PR:

- Run `dart format lib test integration_test`.
- Run `flutter analyze`.
- Run `flutter test`.
- Update docs if behavior changed.
- Add or update tests for processing behavior.
- Include screenshots or before/after images for UI and image-quality changes.
- Explain any model, asset, or dependency license changes.

## Image Fixtures

Do not commit personal photos, private screenshots, or images without a clear
license. Prefer synthetic fixtures or public-domain/appropriately licensed
images with attribution.

If a fixture is useful but cannot be committed, document how maintainers can
reproduce the test locally.

## Model Contributions

Model changes must document:

- Source and license.
- File size.
- Expected input and output tensor shapes.
- Runtime cost on Android and iOS.
- Known failure cases.
- Why it improves over the current selfie segmentation model.

## Reporting Bugs

Use the bug report template and include:

- Device and OS version.
- Flutter version.
- Blur mode.
- Input image characteristics.
- Expected result.
- Actual result.
- Screenshots or sample images when safe to share.
