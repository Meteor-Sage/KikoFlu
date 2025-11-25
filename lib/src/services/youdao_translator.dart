import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class YoudaoTranslator {
  final Dio _dio = Dio();
  static const String _url = 'https://dict.youdao.com/dicttranslate';
  static const String _key = 'cybibtzhdwayqjmrncst';

  Future<String> translate(String text, {String? sourceLang}) async {
    if (text.isEmpty) return text;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final sign = _generateSign(timestamp);

    final params = {
      'keyfrom': 'deskdict.main',
      'client': 'deskdict',
      'from': sourceLang ?? 'auto',
      'to': 'zh-CHS',
      'keyid': 'deskdict',
      'mysticTime': timestamp,
      'pointParam': 'client,product,mysticTime',
      'sign': sign,
      'domain': '0',
      'useTerm': 'false',
      'noCheckPrivate': 'false',
      'recTerms': '[]',
      'id': '0a464aedddbc6e4b9',
      'vendor': 'fanyiweb_navigation',
      'in': 'YoudaoDict_fanyiweb_navigation',
      'appVer': '11.2.0.0',
      'appZengqiang': '0',
      'abTest': '0',
      'model': 'LENOVO',
      'screen': '1920*1080',
      'OsVersion': '10.0.19045',
      'network': 'none',
      'mid': 'windows10.0.19045',
      'appVersion': '11.2.0.0',
      'product': 'deskdict',
      'source': 'mine_transtab_realtime',
    };

    try {
      final response = await _dio.post(
        _url,
        queryParameters: params,
        data: FormData.fromMap({'i': text}),
        options: Options(
          headers: {
            'User-Agent': 'Youdao Desktop Dict (Windows NT 10.0)',
            'Cookie': 'DESKDICT_VENDOR=unknown',
          },
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['translateResult'] != null) {
          final results = data['translateResult'] as List;
          final sb = StringBuffer();
          for (var result in results) {
            if (result is List) {
              for (var item in result) {
                if (item['tgt'] != null) {
                  sb.write(item['tgt']);
                }
              }
            }
          }
          return sb.toString();
        }
      }
      return text;
    } catch (e) {
      print('Youdao translation error: $e');
      return text;
    }
  }

  String _generateSign(String timestamp) {
    const client = 'deskdict';
    const product = 'deskdict';
    final str =
        'client=$client&mysticTime=$timestamp&product=$product&key=$_key';
    final bytes = utf8.encode(str);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
