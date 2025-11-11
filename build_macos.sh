#!/bin/bash

# macOS 发行版构建脚本
# 构建 KikoFlu 的 macOS 应用程序

set -e

echo "🚀 开始构建 macOS 发行版..."

# 检查依赖
echo "🔍 检查依赖环境..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter 未安装"
    exit 1
fi

echo "✅ 依赖检查通过"
echo ""

# 清理
echo "🧹 清理之前的构建..."
flutter clean
rm -rf macos/build

# 获取依赖
echo "📦 获取 Flutter 依赖..."
flutter pub get

# 构建 macOS Release 版本
echo "🔨 构建 macOS Release 版本..."
flutter build macos --release

# 检查构建结果
if [ ! -d "build/macos/Build/Products/Release/KikoFlu.app" ]; then
    echo "❌ 构建失败"
    exit 1
fi

echo "✅ 构建成功！"
echo ""

# 显示应用信息
echo "📱 macOS 应用程序信息："
ls -lh build/macos/Build/Products/Release/KikoFlu.app
echo ""

# 创建 DMG（可选）
echo "📦 是否要创建 DMG 安装包？(y/n)"
read -r create_dmg

if [ "$create_dmg" = "y" ] || [ "$create_dmg" = "Y" ]; then
    echo "🔨 创建 DMG 安装包..."
    
    # 清理旧的 DMG
    rm -f KikoFlu-macOS.dmg
    
    # 创建临时目录
    mkdir -p build/dmg
    
    # 复制应用到临时目录
    cp -R build/macos/Build/Products/Release/KikoFlu.app build/dmg/
    
    # 创建 DMG
    hdiutil create -volname "KikoFlu" \
        -srcfolder build/dmg \
        -ov -format UDZO \
        KikoFlu-macOS.dmg
    
    # 清理临时目录
    rm -rf build/dmg
    
    if [ -f "KikoFlu-macOS.dmg" ]; then
        echo "✅ DMG 创建成功！"
        echo ""
        echo "📦 DMG 文件信息："
        ls -lh KikoFlu-macOS.dmg
        echo ""
        echo "📍 文件位置:"
        echo "$(pwd)/KikoFlu-macOS.dmg"
    else
        echo "❌ DMG 创建失败"
    fi
fi

echo ""
echo "📍 应用程序位置:"
echo "$(pwd)/build/macos/Build/Products/Release/KikoFlu.app"
echo ""
echo "📝 可以直接运行应用程序或将其拖到应用程序文件夹"
echo "   对于分发，建议创建 DMG 或进行代码签名"
echo ""
echo "✅ 所有任务完成！"
