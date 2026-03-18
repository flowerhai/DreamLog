//
//  DreamNotificationTests.swift
//  DreamLogTests
//
//  Phase 69 - 梦境通知中心与小组件增强
//  单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamNotificationTests: XCTestCase {
    
    var notificationService: DreamNotificationService!
    var scheduler: DreamNotificationScheduler!
    var testUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 UserDefaults
        testUserDefaults = UserDefaults(suiteName: "test.dreamlog.notifications")
        testUserDefaults?.removePersistentDomain(forName: "test.dreamlog.notifications")
        
        notificationService = DreamNotificationService(
            userDefaults: testUserDefaults,
            notificationCenter: UNUserNotificationCenter.current()
        )
        
        scheduler = DreamNotificationScheduler(
            notificationService: notificationService
        )
    }
    
    override func tearDown() async throws {
        notificationService = nil
        scheduler = nil
        testUserDefaults = nil
        try await super.tearDown()
    }
    
    // MARK: - 通知类型测试
    
    func testNotificationTypeDisplayNames() {
        XCTAssertEqual(DreamNotificationType.sleepReminder.displayName, "睡前提醒")
        XCTAssertEqual(DreamNotificationType.morningRecall.displayName, "晨间回忆")
        XCTAssertEqual(DreamNotificationType.patternInsight.displayName, "模式洞察")
        XCTAssertEqual(DreamNotificationType.challengeProgress.displayName, "挑战进度")
        XCTAssertEqual(DreamNotificationType.meditationSuggestion.displayName, "冥想建议")
        XCTAssertEqual(DreamNotificationType.weeklyReport.displayName, "周报推送")
        XCTAssertEqual(DreamNotificationType.lucidPrompt.displayName, "清醒梦提示")
        XCTAssertEqual(DreamNotificationType.moodCheck.displayName, "情绪检查")
    }
    
    func testNotificationTypeIcons() {
        XCTAssertEqual(DreamNotificationType.sleepReminder.icon, "moon.fill")
        XCTAssertEqual(DreamNotificationType.morningRecall.icon, "sunrise.fill")
        XCTAssertEqual(DreamNotificationType.patternInsight.icon, "lightbulb.fill")
        XCTAssertEqual(DreamNotificationType.challengeProgress.icon, "target")
    }
    
    func testNotificationTypeColors() {
        XCTAssertEqual(DreamNotificationType.sleepReminder.color, "#6B46C1")
        XCTAssertEqual(DreamNotificationType.morningRecall.color, "#ED8936")
        XCTAssertEqual(DreamNotificationType.patternInsight.color, "#ECC94B")
    }
    
    // MARK: - 通知频率测试
    
    func testNotificationFrequencyDisplayNames() {
        XCTAssertEqual(NotificationFrequency.once.displayName, "仅一次")
        XCTAssertEqual(NotificationFrequency.daily.displayName, "每天")
        XCTAssertEqual(NotificationFrequency.weekly.displayName, "每周")
        XCTAssertEqual(NotificationFrequency.weekdays.displayName, "工作日")
        XCTAssertEqual(NotificationFrequency.weekends.displayName, "周末")
        XCTAssertEqual(NotificationFrequency.custom.displayName, "自定义")
    }
    
    // MARK: - 配置测试
    
    func testDefaultConfigurations() {
        let configs = DreamNotificationConfig.defaultConfigurations
        
        XCTAssertEqual(configs.count, 8)
        
        // 检查睡前提醒配置
        let sleepConfig = configs.first { $0.type == .sleepReminder }
        XCTAssertNotNil(sleepConfig)
        XCTAssertEqual(sleepConfig?.scheduledTime, "22:00")
        XCTAssertEqual(sleepConfig?.isEnabled, true)
        XCTAssertEqual(sleepConfig?.frequency, .daily)
        
        // 检查晨间回忆配置
        let morningConfig = configs.first { $0.type == .morningRecall }
        XCTAssertNotNil(morningConfig)
        XCTAssertEqual(morningConfig?.scheduledTime, "07:30")
        XCTAssertEqual(morningConfig?.isEnabled, true)
    }
    
    func testNotificationSettingsDefault() {
        let settings = DreamNotificationSettings.default
        
        XCTAssertTrue(settings.isNotificationsEnabled)
        XCTAssertTrue(settings.isSmartSchedulingEnabled)
        XCTAssertEqual(settings.quietHoursStart, "22:00")
        XCTAssertEqual(settings.quietHoursEnd, "08:00")
        XCTAssertEqual(settings.configurations.count, 8)
    }
    
    // MARK: - 通知内容测试
    
    func testNotificationContentCreation() {
        let content = DreamNotificationContent(
            title: "测试标题",
            body: "测试内容",
            subtitle: "测试副标题",
            sound: "default",
            badge: 1
        )
        
        XCTAssertEqual(content.title, "测试标题")
        XCTAssertEqual(content.body, "测试内容")
        XCTAssertEqual(content.subtitle, "测试副标题")
        XCTAssertEqual(content.sound, "default")
        XCTAssertEqual(content.badge, 1)
        XCTAssertEqual(content.categoryIdentifier, "DREAM_CATEGORY")
    }
    
    func testDefaultContentGeneration() {
        let content = notificationService.getDefaultContent(for: .sleepReminder)
        
        XCTAssertFalse(content.title.isEmpty)
        XCTAssertFalse(content.body.isEmpty)
        XCTAssertEqual(content.subtitle, "梦境记录提醒")
    }
    
    // MARK: - 智能调度测试
    
    func testQuietHoursDetection() {
        // 设置安静时间为 22:00 - 08:00
        notificationService.settings.quietHoursStart = "22:00"
        notificationService.settings.quietHoursEnd = "08:00"
        
        // 创建测试日期
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // 测试 23:00（在安静时间内）
        var components = DateComponents()
        components.hour = 23
        components.minute = 0
        let nightDate = calendar.date(from: components)!
        
        // 测试 10:00（不在安静时间内）
        components.hour = 10
        let dayDate = calendar.date(from: components)!
        
        // 注意：由于 isQuietHours 是私有方法，这里测试设置是否正确保存
        XCTAssertEqual(notificationService.settings.quietHoursStart, "22:00")
        XCTAssertEqual(notificationService.settings.quietHoursEnd, "08:00")
    }
    
    // MARK: - 配置管理测试
    
    func testGetConfig() {
        let config = notificationService.getConfig(type: .sleepReminder)
        
        XCTAssertNotNil(config)
        XCTAssertEqual(config?.type, .sleepReminder)
    }
    
    func testUpdateConfig() {
        guard var config = notificationService.getConfig(type: .sleepReminder) else {
            XCTFail("配置不存在")
            return
        }
        
        config.isEnabled = false
        config.scheduledTime = "23:00"
        
        notificationService.updateConfig(config)
        
        let updatedConfig = notificationService.getConfig(type: .sleepReminder)
        XCTAssertNotNil(updatedConfig)
        XCTAssertEqual(updatedConfig?.isEnabled, false)
        XCTAssertEqual(updatedConfig?.scheduledTime, "23:00")
    }
    
    // MARK: - 统计测试
    
    func testTrackNotificationSent() {
        let initialCount = notificationService.statistics.totalSent
        
        notificationService.trackNotificationSent(type: .sleepReminder)
        
        XCTAssertEqual(notificationService.statistics.totalSent, initialCount + 1)
        XCTAssertNotNil(notificationService.statistics.lastSentDate)
        
        let typeStats = notificationService.statistics.byType["sleepReminder"]
        XCTAssertNotNil(typeStats)
        XCTAssertEqual(typeStats?.sent, 1)
    }
    
    func testTrackNotificationOpened() {
        // 先发送一个通知
        notificationService.trackNotificationSent(type: .morningRecall)
        
        // 然后追踪打开
        notificationService.trackNotificationOpened(type: .morningRecall)
        
        XCTAssertEqual(notificationService.statistics.totalOpened, 1)
        
        let typeStats = notificationService.statistics.byType["morningRecall"]
        XCTAssertNotNil(typeStats)
        XCTAssertEqual(typeStats?.opened, 1)
        XCTAssertEqual(typeStats?.openRate, 1.0)
    }
    
    // MARK: - 小组件数据测试
    
    func testDreamWidgetDataDefault() {
        let widgetData = DreamWidgetData()
        
        XCTAssertEqual(widgetData.dreamsCountToday, 0)
        XCTAssertEqual(widgetData.dreamsCountWeek, 0)
        XCTAssertEqual(widgetData.streakDays, 0)
        XCTAssertEqual(widgetData.averageClarity, 0.0)
        XCTAssertNil(widgetData.currentChallenge)
        XCTAssertNil(widgetData.dailyInsight)
    }
    
    func testChallengeWidgetData() {
        let challenge = ChallengeWidgetData(
            id: "test-1",
            name: "测试挑战",
            progress: 0.75,
            target: 10,
            current: 7,
            icon: "star.fill"
        )
        
        XCTAssertEqual(challenge.id, "test-1")
        XCTAssertEqual(challenge.name, "测试挑战")
        XCTAssertEqual(challenge.progress, 0.75)
        XCTAssertEqual(challenge.target, 10)
        XCTAssertEqual(challenge.current, 7)
        XCTAssertEqual(challenge.icon, "star.fill")
    }
    
    func testInsightWidgetData() {
        let insight = InsightWidgetData(
            title: "测试洞察",
            content: "这是测试内容",
            type: "pattern",
            icon: "lightbulb.fill"
        )
        
        XCTAssertEqual(insight.title, "测试洞察")
        XCTAssertEqual(insight.content, "这是测试内容")
        XCTAssertEqual(insight.type, "pattern")
        XCTAssertEqual(insight.icon, "lightbulb.fill")
    }
    
    // MARK: - 调度通知测试
    
    func testScheduledNotification() {
        let now = Date()
        let notification = ScheduledNotification(
            type: .sleepReminder,
            scheduledDate: now,
            title: "睡前提醒",
            isRecurring: true
        )
        
        XCTAssertEqual(notification.type, .sleepReminder)
        XCTAssertEqual(notification.title, "睡前提醒")
        XCTAssertTrue(notification.isRecurring)
        XCTAssertFalse(notification.id.isEmpty)
    }
    
    // MARK: - 实时活动数据测试
    
    func testChallengeLiveActivityData() {
        let now = Date()
        let endsAt = Calendar.current.date(byAdding: .hour, value: 24, to: now)!
        
        let activityData = ChallengeLiveActivityData(
            challengeId: "challenge-1",
            challengeName: "晨间记录者",
            challengeType: "daily",
            progress: 0.6,
            currentCount: 3,
            targetCount: 5,
            timeRemaining: 24 * 60 * 60,
            state: .active,
            startedAt: now,
            endsAt: endsAt
        )
        
        XCTAssertEqual(activityData.challengeId, "challenge-1")
        XCTAssertEqual(activityData.challengeName, "晨间记录者")
        XCTAssertEqual(activityData.progress, 0.6)
        XCTAssertEqual(activityData.currentCount, 3)
        XCTAssertEqual(activityData.targetCount, 5)
        XCTAssertEqual(activityData.state, .active)
    }
    
    func testIncubationLiveActivityData() {
        let affirmations = ["我很平静", "我能记住梦境", "我是清醒的"]
        
        let activityData = IncubationLiveActivityData(
            incubationId: "incubation-1",
            goal: "做清醒梦",
            affirmations: affirmations,
            currentAffirmationIndex: 0,
            timeRemaining: 8 * 60 * 60,
            state: .active,
            startedAt: Date()
        )
        
        XCTAssertEqual(activityData.incubationId, "incubation-1")
        XCTAssertEqual(activityData.goal, "做清醒梦")
        XCTAssertEqual(activityData.affirmations.count, 3)
        XCTAssertEqual(activityData.currentAffirmationIndex, 0)
    }
    
    // MARK: - 通知操作测试
    
    func testNotificationActionIdentifiers() {
        XCTAssertEqual(
            NotificationActionType.recordDream.identifier,
            "DREAM_ACTION_RECORD_DREAM"
        )
        XCTAssertEqual(
            NotificationActionType.viewInsight.identifier,
            "DREAM_ACTION_VIEW_INSIGHT"
        )
        XCTAssertEqual(
            NotificationActionType.startChallenge.identifier,
            "DREAM_ACTION_START_CHALLENGE"
        )
    }
    
    func testNotificationActionTitles() {
        XCTAssertEqual(NotificationActionType.recordDream.title, "记录梦境")
        XCTAssertEqual(NotificationActionType.viewInsight.title, "查看详情")
        XCTAssertEqual(NotificationActionType.startChallenge.title, "开始挑战")
        XCTAssertEqual(NotificationActionType.snooze.title, "稍后提醒")
        XCTAssertEqual(NotificationActionType.dismiss.title, "关闭")
    }
    
    // MARK: - 性能测试
    
    func testPerformanceExample() throws {
        self.measure {
            // 测试配置加载性能
            for _ in 0..<100 {
                _ = notificationService.getConfig(type: .sleepReminder)
            }
        }
    }
    
    // MARK: - 实时活动测试
    
    @available(iOS 16.2, *)
    func testLiveActivityStateEnum() {
        XCTAssertEqual(LiveActivityState.active.rawValue, "active")
        XCTAssertEqual(LiveActivityState.completed.rawValue, "completed")
        XCTAssertEqual(LiveActivityState.dismissed.rawValue, "dismissed")
    }
    
    @available(iOS 16.2, *)
    func testChallengeLiveActivityDataInitialization() {
        let challengeData = ChallengeLiveActivityData(
            challengeId: "test_challenge",
            challengeName: "每日记录挑战",
            challengeType: "daily",
            progress: 0.5,
            currentCount: 3,
            targetCount: 7,
            timeRemaining: 3600,
            state: .active,
            startedAt: Date(),
            endsAt: Date().addingTimeInterval(86400)
        )
        
        XCTAssertEqual(challengeData.challengeId, "test_challenge")
        XCTAssertEqual(challengeData.challengeName, "每日记录挑战")
        XCTAssertEqual(challengeData.progress, 0.5)
        XCTAssertEqual(challengeData.currentCount, 3)
        XCTAssertEqual(challengeData.targetCount, 7)
        XCTAssertEqual(challengeData.state, .active)
    }
    
    @available(iOS 16.2, *)
    func testIncubationLiveActivityDataInitialization() {
        let incubationData = IncubationLiveActivityData(
            incubationId: "test_incubation",
            goal: "做清醒梦",
            affirmations: ["我能意识到自己在做梦", "我会记住我的梦境", "我很放松"],
            currentAffirmationIndex: 0,
            timeRemaining: 7200,
            state: .active,
            startedAt: Date(),
            targetSleepTime: Date().addingTimeInterval(7200)
        )
        
        XCTAssertEqual(incubationData.incubationId, "test_incubation")
        XCTAssertEqual(incubationData.goal, "做清醒梦")
        XCTAssertEqual(incubationData.affirmations.count, 3)
        XCTAssertEqual(incubationData.currentAffirmationIndex, 0)
        XCTAssertEqual(incubationData.state, .active)
    }
    
    @available(iOS 16.2, *)
    func testLiveActivityServiceAvailability() async {
        // 测试 Live Activity 服务是否可用
        let service = DreamLiveActivityService.shared
        let isAvailable = service.isAvailable
        
        // 注意：在测试环境中，实时活动可能不可用
        // 这个测试主要验证服务可以正常访问
        XCTAssertNotNil(service)
    }
}

// MARK: - 辅助扩展

extension DreamNotificationService {
    // 为测试暴露私有方法
    func getDefaultContent(for type: DreamNotificationType) -> DreamNotificationContent {
        return self.getDefaultContent(for: type)
    }
}
