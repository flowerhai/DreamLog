//
//  DreamPredictionModels.swift
//  DreamLog
//
//  梦境预测数据模型
//  使用机器学习分析梦境模式，预测未来梦境趋势
//

import Foundation
import SwiftData

// MARK: - 梦境预测模型

/// 梦境预测类型
enum DreamPredictionType: String, Codable, CaseIterable {
    case content = "content"           // 内容预测
    case emotion = "emotion"           // 情绪预测
    case lucidProbability = "lucid"    // 清醒梦概率
    case bestTime = "bestTime"         // 最佳记录时间
    case pattern = "pattern"           // 模式识别
    case warning = "warning"           // 健康预警
    
    var displayName: String {
        switch self {
        case .content: return "梦境内容"
        case .emotion: return "情绪趋势"
        case .lucidProbability: return "清醒梦概率"
        case .bestTime: return "最佳时间"
        case .pattern: return "模式识别"
        case .warning: return "健康预警"
        }
    }
    
    var icon: String {
        switch self {
        case .content: return "🔮"
        case .emotion: return "😊"
        case .lucidProbability: return "🌟"
        case .bestTime: return "⏰"
        case .pattern: return "🔗"
        case .warning: return "⚠️"
        }
    }
}

/// 梦境预测结果
@Model
final class DreamPrediction {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var predictionDate: Date       // 预测的日期
    var type: DreamPredictionType
    var confidence: Double         // 置信度 0-1
    var title: String
    var description: String
    var details: String            // JSON 字符串存储详细数据
    var tags: [String]
    var isRead: Bool
    
    init(
        id: UUID = UUID(),
        predictionDate: Date = Date(),
        type: DreamPredictionType,
        confidence: Double,
        title: String,
        description: String,
        details: String = "{}",
        tags: [String] = [],
        isRead: Bool = false
    ) {
        self.id = id
        self.createdAt = Date()
        self.predictionDate = predictionDate
        self.type = type
        self.confidence = confidence
        self.title = title
        self.description = description
        self.details = details
        self.tags = tags
        self.isRead = isRead
    }
}

// MARK: - 预测详细数据模型

/// 内容预测数据
struct ContentPredictionData: Codable {
    var likelyThemes: [String]          // 可能的主题
    var likelySymbols: [String]         // 可能的符号
    var likelyScenarios: [String]       // 可能的场景
    var inspirationSources: [String]    // 灵感来源（基于近期经历）
    var confidenceBreakdown: [String: Double]  // 各主题置信度
    
    static func empty() -> ContentPredictionData {
        ContentPredictionData(
            likelyThemes: [],
            likelySymbols: [],
            likelyScenarios: [],
            inspirationSources: [],
            confidenceBreakdown: [:]
        )
    }
}

/// 情绪预测数据
struct EmotionPredictionData: Codable {
    var predictedEmotions: [EmotionType: Double]  // 预测情绪分布
    var trendDirection: TrendDirection            // 情绪趋势方向
    var stabilityScore: Double                    // 情绪稳定性评分
    var recommendations: [String]                 // 情绪调节建议
    
    enum TrendDirection: String, Codable {
        case improving = "improving"
        case stable = "stable"
        case declining = "declining"
        case volatile = "volatile"
    }
    
    static func empty() -> EmotionPredictionData {
        EmotionPredictionData(
            predictedEmotions: [:],
            trendDirection: .stable,
            stabilityScore: 0.5,
            recommendations: []
        )
    }
}

/// 清醒梦预测数据
struct LucidPredictionData: Codable {
    var probability: Double                   // 清醒梦概率 0-1
    var contributingFactors: [String]         // 影响因素
    var recommendedTechniques: [String]       // 推荐技巧
    var optimalTiming: String                 // 最佳时机
    var preparationTips: [String]             // 准备建议
    
    static func empty() -> LucidPredictionData {
        LucidPredictionData(
            probability: 0.5,
            contributingFactors: [],
            recommendedTechniques: [],
            optimalTiming: "REM 阶段",
            preparationTips: []
        )
    }
}

/// 最佳时间预测数据
struct BestTimePredictionData: Codable {
    var optimalHours: [Int]                   // 最佳小时 (0-23)
    var sleepQualityCorrelation: Double       // 与睡眠质量关联度
    var recallQualityByHour: [Int: Double]    // 各小时回忆质量
    var historicalPatterns: [String]          // 历史模式
    
    static func empty() -> BestTimePredictionData {
        BestTimePredictionData(
            optimalHours: [],
            sleepQualityCorrelation: 0.5,
            recallQualityByHour: [:],
            historicalPatterns: []
        )
    }
}

/// 模式识别数据
struct PatternPredictionData: Codable {
    var recurringThemes: [String]             // 重复主题
    var cycleLength: Int                      // 周期长度（天）
    var triggerFactors: [String]              // 触发因素
    var correlationMatrix: [String: [String: Double]]  // 关联矩阵
    var anomalyDetection: [String]            // 异常检测
    
    static func empty() -> PatternPredictionData {
        PatternPredictionData(
            recurringThemes: [],
            cycleLength: 7,
            triggerFactors: [],
            correlationMatrix: [:],
            anomalyDetection: []
        )
    }
}

/// 健康预警数据
struct WarningPredictionData: Codable {
    var warningLevel: WarningLevel            // 预警级别
    var indicators: [String]                  // 指标
    var suggestions: [String]                 // 建议
    var relatedPatterns: [String]             // 相关模式
    var shouldConsult: Bool                   // 是否建议咨询专业人士
    
    enum WarningLevel: String, Codable, CaseIterable {
        case normal = "normal"
        case low = "low"
        case medium = "medium"
        case high = "high"
        
        var displayName: String {
            switch self {
            case .normal: return "正常"
            case .low: return "轻度"
            case .medium: return "中度"
            case .high: return "重度"
            }
        }
        
        var color: String {
            switch self {
            case .normal: return "green"
            case .low: return "yellow"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
    }
    
    static func empty() -> WarningPredictionData {
        WarningPredictionData(
            warningLevel: .normal,
            indicators: [],
            suggestions: [],
            relatedPatterns: [],
            shouldConsult: false
        )
    }
}

// MARK: - 预测配置

/// 预测配置
struct PredictionConfig: Codable {
    var isEnabled: Bool
    var predictionDays: Int                   // 预测未来天数
    var minConfidenceThreshold: Double        // 最小置信度阈值
    var autoRefreshInterval: TimeInterval     // 自动刷新间隔
    var notifyOnHighConfidence: Bool          // 高置信度时通知
    var includeHealthWarnings: Bool           // 包含健康预警
    
    static var `default`: PredictionConfig {
        PredictionConfig(
            isEnabled: true,
            predictionDays: 7,
            minConfidenceThreshold: 0.6,
            autoRefreshInterval: 3600,  // 1 小时
            notifyOnHighConfidence: true,
            includeHealthWarnings: true
        )
    }
}

// MARK: - 预测统计

/// 预测统计
struct PredictionStats: Codable {
    var totalPredictions: Int
    var accuratePredictions: Int
    var accuracyRate: Double
    var averageConfidence: Double
    var predictionsByType: [DreamPredictionType: Int]
    var lastUpdated: Date
    
    static var empty: PredictionStats {
        PredictionStats(
            totalPredictions: 0,
            accuratePredictions: 0,
            accuracyRate: 0,
            averageConfidence: 0,
            predictionsByType: [:],
            lastUpdated: Date()
        )
    }
}
