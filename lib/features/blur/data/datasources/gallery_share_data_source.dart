import 'dart:io';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class GalleryShareDataSource {
  const GalleryShareDataSource();

  Future<String> saveToGallery(BlurImage image) async {
    await _requestSavePermission();
    final file = await _writeTempPng(image);
    final saved = await GallerySaver.saveImage(
      file.path,
      albumName: 'Blurly',
      toDcim: true,
    );
    if (saved != true) {
      throw Exception('The image could not be saved to the gallery.');
    }
    return file.path;
  }

  Future<void> shareImage(BlurImage image) async {
    final file = await _writeTempPng(image);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        subject: 'Blurly portrait blur',
        title: 'Share Blurly image',
      ),
    );
  }

  Future<File> _writeTempPng(BlurImage image) async {
    final directory = await getTemporaryDirectory();
    final safeName = image.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final fileName = safeName.toLowerCase().endsWith('.png')
        ? safeName
        : '${p.basenameWithoutExtension(safeName)}_blurly.png';
    final file = File(p.join(directory.path, fileName));
    return file.writeAsBytes(image.bytes, flush: true);
  }

  Future<void> _requestSavePermission() async {
    final photosAddOnly = await Permission.photosAddOnly.request();
    if (photosAddOnly.isGranted || photosAddOnly.isLimited) {
      return;
    }
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) {
      return;
    }
    await Permission.storage.request();
  }
}
