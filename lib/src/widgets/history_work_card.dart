import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/history_record.dart';
import '../models/download_task.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/cache_service.dart';
import '../services/log_service.dart';
import '../services/audio_file_url_resolver.dart';
import '../services/audio_track_queue_builder.dart';
import '../screens/work_detail_screen.dart';
import '../services/storage_service.dart';
import '../utils/string_utils.dart';
import '../providers/lyric_provider.dart';
import '../../l10n/app_localizations.dart';
import 'privacy_blur_cover.dart';

final _log = LogService.instance;

class HistoryWorkCard extends ConsumerWidget {
  final HistoryRecord record;
  final VoidCallback? onTap;

  const HistoryWorkCard({
    super.key,
    required this.record,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';
    final work = record.work;

    final httpHeaders = StorageService.serverCookieHeaders;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkDetailScreen(work: work),
            ),
          );
        },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(S.of(context).deleteRecord),
              content: Text(S.of(context).deletePlayRecordConfirm(work.title)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.of(context).cancel),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(historyProvider.notifier).remove(work.id);
                    Navigator.pop(context);
                  },
                  child: Text(S.of(context).delete),
                ),
              ],
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'work_cover_${work.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: PrivacyBlurCover(
                        child: CachedNetworkImage(
                          imageUrl: work.getCoverImageUrl(host, token: token),
                          httpHeaders: httpHeaders,
                          cacheKey: 'work_cover_${work.id}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.image, color: Colors.grey)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Gradient
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Play Button
                  if (record.lastTrack != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _resumePlayback(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.play_arrow,
                              size: 24,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (record.lastTrack != null)
                    Builder(
                      builder: (context) {
                        final lastTrack = record.lastTrack!;
                        final int? trackDurationMs =
                            lastTrack.duration?.inMilliseconds;
                        final double progressValue =
                            trackDurationMs != null && trackDurationMs > 0
                                ? (record.lastPositionMs / trackDurationMs)
                                    .clamp(0.0, 1.0)
                                : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lastTrack.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${formatDuration(Duration(milliseconds: record.lastPositionMs))} / ${formatDuration(lastTrack.duration ?? Duration.zero)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                if (record.playlistTotal > 0)
                                  Text(
                                    '${record.playlistIndex + 1} / ${record.playlistTotal}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              color: Theme.of(context).colorScheme.primary,
                              minHeight: 3,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ],
                        );
                      },
                    )
                  else
                    Text(
                      S.of(context).notPlayedYet,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resumePlayback(BuildContext context, WidgetRef ref) async {
    final l10n = S.of(context);
    final work = record.work;
    final authState = ref.read(authProvider);
    final host = authState.host ?? '';
    final token = authState.token ?? '';

    // 1. Get all files
    final apiService = ref.read(kikoeruApiServiceProvider);
    List<dynamic> allFiles = [];
    try {
      allFiles = await apiService.getWorkTracks(work.id);
      ref.read(fileListControllerProvider.notifier).updateFiles(allFiles);
    } catch (e) {
      _log.captureOutput('Failed to update file list: $e');

      // 尝试从已下载的任务中构建文件列表
      try {
        final tasks = await DownloadService.instance.getWorkTasks(work.id);
        if (tasks.isNotEmpty) {
          final downloadedFiles = tasks
              .where((t) => t.status == DownloadStatus.completed)
              .map((t) => {
                    'title': t.fileName,
                    'name': t.fileName,
                    'hash': t.hash,
                    'type': 'file',
                  })
              .toList();

          if (downloadedFiles.isNotEmpty) {
            allFiles = downloadedFiles;
            ref.read(fileListControllerProvider.notifier).updateFiles(allFiles);
          }
        }
      } catch (e2) {
        _log.captureOutput('Failed to load downloaded files: $e2');
      }
    }

    if (allFiles.isEmpty) {
      // Fallback to single track if list fetch fails
      if (record.lastTrack != null) {
        try {
          await AudioPlayerService.instance.updateQueue([record.lastTrack!]);
          await AudioPlayerService.instance
              .seek(Duration(milliseconds: record.lastPositionMs));
          await AudioPlayerService.instance.play();
          ref.read(historyProvider.notifier).addOrUpdate(work);
        } catch (e) {
          _log.captureOutput('Failed to resume playback: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.playbackFailed(e.toString()))),
            );
          }
        }
      }
      return;
    }

    // 2. Find the directory containing the last track and get its audio files
    List<dynamic> getSiblingAudioFiles(List<dynamic> files) {
      // Helper to check if a file matches the last track
      bool isTargetFile(dynamic file) {
        if (file['type'] == 'folder') return false;
        final fileHash = file['hash'];
        final fileName = file['title'] ?? file['name'];

        if (record.lastTrack!.hash != null &&
            fileHash == record.lastTrack!.hash) {
          return true;
        }
        // Fallback to title match if hash is missing
        return fileName == record.lastTrack!.title;
      }

      // Helper to extract audio files from a list
      List<dynamic> extractAudioFiles(List<dynamic> list) {
        return list.where((file) {
          if (file['type'] == 'folder') return false;
          final name = file['title'] ?? file['name'] ?? '';
          final ext = name.split('.').last.toLowerCase();
          return ['mp3', 'wav', 'flac', 'm4a', 'aac', 'ogg'].contains(ext);
        }).toList();
      }

      // Recursive search
      for (final file in files) {
        if (file['type'] == 'folder') {
          if (file['children'] != null) {
            // Check if target is in this folder's children (direct siblings)
            final children = file['children'] as List<dynamic>;
            if (children.any(isTargetFile)) {
              return extractAudioFiles(children);
            }
            // If not found directly, recurse deeper
            final result = getSiblingAudioFiles(children);
            if (result.isNotEmpty) return result;
          }
        } else {
          // Check if target is in the root list
          if (isTargetFile(file)) {
            return extractAudioFiles(files);
          }
        }
      }

      return [];
    }

    List<dynamic> audioFiles = getSiblingAudioFiles(allFiles);

    // If we couldn't find the specific directory (e.g. file moved/renamed),
    // fallback to flattening all files to ensure playback works
    if (audioFiles.isEmpty) {
      List<dynamic> flattenAudioFiles(List<dynamic> files) {
        final List<dynamic> result = [];
        for (final file in files) {
          if (file['type'] == 'folder') {
            if (file['children'] != null) {
              result.addAll(flattenAudioFiles(file['children']));
            }
          } else {
            final name = file['title'] ?? file['name'] ?? '';
            final ext = name.split('.').last.toLowerCase();
            if (['mp3', 'wav', 'flac', 'm4a', 'aac', 'ogg'].contains(ext)) {
              result.add(file);
            }
          }
        }
        return result;
      }

      audioFiles = flattenAudioFiles(allFiles);
    }

    final downloadService = DownloadService.instance;

    // Current work cover URL
    String? coverUrl;
    if (host.isNotEmpty) {
      String normalizedUrl = host;
      if (!host.startsWith('http://') && !host.startsWith('https://')) {
        normalizedUrl = 'https://$host';
      }
      coverUrl = token.isNotEmpty
          ? '$normalizedUrl/api/cover/${work.id}?token=$token'
          : '$normalizedUrl/api/cover/${work.id}';
    }

    final audioUrlResolver = AudioFileUrlResolver(
      resolveDownloadedPath: downloadService.getDownloadedFilePath,
      downloadRootPath: () async {
        final downloadDir = await downloadService.getDownloadDirectory();
        return downloadDir.path;
      },
      resolveCachedAudioPath: CacheService.getCachedAudioFile,
    );
    final vaNames = work.vas?.map((va) => va.name).toList() ?? [];
    final artistInfo = vaNames.isNotEmpty ? vaNames.join(', ') : null;
    final queue = await const AudioTrackQueueBuilder().build(
      audioFiles: audioFiles,
      selectedFile:
          record.lastTrack ?? (audioFiles.isNotEmpty ? audioFiles.first : null),
      resolveUrl: (file) => audioUrlResolver.resolveOnline(
        file: file,
        workId: work.id,
        host: host,
        token: token,
        downloadedFiles: const {},
        fileRelativePaths: const {},
      ),
      workId: work.id,
      albumTitle: work.title,
      unknownTitle: l10n.unknown,
      artist: artistInfo,
      artworkUrl: coverUrl,
    );

    var tracks = queue.tracks;
    var index = queue.startIndex;

    if (tracks.isEmpty && record.lastTrack != null) {
      tracks = [record.lastTrack!];
      index = 0;
    }

    // 5. Play
    if (tracks.isNotEmpty) {
      try {
        await AudioPlayerService.instance
            .updateQueue(tracks, startIndex: index);
        await AudioPlayerService.instance
            .seek(Duration(milliseconds: record.lastPositionMs));
        await AudioPlayerService.instance.play();
        ref.read(historyProvider.notifier).addOrUpdate(work);
      } catch (e) {
        _log.captureOutput('Failed to resume playback: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.playbackFailed(e.toString()))),
          );
        }
      }
    }
  }
}
