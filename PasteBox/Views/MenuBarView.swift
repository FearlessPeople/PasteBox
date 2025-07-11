//
//  MenuBarView.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var clipboardMonitor: ClipboardMonitor
    @EnvironmentObject var settingsManager: SettingsManager

    var body: some View {
        // 直接返回菜单内容，使用完全原生的macOS样式
        Group {
            // 1. 偏好设置
            Button("偏好设置") {
                WindowManager.shared.showSettingsWindow()
            }
            .keyboardShortcut(",", modifiers: .command)

            // 2. 停止/开始监听
            Button(clipboardMonitor.isMonitoring ? "停止监听" : "开始监听") {
                toggleMonitoring()
            }
            // 3. 检查更新
            Button("检查更新") {
                checkForUpdates()
            }

            // 4. 开源地址
            Button("开源地址") {
                openSourceRepository()
            }

            // 5. 重启应用
            Button("重启应用") {
                restartApplication()
            }

            // 6. 退出应用
            Button("退出应用") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }

    // 辅助函数
    private func toggleMonitoring() {
        if clipboardMonitor.isMonitoring {
            clipboardMonitor.stopMonitoring()
        } else {
            clipboardMonitor.startMonitoring()
        }
    }

    private func checkForUpdates() {
        // 检查更新功能
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "检查更新"
            alert.informativeText = "当前版本：1.0.0\n\n这是一个演示版本。在实际应用中，这里会连接到更新服务器检查新版本。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }

    private func openSourceRepository() {
        // 打开开源地址
        if let url = URL(string: "https://github.com/your-username/PasteBox") {
            NSWorkspace.shared.open(url)
        }
    }

    private func restartApplication() {
        // 重启应用
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "重启应用"
            alert.informativeText = "确定要重启 PasteBox 吗？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "重启")
            alert.addButton(withTitle: "取消")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // 执行重启
                let task = Process()
                task.launchPath = "/usr/bin/open"
                task.arguments = [Bundle.main.bundlePath]
                task.launch()

                NSApplication.shared.terminate(nil)
            }
        }
    }
}



#Preview {
    MenuBarView()
        .environmentObject(ClipboardMonitor.shared)
        .environmentObject(SettingsManager.shared)
}
