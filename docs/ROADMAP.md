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

## Available Now: User-Guided Refinement

- Keep sharp and Add blur brushes.
- Draft stroke previews, undo, and redo before applying changes.
- Optional mask preview overlay.
- Edge feather and subject expansion controls.
- Pinch to zoom and two-finger pan with a fit-to-screen reset control.
- Explicit Apply processing, so drawing remains responsive.

## Phase 3: Refinement Improvements

- Persist editable mask state with a selected image or saved project.
- Add edge-aware refinement for hair, transparent objects, and thin details.
- Add brush stroke smoothing for precise editing.
- Add golden-image tests for manual refinement output.

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
