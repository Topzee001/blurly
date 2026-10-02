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

  test('holds mask edits until the user applies them', () async {
    final repository = FakeBlurRepository();
    final controller = buildController(repository);
    await controller.pickImage();

    controller.addMaskStroke(const [MaskPoint(0.2, 0.2), MaskPoint(0.4, 0.4)]);
    expect(controller.state.maskEdits, hasLength(1));
    expect(controller.state.hasUnappliedMaskChanges, isTrue);
    expect(controller.state.isProcessing, isFalse);
    expect(repository.processCount, 1);

    controller.undoMaskEdit();
    expect(controller.state.maskEdits, isEmpty);
    expect(controller.state.canRedoMaskEdit, isTrue);

    controller.redoMaskEdit();
    expect(controller.state.maskEdits, hasLength(1));

    await controller.applyMaskRefinement();
    expect(repository.processCount, 2);
    expect(repository.lastOptions?.maskEdits, hasLength(1));
    expect(repository.lastOptions?.maskEdits.single.mode, MaskBrushMode.keep);
    expect(controller.state.hasUnappliedMaskChanges, isFalse);
    expect(controller.state.canUndoMaskEdit, isFalse);
    expect(controller.state.canRedoMaskEdit, isFalse);
  });

  test('defers non-Apply processing while mask edits are pending', () async {
    final repository = FakeBlurRepository();
    final controller = buildController(repository);
    await controller.pickImage();

    controller.addMaskStroke(const [MaskPoint(0.2, 0.2)]);
    controller.updateBlurAmount(31);
    await Future<void>.delayed(Duration.zero);
    await controller.setBlurMode(BlurMode.bokeh);

    expect(repository.processCount, 1);
    expect(controller.state.pendingMaskPreviewStrokes, hasLength(1));
    expect(controller.state.appliedMaskEditCount, 0);
    expect(controller.state.hasUnappliedMaskChanges, isTrue);

    await controller.applyMaskRefinement();

    expect(repository.processCount, 2);
    expect(repository.lastOptions?.blurAmount, 31);
    expect(repository.lastOptions?.mode, BlurMode.bokeh);
    expect(controller.state.hasUnappliedMaskChanges, isFalse);
  });

  test(
    'keeps a completed stroke available for preview until it is applied',
    () async {
      final repository = FakeBlurRepository();
      final controller = buildController(repository);
      await controller.pickImage();

      final update = Completer<BlurImage>();
      repository.processCompleter = update;
      controller
        ..addMaskStroke(const [MaskPoint(0.3, 0.3)])
        ..addMaskStroke(const [MaskPoint(0.5, 0.5)]);

      expect(controller.state.isProcessing, isFalse);
      expect(controller.state.pendingMaskPreviewStrokes, hasLength(2));
      expect(
        controller.state.pendingMaskPreviewStrokes.last.mode,
        MaskBrushMode.keep,
      );

      controller.undoMaskEdit();
      expect(controller.state.pendingMaskPreviewStrokes, hasLength(1));
      controller.redoMaskEdit();
      expect(controller.state.pendingMaskPreviewStrokes, hasLength(2));

      final apply = controller.applyMaskRefinement();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isProcessing, isTrue);
      update.complete(sampleBlurImage('updated.png'));
      await apply;

      expect(controller.state.isProcessing, isFalse);
      expect(controller.state.processedImage?.name, 'updated.png');
      expect(controller.state.pendingMaskPreviewStrokes, isEmpty);
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
      final apply = controller.applyMaskRefinement();
      await Future<void>.delayed(Duration.zero);

      controller.discardMaskRefinement(
        maskEdits: const [],
        edgeFeather: 4,
        maskExpansion: 0,
      );

      staleUpdate.complete(sampleBlurImage('discarded-edit.png'));
      await apply;
      expect(controller.state.processedImage?.name, 'processed_18.png');
      expect(controller.state.maskEdits, isEmpty);
    },
  );
}
