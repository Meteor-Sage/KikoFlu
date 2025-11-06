import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lyric.dart';
import '../providers/audio_provider.dart';
import '../providers/lyric_provider.dart';

class LyricPlayerScreen extends ConsumerStatefulWidget {
  const LyricPlayerScreen({super.key});

  @override
  ConsumerState<LyricPlayerScreen> createState() => _LyricPlayerScreenState();
}

class _LyricPlayerScreenState extends ConsumerState<LyricPlayerScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _currentLyricIndex;
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLyric(int index, List<LyricLine> lyrics) {
    if (!_autoScroll || !_scrollController.hasClients) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final itemHeight = 60.0; // 估算的每行高度
    final targetPosition =
        index * itemHeight - screenHeight / 2 + itemHeight / 2;

    _scrollController.animateTo(
      targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  int _getCurrentLyricIndex(Duration position, List<LyricLine> lyrics) {
    for (int i = 0; i < lyrics.length; i++) {
      if (position >= lyrics[i].startTime && position < lyrics[i].endTime) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final lyricState = ref.watch(lyricControllerProvider);
    final position = ref.watch(positionProvider);
    final currentTrack = ref.watch(currentTrackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('歌词'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.lock : Icons.lock_open),
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
            tooltip: _autoScroll ? '锁定滚动' : '自动滚动',
          ),
        ],
      ),
      body: currentTrack.when(
        data: (track) {
          if (track == null) {
            return const Center(child: Text('没有正在播放的音频'));
          }

          if (lyricState.lyrics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lyrics_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无歌词',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return position.when(
            data: (pos) {
              final currentIndex =
                  _getCurrentLyricIndex(pos, lyricState.lyrics);

              // 自动滚动到当前歌词
              if (currentIndex != _currentLyricIndex && currentIndex >= 0) {
                _currentLyricIndex = currentIndex;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToCurrentLyric(currentIndex, lyricState.lyrics);
                });
              }

              return NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  // 用户手动滚动时暂时禁用自动滚动
                  setState(() {
                    _autoScroll = false;
                  });
                  return false;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  itemCount: lyricState.lyrics.length,
                  itemBuilder: (context, index) {
                    final lyric = lyricState.lyrics[index];
                    final isActive = index == currentIndex;
                    // 空文本表示间隙占位符，显示 ♪
                    final isPlaceholder = lyric.text.isEmpty;

                    return GestureDetector(
                      onTap: isPlaceholder
                          ? null
                          : () {
                              // 点击歌词跳转到对应位置
                              ref
                                  .read(audioPlayerControllerProvider.notifier)
                                  .seek(lyric.startTime);
                              setState(() {
                                _autoScroll = true;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          isPlaceholder ? '♪' : lyric.text,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: isActive && !isPlaceholder
                                    ? Theme.of(context).colorScheme.primary
                                    : isPlaceholder
                                        ? Theme.of(context)
                                            .colorScheme
                                            .outline
                                            .withOpacity(0.3)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                fontWeight: isActive && !isPlaceholder
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: isActive && !isPlaceholder ? 20 : 16,
                                height: 1.5,
                              ),
                          textAlign: isPlaceholder
                              ? TextAlign.center
                              : TextAlign.start,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('加载失败')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('加载失败')),
      ),
    );
  }
}
