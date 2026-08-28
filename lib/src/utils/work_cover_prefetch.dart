import 'dart:async';
import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/work.dart';
import '../services/storage_service.dart';

const _maxPendingCoverPrefetches = 12;
final Queue<_CoverPrefetchTask> _coverPrefetchQueue = Queue();
final Set<ImageProvider<Object>> _queuedCoverProviders = {};
bool _isDrainingCoverPrefetchQueue = false;

int calculateWorkCoverCacheWidth({
  required double viewportWidth,
  required double devicePixelRatio,
  required int crossAxisCount,
  required double horizontalPadding,
  required double crossAxisSpacing,
  bool isListCard = true,
}) {
  if (crossAxisCount <= 1 && isListCard) {
    return (80 * devicePixelRatio).round().clamp(160, 512);
  }

  final columns = crossAxisCount.clamp(1, 6);
  final availableWidth =
      viewportWidth - horizontalPadding * 2 - crossAxisSpacing * (columns - 1);
  final logicalWidth = (availableWidth / columns).clamp(80.0, viewportWidth);
  return (logicalWidth * devicePixelRatio).round().clamp(160, 1024);
}

int resolveWorkCoverCacheWidth(
  BuildContext context, {
  required int crossAxisCount,
  bool isListCard = true,
}) {
  final isLandscape =
      MediaQuery.orientationOf(context) == Orientation.landscape;
  final spacing = isLandscape ? 24.0 : 8.0;
  final padding = isLandscape ? 24.0 : 8.0;

  return calculateWorkCoverCacheWidth(
    viewportWidth: MediaQuery.sizeOf(context).width,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    crossAxisCount: crossAxisCount,
    horizontalPadding: padding,
    crossAxisSpacing: spacing,
    isListCard: isListCard,
  );
}

ImageProvider<Object> createWorkCoverImageProvider({
  required Work work,
  required String host,
  required String token,
  int? cacheWidth,
  Map<String, String>? headers,
}) {
  final provider = CachedNetworkImageProvider(
    work.getCoverImageUrl(host, token: token),
    headers: headers ?? StorageService.serverCookieHeaders,
    cacheKey: 'work_cover_${work.id}',
  );
  return ResizeImage.resizeIfNeeded(cacheWidth, null, provider);
}

void prefetchWorkCovers(
  BuildContext context,
  Iterable<Work> works, {
  required String host,
  required String token,
  required int crossAxisCount,
  bool isListCard = true,
}) {
  if (host.isEmpty) return;

  final targetWidth = resolveWorkCoverCacheWidth(
    context,
    crossAxisCount: crossAxisCount,
    isListCard: isListCard,
  );
  for (final work in works) {
    final provider = createWorkCoverImageProvider(
      work: work,
      host: host,
      token: token,
      cacheWidth: targetWidth,
    );
    _enqueueCoverPrefetch(context, provider);
  }
}

void _enqueueCoverPrefetch(
  BuildContext context,
  ImageProvider<Object> provider,
) {
  if (_queuedCoverProviders.contains(provider) ||
      _coverPrefetchQueue.length >= _maxPendingCoverPrefetches) {
    return;
  }

  _queuedCoverProviders.add(provider);
  _coverPrefetchQueue.add(_CoverPrefetchTask(context, provider));
  if (!_isDrainingCoverPrefetchQueue) {
    unawaited(_drainCoverPrefetchQueue());
  }
}

Future<void> _drainCoverPrefetchQueue() async {
  _isDrainingCoverPrefetchQueue = true;
  try {
    while (_coverPrefetchQueue.isNotEmpty) {
      final task = _coverPrefetchQueue.removeFirst();
      try {
        if (task.context.mounted) {
          await precacheImage(task.provider, task.context);
        }
      } catch (_) {
        // A failed speculative request must not affect normal image loading.
      } finally {
        _queuedCoverProviders.remove(task.provider);
      }
    }
  } finally {
    _isDrainingCoverPrefetchQueue = false;
  }
}

class _CoverPrefetchTask {
  const _CoverPrefetchTask(this.context, this.provider);

  final BuildContext context;
  final ImageProvider<Object> provider;
}
