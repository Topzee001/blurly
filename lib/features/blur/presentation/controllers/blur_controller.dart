import 'dart:async';
import 'dart:math' as math;

import 'package:blurly/core/utils/debouncer.dart';
import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:blurly/features/blur/domain/entities/processing_options.dart';
import 'package:blurly/features/blur/domain/usecases/pick_image.dart';
import 'package:blurly/features/blur/domain/usecases/process_blur_image.dart';
import 'package:blurly/features/blur/domain/usecases/save_blurred_image.dart';
import 'package:blurly/features/blur/domain/usecases/share_blurred_image.dart';
import 'package:blurly/features/blur/domain/usecases/take_photo.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_state.dart';
import 'package:flutter_riverpod/legacy.dart';

class BlurController extends StateNotifier<BlurState> {
  BlurController({
    required PickImage pickImage,
    required TakePhoto takePhoto,
    required ProcessBlurImage processBlurImage,
    required SaveBlurredImage saveBlurredImage,
    required ShareBlurredImage shareBlurredImage,
    Debouncer? sliderDebouncer,
  }) : _pickImage = pickImage,
       _takePhoto = takePhoto,
       _processBlurImage = processBlurImage,
       _saveBlurredImage = saveBlurredImage,
       _shareBlurredImage = shareBlurredImage,
       _sliderDebouncer =
           sliderDebouncer ?? Debouncer(const Duration(milliseconds: 320)),
       super(const BlurState());

  final PickImage _pickImage;
  final TakePhoto _takePhoto;
  final ProcessBlurImage _processBlurImage;
  final SaveBlurredImage _saveBlurredImage;
  final ShareBlurredImage _shareBlurredImage;
  final Debouncer _sliderDebouncer;
  Timer? _progressTimer;
  int _processingRun = 0;

  Future<void> pickImage() async {
    await _loadImage(() => _pickImage());
  }

  Future<void> takePhoto() async {
    await _loadImage(() => _takePhoto());
  }

  Future<void> _loadImage(Future<BlurImage?> Function() loader) async {
    _clearMessages();
    try {
      final image = await loader();
      if (image == null) {
        return;
      }
      state = state.copyWith(
        selectedImage: image,
        processedImage: null,
        showOriginal: false,
        errorMessage: null,
        successMessage: null,
      );
      await processSelectedImage();
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  void updateBlurAmount(double value) {
    state = state.copyWith(
      blurAmount: value.clamp(0, 40).toDouble(),
      errorMessage: null,
      successMessage: null,
    );
    if (state.selectedImage == null) {
      return;
    }
    _sliderDebouncer(processSelectedImage);
  }

  Future<void> setBlurMode(BlurMode mode) async {
    if (state.blurMode == mode) {
      return;
    }
    state = state.copyWith(blurMode: mode, successMessage: null);
    if (state.selectedImage != null) {
      await processSelectedImage();
    }
  }

  void toggleOriginal() {
    if (state.processedImage == null) {
      return;
    }
    state = state.copyWith(showOriginal: !state.showOriginal);
  }

  Future<void> processSelectedImage() async {
    final image = state.selectedImage;
    if (image == null) {
      return;
    }

    final run = ++_processingRun;
    _startProgress();
    state = state.copyWith(
      isProcessing: true,
      processingProgress: 0.08,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final processed = await _processBlurImage(
        image,
        ProcessingOptions(blurAmount: state.blurAmount, mode: state.blurMode),
      );
      if (run != _processingRun) {
        return;
      }
      _stopProgress();
      state = state.copyWith(
        processedImage: processed,
        isProcessing: false,
        showOriginal: false,
        processingProgress: 1,
      );
    } catch (error) {
      if (run != _processingRun) {
        return;
      }
      _stopProgress();
      state = state.copyWith(
        isProcessing: false,
        processingProgress: 0,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> saveImage() async {
    final image = state.processedImage;
    if (image == null) {
      state = state.copyWith(errorMessage: 'Process an image before saving.');
      return;
    }

    _clearMessages();
    try {
      await _saveBlurredImage(image);
      state = state.copyWith(successMessage: 'Saved to gallery.');
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  Future<void> shareImage() async {
    final image = state.processedImage;
    if (image == null) {
      state = state.copyWith(errorMessage: 'Process an image before sharing.');
      return;
    }

    _clearMessages();
    try {
      await _shareBlurredImage(image);
      state = state.copyWith(successMessage: 'Share sheet opened.');
    } catch (error) {
      state = state.copyWith(errorMessage: _friendlyError(error));
    }
  }

  void _startProgress() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted || !state.isProcessing) {
        return;
      }
      final next = math.min(0.92, state.processingProgress + 0.035);
      state = state.copyWith(processingProgress: next);
    });
  }

  void _stopProgress() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void _clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.trim().isEmpty) {
      return 'Something went wrong while processing the image.';
    }
    return message;
  }

  @override
  void dispose() {
    _sliderDebouncer.dispose();
    _stopProgress();
    super.dispose();
  }
}
