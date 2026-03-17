//
//  DreamPatternPredictionModels.swift
//  DreamLog - Dream Pattern Prediction & Forecasting
//
//  Created by DreamLog AI on 2026/3/17.
//  Phase 55: Dream Pattern Prediction & Forecasting
//

import Foundation
import SwiftData

// MARK: - Dream Pattern Prediction Models

/// 梦境模式预测数据模型
@Model
final class DreamPatternPrediction {
    var id: UUID
    var createdAt: Date
    var predictionType: PredictionType
    var confidence: Double
    var timeRange: PredictionTimeRange
    var predictions: [PredictionData]
    var insights: [PredictionInsight]
    var suggestions: [PredictionSuggestion]
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        predictionType: PredictionType,
        confidence: Double,
        timeRange: PredictionTimeRange,
        predictions: [PredictionData],
        insights: [PredictionInsight],
        suggestions: [PredictionSuggestion]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.predictionType = predictionType
        self.confidence = confidence
        self.timeRange = timeRange
        self.predictions = predictions
        self.insights = insights
        self.suggestions = suggestions
    }
}

// MARK: - Prediction Types

enum PredictionType: String, Codable, CaseIterable {
    case theme = "theme"           // 主题预测
    case emotion = "emotion"       // 情绪预测
    case clarity = "clarity"       // 清晰度预测
    case lucid = "lucid"           // 清醒梦概率
    case recording = "recording"   // 最佳记录时间
    case pattern = "pattern"       // 模式识别
    
    var displayName: String {
        switch self {
        case .theme: return "梦境主题"
        case .emotion: return "情绪趋势"
        case .clarity: return "清晰度预测"
        case .lucid: return "清醒梦机会"
        case .recording: return "最佳记录时间"
        case .pattern: return "模式识别"
        }
    }
    
    var icon: String {
        switch self {
        case .theme: return "🔮"
        case .emotion: return "💖"
        case .clarity: return "✨"
        case .lucid: return "🌟"
        case .recording: return "⏰"
        case .pattern: return "📊"
        }
    }
}

// MARK: - Time Range

enum PredictionTimeRange: String, Codable, CaseIterable {
    case next24h = "next24h"       // 未来 24 小时
    case next3days = "next3days"   // 未来 3 天
    case next7days = "next7days"   // 未来 7 天
    case next14days = "next14days" // 未来 14 天
    case next30days = "next30days" // 未来 30 天
    
    var displayName: String {
        switch self {
        case .next24h: return "未来 24 小时"
        case .next3days: return "未来 3 天"
        case .next7days: return "未来 7 天"
        case .next14days: return "未来 14 天"
        case .next30days: return "未来 30 天"
        }
    }
    
    var days: Int {
        switch self {
        case .next24h: return 1
        case .next3days: return 3
        case .next7days: return 7
        case .next14days: return 14
        case .next30days: return 30
        }
    }
}

// MARK: - Prediction Data

struct PredictionData: Codable, Identifiable {
    var id: UUID
    var date: Date
    var type: PredictionType
    var value: String
    var confidence: Double
    var factors: [PredictionFactor]
    var description: String
    
    init(
        id: UUID = UUID(),
        date: Date,
        type: PredictionType,
        value: String,
        confidence: Double,
        factors: [PredictionFactor] = [],
        description: String
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.value = value
        self.confidence = confidence
        self.factors = factors
        self.description = description
    }
}

// MARK: - Prediction Factor

struct PredictionFactor: Codable, Identifiable {
    var id: UUID
    var name: String
    var influence: Double  // -1.0 to 1.0
    var description: String
    
    init(
        id: UUID = UUID(),
        name: String,
        influence: Double,
        description: String
    ) {
        self.id = id
        self.name = name
        self.influence = influence
        self.description = description
    }
}

// MARK: - Prediction Insight

struct PredictionInsight: Codable, Identifiable {
    var id: UUID
    var title: String
    var content: String
    var type: InsightType
    var priority: PriorityLevel
    var relatedTags: [String]
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        type: InsightType,
        priority: PriorityLevel = .medium,
        relatedTags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.priority = priority
        self.relatedTags = relatedTags
    }
}

enum InsightType: String, Codable, CaseIterable {
    case pattern = "pattern"           // 模式发现
    case trend = "trend"               // 趋势分析
    case anomaly = "anomaly"           // 异常检测
    case opportunity = "opportunity"   // 机会提示
    case warning = "warning"           // 注意事项
    case suggestion = "suggestion"     // 建议
    
    var displayName: String {
        switch self {
        case .pattern: return "模式发现"
        case .trend: return "趋势分析"
        case .anomaly: return "异常检测"
        case .opportunity: return "机会提示"
        case .warning: return "注意事项"
        case .suggestion: return "建议"
        }
    }
    
    var icon: String {
        switch self {
        case .pattern: return "🔍"
        case .trend: return "📈"
        case .anomaly: return "⚠️"
        case .opportunity: return "💡"
        case .warning: return "🚨"
        case .suggestion: return "💭"
        }
    }
}

enum PriorityLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "red"
        }
    }
}

// MARK: - Prediction Suggestion

struct PredictionSuggestion: Codable, Identifiable {
    var id: UUID
    var title: String
    var action: String
    var type: SuggestionType
    var expectedBenefit: String
    var difficulty: DifficultyLevel
    var estimatedTime: String
    
