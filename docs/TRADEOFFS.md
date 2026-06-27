# Tradeoffs

Blurly is intentionally small and local-first, but the current MVP makes several
technical tradeoffs that affect blur quality.

## Current Quality Gap

The main issue is subject segmentation. The app currently uses a selfie/person
segmentation model. That means it is good at finding people, but it does not
really understand arbitrary foreground objects such as laptops, bags, products,
chairs, documents, or furniture.

When the model cannot find a useful person mask, Blurly falls back to a centered
subject mask. This prevents the entire image from being blurred, but it is only
a heuristic. It can still:

- Blur parts of the foreground object.
- Protect parts of the background by mistake.
- Fail when the object is off-center.
- Fail when the object fills most of the frame.
- Fail around thin boundaries, reflections, screens, paper edges, and hair.

This is why a laptop photo can look better than a full-image blur, but still not
look like a true AI background blur.

## Why This Tradeoff Exists

The MVP optimized for:

- Small app size.
- Offline processing.
- No backend or paid inference service.
- A simple TFLite integration.
- Fast enough processing on mobile devices.
- A clean Flutter architecture that contributors can extend.

It did not yet solve:

- General object segmentation.
- Depth estimation.
- Multiple foreground subjects.
- Manual mask editing.
- Matting-level edge quality.

## Blur Modes

### Background

`Background` is the default mode. It uses the model output when the foreground
coverage looks usable. If the model returns an empty mask or marks nearly the
whole image as foreground, the app uses a soft centered subject mask.

Tradeoff: it works better for object photos than selfie segmentation alone, but
it is still a guess.

### Person

`Person` uses the selfie segmentation result directly. It is best for portraits
and photos where the main subject is a person.

Tradeoff: it is usually poor for non-person objects.

### Bokeh

`Bokeh` is not a separate AI model. It uses the same foreground protection as
background mode, then applies a warmer visual treatment to the blurred
background.

Tradeoff: it improves the style of the blur, not the intelligence of the mask.

## Recommended Improvements

The highest-impact improvements are:

1. Add a general object segmentation model.
2. Add a depth-estimation model and blur based on depth.
3. Add saliency detection for non-person subjects.
4. Add a manual brush tool for mask correction.
5. Add mask erosion/dilation controls before feathering.
6. Add a guided crop or subject bounding-box step.
7. Add real-device benchmark images and expected-output tests.

## Model Options To Explore

Potential future directions:

- MediaPipe image segmentation variants beyond selfie segmentation.
- DeepLab-style semantic segmentation models.
- MobileSAM-style object masks if mobile performance is acceptable.
- Lightweight depth models for portrait-style blur.
- Hybrid segmentation plus user-guided brush refinement.

Any model change should document:

- License compatibility.
- Model size.
- Input/output tensor shapes.
- Expected latency on mid-range Android and iOS devices.
- Memory usage on large images.
- Quality on people, products, documents, pets, and cluttered scenes.

## Performance Tradeoffs

Blurly currently downscales images larger than 3000 px to avoid freezing the UI
or exhausting memory. This keeps the app responsive, but it can reduce final
detail.

Gaussian blur is CPU-based through the `image` package. It is simple and
portable, but high blur radii are expensive. A future GPU or native pipeline may
be faster.

## Testing Tradeoffs

The current tests cover mask generation, fallback behavior, compositing,
controller transitions, widgets, and a fake full-flow integration path.

Missing coverage:

- Real TFLite inference in desktop test runners.
- Golden-image comparisons for segmentation quality.
- Real-device save/share tests.
- Android/iOS memory benchmarks.

## Contribution Priority

For open-source contributors, the best first issue area is mask quality:

- Add benchmark input photos under a documented test fixture policy.
- Add visual regression/golden tests for blur output.
- Improve fallback masks.
- Add manual subject refinement.
- Evaluate a better segmentation model.
