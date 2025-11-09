import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class CacheService {
  // 缓存时长
  static const Duration workDetailCacheDuration = Duration(hours: 24);
  static const Duration fileCacheDuration = Duration(days: 7);

  // 缓存大小上限配置键
  static const String cacheSizeLimitKey = 'cache_size_limit_mb';
  static const int defaultCacheSizeLimitMB = 1024; // 默认1GB (1024MB)

  // 自动清理检查间隔（避免过于频繁检查）
  static const Duration autoCleanCheckInterval = Duration(minutes: 5);
  static const String lastCleanCheckTimeKey = 'last_clean_check_time';

  // 缓存作品详情
  static Future<void> cacheWorkDetail(
      int workId, Map<String, dynamic> workData) async {
    final prefs = await StorageService.getPrefs();
    final cacheKey = 'work_detail_$workId';
    final cacheTimeKey = 'work_detail_time_$workId';

    await prefs.setString(cacheKey, workData.toString());
    await prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  // 获取缓存的作品详情
  static Future<Map<String, dynamic>?> getCachedWorkDetail(int workId) async {
    final prefs = await StorageService.getPrefs();
    final cacheKey = 'work_detail_$workId';
    final cacheTimeKey = 'work_detail_time_$workId';

    final cachedData = prefs.getString(cacheKey);
    final cacheTime = prefs.getInt(cacheTimeKey);

    if (cachedData == null || cacheTime == null) {
      return null;
    }

    // 检查是否过期
    final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
    if (DateTime.now().difference(cacheDateTime) > workDetailCacheDuration) {
      // 过期，删除缓存
      await prefs.remove(cacheKey);
      await prefs.remove(cacheTimeKey);
      return null;
    }

    // 返回缓存数据（这里简化处理，实际应该使用JSON）
    return {'cached': true};
  }

  // 缓存文件资源（图片、PDF等）
  static Future<String?> cacheFileResource({
    required int workId,
    required String hash,
    required String fileType,
    required String url,
    required Dio dio,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = '${workId}_${hash}_$fileType';
      final filePath = '${cacheDir.path}/$fileName';

      // 如果文件已存在，检查是否过期
      final file = File(filePath);
      if (await file.exists()) {
        final lastModified = await file.lastModified();
        if (DateTime.now().difference(lastModified) < fileCacheDuration) {
          return filePath; // 未过期，直接返回
        }
        // 过期，删除旧文件
        await file.delete();
      }

      // 下载文件
      await dio.download(url, filePath);

      // 保存缓存元数据
      final prefs = await StorageService.getPrefs();
      final metaKey = 'file_cache_meta_${workId}_$hash';
      await prefs.setInt(metaKey, DateTime.now().millisecondsSinceEpoch);

      // 检查并自动清理缓存
      await checkAndCleanCache();

      return filePath;
    } catch (e) {
      print('[Cache] 缓存文件失败: $e');
      return null;
    }
  }

  // 获取缓存的文件资源
  static Future<String?> getCachedFileResource({
    required int workId,
    required String hash,
    required String fileType,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = '${workId}_${hash}_$fileType';
      final filePath = '${cacheDir.path}/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        // 检查是否过期
        final prefs = await StorageService.getPrefs();
        final metaKey = 'file_cache_meta_${workId}_$hash';
        final cacheTime = prefs.getInt(metaKey);

        if (cacheTime != null) {
          final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
          if (DateTime.now().difference(cacheDateTime) < fileCacheDuration) {
            return filePath; // 未过期
          }
        }

        // 过期，删除
        await file.delete();
        await prefs.remove(metaKey);
      }

      return null;
    } catch (e) {
      print('[Cache] 获取缓存文件失败: $e');
      return null;
    }
  }

  // 缓存文本内容
  static Future<void> cacheTextContent({
    required int workId,
    required String hash,
    required String content,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = '${workId}_${hash}_text.txt';
      final filePath = '${cacheDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(content);

      // 保存缓存元数据
      final prefs = await StorageService.getPrefs();
      final metaKey = 'text_cache_meta_${workId}_$hash';
      await prefs.setInt(metaKey, DateTime.now().millisecondsSinceEpoch);

      // 检查并自动清理缓存
      await checkAndCleanCache();
    } catch (e) {
      print('[Cache] 缓存文本失败: $e');
    }
  }

  // 获取缓存的文本内容
  static Future<String?> getCachedTextContent({
    required int workId,
    required String hash,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = '${workId}_${hash}_text.txt';
      final filePath = '${cacheDir.path}/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        // 检查是否过期
        final prefs = await StorageService.getPrefs();
        final metaKey = 'text_cache_meta_${workId}_$hash';
        final cacheTime = prefs.getInt(metaKey);

        if (cacheTime != null) {
          final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
          if (DateTime.now().difference(cacheDateTime) < fileCacheDuration) {
            return await file.readAsString(); // 未过期
          }
        }

        // 过期，删除
        await file.delete();
        await prefs.remove(metaKey);
      }

      return null;
    } catch (e) {
      print('[Cache] 获取缓存文本失败: $e');
      return null;
    }
  }

  // 清除所有缓存
  static Future<void> clearAllCache() async {
    try {
      // 清除文件缓存
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      // 清除 SharedPreferences 中的缓存元数据
      final prefs = await StorageService.getPrefs();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('work_detail_') ||
            key.startsWith('file_cache_meta_') ||
            key.startsWith('text_cache_meta_')) {
          await prefs.remove(key);
        }
      }

      print('[Cache] 所有缓存已清除');
    } catch (e) {
      print('[Cache] 清除缓存失败: $e');
      rethrow;
    }
  }

  // 获取缓存大小
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      print('[Cache] 获取缓存大小失败: $e');
      return 0;
    }
  }

  // 获取缓存目录
  static Future<Directory> _getCacheDirectory() async {
    final appCacheDir = await getApplicationCacheDirectory();
    final cacheDir = Directory('${appCacheDir.path}/kikoeru_cache');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  // 设置缓存大小上限（MB）
  static Future<void> setCacheSizeLimit(int limitMB) async {
    final prefs = await StorageService.getPrefs();
    await prefs.setInt(cacheSizeLimitKey, limitMB);
  }

  // 获取缓存大小上限（MB）
  static Future<int> getCacheSizeLimit() async {
    final prefs = await StorageService.getPrefs();
    return prefs.getInt(cacheSizeLimitKey) ?? defaultCacheSizeLimitMB;
  }

  // 检查并自动清理缓存（如果超过上限）
  // 使用时间间隔控制，避免过于频繁检查
  static Future<void> checkAndCleanCache({bool force = false}) async {
    try {
      // 如果不是强制检查，先判断是否需要检查
      if (!force) {
        final prefs = await StorageService.getPrefs();
        final lastCheckTime = prefs.getInt(lastCleanCheckTimeKey);

        if (lastCheckTime != null) {
          final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
          final timeSinceLastCheck = DateTime.now().difference(lastCheck);

          // 如果距离上次检查不到5分钟，跳过检查
          if (timeSinceLastCheck < autoCleanCheckInterval) {
            return;
          }
        }

        // 更新最后检查时间
        await prefs.setInt(
            lastCleanCheckTimeKey, DateTime.now().millisecondsSinceEpoch);
      }

      final currentSize = await getCacheSize();
      final limitMB = await getCacheSizeLimit();
      final limitBytes = limitMB * 1024 * 1024;

      if (currentSize > limitBytes) {
        print(
            '[Cache] 缓存大小 ${_formatBytes(currentSize)} 超过上限 ${limitMB}MB，开始清理...');
        await _cleanOldCacheFiles(limitBytes);
      }
    } catch (e) {
      print('[Cache] 自动清理缓存失败: $e');
    }
  }

  // 清理旧缓存文件，直到降低到上限的80%
  static Future<void> _cleanOldCacheFiles(int limitBytes) async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return;
      }

      final targetSize = (limitBytes * 0.8).toInt();

      // 获取所有缓存文件及其修改时间
      final List<MapEntry<File, DateTime>> fileList = [];
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          final lastModified = await entity.lastModified();
          fileList.add(MapEntry(entity, lastModified));
        }
      }

      // 按修改时间排序（旧的在前）
      fileList.sort((a, b) => a.value.compareTo(b.value));

      // 计算当前总大小
      int currentSize = 0;
      for (final entry in fileList) {
        currentSize += await entry.key.length();
      }

      // 删除旧文件直到降低到目标大小
      int deletedCount = 0;
      for (final entry in fileList) {
        if (currentSize <= targetSize) {
          break;
        }

        final fileSize = await entry.key.length();
        await entry.key.delete();
        currentSize -= fileSize;
        deletedCount++;

        // 删除对应的元数据
        final fileName = entry.key.path.split(Platform.pathSeparator).last;
        await _removeMetadataForFile(fileName);
      }

      print(
          '[Cache] 已删除 $deletedCount 个旧缓存文件，当前大小: ${_formatBytes(currentSize)}');
    } catch (e) {
      print('[Cache] 清理旧缓存文件失败: $e');
    }
  }

  // 删除文件对应的元数据
  static Future<void> _removeMetadataForFile(String fileName) async {
    try {
      final prefs = await StorageService.getPrefs();

      // 从文件名解析出 workId 和 hash
      // 文件名格式: {workId}_{hash}_{fileType}
      final parts = fileName.split('_');
      if (parts.length >= 2) {
        final workId = parts[0];
        final hash = parts[1];

        // 删除可能的元数据键
        await prefs.remove('file_cache_meta_${workId}_$hash');
        await prefs.remove('text_cache_meta_${workId}_$hash');
      }
    } catch (e) {
      print('[Cache] 删除元数据失败: $e');
    }
  }

  // 格式化字节大小为可读字符串
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  // 获取格式化的缓存大小字符串
  static Future<String> getFormattedCacheSize() async {
    final size = await getCacheSize();
    return _formatBytes(size);
  }
}
