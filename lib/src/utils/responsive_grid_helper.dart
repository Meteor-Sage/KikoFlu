import 'package:flutter/material.dart';

/// 响应式布局工具类
/// 根据屏幕尺寸和方向自动计算最佳列数
class ResponsiveGridHelper {
  /// 根据屏幕尺寸计算大网格的列数
  /// 
  /// 逻辑：
  /// - 竖屏：固定2列
  /// - 横屏：
  ///   - 屏幕宽度 < 1200px 或宽高比 < 1.6：3列
  ///   - 屏幕宽度 >= 1200px 且宽高比 >= 1.6：4列
  static int getBigGridCrossAxisCount(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    
    // 竖屏固定2列
    if (orientation == Orientation.portrait) {
      return 2;
    }
    
    // 横屏根据屏幕尺寸决定3列或4列
    final aspectRatio = size.width / size.height;
    final width = size.width;
    
    // 宽度较小或宽高比不够宽时使用3列
    // 例如：iPad 横屏 (1024x768, 比例1.33) -> 3列
    // 例如：MacBook/PC (1920x1080, 比例1.78) -> 4列
    if (width < 1200 || aspectRatio < 1.6) {
      return 3;
    }
    
    return 4;
  }
  
  /// 根据屏幕尺寸计算小网格的列数
  /// 
  /// 逻辑：
  /// - 竖屏：固定3列
  /// - 横屏：固定5列
  static int getSmallGridCrossAxisCount(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape ? 5 : 3;
  }
  
  /// 获取推荐的卡片最小宽度
  /// 用于确保卡片在不同列数下保持合适的尺寸
  static double getRecommendedCardMinWidth(int crossAxisCount) {
    switch (crossAxisCount) {
      case 2:
        return 160.0; // 竖屏2列
      case 3:
        return 220.0; // 横屏3列（较窄屏幕）
      case 4:
        return 200.0; // 横屏4列（宽屏）
      case 5:
        return 140.0; // 小网格5列
      default:
        return 180.0;
    }
  }
  
  /// 获取屏幕宽度分类
  static ScreenWidthClass getScreenWidthClass(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return ScreenWidthClass.compact; // 手机
    } else if (width < 840) {
      return ScreenWidthClass.medium; // 小平板
    } else if (width < 1200) {
      return ScreenWidthClass.expanded; // 大平板
    } else {
      return ScreenWidthClass.large; // 桌面
    }
  }
  
  /// 获取推荐的间距
  static double getRecommendedSpacing(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final widthClass = getScreenWidthClass(context);
    
    if (orientation == Orientation.landscape) {
      // 横屏使用更大的间距
      return widthClass == ScreenWidthClass.large ? 24.0 : 16.0;
    }
    
    return 8.0;
  }
  
  /// 获取推荐的边距
  static double getRecommendedPadding(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final widthClass = getScreenWidthClass(context);
    
    if (orientation == Orientation.landscape) {
      // 横屏使用更大的边距
      return widthClass == ScreenWidthClass.large ? 24.0 : 16.0;
    }
    
    return 8.0;
  }
  
  /// 判断是否为宽屏设备
  static bool isWideScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final aspectRatio = size.width / size.height;
    return aspectRatio >= 1.6;
  }
}

/// 屏幕宽度分类
enum ScreenWidthClass {
  compact,   // < 600px  (手机)
  medium,    // < 840px  (小平板)
  expanded,  // < 1200px (大平板)
  large,     // >= 1200px (桌面)
}
