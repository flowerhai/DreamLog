//
//  DreamTagManagerModels.swift
//  DreamLog
//
//  智能标签管理系统 - 数据模型
//  Phase 32: 智能标签管理
//

import Foundation

// MARK: - 标签信息模型

/// 标签详细信息
struct TagInfo: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var normalized: String  // 标准化名称（小写、去空格）
    var count: Int  // 使用次数
    var category: TagCategory?
    var createdAt: Date
    var lastUsedAt: Date
    var aliases: [String]  // 别名列表
    var isSuggested: Bool  // 是否为 AI 建议标签
    
    init(
        id: UUID = UUID(),
        name: String,
        count: Int = 0,
        category: TagCategory? = nil,
        createdAt: Date = Date(),
        lastUsedAt: Date = Date(),
        aliases: [String] = [],
        isSuggested: Bool = false
    ) {
        self.id = id
        self.name = name
        self.normalized = name.lowercased().trimmingCharacters(in: .whitespaces)
        self.count = count
        self.category = category
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.aliases = aliases
        self.isSuggested = isSuggested
    }
    
    /// 从标签名自动创建
    static func fromName(_ name: String) -> TagInfo {
        TagInfo(name: name)
    }
}

// MARK: - 标签分类

/// 标签分类
enum TagCategory: String, Codable, CaseIterable, Identifiable {
    case person = "人物"
    case place = "地点"
    case object = "物品"
    case action = "行为"
    case emotion = "情绪"
    case animal = "动物"
    case nature = "自然"
    case supernatural = "超自然"
    case food = "食物"
    case vehicle = "交通工具"
    case building = "建筑"
    case activity = "活动"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .person: return "👤"
        case .place: return "📍"
        case .object: return "📦"
        case .action: return "⚡"
        case .emotion: return "💭"
        case .animal: return "🐾"
        case .nature: return "🌿"
        case .supernatural: return "✨"
        case .food: return "🍎"
        case .vehicle: return "🚗"
        case .building: return "🏠"
        case .activity: return "🎯"
        case .other: return "🏷️"
        }
    }
    
    var color: String {
        switch self {
        case .person: return "FF6B6B"
        case .place: return "4ECDC4"
        case .object: return "45B7D1"
        case .action: return "FFA07A"
        case .emotion: return "DDA0DD"
        case .animal: return "98D8C8"
        case .nature: return "7FB069"
        case .supernatural: return "B19CD9"
        case .food: return "FFB347"
        case .vehicle: return "779ECB"
        case .building: return "AEC6CF"
        case .activity: return "FFD1DC"
        case .other: return "C0C0C0"
        }
    }
}

// MARK: - 标签操作

/// 标签操作类型
enum TagOperation {
    case merge(source: TagInfo, target: TagInfo)
    case rename(tag: TagInfo, newName: String)
    case delete(tag: TagInfo)
    case categorize(tag: TagInfo, category: TagCategory)
    case addAlias(tag: TagInfo, alias: String)
    case removeAlias(tag: TagInfo, alias: String)
}

// MARK: - 标签建议

/// AI 标签建议
struct TagSuggestion: Identifiable, Codable {
    let id: UUID
    let dreamId: UUID
    let dreamTitle: String
    let suggestedTags: [String]
    let confidence: Double  // 0-1 置信度
    let reason: String  // 建议理由
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        dreamTitle: String,
        suggestedTags: [String],
        confidence: Double,
        reason: String
    ) {
        self.id = id
        self.dreamId = dreamId
        self.dreamTitle = dreamTitle
        self.suggestedTags = suggestedTags
        self.confidence = confidence
        self.reason = reason
    }
}

// MARK: - 标签清理建议

/// 标签清理建议
struct TagCleanupSuggestion: Identifiable, Codable {
    let id: UUID
    let type: CleanupType
    let tags: [TagInfo]
    let recommendation: String
    let impact: Int  // 受影响的梦境数量
    
    enum CleanupType: String, Codable {
        case duplicate = "重复标签"  // 大小写不同
        case similar = "相似标签"  // 语义相似
        case typo = "可能拼写错误"
        case unused = "未使用标签"
        case merge = "建议合并"
    }
    
    init(
        id: UUID = UUID(),
        type: CleanupType,
        tags: [TagInfo],
        recommendation: String,
        impact: Int
    ) {
        self.id = id
        self.type = type
        self.tags = tags
        self.recommendation = recommendation
        self.impact = impact
    }
}

// MARK: - 标签统计

/// 标签统计数据
struct TagStatistics: Codable {
    let totalTags: Int
    let totalUsage: Int  // 总使用次数
    let categorizedTags: Int  // 已分类标签数
    let uncategorizedTags: Int  // 未分类标签数
    let topTags: [TagInfo]  // Top 10 使用标签
    let recentTags: [TagInfo]  // 最近使用的标签
    let suggestedTags: [TagInfo]  // AI 建议标签
    let categoryDistribution: [TagCategory: Int]  // 分类分布
    
    var categorizedPercentage: Double {
        guard totalTags > 0 else { return 0 }
        return Double(categorizedTags) / Double(totalTags) * 100
    }
}

// MARK: - 批量操作结果

/// 批量标签操作结果
struct BulkOperationResult: Codable {
    let success: Bool
    let affectedDreams: Int
    let processedTags: Int
    let errors: [String]
    let message: String
    
    init(
        success: Bool,
        affectedDreams: Int,
        processedTags: Int,
        errors: [String] = [],
        message: String
    ) {
        self.success = success
        self.affectedDreams = affectedDreams
        self.processedTags = processedTags
        self.errors = errors
        self.message = message
    }
}

// MARK: - 标签管理配置

/// 标签管理配置
struct TagManagerConfig: Codable {
    var autoSuggestTags: Bool  // 自动建议标签
    var autoCategorize: Bool  // 自动分类
    var suggestSimilarTags: Bool  // 建议相似标签
    var notifyDuplicates: Bool  // 通知重复标签
    var minTagUsageForSuggestion: Int  // 最小使用次数才建议
    
    static var `default`: TagManagerConfig {
        TagManagerConfig(
            autoSuggestTags: true,
            autoCategorize: false,
            suggestSimilarTags: true,
            notifyDuplicates: true,
            minTagUsageForSuggestion: 2
        )
    }
}
