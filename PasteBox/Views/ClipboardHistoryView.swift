//
//  ClipboardHistoryView.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import SwiftUI
import AppKit

/// 简化的双击粘贴：复制内容 → 隐藏窗口 → 直接获取前台应用 → 发送Cmd+V
func smartPasteToFrontmostApp(item: ClipboardItem) {
    // 检查辅助功能权限
    guard checkAccessibilityPermission() else {
        print("需要辅助功能权限才能使用自动粘贴功能")
        showAccessibilityPermissionAlert()
        return
    }

    print("🚀 开始直接粘贴流程")

    // 1. 立即复制内容到系统剪贴板
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    if let textContent = item.getTextContent() {
        pasteboard.setString(textContent, forType: .string)
        print("✅ 已复制文本内容到剪贴板: \(textContent.prefix(50))...")
    } else {
        // 对于非文本内容，使用原有的复制方法
        switch item.type {
        case .image:
            pasteboard.setData(item.content, forType: .tiff)
            print("✅ 已复制图片内容到剪贴板")
        case .file:
            pasteboard.setData(item.content, forType: .fileURL)
            print("✅ 已复制文件内容到剪贴板")
        default:
            pasteboard.setData(item.content, forType: .string)
            print("✅ 已复制其他类型内容到剪贴板")
        }
    }

    // 2. 立即隐藏PasteBox窗口
    WindowManager.shared.hideHistoryWindow()
    print("✅ 已隐藏PasteBox窗口")

    // 3. 获取之前记录的前台应用并切换（优化延迟时间）
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let previousApp = WindowManager.shared.getPreviousFrontmostApp() {
            print("🎯 准备切换到之前的应用: \(previousApp.localizedName ?? "Unknown")")

            // 激活之前的应用
            previousApp.activate()

            // 优化：减少等待时间，使用智能检测
            activateAppAndPasteOptimized(previousApp)
        } else {
            print("❌ 没有记录的前台应用，直接粘贴")
            performDirectPaste()
        }
    }
}

/// 优化的应用激活和粘贴方法
func activateAppAndPasteOptimized(_ targetApp: NSRunningApplication) {
    var attempts = 0
    let maxAttempts = 3
    let checkInterval: TimeInterval = 0.1 // 每100ms检查一次

    func checkActivationAndPaste() {
        attempts += 1

        if let currentApp = NSWorkspace.shared.frontmostApplication,
           currentApp.bundleIdentifier == targetApp.bundleIdentifier {
            // 应用已成功激活
            print("✅ 应用激活成功 (尝试 \(attempts)): \(currentApp.localizedName ?? "Unknown")")
            performDirectPaste()
        } else if attempts < maxAttempts {
            // 继续等待
            print("⏳ 等待应用激活 (尝试 \(attempts)/\(maxAttempts))")
            DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
                checkActivationAndPaste()
            }
        } else {
            // 超时，直接粘贴
            print("⚠️ 应用激活超时，直接粘贴")
            performDirectPaste()
        }
    }

    // 开始检查
    DispatchQueue.main.asyncAfter(deadline: .now() + checkInterval) {
        checkActivationAndPaste()
    }
}

/// 直接粘贴到当前前台应用
func performDirectPaste() {
    // 再次检查当前前台应用
    if let frontApp = NSWorkspace.shared.frontmostApplication {
        let appName = frontApp.localizedName ?? "Unknown"
        let bundleID = frontApp.bundleIdentifier ?? "Unknown"
        print("📋 最终执行粘贴到: \(appName) (\(bundleID))")
    }

    // 直接发送Cmd+V
    performSystemPaste()
}

/// 检查辅助功能权限
func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
    return AXIsProcessTrustedWithOptions(options as CFDictionary)
}

/// 显示权限提示
func showAccessibilityPermissionAlert() {
    let alert = NSAlert()
    alert.messageText = "需要辅助功能权限"
    alert.informativeText = "为了使用双击自动粘贴功能，请在系统偏好设置中授予 ClipboardManager 辅助功能权限。\n\n系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能"
    alert.alertStyle = .warning
    alert.addButton(withTitle: "打开系统偏好设置")
    alert.addButton(withTitle: "取消")

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
        // 打开系统偏好设置
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}







