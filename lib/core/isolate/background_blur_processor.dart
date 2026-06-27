import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class BlurProcessingRequest {
  const BlurProcessingRequest({
    required this.imageBytes,
    required this.modelBytes,
    required this.blurAmount,
    required this.mode,
    required this.edgeFeather,
  });

  final TransferableTypedData imageBytes;
  final TransferableTypedData modelBytes;
  final double blurAmount;
  final BlurMode mode;
  final int edgeFeather;
}

class ImageProcessingIsolate {
  const ImageProcessingIsolate();

  Future<Uint8List> process(BlurProcessingRequest request) {
    return Isolate.run(() => BackgroundBlurProcessor.process(request));
  }
}

class BackgroundBlurProcessor {
  const BackgroundBlurProcessor._();

  static const int maxImageDimension = 3000;
  static const double foregroundThreshold = 0.52;

  static Uint8List process(BlurProcessingRequest request) {
    final bytes = request.imageBytes.materialize().asUint8List();
    final modelBytes = request.modelBytes.materialize().asUint8List();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unsupported image format.');
    }

    final source = downscaleIfNeeded(
      img.bakeOrientation(decoded),
      maxDimension: maxImageDimension,
    );
    final probabilities = _runSelfieSegmentation(source, modelBytes);
    final mask = foregroundMaskForMode(
      probabilities: probabilities,
      width: _lastMaskWidth,
      height: _lastMaskHeight,
      threshold: foregroundThreshold,
      featherRadius: request.edgeFeather,
      targetWidth: source.width,
      targetHeight: source.height,
      mode: request.mode,
    );

    final composited = compositeBackgroundBlur(
      source: source,
      foregroundMask: mask,
      blurAmount: request.blurAmount,
      mode: request.mode,
    );

