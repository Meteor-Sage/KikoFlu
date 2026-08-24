import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../l10n/app_localizations.dart';
import '../utils/scroll_optimization.dart';
import 'liquid_glass_layout.dart';
import 'overscroll_next_page_detector.dart';
import 'pagination_bar.dart';

enum VirtualizedCollectionLayout { list, grid, masonry }

@immutable
class VirtualizedPagination {
  const VirtualizedPagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
    required this.isLoading,
    this.onPreviousPage,
    this.onNextPage,
    this.onGoToPage,
    this.nextPageOnOverscroll = false,
    this.scrollToTop = true,
    this.scrollDuration = const Duration(milliseconds: 500),
    this.scrollCurve = Curves.easeInOut,
    this.extraBuilder,
    this.showWhenEmpty = false,
    this.endMessage,
    this.padding = const EdgeInsets.fromLTRB(8, 8, 8, 24),
  });

  final int currentPage;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
  final bool isLoading;
  final FutureOr<void> Function()? onPreviousPage;
  final FutureOr<void> Function()? onNextPage;
  final FutureOr<void> Function(int page)? onGoToPage;
  final bool nextPageOnOverscroll;
  final bool scrollToTop;
  final Duration scrollDuration;
  final Curve scrollCurve;
  final WidgetBuilder? extraBuilder;
  final bool showWhenEmpty;
  final String? endMessage;
  final EdgeInsetsGeometry padding;

  VirtualizedPagination copyWith({EdgeInsetsGeometry? padding}) {
    return VirtualizedPagination(
      currentPage: currentPage,
      pageSize: pageSize,
      totalCount: totalCount,
      hasMore: hasMore,
      isLoading: isLoading,
      onPreviousPage: onPreviousPage,
      onNextPage: onNextPage,
      onGoToPage: onGoToPage,
      nextPageOnOverscroll: nextPageOnOverscroll,
      scrollToTop: scrollToTop,
      scrollDuration: scrollDuration,
      scrollCurve: scrollCurve,
      extraBuilder: extraBuilder,
      showWhenEmpty: showWhenEmpty,
      endMessage: endMessage,
      padding: padding ?? this.padding,
    );
  }
}

@immutable
class VirtualizedVisibleItem<T> {
  const VirtualizedVisibleItem({
    required this.index,
    required this.id,
    required this.item,
  });

  final int index;
  final Object id;
  final T item;
}

class VirtualizedCollectionController {
  ScrollController? _scrollController;

  bool get hasClients => _scrollController?.hasClients ?? false;

  Future<void> scrollToTop({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) async {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;
    await controller.animateTo(0, duration: duration, curve: curve);
  }

  void jumpToTop() {
    final controller = _scrollController;
    if (controller?.hasClients ?? false) controller!.jumpTo(0);
  }

  void _attach(ScrollController controller) => _scrollController = controller;

  void _detach(ScrollController controller) {
    if (identical(_scrollController, controller)) _scrollController = null;
  }
}

typedef VirtualizedItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

typedef VirtualizedErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback retry,
);

class VirtualizedSliverCollection<T> extends StatefulWidget {
  const VirtualizedSliverCollection({
    super.key,
    required this.items,
    required this.itemId,
    required this.itemBuilder,
    this.layout = VirtualizedCollectionLayout.list,
    this.gridDelegate,
    this.masonryCrossAxisCount,
    this.masonryMainAxisSpacing = 0,
    this.masonryCrossAxisSpacing = 0,
    this.controller,
    this.collectionController,
    this.pageStorageKey,
    this.padding = EdgeInsets.zero,
    this.sliversBefore = const [],
    this.sliversAfter = const [],
    this.onRefresh,
    this.onLoadMore,
    this.pagination,
    this.onRetry,
    this.hasMore = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
    this.emptyBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.loadMoreErrorBuilder,
    this.endBuilder,
    this.showEndIndicator = true,
    this.onVisibleItemsChanged,
    this.onPrefetch,
    this.prefetchItemCount = 6,
    this.nearEndExtent = 720,
    this.cacheExtent = ScrollOptimization.cacheExtent,
    this.physics,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.fillEmptyViewport = true,
    this.collectionTrailingBuilder,
  })  : assert(
          layout != VirtualizedCollectionLayout.grid || gridDelegate != null,
          'gridDelegate is required for grid layout',
        ),
        assert(
          layout != VirtualizedCollectionLayout.masonry ||
              (masonryCrossAxisCount != null && masonryCrossAxisCount > 0),
          'masonryCrossAxisCount is required for masonry layout',
        ),
        assert(
          pagination == null || onLoadMore == null,
          'Explicit pagination and infinite loading are mutually exclusive',
        );

