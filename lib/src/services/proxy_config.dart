import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// 全局代理配置
///
/// 网络层（dart:io HttpClient / dio 底层）通过静态字段同步读取，
/// 无需依赖 Riverpod；UI 层通过 [ProxySettingsNotifier] 修改并持久化。
class ProxyConfig {
  static const String _keyEnabled = 'proxy_enabled';
  static const String _keyAddress = 'proxy_address';

  /// 是否启用代理
  static bool enabled = false;

  /// 代理地址，格式: `127.0.0.1:7890` 或 `http://127.0.0.1:7890`
  static String address = '';

  /// 启动时从 SharedPreferences 加载配置
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_keyEnabled) ?? false;
      address = prefs.getString(_keyAddress) ?? '';
    } catch (_) {
      // 加载失败使用默认值（不启用代理）
    }
  }

  /// 保存配置（同时更新内存中的值）
  static Future<void> save(bool newEnabled, String newAddress) async {
    enabled = newEnabled;
    address = newAddress.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnabled, enabled);
      await prefs.setString(_keyAddress, address);
    } catch (_) {
      // 保存失败不影响本次会话
    }
  }

  /// 生成 dart:io findProxy 指令
  ///
  /// 返回 `DIRECT` 或 `PROXY host:port`。内网/本机地址始终直连，
  /// 避免自建 Kikoeru 服务器（192.168.x.x 等）被错误代理。
  static String findProxyFor(Uri uri) {
    if (!enabled || address.trim().isEmpty) return 'DIRECT';
    final host = uri.host;
    if (host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        _isPrivateIp(host)) {
      return 'DIRECT';
    }
    final normalized = _normalize(address.trim());
    return normalized == null ? 'DIRECT' : 'PROXY $normalized';
  }

  /// 归一化代理地址: 去掉协议头与末尾斜杠，要求 host:port 形式
  static String? _normalize(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http://')) {
      s = s.substring(7);
    } else if (s.startsWith('https://')) {
      s = s.substring(8);
    }
    // 去掉路径部分
    final slash = s.indexOf('/');
    if (slash >= 0) s = s.substring(0, slash);
    if (s.isEmpty || !s.contains(':')) return null;
    return s;
  }

  static bool _isPrivateIp(String host) {
    return host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        host.startsWith('172.16.') ||
        host.startsWith('172.31.');
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
