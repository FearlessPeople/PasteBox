//
//  ClipboardItem.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 剪贴板项目类型枚举
enum ClipboardItemType: String, CaseIterable, Codable {
    case text = "text"
    case richText = "richText"
    case image = "image"
    case file = "file"
    case url = "url"
    case color = "color"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .text:
            return "纯文本"
        case .richText:
            return "富文本"
        case .image:
            return "图片"
        case .file:
            return "文件"
        case .url:
            return "链接"
        case .color:
            return "颜色"
        case .unknown:
            return "其他"
        }
    }
    
    var iconName: String {
        switch self {
        case .text:
            return "doc.text"
        case .richText:
            return "doc.richtext"
        case .image:
            return "photo"
        case .file:
            return "doc"
        case .url:
            return "link"
        case .color:
            return "paintpalette"
        case .unknown:
            return "questionmark.circle"
        }
    }
}

/// 剪贴板项目数据模型
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ClipboardItemType
    let content: Data
    let preview: String
    let createdAt: Date
    let size: Int64
    var isFavorite: Bool
    var tags: [String]
    
    // 用于显示的属性
    var displayContent: String {
        switch type {
        case .text, .richText:
            return preview
        case .image:
            return "图片 (\(formatFileSize(size)))"
        case .file:
            return preview
        case .url:
            return preview
        case .color:
            return "颜色值: \(preview)"
        case .unknown:
            return "未知类型 (\(formatFileSize(size)))"
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    init(id: UUID = UUID(), type: ClipboardItemType, content: Data, preview: String, createdAt: Date = Date(), isFavorite: Bool = false, tags: [String] = []) {
        self.id = id
        self.type = type
        self.content = content
        self.preview = preview
        self.createdAt = createdAt
        self.size = Int64(content.count)
        self.isFavorite = isFavorite
        self.tags = tags
    }
    
    // MARK: - Helper Methods
    
    /// 获取文本内容
    func getTextContent() -> String? {
        switch type {
        case .text, .richText, .url:
            return String(data: content, encoding: .utf8)
        default:
            return nil
        }
    }
    
    /// 获取图片内容
    func getImageContent() -> NSImage? {
        guard type == .image else { return nil }
        return NSImage(data: content)
    }
    
    /// 获取文件路径
    func getFileContent() -> [URL]? {
        guard type == .file else { return nil }
        guard let string = String(data: content, encoding: .utf8) else { return nil }
        let paths = string.components(separatedBy: "\n").filter { !$0.isEmpty }
        return paths.compactMap { URL(string: $0) }
    }
    
    /// 格式化文件大小
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Equatable
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sample Data

extension ClipboardItem {
    static let sampleItems: [ClipboardItem] = [
        ClipboardItem(
            type: .text,
            content: "Hello, World!".data(using: .utf8) ?? Data(),
            preview: "Hello, World!",
            createdAt: Date().addingTimeInterval(-300)
        ),
        ClipboardItem(
            type: .url,
            content: "https://www.apple.com".data(using: .utf8) ?? Data(),
            preview: "https://www.apple.com",
            createdAt: Date().addingTimeInterval(-600),
            isFavorite: true
        ),
        ClipboardItem(
            type: .richText,
            content: "<b>Bold Text</b>".data(using: .utf8) ?? Data(),
            preview: "Bold Text",
            createdAt: Date().addingTimeInterval(-900)
        )
    ]
}
