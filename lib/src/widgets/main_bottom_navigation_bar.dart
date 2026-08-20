import 'package:flutter/material.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import 'liquid_glass_layout.dart';

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
  // Apple's floating tab bar keeps a taller touch target than the legacy
  // Material bar, while the surrounding SafeArea supplies the home-indicator
  // inset separately.
  static const double liquidNavigationBarHeight =
      LiquidGlassLayout.navigationBarHeight;

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

  static const _items = [
    (
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      sfSymbol: 'house',
      selectedSfSymbol: 'house.fill',
    ),
    (
      icon: Icons.search_outlined,
      selectedIcon: Icons.search,
      sfSymbol: 'magnifyingglass',
      selectedSfSymbol: 'magnifyingglass',
    ),
    (
      icon: Icons.favorite_border,
      selectedIcon: Icons.favorite,
      sfSymbol: 'heart',
      selectedSfSymbol: 'heart.fill',
    ),
    (
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      sfSymbol: 'gearshape',
      selectedSfSymbol: 'gearshape.fill',
    ),
  ];

  List<LiquidGlassBarItem> _itemsForDestinations() {
    return [
      for (var index = 0; index < destinations.length; index++)
        LiquidGlassBarItem(
          icon: index < _items.length
              ? _items[index].icon
              : Icons.circle_outlined,
          selectedIcon:
              index < _items.length ? _items[index].selectedIcon : Icons.circle,
          sfSymbol: index < _items.length ? _items[index].sfSymbol : 'circle',
          selectedSfSymbol: index < _items.length
              ? _items[index].selectedSfSymbol
              : 'circle.fill',
          label: destinations[index].label,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
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
            padding: const EdgeInsets.symmetric(
              horizontal: LiquidGlassLayout.horizontalPadding,
              vertical: LiquidGlassLayout.verticalPadding,
            ),
            child: SizedBox(
              width: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bar = ClipRRect(
                    borderRadius: BorderRadius.circular(
                      LiquidGlassLayout.navigationBarHeight / 2,
                    ),
                    child: LiquidGlassBottomBar(
                      items: _itemsForDestinations(),
                      currentIndex: selectedIndex,
                      onTap: onDestinationSelected,
                      height: MainBottomNavigationBar.liquidNavigationBarHeight,
                      showLabels: true,
                      tint: Theme.of(context).colorScheme.primary,
                      fallbackIntensity: 0.86,
                    ),
                  );

                  if (!showUpdateBadge || destinations.isEmpty) return bar;

                  final itemWidth = constraints.maxWidth / destinations.length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      bar,
                      Positioned(
                        top: 10,
                        left: itemWidth * (destinations.length - 0.5) - 4,
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
          ),
        ],
      ),
    );
  }
}
