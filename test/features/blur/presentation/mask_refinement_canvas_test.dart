import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const viewportSize = Size(390, 600);
  final cases = [
    (
      name: 'narrow portrait',
      imageSize: const Size(100, 600),
      limitsAt4x: const Offset(5, 900),
      limitsAt2x: const Offset(0, 300),
    ),
    (
      name: 'wide landscape',
      imageSize: const Size(390, 100),
      limitsAt4x: const Offset(585, 0),
      limitsAt2x: const Offset(195, 0),
    ),
  ];

  for (final scenario in cases) {
    testWidgets('pan keeps a ${scenario.name} visible at every zoom level', (
      tester,
    ) async {
      final photo = img.Image(
        width: scenario.imageSize.width.toInt(),
        height: scenario.imageSize.height.toInt(),
      );
      img.fill(photo, color: img.ColorRgb8(60, 180, 140));
      final image = BlurImage(
        bytes: Uint8List.fromList(img.encodePng(photo)),
        name: 'test.png',
      );
      final strokes = <List<MaskPoint>>[];
      final viewportChanges = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox.fromSize(
                size: viewportSize,
                child: MaskRefinementCanvas(
                  image: image,
                  showOverlay: false,
                  isEditable: true,
                  brushMode: MaskBrushMode.keep,
                  brushSize: 0.04,
                  enableViewportGestures: true,
                  onStroke: strokes.add,
                  onViewportChanged: viewportChanges.add,
                ),
              ),
            ),
          ),
        ),
      );
      final canvas = find.byType(MaskRefinementCanvas);
      await tester.runAsync(() async {
        await precacheImage(MemoryImage(image.bytes), tester.element(canvas));
      });
      await tester.pumpAndSettle();
      final transformFinder = find.descendant(
        of: canvas,
        matching: find.byType(Transform),
      );
      final center = tester.getCenter(canvas);
      final first = await tester.startGesture(
        center - const Offset(20, 0),
        pointer: 21,
      );
      final second = await tester.startGesture(
        center + const Offset(20, 0),
        pointer: 22,
      );

      Future<void> expectView(double scale, Offset offset) async {
        await tester.pump();
        final matrix = tester.widget<Transform>(transformFinder).transform;
        expect(matrix.entry(0, 0), closeTo(scale, 0.0001));
        expect(matrix.entry(0, 3), closeTo(offset.dx, 0.0001));
        expect(matrix.entry(1, 3), closeTo(offset.dy, 0.0001));
        final displayedPhoto = Rect.fromCenter(
          center: viewportSize.center(offset),
          width: scenario.imageSize.width * scale,
          height: scenario.imageSize.height * scale,
        );
        expect(displayedPhoto.overlaps(Offset.zero & viewportSize), isTrue);
        expect(strokes, isEmpty);
        expect(tester.takeException(), isNull);
      }

      await first.moveTo(center - const Offset(80, 0));
      await second.moveTo(center + const Offset(80, 0));
      await expectView(4, Offset.zero);

      await first.moveBy(const Offset(1000, 1000));
      await second.moveBy(const Offset(1000, 1000));
      await expectView(4, scenario.limitsAt4x);

      await first.moveBy(const Offset(-2000, -2000));
      await second.moveBy(const Offset(-2000, -2000));
      await expectView(4, -scenario.limitsAt4x);

      const pan = Offset(-1000, -1000);
      await first.moveTo(center + pan - const Offset(40, 0));
      await second.moveTo(center + pan + const Offset(40, 0));
      await expectView(2, -scenario.limitsAt2x);

      await first.moveTo(center + pan - const Offset(20, 0));
      await second.moveTo(center + pan + const Offset(20, 0));
      await expectView(1, Offset.zero);
      expect(viewportChanges.last, isFalse);
      await first.up();
      await second.up();
      expect(strokes, isEmpty);
    });
  }
}
