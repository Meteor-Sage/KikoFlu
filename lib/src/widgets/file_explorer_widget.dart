import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/work.dart';
import '../models/download_task.dart';
import '../providers/auth_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/lyric_provider.dart';
import '../providers/settings_provider.dart';
import '../services/download_service.dart';
import '../services/cache_service.dart';
import '../services/log_service.dart';
import '../services/translation_service.dart';
import '../services/subtitle_match_loader.dart';
import '../services/audio_playback_plan_builder.dart';
import '../services/file_preview_resolver.dart';
import '../services/downloaded_file_state_scanner.dart';
import '../services/audio_file_url_resolver.dart';
import '../services/video_file_opener.dart';
import '../services/file_name_translation_service.dart';
import '../services/file_name_translation_controller.dart';
import '../services/file_explorer_tap_resolver.dart';
import '../utils/file_icon_utils.dart';
import '../utils/file_tree_utils.dart';
import '../utils/snackbar_util.dart';
import '../utils/string_utils.dart';
import 'file_tree_actions.dart';
import 'file_tree_view.dart';
import 'file_explorer_tree_panel.dart';
import 'image_gallery_screen.dart';
import 'manual_subtitle_load_flow.dart';
import 'text_preview_screen.dart';
import 'pdf_preview_screen.dart';
import 'video_open_failure_dialog.dart';
import 'translation_toggle_button.dart';

final _log = LogService.instance;

class FileExplorerController {
  _FileExplorerWidgetState? _state;

  Future<void> refresh({bool forceRefresh = false}) async {
    final state = _state;
    if (state == null) return;

    await state._loadWorkTree(
      forceRefresh: forceRefresh,
      propagateError: true,
    );
  }

  void _attach(_FileExplorerWidgetState state) {
    _state = state;
  }

  void _detach(_FileExplorerWidgetState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }
}

class FileExplorerWidget extends ConsumerStatefulWidget {
  final Work work;
  final FileExplorerController? controller;

  const FileExplorerWidget({
    super.key,
    required this.work,
    this.controller,
  });

  @override
  ConsumerState<FileExplorerWidget> createState() => _FileExplorerWidgetState();
}

class _FileExplorerWidgetState extends ConsumerState<FileExplorerWidget> {
  List<dynamic> _rootFiles = [];
  final Set<String> _expandedFolders = {}; // 记录展开的文件夹路径
  final Map<String, bool> _downloadedFiles = {}; // hash -> downloaded
  final Map<String, String> _fileRelativePaths = {}; // hash -> relative path
  final Set<String> _audioWithLibrarySubtitles = {}; // 存储在字幕库中有匹配字幕的音频文件名
  bool _isLoading = false;
  String? _errorMessage;
  String? _mainFolderPath; // 主文件夹路径
  StreamSubscription<List<DownloadTask>>? _downloadTasksSubscription;
  int _loadGeneration = 0;
  int _downloadScanGeneration = 0;

  FilePreviewResolver get _previewResolver => FilePreviewResolver(
        downloadRootPath: () async {
          final downloadDir =
              await DownloadService.instance.getDownloadDirectory();
          return downloadDir.path;
        },
      );

  DownloadedFileStateScanner get _downloadedFileScanner {
    final downloadService = DownloadService.instance;
    return DownloadedFileStateScanner(
      resolveDownloadedPath: downloadService.getDownloadedFilePath,
      downloadRootPath: () async {
        final downloadDir = await downloadService.getDownloadDirectory();
        return downloadDir.path;
      },
    );
  }

  AudioFileUrlResolver get _audioUrlResolver {
    final downloadService = DownloadService.instance;
    return AudioFileUrlResolver(
      resolveDownloadedPath: downloadService.getDownloadedFilePath,
      downloadRootPath: () async {
        final downloadDir = await downloadService.getDownloadDirectory();
        return downloadDir.path;
      },
      resolveCachedAudioPath: CacheService.getCachedAudioFile,
    );
  }

