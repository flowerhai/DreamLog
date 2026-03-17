//
//  DreamSmartNotificationsModels.swift
//  DreamLog
//
//  Phase 61: 智能通知与梦境洞察推送
//  数据模型：智能通知配置、洞察推送、定期摘要
//

import Foundation
import SwiftData
import UserNotifications

// MARK: - 通知类型

/// 智能通知类型
enum SmartNotificationType: String, Codable, CaseIterable {
    case dreamReminder = "dream_reminder"          // 梦境记录提醒
    case bedtimeReminder = "bedtime_reminder"      // 睡前提醒
    case morningReflection = "morning_reflection"  // 晨间反思
    case weeklySummary = "weekly_summary"          // 每周摘要
    case monthlyInsight = "monthly_insight"        // 月度洞察
    case patternAlert = "pattern_alert"            // 模式发现提醒
    case achievementUnlock = "achievement_unlock"  // 成就解锁
    case challengeReminder = "challenge_reminder"  // 挑战提醒
    case lucidDreamPrompt = "lucid_dream_prompt"   // 清醒梦提示
    
    var displayName: String {
        switch self {
        case .dreamReminder: return "梦境记录提醒"
        case .bedtimeReminder: return "睡前提醒"
        case .morningReflection: return "晨间反思"
        case .weeklySummary: return "每周摘要"
        case .monthlyInsight: return "月度洞察"
        case .patternAlert: return "模式发现"
        case .achievementUnlock: return "成就解锁"
        case .challengeReminder: return "挑战提醒"
        case .lucidDreamPrompt: return "清醒梦提示"
        }
    }
    
    var icon: String {
        switch self {
        case .dreamReminder: return "🌙"
        case .bedtimeReminder: return "😴"
        case .morningReflection: return "🌅"
        case .weeklySummary: return "📊"
        case .monthlyInsight: return "🧠"
        case .patternAlert: return "🔍"
        case .achievementUnlock: return "🏆"
        case .challengeReminder: return "🎯"
        case .lucidDreamPrompt: return "👁️"
        }
    }
}

// MARK: - 智能通知配置

/// 用户通知偏好设置
@Model
final class SmartNotificationConfig {
    @Attribute(.unique) var id: UUID
    var userId: String
    
    // 基础提醒
    var isDreamReminderEnabled: Bool
    var dreamReminderHour: Int
    var dreamReminderMinute: Int
    
    var isBedtimeReminderEnabled: Bool
    var bedtimeHour: Int
    var bedtimeMinute: Int
    
    // 智能通知
    var isMorningReflectionEnabled: Bool
    var isWeeklySummaryEnabled: Bool
    var isMonthlyInsightEnabled: Bool
    var isPatternAlertEnabled: Bool
    
    // 挑战与成就
    var isChallengeReminderEnabled: Bool
    var isAchievementNotificationEnabled: Bool
    
    // 清醒梦提示
    var isLucidDreamPromptEnabled: Bool
    var lucidDreamPromptFrequency: LucidDreamPromptFrequency
    
    // 免打扰时段
    var isDoNotDisturbEnabled: Bool
    var doNotDisturbStartHour: Int
    var doNotDisturbEndHour: Int
    
    // 智能定时
    var isSmartTimingEnabled: Bool // 基于用户活跃时间自动调整
    
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: String) {
        self.id = UUID()
        self.userId = userId
        
        // 默认值
        self.isDreamReminderEnabled = true
        self.dreamReminderHour = 8
        self.dreamReminderMinute = 0
        
        self.isBedtimeReminderEnabled = true
        self.bedtimeHour = 22
        self.bedtimeMinute = 30
        
        self.isMorningReflectionEnabled = false
        self.isWeeklySummaryEnabled = true
        self.isMonthlyInsightEnabled = true
        self.isPatternAlertEnabled = true
        
        self.isChallengeReminderEnabled = true
        self.isAchievementNotificationEnabled = true
        
        self.isLucidDreamPromptEnabled = false
        self.lucidDreamPromptFrequency = .daily
        
        self.isDoNotDisturbEnabled = true
        self.doNotDisturbStartHour = 23
        self.doNotDisturbEndHour = 7
        
        self.isSmartTimingEnabled = false
        
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 检查是否在免打扰时段
    func isWithinDoNotDisturb() -> Bool {
        guard isDoNotDisturbEnabled else { return false }
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        if doNotDisturbStartHour > doNotDisturbEndHour {
            // 跨天时段 (如 23:00 - 07:00)
            return currentHour >= doNotDisturbStartHour || currentHour < doNotDisturbEndHour
        } else {
            // 同一天时段
            return currentHour >= doNotDisturbStartHour && currentHour < doNotDisturbEndHour
        }
    }
}

// MARK: - 清醒梦提示频率