    init(
        id: UUID = UUID(),
        title: String,
        action: String,
        type: SuggestionType,
        expectedBenefit: String,
        difficulty: DifficultyLevel = .medium,
        estimatedTime: String = "5-10 分钟"
    ) {
        self.id = id
        self.title = title
        self.action = action
        self.type = type
        self.expectedBenefit = expectedBenefit
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
    }
}

enum SuggestionType: String, Codable, CaseIterable {
    case recording = "recording"       // 记录建议
    case meditation = "meditation"     // 冥想练习
    case sleep = "sleep"               // 睡眠改善
    case lucid = "lucid"               // 清醒梦训练
    case reflection = "reflection"     // 反思练习
    case lifestyle = "lifestyle"       // 生活方式
    
    var displayName: String {
        switch self {
        case .recording: return "记录建议"
        case .meditation: return "冥想练习"
        case .sleep: return "睡眠改善"
        case .lucid: return "清醒梦训练"
        case .reflection: return "反思练习"
        case .lifestyle: return "生活方式"
        }
    }
    
    var icon: String {
        switch self {
        case .recording: return "📝"
        case .meditation: return "🧘"
        case .sleep: return "🌙"
        case .lucid: return "✨"
        case .reflection: return "💭"
        case .lifestyle: return "🌱"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
}

// MARK: - Pattern Statistics

struct PatternStatistics: Codable {
    var totalDreams: Int
    var averageClarity: Double
    var averageIntensity: Double
    var lucidDreamPercentage: Double
    var mostCommonEmotions: [String: Int]
    var mostCommonTags: [String: Int]
    var recordingStreak: Int
    var bestRecordingTime: String
    var weeklyTrend: TrendDirection
    var monthlyTrend: TrendDirection
    
    init(
        totalDreams: Int = 0,
        averageClarity: Double = 0,
        averageIntensity: Double = 0,
        lucidDreamPercentage: Double = 0,
        mostCommonEmotions: [String: Int] = [:],
        mostCommonTags: [String: Int] = [:],
        recordingStreak: Int = 0,
        bestRecordingTime: String = "早晨",
        weeklyTrend: TrendDirection = .stable,
        monthlyTrend: TrendDirection = .stable
    ) {
        self.totalDreams = totalDreams
        self.averageClarity = averageClarity
        self.averageIntensity = averageIntensity
        self.lucidDreamPercentage = lucidDreamPercentage
        self.mostCommonEmotions = mostCommonEmotions
        self.mostCommonTags = mostCommonTags
        self.recordingStreak = recordingStreak
        self.bestRecordingTime = bestRecordingTime
        self.weeklyTrend = weeklyTrend
        self.monthlyTrend = monthlyTrend
    }
}

enum TrendDirection: String, Codable, CaseIterable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"
    case fluctuating = "fluctuating"
    
    var displayName: String {
        switch self {
        case .increasing: return "上升"
        case .decreasing: return "下降"
        case .stable: return "稳定"
        case .fluctuating: return "波动"
        }
    }
    
    var icon: String {
        switch self {
        case .increasing: return "📈"
        case .decreasing: return "📉"
        case .stable: return "➡️"
        case .fluctuating: return "〰️"
        }
    }
}

// MARK: - Prediction Request

struct PredictionRequest: Codable {
    var timeRange: PredictionTimeRange
    var predictionTypes: [PredictionType]
    var includeInsights: Bool
    var includeSuggestions: Bool
    var minConfidence: Double
    
    init(
        timeRange: PredictionTimeRange = .next7days,
        predictionTypes: [PredictionType] = [.theme, .emotion, .clarity, .lucid],
        includeInsights: Bool = true,
        includeSuggestions: Bool = true,
        minConfidence: Double = 0.5
    ) {
        self.timeRange = timeRange
        self.predictionTypes = predictionTypes
        self.includeInsights = includeInsights
        self.includeSuggestions = includeSuggestions
        self.minConfidence = minConfidence
    }
}

// MARK: - Prediction Response

struct PredictionResponse: Codable {
    var prediction: DreamPatternPrediction
    var statistics: PatternStatistics
    var generatedAt: Date
    var validUntil: Date
    var dataQuality: DataQualityScore
    
    init(
        prediction: DreamPatternPrediction,
        statistics: PatternStatistics,
        generatedAt: Date = Date(),
        validUntil: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
        dataQuality: DataQualityScore
    ) {
        self.prediction = prediction
        self.statistics = statistics
        self.generatedAt = generatedAt
        self.validUntil = validUntil
        self.dataQuality = dataQuality
    }
}

enum DataQualityScore: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case insufficient = "insufficient"
    
    var displayName: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .poor: return "较差"
        case .insufficient: return "数据不足"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "数据充足，预测可靠度高"
        case .good: return "数据较好，预测可靠度中等"
        case .fair: return "数据一般，预测仅供参考"
        case .poor: return "数据较少，预测可靠度低"
        case .insufficient: return "数据不足，无法生成预测"
        }
    }
    
    var minDreams: Int {
        switch self {
        case .excellent: return 50
        case .good: return 30
        case .fair: return 15
        case .poor: return 7
        case .insufficient: return 0
        }
    }
}
