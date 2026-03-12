//
//  DreamLogApp.swift
//  DreamLog
//
//  App 入口
//

import SwiftUI
import SwiftData

@main
struct DreamLogApp: App {
    static var shared: DreamLogApp!
    
    let modelContainer: ModelContainer
    
    init() {
        Self.shared = self
        
        // 初始化 SwiftData 模型容器
        // 注意：Dream 使用 UserDefaults 持久化，只有 DreamTimeCapsule 使用 SwiftData
        do {
            let schema = Schema([
                DreamTimeCapsule.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法初始化模型容器：\(error)")
        }
    }
    
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
                .modelContainer(modelContainer)
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
