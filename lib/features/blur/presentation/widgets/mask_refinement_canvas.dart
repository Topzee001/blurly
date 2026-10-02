import 'dart:ui' as ui;
import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/domain/entities/mask_edit.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class MaskRefinementCanvas extends StatefulWidget {
  const MaskRefinementCanvas({
    super.key,
    required this.image,
    required this.showOverlay,
    required this.isEditable,
    required this.brushMode,
    required this.brushSize,
    required this.onStroke,
    this.originalImage,
    this.pendingPreviewStrokes = const [],
    this.previewBlurSigma = 8,
    this.maskOverlayBytes,
  });

  final BlurImage image;
  final bool showOverlay;
  final bool isEditable;
  final MaskBrushMode brushMode;
  final double brushSize;
  final ValueChanged<List<MaskPoint>> onStroke;

  /// The untouched photo is revealed within draft Keep sharp strokes.
  final BlurImage? originalImage;

  /// On-canvas previews of every edit waiting for the user to apply it.
  final List<MaskStroke> pendingPreviewStrokes;
  final double previewBlurSigma;
  final Uint8List? maskOverlayBytes;

  @override
  State<MaskRefinementCanvas> createState() => _MaskRefinementCanvasState();
}

class _MaskRefinementCanvasState extends State<MaskRefinementCanvas> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Size? _imageSize;
  final List<MaskPoint> _activeStroke = [];
  Rect? _imageRect;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant MaskRefinementCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.bytes != widget.image.bytes) {
      _imageSize = null;
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    final oldListener = _imageListener;
    if (oldListener != null) {
      _imageStream?.removeListener(oldListener);
    }
    final provider = MemoryImage(widget.image.bytes);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _imageListener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    });
    _imageStream!.addListener(_imageListener!);
  }

  @override
  void dispose() {
    final listener = _imageListener;
    if (listener != null) {
      _imageStream?.removeListener(listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _imageSize;
        if (size == null ||
            constraints.maxWidth <= 0 ||
            constraints.maxHeight <= 0) {
          return Image.memory(widget.image.bytes, fit: BoxFit.contain);
        }
        final rect = _containedRect(
          Size(constraints.maxWidth, constraints.maxHeight),
          size,
        );
        _imageRect = rect;
        return Stack(
          children: [
            Positioned.fromRect(
              rect: rect,
              child: Image.memory(
                widget.image.bytes,
                fit: BoxFit.fill,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
              ),
            ),
            for (final stroke in widget.pendingPreviewStrokes)
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _MaskStrokeClipper(stroke),
                    child: _PendingStrokePreview(
                      image: widget.image,
                      originalImage: widget.originalImage,
                      stroke: stroke,
                      blurSigma: widget.previewBlurSigma,
                    ),
                  ),
                ),
              ),
            if (widget.showOverlay && widget.maskOverlayBytes != null)
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: Image.memory(
                    widget.maskOverlayBytes!,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
              ),
            if (widget.isEditable)
              Positioned.fromRect(
                rect: rect,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MaskStrokePainter(
                      activeStroke: _activeStroke,
                      radius: widget.brushSize,
                      activeMode: widget.brushMode,
                    ),
                  ),
                ),
              ),
            if (widget.isEditable)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanStart: _startStroke,
                  onPanUpdate: _extendStroke,
                  onPanEnd: (_) => _finishStroke(),
                  onPanCancel: _finishStroke,
                ),
              ),
          ],
        );
      },
    );
  }

  Rect _containedRect(Size available, Size image) {
    final scale = (available.width / image.width).clamp(
      0.0,
      available.height / image.height,
    );
    final width = image.width * scale;
    final height = image.height * scale;
    return Rect.fromLTWH(
      (available.width - width) / 2,
      (available.height - height) / 2,
      width,
      height,
    );
  }

  void _startStroke(DragStartDetails details) {
    _activeStroke.clear();
    _addPoint(details.localPosition);
  }

  void _extendStroke(DragUpdateDetails details) {
    _addPoint(details.localPosition);
  }

  void _addPoint(Offset position) {
    final rect = _imageRect;
    if (rect == null || !rect.contains(position)) {
      return;
    }
    setState(() {
      _activeStroke.add(
        MaskPoint(
          ((position.dx - rect.left) / rect.width).clamp(0, 1),
          ((position.dy - rect.top) / rect.height).clamp(0, 1),
        ),
      );
    });
  }

  void _finishStroke() {
    if (_activeStroke.isNotEmpty) {
      widget.onStroke(List.of(_activeStroke));
    }
    if (mounted) {
      setState(_activeStroke.clear);
    }
  }
}

class _PendingStrokePreview extends StatelessWidget {
  const _PendingStrokePreview({
    required this.image,
    required this.originalImage,
    required this.stroke,
    required this.blurSigma,
  });

  final BlurImage image;
  final BlurImage? originalImage;
  final MaskStroke stroke;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    if (stroke.mode == MaskBrushMode.keep && originalImage != null) {
      return Image.memory(
        originalImage!.bytes,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    }

    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: Image.memory(
        image.bytes,
        fit: BoxFit.fill,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

class _MaskStrokeClipper extends CustomClipper<Path> {
  const _MaskStrokeClipper(this.stroke);

  final MaskStroke stroke;

  @override
  Path getClip(Size size) {
    final points = stroke.points;
    if (points.isEmpty) {
      return Path();
    }

    final radius = stroke.radius.clamp(0.012, 0.08) * size.shortestSide;
    final path = Path();

    void addCircle(Offset center) {
      path.addOval(Rect.fromCircle(center: center, radius: radius));
    }

    Offset toOffset(MaskPoint point) =>
        Offset(point.x * size.width, point.y * size.height);

    var previous = toOffset(points.first);
    addCircle(previous);
    for (final point in points.skip(1)) {
      final current = toOffset(point);
      final distance = (current - previous).distance;
      final steps = (distance / (radius * 0.55)).ceil().clamp(1, 160);
      for (var index = 1; index <= steps; index++) {
        addCircle(Offset.lerp(previous, current, index / steps)!);
      }
      previous = current;
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _MaskStrokeClipper oldClipper) =>
      oldClipper.stroke != stroke;
}

class _MaskStrokePainter extends CustomPainter {
  const _MaskStrokePainter({
    required this.activeStroke,
    required this.radius,
    required this.activeMode,
  });

  final List<MaskPoint> activeStroke;
  final double radius;
  final MaskBrushMode activeMode;

  @override
  void paint(Canvas canvas, Size size) {
    _paintStroke(canvas, size, activeStroke, radius, activeMode);
  }

  void _paintStroke(
    Canvas canvas,
    Size size,
    List<MaskPoint> points,
    double brushRadius,
    MaskBrushMode mode,
  ) {
    if (points.isEmpty) {
      return;
    }
    final color = mode == MaskBrushMode.keep
        ? const Color(0x9945D6AD)
        : const Color(0x99F06A6A);
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushRadius * size.shortestSide * 2;
    final path = Path()
      ..moveTo(points.first.x * size.width, points.first.y * size.height);
    for (final point in points.skip(1)) {
      path.lineTo(point.x * size.width, point.y * size.height);
    }
    canvas.drawPath(path, paint);
    if (points.length == 1) {
      canvas.drawCircle(
        Offset(points.first.x * size.width, points.first.y * size.height),
        paint.strokeWidth / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MaskStrokePainter oldDelegate) => true;
}
