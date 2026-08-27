import 'package:flutter/services.dart';
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

  group('ProxyConfig.httpProxyUrl', () {
    test('returns an explicit HTTP URL for native backends', () {
      ProxyConfig.enabled = true;
      ProxyConfig.address = 'HTTP://proxy.example:8080';

      expect(ProxyConfig.httpProxyUrl, 'http://proxy.example:8080');
    });

    test('returns null when disabled or malformed', () {
      ProxyConfig.address = 'proxy.example:8080';
      expect(ProxyConfig.httpProxyUrl, isNull);

      ProxyConfig.enabled = true;
      ProxyConfig.address = 'socks5://proxy.example:1080';
      expect(ProxyConfig.httpProxyUrl, isNull);
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

  group('ProxyConfig.init migration', () {
    test('migrates an enabled legacy address to manual mode', () async {
      SharedPreferences.setMockInitialValues({
        'proxy_enabled': true,
        'proxy_address': 'HTTP://proxy.example:8080',
      });

      await ProxyConfig.init();

      expect(ProxyConfig.mode, ProxyMode.manual);
      expect(ProxyConfig.address, 'proxy.example:8080');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('proxy_mode'), 'manual');
    });

    test(
      'defaults legacy settings without a usable proxy to system mode',
      () async {
        SharedPreferences.setMockInitialValues({
          'proxy_enabled': false,
          'proxy_address': 'proxy.example:8080',
        });

        await ProxyConfig.init();

        expect(ProxyConfig.mode, ProxyMode.system);
        expect(ProxyConfig.address, isEmpty);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('proxy_mode'), 'system');
        expect(prefs.getBool('proxy_enabled'), isFalse);
      },
    );
  });

  test('uses native system proxy entries by URI scheme', () async {
    const channel = MethodChannel('com.meteor.kikoeruflutter/system_proxy');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getSystemProxy');
      return 'http=http-proxy.example:8080;https=https-proxy.example:8443';
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    await ProxyConfig.refreshSystemProxy();
    ProxyConfig.mode = ProxyMode.system;

    expect(
      ProxyConfig.findProxyFor(Uri.parse('http://example.com/')),
      'PROXY http-proxy.example:8080',
    );
    expect(
      ProxyConfig.findProxyFor(Uri.parse('https://example.com/')),
      'PROXY https-proxy.example:8443',
    );
    expect(ProxyConfig.httpProxyUrl, 'http://http-proxy.example:8080');
    expect(ProxyConfig.httpsProxyUrl, 'http://https-proxy.example:8443');
  });
}
