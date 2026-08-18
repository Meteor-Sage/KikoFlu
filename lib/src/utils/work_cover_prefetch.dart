import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/work.dart';
import '../services/storage_service.dart';

void prefetchWorkCovers(
  BuildContext context,
  Iterable<Work> works, {
  required String host,
  required String token,
  required int crossAxisCount,
}) {
  if (host.isEmpty) return;

  final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  final logicalWidth = crossAxisCount <= 1
      ? 80.0
      : MediaQuery.sizeOf(context).width / crossAxisCount;
  final targetWidth =
      (logicalWidth * devicePixelRatio).round().clamp(160, 1024);
  final headers = StorageService.serverCookieHeaders;

  for (final work in works) {
    final provider = CachedNetworkImageProvider(
      work.getCoverImageUrl(host, token: token),
      headers: headers,
      cacheKey: 'work_cover_${work.id}',
    );
    final resized = ResizeImage.resizeIfNeeded(targetWidth, null, provider);
    unawaited(precacheImage(resized, context).catchError((_) {}));
  }
}
