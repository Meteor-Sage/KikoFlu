import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../models/work.dart';
import '../services/download_path_service.dart';
import '../services/download_service.dart';
import '../services/log_service.dart';
import '../services/translation_service.dart';
import '../services/subtitle_match_loader.dart';
import '../services/audio_playback_plan_builder.dart';
import '../services/file_preview_resolver.dart';
import '../services/file_size_resolver.dart';
import '../services/audio_file_url_resolver.dart';
import '../services/video_file_opener.dart';
import '../services/offline_local_file_scanner.dart';
import '../services/file_explorer_tap_resolver.dart';
import '../services/file_name_translation_controller.dart';
import '../services/file_delete_request_builder.dart';
import '../providers/audio_provider.dart';
import '../providers/lyric_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/file_tree_utils.dart';
import '../utils/snackbar_util.dart';
import 'file_tree_actions.dart';
import 'file_tree_view.dart';
import 'file_explorer_tree_panel.dart';
import 'file_delete_confirmation_dialog.dart';
import 'image_gallery_screen.dart';
import 'manual_subtitle_load_flow.dart';
import 'text_preview_screen.dart';
import 'pdf_preview_screen.dart';
import 'video_open_failure_dialog.dart';
import 'translation_toggle_button.dart';
import '../../l10n/app_localizations.dart';

final _log = LogService.instance;

/// 离线文件浏览器 - 显示已下载的文件
/// 只显示硬盘上实际存在的文件，不显示未下载的文件
class OfflineFileExplorerWidget extends ConsumerStatefulWidget {
  final Work work;
  final List<dynamic>? fileTree; // 从 work_metadata.json 中读取的文件树
  final String? localWorkDirPath;
  final String? localCoverRelativePath;

  const OfflineFileExplorerWidget({
    super.key,
    required this.work,
    this.fileTree,
    this.localWorkDirPath,
    this.localCoverRelativePath,
  });

  @override
  ConsumerState<OfflineFileExplorerWidget> createState() =>
      _OfflineFileExplorerWidgetState();
}

