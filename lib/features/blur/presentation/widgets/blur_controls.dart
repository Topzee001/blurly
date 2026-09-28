import 'package:blurly/features/blur/domain/entities/blur_mode.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/pages/mask_refinement_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlurControls extends ConsumerWidget {
  const BlurControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = ref.watch(
      blurControllerProvider.select((state) => state.hasImage),
    );
    if (!hasImage) return const SizedBox.shrink();

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
          children: [
            _ModeSelector(),
            SizedBox(height: 18),
            _BlurSlider(),
            SizedBox(height: 10),
            _RefineSubjectButton(),
          ],
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
          label: Text(
            'Bg blur',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontSize: 14),
          ),
        ),
        ButtonSegment(
          value: BlurMode.person,
          icon: Icon(Icons.person),
          label: Text('Person', style: TextStyle(fontSize: 14)),
        ),
        ButtonSegment(
          value: BlurMode.bokeh,
          icon: Icon(Icons.lens_blur),
          label: Text('Bokeh', style: TextStyle(fontSize: 14)),
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

class _RefineSubjectButton extends ConsumerWidget {
  const _RefineSubjectButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(blurControllerProvider);
    return OutlinedButton.icon(
      key: const ValueKey('openMaskRefinement'),
      onPressed: state.isProcessing
          ? null
          : () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => MaskRefinementEditor(
                    initialEdits: List.of(state.maskEdits),
                    initialEdgeFeather: state.edgeFeather,
                    initialMaskExpansion: state.maskExpansion,
                  ),
                ),
              );
            },
      icon: const Icon(Icons.brush_outlined),
      label: const Text('Refine subject'),
    );
  }
}
