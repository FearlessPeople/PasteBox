//
//  ClipboardMonitor.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation
import AppKit
import UniformTypeIdentifiers
import Combine

/// 剪贴板监听服务
class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()
    
    @Published var items: [ClipboardItem] = []
    @Published var isMonitoring = false
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private let maxItems = 1000 // 最大保存项目数
    private let maxItemSize: Int64 = 50 * 1024 * 1024 // 50MB 最大单项大小
    private var processingQueue = DispatchQueue(label: "clipboard.processing", qos: .utility)
    
    private init() {
        lastChangeCount = pasteboard.changeCount
    }
    
    // MARK: - Public Methods
    
    /// 开始监听剪贴板
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount
        
        // 每0.5秒检查一次剪贴板变化
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
        
        print("剪贴板监听已启动")
    }
    
    /// 停止监听剪贴板
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        
        print("剪贴板监听已停止")
    }
    
    /// 添加项目到剪贴板历史
    func addItem(_ item: ClipboardItem) {
        // 检查项目大小
        if item.size > maxItemSize {
            print("项目过大，跳过保存: \(item.size) bytes")
            return
        }

        processingQueue.async {
            // 检查是否已存在相同内容
            let isDuplicate = self.items.contains { existingItem in
                existingItem.content == item.content && existingItem.type == item.type
            }

            if !isDuplicate {
                DispatchQueue.main.async {
                    self.items.insert(item, at: 0)

                    // 限制最大项目数
                    if self.items.count > self.maxItems {
                        self.items = Array(self.items.prefix(self.maxItems))
                    }

                    // 异步保存到持久化存储
                    self.processingQueue.async {
                        self.saveItems()
                    }
                }
            }
        }
    }
    
    /// 删除指定项目
    func deleteItem(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            self.items.removeAll { $0.id == item.id }
            self.saveItems()
        }
    }
    
    /// 清空所有历史
    func clearAll() {
        DispatchQueue.main.async {
            self.items.removeAll()
            self.saveItems()
        }
    }
    
    /// 切换项目收藏状态
    func toggleFavorite(_ item: ClipboardItem) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                self.items[index] = ClipboardItem(
                    id: item.id,
                    type: item.type,
                    content: item.content,
                    preview: item.preview,
                    createdAt: item.createdAt,
                    isFavorite: !item.isFavorite,
                    tags: item.tags
                )
                self.saveItems()
            }
        }
    }

    /// 复制项目到剪贴板
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.type {
        case .text, .url:
            if let text = item.getTextContent() {
                pasteboard.setString(text, forType: .string)
            }
            
        case .richText:
            if let text = item.getTextContent() {
                pasteboard.setString(text, forType: .rtf)
            }
            
        case .image:
            if let image = item.getImageContent() {
                pasteboard.writeObjects([image])
            }
            
        case .file:
            if let urls = item.getFileContent() {
                pasteboard.writeObjects(urls as [NSURL])
            }
            
        default:
            // 对于其他类型，尝试作为通用数据写入
            pasteboard.setData(item.content, forType: NSPasteboard.PasteboardType(rawValue: "public.data"))
        }
        
        // 更新changeCount以避免重复检测
        lastChangeCount = pasteboard.changeCount
    }
    
    // MARK: - Private Methods
    
    /// 检查剪贴板变化
    private func checkClipboardChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        processClipboardContent()
    }
    
    /// 处理剪贴板内容
    private func processClipboardContent() {
        guard let types = pasteboard.types else { return }
        
        // 按优先级处理不同类型的内容
        if types.contains(.fileURL) {
            processFileContent()
        } else if types.contains(.tiff) || types.contains(.png) {
            processImageContent()
        } else if types.contains(.rtf) {
            processRichTextContent()
        } else if types.contains(.string) {
            processTextContent()
        } else {
            processUnknownContent()
        }
    }
    
    /// 处理文本内容
    private func processTextContent() {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        
        let type: ClipboardItemType = text.isValidURL ? .url : .text
        let preview = String(text.prefix(100))
        
        let item = ClipboardItem(
            type: type,
            content: text.data(using: .utf8) ?? Data(),
            preview: preview
        )
        
        addItem(item)
    }
    
    /// 处理富文本内容
    private func processRichTextContent() {
        guard let rtfData = pasteboard.data(forType: .rtf) else { return }
        
        let preview: String
        if let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            preview = String(attributedString.string.prefix(100))
        } else {
            preview = "富文本内容"
        }
        
        let item = ClipboardItem(
            type: .richText,
            content: rtfData,
            preview: preview
        )
        
        addItem(item)
    }
    
    /// 处理图片内容
    private func processImageContent() {
        guard let image = NSImage(pasteboard: pasteboard) else { return }

        // 检查图片大小，如果太大则压缩
        let originalSize = image.size
        var processedImage = image

        // 如果图片尺寸过大，进行压缩
        let maxDimension: CGFloat = 2048
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            let scale = min(maxDimension / originalSize.width, maxDimension / originalSize.height)
            let newSize = NSSize(width: originalSize.width * scale, height: originalSize.height * scale)

            processedImage = NSImage(size: newSize)
            processedImage.lockFocus()
            image.draw(in: NSRect(origin: .zero, size: newSize))
            processedImage.unlockFocus()
        }

        guard let imageData = processedImage.tiffRepresentation else { return }

        // 检查数据大小
        if imageData.count > maxItemSize {
            print("图片数据过大，跳过保存: \(imageData.count) bytes")
            return
        }

        let preview = "图片 \(Int(originalSize.width))×\(Int(originalSize.height))"

        let item = ClipboardItem(
            type: .image,
            content: imageData,
            preview: preview
        )

        addItem(item)
    }
    
    /// 处理文件内容
    private func processFileContent() {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else { return }
        
        let pathStrings = urls.map { $0.path }.joined(separator: "\n")
        let preview = urls.count == 1 ? urls[0].lastPathComponent : "\(urls.count) 个文件"
        
        let item = ClipboardItem(
            type: .file,
            content: pathStrings.data(using: .utf8) ?? Data(),
            preview: preview
        )
        
        addItem(item)
    }
    
    /// 处理未知类型内容
    private func processUnknownContent() {
        guard let types = pasteboard.types, let firstType = types.first else { return }
        guard let data = pasteboard.data(forType: firstType) else { return }
        
        let preview = "未知类型: \(firstType.rawValue)"
        
        let item = ClipboardItem(
            type: .unknown,
            content: data,
            preview: preview
        )
        
        addItem(item)
    }
    
    /// 保存项目到持久化存储
    private func saveItems() {
        PersistenceManager.shared.saveItems(items)
    }

    /// 从持久化存储加载项目
    func loadItems() {
        processingQueue.async {
            let loadedItems = PersistenceManager.shared.loadItems()
            DispatchQueue.main.async {
                self.items = loadedItems
                self.performMemoryCleanupIfNeeded()
            }
        }
    }

    /// 内存清理
    private func performMemoryCleanupIfNeeded() {
        let totalMemoryUsage = items.reduce(0) { $0 + $1.size }
        let maxMemoryUsage: Int64 = 100 * 1024 * 1024 // 100MB

        if totalMemoryUsage > maxMemoryUsage {
            print("内存使用过高，开始清理: \(totalMemoryUsage) bytes")

            // 移除最旧的非收藏项目
            var cleanedItems: [ClipboardItem] = []
            var currentMemoryUsage: Int64 = 0

            // 首先保留收藏项目
            for item in items {
                if item.isFavorite {
                    cleanedItems.append(item)
                    currentMemoryUsage += item.size
                }
            }

            // 然后按时间倒序添加非收藏项目，直到达到内存限制
            let nonFavoriteItems = items.filter { !$0.isFavorite }.sorted { $0.createdAt > $1.createdAt }
            for item in nonFavoriteItems {
                if currentMemoryUsage + item.size <= maxMemoryUsage {
                    cleanedItems.append(item)
                    currentMemoryUsage += item.size
                } else {
                    break
                }
            }

            items = cleanedItems.sorted { $0.createdAt > $1.createdAt }
            saveItems()

            print("内存清理完成，保留 \(items.count) 个项目，内存使用: \(currentMemoryUsage) bytes")
        }
    }

    /// 定期清理过期项目
    func performScheduledCleanup() {
        let settings = SettingsManager.shared
        PersistenceManager.shared.cleanupExpiredItems(olderThan: settings.autoDeleteAfterDays)
        loadItems()
    }

    /// 公开内存清理方法
    func performMemoryCleanup() {
        performMemoryCleanupIfNeeded()
    }
}

// MARK: - String Extension

private extension String {
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && (url.scheme == "http" || url.scheme == "https" || url.scheme == "ftp")
    }
}
