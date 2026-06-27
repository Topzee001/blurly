import 'package:flutter/services.dart';

class SelfieSegmentationModelLoader {
  SelfieSegmentationModelLoader({
    AssetBundle? bundle,
    this.assetPath = 'assets/models/selfie_segmenter.tflite',
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final String assetPath;
  Uint8List? _cachedModel;

  Future<Uint8List> loadModelBytes() async {
    final cached = _cachedModel;
    if (cached != null) {
      return cached;
    }
    final data = await _bundle.load(assetPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    _cachedModel = Uint8List.fromList(bytes);
    return _cachedModel!;
  }
}