  final List<T> items;
  final Object Function(T item) itemId;
  final VirtualizedItemBuilder<T> itemBuilder;
  final VirtualizedCollectionLayout layout;
  final SliverGridDelegate? gridDelegate;
  final int? masonryCrossAxisCount;
  final double masonryMainAxisSpacing;
  final double masonryCrossAxisSpacing;
  final ScrollController? controller;
  final VirtualizedCollectionController? collectionController;
  final PageStorageKey<String>? pageStorageKey;
  final EdgeInsetsGeometry padding;
  final List<Widget> sliversBefore;
  final List<Widget> sliversAfter;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoadMore;
  final VirtualizedPagination? pagination;
  final VoidCallback? onRetry;
  final bool hasMore;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final Object? error;
  final Object? loadMoreError;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final VirtualizedErrorBuilder? errorBuilder;
  final VirtualizedErrorBuilder? loadMoreErrorBuilder;
  final WidgetBuilder? endBuilder;
  final bool showEndIndicator;
  final ValueChanged<List<VirtualizedVisibleItem<T>>>? onVisibleItemsChanged;
  final ValueChanged<List<T>>? onPrefetch;
  final int prefetchItemCount;
  final double nearEndExtent;
  final double cacheExtent;
  final ScrollPhysics? physics;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool fillEmptyViewport;
  final WidgetBuilder? collectionTrailingBuilder;

  @override
  State<VirtualizedSliverCollection<T>> createState() =>
      _VirtualizedSliverCollectionState<T>();
}

