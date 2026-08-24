import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/widgets/virtualized_sliver_collection.dart';
import 'package:kikoeru_flutter/src/widgets/liquid_glass_layout.dart';

Widget _app(Widget child, {Size size = const Size(400, 800)}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(body: child),
    ),
  );
}

Widget _list({
  required List<int> items,
  ScrollController? controller,
  Future<void> Function()? onLoadMore,
  bool hasMore = false,
  Key? pageStorageKey,
  void Function()? onBuild,
}) {
  return VirtualizedSliverCollection<int>(
    items: items,
    itemId: (item) => item,
    controller: controller,
    pageStorageKey: pageStorageKey as PageStorageKey<String>?,
    hasMore: hasMore,
    onLoadMore: onLoadMore,
    showEndIndicator: false,
    itemBuilder: (context, item, index) {
      onBuild?.call();
      return _IdentityTile(item: item);
    },
  );
}

void main() {
  testWidgets('appends the measured liquid glass dock extent', (tester) async {
    final dockExtent = ValueNotifier<double>(128);
    final controller = ScrollController();

    await tester.pumpWidget(
      _app(
        LiquidGlassDockScope(
          notifier: dockExtent,
          child: _list(
            items: List.generate(20, (index) => index),
            controller: controller,
          ),
        ),
      ),
    );
    await tester.pump();
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.height == dockExtent.value,
      ),
      findsOneWidget,
    );
  });

  testWidgets('stable item identity preserves item state after reordering',
      (tester) async {
    final items = ValueNotifier<List<int>>([1, 2, 3]);

    await tester.pumpWidget(_app(ValueListenableBuilder<List<int>>(
      valueListenable: items,
      builder: (context, value, child) => _list(items: value),
    )));
    await tester.pump();

    items.value = [3, 1, 2];
    await tester.pump();

    expect(find.text('3:3'), findsOneWidget);
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('2:2'), findsOneWidget);
  });

  testWidgets('near-end loading is triggered once for the same snapshot',
      (tester) async {
    final controller = ScrollController();
    final pending = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(_app(_list(
      items: List.generate(100, (index) => index),
      controller: controller,
      hasMore: true,
      onLoadMore: () {
        calls++;
        return pending.future;
      },
    )));
    await tester.pump();

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    controller.jumpTo(controller.position.maxScrollExtent - 1);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    expect(calls, 1);
    pending.complete();
    await tester.pump();
    controller.jumpTo(controller.position.maxScrollExtent - 1);
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('end-of-list state never requests another page', (tester) async {
    final controller = ScrollController();
    var calls = 0;

    await tester.pumpWidget(_app(_list(
      items: List.generate(100, (index) => index),
      controller: controller,
      hasMore: false,
      onLoadMore: () async => calls++,
    )));
    await tester.pump();
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    expect(calls, 0);
  });

  testWidgets('load-more failure waits for an explicit retry', (tester) async {
    var calls = 0;

    await tester.pumpWidget(_app(VirtualizedSliverCollection<int>(
      items: List.generate(5, (index) => index),
      itemId: (item) => item,
      hasMore: true,
      loadMoreError: 'page failed',
      onLoadMore: () async {
        calls++;
      },
      showEndIndicator: false,
      itemBuilder: (context, item, index) => _IdentityTile(item: item),
    )));
    await tester.pump();

    expect(calls, 0);
    expect(find.text('page failed'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('only viewport-near children are built', (tester) async {
    var builds = 0;

    await tester.pumpWidget(_app(_list(
      items: List.generate(1000, (index) => index),
      onBuild: () => builds++,
    )));
    await tester.pump();

    expect(builds, lessThan(100));
  });

  testWidgets('prefetch dispatches each upcoming item at most once',
      (tester) async {
    final prefetchedBatches = <List<int>>[];

    await tester.pumpWidget(_app(
      VirtualizedSliverCollection<int>(
        items: List.generate(100, (index) => index),
        itemId: (item) => item,
        cacheExtent: 0,
        prefetchItemCount: 4,
        showEndIndicator: false,
        onPrefetch: (items) => prefetchedBatches.add(items),
        itemBuilder: (context, item, index) => _IdentityTile(item: item),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(prefetchedBatches, isNotEmpty);

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    final allPrefetched = prefetchedBatches.expand((batch) => batch).toList();
    expect(allPrefetched.toSet().length, allPrefetched.length);
  });

  testWidgets('page storage restores position after leaving and returning',
      (tester) async {
    final bucket = PageStorageBucket();

    Widget page(bool visible) => _app(PageStorage(
          bucket: bucket,
          child: visible
              ? _list(
                  items: List.generate(100, (index) => index),
                  pageStorageKey: const PageStorageKey<String>('restore-feed'),
                )
              : const SizedBox.expand(),
        ));

    await tester.pumpWidget(page(true));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final previousOffset =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(previousOffset, greaterThan(0));

    await tester.pumpWidget(page(false));
    await tester.pump();
    await tester.pumpWidget(page(true));
    await tester.pump();

    final restoredOffset =
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    expect(restoredOffset, closeTo(previousOffset, 1));
  });

  testWidgets('list and responsive grid do not overflow phone or tablet widths',
      (tester) async {
    for (final size in const [Size(320, 640), Size(1024, 768)]) {
      await tester.pumpWidget(_app(
        VirtualizedSliverCollection<int>(
          items: List.generate(30, (index) => index),
          itemId: (item) => item,
          layout: VirtualizedCollectionLayout.grid,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 96,
          ),
          showEndIndicator: false,
          itemBuilder: (context, item, index) => Text(
            'A long item title that must remain constrained: $item',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        size: size,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('masonry layout preserves each child intrinsic height',
      (tester) async {
    await tester.pumpWidget(_app(
      VirtualizedSliverCollection<int>(
        items: const [80, 160, 120],
        itemId: (item) => item,
        layout: VirtualizedCollectionLayout.masonry,
        masonryCrossAxisCount: 2,
        masonryMainAxisSpacing: 8,
        masonryCrossAxisSpacing: 8,
        showEndIndicator: false,
        itemBuilder: (context, item, index) => SizedBox(
          key: ValueKey('height-$item'),
          height: item.toDouble(),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byType(SliverMasonryGrid), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('height-80'))).height, 80);
    expect(
      tester.getSize(find.byKey(const ValueKey('height-160'))).height,
      160,
    );
  });

  testWidgets('masonry fills every column when filtered items are restored',
      (tester) async {
    final items = ValueNotifier<List<int>>([0, 2, 4, 6, 8, 10]);

    await tester.pumpWidget(_app(
      ValueListenableBuilder<List<int>>(
        valueListenable: items,
        builder: (context, value, child) =>
            VirtualizedSliverCollection<int>(
          items: value,
          itemId: (item) => item,
          layout: VirtualizedCollectionLayout.masonry,
          masonryCrossAxisCount: 3,
          masonryMainAxisSpacing: 8,
          masonryCrossAxisSpacing: 8,
          showEndIndicator: false,
          itemBuilder: (context, item, index) => SizedBox(
            key: ValueKey('masonry-item-$item'),
            height: 72,
          ),
        ),
      ),
    ));
    await tester.pump();

    items.value = List.generate(12, (index) => index);
    await tester.pump();

    final firstRowX = {
      for (final item in const [0, 1, 2])
        tester
            .getTopLeft(find.byKey(ValueKey('masonry-item-$item')))
            .dx,
    };
    expect(firstRowX, hasLength(3));
  });

  testWidgets('explicit pagination never auto-loads and prevents reentry',
      (tester) async {
    final controller = ScrollController();
    final pending = Completer<void>();
    var calls = 0;

    await tester.pumpWidget(_app(
      VirtualizedSliverCollection<int>(
        items: List.generate(40, (index) => index),
        itemId: (item) => item,
        controller: controller,
        showEndIndicator: false,
        pagination: VirtualizedPagination(
          currentPage: 1,
          pageSize: 20,
          totalCount: 100,
          hasMore: true,
          isLoading: false,
          scrollToTop: false,
          onNextPage: () {
            calls++;
            return pending.future;
          },
        ),
        itemBuilder: (context, item, index) => _IdentityTile(item: item),
      ),
    ));
    await tester.pump();

    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(calls, 0);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(calls, 1);

    pending.complete();
    await tester.pumpAndSettle();
  });
}

class _IdentityTile extends StatefulWidget {
  const _IdentityTile({required this.item});

  final int item;

  @override
  State<_IdentityTile> createState() => _IdentityTileState();
}

class _IdentityTileState extends State<_IdentityTile> {
  late final int initializedFor = widget.item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Text('${widget.item}:$initializedFor'),
    );
  }
}
