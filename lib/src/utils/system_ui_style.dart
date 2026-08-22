import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const transparentSystemBarsStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  systemStatusBarContrastEnforced: false,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarContrastEnforced: false,
);

SystemUiOverlayStyle transparentSystemBarsForBrightness(Brightness brightness) {
  final iconBrightness =
      brightness == Brightness.light ? Brightness.dark : Brightness.light;

  return transparentSystemBarsStyle.copyWith(
    statusBarIconBrightness: iconBrightness,
    systemNavigationBarIconBrightness: iconBrightness,
  );
}

Future<void> enableEdgeToEdgeSystemUi() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(transparentSystemBarsStyle);
}

Future<void> restoreSystemUiAfterImmersiveMode({
  required bool useEdgeToEdge,
}) async {
  if (useEdgeToEdge) {
    await enableEdgeToEdgeSystemUi();
    return;
  }

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(transparentSystemBarsStyle);
}
