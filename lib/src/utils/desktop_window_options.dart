import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

WindowOptions createDesktopWindowOptions({required bool isWindows}) {
  return WindowOptions(
    size: const Size(1280, 720),
    minimumSize: const Size(350, 600),
    center: true,
    // Transparent composition can make native Windows caption glyphs blend
    // into the title bar. Leave the normal Windows frame under DWM control.
    backgroundColor: isWindows ? null : Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
}
