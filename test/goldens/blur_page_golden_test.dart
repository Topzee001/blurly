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

  // Text and icon rasterization can differ by a small number of pixels between
  // macOS hosts (for example, local Apple Silicon versus a hosted runner).
  // Keep local runs pixel-exact, but allow that host-level noise in CI. A 0.5%
  // threshold is intentionally small: a real visual change should still
  // produce a substantially larger diff.
  final previousGoldenComparator = goldenFileComparator;
  setUpAll(() {
    goldenFileComparator = _TolerantGoldenFileComparator(
      Uri.file(File('test/goldens/blur_page_golden_test.dart').absolute.path),
      precisionTolerance: Platform.environment['CI'] == 'true' ? 0.005 : 0,
    );
  });
  tearDownAll(() {
    goldenFileComparator = previousGoldenComparator;
  });

  setUpAll(() async {
    // Bundle fixed test fonts so a reviewer sees readable text, independent
    // of whichever fonts happen to be installed on the CI machine.
    final textFont = FontLoader('Roboto');
    for (final weight in ['Regular', 'Bold']) {
      textFont.addFont(
        File('test/fonts/Roboto-$weight.ttf')
            .readAsBytes()
            .then((bytes) => ByteData.sublistView(bytes)),
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
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
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

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         precisionTolerance >= 0 && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
