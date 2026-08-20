import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/audio_provider.dart';
import '../providers/settings_provider.dart';
import 'liquid_glass_layout.dart';
import 'mini_player.dart';

/// Global wrapper that shows the mini player on all screens except login
class GlobalAudioPlayerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final bool showMiniPlayer;

  const GlobalAudioPlayerWrapper({
    super.key,
    required this.child,
    this.showMiniPlayer = true,
  });

  @override
  ConsumerState<GlobalAudioPlayerWrapper> createState() =>
      _GlobalAudioPlayerWrapperState();
}

class _GlobalAudioPlayerWrapperState
    extends ConsumerState<GlobalAudioPlayerWrapper> {
  final ValueNotifier<double> _liquidDockExtent = ValueNotifier(0);

  @override
  void dispose() {
    _liquidDockExtent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);

    final miniPlayer = currentTrack.when(
      data: (track) => track != null
          ? const MiniPlayer(enableArtworkHero: false)
          : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );

    if (useLiquidGlass) {
      return LiquidGlassDockScope(
        notifier: _liquidDockExtent,
        child: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              LiquidGlassDockMediaQuery(child: widget.child),
              if (widget.showMiniPlayer)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LiquidGlassDockExtentReporter(
                    onChanged: (extent) {
                      if (_liquidDockExtent.value != extent) {
                        _liquidDockExtent.value = extent;
                      }
                    },
                    child: SafeArea(
                      top: false,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: miniPlayer,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: widget.child),
          if (widget.showMiniPlayer) miniPlayer,
        ],
      ),
    );
  }
}
