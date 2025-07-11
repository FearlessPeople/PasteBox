//
//  WindowManager.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation
import SwiftUI
import AppKit

/// 窗口管理器
class WindowManager: ObservableObject {
    static let shared = WindowManager()

    private var historyWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var historyWindowDelegate: HistoryWindowDelegate?

    // 记录打开面板前的前台应用
    private var previousFrontmostApp: NSRunningApplication?

    // 外部点击监听器
    private var outsideClickMonitor: Any?

    private init() {}
    


    // MARK: - Previous App Management

    /// 在显示面板前记录当前前台应用
    private func capturePreviousApp() {
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appName = frontApp.localizedName ?? "Unknown"
            let bundleID = frontApp.bundleIdentifier ?? "Unknown"
            let pid = frontApp.processIdentifier

            // 只记录非PasteBox的应用
            if bundleID != Bundle.main.bundleIdentifier {
                previousFrontmostApp = frontApp
                print("✅ 记录前台应用: \(appName), Bundle ID: \(bundleID), PID: \(pid)")
            } else {
                print("⚠️ 当前前台应用是PasteBox，保持之前记录: \(previousFrontmostApp?.localizedName ?? "None")")
            }
        } else {
            print("❌ 未检测到前台应用")
        }
    }

    /// 获取之前记录的前台应用
    func getPreviousFrontmostApp() -> NSRunningApplication? {
        if let app = previousFrontmostApp {
            // 检查应用是否仍然有效
            if app.isTerminated {
                print("❌ 之前记录的应用已终止: \(app.localizedName ?? "Unknown")")
                previousFrontmostApp = nil
                return nil
            }

            print("✅ 返回之前记录的应用: \(app.localizedName ?? "Unknown") (\(app.bundleIdentifier ?? "Unknown"))")
            return app
        } else {
            print("❌ 没有记录的前台应用")
            return nil
        }
    }

    // MARK: - History Window Management

    /// 显示历史窗口
    func showHistoryWindow() {
        print("🎯 显示历史窗口")
        if let window = historyWindow {
            // 如果窗口已存在，确保位置一致后激活并显示
            let windowSize = window.frame.size
            let consistentPosition = getConsistentWindowPosition(for: windowSize)
            window.setFrame(NSRect(origin: consistentPosition, size: windowSize), display: true)

            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
            print("✅ 显示已存在的历史窗口 - 位置: \(consistentPosition)")
        } else {
            // 创建新的历史窗口
            createHistoryWindow()
            print("✅ 创建并显示新的历史窗口")
        }

        // 启动外部点击监听
        startOutsideClickMonitoring()
    }
    
    /// 隐藏历史窗口
    func hideHistoryWindow() {
        historyWindow?.orderOut(nil)
        // 停止外部点击监听
        stopOutsideClickMonitoring()
    }
    
    /// 切换历史窗口显示状态
    func toggleHistoryWindow() {
        if let window = historyWindow, window.isVisible {
            print("🔄 切换窗口状态: 隐藏窗口")
            hideHistoryWindow()
        } else {
            print("🔄 切换窗口状态: 显示窗口")
            // 关键：在显示窗口前记录当前前台应用
            capturePreviousApp()
            showHistoryWindow()
        }
    }
    
    /// 创建历史窗口
    private func createHistoryWindow() {
        let contentView = ClipboardHistoryView()
            .environmentObject(ClipboardMonitor.shared)
            .environmentObject(SettingsManager.shared)

        // 定义统一的窗口大小
        let windowSize = NSSize(width: 400, height: 600)
        let windowPosition = getConsistentWindowPosition(for: windowSize)

        let window = NSWindow(
            contentRect: NSRect(origin: windowPosition, size: windowSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = "PasteBox 历史"
        window.contentView = NSHostingView(rootView: contentView)

        // 不使用center()和setFrameAutosaveName，确保位置一致
        window.setFrame(NSRect(origin: windowPosition, size: windowSize), display: true)

        // 设置窗口属性
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 设置窗口关闭行为 - 保持对delegate的强引用
        let delegate = HistoryWindowDelegate()
        window.delegate = delegate
        self.historyWindowDelegate = delegate

        self.historyWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()

        print("✅ 创建历史窗口 - 位置: \(windowPosition), 大小: \(windowSize)")
    }
    
    // MARK: - Settings Window Management
    
    /// 显示设置窗口
    func showSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            createSettingsWindow()
        }
    }
    
    /// 创建设置窗口
    private func createSettingsWindow() {
        let contentView = SettingsView()
            .environmentObject(SettingsManager.shared)
            .environmentObject(ClipboardMonitor.shared)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "PasteBox 设置"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.setFrameAutosaveName("SettingsWindow")
        
        window.isReleasedWhenClosed = false
        
        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Utility Methods
    
    /// 获取一致的窗口位置（无论打开方式如何都保持相同位置）
    private func getConsistentWindowPosition(for windowSize: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint(x: 100, y: 100)
        }

        let screenFrame = screen.visibleFrame

        // 计算屏幕中心偏右上的固定位置
        let x = screenFrame.midX - windowSize.width / 2 + 100 // 稍微偏右
        let y = screenFrame.midY - windowSize.height / 2 + 100 // 稍微偏上

        // 确保窗口完全在屏幕范围内
        let finalX = max(screenFrame.minX, min(x, screenFrame.maxX - windowSize.width))
        let finalY = max(screenFrame.minY, min(y, screenFrame.maxY - windowSize.height))

        return NSPoint(x: finalX, y: finalY)
    }

    /// 获取鼠标位置附近的最佳窗口位置（保留用于其他用途）
    func getOptimalWindowPosition(for windowSize: NSSize) -> NSPoint {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero

        var x = mouseLocation.x - windowSize.width / 2
        var y = mouseLocation.y - windowSize.height / 2

        // 确保窗口在屏幕范围内
        x = max(screenFrame.minX, min(x, screenFrame.maxX - windowSize.width))
        y = max(screenFrame.minY, min(y, screenFrame.maxY - windowSize.height))

        return NSPoint(x: x, y: y)
    }
    
    /// 关闭所有窗口
    func closeAllWindows() {
        stopOutsideClickMonitoring()
        historyWindow?.close()
        settingsWindow?.close()
        historyWindow = nil
        settingsWindow = nil
    }

    // MARK: - Outside Click Monitoring

    /// 启动外部点击监听
    private func startOutsideClickMonitoring() {
        // 先停止之前的监听器
        stopOutsideClickMonitoring()

        print("🎯 启动外部点击监听")

        // 监听全局鼠标点击事件
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }

            // 检查点击是否在历史窗口外部
            if let window = self.historyWindow, window.isVisible {
                // 获取鼠标在屏幕上的位置
                let mouseLocation = NSEvent.mouseLocation
                let windowFrame = window.frame

                print("🖱️ 检测到点击 - 鼠标位置: \(mouseLocation), 窗口范围: \(windowFrame)")

                // 如果点击位置不在窗口范围内，隐藏窗口
                if !windowFrame.contains(mouseLocation) {
                    print("✅ 外部点击确认，隐藏历史面板")
                    DispatchQueue.main.async {
                        self.hideHistoryWindow()
                    }
                } else {
                    print("📍 点击在窗口内部，保持显示")
                }
            }
        }

        // 同时监听应用失去焦点事件
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    /// 停止外部点击监听
    private func stopOutsideClickMonitoring() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
            print("🛑 停止外部点击监听")
        }

        NotificationCenter.default.removeObserver(
            self,
            name: NSApplication.didResignActiveNotification,
            object: nil
        )
    }

    /// 应用失去焦点时的处理
    @objc private func applicationDidResignActive() {
        // 当PasteBox失去焦点时，隐藏历史面板
        if let window = historyWindow, window.isVisible {
            print("📱 应用失去焦点，隐藏历史面板")
            hideHistoryWindow()
        }
    }


}

// MARK: - Window Delegate

class HistoryWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // 当窗口关闭时，只隐藏而不销毁
        if let window = notification.object as? NSWindow {
            window.orderOut(nil)
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
        // 当窗口失去焦点时，可以选择自动隐藏
        // 这里暂时不实现自动隐藏，让用户手动控制
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let showHistoryWindow = Notification.Name("showHistoryWindow")
    static let hideHistoryWindow = Notification.Name("hideHistoryWindow")
    static let showSettingsWindow = Notification.Name("showSettingsWindow")
}
