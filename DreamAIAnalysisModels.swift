//
//  DreamAIAnalysisModels.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  数据模型层 - 定义 AI 解析的核心数据结构
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - 主要解析模型

/// AI 梦境解析结果
@Model
public final class DreamAnalysis {
    /// 唯一标识符
    public var id: UUID
    /// 关联的梦境 ID
    public var dreamId: UUID
    /// 解析创建时间
    public var createdAt: Date
    /// 解析更新时间
    public var updatedAt: Date
    /// 解析版本
    public var version: String
    
    // 三层级解读
    /// 表面层解读
    public var surfaceLayer: AnalysisLayerContent
    /// 心理层解读
    public var psychologicalLayer: AnalysisLayerContent
    /// 精神层解读
    public var spiritualLayer: AnalysisLayerContent
    
    // 符号解析
    /// 识别的符号列表
    public var symbols: [DreamSymbolAnalysis]
    
    // 模式识别
    /// 识别的模式列表
    public var patterns: [DreamPattern]
    
    // 趋势分析
    /// 趋势预测
    public var trendPrediction: TrendPrediction?
    
    // 个性化洞察
    /// 洞察列表
    public var insights: [DreamInsight]
    
    // 行动建议
    /// 建议列表
    public var suggestions: [ActionSuggestion]
    
    // 元数据
    /// 解析置信度 (0-1)
    public var confidence: Double
    /// 使用的模型版本
    public var modelVersion: String
    /// 解析语言
    public var language: String
    
    public init(
        dreamId: UUID,
        surfaceLayer: AnalysisLayerContent,
        psychologicalLayer: AnalysisLayerContent,
        spiritualLayer: AnalysisLayerContent,
        symbols: [DreamSymbolAnalysis] = [],
        patterns: [DreamPattern] = [],
        trendPrediction: TrendPrediction? = nil,
        insights: [DreamInsight] = [],
        suggestions: [ActionSuggestion] = [],
        confidence: Double = 0.8,
        modelVersion: String = "1.0",
        language: String = "zh-CN"
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = "1.0"
        self.surfaceLayer = surfaceLayer
        self.psychologicalLayer = psychologicalLayer
        self.spiritualLayer = spiritualLayer
        self.symbols = symbols
        self.patterns = patterns
        self.trendPrediction = trendPrediction
        self.insights = insights
        self.suggestions = suggestions
        self.confidence = confidence
        self.modelVersion = modelVersion
        self.language = language
    }
}

// MARK: - 解读层级内容

/// 解读层级内容
public struct AnalysisLayerContent: Codable {
    /// 层级类型
    public var layerType: AnalysisLayer
    /// 标题
    public var title: String
    /// 主要解读内容
    public var interpretation: String
    /// 关键点列表
    public var keyPoints: [String]
    /// 相关引用（理论/研究）
    public var references: [String]
    /// 情绪基调
    public var emotionalTone: String
    
    public init(
        layerType: AnalysisLayer,
        title: String,
        interpretation: String,
        keyPoints: [String] = [],
        references: [String] = [],
        emotionalTone: String = "neutral"
    ) {
        self.layerType = layerType
        self.title = title
        self.interpretation = interpretation
        self.keyPoints = keyPoints
        self.references = references
        self.emotionalTone = emotionalTone
    }
}

/// 解读层级枚举
public enum AnalysisLayer: String, Codable, CaseIterable {
    case surface = "surface"        // 表面层 - 字面含义
    case psychological = "psychological"  // 心理层 - 心理学解读
    case spiritual = "spiritual"    // 精神层 - 精神成长
    
    public var displayName: String {
        switch self {
        case .surface: return "表面解读"
        case .psychological: return "心理分析"
        case .spiritual: return "精神启示"
        }
    }
    
    public var description: String {
        switch self {
        case .surface: return "梦境内容的直接描述和字面含义"
        case .psychological: return "从心理学视角探索潜意识的信息"
        case .spiritual: return "精神成长和自我发现的启示"
        }
    }
    
    public var icon: String {
        switch self {
        case .surface: return "📖"
        case .psychological: return "🧠"
        case .spiritual: return "✨"
        }
    }
}

// MARK: - 梦境符号分析

