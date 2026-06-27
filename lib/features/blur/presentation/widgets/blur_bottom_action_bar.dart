import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlurBottomActionBar extends ConsumerWidget {
  const BlurBottomActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(
      blurControllerProvider.select((state) => state.isProcessing),
    );
    final canExport = ref.watch(
      blurControllerProvider.select((state) => state.canExport),
    );
    final controller = ref.read(blurControllerProvider.notifier);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _BarAction(
                key: const ValueKey('pickButton'),
                icon: Icons.photo_library,
                label: 'Pick',
                onPressed: isProcessing ? null : controller.pickImage,
              ),
              _BarAction(
                key: const ValueKey('cameraButton'),
                icon: Icons.photo_camera,
                label: 'Camera',
                onPressed: isProcessing ? null : controller.takePhoto,
              ),
              _BarAction(
                key: const ValueKey('saveButton'),
                icon: Icons.download,
                label: 'Save',
                onPressed: canExport ? controller.saveImage : null,
              ),
              _BarAction(
                key: const ValueKey('shareButton'),
                icon: Icons.ios_share,
                label: 'Share',
                onPressed: canExport ? controller.shareImage : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  const _BarAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ),
    );
  }
}
