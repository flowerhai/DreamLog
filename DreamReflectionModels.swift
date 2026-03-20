//
//  DreamReflectionModels.swift
//  DreamLog
//
//  梦境反思日记 - 数据模型
//  Phase 49: 梦境反思与洞察整合
//

import Foundation
import SwiftData

// MARK: - 反思类型

/// 反思类型枚举
enum ReflectionType: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    
    case insight = "insight"        // 洞察领悟
    case connection = "connection"  // 现实关联
    case emotion = "emotion"        // 情绪探索
    case question = "question"      // 未解问题
    case intention = "intention"    // 意图设定
    case gratitude = "gratitude"    // 感恩记录
    
    var displayName: String {
        switch self {
        case .insight: return "💡 洞察领悟"
        case .connection: return "🔗 现实关联"
        case .emotion: return "💭 情绪探索"
        case .question: return "❓ 未解问题"
        case .intention: return "🎯 意图设定"
        case .gratitude: return "🙏 感恩记录"
        }
    }
    
    var icon: String {
        switch self {
        case .insight: return "💡"
        case .connection: return "🔗"
        case .emotion: return "💭"
        case .question: return "❓"
        case .intention: return "🎯"
        case .gratitude: return "🙏"
        }
    }
    
    var color: String {
        switch self {
        case .insight: return "FFD700"
        case .connection: return "4A90E2"
        case .emotion: return "E91E63"
        case .question: return "9B59B6"
        case .intention: return "2ECC71"
        case .gratitude: return "F39C12"
        }
    }
}

// MARK: - 反思提示模板

/// 反思提示模板
struct ReflectionPrompt: Identifiable, Codable {
    let id: String
    let type: ReflectionType
    let question: String
    let description: String
    let example: String?
    let category: PromptCategory
    
    enum PromptCategory: String, CaseIterable {
        case general = "通用"
        case emotion = "情绪"
        case symbol = "符号"
        case life = "生活"
        case growth = "成长"
    }
}

// MARK: - 梦境反思模型

/// 梦境反思主模型
@Model
final class DreamReflection {
    var id: UUID
    var dreamId: UUID
    var type: String
    var content: String
    var tags: [String]
    var rating: Int  // 1-5 重要性评分
    var isPrivate: Bool
    var createdAt: Date
    var updatedAt: Date
    var relatedLifeEvents: [String]  // 关联的现实事件
    var actionItems: [String]  // 行动项
    var followUpDate: Date?  // 跟进日期
    
    @Relationship var dream: Dream?
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        type: ReflectionType,
        content: String,
        tags: [String] = [],
        rating: Int = 3,
        isPrivate: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        relatedLifeEvents: [String] = [],
        actionItems: [String] = [],
        followUpDate: Date? = nil,
        dream: Dream? = nil
    ) {
        self.id = id
        self.dreamId = dreamId
        self.type = type.rawValue
        self.content = content
        self.tags = tags
        self.rating = rating
        self.isPrivate = isPrivate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.relatedLifeEvents = relatedLifeEvents
        self.actionItems = actionItems
        self.followUpDate = followUpDate
        self.dream = dream
    }
    
    var reflectionType: ReflectionType {
        ReflectionType(rawValue: type) ?? .insight
    }
    
    var displayTags: String {
        tags.joined(separator: " ")
    }
    
    var hasActionItems: Bool {
        !actionItems.isEmpty
    }
    
    var needsFollowUp: Bool {
        guard let followUp = followUpDate else { return false }
        return followUp > Date()
    }
}

// MARK: - 反思维度统计

/// 反思维度统计
struct ReflectionStats {
    let totalReflections: Int
    let byType: [ReflectionType: Int]
    let byRating: [Int: Int]  // rating -> count
    let averageRating: Double
    let reflectionsThisWeek: Int
    let reflectionsThisMonth: Int
    let mostUsedTags: [(tag: String, count: Int)]
    let reflectionStreak: Int  // 连续反思天数
    let totalActionItems: Int
    let completedActionItems: Int
    
