import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/work_cover_prefetch.dart';

void main() {
  group('calculateWorkCoverCacheWidth', () {
    test('matches a two-column portrait masonry card', () {
      expect(
        calculateWorkCoverCacheWidth(
          viewportWidth: 390,
          devicePixelRatio: 3,
          crossAxisCount: 2,
          horizontalPadding: 8,
          crossAxisSpacing: 8,
        ),
        549,
      );
    });

    test('matches a five-column landscape masonry card', () {
      expect(
        calculateWorkCoverCacheWidth(
          viewportWidth: 844,
          devicePixelRatio: 3,
          crossAxisCount: 5,
          horizontalPadding: 24,
          crossAxisSpacing: 24,
        ),
        420,
      );
    });

    test('uses the fixed 80dp cover width for list cards', () {
      expect(
        calculateWorkCoverCacheWidth(
          viewportWidth: 390,
          devicePixelRatio: 3,
          crossAxisCount: 1,
          horizontalPadding: 8,
          crossAxisSpacing: 8,
        ),
        240,
      );
    });
  });
}
