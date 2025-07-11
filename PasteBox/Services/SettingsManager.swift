//
//  SettingsManager.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation
import SwiftUI
import AppKit
import Carbon
import ApplicationServices

/// 应用设置管理器
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    
    @Published var maxHistoryItems: Int {
        didSet {
            UserDefaults.standard.set(maxHistoryItems, forKey: "maxHistoryItems")
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            configureLaunchAtLogin()
        }
    }
    
    @Published var showInDock: Bool {
        didSet {
            UserDefaults.standard.set(showInDock, forKey: "showInDock")
            configureAppActivationPolicy()
        }
    }
    
    @Published var enableSounds: Bool {
        didSet {
            UserDefaults.standard.set(enableSounds, forKey: "enableSounds")
        }
    }
    
    @Published var autoDeleteAfterDays: Int {
        didSet {
            UserDefaults.standard.set(autoDeleteAfterDays, forKey: "autoDeleteAfterDays")
        }
    }
    
    @Published var excludedApps: Set<String> {
        didSet {
            UserDefaults.standard.set(Array(excludedApps), forKey: "excludedApps")
        }
    }
    
    @Published var hotkey: HotkeyConfiguration {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(hotkey), forKey: "hotkey")
            configureGlobalHotkey()
        }
    }
    
    // MARK: - Private Properties

    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var permissionCheckTimer: Timer?
    private var carbonHotKeyRef: EventHotKeyRef?
    private var carbonEventHandler: EventHandlerRef?
    
    // MARK: - Initialization
    
    private init() {
        // 加载设置
        self.maxHistoryItems = UserDefaults.standard.object(forKey: "maxHistoryItems") as? Int ?? 1000
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.showInDock = UserDefaults.standard.object(forKey: "showInDock") as? Bool ?? true
        self.enableSounds = UserDefaults.standard.object(forKey: "enableSounds") as? Bool ?? true
        self.autoDeleteAfterDays = UserDefaults.standard.object(forKey: "autoDeleteAfterDays") as? Int ?? 30
        
        let excludedAppsArray = UserDefaults.standard.array(forKey: "excludedApps") as? [String] ?? []
        self.excludedApps = Set(excludedAppsArray)
        
        if let hotkeyData = UserDefaults.standard.data(forKey: "hotkey"),
           let savedHotkey = try? JSONDecoder().decode(HotkeyConfiguration.self, from: hotkeyData) {
            self.hotkey = savedHotkey
        } else {
            self.hotkey = HotkeyConfiguration.default
        }
        
        // 应用初始配置
        configureAppActivationPolicy()
        configureGlobalHotkey()

        // 启动权限检查定时器
        startPermissionCheckTimer()
    }
    
    // MARK: - Public Methods
    
    /// 重置所有设置
    func resetToDefaults() {
        maxHistoryItems = 1000
        launchAtLogin = false
        showInDock = true
        enableSounds = true
        autoDeleteAfterDays = 30
        excludedApps = []
        hotkey = HotkeyConfiguration.default
    }
    
    /// 添加排除的应用
    func addExcludedApp(_ bundleIdentifier: String) {
        excludedApps.insert(bundleIdentifier)
    }
    
    /// 移除排除的应用
    func removeExcludedApp(_ bundleIdentifier: String) {
        excludedApps.remove(bundleIdentifier)
    }
    
    /// 检查应用是否被排除
    func isAppExcluded(_ bundleIdentifier: String) -> Bool {
        return excludedApps.contains(bundleIdentifier)
    }
    
    // MARK: - Private Methods
    
    /// 配置开机启动
    private func configureLaunchAtLogin() {
        // TODO: 实现开机启动配置
        // 可以使用 ServiceManagement 框架或 Login Items
    }
    
    /// 配置应用激活策略
    private func configureAppActivationPolicy() {
        DispatchQueue.main.async {
            if self.showInDock {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    /// 配置全局快捷键
    private func configureGlobalHotkey() {
        // 移除旧的监听器
        unregisterGlobalHotkey()

        print("开始配置全局快捷键: \(hotkey.displayString)")

        // 检查辅助功能权限
        let hasPermission = checkAccessibilityPermission()
        print("辅助功能权限状态: \(hasPermission)")

        if !hasPermission {
            print("需要辅助功能权限才能使用全局快捷键")
            requestAccessibilityPermission()
            return
        }

        // 延迟配置，确保应用完全启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.registerCarbonHotkey()
            // 同时注册NSEvent监听器作为备选方案
            self.registerNSEventMonitor()
        }
    }

    /// 注册NSEvent监听器（作为备选方案）
    private func registerNSEventMonitor() {
        print("注册NSEvent全局监听器")

        // 全局事件监听器（当应用不在前台时）
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            if self.handleKeyEvent(event) {
                print("NSEvent全局监听器触发成功")
            }
        }

        // 本地事件监听器（当应用在前台时）
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.handleKeyEvent(event) {
                print("NSEvent本地监听器触发成功")
                return nil // 阻止事件继续传播
            }
            return event
        }

        if globalEventMonitor != nil && localEventMonitor != nil {
            print("NSEvent监听器注册成功")
        } else {
            print("NSEvent监听器注册失败")
        }
    }

    /// 注册 Carbon 全局快捷键
    private func registerCarbonHotkey() {
        print("开始注册Carbon全局快捷键")

        // 转换修饰键
        var carbonModifiers: UInt32 = 0
        if hotkey.modifierFlags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if hotkey.modifierFlags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        if hotkey.modifierFlags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if hotkey.modifierFlags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }

        print("Carbon修饰键: \(carbonModifiers), 键码: \(hotkey.keyCode)")

        // 创建事件类型
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // 安装事件处理器
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                // 获取 SettingsManager 实例
                let settingsManager = Unmanaged<SettingsManager>.fromOpaque(userData!).takeUnretainedValue()

                // 处理快捷键事件
                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if result == noErr && hotKeyID.id == 1 {
                    DispatchQueue.main.async {
                        print("Carbon全局快捷键事件触发，发送通知")
                        NotificationCenter.default.post(name: .hotkeyPressed, object: nil)
                    }
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &carbonEventHandler
        )

        if status != noErr {
            print("Carbon事件处理器安装失败: \(status)")
            return
        } else {
            print("Carbon事件处理器安装成功")
        }

        // 注册快捷键
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x43424D47) // "CBMG" as OSType
        hotKeyID.id = 1

        let registerStatus = RegisterEventHotKey(
            UInt32(hotkey.keyCode),
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &carbonHotKeyRef
        )

        if registerStatus == noErr {
            print("Carbon全局快捷键注册成功: \(hotkey.displayString)")
        } else {
            print("Carbon全局快捷键注册失败，错误码: \(registerStatus)")
            // 如果Carbon注册失败，至少NSEvent监听器还能工作
        }
    }

    /// 注销全局快捷键
    private func unregisterGlobalHotkey() {
        // 移除 NSEvent 监听器
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }

        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }

        // 移除 Carbon 快捷键
        if let hotKeyRef = carbonHotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            carbonHotKeyRef = nil
        }

        // 移除事件处理器
        if let handler = carbonEventHandler {
            RemoveEventHandler(handler)
            carbonEventHandler = nil
        }
    }

    /// 检查辅助功能权限
    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 请求辅助功能权限
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let _ = AXIsProcessTrustedWithOptions(options as CFDictionary)

        // 显示权限提示
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "需要辅助功能权限"
            alert.informativeText = "为了使用全局快捷键功能，请在系统偏好设置 > 安全性与隐私 > 隐私 > 辅助功能中，允许 ClipboardManager 访问您的电脑。"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "打开系统偏好设置")
            alert.addButton(withTitle: "稍后设置")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // 打开系统偏好设置
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }

    /// 启动权限检查定时器
    private func startPermissionCheckTimer() {
        // 每3秒检查一次权限状态
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // 如果权限状态发生变化，重新配置快捷键
            let hasPermission = self.checkAccessibilityPermission()
            let hasMonitors = self.globalEventMonitor != nil && self.localEventMonitor != nil
            let hasCarbonHotkey = self.carbonHotKeyRef != nil

            if hasPermission && (!hasMonitors || !hasCarbonHotkey) {
                print("检测到辅助功能权限已授予，重新配置全局快捷键")
                print("当前状态 - NSEvent监听器: \(hasMonitors), Carbon快捷键: \(hasCarbonHotkey)")
                self.configureGlobalHotkey()
            }
        }
    }

    /// 处理按键事件
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        // 过滤掉重复事件
        guard !event.isARepeat else { return false }

        let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let expectedModifiers = NSEvent.ModifierFlags(hotkey.modifierFlags)

        // 调试信息
        if event.keyCode == hotkey.keyCode {
            print("按键匹配 - 期望修饰键: \(expectedModifiers), 实际修饰键: \(eventModifiers)")
        }

        if event.keyCode == hotkey.keyCode && eventModifiers == expectedModifiers {
            print("快捷键匹配成功: \(hotkey.displayString)")
            // 快捷键匹配，发送通知
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .hotkeyPressed, object: nil)
                print("已发送快捷键通知")
            }
            return true
        }

        return false
    }

    /// 手动触发快捷键（用于测试）
    func triggerHotkey() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .hotkeyPressed, object: nil)
            print("手动触发快捷键")
        }
    }

    /// 将字符串转换为四字符代码
    private func fourCharCodeFrom(_ string: String) -> FourCharCode {
        let utf8 = string.utf8
        var result: FourCharCode = 0
        for (i, byte) in utf8.enumerated() {
            if i >= 4 { break }
            result = result << 8 + FourCharCode(byte)
        }
        return result
    }

    deinit {
        unregisterGlobalHotkey()
        permissionCheckTimer?.invalidate()
    }
}

