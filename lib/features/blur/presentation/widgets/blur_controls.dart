import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlurControls extends ConsumerWidget {
  const BlurControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = ref.watch(
      blurControllerProvider.select((state) => state.hasImage),
    );
    if (!hasImage) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_ModeSelector(), SizedBox(height: 18), _BlurSlider()],
        ),
      ),
    );
  }
}

class _ModeSelector extends ConsumerWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(
      blurControllerProvider.select((state) => state.blurMode),
    );
    return SegmentedButton<BlurMode>(
      key: const ValueKey('blurModeSegmented'),
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: BlurMode.background,
          icon: Icon(Icons.center_focus_strong),
          label: Text('Background'),
        ),
        ButtonSegment(
          value: BlurMode.person,
          icon: Icon(Icons.person),
          label: Text('Person'),
        ),
        ButtonSegment(
          value: BlurMode.bokeh,
          icon: Icon(Icons.lens_blur),
          label: Text('Bokeh'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) {
        ref.read(blurControllerProvider.notifier).setBlurMode(selection.first);
      },
    );
  }
}

class _BlurSlider extends ConsumerWidget {
  const _BlurSlider();

  static const double _maxBlurAmount = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blurAmount = ref.watch(
      blurControllerProvider.select((state) => state.blurAmount),
    );
    final isProcessing = ref.watch(
      blurControllerProvider.select((state) => state.isProcessing),
    );
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    final intensityLabel = _intensityPercentageLabel(blurAmount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Intensity', style: labelStyle),
            const Spacer(),
            Text(
              intensityLabel,
              style: labelStyle?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          key: const ValueKey('blurSlider'),
          value: blurAmount,
          min: 0,
          max: _maxBlurAmount,
          divisions: 40,
          label: intensityLabel,
          semanticFormatterCallback: _intensityPercentageLabel,
          onChanged: isProcessing
              ? null
              : ref.read(blurControllerProvider.notifier).updateBlurAmount,
        ),
      ],
    );
  }

  static String _intensityPercentageLabel(double value) {
    final percentage = (value.clamp(0, _maxBlurAmount) / _maxBlurAmount * 100)
        .round();
    return '$percentage%';
  }
}
