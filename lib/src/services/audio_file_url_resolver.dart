import 'dart:io';

import 'download_file_path_service.dart';
import '../utils/file_tree_utils.dart';
import '../utils/local_file_url.dart';

typedef AudioDownloadedPathResolver = Future<String?> Function(
  int workId,
  String hash,
);
typedef AudioDownloadRootProvider = Future<String> Function();
typedef CachedAudioPathResolver = Future<String?> Function(String hash);
typedef AudioFileExists = Future<bool> Function(String path);

enum OfflineAudioPlaybackTargetStatus {
  ready,
  missingId,
  missingFile,
}

class OfflineAudioPlaybackTarget {
  const OfflineAudioPlaybackTarget({
    required this.selectedTitle,
    required this.workDir,
    required this.localPath,
    this.artworkUrl,
  });

  final String selectedTitle;
  final String workDir;
  final String localPath;
  final String? artworkUrl;
}

class OfflineAudioPlaybackTargetResult {
  const OfflineAudioPlaybackTargetResult._({
    required this.status,
    required this.selectedTitle,
    this.target,
  });

  factory OfflineAudioPlaybackTargetResult.ready(
    OfflineAudioPlaybackTarget target,
  ) {
    return OfflineAudioPlaybackTargetResult._(
      status: OfflineAudioPlaybackTargetStatus.ready,
      selectedTitle: target.selectedTitle,
      target: target,
    );
  }

  factory OfflineAudioPlaybackTargetResult.failure(
    OfflineAudioPlaybackTargetStatus status, {
    required String selectedTitle,
  }) {
    return OfflineAudioPlaybackTargetResult._(
      status: status,
      selectedTitle: selectedTitle,
    );
  }

  final OfflineAudioPlaybackTargetStatus status;
  final String selectedTitle;
  final OfflineAudioPlaybackTarget? target;

  OfflineAudioPlaybackTarget get requireTarget {
    final value = target;
    if (value == null) {
      throw StateError('Offline audio target is unavailable for $status.');
    }
    return value;
  }
}

class AudioFileUrlResolver {
  const AudioFileUrlResolver({
    required this.resolveDownloadedPath,
    required this.downloadRootPath,
    required this.resolveCachedAudioPath,
    this.fileExists = _defaultFileExists,
  });

  final AudioDownloadedPathResolver resolveDownloadedPath;
  final AudioDownloadRootProvider downloadRootPath;
  final CachedAudioPathResolver resolveCachedAudioPath;
  final AudioFileExists fileExists;

  Future<String?> resolveOnline({
    required dynamic file,
    required int workId,
    required String host,
    required String token,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
  }) async {
    final fileHash = FileTreeUtils.property(file, 'hash')?.toString();

    if (fileHash != null) {
      final downloadedPath = await resolveDownloadedPath(workId, fileHash);
      if (downloadedPath != null) {
        return LocalFileUrl.fromPath(downloadedPath);
      }

      final copiedPath = await _resolveCopiedLocalPath(
        workId: workId,
        hash: fileHash,
        downloadedFiles: downloadedFiles,
        fileRelativePaths: fileRelativePaths,
      );
      if (copiedPath != null) {
        return LocalFileUrl.fromPath(copiedPath);
      }

      // Keep the remote URL in the track even when a cache exists. The audio
      // player owns cache playback and needs the original URL as a fallback if
      // iOS rejects a historical local cache file.
    }

    final mediaStreamUrl = FileTreeUtils.property(file, 'mediaStreamUrl');
    if (mediaStreamUrl != null && mediaStreamUrl.toString().isNotEmpty) {
      return _withToken(
        _absoluteMediaUrl(
          mediaStreamUrl.toString(),
          host,
        ),
        token,
      );
    }

    if (host.isEmpty || fileHash == null) return null;

    final normalizedHost =
        host.startsWith('http://') || host.startsWith('https://')
            ? host
            : 'https://$host';
    return '$normalizedHost/api/media/stream/$fileHash?token=$token';
  }

