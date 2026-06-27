import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';

class PickImage {
  const PickImage(this._repository);

  final BlurRepository _repository;

  Future<BlurImage?> call() => _repository.pickImageFromGallery();
}
