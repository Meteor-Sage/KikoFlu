import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;

import 'src/screens/login_screen.dart';
import 'src/screens/main_screen.dart';
import 'src/widgets/desktop_floating_lyric.dart';
import 'src/utils/theme.dart';
import 'src/services/storage_service.dart';
import 'src/services/account_database.dart';
import 'src/services/cache_service.dart';
import 'src/services/download_service.dart';
import 'src/services/audio_haptics_service.dart';
import 'src/services/floating_lyric_service.dart';
import 'src/services/log_service.dart';
import 'src/services/audio_player_service.dart';
import 'src/services/playback_history_service.dart';
import 'src/models/work.dart';
import 'l10n/app_localizations.dart';
import 'src/providers/audio_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/locale_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/update_provider.dart';
import 'src/utils/global_keys.dart';
import 'src/utils/system_ui_style.dart';
import 'src/widgets/screen_awake_observer.dart';

void _setEnv(String key, String value) {
  if (Platform.isWindows) {
    final keyNative = key.toNativeUtf16();
    final valueNative = value.toNativeUtf16();
    try {
      final setEnvironmentVariable = ffi.DynamicLibrary.open('kernel32.dll')
          .lookupFunction<
              ffi.Int32 Function(ffi.Pointer<Utf16>, ffi.Pointer<Utf16>),
              int Function(ffi.Pointer<Utf16>,
                  ffi.Pointer<Utf16>)>('SetEnvironmentVariableW');
      setEnvironmentVariable(keyNative, valueNative);
    } finally {
      calloc.free(keyNative);
      calloc.free(valueNative);
    }
  } else if (Platform.isMacOS || Platform.isLinux) {
    final keyNative = key.toNativeUtf8();
    final valueNative = value.toNativeUtf8();
    try {
      final setenv = ffi.DynamicLibrary.process().lookupFunction<
          ffi.Int32 Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Int32),
          int Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int)>('setenv');
      setenv(keyNative, valueNative, 1);
    } finally {
      calloc.free(keyNative);
      calloc.free(valueNative);
    }
  }
}

ffi.DynamicLibrary _openSqliteOnLinux() {
  final executableDir = p.dirname(Platform.resolvedExecutable);
  final candidates = <String>[
    p.join(executableDir, 'lib', 'libsqlite3.so.0'),
    p.join(executableDir, 'lib', 'libsqlite3.so'),
    'libsqlite3.so.0',
    'libsqlite3.so',
    '/lib/aarch64-linux-gnu/libsqlite3.so.0',
    '/usr/lib/aarch64-linux-gnu/libsqlite3.so.0',
    '/lib/x86_64-linux-gnu/libsqlite3.so.0',
    '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
  ];

  Object? lastError;
  for (final candidate in candidates.toSet()) {
    try {
      return ffi.DynamicLibrary.open(candidate);
    } catch (error) {
      lastError = error;
    }
  }

  throw ArgumentError(
    'Failed to load sqlite3 on Linux. Tried: ${candidates.join(', ')}. '
    'Last error: $lastError',
  );
}

void _initSqfliteFfi() {
  if (Platform.isLinux) {
    sqlite3_open.open.overrideFor(
      sqlite3_open.OperatingSystem.linux,
      _openSqliteOnLinux,
    );
  }

  sqfliteFfiInit();
}

Future<void> _configureMpv() async {
  if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final passthrough = prefs.getBool('audio_passthrough_enabled') ?? false;

    Directory configDir;
    if (Platform.isWindows) {
      final exePath = Platform.resolvedExecutable;
      final exeDir = p.dirname(exePath);
      configDir = Directory(p.join(exeDir, 'portable_config'));
    } else {
      final appSupportDir = await getApplicationSupportDirectory();
      configDir = Directory(p.join(appSupportDir.path, 'mpv_config'));
    }

    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    final configFile = File(p.join(configDir.path, 'mpv.conf'));

    // Force set MPV_HOME to ensure config is read
    _setEnv('MPV_HOME', configDir.path);
    LogService.instance.captureOutput(
      '[Audio] Set MPV_HOME to: ${configDir.path}',
    );

    if (passthrough) {
      String configContent;
      if (Platform.isWindows) {
        configContent = '''
ao=wasapi
audio-exclusive=yes
audio-spdif=ac3,dts,eac3
log-file=mpv_debug.log
msg-level=all=v
video=no
sub-auto=no
''';
      } else if (Platform.isLinux) {
        configContent = '''
audio-spdif=ac3,dts,eac3
log-file=${p.join(configDir.path, 'mpv_debug.log')}
msg-level=all=v
video=no
sub-auto=no
''';
      } else {
        configContent = '''
ao=coreaudio
audio-exclusive=yes
audio-spdif=ac3,dts,eac3
log-file=${p.join(configDir.path, 'mpv_debug.log')}
msg-level=all=v
video=no
sub-auto=no
''';
      }

      await configFile.writeAsString(configContent);
      LogService.instance.captureOutput(
        '[Audio] Updated mpv.conf: Exclusive Mode ENABLED (Forced)',
      );
    } else {
      // 即使不开启直通，也建议禁用视频输出以避免 Texture 崩溃
      String configContent;
      if (Platform.isWindows) {
        configContent = '''
log-file=mpv_debug.log
msg-level=all=v
video=no
sub-auto=no
''';
      } else {
        configContent = '''
log-file=${p.join(configDir.path, 'mpv_debug.log')}
msg-level=all=v
video=no
sub-auto=no
''';
      }
      await configFile.writeAsString(configContent);
      LogService.instance
          .captureOutput('[Audio] Updated mpv.conf: Video Disabled');
    }
  } catch (e) {
    LogService.instance.captureOutput('[Audio] Error configuring mpv: $e');
  }
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化日志系统，拦截 print/debugPrint 输出
  setupLogCapture();

  if (args.firstOrNull == 'multi_window') {
    final windowId = args.length > 1 ? args[1] : '0';
    Map<String, dynamic> argument;
    try {
      argument = (args.length > 2 && args[2].isNotEmpty)
          ? jsonDecode(args[2]) as Map<String, dynamic>
          : const <String, dynamic>{};
    } catch (e) {
      LogService.instance.captureOutput(
        '[MultiWindow] Failed to parse arguments: $e',
      );
      argument = const <String, dynamic>{};
    }

    // Initialize window manager for the new window
    await windowManager.ensureInitialized();

    runApp(DesktopFloatingLyric(
      windowId: windowId,
      arguments: argument,
    ));
    return;
  }

  // Initialize just_audio_media_kit for desktop and Android platforms
  if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS ||
      Platform.isAndroid) {
    await _configureMpv();
    JustAudioMediaKit.ensureInitialized(android: true);
  }

  if (Platform.isWindows || Platform.isLinux) {
    _initSqfliteFfi();
    databaseFactory = createDatabaseFactoryFfi(ffiInit: _initSqfliteFfi);
  }

  // Set minimum window size for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(350, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Initialize Hive for local storage
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // For desktop platforms, use application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(p.join(appDocDir.path, 'KikoFlu'));
  } else {
    // For mobile platforms, use default path
    await Hive.initFlutter();
  }
  await StorageService.init();

  // Initialize account database
  await AccountDatabase.instance.database;

  // 启动时检查并清理缓存（如果超过上限）
  CacheService.checkAndCleanCache(force: true).catchError((e) {
    LogService.instance.captureOutput('[Cache] 启动时检查缓存失�? $e');
  });

  // 初始化下载服�?
  await DownloadService.instance.initialize();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(transparentSystemBarsStyle);

  // 允许横竖屏旋�?
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runZonedGuarded(
    () => runApp(const ProviderScope(child: KikoeruApp())),
    (error, stack) {
      LogService.instance.error('$error\n$stack', tag: 'Zone');
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        parent.print(zone, line);
        LogService.instance.captureOutput(line);
      },
    ),
  );
}

