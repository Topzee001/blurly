import 'dart:async';

import 'package:blurly/core/utils/debouncer.dart';
import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/domain/usecases/pick_image.dart';
import 'package:blurly/features/blur/domain/usecases/process_blur_image.dart';
import 'package:blurly/features/blur/domain/usecases/save_blurred_image.dart';
import 'package:blurly/features/blur/domain/usecases/share_blurred_image.dart';
import 'package:blurly/features/blur/domain/usecases/take_photo.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_blur_repository.dart';

void main() {
  BlurController buildController(FakeBlurRepository repository) {
    return BlurController(
      pickImage: PickImage(repository),
      takePhoto: TakePhoto(repository),
      processBlurImage: ProcessBlurImage(repository),
      saveBlurredImage: SaveBlurredImage(repository),
      shareBlurredImage: ShareBlurredImage(repository),
      sliderDebouncer: Debouncer(Duration.zero),
    );
  }

  test('moves through image selection and processing states', () async {
    final completer = Completer<BlurImage>();
    final repository = FakeBlurRepository(processCompleter: completer);
    final controller = buildController(repository);

    final future = controller.pickImage();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state.selectedImage, isNotNull);
    expect(controller.state.isProcessing, isTrue);

    completer.complete(sampleBlurImage('done.png'));
    await future;

    expect(repository.pickCount, 1);
    expect(repository.processCount, 1);
    expect(controller.state.isProcessing, isFalse);
    expect(controller.state.processedImage?.name, 'done.png');
  });

  test(
    'debounces slider updates and reprocesses with new blur amount',
    () async {
      final repository = FakeBlurRepository();
      final controller = buildController(repository);

      await controller.pickImage();
      controller.updateBlurAmount(31);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.blurAmount, 31);
      expect(repository.lastOptions?.blurAmount, 31);
      expect(repository.processCount, greaterThanOrEqualTo(2));
    },
  );

  test('changes blur mode and exports processed image', () async {
    final repository = FakeBlurRepository();
    final controller = buildController(repository);

    await controller.pickImage();
    await controller.setBlurMode(BlurMode.bokeh);
    await controller.saveImage();
    await controller.shareImage();

    expect(repository.lastOptions?.mode, BlurMode.bokeh);
    expect(repository.saveCount, 1);
    expect(repository.shareCount, 1);
    expect(controller.state.successMessage, 'Share sheet opened.');
  });

  test('stores mask edits and supports undo and redo', () async {
    final repository = FakeBlurRepository();
    final controller = buildController(repository);
    await controller.pickImage();

    controller.addMaskStroke(const [MaskPoint(0.2, 0.2), MaskPoint(0.4, 0.4)]);
    expect(controller.state.maskEdits, hasLength(1));
    expect(repository.lastOptions?.maskEdits, hasLength(1));
    expect(repository.lastOptions?.maskEdits.single.mode, MaskBrushMode.keep);

    controller.undoMaskEdit();
    expect(controller.state.maskEdits, isEmpty);
    expect(controller.state.canRedoMaskEdit, isTrue);

    controller.redoMaskEdit();
    expect(controller.state.maskEdits, hasLength(1));
  });

  test(
    'keeps a completed stroke available for preview while updating',
    () async {
      final repository = FakeBlurRepository();
      final controller = buildController(repository);
      await controller.pickImage();

      final update = Completer<BlurImage>();
      repository.processCompleter = update;
      controller.addMaskStroke(const [MaskPoint(0.5, 0.5)]);

      expect(controller.state.isProcessing, isTrue);
      expect(controller.state.pendingMaskPreviewStroke, isNotNull);
      expect(
        controller.state.pendingMaskPreviewStroke?.mode,
        MaskBrushMode.keep,
      );

      update.complete(sampleBlurImage('updated.png'));
      await Future<void>.delayed(Duration.zero);

      expect(controller.state.isProcessing, isFalse);
      expect(controller.state.processedImage?.name, 'updated.png');
      expect(controller.state.pendingMaskPreviewStroke, isNull);
    },
  );

  test(
    'ignores an in-flight result after mask refinement is discarded',
    () async {
      final repository = FakeBlurRepository();
      final controller = buildController(repository);
      await controller.pickImage();

      final staleUpdate = Completer<BlurImage>();
      repository.processCompleter = staleUpdate;
      controller.addMaskStroke(const [MaskPoint(0.5, 0.5)]);

      final restoredUpdate = Completer<BlurImage>();
      repository.processCompleter = restoredUpdate;
      controller.discardMaskRefinement(
        maskEdits: const [],
        edgeFeather: 4,
        maskExpansion: 0,
      );

      staleUpdate.complete(sampleBlurImage('discarded-edit.png'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.processedImage?.name, 'processed_18.png');

      restoredUpdate.complete(sampleBlurImage('restored.png'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.processedImage?.name, 'restored.png');
      expect(controller.state.maskEdits, isEmpty);
    },
  );
}
