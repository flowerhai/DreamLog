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
        // 注意：Dream 使用 UserDefaults 持久化，只有 DreamTimeCapsule 和 DreamPrediction 使用 SwiftData
        do {
            let schema = Schema([
                DreamTimeCapsule.self,
                DreamPrediction.self
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
        
        // 初始化共享模型容器
        SharedModelContainer.initialize(modelContainer)
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
    @StateObject private var hapticService = DreamHapticFeedback.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dreamStore)
                .environmentObject(speechService)
                .environmentObject(aiService)
                .environmentObject(notificationService)
                .environmentObject(cloudSyncService)
                .environmentObject(healthKitService)
                .environmentObject(trendService)
                .environmentObject(timelineService)
                .environmentObject(challengeService)
                .environmentObject(hapticService)
                .modelContainer(modelContainer)
        }
    }
}

// MARK: - Root View with Onboarding

struct RootView: View {
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var speechService: SpeechService
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var notificationService: NotificationService
    @EnvironmentObject var cloudSyncService: CloudSyncService
    @EnvironmentObject var healthKitService: HealthKitService
    @EnvironmentObject var trendService: DreamTrendService
    @EnvironmentObject var timelineService: DreamTimelineService
    @EnvironmentObject var challengeService: DreamChallengeService
    @EnvironmentObject var hapticService: DreamHapticFeedback
    @ObservedObject private var smartReminderService = SmartReminderService.shared
    
    @State private var showOnboarding = false
    @State private var appInitialized = false
    
    var body: some View {
        Group {
            if showOnboarding {
                DreamOnboardingView()
                    .onDisappear {
                        // 引导完成后显示主界面
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    }
            } else {
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
                    .environmentObject(hapticService)
            }
        }
        .onAppear {
            // 检查是否需要显示引导
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            let isFirstLaunch = UserDefaults.standard.object(forKey: "hasCompletedOnboarding") == nil
            
            if isFirstLaunch {
                // 首次启动，显示引导
                withAnimation(.easeInOut(duration: 0.3)) {
                    showOnboarding = true
                }
            }
            
            // 初始化服务
            initializeServices()
            
            appInitialized = true
        }
    }
    
    private func initializeServices() {
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
        
        // 初始化触觉反馈
        hapticService.setEnabled(true)
        hapticService.setIntensity(1.0)
    }
}
