//
//  DreamWellnessScoreModels.swift
//  DreamLog
//
//  Phase 100: 梦境健康评分与预测引擎
//  健康评分数据模型
//

import Foundation
import SwiftData

// MARK: - 健康评分主模型

@Model
final class DreamWellnessScore {
    var id: UUID
    var date: Date
    var overallScore: Double           // 综合评分 0-100
    var sleepQualityScore: Double      // 睡眠质量分 0-100
    var dreamRecallScore: Double       // 梦境回忆分 0-100
    var emotionalHealthScore: Double   // 情绪健康分 0-100
    var patternHealthScore: Double     // 模式健康分 0-100
    var scoreLevel: ScoreLevel         // 评分等级
    var trend: ScoreTrend              // 趋势 (上升/下降/稳定)
    var insights: [String]             // 评分洞察
    var recommendations: [String]      // 改进建议
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        overallScore: Double,
        sleepQualityScore: Double,
        dreamRecallScore: Double,
        emotionalHealthScore: Double,
        patternHealthScore: Double,
        scoreLevel: ScoreLevel,
        trend: ScoreTrend = .stable,
        insights: [String] = [],
        recommendations: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.overallScore = overallScore
        self.sleepQualityScore = sleepQualityScore
        self.dreamRecallScore = dreamRecallScore
        self.emotionalHealthScore = emotionalHealthScore
        self.patternHealthScore = patternHealthScore
        self.scoreLevel = scoreLevel
        self.trend = trend
        self.insights = insights
        self.recommendations = recommendations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 评分等级

enum ScoreLevel: String, Codable, CaseIterable {
    case excellent = "优秀"      // 90-100
    case good = "良好"           // 70-89
    case fair = "一般"           // 50-69
    case needsAttention = "需关注" // 30-49
    case needsImprovement = "需改善" // <30
    
    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "💚"
        case .fair: return "💛"
        case .needsAttention: return "🧡"
        case .needsImprovement: return "❤️"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "teal"
        case .fair: return "yellow"
        case .needsAttention: return "orange"
        case .needsImprovement: return "red"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "非常健康的梦境模式"
        case .good: return "健康的梦境习惯"
        case .fair: return "有改善空间"
        case .needsAttention: return "建议调整习惯"
        case .needsImprovement: return "建议寻求专业建议"
        }
    }
    
    static func from(score: Double) -> ScoreLevel {
        switch score {
        case 90...100: return .excellent
        case 70..<90: return .good
        case 50..<70: return .fair
        case 30..<50: return .needsAttention
        default: return .needsImprovement
        }
    }
}

// MARK: - 评分趋势

enum ScoreTrend: String, Codable, CaseIterable {
    case rising = "上升"
    case falling = "下降"
    case stable = "稳定"
    
    var emoji: String {
        switch self {
        case .rising: return "📈"
        case .falling: return "📉"
        case .stable: return "➡️"
        }
    }
    
    var color: String {
        switch self {
        case .rising: return "green"
        case .falling: return "red"
        case .stable: return "gray"
        }
    }
}

// MARK: - 评分维度详情

struct ScoreDimension: Identifiable, Codable {
    let id: UUID
    let name: String
    let score: Double
    let weight: Double
    var insights: [String]
    var recommendations: [String]
    var trend: ScoreTrend
    var history: [Double]  // 最近 7 天评分
    
    init(
        id: UUID = UUID(),
        name: String,
        score: Double,
        weight: Double,
        insights: [String] = [],
        recommendations: [String] = [],
        trend: ScoreTrend = .stable,
        history: [Double] = []
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.weight = weight
        self.insights = insights
        self.recommendations = recommendations
        self.trend = trend
        self.history = history
    }
}

// MARK: - 预测数据模型

@Model
final class DreamPrediction {
    var id: UUID
    var date: Date
    var predictionType: PredictionType
    var predictedContent: String
    var confidence: Double           // 置信度 0-100
    var confidenceLevel: ConfidenceLevel
    var basis: [String]              // 预测依据
    var recommendations: [String]    // 相关建议
    var validFrom: Date
    var validUntil: Date
    var isAccurate: Bool?            // 预测是否准确 (事后评估)
    var actualOutcome: String?       // 实际结果
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        predictionType: PredictionType,
        predictedContent: String,
        confidence: Double,
        basis: [String] = [],
        recommendations: [String] = [],
        validFrom: Date = Date(),
        validUntil: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
        isAccurate: Bool? = nil,
        actualOutcome: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.predictionType = predictionType
        self.predictedContent = predictedContent
        self.confidence = confidence
        self.confidenceLevel = ConfidenceLevel.from(confidence: confidence)
        self.basis = basis
        self.recommendations = recommendations
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.isAccurate = isAccurate
        self.actualOutcome = actualOutcome
        self.createdAt = createdAt
    }
}

// MARK: - 预测类型

