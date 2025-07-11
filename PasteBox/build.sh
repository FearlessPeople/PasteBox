#!/bin/bash

# PasteBox 构建脚本
# 用于快速构建和运行应用

set -e

echo "🚀 开始构建 PasteBox..."

# 清理之前的构建
echo "🧹 清理构建缓存..."
xcodebuild clean -project ClipboardManager.xcodeproj -target ClipboardManager

# 构建应用（只构建主目标，避免测试目标的代码签名问题）
echo "🔨 构建应用..."
xcodebuild -project ClipboardManager.xcodeproj -target ClipboardManager -configuration Debug build

echo "✅ 构建完成！"

# 询问是否运行应用
read -p "是否立即运行应用？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 启动应用..."
    open build/Debug/ClipboardManager.app
fi
