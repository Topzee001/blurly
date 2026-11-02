import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/errors/media_permission_exception.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

typedef PermissionRequester = Future<PermissionStatus> Function();

class ImagePickerDataSource {
  ImagePickerDataSource({
    ImagePicker? imagePicker,
    PermissionRequester? requestPhotosPermission,
    PermissionRequester? requestCameraPermission,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       _requestPhotosPermission =
           requestPhotosPermission ?? (() => Permission.photos.request()),
       _requestCameraPermission =
           requestCameraPermission ?? (() => Permission.camera.request());

  final PermissionRequester _requestPhotosPermission;
  final PermissionRequester _requestCameraPermission;
  final ImagePicker _imagePicker;

  Future<BlurImage?> pickFromGallery() async {
    final status = await _requestPhotosPermission();
    _requirePermission(
      status: status,
      kind: MediaPermissionKind.photos,
      allowLimited: true,
    );

    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    return _toBlurImage(image);
  }

  Future<BlurImage?> takePhoto() async {
    final status = await _requestCameraPermission();
    _requirePermission(
      status: status,
      kind: MediaPermissionKind.camera,
      allowLimited: false,
    );
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

  void _requirePermission({
    required PermissionStatus status,
    required MediaPermissionKind kind,
    bool allowLimited = false,
  }) {
    if (status.isGranted || (allowLimited && status.isLimited)) {
      return;
    }

    final recovery = status.isPermanentlyDenied
        ? MediaPermissionRecovery.openSettings
        : status.isRestricted
        ? MediaPermissionRecovery.restricted
        : MediaPermissionRecovery.retry;

    throw MediaPermissionException(kind: kind, recovery: recovery);
  }
}
