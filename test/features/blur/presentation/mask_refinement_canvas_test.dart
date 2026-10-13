import 'dart:typed_data';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('zoomed strokes keep the fitted brush width on screen', (
    tester,
  ) async {
    final photo = img.Image(width: 100, height: 100);
    img.fill(photo, color: img.ColorRgb8(60, 180, 140));
    final image = BlurImage(
      bytes: Uint8List.fromList(img.encodePng(photo)),
      name: 'brush.png',
    );
    final strokes = <(List<MaskPoint>, double)>[];

    Widget canvasWithPreview(List<MaskStroke> previews) => MaterialApp(
      home: Center(
        child: SizedBox.fromSize(
          size: const Size(400, 400),
          child: MaskRefinementCanvas(
            image: image,
            showOverlay: false,
            isEditable: true,
            brushMode: MaskBrushMode.keep,
            brushSize: 0.04,
            onStroke: (points, radius) => strokes.add((points, radius)),
            pendingPreviewStrokes: previews,
            enableViewportGestures: true,
          ),
        ),
      ),
    );

    await tester.pumpWidget(canvasWithPreview(const []));
    final canvas = find.byType(MaskRefinementCanvas);
    await tester.runAsync(() async {
      await precacheImage(MemoryImage(image.bytes), tester.element(canvas));
    });
    await tester.pump();
    final center = tester.getCenter(canvas);

    await tester.tapAt(center);
    expect(strokes.single.$2, closeTo(0.04, 1e-6));

    final first = await tester.startGesture(
      center - const Offset(20, 0),
      pointer: 21,
    );
    final second = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 22,
    );
    await first.moveTo(center - const Offset(80, 0));
    await second.moveTo(center + const Offset(80, 0));
    await first.up();
    await second.up();
    await tester.pump();

    await tester.tapAt(center);
    expect(strokes.last.$2, closeTo(0.01, 1e-6));
    expect(strokes.last.$1.single.x, closeTo(0.5, 1e-6));

    await tester.pumpWidget(
      canvasWithPreview([
        MaskStroke(
          mode: MaskBrushMode.keep,
          points: strokes.last.$1,
          radius: strokes.last.$2,
        ),
      ]),
    );
    final clipper = tester.widget<ClipPath>(find.byType(ClipPath)).clipper!;
    final previewPath = clipper.getClip(const Size(400, 400));
    expect(previewPath.contains(const Offset(203, 200)), isTrue);
    expect(previewPath.contains(const Offset(206, 200)), isFalse);
  });

  testWidgets('fine pending strokes stay connected across distant points', (
    tester,
  ) async {
    final photo = img.Image(width: 40, height: 40);
    final image = BlurImage(
      bytes: Uint8List.fromList(img.encodePng(photo)),
      name: 'line.png',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: const Size(400, 400),
            child: MaskRefinementCanvas(
              image: image,
              showOverlay: false,
              isEditable: false,
              brushMode: MaskBrushMode.keep,
              brushSize: 0.012,
              onStroke: (_, _) {},
              pendingPreviewStrokes: const [
                MaskStroke(
                  mode: MaskBrushMode.keep,
                  points: [MaskPoint(0, 0.5), MaskPoint(1, 0.5)],
                  radius: 0.001,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(image.bytes),
        tester.element(find.byType(MaskRefinementCanvas)),
      );
    });
    await tester.pump();

    final clipper = tester.widget<ClipPath>(find.byType(ClipPath)).clipper!;
    final previewPath = clipper.getClip(const Size(400, 400));
    expect(previewPath.contains(const Offset(0, 200)), isTrue);
    expect(previewPath.contains(const Offset(201.25, 200)), isTrue);
    expect(previewPath.contains(const Offset(400, 200)), isTrue);
    expect(previewPath.contains(const Offset(201.25, 201)), isFalse);
  });

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
                  onStroke: (points, _) => strokes.add(points),
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
