#!/bin/bash

# PasteBox 应用打包脚本
# 创建可分发的 macOS 应用包

echo "🚀 开始打包 PasteBox 应用..."

# 配置变量
APP_NAME="PasteBox"
VERSION="1.0.0"
BUILD_DIR="build/Debug"
DIST_DIR="dist"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
PACKAGE_NAME="$APP_NAME-$VERSION"

# 检查应用是否存在
if [ ! -d "$APP_PATH" ]; then
    echo "❌ 错误：找不到应用文件 $APP_PATH"
    echo "请先运行构建命令：xcodebuild -project PasteBox.xcodeproj -target PasteBox -configuration Debug build"
    exit 1
fi

echo "📱 找到应用: $APP_PATH"

# 创建分发目录
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📦 创建分发包..."

# 方法1: 创建 ZIP 压缩包
echo "📦 创建 ZIP 压缩包..."
cd "$BUILD_DIR"
zip -r "../../$DIST_DIR/$PACKAGE_NAME.zip" "$APP_NAME.app" -x "*.DS_Store"
cd ../..

if [ $? -eq 0 ]; then
    echo "✅ ZIP 包创建成功: $DIST_DIR/$PACKAGE_NAME.zip"
else
    echo "❌ ZIP 包创建失败"
fi

# 方法2: 创建 DMG 安装包
echo "📦 创建 DMG 安装包..."

# 创建临时目录
TEMP_DMG_DIR="temp_dmg"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# 复制应用到临时目录
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# 创建 Applications 链接
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# 创建 DMG
DMG_NAME="$DIST_DIR/$PACKAGE_NAME.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_NAME"

if [ $? -eq 0 ]; then
    echo "✅ DMG 包创建成功: $DMG_NAME"
else
    echo "❌ DMG 包创建失败"
fi

# 清理临时文件
rm -rf "$TEMP_DMG_DIR"

# 方法3: 直接复制应用文件
echo "📦 复制独立应用文件..."
cp -R "$APP_PATH" "$DIST_DIR/$APP_NAME.app"

if [ $? -eq 0 ]; then
    echo "✅ 独立应用复制成功: $DIST_DIR/$APP_NAME.app"
else
    echo "❌ 独立应用复制失败"
fi

# 显示文件信息
echo ""
echo "📊 打包结果："
echo "----------------------------------------"
ls -la "$DIST_DIR/"
echo "----------------------------------------"

# 计算文件大小
if [ -f "$DIST_DIR/$PACKAGE_NAME.zip" ]; then
    ZIP_SIZE=$(stat -f%z "$DIST_DIR/$PACKAGE_NAME.zip" 2>/dev/null || stat -c%s "$DIST_DIR/$PACKAGE_NAME.zip" 2>/dev/null)
    echo "📦 ZIP 包大小: $(echo $ZIP_SIZE | awk '{printf "%.2f MB", $1/1024/1024}')"
fi

if [ -f "$DMG_NAME" ]; then
    DMG_SIZE=$(stat -f%z "$DMG_NAME" 2>/dev/null || stat -c%s "$DMG_NAME" 2>/dev/null)
    echo "💿 DMG 包大小: $(echo $DMG_SIZE | awk '{printf "%.2f MB", $1/1024/1024}')"
fi

if [ -d "$DIST_DIR/$APP_NAME.app" ]; then
    APP_SIZE=$(du -sm "$DIST_DIR/$APP_NAME.app" | cut -f1)
    echo "📱 应用大小: ${APP_SIZE} MB"
fi

echo ""
echo "🎉 打包完成！"
echo ""
echo "📋 分发选项："
echo "1. 📦 ZIP 压缩包: $DIST_DIR/$PACKAGE_NAME.zip"
echo "   - 适合: 网络传输、邮件分享"
echo "   - 使用: 下载后解压，拖拽到 Applications 文件夹"
echo ""
echo "2. 💿 DMG 安装包: $DMG_NAME"
echo "   - 适合: 专业分发、官方下载"
echo "   - 使用: 双击打开，拖拽应用到 Applications 文件夹"
echo ""
echo "3. 📱 独立应用: $DIST_DIR/$APP_NAME.app"
echo "   - 适合: 直接使用、测试"
echo "   - 使用: 双击直接运行或拖拽到 Applications 文件夹"
echo ""
echo "💡 安装说明："
echo "- 系统要求: macOS 15.5 或更高版本"
echo "- 首次运行可能需要在系统偏好设置中允许运行"
echo "- 需要授予辅助功能权限以使用自动粘贴功能"
echo ""
echo "🔧 如果 Dock 图标不显示："
echo "1. 重启 Dock: killall Dock"
echo "2. 重新注册应用: /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted '$DIST_DIR/$APP_NAME.app'"
echo ""
echo "📂 所有文件已保存到: $DIST_DIR/"
