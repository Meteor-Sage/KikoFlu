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
import 'package:real_liquid_glass/real_liquid_glass.dart';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:sqlite3/open.dart' as sqlite3_open;

import 'src/screens/login_screen.dart';
import 'src/screens/main_screen.dart';
import 'src/widgets/desktop_floating_lyric.dart';
import 'src/utils/theme.dart';
import 'src/services/storage_service.dart';
import 'src/services/proxy_config.dart';
import 'src/services/account_database.dart';
import 'src/services/cache_service.dart';
import 'src/services/download_service.dart';
import 'src/services/audio_haptics_service.dart';
import 'src/services/floating_lyric_service.dart';
import 'src/services/log_service.dart';
import 'src/services/audio_player_service.dart';
import 'src/services/playback_history_service.dart';
import 'src/services/platform_appearance_service.dart';
import 'src/models/work.dart';
import 'l10n/app_localizations.dart';
import 'src/providers/audio_provider.dart';
import 'src/providers/auth_provider.dart';
import 'src/providers/locale_provider.dart';
import 'src/providers/theme_provider.dart';
import 'src/providers/update_provider.dart';
import 'src/utils/desktop_window_options.dart';
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
    final httpProxyUrl = ProxyConfig.httpProxyUrl;
    final httpsProxyUrl = ProxyConfig.httpsProxyUrl;
    final hasProxy = httpProxyUrl != null || httpsProxyUrl != null;

    // media_kit/mpv is a native network stack and does not inherit Dart's
    // HttpOverrides. Export the configured HTTP proxy before libmpv is
    // initialized so direct URL playback uses the same route as API/Dio.
    if (hasProxy) {
      if (httpProxyUrl != null) {
        _setEnv('http_proxy', httpProxyUrl);
        _setEnv('HTTP_PROXY', httpProxyUrl);
      }
      if (httpsProxyUrl != null) {
        _setEnv('https_proxy', httpsProxyUrl);
        _setEnv('HTTPS_PROXY', httpsProxyUrl);
      }
      // Keep loopback, private IPv4, and local IPv6 endpoints on the direct
      // path, matching ProxyConfig.findProxyFor().
      const noProxy =
          'localhost,127.*,10.*,169.254.*,192.168.*,172.16.*,172.17.*,'
          '172.18.*,172.19.*,172.20.*,172.21.*,172.22.*,172.23.*,'
          '172.24.*,172.25.*,172.26.*,172.27.*,172.28.*,172.29.*,'
          '172.30.*,172.31.*,::1,fc00::*,fd*,fe80::*';
      _setEnv('no_proxy', noProxy);
      _setEnv('NO_PROXY', noProxy);
      LogService.instance.captureOutput(
        '[Audio] Native proxy configured: http=$httpProxyUrl https=$httpsProxyUrl',
      );
    } else {
      // A direct-mode session must also bypass proxy variables inherited from
      // the shell or an older launcher environment.
      _setEnv('no_proxy', '*');
      _setEnv('NO_PROXY', '*');
    }

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
volume-max=400
log-file=mpv_debug.log
msg-level=all=v
video=no
sub-auto=no
''';
      } else if (Platform.isLinux) {
        configContent = '''
audio-spdif=ac3,dts,eac3
volume-max=400
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
volume-max=400
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
volume-max=400
log-file=mpv_debug.log
msg-level=all=v
video=no
sub-auto=no
''';
      } else {
        configContent = '''
volume-max=400
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

  if (Platform.isAndroid) {
    await enableEdgeToEdgeSystemUi();
  }

  // 初始化代理配置，并让所有 HttpClient（API/下载/音频流）走代理
  await ProxyConfig.init();
  HttpOverrides.global = KikoFluHttpOverrides();

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

  // Use media_kit only for desktop platforms. Android is natively supported
  // by just_audio and should stay on its Media3/AudioTrack backend.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await _configureMpv();
    JustAudioMediaKit.ensureInitialized();
  }

  if (Platform.isWindows || Platform.isLinux) {
    _initSqfliteFfi();
    databaseFactory = createDatabaseFactoryFfi(ffiInit: _initSqfliteFfi);
  }

  // Set minimum window size for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    final windowOptions = createDesktopWindowOptions(
      isWindows: Platform.isWindows,
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

  // Android applies this together with edge-to-edge before initialization.
  if (!Platform.isAndroid) {
    SystemChrome.setSystemUIOverlayStyle(transparentSystemBarsStyle);
  }

  // 允许横竖屏旋�?
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  if (Platform.isMacOS) {
    await PlatformAppearanceService.instance.initialize();
  }

  // Resolve the real native-material capability before providers choose the
  // first-run navigation style. Older Apple OSes stay on the classic default.
  await LiquidGlass.capabilities();

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
  final _appearanceService = PlatformAppearanceService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isMacOS) {
      _appearanceService.addListener(_handleAppearanceChanged);
      unawaited(_initializeMacOSAppearance());
    }
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

  Future<void> _initializeMacOSAppearance() async {
    await _appearanceService.initialize();
    await _appearanceService.setMode(
      ref.read(themeSettingsProvider).toThemeMode(),
    );
  }

  void _handleAppearanceChanged() {
    if (mounted) setState(() {});
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
    if (Platform.isMacOS) {
      _appearanceService.removeListener(_handleAppearanceChanged);
    }
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
      AudioPlayerService.instance.persistPlaybackPosition();
    }
  }

  @override
  void onWindowClose() async {
    // 桌面端关闭窗口时 flush 播放历史
    await PlaybackHistoryService.instance.flushNow(reason: FlushReason.dispose);
    await AudioPlayerService.instance.persistPlaybackPosition();
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
    if (Platform.isMacOS) {
      ref.listen<AppThemeMode>(
        themeSettingsProvider.select((settings) => settings.themeMode),
        (previous, next) {
          unawaited(
            _appearanceService.setMode(switch (next) {
              AppThemeMode.system => ThemeMode.system,
              AppThemeMode.light => ThemeMode.light,
              AppThemeMode.dark => ThemeMode.dark,
            }),
          );
        },
      );
    }
    final locale = ref.watch(localeProvider);
    final effectiveLocale =
        locale ?? WidgetsBinding.instance.platformDispatcher.locale;

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
        final requestedMode = switch (themeSettings.themeMode) {
          AppThemeMode.system => ThemeMode.system,
          AppThemeMode.light => ThemeMode.light,
          AppThemeMode.dark => ThemeMode.dark,
        };
        final mode = Platform.isMacOS
            ? PlatformAppearanceService.resolveMacOSThemeMode(
                requestedMode,
                _appearanceService.effectiveBrightness,
              )
            : requestedMode;

        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          title: 'Kikoeru',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          locale: locale,
          theme: AppTheme.lightTheme(
            lightScheme,
            themeSettings.colorSchemeType,
            effectiveLocale,
          ),
          darkTheme: AppTheme.darkTheme(
            darkScheme,
            themeSettings.colorSchemeType,
            effectiveLocale,
          ),
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
