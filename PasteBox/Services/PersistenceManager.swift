//
//  PersistenceManager.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation

/// 持久化存储管理器
class PersistenceManager {
    static let shared = PersistenceManager()
    
    private let documentsDirectory: URL
    private let dataFileName = "clipboard_history.json"
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB
    
    private init() {
        documentsDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipboardManager")
        
        // 创建应用支持目录
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }
    
    private var dataFileURL: URL {
        documentsDirectory.appendingPathComponent(dataFileName)
    }
    
    // MARK: - Public Methods
    
    /// 保存剪贴板项目
    func saveItems(_ items: [ClipboardItem]) {
        do {
            // 限制保存的项目数量以控制文件大小
            let itemsToSave = Array(items.prefix(1000))
            
            let data = try JSONEncoder().encode(itemsToSave)
            
            // 检查文件大小
            if data.count > maxFileSize {
                print("警告: 数据文件过大，将只保存最近的项目")
                let reducedItems = Array(itemsToSave.prefix(500))
                let reducedData = try JSONEncoder().encode(reducedItems)
                try reducedData.write(to: dataFileURL)
            } else {
                try data.write(to: dataFileURL)
            }
            
            print("已保存 \(itemsToSave.count) 个剪贴板项目")
        } catch {
            print("保存剪贴板历史失败: \(error)")
        }
    }
    
    /// 加载剪贴板项目
    func loadItems() -> [ClipboardItem] {
        do {
            guard FileManager.default.fileExists(atPath: dataFileURL.path) else {
                print("历史文件不存在，返回空数组")
                return []
            }
            
            let data = try Data(contentsOf: dataFileURL)
            let items = try JSONDecoder().decode([ClipboardItem].self, from: data)
            
            print("已加载 \(items.count) 个剪贴板项目")
            return items
        } catch {
            print("加载剪贴板历史失败: \(error)")
            return []
        }
    }
    
    /// 清空所有数据
    func clearAllData() {
        do {
            if FileManager.default.fileExists(atPath: dataFileURL.path) {
                try FileManager.default.removeItem(at: dataFileURL)
                print("已清空所有历史数据")
            }
        } catch {
            print("清空数据失败: \(error)")
        }
    }
    
    /// 导出数据
    func exportData(to url: URL) throws {
        guard FileManager.default.fileExists(atPath: dataFileURL.path) else {
            throw PersistenceError.noDataToExport
        }
        
        try FileManager.default.copyItem(at: dataFileURL, to: url)
    }
    
    /// 导入数据
    func importData(from url: URL) throws -> [ClipboardItem] {
        let data = try Data(contentsOf: url)
        let items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        return items
    }
    
    /// 获取数据文件信息
    func getDataFileInfo() -> (size: Int64, itemCount: Int, lastModified: Date?) {
        guard FileManager.default.fileExists(atPath: dataFileURL.path) else {
            return (0, 0, nil)
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: dataFileURL.path)
            let size = attributes[.size] as? Int64 ?? 0
            let lastModified = attributes[.modificationDate] as? Date
            
            let items = loadItems()
            
            return (size, items.count, lastModified)
        } catch {
            print("获取文件信息失败: \(error)")
            return (0, 0, nil)
        }
    }
    
    /// 清理过期数据
    func cleanupExpiredItems(olderThan days: Int) {
        let items = loadItems()
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let filteredItems = items.filter { $0.createdAt > cutoffDate }

        if filteredItems.count < items.count {
            saveItems(filteredItems)
            print("已清理 \(items.count - filteredItems.count) 个过期项目")
        }
    }

    /// 按类型清理数据
    func cleanupItemsByType(_ types: [ClipboardItemType]) {
        let items = loadItems()
        let filteredItems = items.filter { !types.contains($0.type) }

        if filteredItems.count < items.count {
            saveItems(filteredItems)
            print("已清理 \(items.count - filteredItems.count) 个指定类型的项目")
        }
    }

    /// 按大小清理数据（移除大文件）
    func cleanupLargeItems(largerThan sizeInBytes: Int64) {
        let items = loadItems()
        let filteredItems = items.filter { $0.size <= sizeInBytes }

        if filteredItems.count < items.count {
            saveItems(filteredItems)
            print("已清理 \(items.count - filteredItems.count) 个大文件项目")
        }
    }
    
    /// 优化存储（压缩和清理）
    func optimizeStorage() {
        let items = loadItems()
        
        // 移除重复项目
        var uniqueItems: [ClipboardItem] = []
        var seenContent: Set<Data> = []
        
        for item in items {
            if !seenContent.contains(item.content) {
                uniqueItems.append(item)
                seenContent.insert(item.content)
            }
        }
        
        if uniqueItems.count < items.count {
            saveItems(uniqueItems)
            print("存储优化完成，移除了 \(items.count - uniqueItems.count) 个重复项目")
        }
    }
}

// MARK: - Errors

enum PersistenceError: LocalizedError {
    case noDataToExport
    case invalidDataFormat
    case fileAccessDenied
    
    var errorDescription: String? {
        switch self {
        case .noDataToExport:
            return "没有数据可以导出"
        case .invalidDataFormat:
            return "数据格式无效"
        case .fileAccessDenied:
            return "文件访问被拒绝"
        }
    }
}

// MARK: - File Size Formatter

extension PersistenceManager {
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
