import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:path/path.dart' as p;
import 'android_subtitle_directory_picker.dart';
import 'download_path_service.dart';
import 'log_service.dart';
import 'subtitle_database.dart';
import 'subtitle_library_rules.dart';
import 'subtitle_matching.dart';
import '../utils/file_icon_utils.dart';

/// 字幕库管理服务
class SubtitleLibraryService {
  static final _log = LogService.instance;
  static const String _libraryFolderName = 'subtitle_library';
  static const String _cacheFileName = 'library_cache.json';
  static const List<String> _supportedSubtitleExtensions = [
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
    'ttml',
  ];
  static const _androidDirectoryPicker = AndroidSubtitleDirectoryPicker();

  // Windows 路径长度限制 (保留一些余量)
  static const int _maxPathLength = SubtitleLibraryRules.maxPathLength;

  // 自动分配目录名称
  static const String parsedFolderName = SubtitleLibraryRules.parsedFolderName;
  static const String unknownFolderName =
      SubtitleLibraryRules.unknownFolderName;
  static const String savedFolderName = SubtitleLibraryRules.savedFolderName;

  // 数据库初始化标志
  static bool _dbInitialized = false;
  static Future<void>? _dbInitFuture;

  static final _cacheUpdateController = StreamController<void>.broadcast();
  static Stream<void> get onCacheUpdated => _cacheUpdateController.stream;

  static String _joinRelativePath(String rootPath, String relativePath) {
    final segments = relativePath
        .replaceAll('\\', '/')
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .where((segment) {
          final trimmed = segment.trim();
          return trimmed != '.' && trimmed != '..';
        })
        .map(
          (segment) => segment.replaceFirstMapped(
            RegExp(r'^([a-zA-Z]):'),
            (match) => '${match.group(1)}_',
          ),
        )
        .toList(growable: false);
    return segments.isEmpty ? rootPath : p.joinAll([rootPath, ...segments]);
  }

  /// 检查匹配结果
  /// 返回 (是否匹配, 相似度分数)
  static (bool, double) checkMatch(
      String subtitleFileName, String audioFileName) {
    return SubtitleMatcher.check(subtitleFileName, audioFileName).toRecord();
  }

  /// 检查字幕文件是否匹配音频文件
  /// [subtitleFileName] 字幕文件名（包含扩展名）
  /// [audioFileName] 音频文件名（包含扩展名）
  static bool isSubtitleForAudio(
      String subtitleFileName, String audioFileName) {
    return SubtitleMatcher.isSubtitleForAudio(subtitleFileName, audioFileName);
  }

  /// 移除音频文件扩展名
  static String removeAudioExtension(String fileName) {
    return SubtitleMatcher.removeAudioExtension(fileName);
  }

  /// 获取已解析目录下的所有文件夹名称
  static Future<List<String>> getParsedSubtitleFolders() async {
    try {
      await _ensureDatabase();
      return await SubtitleDatabase.instance
          .getParsedFolderNames(parsedFolderName);
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 获取已解析文件夹列表失败: $e');
      return [];
    }
  }

  /// 清除缓存并重建数据库索引
  static Future<void> clearCache() async {
    try {
      final libraryDir = await getSubtitleLibraryDirectory();

      // 删除旧版 JSON 缓存（如果存在）
      final cacheFile = File(p.join(libraryDir.path, _cacheFileName));
      if (await cacheFile.exists()) {
        await cacheFile.delete();
      }

      // 重建数据库
      await _rebuildDatabase(libraryDir);
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 重建索引失败: $e');
    }

    _log.captureOutput('[SubtitleLibrary] 索引已重建');
    _cacheUpdateController.add(null);
  }

  /// 确保数据库已初始化并完成迁移（供外部调用）
  static Future<void> ensureInitialized() => _ensureDatabase();

  /// 确保数据库已初始化并完成迁移
  static Future<void> _ensureDatabase() async {
    if (_dbInitialized) return;
    // 防止并发重复初始化
    _dbInitFuture ??= _initDatabase();
    await _dbInitFuture;
  }

  static Future<void> _initDatabase() async {
    if (_dbInitialized) return;

    final libraryDir = await getSubtitleLibraryDirectory();

    // 先执行旧格式文件夹迁移（纯文件系统操作）
    await _migrateOldFormatFolders(libraryDir);

    final version =
        await SubtitleDatabase.instance.getMeta('migration_version');

    if (version == null) {
      // 首次运行：尝试从 JSON 缓存快速迁移
      final cacheFile = File(p.join(libraryDir.path, _cacheFileName));
      if (await cacheFile.exists()) {
        try {
          _log.captureOutput('[SubtitleLibrary] 从 JSON 缓存迁移到数据库...');
          final content = await cacheFile.readAsString();
          final cacheData = jsonDecode(content) as Map<String, dynamic>;
          final tree = cacheData['fileTree'] as List<dynamic>?;
          if (tree != null && tree.isNotEmpty) {
            final records = <SubtitleFileRecord>[];
            _flattenTreeToRecords(tree, libraryDir.path, records);
            await SubtitleDatabase.instance.insertFiles(records);
            _log.captureOutput(
                '[SubtitleLibrary] JSON 迁移完成: ${records.length} 条记录');
          } else {
            // JSON 为空，扫描文件系统
            await _rebuildDatabase(libraryDir);
          }
          await cacheFile.delete();
        } catch (e) {
          _log.captureOutput('[SubtitleLibrary] JSON 迁移失败，回退到文件系统扫描: $e');
          await _rebuildDatabase(libraryDir);
        }
      } else {
        // 无 JSON 缓存，扫描文件系统
        final fileCount = await SubtitleDatabase.instance.getFileCount();
        if (fileCount == 0) {
          await _rebuildDatabase(libraryDir);
        }
      }
      await SubtitleDatabase.instance.setMeta('migration_version', '1');
    }

    _dbInitialized = true;
  }

  /// 重建数据库（清空后重新扫描文件系统）
  static Future<void> _rebuildDatabase(Directory libraryDir) async {
    await SubtitleDatabase.instance.clear();
    final records = <SubtitleFileRecord>[];
    await _scanDirectoryForRecords(libraryDir, libraryDir.path, records);
    if (records.isNotEmpty) {
      await SubtitleDatabase.instance.insertFiles(records);
    }
    _log.captureOutput('[SubtitleLibrary] 数据库重建完成: ${records.length} 条记录');
  }

