import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import '../providers/settings_provider.dart';

class FloatingFeedModeAction {
  const FloatingFeedModeAction({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
}

class FloatingFeedToolAction {
  const FloatingFeedToolAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;
}

/// Two floating capsules used by feed surfaces: modes on the left and tools
/// on the right. The surface remains translucent without applying extra blur
/// filters, so a page only needs one shared top backdrop filter.
class FloatingFeedToolbar extends StatelessWidget {
  const FloatingFeedToolbar({
    super.key,
    required this.modeActions,
    required this.toolActions,
    this.collapseModesWhenNeeded = true,
  }) : assert(modeActions.length > 0);

  final List<FloatingFeedModeAction> modeActions;
  final List<FloatingFeedToolAction> toolActions;

  /// Replaces the mode row with a dropdown when it cannot fit beside tools.
  ///
  /// Dense filter sets such as online bookmarks use the dropdown. Short,
  /// primary navigation sets can disable this to keep every option visible;
  /// in very narrow layouts their capsule scrolls horizontally instead.
  final bool collapseModesWhenNeeded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const surfacePadding = 8.0;
          const capsuleGap = 8.0;
          final toolWidth = toolActions.isEmpty
              ? 0.0
              : surfacePadding + toolActions.length * 40.0;
          final availableModeWidth =
              (constraints.maxWidth -
                      toolWidth -
                      (toolActions.isEmpty ? 0 : capsuleGap))
                  .clamp(0.0, constraints.maxWidth)
                  .toDouble();
          final requiredModeWidth =
              surfacePadding +
              modeActions.fold<double>(
                0,
                (width, action) =>
                    width + _modeActionWidth(context, action.label),
              );
          final modesOverflow = requiredModeWidth > availableModeWidth;
          final useDropdown = collapseModesWhenNeeded && modesOverflow;
          final selectedIndex = modeActions.indexWhere(
            (action) => action.isSelected,
          );
          final selectedAction =
              modeActions[selectedIndex < 0 ? 0 : selectedIndex];
          final maxDropdownWidth = availableModeWidth > surfacePadding
              ? availableModeWidth - surfacePadding
              : availableModeWidth;
          final desiredDropdownWidth =
              _modeActionWidth(context, selectedAction.label) + 24;
          final dropdownWidth = desiredDropdownWidth < maxDropdownWidth
              ? desiredDropdownWidth
              : maxDropdownWidth;

          final modeRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in modeActions) _ModeButton(action: action),
            ],
          );
          final modeContent = !collapseModesWhenNeeded && modesOverflow
              ? SizedBox(
                  width: availableModeWidth,
                  child: SingleChildScrollView(
                    key: const ValueKey('feed-mode-scroll'),
                    scrollDirection: Axis.horizontal,
                    child: modeRow,
                  ),
                )
              : modeRow;
          final modeSurface = FloatingToolbarSurface(
            key: const ValueKey('feed-mode-capsule'),
            child: useDropdown
                ? _ModeDropdown(actions: modeActions, maxWidth: dropdownWidth)
                : modeContent,
          );

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(fit: FlexFit.loose, child: modeSurface),
              if (toolActions.isNotEmpty) ...[
                const SizedBox(width: capsuleGap),
                FloatingToolbarSurface(
                  key: const ValueKey('feed-tool-capsule'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final action in toolActions)
                        _ToolButton(action: action),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  double _modeActionWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return 24 + 18 + 6 + painter.width;
  }
}

class _ModeDropdown extends StatelessWidget {
  const _ModeDropdown({required this.actions, required this.maxWidth});

