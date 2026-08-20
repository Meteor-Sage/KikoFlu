import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show PlatformViewHitTestBehavior;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'capabilities.dart';
import 'glass_style.dart';

/// Lets nearby glass shapes merge fluidly, like droplets.
///
/// Wrap a subtree in a group and every [LiquidGlassContainer] inside it is
/// rendered by a single native glass container (UIGlassContainerEffect on
/// iOS 26+, NSGlassEffectContainerView on macOS 26+). When two shapes come
/// within [spacing] logical pixels of each other they blend into one
/// continuous glass form — the signature "liquid" behavior. Animate a
/// container's position (e.g. with [AnimatedPositioned]) and the material
/// morphs along.
///
/// As a bonus, N containers in a group cost one platform view, not N.
///
/// On platforms without native glass the group is a plain passthrough and
/// its containers render their individual fallback surfaces.
class LiquidGlassGroup extends StatefulWidget {
  /// Creates a merge group around [child].
  const LiquidGlassGroup({
    super.key,
    required this.child,
    this.spacing = 24,
  });

  /// Subtree whose [LiquidGlassContainer]s share one glass container.
  final Widget child;

  /// Distance in logical pixels at which shapes begin to merge.
  final double spacing;

  @override
  State<LiquidGlassGroup> createState() => LiquidGlassGroupState();
}

/// State of a [LiquidGlassGroup]; containers inside the group talk to it
/// through [GlassGroupScope].
class LiquidGlassGroupState extends State<LiquidGlassGroup> {
  MethodChannel? _channel;
  final Map<int, GlassRegion> _regions = {};
  int _nextId = 0;
  bool _flushScheduled = false;

  /// Allocates an id for a region joining the group.
  int registerRegion() => _nextId++;

  /// Reports a region's current geometry and material parameters.
  void updateRegion(GlassRegion region) {
    if (_regions[region.id] == region) return;
    _regions[region.id] = region;
    _scheduleFlush();
  }

  /// Removes a region that left the tree.
  void removeRegion(int id) {
    if (_regions.remove(id) != null) _scheduleFlush();
  }

  /// The render object regions measure themselves against.
  RenderBox? get groupRenderBox => context.findRenderObject() as RenderBox?;

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    // Regions report during paint; push to the platform right after.
    Future.microtask(() {
      _flushScheduled = false;
      _flush();
    });
  }

  void _flush() {
    final channel = _channel;
    if (channel == null || !mounted) return;
    channel.invokeMethod<void>('setRegions', {
      'spacing': widget.spacing,
      'regions': [
        for (final r in _regions.values)
          {
            'id': r.id,
            'x': r.rect.left,
            'y': r.rect.top,
            'width': r.rect.width,
            'height': r.rect.height,
            'style': r.style.name,
            'tint': r.tint?.toARGB32(),
            'capsule': r.shape.capsule,
            'cornerRadius': r.shape.cornerRadius,
          },
      ],
    });
  }

  @override
  void didUpdateWidget(LiquidGlassGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spacing != oldWidget.spacing) _scheduleFlush();
  }

  @override
  Widget build(BuildContext context) {
    if (!LiquidGlass.isNativePlatform) {
      return widget.child;
    }
    final view = defaultTargetPlatform == TargetPlatform.macOS
        ? AppKitView(
            viewType: 'real_liquid_glass/glass_group',
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onViewCreated,
          )
        : UiKitView(
            viewType: 'real_liquid_glass/glass_group',
            creationParamsCodec: const StandardMessageCodec(),
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onViewCreated,
          );
    return GlassGroupScope(
      state: this,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: view)),
          widget.child,
        ],
      ),
    );
  }

  void _onViewCreated(int id) {
    _channel = MethodChannel('real_liquid_glass/glass_group_$id');
    _scheduleFlush();
  }
}

