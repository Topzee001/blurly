import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';

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
    this.isProcessingFinalizing = false,
    this.blurMode = BlurMode.background,
    this.isRefiningMask = false,
    this.showMaskOverlay = false,
    this.brushMode = MaskBrushMode.keep,
    this.brushSize = 0.035,
    this.edgeFeather = 4,
    this.maskExpansion = 0,
    this.maskEdits = const [],
    this.undoneMaskEdits = const [],
    this.pendingMaskPreviewStrokes = const [],
    this.appliedMaskEditCount = 0,
    this.hasUnappliedMaskChanges = false,
  });

  final BlurImage? selectedImage;
  final BlurImage? processedImage;
  final bool isProcessing;
  final double blurAmount;
  final bool showOriginal;
  final String? errorMessage;
  final String? successMessage;
  final double processingProgress;
  final bool isProcessingFinalizing;
  final BlurMode blurMode;
  final bool isRefiningMask;
  final bool showMaskOverlay;
  final MaskBrushMode brushMode;
  final double brushSize;
  final int edgeFeather;
  final int maskExpansion;
  final List<MaskStroke> maskEdits;
  final List<MaskStroke> undoneMaskEdits;
  final List<MaskStroke> pendingMaskPreviewStrokes;
  final int appliedMaskEditCount;
  final bool hasUnappliedMaskChanges;

  bool get hasImage => selectedImage != null;
  bool get canExport => processedImage != null && !isProcessing;
  bool get canUndoMaskEdit => maskEdits.isNotEmpty;
  bool get canRedoMaskEdit => undoneMaskEdits.isNotEmpty;

  BlurState copyWith({
    Object? selectedImage = _sentinel,
    Object? processedImage = _sentinel,
    bool? isProcessing,
    double? blurAmount,
    bool? showOriginal,
    Object? errorMessage = _sentinel,
    Object? successMessage = _sentinel,
    double? processingProgress,
    bool? isProcessingFinalizing,
    BlurMode? blurMode,
    bool? isRefiningMask,
    bool? showMaskOverlay,
    MaskBrushMode? brushMode,
    double? brushSize,
    int? edgeFeather,
    int? maskExpansion,
    List<MaskStroke>? maskEdits,
    List<MaskStroke>? undoneMaskEdits,
    List<MaskStroke>? pendingMaskPreviewStrokes,
    int? appliedMaskEditCount,
    bool? hasUnappliedMaskChanges,
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
      isProcessingFinalizing:
          isProcessingFinalizing ?? this.isProcessingFinalizing,
      blurMode: blurMode ?? this.blurMode,
      isRefiningMask: isRefiningMask ?? this.isRefiningMask,
      showMaskOverlay: showMaskOverlay ?? this.showMaskOverlay,
      brushMode: brushMode ?? this.brushMode,
      brushSize: brushSize ?? this.brushSize,
      edgeFeather: edgeFeather ?? this.edgeFeather,
      maskExpansion: maskExpansion ?? this.maskExpansion,
      maskEdits: maskEdits ?? this.maskEdits,
      undoneMaskEdits: undoneMaskEdits ?? this.undoneMaskEdits,
      pendingMaskPreviewStrokes:
          pendingMaskPreviewStrokes ?? this.pendingMaskPreviewStrokes,
      appliedMaskEditCount: appliedMaskEditCount ?? this.appliedMaskEditCount,
      hasUnappliedMaskChanges:
          hasUnappliedMaskChanges ?? this.hasUnappliedMaskChanges,
    );
  }
}

const Object _sentinel = Object();
