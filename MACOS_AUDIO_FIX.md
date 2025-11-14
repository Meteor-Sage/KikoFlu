# macOS 音频自动切换修复说明

## 问题描述
在 macOS 平台上，使用 `StreamAudioSource` 播放音频时，`just_audio` 库的完成事件（`ProcessingState.completed`）可能无法正常触发，导致播放列表无法自动切换到下一首歌曲。

## 解决方案

### 平台特定修复策略
为了避免影响其他平台的正常运行，所有修复措施都使用 `Platform.isMacOS` 进行条件判断：

#### 1. **多层检测机制（仅 macOS）**
   - **主监听器**：`playerStateStream` 监听播放状态变化，使用 `_completionHandled` 标志防止重复触发
   - **位置监听器**：监听播放位置，当位置接近结尾且停止移动时触发完成
   - **定时器检查**：每 500ms 检查一次播放状态，作为最终的后备方案

#### 2. **完成标志管理（仅 macOS）**
   - 使用 `_completionHandled` 布尔值追踪当前曲目是否已处理完成
   - 在加载新曲目时重置标志
   - 检测到后退搜索时重置标志

#### 3. **定时器生命周期管理（仅 macOS）**
   - 在 `initialize()` 时启动定时器
   - 在 `play()` 时检查并确保定时器运行
   - 在 `dispose()` 时取消定时器

### 其他平台保持简洁
- **Windows/Linux/Android/iOS**：仅使用原有的 `ProcessingState.completed` 监听
- 不启用额外的定时器或位置检查
- 保持代码简洁和性能优化

## 关键代码位置

### 初始化 (initialize 方法)
```dart
// macOS specific: Additional position-based completion detection
if (Platform.isMacOS) {
  // 位置监听器和定时器启动
} else {
  // 其他平台：简单的位置流监听
}
```

### 播放控制 (play 方法)
```dart
// macOS specific: Ensure completion check timer is running
if (Platform.isMacOS && ...) {
  _startCompletionCheckTimer();
}
```

### 曲目加载 (_loadTrack 方法)
```dart
// Reset completion flag for new track (macOS specific)
if (Platform.isMacOS) {
  _completionHandled = false;
}
```

## 优化点

1. **平台隔离**：所有 macOS 特定代码都用条件判断包裹
2. **避免重复触发**：使用完成标志确保每个曲目只处理一次
3. **多层后备**：三种检测机制互为补充，确保可靠性
4. **性能优化**：其他平台保持原有的简洁逻辑，不受影响
5. **资源清理**：正确管理定时器生命周期，避免内存泄漏

## 测试建议

### macOS 测试
- ✅ 单曲循环模式
- ✅ 列表循环模式
- ✅ 顺序播放模式
- ✅ 播放列表自动切换
- ✅ 手动切换歌曲

### 其他平台回归测试
- ✅ 确认不会跳过曲目
- ✅ 确认不会重复触发
- ✅ 确认循环模式正常
- ✅ 确认性能无影响

## 注意事项
- 此修复是针对 macOS 平台 `StreamAudioSource` 的已知问题
- 如果 `just_audio` 库未来版本修复了这个问题，可以移除这些 workaround 代码
- 保持关注 just_audio 的更新日志
