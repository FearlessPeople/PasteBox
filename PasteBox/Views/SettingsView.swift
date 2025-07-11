//
//  SettingsView.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import SwiftUI
import Carbon

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .environmentObject(settingsManager)
                .environmentObject(clipboardMonitor)
                .tabItem {
                    Image(systemName: "gear")
                    Text("通用")
                }
            
            HotkeySettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("快捷键")
                }
            
            PrivacySettingsView()
                .environmentObject(settingsManager)
                .tabItem {
                    Image(systemName: "hand.raised")
                    Text("隐私")
                }
            
            PerformanceView()
                .environmentObject(PerformanceMonitor.shared)
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("性能")
                }

            AboutView()
                .tabItem {
                    Image(systemName: "info.circle")
                    Text("关于")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    @State private var showingExportPanel = false
    @State private var showingImportPanel = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
    
    var body: some View {
        Form {
            Section("应用设置") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("开机自动启动", isOn: $settingsManager.launchAtLogin)
                    Toggle("在 Dock 中显示", isOn: $settingsManager.showInDock)
                    Toggle("启用声音效果", isOn: $settingsManager.enableSounds)
                }
                .padding(.vertical, 4)
            }

            Section("历史记录") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("最大保存数量:")
                            .frame(minWidth: 120, alignment: .leading)
                        Spacer()
                        TextField("", value: $settingsManager.maxHistoryItems, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("项")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("自动删除:")
                            .frame(minWidth: 120, alignment: .leading)
                        Spacer()
                        TextField("", value: $settingsManager.autoDeleteAfterDays, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("天后")
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    HStack {
                        Text("当前历史数量:")
                            .frame(minWidth: 120, alignment: .leading)
                        Spacer()
                        Text("\(clipboardMonitor.items.count)")
                            .foregroundColor(.secondary)
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("数据管理") {
                VStack(alignment: .leading, spacing: 16) {
                    // 操作按钮组
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Button("清空所有历史") {
                                clipboardMonitor.clearAll()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                            .help("删除所有剪贴板历史记录")

                            Button("优化存储") {
                                PersistenceManager.shared.optimizeStorage()
                            }
                            .buttonStyle(.bordered)
                            .help("清理和优化存储空间")

                            Spacer()
                        }

                        HStack(spacing: 12) {
                            Button("导出历史数据") {
                                exportData()
                            }
                            .buttonStyle(.bordered)
                            .help("导出历史数据到文件")

                            Button("导入历史数据") {
                                importData()
                            }
                            .buttonStyle(.bordered)
                            .help("从文件导入历史数据")

                            Spacer()
                        }
                    }

                    Divider()

                    // 存储信息
                    let fileInfo = PersistenceManager.shared.getDataFileInfo()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("存储信息")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        HStack {
                            Text("文件大小:")
                                .frame(minWidth: 80, alignment: .leading)
                            Text(PersistenceManager.shared.formatFileSize(fileInfo.size))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .font(.caption)

                        if let lastModified = fileInfo.lastModified {
                            HStack {
                                Text("最后更新:")
                                    .frame(minWidth: 80, alignment: .leading)
                                Text(lastModified, formatter: dateFormatter)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fileExporter(
            isPresented: $showingExportPanel,
            document: ClipboardDataDocument(items: clipboardMonitor.items),
            contentType: .json,
            defaultFilename: "clipboard_history_\(Date().timeIntervalSince1970)"
        ) { result in
            switch result {
            case .success(let url):
                print("数据导出成功: \(url)")
            case .failure(let error):
                print("数据导出失败: \(error)")
            }
        }
        .fileImporter(
            isPresented: $showingImportPanel,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    importDataFromURL(url)
                }
            case .failure(let error):
                print("数据导入失败: \(error)")
            }
        }
    }

    private func exportData() {
        showingExportPanel = true
    }

    private func importData() {
        showingImportPanel = true
    }

    private func importDataFromURL(_ url: URL) {
        do {
            let items = try PersistenceManager.shared.importData(from: url)
            // 合并导入的数据
            for item in items {
                clipboardMonitor.addItem(item)
            }
            print("成功导入 \(items.count) 个项目")
        } catch {
            print("导入数据失败: \(error)")
        }
    }
}

struct HotkeySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var isRecording = false
    @State private var recordedKeyCode: Int?
    @State private var recordedModifiers: ModifierFlags = []
    
    var body: some View {
        Form {
            Section("全局快捷键") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("显示历史面板:")
                            .frame(minWidth: 120, alignment: .leading)
                        Spacer()

                        HotkeyRecorderView(
                            hotkey: $settingsManager.hotkey,
                            isRecording: $isRecording
                        )
                    }

                    Text("点击快捷键区域开始录制新的快捷键组合")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("预设快捷键") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Button("⌘⇧V") {
                            settingsManager.hotkey = HotkeyConfiguration(
                                keyCode: UInt16(kVK_ANSI_V),
                                modifierFlags: [.command, .shift]
                            )
                        }
                        .buttonStyle(.bordered)

                        Button("⌘⌥C") {
                            settingsManager.hotkey = HotkeyConfiguration(
                                keyCode: UInt16(kVK_ANSI_C),
                                modifierFlags: [.command, .option]
                            )
                        }
                        .buttonStyle(.bordered)

                        Button("⌃⇧Space") {
                            settingsManager.hotkey = HotkeyConfiguration(
                                keyCode: UInt16(kVK_Space),
                                modifierFlags: [.control, .shift]
                            )
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }

                    Text("选择一个预设快捷键或自定义")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct HotkeyRecorderView: View {
    @Binding var hotkey: HotkeyConfiguration
    @Binding var isRecording: Bool
    @State private var displayText: String = ""
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: NSEvent.ModifierFlags = []

    var body: some View {
        Button(action: {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            Text(isRecording ? "按下快捷键... (ESC取消)" : hotkey.displayString)
                .frame(minWidth: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .background(isRecording ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(6)
        .onAppear {
            displayText = hotkey.displayString
        }
        .overlay(
            // 透明的事件捕获视图
            isRecording ?
            KeyEventCaptureView { keyCode, modifiers in
                handleKeyEvent(keyCode: keyCode, modifiers: modifiers)
            }
            .allowsHitTesting(true)
            : nil
        )
    }

    private func startRecording() {
        isRecording = true
        recordedKeyCode = nil
        recordedModifiers = []
    }

    private func stopRecording() {
        isRecording = false

        if let keyCode = recordedKeyCode, !recordedModifiers.isEmpty {
            let modifierFlags = ModifierFlags(recordedModifiers)
            hotkey = HotkeyConfiguration(keyCode: keyCode, modifierFlags: modifierFlags)
        }
    }

    private func handleKeyEvent(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        // ESC键取消录制
        if keyCode == 53 { // ESC key
            isRecording = false
            return
        }

        // 需要至少一个修饰键
        let validModifiers = modifiers.intersection([.command, .option, .control, .shift])
        if !validModifiers.isEmpty {
            recordedKeyCode = keyCode
            recordedModifiers = validModifiers
            stopRecording()
        }
    }
}

// 辅助视图用于捕获键盘事件
struct KeyEventCaptureView: NSViewRepresentable {
    let onKeyEvent: (UInt16, NSEvent.ModifierFlags) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyEvent = onKeyEvent
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyCaptureView: NSView {
    var onKeyEvent: ((UInt16, NSEvent.ModifierFlags) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        onKeyEvent?(event.keyCode, event.modifierFlags)
    }

    override func flagsChanged(with event: NSEvent) {
        // 处理修饰键变化
        super.flagsChanged(with: event)
    }
}

extension ModifierFlags {
    init(_ nsModifiers: NSEvent.ModifierFlags) {
        self.init()
        if nsModifiers.contains(.command) {
            self.insert(.command)
        }
        if nsModifiers.contains(.shift) {
            self.insert(.shift)
        }
        if nsModifiers.contains(.option) {
            self.insert(.option)
        }
        if nsModifiers.contains(.control) {
            self.insert(.control)
        }
    }
}

struct PrivacySettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var newAppIdentifier = ""
    
    var body: some View {
        Form {
            Section("排除的应用") {
                Text("以下应用的剪贴板内容将不会被记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                List {
                    ForEach(Array(settingsManager.excludedApps), id: \.self) { appId in
                        HStack {
                            Text(appId)
                            Spacer()
                            Button("移除") {
                                settingsManager.removeExcludedApp(appId)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .frame(height: 150)
                
                HStack {
                    TextField("应用包标识符 (Bundle ID)", text: $newAppIdentifier)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("添加") {
                        if !newAppIdentifier.isEmpty {
                            settingsManager.addExcludedApp(newAppIdentifier)
                            newAppIdentifier = ""
                        }
                    }
                    .disabled(newAppIdentifier.isEmpty)
                }
            }
            
            Section("常见应用") {
                let commonApps = [
                    ("1Password", "com.1password.1password"),
                    ("Keychain Access", "com.apple.keychainaccess"),
                    ("Terminal", "com.apple.Terminal"),
                    ("密码管理器", "com.apple.Passwords")
                ]
                
                ForEach(commonApps, id: \.1) { name, bundleId in
                    HStack {
                        Text(name)
                        Spacer()
                        if settingsManager.excludedApps.contains(bundleId) {
                            Button("已排除") {
                                settingsManager.removeExcludedApp(bundleId)
                            }
                            .foregroundColor(.green)
                        } else {
                            Button("排除") {
                                settingsManager.addExcludedApp(bundleId)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

struct PerformanceView: View {
    @EnvironmentObject var performanceMonitor: PerformanceMonitor
    @State private var performanceReport: PerformanceReport?

    var body: some View {
        Form {
            Section("实时性能指标") {
                HStack {
                    Text("内存使用:")
                    Spacer()
                    Text(ByteCountFormatter().string(fromByteCount: performanceMonitor.memoryUsage))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("项目数量:")
                    Spacer()
                    Text("\(performanceMonitor.itemCount)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("平均项目大小:")
                    Spacer()
                    Text(ByteCountFormatter().string(fromByteCount: performanceMonitor.averageItemSize))
                        .foregroundColor(.secondary)
                }
            }

            if let report = performanceReport {
                Section("详细报告") {
                    HStack {
                        Text("应用内存使用:")
                        Spacer()
                        Text(report.formattedMemoryUsage)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("数据总大小:")
                        Spacer()
                        Text(report.formattedTotalDataSize)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("最大项目大小:")
                        Spacer()
                        Text(report.formattedLargestItemSize)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("收藏项目数:")
                        Spacer()
                        Text("\(report.favoriteItemsCount)")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("操作") {
                HStack {
                    Button("生成性能报告") {
                        performanceReport = performanceMonitor.getPerformanceReport()
                    }

                    Button("清理内存") {
                        ClipboardMonitor.shared.performMemoryCleanup()
                        performanceReport = performanceMonitor.getPerformanceReport()
                    }

                    Spacer()
                }

                HStack {
                    Button("优化存储") {
                        PersistenceManager.shared.optimizeStorageWithPerformanceMonitoring()
                        performanceReport = performanceMonitor.getPerformanceReport()
                    }

                    Button("定期清理") {
                        ClipboardMonitor.shared.performScheduledCleanup()
                        performanceReport = performanceMonitor.getPerformanceReport()
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .onAppear {
            performanceReport = performanceMonitor.getPerformanceReport()
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            VStack(spacing: 8) {
                Text("剪贴板管理器")
                    .font(.title)
                    .fontWeight(.bold)

                Text("版本 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("一个简洁高效的 macOS 剪贴板管理工具")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)

                Button("反馈问题") {
                    if let url = URL(string: "mailto:feedback@clipboardmanager.com") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }

            Spacer()

            Text("© 2025 ClipboardManager. All rights reserved.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager.shared)
        .environmentObject(ClipboardMonitor.shared)
}
