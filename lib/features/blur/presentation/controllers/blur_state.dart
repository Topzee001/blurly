import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/blur_mode.dart';

class BlurState {
  const BlurState({
    this.selectedImage,
    this.processedImage,
    this.isProcessing = false,
    this.blurAmount = 18,
    this.showOriginal = false,
    this.errorMessage,
    this.successMessage,
    this.processingProgress = 0,
    this.blurMode = BlurMode.background,
  });

  final BlurImage? selectedImage;
  final BlurImage? processedImage;
  final bool isProcessing;
  final double blurAmount;
  final bool showOriginal;
  final String? errorMessage;
  final String? successMessage;
  final double processingProgress;
  final BlurMode blurMode;

  bool get hasImage => selectedImage != null;
  bool get canExport => processedImage != null && !isProcessing;

  BlurState copyWith({
    Object? selectedImage = _sentinel,
    Object? processedImage = _sentinel,
    bool? isProcessing,
    double? blurAmount,
    bool? showOriginal,
    Object? errorMessage = _sentinel,
    Object? successMessage = _sentinel,
    double? processingProgress,
    BlurMode? blurMode,
  }) {
    return BlurState(
      selectedImage: identical(selectedImage, _sentinel)
          ? this.selectedImage
          : selectedImage as BlurImage?,
      processedImage: identical(processedImage, _sentinel)
          ? this.processedImage
          : processedImage as BlurImage?,
      isProcessing: isProcessing ?? this.isProcessing,
      blurAmount: blurAmount ?? this.blurAmount,
      showOriginal: showOriginal ?? this.showOriginal,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: identical(successMessage, _sentinel)
          ? this.successMessage
          : successMessage as String?,
      processingProgress: processingProgress ?? this.processingProgress,
      blurMode: blurMode ?? this.blurMode,
    );
  }
}

const Object _sentinel = Object();
