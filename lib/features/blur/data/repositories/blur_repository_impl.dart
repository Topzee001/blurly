import 'dart:isolate';
import 'dart:typed_data';

import 'package:blurly/core/isolate/background_blur_processor.dart';
import 'package:blurly/features/blur/data/datasources/gallery_share_data_source.dart';
import 'package:blurly/features/blur/data/datasources/image_picker_data_source.dart';
import 'package:blurly/features/blur/data/services/selfie_segmentation_model_loader.dart';
import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/processing_options.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';
import 'package:path/path.dart' as p;

class BlurRepositoryImpl implements BlurRepository {
  BlurRepositoryImpl({
    required ImagePickerDataSource pickerDataSource,
    required GalleryShareDataSource galleryShareDataSource,
    required SelfieSegmentationModelLoader modelLoader,
    ImageProcessingIsolate imageProcessingIsolate =
        const ImageProcessingIsolate(),
  }) : _pickerDataSource = pickerDataSource,
       _galleryShareDataSource = galleryShareDataSource,
       _modelLoader = modelLoader,
       _imageProcessingIsolate = imageProcessingIsolate;

  final ImagePickerDataSource _pickerDataSource;
  final GalleryShareDataSource _galleryShareDataSource;
  final SelfieSegmentationModelLoader _modelLoader;
  final ImageProcessingIsolate _imageProcessingIsolate;
  final Map<String, BlurImage> _cache = {};

  @override
  Future<BlurImage?> pickImageFromGallery() =>
      _pickerDataSource.pickFromGallery();

  @override
  Future<BlurImage?> takePhoto() => _pickerDataSource.takePhoto();

  @override
  Future<BlurImage> processImage(
    BlurImage image,
    ProcessingOptions options,
  ) async {
    final cacheKey = _cacheKey(image.bytes, options);
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final modelBytes = await _modelLoader.loadModelBytes();
    final resultBytes = await _imageProcessingIsolate.process(
      BlurProcessingRequest(
        imageBytes: TransferableTypedData.fromList([image.bytes]),
        modelBytes: TransferableTypedData.fromList([modelBytes]),
        blurAmount: options.blurAmount,
        mode: options.mode,
        edgeFeather: options.edgeFeather,
      ),
    );

    final processed = BlurImage(
      bytes: Uint8List.fromList(resultBytes),
      name: _processedName(image.name, options),
    );
    _cache[cacheKey] = processed;
    if (_cache.length > 12) {
      _cache.remove(_cache.keys.first);
    }
    return processed;
  }

  @override
  Future<String> saveToGallery(BlurImage image) {
    return _galleryShareDataSource.saveToGallery(image);
  }

  @override
  Future<void> shareImage(BlurImage image) {
    return _galleryShareDataSource.shareImage(image);
  }

  String _processedName(String imageName, ProcessingOptions options) {
    final base = p.basenameWithoutExtension(imageName).isEmpty
        ? 'blurly'
        : p.basenameWithoutExtension(imageName);
    return '${base}_blur_${options.blurAmount.round()}_${options.mode.name}.png';
  }

  String _cacheKey(Uint8List bytes, ProcessingOptions options) {
    return '${_fnv1a(bytes)}:${options.blurAmount.round()}:'
        '${options.mode.name}:${options.edgeFeather}';
  }

  int _fnv1a(Uint8List bytes) {
    const prime = 16777619;
    var hash = 2166136261;
    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * prime) & 0xffffffff;
    }
    return hash;
  }
}
