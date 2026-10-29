import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/errors/media_permission_exception.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

// The function type creates a small test boundary around the OS plugin.
// Tests can return any PermissionStatus without invoking a MethodChannel.
typedef PermissionRequester = Future<PermissionStatus> Function();

class ImagePickerDataSource {
  ImagePickerDataSource({
    ImagePicker? imagePicker,
    PermissionRequester? requestPhotosPermission,
    PermissionRequester? requestCameraPermission,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       // Production defaults still call permission_handler normally.
       _requestPhotosPermission =
           requestPhotosPermission ?? (() => Permission.photos.request()),
       _requestCameraPermission =
           requestCameraPermission ?? (() => Permission.camera.request());

  final ImagePicker _imagePicker;
  final PermissionRequester _requestPhotosPermission;
  final PermissionRequester _requestCameraPermission;

  Future<BlurImage?> pickFromGallery() async {
    // Permission must be evaluated before the gallery picker is called.
    final status = await _requestPhotosPermission();
    _requirePermission(
      kind: MediaPermissionKind.photos,
      status: status,
      // iOS limited Photos access is sufficient for image selection.
      allowLimited: true,
    );

    // This line is now reachable only for granted or limited Photos access.
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    return _toBlurImage(image);
  }

  Future<BlurImage?> takePhoto() async {
    // Camera accepts only fully granted access.
    final status = await _requestCameraPermission();
    _requirePermission(kind: MediaPermissionKind.camera, status: status);

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
    required MediaPermissionKind kind,
    required PermissionStatus status,
    bool allowLimited = false,
  }) {
    // The early return defines the only allowed path to ImagePicker.
    if (status.isGranted || (allowLimited && status.isLimited)) {
      return;
    }

    // Convert plugin status into application-level recovery guidance.
    final recovery = status.isPermanentlyDenied
        ? MediaPermissionRecovery.openSettings
        : status.isRestricted
        ? MediaPermissionRecovery.restricted
        : MediaPermissionRecovery.retry;

    // Throwing here guarantees blocked access never falls through to a picker.
    throw MediaPermissionException(kind: kind, recovery: recovery);
  }
}
