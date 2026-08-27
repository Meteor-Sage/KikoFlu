import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/proxy_config.dart';

/// 代理设置（UI 层状态）
class ProxySettings {
  final ProxyMode mode;
  final bool enabled;
  final String address;

  const ProxySettings({this.mode = ProxyMode.system, this.address = ''})
    : enabled = mode != ProxyMode.direct;

  ProxySettings copyWith({ProxyMode? mode, String? address}) {
    return ProxySettings(
      mode: mode ?? this.mode,
      address: address ?? this.address,
    );
  }
}

/// 代理设置 Notifier：修改后同步持久化到 [ProxyConfig]
class ProxySettingsNotifier extends StateNotifier<ProxySettings> {
  ProxySettingsNotifier()
    : super(
        ProxySettings(mode: ProxyConfig.mode, address: ProxyConfig.address),
      );

  Future<void> setMode(ProxyMode value) async {
    state = state.copyWith(mode: value);
    await ProxyConfig.saveMode(value, state.address);
    if (value == ProxyMode.system) {
      await ProxyConfig.refreshSystemProxy();
    }
  }

  /// Compatibility API for the old two-state settings UI.
  @Deprecated('Use setMode instead')
  Future<void> setEnabled(bool value) async {
    await setMode(value ? ProxyMode.manual : ProxyMode.direct);
  }

  Future<bool> setAddress(String value) async {
    if (value.trim().isNotEmpty &&
        ProxyConfig.normalizeAddress(value) == null) {
      return false;
    }
    final normalized = value.trim().isEmpty
        ? ''
        : ProxyConfig.normalizeAddress(value)!;
    state = state.copyWith(address: normalized);
    await ProxyConfig.saveMode(state.mode, normalized);
    return true;
  }
}

final proxySettingsProvider =
    StateNotifierProvider<ProxySettingsNotifier, ProxySettings>(
  (ref) => ProxySettingsNotifier(),
);
