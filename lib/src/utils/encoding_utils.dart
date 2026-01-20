import 'dart:convert';
import 'dart:io';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:charset/charset.dart';

/// 文件编码检测和解码工具类
/// 支持 UTF-8、UTF-16LE、UTF-16BE、GBK、Shift-JIS、Latin1 等编码
class EncodingUtils {
  /// 检测编码并解码字节数组
  /// 返回 (解码后的字符串, 检测到的编码名称)
  static (String content, String encoding) decodeBytes(List<int> bytes) {
    // 1. 检查 UTF-16LE BOM (FF FE)
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      try {
        // UTF-16LE: 小端序，移除 BOM
        final utf16Bytes = bytes.sublist(2);
        final utf16Codes = <int>[];
        for (int i = 0; i < utf16Bytes.length; i += 2) {
          if (i + 1 < utf16Bytes.length) {
            // 小端序：低字节在前
            final code = utf16Bytes[i] | (utf16Bytes[i + 1] << 8);
            utf16Codes.add(code);
          }
        }
        return (String.fromCharCodes(utf16Codes), 'UTF-16LE');
      } catch (e) {
        // UTF-16LE 解码失败，继续尝试其他编码
      }
    }

    // 2. 检查 UTF-16BE BOM (FE FF)
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      try {
        // UTF-16BE: 大端序，移除 BOM
        final utf16Bytes = bytes.sublist(2);
        final utf16Codes = <int>[];
        for (int i = 0; i < utf16Bytes.length; i += 2) {
          if (i + 1 < utf16Bytes.length) {
            // 大端序：高字节在前
            final code = (utf16Bytes[i] << 8) | utf16Bytes[i + 1];
            utf16Codes.add(code);
          }
        }
        return (String.fromCharCodes(utf16Codes), 'UTF-16BE');
      } catch (e) {
        // UTF-16BE 解码失败，继续尝试其他编码
      }
    }

    // 3. 检查 UTF-8 BOM (EF BB BF)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      try {
        return (utf8.decode(bytes.sublist(3)), 'UTF-8');
      } catch (e) {
        // UTF-8 BOM 存在但解码失败，继续尝试其他编码
      }
    }

    // 4. 尝试 UTF-8 解码（无 BOM）
    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      // 检查是否有替换字符（通常是解码错误的标志）
      if (!decoded.contains('\uFFFD') && !decoded.contains('�')) {
        return (decoded, 'UTF-8');
      }
    } catch (e) {
      // UTF-8 解码失败，继续尝试其他编码
    }

    // 5. 尝试 GBK 解码（简体中文）
    // GBK 比 Shift-JIS 优先，因为字幕文件更多是中文
    try {
      final decoded = gbk_bytes.decode(bytes);
      // 验证：检查是否有替换字符
      if (decoded.isNotEmpty &&
          !decoded.contains('\uFFFD') &&
          !decoded.contains('�')) {
        // 额外验证：检查是否有合理的中文字符比例
        if (_hasReasonableContent(decoded)) {
          return (decoded, 'GBK');
        }
      }
    } catch (e) {
      // GBK 解码失败
    }

    // 6. 尝试 Shift-JIS 解码（日文）
    try {
      final decoded = shiftJis.decode(bytes);
      // 验证：检查是否有替换字符
      if (decoded.isNotEmpty &&
          !decoded.contains('\uFFFD') &&
          !decoded.contains('�')) {
        if (_hasReasonableContent(decoded)) {
          return (decoded, 'Shift-JIS');
        }
      }
    } catch (e) {
      // Shift-JIS 解码失败
    }

    // 7. 最后尝试 Latin1（不会失败，但可能显示乱码）
    try {
      return (latin1.decode(bytes), 'Latin1');
    } catch (e) {
      // 如果连 Latin1 都失败，返回错误提示
      return ('文件编码无法识别，无法正确显示内容', 'Unknown');
    }
  }

  /// 检查解码后的内容是否合理
  /// 避免错误解码导致的乱码通过验证
  static bool _hasReasonableContent(String content) {
    if (content.isEmpty) return false;

    // 统计有效字符（字母、数字、中日韩文字、常见标点）
    int validChars = 0;
    int totalChars = content.length;

    for (final codeUnit in content.codeUnits) {
      if (
          // ASCII 可打印字符
          (codeUnit >= 0x20 && codeUnit <= 0x7E) ||
              // 常见中日韩字符
              (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) ||
              // 日文平假名
              (codeUnit >= 0x3040 && codeUnit <= 0x309F) ||
              // 日文片假名
              (codeUnit >= 0x30A0 && codeUnit <= 0x30FF) ||
              // 换行符
              codeUnit == 0x0A ||
              codeUnit == 0x0D ||
              codeUnit == 0x09) {
        validChars++;
      }
    }

    // 如果有效字符比例超过 80%，认为是合理内容
    return totalChars > 0 && (validChars / totalChars) > 0.8;
  }

  /// 从文件读取内容，自动检测编码
  /// 返回 (解码后的字符串, 检测到的编码名称)
  static Future<(String content, String encoding)> readFileWithEncoding(
      File file) async {
    final bytes = await file.readAsBytes();
    return decodeBytes(bytes);
  }

  /// 从文件读取内容，自动检测编码（只返回内容）
  static Future<String> readFileAsString(File file) async {
    final (content, _) = await readFileWithEncoding(file);
    return content;
  }

  /// 将字符串编码为字节数组
  /// 使用指定的编码格式
  static List<int> encodeString(String content, String encoding) {
    try {
      switch (encoding) {
        case 'UTF-16LE':
          // 转换为 UTF-16 码点，添加 BOM
          final codeUnits = content.codeUnits;
          final bytes = <int>[0xFF, 0xFE]; // BOM
          // 小端序：低字节在前
          for (final code in codeUnits) {
            bytes.add(code & 0xFF); // 低字节
            bytes.add((code >> 8) & 0xFF); // 高字节
          }
          return bytes;
        case 'UTF-16BE':
          // 转换为 UTF-16 码点，添加 BOM
          final codeUnits = content.codeUnits;
          final bytes = <int>[0xFE, 0xFF]; // BOM
          // 大端序：高字节在前
          for (final code in codeUnits) {
            bytes.add((code >> 8) & 0xFF); // 高字节
            bytes.add(code & 0xFF); // 低字节
          }
          return bytes;
        case 'GBK':
          return gbk_bytes.encode(content);
        case 'Shift-JIS':
          return shiftJis.encode(content);
        case 'Latin1':
          return latin1.encode(content);
        case 'UTF-8':
        default:
          // UTF-8 是最安全的默认选择
          return utf8.encode(content);
      }
    } catch (e) {
      // 编码失败时降级到 UTF-8
      return utf8.encode(content);
    }
  }
}
