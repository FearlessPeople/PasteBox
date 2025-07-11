//
//  ClipboardMonitorTests.swift
//  ClipboardManagerTests
//
//  Created by zfang on 2025/7/11.
//

import XCTest
@testable import ClipboardManager

final class ClipboardMonitorTests: XCTestCase {
    var clipboardMonitor: ClipboardMonitor!
    
    override func setUpWithError() throws {
        clipboardMonitor = ClipboardMonitor.shared
    }
    
    override func tearDownWithError() throws {
        clipboardMonitor.stopMonitoring()
        clipboardMonitor.clearAll()
    }
    
    func testAddItem() throws {
        // Given
        let testItem = ClipboardItem(
            type: .text,
            content: "Test content".data(using: .utf8) ?? Data(),
            preview: "Test content"
        )
        
        // When
        clipboardMonitor.addItem(testItem)
        
        // Then
        XCTAssertEqual(clipboardMonitor.items.count, 1)
        XCTAssertEqual(clipboardMonitor.items.first?.preview, "Test content")
    }
    
    func testDeleteItem() throws {
        // Given
        let testItem = ClipboardItem(
            type: .text,
            content: "Test content".data(using: .utf8) ?? Data(),
            preview: "Test content"
        )
        clipboardMonitor.addItem(testItem)
        
        // When
        clipboardMonitor.deleteItem(testItem)
        
        // Then
        XCTAssertEqual(clipboardMonitor.items.count, 0)
    }
    
    func testClearAll() throws {
        // Given
        let testItem1 = ClipboardItem(
            type: .text,
            content: "Test content 1".data(using: .utf8) ?? Data(),
            preview: "Test content 1"
        )
        let testItem2 = ClipboardItem(
            type: .text,
            content: "Test content 2".data(using: .utf8) ?? Data(),
            preview: "Test content 2"
        )
        clipboardMonitor.addItem(testItem1)
        clipboardMonitor.addItem(testItem2)
        
        // When
        clipboardMonitor.clearAll()
        
        // Then
        XCTAssertEqual(clipboardMonitor.items.count, 0)
    }
    
    func testDuplicateItemsNotAdded() throws {
        // Given
        let content = "Duplicate content".data(using: .utf8) ?? Data()
        let testItem1 = ClipboardItem(
            type: .text,
            content: content,
            preview: "Duplicate content"
        )
        let testItem2 = ClipboardItem(
            type: .text,
            content: content,
            preview: "Duplicate content"
        )
        
        // When
        clipboardMonitor.addItem(testItem1)
        clipboardMonitor.addItem(testItem2)
        
        // Then
        XCTAssertEqual(clipboardMonitor.items.count, 1)
    }
    
    func testMaxItemsLimit() throws {
        // Given
        let maxItems = 1000
        
        // When
        for i in 0..<(maxItems + 10) {
            let testItem = ClipboardItem(
                type: .text,
                content: "Test content \(i)".data(using: .utf8) ?? Data(),
                preview: "Test content \(i)"
            )
            clipboardMonitor.addItem(testItem)
        }
        
        // Then
        XCTAssertEqual(clipboardMonitor.items.count, maxItems)
    }
    
    func testMonitoringStartStop() throws {
        // Given
        XCTAssertFalse(clipboardMonitor.isMonitoring)
        
        // When
        clipboardMonitor.startMonitoring()
        
        // Then
        XCTAssertTrue(clipboardMonitor.isMonitoring)
        
        // When
        clipboardMonitor.stopMonitoring()
        
        // Then
        XCTAssertFalse(clipboardMonitor.isMonitoring)
    }
}
