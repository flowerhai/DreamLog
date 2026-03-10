//
//  DreamLogApp.swift
//  DreamLog
//
//  App 入口
//

import SwiftUI

@main
struct DreamLogApp: App {
    @ObservedObject private var dreamStore = DreamStore.shared
    @StateObject private var speechService = SpeechService()
    @StateObject private var aiService = AIService()
    @ObservedObject private var notificationService = NotificationService.shared
    @ObservedObject private var cloudSyncService = CloudSyncService.shared
    @ObservedObject private var healthKitService = HealthKitService.shared
    @ObservedObject private var trendService = DreamTrendService.shared
    @ObservedObject private var timelineService = DreamTimelineService.shared
    @ObservedObject private var smartReminderService = SmartReminderService.shared
    @ObservedObject private var challengeService = DreamChallengeService.shared
    
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
                .environmentObject(timelineService)
                .environmentObject(challengeService)
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
                    
                    // 初始化智能提醒服务
                    smartReminderService.checkAuthorization()
                    smartReminderService.updateAnalysis(from: dreamStore)
                    
                    // 初始化挑战系统
                    challengeService.setupDreamListener()
                }
        }
    }
}