/// 梦境符号分析
public struct DreamSymbolAnalysis: Codable, Identifiable {
    public var id: UUID
    /// 符号名称
    public var symbolName: String
    /// 符号类别
    public var category: SymbolCategory
    /// 在梦境中的上下文
    public var context: String
    /// 表面层解读
    public var surfaceMeaning: String
    /// 心理层解读
    public var psychologicalMeaning: String
    /// 精神层解读
    public var spiritualMeaning: String
    /// 文化背景解读
    public var culturalInterpretations: [CulturalInterpretation]
    /// 相关符号
    public var relatedSymbols: [String]
    /// 出现频率（用户历史中）
    public var frequency: Int
    /// 情绪关联
    public var emotionalAssociations: [String]
    /// 置信度
    public var confidence: Double
    
    public init(
        symbolName: String,
        category: SymbolCategory,
        context: String,
        surfaceMeaning: String,
        psychologicalMeaning: String,
        spiritualMeaning: String,
        culturalInterpretations: [CulturalInterpretation] = [],
        relatedSymbols: [String] = [],
        frequency: Int = 1,
        emotionalAssociations: [String] = [],
        confidence: Double = 0.8
    ) {
        self.id = UUID()
        self.symbolName = symbolName
        self.category = category
        self.context = context
        self.surfaceMeaning = surfaceMeaning
        self.psychologicalMeaning = psychologicalMeaning
        self.spiritualMeaning = spiritualMeaning
        self.culturalInterpretations = culturalInterpretations
        self.relatedSymbols = relatedSymbols
        self.frequency = frequency
        self.emotionalAssociations = emotionalAssociations
        self.confidence = confidence
    }
}

/// 符号类别
public enum SymbolCategory: String, Codable, CaseIterable {
    case person = "person"          // 人物
    case place = "place"            // 地点
    case object = "object"          // 物体
    case action = "action"          // 动作
    case situation = "situation"    // 情境
    case animal = "animal"          // 动物
    case nature = "nature"          // 自然元素
    case abstract = "abstract"      // 抽象概念
    
    public var displayName: String {
        switch self {
        case .person: return "人物"
        case .place: return "地点"
        case .object: return "物体"
        case .action: return "动作"
        case .situation: return "情境"
        case .animal: return "动物"
        case .nature: return "自然"
        case .abstract: return "抽象"
        }
    }
    
    public var icon: String {
        switch self {
        case .person: return "👤"
        case .place: return "🏠"
        case .object: return "🎯"
        case .action: return "🏃"
        case .situation: return "🎭"
        case .animal: return "🐾"
        case .nature: return "🌿"
        case .abstract: return "💭"
        }
    }
}

/// 文化背景解读
public struct CulturalInterpretation: Codable {
    /// 文化名称
    public var culture: String
    /// 解读内容
    public var interpretation: String
    /// 来源/参考
    public var source: String
    
    public init(culture: String, interpretation: String, source: String = "") {
        self.culture = culture
        self.interpretation = interpretation
        self.source = source
    }
}

// MARK: - 梦境模式

/// 梦境模式
public struct DreamPattern: Codable, Identifiable {
    public var id: UUID
    /// 模式类型
    public var patternType: PatternType
    /// 模式名称
    public var name: String
    /// 模式描述
    public var description: String
    /// 相关梦境 ID 列表
    public var relatedDreamIds: [UUID]
    /// 出现次数
    public var occurrenceCount: Int
    /// 首次出现时间
    public var firstOccurrence: Date
    /// 最近出现时间
    public var lastOccurrence: Date
    /// 模式强度 (0-1)
    public var strength: Double
    /// 变化趋势
    public var trend: PatternTrend
    
    public init(
        patternType: PatternType,
        name: String,
        description: String,
        relatedDreamIds: [UUID],
        occurrenceCount: Int,
        firstOccurrence: Date,
        lastOccurrence: Date,
        strength: Double,
        trend: PatternTrend
    ) {
        self.id = UUID()
        self.patternType = patternType
        self.name = name
        self.description = description
        self.relatedDreamIds = relatedDreamIds
        self.occurrenceCount = occurrenceCount
        self.firstOccurrence = firstOccurrence
        self.lastOccurrence = lastOccurrence
        self.strength = strength
        self.trend = trend
    }
}

/// 模式类型
public enum PatternType: String, Codable, CaseIterable {
    case recurringSymbol = "recurringSymbol"      // 重复符号
    case recurringTheme = "recurringTheme"        // 重复主题
    case emotionalPattern = "emotionalPattern"    // 情绪模式
    case temporalPattern = "temporalPattern"      // 时间模式
    case lucidPattern = "lucidPattern"            // 清醒梦模式
    case intensityPattern = "intensityPattern"    // 强度模式
    
