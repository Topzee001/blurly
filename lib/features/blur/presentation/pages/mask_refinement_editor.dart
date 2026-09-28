import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:blurly/features/blur/presentation/widgets/mask_refinement_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaskRefinementEditor extends ConsumerStatefulWidget {
  const MaskRefinementEditor({
    super.key,
    required this.initialEdits,
    required this.initialEdgeFeather,
    required this.initialMaskExpansion,
  });

  final List<MaskStroke> initialEdits;
  final int initialEdgeFeather;
  final int initialMaskExpansion;

  @override
  ConsumerState<MaskRefinementEditor> createState() =>
      _MaskRefinementEditorState();
}

enum _MaskTool { brush, feather, expand }

class _MaskRefinementEditorState extends ConsumerState<MaskRefinementEditor> {
  _MaskTool _selectedTool = _MaskTool.brush;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(blurControllerProvider.notifier).setMaskRefinementEnabled(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blurControllerProvider);
    final controller = ref.read(blurControllerProvider.notifier);
    final selected = state.selectedImage;
    final processed = state.processedImage;
    final editorImage = processed ?? selected;
    final editorTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF72DFC7),
        brightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: _isLeaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isLeaving) {
          _cancel();
        }
      },
      child: Theme(
        data: editorTheme,
        child: Scaffold(
          key: const ValueKey('maskRefinementEditor'),
          backgroundColor: const Color(0xFF0F1214),
          body: SafeArea(
            child: Column(
              children: [
                _EditorHeader(
                  canUndo: state.canUndoMaskEdit && !state.isProcessing,
                  canRedo: state.canRedoMaskEdit && !state.isProcessing,
                  canFinish: !state.isProcessing,
                  onCancel: _cancel,
                  onUndo: controller.undoMaskEdit,
                  onRedo: controller.redoMaskEdit,
                  onDone: _done,
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.black,
                        child: editorImage == null
                            ? const SizedBox.shrink()
                            : MaskRefinementCanvas(
                                image: editorImage,
                                originalImage: selected,
                                maskOverlayBytes: editorImage.maskOverlayBytes,
                                showOverlay: state.showMaskOverlay,
                                isEditable: !state.isProcessing,
                                brushMode: state.brushMode,
                                brushSize: state.brushSize,
                                pendingPreviewStroke:
                                    state.pendingMaskPreviewStroke,
                                previewBlurSigma: 5 + state.blurAmount * 0.35,
                                onStroke: controller.addMaskStroke,
                              ),
                      ),
                      if (state.showMaskOverlay)
                        const Positioned(
                          top: 14,
                          left: 16,
                          child: _MaskPreviewHint(),
                        ),
                      if (state.isProcessing)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text(
                                'Updating blur',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _EditorToolDock(
                  selectedTool: _selectedTool,
                  brushMode: state.brushMode,
                  showOverlay: state.showMaskOverlay,
                  brushSize: state.brushSize,
                  edgeFeather: state.edgeFeather,
                  maskExpansion: state.maskExpansion,
                  isProcessing: state.isProcessing,
                  onSelectTool: _selectTool,
                  onSelectBrushMode: controller.setBrushMode,
                  onToggleOverlay: () =>
                      controller.setMaskOverlayVisible(!state.showMaskOverlay),
                  onBrushSize: controller.updateBrushSize,
                  onEdgeFeather: controller.updateEdgeFeather,
                  onMaskExpansion: controller.updateMaskExpansion,
                  accent: editorTheme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectTool(_MaskTool tool) {
    setState(() => _selectedTool = tool);
  }

  void _done() {
    ref.read(blurControllerProvider.notifier).closeMaskRefinement();
    _leaveEditor();
  }

  void _cancel() {
    ref
        .read(blurControllerProvider.notifier)
        .discardMaskRefinement(
          maskEdits: widget.initialEdits,
          edgeFeather: widget.initialEdgeFeather,
          maskExpansion: widget.initialMaskExpansion,
        );
    _leaveEditor();
  }

  void _leaveEditor() {
    if (_isLeaving) {
      return;
    }
    setState(() => _isLeaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.canUndo,
    required this.canRedo,
    required this.canFinish,
    required this.onCancel,
    required this.onUndo,
    required this.onRedo,
    required this.onDone,
  });

  final bool canUndo;
  final bool canRedo;
  final bool canFinish;
  final VoidCallback onCancel;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('cancelMaskRefinement'),
            tooltip: 'Cancel mask edits',
            onPressed: onCancel,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Refine subject',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
          IconButton(
            key: const ValueKey('undoMaskEdit'),
            tooltip: 'Undo',
            onPressed: canUndo ? onUndo : null,
            icon: const Icon(Icons.undo),
            color: Colors.white,
            disabledColor: Colors.white30,
          ),
          IconButton(
            key: const ValueKey('redoMaskEdit'),
            tooltip: 'Redo',
            onPressed: canRedo ? onRedo : null,
            icon: const Icon(Icons.redo),
            color: Colors.white,
            disabledColor: Colors.white30,
          ),
          TextButton(
            key: const ValueKey('finishMaskRefinement'),
            onPressed: canFinish ? onDone : null,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _MaskPreviewHint extends StatelessWidget {
  const _MaskPreviewHint();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Teal stays sharp',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _EditorToolDock extends StatelessWidget {
  const _EditorToolDock({
    required this.selectedTool,
    required this.brushMode,
    required this.showOverlay,
    required this.brushSize,
    required this.edgeFeather,
    required this.maskExpansion,
    required this.isProcessing,
    required this.onSelectTool,
    required this.onSelectBrushMode,
    required this.onToggleOverlay,
    required this.onBrushSize,
    required this.onEdgeFeather,
    required this.onMaskExpansion,
    required this.accent,
  });

  final _MaskTool selectedTool;
  final MaskBrushMode brushMode;
  final bool showOverlay;
  final double brushSize;
  final int edgeFeather;
  final int maskExpansion;
  final bool isProcessing;
  final ValueChanged<_MaskTool> onSelectTool;
  final ValueChanged<MaskBrushMode> onSelectBrushMode;
  final VoidCallback onToggleOverlay;
  final ValueChanged<double> onBrushSize;
  final ValueChanged<double> onEdgeFeather;
  final ValueChanged<double> onMaskExpansion;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final adjustment = switch (selectedTool) {
      _MaskTool.brush => _Adjustment(
        label: 'Brush size',
        value: brushSize,
        min: 0.012,
        max: 0.08,
        valueLabel: '${(brushSize * 100).round()}%',
        onChanged: onBrushSize,
      ),
      _MaskTool.feather => _Adjustment(
        label: 'Edge softness',
        value: edgeFeather.toDouble(),
        min: 0,
        max: 12,
        valueLabel: '${edgeFeather}px',
        onChanged: onEdgeFeather,
      ),
      _MaskTool.expand => _Adjustment(
        label: 'Subject size',
        value: maskExpansion.toDouble(),
        min: -12,
        max: 12,
        valueLabel: maskExpansion > 0
            ? '+${maskExpansion}px'
            : '${maskExpansion}px',
        onChanged: onMaskExpansion,
      ),
    };

    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF171B1E)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedTool == _MaskTool.brush)
                SegmentedButton<MaskBrushMode>(
                  key: const ValueKey('maskBrushMode'),
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: MaskBrushMode.keep,
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Keep sharp', maxLines: 1, softWrap: false),
                    ),
                    ButtonSegment(
                      value: MaskBrushMode.blur,
                      icon: Icon(Icons.remove_circle_outline),
                      label: Text('Add blur', maxLines: 1, softWrap: false),
                    ),
                  ],
                  selected: {brushMode},
                  onSelectionChanged: isProcessing
                      ? null
                      : (selection) => onSelectBrushMode(selection.first),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    adjustment.label,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(adjustment.valueLabel, style: TextStyle(color: accent)),
                ],
              ),
              Slider(
                key: ValueKey('mask${selectedTool.name}Slider'),
                value: adjustment.value,
                min: adjustment.min,
                max: adjustment.max,
                divisions: ((adjustment.max - adjustment.min) * 100).round(),
                onChanged: isProcessing ? null : adjustment.onChanged,
              ),
              const Divider(color: Color(0xFF343A3E), height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ToolButton(
                    key: const ValueKey('brushMaskTool'),
                    icon: Icons.brush_outlined,
                    label: 'Brush',
                    selected: selectedTool == _MaskTool.brush,
                    onTap: () => onSelectTool(_MaskTool.brush),
                  ),
                  _ToolButton(
                    key: const ValueKey('featherMaskTool'),
                    icon: Icons.blur_on_outlined,
                    label: 'Feather',
                    selected: selectedTool == _MaskTool.feather,
                    onTap: () => onSelectTool(_MaskTool.feather),
                  ),
                  _ToolButton(
                    key: const ValueKey('expandMaskTool'),
                    icon: Icons.open_with,
                    label: 'Expand',
                    selected: selectedTool == _MaskTool.expand,
                    onTap: () => onSelectTool(_MaskTool.expand),
                  ),
                  _ToolButton(
                    key: const ValueKey('maskPreviewButton'),
                    icon: showOverlay
                        ? Icons.visibility
                        : Icons.visibility_outlined,
                    label: 'Mask',
                    selected: showOverlay,
                    onTap: onToggleOverlay,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Adjustment {
  const _Adjustment({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final ValueChanged<double> onChanged;
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF72DFC7) : Colors.white70;
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
