import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/proxy_config.dart';

/// 代理设置（UI 层状态）
class ProxySettings {
  final bool enabled;
  final String address;

  const ProxySettings({this.enabled = false, this.address = ''});

  ProxySettings copyWith({bool? enabled, String? address}) {
    return ProxySettings(
      enabled: enabled ?? this.enabled,
      address: address ?? this.address,
    );
  }
}

/// 代理设置 Notifier：修改后同步持久化到 [ProxyConfig]
class ProxySettingsNotifier extends StateNotifier<ProxySettings> {
  ProxySettingsNotifier()
      : super(ProxySettings(
          enabled: ProxyConfig.enabled,
          address: ProxyConfig.address,
        ));

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await ProxyConfig.save(value, state.address);
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
    await ProxyConfig.save(state.enabled, normalized);
    return true;
  }
}

final proxySettingsProvider =
    StateNotifierProvider<ProxySettingsNotifier, ProxySettings>(
  (ref) => ProxySettingsNotifier(),
);
