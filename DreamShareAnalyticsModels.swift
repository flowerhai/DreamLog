//
//  DreamShareAnalyticsModels.swift
//  DreamLog - 梦境分享数据分析模型
//
//  Created by DreamLog Team on 2026-03-15.
//  Phase 46: Dream Share Analytics - 分享数据分析与洞察
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - 分享统计模型

/// 分享统计数据 - 聚合分享历史记录
@Model
final class ShareStatistics {
    var id: UUID
    var period: String                      // 统计周期 (daily/weekly/monthly/yearly/all)
    var periodStart: Date                   // 周期开始日期
    var periodEnd: Date                     // 周期结束日期
    var totalShares: Int                    // 总分享次数
    var uniqueDreamsShared: Int             // 被分享的独特梦境数
    var platformBreakdown: [String: Int]    // 平台分布 [platformID: count]
    var templateBreakdown: [String: Int]    // 模板使用分布 [templateID: count]
    var hourlyDistribution: [Int: Int]      // 小时分布 [hour: count]
    var weeklyDistribution: [Int: Int]      // 星期分布 [weekday: count]
    var topSharedTags: [String]             // 热门标签 Top 10
    var topSharedEmotions: [String]         // 热门情绪 Top 5
    var averageSharesPerDay: Double         // 日均分享次数
    var peakSharingHour: Int                // 分享高峰小时
    var peakSharingWeekday: Int             // 分享高峰星期
    var streakDays: Int                     // 连续分享天数
    var longestStreak: Int                  // 最长连续分享天数
    var lastShareDate: Date?                // 最后分享日期
    var createdAt: Date
    var updatedAt: Date
    
    init(
        period: String = "all",
        periodStart: Date = Date.distantPast,
        periodEnd: Date = Date(),
        totalShares: Int = 0,
        uniqueDreamsShared: Int = 0,
        platformBreakdown: [String: Int] = [:],
        templateBreakdown: [String: Int] = [:],
        hourlyDistribution: [Int: Int] = [:],
        weeklyDistribution: [Int: Int] = [:],
        topSharedTags: [String] = [],
        topSharedEmotions: [String] = [],
        averageSharesPerDay: Double = 0,
        peakSharingHour: Int = 20,
        peakSharingWeekday: Int = 0,
        streakDays: Int = 0,
        longestStreak: Int = 0,
        lastShareDate: Date? = nil
    ) {
        self.id = UUID()
        self.period = period
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalShares = totalShares
        self.uniqueDreamsShared = uniqueDreamsShared
        self.platformBreakdown = platformBreakdown
        self.templateBreakdown = templateBreakdown
        self.hourlyDistribution = hourlyDistribution
        self.weeklyDistribution = weeklyDistribution
        self.topSharedTags = topSharedTags
        self.topSharedEmotions = topSharedEmotions
        self.averageSharesPerDay = averageSharesPerDay
        self.peakSharingHour = peakSharingHour
        self.peakSharingWeekday = peakSharingWeekday
        self.streakDays = streakDays
        self.longestStreak = longestStreak
        self.lastShareDate = lastShareDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 分享洞察模型

/// 分享洞察 - 基于数据分析的智能建议
struct ShareInsight: Identifiable, Codable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let suggestion: String
    let confidence: Double              // 置信度 0-1
    let dataPoints: Int                 // 支持数据点数
    let createdAt: Date
    
    enum InsightType: String, Codable {
        case bestTime = "best_time"           // 最佳分享时间
        case popularPlatform = "popular_platform"  // 热门平台
        case trendingTag = "trending_tag"     // 热门标签
        case sharingPattern = "sharing_pattern"  // 分享模式
        case improvement = "improvement"      // 改进建议
        case milestone = "milestone"          // 里程碑
        case engagement = "engagement"        // 互动建议
    }
    
    init(
        type: InsightType,
        title: String,
        description: String,
        suggestion: String,
        confidence: Double = 0.8,
        dataPoints: Int = 0
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.suggestion = suggestion
        self.confidence = confidence
        self.dataPoints = dataPoints
        self.createdAt = Date()
    }
}

// MARK: - 分享趋势模型

/// 分享趋势数据点
struct ShareTrendPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let shareCount: Int
    let uniqueDreams: Int
    let topPlatform: String
    
