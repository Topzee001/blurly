enum MaskBrushMode {
  keep,
  blur;

  String get label => switch (this) {
    MaskBrushMode.keep => 'Keep',
    MaskBrushMode.blur => 'Blur',
  };
}

/// A brush stroke in image-relative coordinates, so it remains valid at any
/// preview or processing resolution.
class MaskStroke {
  const MaskStroke({
    required this.mode,
    required this.points,
    required this.radius,
  });

  final MaskBrushMode mode;
  final List<MaskPoint> points;
  final double radius;
}

class MaskPoint {
  const MaskPoint(this.x, this.y);

  final double x;
  final double y;
}
