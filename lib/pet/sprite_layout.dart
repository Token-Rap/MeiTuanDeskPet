import 'dart:ui';

/// Fits all poses at one pixel scale and anchors their ground to the same line.
Rect spriteDestination(Rect source, double ground, Size size, double cellWidth) {
  final scale = size.width / (cellWidth + 24);
  return Rect.fromLTWH(
    (size.width - source.width * scale) / 2,
    size.height * 0.94 - (ground - source.top) * scale,
    source.width * scale,
    source.height * scale,
  );
}