  /// 扫描目录，收集字幕文件记录
  static Future<void> _scanDirectoryForRecords(
    Directory dir,
    String rootPath,
    List<SubtitleFileRecord> records,
  ) async {
    try {
      if (dir.path.length > _maxPathLength) return;

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          final folderName = entity.path.split(Platform.pathSeparator).last;
          // 跳过缓存文件和隐藏文件夹
          if (folderName.startsWith('.')) continue;
          await _scanDirectoryForRecords(entity, rootPath, records);
        } else if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (FileIconUtils.isLyricFile(fileName)) {
            try {
              final stat = await entity.stat();
              final relativePath =
                  _toRelativePath(entity.path.substring(rootPath.length + 1));
              final category = _extractCategory(relativePath);
              final workId = _extractWorkId(relativePath);

              records.add(SubtitleFileRecord(
                fileName: fileName,
                relativePath: relativePath,
                category: category,
                workId: workId,
                fileSize: stat.size,
                modifiedAt: stat.modified.toIso8601String(),
                normalizedName: _computeNormalizedName(fileName),
              ));
            } catch (e) {
              // 跳过无法读取的文件
            }
          }
        }
      }
    } catch (e) {
      if (e is FileSystemException ||
          e.toString().contains('PathNotFoundException') ||
          e.toString().contains('系统找不到指定的路径')) {
        _log.captureOutput(
            '[SubtitleLibrary] 路径过长导致访问失败，跳过: ${dir.path.split(Platform.pathSeparator).last}');
      } else {
        _log.captureOutput('[SubtitleLibrary] 扫描目录失败: ${dir.path}, 错误: $e');
      }
    }
  }

  /// 同步单个目录到数据库（删除旧记录 + 重新扫描）
  static Future<void> _syncDirectoryToDatabase(String directoryPath) async {
    final libraryDir = await getSubtitleLibraryDirectory();
    final libraryRoot = libraryDir.path;

    // 将绝对路径转换为相对路径前缀
    final relativePrefix = directoryPath.length > libraryRoot.length
        ? _toRelativePath(directoryPath.substring(libraryRoot.length + 1))
        : '';

    // 删除该目录下的旧记录
    if (relativePrefix.isNotEmpty) {
      await SubtitleDatabase.instance
          .deleteByRelativePathPrefix(relativePrefix);
    }

    // 如果目录仍存在，重新扫描并插入
    final dir = Directory(directoryPath);
    if (await dir.exists()) {
      final records = <SubtitleFileRecord>[];
      await _scanDirectoryForRecords(dir, libraryDir.path, records);
      if (records.isNotEmpty) {
        await SubtitleDatabase.instance.insertFiles(records);
      }
    }
  }

  /// 从 JSON 文件树展平为数据库记录（用于迁移）
  static void _flattenTreeToRecords(
    List<dynamic> tree,
    String rootPath,
    List<SubtitleFileRecord> records,
  ) {
    for (final item in tree) {
      final map = item as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (type == 'folder') {
        final children = map['children'];
        if (children != null) {
          _flattenTreeToRecords(children as List<dynamic>, rootPath, records);
        }
      } else if (type == 'text') {
        final filePath = map['path'] as String;
        final fileName = map['title'] as String;
        final relativePath =
            _toRelativePath(filePath.substring(rootPath.length + 1));
        final category = _extractCategory(relativePath);
        final workId = _extractWorkId(relativePath);

        records.add(SubtitleFileRecord(
          fileName: fileName,
          relativePath: relativePath,
          category: category,
          workId: workId,
          fileSize: (map['size'] as int?) ?? 0,
          modifiedAt: map['modified'] as String?,
          normalizedName: _computeNormalizedName(fileName),
        ));
      }
    }
  }

  /// 从相对路径提取分类
  static String _extractCategory(String relativePath) {
    final firstSlash = relativePath.indexOf('/');
    if (firstSlash > 0) {
      return relativePath.substring(0, firstSlash);
    }
    return '';
  }

  /// 从相对路径提取 workId
  static int? _extractWorkId(String relativePath) {
    final parts = relativePath.split('/');
    if (parts.length < 2) return null;
    final match = _workIdRegex.firstMatch(parts[1]);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }

  static final _workIdRegex = RegExp(r'[RrBbVv][Jj]0*(\d+)');

  /// 将平台路径分隔符统一为 / （用于数据库存储）
  static String _toRelativePath(String raw) {
    return Platform.isWindows ? raw.replaceAll('\\', '/') : raw;
  }

  /// 预计算归一化文件名（用于匹配加速）
  static String _computeNormalizedName(String fileName) {
    // 去掉字幕扩展名
    final textExtensions = ['.vtt', '.srt', '.txt', '.lrc'];
    String baseName = fileName.toLowerCase();
    for (final ext in textExtensions) {
      if (baseName.endsWith(ext)) {
        baseName = baseName.substring(0, baseName.length - ext.length);
        break;
      }
    }
    baseName = removeAudioExtension(baseName);
    return SubtitleMatcher.normalizeForMatching(baseName);
  }

  /// 从数据库记录构建文件树（用于 UI 展示）
  static List<Map<String, dynamic>> _buildTreeFromRecords(
    List<Map<String, dynamic>> records,
    String libraryRootPath,
  ) {
    // 使用嵌套 Map 构建树结构
    final rootChildren = <String, dynamic>{};

    for (final record in records) {
      final relativePath = record['relative_path'] as String;
      final parts = relativePath.split('/');

      Map<String, dynamic> current = rootChildren;
      var currentFullPath = libraryRootPath;

      // 遍历路径的每一级目录
      for (int i = 0; i < parts.length - 1; i++) {
        currentFullPath =
            '$currentFullPath${Platform.pathSeparator}${parts[i]}';
        if (!current.containsKey(parts[i])) {
          current[parts[i]] = <String, dynamic>{
            '_meta': {
              'type': 'folder',
              'title': parts[i],
              'path': currentFullPath,
            },
            '_children': <String, dynamic>{},
          };
        }
        current = (current[parts[i]] as Map<String, dynamic>)['_children']
            as Map<String, dynamic>;
      }

      // 添加文件叶节点
      final fileName = parts.last;
      current[fileName] = <String, dynamic>{
        '_meta': {
          'type': 'text',
          'title': fileName,
          'path': '$currentFullPath${Platform.pathSeparator}$fileName',
          'size': record['file_size'] as int?,
          'modified': record['modified_at'] as String?,
        },
      };
    }

    return _convertNodeMapToList(rootChildren);
  }

  /// 将嵌套 Map 转换为 UI 期望的 List 格式
  static List<Map<String, dynamic>> _convertNodeMapToList(
    Map<String, dynamic> nodeMap,
  ) {
    final items = <Map<String, dynamic>>[];

    for (final entry in nodeMap.entries) {
      final node = entry.value as Map<String, dynamic>;
      final meta = node['_meta'] as Map<String, dynamic>;

      if (meta['type'] == 'folder') {
        final childrenMap = node['_children'] as Map<String, dynamic>?;
        if (childrenMap != null && childrenMap.isNotEmpty) {
          final children = _convertNodeMapToList(childrenMap);
          if (children.isNotEmpty) {
            items.add({
              'type': 'folder',
              'title': meta['title'],
              'path': meta['path'],
              'children': children,
            });
          }
        }
      } else {
        items.add(Map<String, dynamic>.from(meta));
      }
    }

    // 排序：文件夹在前，然后按名称排序
    items.sort((a, b) {
      if (a['type'] == 'folder' && b['type'] != 'folder') return -1;
      if (a['type'] != 'folder' && b['type'] == 'folder') return 1;
      return (a['title'] as String).compareTo(b['title'] as String);
    });

    return items;
  }

  /// 获取字幕库目录
  static Future<Directory> getSubtitleLibraryDirectory() async {
    final downloadDir = await DownloadPathService.getDownloadDirectory();
    final libraryDir = Directory(p.join(downloadDir.path, _libraryFolderName));

    // 如果不存在则自动创建
    if (!await libraryDir.exists()) {
      await libraryDir.create(recursive: true);
      _log.captureOutput('[SubtitleLibrary] 创建字幕库目录: ${libraryDir.path}');
    }

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
        allowedExtensions: _supportedSubtitleExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: '未选择文件',
        );
      }

      final libraryDir = await getSubtitleLibraryDirectory();

      // 创建"已保存"文件夹
      final savedDir = Directory(p.join(libraryDir.path, savedFolderName));
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
        _log.captureOutput('[SubtitleLibrary] 创建"已保存"文件夹: ${savedDir.path}');
      }

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
          final destFile = File(p.join(savedDir.path, fileName));

          // 如果文件已存在，添加序号
          String finalFileName = fileName;
          int counter = 1;
          File finalDestFile = destFile;

          while (await finalDestFile.exists()) {
            final nameWithoutExt =
                fileName.substring(0, fileName.lastIndexOf('.'));
            final ext = fileName.substring(fileName.lastIndexOf('.'));
            finalFileName = '${nameWithoutExt}_$counter$ext';
            finalDestFile = File(p.join(savedDir.path, finalFileName));
            counter++;
          }

          await sourceFile.copy(finalDestFile.path);
          successCount++;
          _log.captureOutput('[SubtitleLibrary] 导入字幕文件到"已保存": $finalFileName');
        } catch (e) {
          errorCount++;
          errorFiles.add('$fileName ($e)');
          _log.captureOutput('[SubtitleLibrary] 导入文件失败: $fileName, 错误: $e');
        }
      }

      // 刷新"已保存"文件夹缓存
      final savedDirPath = p.join(libraryDir.path, savedFolderName);
      await _refreshDirectoriesAfterChange({savedDirPath});

      String message = '成功导入 $successCount 个字幕文件到"已保存"文件夹';
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

  /// 导入文件夹（递归检查子目录，自动分配路径）
  /// [onProgress] - 进度回调，参数为当前进度消息
  static Future<ImportResult> importFolder(
      {Function(String)? onProgress}) async {
    AndroidSubtitleDirectorySelection? androidSelection;
    try {
      final String? directoryPath;
      if (Platform.isAndroid) {
        androidSelection = await _androidDirectoryPicker.pick(
          allowedExtensions: _supportedSubtitleExtensions,
        );
        directoryPath = androidSelection?.path;
      } else {
        directoryPath = await FilePicker.platform.getDirectoryPath();
      }

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

      int totalSuccess = 0;
      int totalError = 0;
      int totalSkipped = 0;
      int parsedFolderCount = 0;
      int unknownFolderCount = 0;

      onProgress?.call('正在扫描文件夹结构...');

      // 检查根目录本身是否匹配规则（例如用户选择的就是 RJ123456 文件夹）
      final rootFolderName = sourceDir.path.split(Platform.pathSeparator).last;
      Map<String, int> result;
      final Set<String> modifiedPaths = {};

      if (_matchFolderPattern(rootFolderName)) {
        // 根目录匹配规则：将整个目录作为一个作品导入到"已解析"
        onProgress?.call('正在处理: $rootFolderName');

        final folderName = _normalizeFolderName(rootFolderName);
        const targetCategory = parsedFolderName;
        final targetDir =
            Directory(p.join(libraryDir.path, targetCategory, folderName));

        // 检查目标路径长度
        if (targetDir.path.length > _maxPathLength) {
          return ImportResult(
            success: false,
            message: '目标路径过长，无法导入: $folderName (${targetDir.path.length} 字符)',
          );
        }

        // 检查目标文件夹是否已存在，如果存在则合并（复制并替换）
        if (await targetDir.exists()) {
          _log.captureOutput(
              '[SubtitleLibrary] 检测到同名文件夹，合并并替换同名文件: $folderName');
          result = await _mergeAndCopyFolder(sourceDir, targetDir,
              onProgress: onProgress);
          parsedFolderCount = 1;
          modifiedPaths.add(targetDir.path);
          _log.captureOutput(
              '[SubtitleLibrary] 已合并根目录文件夹: $folderName，导入 ${result['successCount']} 个字幕文件');
        } else {
          result = await _copyDirectoryWithFilter(
            sourceDir,
            targetDir,
            onProgress: onProgress,
          );
          parsedFolderCount = 1;
          modifiedPaths.add(targetDir.path);
          _log.captureOutput(
              '[SubtitleLibrary] 已解析根目录文件夹: $folderName, 字幕文件: ${result['successCount']}');
        }
      } else {
        // 根目录不匹配规则：递归处理子目录
        result = await _processFolderRecursively(
          sourceDir,
          sourceDir,
          libraryDir,
          onProgress: onProgress,
          modifiedPaths: modifiedPaths,
        );
        parsedFolderCount = result['parsedCount'] ?? 0;
        unknownFolderCount = result['unknownCount'] ?? 0;
      }

      totalSuccess = result['successCount'] ?? 0;
      totalError =
          (result['errorCount'] ?? 0) + (androidSelection?.errorCount ?? 0);
      totalSkipped =
          (result['skippedCount'] ?? 0) + (androidSelection?.skippedCount ?? 0);

      if (totalSuccess == 0) {
        return ImportResult(
          success: false,
          message: '文件夹中没有找到字幕文件',
        );
      }

      String message = '成功导入 $totalSuccess 个字幕文件';
      if (parsedFolderCount > 0) {
        message += '\n已解析: $parsedFolderCount 个文件夹';
      }
      if (unknownFolderCount > 0) {
        message += '\n未知作品: $unknownFolderCount 个文件夹';
      }
      if (totalSkipped > 0) {
        message += '\n跳过 $totalSkipped 个非字幕文件';
      }
      if (totalError > 0) {
        message += '\n失败 $totalError 个';
      }

      // 刷新相关文件夹缓存
      if (modifiedPaths.isNotEmpty) {
        onProgress?.call('正在刷新缓存...');
        await _refreshDirectoriesAfterChange(modifiedPaths,
            onProgress: onProgress);
      } else {
        // 如果没有收集到具体路径（异常情况），回退到刷新整个分类
        final parsedDirPath = p.join(libraryDir.path, parsedFolderName);
        final unknownDirPath = p.join(libraryDir.path, unknownFolderName);
        onProgress?.call('正在刷新缓存...');
        await _refreshDirectoriesAfterChange({parsedDirPath, unknownDirPath},
            onProgress: onProgress);
      }

      return ImportResult(
        success: true,
        message: message,
        importedCount: totalSuccess,
        errorCount: totalError,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: '导入文件夹失败: $e',
      );
    } finally {
      final selection = androidSelection;
      if (selection != null) {
        try {
          await _androidDirectoryPicker.release(selection.token);
        } catch (e) {
          _log.captureOutput('[SubtitleLibrary] 清理 Android 导入缓存失败: $e');
        }
      }
    }
  }

  /// 导入压缩包（支持多层嵌套解压）
  /// [onProgress] - 进度回调，参数为当前进度消息
  static Future<ImportResult> importArchive(
      {Function(String)? onProgress}) async {
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

      // 先验证压缩包格式
      try {
        if (platformFile.extension == 'zip') {
          ZipDecoder().decodeBytes(bytes, verify: false);
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

      // 创建临时目录用于解压
      final tempDir = Directory(
        p.join(
          libraryDir.path,
          '.temp_${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
      await tempDir.create(recursive: true);

      // 创建导入统计器
      final stats = _ImportStats();
      final Set<String> modifiedPaths = {};

      try {
        // 智能判断是否需要为根压缩包创建文件夹
        // 如果压缩包名符合 RJ 号格式，且内容不是已经包含在同名文件夹中，则创建文件夹
        final zipName = platformFile.name;
        final zipNameWithoutExt = zipName.replaceAll(
            RegExp(r'\.(zip|rar|7z)$', caseSensitive: false), '');

        String relativePath = '';

        // 只有当压缩包名符合 RJ 号格式时才进行智能判断
        if (_matchFolderPattern(zipNameWithoutExt)) {
          Archive? rootArchive;
          try {
            // 重新解码一次用于检查结构（虽然有性能损耗，但为了正确性是值得的）
            // 注意：这里假设是 ZIP，前面已经检查过
            if (platformFile.extension == 'zip') {
              rootArchive = ZipDecoder().decodeBytes(bytes, verify: false);
            }
          } catch (e) {
            _log.captureOutput('[SubtitleLibrary] 检查压缩包结构失败: $e');
          }

          if (rootArchive != null) {
            final shouldCreate =
                _shouldCreateNewFolder(rootArchive, zipNameWithoutExt);
            if (shouldCreate) {
              relativePath = zipNameWithoutExt;
              _log.captureOutput(
                  '[SubtitleLibrary] 根压缩包符合 RJ 格式且内容分散，将解压到: $relativePath');
            }
          }
        }

        // 先解压到临时目录
        onProgress?.call('正在解压压缩包...');
        _log.captureOutput('[SubtitleLibrary] 解压到临时目录: ${tempDir.path}');
        await _processArchiveBytes(
          bytes,
          platformFile.extension ?? 'zip',
          tempDir.path,
          relativePath,
          stats,
          depth: 0,
          onProgress: onProgress,
        );

        // 递归处理临时目录，按规则分配到目标位置
        onProgress?.call('正在分类和移动文件...');
        final result = await _processFolderRecursively(
          tempDir,
          tempDir,
          libraryDir,
          onProgress: onProgress,
          modifiedPaths: modifiedPaths,
        );

        // 更新统计信息
        stats.successCount = result['successCount'] ?? 0;
        stats.errorCount = result['errorCount'] ?? 0;
        stats.skippedCount = result['skippedCount'] ?? 0;
        final parsedCount = result['parsedCount'] ?? 0;
        final unknownCount = result['unknownCount'] ?? 0;

        _log.captureOutput(
            '[SubtitleLibrary] 已解析: $parsedCount 个文件夹, 未知作品: $unknownCount 个文件夹');
      } finally {
        // 清理临时目录
        onProgress?.call('正在清理临时文件...');
        try {
          if (await tempDir.exists()) {
            await _deleteDirectoryWithProgress(tempDir, onProgress);
            _log.captureOutput('[SubtitleLibrary] 清理临时目录完成');
          }
        } catch (e) {
          _log.captureOutput('[SubtitleLibrary] 清理临时目录失败: $e');
        }
      }

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

      // 刷新相关文件夹缓存
      if (modifiedPaths.isNotEmpty) {
        onProgress?.call('正在刷新缓存...');
        await _refreshDirectoriesAfterChange(modifiedPaths,
            onProgress: onProgress);
      } else {
        // 如果没有收集到具体路径（异常情况），回退到刷新整个分类
        final parsedDirPath = p.join(libraryDir.path, parsedFolderName);
        final unknownDirPath = p.join(libraryDir.path, unknownFolderName);
        onProgress?.call('正在刷新缓存...');
        await _refreshDirectoriesAfterChange({parsedDirPath, unknownDirPath},
            onProgress: onProgress);
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
    Function(String)? onProgress,
  }) async {
    // 防止无限递归：最大深度限制
    const maxDepth = 10;
    if (depth > maxDepth) {
      _log.captureOutput('[SubtitleLibrary] 警告: 压缩包嵌套深度超过 $maxDepth 层，停止解压');
      stats.errorCount++;
      stats.depthErrorCount++;
      return;
    }

    // 内存保护：单个嵌套压缩包大小限制 (1GB)
    const maxFileSize = 1024 * 1024 * 1024; // 1GB
    if (bytes.length > maxFileSize) {
      final sizeInMB = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      _log.captureOutput('[SubtitleLibrary] 警告: 嵌套压缩包过大 ($sizeInMB MB)，跳过');
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
        _log.captureOutput('[SubtitleLibrary] 不支持的压缩格式: $extension');
        stats.skippedCount++;
        return;
      }
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 解压失败 (depth=$depth): $e');
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
          _log.captureOutput(
              '[SubtitleLibrary] 文件过大，跳过: $decodedName ($sizeInMB MB)');
          stats.sizeErrorCount++;
          stats.skippedCount++;
          continue;
        }
      } catch (e) {
        _log.captureOutput('[SubtitleLibrary] 读取文件内容失败: $decodedName, 错误: $e');
        stats.errorCount++;
        continue;
      }

      // 判断是否是嵌套的压缩包
      if (fileExtension == 'zip') {
        _log.captureOutput(
            '[SubtitleLibrary] 发现嵌套压缩包 (depth=${depth + 1}): $decodedName');
        stats.nestedArchiveCount++;

        // 先解析嵌套压缩包以判断是否需要创建文件夹
        Archive? nestedArchive;
        try {
          nestedArchive = ZipDecoder().decodeBytes(content, verify: false);
        } catch (e) {
          _log.captureOutput(
              '[SubtitleLibrary] 解析嵌套压缩包失败: $decodedName, 错误: $e');
          stats.decodeErrorCount++;
          stats.errorCount++;
          continue;
        }

        // 智能判断是否需要为嵌套压缩包创建文件夹
        final zipNameWithoutExt =
            decodedName.replaceAll(RegExp(r'\.zip$', caseSensitive: false), '');
        final shouldCreateFolder =
            _shouldCreateNewFolder(nestedArchive, zipNameWithoutExt);

        // 根据智能判断决定相对路径
        final nestedRelativePath = shouldCreateFolder
            ? (relativePath.isEmpty
                ? zipNameWithoutExt
                : '$relativePath/$zipNameWithoutExt')
            : relativePath; // 不创建文件夹时使用当前相对路径

        _log.captureOutput(
            '[SubtitleLibrary] 嵌套压缩包${shouldCreateFolder ? "需要创建文件夹" : "直接解压"}: $zipNameWithoutExt');

        // 递归处理嵌套压缩包
        await _processArchiveBytes(
          content,
          'zip',
          targetBasePath,
          nestedRelativePath,
          stats,
          depth: depth + 1,
          onProgress: onProgress,
        );
        continue;
      }

      // 处理字幕文件
      if (FileIconUtils.isLyricFile(fileName)) {
        try {
          final fullRelativePath =
              relativePath.isEmpty ? decodedName : '$relativePath/$decodedName';
          var targetFilePath =
              _joinRelativePath(targetBasePath, fullRelativePath);

          // 检查路径长度，如果过长则缩短
          if (targetFilePath.length > _maxPathLength) {
            targetFilePath = _shortenPath(targetFilePath, fileName);
            if (targetFilePath.isEmpty) {
              _log.captureOutput('[SubtitleLibrary] 路径过长无法缩短，跳过: $decodedName');
              stats.skippedCount++;
              continue;
            }
          }

          final targetFile = File(targetFilePath);

          await targetFile.parent.create(recursive: true);

          // 如果目标文件已存在，直接覆盖
          if (await targetFile.exists()) {
            _log.captureOutput('[SubtitleLibrary] 替换同名文件: $fileName');
          }

          await targetFile.writeAsBytes(content);
          stats.successCount++;

          // 每10个文件显示一次进度
          if (stats.successCount % 10 == 0) {
            onProgress?.call('已解压 ${stats.successCount} 个字幕文件...');
          }

          _log.captureOutput(
              '[SubtitleLibrary] 解压字幕 (depth=$depth): ${targetFile.path.substring(targetBasePath.length)}');
        } catch (e) {
          stats.errorCount++;
          _log.captureOutput('[SubtitleLibrary] 写入文件失败: $decodedName, 错误: $e');
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

    // 确保数据库已初始化
    await _ensureDatabase();

    // 强制刷新：先迁移旧格式，再重建数据库
    if (forceRefresh) {
      await _migrateOldFormatFolders(libraryDir);
      await _rebuildDatabase(libraryDir);
    }

    // 从数据库查询所有记录并构建树
    final records = await SubtitleDatabase.instance.getAllFiles();
    return _buildTreeFromRecords(records, libraryDir.path);
  }

  /// 外部调用：刷新某个目录的缓存
  static Future<void> refreshDirectoryCache(String directoryPath) async {
    await _refreshDirectoriesAfterChange({directoryPath});
  }

  static Future<void> _refreshDirectoriesAfterChange(Set<String> directoryPaths,
      {Function(String)? onProgress}) async {
    if (directoryPaths.isEmpty) return;

    try {
      // 如果变更目录过多，整体重建
      if (directoryPaths.length > 50) {
        _log.captureOutput(
            '[SubtitleLibrary] 变更文件夹数量过多 (${directoryPaths.length})，切换为全量重建');
        onProgress?.call('正在重建索引...');
        final libraryDir = await getSubtitleLibraryDirectory();
        await _rebuildDatabase(libraryDir);
      } else {
        int count = 0;
        final total = directoryPaths.length;
        for (final dirPath in directoryPaths) {
          count++;
          if (total > 5 && onProgress != null) {
            onProgress('正在刷新索引: $count/$total');
          }
          await _syncDirectoryToDatabase(dirPath);
        }
      }
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 刷新索引失败: $e');
    }

    _cacheUpdateController.add(null);
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

      _log.captureOutput('[SubtitleLibrary] 已删除: $path');
      final parentPath = FileSystemEntity.parentOf(path);
      await _refreshDirectoriesAfterChange({parentPath});
      return true;
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 删除失败: $path, 错误: $e');
      return false;
    }
  }

  /// 重命名字幕文件或文件夹
  static Future<bool> rename(String oldPath, String newName) async {
    try {
      final entity = FileSystemEntity.typeSync(oldPath);
      final parentPath = p.dirname(oldPath);
      final newPath = p.join(parentPath, newName);

      if (entity == FileSystemEntityType.file) {
        await File(oldPath).rename(newPath);
      } else if (entity == FileSystemEntityType.directory) {
        await Directory(oldPath).rename(newPath);
      } else {
        return false;
      }

      _log.captureOutput('[SubtitleLibrary] 已重命名: $oldPath -> $newPath');
      await _refreshDirectoriesAfterChange({parentPath});
      return true;
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 重命名失败: $oldPath, 错误: $e');
      return false;
    }
  }

  /// 移动字幕文件或文件夹到指定目录
  static Future<bool> move(String sourcePath, String targetFolderPath) async {
    try {
      final entity = FileSystemEntity.typeSync(sourcePath);
      final fileName = p.basename(sourcePath);
      final newPath = p.join(targetFolderPath, fileName);

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
                p.join(targetFolderPath, '${nameWithoutExt}_$counter$ext');
            counter++;
          } while (await File(finalPath).exists());

          await File(sourcePath).rename(finalPath);
          _log.captureOutput(
              '[SubtitleLibrary] 文件已移动（重命名）: $sourcePath -> $finalPath');
        } else {
          await File(sourcePath).rename(newPath);
          _log.captureOutput(
              '[SubtitleLibrary] 文件已移动: $sourcePath -> $newPath');
        }
      } else if (entity == FileSystemEntityType.directory) {
        if (targetExists && await FileSystemEntity.isDirectory(newPath)) {
          // 文件夹冲突：合并内容
          _log.captureOutput(
              '[SubtitleLibrary] 检测到同名文件夹，开始合并: $sourcePath -> $newPath');
          await _mergeFolders(sourcePath, newPath);
          _log.captureOutput(
              '[SubtitleLibrary] 文件夹已合并: $sourcePath -> $newPath');
        } else {
          // 目标不存在或是文件，直接重命名
          await Directory(sourcePath).rename(newPath);
          _log.captureOutput(
              '[SubtitleLibrary] 文件夹已移动: $sourcePath -> $newPath');
        }
      } else {
        return false;
      }

      final sourceParent = FileSystemEntity.parentOf(sourcePath);
      await _refreshDirectoriesAfterChange({sourceParent, targetFolderPath});
      return true;
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 移动失败: $sourcePath, 错误: $e');
      return false;
    }
  }

  /// 合并两个文件夹（将源文件夹内容移动到目标文件夹）
  /// 用于移动操作，会删除源文件夹，同名文件直接替换
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
      final targetPath = p.join(targetDir.path, fileName);

      if (entity is File) {
        // 处理文件：直接替换
        if (await File(targetPath).exists()) {
          await File(targetPath).delete();
          _log.captureOutput('[SubtitleLibrary] 替换同名文件: $fileName');
        }
        await entity.rename(targetPath);
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
        _log.captureOutput('[SubtitleLibrary] 删除空文件夹失败: $sourceFolder, 错误: $e');
      }
    }
  }

  /// 合并并复制文件夹（用于导入，不删除源文件夹，同名文件直接替换）
  /// 返回统计信息：successCount, errorCount, skippedCount
  static Future<Map<String, int>> _mergeAndCopyFolder(
    Directory sourceDir,
    Directory targetDir, {
    Function(String)? onProgress,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    int skippedCount = 0;

    try {
      await for (final entity
          in sourceDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;

          if (!FileIconUtils.isLyricFile(fileName)) {
            skippedCount++;
            continue;
          }

          try {
            final relativePath =
                entity.path.substring(sourceDir.path.length + 1);
            var targetFilePath =
                _joinRelativePath(targetDir.path, relativePath);

            // 检查路径长度，如果过长则缩短
            if (targetFilePath.length > _maxPathLength) {
              targetFilePath = _shortenPath(targetFilePath, fileName);
              if (targetFilePath.isEmpty) {
                _log.captureOutput(
                    '[SubtitleLibrary] 路径过长无法缩短，跳过: $relativePath');
                skippedCount++;
                continue;
              }
            }

            final targetFile = File(targetFilePath);
            await targetFile.parent.create(recursive: true);

            // 如果目标文件已存在，直接替换
            if (await targetFile.exists()) {
              _log.captureOutput('[SubtitleLibrary] 替换同名文件: $fileName');
            }

            await entity.copy(targetFile.path);
            successCount++;

            // 每10个文件显示一次进度
            if (successCount % 10 == 0) {
              onProgress?.call('已处理 $successCount 个字幕文件...');
            }
          } catch (e) {
            errorCount++;
            _log.captureOutput('[SubtitleLibrary] 复制文件失败: $fileName, 错误: $e');
          }
        }
      }
    } catch (e) {
      _log.captureOutput(
          '[SubtitleLibrary] 合并复制目录失败: ${sourceDir.path}, 错误: $e');
      errorCount++;
    }

    return {
      'successCount': successCount,
      'errorCount': errorCount,
      'skippedCount': skippedCount,
    };
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
      _log.captureOutput('[SubtitleLibrary] 读取子文件夹失败: $parentPath, 错误: $e');
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
  /// forceRefresh: 是否强制刷新，重新扫描文件系统
  static Future<LibraryStats> getStats({bool forceRefresh = false}) async {
    final libraryDir = await getSubtitleLibraryDirectory();

    if (!await libraryDir.exists()) {
      return LibraryStats(
        totalFiles: 0,
        totalSize: 0,
        folderCount: 0,
      );
    }

    // 确保数据库已初始化
    await _ensureDatabase();

    if (forceRefresh) {
      await _rebuildDatabase(libraryDir);
    }

    // 从数据库查询统计
    final raw = await SubtitleDatabase.instance.getStatsRaw();
    final totalFiles = raw['totalFiles'] ?? 0;
    final totalSize = raw['totalSize'] ?? 0;
    final folderCount = await SubtitleDatabase.instance.getFolderCount();

    return LibraryStats(
      totalFiles: totalFiles,
      totalSize: totalSize,
      folderCount: folderCount,
    );
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
      _log.captureOutput('[SubtitleLibrary] 路径缩短失败: $e');
      return '';
    }
  }

  /// 递归处理文件夹，识别并分配到相应目录
  /// 返回统计信息：successCount, errorCount, skippedCount, parsedCount, unknownCount
  static Future<Map<String, int>> _processFolderRecursively(
    Directory currentDir,
    Directory rootDir,
    Directory libraryDir, {
    Function(String)? onProgress,
    Set<String>? modifiedPaths,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    int skippedCount = 0;
    int parsedCount = 0;
    int unknownCount = 0;

    try {
      // 获取当前目录下的所有直接子项
      final List<FileSystemEntity> entities = [];
      await for (final entity in currentDir.list(followLinks: false)) {
        entities.add(entity);
      }

      // 分类子项
      final List<Directory> subDirs = [];
      final List<File> files = [];

      for (final entity in entities) {
        if (entity is Directory) {
          subDirs.add(entity);
        } else if (entity is File) {
          files.add(entity);
        }
      }

      // 如果当前目录有子目录，递归处理它们
      for (final subDir in subDirs) {
        final originalFolderName =
            subDir.path.split(Platform.pathSeparator).last;

        // 检查子目录名是否匹配规则
        if (_matchFolderPattern(originalFolderName)) {
          // 标准化文件夹名
          final folderName = _normalizeFolderName(originalFolderName);

          // 匹配规则：整个子目录移动到"已解析"
          const targetCategory = parsedFolderName;
          final targetDir =
              Directory(p.join(libraryDir.path, targetCategory, folderName));

          // 检查目标路径长度
          if (targetDir.path.length > _maxPathLength) {
            _log.captureOutput(
                '[SubtitleLibrary] 目标路径过长，跳过文件夹: $folderName (${targetDir.path.length} 字符)');
            errorCount++;
            continue;
          }

          onProgress?.call('正在处理: $folderName');

          // 检查目标文件夹是否已存在，如果存在则合并（复制并替换）
          if (await targetDir.exists()) {
            _log.captureOutput(
                '[SubtitleLibrary] 检测到同名文件夹，合并并替换同名文件: $folderName');
            final result = await _mergeAndCopyFolder(subDir, targetDir,
                onProgress: onProgress);
            successCount += result['successCount'] ?? 0;
            errorCount += result['errorCount'] ?? 0;
            skippedCount += result['skippedCount'] ?? 0;
            parsedCount++;
            modifiedPaths?.add(targetDir.path);
            _log.captureOutput(
                '[SubtitleLibrary] 已合并文件夹: $folderName，导入 ${result['successCount']} 个字幕文件');
          } else {
            final result = await _copyDirectoryWithFilter(
              subDir,
              targetDir,
              onProgress: onProgress,
            );
            successCount += result['successCount'] ?? 0;
            errorCount += result['errorCount'] ?? 0;
            skippedCount += result['skippedCount'] ?? 0;
            parsedCount++;
            modifiedPaths?.add(targetDir.path);

            _log.captureOutput(
                '[SubtitleLibrary] 已解析文件夹: $folderName, 字幕文件: ${result['successCount']}');
          }
        } else {
          // 不匹配规则：递归检查子目录内部
          final subResult = await _processFolderRecursively(
            subDir,
            rootDir,
            libraryDir,
            onProgress: onProgress,
            modifiedPaths: modifiedPaths,
          );
          successCount += subResult['successCount'] ?? 0;
          errorCount += subResult['errorCount'] ?? 0;
          skippedCount += subResult['skippedCount'] ?? 0;
          parsedCount += subResult['parsedCount'] ?? 0;
          unknownCount += subResult['unknownCount'] ?? 0;

          // 如果子目录没有匹配的子文件夹，但有字幕文件，放入"未知作品"
          if ((subResult['parsedCount'] ?? 0) == 0) {
            final hasSubtitles = await _hasSubtitleFiles(subDir);
            if (hasSubtitles) {
              final folderName = originalFolderName; // 未知作品不需要标准化
              const targetCategory = unknownFolderName;
              final targetDir = Directory(
                  p.join(libraryDir.path, targetCategory, folderName));

              // 检查目标路径长度
              if (targetDir.path.length > _maxPathLength) {
                _log.captureOutput(
                    '[SubtitleLibrary] 目标路径过长，跳过文件夹: $folderName (${targetDir.path.length} 字符)');
                errorCount++;
                continue;
              }

              onProgress?.call('正在处理: $folderName');

              // 检查目标文件夹是否已存在，如果存在则合并（复制并替换）
              if (await targetDir.exists()) {
                _log.captureOutput(
                    '[SubtitleLibrary] 检测到同名文件夹，合并并替换同名文件: $folderName');
                final result = await _mergeAndCopyFolder(subDir, targetDir,
                    onProgress: onProgress);
                successCount += result['successCount'] ?? 0;
                errorCount += result['errorCount'] ?? 0;
                skippedCount += result['skippedCount'] ?? 0;
                unknownCount++;
                modifiedPaths?.add(targetDir.path);
                _log.captureOutput(
                    '[SubtitleLibrary] 已合并未知作品: $folderName，导入 ${result['successCount']} 个字幕文件');
              } else {
                final result = await _copyDirectoryWithFilter(
                  subDir,
                  targetDir,
                  onProgress: onProgress,
                );
                successCount += result['successCount'] ?? 0;
                errorCount += result['errorCount'] ?? 0;
                skippedCount += result['skippedCount'] ?? 0;
                unknownCount++;
                modifiedPaths?.add(targetDir.path);

                _log.captureOutput(
                    '[SubtitleLibrary] 未知作品: $folderName, 字幕文件: ${result['successCount']}');
              }
            }
          }
        }
      }

      // 如果当前目录有直接的字幕文件（根目录散落的文件）
      if (files.isNotEmpty && currentDir.path == rootDir.path) {
        for (final file in files) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          if (FileIconUtils.isLyricFile(fileName)) {
            try {
              const targetCategory = unknownFolderName;
              final targetDir =
                  Directory(p.join(libraryDir.path, targetCategory));
              await targetDir.create(recursive: true);

              var targetFilePath = p.join(targetDir.path, fileName);

              // 检查路径长度
              if (targetFilePath.length > _maxPathLength) {
                targetFilePath = _shortenPath(targetFilePath, fileName);
                if (targetFilePath.isEmpty) {
                  _log.captureOutput(
                      '[SubtitleLibrary] 根目录文件路径过长，跳过: $fileName');
                  skippedCount++;
                  continue;
                }
              }

              final targetFile = File(targetFilePath);
              await file.copy(targetFile.path);
              successCount++;
              _log.captureOutput('[SubtitleLibrary] 根目录文件: $fileName');
            } catch (e) {
              errorCount++;
              _log.captureOutput(
                  '[SubtitleLibrary] 复制根目录文件失败: $fileName, 错误: $e');
            }
          } else {
            skippedCount++;
          }
        }
      }
    } catch (e) {
      _log.captureOutput(
          '[SubtitleLibrary] 处理目录失败: ${currentDir.path}, 错误: $e');
      errorCount++;
    }

    return {
      'successCount': successCount,
      'errorCount': errorCount,
      'skippedCount': skippedCount,
      'parsedCount': parsedCount,
      'unknownCount': unknownCount,
    };
  }

  /// 检查目录是否包含字幕文件
  static Future<bool> _hasSubtitleFiles(Directory dir) async {
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (FileIconUtils.isLyricFile(fileName)) {
            return true;
          }
        }
      }
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 检查字幕文件失败: ${dir.path}, 错误: $e');
    }
    return false;
  }

  /// 复制目录并过滤非字幕文件
  static Future<Map<String, int>> _copyDirectoryWithFilter(
    Directory sourceDir,
    Directory targetDir, {
    Function(String)? onProgress,
  }) async {
    int successCount = 0;
    int errorCount = 0;
    int skippedCount = 0;

    try {
      await for (final entity
          in sourceDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;

          if (!FileIconUtils.isLyricFile(fileName)) {
            skippedCount++;
            continue;
          }

          try {
            final relativePath =
                entity.path.substring(sourceDir.path.length + 1);
            var targetFilePath =
                _joinRelativePath(targetDir.path, relativePath);

            // 检查路径长度，如果过长则缩短
            if (targetFilePath.length > _maxPathLength) {
              targetFilePath = _shortenPath(targetFilePath, fileName);
              if (targetFilePath.isEmpty) {
                _log.captureOutput(
                    '[SubtitleLibrary] 路径过长无法缩短，跳过: $relativePath');
                skippedCount++;
                continue;
              }
            }

            final targetFile = File(targetFilePath);

            await targetFile.parent.create(recursive: true);

            // 如果目标文件已存在，直接覆盖
            if (await targetFile.exists()) {
              _log.captureOutput('[SubtitleLibrary] 替换同名文件: $fileName');
            }

            await entity.copy(targetFile.path);
            successCount++;

            // 每10个文件显示一次进度
            if (successCount % 10 == 0) {
              onProgress?.call('已处理 $successCount 个字幕文件...');
            }
          } catch (e) {
            errorCount++;
            _log.captureOutput('[SubtitleLibrary] 复制文件失败: $fileName, 错误: $e');
          }
        }
      }
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 复制目录失败: ${sourceDir.path}, 错误: $e');
      errorCount++;
    }

    return {
      'successCount': successCount,
      'errorCount': errorCount,
      'skippedCount': skippedCount,
    };
  }

  /// 匹配文件夹名称模式
  /// 支持：RJ/BJ/VJ + 6-8位数字，或纯6-8位数字（不区分大小写）
  static bool _matchFolderPattern(String folderName) {
    return SubtitleLibraryRules.matchesWorkFolderName(folderName);
  }

  /// 向前兼容：迁移根目录的旧格式文件夹到"已解析"
  /// 纯文件系统操作，不依赖数据库
  static Future<void> _migrateOldFormatFolders(Directory libraryDir) async {
    try {
      final parsedFolderPath = p.join(libraryDir.path, parsedFolderName);
      final parsedFolder = Directory(parsedFolderPath);

      // 确保"已解析"文件夹存在
      if (!await parsedFolder.exists()) {
        await parsedFolder.create(recursive: true);
      }

      int migratedCount = 0;

      // 扫描根目录的直接子文件夹
      await for (final entity in libraryDir.list(followLinks: false)) {
        if (entity is Directory) {
          final folderName = entity.path.split(Platform.pathSeparator).last;

          // 跳过系统文件夹
          if (folderName == parsedFolderName ||
              folderName == unknownFolderName ||
              folderName == savedFolderName ||
              folderName.startsWith('.')) {
            continue;
          }

          // 检查是否匹配旧格式（RJ/BJ/VJ + 数字，或纯数字）
          if (_matchFolderPattern(folderName)) {
            // 标准化文件夹名
            final normalizedName = _normalizeFolderName(folderName);
            final targetPath = p.join(parsedFolderPath, normalizedName);

            _log.captureOutput(
                '[SubtitleLibrary] 迁移旧格式文件夹: $folderName -> 已解析/$normalizedName');

            try {
              if (await Directory(targetPath).exists()) {
                // 同名文件夹已存在，合并内容
                await _mergeFolders(entity.path, targetPath);
              } else {
                await entity.rename(targetPath);
              }
              migratedCount++;
            } catch (e) {
              _log.captureOutput('[SubtitleLibrary] 迁移文件夹失败: $folderName, $e');
            }
          }
        }
      }

      if (migratedCount > 0) {
        _log.captureOutput(
            '[SubtitleLibrary] 成功迁移 $migratedCount 个旧格式文件夹到"已解析"');
      }
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 迁移旧格式文件夹失败: $e');
    }
  }

  /// 标准化文件夹名称
  /// 规则：
  /// 1. 如果是小写的 rj/bj/vj 开头，转换为大写 RJ/BJ/VJ
  /// 2. 如果是纯6-8位数字，添加 RJ 前缀
  /// 3. 其他情况保持不变
  static String _normalizeFolderName(String folderName) {
    final normalized = SubtitleLibraryRules.normalizeWorkFolderName(folderName);
    if (normalized != folderName) {
      _log.captureOutput(
          '[SubtitleLibrary] 标准化文件夹名: $folderName -> $normalized');
    }
    return normalized;
  }

  /// 判断是否需要为压缩包创建新文件夹
  /// 规则：
  /// 1. 如果根目录有多个项，需要创建
  /// 2. 如果根目录只有一个文件夹，但文件夹名与ZIP名不同，也需要创建
  /// 3. 如果根目录只有一个文件夹，且文件夹名与ZIP名相同，不需要创建
  static bool _shouldCreateNewFolder(Archive archive, String zipName) {
    final rootItems = SubtitleLibraryRules.archiveRootItems(archive);
    final shouldCreate =
        SubtitleLibraryRules.shouldCreateNewFolder(rootItems, zipName);

    if (rootItems.length == 1 && shouldCreate) {
      _log.captureOutput(
          '[SubtitleLibrary] 压缩包内文件夹名 "${rootItems.first}" 与 ZIP 名 "$zipName" 不同，创建文件夹');
    } else if (rootItems.length == 1) {
      _log.captureOutput('[SubtitleLibrary] 压缩包内文件夹名与 ZIP 名相同，直接解压');
    }

    return shouldCreate;
  }

  /// 递归删除目录并显示进度
  static Future<void> _deleteDirectoryWithProgress(
      Directory dir, Function(String)? onProgress) async {
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          await _deleteDirectoryWithProgress(entity, onProgress);
        } else {
          await entity.delete();
        }
      }

      final folderName = dir.path.split(RegExp(r'[/\\]')).last;
      // 避免显示顶层临时目录名，只显示实际的内容文件夹
      if (!folderName.startsWith('.temp_')) {
        onProgress?.call('正在清理临时文件: $folderName');
      }

      await dir.delete();
    } catch (e) {
      _log.captureOutput('[SubtitleLibrary] 删除失败: ${dir.path}, $e');
    }
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
