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
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var cloudSyncService = CloudSyncService.shared
    @ObservedObject private var healthKitService = HealthKitService.shared
    @ObservedObject private var trendService = DreamTrendService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dreamStore)
                .environmentObject(speechService)
                .environmentObject(aiService)
                .environmentObject(notificationService)
                .environmentObject(cloudSyncService)
                .environmentObject(healthKitService)
                .environmentObject(trendService)
                .onAppear {
                    // 初始化通知服务
                    notificationService.checkAuthorization()
                    notificationService.checkPendingNotifications()
                    
                    // 初始化云同步
                    if cloudSyncService.isCloudEnabled {
                        dreamStore.triggerCloudSync()
                    }
                    
                    // 检查 HealthKit 授权状态
                    healthKitService.checkAuthorizationStatus()
                }
        }
    }
}
