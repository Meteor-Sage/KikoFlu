<div align="center">
  <img src="assets/icons/app_icon_opaque.png" alt="KikoFlu" width="120" height="120">

  # KikoFlu

  [English](README_EN.md) | [日本語](README_JA.md) | 简体中文
  
  一个跨平台同人音声客户端，支持连接 Kikoeru 自建服务器或在线服务

  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](#)
  [![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)


</div>

<div align="center">
  <img src="screenshots/8.png" width="900" alt="KikoFlu 截图">
</div>

## 特性

### 🎵 媒体播放
- 后台播放与自动缓存机制
- 倍速播放
- 单曲循环、列表循环、随机播放
- 音频触感反馈(Beta)：移动端根据声音特征控制设备振动
- 多媒体支持：音频、视频、文本、图片、PDF 等
- 支持整个作品或选择性下载，并发下载管理
- 离线下载搜索与排序
- 本地导入作品元数据识别

### 📝 字幕系统
- 自动字幕加载
- 字幕导入、编辑、调轴
- 字幕翻译（播放时实时翻译歌词/台词）
- 播放器内翻译当前播放字幕，完成后立即显示并保存
- 歌词/字幕全屏显示
- 字幕库（SQLite 索引，快速检索）
- 支持保存目录修改，跨硬盘拷贝

### 🎨 界面
- 全平台支持（Android / iOS / Windows / macOS / Linux）
- Material Design 3 设计规范
- 横屏模式支持
- 明暗主题自适应
- 标题、文件目录、文本文件翻译
- 标签自动翻译（中/英/日）
- 防社死模式
- 评分系统
- 推荐作品功能

### 🔍 搜索
- 高级搜索，支持多标签 / 排除标签
- 多维度筛选（标签、评分、发售日期等）
- 完整作品信息展示

### 🌐 国际化
- 简体中文 / 繁體中文 / English / 日本語 / Русский
- 多形式、多语言翻译支持

### ⚙️ 设置
- 多账户支持
- 自定义服务器地址（[使用指南](https://github.com/pa-jesusf/KikoFlu/wiki/%E4%BD%BF%E7%94%A8%E8%87%AA%E5%BB%BA%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E5%99%A8)），可测试连接延迟
- 自定义缓存大小限制与清理策略
- 主题模式、配色方案自由选择
- 翻译目标语言可单独设置，LLM 模式支持自定义目标语言
- 丰富的界面自定义选项
- 应用内日志系统（支持导出）
- 更新检查

### 📱 Android 特性
- 悬浮歌词（锁定 / 解锁 / 触控穿透）

---

## 下载

前往 [Releases](https://github.com/pa-jesusf/KikoFlu/releases/latest) 下载最新版本。

支持平台：Android（universal / arm64 / armeabi-v7a / x86_64）、iOS（未签名 IPA）、Windows（安装包 / 便携版）、macOS（DMG）、Linux（x64 / arm64）

### AltStore / SideStore

iOS 用户可通过 AltStore 或 SideStore 添加软件源来安装和更新 KikoFlu：

**源地址：** `https://raw.githubusercontent.com/pa-jesusf/KikoFlu/main/altstore-source.json`

---

## 源码构建

### 环境要求
- Flutter SDK 3.44.1+
- Dart SDK 3.12.1+

```bash
git clone https://github.com/pa-jesusf/KikoFlu.git
cd KikoFlu
flutter pub get
```

### 构建命令

| 平台 | 命令 |
|------|------|
| Android | `flutter build apk --release --split-per-abi` |
| Windows | `flutter build windows --release` |
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |
| iOS | `./build_ios_xcode.sh` |

---

## 相关项目

- [Kikoeru](https://github.com/Number178/kikoeru-express) — 自建后端服务器
- [asmr.one](https://www.asmr.one) — 在线服务

## 开源协议

[GPL-3.0 License](LICENSE)

## 联系方式

- **问题反馈**：[Issues](https://github.com/pa-jesusf/KikoFlu/issues)
- **交流群组**：[Telegram](https://t.me/+PrkiN-pZrXs4ZTU1)

---

<div align="center">

  **如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！**

</div>