    public var displayName: String {
        switch self {
        case .recurringSymbol: return "重复符号"
        case .recurringTheme: return "重复主题"
        case .emotionalPattern: return "情绪模式"
        case .temporalPattern: return "时间模式"
        case .lucidPattern: return "清醒梦模式"
        case .intensityPattern: return "强度模式"
        }
    }
}

/// 模式趋势
public enum PatternTrend: String, Codable {
    case increasing = "increasing"  // 增强
    case decreasing = "decreasing"  // 减弱
    case stable = "stable"          // 稳定
    case fluctuating = "fluctuating" // 波动
    
    public var displayName: String {
        switch self {
        case .increasing: return "增强 ↑"
        case .decreasing: return "减弱 ↓"
        case .stable: return "稳定 →"
        case .fluctuating: return "波动 ~"
        }
    }
    
    public var icon: String {
        switch self {
        case .increasing: return "📈"
        case .decreasing: return "📉"
        case .stable: return "➡️"
        case .fluctuating: return "〰️"
        }
    }
}

// MARK: - 趋势预测

/// 趋势预测
public struct TrendPrediction: Codable {
    /// 预测类型
    public var predictionType: PredictionType
    /// 预测标题
    public var title: String
    /// 预测描述
    public var description: String
    /// 预测时间范围
    public var timeRange: String
    /// 预测内容
    public var predictions: [PredictionItem]
    /// 置信度
    public var confidence: Double
    /// 影响因素
    public var influencingFactors: [String]
    /// 建议行动
    public var recommendedActions: [String]
    
    public init(
        predictionType: PredictionType,
        title: String,
        description: String,
        timeRange: String,
        predictions: [PredictionItem],
        confidence: Double,
        influencingFactors: [String] = [],
        recommendedActions: [String] = []
    ) {
        self.predictionType = predictionType
        self.title = title
        self.description = description
        self.timeRange = timeRange
        self.predictions = predictions
        self.confidence = confidence
        self.influencingFactors = influencingFactors
        self.recommendedActions = recommendedActions
    }
}

/// 预测类型
public enum PredictionType: String, Codable, CaseIterable {
    case theme = "theme"              // 主题预测
    case emotion = "emotion"          // 情绪预测
    case lucidity = "lucidity"        // 清醒梦预测
    case clarity = "clarity"          // 清晰度预测
    case stress = "stress"            // 压力预警
    
    public var displayName: String {
        switch self {
        case .theme: return "主题预测"
        case .emotion: return "情绪预测"
        case .lucidity: return "清醒梦预测"
        case .clarity: return "清晰度预测"
        case .stress: return "压力预警"
        }
    }
}

/// 预测项目
public struct PredictionItem: Codable {
    /// 预测内容
    public var content: String
    /// 概率 (0-1)
    public var probability: Double
    /// 时间范围
    public var timeFrame: String
    
    public init(content: String, probability: Double, timeFrame: String) {
        self.content = content
        self.probability = probability
        self.timeFrame = timeFrame
    }
}

// MARK: - 个性化洞察

/// 梦境洞察
public struct DreamInsight: Codable, Identifiable {
    public var id: UUID
    /// 洞察类型
    public var insightType: InsightType
    /// 洞察标题
    public var title: String
    /// 洞察描述
    public var description: String
    /// 支持数据
    public var supportingData: [String]
    /// 重要性等级
    public var importance: ImportanceLevel
    /// 相关梦境 ID
    public var relatedDreamIds: [UUID]
    /// 创建时间
    public var createdAt: Date
    
    public init(
        insightType: InsightType,
        title: String,
        description: String,
        supportingData: [String] = [],
        importance: ImportanceLevel = .medium,
        relatedDreamIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.insightType = insightType
        self.title = title
        self.description = description
        self.supportingData = supportingData
        self.importance = importance
        self.relatedDreamIds = relatedDreamIds
        self.createdAt = createdAt
    }
}

/// 洞察类型
public enum InsightType: String, Codable, CaseIterable {
    case pattern = "pattern"              // 模式发现
    case trend = "trend"                  // 趋势分析
    case correlation = "correlation"      // 关联发现
    case anomaly = "anomaly"              // 异常检测
    case growth = "growth"                // 成长轨迹
    case opportunity = "opportunity"      // 成长机会
    
    public var displayName: String {
        switch self {
        case .pattern: return "模式发现"
        case .trend: return "趋势分析"
        case .correlation: return "关联发现"
        case .anomaly: return "异常检测"
        case .growth: return "成长轨迹"
        case .opportunity: return "成长机会"
        }
    }
    
