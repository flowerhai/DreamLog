//
//  DreamSmartInsightsModels.swift
//  DreamLog
//
//  Phase 78: Smart Dream Insights & Notifications
//  智能梦境洞察与通知系统
//

import Foundation
import SwiftData

// MARK: - 洞察类型枚举

/// 智能洞察类型
@Model
public class DreamInsightType: Codable, Hashable {
    public var id: UUID
    public var name: String
    public var nameKey: String // 本地化键
    public var icon: String
    public var color: String // 十六进制颜色
    public var description: String
    
    public init(id: UUID = UUID(), name: String, nameKey: String, icon: String, color: String, description: String) {
        self.id = id
        self.name = name
        self.nameKey = nameKey
        self.icon = icon
        self.color = color
        self.description = description
    }
    
    // 预定义洞察类型
    public static let allTypes: [DreamInsightType] = [
        DreamInsightType(name: "模式发现", nameKey: "insight.pattern", icon: "🔍", color: "#8B5CF6", description: "发现梦境中的重复模式"),
        DreamInsightType(name: "情绪趋势", nameKey: "insight.emotion", icon: "💖", color: "#EC4899", description: "情绪变化趋势分析"),
        DreamInsightType(name: "主题演变", nameKey: "insight.theme", icon: "🎭", color: "#3B82F6", description: "梦境主题的演变"),
        DreamInsightType(name: "清醒梦机会", nameKey: "insight.lucid", icon: "👁️", color: "#10B981", description: "清醒梦最佳时机"),
        DreamInsightType(name: "睡眠质量", nameKey: "insight.sleep", icon: "🌙", color: "#6366F1", description: "睡眠与梦境关联"),
        DreamInsightType(name: "创意启发", nameKey: "insight.creative", icon: "💡", color: "#F59E0B", description: "来自梦境的创意灵感"),
        DreamInsightType(name: "健康提醒", nameKey: "insight.health", icon: "🍎", color: "#EF4444", description: "健康相关的洞察"),
        DreamInsightType(name: "里程碑", nameKey: "insight.milestone", icon: "🏆", color: "#F97316", description: "记录里程碑达成")
    ]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: DreamInsightType, rhs: DreamInsightType) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 智能洞察模型

/// 智能梦境洞察
@Model
public class DreamSmartInsight {
    public var id: UUID
    public var title: String
    public var content: String
    public var type: DreamInsightType
    public var priority: InsightPriority // 优先级
    public var confidence: Double // 置信度 0-1
    public var relatedDreamIds: [UUID] // 关联的梦境 ID
    public var tags: [String] // 相关标签
    public var actionSuggestion: String? // 行动建议
    public var isRead: Bool
    public var isSaved: Bool
    public var createdAt: Date
    public var expiresAt: Date? // 过期时间（某些洞察有过期性）
    public var notificationSent: Bool
    
    public init(
        title: String,
        content: String,
        type: DreamInsightType,
        priority: InsightPriority = .medium,
        confidence: Double = 0.8,
        relatedDreamIds: [UUID] = [],
        tags: [String] = [],
        actionSuggestion: String? = nil,
        isRead: Bool = false,
        isSaved: Bool = false,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        notificationSent: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.type = type
        self.priority = priority
        self.confidence = confidence
        self.relatedDreamIds = relatedDreamIds
        self.tags = tags
        self.actionSuggestion = actionSuggestion
        self.isRead = isRead
        self.isSaved = isSaved
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.notificationSent = notificationSent
    }
}

// MARK: - 优先级枚举

/// 洞察优先级
public enum InsightPriority: Int, Codable, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2
    case urgent = 3
    
    public var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "#6B7280"
        case .medium: return "#3B82F6"
        case .high: return "#F59E0B"
        case .urgent: return "#EF4444"
        }
    }
}

// MARK: - 洞察统计模型

/// 洞察统计数据
public struct InsightStatistics: Codable {
    public var totalInsights: Int
    public var unreadCount: Int
    public var savedCount: Int
    public var byType: [String: Int] // 类型 -> 数量
    public var byPriority: [String: Int] // 优先级 -> 数量
    public var weeklyTrend: [Date: Int] // 日期 -> 数量
    public var mostCommonType: String?
    public var averageConfidence: Double
    
    public init(
        totalInsights: Int = 0,
        unreadCount: Int = 0,
        savedCount: Int = 0,
        byType: [String: Int] = [:],
        byPriority: [String: Int] = [:],
        weeklyTrend: [Date: Int] = [:],
        mostCommonType: String? = nil,
        averageConfidence: Double = 0.0
    ) {
        self.totalInsights = totalInsights
        self.unreadCount = unreadCount
        self.savedCount = savedCount
        self.byType = byType
        self.byPriority = byPriority
        self.weeklyTrend = weeklyTrend
        self.mostCommonType = mostCommonType
        self.averageConfidence = averageConfidence
    }
}

// MARK: - 洞察生成配置

/// 洞察生成配置
public struct InsightGenerationConfig: Codable {
    public var enabled: Bool
    public var minConfidence: Double // 最小置信度
    public var checkInterval: TimeInterval // 检查间隔（秒）
    public var enabledTypes: [String] // 启用的洞察类型
    public var quietHoursStart: Int // 免打扰开始时间（小时）
    public var quietHoursEnd: Int // 免打扰结束时间（小时）
    public var maxDailyInsights: Int // 每日最大洞察数
    public var notifyOnHighPriority: Bool // 高优先级是否通知
    
    public static let `default` = InsightGenerationConfig(
        enabled: true,
        minConfidence: 0.6,
        checkInterval: 3600, // 1 小时
        enabledTypes: DreamInsightType.allTypes.map { $0.nameKey },
        quietHoursStart: 23,
        quietHoursEnd: 8,
        maxDailyInsights: 5,
        notifyOnHighPriority: true
    )
}

// MARK: - 通知设置模型

/// 智能通知设置
@Model
public class DreamSmartNotificationSettings {
    public var id: UUID
    public var enabled: Bool
    public var config: InsightGenerationConfig
    public var lastCheckDate: Date?
    public var dailyInsightCount: Int
    public var lastResetDate: Date
    
    public init(
        enabled: Bool = true,
        config: InsightGenerationConfig = .default,
        lastCheckDate: Date? = nil,
        dailyInsightCount: Int = 0,
        lastResetDate: Date = Date()
    ) {
        self.id = UUID()
        self.enabled = enabled
        self.config = config
        self.lastCheckDate = lastCheckDate
        self.dailyInsightCount = dailyInsightCount
        self.lastResetDate = lastResetDate
    }
}

// MARK: - 洞察卡片预览

/// 洞察卡片预览（用于 UI 展示）
public struct InsightCardPreview: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let content: String
    public let typeIcon: String
    public let typeColor: String
    public let priority: InsightPriority
    public let confidence: Double
    public let createdAt: Date
    public let isRead: Bool
    public let actionSuggestion: String?
    
    public init(insight: DreamSmartInsight) {
        self.id = insight.id
        self.title = insight.title
        self.content = insight.content
        self.typeIcon = insight.type.icon
        self.typeColor = insight.type.color
        self.priority = insight.priority
        self.confidence = insight.confidence
        self.createdAt = insight.createdAt
        self.isRead = insight.isRead
        self.actionSuggestion = insight.actionSuggestion
    }
}
