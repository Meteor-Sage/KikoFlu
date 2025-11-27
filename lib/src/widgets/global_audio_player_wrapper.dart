import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_provider.dart';
import 'mini_player.dart';

/// Global wrapper that shows the mini player on all screens except login
class GlobalAudioPlayerWrapper extends ConsumerWidget {
  final Widget child;
  final bool showMiniPlayer;

  const GlobalAudioPlayerWrapper({
    super.key,
    required this.child,
    this.showMiniPlayer = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTrack = ref.watch(currentTrackProvider);

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          if (showMiniPlayer) ...[
            currentTrack.when(
              data: (track) => track != null
                  ? const MiniPlayer(enableArtworkHero: false)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