    return Uint8List.fromList(img.encodePng(composited, level: 6));
  }

  static int _lastMaskWidth = 256;
  static int _lastMaskHeight = 256;

  static img.Image downscaleIfNeeded(
    img.Image source, {
    int maxDimension = maxImageDimension,
  }) {
    final longestSide = math.max(source.width, source.height);
    if (longestSide <= maxDimension) {
      return source.clone();
    }

    final scale = maxDimension / longestSide;
    return img.copyResize(
      source,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      interpolation: img.Interpolation.average,
    );
  }

  static img.Image resizeForInference(
    img.Image source, {
    required int width,
    required int height,
  }) {
    return img.copyResize(
      source,
      width: width,
      height: height,
      interpolation: img.Interpolation.linear,
    );
  }

  static img.Image compositeBackgroundBlur({
    required img.Image source,
    required img.Image foregroundMask,
    required double blurAmount,
    BlurMode mode = BlurMode.background,
  }) {
    final radius = blurRadiusForImage(source, blurAmount);
    final blurred = radius == 0
        ? source.clone()
        : img.gaussianBlur(source.clone(), radius: radius);
    final background = mode == BlurMode.bokeh && radius > 0
        ? _applyBokehLook(blurred, radius)
        : blurred;

    final mask =
        foregroundMask.width == source.width &&
            foregroundMask.height == source.height
        ? foregroundMask
        : img.copyResize(
            foregroundMask,
            width: source.width,
            height: source.height,
            interpolation: img.Interpolation.linear,
          );

    final output = img.Image(width: source.width, height: source.height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final foreground = source.getPixel(x, y);
        final back = background.getPixel(x, y);
        final alpha = (mask.getPixel(x, y).r / 255).clamp(0, 1).toDouble();
        final inverse = 1 - alpha;

        output.setPixelRgba(
          x,
          y,
          foreground.r * alpha + back.r * inverse,
          foreground.g * alpha + back.g * inverse,
          foreground.b * alpha + back.b * inverse,
          foreground.a,
        );
      }
    }
    return output;
  }

  static int blurRadiusForImage(img.Image source, double blurAmount) {
    final requested = blurAmount.round().clamp(0, 40).toInt();
    final shortestSide = math.min(source.width, source.height);
    final maxSafeRadius = math.max(0, ((shortestSide - 1) / 2).floor());
    return math.min(requested, maxSafeRadius);
  }

  static img.Image _applyBokehLook(img.Image blurred, int radius) {
    final amount = (radius / 40).clamp(0, 1).toDouble();
    final output = img.Image(width: blurred.width, height: blurred.height);
    final saturation = 1 + amount * 0.16;
    final lift = 10 * amount;

    for (var y = 0; y < blurred.height; y++) {
      for (var x = 0; x < blurred.width; x++) {
        final pixel = blurred.getPixel(x, y);
        final gray = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
        output.setPixelRgba(
          x,
          y,
          _clampChannel(gray + (pixel.r - gray) * saturation + lift + 3),
          _clampChannel(gray + (pixel.g - gray) * saturation + lift),
          _clampChannel(gray + (pixel.b - gray) * saturation + lift - 4),
          pixel.a,
        );
      }
    }

    return output;
  }

  static int _clampChannel(num value) {
    return value.round().clamp(0, 255).toInt();
  }

  static img.Image foregroundMaskForMode({
    required List<double> probabilities,
    required int width,
    required int height,
    required double threshold,
    required int featherRadius,
    required int targetWidth,
    required int targetHeight,
    required BlurMode mode,
  }) {
    final binary = MaskUtils.binaryMaskFromProbabilities(
      probabilities: probabilities,
      threshold: threshold,
    );
    final coverage = MaskUtils.coverage(binary);

    if (!MaskUtils.hasUsableForegroundCoverage(coverage)) {
      return MaskUtils.centerSubjectMask(
        width: targetWidth,
        height: targetHeight,
        featherRadius: featherRadius,
        verticalCenter: mode == BlurMode.person ? 0.52 : 0.58,
      );
    }

    return MaskUtils.maskImageFromBinaryMask(
      binaryMask: binary,
      width: width,
      height: height,
      featherRadius: featherRadius,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  static List<double> _runSelfieSegmentation(
    img.Image source,
    Uint8List modelBytes,
  ) {
    final interpreter = Interpreter.fromBuffer(modelBytes);
    try {
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      final inputShape = inputTensor.shape;
      final inputHeight = inputShape.length > 2 ? inputShape[1] : 256;
      final inputWidth = inputShape.length > 2 ? inputShape[2] : 256;
      final channels = inputShape.isNotEmpty ? inputShape.last : 3;
      final inferenceImage = resizeForInference(
        source,
        width: inputWidth,
        height: inputHeight,
      );

      final input = _buildInputBuffer(
        inferenceImage,
        channels: channels,
        tensorType: inputTensor.type,
      );
      final outputShape = outputTensor.shape;
      final output = _emptyOutputBuffer(
        outputTensor.numElements(),
        outputTensor.type,
      );

      interpreter.run(input, output);

      final parsed = _parseSegmentationOutput(
        output: output,
        tensorType: outputTensor.type,
        shape: outputShape,
      );
      _lastMaskWidth = parsed.width;
      _lastMaskHeight = parsed.height;
      return parsed.foregroundProbabilities;
    } finally {
      interpreter.close();
    }
  }

  static Object _buildInputBuffer(
    img.Image image, {
    required int channels,
    required TensorType tensorType,
  }) {
    final pixelCount = image.width * image.height;
    if (tensorType == TensorType.uint8) {
      final input = Uint8List(pixelCount * channels);
      _fillUint8Input(input, image, channels);
      return input.buffer;
    }
    if (tensorType == TensorType.int8) {
      final input = Int8List(pixelCount * channels);
      _fillInt8Input(input, image, channels);
      return input.buffer;
    }

    final input = Float32List(pixelCount * channels);
    var i = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        input[i++] = pixel.r / 255;
        if (channels > 1) input[i++] = pixel.g / 255;
        if (channels > 2) input[i++] = pixel.b / 255;
        if (channels > 3) input[i++] = pixel.a / 255;
      }
    }
    return input.buffer;
  }

  static void _fillUint8Input(Uint8List input, img.Image image, int channels) {
    var i = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        input[i++] = pixel.r.round().clamp(0, 255).toInt();
        if (channels > 1) input[i++] = pixel.g.round().clamp(0, 255).toInt();
        if (channels > 2) input[i++] = pixel.b.round().clamp(0, 255).toInt();
        if (channels > 3) input[i++] = pixel.a.round().clamp(0, 255).toInt();
      }
    }
  }

  static void _fillInt8Input(Int8List input, img.Image image, int channels) {
    var i = 0;
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        input[i++] = (pixel.r.round() - 128).clamp(-128, 127).toInt();
        if (channels > 1) {
          input[i++] = (pixel.g.round() - 128).clamp(-128, 127).toInt();
        }
        if (channels > 2) {
          input[i++] = (pixel.b.round() - 128).clamp(-128, 127).toInt();
        }
        if (channels > 3) {
          input[i++] = (pixel.a.round() - 128).clamp(-128, 127).toInt();
        }
      }
    }
  }

  static Object _emptyOutputBuffer(int elements, TensorType tensorType) {
    return switch (tensorType) {
      TensorType.uint8 => Uint8List(elements).buffer,
      TensorType.int8 => Int8List(elements).buffer,
      TensorType.int32 => Int32List(elements).buffer,
      TensorType.int64 => Int64List(elements).buffer,
      _ => Float32List(elements).buffer,
    };
  }

  static _ParsedSegmentationOutput _parseSegmentationOutput({
    required Object output,
    required TensorType tensorType,
    required List<int> shape,
  }) {
    final values = _outputToDoubleList(output, tensorType);
    final layout = _OutputLayout.fromShape(shape);
    final probabilities = List<double>.filled(layout.width * layout.height, 0);

    for (var y = 0; y < layout.height; y++) {
      for (var x = 0; x < layout.width; x++) {
        final outIndex = y * layout.width + x;
        if (layout.channels == 1) {
          probabilities[outIndex] = _normalizeScalar(
            values[layout.indexFor(x, y, 0)],
            tensorType,
          );
          continue;
        }

        final scores = List<double>.generate(
          layout.channels,
          (channel) => values[layout.indexFor(x, y, channel)],
        );
        probabilities[outIndex] = _foregroundFromScores(scores);
      }
    }

    return _ParsedSegmentationOutput(
      foregroundProbabilities: probabilities,
      width: layout.width,
      height: layout.height,
    );
  }

  static List<double> _outputToDoubleList(
    Object output,
    TensorType tensorType,
  ) {
    if (output is ByteBuffer) {
      return switch (tensorType) {
        TensorType.uint8 =>
          output.asUint8List().map((value) => value / 255).toList(),
        TensorType.int8 =>
          output.asInt8List().map((value) => (value + 128) / 255).toList(),
        TensorType.int32 =>
          output.asInt32List().map((value) => value.toDouble()).toList(),
        TensorType.int64 =>
          output.asInt64List().map((value) => value.toDouble()).toList(),
        _ => output.asFloat32List().toList(),
      };
    }
    if (output is Float32List) {
      return output.toList();
    }
    if (output is Uint8List) {
      return output.map((value) => value / 255).toList();
    }
    if (output is Int8List) {
      return output.map((value) => (value + 128) / 255).toList();
    }
    throw ArgumentError(
      'Unsupported TFLite output buffer: ${output.runtimeType}',
    );
  }

  static double _normalizeScalar(double value, TensorType tensorType) {
    if (tensorType == TensorType.uint8 || tensorType == TensorType.int8) {
      return value.clamp(0, 1).toDouble();
    }
    if (value >= 0 && value <= 1) {
      return value;
    }
    return 1 / (1 + math.exp(-value));
  }

  static double _foregroundFromScores(List<double> scores) {
    final hasLogits = scores.any((score) => score < 0 || score > 1);
    final sum = scores.fold<double>(0, (total, score) => total + score);
    if (!hasLogits && sum > 0.5 && sum < 1.5) {
      return (1 - scores.first).clamp(0, 1).toDouble();
    }

    final maxScore = scores.reduce(math.max);
    final exps = scores.map((score) => math.exp(score - maxScore)).toList();
    final expSum = exps.fold<double>(0, (total, score) => total + score);
    if (expSum == 0) {
      return 0;
    }
    final background = exps.first / expSum;
    return (1 - background).clamp(0, 1).toDouble();
  }
}

