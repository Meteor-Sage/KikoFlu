import 'package:flutter_test/flutter_test.dart';

/// 测试智能路径判断逻辑
/// 模拟 _shouldCreateNewFolder 的逻辑
bool shouldCreateNewFolder(List<String> rootItems, String zipName) {
  // 如果有多个项目，需要创建文件夹
  if (rootItems.length != 1) {
    return true;
  }

  // 只有一个项目，检查是否与ZIP名相同
  final singleItem = rootItems.first;

  // 如果文件夹名与ZIP名不同，需要创建文件夹
  if (singleItem != zipName) {
    return true;
  }

  // 文件夹名与ZIP名相同，不需要创建
  return false;
}

void main() {
  group('ZIP智能路径判断测试', () {
    test('多个根目录项 - 需要创建文件夹', () {
      final rootItems = ['folder1', 'folder2', 'file.txt'];
      final zipName = 'archive';

      expect(shouldCreateNewFolder(rootItems, zipName), true,
          reason: '多个根目录项应该创建文件夹');
    });

    test('单个文件夹且名称与ZIP相同 - 不需要创建文件夹', () {
      final rootItems = ['RJ123456'];
      final zipName = 'RJ123456';

      expect(shouldCreateNewFolder(rootItems, zipName), false,
          reason: '文件夹名与ZIP名相同，应该直接解压');
    });

    test('单个文件夹但名称与ZIP不同 - 需要创建文件夹', () {
      final rootItems = ['subfolder'];
      final zipName = 'RJ123456';

      expect(shouldCreateNewFolder(rootItems, zipName), true,
          reason: '文件夹名与ZIP名不同，应该创建ZIP命名的文件夹');
    });

    test('实际场景1: RJ123456.zip包含RJ123456文件夹', () {
      final rootItems = ['RJ123456'];
      final zipName = 'RJ123456';

      expect(shouldCreateNewFolder(rootItems, zipName), false);
      // 结果: 直接解压到 已解析/RJ123456/
    });

    test('实际场景2: RJ123456.zip包含data文件夹', () {
      final rootItems = ['data'];
      final zipName = 'RJ123456';

      expect(shouldCreateNewFolder(rootItems, zipName), true);
      // 结果: 创建 已解析/RJ123456/data/
    });

    test('实际场景3: collection.zip包含多个文件夹', () {
      final rootItems = ['RJ123456', 'RJ234567', 'readme.txt'];
      final zipName = 'collection';

      expect(shouldCreateNewFolder(rootItems, zipName), true);
      // 结果: 创建 未知作品/collection/ 然后递归处理内部
    });

    test('实际场景4: RJ123456.zip包含Album文件夹', () {
      final rootItems = ['Album'];
      final zipName = 'RJ123456';

      expect(shouldCreateNewFolder(rootItems, zipName), true);
      // 结果: 创建 已解析/RJ123456/Album/
    });

    test('实际场景5: MyMusic.zip包含MyMusic文件夹', () {
      final rootItems = ['MyMusic'];
      final zipName = 'MyMusic';

      expect(shouldCreateNewFolder(rootItems, zipName), false);
      // 结果: 直接解压到 未知作品/MyMusic/
    });

    test('边界情况: 空根目录', () {
      final rootItems = <String>[];
      final zipName = 'archive';

      expect(shouldCreateNewFolder(rootItems, zipName), true,
          reason: '空根目录视为需要创建文件夹');
    });

    test('大小写敏感测试', () {
      final rootItems = ['rj123456'];
      final zipName = 'RJ123456';

      expect(shouldCreateNewFolder(rootItems, zipName), true,
          reason: '大小写不同视为不同名称');
    });
  });

  group('完整导入流程模拟', () {
    test('场景A: 标准RJ压缩包', () {
      // RJ123456.zip
      //   └── RJ123456/
      //       ├── track1.lrc
      //       └── track2.srt

      final rootItems = ['RJ123456'];
      final zipName = 'RJ123456';
      final needFolder = shouldCreateNewFolder(rootItems, zipName);

      expect(needFolder, false);
      print('✓ RJ123456.zip → 已解析/RJ123456/ (直接解压)');
    });

    test('场景B: 包含子文件夹的RJ压缩包', () {
      // RJ234567.zip
      //   └── Audio/
      //       └── track.lrc

      final rootItems = ['Audio'];
      final zipName = 'RJ234567';
      final needFolder = shouldCreateNewFolder(rootItems, zipName);

      expect(needFolder, true);
      print('✓ RJ234567.zip → 已解析/RJ234567/Audio/ (创建文件夹)');
    });

    test('场景C: 多个RJ的集合包', () {
      // Collection.zip
      //   ├── RJ111111/
      //   ├── RJ222222/
      //   └── RJ333333/

      final rootItems = ['RJ111111', 'RJ222222', 'RJ333333'];
      final zipName = 'Collection';
      final needFolder = shouldCreateNewFolder(rootItems, zipName);

      expect(needFolder, true);
      print('✓ Collection.zip → 临时解压 → 递归识别各个RJ目录');
    });
  });
}
