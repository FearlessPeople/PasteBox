//
//  PerformanceMonitor.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation
import os.log

/// 性能监控器
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()
    
    @Published var memoryUsage: Int64 = 0
    @Published var itemCount: Int = 0
    @Published var averageItemSize: Int64 = 0
    
    private let logger = Logger(subsystem: "ClipboardManager", category: "Performance")
    private var timer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// 开始性能监控
    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        updateMetrics()
    }
    
    /// 停止性能监控
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// 记录操作性能
    func measureTime<T>(operation: String, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.info("操作 '\(operation)' 耗时: \(String(format: "%.3f", timeElapsed))秒")
        
        if timeElapsed > 1.0 {
            logger.warning("操作 '\(operation)' 耗时过长: \(String(format: "%.3f", timeElapsed))秒")
        }
        
        return result
    }
    
    /// 记录异步操作性能
    func measureAsyncTime<T>(operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        logger.info("异步操作 '\(operation)' 耗时: \(String(format: "%.3f", timeElapsed))秒")
        
        return result
    }
    
    /// 记录内存使用情况
    func logMemoryUsage() {
        let memoryInfo = getMemoryInfo()
        logger.info("内存使用情况 - 物理内存: \(self.formatBytes(memoryInfo.physicalMemory)), 虚拟内存: \(self.formatBytes(memoryInfo.virtualMemory))")
    }
    
    /// 获取应用性能报告
    func getPerformanceReport() -> PerformanceReport {
        let memoryInfo = getMemoryInfo()
        let clipboardItems = ClipboardMonitor.shared.items
        
        return PerformanceReport(
            memoryUsage: memoryInfo.physicalMemory,
            virtualMemory: memoryInfo.virtualMemory,
            itemCount: clipboardItems.count,
            totalDataSize: clipboardItems.reduce(0) { $0 + $1.size },
            averageItemSize: clipboardItems.isEmpty ? 0 : clipboardItems.reduce(0) { $0 + $1.size } / Int64(clipboardItems.count),
            largestItemSize: clipboardItems.max(by: { $0.size < $1.size })?.size ?? 0,
            favoriteItemsCount: clipboardItems.filter { $0.isFavorite }.count
        )
    }
    
    // MARK: - Private Methods
    
    /// 更新性能指标
    private func updateMetrics() {
        let clipboardItems = ClipboardMonitor.shared.items
        
        DispatchQueue.main.async {
            self.itemCount = clipboardItems.count
            self.memoryUsage = clipboardItems.reduce(0) { $0 + $1.size }
            self.averageItemSize = clipboardItems.isEmpty ? 0 : self.memoryUsage / Int64(clipboardItems.count)
        }
        
        // 检查内存使用是否过高
        if self.memoryUsage > 200 * 1024 * 1024 { // 200MB
            logger.warning("内存使用过高: \(self.formatBytes(self.memoryUsage))")
        }

        // 检查项目数量是否过多
        if self.itemCount > 5000 {
            logger.warning("剪贴板项目数量过多: \(self.itemCount)")
        }
    }
    
    /// 获取内存信息
    private func getMemoryInfo() -> (physicalMemory: Int64, virtualMemory: Int64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return (Int64(info.resident_size), Int64(info.virtual_size))
        } else {
            return (0, 0)
        }
    }
    
    /// 格式化字节数
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Performance Report

struct PerformanceReport {
    let memoryUsage: Int64
    let virtualMemory: Int64
    let itemCount: Int
    let totalDataSize: Int64
    let averageItemSize: Int64
    let largestItemSize: Int64
    let favoriteItemsCount: Int
    
    var formattedMemoryUsage: String {
        ByteCountFormatter().string(fromByteCount: memoryUsage)
    }
    
    var formattedTotalDataSize: String {
        ByteCountFormatter().string(fromByteCount: totalDataSize)
    }
    
    var formattedAverageItemSize: String {
        ByteCountFormatter().string(fromByteCount: averageItemSize)
    }
    
    var formattedLargestItemSize: String {
        ByteCountFormatter().string(fromByteCount: largestItemSize)
    }
}

// MARK: - Performance Extensions

extension ClipboardMonitor {
    /// 带性能监控的添加项目
    func addItemWithPerformanceMonitoring(_ item: ClipboardItem) {
        PerformanceMonitor.shared.measureTime(operation: "添加剪贴板项目") {
            self.addItem(item)
        }
    }
    
    /// 带性能监控的保存项目
    func saveItemsWithPerformanceMonitoring() {
        PerformanceMonitor.shared.measureTime(operation: "保存剪贴板项目") {
            PersistenceManager.shared.saveItems(self.items)
        }
    }
}

extension PersistenceManager {
    /// 带性能监控的加载项目
    func loadItemsWithPerformanceMonitoring() -> [ClipboardItem] {
        return PerformanceMonitor.shared.measureTime(operation: "加载剪贴板项目") {
            return self.loadItems()
        }
    }
    
    /// 带性能监控的优化存储
    func optimizeStorageWithPerformanceMonitoring() {
        PerformanceMonitor.shared.measureTime(operation: "优化存储") {
            self.optimizeStorage()
        }
    }
}
