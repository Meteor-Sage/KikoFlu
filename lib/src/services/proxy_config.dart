import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProxyMode { direct, system, manual }

/// 全局代理配置
///
/// 网络层（dart:io HttpClient / dio 底层）通过静态字段同步读取，
/// 无需依赖 Riverpod；UI 层通过 [ProxySettingsNotifier] 修改并持久化。
class ProxyConfig {
  static const String _systemProxyChannelName =
      'com.meteor.kikoeruflutter/system_proxy';
  static const String _keyEnabled = 'proxy_enabled';
  static const String _keyAddress = 'proxy_address';
  static const String _keyMode = 'proxy_mode';

  static const MethodChannel _systemProxyChannel = MethodChannel(
    _systemProxyChannelName,
  );

  /// Current proxy mode. New installations follow the system proxy.
  static ProxyMode mode = ProxyMode.system;

  /// 代理地址，格式: `127.0.0.1:7890` 或 `http://127.0.0.1:7890`
  static String address = '';

  static String? _systemHttpProxy;
  static String? _systemHttpsProxy;

  /// Compatibility view for code written against the old boolean setting.
  /// `true` maps to manual mode and `false` maps to direct mode.
  @Deprecated('Use mode instead')
  static bool get enabled => mode != ProxyMode.direct;

  @Deprecated('Use mode instead')
  static set enabled(bool value) {
    mode = value ? ProxyMode.manual : ProxyMode.direct;
  }

  /// Returns the proxy URL format consumed by native desktop media backends.
  ///
  /// The UI deliberately stores a scheme-less `host:port` value. Native
  /// backends need an explicit HTTP scheme so they do not interpret the value
  /// as a SOCKS or otherwise unsupported proxy.
  static String? get httpProxyUrl {
    final normalized = switch (mode) {
      ProxyMode.direct => null,
      ProxyMode.manual => normalizeAddress(address),
      ProxyMode.system => _systemHttpProxy ?? _systemHttpsProxy,
    };
    return normalized == null ? null : 'http://$normalized';
  }

  /// Returns the HTTPS proxy URL consumed by native HTTP stacks.
  static String? get httpsProxyUrl {
    final normalized = switch (mode) {
      ProxyMode.direct => null,
      ProxyMode.manual => normalizeAddress(address),
      ProxyMode.system => _systemHttpsProxy ?? _systemHttpProxy,
    };
    return normalized == null ? null : 'http://$normalized';
  }

