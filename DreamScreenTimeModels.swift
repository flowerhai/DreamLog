//
//  DreamScreenTimeModels.swift
//  DreamLog
//
//  Phase 93: 屏幕时间与数字健康追踪
//  追踪睡前屏幕使用时间，分析与梦境质量的关联
//

import Foundation

// MARK: - 屏幕时间数据类型

/// 屏幕使用应用类别
enum ScreenTimeCategory: String, Codable, CaseIterable, Identifiable {
    case socialMedia = "social_media"
    case entertainment = "entertainment"
    case games = "games"
    case productivity = "productivity"
    case education = "education"
    case reading = "reading"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .socialMedia: return "社交媒体"
        case .entertainment: return "娱乐"
        case .games: return "游戏"
        case .productivity: return "生产力"
        case .education: return "教育"
        case .reading: return "阅读"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .socialMedia: return "person.2.fill"
        case .entertainment: return "tv.fill"
        case .games: return "gamecontroller.fill"
        case .productivity: return "briefcase.fill"
        case .education: return "book.fill"
        case .reading: return "text.book.closed.fill"
        case .other: return "app.fill"
        }
    }
    
    var color: String {
        switch self {
        case .socialMedia: return "FF2D55"
        case .entertainment: return "5856D6"
        case .games: return "FF9500"
        case .productivity: return "34C759"
        case .education: return "007AFF"
        case .reading: return "BF5AF2"
        case .other: return "8E8E93"
        }
    }
}

/// 屏幕使用记录
struct ScreenTimeSession: Identifiable, Codable {
    var id: UUID
    var date: Date
    var duration: TimeInterval // 秒
    var category: ScreenTimeCategory
    var appName: String
    var isBeforeBed: Bool // 是否在睡前使用
    var minutesBeforeSleep: Int? // 距离睡眠的分钟数
    
    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, category: ScreenTimeCategory, appName: String, isBeforeBed: Bool = false, minutesBeforeSleep: Int? = nil) {
        self.id = id
        self.date = date
        self.duration = duration
        self.category = category
        self.appName = appName
        self.isBeforeBed = isBeforeBed
        self.minutesBeforeSleep = minutesBeforeSleep
    }
}

/// 每日屏幕时间统计
struct DailyScreenTimeStats: Identifiable, Codable {
    var id: UUID
    var date: Date
    var totalDuration: TimeInterval // 总使用时长（秒）
    var beforeBedDuration: TimeInterval // 睡前使用时长（秒）
    var categoryBreakdown: [ScreenTimeCategory: TimeInterval] // 分类统计
    var sessionCount: Int // 使用次数
    var averageSessionDuration: TimeInterval // 平均单次时长
    var peakCategory: ScreenTimeCategory? // 使用最多的类别
    
    var id: UUID { UUID() }
    
    init(date: Date, sessions: [ScreenTimeSession]) {
        self.id = UUID()
        self.date = date
        self.totalDuration = sessions.reduce(0) { $0 + $1.duration }
        self.beforeBedDuration = sessions.filter { $0.isBeforeBed }.reduce(0) { $0 + $1.duration }
        self.sessionCount = sessions.count
        self.averageSessionDuration = sessions.isEmpty ? 0 : totalDuration / Double(sessions.count)
        
        // 分类统计
        var breakdown: [ScreenTimeCategory: TimeInterval] = [:]
        for session in sessions {
            breakdown[session.category, default: 0] += session.duration
        }
        self.categoryBreakdown = breakdown
        
        // 找出使用最多的类别
        self.peakCategory = breakdown.max(by: { $0.value < $1.value })?.key
    }
    
    var totalHours: Double { totalDuration / 3600 }
    var beforeBedMinutes: Double { beforeBedDuration / 60 }
}

// MARK: - 屏幕时间与梦境关联分析

/// 屏幕时间对梦境的影响分析
struct ScreenTimeDreamCorrelation: Codable {
    var analysisDate: Date
    var dataRangeDays: Int
    var totalDreamsAnalyzed: Int
    
    // 整体关联度 (-1 到 1，-1 强负相关，1 强正相关，0 无关联)
    var overallCorrelation: Double
    
    // 分类关联度
    var categoryCorrelations: [ScreenTimeCategory: Double]
    
    // 关键发现
    var keyFindings: [ScreenTimeFinding]
    
    // 个性化建议
    var recommendations: [ScreenTimeRecommendation]
    
    // 统计摘要
    var stats: CorrelationStats
}

/// 关键发现
struct ScreenTimeFinding: Identifiable, Codable {
    var id: UUID
    var type: FindingType
    var title: String
    var description: String
    var severity: FindingSeverity
    var supportingData: String
    
    enum FindingType: String, Codable {
        case negativeImpact = "negative_impact"
        case positiveImpact = "positive_impact"
        case pattern = "pattern"
        case warning = "warning"
        case achievement = "achievement"
    }
    
    enum FindingSeverity: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}

/// 个性化建议
struct ScreenTimeRecommendation: Identifiable, Codable {
    var id: UUID
    var category: RecommendationCategory
    var title: String
    var description: String
    var actionItems: [String]
    var expectedBenefit: String
    var priority: Priority
    
