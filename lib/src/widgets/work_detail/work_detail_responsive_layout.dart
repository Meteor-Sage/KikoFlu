import 'package:flutter/material.dart';

import '../liquid_glass_layout.dart';

typedef WorkDetailCoverBuilder = Widget Function(
  BuildContext context,
  bool isLandscape,
);

class WorkDetailResponsiveLayout extends StatelessWidget {
  const WorkDetailResponsiveLayout({
    super.key,
    required this.coverBuilder,
    required this.info,
    this.onRefresh,
  });

  final WorkDetailCoverBuilder coverBuilder;
  final Widget info;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final cover = coverBuilder(context, isLandscape);

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Center(child: cover),
          ),
          Expanded(
            flex: 3,
            child: _buildScrollable(context, info),
          ),
        ],
      );
    }

    return _buildScrollable(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cover,
          info,
        ],
      ),
    );
  }

  Widget _buildScrollable(BuildContext context, Widget child) {
    final dockExtent = LiquidGlassDockScope.extentOf(context);
    final scrollContent = dockExtent > 0
        ? Padding(
            padding: EdgeInsets.only(bottom: dockExtent),
            child: child,
          )
        : child;
    final scrollable = SingleChildScrollView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      child: scrollContent,
    );

    if (onRefresh == null) return scrollable;

    return RefreshIndicator(
      onRefresh: onRefresh!,
      child: scrollable,
    );
  }
}