/// Geometry and material of one glass shape inside a group.
@immutable
class GlassRegion {
  /// Bundles one region's parameters for transport to the native side.
  const GlassRegion({
    required this.id,
    required this.rect,
    required this.style,
    required this.shape,
    this.tint,
  });

  /// Group-unique id from [LiquidGlassGroupState.registerRegion].
  final int id;

  /// Bounds relative to the group's origin, in logical pixels.
  final Rect rect;

  /// Material variant of this shape.
  final LiquidGlassStyle style;

  /// Outline of this shape.
  final LiquidGlassShape shape;

  /// Optional tint of this shape.
  final Color? tint;

  @override
  bool operator ==(Object other) =>
      other is GlassRegion &&
      other.id == id &&
      other.rect == rect &&
      other.style == style &&
      other.shape == shape &&
      other.tint == tint;

  @override
  int get hashCode => Object.hash(id, rect, style, shape, tint);
}

/// Inherited handle that lets containers find their enclosing group.
class GlassGroupScope extends InheritedWidget {
  /// Wires [state] into the tree below the group.
  const GlassGroupScope({
    super.key,
    required this.state,
    required super.child,
  });

  /// The group these containers belong to.
  final LiquidGlassGroupState state;

  /// The enclosing group's state, or null outside any group.
  static LiquidGlassGroupState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GlassGroupScope>()?.state;

  @override
  bool updateShouldNotify(GlassGroupScope oldWidget) =>
      state != oldWidget.state;
}

/// Invisible leaf that measures where a grouped container sits and streams
/// that geometry to the group. The glass itself is drawn natively by the
/// group's platform view.
class GlassRegionReporter extends LeafRenderObjectWidget {
  /// Creates the reporter for one grouped container.
  const GlassRegionReporter({
    super.key,
    required this.group,
    required this.style,
    required this.shape,
    this.tint,
  });

  /// The enclosing group.
  final LiquidGlassGroupState group;

  /// Material variant to report.
  final LiquidGlassStyle style;

  /// Shape to report.
  final LiquidGlassShape shape;

  /// Tint to report.
  final Color? tint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderGlassRegion(group: group, style: style, shape: shape, tint: tint);

  @override
  void updateRenderObject(
      BuildContext context, RenderGlassRegion renderObject) {
    renderObject
      ..group = group
      ..style = style
      ..shape = shape
      ..tint = tint;
  }
}

/// Render object behind [GlassRegionReporter].
class RenderGlassRegion extends RenderBox {
  /// Creates the render object; parameters mirror [GlassRegionReporter].
  RenderGlassRegion({
    required this._group,
    required this._style,
    required this._shape,
    this._tint,
  });

  LiquidGlassGroupState _group;
  LiquidGlassStyle _style;
  LiquidGlassShape _shape;
  Color? _tint;
  int? _id;

  set group(LiquidGlassGroupState value) {
    if (identical(value, _group)) return;
    _leaveGroup();
    _group = value;
    markNeedsPaint();
  }

  set style(LiquidGlassStyle value) {
    if (value == _style) return;
    _style = value;
    markNeedsPaint();
  }

  set shape(LiquidGlassShape value) {
    if (value == _shape) return;
    _shape = value;
    markNeedsPaint();
  }

  set tint(Color? value) {
    if (value == _tint) return;
    _tint = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final groupBox = _group.groupRenderBox;
    if (groupBox == null || !groupBox.attached) return;
    final topLeft = localToGlobal(Offset.zero, ancestor: groupBox);
    _id ??= _group.registerRegion();
    _group.updateRegion(GlassRegion(
      id: _id!,
      rect: topLeft & size,
      style: _style,
      shape: _shape,
      tint: _tint,
    ));
  }

  void _leaveGroup() {
    final id = _id;
    if (id != null) {
      _group.removeRegion(id);
      _id = null;
    }
  }

  @override
  void detach() {
    _leaveGroup();
    super.detach();
  }
}
