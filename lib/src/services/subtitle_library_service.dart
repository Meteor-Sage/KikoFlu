import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'download_path_service.dart';
import '../utils/file_icon_utils.dart';

/// 字幕库管理服务
class SubtitleLibraryService {
  static const String _libraryFolderName = 'subtitle_library';

  // Windows 路径长度限制 (保留一些余量)
  static const int _maxPathLength = 240;

  // 缓存相关
  static List<Map<String, dynamic>>? _cachedFileTree;
  static LibraryStats? _cachedStats;
  static DateTime? _lastKnownModified;
  static String? _libraryRootPath;

  /// 清除缓存
  static void clearCache() {
    _cachedFileTree = null;
    _cachedStats = null;
    _lastKnownModified = null;
    _libraryRootPath = null;
    print('[SubtitleLibrary] 缓存已清除');
  }

  static void _ensureRootPath(String path) {
    if (_libraryRootPath == null) {
      _libraryRootPath = path;
      return;
    }

    if (_libraryRootPath != path) {
      clearCache();
      _libraryRootPath = path;
    }
  }

  static Future<void> _updateLibraryModifiedTime([Directory? directory]) async {
    try {
      final dir = directory ?? await getSubtitleLibraryDirectory();
      final stat = await dir.stat();
      _lastKnownModified = stat.modified;
    } catch (e) {
      print('[SubtitleLibrary] 更新目录修改时间失败: $e');
    }
  }

  /// 检查目录是否有变化
  static Future<bool> _hasDirectoryChanged(Directory dir) async {
    if (!await dir.exists()) {
      return true;
    }

    try {
      final stat = await dir.stat();
      final currentModified = stat.modified;

      // 如果没有记录上次修改时间，认为有变化
      if (_lastKnownModified == null) {
        _lastKnownModified = currentModified;
        return true;
      }

      // 如果修改时间不同，说明有变化
      if (currentModified != _lastKnownModified) {
        _lastKnownModified = currentModified;
        return true;
      }

      return false;
    } catch (e) {
      print('[SubtitleLibrary] 检查目录变化失败: $e');
      return true; // 出错时认为有变化，重新扫描
    }
  }

  /// 获取字幕库目录
  static Future<Directory> getSubtitleLibraryDirectory() async {
    final downloadDir = await DownloadPathService.getDownloadDirectory();
    final libraryDir = Directory('${downloadDir.path}/$_libraryFolderName');

    // 如果不存在则自动创建
    if (!await libraryDir.exists()) {
      await libraryDir.create(recursive: true);
      print('[SubtitleLibrary] 创建字幕库目录: ${libraryDir.path}');
    }

    _ensureRootPath(libraryDir.path);
    return libraryDir;
  }

  /// 检查字幕库是否存在
  static Future<bool> exists() async {
    final libraryDir = await getSubtitleLibraryDirectory();
    return await libraryDir.exists();
  }