class _OfflineFileExplorerWidgetState
    extends ConsumerState<OfflineFileExplorerWidget> {
  List<dynamic> _localFiles = []; // 仅包含本地存在的文件
  final Set<String> _expandedFolders = {}; // 记录展开的文件夹路径
  final Set<String> _audioWithLibrarySubtitles = {}; // 存储在字幕库中有匹配字幕的音频文件名
  bool _isLoading = true;
  String? _errorMessage;
  String? _mainFolderPath; // 主文件夹路径
  late final FileListController _fileListController;
  int _loadGeneration = 0;
  String? _workDirPath;

  FilePreviewResolver get _previewResolver => FilePreviewResolver(
        downloadRootPath: () async {
          final downloadDir = await DownloadPathService.getDownloadDirectory();
          return downloadDir.path;
        },
      );

  FileSizeResolver get _fileSizeResolver => FileSizeResolver(
        downloadRootPath: () async {
          final downloadDir = await DownloadPathService.getDownloadDirectory();
          return downloadDir.path;
        },
      );

  AudioFileUrlResolver get _audioUrlResolver => AudioFileUrlResolver(
        resolveDownloadedPath: (_, __) async => null,
        downloadRootPath: () async {
          final downloadDir = await DownloadPathService.getDownloadDirectory();
          return downloadDir.path;
        },
        resolveCachedAudioPath: (_) async => null,
      );

  final VideoFileOpener _videoFileOpener = VideoFileOpener();
  final SubtitleMatchLoader _subtitleMatchLoader = const SubtitleMatchLoader();
  final FileExplorerTapResolver _tapResolver =
      const FileExplorerTapResolver(videoBeforeAudio: false);
  final AudioPlaybackPlanBuilder _audioPlaybackPlanBuilder =
      const AudioPlaybackPlanBuilder();
  final FileNameTranslationController _translationController =
      FileNameTranslationController();
  final FileDeleteRequestBuilder _deleteRequestBuilder =
      const FileDeleteRequestBuilder();

  @override
  void initState() {
    super.initState();
    _fileListController = ref.read(fileListControllerProvider.notifier);
    _loadLocalFiles();
  }

  @override
  void dispose() {
    _loadGeneration++;
    _translationController.dispose();
    // 离线页面关闭时清空文件列表，避免影响其他作品
    // 使用 Future.microtask 延迟执行，避免在 dispose 中直接修改 provider
    Future.microtask(() => _fileListController.clear(workId: widget.work.id));
    super.dispose();
  }

  bool _isCurrentLoad(int generation) {
    return mounted && generation == _loadGeneration;
  }

  // 加载本地存在的文件
  Future<void> _loadLocalFiles() async {
    if (widget.fileTree == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = S.of(context).noFileTreeInfo;
      });
      return;
    }

    final generation = ++_loadGeneration;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final downloadDir = await DownloadPathService.getDownloadDirectory();
      if (!_isCurrentLoad(generation)) return;

      final workDir = widget.localWorkDirPath != null
          ? Directory(widget.localWorkDirPath!)
          : Directory(p.join(downloadDir.path, widget.work.id.toString()));

      if (!await workDir.exists()) {
        if (!_isCurrentLoad(generation)) return;
        setState(() {
          _isLoading = false;
          _errorMessage = S.of(context).workFolderNotExist;
        });
        return;
      }

      final scanResult = await const OfflineLocalFileScanner().scan(
        fileTree: widget.fileTree!,
        workDirPath: workDir.path,
      );
      if (!_isCurrentLoad(generation)) return;

      _workDirPath = workDir.path;
      _localFiles = scanResult.files;
      // 更新全局文件列表供字幕自动加载使用
      _fileListController.updateFiles(
        List<dynamic>.from(_localFiles),
        workId: widget.work.id,
        subtitleWorkDirPath: workDir.path,
      );

      // 检查字幕库中的匹配项
      await _checkLibrarySubtitles(generation);
      if (!_isCurrentLoad(generation)) return;

      // 识别主文件夹并自动展开（需要在检查字幕库后执行）
      _identifyAndExpandMainFolder();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!_isCurrentLoad(generation)) return;
      setState(() {
        _isLoading = false;
        _errorMessage = S.of(context).loadFilesFailed(e.toString());
      });
    }
  }

  // 检查字幕库中哪些音频文件有匹配的字幕
  Future<void> _checkLibrarySubtitles(int generation) async {
    try {
      final matches = await _subtitleMatchLoader.loadMatches(
        workId: widget.work.id,
        fileTree: _localFiles,
      );
      if (!_isCurrentLoad(generation)) return;

      _audioWithLibrarySubtitles
        ..clear()
        ..addAll(matches);

      _log.captureOutput(
          '[OfflineFileExplorer] 字幕库匹配: ${_audioWithLibrarySubtitles.length} 个音频文件有字幕');
    } catch (e) {
      _log.captureOutput('[OfflineFileExplorer] 检查字幕库失败: $e');
    }
  }

  // 识别主文件夹：音频数量最多的目录，如果有多个则选择文本文件最多的
  void _identifyAndExpandMainFolder() {
    final formatPreference = ref.read(audioFormatPreferenceProvider);
    final mainFolder = FileTreeUtils.identifyMainFolder(
      _localFiles,
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
          '[OfflineFileExplorer] 识别到主文件夹 $_mainFolderPath (音频:${mainFolder.audioCount}, 文本:${mainFolder.textCount})');
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

  // 播放音频文件（从本地）
  Future<void> _playAudioFile(dynamic audioFile, String parentPath) async {
    final l10n = S.of(context);
    final title = FileTreeUtils.titleOf(audioFile, defaultValue: l10n.unknown);
    try {
      _log.captureOutput(
        '[OfflineFileExplorer] 点击播放: workId=${widget.work.id}, '
        'title="$title", parentPath="$parentPath", '
        'localRelativePath=${FileTreeUtils.property(audioFile, 'localRelativePath')}, '
        'relativePath=${FileTreeUtils.property(audioFile, 'relativePath')}, '
        'localPath=${FileTreeUtils.property(audioFile, 'localPath')}, '
        'hash=${FileTreeUtils.property(audioFile, 'hash')}',
      );

      final targetResult = await _audioUrlResolver.resolveOfflinePlaybackTarget(
        file: audioFile,
        workId: widget.work.id,
        parentPath: parentPath,
        unknownTitle: l10n.unknown,
        workDirPath: _workDirPath,
        coverRelativePath: widget.localCoverRelativePath,
      );

      if (!mounted) return;

      switch (targetResult.status) {
        case OfflineAudioPlaybackTargetStatus.missingId:
          _log.captureOutput(
            '[OfflineFileExplorer] 播放失败: 缺少文件标识 title="$title"',
          );
          SnackBarUtil.showError(context, l10n.cannotPlayAudioMissingId);
          return;
        case OfflineAudioPlaybackTargetStatus.missingFile:
          _log.captureOutput(
            '[OfflineFileExplorer] 播放失败: 本地文件不存在 title="$title"',
          );
          SnackBarUtil.showError(context, l10n.audioFileNotExist);
          return;
        case OfflineAudioPlaybackTargetStatus.ready:
          break;
      }

      final target = targetResult.requireTarget;
      _log.captureOutput(
        '[OfflineFileExplorer] 播放目标: title="$title", '
        'workDir=${target.workDir}, localPath=${target.localPath}',
      );
      final playlistMode =
          await ref.read(audioTapPlaylistModeProvider.notifier).getMode();
      if (!mounted) return;
      final plan = await _audioPlaybackPlanBuilder.build(
        fileTree: _localFiles,
        parentPath: parentPath,
        selectedFile: audioFile,
        resolveUrl: (file) => _audioUrlResolver.resolveOffline(
          file: file,
          workDir: target.workDir,
          parentPath: parentPath,
        ),
        work: widget.work,
        unknownTitle: l10n.unknown,
        artworkUrl: target.artworkUrl,
        subtitleWorkDirPath: target.workDir,
        playlistMode: playlistMode,
      );

      if (!mounted) return;

      switch (plan.status) {
        case AudioPlaybackPlanStatus.selectedFileMissing:
          _log.captureOutput(
            '[OfflineFileExplorer] 播放失败: 队列中找不到选中文件 title="${plan.selectedTitle}"',
          );
          SnackBarUtil.showError(
            context,
            l10n.cannotFindAudioFile(plan.selectedTitle),
          );
          return;
        case AudioPlaybackPlanStatus.emptyQueue:
          _log.captureOutput(
            '[OfflineFileExplorer] 播放失败: 可播放队列为空 title="${plan.selectedTitle}"',
          );
          SnackBarUtil.showError(context, l10n.noPlayableAudioFiles);
          return;
        case AudioPlaybackPlanStatus.ready:
          final queue = plan.queue!;
          _log.captureOutput(
            '[OfflineFileExplorer] 开始播放队列: count=${queue.tracks.length}, '
            'startIndex=${queue.startIndex}, '
            'startTitle="${queue.tracks[queue.startIndex].title}"',
          );
          await ref.read(audioPlayerControllerProvider.notifier).playTracks(
                queue.tracks,
                startIndex: queue.startIndex,
                work: widget.work,
                playlistMode: playlistMode,
              );
      }
    } catch (e, st) {
      _log.captureOutput('[OfflineFileExplorer] 播放异常: title="$title", $e');
      _log.captureOutput(st.toString());
      if (!mounted) return;
      SnackBarUtil.showError(context, l10n.playbackFailed(e.toString()));
    }
  }

  // 辅助方法：判断文件名是否为音频格式
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
    );
  }

  // 预览图片文件（从本地）
  Future<void> _previewImageFile(dynamic file) async {
    final l10n = S.of(context);

    final result = await _previewResolver.buildOfflineImageGalleryTarget(
      selectedFile: file,
      imageFiles: _getImageFilesFromCurrentDirectory(),
      fileTree: _localFiles,
      workId: widget.work.id,
      unknownTitle: l10n.unknown,
      workDirPath: _workDirPath,
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
              workId: widget.work.id,
            ),
          ),
        );
        return;
      case PreviewImageGalleryStatus.missingSelectedImage:
        SnackBarUtil.showError(context, l10n.cannotFindImageFile);
        return;
      case PreviewImageGalleryStatus.empty:
        SnackBarUtil.showError(context, l10n.noPreviewableImages);
        return;
      case PreviewImageGalleryStatus.missingOnlineInfo:
        return;
    }
  }

  List<dynamic> _getImageFilesFromCurrentDirectory() {
    return FileTreeUtils.imageFilesRecursive(_localFiles);
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
    final l10n = S.of(context);
    final result = await _previewResolver.resolveOfflineDocumentTarget(
      file: file,
      fileTree: _localFiles,
      workId: widget.work.id,
      unknownTitle: l10n.unknown,
      workDirPath: _workDirPath,
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
      case PreviewDocumentTargetStatus.missingId:
        SnackBarUtil.showError(
          context,
          isPdf
              ? l10n.cannotPreviewPdfMissingId
              : l10n.cannotPreviewTextMissingId,
        );
        return;
      case PreviewDocumentTargetStatus.missingPath:
        SnackBarUtil.showError(context, l10n.cannotFindFilePath);
        return;
      case PreviewDocumentTargetStatus.missingFile:
        SnackBarUtil.showError(context, l10n.fileNotExist(result.title));
        return;
      case PreviewDocumentTargetStatus.missingOnlineInfo:
      case PreviewDocumentTargetStatus.unavailable:
        return;
    }
  }

  Future<void> _playVideoWithSystemPlayer(dynamic videoFile) async {
    final l10n = S.of(context);

    final targetResult = await _previewResolver.resolveOfflineVideoTarget(
      file: videoFile,
      fileTree: _localFiles,
      workId: widget.work.id,
      workDirPath: _workDirPath,
    );

    if (!mounted) return;

    switch (targetResult.status) {
      case PreviewVideoTargetStatus.ready:
        final target = targetResult.requireTarget;
        final result = await _videoFileOpener.open(target.source);
        if (!mounted) return;

        _handleLocalVideoOpenResult(result, fallbackPath: target.localPath);
        return;
      case PreviewVideoTargetStatus.missingId:
        SnackBarUtil.showError(context, l10n.cannotPlayVideoMissingId);
        return;
      case PreviewVideoTargetStatus.missingPath:
        SnackBarUtil.showError(context, l10n.cannotFindFilePath);
        return;
      case PreviewVideoTargetStatus.missingFile:
        SnackBarUtil.showError(context, l10n.videoFileNotExist);
        return;
      case PreviewVideoTargetStatus.missingParams:
        return;
    }
  }

  void _handleLocalVideoOpenResult(
    VideoOpenResult result, {
    required String? fallbackPath,
  }) {
    final l10n = S.of(context);

    switch (result.type) {
      case VideoOpenResultType.success:
        return;
      case VideoOpenResultType.localOpenFailed:
        showDialog(
          context: context,
          builder: (context) => VideoOpenFailureDialog.local(
            errorMessage: result.message ?? '',
            filePath: result.path ?? fallbackPath ?? '',
          ),
        );
        return;
      case VideoOpenResultType.localOpenError:
        SnackBarUtil.showError(
          context,
          l10n.openVideoFileError(result.message ?? ''),
        );
        return;
      case VideoOpenResultType.remoteCannotLaunch:
      case VideoOpenResultType.remoteOpenError:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildFileList();
  }

  Widget _buildFileList() {
    return FileExplorerTreePanel(
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      empty: _localFiles.isEmpty,
      emptyMessage: S.of(context).noDownloadedFiles,
      onRetry: _loadLocalFiles,
      title: S.of(context).offlineFiles,
      trailing: TranslationToggleButton(
        isTranslated: _translationController.showTranslation,
        originalLabel: S.of(context).translationOriginal,
        translatedLabel: S.of(context).translationTranslated,
        onPressed: () {
          setState(() {
            _translationController.toggleShowTranslation();
          });
        },
      ),
      items: _localFiles,
      expandedFolders: _expandedFolders,
      onToggleFolder: _toggleFolder,
      onFileTap: _handleFileTap,
      displayNameFor: _getDisplayName,
      metadataBuilder: _buildFileMetadata,
      trailingBuilder: _buildFileActions,
      audioWithLibrarySubtitles: _audioWithLibrarySubtitles,
    );
  }

  Widget? _buildFileMetadata(BuildContext context, FileTreeEntry entry) {
    if (entry.isFolder) return null;

    return FutureBuilder<int?>(
      future: _fileSizeResolver.resolveOffline(
        item: entry.item,
        workId: widget.work.id,
        parentPath: entry.parentPath,
        workDirPath: _workDirPath,
      ),
      builder: (context, snapshot) {
        final fileSize =
            snapshot.hasData ? FileSizeResolver.formatBytes(snapshot.data) : '';
        if (fileSize.isEmpty) {
          return const SizedBox.shrink();
        }

        return Text(
          fileSize,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        );
      },
    );
  }

  Widget? _buildFileActions(BuildContext context, FileTreeEntry entry) {
    return FileTreeActions(
      entry: entry,
      showPlaybackActions: false,
      showPreviewActions: false,
      showDeleteAction: true,
      onLoadSubtitle: (item, _) => _loadLyricManually(item),
      onDelete: (item, parentPath) => _deleteFile(item, parentPath),
    );
  }

  // 获取显示的名称（根据翻译状态）
  String _getDisplayName(String originalName) {
    return _translationController.displayName(
      originalName,
      onMissingTranslation: _queueTranslation,
    );
  }

  // 按需翻译单个项目
  void _queueTranslation(String originalName) {
    final generation = _translationController.beginLazyTranslation(
      originalName,
    );
    if (generation == null) return;

    Future.microtask(() => _translateItem(originalName, generation));
  }

  Future<void> _translateItem(String originalName, int generation) async {
    try {
      final translationService = TranslationService();
      final translated = await translationService.translate(
        originalName,
        sourceLang: 'ja',
      );

      final completed = _translationController.completeLazyTranslation(
        generation,
        originalName,
        translated,
      );
      if (!completed) return;
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      _log.captureOutput('[OfflineFileExplorer] 翻译失败: $e');
      final failed = _translationController.failLazyTranslation(
        generation,
        originalName,
      );
      if (!failed) return;
      if (!mounted) return;
      setState(() {});
    }
  }

  // 处理文件点击
  void _handleFileTap(dynamic file, String title, String parentPath) {
    final action = _tapResolver.resolve(file);
    _log.captureOutput(
      '[OfflineFileExplorer] 文件点击: workId=${widget.work.id}, '
      'title="$title", parentPath="$parentPath", action=$action, '
      'type=${FileTreeUtils.property(file, 'type')}, '
      'hash=${FileTreeUtils.property(file, 'hash')}',
    );

    switch (action) {
      case FileExplorerTapAction.audio:
        _playAudioFile(file, parentPath);
        return;
      case FileExplorerTapAction.video:
        _playVideoWithSystemPlayer(file);
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
            context, S.of(context).unsupportedFileType(title));
    }
  }

  // 删除单个文件
  Future<void> _deleteFile(dynamic file, String parentPath) async {
    final l10n = S.of(context);
    final request = _deleteRequestBuilder.build(
      file: file,
      parentPath: parentPath,
      unknownTitle: l10n.unknown,
    );

    final confirmed = await showFileDeleteConfirmationDialog(
      context,
      relativePath: request.relativePath,
    );

    if (!confirmed || !mounted) return;

    try {
      // 显示加载指示器
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // 删除文件
      await DownloadService.instance.deleteFile(
        widget.work.id,
        request.relativePath,
        workDirPath: _workDirPath,
      );

      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 重新加载文件列表
      await _loadLocalFiles();

      // 显示成功消息
      if (mounted) {
        SnackBarUtil.showSuccess(context, l10n.deletedItem(request.title));
      }
    } catch (e) {
      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
      }

      // 显示错误消息
      if (mounted) {
        SnackBarUtil.showError(
          context,
          l10n.deleteFailedWithError(e.toString()),
        );
      }
    }
  }
}
