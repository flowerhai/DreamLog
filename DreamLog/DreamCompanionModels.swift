//
//  DreamCompanionModels.swift
//  DreamLog
//
//  Phase 56 - 梦境 AI 伙伴系统
//  数据模型
//

import Foundation
import SwiftData

// MARK: - 对话类型

/// AI 伙伴对话类型
enum CompanionMessageType: String, CaseIterable, Codable {
    case greeting = "greeting"               // 问候
    case interpretation = "interpretation"   // 解析
    case question = "question"               // 提问
    case insight = "insight"                 // 洞察
    case suggestion = "suggestion"           // 建议
    case followup = "followup"               // 追问
    case encouragement = "encouragement"     // 鼓励
    case reflection = "reflection"           // 反思
    
    var displayName: String {
        switch self {
        case .greeting: return "👋 问候"
        case .interpretation: return "🔮 解析"
        case .question: return "❓ 提问"
        case .insight: return "💡 洞察"
        case .suggestion: return "💭 建议"
        case .followup: return "🔄 追问"
        case .encouragement: return "✨ 鼓励"
        case .reflection: return "🪞 反思"
        }
    }
}

// MARK: - 对话情感

/// AI 伙伴对话情感
enum CompanionTone: String, CaseIterable, Codable {
    case warm = "warm"           // 温暖
    case curious = "curious"     // 好奇
    case supportive = "supportive" // 支持
    case analytical = "analytical" // 分析
    case playful = "playful"     // 轻松
    case thoughtful = "thoughtful" // 深思
    
    var displayName: String {
        switch self {
        case .warm: return "🌟 温暖"
        case .curious: return "🤔 好奇"
        case .supportive: return "💪 支持"
        case .analytical: return "🧠 分析"
        case .playful: return "😊 轻松"
        case .thoughtful: return "💭 深思"
        }
    }
}

// MARK: - 对话消息模型

/// AI 伙伴对话消息
@Model
class CompanionMessage {
    var id: UUID
    var sessionId: UUID
    var messageType: CompanionMessageType
    var tone: CompanionTone
    var content: String
    var dreamId: UUID?
    var timestamp: Date
    var isFromUser: Bool
    var metadata: [String: String]?
    
    init(
        id: UUID = UUID(),
        sessionId: UUID,
        messageType: CompanionMessageType,
        tone: CompanionTone = .warm,
        content: String,
        dreamId: UUID? = nil,
        timestamp: Date = Date(),
        isFromUser: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.messageType = messageType
        self.tone = tone
        self.content = content
        self.dreamId = dreamId
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.metadata = metadata
    }
}

// MARK: - 对话会话模型

/// AI 伙伴对话会话
@Model
class CompanionSession {
    var id: UUID
    var title: String
    var dreamId: UUID?
    var topic: String
    var createdAt: Date
    var updatedAt: Date
    var messageCount: Int
    var isArchived: Bool
    var tags: [String]
    
    @Relationship(deleteRule: .cascade)
    var messages: [CompanionMessage]
    
    init(
        id: UUID = UUID(),
        title: String = "新对话",
        dreamId: UUID? = nil,
        topic: String = "梦境探索",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        messageCount: Int = 0,
        isArchived: Bool = false,
        tags: [String] = [],
        messages: [CompanionMessage] = []
    ) {
        self.id = id
        self.title = title
        self.dreamId = dreamId
        self.topic = topic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
        self.isArchived = isArchived
        self.tags = tags
        self.messages = messages
    }
}

// MARK: - 对话上下文

/// AI 伙伴对话上下文
struct CompanionContext {
    var recentDreams: [DreamSummary]
    var userPreferences: UserPreferences
    var dreamPatterns: DreamPatterns
    var currentMood: String?
    var sessionHistory: [SessionSummary]
    
    struct DreamSummary {
        var id: UUID
        var title: String
        var date: Date
        var emotions: [String]
        var tags: [String]
        var clarity: Int
    }
    
    struct UserPreferences {
        var interpretationStyle: String  // "psychological", "spiritual", "creative"
        var detailLevel: String          // "brief", "detailed", "deep"
        var focusAreas: [String]         // ["emotions", "symbols", "patterns"]
    }
    
    struct DreamPatterns {
        var recurringThemes: [String]
        var commonEmotions: [String]
        var dreamFrequency: String
        var lucidDreamRate: Double
    }
    
