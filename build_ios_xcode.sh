#!/bin/bash

# iOS 无签名 IPA 简化构建脚本（使用 Xcode Archive 方式）
# 适用于 Xcode 26.1 等较新版本

set -e

echo "🚀 开始构建 iOS 无签名 IPA（简化版）..."

# 检查依赖
echo "🔍 检查依赖环境..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装"
    exit 1
fi

if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods 未安装"
    exit 1
fi

echo "✅ 依赖检查通过"
echo ""

# 清理
echo "🧹 清理之前的构建..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock

# 获取依赖
echo "📦 获取 Flutter 依赖..."
flutter pub get

# 安装 iOS 依赖
echo "📦 安装 iOS 依赖（首次可能需要较长时间）..."
cd ios
pod install
cd ..

# 使用 xcodebuild 构建（不需要模拟器）
echo "🔨 构建 iOS Release 版本（无签名）..."
cd ios

xcodebuild \
    -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath build/Runner.xcarchive \
    archive \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_ENTITLEMENTS="" \
    PROVISIONING_PROFILE=""

cd ..

# 检查 archive 是否成功
if [ ! -d "ios/build/Runner.xcarchive" ]; then
    echo "❌ Archive 失败"
    exit 1
fi

# 导出 IPA
echo "📦 导出 IPA..."
cd ios

xcodebuild \
    -exportArchive \
    -archivePath build/Runner.xcarchive \
    -exportPath build/unsigned \
    -exportOptionsPlist ../ios/ExportOptions.plist

cd ..

# 查找并复制 IPA
if [ -f "ios/build/unsigned/Runner.ipa" ]; then
    cp ios/build/unsigned/Runner.ipa ./KikoFlu-unsigned.ipa
    echo "✅ 构建完成！"
    echo "📱 无签名 IPA 文件: KikoFlu-unsigned.ipa"
    echo ""
    ls -lh KikoFlu-unsigned.ipa
else
    echo "❌ IPA 导出失败"
    echo "尝试手动打包..."
    
    # 手动打包
    mkdir -p build/Payload
    cp -r ios/build/Runner.xcarchive/Products/Applications/Runner.app build/Payload/
    cd build
    zip -r ../KikoFlu-unsigned.ipa Payload
    cd ..
    
    if [ -f "KikoFlu-unsigned.ipa" ]; then
        echo "✅ 手动打包成功！"
        echo "📱 无签名 IPA 文件: KikoFlu-unsigned.ipa"
        ls -lh KikoFlu-unsigned.ipa
    else
        echo "❌ 打包失败"
        exit 1
    fi
fi

echo ""
echo "📝 用户可以使用以下工具自签名："
echo "   - AltStore (https://altstore.io/)"
echo "   - Sideloadly (https://sideloadly.io/)"
echo "   - iOS App Signer"
