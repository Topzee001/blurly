import 'dart:typed_data';

import 'package:blurly/features/blur/data/datasources/image_picker_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.result);

  final XFile? result;
  ImageSource? requestedSource;
  int? requestedQuality;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    requestedSource = source;
    requestedQuality = imageQuality;
    return result;
  }
}

void main() {
  test('picks a photo without requesting broad library permission', () async {
    final picker = _FakeImagePicker(
      XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'photo.jpg'),
    );

    final image = await ImagePickerDataSource(
      imagePicker: picker,
    ).pickFromGallery();

    expect(picker.requestedSource, ImageSource.gallery);
    expect(picker.requestedQuality, 100);
    expect(image?.bytes, [1, 2, 3]);
  });

  test('canceling the system picker returns no image', () async {
    final picker = _FakeImagePicker(null);

    final image = await ImagePickerDataSource(
      imagePicker: picker,
    ).pickFromGallery();

    expect(picker.requestedSource, ImageSource.gallery);
    expect(image, isNull);
  });
}
