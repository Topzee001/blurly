import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/fakes/fake_blur_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full flow from image selection to save', (tester) async {
    final repository = FakeBlurRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [blurRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: BlurPage()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pickButton')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('blurSlider')),
      const Offset(60, 0),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saveButton')));
    await tester.pumpAndSettle();

    expect(repository.pickCount, 1);
    expect(repository.processCount, greaterThanOrEqualTo(2));
    expect(repository.saveCount, 1);
    expect(find.text('Saved to gallery.'), findsOneWidget);
  });
}