    enum RecommendationCategory: String, Codable {
        case reduceBeforeBed = "reduce_before_bed"
        case changeCategory = "change_category"
        case timing = "timing"
        case alternative = "alternative"
        case habit = "habit"
    }
    
    enum Priority: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}

/// 关联统计
struct CorrelationStats: Codable {
    var averageScreenTimeBeforeBed: TimeInterval // 平均睡前屏幕时间（秒）
    var averageDreamClarity: Double // 平均梦境清晰度
    var averageDreamQuality: Double // 平均梦境质量
    
    // 分组统计
    var highScreenTimeGroup: GroupStats // 高屏幕时间组（>60 分钟）
    var lowScreenTimeGroup: GroupStats // 低屏幕时间组（<30 分钟）
    
    struct GroupStats: Codable {
        var count: Int
        var averageClarity: Double
        var averageQuality: Double
        var averageNightmareRate: Double
    }
}

// MARK: - 数字健康目标

/// 屏幕时间目标
struct ScreenTimeGoal: Identifiable, Codable {
    var id: UUID
    var category: ScreenTimeCategory
    var dailyLimitMinutes: Int // 每日限制（分钟）
    var beforeBedLimitMinutes: Int // 睡前限制（分钟）
    var isEnabled: Bool
    var notifyWhenExceeded: Bool
    
    init(id: UUID = UUID(), category: ScreenTimeCategory, dailyLimitMinutes: Int = 60, beforeBedLimitMinutes: Int = 30, isEnabled: Bool = true, notifyWhenExceeded: Bool = true) {
        self.id = id
        self.category = category
        self.dailyLimitMinutes = dailyLimitMinutes
        self.beforeBedLimitMinutes = beforeBedLimitMinutes
        self.isEnabled = isEnabled
        self.notifyWhenExceeded = notifyWhenExceeded
    }
}

/// 数字健康设置
struct DigitalWellnessSettings: Codable {
    var trackingEnabled: Bool
    var bedTimeReminder: Bool
    var bedTime: DateComponents?
    var wakeTime: DateComponents?
    var windDownMinutes: Int // 睡前放松时间（分钟）
    var goals: [ScreenTimeGoal]
    var notifyOnCorrelation: Bool // 发现显著关联时通知
    
    static var `default`: DigitalWellnessSettings {
        DigitalWellnessSettings(
            trackingEnabled: true,
            bedTimeReminder: true,
            bedTime: DateComponents(hour: 23, minute: 0),
            wakeTime: DateComponents(hour: 7, minute: 0),
            windDownMinutes: 60,
            goals: [
                ScreenTimeGoal(category: .socialMedia, dailyLimitMinutes: 90, beforeBedLimitMinutes: 30),
                ScreenTimeGoal(category: .games, dailyLimitMinutes: 60, beforeBedLimitMinutes: 0),
                ScreenTimeGoal(category: .entertainment, dailyLimitMinutes: 120, beforeBedLimitMinutes: 30)
            ],
            notifyOnCorrelation: true
        )
    }
}

// MARK: - 周报/月报数据

/// 屏幕时间周报
struct ScreenTimeWeeklyReport: Codable {
    var weekStart: Date
    var weekEnd: Date
    var dailyStats: [DailyScreenTimeStats]
    var totalScreenTime: TimeInterval
    var averageDailyScreenTime: TimeInterval
    var beforeBedPercentage: Double
    var topCategory: ScreenTimeCategory?
    var dreamQualityTrend: TrendDirection
    var correlationInsight: String
    var weeklyGoal: ScreenTimeWeeklyGoal
    var achievements: [ScreenTimeAchievement]
    
    enum TrendDirection: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
    }
}

/// 每周目标
struct ScreenTimeWeeklyGoal: Codable {
    var targetMinutes: Int
    var actualMinutes: Int
    var beforeBedTargetMinutes: Int
    var beforeBedActualMinutes: Int
    var isAchieved: Bool
    var progressPercentage: Double
}

/// 成就徽章
struct ScreenTimeAchievement: Identifiable, Codable {
    var id: UUID
    var type: AchievementType
    var title: String
    var description: String
    var icon: String
    var earnedDate: Date
    var level: Int
    
    enum AchievementType: String, Codable, CaseIterable {
        case digitalDetox = "digital_detox" // 无屏幕日
        case earlyBird = "early_bird" // 提前停止使用
        case consistentWeek = "consistent_week" // 连续达标周
        case mindfulUser = "mindful_user" // 正念使用者
        case qualitySleeper = "quality_sleeper" // 高质量睡眠
        case dreamMaster = "dream_master" // 梦境大师
    }
}

// MARK: - 快速统计

struct ScreenTimeQuickStats: Codable {
    var todayMinutes: Int
    var beforeBedTodayMinutes: Int
    var weeklyAverageMinutes: Double
    var correlationScore: Double // -1 到 1
    var streakDays: Int // 连续达标天数
    var dreamQualityScore: Double
}
