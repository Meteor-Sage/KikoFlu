import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/history_record.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../services/audio_player_service.dart';
import '../screens/work_detail_screen.dart';
import '../utils/string_utils.dart';
import '../providers/lyric_provider.dart';

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
              title: const Text('删除记录'),
              content: Text('确定要删除 "${work.title}" 的播放记录吗？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(historyProvider.notifier).remove(work.id);
                    Navigator.pop(context);
                  },
                  child: const Text('删除'),
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
                  CachedNetworkImage(
                    imageUrl: work.getCoverImageUrl(host, token: token),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.image, color: Colors.grey)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey)),
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
                            Colors.black.withOpacity(0.7),
                          ],
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
                  if (record.lastTrack != null) ...[
                    Text(
                      record.lastTrack!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${formatDuration(Duration(milliseconds: record.lastPositionMs))} / ${formatDuration(record.lastTrack!.duration ?? Duration.zero)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.play_arrow, size: 18),
                            onPressed: () async {
                              // Update file list for subtitle matching
                              try {
                                final apiService =
                                    ref.read(kikoeruApiServiceProvider);
                                final allFiles =
                                    await apiService.getWorkTracks(work.id);
                                ref
                                    .read(fileListControllerProvider.notifier)
                                    .updateFiles(allFiles);
                              } catch (e) {
                                print(
                                    'Failed to update file list for subtitles: $e');
                              }

                              // Resume playback
                              await AudioPlayerService.instance
                                  .updateQueue([record.lastTrack!]);
                              await AudioPlayerService.instance.seek(Duration(
                                  milliseconds: record.lastPositionMs));
                              await AudioPlayerService.instance.play();

                              // Also update history to bring it to top
                              ref
                                  .read(historyProvider.notifier)
                                  .addOrUpdate(work);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      '尚未播放',
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
}