class KikoeruApp extends ConsumerStatefulWidget {
  const KikoeruApp({super.key});

  @override
  ConsumerState<KikoeruApp> createState() => _KikoeruAppState();
}

class _KikoeruAppState extends ConsumerState<KikoeruApp>
    with WindowListener, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
    // Initialize audio and video services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPlaybackHistoryService();
      ref.read(audioPlayerControllerProvider.notifier).initialize();

      // Silent update check on startup
      _checkForUpdates();
    });
  }

  void _initPlaybackHistoryService() {
    final historyService = PlaybackHistoryService.instance;

    // 注入 Work 获取回调
    historyService.onFetchWork = (workId) async {
      final api = ref.read(kikoeruApiServiceProvider);
      final json = await api.getWork(workId);
      return Work.fromJson(json);
    };

    // 绑定播放器
    historyService.attachPlayer(AudioPlayerService.instance);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isForegroundActive = state == AppLifecycleState.resumed;
    AudioHapticsService.instance.setForegroundActive(isForegroundActive);

    // 应用进入后台时立即 flush 播放历史
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      PlaybackHistoryService.instance
          .flushNow(reason: FlushReason.appBackground);
    }
  }

  @override
  void onWindowClose() async {
    // 桌面端关闭窗口时 flush 播放历史
    await PlaybackHistoryService.instance.flushNow(reason: FlushReason.dispose);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 关闭主窗口时，同时关闭悬浮字幕窗口
      await FloatingLyricService.instance.hide();
    }
    super.onWindowClose();
  }

  /// Silently check for updates on startup
  Future<void> _checkForUpdates() async {
    try {
      final updateService = ref.read(updateServiceProvider);
      final updateInfo = await updateService.checkForUpdates();

      if (updateInfo != null && updateInfo.hasNewVersion) {
        ref.read(updateInfoProvider.notifier).state = updateInfo;
        ref.read(hasNewVersionProvider.notifier).state = true;

        // Check if red dot should be shown
        final shouldShow = await updateService.shouldShowRedDot();
        ref.read(showUpdateRedDotProvider.notifier).state = shouldShow;
      }
    } catch (e) {
      // Silent failure - no user notification
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeSettingsProvider);
    final locale = ref.watch(localeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // 根据用户设置决定是否使用动态颜�?
        final ColorScheme? lightScheme =
            themeSettings.colorSchemeType == ColorSchemeType.dynamic
                ? lightDynamic
                : null;
        final ColorScheme? darkScheme =
            themeSettings.colorSchemeType == ColorSchemeType.dynamic
                ? darkDynamic
                : null;

        // 根据用户设置决定主题模式
        final ThemeMode mode = switch (themeSettings.themeMode) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
        };

        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'Kikoeru',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: locale,
          theme:
              AppTheme.lightTheme(lightScheme, themeSettings.colorSchemeType),
          darkTheme:
              AppTheme.darkTheme(darkScheme, themeSettings.colorSchemeType),
          themeMode: mode,
          home: ScreenAwakeObserver(child: _buildHomeScreen()),
        );
      },
    );
  }

  Widget _buildHomeScreen() {
    final authState = ref.watch(authProvider);

    // 如果有用户信息（包括离线模式），显示主页
    // 这样用户可以访问本地下载的内�?
    if (authState.currentUser != null) {
      return const MainScreen();
    } else {
      return const LoginScreen();
    }
  }
}
