import '../providers/settings_provider.dart';
import '../utils/file_icon_utils.dart';

class FileTreeFolderStats {
  const FileTreeFolderStats({
    required this.audioCount,
    required this.textCount,
  });

  final int audioCount;
  final int textCount;
}

class FileTreeMainFolder {
  const FileTreeMainFolder({
    required this.path,
    required this.audioCount,
    required this.textCount,
    required this.expandedPaths,
  });

  final String path;
  final int audioCount;
  final int textCount;
  final Set<String> expandedPaths;
}

class FileTreeUtils {
  FileTreeUtils._();

  /// Sorts a local file tree by display name at every directory level.
  static void sortItemsByTitle(List<dynamic> items) {
    for (final item in items) {
      final children = childrenOf(item);
      if (isFolder(item) && children != null) {
        sortItemsByTitle(children);
      }
    }

    items.sort((a, b) => compareTitles(titleOf(a), titleOf(b)));
  }

  static int compareTitles(String a, String b) {
    final lowerCompare = a.toLowerCase().compareTo(b.toLowerCase());
    return lowerCompare != 0 ? lowerCompare : a.compareTo(b);
  }

  static dynamic property(
    dynamic item,
    String key, {
    dynamic defaultValue,
  }) {
    if (item == null) return defaultValue;

    if (item is Map) {
      return item[key] ?? defaultValue;
    }

    try {
      switch (key) {
        case 'type':
          return (item as dynamic).type ?? defaultValue;
        case 'title':
        case 'name':
          return (item as dynamic).title ?? defaultValue;
        case 'hash':
          return (item as dynamic).hash ?? defaultValue;
        case 'children':
          return (item as dynamic).children ?? defaultValue;
        case 'size':
          return (item as dynamic).size ?? defaultValue;
        case 'mediaType':
          return (item as dynamic).type ?? defaultValue;
        case 'duration':
          return (item as dynamic).duration ?? defaultValue;
        default:
          return defaultValue;
      }
    } catch (_) {
      return defaultValue;
    }
  }

  static String titleOf(dynamic item, {String defaultValue = ''}) {
    final title = property(item, 'title') ?? property(item, 'name');
    return title?.toString() ?? defaultValue;
  }

  static String typeOf(dynamic item, {String defaultValue = ''}) {
    return property(item, 'type', defaultValue: defaultValue)?.toString() ??
        defaultValue;
  }

  static List<dynamic>? childrenOf(dynamic item) {
    final children = property(item, 'children');
    return children is List<dynamic> ? children : null;
  }

  static bool isFolder(dynamic item) => typeOf(item) == 'folder';

  static bool isAudio(dynamic item) {
    final type = typeOf(item);
    final title = titleOf(item).toLowerCase();
    return type == 'audio' || FileIconUtils.inferFileType(title) == 'audio';
  }

  static bool isImage(dynamic item) {
    final type = typeOf(item);
    final title = titleOf(item).toLowerCase();
    return type == 'image' || FileIconUtils.inferFileType(title) == 'image';
  }

  static bool isText(dynamic item) {
    final type = typeOf(item);
    final title = titleOf(item).toLowerCase();
    return type == 'text' || FileIconUtils.inferFileType(title) == 'text';
  }

  static String itemPath(String parentPath, dynamic item) {
    final title = titleOf(item, defaultValue: 'unknown');
    return parentPath.isEmpty ? title : '$parentPath/$title';
  }

  static String localRelativePathOf(dynamic item, String parentPath) {
    final explicitPath = property(item, 'localRelativePath');
    if (explicitPath is String && explicitPath.trim().isNotEmpty) {
      return explicitPath.replaceAll('\\', '/');
    }

    final relativePath = property(item, 'relativePath');
    if (relativePath is String && relativePath.trim().isNotEmpty) {
      return relativePath.replaceAll('\\', '/');
    }

    return itemPath(parentPath, item).replaceAll('\\', '/');
  }

  static Set<String> expandedPathsFor(String targetPath) {
    if (targetPath.isEmpty) return {};

    final expandedPaths = <String>{};
    final segments = targetPath.split('/');
    var currentPath = '';

    for (final segment in segments) {
      currentPath = currentPath.isEmpty ? segment : '$currentPath/$segment';
      expandedPaths.add(currentPath);
    }

    return expandedPaths;
  }

  static List<dynamic> findFolderChildren(
    List<dynamic> rootItems,
    String targetPath,
  ) {
    if (targetPath.isEmpty) return rootItems;

    final segments = targetPath.split('/');
    var currentItems = rootItems;

    for (final segment in segments) {
      dynamic matchedFolder;
      for (final item in currentItems) {
        if (isFolder(item) && titleOf(item) == segment) {
          matchedFolder = item;
          break;
        }
      }

      if (matchedFolder == null) {
        return [];
      }

      currentItems = childrenOf(matchedFolder) ?? [];
    }

    return currentItems;
  }

  static FileTreeFolderStats countImmediateFiles(
    List<dynamic> items, {
    Set<String> audioWithLibrarySubtitles = const {},
  }) {
    var audioCount = 0;
    var textCount = 0;

    for (final item in items) {
      if (isAudio(item)) {
        audioCount++;
        if (audioWithLibrarySubtitles.contains(titleOf(item))) {
          textCount++;
        }
      } else if (isText(item)) {
        textCount++;
      }
    }

    return FileTreeFolderStats(
      audioCount: audioCount,
      textCount: textCount,
    );
  }

