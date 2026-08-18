import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/providers/proxy_provider.dart';
import 'package:kikoeru_flutter/src/services/proxy_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProxyConfig.enabled = false;
    ProxyConfig.address = '';
  });

  group('ProxyConfig.normalizeAddress', () {
    test('normalizes supported HTTP proxy addresses', () {
      expect(
        ProxyConfig.normalizeAddress('  HTTP://proxy.example:8080  '),
        'proxy.example:8080',
      );
      expect(
        ProxyConfig.normalizeAddress('https://127.0.0.1:7890'),
        '127.0.0.1:7890',
      );
      expect(
        ProxyConfig.normalizeAddress('[2001:db8::1]:3128'),
        '[2001:db8::1]:3128',
      );
    });

    test('rejects malformed or unsupported addresses', () {
      for (final value in [
        '',
        'proxy.example',
        'proxy.example:0',
        'proxy.example:65536',
        'proxy.example:not-a-port',
        'socks5://proxy.example:1080',
        'http://user:password@proxy.example:8080',
        'http://proxy.example:8080/path',
        '2001:db8::1:3128',
      ]) {
        expect(ProxyConfig.normalizeAddress(value), isNull, reason: value);
      }
    });
  });

  group('ProxyConfig.findProxyFor', () {
    test('uses the configured proxy for public hosts only when enabled', () {
      ProxyConfig.address = 'proxy.example:8080';

      expect(
        ProxyConfig.findProxyFor(Uri.parse('https://example.com/resource')),
        'DIRECT',
      );

      ProxyConfig.enabled = true;
      expect(
        ProxyConfig.findProxyFor(Uri.parse('https://example.com/resource')),
        'PROXY proxy.example:8080',
      );
    });

    test('keeps loopback and private network destinations direct', () {
      ProxyConfig.enabled = true;
      ProxyConfig.address = '127.0.0.1:7890';

      for (final host in [
        'localhost',
        '127.0.0.1',
        '10.0.0.4',
        '172.16.0.1',
        '172.31.255.254',
        '192.168.1.8',
        '169.254.10.2',
        '[::1]',
        '[fc00::1]',
        '[fe80::1]',
      ]) {
        expect(
          ProxyConfig.findProxyFor(Uri.parse('http://$host/api/health')),
          'DIRECT',
          reason: host,
        );
      }

      expect(
        ProxyConfig.findProxyFor(Uri.parse('http://172.32.0.1/api/health')),
        'PROXY 127.0.0.1:7890',
      );
    });
  });

  test('proxy settings reject invalid input without changing state', () async {
    final notifier = ProxySettingsNotifier();
    addTearDown(notifier.dispose);

    expect(await notifier.setAddress('proxy.example'), isFalse);
    expect(notifier.state.address, isEmpty);

    expect(await notifier.setAddress('HTTP://proxy.example:8080'), isTrue);
    expect(notifier.state.address, 'proxy.example:8080');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('proxy_address'), 'proxy.example:8080');
  });
}
