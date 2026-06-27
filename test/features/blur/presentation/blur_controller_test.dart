import 'dart:async';

import 'package:blurly/core/utils/debouncer.dart';
import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
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
}
