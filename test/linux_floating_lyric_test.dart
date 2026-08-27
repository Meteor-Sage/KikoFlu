import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux floating lyrics reuse the desktop multi-window path', () {
    final serviceSource = File(
      'lib/src/services/floating_lyric_service.dart',
    ).readAsStringSync();
    final providerSource = File(
      'lib/src/providers/floating_lyric_provider.dart',
    ).readAsStringSync();
    final settingsSource = File(
      'lib/src/screens/settings_screen.dart',
    ).readAsStringSync();

    expect(serviceSource, contains('Platform.isWindows || Platform.isLinux'));
    expect(serviceSource, contains('Platform.isLinux ||'));
    expect(providerSource, contains('Platform.isLinux ||'));
    expect(
      settingsSource,
      contains('Platform.isWindows || Platform.isLinux || Platform.isMacOS'),
    );
  });

  test('Linux secondary windows register transparency and input handling', () {
    final runnerSource = File(
      'linux/runner/my_application.cc',
    ).readAsStringSync();
    final pluginSource = File(
      'linux/runner/floating_lyric_plugin.cc',
    ).readAsStringSync();
    final widgetSource = File(
      'lib/src/widgets/desktop_floating_lyric.dart',
    ).readAsStringSync();

    expect(
      runnerSource,
      contains('desktop_multi_window_plugin_set_window_created_callback'),
    );
    expect(runnerSource, contains('gdk_screen_get_rgba_visual'));
    expect(runnerSource, contains('gtk_widget_set_visual'));
    expect(runnerSource, contains('fl_view_set_background_color'));
    expect(
      runnerSource,
      contains('floating_lyric_plugin_register_with_registry(registry)'),
    );
    expect(pluginSource, contains('gdk_window_set_pass_through'));
    expect(pluginSource, contains('gtk_container_forall'));
    expect(pluginSource, contains('gdk_window_set_opaque_region'));
    expect(pluginSource, contains('gtk_window_set_keep_above'));
    expect(pluginSource, contains('delete-event'));
    expect(pluginSource, contains('gtk_widget_hide'));
    expect(pluginSource, isNot(contains('gtk_widget_destroy(')));
    expect(pluginSource, contains('destroyWindow'));
    expect(pluginSource, contains('hideWindow'));
    expect(pluginSource, contains('floating_lyric_linux.log'));
    expect(pluginSource, contains('fsync'));
    expect(widgetSource, contains("'configureWindow'"));
    expect(widgetSource, contains("'setIgnoreMouseEvents'"));
    expect(widgetSource, contains("'hideWindow'"));
    expect(widgetSource, contains('setPreventClose(true)'));
    expect(widgetSource, contains('fontFamilyFallback'));
  });

  test('Linux GTK windows use the bundled application icon', () {
    final runnerSource = File(
      'linux/runner/my_application.cc',
    ).readAsStringSync();

    expect(runnerSource, contains('gtk_window_set_icon_from_file'));
    expect(runnerSource, contains('gtk_window_set_default_icon_from_file'));
    expect(runnerSource, contains('/proc/self/exe'));
    expect(runnerSource, contains('app_icon_opaque.png'));
    expect(runnerSource, contains('flutter_assets'));
  });
}
