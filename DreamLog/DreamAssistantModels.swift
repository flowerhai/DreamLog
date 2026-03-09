//
//  DreamAssistantModels.swift
//  DreamLog
//
//  梦境 AI 助手数据模型
//  Phase 13 - AI 助手
//

import Foundation

// MARK: - 聊天消息模型

/// 聊天消息
struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    let content: String
    let sender: MessageSender
    let timestamp: Date
    let type: MessageType
    let relatedDreams: [UUID]?  // 关联的梦境 ID
    
    init(
        id: UUID = UUID(),
        content: String,
        sender: MessageSender,
        timestamp: Date = Date(),
        type: MessageType = .text,
        relatedDreams: [UUID]? = nil
    ) {
        self.id = id
        self.content = content
        self.sender = sender
        self.timestamp = timestamp
        self.type = type
        self.relatedDreams = relatedDreams
    }
}

/// 消息发送者
enum MessageSender: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

/// 消息类型
enum MessageType: String, Codable {
    case text = "text"
    case suggestion = "suggestion"  // 建议芯片
    case dreamCard = "dreamCard"    // 梦境卡片
    case insight = "insight"        // 洞察卡片
    case quickAction = "quickAction" // 快速操作
}

// MARK: - 建议芯片

/// 建议芯片 - 用户可点击的快速问题
struct SuggestionChip: Identifiable, Hashable {
    let id: UUID
    let title: String
    let query: String
    let icon: String
    
    init(id: UUID = UUID(), title: String, query: String, icon: String = "questionmark.circle") {
        self.id = id
        self.title = title
        self.query = query
        self.icon = icon
    }
}

// MARK: - 快速操作

/// 快速操作
struct QuickAction: Identifiable, Hashable {
    let id: UUID
    let title: String
    let icon: String
    let action: QuickActionType
    
    init(id: UUID = UUID(), title: String, icon: String, action: QuickActionType) {
        self.id = id
        self.title = title
        self.icon = icon
        self.action = action
    }
}

/// 快速操作类型
enum QuickActionType: Hashable {
    case recordDream      // 记录新梦境
    case viewStats        // 查看统计
    case browseGallery    // 浏览画廊
    case searchDreams     // 搜索梦境
    case lucidTraining    // 清醒梦训练
    case meditation       // 冥想
}

// MARK: - 洞察卡片

/// 洞察卡片数据
struct InsightCard: Identifiable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let value: String?
    let trend: TrendDirection?
    let color: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        icon: String,
        value: String? = nil,
        trend: TrendDirection? = nil,
        color: String = "accent"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.value = value
        self.trend = trend
        self.color = color
    }
}

/// 趋势方向
enum TrendDirection: String, Codable {
    case up = "up"
    case down = "down"
    case stable = "stable"
}

// MARK: - 助手状态

/// 助手状态
enum AssistantState {
    case idle
    case listening    // 正在听写
    case thinking     // 正在思考
    case speaking     // 正在朗读回复
}

// MARK: - 查询意图

/// 用户查询意图
enum QueryIntent {
    case searchDreams(keyword: String)
    case askStats(period: String)
    case askPattern(topic: String)
    case askRecommendation
    case askHelp
    case recordDream
    case unknown
    
    static func parse(_ query: String) -> QueryIntent {
        let lowercased = query.lowercased()
        
        if lowercased.contains("搜索") || lowercased.contains("找") {
            return .searchDreams(keyword: query)
        }
        if lowercased.contains("统计") || lowercased.contains("多少") || lowercased.contains("几个") {
            return .askStats(period: query)
        }
        if lowercased.contains("模式") || lowercased.contains("趋势") || lowercased.contains("经常") {
            return .askPattern(topic: query)
        }
        if lowercased.contains("推荐") || lowercased.contains("建议") {
            return .askRecommendation
        }
        if lowercased.contains("帮助") || lowercased.contains("怎么") || lowercased.contains("如何") {
            return .askHelp
        }
        if lowercased.contains("记录") || lowercased.contains("写梦") {
            return .recordDream
        }
        
        return .unknown
    }
}