class MaskUtils {
  const MaskUtils._();

  static Uint8List binaryMaskFromProbabilities({
    required List<double> probabilities,
    required double threshold,
  }) {
    return Uint8List.fromList(
      probabilities.map((value) => value >= threshold ? 255 : 0).toList(),
    );
  }

  static img.Image maskImageFromProbabilities({
    required List<double> probabilities,
    required int width,
    required int height,
    required double threshold,
    required int featherRadius,
    required int targetWidth,
    required int targetHeight,
  }) {
    final binary = binaryMaskFromProbabilities(
      probabilities: probabilities,
      threshold: threshold,
    );
    return maskImageFromBinaryMask(
      binaryMask: binary,
      width: width,
      height: height,
      featherRadius: featherRadius,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
  }

  static img.Image maskImageFromBinaryMask({
    required Uint8List binaryMask,
    required int width,
    required int height,
    required int featherRadius,
    required int targetWidth,
    required int targetHeight,
  }) {
    final smallMask = img.Image(width: width, height: height);
    var i = 0;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final value = binaryMask[i++];
        smallMask.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    final fullMask = img.copyResize(
      smallMask,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    if (featherRadius <= 0) {
      return fullMask;
    }
    return img.gaussianBlur(
      fullMask,
      radius: featherRadius.clamp(1, 8).toInt(),
    );
  }

  static double coverage(Uint8List binaryMask) {
    if (binaryMask.isEmpty) {
      return 0;
    }
    var foregroundPixels = 0;
    for (final value in binaryMask) {
      if (value > 0) {
        foregroundPixels++;
      }
    }
    return foregroundPixels / binaryMask.length;
  }

  static bool hasUsableForegroundCoverage(double coverage) {
    return coverage >= 0.025 && coverage <= 0.9;
  }

  static img.Image centerSubjectMask({
    required int width,
    required int height,
    required int featherRadius,
    double verticalCenter = 0.58,
  }) {
    final mask = img.Image(width: width, height: height);
    final centerX = (width - 1) / 2;
    final centerY = (height - 1) * verticalCenter;
    final radiusX = width * 0.36;
    final radiusY = height * 0.34;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final dx = ((x - centerX).abs() / radiusX).clamp(0, 2).toDouble();
        final dy = ((y - centerY).abs() / radiusY).clamp(0, 2).toDouble();
        final distance = math.pow(dx, 4) + math.pow(dy, 4);
        final alpha = (1 - ((distance - 0.72) / 0.34)).clamp(0, 1).toDouble();
        final value = (alpha * 255).round();
        mask.setPixelRgba(x, y, value, value, value, 255);
      }
    }

    if (featherRadius <= 0) {
      return mask;
    }
    return img.gaussianBlur(mask, radius: featherRadius.clamp(1, 8).toInt());
  }
}