// MARK: - HotkeyConfiguration

/// 快捷键配置
struct HotkeyConfiguration: Codable, Equatable {
    let keyCode: UInt16
    let modifierFlags: ModifierFlags

    var displayString: String {
        var components: [String] = []

        if modifierFlags.contains(.command) {
            components.append("⌘")
        }
        if modifierFlags.contains(.option) {
            components.append("⌥")
        }
        if modifierFlags.contains(.control) {
            components.append("⌃")
        }
        if modifierFlags.contains(.shift) {
            components.append("⇧")
        }

        components.append(keyCodeToString(keyCode))

        return components.joined()
    }

    static let `default` = HotkeyConfiguration(
        keyCode: 9, // V key
        modifierFlags: [.command, .shift]
    )

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Escape"
        default: return "Key\(keyCode)"
        }
    }
}

// MARK: - ModifierFlags

struct ModifierFlags: OptionSet, Codable {
    let rawValue: Int

    static let command = ModifierFlags(rawValue: 1 << 0)
    static let shift = ModifierFlags(rawValue: 1 << 1)
    static let option = ModifierFlags(rawValue: 1 << 2)
    static let control = ModifierFlags(rawValue: 1 << 3)
}

// MARK: - NSEvent.ModifierFlags Extension

extension NSEvent.ModifierFlags {
    init(_ modifierFlags: ModifierFlags) {
        self.init()
        if modifierFlags.contains(.command) {
            self.insert(.command)
        }
        if modifierFlags.contains(.shift) {
            self.insert(.shift)
        }
        if modifierFlags.contains(.option) {
            self.insert(.option)
        }
        if modifierFlags.contains(.control) {
            self.insert(.control)
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let hotkeyPressed = Notification.Name("hotkeyPressed")
}
