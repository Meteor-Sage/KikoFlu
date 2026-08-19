import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kikoeru_flutter/src/utils/theme.dart';

void main() {
  test('uses the native Simplified Chinese font first', () {
    expect(
      AppTheme.iosFontFamilyFallback(const Locale('zh', 'CN')).first,
      'PingFang SC',
    );
  });

  test('uses the native Traditional Chinese font first', () {
    expect(
      AppTheme.iosFontFamilyFallback(
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ).first,
      'PingFang TC',
    );
  });

  test('uses the native Japanese font first', () {
    expect(
      AppTheme.iosFontFamilyFallback(const Locale('ja', 'JP')).first,
      'Hiragino Sans',
    );
  });
}
