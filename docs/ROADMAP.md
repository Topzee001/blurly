# Roadmap

Blurly's main product goal is clear: keep the subject sharp and blur only the
background, even when the subject is not a person.

## Phase 1: Stabilize MVP

- Keep the app local-first.
- Keep image processing off the UI thread.
- Improve fallback mask behavior for object photos.
- Add clearer mode explanations in the UI.
- Add golden-output tests for synthetic fixtures.
- Verify Android and iOS builds on real devices.

## Phase 2: Better Subject Detection

- Evaluate a general object segmentation model.
- Evaluate saliency detection for common object photos.
- Add model metadata docs and benchmark results.
- Compare object, person, document, product, and cluttered-scene examples.
- Add confidence/coverage checks before choosing the mask path.

## Phase 3: User-Guided Refinement

- Add brush-to-keep and brush-to-blur tools.
- Add undo/redo for mask edits.
- Add mask preview overlay.
- Add edge feather and mask expansion controls.
- Save editable mask state with the selected image.

## Phase 4: Portrait Quality

- Improve hair and fine-edge handling.
- Add depth-estimation-based blur.
- Add distance-based blur falloff.
- Add stronger bokeh styles without destroying image brightness.
- Add before/after export comparisons.

## Phase 5: Production Readiness

- Add release signing docs.
- Add crash/error reporting policy.
- Add privacy review for any telemetry.
- Add device performance benchmarks.
- Add Play Store and App Store metadata drafts.
