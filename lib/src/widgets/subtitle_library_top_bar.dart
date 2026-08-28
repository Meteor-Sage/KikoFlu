import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/subtitle_library_service.dart';
import '../utils/design_tokens.dart';

class SubtitleLibraryTopBar extends StatelessWidget {
  const SubtitleLibraryTopBar({
    super.key,
    required this.isSelectionMode,
    required this.isSearching,
    required this.selectedCount,
    required this.searchQuery,
    required this.searchController,
    required this.currentPath,
    required this.rootPath,
    required this.showOpenFolderButton,
    required this.onExitSelection,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onDeleteSelected,
    required this.onRefresh,
    required this.onOpenFolder,
    required this.onStartSearch,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStartSelection,
    required this.onShowGuide,
    required this.onNavigateTo,
    this.stats,
    this.pathSeparator = '/',
  });

  final bool isSelectionMode;
  final bool isSearching;
  final int selectedCount;
  final String searchQuery;
  final TextEditingController searchController;
  final String currentPath;
  final String? rootPath;
  final bool showOpenFolderButton;
  final LibraryStats? stats;
  final String pathSeparator;
  final VoidCallback onExitSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onDeleteSelected;
  final VoidCallback onRefresh;
  final VoidCallback onOpenFolder;
  final VoidCallback onStartSearch;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onStartSelection;
  final VoidCallback onShowGuide;
  final ValueChanged<String> onNavigateTo;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final horizontalPadding = isLandscape ? AppSpacing.lg : AppSpacing.xs;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelectionMode)
            _SelectionToolbar(
              horizontalPadding: horizontalPadding,
              selectedCount: selectedCount,
              onExitSelection: onExitSelection,
              onSelectAll: onSelectAll,
              onDeselectAll: onDeselectAll,
              onDeleteSelected: onDeleteSelected,
            )
          else if (isSearching)
            _SearchToolbar(
              horizontalPadding: horizontalPadding,
              searchController: searchController,
              searchQuery: searchQuery,
              onCloseSearch: onCloseSearch,
              onSearchChanged: onSearchChanged,
              onClearSearch: onClearSearch,
            )
          else
            _DefaultToolbar(
              horizontalPadding: horizontalPadding,
              showOpenFolderButton: showOpenFolderButton,
              stats: stats,
              onRefresh: onRefresh,
              onOpenFolder: onOpenFolder,
              onStartSearch: onStartSearch,
              onStartSelection: onStartSelection,
              onShowGuide: onShowGuide,
            ),
          if (!isSearching && !isSelectionMode)
            Padding(
              padding: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
                top: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_open,
                    size: AppIconSize.small,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: buildBreadcrumbs(context)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> buildBreadcrumbs(BuildContext context) {
    final root = rootPath;
    final breadcrumbs = <Widget>[
      InkWell(
        onTap: root == null ? null : () => onNavigateTo(root),
        borderRadius: BorderRadius.circular(AppRadius.tag),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: 2,
          ),
          child: Text(
            S.of(context).subtitleLibrary,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ];

    if (currentPath.isEmpty || root == null || currentPath == root) {
      return breadcrumbs;
    }

    final relative = currentPath.startsWith(root)
        ? currentPath.substring(root.length)
        : currentPath;
    var cleanRelative = relative;
    if (cleanRelative.startsWith(pathSeparator)) {
      cleanRelative = cleanRelative.substring(pathSeparator.length);
    }
    if (cleanRelative.isEmpty) return breadcrumbs;

    final parts = cleanRelative.split(pathSeparator);
    var currentBuildPath = root;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      currentBuildPath = '$currentBuildPath$pathSeparator$part';
      final targetPath = currentBuildPath;

      breadcrumbs.add(
        Text(
          ' > ',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );

      if (i == parts.length - 1) {
        breadcrumbs.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: 2,
            ),
            child: Text(
              part,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else {
        breadcrumbs.add(
          InkWell(
            onTap: () => onNavigateTo(targetPath),
            borderRadius: BorderRadius.circular(AppRadius.tag),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxs,
                vertical: 2,
              ),
              child: Text(
                part,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }
    }

    return breadcrumbs;
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.horizontalPadding,
    required this.selectedCount,
    required this.onExitSelection,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onDeleteSelected,
  });

  final double horizontalPadding;
  final int selectedCount;
  final VoidCallback onExitSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: horizontalPadding - 8),
          child: IconButton(
            icon: const Icon(Icons.close),
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: onExitSelection,
            tooltip: S.of(context).exitSelection,
          ),
        ),
        Text(
          S.of(context).selectedCount(selectedCount),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        IconButton(
          icon: Icon(selectedCount == 0 ? Icons.select_all : Icons.deselect),
          iconSize: 22,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          onPressed: selectedCount == 0 ? onSelectAll : onDeselectAll,
          tooltip: selectedCount == 0
              ? S.of(context).selectAll
              : S.of(context).deselectAll,
        ),
        if (selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            iconSize: 22,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            onPressed: onDeleteSelected,
            tooltip: S.of(context).deleteWithCount(selectedCount),
            color: Theme.of(context).colorScheme.error,
          ),
        SizedBox(width: horizontalPadding - 8),
      ],
    );
  }
}

class _SearchToolbar extends StatelessWidget {
  const _SearchToolbar({
    required this.horizontalPadding,
    required this.searchController,
    required this.searchQuery,
    required this.onCloseSearch,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final double horizontalPadding;
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onCloseSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: EdgeInsets.only(left: horizontalPadding - 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onCloseSearch,
          ),
        ),
        Expanded(
          child: TextField(
            controller: searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: S.of(context).searchSubtitles,
              border: InputBorder.none,
            ),
            onChanged: onSearchChanged,
          ),
        ),
        if (searchQuery.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: onClearSearch),
        SizedBox(width: horizontalPadding - 8),
      ],
    );
  }
}

class _DefaultToolbar extends StatelessWidget {
  const _DefaultToolbar({
    required this.horizontalPadding,
    required this.showOpenFolderButton,
    required this.onRefresh,
    required this.onOpenFolder,
    required this.onStartSearch,
    required this.onStartSelection,
    required this.onShowGuide,
    this.stats,
  });

  final double horizontalPadding;
  final bool showOpenFolderButton;
  final LibraryStats? stats;
  final VoidCallback onRefresh;
  final VoidCallback onOpenFolder;
  final VoidCallback onStartSearch;
  final VoidCallback onStartSelection;
  final VoidCallback onShowGuide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(S.of(context).reload),
            style: _toolbarButtonStyle(context),
            onPressed: onRefresh,
          ),
          if (showOpenFolderButton)
            TextButton.icon(
              icon: const Icon(Icons.folder_open, size: 20),
              label: Text(S.of(context).openFolder),
              style: _toolbarButtonStyle(context),
              onPressed: onOpenFolder,
            ),
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: onStartSelection,
            tooltip: S.of(context).select,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onStartSearch,
            tooltip: S.of(context).search,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: S.of(context).subtitleLibraryGuide,
            onPressed: onShowGuide,
          ),
          if (stats != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                S
                    .of(context)
                    .nFilesWithSize(stats!.totalFiles, stats!.sizeFormatted),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ButtonStyle _toolbarButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.5),
    );
  }
}
