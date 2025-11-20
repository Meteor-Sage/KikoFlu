import 'package:flutter_test/flutter_test.dart';

/// 测试文件夹名称模式匹配
/// 匹配规则：RJ/BJ/VJ + 6-8位数字，或纯6-8位数字（不区分大小写）
bool matchFolderPattern(String folderName) {
  final patterns = [
    RegExp(r'^[RrBbVv][Jj]\d{6,8}$'), // RJ/BJ/VJ + 6-8位数字
    RegExp(r'^\d{6,8}$'), // 纯6-8位数字
  ];

  return patterns.any((pattern) => pattern.hasMatch(folderName));
}

void main() {
  group('文件夹名称模式匹配测试', () {
    test('RJ格式匹配测试', () {
      expect(matchFolderPattern('RJ123456'), true);
      expect(matchFolderPattern('RJ1234567'), true);
      expect(matchFolderPattern('RJ12345678'), true);
      expect(matchFolderPattern('rj123456'), true); // 小写
      expect(matchFolderPattern('Rj123456'), true); // 混合大小写
      expect(matchFolderPattern('RJ12345'), false); // 5位数字
      expect(matchFolderPattern('RJ123456789'), false); // 9位数字
    });

    test('BJ格式匹配测试', () {
      expect(matchFolderPattern('BJ123456'), true);
      expect(matchFolderPattern('bj1234567'), true);
      expect(matchFolderPattern('BJ12345678'), true);
      expect(matchFolderPattern('Bj12345'), false); // 5位数字
    });

    test('VJ格式匹配测试', () {
      expect(matchFolderPattern('VJ123456'), true);
      expect(matchFolderPattern('vj1234567'), true);
      expect(matchFolderPattern('VJ12345678'), true);
      expect(matchFolderPattern('vJ12345'), false); // 5位数字
    });

    test('纯数字格式匹配测试', () {
      expect(matchFolderPattern('123456'), true); // 6位
      expect(matchFolderPattern('1234567'), true); // 7位
      expect(matchFolderPattern('12345678'), true); // 8位
      expect(matchFolderPattern('12345'), false); // 5位
      expect(matchFolderPattern('123456789'), false); // 9位
    });

    test('不匹配的格式测试', () {
      expect(matchFolderPattern('RJ12345a'), false); // 包含字母
      expect(matchFolderPattern('123456a'), false); // 包含字母
      expect(matchFolderPattern('ABC123456'), false); // 不是RJ/BJ/VJ
      expect(matchFolderPattern('R123456'), false); // 缺少J
      expect(matchFolderPattern('RJ 123456'), false); // 包含空格
      expect(matchFolderPattern('RJ-123456'), false); // 包含连字符
      expect(matchFolderPattern('Season 1'), false); // 普通文件夹名
      expect(matchFolderPattern('未知作品'), false); // 中文
    });

    test('边界情况测试', () {
      expect(matchFolderPattern(''), false); // 空字符串
      expect(matchFolderPattern('RJ'), false); // 只有前缀
      expect(matchFolderPattern('123'), false); // 太短的数字
    });

    test('实际场景测试 - 多层嵌套', () {
      // 模拟实际场景：压缩包或文件夹中可能包含多个符合规则的子目录
      final testCases = {
        'RJ123456': true, // 应该放入"已解析"
        'RJ234567': true, // 应该放入"已解析"
        'BJ345678': true, // 应该放入"已解析"
        'VJ456789': true, // 应该放入"已解析"
        '12345678': true, // 应该放入"已解析"
        'MyMusic': false, // 应该放入"未知作品"（如果有字幕文件）
        'Collection': false, // 应该放入"未知作品"（如果有字幕文件）
        'Audio': false, // 应该放入"未知作品"（如果有字幕文件）
      };

      testCases.forEach((folderName, shouldMatch) {
        expect(matchFolderPattern(folderName), shouldMatch,
            reason:
                '$folderName should ${shouldMatch ? "match" : "not match"}');
      });
    });
  });
}
