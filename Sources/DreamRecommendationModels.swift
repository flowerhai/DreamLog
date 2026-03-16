//
//  DreamRecommendationModels.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  数据模型层
//

import Foundation
import SwiftData

// MARK: - 推荐类型枚举

/// 推荐类型
@Model
public enum DreamRecommendationType: String, CaseIterable, Codable {
    // 梦境推荐
    case similarDream = "similar_dream"          // 相似梦境
    case relatedDream = "related_dream"          // 关联梦境
    case memoryDream = "memory_dream"            // 回忆梦境
    
    // 内容推荐
    case meditation = "meditation"               // 冥想推荐
    case music = "music"                         // 音乐推荐
    case inspiration = "inspiration"             // 灵感提示
    case lucidTraining = "lucid_training"        // 清醒梦训练
    
    // 功能推荐
    case export = "export"                       // 导出建议
    case share = "share"                         // 分享建议
    case reflection = "reflection"               // 反思建议
    
    // 健康建议
    case sleepImprovement = "sleep_improvement"  // 睡眠改善
    case habitOptimization = "habit_optimization" // 习惯优化
    
    public var displayName: String {
        switch self {
        case .similarDream: return "相似梦境"
        case .relatedDream: return "关联梦境"
        case .memoryDream: return "回忆梦境"
        case .meditation: return "冥想推荐"
        case .music: return "音乐推荐"
        case .inspiration: return "灵感提示"
        case .lucidTraining: return "清醒梦训练"
        case .export: return "导出建议"
        case .share: return "分享建议"
        case .reflection: return "反思建议"
        case .sleepImprovement: return "睡眠改善"
        case .habitOptimization: return "习惯优化"
        }
    }
    
    public var icon: String {
        switch self {
        case .similarDream, .relatedDream, .memoryDream: return "moon.stars.fill"
        case .meditation: return "figure.mind.and.body"
        case .music: return "music.note"
        case .inspiration: return "lightbulb.fill"
        case .lucidTraining: return "brain.head.profile"
        case .export: return "square.and.arrow.up"
        case .share: return "person.2.fill"
        case .reflection: return "book.fill"
        case .sleepImprovement: return "bed.double.fill"
        case .habitOptimization: return "chart.line.uptrend.xyaxis"
        }
    }
    
    public var color: String {
        switch self {
        case .similarDream, .relatedDream, .memoryDream: return "purple"
        case .meditation: return "green"
        case .music: return "blue"
        case .inspiration: return "yellow"
        case .lucidTraining: return "orange"
        case .export: return "gray"
        case .share: return "pink"
        case .reflection: return "indigo"
        case .sleepImprovement: return "teal"
        case .habitOptimization: return "cyan"
        }
    }
}

// MARK: - 推荐模型

/// 梦境推荐
@Model
public final class DreamRecommendation {
    public var id: UUID
    public var type: DreamRecommendationType
    public var title: String
    public var description: String
    public var reason: String  // 推荐理由
    public var confidence: Double  // 置信度 0-1
    public var priority: Int  // 优先级 1-5
    public var metadata: [String: AnyCodable]  // 元数据
    public var relatedDreamIds: [UUID]  // 关联梦境 ID
    public var createdAt: Date
    public var expiresAt: Date?  // 过期时间
    public var isRead: Bool
    public var isLiked: Bool
    public var isDismissed: Bool
    public var feedbackScore: Int?  // 用户反馈 1-5
    
    public init(
        type: DreamRecommendationType,
        title: String,
        description: String,
        reason: String,
        confidence: Double = 0.5,
        priority: Int = 3,
        metadata: [String: AnyCodable] = [:],
        relatedDreamIds: [UUID] = [],
        expiresAt: Date? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.reason = reason
        self.confidence = confidence
        self.priority = priority
        self.metadata = metadata
        self.relatedDreamIds = relatedDreamIds
        self.createdAt = Date()
        self.expiresAt = expiresAt
        self.isRead = false
        self.isLiked = false
        self.isDismissed = false
    }
    
    /// 是否已过期
    public var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
    
    /// 是否有效（未读且未关闭且未过期）
    public var isActive: Bool {
        !isDismissed && !isExpired
    }
}

// MARK: - 洞察模型

/// 洞察类型
public enum DreamInsightType: String, CaseIterable, Codable {
    case pattern = "pattern"                    // 模式识别
    case trend = "trend"                        // 趋势分析
    case correlation = "correlation"            // 关联分析
    case prediction = "prediction"              // 预测
    case anomaly = "anomaly"                    // 异常检测
    case achievement = "achievement"            // 成就
    
    public var displayName: String {
        switch self {
        case .pattern: return "模式洞察"
        case .trend: return "趋势分析"
        case .correlation: return "关联分析"
        case .prediction: return "预测"
        case .anomaly: return "异常检测"
        case .achievement: return "成就"
        }
    }
    
    public var icon: String {
        switch self {
        case .pattern: return "repeat"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .correlation: return "link"
        case .prediction: return "crystalball"
        case .anomaly: return "exclamationmark.triangle"
        case .achievement: return "star.fill"
        }
    }
}

/// 梦境洞察
@Model
public final class DreamInsight {
    public var id: UUID
    public var type: DreamInsightType
    public var title: String
    public var description: String
    public var details: String  // 详细说明
    public var dataPoints: [String: AnyCodable]  // 数据点
    public var confidence: Double  // 置信度
    public var timeRange: TimeRange  // 时间范围
    public var createdAt: Date
    public var isImportant: Bool  // 是否重要
    
