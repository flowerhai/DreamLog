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
    static var shared: DreamLogApp?
    
    let modelContainer: ModelContainer
    
    @ObservedObject private var performanceService = PerformanceOptimizationService.shared
    @ObservedObject private var accessibilityMonitor = AccessibilitySettingsMonitor.shared
    
    init() {
        Self.shared = self
        
        // 记录启动开始时间
        PerformanceOptimizationService.shared.recordLaunchStart()
        
        // 初始化 SwiftData 模型容器
        // 注意：Dream 使用 UserDefaults 持久化，SwiftData 用于高级功能
        do {
            let schema = Schema([
                // 核心模型
                DreamTimeCapsule.self,
                DreamPrediction.self,
                DreamReflection.self,
                SmartNotificationConfig.self,
                PendingNotificationInsight.self,
                
                // 推荐与洞察
                DreamRecommendation.self,
                DreamInsight.self,
                DreamSuggestion.self,
                
                // 挑战系统
                DreamChallenge.self,
                ChallengeBadge.self,
                
                // 协作解读
                DreamCollaborationSession.self,
                CollaborationParticipant.self,
                DreamInterpretation.self,
                CollaborationComment.self,
                
                // 备份与导出
                BackupSchedule.self,
                DreamExportTemplate.self,
                
                // 社区与社交
                SharedDream.self,
                CommunityComment.self,
                CommunityLike.self,
                
                // 灵感与创意
                DailyInspiration.self,
                ArtShareTemplate.self,
                
                // 冥想与音乐
                DreamMeditationSession.self,
                DreamPlaylist.self,
                
                // 位置与地图
                DreamLocation.self,
                
                // 伴侣系统
                CompanionSession.self,
                
                // 年度回顾
                DreamYearInReview.self,
                
                // 社交互动
                SocialActivity.self,
                
                // AI 分析
                DreamAnalysis.self
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
    @ObservedObject private var smartNotificationService = DreamSmartNotificationService.shared
    @ObservedObject private var hapticService = DreamHapticFeedback.shared
    @ObservedObject private var communityService = CommunityService.shared
    
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
                .environmentObject(smartNotificationService)
                .environmentObject(hapticService)
                .environmentObject(performanceService)
                .environmentObject(accessibilityMonitor)
                .environmentObject(communityService)
                .modelContainer(modelContainer)
                .onAppear {
                    // 启动完成
                    PerformanceOptimizationService.shared.recordLaunchEnd()
                    // 开始性能监控
                    PerformanceOptimizationService.shared.startMemoryMonitoring()
                    PerformanceOptimizationService.shared.startFrameRateMonitoring()
                    PerformanceOptimizationService.shared.registerForMemoryWarnings()
                }
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
                    .environmentObject(communityService)
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
        
        // 初始化智能通知服务
        if let modelContext = SharedModelContainer.main?.mainContext {
            smartNotificationService.initialize(modelContext: modelContext)
        }
        smartNotificationService.checkAuthorization()
        
        // 初始化挑战系统
        challengeService.setupDreamListener()
        
        // 初始化触觉反馈
        hapticService.setEnabled(true)
        hapticService.setIntensity(1.0)
    }
}
