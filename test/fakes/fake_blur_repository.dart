import 'dart:async';
import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/processing_options.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';
import 'package:image/image.dart' as img;

class FakeBlurRepository implements BlurRepository {
  FakeBlurRepository({
    BlurImage? pickedImage,
    BlurImage? processedImage,
    this.processCompleter,
  }) : pickedImage = pickedImage ?? sampleBlurImage('picked.png'),
       processedImage = processedImage ?? sampleBlurImage('processed.png');

  final BlurImage pickedImage;
  final BlurImage processedImage;
  Completer<BlurImage>? processCompleter;
  int pickCount = 0;
  int cameraCount = 0;
  int processCount = 0;
  int saveCount = 0;
  int shareCount = 0;
  ProcessingOptions? lastOptions;

  @override
  Future<BlurImage?> pickImageFromGallery() async {
    pickCount++;
    return pickedImage;
  }

  @override
  Future<BlurImage?> takePhoto() async {
    cameraCount++;
    return pickedImage.copyWith(name: 'camera.png');
  }

  @override
  Future<BlurImage> processImage(
    BlurImage image,
    ProcessingOptions options,
  ) async {
    processCount++;
    lastOptions = options;
    final completer = processCompleter;
    if (completer != null) {
      return completer.future;
    }
    return processedImage.copyWith(
      name: 'processed_${options.blurAmount.round()}.png',
    );
  }

  @override
  Future<String> saveToGallery(BlurImage image) async {
    saveCount++;
    return '/tmp/${image.name}';
  }

  @override
  Future<void> shareImage(BlurImage image) async {
    shareCount++;
  }
}

BlurImage sampleBlurImage(String name) {
  return BlurImage(bytes: samplePngBytes(), name: name);
}

Uint8List samplePngBytes() {
  final image = img.Image(width: 24, height: 24);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgba(
        x,
        y,
        x.isEven ? 230 : 30,
        y.isEven ? 80 : 210,
        140,
        255,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
