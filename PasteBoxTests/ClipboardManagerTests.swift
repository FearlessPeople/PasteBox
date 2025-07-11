//
//  ClipboardManagerTests.swift
//  ClipboardManagerTests
//
//  Created by zfang on 2025/7/10.
//

import Testing
@testable import ClipboardManager

struct ClipboardManagerTests {

    @Test func testClipboardItemCreation() async throws {
        let content = "Test content".data(using: .utf8) ?? Data()
        let item = ClipboardItem(
            type: .text,
            content: content,
            preview: "Test content"
        )

        #expect(item.type == .text)
        #expect(item.preview == "Test content")
        #expect(item.size == Int64(content.count))
        #expect(item.isFavorite == false)
        #expect(item.tags.isEmpty)
    }

    @Test func testClipboardItemTextContent() async throws {
        let testText = "Hello, World!"
        let content = testText.data(using: .utf8) ?? Data()
        let item = ClipboardItem(
            type: .text,
            content: content,
            preview: testText
        )

        #expect(item.getTextContent() == testText)
    }

    @Test func testClipboardItemDisplayContent() async throws {
        let item = ClipboardItem(
            type: .image,
            content: Data(count: 1024),
            preview: "Test Image"
        )

        #expect(item.displayContent.contains("图片"))
    }

    @Test func testClipboardMonitorAddItem() async throws {
        let monitor = ClipboardMonitor.shared
        monitor.clearAll()

        let testItem = ClipboardItem(
            type: .text,
            content: "Test content".data(using: .utf8) ?? Data(),
            preview: "Test content"
        )

        monitor.addItem(testItem)

        #expect(monitor.items.count == 1)
        #expect(monitor.items.first?.preview == "Test content")
    }

    @Test func testClipboardMonitorDeleteItem() async throws {
        let monitor = ClipboardMonitor.shared
        monitor.clearAll()

        let testItem = ClipboardItem(
            type: .text,
            content: "Test content".data(using: .utf8) ?? Data(),
            preview: "Test content"
        )
        monitor.addItem(testItem)

        monitor.deleteItem(testItem)

        #expect(monitor.items.count == 0)
    }

    @Test func testClipboardMonitorClearAll() async throws {
        let monitor = ClipboardMonitor.shared
        monitor.clearAll()

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
        monitor.addItem(testItem1)
        monitor.addItem(testItem2)

        monitor.clearAll()

        #expect(monitor.items.count == 0)
    }

    @Test func testDuplicateItemsNotAdded() async throws {
        let monitor = ClipboardMonitor.shared
        monitor.clearAll()

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

        monitor.addItem(testItem1)
        monitor.addItem(testItem2)

        #expect(monitor.items.count == 1)
    }

    @Test func testSettingsDefaults() async throws {
        let settings = SettingsManager.shared

        #expect(settings.maxHistoryItems == 1000)
        #expect(settings.launchAtLogin == false)
        #expect(settings.showInDock == true)
        #expect(settings.enableSounds == true)
        #expect(settings.autoDeleteAfterDays == 30)
        #expect(settings.excludedApps.isEmpty)
    }

    @Test func testExcludedApps() async throws {
        let settings = SettingsManager.shared
        let testBundleId = "com.test.app"

        settings.addExcludedApp(testBundleId)
        #expect(settings.isAppExcluded(testBundleId))

        settings.removeExcludedApp(testBundleId)
        #expect(settings.isAppExcluded(testBundleId) == false)
    }

}
