import 'dart:typed_data';

class BlurImage {
  const BlurImage({
    required this.bytes,
    required this.name,
    this.path,
    this.maskOverlayBytes,
  });

  final Uint8List bytes;
  final String name;
  final String? path;
  final Uint8List? maskOverlayBytes;

  int get sizeInBytes => bytes.lengthInBytes;

  BlurImage copyWith({
    Uint8List? bytes,
    String? name,
    String? path,
    Uint8List? maskOverlayBytes,
  }) {
    return BlurImage(
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      path: path ?? this.path,
      maskOverlayBytes: maskOverlayBytes ?? this.maskOverlayBytes,
    );
  }
}
