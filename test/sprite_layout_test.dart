import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:meituan_desk_pet/pet/sprite_layout.dart';

void main() {
  test('walking and sleeping preserve proportions and share one ground line', () {
    const size = Size(208, 208);
    const sources = [Rect.fromLTWH(0, 652, 313.5, 301), Rect.fromLTWH(0, 953, 313.5, 301)];
    const grounds = [892.0, 1181.0];
    for (var i = 0; i < sources.length; i++) {
      final source = sources[i];
      final dest = spriteDestination(source, grounds[i], size, 313.5);
      final scale = dest.width / source.width;
      expect(dest.height / source.height, closeTo(scale, 0.0001));
      expect(dest.top + (grounds[i] - source.top) * scale,
          closeTo(size.height * 0.94, 0.0001));
      expect(dest.left, greaterThan(0));
      expect(dest.right, lessThan(size.width));
    }
  });
}
