import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/responsive_grid_helper.dart';

void main() {
  testWidgets('adapts big-grid columns to width and aspect ratio', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      ResponsiveGridHelper.getBigGridCrossAxisCount(
        context,
        availableWidth: 320,
        availableHeight: 800,
      ),
      1,
    );
    expect(
      ResponsiveGridHelper.getBigGridCrossAxisCount(
        context,
        availableWidth: 400,
        availableHeight: 800,
      ),
      2,
    );
    expect(
      ResponsiveGridHelper.getBigGridCrossAxisCount(
        context,
        availableWidth: 1024,
        availableHeight: 768,
      ),
      3,
    );
    expect(
      ResponsiveGridHelper.getBigGridCrossAxisCount(
        context,
        availableWidth: 1920,
        availableHeight: 1080,
      ),
      4,
    );
  });

  testWidgets('keeps small-grid cards usable in very narrow windows', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) {
            context = buildContext;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      ResponsiveGridHelper.getSmallGridCrossAxisCount(
        context,
        availableWidth: 320,
        availableHeight: 800,
      ),
      3,
    );
    expect(
      ResponsiveGridHelper.getSmallGridCrossAxisCount(
        context,
        availableWidth: 240,
        availableHeight: 800,
      ),
      2,
    );
  });
}