class _VirtualizedSliverCollectionState<T>
    extends State<VirtualizedSliverCollection<T>> {
  late ScrollController _controller;
  late bool _ownsController;
  final Map<int, BuildContext> _mountedItems = {};
  final Set<Object> _prefetchedIds = {};
  bool _inspectionScheduled = false;
  bool _requestInFlight = false;
  bool _pageRequestInFlight = false;
  Object? _lastLoadSignature;
  List<Object> _lastVisibleIds = const [];

  bool get _tracksItems =>
      widget.onVisibleItemsChanged != null || widget.onPrefetch != null;

  @override
  void initState() {
    super.initState();
    _setController(widget.controller);
    widget.collectionController?._attach(_controller);
    _scheduleInspection();
  }

  @override
  void didUpdateWidget(covariant VirtualizedSliverCollection<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.collectionController?._detach(_controller);
      _clearController();
      _setController(widget.controller);
    }
    if (!identical(
        oldWidget.collectionController, widget.collectionController)) {
      oldWidget.collectionController?._detach(_controller);
    }
    widget.collectionController?._attach(_controller);

    final currentIds = widget.items.map(widget.itemId).toSet();
    _prefetchedIds.removeWhere((id) => !currentIds.contains(id));
    _scheduleInspection();
  }

  @override
  void dispose() {
    widget.collectionController?._detach(_controller);
    _clearController();
    super.dispose();
  }

  void _setController(ScrollController? external) {
    _ownsController = external == null;
    _controller = external ?? ScrollController();
    _controller.addListener(_handleScroll);
  }

  void _clearController() {
    _controller.removeListener(_handleScroll);
    if (_ownsController) _controller.dispose();
  }

  void _handleScroll() {
    if (_tracksItems) _scheduleInspection();
    if (widget.pagination == null && widget.onLoadMore != null) {
      _maybeLoadMore();
    }
  }

  void _scheduleInspection() {
    final needsInitialLoadCheck =
        widget.pagination == null && widget.onLoadMore != null;
    if ((!_tracksItems && !needsInitialLoadCheck) || _inspectionScheduled) {
      return;
    }
    _inspectionScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inspectionScheduled = false;
      if (!mounted) return;
      if (_tracksItems) _inspectVisibleItems();
      if (widget.pagination == null && widget.onLoadMore != null) {
        _maybeLoadMore();
      }
    });
  }

  void _registerItem(int index, BuildContext context) {
    _mountedItems[index] = context;
    _scheduleInspection();
  }

  void _unregisterItem(int index, BuildContext context) {
    if (identical(_mountedItems[index], context)) _mountedItems.remove(index);
  }

  void _inspectVisibleItems() {
    if (!_controller.hasClients || widget.items.isEmpty) return;
    if (widget.onVisibleItemsChanged == null && widget.onPrefetch == null) {
      return;
    }

    if (widget.onVisibleItemsChanged == null) {
      _prefetchAfterMountedItems();
      return;
    }

    final position = _controller.position;
    final viewportStart = position.pixels;
    final viewportEnd = viewportStart + position.viewportDimension;
    final visibleIndices = <int>[];

    for (final entry in _mountedItems.entries) {
      final renderObject = entry.value.findRenderObject();
      if (renderObject == null || !renderObject.attached) continue;
      final viewport = RenderAbstractViewport.maybeOf(renderObject);
      if (viewport == null) continue;
      final leading = viewport.getOffsetToReveal(renderObject, 0).offset;
      final trailing = viewport.getOffsetToReveal(renderObject, 1).offset;
      if (trailing > viewportStart && leading < viewportEnd) {
        visibleIndices.add(entry.key);
      }
    }

    visibleIndices.sort();
    final visible = <VirtualizedVisibleItem<T>>[];
    for (final index in visibleIndices) {
      if (index < 0 || index >= widget.items.length) continue;
      final item = widget.items[index];
      visible.add(VirtualizedVisibleItem(
        index: index,
        id: widget.itemId(item),
        item: item,
      ));
    }

    final visibleIds = visible.map((entry) => entry.id).toList(growable: false);
    if (!_sameIds(visibleIds, _lastVisibleIds)) {
      _lastVisibleIds = visibleIds;
      widget.onVisibleItemsChanged?.call(List.unmodifiable(visible));
    }

    if (widget.onPrefetch == null || visibleIndices.isEmpty) return;
    final anchorContext = _mountedItems[visibleIndices.last];
    if (anchorContext == null ||
        position.recommendDeferredLoading(anchorContext)) {
      return;
    }
    final start = visibleIndices.last + 1;
    _dispatchPrefetch(start);
  }

  void _prefetchAfterMountedItems() {
    if (widget.onPrefetch == null || _mountedItems.isEmpty) return;

    final mountedIndices = _mountedItems.keys
        .where((index) => index >= 0 && index < widget.items.length)
        .toList(growable: false);
    if (mountedIndices.isEmpty) return;
    final lastMountedIndex = mountedIndices.reduce((a, b) => a > b ? a : b);
    final anchorContext = _mountedItems[lastMountedIndex];
    if (anchorContext == null ||
        _controller.position.recommendDeferredLoading(anchorContext)) {
      return;
    }

    _dispatchPrefetch(lastMountedIndex + 1);
  }

  void _dispatchPrefetch(int start) {
    final end =
        (start + widget.prefetchItemCount).clamp(0, widget.items.length);
    final pending = <T>[];
    for (var index = start; index < end; index++) {
      final item = widget.items[index];
      if (_prefetchedIds.add(widget.itemId(item))) pending.add(item);
    }
    if (pending.isNotEmpty) widget.onPrefetch!(List.unmodifiable(pending));
  }

  bool _sameIds(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  void _maybeLoadMore() {
    if (widget.pagination != null) return;
    if (!_controller.hasClients || widget.items.isEmpty) return;
    if (_controller.position.extentAfter > widget.nearEndExtent) return;
    _invokeLoadMore();
  }

  Future<void> _changePage(
    VirtualizedPagination pagination,
    FutureOr<void> Function()? callback, {
    bool waitForResultBeforeScroll = false,
  }) async {
    if (callback == null || _pageRequestInFlight) return;
    setState(() => _pageRequestInFlight = true);
    try {
      final result = callback();
      if (waitForResultBeforeScroll) await result;
      if (pagination.scrollToTop) {
        await WidgetsBinding.instance.endOfFrame;
        if (mounted && _controller.hasClients) {
          await _controller.animateTo(
            0,
            duration: pagination.scrollDuration,
            curve: pagination.scrollCurve,
          );
        }
      }
      if (!waitForResultBeforeScroll) await result;
    } finally {
      if (mounted) setState(() => _pageRequestInFlight = false);
    }
  }

  Future<void> _invokeLoadMore({bool force = false}) async {
    final callback = widget.onLoadMore;
    if (callback == null ||
        !widget.hasMore ||
        widget.isInitialLoading ||
        widget.isRefreshing ||
        widget.isLoadingMore ||
        (!force && widget.loadMoreError != null) ||
        _requestInFlight) {
      return;
    }

    final lastId =
        widget.items.isEmpty ? null : widget.itemId(widget.items.last);
    final signature = Object.hash(widget.items.length, lastId);
    if (!force && _lastLoadSignature == signature) return;
    _lastLoadSignature = signature;

    setState(() => _requestInFlight = true);
    try {
      await callback();
    } finally {
      if (mounted) setState(() => _requestInFlight = false);
    }
  }

  SliverChildBuilderDelegate _buildDelegate(Map<Object, int> indexById) {
    return SliverChildBuilderDelegate(
      (context, index) {
        if (index == widget.items.length) {
          return KeyedSubtree(
            key: const ValueKey('virtualized-collection-trailing'),
            child: widget.collectionTrailingBuilder!(context),
          );
        }
        final item = widget.items[index];
        final id = widget.itemId(item);
        final child = widget.itemBuilder(context, item, index);
        if (!_tracksItems) {
          return KeyedSubtree(key: _VirtualizedItemKey(id), child: child);
        }
        return _TrackedVirtualizedItem(
          key: _VirtualizedItemKey(id),
          index: index,
          onMount: _registerItem,
          onUnmount: _unregisterItem,
          child: child,
        );
      },
      childCount: widget.items.length +
          (widget.collectionTrailingBuilder == null ? 0 : 1),
      // flutter_staggered_grid_view 0.7.0 does not correctly re-layout
      // masonry children reparented through findChildIndexCallback.
      findChildIndexCallback:
          widget.layout == VirtualizedCollectionLayout.masonry
              ? null
              : (key) {
                  if (key is! _VirtualizedItemKey) return null;
                  return indexById[key.value];
                },
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
    );
  }

  Widget _buildInitialStatus() {
    if (widget.isInitialLoading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }
    if (widget.error != null) {
      return (widget.errorBuilder ?? _defaultErrorBuilder)(
        context,
        widget.error!,
        widget.onRetry ?? () {},
      );
    }
    return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
  }

  Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    VoidCallback retry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final pagination = widget.pagination;
    if (pagination != null) {
      return Padding(
        padding: pagination.padding,
        child: Column(
          children: [
            PaginationBar(
              currentPage: pagination.currentPage,
              pageSize: pagination.pageSize,
              totalCount: pagination.totalCount,
              hasMore: pagination.hasMore,
              isLoading: pagination.isLoading || _pageRequestInFlight,
              onPreviousPage: pagination.onPreviousPage == null
                  ? null
                  : () => _changePage(pagination, pagination.onPreviousPage),
              onNextPage: pagination.onNextPage == null
                  ? null
                  : () => _changePage(pagination, pagination.onNextPage),
              onGoToPage: pagination.onGoToPage == null
                  ? null
                  : (page) => _changePage(
                        pagination,
                        () => pagination.onGoToPage!(page),
                      ),
              endMessage: pagination.endMessage,
            ),
            if (pagination.extraBuilder != null) ...[
              const SizedBox(height: 8),
              pagination.extraBuilder!(context),
            ],
          ],
        ),
      );
    }
    if (widget.loadMoreError != null) {
      void retry() => _invokeLoadMore(force: true);
      return (widget.loadMoreErrorBuilder ?? _defaultErrorBuilder)(
        context,
        widget.loadMoreError!,
        retry,
      );
    }
    if ((widget.isLoadingMore || _requestInFlight) &&
        widget.collectionTrailingBuilder == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!widget.hasMore && widget.showEndIndicator) {
      return widget.endBuilder?.call(context) ??
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 8),
                Text(S.of(context).reachedEnd),
              ],
            ),
          );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final indexById = <Object, int>{};
    for (var index = 0; index < widget.items.length; index++) {
      indexById[widget.itemId(widget.items[index])] = index;
    }
    assert(
      indexById.length == widget.items.length,
      'VirtualizedSliverCollection item IDs must be unique',
    );

    final delegate = _buildDelegate(indexById);
    final liquidGlassDockExtent = LiquidGlassDockScope.extentOf(context);
    final trailingSafeExtent = liquidGlassDockExtent;
    final collection = switch (widget.layout) {
      VirtualizedCollectionLayout.list => SliverList(delegate: delegate),
      VirtualizedCollectionLayout.grid => SliverGrid(
          delegate: delegate,
          gridDelegate: widget.gridDelegate!,
        ),
      VirtualizedCollectionLayout.masonry => SliverMasonryGrid(
          delegate: delegate,
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.masonryCrossAxisCount!,
          ),
          mainAxisSpacing: widget.masonryMainAxisSpacing,
          crossAxisSpacing: widget.masonryCrossAxisSpacing,
        ),
    };

    Widget scrollView = CustomScrollView(
      key: widget.pageStorageKey,
      controller: _controller,
      cacheExtent: widget.cacheExtent,
      physics: widget.physics,
      slivers: [
        ...widget.sliversBefore,
        if (widget.items.isEmpty && widget.fillEmptyViewport)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildInitialStatus(),
          )
        else if (widget.items.isEmpty)
          SliverToBoxAdapter(child: _buildInitialStatus())
        else ...[
          SliverPadding(padding: widget.padding, sliver: collection),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
        if (widget.items.isEmpty &&
            widget.pagination != null &&
            widget.pagination!.showWhenEmpty)
          SliverToBoxAdapter(child: _buildFooter()),
        ...widget.sliversAfter,
        if (trailingSafeExtent > 0)
          SliverToBoxAdapter(child: SizedBox(height: trailingSafeExtent)),
      ],
    );

    if (widget.onRefresh != null) {
      scrollView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: scrollView,
      );
    }

    final pagination = widget.pagination;
    if (pagination != null && pagination.nextPageOnOverscroll) {
      scrollView = OverscrollNextPageDetector(
        onNextPage: () => _changePage(
          pagination,
          pagination.onNextPage,
          waitForResultBeforeScroll: true,
        ),
        hasNextPage: pagination.hasMore,
        isLoading: pagination.isLoading || _pageRequestInFlight,
        child: scrollView,
      );
    }

    return Stack(
      children: [
        scrollView,
        if (widget.isRefreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }
}

class _VirtualizedItemKey extends ValueKey<Object> {
  const _VirtualizedItemKey(super.value);
}

class _TrackedVirtualizedItem extends StatefulWidget {
  const _TrackedVirtualizedItem({
    super.key,
    required this.index,
    required this.onMount,
    required this.onUnmount,
    required this.child,
  });

  final int index;
  final void Function(int index, BuildContext context) onMount;
  final void Function(int index, BuildContext context) onUnmount;
  final Widget child;

  @override
  State<_TrackedVirtualizedItem> createState() =>
      _TrackedVirtualizedItemState();
}

class _TrackedVirtualizedItemState extends State<_TrackedVirtualizedItem> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onMount(widget.index, context);
    });
  }

  @override
  void didUpdateWidget(covariant _TrackedVirtualizedItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      oldWidget.onUnmount(oldWidget.index, context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onMount(widget.index, context);
      });
    }
  }

  @override
  void dispose() {
    widget.onUnmount(widget.index, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