enum LucidDreamPromptFrequency: String, Codable, CaseIterable {
    case hourly = "hourly"       // 每小时
    case every2Hours = "every_2_hours" // 每 2 小时
    case every3Hours = "every_3_hours" // 每 3 小时
    case daily = "daily"         // 每天一次
    
    var displayName: String {
        switch self {
        case .hourly: return "每小时"
        case .every2Hours: return "每 2 小时"
        case .every3Hours: return "每 3 小时"
        case .daily: return "每天一次"
        }
    }
    
    var intervalSeconds: TimeInterval {
        switch self {
        case .hourly: return 3600
        case .every2Hours: return 7200
        case .every3Hours: return 10800
        case .daily: return 86400
        }
    }
}

// MARK: - 通知洞察

/// 待推送的梦境洞察
@Model
final class PendingNotificationInsight {
    @Attribute(.unique) var id: UUID
    var type: SmartNotificationType
    var title: String
    var body: String
    var data: Data? // JSON 编码的附加数据
    var scheduledDate: Date
    var isSent: Bool
    var sentDate: Date?
    var priority: NotificationPriority
    
    init(
        type: SmartNotificationType,
        title: String,
        body: String,
        data: Data? = nil,
        scheduledDate: Date,
        priority: NotificationPriority = .normal
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.body = body
        self.data = data
        self.scheduledDate = scheduledDate
        self.isSent = false
        self.sentDate = nil
        self.priority = priority
    }
}

// MARK: - 通知优先级

enum NotificationPriority: Int, Codable, CaseIterable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .normal: return "普通"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
}

// MARK: - 每周摘要数据

/// 每周梦境摘要数据结构
struct WeeklySummaryData: Codable {
    var totalDreams: Int
    var averageClarity: Double
    var topEmotions: [(emotion: String, count: Int)]
    var topTags: [String]
    var lucidDreamCount: Int
    var insight: String
    var weekStartDate: Date
    var weekEndDate: Date
    
    init(
        totalDreams: Int = 0,
        averageClarity: Double = 0,
        topEmotions: [(emotion: String, count: Int)] = [],
        topTags: [String] = [],
        lucidDreamCount: Int = 0,
        insight: String = "",
        weekStartDate: Date = Date(),
        weekEndDate: Date = Date()
    ) {
        self.totalDreams = totalDreams
        self.averageClarity = averageClarity
        self.topEmotions = topEmotions
        self.topTags = topTags
        self.lucidDreamCount = lucidDreamCount
        self.insight = insight
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
    }
}

// MARK: - 月度洞察数据

/// 月度梦境洞察数据结构
struct MonthlyInsightData: Codable {
    var totalDreams: Int
    var dreamTrend: DreamTrend // 上升/下降/平稳
    var dominantTheme: String
    var emotionalJourney: [String] // 情绪变化描述
    var recurringPatterns: [String] // 重复模式
    var recommendations: [String] // 建议
    var month: Date
    var comparisonWithPrevious: String // 与上月对比
    
    init(
        totalDreams: Int = 0,
        dreamTrend: DreamTrend = .stable,
        dominantTheme: String = "",
        emotionalJourney: [String] = [],
        recurringPatterns: [String] = [],
        recommendations: [String] = [],
        month: Date = Date(),
        comparisonWithPrevious: String = ""
    ) {
        self.totalDreams = totalDreams
        self.dreamTrend = dreamTrend
        self.dominantTheme = dominantTheme
        self.emotionalJourney = emotionalJourney
        self.recurringPatterns = recurringPatterns
        self.recommendations = recommendations
        self.month = month
        self.comparisonWithPrevious = comparisonWithPrevious
    }
}

enum DreamTrend: String, Codable {
    case increasing = "increasing" // 增加
    case decreasing = "decreasing" // 减少
    case stable = "stable"         // 平稳
    
    var displayName: String {
        switch self {
        case .increasing: return "上升 ↑"
        case .decreasing: return "下降 ↓"
        case .stable: return "平稳 →"
        }
    }
}

// MARK: - 通知交互动作

extension UNNotificationCategory {
    static let dreamReminder = UNNotificationCategory(
        identifier: "dream_reminder",
        actions: [
            UNNotificationAction(
                identifier: "RECORD_DREAM",
                title: "立即记录",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "SNOOZE",
                title: "稍后提醒",
                options: []
            )
        ],
        intentIdentifiers: [],
        options: []
    )
    
    static let weeklySummary = UNNotificationCategory(
        identifier: "weekly_summary",
        actions: [
            UNNotificationAction(
                identifier: "VIEW_SUMMARY",
                title: "查看详情",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "SHARE",
                title: "分享",
                options: .foreground
            )
        ],
        intentIdentifiers: [],
        options: []
    )
}
