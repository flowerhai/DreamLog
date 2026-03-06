//
//  DreamLogApp.swift
//  DreamLog
//
//  App 入口
//

import SwiftUI

@main
struct DreamLogApp: App {
    @StateObject private var dreamStore = DreamStore()
    @StateObject private var speechService = SpeechService()
    @StateObject private var aiService = AIService()
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var cloudSyncService = CloudSyncService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dreamStore)
                .environmentObject(speechService)
                .environmentObject(aiService)
                .environmentObject(notificationService)
                .environmentObject(cloudSyncService)
                .onAppear {
                    // 初始化通知服务
                    notificationService.checkAuthorization()
                    notificationService.checkPendingNotifications()
                    
                    // 初始化云同步
                    if cloudSyncService.isCloudEnabled {
                        dreamStore.triggerCloudSync()
                    }
                }
        }
    }
}
