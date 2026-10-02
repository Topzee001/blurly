import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImagePreviewCard extends ConsumerWidget {
  const ImagePreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      blurControllerProvider.select((state) => state.selectedImage),
    );
    final processed = ref.watch(
      blurControllerProvider.select((state) => state.processedImage),
    );
    final showOriginal = ref.watch(
      blurControllerProvider.select((state) => state.showOriginal),
    );
    final isProcessing = ref.watch(
      blurControllerProvider.select((state) => state.isProcessing),
    );
    final progress = ref.watch(
      blurControllerProvider.select((state) => state.processingProgress),
    );
    final isFinalizing = ref.watch(
      blurControllerProvider.select((state) => state.isProcessingFinalizing),
    );
    final pickImage = ref.read(blurControllerProvider.notifier).pickImage;

    final image = showOriginal ? selected : processed ?? selected;

    return Card(
      key: const ValueKey('previewCard'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
                  child: child,
                ),
              );
            },
            child: image == null
                ? _EmptyPreview(
                    key: const ValueKey('emptyPreview'),
                    onPickImage: isProcessing ? null : pickImage,
                  )
                : _PreviewImage(
                    key: ValueKey(showOriginal ? 'original' : 'processed'),
                    image: image,
                  ),
          ),
          if (isProcessing)
            _ProcessingOverlay(
              key: const ValueKey('loadingIndicator'),
              progress: progress,
              isFinalizing: isFinalizing,
            ),
          if (processed != null)
            Positioned(
              top: 12,
              left: 12,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: _StatePill(text: showOriginal ? 'Original' : 'Blurred'),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({super.key, required this.image});

  final BlurImage image;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: MaskRefinementCanvas(
        image: image,
        showOverlay: false,
        isEditable: false,
        brushMode: MaskBrushMode.keep,
        brushSize: 0.035,
        onStroke: (_) {},
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({super.key, required this.onPickImage});

  final VoidCallback? onPickImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Pick a photo',
      child: InkWell(
        key: const ValueKey('emptyPreviewPickButton'),
        onTap: onPickImage,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_camera_back,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Pick or shoot a portrait',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({
    super.key,
    required this.progress,
    required this.isFinalizing,
  });

  final double progress;
  final bool isFinalizing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
      ),
      child: Center(
        child: SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                value: isFinalizing ? null : progress.clamp(0.02, 0.78),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: isFinalizing ? null : progress.clamp(0.02, 0.78),
              ),
              const SizedBox(height: 12),
              Text(
                isFinalizing
                    ? 'Finishing your photo...'
                    : 'Processing ${((progress.clamp(0, 0.78)) * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onInverseSurface,
          ),
        ),
      ),
    );
  }
}
