import 'dart:async';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_blur_repository.dart';

void main() {
  Future<FakeBlurRepository> pumpBlurPage(
    WidgetTester tester, {
    FakeBlurRepository? repository,
  }) async {
    final fake = repository ?? FakeBlurRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [blurRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: BlurPage()),
      ),
    );
    return fake;
  }

  testWidgets('image picker button starts gallery flow', (tester) async {
    final repository = await pumpBlurPage(tester);

    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();

    expect(repository.pickCount, 1);
    expect(repository.processCount, 1);
    expect(find.byKey(const ValueKey('blurSlider')), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
  });

  testWidgets('empty preview starts the same gallery flow', (tester) async {
    final repository = await pumpBlurPage(tester);

    await tester.tap(find.byKey(const ValueKey('emptyPreviewPickButton')));
    await tester.pumpAndSettle();

    expect(repository.pickCount, 1);
    expect(repository.processCount, 1);
  });

  testWidgets('slider interaction updates blur intensity', (tester) async {
    final repository = await pumpBlurPage(tester);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('blurSlider')),
      const Offset(80, 0),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.lastOptions?.blurAmount.round(), isNot(18));
    expect(repository.processCount, greaterThanOrEqualTo(2));
  });

  testWidgets('loading indicator is visible during processing', (tester) async {
    final completer = Completer<BlurImage>();
    await pumpBlurPage(
      tester,
      repository: FakeBlurRepository(processCompleter: completer),
    );

    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pump();

    expect(find.byKey(const ValueKey('loadingIndicator')), findsOneWidget);

    completer.complete(sampleBlurImage('processed.png'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('loadingIndicator')), findsNothing);
  });

  testWidgets('before and after toggle switches preview label', (tester) async {
    await pumpBlurPage(tester);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();

    expect(find.text('Blurred'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('beforeAfterToggle')));
    await tester.pumpAndSettle();

    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets('mask refinement opens a focused editor', (tester) async {
    await pumpBlurPage(tester);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('openMaskRefinement')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('maskRefinementEditor')), findsOneWidget);
    expect(find.byKey(const ValueKey('maskBrushMode')), findsOneWidget);
    expect(find.byKey(const ValueKey('undoMaskEdit')), findsOneWidget);
    expect(find.byKey(const ValueKey('maskPreviewButton')), findsOneWidget);
  });

  testWidgets('mask refinement fits a compact phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpBlurPage(tester);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('openMaskRefinement')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('finishMaskRefinement')), findsOneWidget);
  });

  testWidgets('fit image resets a pinched and panned viewport safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = await pumpBlurPage(tester);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(repository.processedImage.bytes),
        tester.element(find.byType(BlurPage)),
      );
    });
    await tester.tap(find.byKey(const ValueKey('openMaskRefinement')));
    await tester.pumpAndSettle();

    final canvas = find.byType(MaskRefinementCanvas);
    final viewportTransform = find.descendant(
      of: canvas,
      matching: find.byType(Transform),
    );
    final resetButton = find.byKey(const ValueKey('resetMaskViewport'));
    final center = tester.getCenter(canvas);
    expect(resetButton, findsNothing);
    final first = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 21,
    );
    final second = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 22,
    );
    await first.moveTo(center - const Offset(65, 0));
    await second.moveTo(center + const Offset(65, 0));
    await first.moveBy(const Offset(20, 15));
    await second.moveBy(const Offset(20, 15));
    await first.up();
    await second.up();
    await tester.pump();

    final zoomed = tester.widget<Transform>(viewportTransform).transform;
    expect(zoomed.entry(0, 0), greaterThan(1));
    expect(zoomed.entry(0, 3), isNot(0));
    expect(resetButton, findsOneWidget);
    expect(find.text('Apply'), findsNothing);

    await tester.tap(resetButton);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(resetButton, findsNothing);
    final reset = tester.widget<Transform>(viewportTransform).transform;
    expect(reset.entry(0, 0), 1);
    expect(reset.entry(0, 3), 0);
    expect(reset.entry(1, 3), 0);
    await tester.pumpAndSettle();
    expect(resetButton, findsNothing);
    expect(find.text('Apply'), findsNothing);
    expect(repository.processCount, 1);

    await tester.tap(find.byKey(const ValueKey('cancelMaskRefinement')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('maskRefinementEditor')), findsNothing);
  });

  testWidgets('zoomed brush edits keep their fine radius through Apply', (
    tester,
  ) async {
    final repository = await pumpBlurPage(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BlurPage)),
    );
    final controller = container.read(blurControllerProvider.notifier);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();
    controller.updateBrushSize(0.012);
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(repository.processedImage.bytes),
        tester.element(find.byType(BlurPage)),
      );
    });
    await tester.tap(find.byKey(const ValueKey('openMaskRefinement')));
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(MaskRefinementCanvas));
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

    controller.setBrushMode(MaskBrushMode.blur);
    await tester.tapAt(center);
    controller.setBrushMode(MaskBrushMode.keep);
    await tester.tapAt(center + const Offset(20, 0));
    await tester.pump();

    final edits = container.read(blurControllerProvider).maskEdits;
    expect(edits.map((edit) => edit.mode), [
      MaskBrushMode.blur,
      MaskBrushMode.keep,
    ]);
    for (final edit in edits) {
      expect(edit.radius, closeTo(0.003, 1e-6));
    }
    expect(repository.processCount, 1);

    await tester.tap(find.byKey(const ValueKey('finishMaskRefinement')));
    await tester.pumpAndSettle();
    expect(repository.processCount, 2);
    expect(repository.lastOptions?.maskEdits, hasLength(2));
    for (final edit in repository.lastOptions!.maskEdits) {
      expect(edit.radius, closeTo(0.003, 1e-6));
    }
  });

  testWidgets('system back cancels mask refinement', (tester) async {
    await pumpBlurPage(tester);
    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('openMaskRefinement')));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('maskRefinementEditor')), findsNothing);
    expect(find.byKey(const ValueKey('openMaskRefinement')), findsOneWidget);
  });

  testWidgets('theme toggle switches between dark and light icons', (
    tester,
  ) async {
    await pumpBlurPage(tester);

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('themeModeToggle')));
    await tester.pump();

    expect(find.byIcon(Icons.light_mode), findsOneWidget);
  });

  testWidgets('privacy policy action opens privacy copy', (tester) async {
    await pumpBlurPage(tester);

    await tester.tap(find.byKey(const ValueKey('privacyPolicyButton')));
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.textContaining('processes photos locally'), findsOneWidget);
  });
}