  /// 启动时从 SharedPreferences 加载配置
  static Future<void> init() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // Preferences may be unavailable during a platform bootstrap. Keep the
      // new system default and still attempt native proxy discovery below.
    }

    final storedMode = prefs?.getString(_keyMode);
    final storedAddress =
        normalizeAddress(prefs?.getString(_keyAddress) ?? '') ?? '';

    if (storedMode != null) {
      mode = _parseMode(storedMode) ?? ProxyMode.system;
      address = storedAddress;
    } else {
      // Migrate the old boolean setting without treating an empty or invalid
      // address as an enabled manual proxy.
      final oldEnabled = prefs?.getBool(_keyEnabled) ?? false;
      final migratedManual = oldEnabled && storedAddress.isNotEmpty;
      mode = migratedManual ? ProxyMode.manual : ProxyMode.system;
      address = migratedManual ? storedAddress : '';
      if (prefs != null) {
        try {
          await _persist(prefs);
        } catch (_) {
          // A migration write failure must not prevent the app from starting.
        }
      }
    }

    await refreshSystemProxy();
  }

  /// 保存配置（同时更新内存中的值）
  static Future<void> saveMode(ProxyMode newMode, String newAddress) async {
    mode = newMode;
    address = normalizeAddress(newAddress) ?? '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await _persist(prefs);
    } catch (_) {
      // 保存失败不影响本次会话
    }
  }

  /// Compatibility API for callers using the old boolean setting.
  @Deprecated('Use saveMode instead')
  static Future<void> save(bool newEnabled, String newAddress) {
    return saveMode(
      newEnabled ? ProxyMode.manual : ProxyMode.direct,
      newAddress,
    );
  }

  /// Re-read the platform proxy settings. This is called during startup and
  /// can also be used after the user changes the system proxy while running.
  static Future<void> refreshSystemProxy() async {
    _systemHttpProxy = null;
    _systemHttpsProxy = null;

    try {
      final raw = await _systemProxyChannel.invokeMethod<Object?>(
        'getSystemProxy',
      );
      _parseSystemProxy(raw);
    } catch (_) {
      // Platforms without a native bridge fall back to proxy environment
      // variables below.
    }

    _systemHttpProxy ??= _proxyFromEnvironment(
      Uri.parse('http://api.asmr-200.com/'),
    );
    _systemHttpsProxy ??= _proxyFromEnvironment(
      Uri.parse('https://api.asmr-200.com/'),
    );
  }

  /// 生成 dart:io findProxy 指令
  ///
  /// 返回 `DIRECT` 或 `PROXY host:port`。内网/本机地址始终直连，
  /// 避免自建 Kikoeru 服务器（192.168.x.x 等）被错误代理。
  static String findProxyFor(Uri uri) {
    final host = uri.host;
    if (host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        _isPrivateIp(host)) {
      return 'DIRECT';
    }

    final normalized = switch (mode) {
      ProxyMode.direct => null,
      ProxyMode.manual => normalizeAddress(address),
      ProxyMode.system =>
        uri.scheme.toLowerCase() == 'http'
            ? (_systemHttpProxy ?? _systemHttpsProxy)
            : (_systemHttpsProxy ?? _systemHttpProxy),
    };
    return normalized == null ? 'DIRECT' : 'PROXY $normalized';
  }

  static ProxyMode? _parseMode(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'direct' => ProxyMode.direct,
      'system' => ProxyMode.system,
      'manual' => ProxyMode.manual,
      _ => null,
    };
  }

  static Future<void> _persist(SharedPreferences prefs) async {
    await prefs.setString(_keyMode, mode.name);
    // Keep legacy keys coherent so downgrading cannot unexpectedly enable an
    // old manually configured proxy after the user chose system or direct.
    await prefs.setBool(
      _keyEnabled,
      mode == ProxyMode.manual && address.isNotEmpty,
    );
    await prefs.setString(_keyAddress, address);
  }

  static void _parseSystemProxy(Object? raw) {
    if (raw is Map) {
      _systemHttpProxy = normalizeAddress('${raw['http'] ?? ''}');
      _systemHttpsProxy = normalizeAddress('${raw['https'] ?? ''}');
      return;
    }
    if (raw is! String || raw.trim().isEmpty) return;

    for (final entry in raw.split(';')) {
      final value = entry.trim();
      if (value.isEmpty) continue;
      final separator = value.indexOf('=');
      final key = separator > 0
          ? value.substring(0, separator).trim().toLowerCase()
          : '';
      final endpoint = separator > 0
          ? value.substring(separator + 1).trim()
          : value;
      if (key == 'socks' || key == 'socks5') continue;
      final normalized = normalizeAddress(endpoint);
      if (normalized == null) continue;
      if (key == 'http') {
        _systemHttpProxy = normalized;
      } else if (key == 'https') {
        _systemHttpsProxy = normalized;
      } else {
        _systemHttpProxy ??= normalized;
        _systemHttpsProxy ??= normalized;
      }
    }
  }

  static String? _proxyFromEnvironment(Uri uri) {
    final directive = HttpClient.findProxyFromEnvironment(
      uri,
      environment: Platform.environment,
    );
    final match = RegExp(
      r'PROXY\s+([^;\s]+)',
      caseSensitive: false,
    ).firstMatch(directive);
    return match == null ? null : normalizeAddress(match.group(1)!);
  }

  /// Returns a canonical `host:port` value or null for malformed input.
  static String? normalizeAddress(String raw) {
    var value = raw.trim();
    if (value.isEmpty || value.contains('@')) return null;

    final scheme = RegExp(
      r'^(https?)://',
      caseSensitive: false,
    ).firstMatch(value);
    if (scheme != null) {
      value = value.substring(scheme.end);
    } else if (value.contains('://')) {
      return null;
    }

    if (value.contains('/') || value.contains('?') || value.contains('#')) {
      return null;
    }

    String host;
    String portText;
    if (value.startsWith('[')) {
      final end = value.indexOf(']');
      if (end <= 1 || end + 1 >= value.length || value[end + 1] != ':') {
        return null;
      }
      host = value.substring(1, end);
      portText = value.substring(end + 2);
    } else {
      final separator = value.lastIndexOf(':');
      if (separator <= 0 || separator == value.length - 1) return null;
      host = value.substring(0, separator);
      portText = value.substring(separator + 1);
      if (host.contains(':')) return null;
    }

    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) return null;
    if (host.isEmpty || RegExp(r'\s').hasMatch(host)) return null;

    final ip = InternetAddress.tryParse(host);
    if (ip == null && !RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$').hasMatch(host)) {
      return null;
    }

    return ip?.type == InternetAddressType.IPv6
        ? '[$host]:$port'
        : '$host:$port';
  }

  static bool _isPrivateIp(String host) {
    final address = InternetAddress.tryParse(host);
    if (address == null) return false;
    final bytes = Uint8List.fromList(address.rawAddress);
    if (address.type == InternetAddressType.IPv4) {
      return bytes[0] == 10 ||
          (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) ||
          (bytes[0] == 192 && bytes[1] == 168) ||
          (bytes[0] == 169 && bytes[1] == 254) ||
          bytes[0] == 127;
    }
    return address.isLoopback ||
        (bytes.isNotEmpty && (bytes[0] & 0xfe) == 0xfc) ||
        (bytes.length >= 2 && bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80);
  }
}

/// 全局 HttpOverrides：让所有 dart:io HttpClient（包括 dio 底层、
/// 音频流请求）统一走 [ProxyConfig] 指定的代理。
class KikoFluHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = ProxyConfig.findProxyFor;
    return client;
  }
}
