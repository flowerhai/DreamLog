//
//  DreamYearInReviewModels.swift
//  DreamLog - 梦境年度回顾数据模型
//  Phase 63: Dream Year in Review (梦境年度回顾)
//
//  Created by DreamLog Team on 2026-03-18.
//

import Foundation
import SwiftData

// MARK: - 年度回顾主模型

@Model
final class DreamYearInReview {
    var id: UUID
    var year: Int
    var createdAt: Date
    var updatedAt: Date
    
    // 基础统计
    var totalDreams: Int
    var lucidDreams: Int
    var averageClarity: Double
    var averageIntensity: Double
    var totalDreamTime: TimeInterval  // 总梦境时长（分钟）
    
    // 连续记录
    var longestStreak: Int
    var currentStreak: Int
    var totalRecordDays: Int
    
    // 情绪统计
    var topEmotion: String
    var emotionDistribution: [String: Int]
    
    // 标签统计
    var topTags: [String]
    var tagCloud: [String: Int]
    
    // 时间模式
    var bestDayOfWeek: String
    var bestTimeOfDay: String
    var dreamsByMonth: [Int: Int]  // 月份 -> 梦境数
    
    // 亮点梦境
    var highlightDreamIds: [UUID]
    var clearestDreamId: UUID?
    var mostLucidMonth: Int
    
    // AI 洞察
    var aiInsights: [YearInReviewInsight]
    var yearTheme: String
    var yearKeyword: String
    
    // 分享配置
    var isShareable: Bool
    var shareCardIds: [UUID]
    
    // MARK: - 初始化
    
    init(
        year: Int,
        totalDreams: Int = 0,
        lucidDreams: Int = 0,
        averageClarity: Double = 0,
        averageIntensity: Double = 0,
        totalDreamTime: TimeInterval = 0,
        longestStreak: Int = 0,
        currentStreak: Int = 0,
        totalRecordDays: Int = 0,
        topEmotion: String = "",
        emotionDistribution: [String: Int] = [:],
        topTags: [String] = [],
        tagCloud: [String: Int] = [:],
        bestDayOfWeek: String = "",
        bestTimeOfDay: String = "",
        dreamsByMonth: [Int: Int] = [:],
        highlightDreamIds: [UUID] = [],
        clearestDreamId: UUID? = nil,
        mostLucidMonth: Int = 1,
        aiInsights: [YearInReviewInsight] = [],
        yearTheme: String = "",
        yearKeyword: String = "",
        isShareable: true,
        shareCardIds: [UUID] = []
    ) {
        self.id = UUID()
        self.year = year
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalDreams = totalDreams
        self.lucidDreams = lucidDreams
        self.averageClarity = averageClarity
        self.averageIntensity = averageIntensity
        self.totalDreamTime = totalDreamTime
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.totalRecordDays = totalRecordDays
        self.topEmotion = topEmotion
        self.emotionDistribution = emotionDistribution
        self.topTags = topTags
        self.tagCloud = tagCloud
        self.bestDayOfWeek = bestDayOfWeek
        self.bestTimeOfDay = bestTimeOfDay
        self.dreamsByMonth = dreamsByMonth
        self.highlightDreamIds = highlightDreamIds
        self.clearestDreamId = clearestDreamId
        self.mostLucidMonth = mostLucidMonth
        self.aiInsights = aiInsights
        self.yearTheme = yearTheme
        self.yearKeyword = yearKeyword
        self.isShareable = isShareable
        self.shareCardIds = shareCardIds
    }
}

// MARK: - AI 洞察模型

struct YearInReviewInsight: Codable, Identifiable, Hashable {
    var id: UUID
    var type: InsightType
    var title: String
    var description: String
    var icon: String
    var confidence: Double  // 0-1
    var relatedTags: [String]
    var actionSuggestion: String?
    
    enum InsightType: String, Codable, CaseIterable {
        case pattern = "pattern"          // 模式发现
        case trend = "trend"              // 趋势分析
        case achievement = "achievement"  // 成就认可
        case suggestion = "suggestion"    // 改进建议
        case prediction = "prediction"    // 未来预测
        case curiosity = "curiosity"      // 有趣发现
    }
    
    init(
        type: InsightType,
        title: String,
        description: String,
        icon: String,
        confidence: Double = 0.8,
        relatedTags: [String] = [],
        actionSuggestion: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.icon = icon
        self.confidence = confidence
        self.relatedTags = relatedTags
        self.actionSuggestion = actionSuggestion
    }
}

// MARK: - 月度回顾模型

@Model
final class DreamMonthInReview {
    var id: UUID
    var year: Int
    var month: Int
    var createdAt: Date
    
    var totalDreams: Int
    var lucidDreams: Int
    var averageClarity: Double
    var topEmotion: String
    var topTags: [String]
    var highlightDreamId: UUID?
    