  final List<FloatingFeedModeAction> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = actions.indexWhere((action) => action.isSelected);
    final effectiveIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final selected = actions[effectiveIndex];
    return SizedBox(
      key: const ValueKey('feed-mode-dropdown'),
      height: 40,
      width: maxWidth,
      child: PopupMenuButton<int>(
        tooltip: selected.label,
        position: PopupMenuPosition.under,
        onSelected: (index) => actions[index].onPressed(),
        itemBuilder: (context) => [
          for (var index = 0; index < actions.length; index++)
            PopupMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  Icon(actions[index].icon, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(actions[index].label)),
                  if (actions[index].isSelected) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.check,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(selected.icon, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selected.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared horizontal inset for all floating controls in feed-like screens.
/// Landscape uses a wider inset so every floating capsule shares the same
/// left and right edges across tabs and nested toolbars.
class FloatingToolbarLayout {
  const FloatingToolbarLayout._();

  static double horizontalPadding(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape
        ? 24.0
        : 8.0;
  }
}

/// Shared translucent capsule surface for toolbars that need custom content.
class FloatingToolbarSurface extends ConsumerWidget {
  static const double backgroundOpacity = 0.94;
  static const double _radius = 24;

  const FloatingToolbarSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    final fallbackGlassTransparency =
        ref.watch(fallbackGlassTransparencyProvider);
    final content = Material(
      type: MaterialType.transparency,
      child: Padding(padding: padding, child: child),
    );

    if (useLiquidGlass) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: LiquidGlassContainer(
          shape: const LiquidGlassShape.capsule(),
          style: LiquidGlassStyle.regular,
          fallbackIntensity: fallbackGlassTransparency,
          child: content,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: Material(
          color: theme.colorScheme.surfaceContainer.withValues(
            alpha: backgroundOpacity,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Keeps a secondary floating toolbar aligned with a collapsible primary
/// toolbar without rebuilding or moving the scrollable below it.
class FloatingToolbarPositionFollower extends StatefulWidget {
  const FloatingToolbarPositionFollower({
    super.key,
    required this.primaryToolbarVisible,
    required this.visibleTop,
    required this.hiddenTop,
    required this.left,
    required this.right,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
  });

  final ValueListenable<bool> primaryToolbarVisible;
  final double visibleTop;
  final double hiddenTop;
  final double left;
  final double right;
  final Widget child;
  final Duration duration;

  @override
  State<FloatingToolbarPositionFollower> createState() =>
      _FloatingToolbarPositionFollowerState();
}

class _FloatingToolbarPositionFollowerState
    extends State<FloatingToolbarPositionFollower> {
  late bool _primaryToolbarVisible;
  final LayerLink _toolbarLayerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController()
    ..show();

  @override
  void initState() {
    super.initState();
    _primaryToolbarVisible = widget.primaryToolbarVisible.value;
    widget.primaryToolbarVisible.addListener(_handleVisibilityChanged);
  }

  @override
  void didUpdateWidget(FloatingToolbarPositionFollower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryToolbarVisible != widget.primaryToolbarVisible) {
      oldWidget.primaryToolbarVisible.removeListener(_handleVisibilityChanged);
      _primaryToolbarVisible = widget.primaryToolbarVisible.value;
      widget.primaryToolbarVisible.addListener(_handleVisibilityChanged);
    }
  }

  @override
  void dispose() {
    widget.primaryToolbarVisible.removeListener(_handleVisibilityChanged);
    super.dispose();
  }

  void _handleVisibilityChanged() {
    final visible = widget.primaryToolbarVisible.value;
    if (_primaryToolbarVisible == visible) return;
    setState(() => _primaryToolbarVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      top: _primaryToolbarVisible ? widget.visibleTop : widget.hiddenTop,
      left: widget.left,
      right: widget.right,
      // Paint the toolbar in the root overlay so a page-level backdrop blur
      // cannot cover the native glass capsule.
      child: LayoutBuilder(
        builder: (context, constraints) => OverlayPortal(
          controller: _overlayController,
          overlayLocation: OverlayChildLocation.rootOverlay,
          overlayChildBuilder: (context) => CompositedTransformFollower(
            link: _toolbarLayerLink,
            showWhenUnlinked: false,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: constraints.maxWidth,
                child: widget.child,
              ),
            ),
          ),
          child: CompositedTransformTarget(
            link: _toolbarLayerLink,
            child: const SizedBox(height: 48),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.action});

  final FloatingFeedModeAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: action.isSelected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: action.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: action.isSelected
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 18,
                  color: action.isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: action.isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: action.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.action});

  final FloatingFeedToolAction action;

  @override
  Widget build(BuildContext context) {
    return FloatingToolbarIconButton(
      icon: action.icon,
      tooltip: action.tooltip,
      onPressed: action.onPressed,
      isSelected: action.isSelected,
    );
  }
}

/// Icon-only action button for toolbars that use a custom capsule grouping.
class FloatingToolbarIconButton extends StatelessWidget {
  const FloatingToolbarIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isSelected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon),
        iconSize: 20,
        padding: EdgeInsets.zero,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.32),
      ),
    );
  }
}

/// A shallow, single-pass backdrop blur whose opacity fades into the content.
/// Keeping the filtered area bounded avoids applying blur to the whole feed.
class ProgressiveTopBlur extends StatelessWidget {
  const ProgressiveTopBlur({super.key, required this.height, this.sigma = 14});

  final double height;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.paddingOf(context).top <= 0) {
      return const SizedBox.shrink();
    }
    final surface = Theme.of(context).colorScheme.surface;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRect(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.58, 1],
            ).createShader(bounds),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: sigma,
                sigmaY: sigma,
                tileMode: TileMode.decal,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      surface.withValues(alpha: 0.72),
                      surface.withValues(alpha: 0.34),
                      surface.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.58, 1],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
