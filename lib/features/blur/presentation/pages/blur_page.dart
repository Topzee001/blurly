import 'package:blurly/core/theme/theme_mode_provider.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/widgets/blur_bottom_action_bar.dart';
import 'package:blurly/features/blur/presentation/widgets/blur_controls.dart';
import 'package:blurly/features/blur/presentation/widgets/image_preview_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlurPage extends ConsumerWidget {
  const BlurPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      blurControllerProvider.select((state) => state.errorMessage),
      (previous, next) => _showSnackBar(context, next, isError: true),
    );
    ref.listen(
      blurControllerProvider.select((state) => state.successMessage),
      (previous, next) => _showSnackBar(context, next),
    );

    final hasImage = ref.watch(
      blurControllerProvider.select((state) => state.hasImage),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blurly'),
        actions: const [
          _PrivacyPolicyAction(),
          _ThemeModeToggle(),
          _BeforeAfterToggle(),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 24 : 16,
                    8,
                    isWide ? 24 : 16,
                    16,
                  ),
                  child: isWide
                      ? const Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(flex: 7, child: ImagePreviewCard()),
                            SizedBox(width: 24),
                            Expanded(flex: 4, child: BlurControls()),
                          ],
                        )
                      : Column(
                          children: [
                            const Expanded(child: ImagePreviewCard()),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: hasImage
                                  ? const Padding(
                                      key: ValueKey('controls'),
                                      padding: EdgeInsets.only(top: 16),
                                      child: BlurControls(),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty-controls'),
                                    ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BlurBottomActionBar(),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String? message, {
    bool isError = false,
  }) {
    if (message == null || message.isEmpty) {
      return;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isError
        ? colorScheme.onError
        : colorScheme.onInverseSurface;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: foreground)),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? colorScheme.error
              : colorScheme.inverseSurface,
        ),
      );
  }
}

class _PrivacyPolicyAction extends StatelessWidget {
  const _PrivacyPolicyAction();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Privacy policy',
      child: IconButton(
        key: const ValueKey('privacyPolicyButton'),
        onPressed: () => _showPrivacyPolicy(context),
        icon: const Icon(Icons.privacy_tip_outlined),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Blurly processes photos locally on your device. It does not '
            'collect, sell, or share personal data with the developer or a '
            'remote server.\n\n'
            'Camera and photo permissions are used only when you choose to '
            'pick, capture, save, or share an image. If you share a processed '
            'image with another app, that transfer is initiated by you through '
            "Android's share sheet.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ThemeModeToggle extends ConsumerWidget {
  const _ThemeModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);

    return Tooltip(
      message: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      child: IconButton(
        key: const ValueKey('themeModeToggle'),
        onPressed: () {
          ref.read(themeModeProvider.notifier).state = isDark
              ? ThemeMode.light
              : ThemeMode.dark;
        },
        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      ),
    );
  }
}

class _BeforeAfterToggle extends ConsumerWidget {
  const _BeforeAfterToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canToggle = ref.watch(
      blurControllerProvider.select((state) => state.processedImage != null),
    );
    final showOriginal = ref.watch(
      blurControllerProvider.select((state) => state.showOriginal),
    );
    return Tooltip(
      message: showOriginal ? 'Show blurred image' : 'Show original image',
      child: IconButton(
        key: const ValueKey('beforeAfterToggle'),
        onPressed: canToggle
            ? ref.read(blurControllerProvider.notifier).toggleOriginal
            : null,
        icon: Icon(showOriginal ? Icons.auto_awesome : Icons.compare),
      ),
    );
  }
}