    init(date: Date, shareCount: Int, uniqueDreams: Int = 0, topPlatform: String = "") {
        self.id = UUID()
        self.date = date
        self.shareCount = shareCount
        self.uniqueDreams = uniqueDreams
        self.topPlatform = topPlatform
    }
}

// MARK: - 分享成就模型

/// 分享成就 - 用户达成的分享里程碑
@Model
final class ShareAchievement {
    var id: UUID
    let achievementId: String               // 成就 ID
    let name: String                        // 成就名称
    let description: String                 // 成就描述
    let icon: String                        // 成就图标 (SF Symbol)
    let category: AchievementCategory       // 成就类别
    let requirement: Int                    // 达成要求数量
    var progress: Int                       // 当前进度
    var isUnlocked: Bool                    // 是否已解锁
    var unlockedAt: Date?                   // 解锁时间
    var shareCount: Int                     // 达成时的分享数
    let createdAt: Date
    
    enum AchievementCategory: String, Codable {
        case count = "count"                // 次数成就
        case streak = "streak"              // 连续成就
        case platform = "platform"          // 平台成就
        case variety = "variety"            // 多样性成就
        case time = "time"                  // 时间成就
        case special = "special"            // 特殊成就
    }
    
    init(
        achievementId: String,
        name: String,
        description: String,
        icon: String,
        category: AchievementCategory,
        requirement: Int,
        progress: Int = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        shareCount: Int = 0
    ) {
        self.id = UUID()
        self.achievementId = achievementId
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.requirement = requirement
        self.progress = progress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.shareCount = shareCount
        self.createdAt = Date()
    }
}

// MARK: - 分享配置模型

/// 分享分析配置
struct ShareAnalyticsConfig: Codable {
    var enableTracking: Bool                // 启用追踪
    var enableInsights: Bool                // 启用智能洞察
    var enableNotifications: Bool           // 启用成就通知
    var trackPlatforms: [String]            // 追踪的平台列表
    var dataRetentionDays: Int              // 数据保留天数
    
    static var `default`: ShareAnalyticsConfig {
        ShareAnalyticsConfig(
            enableTracking: true,
            enableInsights: true,
            enableNotifications: true,
            trackPlatforms: SharePlatform.allCases.map { $0.rawValue },
            dataRetentionDays: 365
        )
    }
}

// MARK: - 分享卡片数据模型

/// 分享统计卡片数据
struct ShareStatCard: Identifiable {
    let id: UUID
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let trend: TrendDirection?
    let trendValue: Double?
    let color: Color
    
    enum TrendDirection {
        case up
        case down
        case stable
    }
    
    init(
        title: String,
        value: String,
        subtitle: String = "",
        icon: String = "chart.bar",
        trend: TrendDirection? = nil,
        trendValue: Double? = nil,
        color: Color = .blue
    ) {
        self.id = UUID()
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.trendValue = trendValue
        self.color = color
    }
}

// MARK: - 平台使用详情

/// 平台使用详情
struct PlatformUsageDetail: Identifiable {
    let id: UUID
    let platform: SharePlatform
    let shareCount: Int
    let percentage: Double
    let lastUsed: Date?
    let favoriteTemplates: [String]
    let averageSharesPerWeek: Double
    
    init(
        platform: SharePlatform,
        shareCount: Int,
        percentage: Double = 0,
        lastUsed: Date? = nil,
        favoriteTemplates: [String] = [],
        averageSharesPerWeek: Double = 0
    ) {
        self.id = UUID()
        self.platform = platform
        self.shareCount = shareCount
        self.percentage = percentage
        self.lastUsed = lastUsed
        self.favoriteTemplates = favoriteTemplates
        self.averageSharesPerWeek = averageSharesPerWeek
    }
}
