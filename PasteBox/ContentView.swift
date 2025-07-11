//
//  ContentView.swift
//  PasteBox
//
//  Created by zfang on 2025/7/10.
//

import SwiftUI

// 这个文件现在作为主要的内容视图，重定向到历史面板
struct ContentView: View {
    var body: some View {
        ClipboardHistoryView()
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipboardMonitor.shared)
        .environmentObject(SettingsManager.shared)
}
