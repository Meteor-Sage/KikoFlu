import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/download_task.dart';
import '../utils/file_icon_utils.dart';
import 'cache_service.dart';
import 'storage_service.dart';
import 'kikoeru_api_service.dart';
import 'download_path_service.dart';
import 'download_file_path_service.dart';
import 'local_work_metadata_service.dart';
import 'log_service.dart';

final _log = LogService.instance;

class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService._();

  DownloadService._();

  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, Future<void>> _runningDownloads = {};
  // Prevent two rapid addTask calls for the same file from both passing the
  // duplicate check while either call is waiting on the cache/filesystem.
  final Map<String, Future<DownloadTask>> _pendingTaskAdds = {};
  final StreamController<List<DownloadTask>> _tasksController =
      StreamController<List<DownloadTask>>.broadcast();
  final List<DownloadTask> _tasks = [];
  final Dio _dio = Dio();
  final LocalWorkMetadataService _localMetadataService =
      const LocalWorkMetadataService();

  // 并发下载控制
  static const int _maxConcurrentDownloads = 20;
  int _activeDownloadCount = 0;
  bool _isProcessingQueue = false;

  // 用于延迟保存任务，避免频繁 I/O 操作
  Timer? _saveTimer;
  bool _needsSave = false;

  Stream<List<DownloadTask>> get tasksStream => _tasksController.stream;
  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  // 获取正在下载或等待下载的任务数量
  int get activeDownloadCount => _tasks
      .where(
        (task) =>
            task.status == DownloadStatus.downloading ||
            task.status == DownloadStatus.pending,
      )
      .length;

  // 检查是否有任务正在下载
  bool get hasActiveDownloads => activeDownloadCount > 0;

  static const String _tasksKey = 'download_tasks';

  Future<void> initialize() async {
    await _loadTasks();
    // 恢复未完成的下载任务
    for (final task in _tasks) {
      if (task.status == DownloadStatus.downloading) {
        _updateTask(task.copyWith(status: DownloadStatus.paused));
      }
    }
    // 启动时从硬盘完全同步任务（静默执行）
    try {
      await reloadMetadataFromDisk();
      _log.info('启动时同步完成', tag: 'Download');
    } catch (e) {
      _log.error('启动时同步失败: $e', tag: 'Download');
      // 同步失败则保持当前状态，等待用户手动刷新
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    // 使用 DownloadPathService 获取下载目录（支持自定义路径）
    return await DownloadPathService.getDownloadDirectory();
  }

  // 公开方法，用于获取下载根目录
  Future<Directory> getDownloadDirectory() async {
    return _getDownloadDirectory();
  }

  Future<String> _getWorkDownloadDirectory(int workId) async {
    final downloadDir = await _getDownloadDirectory();
    final workDir = Directory(p.join(downloadDir.path, workId.toString()));
    if (!await workDir.exists()) {
      await workDir.create(recursive: true);
    }
    return workDir.path;
  }

  File _workMetadataFile(Directory workDir) {
    return File(
      p.join(workDir.path, LocalWorkMetadataService.metadataFileName),
    );
  }

  Directory _workDirectoryForMetadata(
    Directory downloadDir,
    int workId,
    Map<String, dynamic>? metadata,
  ) {
    final localDirName =
        metadata?[LocalWorkMetadataService.localWorkDirNameKey];
    if (localDirName is String && localDirName.trim().isNotEmpty) {
      final relativeDir = DownloadFilePathService.normalizeRelativePath(
        localDirName,
      );
      if (relativeDir.isNotEmpty) {
        return Directory(
          DownloadFilePathService.localPathForRelativePath(
            rootPath: downloadDir.path,
            relativePath: relativeDir,
          ),
        );
      }
    }

    return Directory(p.join(downloadDir.path, workId.toString()));
  }

  Future<Directory> getWorkDirectory(
    int workId, {
    Map<String, dynamic>? metadata,
  }) async {
    final downloadDir = await _getDownloadDirectory();
    if (metadata != null) {
      return _workDirectoryForMetadata(downloadDir, workId, metadata);
    }

    final loadedMetadata = await _loadWorkMetadata(workId);
    return _workDirectoryForMetadata(downloadDir, workId, loadedMetadata);
  }

  String? localCoverPathForMetadata(
    Directory workDir,
    Map<String, dynamic>? metadata,
  ) {
    final relativeCoverPath = metadata?['localCoverPath'];
    if (relativeCoverPath is! String || relativeCoverPath.trim().isEmpty) {
      return null;
    }

    return DownloadFilePathService.localPathForRelativePath(
      rootPath: workDir.path,
      relativePath: relativeCoverPath,
    );
  }

  Future<void> _ensureDirectoryWritable(Directory directory) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final probe = File(
      p.join(
        directory.path,
        '.kikoflu_write_test_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    try {
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
    } catch (e) {
      throw FileSystemException(
        '无法写入下载目录，请检查外置存储权限或重新选择下载路径',
        directory.path,
        e is FileSystemException ? e.osError : null,
      );
    }
  }

  // 下载封面图片到本地
  Future<String?> _downloadCoverImage(
    int workId,
    String coverUrl, {
    String? workDirPath,
  }) async {
    try {
      final workDir = workDirPath ?? await _getWorkDownloadDirectory(workId);
      final coverFile = File(
        DownloadFilePathService.localPathForRelativePath(
          rootPath: workDir,
          relativePath: 'cover.jpg',
        ),
      );

      // 如果已存在则不重复下载
      if (await coverFile.exists()) {
        return coverFile.path;
      }

      // 下载图片
      _dio.options.headers.addAll(StorageService.serverCookieHeaders);
      await _dio.download(coverUrl, coverFile.path);
      return coverFile.path;
    } catch (e) {
      _log.error('下载封面图片失败: $e', tag: 'Download');
      return null;
    }
  }

  // 保存作品元数据到硬盘。元数据先落盘，封面再后台补齐，避免封面请求影响离线详情。
  Future<void> _saveWorkMetadata(
    int workId,
    Map<String, dynamic> metadata,
    String? coverUrl,
  ) async {
    try {
      final workDir = Directory(await _getWorkDownloadDirectory(workId));
      final metadataToSave = Map<String, dynamic>.from(metadata);
      if (_metadataIdAsPositiveInt(metadataToSave['id']) == null) {
        metadataToSave['id'] = workId;
      }
      metadataToSave[LocalWorkMetadataService.localWorkDirNameKey] = p.basename(
        workDir.path,
      );

      final metadataFile = _workMetadataFile(workDir);
      await metadataFile.writeAsString(jsonEncode(metadataToSave), flush: true);
      _log.debug(
        '已保存作品元数据: workId=$workId, path=${metadataFile.path}, '
        'children=${(metadataToSave['children'] as List?)?.length ?? 0}',
        tag: 'Download',
      );

      if (coverUrl != null && coverUrl.isNotEmpty) {
        unawaited(
          _saveCoverForMetadata(
            workId: workId,
            workDir: workDir,
            coverUrl: coverUrl,
            metadata: metadataToSave,
          ),
        );
      }
    } catch (e) {
      _log.error('保存作品元数据失败: $e', tag: 'Download');
    }
  }

  Future<void> _saveCoverForMetadata({
    required int workId,
    required Directory workDir,
    required String coverUrl,
    required Map<String, dynamic> metadata,
  }) async {
    final localCoverPath = await _downloadCoverImage(
      workId,
      coverUrl,
      workDirPath: workDir.path,
    );
    if (localCoverPath == null) return;

    try {
      final updatedMetadata = Map<String, dynamic>.from(metadata)
        ..['localCoverPath'] = 'cover.jpg';
      await _workMetadataFile(
        workDir,
      ).writeAsString(jsonEncode(updatedMetadata), flush: true);
      _log.debug('已更新作品封面元数据: workId=$workId', tag: 'Download');
    } catch (e) {
      _log.error('更新作品封面元数据失败: $e', tag: 'Download');
    }
  }

  // 从硬盘读取作品元数据
  Future<Map<String, dynamic>?> _loadWorkMetadata(int workId) async {
    try {
      final workDir = await _findExistingWorkDirectory(workId);
      if (workDir == null) {
        _log.warning('未找到作品目录，无法加载元数据: workId=$workId', tag: 'Download');
        return null;
      }

      final metadataFile = _workMetadataFile(workDir);

      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final metadata = jsonDecode(content) as Map<String, dynamic>;
        if (_metadataIdAsPositiveInt(metadata['id']) == null) {
          metadata['id'] = workId;
        }
        metadata[LocalWorkMetadataService.localWorkDirNameKey] = p.basename(
          workDir.path,
        );
        _log.debug(
          '已从磁盘加载元数据: workId=$workId, dir=${p.basename(workDir.path)}, '
          'metadataId=${metadata['id']}, sourceId=${metadata['source_id']}, '
          'children=${(metadata['children'] as List?)?.length ?? 0}',
          tag: 'Download',
        );

        // 迁移旧的绝对路径为相对路径
        if (metadata.containsKey('localCoverPath')) {
          final coverPath = metadata['localCoverPath'] as String?;
          if (coverPath != null && p.isAbsolute(coverPath)) {
            // 如果包含路径分隔符，说明是绝对路径，转换为相对路径
            metadata['localCoverPath'] = 'cover.jpg';
            // 保存更新后的元数据
            await metadataFile.writeAsString(jsonEncode(metadata));
            _log.info('已迁移作品 $workId 的封面路径为相对路径', tag: 'Download');
          }
        }

        return metadata;
      }
      _log.warning(
        '作品目录存在但缺少 work_metadata.json: workId=$workId, dir=${workDir.path}',
        tag: 'Download',
      );
    } catch (e) {
      _log.error('读取作品元数据失败: $e', tag: 'Download');
    }
    return null;
  }

  Future<Directory?> _findExistingWorkDirectory(int workId) async {
    final downloadDir = await _getDownloadDirectory();
    if (!await downloadDir.exists()) {
      _log.warning('下载根目录不存在: ${downloadDir.path}', tag: 'Download');
      return null;
    }

    Directory? fallback;
    await for (final entity in downloadDir.list(followLinks: false)) {
      if (entity is! Directory) continue;

      final parsed = _localMetadataService.parseWorkFolder(entity);
      if (parsed?.id != workId) continue;

      if (p.basename(entity.path) == workId.toString()) {
        _log.debug(
          '匹配作品目录: workId=$workId, dir=${entity.path}, exact=true',
          tag: 'Download',
        );
        return entity;
      }
      fallback ??= entity;
    }

    if (fallback != null) {
      _log.debug(
        '匹配作品目录: workId=$workId, dir=${fallback.path}, exact=false',
        tag: 'Download',
      );
    }
    return fallback;
  }

  int? _metadataIdAsPositiveInt(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  // 获取作品元数据（公共方法，优先从内存读取，否则从硬盘读取）
  Future<Map<String, dynamic>?> getWorkMetadata(int workId) async {
    // 先尝试从任务中获取
    final task = _tasks.firstWhere(
      (t) => t.workId == workId && t.workMetadata != null,
      orElse: () => DownloadTask(
        id: '',
        workId: 0,
        workTitle: '',
        fileName: '',
        downloadUrl: '',
        createdAt: DateTime.now(),
      ),
    );

    if (task.id.isNotEmpty && task.workMetadata != null) {
      _log.debug(
        '从内存任务获取元数据: workId=$workId, task=${task.id}, '
        'metadataId=${task.workMetadata?['id']}, sourceId=${task.workMetadata?['source_id']}',
        tag: 'Download',
      );
      return task.workMetadata;
    }

    // 如果内存中没有，从硬盘读取
    _log.info('内存任务无元数据，尝试从磁盘恢复: workId=$workId', tag: 'Download');
    return await _loadWorkMetadata(workId);
  }

  String _taskIdentity({
    required int workId,
    required String? hash,
    required String fileName,
  }) {
    final normalizedHash = hash?.trim();
    if (normalizedHash != null && normalizedHash.isNotEmpty) {
      return '$workId:hash:$normalizedHash';
    }
    // Hash-less files still need a stable identity. The previous null-hash
    // comparison treated every file in a work as the same task.
    return '$workId:path:$fileName';
  }

  String _taskIdentityForTask(DownloadTask task) {
    return _taskIdentity(
      workId: task.workId,
      hash: task.hash,
      fileName: task.fileName,
    );
  }

  DownloadTask? _findTask({
    required int workId,
    required String? hash,
    required String fileName,
  }) {
    final identity = _taskIdentity(
      workId: workId,
      hash: hash,
      fileName: fileName,
    );
    for (final task in _tasks) {
      if (_taskIdentityForTask(task) == identity) return task;
    }
    return null;
  }

  // 添加下载任务
  Future<DownloadTask> addTask({
    required int workId,
    required String workTitle,
    required String fileName,
    required String downloadUrl,
    required String? hash,
    int? totalBytes,
    Map<String, dynamic>? workMetadata,
    String? coverUrl,
    String? relativePath, // 相对路径，用于按文件树组织
  }) {
    final safeFileName = relativePath != null && relativePath.isNotEmpty
        ? '${DownloadFilePathService.safeRelativePath(relativePath)}/'
              '${DownloadFilePathService.safePathSegment(fileName)}'
        : DownloadFilePathService.safeRelativePath(fileName);

    final identity = _taskIdentity(
      workId: workId,
      hash: hash,
      fileName: safeFileName,
    );
    final inFlight = _pendingTaskAdds[identity];
    if (inFlight != null) return inFlight;

    final operation = _addTaskInternal(
      workId: workId,
      workTitle: workTitle,
      fileName: safeFileName,
      downloadUrl: downloadUrl,
      hash: hash,
      totalBytes: totalBytes,
      workMetadata: workMetadata,
      coverUrl: coverUrl,
    );
    _pendingTaskAdds[identity] = operation;
    unawaited(
      operation.then<void>(
        (_) {
          if (identical(_pendingTaskAdds[identity], operation)) {
            _pendingTaskAdds.remove(identity);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_pendingTaskAdds[identity], operation)) {
            _pendingTaskAdds.remove(identity);
          }
        },
      ),
    );
    return operation;
  }

  Future<DownloadTask> _addTaskInternal({
    required int workId,
    required String workTitle,
    required String fileName,
    required String downloadUrl,
    required String? hash,
    int? totalBytes,
    Map<String, dynamic>? workMetadata,
    String? coverUrl,
  }) async {
    // 检查是否已存在
    final existingTask = _findTask(
      workId: workId,
      hash: hash,
      fileName: fileName,
    );

    if (existingTask != null) {
      if (existingTask.status == DownloadStatus.completed) {
        // 如果任务已完成但没有元数据，更新元数据
        if (existingTask.workMetadata == null && workMetadata != null) {
          final updatedTask = existingTask.copyWith(workMetadata: workMetadata);
          _updateTask(updatedTask, immediate: true);
          // 保存元数据到硬盘
          await _saveWorkMetadata(workId, workMetadata, coverUrl);
          return updatedTask;
        }
        return existingTask;
      }
      // 如果任务存在但未完成，返回现有任务
      return existingTask;
    }

    // 检查缓存中是否已有此文件
    if (hash != null && hash.isNotEmpty) {
      final cachedFile = await CacheService.getCachedAudioFile(hash);
      if (cachedFile != null) {
        // 从缓存移动到下载目录
        final workDir = await _getWorkDownloadDirectory(workId);
        final targetPath = DownloadFilePathService.localPathForRelativePath(
          rootPath: workDir,
          relativePath: fileName,
        );
        final targetFile = File(targetPath);

        // 确保目录存在
        await targetFile.parent.create(recursive: true);

        if (!await targetFile.exists()) {
          await File(cachedFile).copy(targetPath);
        }

        final task = DownloadTask(
          id: hash,
          workId: workId,
          workTitle: workTitle,
          fileName: fileName, // 使用包含路径的完整文件名
          downloadUrl: downloadUrl,
          hash: hash,
          totalBytes: totalBytes ?? await targetFile.length(),
          downloadedBytes: totalBytes ?? await targetFile.length(),
          status: DownloadStatus.completed,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
          workMetadata: workMetadata,
        );

        _tasks.add(task);
        await _saveTasks();
        _tasksController.add(List.from(_tasks));

        // 保存作品元数据到硬盘
        if (workMetadata != null) {
          await _saveWorkMetadata(workId, workMetadata, coverUrl);
        }

        return task;
      }
    }

    final task = DownloadTask(
      id: hash?.trim().isNotEmpty == true ? hash! : '$workId:$fileName',
      workId: workId,
      workTitle: workTitle,
      fileName: fileName,
      downloadUrl: downloadUrl,
      hash: hash,
      totalBytes: totalBytes,
      createdAt: DateTime.now(),
      workMetadata: workMetadata,
    );

    _tasks.add(task);
    _tasksController.add(List.from(_tasks));

    // 添加任务后立即保存
    await _saveTasks();

    // 保存作品元数据到硬盘
    if (workMetadata != null) {
      await _saveWorkMetadata(workId, workMetadata, coverUrl);
    }

    // 自动开始下载（通过队列调度）
    unawaited(_processQueue());

    return task;
  }

  /// 处理下载队列：确保活跃下载数不超过上限
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;
    try {
      // 获取所有等待中的任务
      final pendingTasks = _tasks
          .where((t) => t.status == DownloadStatus.pending)
          .toList();

      if (pendingTasks.isNotEmpty) {
        _log.debug(
          '调度下载队列: ${pendingTasks.length} 个等待中, $_activeDownloadCount/$_maxConcurrentDownloads 个进行中',
          tag: 'Download',
        );
      }

      for (final task in pendingTasks) {
        if (_activeDownloadCount >= _maxConcurrentDownloads) break;
        if (_runningDownloads.containsKey(task.id)) continue;
        _activeDownloadCount++;
        final download = _startDownload(task);
        _runningDownloads[task.id] = download;
        unawaited(_finishDownload(task.id, download));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _finishDownload(String taskId, Future<void> download) async {
    try {
      await download;
    } catch (e) {
      // _startDownload normally records its own failures. This also covers
      // setup errors that occur before its main try/catch block.
      _log.error('下载任务异常退出: taskId=$taskId, error=$e', tag: 'Download');
      final task = _tasks.cast<DownloadTask?>().firstWhere(
        (candidate) => candidate?.id == taskId,
        orElse: () => null,
      );
      if (task?.status == DownloadStatus.downloading) {
        _updateTask(
          task!.copyWith(status: DownloadStatus.failed, error: e.toString()),
          immediate: true,
        );
      }
    } finally {
      if (identical(_runningDownloads[taskId], download)) {
        _runningDownloads.remove(taskId);
      }
      _activeDownloadCount--;
      unawaited(_processQueue()); // 完成后继续调度
    }
  }

  Future<void> _waitForRunningDownload(String taskId) async {
    final download = _runningDownloads[taskId];
    if (download == null) return;
    try {
      await download;
    } catch (_) {
      // The download service records the failure; resume can still retry it.
    }
  }

  void _markTaskFailedIfCurrent(String taskId, Object error) {
    final currentTask = _tasks.cast<DownloadTask?>().firstWhere(
      (candidate) => candidate?.id == taskId,
      orElse: () => null,
    );
    if (currentTask?.status == DownloadStatus.downloading) {
      _updateTask(
        currentTask!.copyWith(
          status: DownloadStatus.failed,
          error: error.toString(),
        ),
        immediate: true,
      );
    }
  }

  Future<void> _startDownload(DownloadTask task) async {
    final currentTask = _tasks.cast<DownloadTask?>().firstWhere(
      (candidate) => candidate?.id == task.id,
      orElse: () => null,
    );
    if (currentTask == null || currentTask.status != DownloadStatus.pending) {
      return;
    }
    task = currentTask;

    _log.info(
      '开始下载: ${task.fileName} (workId: ${task.workId})',
      tag: 'Download',
    );

    _updateTask(
      task.copyWith(status: DownloadStatus.downloading),
      immediate: true,
    );

    final workDir = await _getWorkDownloadDirectory(task.workId);
    await _ensureDirectoryWritable(Directory(workDir));
    // 使用fileName中的路径信息（如果包含/）
    final filePath = DownloadFilePathService.localPathForRelativePath(
      rootPath: workDir,
      relativePath: task.fileName,
    );
    final tempFilePath = '$filePath.downloading'; // 临时文件路径
    final file = File(filePath);
    final tempFile = File(tempFilePath);

    _log.debug(
      '下载路径: filePath=$filePath, tempFile=$tempFilePath',
      tag: 'Download',
    );

    // 确保父目录存在
    await file.parent.create(recursive: true);

    final latestTask = _tasks.cast<DownloadTask?>().firstWhere(
      (candidate) => candidate?.id == task.id,
      orElse: () => null,
    );
    if (latestTask == null || latestTask.status != DownloadStatus.downloading) {
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    try {
      // 先检查缓存中是否已有此文件
      if (task.hash != null && task.hash!.isNotEmpty) {
        final fileType = task.fileName.split('.').last.toLowerCase();
        final cachedPath = await CacheService.getCachedFileResource(
          workId: task.workId,
          hash: task.hash!,
          fileType: fileType,
        );

        if (cachedPath != null) {
          // 缓存存在,直接复制文件
          _log.info('从缓存复制文件: $cachedPath -> $filePath', tag: 'Download');
          final cachedFile = File(cachedPath);
          if (await cachedFile.exists()) {
            await cachedFile.copy(filePath);

            final completedTask = task.copyWith(
              status: DownloadStatus.completed,
              completedAt: DateTime.now(),
              downloadedBytes: await file.length(),
              totalBytes: await file.length(),
            );
            _updateTask(completedTask, immediate: true);
            if (identical(_cancelTokens[task.id], cancelToken)) {
              _cancelTokens.remove(task.id);
            }
            return;
          }
        }
      }

      // 缓存不存在,从网络下载
      // 节流：限制进度更新频率
      int lastUpdateTime = 0;
      const updateInterval = 500; // 500ms 更新一次
      int? firstReportedTotal; // 记录首次收到的total，用于诊断进度跳变

      _dio.options.headers.addAll(StorageService.serverCookieHeaders);

      _log.info(
        '开始网络下载: ${task.fileName}, url=${task.downloadUrl}',
        tag: 'Download',
      );

      // 下载到临时文件，完成后再重命名
      await _dio.download(
        task.downloadUrl,
        tempFilePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // 诊断：检测服务器报告的总大小是否变化（可能导致进度条跳变）
            if (firstReportedTotal == null) {
              firstReportedTotal = total;
              if (task.totalBytes != null &&
                  task.totalBytes! > 0 &&
                  task.totalBytes != total) {
                _log.warning(
                  '服务器报告的文件大小($total)与任务记录的大小(${task.totalBytes})不一致: ${task.fileName}',
                  tag: 'Download',
                );
              }
            } else if (firstReportedTotal != total) {
              _log.warning(
                '下载过程中文件总大小发生变化: $firstReportedTotal -> $total (${task.fileName})',
                tag: 'Download',
              );
              firstReportedTotal = total;
            }

            final now = DateTime.now().millisecondsSinceEpoch;
            // 只在间隔足够时才更新，避免过于频繁的更新
            if (now - lastUpdateTime > updateInterval || received == total) {
              lastUpdateTime = now;
              final currentTask = _tasks.cast<DownloadTask?>().firstWhere(
                (candidate) => candidate?.id == task.id,
                orElse: () => null,
              );
              if (currentTask?.status == DownloadStatus.downloading) {
                _updateTask(
                  currentTask!.copyWith(
                    downloadedBytes: received,
                    totalBytes: total,
                  ),
                ); // 不立即保存，使用延迟保存
              }
            }
          }
        },
      );

      // 下载完成，重命名临时文件为最终文件
      await tempFile.rename(filePath);

      _log.info('下载完成: ${task.fileName}', tag: 'Download');

      // 从 _tasks 获取当前版本以保留进度数据
      final currentTask = _tasks.firstWhere(
        (t) => t.id == task.id,
        orElse: () => task,
      );
      final completedTask = currentTask.copyWith(
        status: DownloadStatus.completed,
        completedAt: DateTime.now(),
      );
      _updateTask(completedTask, immediate: true); // 完成时立即保存
      if (identical(_cancelTokens[task.id], cancelToken)) {
        _cancelTokens.remove(task.id);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _log.info('下载已取消: ${task.fileName}', tag: 'Download');
        final currentTask = _tasks.cast<DownloadTask?>().firstWhere(
          (candidate) => candidate?.id == task.id,
          orElse: () => null,
        );
        // A pause/resume or delete may have changed the state while Dio was
        // unwinding. Do not overwrite that newer state with a stale snapshot.
        if (currentTask?.status == DownloadStatus.downloading) {
          _updateTask(
            currentTask!.copyWith(status: DownloadStatus.paused),
            immediate: true,
          );
        }
      } else if (e is PathNotFoundException) {
        _log.error(
          '路径不存在: ${task.fileName}, filePath=$filePath, error=$e',
          tag: 'Download',
        );
        _markTaskFailedIfCurrent(task.id, e);
      } else if (e is FileSystemException) {
        _log.error(
          '文件系统错误: ${task.fileName}, filePath=$filePath, error=$e',
          tag: 'Download',
        );
        _markTaskFailedIfCurrent(task.id, e);
      } else if (e is DioException) {
        _log.error(
          '网络错误: ${task.fileName}, type=${e.type}, message=${e.message}, url=${task.downloadUrl}',
          tag: 'Download',
        );
        _markTaskFailedIfCurrent(task.id, e);
      } else {
        _log.error('下载失败: ${task.fileName}, error=$e', tag: 'Download');
        _markTaskFailedIfCurrent(task.id, e);
      }
      if (identical(_cancelTokens[task.id], cancelToken)) {
        _cancelTokens.remove(task.id);
      }
    }
  }

  Future<void> pauseTask(String taskId) async {
    final task = _tasks.cast<DownloadTask?>().firstWhere(
      (candidate) => candidate?.id == taskId,
      orElse: () => null,
    );
    if (task == null ||
        (task.status != DownloadStatus.downloading &&
            task.status != DownloadStatus.pending)) {
      return;
    }

    // Mark pending tasks as paused as well, otherwise the queue can start
    // them after the user has requested a pause.
    _updateTask(task.copyWith(status: DownloadStatus.paused), immediate: true);
    final token = _cancelTokens[taskId];
    if (token != null) {
      token.cancel();
    }
  }

  Future<void> pauseTasks(Iterable<String> taskIds) async {
    final ids = taskIds.toSet();
    var changed = false;
    for (final task in _tasks.where((task) => ids.contains(task.id)).toList()) {
      if (task.status != DownloadStatus.downloading &&
          task.status != DownloadStatus.pending) {
        continue;
      }

      _updateTask(task.copyWith(status: DownloadStatus.paused));
      _cancelTokens[task.id]?.cancel();
      changed = true;
    }

    if (changed) {
      _saveTimer?.cancel();
      _saveTimer = null;
      _needsSave = false;
      await _saveTasks();
    }
  }

  Future<void> resumeTask(String taskId) async {
    final initialTask = _tasks.cast<DownloadTask?>().firstWhere(
      (candidate) => candidate?.id == taskId,
      orElse: () => null,
    );
    if (initialTask == null ||
        (initialTask.status != DownloadStatus.paused &&
            initialTask.status != DownloadStatus.failed)) {
      return;
    }

    await _waitForRunningDownload(taskId);
    final task = _tasks.cast<DownloadTask?>().firstWhere(
      (candidate) => candidate?.id == taskId,
      orElse: () => null,
    );
    if (task != null &&
        (task.status == DownloadStatus.paused ||
            task.status == DownloadStatus.failed)) {
      _updateTask(
        task.copyWith(status: DownloadStatus.pending),
        immediate: true,
      );
      unawaited(_processQueue());
    }
  }

  Future<void> resumeTasks(Iterable<String> taskIds) async {
    final ids = taskIds.toSet();
    final resumableIds = _tasks
        .where(
          (task) =>
              ids.contains(task.id) &&
              (task.status == DownloadStatus.paused ||
                  task.status == DownloadStatus.failed),
        )
        .map((task) => task.id)
        .toSet();
    await Future.wait(resumableIds.map(_waitForRunningDownload));
    var changed = false;
    for (final task in _tasks.where((task) => ids.contains(task.id)).toList()) {
      if (task.status != DownloadStatus.paused &&
          task.status != DownloadStatus.failed) {
        continue;
      }

      _updateTask(task.copyWith(status: DownloadStatus.pending));
      changed = true;
    }

    if (changed) {
      _saveTimer?.cancel();
      _saveTimer = null;
      _needsSave = false;
      await _saveTasks();
      unawaited(_processQueue());
    }
  }

  Future<void> deleteTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final workId = task.workId;

    // 取消下载
    final token = _cancelTokens[taskId];
    if (token != null) {
      token.cancel();
      _cancelTokens.remove(taskId);
    }

    // 删除文件
    if (task.status == DownloadStatus.completed) {
      final workDir = await _getWorkDownloadDirectory(workId);
      final file = File(
        DownloadFilePathService.localPathForRelativePath(
          rootPath: workDir,
          relativePath: task.fileName,
        ),
      );
      if (await file.exists()) {
        await file.delete();
      }
    }

    // 从任务列表中移除
    _tasks.removeWhere((t) => t.id == taskId);

    // 检查该作品是否还有其他任务
    final remainingTasks = _tasks.where((t) => t.workId == workId).toList();
    if (remainingTasks.isEmpty) {
      // 如果没有其他任务了，删除整个作品文件夹
      try {
        final workDir = await _getWorkDownloadDirectory(workId);
        final dir = Directory(workDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          _log.info('已删除作品文件夹: $workDir', tag: 'Download');
        }
      } catch (e) {
        _log.error('删除作品文件夹失败: $e', tag: 'Download');
      }
    }

    await _saveTasks();
    _tasksController.add(List.from(_tasks));
  }

  /// 删除单个文件（用于离线详情页）
  /// 删除后会清理空文件夹并同步任务列表
  Future<void> deleteFile(
    int workId,
    String relativePath, {
    String? workDirPath,
  }) async {
    try {
      final workDir = workDirPath ?? await _getWorkDownloadDirectory(workId);
      final file = File(
        DownloadFilePathService.localPathForRelativePath(
          rootPath: workDir,
          relativePath: relativePath,
        ),
      );

      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      // 删除文件
      await file.delete();
      _log.info('已删除文件: $relativePath', tag: 'Download');

      // 清理空文件夹
      await _cleanEmptyDirectories(file.parent, workDir);

      // 从任务列表中移除对应的任务
      _tasks.removeWhere(
        (t) =>
            t.workId == workId &&
            t.fileName == relativePath &&
            t.status == DownloadStatus.completed,
      );

      // 检查该作品是否还有其他文件
      final workDirObj = Directory(workDir);
      if (await workDirObj.exists()) {
        final contents = await workDirObj.list().toList();
        // 只剩下 metadata 和 cover 文件时，删除整个作品文件夹
        final hasOtherFiles = contents.any((entity) {
          final name = entity.path.split(Platform.pathSeparator).last;
          return !LocalWorkMetadataService.shouldSkipMetadataFile(
            name,
            isRoot: true,
          );
        });

        if (!hasOtherFiles) {
          await workDirObj.delete(recursive: true);
          _log.info('作品文件夹已空，已删除: $workDir', tag: 'Download');
          // 删除所有相关任务
          _tasks.removeWhere((t) => t.workId == workId);
        }
      }

      await _saveTasks();
      _tasksController.add(List.from(_tasks));
    } catch (e) {
      _log.error('删除文件失败: $e', tag: 'Download');
      rethrow;
    }
  }

  /// 递归清理空文件夹
  Future<void> _cleanEmptyDirectories(Directory dir, String workDir) async {
    try {
      // 不要删除作品根目录
      if (dir.path == workDir) {
        return;
      }

      // 检查目录是否为空
      final contents = await dir.list().toList();
      if (contents.isEmpty) {
        _log.debug('清理空文件夹: ${dir.path}', tag: 'Download');
        await dir.delete();

        // 递归检查父目录
        await _cleanEmptyDirectories(dir.parent, workDir);
      }
    } catch (e) {
      _log.error('清理空文件夹失败: $e', tag: 'Download');
    }
  }

  Future<List<DownloadTask>> getWorkTasks(int workId) async {
    return _tasks.where((t) => t.workId == workId).toList();
  }

  Future<String?> getDownloadedFilePath(int workId, String? hash) async {
    if (hash == null) return null;

    final task = _tasks.firstWhere(
      (t) =>
          t.workId == workId &&
          t.hash == hash &&
          t.status == DownloadStatus.completed,
      orElse: () => DownloadTask(
        id: '',
        workId: 0,
        workTitle: '',
        fileName: '',
        downloadUrl: '',
        createdAt: DateTime.now(),
      ),
    );

    if (task.id.isEmpty) return null;

    final workDir = await _getWorkDownloadDirectory(workId);
    final file = File(
      DownloadFilePathService.localPathForRelativePath(
        rootPath: workDir,
        relativePath: task.fileName,
      ),
    );
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  void _updateTask(DownloadTask updatedTask, {bool immediate = false}) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      _tasksController.add(List.from(_tasks));

      // 对于下载进度更新，使用延迟保存避免频繁 I/O
      if (immediate) {
        _saveTasks();
      } else {
        _scheduleDelayedSave();
      }
    }
  }

  // 延迟保存，避免频繁的 I/O 操作
  void _scheduleDelayedSave() {
    _needsSave = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (_needsSave) {
        _saveTasks();
        _needsSave = false;
      }
    });
  }

  // 升级旧版本的作品文件夹（尝试从 API 获取元数据）
  Future<void> _upgradeOldWorkFolders(Map<int, Directory> workFolders) async {
    for (final entry in workFolders.entries) {
      final workId = entry.key;
      final workDir = entry.value;

      // 检查是否已有元数据文件
      final metadataFile = _workMetadataFile(workDir);
      if (await metadataFile.exists()) {
        continue; // 已有元数据，跳过
      }

      _log.info('发现本地作品文件夹，尝试补全元数据: RJ$workId', tag: 'Download');

      try {
        // 创建 API 服务实例尝试获取元数据
        final apiService = KikoeruApiService();

        // 获取作品详情
        final workData = await apiService.getWork(workId);

        // 获取文件树
        final tracks = await apiService.getWorkTracks(workId);

        // 将 tracks 转换为 children 格式并添加到 workData
        workData['children'] = tracks;

        // 保存元数据（使用相对路径）
        workData[LocalWorkMetadataService.localWorkDirNameKey] = p.basename(
          workDir.path,
        );
        workData['localCoverPath'] = 'cover.jpg';
        await metadataFile.writeAsString(jsonEncode(workData));
        _log.info('已保存作品元数据: RJ$workId', tag: 'Download');

        // 下载封面（使用高清封面 URL）
        final host = StorageService.getString('server_host') ?? '';
        final token = StorageService.getString('auth_token') ?? '';

        if (host.isNotEmpty) {
          String normalizedHost = host;
          if (!host.startsWith('http://') && !host.startsWith('https://')) {
            normalizedHost = 'https://$host';
          }

          final coverUrl = token.isNotEmpty
              ? '$normalizedHost/api/cover/$workId?token=$token'
              : '$normalizedHost/api/cover/$workId';

          await _downloadCoverImage(
            workId,
            coverUrl,
            workDirPath: workDir.path,
          );
          _log.info('已下载作品封面: RJ$workId', tag: 'Download');
        }

        // 尝试组织文件树结构
        await _organizeFilesIntoTree(workId, workDir, tracks);

        _log.info('作品升级成功: RJ$workId', tag: 'Download');
      } catch (e) {
        _log.warning('在线补全作品元数据失败，改用本地基础元数据 RJ$workId: $e', tag: 'Download');
        try {
          final importedMetadata = await _localMetadataService
              .loadImportedMetadata(workDir: workDir, workId: workId);
          final fallbackMetadata = await _localMetadataService
              .buildFallbackMetadata(
                workId: workId,
                workDir: workDir,
                directoryName: p.basename(workDir.path),
                existingMetadata: importedMetadata,
              );
          await metadataFile.writeAsString(jsonEncode(fallbackMetadata));
          _log.info('已生成本地作品基础元数据: RJ$workId', tag: 'Download');
        } catch (fallbackError) {
          _log.error(
            '生成本地作品基础元数据失败 RJ$workId: $fallbackError',
            tag: 'Download',
          );
        }
      }
    }
  }

  // 将扁平的文件结构组织成树形结构
  Future<void> _organizeFilesIntoTree(
    int workId,
    Directory workDir,
    List<dynamic> tracks,
  ) async {
    try {
      // 构建文件树映射：hash -> 相对路径
      final Map<String, String> hashToPath = {};

      void buildPathMap(List<dynamic> items, String parentPath) {
        for (final item in items) {
          final type = item['type'] as String?;
          final title =
              item['title'] as String? ?? item['name'] as String? ?? '';
          final hash = item['hash'] as String?;

          if (type == 'folder') {
            // 文件夹，递归处理子项
            final folderPath = parentPath.isEmpty
                ? title
                : '$parentPath/$title';
            final children = item['children'] as List<dynamic>?;
            if (children != null) {
              buildPathMap(children, folderPath);
            }
          } else if (hash != null) {
            // 文件，记录路径映射
            final filePath = parentPath.isEmpty ? title : '$parentPath/$title';
            hashToPath[hash] = filePath;
          }
        }
      }

      buildPathMap(tracks, '');

      // 扫描工作目录中的所有文件
      await for (final entity in workDir.list()) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;

          // 跳过元数据和封面文件
          if (fileName == 'work_metadata.json' || fileName == 'cover.jpg') {
            continue;
          }

          // 尝试从文件树中找到对应的路径
          String? targetPath;
          for (final entry in hashToPath.entries) {
            final expectedFileName = entry.value.split('/').last;
            if (expectedFileName == fileName) {
              targetPath = entry.value;
              break;
            }
          }

          // 如果找到了对应路径且包含目录，则移动文件
          if (targetPath != null && targetPath.contains('/')) {
            final targetFile = File(
              DownloadFilePathService.localPathForRelativePath(
                rootPath: workDir.path,
                relativePath: DownloadFilePathService.safeRelativePath(
                  targetPath,
                ),
              ),
            );

            // 创建目标目录
            await targetFile.parent.create(recursive: true);

            // 移动文件
            try {
              await entity.rename(targetFile.path);
              _log.info('文件已重新组织: $fileName -> $targetPath', tag: 'Download');
            } catch (e) {
              // 如果 rename 失败（跨文件系统），尝试复制后删除
              await entity.copy(targetFile.path);
              await entity.delete();
              _log.info(
                '文件已复制并重新组织: $fileName -> $targetPath',
                tag: 'Download',
              );
            }
          }
        }
      }

      _log.info('文件树结构组织完成: RJ$workId', tag: 'Download');
    } catch (e) {
      _log.error('组织文件树失败 RJ$workId: $e', tag: 'Download');
      // 失败不影响继续运行
    }
  }

  /// 同步磁盘文件到 work_metadata.json 的 children 文件树
  /// 确保手动添加的文件也能在离线浏览器中正确显示
  Future<void> _syncFileTreeWithDisk(int workId, Directory workDir) async {
    // 1. 收集磁盘上所有实际文件的相对路径
    final diskFiles = <String, File>{};

    Future<void> collectFiles(Directory dir, String relativePath) async {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          // 跳过元数据、封面和临时下载文件
          if (LocalWorkMetadataService.shouldSkipMetadataFile(
            fileName,
            isRoot: relativePath.isEmpty,
          )) {
            continue;
          }
          final fullName = relativePath.isEmpty
              ? fileName
              : '$relativePath/$fileName';
          diskFiles[fullName] = entity;
        } else if (entity is Directory) {
          final dirName = entity.path.split(Platform.pathSeparator).last;
          final subPath = relativePath.isEmpty
              ? dirName
              : '$relativePath/$dirName';
          await collectFiles(entity, subPath);
        }
      }
    }

    await collectFiles(workDir, '');
    if (diskFiles.isEmpty) return;

    // 2. 加载现有元数据
    final metadataFile = _workMetadataFile(workDir);
    Map<String, dynamic>? metadata;

    if (await metadataFile.exists()) {
      try {
        metadata =
            jsonDecode(await metadataFile.readAsString())
                as Map<String, dynamic>;
      } catch (e) {
        _log.error('读取元数据失败: RJ$workId, $e', tag: 'Download');
      }
    }

    bool metadataCreated = false;
    bool metadataChanged = false;
    if (metadata == null) {
      // 没有任何元数据，创建基础元数据
      metadata = await _localMetadataService.buildFallbackMetadata(
        workId: workId,
        workDir: workDir,
        directoryName: p.basename(workDir.path),
      );
      metadataCreated = true;
    } else {
      if (_metadataIdAsPositiveInt(metadata['id']) == null) {
        metadata['id'] = workId;
        metadataChanged = true;
      }
      if (metadata[LocalWorkMetadataService.localWorkDirNameKey] !=
          p.basename(workDir.path)) {
        metadata[LocalWorkMetadataService.localWorkDirNameKey] = p.basename(
          workDir.path,
        );
        metadataChanged = true;
      }

      final detectedCover = await _localMetadataService.detectCoverRelativePath(
        workDir,
        metadata['localCoverPath'],
      );
      if (detectedCover != null &&
          metadata['localCoverPath'] != detectedCover) {
        metadata['localCoverPath'] = detectedCover;
        metadataChanged = true;
      }
    }

    // 3. 收集已有文件树中所有文件的相对路径
    final existingChildren = (metadata['children'] as List<dynamic>?) ?? [];
    final knownPaths = <String>{};

    void collectKnownPaths(List<dynamic> items, String parentPath) {
      for (final item in items) {
        if (item is! Map<String, dynamic>) continue;
        final type = item['type'] as String? ?? '';
        if (type == 'folder') {
          final folderPath = DownloadFilePathService.localRelativePathForItem(
            item,
            parentPath,
          );
          final children = item['children'] as List<dynamic>?;
          if (children != null) {
            collectKnownPaths(children, folderPath);
          }
        } else {
          knownPaths.add(
            DownloadFilePathService.localRelativePathForItem(item, parentPath),
          );
        }
      }
    }

    collectKnownPaths(existingChildren, '');

    // 4. 找出磁盘上有但文件树中没有的文件
    final newFiles = <String, File>{};
    for (final entry in diskFiles.entries) {
      if (!knownPaths.contains(entry.key)) {
        newFiles[entry.key] = entry.value;
      }
    }

    if (newFiles.isEmpty && !metadataCreated && !metadataChanged) return;

    // 5. 将新文件添加到 children 树中的正确位置
    final mutableChildren = List<dynamic>.from(existingChildren);

    for (final entry in newFiles.entries) {
      final relativePath = entry.key;
      final file = entry.value;
      final parts = relativePath.split('/');

      final fileType = FileIconUtils.inferFileType(parts.last);
      final syntheticHash = 'local:$relativePath';

      int? fileSize;
      try {
        fileSize = await file.length();
      } catch (_) {}

      final fileEntry = <String, dynamic>{
        'type': fileType,
        'title': parts.last,
        'hash': syntheticHash,
        'localRelativePath': relativePath,
        'relativePath': relativePath,
        if (fileSize != null) 'size': fileSize,
      };

      if (parts.length == 1) {
        // 根级别文件
        mutableChildren.add(fileEntry);
      } else {
        // 嵌套文件，确保父文件夹存在
        var currentLevel = mutableChildren;
        for (var i = 0; i < parts.length - 1; i++) {
          final folderName = parts[i];
          // 查找或创建文件夹
          Map<String, dynamic>? folder;
          for (final item in currentLevel) {
            if (item is Map<String, dynamic> &&
                item['type'] == 'folder' &&
                item['title'] == folderName) {
              folder = item;
              break;
            }
          }

          if (folder == null) {
            folder = <String, dynamic>{
              'type': 'folder',
              'title': folderName,
              'localRelativePath': parts.take(i + 1).join('/'),
              'children': <dynamic>[],
            };
            currentLevel.add(folder);
          } else if (folder['children'] == null) {
            folder['children'] = <dynamic>[];
          }
          currentLevel = folder['children'] as List<dynamic>;
        }
        currentLevel.add(fileEntry);
      }

      _log.info('添加手动文件到文件树: $relativePath (RJ$workId)', tag: 'Download');
    }

    if (newFiles.isNotEmpty || metadataCreated || metadataChanged) {
      metadata['children'] = mutableChildren;
      await metadataFile.writeAsString(jsonEncode(metadata));
      _log.info(
        '已更新作品文件树: RJ$workId, 新增 ${newFiles.length} 个文件',
        tag: 'Download',
      );
    }
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await StorageService.getPrefs();
      final tasksJson = prefs.getString(_tasksKey);
      if (tasksJson != null) {
        final List<dynamic> tasksList = jsonDecode(tasksJson);
        final loadedTasks = tasksList
            .map((json) => DownloadTask.fromJson(json))
            .toList();
        final uniqueTasks = <String, DownloadTask>{};
        for (final task in loadedTasks) {
          final identity = _taskIdentityForTask(task);
          final existing = uniqueTasks[identity];
          if (existing == null ||
              _taskStatusPriority(task.status) >
                  _taskStatusPriority(existing.status)) {
            uniqueTasks[identity] = task;
          }
        }

        _tasks
          ..clear()
          ..addAll(uniqueTasks.values);
        if (uniqueTasks.length != loadedTasks.length) {
          await _saveTasks();
          _log.warning(
            '已清理重复下载任务: ${loadedTasks.length - uniqueTasks.length} 个',
            tag: 'Download',
          );
        }
      }
    } catch (e) {
      _log.error('加载下载任务失败: $e', tag: 'Download');
    }
  }

  int _taskStatusPriority(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return 4;
      case DownloadStatus.downloading:
        return 3;
      case DownloadStatus.pending:
        return 2;
      case DownloadStatus.paused:
        return 1;
      case DownloadStatus.failed:
        return 0;
    }
  }

  // 从硬盘加载元数据并补充到任务中
  /// 公开方法：从硬盘完全同步下载任务
  /// 扫描硬盘文件系统，删除不存在的任务，添加新发现的文件
  /// 用于手动刷新，确保下载完成界面与硬盘文件完全一致
  Future<void> reloadMetadataFromDisk() async {
    try {
      _log.info('开始从硬盘同步任务...', tag: 'Download');

      // 获取下载目录
      final downloadDir = await _getDownloadDirectory();
      if (!await downloadDir.exists()) {
        _log.warning('下载目录不存在，清空所有已完成任务', tag: 'Download');
        _tasks.removeWhere((t) => t.status == DownloadStatus.completed);
        _tasksController.add(List.from(_tasks));
        await _saveTasks();
        return;
      }

      // 扫描硬盘上所有的作品文件夹
      final workFolders = <int, Directory>{};
      var ignoredDirectoryCount = 0;
      await for (final entity in downloadDir.list()) {
        if (entity is! Directory) continue;

        final folder = _localMetadataService.parseWorkFolder(entity);
        if (folder != null) {
          workFolders[folder.id] = entity;
        } else {
          ignoredDirectoryCount++;
          _log.debug('忽略无法识别为作品的目录: ${entity.path}', tag: 'Download');
        }
      }

      _log.info(
        '发现 ${workFolders.length} 个作品文件夹，忽略 $ignoredDirectoryCount 个目录',
        tag: 'Download',
      );

      // 第一步：删除硬盘上不存在的已完成任务
      final tasksToRemove = <String>[];
      for (final task in _tasks) {
        if (task.status == DownloadStatus.completed) {
          final workDir = workFolders[task.workId];
          if (workDir == null) {
            // 作品文件夹不存在，删除任务
            tasksToRemove.add(task.id);
            _log.warning('作品文件夹不存在，删除任务: ${task.workTitle}', tag: 'Download');
          } else {
            // 检查文件是否存在
            final file = File(
              DownloadFilePathService.localPathForRelativePath(
                rootPath: workDir.path,
                relativePath: task.fileName,
              ),
            );
            if (!await file.exists()) {
              tasksToRemove.add(task.id);
              _log.warning('文件不存在，删除任务: ${task.fileName}', tag: 'Download');
            }
          }
        }
      }

      // 执行删除
      if (tasksToRemove.isNotEmpty) {
        _tasks.removeWhere((t) => tasksToRemove.contains(t.id));
        _log.info('删除了 ${tasksToRemove.length} 个不存在的任务', tag: 'Download');
      }

      // 第二步：检查并升级旧版本文件（没有元数据的文件）
      await _upgradeOldWorkFolders(workFolders);

      // 第三步：同步磁盘文件到文件树（确保手动添加的文件能正确显示）
      for (final entry in workFolders.entries) {
        try {
          await _syncFileTreeWithDisk(entry.key, entry.value);
        } catch (e) {
          _log.error('同步文件树失败 RJ${entry.key}: $e', tag: 'Download');
        }
      }

      // 第四步：扫描硬盘上的所有文件，添加新发现的任务
      final newTasks = <DownloadTask>[];
      for (final entry in workFolders.entries) {
        final workId = entry.key;
        final workDir = entry.value;

        // 加载元数据（现在可能已经通过升级创建了）
        final metadata = await _loadWorkMetadata(workId);
        final workTitle = metadata?['title'] as String? ?? 'RJ$workId';
        if (metadata == null) {
          _log.warning(
            '扫描作品文件时未加载到元数据，将创建无详情任务: workId=$workId, dir=${workDir.path}',
            tag: 'Download',
          );
        }

        // 递归扫描文件夹中的所有文件
        Future<void> scanDirectory(Directory dir, String relativePath) async {
          await for (final entity in dir.list()) {
            if (entity is File) {
              final fileName = entity.path.split(Platform.pathSeparator).last;

              // 跳过元数据、封面和临时下载文件
              if (LocalWorkMetadataService.shouldSkipMetadataFile(
                fileName,
                isRoot: relativePath.isEmpty,
              )) {
                continue;
              }

              // 构建相对路径下的文件名
              final fullFileName = relativePath.isEmpty
                  ? fileName
                  : '$relativePath/$fileName';

              // 检查该文件是否已有对应的任务
              final existingTask = _tasks.firstWhere(
                (t) => t.workId == workId && t.fileName == fullFileName,
                orElse: () => DownloadTask(
                  id: '',
                  workId: 0,
                  workTitle: '',
                  fileName: '',
                  downloadUrl: '',
                  createdAt: DateTime.now(),
                ),
              );

              if (existingTask.id.isEmpty) {
                // 发现新文件，创建任务
                final newTask = DownloadTask(
                  id: '${workId}_${fullFileName}_${DateTime.now().millisecondsSinceEpoch}',
                  workId: workId,
                  workTitle: workTitle,
                  fileName: fullFileName,
                  downloadUrl: '', // 硬盘扫描的任务没有下载URL
                  status: DownloadStatus.completed,
                  totalBytes: await entity.length(),
                  downloadedBytes: await entity.length(),
                  createdAt: entity.statSync().modified,
                  completedAt: entity.statSync().modified,
                  workMetadata: metadata,
                );
                newTasks.add(newTask);
                _log.info('发现新文件: $fullFileName ($workTitle)', tag: 'Download');
              }
            } else if (entity is Directory) {
              // 递归扫描子目录
              final dirName = entity.path.split(Platform.pathSeparator).last;
              final subPath = relativePath.isEmpty
                  ? dirName
                  : '$relativePath/$dirName';
              await scanDirectory(entity, subPath);
            }
          }
        }

        await scanDirectory(workDir, '');
      }

      // 添加新任务
      if (newTasks.isNotEmpty) {
        _tasks.addAll(newTasks);
        _log.info('添加了 ${newTasks.length} 个新任务', tag: 'Download');
      }

      // 第五步：为所有已完成任务更新元数据（包含新同步的文件树）
      for (var i = 0; i < _tasks.length; i++) {
        final task = _tasks[i];
        if (task.status == DownloadStatus.completed) {
          final metadata = await _loadWorkMetadata(task.workId);
          if (metadata != null) {
            _tasks[i] = task.copyWith(workMetadata: metadata);
          } else {
            _log.warning(
              '完成任务仍缺少元数据: workId=${task.workId}, task=${task.id}, '
              'file=${task.fileName}',
              tag: 'Download',
            );
          }
        }
      }

      // 通知更新并保存
      _tasksController.add(List.from(_tasks));
      await _saveTasks();

      _log.info(
        '同步完成：删除 ${tasksToRemove.length} 个，新增 ${newTasks.length} 个',
        tag: 'Download',
      );
    } catch (e) {
      _log.error('从硬盘同步任务失败: $e', tag: 'Download');
      rethrow;
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await StorageService.getPrefs();
      final tasksJson = jsonEncode(_tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_tasksKey, tasksJson);
    } catch (e) {
      _log.error('保存下载任务失败: $e', tag: 'Download');
    }
  }

  void dispose() {
    _saveTimer?.cancel();
    _saveTimer = null;
    _tasksController.close();
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _cancelTokens.clear();

    // 确保最后保存一次
    if (_needsSave) {
      _saveTasks();
    }
  }
}