/// 执行系统级粘贴操作 (Cmd+V)
func performSystemPaste() {
    let currentApp = NSWorkspace.shared.frontmostApplication
    print("执行粘贴到: \(currentApp?.localizedName ?? "Unknown")")

    guard let source = CGEventSource(stateID: .hidSystemState) else {
        print("错误：无法创建事件源")
        return
    }

    // 创建 Cmd+V 按键事件 (V键的虚拟键码是0x09)
    guard let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
          let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) else {
        print("错误：无法创建按键事件")
        return
    }

    // 添加 Command 修饰键
    keyDownEvent.flags = .maskCommand
    keyUpEvent.flags = .maskCommand

    // 发送按键按下事件
    keyDownEvent.post(tap: .cghidEventTap)
    print("已发送 Cmd+V 按键按下事件")

    // 短暂延迟后发送按键释放事件
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
        keyUpEvent.post(tap: .cghidEventTap)
        print("已发送 Cmd+V 按键释放事件 - 粘贴操作完成")
    }
}

struct ClipboardHistoryView: View {
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var searchText = ""
    @State private var selectedType: ClipboardItemType? = nil
    @State private var sortOption: SortOption = .dateDescending
    @State private var showFavoritesOnly = false
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ClipboardItem?

    enum SortOption: String, CaseIterable {
        case dateDescending = "最新优先"
        case dateAscending = "最旧优先"
        case sizeDescending = "大小降序"
        case sizeAscending = "大小升序"
        case typeGrouped = "按类型分组"
        case favoritesFirst = "收藏优先"
    }
    
