# Changelog

All notable changes to Blurly will be documented in this file.

## Unreleased

### Refinement and editing

- Added the Refine subject editor with Keep sharp and Add blur brushes.
- Added visible previews for all pending brush strokes before applying changes.
- Added undo and redo for draft brush edits.
- Added edge feathering, subject expansion, and optional mask overlay controls.
- Added pinch-to-zoom, two-finger pan, and fit-to-screen reset in Refine subject.
- Changed refinement processing to an explicit Apply action so strokes do not
  repeatedly start expensive image processing.
- Improved the processing overlay with a finalizing state for long operations.

### Experience and sharing

- Added direct image receiving from the system share sheet.
- Made the empty image preview open the gallery picker.
- Added light and dark themes and refreshed the app wordmark and action layout.
- Refreshed Play Store screenshots and store-listing documentation.

### Foundation

- Added Flutter/Riverpod app shell.
- Added gallery picker and camera capture flows.
- Added TFLite selfie segmentation model integration.
- Added isolate-backed image processing.
- Added background, person, and bokeh blur modes.
- Added mask feathering and fallback center-subject masking.
- Added save and share flows.
- Added unit, widget, and integration test scaffolding.
- Added open-source documentation and contribution process.
