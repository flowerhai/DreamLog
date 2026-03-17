//
//  DreamSmartNotificationTests.swift
//  DreamLogTests
//
//  Phase 61: 智能通知与梦境洞察推送
//  单元测试
//

import XCTest
import UserNotifications
import SwiftData
@testable import DreamLog

@MainActor
final class DreamSmartNotificationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamSmartNotificationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            SmartNotificationConfig.self,
            PendingNotificationInsight.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        
        service = DreamSmartNotificationService.shared
        service.initialize(modelContext: modelContainer.mainContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 配置测试
    
    func testCreateDefaultConfig() throws {
        let userId = "test_user_123"
        let config = SmartNotificationConfig(userId: userId)
        modelContainer.mainContext.insert(config)
        
        try modelContainer.mainContext.save()
        
        let configs = try modelContainer.mainContext.fetch(FetchDescriptor<SmartNotificationConfig>())
        XCTAssertEqual(configs.count, 1)
        XCTAssertEqual(configs[0].userId, userId)
        XCTAssertTrue(configs[0].isDreamReminderEnabled)
        XCTAssertEqual(configs[0].dreamReminderHour, 8)
        XCTAssertEqual(configs[0].dreamReminderMinute, 0)
    }
    
    func testNotificationConfigDefaults() throws {
        let config = SmartNotificationConfig(userId: "test_user")
        
        // 基础提醒默认启用
        XCTAssertTrue(config.isDreamReminderEnabled)
        XCTAssertTrue(config.isBedtimeReminderEnabled)
        
        // 智能通知部分启用
        XCTAssertFalse(config.isMorningReflectionEnabled)
        XCTAssertTrue(config.isWeeklySummaryEnabled)
        XCTAssertTrue(config.isMonthlyInsightEnabled)
        XCTAssertTrue(config.isPatternAlertEnabled)
        
        // 挑战与成就
        XCTAssertTrue(config.isChallengeReminderEnabled)
        XCTAssertTrue(config.isAchievementNotificationEnabled)
        
        // 清醒梦提示默认关闭
        XCTAssertFalse(config.isLucidDreamPromptEnabled)
        XCTAssertEqual(config.lucidDreamPromptFrequency, .daily)
        
        // 免打扰
        XCTAssertTrue(config.isDoNotDisturbEnabled)
        XCTAssertEqual(config.doNotDisturbStartHour, 23)
        XCTAssertEqual(config.doNotDisturbEndHour, 7)
    }
    
    // MARK: - 免打扰时段测试
    
    func testIsWithinDoNotDisturb_CrossDay() {
        let config = SmartNotificationConfig(userId: "test_user")
        config.doNotDisturbStartHour = 23
        config.doNotDisturbEndHour = 7
        
        // 测试跨天时段 (23:00 - 07:00)
        XCTAssertTrue(config.isWithinDoNotDisturb()) // 假设当前时间在免打扰时段
        
        // 注意：这个测试依赖于当前系统时间
        // 更好的做法是注入当前时间
    }
    
    func testIsWithinDoNotDisturb_SameDay() {
        let config = SmartNotificationConfig(userId: "test_user")
        config.doNotDisturbStartHour = 10
        config.doNotDisturbEndHour = 12
        
        // 测试同一天时段
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if currentHour >= 10 && currentHour < 12 {
            XCTAssertTrue(config.isWithinDoNotDisturb())
        }
    }
    
    // MARK: - 清醒梦提示频率测试
    
    func testLucidDreamPromptFrequency() {
        XCTAssertEqual(LucidDreamPromptFrequency.hourly.intervalSeconds, 3600)
        XCTAssertEqual(LucidDreamPromptFrequency.every2Hours.intervalSeconds, 7200)
        XCTAssertEqual(LucidDreamPromptFrequency.every3Hours.intervalSeconds, 10800)
        XCTAssertEqual(LucidDreamPromptFrequency.daily.intervalSeconds, 86400)
        
        XCTAssertEqual(LucidDreamPromptFrequency.hourly.displayName, "每小时")
        XCTAssertEqual(LucidDreamPromptFrequency.every2Hours.displayName, "每 2 小时")
        XCTAssertEqual(LucidDreamPromptFrequency.every3Hours.displayName, "每 3 小时")
        XCTAssertEqual(LucidDreamPromptFrequency.daily.displayName, "每天一次")
    }
    
    // MARK: - 通知类型测试
    
    func testSmartNotificationType() {
        let allTypes = SmartNotificationType.allCases
        
        XCTAssertEqual(allTypes.count, 9)
        
        XCTAssertEqual(SmartNotificationType.dreamReminder.displayName, "梦境记录提醒")
        XCTAssertEqual(SmartNotificationType.dreamReminder.icon, "🌙")
        
        XCTAssertEqual(SmartNotificationType.weeklySummary.displayName, "每周摘要")
        XCTAssertEqual(SmartNotificationType.weeklySummary.icon, "📊")
        
        XCTAssertEqual(SmartNotificationType.monthlyInsight.displayName, "月度洞察")
        XCTAssertEqual(SmartNotificationType.monthlyInsight.icon, "🧠")
    }
    
    // MARK: - 每周摘要数据测试
    
    func testWeeklySummaryData() {
        let summary = WeeklySummaryData(
            totalDreams: 7,
            averageClarity: 4.2,
            topEmotions: [("平静", 4), ("快乐", 2), ("兴奋", 1)],
            topTags: ["飞行", "水", "自由"],
            lucidDreamCount: 2,
            insight: "本周梦境质量较高",
            weekStartDate: Date(),
            weekEndDate: Date().addingTimeInterval(7 * 24 * 3600)
        )
        
        XCTAssertEqual(summary.totalDreams, 7)
        XCTAssertEqual(summary.averageClarity, 4.2, accuracy: 0.01)
        XCTAssertEqual(summary.topEmotions.count, 3)
        XCTAssertEqual(summary.topTags.count, 3)
        XCTAssertEqual(summary.lucidDreamCount, 2)
        XCTAssertFalse(summary.insight.isEmpty)
    }
    
    // MARK: - 月度洞察数据测试
    
    func testMonthlyInsightData() {
        let insight = MonthlyInsightData(
            totalDreams: 25,
            dreamTrend: .increasing,
            dominantTheme: "飞行与自由",
            emotionalJourney: ["平静 → 兴奋 → 平静"],
            recurringPatterns: ["水元素频繁出现", "飞行场景增多"],
            recommendations: ["尝试清醒梦练习", "记录梦境情绪变化"],
            month: Date(),
            comparisonWithPrevious: "比上月多记录了 5 个梦境"
        )
        
        XCTAssertEqual(insight.totalDreams, 25)
        XCTAssertEqual(insight.dreamTrend, .increasing)
        XCTAssertEqual(insight.dominantTheme, "飞行与自由")
        XCTAssertEqual(insight.recurringPatterns.count, 2)
        XCTAssertEqual(insight.recommendations.count, 2)
    }
    
    func testDreamTrendDisplayNames() {
        XCTAssertEqual(DreamTrend.increasing.displayName, "上升 ↑")
        XCTAssertEqual(DreamTrend.decreasing.displayName, "下降 ↓")
        XCTAssertEqual(DreamTrend.stable.displayName, "平稳 →")
    }
    
    // MARK: - 通知优先级测试
    
    func testNotificationPriority() {
        XCTAssertEqual(NotificationPriority.low.rawValue, 0)
        XCTAssertEqual(NotificationPriority.normal.rawValue, 1)
        XCTAssertEqual(NotificationPriority.high.rawValue, 2)
        XCTAssertEqual(NotificationPriority.urgent.rawValue, 3)
        
        XCTAssertEqual(NotificationPriority.low.displayName, "低")
        XCTAssertEqual(NotificationPriority.normal.displayName, "普通")
        XCTAssertEqual(NotificationPriority.high.displayName, "高")
        XCTAssertEqual(NotificationPriority.urgent.displayName, "紧急")
    }
    
    // MARK: - 待推送洞察测试
    
    func testPendingNotificationInsight() throws {
        let insight = PendingNotificationInsight(
            type: .weeklySummary,
            title: "本周梦境摘要",
            body: "本周记录了 7 个梦境",
            scheduledDate: Date(),
            priority: .high
        )
        
        modelContainer.mainContext.insert(insight)
        try modelContainer.mainContext.save()
        
        let insights = try modelContainer.mainContext.fetch(FetchDescriptor<PendingNotificationInsight>())
        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights[0].type, .weeklySummary)
        XCTAssertEqual(insights[0].priority, .high)
        XCTAssertFalse(insights[0].isSent)
    }
    
    // MARK: - 活跃时间追踪测试
    
    func testUserActiveHoursTracking() {
        // 模拟记录活跃时间
        service.userActiveHours[8] = 5
        service.userActiveHours[9] = 3
        service.userActiveHours[20] = 4
        service.userActiveHours[21] = 6
        
        // 验证追踪数据
        XCTAssertEqual(service.userActiveHours[8], 5)
        XCTAssertEqual(service.userActiveHours[21], 6)
        XCTAssertEqual(service.userActiveHours.count, 4)
    }
    
    func testCalculateOptimalReminderTime() {
        // 设置活跃时间
        service.userActiveHours[8] = 2
        service.userActiveHours[9] = 10 // 最活跃
        service.userActiveHours[10] = 5
        
        let optimalTime = service.calculateOptimalReminderTime()
        
        // 应该在最活跃时间前 1 小时
        XCTAssertEqual(optimalTime.hour, 8)
        XCTAssertEqual(optimalTime.minute, 0)
    }
    
    // MARK: - 性能测试
    
    func testPerformance_ConfigCreation() throws {
        self.measure {
            let config = SmartNotificationConfig(userId: "test_user")
            modelContainer.mainContext.insert(config)
            try? modelContainer.mainContext.save()
        }
    }
    
    func testPerformance_InsightCreation() throws {
        self.measure {
            let insight = PendingNotificationInsight(
                type: .weeklySummary,
                title: "测试摘要",
                body: "测试内容",
                scheduledDate: Date()
            )
            modelContainer.mainContext.insert(insight)
            try? modelContainer.mainContext.save()
        }
    }
}
