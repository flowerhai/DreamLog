//
//  DreamDigitalWellnessModels.swift
//  DreamLog
//
//  数字健康数据模型 - 追踪屏幕使用与梦境的关联
//

import Foundation
import SwiftData

// MARK: - 屏幕使用数据类型

/// 应用类别
enum AppCategory: String, Codable, CaseIterable {
    case socialMedia = "社交网络"
    case entertainment = "娱乐"
    case productivity = "效率"
    case games = "游戏"
    case education = "教育"
    case health = "健康与健身"
    case news = "新闻"
    case shopping = "购物"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .socialMedia: return "📱"
        case .entertainment: return "🎬"
        case .productivity: return "💼"
        case .games: return "🎮"
        case .education: return "📚"
        case .health: return "💪"
        case .news: return "📰"
        case .shopping: return "🛍️"
        case .other: return "📦"
        }
    }
    
    var color: String {
        switch self {
        case .socialMedia: return "FF2D55"
        case .entertainment: return "5856D6"
        case .productivity: return "34C759"
        case .games: return "FF9500"
        case .education: return "007AFF"
        case .health: return "FF3B30"
        case .news: return "8E8E93"
        case .shopping: return "FF2D55"
        case .other: return "C7C7CC"
        }
    }
}

/// 屏幕使用记录
@Model
final class ScreenTimeRecord {
    var id: UUID
    var date: Date
    var totalMinutes: Int
    var category: String
    var topApps: [String]
    var pickups: Int // 拿起设备次数
    var notifications: Int // 通知数量
    
    init(
        id: UUID = UUID(),
        date: Date,
        totalMinutes: Int,
        category: String,
        topApps: [String] = [],
        pickups: Int = 0,
        notifications: Int = 0
    ) {
        self.id = id
        self.date = date
        self.totalMinutes = totalMinutes
        self.category = category
        self.topApps = topApps
        self.pickups = pickups
        self.notifications = notifications
    }
}

/// 睡前屏幕使用记录
@Model
final class PreSleepScreenTime {
    var id: UUID
    var date: Date
    var minutesBeforeSleep: Int // 睡前使用分钟数
    var lastUseTime: Date // 最后使用时间
    var blueLightExposure: String // 低/中/高
    var stimulatingContent: Bool // 是否有刺激内容
    
    init(
        id: UUID = UUID(),
        date: Date,
        minutesBeforeSleep: Int,
        lastUseTime: Date,
        blueLightExposure: String,
        stimulatingContent: Bool
    ) {
        self.id = id
        self.date = date
        self.minutesBeforeSleep = minutesBeforeSleep
        self.lastUseTime = lastUseTime
        self.blueLightExposure = blueLightExposure
        self.stimulatingContent = stimulatingContent
    }
}

// MARK: - 数字健康洞察

/// 洞察类型
enum WellnessInsightType: String, Codable, CaseIterable {
    case screenTimeImpact = "屏幕时间影响"
    case blueLightEffect = "蓝光影响"
    case contentStimulation = "内容刺激"
    case usagePattern = "使用模式"
    case bedtimeRoutine = "睡前习惯"
    case improvement = "改善建议"
    
    var icon: String {
        switch self {
        case .screenTimeImpact: return "📱"
        case .blueLightEffect: return "💡"
        case .contentStimulation: return "🎬"
        case .usagePattern: return "📊"
        case .bedtimeRoutine: return "🌙"
        case .improvement: return "💡"
        }
    }
    
    var color: String {
        switch self {
        case .screenTimeImpact: return "FF9500"
        case .blueLightEffect: return "5AC8FA"
        case .contentStimulation: return "FF2D55"
        case .usagePattern: return "5856D6"
        case .bedtimeRoutine: return "34C759"
        case .improvement: return "FFD60A"
        }
    }
}

/// 数字健康洞察
@Model
final class DigitalWellnessInsight {
    var id: UUID
    var createdAt: Date
    var type: String
    var title: String
    var description: String
    var severity: String // low/medium/high
    var relatedDreamIds: [UUID]
    var recommendations: [String]
    var isRead: Bool
    var isSaved: Bool
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        type: String,
        title: String,
        description: String,
        severity: String = "medium",
        relatedDreamIds: [UUID] = [],
        recommendations: [String] = [],
        isRead: Bool = false,
        isSaved: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.type = type
        self.title = title
        self.description = description
        self.severity = severity
        self.relatedDreamIds = relatedDreamIds
        self.recommendations = recommendations
        self.isRead = isRead
        self.isSaved = isSaved
    }
}

// MARK: - 统计数据

/// 数字健康统计
struct DigitalWellnessStats {
    var avgScreenTimeBeforeSleep: Int // 平均睡前屏幕时间 (分钟)
    var highScreenTimeDays: Int // 高屏幕时间天数
    var correlationWithDreamQuality: Double // 与梦境清晰度相关性 (-1 to 1)
    var correlationWithSleepQuality: Double // 与睡眠质量相关性
    var topProblematicCategories: [String] // 问题最多的应用类别
    var improvementTrend: String // improving/stable/declining
    var weeklyStats: WeeklyWellnessStats
    
    struct WeeklyWellnessStats {
        var weekStart: Date
        var avgScreenTime: Int
        var avgSleepLatency: Int // 入睡时间 (分钟)
        var dreamRecallRate: Double // 梦境回忆率
        var qualityScore: Double // 整体健康评分
    }
}

// MARK: - 配置

/// 数字健康配置
struct DigitalWellnessConfig: Codable {
    var isEnabled: Bool
    var targetBedtime: String // "23:00"
    var screenTimeLimit: Int // 睡前限制分钟数
    var blueLightFilterReminder: Bool
    var windDownReminder: Bool
    var windDownDuration: Int // 放松时长 (分钟)
    var excludedApps: [String] // 不计入的应用 (如冥想应用)
    
    static var `default`: DigitalWellnessConfig {
        DigitalWellnessConfig(
            isEnabled: true,
            targetBedtime: "23:00",
            screenTimeLimit: 30,
            blueLightFilterReminder: true,
            windDownReminder: true,
            windDownDuration: 60,
            excludedApps: ["DreamLog", "Calm", "Headspace"]
        )
    }
}

// MARK: - 分享数据

/// 数字健康报告卡片
struct WellnessReportCard {
    var period: String
    var screenTimeScore: Int // 0-100
    var sleepQualityScore: Int
    var dreamQualityScore: Int
    var overallScore: Int
    var keyInsights: [String]
    var improvements: [String]
    var shareableImage: Data?
}
