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

## Later: In-App Updates and Product Discovery

- Add a dismissible What's new view after an app update, with short demos of
  useful editing features and a way to reopen it from the app.
- Plan contextual feature discovery, feedback, and sharing prompts that do not
  interrupt image editing or require an account.
- Evaluate Google Play in-app updates, including flexible update downloads,
  user-controlled installation, and offline/error handling.
- Build on the existing Shorebird/Codemagic release and patch setup when
  designing the in-app update experience. Plan release/patch visibility and
  recovery behavior without duplicating the existing deployment workflows;
  keep store-release requirements distinct from eligible Dart patches.
- Keep these items planned for a later release; the current marketing work is
  focused on demonstrating the existing Android app and its refinement tools.
