import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'capabilities.dart';
import 'glass_container.dart';
import 'glass_style.dart';
import 'native_glass_view.dart';

/// One destination in a [LiquidGlassBottomBar].
class LiquidGlassBarItem {
  /// Creates a bar destination.
  const LiquidGlassBarItem({
    required this.icon,
    this.selectedIcon,
    required this.sfSymbol,
    this.selectedSfSymbol,
    required this.label,
  });

  /// Icon shown when the destination is not selected.
  final IconData icon;

  /// Icon shown when selected; falls back to [icon].
  final IconData? selectedIcon;

  /// SF Symbol rendered by the native iOS tab bar.
  final String sfSymbol;

  /// Optional selected-state SF Symbol; defaults to [sfSymbol].
  final String? selectedSfSymbol;

  /// Short destination name, shown under the icon and used for
  /// accessibility.
  final String label;
}

/// A floating capsule tab bar in the iOS 26/27 Liquid Glass idiom.
///
/// Sits above your content (typically in a [Stack], aligned to the
/// bottom) so the glass has something to refract.
///
/// The selected destination is marked by a capsule that behaves like the
/// native iOS 26 tab bar selection:
///
/// * on iOS/macOS the capsule is **real glass** (its own lensing layer on
///   the bar), elsewhere a translucent highlight;
/// * tap a destination and the capsule **slides over with a liquid
///   stretch**, landing on the item you tapped while its icon pops;
/// * **drag horizontally** anywhere on the bar and the capsule follows
///   your finger like liquid, snapping to the nearest destination when
///   you let go.
///
/// ```dart
/// LiquidGlassBottomBar(
///   items: const [
///     LiquidGlassBarItem(icon: CupertinoIcons.house, label: 'Home'),
///     LiquidGlassBarItem(icon: CupertinoIcons.search, label: 'Search'),
///   ],
///   currentIndex: _index,
///   onTap: (i) => setState(() => _index = i),
/// )
/// ```
class LiquidGlassBottomBar extends StatefulWidget {
  /// Creates the bar. [items] needs at least two destinations.
  const LiquidGlassBottomBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.tint,
    this.style = LiquidGlassStyle.regular,
    this.height = 85,
    this.margin = EdgeInsets.zero,
    this.showLabels = true,
    this.fallbackIntensity = 1.0,
  }) : assert(items.length >= 2, 'Provide at least two destinations');

  /// The destinations to display, in order.
  final List<LiquidGlassBarItem> items;

  /// Index of the selected destination.
  final int currentIndex;

  /// Called with the tapped (or drag-released) destination's index.
  final ValueChanged<int> onTap;

  /// Color of the selected icon and label. Defaults to the ambient
  /// Cupertino primary color.
  final Color? tint;

  /// Glass variant for the bar surface.
  final LiquidGlassStyle style;

  /// Bar height, excluding [margin].
  final double height;

  /// Spacing around the floating bar. The default keeps it clear of the
  /// home indicator; wrap in [SafeArea] if you need more.
  final EdgeInsetsGeometry margin;

  /// Whether to show labels under the icons.
  final bool showLabels;

  /// Fallback-effect strength on non-Apple platforms; see
  /// [LiquidGlassContainer.fallbackIntensity].
  final double fallbackIntensity;

  static const double _capsulePadding = 4;
  static const Color _pillLight = Color(0x14000000);
  static const Color _pillDark = Color(0x2EFFFFFF);

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar> {
  /// Where the slide animation starts from.
  late int _from = widget.currentIndex;

  /// Finger x-position within the bar while dragging, null otherwise.
  double? _dragX;

  @override
  void didUpdateWidget(LiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _from = oldWidget.currentIndex;
    }
  }

  int _indexAt(double x, double barWidth) {
    final itemWidth = barWidth / widget.items.length;
    return (x ~/ itemWidth).clamp(0, widget.items.length - 1);
  }

  void _select(int index) {
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();
    }
    widget.onTap(index);
  }

  /// The capsule: real glass on iOS/macOS (a lensing layer over the bar's
  /// own glass, like the native tab bar), translucent highlight elsewhere.
  Widget _capsule(BuildContext context) {
    if (LiquidGlass.isNativePlatform) {
      return const IgnorePointer(
        child: NativeGlassView(
          style: LiquidGlassStyle.regular,
          shape: LiquidGlassShape.capsule(),
          interactive: false,
        ),
      );
    }
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark
            ? LiquidGlassBottomBar._pillDark
            : LiquidGlassBottomBar._pillLight,
        borderRadius: BorderRadius.circular(widget.height / 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Padding(
        padding: widget.margin,
        child: SizedBox(
          height: widget.height,
          child: _NativeLiquidGlassTabBar(
            items: widget.items,
            currentIndex: widget.currentIndex,
            onTap: _select,
            tint: widget.tint ?? CupertinoTheme.of(context).primaryColor,
          ),
        ),
      );
    }
    final selectedColor =
        widget.tint ?? CupertinoTheme.of(context).primaryColor;
    final unselectedColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return LiquidGlassContainer(
      shape: const LiquidGlassShape.capsule(),
      style: widget.style,
      height: widget.height,
      margin: widget.margin,
      padding: const EdgeInsets.all(LiquidGlassBottomBar._capsulePadding),
      fallbackIntensity: widget.fallbackIntensity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final barWidth = constraints.maxWidth;
          final itemWidth = barWidth / widget.items.length;
          final dragging = _dragX != null;
          // While dragging, the highlight follows the finger live.
          final activeIndex = dragging
              ? _indexAt(_dragX!, barWidth)
              : widget.currentIndex;

          Widget capsuleLayer;
          if (dragging) {
            final left = (_dragX! - itemWidth / 2).clamp(
              0.0,
              barWidth - itemWidth,
            );
            capsuleLayer = Positioned(
              left: left,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: _capsule(context),
            );
          } else {
            // Liquid slide: the capsule stretches while traveling and
            // settles back into the item slot, like the native bar.
            capsuleLayer = TweenAnimationBuilder<double>(
              key: ValueKey<int>(widget.currentIndex),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: _capsule(context),
              builder: (context, t, child) {
                final fromCenter = itemWidth * (_from + 0.5);
                final toCenter = itemWidth * (widget.currentIndex + 0.5);
                final center = lerpDouble(fromCenter, toCenter, t)!;
                final travel = _from == widget.currentIndex
                    ? 0.0
                    : math.sin(math.pi * t);
                final stretchedWidth = itemWidth * (1 + 0.28 * travel);
                final squash = 2.5 * travel;
                return Positioned(
                  left: (center - stretchedWidth / 2).clamp(
                    0.0,
                    barWidth - stretchedWidth,
                  ),
                  top: squash,
                  bottom: squash,
                  width: stretchedWidth,
                  child: child!,
                );
              },
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) =>
                _select(_indexAt(details.localPosition.dx, barWidth)),
            onHorizontalDragStart: (details) =>
                setState(() => _dragX = details.localPosition.dx),
            onHorizontalDragUpdate: (details) => setState(
              () => _dragX = details.localPosition.dx.clamp(0.0, barWidth),
            ),
            onHorizontalDragEnd: (_) {
              final index = _indexAt(_dragX!, barWidth);
              setState(() => _dragX = null);
              _select(index);
            },
            onHorizontalDragCancel: () => setState(() => _dragX = null),
            child: Stack(
              children: [
                capsuleLayer,
                Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      Expanded(
                        child: _BarItem(
                          item: widget.items[i],
                          selected: i == activeIndex,
                          selectedColor: selectedColor,
                          unselectedColor: unselectedColor,
                          showLabel: widget.showLabels,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NativeLiquidGlassTabBar extends StatefulWidget {
  const _NativeLiquidGlassTabBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.tint,
  });

  final List<LiquidGlassBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color tint;

  @override
  State<_NativeLiquidGlassTabBar> createState() =>
      _NativeLiquidGlassTabBarState();
}

class _NativeLiquidGlassTabBarState extends State<_NativeLiquidGlassTabBar> {
  MethodChannel? _channel;

  Map<String, Object> get _params => {
    'labels': widget.items.map((item) => item.label).toList(),
    'symbols': widget.items.map((item) => item.sfSymbol).toList(),
    'selectedSymbols': widget.items
        .map((item) => item.selectedSfSymbol ?? item.sfSymbol)
        .toList(),
    'currentIndex': widget.currentIndex,
    'tint': widget.tint.toARGB32(),
    'dark': CupertinoTheme.of(context).brightness == Brightness.dark,
  };

  @override
  void didUpdateWidget(_NativeLiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _channel?.invokeMethod<void>('update', _params);
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UiKitView(
    viewType: 'real_liquid_glass/tab_bar',
    creationParams: _params,
    creationParamsCodec: const StandardMessageCodec(),
    onPlatformViewCreated: (id) {
      final channel = MethodChannel('real_liquid_glass/tab_bar_$id');
      _channel = channel;
      channel.setMethodCallHandler((call) async {
        if (call.method == 'selected') {
          final args = call.arguments as Map<Object?, Object?>;
          widget.onTap(args['index']! as int);
        }
      });
    },
  );
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.item,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.showLabel,
  });

  final LiquidGlassBarItem item;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;
    return Semantics(
      container: true,
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pop the icon when the capsule arrives on it.
          AnimatedScale(
            scale: selected ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: Icon(
              selected ? (item.selectedIcon ?? item.icon) : item.icon,
              size: 24,
              color: color,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