  /// 导入单个字幕文件
  static Future<ImportResult> importSubtitleFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'vtt',
          'srt',
          'lrc',
          'txt',
          'ass',
          'ssa',
          'sub',
          'idx',
          'sbv',
          'dfxp',
          'ttml'
        ],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: '未选择文件',
        );
      }

      final libraryDir = await getSubtitleLibraryDirectory();
      int successCount = 0;
      int errorCount = 0;
      final List<String> errorFiles = [];

      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final sourceFile = File(platformFile.path!);
        final fileName = platformFile.name;

        // 验证是否是字幕文件
        if (!FileIconUtils.isLyricFile(fileName)) {
          errorCount++;
          errorFiles.add('$fileName (不是字幕文件)');
          continue;
        }

        try {
          final destFile = File('${libraryDir.path}/$fileName');

          // 如果文件已存在，添加序号
          String finalFileName = fileName;
          int counter = 1;
          File finalDestFile = destFile;

          while (await finalDestFile.exists()) {
            final nameWithoutExt =
                fileName.substring(0, fileName.lastIndexOf('.'));
            final ext = fileName.substring(fileName.lastIndexOf('.'));
            finalFileName = '${nameWithoutExt}_$counter$ext';
            finalDestFile = File('${libraryDir.path}/$finalFileName');
            counter++;
          }

          await sourceFile.copy(finalDestFile.path);
          successCount++;
          print('[SubtitleLibrary] 导入字幕文件: $finalFileName');
        } catch (e) {
          errorCount++;
          errorFiles.add('$fileName ($e)');
          print('[SubtitleLibrary] 导入文件失败: $fileName, 错误: $e');
        }
      }

      String message = '成功导入 $successCount 个字幕文件';
      if (errorCount > 0) {
        message += '\n失败 $errorCount 个';
        if (errorFiles.length <= 3) {
          message += ': ${errorFiles.join(", ")}';
        }
      }

      return ImportResult(
        success: successCount > 0,
        message: message,
        importedCount: successCount,
        errorCount: errorCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入失败: $e',
      );
    }
  }

  /// 导入文件夹（保留内部结构，过滤非字幕文件）
  static Future<ImportResult> importFolder() async {
    try {
      final directoryPath = await FilePicker.platform.getDirectoryPath();

      if (directoryPath == null) {
        return ImportResult(
          success: false,
          message: '未选择文件夹',
        );
      }

      final sourceDir = Directory(directoryPath);
      if (!await sourceDir.exists()) {
        return ImportResult(
          success: false,
          message: '文件夹不存在',
        );
      }

      final libraryDir = await getSubtitleLibraryDirectory();
      final folderName = sourceDir.path.split(Platform.pathSeparator).last;
      final targetDir = Directory('${libraryDir.path}/$folderName');

      int successCount = 0;
      int errorCount = 0;
      int skippedCount = 0;

      // 递归处理文件夹
      await for (final entity
          in sourceDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;

          // 只处理字幕文件
          if (!FileIconUtils.isLyricFile(fileName)) {
            skippedCount++;
            continue;
          }

          try {
            // 保持相对路径结构
            final relativePath =
                entity.path.substring(sourceDir.path.length + 1);
            final targetFile = File('${targetDir.path}/$relativePath');

            await targetFile.parent.create(recursive: true);
            await entity.copy(targetFile.path);
            successCount++;
            print('[SubtitleLibrary] 导入: $relativePath');
          } catch (e) {
            errorCount++;
            print('[SubtitleLibrary] 导入文件失败: $fileName, 错误: $e');
          }
        }
      }

      if (successCount == 0) {
        return ImportResult(
          success: false,
          message: '文件夹中没有找到字幕文件',
        );
      }

      String message = '成功导入 $successCount 个字幕文件';
      if (skippedCount > 0) {
        message += '\n跳过 $skippedCount 个非字幕文件';
      }
      if (errorCount > 0) {
        message += '\n失败 $errorCount 个';
      }

      // 清除缓存以便下次重新扫描
      clearCache();

      return ImportResult(
        success: true,
        message: message,
        importedCount: successCount,
        errorCount: errorCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入文件夹失败: $e',
      );
    }
  }

  /// 导入压缩包（支持多层嵌套解压）
  static Future<ImportResult> importArchive() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'rar', '7z'],
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: '未选择压缩包',
        );
      }

      final platformFile = result.files.first;
      if (platformFile.path == null) {
        return ImportResult(
          success: false,
          message: '无法访问文件',
        );
      }

      final archiveFile = File(platformFile.path!);

      // 检查文件大小（限制 16GB）
      const maxArchiveSize = 16 * 1024 * 1024 * 1024; // 16GB
      final fileSize = await archiveFile.length();
      if (fileSize > maxArchiveSize) {
        final sizeInGB = (fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2);
        return ImportResult(
          success: false,
          message: '压缩包文件过大 ($sizeInGB GB)，最大支持 16GB',
        );
      }

      final bytes = await archiveFile.readAsBytes();

      final libraryDir = await getSubtitleLibraryDirectory();
      final archiveName =
          platformFile.name.substring(0, platformFile.name.lastIndexOf('.'));

      // 先解析压缩包以判断根目录结构
      Archive? archive;
      try {
        if (platformFile.extension == 'zip') {
          archive = ZipDecoder().decodeBytes(bytes, verify: false);
        } else {
          return ImportResult(
            success: false,
            message: '暂只支持 ZIP 格式压缩包',
          );
        }
      } catch (e) {
        return ImportResult(
          success: false,
          message: '解压失败，可能是加密的压缩包: $e',
        );
      }

      // 智能判断是否需要创建新文件夹
      // 如果压缩包根目录只有一个文件夹，直接解压到根目录；否则创建新文件夹
      final shouldCreateFolder = _shouldCreateNewFolder(archive);
      final targetDir = shouldCreateFolder
          ? Directory('${libraryDir.path}/$archiveName')
          : libraryDir;

      print(
          '[SubtitleLibrary] 压缩包根目录${shouldCreateFolder ? "有多个项" : "只有单一文件夹"}，${shouldCreateFolder ? "创建新文件夹" : "直接解压到根目录"}');

      // 创建导入统计器
      final stats = _ImportStats();

      // 处理压缩包（支持嵌套）
      await _processArchiveBytes(
        bytes,
        platformFile.extension ?? 'zip',
        targetDir.path,
        '',
        stats,
        depth: 0,
      );

      if (stats.successCount == 0) {
        // 根据错误信息生成更详细的提示
        String message = '压缩包中没有找到字幕文件';
        if (stats.sizeErrorCount > 0) {
          message += '\n有 ${stats.sizeErrorCount} 个文件因过大被跳过';
        }
        if (stats.depthErrorCount > 0) {
          message += '\n有 ${stats.depthErrorCount} 个文件因嵌套过深被跳过';
        }
        if (stats.decodeErrorCount > 0) {
          message += '\n有 ${stats.decodeErrorCount} 个文件解压失败';
        }
        if (stats.skippedCount > 0) {
          message += '\n跳过 ${stats.skippedCount} 个非字幕文件';
        }
        return ImportResult(
          success: false,
          message: message,
        );
      }

      String message = '成功导入 ${stats.successCount} 个字幕文件';
      if (stats.nestedArchiveCount > 0) {
        message += '\n解压 ${stats.nestedArchiveCount} 个嵌套压缩包';
      }
      if (stats.skippedCount > 0) {
        message += '\n跳过 ${stats.skippedCount} 个非字幕文件';
      }
      if (stats.errorCount > 0) {
        message += '\n失败 ${stats.errorCount} 个';
      }

      return ImportResult(
        success: true,
        message: message,
        importedCount: stats.successCount,
        errorCount: stats.errorCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入压缩包失败: $e',
      );
    }
  }

  /// 处理压缩包字节数据（递归支持嵌套）
  static Future<void> _processArchiveBytes(
    List<int> bytes,
    String extension,
    String targetBasePath,
    String relativePath,
    _ImportStats stats, {
    required int depth,
  }) async {
    // 防止无限递归：最大深度限制
    const maxDepth = 10;
    if (depth > maxDepth) {
      print('[SubtitleLibrary] 警告: 压缩包嵌套深度超过 $maxDepth 层，停止解压');
      stats.errorCount++;
      stats.depthErrorCount++;
      return;
    }

    // 内存保护：单个嵌套压缩包大小限制 (1GB)
    const maxFileSize = 1024 * 1024 * 1024; // 1GB
    if (bytes.length > maxFileSize) {
      final sizeInMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      print('[SubtitleLibrary] 警告: 嵌套压缩包过大 ($sizeInMB MB)，跳过');
      stats.errorCount++;
      stats.sizeErrorCount++;
      return;
    }

    // 解压
    Archive? archive;
    try {
      if (extension == 'zip') {
        archive = ZipDecoder().decodeBytes(bytes, verify: false);
      } else {
        print('[SubtitleLibrary] 不支持的压缩格式: $extension');
        stats.skippedCount++;
        return;
      }
    } catch (e) {
      print('[SubtitleLibrary] 解压失败 (depth=$depth): $e');
      stats.errorCount++;
      stats.decodeErrorCount++;
      return;
    }

    // 处理压缩包中的文件
    for (final file in archive.files) {
      if (!file.isFile) continue;

      // 尝试修复文件名编码（处理 GBK 编码的中文文件名）
      String decodedName = file.name;
      try {
        final nameBytes = latin1.encode(file.name);
        decodedName = gbk_bytes.decode(nameBytes);
      } catch (e) {
        decodedName = file.name;
      }

      final fileName = decodedName.split('/').last;
      final fileExtension = fileName.contains('.')
          ? fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
          : '';

      // 获取文件内容
      List<int>? content;
      try {
        content = file.content as List<int>?;
        if (content == null || content.isEmpty) {
          stats.skippedCount++;
          continue;
        }

        // 内存保护：限制单个文件内容大小 (500MB)
        const maxContentSize = 500 * 1024 * 1024;
        if (content.length > maxContentSize) {
          final sizeInMB = (content.length / (1024 * 1024)).toStringAsFixed(1);
          print('[SubtitleLibrary] 文件过大，跳过: $decodedName ($sizeInMB MB)');
          stats.sizeErrorCount++;
          stats.skippedCount++;
          continue;
        }
      } catch (e) {
        print('[SubtitleLibrary] 读取文件内容失败: $decodedName, 错误: $e');
        stats.errorCount++;
        continue;
      }

      // 判断是否是嵌套的压缩包
      if (fileExtension == 'zip') {
        print('[SubtitleLibrary] 发现嵌套压缩包 (depth=${depth + 1}): $decodedName');
        stats.nestedArchiveCount++;

        // 先解析嵌套压缩包以判断是否需要创建文件夹
        Archive? nestedArchive;
        try {
          nestedArchive = ZipDecoder().decodeBytes(content, verify: false);
        } catch (e) {
          print('[SubtitleLibrary] 解析嵌套压缩包失败: $decodedName, 错误: $e');
          stats.decodeErrorCount++;
          stats.errorCount++;
          continue;
        }

        // 智能判断是否需要为嵌套压缩包创建文件夹
        final shouldCreateFolder = _shouldCreateNewFolder(nestedArchive);
        final zipNameWithoutExt =
            decodedName.replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');

        // 根据智能判断决定相对路径
        final nestedRelativePath = shouldCreateFolder
            ? (relativePath.isEmpty
                ? zipNameWithoutExt
                : '$relativePath/$zipNameWithoutExt')
            : relativePath; // 不创建文件夹时使用当前相对路径

        print(
            '[SubtitleLibrary] 嵌套压缩包${shouldCreateFolder ? "有多个项，创建文件夹" : "只有单一文件夹，直接解压"}: $zipNameWithoutExt');

        // 递归处理嵌套压缩包
        await _processArchiveBytes(
          content,
          'zip',
          targetBasePath,
          nestedRelativePath,
          stats,
          depth: depth + 1,
        );
        continue;
      }

      // 处理字幕文件
      if (FileIconUtils.isLyricFile(fileName)) {
        try {
          final fullRelativePath =
              relativePath.isEmpty ? decodedName : '$relativePath/$decodedName';
          var targetFilePath = '$targetBasePath/$fullRelativePath';

          // 检查路径长度，如果过长则缩短
          if (targetFilePath.length > _maxPathLength) {
            targetFilePath = _shortenPath(targetFilePath, fileName);
            if (targetFilePath.isEmpty) {
              print('[SubtitleLibrary] 路径过长无法缩短，跳过: $decodedName');
              stats.skippedCount++;
              continue;
            }
          }

          final targetFile = File(targetFilePath);

          await targetFile.parent.create(recursive: true);
          await targetFile.writeAsBytes(content);
          stats.successCount++;
          print(
              '[SubtitleLibrary] 解压字幕 (depth=$depth): ${targetFile.path.substring(targetBasePath.length)}');
        } catch (e) {
          stats.errorCount++;
          print('[SubtitleLibrary] 写入文件失败: $decodedName, 错误: $e');
        }
      } else {
        stats.skippedCount++;
      }
    }
  }

  /// 获取字幕库文件列表（树状结构）
  /// forceRefresh: 是否强制刷新，忽略缓存
  static Future<List<Map<String, dynamic>>> getSubtitleFiles({
    bool forceRefresh = false,
  }) async {
    final libraryDir = await getSubtitleLibraryDirectory();

    if (!await libraryDir.exists()) {
      return [];
    }

    // 检查是否需要刷新缓存
    final hasChanged = await _hasDirectoryChanged(libraryDir);

    if (!forceRefresh && !hasChanged && _cachedFileTree != null) {
      print('[SubtitleLibrary] 使用缓存的文件树');
      return _cachedFileTree!;
    }

    print('[SubtitleLibrary] 重新扫描文件树');
    final fileTree = await _buildFileTree(libraryDir, libraryDir.path);

    // 更新缓存
    _cachedFileTree = fileTree;

    return fileTree;
  }

  /// 构建文件树
  static Future<List<Map<String, dynamic>>> _buildFileTree(
      Directory dir, String rootPath) async {
    final List<Map<String, dynamic>> items = [];

    try {
      // 检查路径长度
      if (dir.path.length > _maxPathLength) {
        print('[SubtitleLibrary] 路径过长，跳过目录: ${dir.path}');
        return items;
      }

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          // 检查子目录路径长度
          if (entity.path.length > _maxPathLength) {
            print(
                '[SubtitleLibrary] 子目录路径过长，跳过: ${entity.path.split(Platform.pathSeparator).last}');
            continue;
          }

          final children = await _buildFileTree(entity, rootPath);
          if (children.isNotEmpty) {
            items.add({
              'type': 'folder',
              'title': entity.path.split(Platform.pathSeparator).last,
              'path': entity.path,
              'children': children,
            });
          }
        } else if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (FileIconUtils.isLyricFile(fileName)) {
            try {
              final stat = await entity.stat();
              items.add({
                'type': 'text',
                'title': fileName,
                'path': entity.path,
                'size': stat.size,
                'modified': stat.modified.toIso8601String(),
              });
            } catch (e) {
              print('[SubtitleLibrary] 读取文件信息失败: $fileName, 错误: $e');
            }
          }
        }
      }
    } catch (e) {
      // 检查是否是路径过长导致的错误
      if (e is FileSystemException ||
          e.toString().contains('PathNotFoundException') ||
          e.toString().contains('系统找不到指定的路径')) {
        print(
            '[SubtitleLibrary] 路径过长导致访问失败，跳过: ${dir.path.split(Platform.pathSeparator).last}');
      } else {
        print('[SubtitleLibrary] 读取目录失败: ${dir.path}, 错误: $e');
      }
    }

    // 按类型和名称排序
    items.sort((a, b) {
      if (a['type'] == 'folder' && b['type'] != 'folder') return -1;
      if (a['type'] != 'folder' && b['type'] == 'folder') return 1;
      return (a['title'] as String).compareTo(b['title'] as String);
    });

    return items;
  }

  /// 外部调用：刷新某个目录的缓存（仅在缓存已构建时生效）
  static Future<void> refreshDirectoryCache(String directoryPath) async {
    await _refreshDirectoriesAfterChange({directoryPath});
  }

  static Future<void> _refreshDirectoriesAfterChange(
      Set<String> directoryPaths) async {
    if (directoryPaths.isEmpty) {
      await _updateLibraryModifiedTime();
      return;
    }

    try {
      final libraryDir = await getSubtitleLibraryDirectory();

      if (_cachedFileTree != null && _libraryRootPath != null) {
        final targets = directoryPaths
            .where((path) => path.startsWith(_libraryRootPath!))
            .toSet();

        for (final dir in targets) {
          await _refreshDirectorySnapshot(dir);
        }
      }

      await _updateLibraryModifiedTime(libraryDir);
    } catch (e) {
      print('[SubtitleLibrary] 局部刷新缓存失败: $e');
    }
  }

  static Future<void> _refreshDirectorySnapshot(String directoryPath) async {
    if (_cachedFileTree == null || _libraryRootPath == null) {
      return;
    }

    try {
      final directory = Directory(directoryPath);
      List<Map<String, dynamic>> newChildren = [];
      if (await directory.exists()) {
        newChildren = await _buildFileTree(directory, _libraryRootPath!);
      }

      final bool isRoot = directoryPath == _libraryRootPath;
      final List<Map<String, dynamic>>? oldChildren = isRoot
          ? _cachedFileTree
          : (_findNodeLocation(directoryPath, _cachedFileTree!)
              ?.node['children'] as List<Map<String, dynamic>>?);

      if (_cachedStats != null) {
        final oldStats = _calculateStatsForChildren(
          oldChildren,
          includeSelf: !isRoot && oldChildren != null,
        );
        final newStats = _calculateStatsForChildren(
          newChildren,
          includeSelf: !isRoot,
        );
        _applyStatsDelta(
          filesDelta: newStats.files - oldStats.files,
          foldersDelta: newStats.folders - oldStats.folders,
          sizeDelta: newStats.size - oldStats.size,
        );
      }

      if (isRoot) {
        _cachedFileTree = newChildren;
      } else {
        final location = _findNodeLocation(directoryPath, _cachedFileTree!);
        if (location == null) {
          final parentPath = FileSystemEntity.parentOf(directoryPath);
          if (parentPath != directoryPath) {
            await _refreshDirectorySnapshot(parentPath);
          }
          return;
        }
        location.node['children'] = newChildren;
      }
    } catch (e) {
      print('[SubtitleLibrary] 更新目录缓存失败: $e');
    }
  }

  /// 删除字幕文件或文件夹
  static Future<bool> delete(String path) async {
    try {
      final entity = FileSystemEntity.typeSync(path);

      if (entity == FileSystemEntityType.file) {
        await File(path).delete();
      } else if (entity == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else {
        return false;
      }

      print('[SubtitleLibrary] 已删除: $path');
      final parentPath = FileSystemEntity.parentOf(path);
      await _refreshDirectoriesAfterChange({parentPath});
      return true;
    } catch (e) {
      print('[SubtitleLibrary] 删除失败: $path, 错误: $e');
      return false;
    }
  }

  /// 重命名字幕文件或文件夹
  static Future<bool> rename(String oldPath, String newName) async {
    try {
      final entity = FileSystemEntity.typeSync(oldPath);
      final parentPath =
          oldPath.substring(0, oldPath.lastIndexOf(Platform.pathSeparator));
      final newPath = '$parentPath${Platform.pathSeparator}$newName';

      if (entity == FileSystemEntityType.file) {
        await File(oldPath).rename(newPath);
      } else if (entity == FileSystemEntityType.directory) {
        await Directory(oldPath).rename(newPath);
      } else {
        return false;
      }

      print('[SubtitleLibrary] 已重命名: $oldPath -> $newPath');
      await _refreshDirectoriesAfterChange({parentPath});
      return true;
    } catch (e) {
      print('[SubtitleLibrary] 重命名失败: $oldPath, 错误: $e');
      return false;
    }
  }

  /// 移动字幕文件或文件夹到指定目录
  static Future<bool> move(String sourcePath, String targetFolderPath) async {
    try {
      final entity = FileSystemEntity.typeSync(sourcePath);
      final fileName = sourcePath.split(Platform.pathSeparator).last;
      final newPath = '$targetFolderPath${Platform.pathSeparator}$fileName';

      // 检查目标路径是否与源路径相同
      if (sourcePath == newPath) {
        return true; // 无需移动
      }

      // 检查目标是否已存在
      final targetExists = await FileSystemEntity.isFile(newPath) ||
          await FileSystemEntity.isDirectory(newPath);

      if (entity == FileSystemEntityType.file) {
        if (targetExists && await FileSystemEntity.isFile(newPath)) {
          // 文件冲突：添加序号
          final nameWithoutExt = fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          final ext = fileName.contains('.')
              ? fileName.substring(fileName.lastIndexOf('.'))
              : '';
          int counter = 1;
          String finalPath;

          do {
            finalPath =
                '$targetFolderPath${Platform.pathSeparator}${nameWithoutExt}_$counter$ext';
            counter++;
          } while (await File(finalPath).exists());

          await File(sourcePath).rename(finalPath);
          print('[SubtitleLibrary] 文件已移动（重命名）: $sourcePath -> $finalPath');
        } else {
          await File(sourcePath).rename(newPath);
          print('[SubtitleLibrary] 文件已移动: $sourcePath -> $newPath');
        }
      } else if (entity == FileSystemEntityType.directory) {
        if (targetExists && await FileSystemEntity.isDirectory(newPath)) {
          // 文件夹冲突：合并内容
          print('[SubtitleLibrary] 检测到同名文件夹，开始合并: $sourcePath -> $newPath');
          await _mergeFolders(sourcePath, newPath);
          print('[SubtitleLibrary] 文件夹已合并: $sourcePath -> $newPath');
        } else {
          // 目标不存在或是文件，直接重命名
          await Directory(sourcePath).rename(newPath);
          print('[SubtitleLibrary] 文件夹已移动: $sourcePath -> $newPath');
        }
      } else {
        return false;
      }

      final sourceParent = FileSystemEntity.parentOf(sourcePath);
      await _refreshDirectoriesAfterChange({sourceParent, targetFolderPath});
      return true;
    } catch (e) {
      print('[SubtitleLibrary] 移动失败: $sourcePath, 错误: $e');
      return false;
    }
  }

  /// 合并两个文件夹（将源文件夹内容移动到目标文件夹）
  static Future<void> _mergeFolders(
      String sourceFolder, String targetFolder) async {
    final sourceDir = Directory(sourceFolder);
    final targetDir = Directory(targetFolder);

    if (!await sourceDir.exists()) return;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // 遍历源文件夹中的所有内容
    await for (final entity in sourceDir.list()) {
      final fileName = entity.path.split(Platform.pathSeparator).last;
      final targetPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

      if (entity is File) {
        // 处理文件
        if (await File(targetPath).exists()) {
          // 目标已存在文件，添加序号
          final nameWithoutExt = fileName.contains('.')
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          final ext = fileName.contains('.')
              ? fileName.substring(fileName.lastIndexOf('.'))
              : '';
          int counter = 1;
          String finalPath;

          do {
            finalPath =
                '${targetDir.path}${Platform.pathSeparator}${nameWithoutExt}_$counter$ext';
            counter++;
          } while (await File(finalPath).exists());

          await entity.copy(finalPath);
          await entity.delete();
        } else {
          await entity.rename(targetPath);
        }
      } else if (entity is Directory) {
        // 处理子文件夹（递归合并）
        if (await Directory(targetPath).exists()) {
          await _mergeFolders(entity.path, targetPath);
        } else {
          await entity.rename(targetPath);
        }
      }
    }

    // 删除源文件夹（应该已经为空）
    if (await sourceDir.exists()) {
      try {
        await sourceDir.delete();
      } catch (e) {
        print('[SubtitleLibrary] 删除空文件夹失败: $sourceFolder, 错误: $e');
      }
    }
  }

  /// 获取指定目录下的直接子文件夹（用于树形浏览）
  static Future<List<Map<String, dynamic>>> getSubFolders(
      String parentPath) async {
    final parentDir = Directory(parentPath);

    if (!await parentDir.exists()) {
      return [];
    }

    final folders = <Map<String, dynamic>>[];

    try {
      await for (final entity in parentDir.list(followLinks: false)) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          folders.add({
            'name': name,
            'path': entity.path,
          });
        }
      }
    } catch (e) {
      print('[SubtitleLibrary] 读取子文件夹失败: $parentPath, 错误: $e');
    }

    // 按名称排序
    folders
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    return folders;
  }

  /// 获取所有可用的目标文件夹（已废弃，性能问题）
  @Deprecated('Use getSubFolders for lazy loading instead')
  static Future<List<Map<String, dynamic>>> getAvailableFolders() async {
    final libraryDir = await getSubtitleLibraryDirectory();

    if (!await libraryDir.exists()) {
      return [];
    }

    final folders = <Map<String, dynamic>>[];

    // 添加根目录选项
    folders.add({
      'name': '根目录',
      'path': libraryDir.path,
    });

    await for (final entity
        in libraryDir.list(recursive: true, followLinks: false)) {
      if (entity is Directory) {
        final relativePath = entity.path.substring(libraryDir.path.length + 1);
        folders.add({
          'name': relativePath,
          'path': entity.path,
        });
      }
    }

    return folders;
  }

  /// 获取字幕库统计信息
  /// forceRefresh: 是否强制刷新，忽略缓存
  static Future<LibraryStats> getStats({bool forceRefresh = false}) async {
    final libraryDir = await getSubtitleLibraryDirectory();

    if (!await libraryDir.exists()) {
      return LibraryStats(
        totalFiles: 0,
        totalSize: 0,
        folderCount: 0,
      );
    }

    // 检查是否需要刷新缓存
    final hasChanged = await _hasDirectoryChanged(libraryDir);

    if (!forceRefresh && !hasChanged && _cachedStats != null) {
      print('[SubtitleLibrary] 使用缓存的统计信息');
      return _cachedStats!;
    }

    print('[SubtitleLibrary] 重新计算统计信息');
    int fileCount = 0;
    int folderCount = 0;
    int totalSize = 0;

    await for (final entity
        in libraryDir.list(recursive: true, followLinks: false)) {
      try {
        // 跳过路径过长的项
        if (entity.path.length > _maxPathLength) {
          continue;
        }

        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (FileIconUtils.isLyricFile(fileName)) {
            fileCount++;
            try {
              final stat = await entity.stat();
              totalSize += stat.size;
            } catch (e) {
              // 忽略无法读取的文件
            }
          }
        } else if (entity is Directory) {
          folderCount++;
        }
      } catch (e) {
        // 忽略单个文件/文件夹的错误
        continue;
      }
    }

    final stats = LibraryStats(
      totalFiles: fileCount,
      totalSize: totalSize,
      folderCount: folderCount,
    );

    // 更新缓存
    _cachedStats = stats;

    return stats;
  }

  static _TreeStats _calculateStatsForChildren(
      List<Map<String, dynamic>>? children,
      {bool includeSelf = false}) {
    final stats = _TreeStats();

    if (children != null) {
      for (final child in children) {
        final type = child['type'];
        if (type == 'text') {
          stats.files++;
          stats.size += (child['size'] as int?) ?? 0;
        } else if (type == 'folder') {
          stats.folders++;
          final nestedStats = _calculateStatsForChildren(
              child['children'] as List<Map<String, dynamic>>?);
          stats.files += nestedStats.files;
          stats.folders += nestedStats.folders;
          stats.size += nestedStats.size;
        }
      }
    }

    if (includeSelf) {
      stats.folders++;
    }

    return stats;
  }

  static void _applyStatsDelta({
    int filesDelta = 0,
    int foldersDelta = 0,
    int sizeDelta = 0,
  }) {
    if (_cachedStats == null) return;

    final newFiles = _cachedStats!.totalFiles + filesDelta;
    final newFolders = _cachedStats!.folderCount + foldersDelta;
    final newSize = _cachedStats!.totalSize + sizeDelta;

    _cachedStats = LibraryStats(
      totalFiles: newFiles < 0 ? 0 : newFiles,
      totalSize: newSize < 0 ? 0 : newSize,
      folderCount: newFolders < 0 ? 0 : newFolders,
    );
  }

  static _NodeLocation? _findNodeLocation(
      String path, List<Map<String, dynamic>> nodes) {
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      if (node['path'] == path) {
        return _NodeLocation(nodes, i);
      }

      if (node['type'] == 'folder') {
        final children = node['children'] as List<Map<String, dynamic>>?;
        if (children == null) continue;
        final result = _findNodeLocation(path, children);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  /// 缩短过长的路径
  /// 策略：保留文件名，缩短中间的目录名
  static String _shortenPath(String fullPath, String fileName) {
    try {
      final parts = fullPath.split(Platform.pathSeparator);
      if (parts.length <= 2) {
        return ''; // 无法再缩短
      }

      // 保留根路径和文件名，缩短中间部分
      final rootPart = parts[0];
      final middleParts = parts.sublist(1, parts.length - 1);

      // 缩短每个中间目录名到最多10个字符
      final shortenedMiddle = middleParts.map((part) {
        if (part.length > 10) {
          return part.substring(0, 10);
        }
        return part;
      }).toList();

      final newPath =
          [rootPart, ...shortenedMiddle, fileName].join(Platform.pathSeparator);

      // 如果还是太长，进一步缩短
      if (newPath.length > _maxPathLength) {
        // 只保留根路径和文件名
        return [rootPart, parts[1], fileName].join(Platform.pathSeparator);
      }

      return newPath;
    } catch (e) {
      print('[SubtitleLibrary] 路径缩短失败: $e');
      return '';
    }
  }

  /// 判断是否需要为压缩包创建新文件夹
  /// 规则：如果压缩包根目录只有一个文件夹且没有其他文件，则不需要创建；否则需要创建
  static bool _shouldCreateNewFolder(Archive archive) {
    // 统计根目录的项目
    final rootItems = <String>{};

    for (final file in archive.files) {
      if (!file.isFile && file.name.isEmpty) continue;

      // 获取根目录项（第一个路径分隔符之前的部分）
      final parts = file.name.split('/');
      if (parts.isEmpty) continue;

      // 如果是根目录的文件或文件夹
      if (parts.length == 1 && parts[0].isNotEmpty) {
        // 根目录有文件
        rootItems.add(parts[0]);
      } else if (parts.length > 1 && parts[0].isNotEmpty) {
        // 根目录有文件夹
        rootItems.add(parts[0]);
      }
    }

    // 如果根目录只有一个项目（文件夹），则不需要创建新文件夹
    // 如果有多个项目或者根目录有文件，则需要创建新文件夹
    return rootItems.length != 1;
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final String message;
  final int importedCount;
  final int errorCount;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
    this.errorCount = 0,
  });
}

/// 字幕库统计信息
class LibraryStats {
  final int totalFiles;
  final int totalSize;
  final int folderCount;

  LibraryStats({
    required this.totalFiles,
    required this.totalSize,
    required this.folderCount,
  });

  String get sizeFormatted {
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}

/// 导入统计（用于压缩包递归解压）
class _ImportStats {
  int successCount = 0;
  int errorCount = 0;
  int skippedCount = 0;
  int nestedArchiveCount = 0; // 嵌套压缩包数量
  int sizeErrorCount = 0; // 因文件过大被跳过的数量
  int depthErrorCount = 0; // 因嵌套过深被跳过的数量
  int decodeErrorCount = 0; // 解压失败的数量
}

class _TreeStats {
  int files = 0;
  int folders = 0;
  int size = 0;
}

class _NodeLocation {
  final List<Map<String, dynamic>> parentList;
  final int index;

  _NodeLocation(this.parentList, this.index);

  Map<String, dynamic> get node => parentList[index];
}
