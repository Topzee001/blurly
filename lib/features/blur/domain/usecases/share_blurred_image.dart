import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';

class ShareBlurredImage {
  const ShareBlurredImage(this._repository);

  final BlurRepository _repository;

  Future<void> call(BlurImage image) => _repository.shareImage(image);
}
