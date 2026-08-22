import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/widgets/work_detail/work_detail_responsive_layout.dart';
import 'package:kikoeru_flutter/src/widgets/liquid_glass_layout.dart';

Widget _testApp({
  required Orientation orientation,
  required Widget child,
}) {
  final size = orientation == Orientation.landscape
      ? const Size(900, 500)
      : const Size(400, 800);

  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
      ),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('uses a vertical scrolling layout in portrait', (tester) async {
    await tester.pumpWidget(
      _testApp(
        orientation: Orientation.portrait,
        child: WorkDetailResponsiveLayout(
          coverBuilder: (context, isLandscape) =>
              Text(isLandscape ? 'landscape-cover' : 'portrait-cover'),
          info: const Text('info'),
        ),
      ),
    );

    expect(find.text('portrait-cover'), findsOneWidget);
    expect(find.text('info'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsNothing);
  });

  testWidgets('uses a split scrolling layout in landscape', (tester) async {
    await tester.pumpWidget(
      _testApp(
        orientation: Orientation.landscape,
        child: WorkDetailResponsiveLayout(
          coverBuilder: (context, isLandscape) =>
              Text(isLandscape ? 'landscape-cover' : 'portrait-cover'),
          info: const Text('info'),
        ),
      ),
    );

    expect(find.text('landscape-cover'), findsOneWidget);
    expect(find.text('info'), findsOneWidget);
    expect(find.byType(Row), findsOneWidget);
    expect(find.byType(Expanded), findsNWidgets(2));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('wraps the active scroll view with refresh when provided',
      (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      _testApp(
        orientation: Orientation.portrait,
        child: WorkDetailResponsiveLayout(
          coverBuilder: (context, isLandscape) => const Text('cover'),
          info: const Text('info'),
          onRefresh: () async => refreshCount++,
        ),
      ),
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.fling(
      find.byType(SingleChildScrollView),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(refreshCount, 1);
  });

  testWidgets('reserves the measured liquid glass dock extent', (tester) async {
    final dockExtent = ValueNotifier<double>(96);
    addTearDown(dockExtent.dispose);

    await tester.pumpWidget(
      _testApp(
        orientation: Orientation.portrait,
        child: LiquidGlassDockScope(
          notifier: dockExtent,
          child: WorkDetailResponsiveLayout(
            coverBuilder: (context, isLandscape) => const Text('cover'),
            info: const Text('info'),
          ),
        ),
      ),
    );

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final content = scrollView.child! as Padding;
    expect(content.padding, const EdgeInsets.only(bottom: 96));

    dockExtent.value = 120;
    await tester.pump();

    final updatedScrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    final updatedContent = updatedScrollView.child! as Padding;
    expect(updatedContent.padding, const EdgeInsets.only(bottom: 120));
  });
}
