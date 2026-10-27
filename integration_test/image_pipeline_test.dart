import 'package:blurly/features/blur/data/datasources/gallery_share_data_source.dart';
import 'package:blurly/features/blur/data/datasources/image_picker_data_source.dart';
import 'package:blurly/features/blur/data/repositories/blur_repository_impl.dart';
import 'package:blurly/features/blur/data/services/selfie_segmentation_model_loader.dart';
import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';

import '../test/fakes/fake_blur_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'bundled TFLite model processes an image through the real isolate',
    (tester) async {
      final source = sampleBlurImage('fixture.png');
      final gallery = _RecordingGallery();
      // Replace interactive OS boundaries only. Model assets, native TFLite,
      // repository caching and isolate processing all use production code.
      final repository = BlurRepositoryImpl(
        pickerDataSource: _FixturePicker(source),
        galleryShareDataSource: gallery,
        modelLoader: SelfieSegmentationModelLoader(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [blurRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: BlurPage()),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('pickButton')));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(BlurPage)),
      );
      final state = container.read(blurControllerProvider);
      expect(state.errorMessage, isNull);
      expect(state.canExport, isTrue);
      final processed = state.processedImage!;
      expect(processed.bytes, isNot(orderedEquals(source.bytes)));
      final decoded = img.decodePng(processed.bytes)!;
      expect(decoded.width, 24);
      expect(decoded.height, 24);
      expect(img.decodePng(processed.maskOverlayBytes!), isNotNull);

      await tester.tap(find.byKey(const ValueKey('saveButton')));
      await tester.pumpAndSettle();
      expect(gallery.savedImage, same(processed));
      expect(find.text('Saved to gallery.'), findsOneWidget);
    },
  );
}

class _FixturePicker extends ImagePickerDataSource {
  _FixturePicker(this.image);

  final BlurImage image;

  @override
  Future<BlurImage?> pickFromGallery() async => image;
}

class _RecordingGallery extends GalleryShareDataSource {
  BlurImage? savedImage;

  @override
  Future<String> saveToGallery(BlurImage image) async {
    savedImage = image;
    return '/test-output/${image.name}';
  }
}