    public init(
        type: DreamInsightType,
        title: String,
        description: String,
        details: String = "",
        dataPoints: [String: AnyCodable] = [:],
        confidence: Double = 0.5,
        timeRange: TimeRange = .last30Days,
        isImportant: Bool = false
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.details = details
        self.dataPoints = dataPoints
        self.confidence = confidence
        self.timeRange = timeRange
        self.createdAt = Date()
        self.isImportant = isImportant
    }
}

// MARK: - 建议模型

/// 建议类型
public enum SuggestionCategory: String, CaseIterable, Codable {
    case recording = "recording"          // 记录优化
    case lucidDream = "lucid_dream"       // 清醒梦
    case sleep = "sleep"                  // 睡眠
    case creativity = "creativity"        // 创意
    case health = "health"                // 健康
    case social = "social"                // 社交
    
    public var displayName: String {
        switch self {
        case .recording: return "记录优化"
        case .lucidDream: return "清醒梦"
        case .sleep: return "睡眠"
        case .creativity: return "创意"
        case .health: return "健康"
        case .social: return "社交"
        }
    }
}

/// 梦境建议
@Model
public final class DreamSuggestion {
    public var id: UUID
    public var category: SuggestionCategory
    public var title: String
    public var action: String  // 行动建议
    public var reason: String  // 建议原因
    public var expectedBenefit: String  // 预期收益
    public var difficulty: Int  // 难度 1-5
    public var estimatedTime: Int  // 预计时间（分钟）
    public var tags: [String]
    public var isCompleted: Bool
    public var completedAt: Date?
    public var isAccepted: Bool
    public var acceptedAt: Date?
    public var isDismissed: Bool
    public var createdAt: Date
    
    public init(
        category: SuggestionCategory,
        title: String,
        action: String,
        reason: String,
        expectedBenefit: String,
        difficulty: Int = 2,
        estimatedTime: Int = 10,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.category = category
        self.title = title
        self.action = action
        self.reason = reason
        self.expectedBenefit = expectedBenefit
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.tags = tags
        self.isCompleted = false
        self.isAccepted = false
        self.isDismissed = false
        self.createdAt = Date()
    }
    
    /// 标记为已接受
    public func accept() {
        self.isAccepted = true
        self.acceptedAt = Date()
    }
    
    /// 标记为已完成
    public func complete() {
        self.isCompleted = true
        self.completedAt = Date()
    }
}

// MARK: - 时间范围枚举

/// 时间范围
public enum TimeRange: String, CaseIterable, Codable {
    case last7Days = "last_7_days"
    case last14Days = "last_14_days"
    case last30Days = "last_30_days"
    case last90Days = "last_90_days"
    case last180Days = "last_180_days"
    case all = "all"
    
    public var displayName: String {
        switch self {
        case .last7Days: return "最近 7 天"
        case .last14Days: return "最近 14 天"
        case .last30Days: return "最近 30 天"
        case .last90Days: return "最近 90 天"
        case .last180Days: return "最近 180 天"
        case .all: return "全部"
        }
    }
    
    public var days: Int? {
        switch self {
        case .last7Days: return 7
        case .last14Days: return 14
        case .last30Days: return 30
        case .last90Days: return 90
        case .last180Days: return 180
        case .all: return nil
        }
    }
    
    public var startDate: Date {
        let calendar = Calendar.current
        let days = self.days ?? 365 * 5  // 默认 5 年
        return calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}

// MARK: - 推荐配置

/// 推荐系统配置
public struct RecommendationConfig: Codable {
    public var enableSimilarDreams: Bool
    public var enableMeditationRecommendations: Bool
    public var enableMusicRecommendations: Bool
    public var enableInspirationRecommendations: Bool
    public var enableLucidTrainingRecommendations: Bool
    public var minConfidenceThreshold: Double
    public var maxRecommendationsPerDay: Int
    public var diversityFactor: Double  // 多样性因子 0-1
    
    public static let `default` = RecommendationConfig(
        enableSimilarDreams: true,
        enableMeditationRecommendations: true,
        enableMusicRecommendations: true,
        enableInspirationRecommendations: true,
        enableLucidTrainingRecommendations: true,
        minConfidenceThreshold: 0.3,
        maxRecommendationsPerDay: 10,
        diversityFactor: 0.3
    )
}

// MARK: - 推荐统计

/// 推荐统计
public struct RecommendationStats: Codable {
    public var totalRecommendations: Int
    public var readCount: Int
    public var likedCount: Int
    public var dismissedCount: Int
    public var clickThroughRate: Double
    public var averageFeedbackScore: Double?
    public var topRecommendationType: DreamRecommendationType?
    public var recommendationsByType: [DreamRecommendationType: Int]
    
    public init(
        totalRecommendations: Int = 0,
        readCount: Int = 0,
        likedCount: Int = 0,
        dismissedCount: Int = 0,
        clickThroughRate: Double = 0,
        averageFeedbackScore: Double? = nil,
        topRecommendationType: DreamRecommendationType? = nil,
        recommendationsByType: [DreamRecommendationType: Int] = [:]
    ) {
        self.totalRecommendations = totalRecommendations
        self.readCount = readCount
        self.likedCount = likedCount
        self.dismissedCount = dismissedCount
        self.clickThroughRate = clickThroughRate
        self.averageFeedbackScore = averageFeedbackScore
        self.topRecommendationType = topRecommendationType
        self.recommendationsByType = recommendationsByType
    }
}

// MARK: - AnyCodable (如果项目中不存在)

/// 支持任意 Codable 类型的包装器
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to encode value"
                )
            )
        }
    }
}
