# 响应式网格布局功能说明

## 功能概述

实现了根据屏幕比例自动选择3列或4列的智能布局，提供更好的用户体验。

## 布局逻辑

### 大网格模式 (bigGrid)

#### 竖屏模式
- **固定 2 列**
- 适用于所有手机和平板竖屏

#### 横屏模式（智能切换）
根据屏幕宽度和宽高比自动选择：

| 设备类型 | 屏幕宽度 | 宽高比 | 列数 | 示例设备 |
|---------|---------|--------|------|---------|
| 小平板 | < 1200px | < 1.6 | **3列** | iPad 横屏 (1024x768, 1.33) |
| 普通笔记本 | < 1200px | < 1.6 | **3列** | 13" MacBook (1440x900, 1.6) |
| 宽屏笔记本 | ≥ 1200px | ≥ 1.6 | **4列** | 15" MacBook (1920x1200, 1.6) |
| 桌面显示器 | ≥ 1200px | ≥ 1.6 | **4列** | PC (1920x1080, 1.78) |
| 超宽屏 | ≥ 1200px | ≥ 1.6 | **4列** | 2K/4K 显示器 |

### 小网格模式 (smallGrid)

| 方向 | 列数 |
|-----|------|
| 竖屏 | **3列** |
| 横屏 | **5列** |

### 判断逻辑

```dart
// 伪代码
if (竖屏) {
  return 2列;
} else if (横屏) {
  if (宽度 < 1200px || 宽高比 < 1.6) {
    return 3列;  // 较窄的横屏
  } else {
    return 4列;  // 宽屏
  }
}
```

## 实现细节

### 核心工具类

**文件**: `lib/src/utils/responsive_grid_helper.dart`

#### 主要方法

1. **`getBigGridCrossAxisCount(BuildContext context)`**
   - 返回大网格的列数（2/3/4）
   - 根据方向、屏幕宽度和宽高比智能计算

2. **`getSmallGridCrossAxisCount(BuildContext context)`**
   - 返回小网格的列数（3/5）
   - 竖屏3列，横屏5列

3. **`getScreenWidthClass(BuildContext context)`**
   - 返回屏幕宽度分类
   - Compact (< 600px) / Medium (< 840px) / Expanded (< 1200px) / Large (≥ 1200px)

4. **`isWideScreen(BuildContext context)`**
   - 判断是否为宽屏设备（宽高比 ≥ 1.6）

5. **辅助方法**
   - `getRecommendedCardMinWidth()` - 获取推荐的卡片最小宽度
   - `getRecommendedSpacing()` - 获取推荐的间距
   - `getRecommendedPadding()` - 获取推荐的边距

### 应用位置

1. **`works_screen.dart`** - 作品列表页面
2. **`my_screen.dart`** - 我的收藏页面
3. **`works_grid_view.dart`** - 网格视图组件
4. **`search_result_screen.dart`** - 搜索结果页面（通过 works_grid_view）

## 使用示例

### 基础使用

```dart
// 获取列数
final columnCount = ResponsiveGridHelper.getBigGridCrossAxisCount(context);

// 构建网格
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columnCount,
  ),
  // ...
)
```

### 完整示例

```dart
Widget _buildLayoutView(WorksState state) {
  switch (state.layoutType) {
    case LayoutType.bigGrid:
      return _buildGridView(
        state,
        crossAxisCount: ResponsiveGridHelper.getBigGridCrossAxisCount(context),
      );
    case LayoutType.smallGrid:
      return _buildGridView(
        state,
        crossAxisCount: ResponsiveGridHelper.getSmallGridCrossAxisCount(context),
      );
    case LayoutType.list:
      return _buildListView(state);
  }
}
```

## 屏幕宽度分类

```dart
enum ScreenWidthClass {
  compact,   // < 600px  - 手机
  medium,    // < 840px  - 小平板
  expanded,  // < 1200px - 大平板
  large,     // ≥ 1200px - 桌面
}
```

## 测试场景

### 场景 1: iPad 横屏
- 分辨率: 1024 x 768
- 宽高比: 1.33
- 宽度: 1024px < 1200px
- **结果: 3列** ✓

### 场景 2: 13" MacBook Pro
- 分辨率: 1440 x 900
- 宽高比: 1.6
- 宽度: 1440px ≥ 1200px，但宽高比刚好 = 1.6
- **结果: 4列** ✓

### 场景 3: 15" MacBook Pro
- 分辨率: 1920 x 1200
- 宽高比: 1.6
- 宽度: 1920px ≥ 1200px
- **结果: 4列** ✓

### 场景 4: iMac 27"
- 分辨率: 2560 x 1440
- 宽高比: 1.78
- 宽度: 2560px ≥ 1200px
- **结果: 4列** ✓

### 场景 5: iPhone 横屏
- 分辨率: 844 x 390
- 宽高比: 2.16
- 宽度: 844px < 1200px
- **结果: 3列** ✓

## 优势

1. **平滑过渡**: 从2列到3列到4列，逐步增加列数
2. **自动适配**: 无需手动配置，根据设备特性自动调整
3. **优化体验**: 
   - 小设备不会显得过于拥挤（3列）
   - 大设备充分利用空间（4列）
   - 保持卡片合适的尺寸
4. **代码复用**: 统一的工具类，所有页面共享逻辑
5. **易于维护**: 修改判断逻辑只需更新一个文件

## 可调整参数

如需调整判断阈值，可在 `responsive_grid_helper.dart` 中修改：

```dart
// 当前阈值
if (width < 1200 || aspectRatio < 1.6) {
  return 3;
}

// 示例：更宽松的判断（更早切换到4列）
if (width < 1000 || aspectRatio < 1.5) {
  return 3;
}

// 示例：更严格的判断（更晚切换到4列）
if (width < 1400 || aspectRatio < 1.7) {
  return 3;
}
```

## 视觉效果

### 竖屏模式
```
┌──────┬──────┐
│  卡  │  卡  │  2列
│  片  │  片  │
├──────┼──────┤
│  卡  │  卡  │
│  片  │  片  │
└──────┴──────┘
```

### 横屏模式 - 较窄屏幕 (< 1200px 或 比例 < 1.6)
```
┌─────┬─────┬─────┐
│ 卡  │ 卡  │ 卡  │  3列
│ 片  │ 片  │ 片  │
├─────┼─────┼─────┤
│ 卡  │ 卡  │ 卡  │
│ 片  │ 片  │ 片  │
└─────┴─────┴─────┘
```

### 横屏模式 - 宽屏 (≥ 1200px 且 比例 ≥ 1.6)
```
┌────┬────┬────┬────┐
│ 卡 │ 卡 │ 卡 │ 卡 │  4列
│ 片 │ 片 │ 片 │ 片 │
├────┼────┼────┼────┤
│ 卡 │ 卡 │ 卡 │ 卡 │
│ 片 │ 片 │ 片 │ 片 │
└────┴────┴────┴────┘
```

## 注意事项

1. **实时响应**: 旋转设备或调整窗口大小时会自动重新计算
2. **性能优化**: 使用 MediaQuery 的数据，无额外性能开销
3. **兼容性**: 适用于所有 Flutter 支持的平台（iOS、Android、macOS、Windows、Web）
4. **字体调整**: 横屏模式下字体已相应增大（在之前的更新中完成）

## 未来扩展

可以根据需要添加更多功能：

1. **用户自定义**: 允许用户在设置中手动选择列数
2. **动态计算**: 根据卡片内容动态调整列数
3. **横向滚动**: 在特别窄的屏幕上使用横向滚动而非多列
4. **响应式字体**: 根据列数进一步微调字体大小