  final VideoFileOpener _videoFileOpener = VideoFileOpener();
  final SubtitleMatchLoader _subtitleMatchLoader = const SubtitleMatchLoader();
  final FileExplorerTapResolver _tapResolver =
      const FileExplorerTapResolver(videoBeforeAudio: true);
  final AudioPlaybackPlanBuilder _audioPlaybackPlanBuilder =
      const AudioPlaybackPlanBuilder();
  final FileNameTranslationController _translationController =
      FileNameTranslationController();

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _loadWorkTree();
    // 监听下载任务变化
    _listenToDownloadTasks();
  }

  @override
  void didUpdateWidget(covariant FileExplorerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _loadGeneration++;
    _downloadScanGeneration++;
    _translationController.dispose();
    _downloadTasksSubscription?.cancel();
    super.dispose();
  }

  bool _isCurrentLoad(int generation) {
    return mounted && generation == _loadGeneration;
  }

  // 监听下载任务变化，当有任务完成或被删除时重新检测
  void _listenToDownloadTasks() {
    final downloadService = DownloadService.instance;
    _downloadTasksSubscription = downloadService.tasksStream.listen((tasks) {
      // 过滤出与当前作品相关的任务
      final workTasks = tasks.where((t) => t.workId == widget.work.id).toList();

      // 如果有任务状态变化，重新检测已下载文件
      if (workTasks.isNotEmpty) {
        _checkDownloadedFiles();
      }
    });
  }

  Future<void> _loadWorkTree({
    bool forceRefresh = false,
    bool propagateError = false,
  }) async {
    final generation = ++_loadGeneration;
    final preserveCurrentTree = forceRefresh && _rootFiles.isNotEmpty;
    setState(() {
      _isLoading = !preserveCurrentTree;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      final files = await apiService.getWorkTracks(
        widget.work.id,
        forceRefresh: forceRefresh,
      );
      if (!_isCurrentLoad(generation)) return;

      // 注意：不要在这里更新全局文件列表
      // 只在播放音频时才更新，避免浏览其他作品时影响当前播放的歌曲?

      setState(() {
        _rootFiles = files;
        _isLoading = false;
      });

      // 检查已下载的文件
      _checkDownloadedFiles();

      // 检查字幕库中的匹配项
      await _checkLibrarySubtitles(generation);
      if (!_isCurrentLoad(generation)) return;

      // 识别主文件夹并自动展开（需要在检查字幕库后执行）
      setState(() {
        _identifyAndExpandMainFolder();
      });
    } catch (e) {
      if (!_isCurrentLoad(generation)) return;
      setState(() {
        if (!preserveCurrentTree) {
          _errorMessage = S.of(context).loadFilesFailed(e.toString());
        }
        _isLoading = false;
      });
      if (propagateError) rethrow;
    }
  }

  // 检查已下载的文件
  Future<void> _checkDownloadedFiles() async {
    final generation = ++_downloadScanGeneration;
    final result = await _downloadedFileScanner.scan(
      workId: widget.work.id,
      fileTree: _rootFiles,
    );

    if (!mounted || generation != _downloadScanGeneration) return;

    setState(() {
      _downloadedFiles
        ..clear()
        ..addAll(result.downloadedFiles);
      _fileRelativePaths
        ..clear()
        ..addAll(result.fileRelativePaths);
    });
  }

  // 检查字幕库中哪些音频文件有匹配的字幕
  Future<void> _checkLibrarySubtitles(int generation) async {
    try {
      final matches = await _subtitleMatchLoader.loadMatches(
        workId: widget.work.id,
        fileTree: _rootFiles,
      );
      if (!_isCurrentLoad(generation)) return;

      _audioWithLibrarySubtitles
        ..clear()
        ..addAll(matches);

      _log.captureOutput(
          '[FileExplorer] 字幕库匹配: ${_audioWithLibrarySubtitles.length} 个音频文件有字幕');
    } catch (e) {
      _log.captureOutput('[FileExplorer] 检查字幕库失败: $e');
    }
  }

  // 识别主文件夹：音频数量最多的目录，如果有多个则选择文本文件最多的
  void _identifyAndExpandMainFolder() {
    final formatPreference = ref.read(audioFormatPreferenceProvider);
    final mainFolder = FileTreeUtils.identifyMainFolder(
      _rootFiles,
      formatPreference.priority,
      audioWithLibrarySubtitles: _audioWithLibrarySubtitles,
    );

    if (mainFolder == null) {
      _mainFolderPath = null;
      return;
    }

    _mainFolderPath = mainFolder.path;
    _expandedFolders.addAll(mainFolder.expandedPaths);
    if (mainFolder.path.isNotEmpty) {
      _log.captureOutput(
          '[FileExplorer] 识别到主文件夹 $_mainFolderPath (音频:${mainFolder.audioCount}, 文本:${mainFolder.textCount})');
    }
  }

  // 切换文件夹展开/折叠状态
  void _toggleFolder(String path) {
    setState(() {
      if (_expandedFolders.contains(path)) {
        _expandedFolders.remove(path);
      } else {
        _expandedFolders.add(path);
      }
    });
  }

  void _playAudioFile(dynamic audioFile, String parentPath) async {
    final l10n = S.of(context);
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final coverUrl =
        host.isEmpty ? null : widget.work.getCoverImageUrl(host, token: token);
    final title = FileTreeUtils.titleOf(audioFile, defaultValue: l10n.unknown);

    // 获取当前作品的完整文件树（用于字幕查找）
    try {
      final apiService = ref.read(kikoeruApiServiceProvider);
      final allFiles = await apiService.getWorkTracks(widget.work.id);

      // 只在播放音频时更新全局文件列表，这样字幕才能正确关联
      ref.read(fileListControllerProvider.notifier).updateFiles(
            allFiles,
            workId: widget.work.id,
          );
    } catch (e) {
      _log.captureOutput('获取完整文件树失败 $e');
      // 即使获取失败也继续播放，只是可能没有字幕
    }

    if (!mounted) return;

    final playlistMode =
        await ref.read(audioTapPlaylistModeProvider.notifier).getMode();
    if (!mounted) return;
    final plan = await _audioPlaybackPlanBuilder.build(
      fileTree: _rootFiles,
      parentPath: parentPath,
      selectedFile: audioFile,
      resolveUrl: (file) => _audioUrlResolver.resolveOnline(
        file: file,
        workId: widget.work.id,
        host: host,
        token: token,
        downloadedFiles: _downloadedFiles,
        fileRelativePaths: _fileRelativePaths,
      ),
      work: widget.work,
      unknownTitle: l10n.unknown,
      artworkUrl: coverUrl,
      playlistMode: playlistMode,
    );

    if (!mounted) return;

    switch (plan.status) {
      case AudioPlaybackPlanStatus.selectedFileMissing:
        SnackBarUtil.showError(
          context,
          l10n.cannotFindAudioFile(plan.selectedTitle),
          duration: const Duration(seconds: 3),
        );
        return;
      case AudioPlaybackPlanStatus.emptyQueue:
        SnackBarUtil.showError(
          context,
          l10n.noPlayableAudioFiles,
          duration: const Duration(seconds: 3),
        );
        return;
      case AudioPlaybackPlanStatus.ready:
        final queue = plan.queue!;
        _log.captureOutput('播放音频: $title');
        _log.captureOutput('播放队列包含 ${queue.tracks.length} 个文件');

        try {
          await ref.read(audioPlayerControllerProvider.notifier).playTracks(
                queue.tracks,
                startIndex: queue.startIndex,
                work: widget.work,
                playlistMode: playlistMode,
              );
        } catch (e) {
          _log.captureOutput('播放音频失败: $e');
          if (mounted) {
            SnackBarUtil.showError(
              context,
              l10n.playbackFailed(e.toString()),
            );
          }
        }
    }

    // 注意：字幕会通过 lyricAutoLoaderProvider 自动加载
    // 不需要手动调用 loadLyricForTrack
  }

  // 手动加载字幕
  Future<void> _loadLyricManually(dynamic file) async {
    final l10n = S.of(context);
    final title = FileTreeUtils.titleOf(file, defaultValue: l10n.unknown);
    final currentTrack = ref.read(currentTrackProvider).value;

    await runManualSubtitleLoadFlow(
      context,
      file: file,
      workId: widget.work.id,
      subtitleTitle: title,
      currentAudioTitle: currentTrack?.title,
      loadSubtitle: (file, {required workId}) {
        return ref.read(lyricControllerProvider.notifier).loadLyricManually(
              file,
              workId: workId,
            );
      },
      isMounted: () => mounted,
      successDuration: const Duration(seconds: 3),
      errorDuration: const Duration(seconds: 4),
    );
  }

  Future<void> _previewImageFile(dynamic file) async {
    final l10n = S.of(context);
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';

    final result = await _previewResolver.buildOnlineImageGalleryTarget(
      selectedFile: file,
      imageFiles: _getImageFilesFromCurrentDirectory(),
      workId: widget.work.id,
      host: host,
      token: token,
      downloadedFiles: _downloadedFiles,
      fileRelativePaths: _fileRelativePaths,
      unknownTitle: l10n.unknown,
    );

    if (!mounted) return;

    switch (result.status) {
      case PreviewImageGalleryStatus.ready:
        final target = result.requireTarget;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageGalleryScreen(
              images: target.toGalleryMaps(),
              initialIndex: target.initialIndex,
              workId: widget.work.id, // 传递作品ID用于缓存
            ),
          ),
        );
        return;
      case PreviewImageGalleryStatus.missingOnlineInfo:
        SnackBarUtil.showError(context, l10n.cannotPreviewImageMissingInfo);
        return;
      case PreviewImageGalleryStatus.missingSelectedImage:
        SnackBarUtil.showError(context, l10n.cannotFindImageFile);
        return;
      case PreviewImageGalleryStatus.empty:
        return;
    }
  }

  // 获取当前目录下所有图片文件（递归遍历整个树）
  List<dynamic> _getImageFilesFromCurrentDirectory() {
    return FileTreeUtils.imageFilesRecursive(_rootFiles);
  }

  Future<void> _previewTextFile(dynamic file) async {
    await _previewDocumentFile(file, isPdf: false);
  }

  Future<void> _previewPdfFile(dynamic file) async {
    await _previewDocumentFile(file, isPdf: true);
  }

  Future<void> _previewDocumentFile(
    dynamic file, {
    required bool isPdf,
  }) async {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final l10n = S.of(context);
    final result = await _previewResolver.resolveOnlineDocumentTarget(
      file: file,
      workId: widget.work.id,
      host: host,
      token: token,
      downloadedFiles: _downloadedFiles,
      fileRelativePaths: _fileRelativePaths,
      unknownTitle: l10n.unknown,
    );

    if (!mounted) return;

    switch (result.status) {
      case PreviewDocumentTargetStatus.ready:
        final target = result.requireTarget;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              if (isPdf) {
                return PdfPreviewScreen(
                  pdfUrl: target.url,
                  title: target.title,
                  workId: widget.work.id,
                  hash: target.hash,
                );
              }

              return TextPreviewScreen(
                textUrl: target.url,
                title: target.title,
                workId: widget.work.id,
                hash: target.hash,
              );
            },
          ),
        );
        return;
      case PreviewDocumentTargetStatus.missingOnlineInfo:
        SnackBarUtil.showError(
          context,
          isPdf
              ? l10n.cannotPreviewPdfMissingInfo
              : l10n.cannotPreviewTextMissingInfo,
        );
        return;
      case PreviewDocumentTargetStatus.unavailable:
      case PreviewDocumentTargetStatus.missingId:
      case PreviewDocumentTargetStatus.missingPath:
      case PreviewDocumentTargetStatus.missingFile:
        return;
    }
  }

  // 使用系统播放器播放视频文件
  Future<void> _playVideoWithSystemPlayer(dynamic videoFile) async {
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';

    final targetResult = await _previewResolver.resolveOnlineVideoTarget(
      file: videoFile,
      workId: widget.work.id,
      host: host,
      token: token,
      downloadedFiles: _downloadedFiles,
      fileRelativePaths: _fileRelativePaths,
    );

    if (!mounted) return;

    switch (targetResult.status) {
      case PreviewVideoTargetStatus.ready:
        final target = targetResult.requireTarget;
        final localPath = target.localPath;
        if (localPath != null) {
          _log.captureOutput('[FileExplorer] 使用本地视频文件: $localPath');
        }

        final result = await _videoFileOpener.open(target.source);
        if (!mounted) return;

        _handleVideoOpenResult(result);
        return;
      case PreviewVideoTargetStatus.missingId:
        SnackBarUtil.showError(
          context,
          S.of(context).cannotPlayVideoMissingId,
        );
        return;
      case PreviewVideoTargetStatus.missingParams:
        SnackBarUtil.showError(
          context,
          S.of(context).cannotPlayVideoMissingParams,
        );
        return;
      case PreviewVideoTargetStatus.missingPath:
      case PreviewVideoTargetStatus.missingFile:
        return;
    }
  }

  void _handleVideoOpenResult(VideoOpenResult result) {
    switch (result.type) {
      case VideoOpenResultType.success:
        return;
      case VideoOpenResultType.localOpenFailed:
        showDialog(
          context: context,
          builder: (context) => VideoOpenFailureDialog.local(
            errorMessage: result.message ?? '',
            filePath: result.path ?? '',
          ),
        );
        return;
      case VideoOpenResultType.localOpenError:
        SnackBarUtil.showError(
          context,
          S.of(context).openVideoFileError(result.message ?? ''),
        );
        return;
      case VideoOpenResultType.remoteCannotLaunch:
        final uri = result.uri;
        if (uri == null) return;
        showDialog(
          context: context,
          builder: (context) => VideoOpenFailureDialog.remote(
            videoUrl: uri.toString(),
            onOpenInBrowser: () => _videoFileOpener.openInBrowser(uri),
          ),
        );
        return;
      case VideoOpenResultType.remoteOpenError:
        SnackBarUtil.showError(
          context,
          S.of(context).playVideoError(result.message ?? ''),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 直接返回文件列表，占满全部空间
    return _buildFileList();
  }

  Widget _buildFileList() {
    return FileExplorerTreePanel(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      empty: _rootFiles.isEmpty,
      emptyMessage: S.of(context).noFiles,
      onRetry: _loadWorkTree,
      title: _translationController.showTranslation
          ? S
              .of(context)
              .resourceFilesTranslated(_translationController.translationCount)
          : S.of(context).resourceFiles,
      trailing: TranslationToggleButton(
        isTranslated: _translationController.showTranslation,
        isLoading: _translationController.isBulkTranslating,
        originalLabel: S.of(context).translationOriginal,
        translatedLabel: S.of(context).translationTranslated,
        onPressed: _translateAllNames,
      ),
      progressMessage: _translationController.isBulkTranslating
          ? _translationController.progress
          : null,
      items: _rootFiles,
      expandedFolders: _expandedFolders,
      onToggleFolder: _toggleFolder,
      onFileTap: _handleFileTap,
      displayNameFor: _getDisplayName,
      metadataBuilder: _buildFileMetadata,
      trailingBuilder: _buildFileActions,
      downloadedFiles: _downloadedFiles,
      audioWithLibrarySubtitles: _audioWithLibrarySubtitles,
      showDownloadedBadge: true,
      fadeDownloadedItems: true,
    );
  }

  Widget? _buildFileMetadata(BuildContext context, FileTreeEntry entry) {
    final item = entry.item;
    final duration = FileTreeUtils.property(item, 'duration');
    if (duration == null) return null;

    if (!FileIconUtils.isAudioFile(item) && !FileIconUtils.isVideoFile(item)) {
      return null;
    }

    final durationText = formatDurationSeconds(duration, padHours: false);
    if (durationText.isEmpty) return null;

    return Text(
      durationText,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey[600],
      ),
    );
  }

  Widget? _buildFileActions(BuildContext context, FileTreeEntry entry) {
    return FileTreeActions(
      entry: entry,
      onPlayAudio: (item, parentPath) => _playAudioFile(item, parentPath),
      onPlayVideo: (item, _) => _playVideoWithSystemPlayer(item),
      onLoadSubtitle: (item, _) => _loadLyricManually(item),
      onPreviewImage: (item, _) => _previewImageFile(item),
      onPreviewText: (item, _) => _previewTextFile(item),
      onPreviewPdf: (item, _) => _previewPdfFile(item),
    );
  }

  // 分块批量翻译所有文件/文件夹名称
  Future<void> _translateAllNames() async {
    if (_translationController.isBulkTranslating) return;

    if (_translationController.toggleExistingTranslations()) {
      setState(() {});
      return;
    }

    final l10n = S.of(context);
    final generation =
        _translationController.beginBulkTranslation(l10n.preparingTranslation);
    setState(() {});

    try {
      final result = await FileNameTranslationService(
        translate: TranslationService().translate,
      ).translateFileTree(
        fileTree: _rootFiles,
        onProgress: (current, total) {
          final updated = _translationController.updateBulkProgress(
            generation,
            l10n.translatingProgress(current, total),
          );
          if (updated && mounted) setState(() {});
        },
        onChunkError: (index, error) {
          _log.captureOutput('[FileExplorer] 翻译块 $index 失败: $error');
        },
      );

      if (!mounted) return;

      if (result.isEmpty) {
        if (!_translationController.finishBulkWithoutTranslations(generation)) {
          return;
        }
        setState(() {});
        SnackBarUtil.showInfo(
          context,
          S.of(context).noContentToTranslate,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      if (!_translationController.completeBulkTranslation(
        generation,
        result.translations,
      )) {
        return;
      }
      setState(() {});

      SnackBarUtil.showSuccess(
        context,
        l10n.translationComplete(result.translations.length),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      if (!_translationController.failBulkTranslation(generation)) return;
      setState(() {});

      SnackBarUtil.showError(
        context,
        l10n.translationFailed(e.toString()),
        duration: const Duration(seconds: 3),
      );
    }
  }

  // 获取显示的名称（根据翻译状态）
  String _getDisplayName(String originalName) {
    return _translationController.displayName(originalName);
  }

  // 处理文件点击
  void _handleFileTap(dynamic file, String title, String parentPath) {
    switch (_tapResolver.resolve(file)) {
      case FileExplorerTapAction.video:
        _playVideoWithSystemPlayer(file);
        return;
      case FileExplorerTapAction.audio:
        _playAudioFile(file, parentPath);
        return;
      case FileExplorerTapAction.image:
        _previewImageFile(file);
        return;
      case FileExplorerTapAction.pdf:
        _previewPdfFile(file);
        return;
      case FileExplorerTapAction.text:
        _previewTextFile(file);
        return;
      case FileExplorerTapAction.unsupported:
        SnackBarUtil.showInfo(
          context,
          S.of(context).unsupportedFileTypeWithTitle(title),
          duration: const Duration(seconds: 2),
        );
    }
  }
}
