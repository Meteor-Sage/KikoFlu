import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audio_track.dart';
import '../models/video_track.dart';
import '../providers/audio_provider.dart';
import '../providers/video_provider.dart';
import '../widgets/audio_player_widget.dart';
import '../widgets/video_player_widget.dart';

class MediaPlayerDemoScreen extends ConsumerWidget {
  const MediaPlayerDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体播放器演示'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audio section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.audiotrack),
                        const SizedBox(width: 8),
                        Text(
                          '音频播放',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _playDemoAudio(ref);
                      },
                      child: const Text('播放示例音频'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AudioPlayerScreen(),
                          ),
                        );
                      },
                      child: const Text('打开音频播放器'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Video section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.video_library),
                        const SizedBox(width: 8),
                        Text(
                          '视频播放',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _playDemoVideo(ref, context);
                      },
                      child: const Text('播放示例视频'),
                    ),
                    const SizedBox(height: 8),
                    // Video thumbnail examples
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          final demoVideo = _getDemoVideo(index);
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            child: VideoThumbnailWidget(
                              video: demoVideo,
                              onTap: () {
                                _playVideo(ref, context, demoVideo);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Text(
                          '使用说明',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• 音频播放支持后台播放、进度控制、播放列表管理'),
                    const Text('• 视频播放支持全屏模式、手势控制、倍速播放'),
                    const Text('• 底部迷你播放器显示当前播放状态'),
                    const Text('• 所有功能都采用现代化的Material Design 3设计'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playDemoAudio(WidgetRef ref) {
    final demoTrack = AudioTrack(
      id: 'demo_audio_1',
      url:
          'https://commondatastorage.googleapis.com/codeskulptor-demos/DDR_assets/Sevish_-__nbsp_.mp3',
      title: '示例音频',
      artist: 'Sevish',
      album: '演示专辑',
      duration: const Duration(minutes: 3, seconds: 30),
    );

    ref.read(audioPlayerControllerProvider.notifier).playTrack(demoTrack);
  }

  void _playDemoVideo(WidgetRef ref, BuildContext context) {
    final demoVideo = VideoTrack(
      id: 'demo_video_1',
      url:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      title: 'Big Buck Bunny',
      description: '经典示例视频',
      duration: const Duration(minutes: 10, seconds: 34),
    );

    _playVideo(ref, context, demoVideo);
  }

  void _playVideo(WidgetRef ref, BuildContext context, VideoTrack video) {
    ref.read(videoPlayerControllerProvider.notifier).playVideo(video);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VideoPlayerScreen(),
      ),
    );
  }

  VideoTrack _getDemoVideo(int index) {
    final videos = [
      VideoTrack(
        id: 'demo_video_1',
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        title: 'Big Buck Bunny',
        description: '经典示例视频',
        duration: const Duration(minutes: 10, seconds: 34),
        thumbnailUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      ),
      VideoTrack(
        id: 'demo_video_2',
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
        title: 'Elephants Dream',
        description: '另一个示例视频',
        duration: const Duration(minutes: 10, seconds: 53),
        thumbnailUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      ),
      VideoTrack(
        id: 'demo_video_3',
        url:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        title: 'For Bigger Blazes',
        description: '第三个示例视频',
        duration: const Duration(seconds: 15),
        thumbnailUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
      ),
    ];

    return videos[index];
  }
}
