import 'package:blurly/core/theme/app_theme.dart';
import 'package:blurly/core/theme/theme_mode_provider.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blurly/features/blur/presentation/widgets/incoming_share_listener.dart';

class BlurlyApp extends ConsumerWidget {
  const BlurlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Blurly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const IncomingSharedListener(child: BlurPage()),
    );
  }
}
