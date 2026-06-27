import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

class ImagePickerDataSource {
  ImagePickerDataSource({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<BlurImage?> pickFromGallery() async {
    await _requestPhotosPermission();
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    return _toBlurImage(image);
  }

  Future<BlurImage?> takePhoto() async {
    await Permission.camera.request();
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.rear,
    );
    return _toBlurImage(image);
  }

  Future<BlurImage?> _toBlurImage(XFile? file) async {
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return BlurImage(
      bytes: Uint8List.fromList(bytes),
      path: file.path,
      name: p.basename(file.path.isEmpty ? file.name : file.path),
    );
  }

  Future<void> _requestPhotosPermission() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) {
      return;
    }
    await Permission.storage.request();
  }
}
