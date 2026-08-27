<div align="center">
  <img src="assets/icons/app_icon_opaque.png" alt="KikoFlu" width="120" height="120">

  # KikoFlu

  English | [日本語](README_JA.md) | [简体中文](README.md)
  
  A cross-platform doujin voice client. Supports self-hosted Kikoeru servers and online services.

  [![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)](#)
  [![License](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)


</div>

<div align="center">
  <img src="screenshots/8.png" width="900" alt="KikoFlu Screenshot">
</div>

## Features

### 🎵 Media Playback
- Background playback with automatic caching
- Persistent Mini Player item and playback position
- Playback speed control
- Loop (single / list) and shuffle modes
- Global audio gain with attenuation and amplification
- Audio haptics (Beta): mobile devices vibrate based on audio characteristics
- Multi-format support: audio, video, text, images, PDF, etc.
- Full or selective download with concurrent download management
- Offline download search and sorting
- Local imported work metadata recognition

### 📝 Subtitle System
- Automatic subtitle loading
- Subtitle import, editing, and timing adjustment
- Supports `.vtt`, `.srt`, `.lrc`, `.txt`, `.ass`, `.ssa`, `.sub`, `.idx`, `.sbv`, `.dfxp`, and `.ttml`
- Real-time subtitle / lyric translation during playback
- Translate subtitles for the current playback directly in the player, with immediate display and saving when complete
- Fullscreen lyrics / subtitle display
- Subtitle library (SQLite indexed, fast search)
- Custom save directory with cross-drive copy support

### 🎨 Interface
- Full platform support (Android / iOS / Windows / macOS / Linux)
- Material Design 3
- Liquid Glass navigation and Mini Player, enabled by default on Apple 26+ platforms with a compatible fallback elsewhere
- Landscape mode support
- Light and dark theme
- Title, file directory, and text file translation
- Automatic tag translation (Chinese / English / Japanese)
- Privacy mode
- Rating system
- Recommendations

### 🔍 Search
- Advanced search with multi-tag / exclude-tag support
- Multi-dimensional filtering (tags, rating, release date, etc.)
- Detailed work information display

### 🌐 Internationalization
- 简体中文 / 繁體中文 / English / 日本語 / Русский
- Multi-format, multilingual translation support

### ⚙️ Settings
- Multi-account support
- Custom server address ([Guide](https://github.com/pa-jesusf/KikoFlu/wiki/%E4%BD%BF%E7%94%A8%E8%87%AA%E5%BB%BA%E5%90%8E%E7%AB%AF%E6%9C%8D%E5%8A%A1%E5%99%A8)) with connection latency testing
- Cache size limit and cleanup strategy
- Theme and color scheme customization
- Separate translation target language setting, with custom target languages in LLM mode
- Playback settings for subtitle-library priority, preferred audio format, preloading, and audio gain
- Extensive UI customization options
- In-app log system (with export)
- Update checker

### 📝 Floating Lyrics
- Available on Android, iOS, Windows, macOS, and Linux
- Android supports lock / unlock and touch passthrough; desktop platforms support click-through mode
- iOS uses system Picture in Picture for floating lyrics

---

## Download

Go to [Releases](https://github.com/pa-jesusf/KikoFlu/releases/latest) for the latest version.

Platforms: Android (universal / arm64-v8a), iOS (unsigned IPA), Windows (installer / portable), macOS (DMG), Linux (x64 / arm64)

### AltStore / SideStore

iOS users can add the KikoFlu source to AltStore or SideStore for easy installation and updates:

**Source URL:** `https://raw.githubusercontent.com/pa-jesusf/KikoFlu/main/altstore-source.json`

---

## Build from Source

### Requirements
- Flutter SDK 3.0+
- Dart SDK 3.0+

```bash
git clone https://github.com/pa-jesusf/KikoFlu.git
cd KikoFlu
flutter pub get
```

### Build Commands

| Platform | Command |
|----------|---------|
| Android | `flutter build apk --release --split-per-abi` |
| Windows | `flutter build windows --release` |
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |
| iOS | `./build_ios_xcode.sh` |

---

## Related Projects

- [Kikoeru](https://github.com/Number178/kikoeru-express) — Self-hosted backend server
- [asmr.one](https://www.asmr.one) — Online service

## License

[GPL-3.0 License](LICENSE)

## Contact

- **Bug Reports**: [Issues](https://github.com/pa-jesusf/KikoFlu/issues)
- **Community**: [Telegram](https://t.me/+PrkiN-pZrXs4ZTU1)
