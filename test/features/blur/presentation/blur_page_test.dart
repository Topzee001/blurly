import 'dart:async';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
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
}
