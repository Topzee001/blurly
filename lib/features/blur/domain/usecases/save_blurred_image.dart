import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';

class SaveBlurredImage {
  const SaveBlurredImage(this._repository);

  final BlurRepository _repository;

  Future<String> call(BlurImage image) => _repository.saveToGallery(image);
}
