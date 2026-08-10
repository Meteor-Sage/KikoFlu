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

  Future<void> setAddress(String value) async {
    state = state.copyWith(address: value);
    await ProxyConfig.save(state.enabled, value);
  }
}

final proxySettingsProvider =
    StateNotifierProvider<ProxySettingsNotifier, ProxySettings>(
  (ref) => ProxySettingsNotifier(),
);
