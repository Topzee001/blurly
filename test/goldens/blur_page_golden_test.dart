import 'dart:io';

import 'package:blurly/core/theme/app_theme.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_blur_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Bundle fixed test fonts so a reviewer sees readable text, independent
    // of whichever fonts happen to be installed on the CI machine.
    final textFont = FontLoader('Roboto');
    for (final weight in ['Regular', 'Bold']) {
      textFont.addFont(
        File(
          'test/fonts/Roboto-$weight.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
    await textFont.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  for (final brightness in Brightness.values) {
    testWidgets('empty editor in ${brightness.name} mode matches its golden', (
      tester,
    ) async {
      // Fixed logical dimensions, platform and text scale make the baseline
      // intentional. Generate and compare with the Flutter version in .fvmrc.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            blurRepositoryProvider.overrideWithValue(FakeBlurRepository()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light().copyWith(platform: TargetPlatform.android),
            darkTheme: AppTheme.dark().copyWith(
              platform: TargetPlatform.android,
            ),
            themeMode: brightness == Brightness.light
                ? ThemeMode.light
                : ThemeMode.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            ),
            home: const RepaintBoundary(
              key: ValueKey('goldenEditor'),
              child: BlurPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('goldenEditor')),
        matchesGoldenFile('baselines/blur_page_${brightness.name}.png'),
      );
    });
  }
}
