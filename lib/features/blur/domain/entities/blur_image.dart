import 'dart:typed_data';

class BlurImage {
  const BlurImage({required this.bytes, required this.name, this.path});

  final Uint8List bytes;
  final String name;
  final String? path;

  int get sizeInBytes => bytes.lengthInBytes;

  BlurImage copyWith({Uint8List? bytes, String? name, String? path}) {
    return BlurImage(
      bytes: bytes ?? this.bytes,
      name: name ?? this.name,
      path: path ?? this.path,
    );
  }
}
