import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_blur_repository.dart';

void main() {
  late BlurImage image;
  late List<List<MaskPoint>> strokes;
  late List<bool> viewportChanges;

  setUp(() {
    image = sampleBlurImage('canvas.png');
    strokes = [];
    viewportChanges = [];
  });

  Future<void> pumpCanvas(
    WidgetTester tester, {
    bool editable = true,
    bool viewportGestures = true,
    int resetRequest = 0,
    Size size = const Size(400, 400),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.fromSize(
            size: size,
            child: MaskRefinementCanvas(
              image: image,
              showOverlay: false,
              isEditable: editable,
              brushMode: MaskBrushMode.keep,
              brushSize: 0.04,
              onStroke: strokes.add,
              enableViewportGestures: viewportGestures,
              resetViewportRequest: resetRequest,
              onViewportChanged: viewportChanges.add,
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
  }

  Offset position(WidgetTester tester, Offset local) =>
      tester.getTopLeft(find.byType(MaskRefinementCanvas)) + local;

  Future<void> transformViewport(
    WidgetTester tester, {
    Offset firstStart = const Offset(150, 200),
    Offset secondStart = const Offset(250, 200),
    Offset firstEnd = const Offset(100, 200),
    Offset secondEnd = const Offset(300, 200),
  }) async {
    final first = await tester.startGesture(position(tester, firstStart));
    final second = await tester.startGesture(
      position(tester, secondStart),
      pointer: 2,
    );
    await first.moveTo(position(tester, firstEnd));
    await second.moveTo(position(tester, secondEnd));
    await first.up();
    await second.up();
    await tester.pump();
  }

  void expectViewport(
    WidgetTester tester, {
    double scale = 1,
    Offset offset = Offset.zero,
  }) {
    final transform = tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(MaskRefinementCanvas),
            matching: find.byType(Transform),
          ),
        )
        .transform;
    expect(transform.entry(0, 0), closeTo(scale, 1e-6));
    expect(transform.entry(1, 1), closeTo(scale, 1e-6));
    expect(transform.entry(0, 3), closeTo(offset.dx, 1e-6));
    expect(transform.entry(1, 3), closeTo(offset.dy, 1e-6));
  }

  void expectPoint(MaskPoint point, double x, double y) {
    expect(point.x, closeTo(x, 1e-6));
    expect(point.y, closeTo(y, 1e-6));
  }

  testWidgets('one finger emits an ordered stroke only on release', (
    tester,
  ) async {
    await pumpCanvas(tester);
    final finger = await tester.startGesture(
      position(tester, const Offset(100, 100)),
    );
    await finger.moveTo(position(tester, const Offset(200, 300)));
    expect(strokes, isEmpty);
    await finger.up();

    expect(strokes, hasLength(1));
    expect(strokes.single, hasLength(2));
    expectPoint(strokes.single.first, 0.25, 0.25);
    expectPoint(strokes.single.last, 0.5, 0.75);
    expectViewport(tester);
    expect(viewportChanges, isEmpty);

    await tester.tapAt(position(tester, const Offset(300, 200)));
    expect(strokes, hasLength(2));
    expect(
      strokes.first,
      hasLength(2),
      reason: 'Later gestures must not mutate emitted strokes.',
    );
    expectPoint(strokes.last.single, 0.75, 0.5);
  });

  testWidgets(
    'letterbox points are ignored and image edges normalize correctly',
    (tester) async {
      await pumpCanvas(tester, size: const Size(400, 200));
      await tester.tapAt(position(tester, const Offset(50, 100)));
      expect(strokes, isEmpty);

      final finger = await tester.startGesture(
        position(tester, const Offset(50, 100)),
      );
      await finger.moveTo(position(tester, const Offset(100, 0)));
      await finger.moveTo(position(tester, const Offset(200, 100)));
      await finger.moveTo(position(tester, const Offset(300, 100)));
      await finger.up();

      expect(strokes.single, hasLength(2));
      expectPoint(strokes.single.first, 0, 0);
      expectPoint(strokes.single.last, 0.5, 0.5);
    },
  );

  testWidgets('adding a second finger cancels the draft brush stroke', (
    tester,
  ) async {
    await pumpCanvas(tester);
    final first = await tester.startGesture(
      position(tester, const Offset(100, 200)),
    );
    await first.moveTo(position(tester, const Offset(150, 200)));
    final second = await tester.startGesture(
      position(tester, const Offset(250, 200)),
      pointer: 2,
    );
    await second.moveTo(position(tester, const Offset(350, 200)));
    await second.up();
    await first.moveTo(position(tester, const Offset(180, 220)));
    await first.up();
    await tester.pump();

    expect(
      strokes,
      isEmpty,
      reason: 'The remaining finger must not resume the cancelled stroke.',
    );
    expectViewport(tester, scale: 2, offset: const Offset(50, 0));
    expect(viewportChanges, [true]);

    await tester.tapAt(position(tester, const Offset(250, 200)));
    expectPoint(strokes.single.single, 0.5, 0.5);
  });

  testWidgets('cancelled pointers discard a stroke and allow a fresh stroke', (
    tester,
  ) async {
    await pumpCanvas(tester);
    final finger = await tester.startGesture(
      position(tester, const Offset(100, 100)),
    );
    await finger.moveTo(position(tester, const Offset(200, 200)));
    await finger.cancel();
    expect(strokes, isEmpty);

    await tester.tapAt(position(tester, const Offset(300, 300)));
    expectPoint(strokes.single.single, 0.75, 0.75);
  });

  testWidgets('cancelling a pinch never commits either finger as a stroke', (
    tester,
  ) async {
    await pumpCanvas(tester);
    final first = await tester.startGesture(
      position(tester, const Offset(150, 200)),
    );
    final second = await tester.startGesture(
      position(tester, const Offset(250, 200)),
      pointer: 2,
    );
    await second.moveTo(position(tester, const Offset(350, 200)));
    await second.cancel();
    await first.moveTo(position(tester, const Offset(200, 200)));
    await first.up();
    expect(strokes, isEmpty);

    await tester.tapAt(position(tester, const Offset(250, 200)));
    expectPoint(strokes.single.single, 0.5, 0.5);
  });

  testWidgets('pinch zoom preserves the off-center focal image point', (
    tester,
  ) async {
    await pumpCanvas(tester);
    await transformViewport(
      tester,
      firstStart: const Offset(50, 150),
      secondStart: const Offset(150, 150),
      firstEnd: const Offset(0, 150),
      secondEnd: const Offset(200, 150),
    );

    expectViewport(tester, scale: 2, offset: const Offset(100, 50));
    await tester.tapAt(position(tester, const Offset(100, 150)));
    expectPoint(strokes.single.single, 0.25, 0.375);
  });

  testWidgets('brush coordinates account for both zoom and two-finger pan', (
    tester,
  ) async {
    await pumpCanvas(tester);
    await transformViewport(tester);
    expectViewport(tester, scale: 2);
    await transformViewport(
      tester,
      firstEnd: const Offset(200, 240),
      secondEnd: const Offset(300, 240),
    );
    expectViewport(tester, scale: 2, offset: const Offset(50, 40));

    final finger = await tester.startGesture(
      position(tester, const Offset(250, 240)),
    );
    await finger.moveTo(position(tester, const Offset(350, 140)));
    await finger.up();
    expect(strokes.single, hasLength(2));
    expectPoint(strokes.single.first, 0.5, 0.5);
    expectPoint(strokes.single.last, 0.625, 0.375);
  });

  testWidgets('zoom cannot exceed four times the fitted image', (tester) async {
    await pumpCanvas(tester);
    await transformViewport(
      tester,
      firstStart: const Offset(190, 200),
      secondStart: const Offset(210, 200),
    );
    expectViewport(tester, scale: 4);
    expect(strokes, isEmpty);
  });

  testWidgets(
    'pinching below fit resets zoom and reports an unmodified viewport',
    (tester) async {
      await pumpCanvas(tester);
      await transformViewport(tester);
      await transformViewport(
        tester,
        firstStart: const Offset(100, 200),
        secondStart: const Offset(300, 200),
        firstEnd: const Offset(190, 200),
        secondEnd: const Offset(210, 200),
      );
      expectViewport(tester);
      expect(viewportChanges.last, isFalse);
      expect(strokes, isEmpty);
    },
  );

  for (final direction in [-1.0, 1.0]) {
    testWidgets('pan is bounded on both axes in direction $direction', (
      tester,
    ) async {
      await pumpCanvas(tester);
      await transformViewport(tester);
      final displacement = Offset(500 * direction, 500 * direction);
      await transformViewport(
        tester,
        firstEnd: const Offset(150, 200) + displacement,
        secondEnd: const Offset(250, 200) + displacement,
      );
      expectViewport(
        tester,
        scale: 2,
        offset: Offset(200 * direction, 200 * direction),
      );
      expect(strokes, isEmpty);
    });
  }

  testWidgets('unchanged and coincident pointers do not modify the viewport', (
    tester,
  ) async {
    await pumpCanvas(tester);
    await transformViewport(
      tester,
      firstStart: const Offset(200, 200),
      secondStart: const Offset(200, 200),
      firstEnd: const Offset(200, 200),
      secondEnd: const Offset(300, 200),
    );
    expectViewport(tester);
    expect(viewportChanges, isEmpty);
    expect(strokes, isEmpty);
  });

  testWidgets('reset requests restore fit without changing brush output', (
    tester,
  ) async {
    await pumpCanvas(tester);
    await tester.tapAt(position(tester, const Offset(100, 100)));
    await transformViewport(tester);

    await pumpCanvas(tester);
    expectViewport(tester, scale: 2, offset: Offset.zero);
    final notificationsBeforeReset = viewportChanges.length;
    await pumpCanvas(tester, resetRequest: 1);
    expectViewport(tester);
    expect(viewportChanges.skip(notificationsBeforeReset), [false]);
    expect(strokes, hasLength(1));
    expectPoint(strokes.single.single, 0.25, 0.25);

    await tester.tapAt(position(tester, const Offset(100, 100)));
    expectPoint(strokes.last.single, 0.25, 0.25);
    await pumpCanvas(tester, resetRequest: 2);
    expect(viewportChanges.length, notificationsBeforeReset + 1);
  });

  testWidgets(
    'non-editable canvas allows zoom and reset but emits no strokes',
    (tester) async {
      await pumpCanvas(tester, editable: false);
      await tester.dragFrom(
        position(tester, const Offset(150, 200)),
        const Offset(50, 0),
      );
      await transformViewport(tester);
      expectViewport(tester, scale: 2);
      expect(strokes, isEmpty);
      await pumpCanvas(tester, editable: false, resetRequest: 1);
      expectViewport(tester);
      expect(viewportChanges.last, isFalse);
    },
  );

  testWidgets('legacy drag still draws when viewport gestures are disabled', (
    tester,
  ) async {
    await pumpCanvas(tester, viewportGestures: false);
    await tester.dragFrom(
      position(tester, const Offset(100, 200)),
      const Offset(100, 0),
    );
    expect(strokes, hasLength(1));
    expectPoint(strokes.single.last, 0.5, 0.5);
    expectViewport(tester);
    expect(viewportChanges, isEmpty);
  });

  testWidgets('disabled editing and viewport gestures ignore all input', (
    tester,
  ) async {
    await pumpCanvas(tester, editable: false, viewportGestures: false);
    await tester.dragFrom(
      position(tester, const Offset(100, 200)),
      const Offset(100, 0),
    );
    await transformViewport(tester);
    expect(strokes, isEmpty);
    expect(viewportChanges, isEmpty);
    expectViewport(tester);
  });
}
