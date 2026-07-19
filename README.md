# Blurly

[![Flutter CI](https://github.com/Topzee001/blurly/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/Topzee001/blurly/actions/workflows/flutter_ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Blurly is an open-source Flutter photo editor for blurring image backgrounds.
It uses TensorFlow Lite selfie segmentation, isolate-based image processing,
and a minimal Riverpod UI.

Repository: [github.com/Topzee001/blurly](https://github.com/Topzee001/blurly)

## Project Status

Blurly is an early MVP. The app can pick/capture photos, process them locally,
preview before/after results, save images, and share output PNGs. The current
segmentation quality is not yet production-grade.

Known limitation: the bundled model is a selfie/person segmentation model. It
does not truly understand arbitrary objects such as laptops, bags, chairs, or
products. For non-person photos, Blurly falls back to a centered subject mask,
which can still blur parts of the object or keep parts of the background sharp.
Improving this is the main open-source contribution area.

## Features

- Pick an image from the gallery.
- Take a photo with the camera.
- Process images locally with TensorFlow Lite.
- Run heavy image work in an isolate.
- Downscale very large images before processing.
- Adjust blur intensity from 0% to 100%.
- Toggle original/processed preview.
- Save processed PNGs to the gallery.
- Share processed PNGs.
- Light and dark theme support.
- Responsive phone/tablet layout.

## Blur Modes

Blurly currently has three modes:

- `Background`: Default mode. Uses the selfie mask when it is usable, then
  falls back to a centered object/subject mask when the model cannot find a
  person. This is best for quick object photos, but it is heuristic.
- `Person`: Uses the TensorFlow Lite selfie segmentation mask directly. This is
  best for portraits and people.
- `Bokeh`: Uses the same subject protection as background mode, then applies a
  warmer portrait-style treatment to the blurred background.

Bokeh is not a separate AI model. It is a visual style layered on top of the
background blur result.

## What Needs Work

The biggest current weakness is subject separation. The app may blur parts of
the subject or keep parts of the background unblurred when:

- The subject is not a person.
- The object is not centered.
- The object touches the edge of the frame.
- The background and subject have similar colors.
- The model returns an empty or overly broad mask.

See [docs/TRADEOFFS.md](docs/TRADEOFFS.md) for the technical tradeoffs and
recommended next steps.

## Requirements

This repository was built and tested with:

- Flutter `3.41.2`
- Dart `3.11.0`
- Android minSdk `23`
- iOS `13.0+`

The dependency set currently requires Flutter `>=3.38.1` because of
`share_plus 13.2.0`. If supporting Flutter 3.24 is important, the dependency
set should be downgraded and retested.

## Setup

```sh
flutter pub get
flutter run
```

The bundled model lives at:

```text
assets/models/selfie_segmenter.tflite
```

Android and iOS camera/photo permissions are already declared. iOS uses
`platform :ios, '13.0'` in `ios/Podfile`.

## Tests

```sh
flutter analyze
flutter test
flutter test integration_test
```

The integration test uses a fake repository so it validates the full UI flow
without opening native gallery/camera UI. On a fresh iOS setup, CocoaPods may
need to download TensorFlow Lite pods before the integration runner starts.

## Architecture

```text
lib/
├── core/
│   ├── isolate/
│   ├── theme/
│   └── utils/
├── features/
│   └── blur/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── app.dart
└── main.dart
```

Blurly uses a small Clean Architecture slice:

- `domain`: Entities, repository contract, and use cases.
- `data`: Image picking, model loading, gallery/share adapters, caching.
- `core/isolate`: Decode, resize, segmentation, mask handling, blur, compositing.
- `presentation`: Riverpod `BlurController`, page widgets, controls, preview UI.

## Image Pipeline

1. Decode selected bytes with the `image` package.
2. Bake EXIF orientation.
3. Downscale images with a side longer than 3000 px.
4. Resize a copy for TFLite inference.
5. Run the bundled selfie segmentation model.
6. Convert binary or multiclass output into a foreground mask.
7. Feather mask edges.
8. Fall back to a centered subject mask when the AI mask is unusable.
9. Blur the background with the `image` package.
10. Composite original foreground over blurred background.
11. Return final PNG bytes to the UI.

## Open Source

Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- [SECURITY.md](SECURITY.md)
- [docs/TRADEOFFS.md](docs/TRADEOFFS.md)
- [docs/ROADMAP.md](docs/ROADMAP.md)

Project links:

- Issues: [github.com/Topzee001/blurly/issues](https://github.com/Topzee001/blurly/issues)
- Pull requests: [github.com/Topzee001/blurly/pulls](https://github.com/Topzee001/blurly/pulls)

Good first contribution areas:

- Replace or supplement selfie segmentation with object/general segmentation.
- Add depth estimation or saliency detection for non-person images.
- Add manual mask brush refinement.
- Improve mask edge cleanup and hair/object boundary handling.
- Add real-device integration coverage for Android and iOS.

## Third-Party Notes

`gallery_saver` is vendored under `third_party/gallery_saver` with a minimal
Android namespace/JVM-target patch so it builds with the current Android Gradle
Plugin while preserving the requested package API.

`receive_sharing_intent` is vendored under
`third_party/receive_sharing_intent` with an Android Gradle patch so CI builds
do not request the unavailable `android-37` SDK target.

## License

Blurly is released under the MIT License. See [LICENSE](LICENSE).
