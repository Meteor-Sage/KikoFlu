import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import '../../l10n/app_localizations.dart';
import '../providers/audio_provider.dart';
import '../providers/update_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import '../widgets/mini_player.dart';
import 'works_screen.dart';
import 'search_screen.dart';
import 'my_screen.dart';
import 'settings_screen.dart';
import '../providers/settings_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  static const int _settingsTabIndex = 3;

  // 使用 PageStorageBucket 来保存页面状态
  final PageStorageBucket _bucket = PageStorageBucket();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const [
      WorksScreen(key: PageStorageKey('works_screen')),
      SearchScreen(key: PageStorageKey('search_screen')),
      MyScreen(key: PageStorageKey('my_screen')),
      SettingsScreen(key: PageStorageKey('settings_screen')),
    ];
  }

  List<NavigationDestination> _buildDestinations(
      BuildContext context, bool showUpdateBadge) {
    final s = S.of(context);
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: s.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.search_outlined),
        selectedIcon: const Icon(Icons.search),
        label: s.navSearch,
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_border),
        selectedIcon: const Icon(Icons.favorite),
        label: s.navMy,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: showUpdateBadge,
          child: const Icon(Icons.settings_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: showUpdateBadge,
          child: const Icon(Icons.settings),
        ),
        label: s.navSettings,
      ),
    ];
  }

  void _handleDestinationSelected(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    if (index == _settingsTabIndex) {
      ref.read(settingsCacheRefreshTriggerProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final showUpdateBadge = ref.watch(showUpdateRedDotProvider);
    final useLiquidGlass = ref.watch(liquidGlassNavigationProvider);
    final destinations = _buildDestinations(context, showUpdateBadge);

    if (isLandscape) {
      // 横屏布局：使用 NavigationRail
      return Scaffold(
        body: Stack(
          children: [
            // 主内容区域
            Row(
              children: [
                // 侧边导航栏
                SafeArea(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: useLiquidGlass
                              ? const EdgeInsets.all(8)
                              : EdgeInsets.zero,
                          child: useLiquidGlass
                              ? LiquidGlassContainer(
                                  shape:
                                      const LiquidGlassShape.roundedRectangle(
                                          28),
                                  fallbackIntensity: 0.86,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: _buildNavigationRail(destinations),
                                  ),
                                )
                              : _buildNavigationRail(destinations),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // 页面内容
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authProvider);
                      final isOfflineMode = authState.currentUser != null &&
                          !authState.isLoggedIn &&
                          authState.error != null;

                      return Padding(
                        padding: EdgeInsets.only(top: isOfflineMode ? 30 : 0),
                        child: SafeArea(
                          top: false,
                          child: Column(
                            children: [
                              // 主内容
                              Expanded(
                                child: PageStorage(
                                  bucket: _bucket,
                                  child: IndexedStack(
                                    index: _currentIndex,
                                    children:
                                        List.generate(_screens.length, (index) {
                                      return HeroMode(
                                        enabled: index == _currentIndex,
                                        child: _screens[index],
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              // MiniPlayer
                              Consumer(
                                builder: (context, ref, child) {
                                  final currentTrack =
                                      ref.watch(currentTrackProvider);
                                  return currentTrack.when(
                                    data: (track) => track != null
                                        ? const MiniPlayer()
                                        : const SizedBox.shrink(),
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // 离线模式提示横幅（覆盖在顶部）
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Consumer(
                builder: (context, ref, child) {
                  final authState = ref.watch(authProvider);
                  final isOfflineMode = authState.currentUser != null &&
                      !authState.isLoggedIn &&
                      authState.error != null;

                  if (!isOfflineMode) {
                    return const SizedBox.shrink();
                  }

                  final topPadding = MediaQuery.of(context).padding.top;

                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(12, topPadding + 4, 12, 4),
                    color: Colors.orange.shade800,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            S.of(context).offlineModeMessage,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final notifier = ref.read(authProvider.notifier);
                            await notifier.retryConnection();
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            S.of(context).retry,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    // 竖屏布局：使用 BottomNavigationBar
    return Scaffold(
      // The native glass bar must overlap the page to refract its content.
      extendBody: useLiquidGlass,
      body: Stack(
        children: [
          // 主内容
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authProvider);
              final isOfflineMode = authState.currentUser != null &&
                  !authState.isLoggedIn &&
                  authState.error != null;

              return Padding(
                padding: EdgeInsets.only(top: isOfflineMode ? 30 : 0),
                child: SafeArea(
                  top: false,
                  child: PageStorage(
                    bucket: _bucket,
                    child: IndexedStack(
                      index: _currentIndex,
                      children: List.generate(_screens.length, (index) {
                        return HeroMode(
                          enabled: index == _currentIndex,
                          child: _screens[index],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
          // 离线模式提示横幅（覆盖在顶部）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authProvider);
                final isOfflineMode = authState.currentUser != null &&
                    !authState.isLoggedIn &&
                    authState.error != null;

                if (!isOfflineMode) {
                  return const SizedBox.shrink();
                }

                final topPadding = MediaQuery.of(context).padding.top;

                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(12, topPadding + 4, 12, 4),
                  color: Colors.orange.shade800,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          S.of(context).offlineModeMessage,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final notifier = ref.read(authProvider.notifier);
                          await notifier.retryConnection();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          S.of(context).retry,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _handleDestinationSelected,
        destinations: destinations,
        liquidGlass: useLiquidGlass,
        showUpdateBadge: showUpdateBadge,
        miniPlayer: Consumer(
          builder: (context, ref, child) {
            final currentTrack = ref.watch(currentTrackProvider);
            return currentTrack.when(
              data: (track) =>
                  track != null ? const MiniPlayer() : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationRail(List<NavigationDestination> destinations) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _handleDestinationSelected,
      labelType: NavigationRailLabelType.selected,
      destinations: destinations
          .map((dest) => NavigationRailDestination(
                icon: dest.icon,
                selectedIcon: dest.selectedIcon,
                label: Text(dest.label),
              ))
          .toList(),
    );
  }
}