    var completionRate: Double {
        guard totalActionItems > 0 else { return 0 }
        return Double(completedActionItems) / Double(totalActionItems) * 100
    }
}

// MARK: - 洞察卡片

/// 洞察卡片 - 用于展示重要洞察
struct ReflectionInsightCard: Identifiable, Codable {
    let id: String
    let reflectionId: UUID
    let dreamTitle: String
    let insight: String
    let type: ReflectionType
    let createdAt: Date
    let rating: Int
    let tags: [String]
    
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }
}

// MARK: - 反思导出模型

/// 反思导出配置
struct ReflectionExportConfig: Codable {
    var includePrivate: Bool
    var dateRange: DateRange
    var types: [ReflectionType]
    var format: ExportFormat
    
    enum DateRange: Codable {
        case all
        case last7Days
        case last30Days
        case last3Months
        case custom(start: Date, end: Date)
    }
    
    enum ExportFormat: Codable {
        case pdf
        case markdown
        case json
    }
    
    static var `default`: ReflectionExportConfig {
        ReflectionExportConfig(
            includePrivate: false,
            dateRange: .all,
            types: ReflectionType.allCases,
            format: .markdown
        )
    }
}

// MARK: - 预设提示模板

extension ReflectionPrompt {
    static let defaultPrompts: [ReflectionPrompt] = [
        // 洞察领悟
        ReflectionPrompt(
            id: "insight_1",
            type: .insight,
            question: "这个梦境让我意识到了什么？",
            description: "记录从梦境中获得的新认识或领悟",
            example: "我意识到我一直在逃避某个问题...",
            category: .general
        ),
        ReflectionPrompt(
            id: "insight_2",
            type: .insight,
            question: "梦境中的符号对我意味着什么？",
            description: "探索梦境符号的个人含义",
            example: "水在我的梦中总是代表情绪...",
            category: .symbol
        ),
        
        // 现实关联
        ReflectionPrompt(
            id: "connection_1",
            type: .connection,
            question: "这个梦境与我最近的什么经历有关？",
            description: "连接梦境内容与现实生活",
            example: "梦中的追逐场景让我想起最近的工作压力...",
            category: .life
        ),
        ReflectionPrompt(
            id: "connection_2",
            type: .connection,
            question: "梦境反映了我当前的什么状态？",
            description: "反思梦境与当前生活状态的关联",
            example: "飞翔的梦出现在我感到自由的时期...",
            category: .life
        ),
        
        // 情绪探索
        ReflectionPrompt(
            id: "emotion_1",
            type: .emotion,
            question: "梦境中的情绪如何影响我醒来后的感受？",
            description: "探索梦境情绪的延续效应",
            example: "醒来后仍然感到焦虑...",
            category: .emotion
        ),
        ReflectionPrompt(
            id: "emotion_2",
            type: .emotion,
            question: "这个梦境帮我处理了什么情绪？",
            description: "识别梦境的情绪疗愈功能",
            example: "梦帮我释放了积压的愤怒...",
            category: .emotion
        ),
        
        // 未解问题
        ReflectionPrompt(
            id: "question_1",
            type: .question,
            question: "这个梦境还有什么让我困惑的地方？",
            description: "记录需要进一步探索的问题",
            example: "为什么梦中会出现那个陌生人？",
            category: .general
        ),
        
        // 意图设定
        ReflectionPrompt(
            id: "intention_1",
            type: .intention,
            question: "基于这个梦境，我想在生活中做出什么改变？",
            description: "将梦境洞察转化为行动意图",
            example: "我要更多地关注自己的情绪需求...",
            category: .growth
        ),
        ReflectionPrompt(
            id: "intention_2",
            type: .intention,
            question: "今晚入睡前我想带着什么意图？",
            description: "设定睡前意图",
            example: "今晚我希望能梦见指引...",
            category: .growth
        ),
        
        // 感恩记录
        ReflectionPrompt(
            id: "gratitude_1",
            type: .gratitude,
            question: "这个梦境让我感激什么？",
            description: "记录从梦境中获得的礼物",
            example: "感激我的潜意识给我这个启示...",
            category: .growth
        )
    ]
}
