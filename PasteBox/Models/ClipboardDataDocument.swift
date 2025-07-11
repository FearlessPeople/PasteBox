//
//  ClipboardDataDocument.swift
//  PasteBox
//
//  Created by zfang on 2025/7/11.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 剪贴板数据文档，用于导入导出功能
struct ClipboardDataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }
    
    var items: [ClipboardItem]
    
    init(items: [ClipboardItem] = []) {
        self.items = items
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        do {
            self.items = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(items)
        return FileWrapper(regularFileWithContents: data)
    }
}
