import 'dart:io';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart'
    show ReceiveSharingIntent, SharedMediaFile, SharedMediaType;

class IncomingSharedDataSource {
  const IncomingSharedDataSource();

  Stream<BlurImage?> watchSharedImage() {
    return ReceiveSharingIntent.instance.getMediaStream().asyncMap(
      _firstImageFromFiles,
    );
  }

  Future<BlurImage?> getInitialSharedImage() async {
    final files = await ReceiveSharingIntent.instance.getInitialMedia();
    final image = await _firstImageFromFiles(files);
    return image;
  }

  Future<BlurImage?> _firstImageFromFiles(List<SharedMediaFile> files) async {
    for (final file in files) {
      final isImage =
          file.type == SharedMediaType.image ||
          (file.mimeType?.startsWith('/image') ?? false);

      if (!isImage) continue;

      final bytes = await File(file.path).readAsBytes();

      return BlurImage(
        bytes: bytes,
        name: p.basename(file.path),
        path: file.path,
      );
    }
    return null;
  }
}
