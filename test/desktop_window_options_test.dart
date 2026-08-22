import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

import 'package:kikoeru_flutter/src/utils/desktop_window_options.dart';

void main() {
  group('createDesktopWindowOptions', () {
    test(
      'keeps the native Windows title bar out of transparent composition',
      () {
        final options = createDesktopWindowOptions(isWindows: true);

        expect(options.backgroundColor, isNull);
        expect(options.titleBarStyle, TitleBarStyle.normal);
      },
    );

    test('preserves transparent backgrounds on other desktop platforms', () {
      final options = createDesktopWindowOptions(isWindows: false);

      expect(options.backgroundColor, Colors.transparent);
      expect(options.titleBarStyle, TitleBarStyle.normal);
    });
  });
}