enum PredictionType: String, Codable, CaseIterable {
    case dreamTheme = "梦境主题"
    case emotionalTrend = "情绪趋势"
    case lucidDreamProbability = "清醒梦概率"
    case optimalRecordTime = "最佳记录时间"
    case sleepQuality = "睡眠质量"
    case dreamFrequency = "梦境频率"
    
    var emoji: String {
        switch self {
        case .dreamTheme: return "🎭"
        case .emotionalTrend: return "💭"
        case .lucidDreamProbability: return "👁️"
        case .optimalRecordTime: return "⏰"
        case .sleepQuality: return "😴"
        case .dreamFrequency: return "📊"
        }
    }
    
    var description: String {
        switch self {
        case .dreamTheme: return "预测可能出现的梦境主题"
        case .emotionalTrend: return "预测情绪走向"
        case .lucidDreamProbability: return "预测清醒梦可能性"
        case .optimalRecordTime: return "推荐最佳记录时间"
        case .sleepQuality: return "预测睡眠质量"
        case .dreamFrequency: return "预测梦境频率"
        }
    }
}

// MARK: - 置信度等级

enum ConfidenceLevel: String, Codable, CaseIterable {
    case high = "高"      // 80%+
    case medium = "中"    // 60-79%
    case low = "低"       // <60%
    
    var description: String {
        switch self {
        case .high: return "强烈建议参考"
        case .medium: return "有参考价值"
        case .low: return "仅供参考"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "yellow"
        case .low: return "red"
        }
    }
    
    static func from(confidence: Double) -> ConfidenceLevel {
        switch confidence {
        case 80...100: return .high
        case 60..<80: return .medium
        default: return .low
        }
    }
}

// MARK: - 预测主题

struct PredictedTheme: Identifiable, Codable {
    let id: UUID
    let theme: String
    let probability: Double
    let category: ThemeCategory
    let relatedSymbols: [String]
    let relatedEmotions: [String]
    let basis: String
    
    init(
        id: UUID = UUID(),
        theme: String,
        probability: Double,
        category: ThemeCategory,
        relatedSymbols: [String] = [],
        relatedEmotions: [String] = [],
        basis: String
    ) {
        self.id = id
        self.theme = theme
        self.probability = probability
        self.category = category
        self.relatedSymbols = relatedSymbols
        self.relatedEmotions = relatedEmotions
        self.basis = basis
    }
}

// MARK: - 主题分类

enum ThemeCategory: String, Codable, CaseIterable {
    case adventure = "冒险"
    case romance = "浪漫"
    case fear = "恐惧"
    case success = "成功"
    case failure = "失败"
    case flying = "飞行"
    case falling = "坠落"
    case water = "水"
    case nature = "自然"
    case urban = "城市"
    case fantasy = "奇幻"
    case reality = "现实"
    
    var emoji: String {
        switch self {
        case .adventure: return "🗺️"
        case .romance: return "💕"
        case .fear: return "😨"
        case .success: return "🏆"
        case .failure: return "💔"
        case .flying: return "🦅"
        case .falling: return "🍂"
        case .water: return "🌊"
        case .nature: return "🌲"
        case .urban: return "🏙️"
        case .fantasy: return "🦄"
        case .reality: return "🏠"
        }
    }
}

// MARK: - 情绪趋势

struct EmotionalTrend: Identifiable, Codable {
    let id: UUID
    let currentEmotion: String
    let predictedEmotion: String
    let trend: TrendDirection
    let intensity: Double
    let confidence: Double
    let factors: [String]
    let recommendations: [String]
    
    init(
        id: UUID = UUID(),
        currentEmotion: String,
        predictedEmotion: String,
        trend: TrendDirection,
        intensity: Double,
        confidence: Double,
        factors: [String] = [],
        recommendations: [String] = []
    ) {
        self.id = id
        self.currentEmotion = currentEmotion
        self.predictedEmotion = predictedEmotion
        self.trend = trend
        self.intensity = intensity
        self.confidence = confidence
        self.factors = factors
        self.recommendations = recommendations
    }
}

// MARK: - 趋势方向

enum TrendDirection: String, Codable, CaseIterable {
    case improving = "改善"
    case declining = "下降"
    case stable = "稳定"
    case fluctuating = "波动"
}

// MARK: - 时间范围

struct TimeRange: Identifiable, Codable {
    let id: UUID
    let startHour: Int
    let endHour: Int
    let quality: Double
    let basis: String
    
    init(
        id: UUID = UUID(),
        startHour: Int,
        endHour: Int,
        quality: Double,
        basis: String
    ) {
        self.id = id
        self.startHour = startHour
        self.endHour = endHour
        self.quality = quality
        self.basis = basis
    }
    
    var displayString: String {
        "\(String(format: "%02d", startHour)):00 - \(String(format: "%02d", endHour)):00"
    }
}

// MARK: - 健康报告模型

