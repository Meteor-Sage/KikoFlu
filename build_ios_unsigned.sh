#!/bin/bash

# iOS 无签名 IPA 构建脚本
# 用于创建可供用户自签名的 IPA 包

set -e

echo "🚀 开始构建 iOS 无签名 IPA..."

# 检查 Flutter 是否已安装
echo "🔍 检查依赖环境..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装或未添加到 PATH"
    echo ""
    echo "请先安装 Flutter SDK："
    echo "  方法1（推荐）: brew install --cask flutter"
    echo "  方法2: 从官网下载 https://flutter.dev/docs/get-started/install/macos"
    echo ""
    echo "安装后运行: flutter doctor -v"
    exit 1
fi

# 检查 CocoaPods 是否已安装
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods 未安装"
    echo ""
    echo "请先安装 CocoaPods："
    echo "  brew install cocoapods"
    exit 1
fi

# 检查 Xcode 是否已安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode 未安装或未配置"
    echo ""
    echo "请从 App Store 安装 Xcode，并运行："
    echo "  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    echo "  sudo xcodebuild -runFirstLaunch"
    exit 1
fi

echo "✅ 依赖检查通过"
echo ""

# 清理之前的构建
echo "🧹 清理之前的构建..."
rm -rf build/ios

# Flutter clean
echo "🧹 清理 Flutter 缓存..."
flutter clean

# 获取依赖
echo "📦 获取 Flutter 依赖..."
flutter pub get

# 安装 CocoaPods 依赖
echo "📦 安装 iOS 依赖..."
cd ios
pod install --repo-update
cd ..

# 构建 iOS release 版本（不签名）
echo "🔨 构建 iOS Release 版本（无签名）..."
flutter build ipa --release --no-codesign --export-method development

# 检查构建是否成功
if [ -f "build/ios/ipa/kikoeru_flutter.ipa" ]; then
    echo "📦 IPA 已自动生成..."
    cp build/ios/ipa/kikoeru_flutter.ipa ./KikoFlu-unsigned.ipa
elif [ -d "build/ios/iphoneos/Runner.app" ]; then
    # 如果 flutter build ipa 失败，手动打包
    echo "📦 手动创建 IPA 包..."
    mkdir -p build/ios/Payload
    cp -r build/ios/iphoneos/Runner.app build/ios/Payload/
    
    # 打包成 IPA
    cd build/ios
    zip -r KikoFlu-unsigned.ipa Payload
    cd ../..
    
    # 移动 IPA 到根目录
    mv build/ios/KikoFlu-unsigned.ipa ./
else
    echo "❌ 构建失败！未找到构建产物"
    exit 1
fi

echo "✅ 构建完成！"
echo "📱 无签名 IPA 文件: KikoFlu-unsigned.ipa"
echo ""
echo "📝 用户可以使用以下工具自签名："
echo "   - AltStore (https://altstore.io/)"
echo "   - Sideloadly (https://sideloadly.io/)"
echo "   - iOS App Signer (https://github.com/DanTheMan827/ios-app-signer)"
echo "   - Xcode 直接安装（需要 Apple 开发者账号）"
