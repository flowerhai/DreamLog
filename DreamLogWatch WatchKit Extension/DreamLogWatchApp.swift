//
//  DreamLogWatchApp.swift
//  DreamLog WatchKit Extension
//
//  Apple Watch 应用入口
//

import SwiftUI
import WatchKit

@main
struct DreamLogWatchApp: App {
    @StateObject private var dreamStore = DreamStore()
    @StateObject private var hapticFeedback = HapticFeedback.shared
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(dreamStore)
                .environmentObject(hapticFeedback)
                .onAppear {
                    // 加载梦境数据
                    dreamStore.loadDreams()
                }
        }
    }
}