    struct SessionSummary {
        var sessionId: UUID
        var topic: String
        var insightsCount: Int
        var lastActive: Date
    }
}

// MARK: - AI 响应模型

/// AI 伙伴响应
struct CompanionResponse {
    var message: String
    var messageType: CompanionMessageType
    var tone: CompanionTone
    var suggestedQuestions: [String]
    var relatedDreams: [UUID]
    var insights: [Insight]
    var actions: [CompanionAction]
    
    struct Insight {
        var title: String
        var description: String
        var confidence: Double
    }
    
    struct CompanionAction {
        var actionType: ActionType
        var title: String
        var icon: String
        
        enum ActionType {
            case viewDream
            case exploreSymbol
            case startMeditation
            case setGoal
            case shareInsight
        }
    }
}

// MARK: - 对话模板

/// AI 伙伴对话模板
struct CompanionTemplate {
    var id: String
    var name: String
    var category: TemplateCategory
    var prompts: [String]
    var responsePatterns: [ResponsePattern]
    
    enum TemplateCategory: String, CaseIterable {
        case interpretation = "interpretation"  // 梦境解析
        case exploration = "exploration"        // 梦境探索
        case reflection = "reflection"          // 梦境反思
        case guidance = "guidance"              // 梦境指导
        case creativity = "creativity"          // 创意启发
    }
    
    struct ResponsePattern {
        var trigger: String
        var response: String
        var followUpQuestions: [String]
    }
}

// MARK: - 预设模板

extension CompanionTemplate {
    static let defaultTemplates: [CompanionTemplate] = [
        CompanionTemplate(
            id: "interpretation_basic",
            name: "基础梦境解析",
            category: .interpretation,
            prompts: [
                "帮我解析这个梦境的含义",
                "这个梦说明了什么？",
                "梦境中的 [符号] 代表什么？"
            ],
            responsePatterns: []
        ),
        CompanionTemplate(
            id: "exploration_deep",
            name: "深度梦境探索",
            category: .exploration,
            prompts: [
                "我想更深入地了解这个梦",
                "这个梦和我的现实生活有什么联系？",
                "梦境中的情绪说明了什么？"
            ],
            responsePatterns: []
        ),
        CompanionTemplate(
            id: "reflection_guided",
            name: "引导式反思",
            category: .reflection,
            prompts: [
                "这个梦让我思考...",
                "我从这个梦中学到了什么？",
                "如何将梦境的启示应用到生活中？"
            ],
            responsePatterns: []
        ),
        CompanionTemplate(
            id: "creativity_inspire",
            name: "创意启发",
            category: .creativity,
            prompts: [
                "这个梦能给我什么创作灵感？",
                "如何将梦境转化为艺术作品？",
                "梦境中的意象可以用于写作吗？"
            ],
            responsePatterns: []
        )
    ]
}

// MARK: - 对话统计

/// AI 伙伴对话统计
struct CompanionStats {
    var totalSessions: Int
    var totalMessages: Int
    var averageSessionLength: Double
    var mostCommonTopics: [String]
    var insightsGenerated: Int
    var userSatisfactionScore: Double?
    var weeklyTrend: [WeeklyStat]
    
    struct WeeklyStat {
        var weekStart: Date
        var sessionsCount: Int
        var messagesCount: Int
        var averageDuration: Double
    }
}

// MARK: - 快速问题

/// AI 伙伴快速问题
struct QuickQuestion {
    var id: String
    var question: String
    var category: QuestionCategory
    var icon: String
    var context: String?
    
    enum QuestionCategory: String, CaseIterable {
        case interpretation = "interpretation"
        case emotion = "emotion"
        case symbol = "symbol"
        case pattern = "pattern"
        case action = "action"
    }
}

extension QuickQuestion {
    static let defaultQuestions: [QuickQuestion] = [
        QuickQuestion(id: "q1", question: "这个梦的主要情绪是什么？", category: .emotion, icon: "💭"),
        QuickQuestion(id: "q2", question: "梦中有什么特别的符号吗？", category: .symbol, icon: "🔮"),
        QuickQuestion(id: "q3", question: "这个梦让我想到了什么？", category: .interpretation, icon: "💡"),
        QuickQuestion(id: "q4", question: "我最近有类似的梦吗？", category: .pattern, icon: "🔄"),
        QuickQuestion(id: "q5", question: "我应该从这个梦中学到什么？", category: .action, icon: "🎯")
    ]
}