  static FileTreeMainFolder? identifyMainFolder(
    List<dynamic> rootItems,
    List<AudioFormat> formatPriority, {
    Set<String> audioWithLibrarySubtitles = const {},
  }) {
    if (rootItems.isEmpty) return null;

    final rootStats = countImmediateFiles(
      rootItems,
      audioWithLibrarySubtitles: audioWithLibrarySubtitles,
    );
    if (rootStats.audioCount > 0) {
      return FileTreeMainFolder(
        path: '',
        audioCount: rootStats.audioCount,
        textCount: rootStats.textCount,
        expandedPaths: const {},
      );
    }

    final folderStats = <String, FileTreeFolderStats>{};

    void analyzeFolders(List<dynamic> items, String parentPath) {
      for (final item in items) {
        if (!isFolder(item)) continue;

        final children = childrenOf(item);
        if (children == null || children.isEmpty) continue;

        final path = itemPath(parentPath, item);
        folderStats[path] = countImmediateFiles(
          children,
          audioWithLibrarySubtitles: audioWithLibrarySubtitles,
        );
        analyzeFolders(children, path);
      }
    }

    analyzeFolders(rootItems, '');

    if (folderStats.isEmpty) {
      return null;
    }

    final maxAudioCount = folderStats.values
        .map((stats) => stats.audioCount)
        .reduce((best, count) => count > best ? count : best);

    var maxTextCount = -1;
    var candidateFolders = <String>[];

    for (final entry in folderStats.entries) {
      if (entry.value.audioCount != maxAudioCount) continue;

      final textCount = entry.value.textCount;
      if (textCount > maxTextCount) {
        maxTextCount = textCount;
        candidateFolders = [entry.key];
      } else if (textCount == maxTextCount) {
        candidateFolders.add(entry.key);
      }
    }

    if (candidateFolders.isEmpty) {
      return null;
    }

    final path = candidateFolders.length > 1
        ? selectByAudioFormatPreference(
            rootItems,
            candidateFolders,
            formatPriority,
          )
        : candidateFolders.first;

    return FileTreeMainFolder(
      path: path,
      audioCount: maxAudioCount,
      textCount: maxTextCount,
      expandedPaths: expandedPathsFor(path),
    );
  }

  static String selectByAudioFormatPreference(
    List<dynamic> rootItems,
    List<String> folderPaths,
    List<AudioFormat> priorityOrder,
  ) {
    final folderPriorities = <String, int>{};

    for (final folderPath in folderPaths) {
      final folderChildren = findFolderChildren(rootItems, folderPath);
      var highestPriority = priorityOrder.length;

      for (final child in folderChildren) {
        if (!isAudio(child)) continue;

        final fileName = titleOf(child).toLowerCase();
        for (var i = 0; i < priorityOrder.length; i++) {
          final format = priorityOrder[i];
          if (fileName.endsWith('.${format.extension}')) {
            if (i < highestPriority) {
              highestPriority = i;
            }
            break;
          }
        }
      }

      folderPriorities[folderPath] = highestPriority;
    }

    var selectedFolder = folderPaths.first;
    var bestPriority = folderPriorities[selectedFolder]!;

    for (final folderPath in folderPaths) {
      final priority = folderPriorities[folderPath]!;
      if (priority < bestPriority) {
        bestPriority = priority;
        selectedFolder = folderPath;
      }
    }

    return selectedFolder;
  }

  static List<dynamic> audioFilesInDirectory(
    List<dynamic> rootItems,
    String targetPath,
  ) {
    return findFolderChildren(rootItems, targetPath).where(isAudio).toList();
  }

  static List<dynamic> imageFilesRecursive(List<dynamic> rootItems) {
    final imageFiles = <dynamic>[];

    void collect(List<dynamic> items) {
      for (final item in items) {
        if (isImage(item)) {
          imageFiles.add(item);
        } else if (isFolder(item)) {
          final children = childrenOf(item);
          if (children != null) {
            collect(children);
          }
        }
      }
    }

    collect(rootItems);
    return imageFiles;
  }

  static String? relativePathForHash(
    List<dynamic> rootItems,
    dynamic targetHash,
  ) {
    if (targetHash == null) return null;

    final targetHashString = targetHash.toString();

    String? find(List<dynamic> items, String parentPath) {
      for (final item in items) {
        if (isFolder(item)) {
          final children = childrenOf(item);
          if (children == null) continue;

          final result = find(children, localRelativePathOf(item, parentPath));
          if (result != null) return result;
          continue;
        }

        final itemHash = property(item, 'hash')?.toString();
        if (itemHash == targetHashString) {
          return localRelativePathOf(item, parentPath);
        }
      }

      return null;
    }

    return find(rootItems, '');
  }

  static List<String> collectNames(List<dynamic> items) {
    final names = <String>[];

    void collect(List<dynamic> currentItems) {
      for (final item in currentItems) {
        final title = titleOf(item);
        if (title.isNotEmpty && !names.contains(title)) {
          names.add(title);
        }

        if (isFolder(item)) {
          final children = childrenOf(item);
          if (children != null) {
            collect(children);
          }
        }
      }
    }

    collect(items);
    return names;
  }
}
