import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/l10n/app_localizations.dart';
import 'package:kikoeru_flutter/src/services/subtitle_library_service.dart';
import 'package:kikoeru_flutter/src/widgets/subtitle_library_top_bar.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

SubtitleLibraryTopBar _topBar({
  required TextEditingController searchController,
  bool isSelectionMode = false,
  bool isSearching = false,
  int selectedCount = 0,
  String searchQuery = '',
  String currentPath = '/library/parsed/work',
  String? rootPath = '/library',
  bool showOpenFolderButton = true,
  LibraryStats? stats,
  VoidCallback? onExitSelection,
  VoidCallback? onSelectAll,
  VoidCallback? onDeselectAll,
  VoidCallback? onDeleteSelected,
  VoidCallback? onRefresh,
  VoidCallback? onOpenFolder,
  VoidCallback? onStartSearch,
  VoidCallback? onCloseSearch,
  ValueChanged<String>? onSearchChanged,
  VoidCallback? onClearSearch,
  VoidCallback? onStartSelection,
  VoidCallback? onShowGuide,
  ValueChanged<String>? onNavigateTo,
}) {
  return SubtitleLibraryTopBar(
    isSelectionMode: isSelectionMode,
    isSearching: isSearching,
    selectedCount: selectedCount,
    searchQuery: searchQuery,
    searchController: searchController,
    currentPath: currentPath,
    rootPath: rootPath,
    showOpenFolderButton: showOpenFolderButton,
    stats: stats,
    pathSeparator: '/',
    onExitSelection: onExitSelection ?? () {},
    onSelectAll: onSelectAll ?? () {},
    onDeselectAll: onDeselectAll ?? () {},
    onDeleteSelected: onDeleteSelected ?? () {},
    onRefresh: onRefresh ?? () {},
    onOpenFolder: onOpenFolder ?? () {},
    onStartSearch: onStartSearch ?? () {},
    onCloseSearch: onCloseSearch ?? () {},
    onSearchChanged: onSearchChanged ?? (_) {},
    onClearSearch: onClearSearch ?? () {},
    onStartSelection: onStartSelection ?? () {},
    onShowGuide: onShowGuide ?? () {},
    onNavigateTo: onNavigateTo ?? (_) {},
  );
}

void main() {
  testWidgets('renders default actions, stats, and breadcrumb navigation',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    var refreshCount = 0;
    var openFolderCount = 0;
    var searchCount = 0;
    var selectionCount = 0;
    var guideCount = 0;
    final navigatedPaths = <String>[];

    await tester.pumpWidget(
      _testApp(
        _topBar(
          searchController: controller,
          stats: LibraryStats(
            totalFiles: 2,
            totalSize: 2048,
            folderCount: 1,
          ),
          onRefresh: () => refreshCount++,
          onOpenFolder: () => openFolderCount++,
          onStartSearch: () => searchCount++,
          onStartSelection: () => selectionCount++,
          onShowGuide: () => guideCount++,
          onNavigateTo: navigatedPaths.add,
        ),
      ),
    );

    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Open Folder'), findsOneWidget);
    expect(find.textContaining('2 files'), findsOneWidget);
    expect(find.text('Subtitle Library'), findsOneWidget);
    expect(find.text('parsed'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    await tester.tap(find.text('Open Folder'));
    await tester.tap(find.byIcon(Icons.search));
    await tester.tap(find.byIcon(Icons.checklist));
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.tap(find.text('parsed'));

    expect(
      tester.getCenter(find.byIcon(Icons.checklist)).dx,
      lessThan(tester.getCenter(find.byIcon(Icons.search)).dx),
    );
    expect(refreshCount, 1);
    expect(openFolderCount, 1);
    expect(searchCount, 1);
    expect(selectionCount, 1);
    expect(guideCount, 1);
    expect(navigatedPaths, ['/library/parsed']);
  });

  testWidgets('renders selection actions and dispatches callbacks',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    var exitCount = 0;
    var deselectCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      _testApp(
        _topBar(
          searchController: controller,
          isSelectionMode: true,
          selectedCount: 2,
          onExitSelection: () => exitCount++,
          onDeselectAll: () => deselectCount++,
          onDeleteSelected: () => deleteCount++,
        ),
      ),
    );

    expect(find.text('2 selected'), findsOneWidget);
    expect(find.byIcon(Icons.deselect), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.tap(find.byIcon(Icons.deselect));
    await tester.tap(find.byIcon(Icons.delete));

    expect(exitCount, 1);
    expect(deselectCount, 1);
    expect(deleteCount, 1);
  });

  testWidgets('renders search field and dispatches search callbacks',
      (tester) async {
    final controller = TextEditingController(text: 'voice');
    addTearDown(controller.dispose);

    var closeCount = 0;
    var clearCount = 0;
    var changedValue = '';

    await tester.pumpWidget(
      _testApp(
        _topBar(
          searchController: controller,
          isSearching: true,
          searchQuery: 'voice',
          onCloseSearch: () => closeCount++,
          onClearSearch: () => clearCount++,
          onSearchChanged: (value) => changedValue = value,
        ),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'subtitle');
    await tester.tap(find.byIcon(Icons.clear));
    await tester.tap(find.byIcon(Icons.arrow_back));

    expect(changedValue, 'subtitle');
    expect(clearCount, 1);
    expect(closeCount, 1);
  });
}
