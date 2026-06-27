import 'package:blurly/core/theme/app_theme.dart';
import 'package:blurly/features/blur/presentation/pages/blur_page.dart';
import 'package:flutter/material.dart';

class BlurlyApp extends StatelessWidget {
  const BlurlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blurly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const BlurPage(),
    );
  }
}