@Model
final class DreamWellnessReport {
    var id: UUID
    var reportType: ReportType
    var periodStart: Date
    var periodEnd: Date
    var overallScore: Double
    var averageScores: [String: Double]  // 各维度平均分
    var trend: ScoreTrend
    var highlights: [String]             // 亮点时刻
    var concerns: [String]               // 需关注的问题
    var recommendations: [String]        // 改进建议
    var predictions: [String]            // 预测展望
    var achievements: [String]           // 解锁成就
    var charts: [ReportChart]            // 图表数据
    var isGenerated: Bool
    var isSent: Bool
    var sentAt: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        reportType: ReportType,
        periodStart: Date,
        periodEnd: Date,
        overallScore: Double,
        averageScores: [String: Double] = [:],
        trend: ScoreTrend = .stable,
        highlights: [String] = [],
        concerns: [String] = [],
        recommendations: [String] = [],
        predictions: [String] = [],
        achievements: [String] = [],
        charts: [ReportChart] = [],
        isGenerated: Bool = false,
        isSent: Bool = false,
        sentAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reportType = reportType
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.overallScore = overallScore
        self.averageScores = averageScores
        self.trend = trend
        self.highlights = highlights
        self.concerns = concerns
        self.recommendations = recommendations
        self.predictions = predictions
        self.achievements = achievements
        self.charts = charts
        self.isGenerated = isGenerated
        self.isSent = isSent
        self.sentAt = sentAt
        self.createdAt = createdAt
    }
}

// MARK: - 报告类型

enum ReportType: String, Codable, CaseIterable {
    case daily = "日报"
    case weekly = "周报"
    case monthly = "月报"
    case quarterly = "季报"
    case yearly = "年报"
    
    var emoji: String {
        switch self {
        case .daily: return "📅"
        case .weekly: return "📆"
        case .monthly: return "🗓️"
        case .quarterly: return "📊"
        case .yearly: return "📈"
        }
    }
}

// MARK: - 报告图表

struct ReportChart: Identifiable, Codable {
    let id: UUID
    let chartType: ChartType
    let title: String
    let data: [ChartPoint]
    let metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        chartType: ChartType,
        title: String,
        data: [ChartPoint],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.chartType = chartType
        self.title = title
        self.data = data
        self.metadata = metadata
    }
}

// MARK: - 图表类型

enum ChartType: String, Codable, CaseIterable {
    case line = "折线图"
    case bar = "柱状图"
    case pie = "饼图"
    case radar = "雷达图"
    case heatmap = "热力图"
}

// MARK: - 图表数据点

struct ChartPoint: Identifiable, Codable {
    let id: UUID
    let label: String
    let value: Double
    let secondaryValue: Double?
    let metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        label: String,
        value: Double,
        secondaryValue: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.secondaryValue = secondaryValue
        self.metadata = metadata
    }
}

// MARK: - 推荐模型

@Model
final class DreamRecommendation {
    var id: UUID
    var recommendationType: RecommendationType
    var title: String
    var description: String
    var action: String                    // 可执行的动作
    var priority: Priority
    var relevanceScore: Double            // 相关度评分 0-100
    var basis: [String]                   // 推荐依据
    var estimatedImpact: String           // 预期效果
    var isCompleted: Bool
    var completedAt: Date?
    var isDismissed: Bool
    var dismissedAt: Date?
    var validFrom: Date
    var validUntil: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        recommendationType: RecommendationType,
        title: String,
        description: String,
        action: String,
        priority: Priority,
        relevanceScore: Double,
        basis: [String] = [],
        estimatedImpact: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        isDismissed: Bool = false,
        dismissedAt: Date? = nil,
        validFrom: Date = Date(),
        validUntil: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.recommendationType = recommendationType
        self.title = title
        self.description = description
        self.action = action
        self.priority = priority
        self.relevanceScore = relevanceScore
        self.basis = basis
        self.estimatedImpact = estimatedImpact
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isDismissed = isDismissed
        self.dismissedAt = dismissedAt
        self.validFrom = validFrom
        self.validUntil = validUntil
        self.createdAt = createdAt
    }
}

// MARK: - 推荐类型

enum RecommendationType: String, Codable, CaseIterable {
    case sleepImprovement = "睡眠改善"
    case dreamRecording = "梦境记录"
    case meditation = "冥想练习"
    case lucidDreamTraining = "清醒梦训练"
    case creativeInspiration = "创意启发"
    case stressRelief = "压力缓解"
    case habitBuilding = "习惯养成"
    case healthWarning = "健康警告"
    
    var emoji: String {
        switch self {
        case .sleepImprovement: return "😴"
        case .dreamRecording: return "📝"
        case .meditation: return "🧘"
        case .lucidDreamTraining: return "👁️"
        case .creativeInspiration: return "💡"
        case .stressRelief: return "🌿"
        case .habitBuilding: return "💪"
        case .healthWarning: return "⚠️"
        }
    }
}

// MARK: - 优先级

enum Priority: String, Codable, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    case urgent = "紧急"
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var emoji: String {
        switch self {
        case .low: return "⚪"
        case .medium: return "🔵"
        case .high: return "🟠"
        case .urgent: return "🔴"
        }
    }
}
