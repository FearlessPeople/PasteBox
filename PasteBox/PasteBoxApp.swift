//
//  PasteBoxApp.swift
//  PasteBox
//
//  Created by zfang on 2025/7/10.
//

import SwiftUI
import AppKit

@main
struct PasteBoxApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardMonitor = ClipboardMonitor.shared
    @StateObject private var settingsManager = SettingsManager.shared

    var body: some Scene {
        // 主窗口（历史面板）
        WindowGroup("PasteBoxHistory") {
            ClipboardHistoryView()
                .environmentObject(clipboardMonitor)
                .environmentObject(settingsManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 400, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        // 设置窗口
        WindowGroup("Settings") {
            SettingsView()
                .environmentObject(settingsManager)
                .environmentObject(clipboardMonitor)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 500, height: 400)

        // 菜单栏 - 使用原生菜单样式
        MenuBarExtra("PasteBox", systemImage: "clipboard") {
            MenuBarView()
                .environmentObject(clipboardMonitor)
                .environmentObject(settingsManager)
        }
        .menuBarExtraStyle(.menu)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 Dock 图标（如果设置中配置为隐藏）
        if !SettingsManager.shared.showInDock {
            NSApp.setActivationPolicy(.accessory)
        }

        // 启动剪贴板监听
        ClipboardMonitor.shared.startMonitoring()

        // 加载历史数据
        ClipboardMonitor.shared.loadItems()

        // 设置全局快捷键监听
        setupGlobalHotkeyListener()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 停止剪贴板监听
        ClipboardMonitor.shared.stopMonitoring()
    }

    private func setupGlobalHotkeyListener() {
        // 监听快捷键按下通知
        NotificationCenter.default.addObserver(
            forName: .hotkeyPressed,
            object: nil,
            queue: .main
        ) { _ in
            WindowManager.shared.toggleHistoryWindow()
        }

        // 监听其他窗口显示通知
        NotificationCenter.default.addObserver(
            forName: .showHistoryWindow,
            object: nil,
            queue: .main
        ) { _ in
            WindowManager.shared.showHistoryWindow()
        }

        NotificationCenter.default.addObserver(
            forName: .showSettingsWindow,
            object: nil,
            queue: .main
        ) { _ in
            WindowManager.shared.showSettingsWindow()
        }
    }
}
