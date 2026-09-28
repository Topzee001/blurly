import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';

class ProcessingOptions {
  const ProcessingOptions({
    required this.blurAmount,
    this.mode = BlurMode.background,
    this.edgeFeather = 4,
    this.maskExpansion = 0,
    this.maskEdits = const [],
  });

  final double blurAmount;
  final BlurMode mode;
  final int edgeFeather;
  final int maskExpansion;
  final List<MaskStroke> maskEdits;

  ProcessingOptions copyWith({
    double? blurAmount,
    BlurMode? mode,
    int? edgeFeather,
    int? maskExpansion,
    List<MaskStroke>? maskEdits,
  }) {
    return ProcessingOptions(
      blurAmount: blurAmount ?? this.blurAmount,
      mode: mode ?? this.mode,
      edgeFeather: edgeFeather ?? this.edgeFeather,
      maskExpansion: maskExpansion ?? this.maskExpansion,
      maskEdits: maskEdits ?? this.maskEdits,
    );
  }
}
