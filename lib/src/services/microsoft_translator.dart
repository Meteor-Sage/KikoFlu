import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class MicrosoftTranslator {
  final Dio _dio = Dio();
  static const String _apiEndpoint = 'api.cognitive.microsofttranslator.com';
  static const String _apiVersion = '3.0';

  // Private key from the python script
  static final List<int> _privateKey = [
    162,
    41,
    58,
    61,
    208,
    221,
    50,
    115,
    151,
    122,
    100,
    219,
    194,
    243,
    39,
    245,
    215,
    191,
    135,
    217,
    69,
    157,
    240,
    90,
    9,
    102,
    198,
    48,
    198,
    106,
    170,
    132,
    154,
    65,
    170,
    148,
    58,
    168,
    213,
    26,
    110,
    77,
    170,
    201,
    163,
    112,
    18,
    53,
    199,
    235,
    18,
    246,
    232,
    35,
    7,
    158,
    71,
    16,
    149,
    145,
    136,
    85,
    216,
    23
  ];

  Future<String> translate(String text, {String? sourceLang}) async {
    if (text.isEmpty) return text;

    final targetLang =
        'zh-Hans'; // Microsoft uses zh-Hans for Simplified Chinese
    final from = sourceLang != null ? '&from=$sourceLang' : '';

    // Construct URL path and query for signature
    // Python: url = "{}/translate?api-version={}&to={}".format(_apiEndpoint, _apiVersion, self.tgtlang)
    final urlPath =
        '$_apiEndpoint/translate?api-version=$_apiVersion&to=$targetLang$from';

    final signature = _getSignature(urlPath);

    try {
      final response = await _dio.post(
        'https://$urlPath',
        data: [
          {'Text': text}
        ],
        options: Options(
          headers: {
            'X-MT-Signature': signature,
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          final first = data[0];
          if (first is Map && first['translations'] is List) {
            final translations = first['translations'] as List;
            if (translations.isNotEmpty) {
              return translations[0]['text'] ?? text;
            }
          }
        }
      }
      return text;
    } catch (e) {
      print('Microsoft translation error: $e');
      return text;
    }
  }

  String _getSignature(String url) {
    final guid = _generateGuid();
    final dateTime = HttpDate.format(DateTime.now().toUtc());

    // Python: escaped_url = quote(url, safe="")
    final escapedUrl = Uri.encodeComponent(url);

    final bytesStr = utf8.encode(
        'MSTranslatorAndroidApp$escapedUrl$dateTime$guid'.toLowerCase());

    final hmacSha256 = Hmac(sha256, _privateKey);
    final digest = hmacSha256.convert(bytesStr);
    final hash = base64.encode(digest.bytes);

    return 'MSTranslatorAndroidApp::$hash::$dateTime::$guid';
  }

  String _generateGuid() {
    final random = Random();
    final buffer = StringBuffer();
    for (var i = 0; i < 32; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }
}
