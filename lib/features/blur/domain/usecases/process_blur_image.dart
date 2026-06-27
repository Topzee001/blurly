import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/processing_options.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';

class ProcessBlurImage {
  const ProcessBlurImage(this._repository);

  final BlurRepository _repository;

  Future<BlurImage> call(BlurImage image, ProcessingOptions options) {
    return _repository.processImage(image, options);
  }
}