    public var icon: String {
        switch self {
        case .pattern: return "🔍"
        case .trend: return "📊"
        case .correlation: return "🔗"
        case .anomaly: return "⚠️"
        case .growth: return "🌱"
        case .opportunity: return "💡"
        }
    }
}

/// 重要性等级
public enum ImportanceLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .critical: return "重要"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - 行动建议

/// 行动建议
public struct ActionSuggestion: Codable, Identifiable {
    public var id: UUID
    /// 建议类别
    public var category: SuggestionCategory
    /// 建议标题
    public var title: String
    /// 建议描述
    public var description: String
    /// 具体行动步骤
    public var actionSteps: [String]
    /// 预期效果
    public var expectedOutcome: String
    /// 难度等级
    public var difficulty: DifficultyLevel
    /// 预计时间
    public var estimatedTime: String
    /// 相关资源
    public var resources: [SuggestionResource]
    /// 优先级
    public var priority: Int
    
    public init(
        category: SuggestionCategory,
        title: String,
        description: String,
        actionSteps: [String] = [],
        expectedOutcome: String = "",
        difficulty: DifficultyLevel = .medium,
        estimatedTime: String = "",
        resources: [SuggestionResource] = [],
        priority: Int = 5
    ) {
        self.id = UUID()
        self.category = category
        self.title = title
        self.description = description
        self.actionSteps = actionSteps
        self.expectedOutcome = expectedOutcome
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.resources = resources
        self.priority = priority
    }
}

/// 建议类别
public enum SuggestionCategory: String, Codable, CaseIterable {
    case recording = "recording"        // 记录优化
    case meditation = "meditation"      // 冥想练习
    case creativity = "creativity"      // 创意表达
    case sleep = "sleep"                // 睡眠改善
    case reflection = "reflection"      // 自我反思
    case growth = "growth"              // 个人成长
    case lucid = "lucid"                // 清醒梦训练
    
    public var displayName: String {
        switch self {
        case .recording: return "记录优化"
        case .meditation: return "冥想练习"
        case .creativity: return "创意表达"
        case .sleep: return "睡眠改善"
        case .reflection: return "自我反思"
        case .growth: return "个人成长"
        case .lucid: return "清醒梦训练"
        }
    }
    
    public var icon: String {
        switch self {
        case .recording: return "📝"
        case .meditation: return "🧘"
        case .creativity: return "🎨"
        case .sleep: return "💤"
        case .reflection: return "🪞"
        case .growth: return "🌱"
        case .lucid: return "💡"
        }
    }
}

/// 难度等级
public enum DifficultyLevel: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    public var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
}

/// 建议资源
public struct SuggestionResource: Codable {
    /// 资源类型
    public var type: ResourceType
    /// 资源标题
    public var title: String
    /// 资源 URL 或路径
    public var url: String?
    /// 描述
    public var description: String
    
    public init(type: ResourceType, title: String, url: String? = nil, description: String = "") {
        self.type = type
        self.title = title
        self.url = url
        self.description = description
    }
}

/// 资源类型
public enum ResourceType: String, Codable {
    case article = "article"
    case video = "video"
    case audio = "audio"
    case exercise = "exercise"
    case tool = "tool"
    
    public var displayName: String {
        switch self {
        case .article: return "文章"
        case .video: return "视频"
        case .audio: return "音频"
        case .exercise: return "练习"
        case .tool: return "工具"
        }
    }
}

// MARK: - 解析配置

/// AI 解析配置
public struct AIAnalysisConfiguration: Codable {
    /// 是否启用表面层解读
    public var enableSurfaceLayer: Bool
    /// 是否启用心理层解读
    public var enablePsychologicalLayer: Bool
    /// 是否启用精神层解读
    public var enableSpiritualLayer: Bool
    /// 是否启用模式识别
    public var enablePatternRecognition: Bool
    /// 是否启用趋势预测
    public var enableTrendPrediction: Bool
    /// 是否启用个性化洞察
    public var enablePersonalizedInsights: Bool
    /// 最大符号识别数量
    public var maxSymbols: Int
    /// 置信度阈值
    public var confidenceThreshold: Double
    /// 语言
    public var language: String
    
    public static var `default`: AIAnalysisConfiguration {
        AIAnalysisConfiguration(
            enableSurfaceLayer: true,
            enablePsychologicalLayer: true,
            enableSpiritualLayer: true,
            enablePatternRecognition: true,
            enableTrendPrediction: true,
            enablePersonalizedInsights: true,
            maxSymbols: 10,
            confidenceThreshold: 0.6,
            language: "zh-CN"
        )
    }
}
