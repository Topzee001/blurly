import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/processing_options.dart';

abstract class BlurRepository {
  Future<BlurImage?> pickImageFromGallery();

  Future<BlurImage?> takePhoto();

  Future<BlurImage> processImage(BlurImage image, ProcessingOptions options);

  Future<String> saveToGallery(BlurImage image);

  Future<void> shareImage(BlurImage image);
}
