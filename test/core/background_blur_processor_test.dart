import 'dart:typed_data';

import 'package:blurly/core/isolate/background_blur_processor.dart';
import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('MaskUtils', () {
    test('generates a binary mask from probabilities', () {
      final mask = MaskUtils.binaryMaskFromProbabilities(
        probabilities: [0.1, 0.52, 0.9],
        threshold: 0.52,
      );

      expect(mask, Uint8List.fromList([0, 255, 255]));
    });

    test('feathers mask edges during mask image generation', () {
      final mask = MaskUtils.maskImageFromProbabilities(
        probabilities: [0, 1, 1, 0],
        width: 2,
        height: 2,
        threshold: 0.5,
        featherRadius: 2,
        targetWidth: 16,
        targetHeight: 16,
      );

      final centerValue = mask.getPixel(8, 8).r;
      expect(centerValue, greaterThan(0));
      expect(centerValue, lessThan(255));
    });

    test('detects unusable empty and full foreground masks', () {
      expect(MaskUtils.coverage(Uint8List.fromList([0, 0, 255, 0])), 0.25);
      expect(MaskUtils.hasUsableForegroundCoverage(0), isFalse);
      expect(MaskUtils.hasUsableForegroundCoverage(0.45), isTrue);
      expect(MaskUtils.hasUsableForegroundCoverage(0.98), isFalse);
    });

    test('creates a center subject fallback mask', () {
      final mask = MaskUtils.centerSubjectMask(
        width: 40,
        height: 40,
        featherRadius: 2,
      );

      expect(mask.getPixel(20, 23).r, greaterThan(180));
      expect(mask.getPixel(0, 0).r, lessThan(40));
    });
  });

  group('BackgroundBlurProcessor', () {
    test('downscales images larger than the safety limit', () {
      final source = img.Image(width: 4000, height: 2000);

      final resized = BackgroundBlurProcessor.downscaleIfNeeded(
        source,
        maxDimension: 3000,
      );

      expect(resized.width, 3000);
      expect(resized.height, 1500);
    });

    test('resizes image for model inference', () {
      final source = img.Image(width: 80, height: 40);

      final resized = BackgroundBlurProcessor.resizeForInference(
        source,
        width: 256,
        height: 256,
      );

      expect(resized.width, 256);
      expect(resized.height, 256);
    });

    test('composites foreground over blurred background', () {
      final source = img.Image(width: 9, height: 9);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          final value = (x + y).isEven ? 0 : 255;
          source.setPixelRgba(x, y, value, value, value, 255);
        }
      }
      final mask = img.Image(width: 9, height: 9);
      for (var y = 0; y < mask.height; y++) {
        for (var x = 0; x < mask.width; x++) {
          final value = x == 4 && y == 4 ? 255 : 0;
          mask.setPixelRgba(x, y, value, value, value, 255);
        }
      }

      final output = BackgroundBlurProcessor.compositeBackgroundBlur(
        source: source,
        foregroundMask: mask,
        blurAmount: 4,
      );

      expect(output.getPixel(4, 4).r, source.getPixel(4, 4).r);
      expect(output.getPixel(4, 3).r, isNot(source.getPixel(4, 3).r));
    });

    test('falls back to center subject mask when segmentation is empty', () {
      final mask = BackgroundBlurProcessor.foregroundMaskForMode(
        probabilities: List<double>.filled(16, 0),
        width: 4,
        height: 4,
        threshold: 0.5,
        featherRadius: 2,
        targetWidth: 40,
        targetHeight: 40,
        mode: BlurMode.background,
      );

      expect(mask.getPixel(20, 23).r, greaterThan(150));
      expect(mask.getPixel(0, 0).r, lessThan(50));
    });

    test('bokeh mode keeps image content visible', () {
      final source = img.Image(width: 9, height: 9);
      for (var y = 0; y < source.height; y++) {
        for (var x = 0; x < source.width; x++) {
          source.setPixelRgba(x, y, 80 + x * 10, 120 + y * 8, 180, 255);
        }
      }
      final backgroundOnlyMask = img.Image(width: 9, height: 9);
      backgroundOnlyMask.clear(img.ColorRgb8(0, 0, 0));

      final output = BackgroundBlurProcessor.compositeBackgroundBlur(
        source: source,
        foregroundMask: backgroundOnlyMask,
        blurAmount: 18,
        mode: BlurMode.bokeh,
      );

      final center = output.getPixel(4, 4);
      expect(center.r + center.g + center.b, greaterThan(80));
    });
  });
}
