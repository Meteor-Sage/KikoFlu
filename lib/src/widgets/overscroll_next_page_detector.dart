import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// A widget that detects overscroll at the bottom of a ScrollView and triggers an action.
/// It provides a visual "stretch" feedback and a text prompt.
class OverscrollNextPageDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onNextPage;
  final bool hasNextPage;
  final bool isLoading;
  final String? promptText;
  final String? releaseText;
  final double triggerThreshold;

  const OverscrollNextPageDetector({
    super.key,
    required this.child,
    this.onNextPage,
    this.hasNextPage = false,
    this.isLoading = false,
    this.promptText,
    this.releaseText,
    this.triggerThreshold = 100.0,
  });

  @override
  State<OverscrollNextPageDetector> createState() =>
      _OverscrollNextPageDetectorState();
}

class _OverscrollNextPageDetectorState
    extends State<OverscrollNextPageDetector> {
  double _overscroll = 0;
  bool _isTriggered = false;
  bool _isUserDragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: widget.child,
        ),
        if (_overscroll > 0 && widget.hasNextPage && !widget.isLoading)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _overscroll.clamp(0.0, 200.0),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Opacity(
                opacity:
                    (_overscroll / widget.triggerThreshold).clamp(0.0, 1.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isTriggered
                          ? Icons.arrow_circle_up
                          : Icons.keyboard_double_arrow_up,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isTriggered
                          ? (widget.releaseText ??
                              S.of(context).releaseForNextPage)
                          : (widget.promptText ??
                              S.of(context).pullDownForNextPage),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!widget.hasNextPage || widget.isLoading) {
      if (_overscroll > 0 || _isTriggered || _isUserDragging) {
        _resetOverscroll();
      }
      return false;
    }

    if (notification.depth != 0) {
      return false;
    }

    if (notification is ScrollStartNotification) {
      if (_overscroll > 0 || _isTriggered) {
        _resetOverscroll();
      }
      _isUserDragging = notification.dragDetails != null;
      return false;
    }

    if (notification is OverscrollNotification) {
      if (notification.dragDetails != null) {
        _isUserDragging = true;
      }

      if (_isUserDragging &&
          notification.overscroll > 0 &&
          _isAtBottom(notification.metrics)) {
        _updateOverscroll(
          (_overscroll + notification.overscroll / 2).clamp(0.0, 200.0),
        );
      }
    } else if (notification is ScrollUpdateNotification) {
      final isDraggingUpdate = notification.dragDetails != null;

      if (isDraggingUpdate) {
        _isUserDragging = true;
      } else if (_isUserDragging) {
        // Finger released. Keep the current trigger state armed until
        // ScrollEndNotification arrives, otherwise the elastic bounce-back
        // phase will clear the pending next-page action prematurely.
        _isUserDragging = false;
      }

      final bottomOverscroll = _bottomOverscroll(notification.metrics);
      if (isDraggingUpdate && bottomOverscroll > 0) {
        _updateOverscroll(bottomOverscroll.clamp(0.0, 200.0));
      } else if (isDraggingUpdate && _overscroll > 0 && bottomOverscroll <= 0) {
        _resetOverscroll(keepDraggingState: true);
      }
    } else if (notification is ScrollEndNotification) {
      final shouldTrigger = _isTriggered;
      _resetOverscroll();
      if (shouldTrigger) {
        widget.onNextPage?.call();
      }
    }

    return false;
  }

  bool _isAtBottom(ScrollMetrics metrics) {
    return metrics.extentAfter == 0 ||
        metrics.pixels >= metrics.maxScrollExtent;
  }

  double _bottomOverscroll(ScrollMetrics metrics) {
    if (metrics.pixels <= metrics.maxScrollExtent) {
      return 0;
    }
    return metrics.pixels - metrics.maxScrollExtent;
  }

  void _updateOverscroll(double value) {
    final clamped = value.clamp(0.0, 200.0);
    final triggered = clamped >= widget.triggerThreshold;

    if (_overscroll == clamped && _isTriggered == triggered) {
      return;
    }

    setState(() {
      _overscroll = clamped;
      _isTriggered = triggered;
    });
  }

  void _resetOverscroll({bool keepDraggingState = false}) {
    if (_overscroll == 0 &&
        !_isTriggered &&
        (_isUserDragging == keepDraggingState)) {
      return;
    }

    setState(() {
      _overscroll = 0;
      _isTriggered = false;
      if (!keepDraggingState) {
        _isUserDragging = false;
      }
    });
  }
}