  Future<String?> resolveOffline({
    required dynamic file,
    required String workDir,
    required String parentPath,
  }) async {
    final localPath = FileTreeUtils.property(file, 'localPath')?.toString();
    if (localPath != null &&
        localPath.trim().isNotEmpty &&
        await fileExists(localPath)) {
      return LocalFileUrl.fromPath(localPath);
    }

    final filePath = DownloadFilePathService.localPathForRelativePath(
      rootPath: workDir,
      relativePath: DownloadFilePathService.localRelativePathForItem(
        file,
        parentPath,
      ),
    );
    if (await fileExists(filePath)) {
      return LocalFileUrl.fromPath(filePath);
    }
    return null;
  }

  Future<OfflineAudioPlaybackTargetResult> resolveOfflinePlaybackTarget({
    required dynamic file,
    required int workId,
    required String parentPath,
    required String unknownTitle,
    String? workDirPath,
    String? coverRelativePath,
  }) async {
    final selectedTitle = FileTreeUtils.titleOf(
      file,
      defaultValue: unknownTitle,
    );

    final workDir = workDirPath ??
        DownloadFilePathService.localPathForRelativePath(
          rootPath: await downloadRootPath(),
          relativePath: workId.toString(),
        );
    final explicitLocalPath =
        FileTreeUtils.property(file, 'localPath')?.toString().trim();
    final localPath = explicitLocalPath != null && explicitLocalPath.isNotEmpty
        ? explicitLocalPath
        : DownloadFilePathService.localPathForRelativePath(
            rootPath: workDir,
            relativePath: DownloadFilePathService.localRelativePathForItem(
              file,
              parentPath,
            ),
          );

    if (!await fileExists(localPath)) {
      return OfflineAudioPlaybackTargetResult.failure(
        OfflineAudioPlaybackTargetStatus.missingFile,
        selectedTitle: selectedTitle,
      );
    }

    final coverPath = DownloadFilePathService.localPathForRelativePath(
      rootPath: workDir,
      relativePath: coverRelativePath ?? 'cover.jpg',
    );
    final artworkUrl =
        await fileExists(coverPath) ? LocalFileUrl.fromPath(coverPath) : null;

    return OfflineAudioPlaybackTargetResult.ready(
      OfflineAudioPlaybackTarget(
        selectedTitle: selectedTitle,
        workDir: workDir,
        localPath: localPath,
        artworkUrl: artworkUrl,
      ),
    );
  }

  Future<String?> _resolveCopiedLocalPath({
    required int workId,
    required String hash,
    required Map<String, bool> downloadedFiles,
    required Map<String, String> fileRelativePaths,
  }) async {
    if (downloadedFiles[hash] != true) return null;

    final relativePath = fileRelativePaths[hash];
    if (relativePath == null) return null;

    final rootPath = await downloadRootPath();
    final filePath = DownloadFilePathService.localPathForWorkRelativePath(
      rootPath: rootPath,
      workId: workId,
      relativePath: relativePath,
    );
    if (await fileExists(filePath)) {
      return filePath;
    }
    return null;
  }

  static String _absoluteMediaUrl(String url, String host) {
    if (!url.startsWith('/')) return url;
    if (host.isEmpty) return url;
    return '${normalizeMediaHost(host)}$url';
  }

  static String _withToken(String url, String token) {
    if (token.isEmpty || url.contains('token=')) {
      return url;
    }
    return url.contains('?') ? '$url&token=$token' : '$url?token=$token';
  }

  static String normalizeMediaHost(String host) {
    if (host.startsWith('http://') || host.startsWith('https://')) {
      return host;
    }
    if (host.contains('localhost') ||
        host.startsWith('127.0.0.1') ||
        host.startsWith('192.168.')) {
      return 'http://$host';
    }
    return 'https://$host';
  }

  static Future<bool> _defaultFileExists(String path) {
    return File(path).exists();
  }
}
