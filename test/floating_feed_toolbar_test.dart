import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/floating_feed_toolbar.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 390, child: child),
      ),
    ),
  );
}

Widget _wideTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 700, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('renders two capsules and keeps their actions interactive',
      (tester) async {
    var selectedMode = '';
    var toolTaps = 0;

    await tester.pumpWidget(
      _testApp(
        FloatingFeedToolbar(
          modeActions: [
            FloatingFeedModeAction(
              icon: Icons.grid_view,
              label: 'All',
              isSelected: true,
              onPressed: () => selectedMode = 'all',
            ),
            FloatingFeedModeAction(
              icon: Icons.local_fire_department,
              label: 'Popular',
              isSelected: false,
              onPressed: () => selectedMode = 'popular',
            ),
          ],
          toolActions: [
            FloatingFeedToolAction(
              icon: Icons.closed_caption,
              tooltip: 'Subtitles',
              isSelected: true,
              onPressed: () => toolTaps++,
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('feed-mode-capsule')), findsOneWidget);
    expect(find.byKey(const ValueKey('feed-tool-capsule')), findsOneWidget);
    expect(tester.getSize(find.byType(FloatingFeedToolbar)).height, 48);

    await tester.tap(find.text('Popular'));
    await tester.tap(find.byTooltip('Subtitles'));
    expect(selectedMode, 'popular');
    expect(toolTaps, 1);
  });

  testWidgets('progressive top treatment uses one bounded blur pass',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MediaQuery(
          data: MediaQueryData(padding: EdgeInsets.only(top: 44)),
          child: ProgressiveTopBlur(height: 96),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(tester.getSize(find.byType(ProgressiveTopBlur)).height, 96);
  });

  testWidgets('top treatment is omitted without a status bar inset',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const ProgressiveTopBlur(height: 96),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('secondary toolbar follows the primary toolbar position',
      (tester) async {
    final primaryVisible = ValueNotifier(true);
    addTearDown(primaryVisible.dispose);

    await tester.pumpWidget(
      _testApp(
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              FloatingToolbarPositionFollower(
                primaryToolbarVisible: primaryVisible,
                visibleTop: 100,
                hiddenTop: 44,
                left: 0,
                right: 0,
                child: const SizedBox(
                  key: ValueKey('secondary-toolbar'),
                  height: 48,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final visibleTop =
        tester.getTopLeft(find.byKey(const ValueKey('secondary-toolbar'))).dy;
    primaryVisible.value = false;
    await tester.pumpAndSettle();
    final hiddenTop =
        tester.getTopLeft(find.byKey(const ValueKey('secondary-toolbar'))).dy;

    expect(visibleTop - hiddenTop, 56);
  });

  testWidgets('mode capsule hugs its content and leaves tools at the edge',
      (tester) async {
    await tester.pumpWidget(
      _wideTestApp(
        FloatingFeedToolbar(
          modeActions: [
            FloatingFeedModeAction(
              icon: Icons.grid_view,
              label: 'All',
              isSelected: true,
              onPressed: () {},
            ),
          ],
          toolActions: [
            FloatingFeedToolAction(
              icon: Icons.sort,
              tooltip: 'Sort',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    final mode = tester.getRect(
      find.byKey(const ValueKey('feed-mode-capsule')),
    );
    final tools = tester.getRect(
      find.byKey(const ValueKey('feed-tool-capsule')),
    );
    expect(mode.width, lessThan(160));
    expect(tools.right, closeTo(750, 1));
  });
}