class _ParsedSegmentationOutput {
  const _ParsedSegmentationOutput({
    required this.foregroundProbabilities,
    required this.width,
    required this.height,
  });

  final List<double> foregroundProbabilities;
  final int width;
  final int height;
}

class _OutputLayout {
  const _OutputLayout({
    required this.width,
    required this.height,
    required this.channels,
    required this.isChannelsFirst,
  });

  final int width;
  final int height;
  final int channels;
  final bool isChannelsFirst;

  static _OutputLayout fromShape(List<int> shape) {
    if (shape.length == 4) {
      if (shape[1] <= 8 && shape[2] > 8 && shape[3] > 8) {
        return _OutputLayout(
          width: shape[3],
          height: shape[2],
          channels: shape[1],
          isChannelsFirst: true,
        );
      }
      return _OutputLayout(
        width: shape[2],
        height: shape[1],
        channels: shape[3],
        isChannelsFirst: false,
      );
    }
    if (shape.length == 3) {
      if (shape.last <= 8) {
        return _OutputLayout(
          width: shape[1],
          height: shape[0],
          channels: shape[2],
          isChannelsFirst: false,
        );
      }
      return _OutputLayout(
        width: shape[2],
        height: shape[1],
        channels: shape[0],
        isChannelsFirst: true,
      );
    }
    if (shape.length == 2) {
      return _OutputLayout(
        width: shape[1],
        height: shape[0],
        channels: 1,
        isChannelsFirst: false,
      );
    }
    throw ArgumentError('Unsupported TFLite output shape: $shape');
  }

  int indexFor(int x, int y, int channel) {
    if (channels == 1) {
      return y * width + x;
    }
    if (isChannelsFirst) {
      return channel * width * height + y * width + x;
    }
    return (y * width + x) * channels + channel;
  }
}
