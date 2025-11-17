import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'storage_service.dart';

/// 下载路径管理服务
class DownloadPathService {
  static const String _customPathKey = 'custom_download_path';

  /// 获取当前下载路径（自定义路径或默认路径）
  static Future<Directory> getDownloadDirectory() async {
    final customPath = StorageService.getString(_customPathKey);

    if (customPath != null && customPath.isNotEmpty) {
      final dir = Directory(customPath);
      if (await dir.exists()) {
        return dir;
      }
      // 自定义路径不存在，清除并使用默认路径
      await clearCustomPath();
    }

    return _getDefaultDownloadDirectory();
  }

  /// 获取默认下载路径
  static Future<Directory> _getDefaultDownloadDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir;
  }

  /// 获取自定义路径（如果设置了）
  static String? getCustomPath() {
    return StorageService.getString(_customPathKey);
  }

  /// 检查是否设置了自定义路径
  static bool hasCustomPath() {
    final path = StorageService.getString(_customPathKey);
    return path != null && path.isNotEmpty;
  }

  /// 清除自定义路径
  static Future<void> clearCustomPath() async {
    await StorageService.remove(_customPathKey);
  }

  /// 选择自定义下载目录
  /// 返回 null 表示用户取消选择
  /// 返回路径字符串表示成功
  static Future<String?> pickCustomDirectory() async {
    // 根据平台不同处理
    if (Platform.isAndroid) {
      return await _pickDirectoryAndroid();
    } else if (Platform.isIOS) {
      return await _pickDirectoryIOS();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return await _pickDirectoryDesktop();
    }
    return null;
  }

  /// Android 平台选择目录
  static Future<String?> _pickDirectoryAndroid() async {
    // Android 11+ 需要 MANAGE_EXTERNAL_STORAGE 权限
    if (await _requestStoragePermission()) {
      final result = await FilePicker.platform.getDirectoryPath();
      return result;
    }
    return null;
  }

  /// iOS 平台选择目录
  static Future<String?> _pickDirectoryIOS() async {
    // iOS 使用文档选择器
    final result = await FilePicker.platform.getDirectoryPath();
    return result;
  }

  /// 桌面平台（Windows/macOS/Linux）选择目录
  static Future<String?> _pickDirectoryDesktop() async {
    final result = await FilePicker.platform.getDirectoryPath();
    return result;
  }

  /// 请求存储权限（Android）
  static Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Android 13+ (API 33+) 使用新的权限模型
    if (Platform.version.contains('13') ||
        Platform.version.contains('14') ||
        Platform.version.contains('15')) {
      // Android 13+ 不再需要 MANAGE_EXTERNAL_STORAGE
      // 使用 scoped storage
      return true;
    }

    // Android 11-12 需要 MANAGE_EXTERNAL_STORAGE
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
    }

    if (!status.isGranted) {
      // 如果没有获得权限，尝试基本的存储权限
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
      return storageStatus.isGranted;
    }

    return status.isGranted;
  }

  /// 设置自定义下载路径并迁移文件
  /// 返回迁移结果消息
  static Future<MigrationResult> setCustomPath(String newPath) async {
    final newDir = Directory(newPath);

    // 确保新目录存在
    if (!await newDir.exists()) {
      try {
        await newDir.create(recursive: true);
      } catch (e) {
        return MigrationResult(
          success: false,
          message: '无法创建目录: $e',
        );
      }
    }

    // 获取当前下载目录
    final oldDir = await getDownloadDirectory();

    // 如果新旧路径相同，不需要迁移
    if (oldDir.path == newPath) {
      return MigrationResult(
        success: true,
        message: '目录未改变，无需迁移',
      );
    }

    // 执行文件迁移
    final migrationResult = await _migrateFiles(oldDir, newDir);

    if (migrationResult.success) {
      // 保存新路径
      await StorageService.setString(_customPathKey, newPath);
    }

    return migrationResult;
  }

  /// 将下载目录迁移回默认路径
  static Future<MigrationResult> migrateToDefaultPath() async {
    final currentDir = await getDownloadDirectory();
    final defaultDir = await _getDefaultDownloadDirectory();

    if (currentDir.path == defaultDir.path) {
      await clearCustomPath();
      return MigrationResult(
        success: true,
        message: '当前已使用默认路径',
      );
    }

    final result = await _migrateFiles(currentDir, defaultDir);

    if (result.success) {
      await clearCustomPath();
    }

    return result;
  }

  /// 迁移文件从旧目录到新目录
  static Future<MigrationResult> _migrateFiles(
    Directory oldDir,
    Directory newDir,
  ) async {
    try {
      // 检查旧目录是否存在
      if (!await oldDir.exists()) {
        return MigrationResult(
          success: true,
          message: '原目录不存在，无需迁移',
        );
      }

      int fileCount = 0;
      int folderCount = 0;
      int errorCount = 0;

      // 遍历旧目录中的所有文件和文件夹
      await for (final entity in oldDir.list(recursive: true)) {
        try {
          final relativePath = entity.path.substring(oldDir.path.length + 1);
          final newPath = '${newDir.path}/$relativePath';

          if (entity is File) {
            // 创建目标目录
            final newFile = File(newPath);
            await newFile.parent.create(recursive: true);

            // 复制文件
            await entity.copy(newPath);
            fileCount++;
          } else if (entity is Directory) {
            // 创建目录
            await Directory(newPath).create(recursive: true);
            folderCount++;
          }
        } catch (e) {
          print('[DownloadPath] 迁移失败: ${entity.path}, 错误: $e');
          errorCount++;
        }
      }

      // 迁移完成后删除旧目录
      try {
        await oldDir.delete(recursive: true);
      } catch (e) {
        print('[DownloadPath] 删除旧目录失败: $e');
        // 不影响迁移结果
      }

      return MigrationResult(
        success: true,
        message: '迁移完成: $fileCount 个文件, $folderCount 个文件夹'
            '${errorCount > 0 ? ', $errorCount 个错误' : ''}',
        fileCount: fileCount,
        errorCount: errorCount,
      );
    } catch (e) {
      return MigrationResult(
        success: false,
        message: '迁移失败: $e',
      );
    }
  }

  /// 检查平台是否支持自定义路径
  static bool isPlatformSupported() {
    // iOS 在沙盒限制下不建议支持自定义路径
    // 但可以通过文档选择器访问
    return Platform.isWindows ||
        Platform.isMacOS ||
        Platform.isAndroid ||
        Platform.isLinux;
  }

  /// 获取平台友好的提示信息
  static String getPlatformHint() {
    if (Platform.isAndroid) {
      return 'Android: 将使用系统文件选择器，可能需要存储权限';
    } else if (Platform.isIOS) {
      return 'iOS: 受系统沙盒限制，建议使用默认路径';
    } else if (Platform.isWindows) {
      return 'Windows: 可选择任意可访问的目录';
    } else if (Platform.isMacOS) {
      return 'macOS: 可选择任意可访问的目录';
    }
    return '选择一个用于保存下载文件的目录';
  }
}

/// 迁移结果
class MigrationResult {
  final bool success;
  final String message;
  final int fileCount;
  final int errorCount;

  MigrationResult({
    required this.success,
    required this.message,
    this.fileCount = 0,
    this.errorCount = 0,
  });
}