    init(
        year: Int,
        month: Int,
        totalDreams: Int = 0,
        lucidDreams: Int = 0,
        averageClarity: Double = 0,
        topEmotion: String = "",
        topTags: [String] = [],
        highlightDreamId: UUID? = nil
    ) {
        self.id = UUID()
        self.year = year
        self.month = month
        self.createdAt = Date()
        self.totalDreams = totalDreams
        self.lucidDreams = lucidDreams
        self.averageClarity = averageClarity
        self.topEmotion = topEmotion
        self.topTags = topTags
        self.highlightDreamId = highlightDreamId
    }
}

// MARK: - 分享卡片模型

@Model
final class YearInReviewShareCard {
    var id: UUID
    var year: Int
    var cardType: CardType
    var createdAt: Date
    
    // 卡片内容
    var title: String
    var subtitle: String
    var mainValue: String
    var description: String
    var backgroundImage: String  // 渐变主题名称
    var decorations: [String]    // 装饰元素
    
    // 分享统计
    var shareCount: Int
    var lastSharedAt: Date?
    
    enum CardType: String, Codable, CaseIterable {
        case overview = "overview"          // 总览卡片
        case emotion = "emotion"            // 情绪之旅
        case tags = "tags"                  // 热门标签
        case lucid = "lucid"                // 清醒梦探索
        case streak = "streak"              // 连续记录
        case highlight = "highlight"        // 最佳梦境
        case monthly = "monthly"            // 月度分布
        case insight = "insight"            // AI 洞察
        case theme = "theme"                // 年度主题
        case prediction = "prediction"      // 新年预测
    }
    
    init(
        year: Int,
        cardType: CardType,
        title: String,
        subtitle: String,
        mainValue: String,
        description: String,
        backgroundImage: String = "starry",
        decorations: [String] = [],
        shareCount: Int = 0
    ) {
        self.id = UUID()
        self.year = year
        self.cardType = cardType
        self.createdAt = Date()
        self.title = title
        self.subtitle = subtitle
        self.mainValue = mainValue
        self.description = description
        self.backgroundImage = backgroundImage
        self.decorations = decorations
        self.shareCount = shareCount
    }
}

// MARK: - 年度对比模型

struct YearComparison: Codable, Hashable {
    var currentYear: Int
    var previousYear: Int?
    
    var dreamsChange: Double  // 百分比变化
    var lucidChange: Double
    var clarityChange: Double
    var streakChange: Double
    
    var improvedAreas: [String]
    var areasToFocus: [String]
    
    init(
        currentYear: Int,
        previousYear: Int? = nil,
        dreamsChange: Double = 0,
        lucidChange: Double = 0,
        clarityChange: Double = 0,
        streakChange: Double = 0,
        improvedAreas: [String] = [],
        areasToFocus: [String] = []
    ) {
        self.currentYear = currentYear
        self.previousYear = previousYear
        self.dreamsChange = dreamsChange
        self.lucidChange = lucidChange
        self.clarityChange = clarityChange
        self.streakChange = streakChange
        self.improvedAreas = improvedAreas
        self.areasToFocus = areasToFocus
    }
}

// MARK: - 配置模型

struct YearInReviewConfig: Codable {
    var enabled: Bool
    var autoGenerate: Bool  // 每年自动生成
    var generateDate: Date  // 生成日期（默认 1 月 1 日）
    var reminderEnabled: Bool
    var reminderDate: Date?  // 提醒日期
    var shareEnabled: Bool
    var defaultTheme: String
    
    static var `default`: YearInReviewConfig {
        YearInReviewConfig(
            enabled: true,
            autoGenerate: true,
            generateDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date(),
            reminderEnabled: true,
            reminderDate: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 10)) ?? Date(),
            shareEnabled: true,
            defaultTheme: "starry"
        )
    }
}

// MARK: - 扩展

extension YearInReviewInsight.InsightType {
    var displayName: String {
        switch self {
        case .pattern: return "模式发现"
        case .trend: return "趋势分析"
        case .achievement: return "成就认可"
        case .suggestion: return "改进建议"
        case .prediction: return "未来预测"
        case .curiosity: return "有趣发现"
        }
    }
    
    var icon: String {
        switch self {
        case .pattern: return "🔍"
        case .trend: return "📈"
        case .achievement: return "🏆"
        case .suggestion: return "💡"
        case .prediction: return "🔮"
        case .curiosity: return "✨"
        }
    }
}

extension YearInReviewShareCard.CardType {
    var displayName: String {
        switch self {
        case .overview: return "年度总览"
        case .emotion: return "情绪之旅"
        case .tags: return "热门标签"
        case .lucid: return "清醒梦探索"
        case .streak: return "连续记录"
        case .highlight: return "最佳梦境"
        case .monthly: return "月度分布"
        case .insight: return "AI 洞察"
        case .theme: return "年度主题"
        case .prediction: return "新年预测"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "📊"
        case .emotion: return "💖"
        case .tags: return "🏷️"
        case .lucid: return "👁️"
        case .streak: return "🔥"
        case .highlight: return "⭐"
        case .monthly: return "📅"
        case .insight: return "🧠"
        case .theme: return "🎨"
        case .prediction: return "🔮"
        }
    }
}
