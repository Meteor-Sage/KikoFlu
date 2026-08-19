import 'package:flutter/material.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.miniPlayer = const SizedBox.shrink(),
    this.liquidGlass = false,
    this.showUpdateBadge = false,
  });

  static const double navigationBarHeight = 58;
  static const double liquidNavigationBarHeight = 82;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget miniPlayer;
  final bool liquidGlass;
  final bool showUpdateBadge;

  @override
  Widget build(BuildContext context) {
    if (liquidGlass) {
      return _LiquidGlassBottomNavigation(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        miniPlayer: miniPlayer,
        showUpdateBadge: showUpdateBadge,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        miniPlayer,
        NavigationBar(
          height: navigationBarHeight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ],
    );
  }
}

class _LiquidGlassBottomNavigation extends StatelessWidget {
  const _LiquidGlassBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.miniPlayer,
    required this.showUpdateBadge,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget miniPlayer;
  final bool showUpdateBadge;

  static const double _barHeight =
      MainBottomNavigationBar.liquidNavigationBarHeight;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: miniPlayer,
          ),
          Padding(
            // Keep this edge exactly aligned with MiniPlayer's glass surface.
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bar = LiquidGlassContainer(
                  width: double.infinity,
                  height: _barHeight,
                  shape: const LiquidGlassShape.capsule(),
                  style: LiquidGlassStyle.clear,
                  fallbackIntensity: 0.78,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_barHeight / 2),
                    child: Row(
                      children: [
                        for (var index = 0;
                            index < destinations.length;
                            index++)
                          Expanded(
                            child: _LiquidNavigationDestination(
                              destination: destinations[index],
                              selected: index == selectedIndex,
                              onPressed: () => onDestinationSelected(index),
                            ),
                          ),
                      ],
                    ),
                  ),
                );

                if (!showUpdateBadge || destinations.isEmpty) return bar;

                final itemWidth = constraints.maxWidth / destinations.length;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    bar,
                    Positioned(
                      top: 12,
                      right: itemWidth / 2 - 4,
                      child: IgnorePointer(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidNavigationDestination extends StatelessWidget {
  const _LiquidNavigationDestination({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground =
        selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.72)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(36),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconTheme(
                    data: IconThemeData(size: 30, color: foreground),
                    child: selected
                        ? (destination.selectedIcon ?? destination.icon)
                        : destination.icon,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
