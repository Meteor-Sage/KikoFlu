import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/models/work.dart';
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

    test('uses the full cell width for a single-column grid card', () {
      expect(
        calculateWorkCoverCacheWidth(
          viewportWidth: 390,
          devicePixelRatio: 3,
          crossAxisCount: 1,
          horizontalPadding: 8,
          crossAxisSpacing: 8,
          isListCard: false,
        ),
        1024,
      );
    });
  });

  test('creates the same cached decode used by a work card', () {
    const work = Work(id: 123456, title: 'Work');
    final provider = createWorkCoverImageProvider(
      work: work,
      host: 'https://example.com',
      token: 'token',
      cacheWidth: 549,
      headers: const {},
    );

    expect(provider, isA<ResizeImage>());
    final resized = provider as ResizeImage;
    expect(resized.width, 549);
    expect(
      resized.imageProvider,
      const CachedNetworkImageProvider(
        'https://example.com/api/cover/123456?token=token',
        cacheKey: 'work_cover_123456',
      ),
    );
  });
}
