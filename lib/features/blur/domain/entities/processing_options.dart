import 'package:blurly/features/blur/domain/entities/blur_mode.dart';

class ProcessingOptions {
  const ProcessingOptions({
    required this.blurAmount,
    this.mode = BlurMode.background,
    this.edgeFeather = 4,
  });

  final double blurAmount;
  final BlurMode mode;
  final int edgeFeather;

  ProcessingOptions copyWith({
    double? blurAmount,
    BlurMode? mode,
    int? edgeFeather,
  }) {
    return ProcessingOptions(
      blurAmount: blurAmount ?? this.blurAmount,
      mode: mode ?? this.mode,
      edgeFeather: edgeFeather ?? this.edgeFeather,
    );
  }
}
