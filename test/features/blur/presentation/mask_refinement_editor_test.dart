import 'dart:async';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/mask_refinement_editor.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_blur_repository.dart';

void main() {
  Future<ProviderContainer> pumpEditor(
    WidgetTester tester, {
    FakeBlurRepository? repository,
  }) async {
    final fake = repository ?? FakeBlurRepository();
    final container = ProviderContainer(
      overrides: [blurRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    await container.read(blurControllerProvider.notifier).pickImage();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: MaskRefinementEditor(
            initialEdits: [],
            initialEdgeFeather: 4,
            initialMaskExpansion: 0,
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaskRefinementCanvas));
      await precacheImage(MemoryImage(fake.processedImage.bytes), context);
      await precacheImage(MemoryImage(fake.pickedImage.bytes), context);
    });
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> zoomCanvas(WidgetTester tester) async {
    final center = tester.getCenter(find.byType(MaskRefinementCanvas));
    final first = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await first.moveTo(center - const Offset(60, 0));
    await second.moveTo(center + const Offset(60, 0));
    await first.up();
    await second.up();
    await tester.pump();
  }

  for (final tool in ['feather', 'expand']) {
    testWidgets(
      '$tool disables brush strokes while preserving viewport gestures',
      (tester) async {
        final container = await pumpEditor(tester);
        final canvas = find.byType(MaskRefinementCanvas);
        expect(tester.widget<MaskRefinementCanvas>(canvas).isEditable, isTrue);
        await tester.tap(find.byKey(ValueKey('${tool}MaskTool')));
        await tester.pumpAndSettle();
        expect(tester.widget<MaskRefinementCanvas>(canvas).isEditable, isFalse);

        await tester.dragFrom(tester.getCenter(canvas), const Offset(30, 0));
        await zoomCanvas(tester);
        expect(container.read(blurControllerProvider).maskEdits, isEmpty);
        expect(find.byKey(const ValueKey('resetMaskViewport')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('brushMaskTool')));
        await tester.pumpAndSettle();
        expect(tester.widget<MaskRefinementCanvas>(canvas).isEditable, isTrue);
        await tester.tapAt(tester.getCenter(canvas));
        expect(container.read(blurControllerProvider).maskEdits, hasLength(1));
      },
    );
  }

  testWidgets('processing disables brush input and restores it on completion', (
    tester,
  ) async {
    final repository = FakeBlurRepository();
    final container = await pumpEditor(tester, repository: repository);
    final canvas = find.byType(MaskRefinementCanvas);
    await tester.tapAt(tester.getCenter(canvas));
    await tester.pump();

    final completer = Completer<BlurImage>();
    repository.processCompleter = completer;
    final processing = container
        .read(blurControllerProvider.notifier)
        .applyMaskRefinement();
    await tester.pump();
    expect(tester.widget<MaskRefinementCanvas>(canvas).isEditable, isFalse);
    // Keep input away from the progress indicator covering the canvas center.
    await tester.dragFrom(
      tester.getCenter(canvas) + const Offset(80, 0),
      const Offset(20, 0),
    );
    expect(container.read(blurControllerProvider).maskEdits, hasLength(1));

    completer.complete(repository.processedImage);
    await processing;
    await tester.pumpAndSettle();
    expect(tester.widget<MaskRefinementCanvas>(canvas).isEditable, isTrue);
    await tester.tapAt(tester.getCenter(canvas));
    expect(container.read(blurControllerProvider).maskEdits, hasLength(2));
  });

  testWidgets(
    'fit control appears after zoom and restores the image without discarding edits',
    (tester) async {
      final repository = FakeBlurRepository();
      final container = await pumpEditor(tester, repository: repository);
      final canvas = find.byType(MaskRefinementCanvas);
      final reset = find.byKey(const ValueKey('resetMaskViewport'));
      expect(reset, findsNothing);

      await tester.tapAt(tester.getCenter(canvas));
      await tester.pump();
      final edits = container.read(blurControllerProvider).maskEdits;
      expect(edits, hasLength(1));
      await zoomCanvas(tester);
      expect(reset, findsOneWidget);
      expect(find.byTooltip('Fit image to screen'), findsOneWidget);

      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(reset, findsNothing);
      final transform = tester
          .widget<Transform>(
            find.descendant(of: canvas, matching: find.byType(Transform)),
          )
          .transform;
      expect(transform.isIdentity(), isTrue);
      final state = container.read(blurControllerProvider);
      expect(state.maskEdits, orderedEquals(edits));
      expect(state.hasUnappliedMaskChanges, isTrue);
      expect(repository.processCount, 1);

      await zoomCanvas(tester);
      expect(
        reset,
        findsOneWidget,
        reason: 'Reset must remain usable on subsequent gestures.',
      );
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(reset, findsNothing);
    },
  );
}
