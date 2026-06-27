import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';

class TakePhoto {
  const TakePhoto(this._repository);

  final BlurRepository _repository;

  Future<BlurImage?> call() => _repository.takePhoto();
}