    var filteredItems: [ClipboardItem] {
        var items = clipboardMonitor.items

        // 按收藏状态过滤
        if showFavoritesOnly {
            items = items.filter { $0.isFavorite }
        }

        // 按类型过滤
        if let selectedType = selectedType {
            if selectedType == .text {
                // "文本"过滤器包含纯文本和富文本
                items = items.filter { $0.type == .text || $0.type == .richText }
            } else {
                items = items.filter { $0.type == selectedType }
            }
        }

        // 按搜索文本过滤
        if !searchText.isEmpty {
            items = items.filter { item in
                item.displayContent.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // 排序
        switch sortOption {
        case .dateDescending:
            items = items.sorted { $0.createdAt > $1.createdAt }
        case .dateAscending:
            items = items.sorted { $0.createdAt < $1.createdAt }
        case .sizeDescending:
            items = items.sorted { $0.size > $1.size }
        case .sizeAscending:
            items = items.sorted { $0.size < $1.size }
        case .typeGrouped:
            items = items.sorted {
                if $0.type != $1.type {
                    return $0.type.rawValue < $1.type.rawValue
                }
                return $0.createdAt > $1.createdAt
            }
        case .favoritesFirst:
            items = items.sorted {
                if $0.isFavorite != $1.isFavorite {
                    return $0.isFavorite && !$1.isFavorite
                }
                return $0.createdAt > $1.createdAt
            }
        }

        return items
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索和过滤栏
            VStack(spacing: 6) {
                    // 搜索框
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("搜索剪贴板历史...", text: $searchText)
                            .textFieldStyle(.plain)

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
                    


                    // 紧凑的水平过滤器布局
                    HStack(spacing: 8) {
                        // 主要过滤器 - 减少间距
                        HStack(spacing: 4) {
                            FilterChip(
                                title: "全部",
                                isSelected: selectedType == nil && !showFavoritesOnly,
                                action: {
                                    selectedType = nil
                                    showFavoritesOnly = false
                                }
                            )

                            FilterChip(
                                title: "文本",
                                isSelected: selectedType == .text || selectedType == .richText,
                                action: {
                                    selectedType = .text
                                    showFavoritesOnly = false
                                }
                            )

                            FilterChip(
                                title: "图片",
                                isSelected: selectedType == .image,
                                action: {
                                    selectedType = .image
                                    showFavoritesOnly = false
                                }
                            )

                            FilterChip(
                                title: "文件",
                                isSelected: selectedType == .file,
                                action: {
                                    selectedType = .file
                                    showFavoritesOnly = false
                                }
                            )

                            FilterChip(
                                title: "收藏",
                                isSelected: showFavoritesOnly,
                                action: {
                                    showFavoritesOnly.toggle()
                                    if showFavoritesOnly {
                                        selectedType = nil
                                    }
                                }
                            )
                        }

                        Spacer()

                        // 紧凑的控制按钮组
                        HStack(spacing: 4) {
                            // 排序选择器
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(option.rawValue) {
                                        sortOption = option
                                    }
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.caption2)
                                    Text(sortOption.rawValue)
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .help("排序方式")
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }

                            // 设置按钮
                            Button(action: {
                                WindowManager.shared.showSettingsWindow()
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("设置")
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // 历史列表
                if filteredItems.isEmpty {
                    EmptyStateView(hasItems: !clipboardMonitor.items.isEmpty)
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(filteredItems) { item in
                                ClipboardItemRow(
                                    item: item,
                                    onCopy: {
                                        clipboardMonitor.copyToClipboard(item)
                                    },
                                    onDelete: {
                                        itemToDelete = item
                                        showingDeleteAlert = true
                                    },
                                    onToggleFavorite: {
                                        clipboardMonitor.toggleFavorite(item)
                                    },
                                    onDoubleClick: {
                                        // 智能粘贴：复制到剪贴板，切换到前台应用，然后粘贴
                                        smartPasteToFrontmostApp(item: item)
                                    }
                                )
                                .id(item.id)
                            }
                        }
                        .listStyle(.plain)
                        .onChange(of: clipboardMonitor.items.count) { _, newCount in
                            // 当有新项目添加时，滚动到顶部
                            if let firstItem = filteredItems.first {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(firstItem.id, anchor: .top)
                                }
                            }
                        }
                        .onAppear {
                            // 初始加载时滚动到顶部
                            if let firstItem = filteredItems.first {
                                proxy.scrollTo(firstItem.id, anchor: .top)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 底部状态栏
                HStack {
                    Text("\(filteredItems.count) / \(clipboardMonitor.items.count) 项")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if clipboardMonitor.isMonitoring {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("监听中")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
        }
        .alert("删除确认", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let item = itemToDelete {
                    clipboardMonitor.deleteItem(item)
                }
            }
        } message: {
            Text("确定要删除这个剪贴板项目吗？")
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct EmptyStateView: View {
    let hasItems: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasItems ? "magnifyingglass" : "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(hasItems ? "没有找到匹配的项目" : "暂无剪贴板历史")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !hasItems {
                Text("复制一些内容开始使用吧")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    let onToggleFavorite: () -> Void
    let onDoubleClick: () -> Void
    @State private var isHovered = false
    @State private var showingPreview = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // 类型图标或图片缩略图
                if item.type == .image, let image = item.getImageContent() {
                    // 显示图片缩略图
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    // 显示类型图标
                    Image(systemName: item.type.iconName)
                        .foregroundColor(.accentColor)
                        .frame(width: 20, height: 20)
                }

                // 内容区域
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayContent)
                        .lineLimit(showingPreview ? nil : 3)
                        .font(.system(size: 14))
                        .animation(.easeInOut(duration: 0.2), value: showingPreview)

                    HStack {
                        Text(item.timeAgo)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if item.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }

                        if !item.tags.isEmpty {
                            ForEach(item.tags.prefix(2), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }

                        Spacer()

                        // 文件大小显示
                        if item.size > 1024 {
                            Text(formatFileSize(item.size))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                // 操作按钮
                if isHovered {
                    HStack(spacing: 8) {
                        Button(action: {
                            showingPreview.toggle()
                        }) {
                            Image(systemName: showingPreview ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                        .help(showingPreview ? "收起预览" : "展开预览")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }

                        Button(action: onToggleFavorite) {
                            Image(systemName: item.isFavorite ? "star.fill" : "star")
                                .foregroundColor(item.isFavorite ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(item.isFavorite ? "取消收藏" : "添加收藏")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }

                        Button(action: onCopy) {
                            Image(systemName: "doc.on.doc")
                        }
                        .buttonStyle(.plain)
                        .help("复制")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("删除")
                        .onHover { hovering in
                            if hovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)

            // 扩展预览区域
            if showingPreview && item.type == .image {
                if let image = item.getImageContent() {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                }
            }
        }
        .background(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.isFavorite ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            print("双击检测到，执行智能粘贴")
            onDoubleClick()
        }
        .onTapGesture {
            // 延迟执行单击，避免与双击冲突
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onCopy()
            }
        }
        .contextMenu {
            Button("复制", action: onCopy)
            Button(item.isFavorite ? "取消收藏" : "添加收藏", action: onToggleFavorite)
            Divider()
            Button("删除", action: onDelete)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    ClipboardHistoryView()
        .environmentObject(ClipboardMonitor.shared)
        .environmentObject(SettingsManager.shared)
}
