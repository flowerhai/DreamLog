//
//  DreamMorningReflectionModels.swift
//  DreamLog
//
//  Phase 79: Morning Reflection Guide - 晨间反思引导
//  晨间反思数据模型
//

import Foundation
import SwiftData

// MARK: - 反思类型

/// 晨间反思类型
public enum MorningReflectionType: String, CaseIterable, Codable {
    case gratitude = "gratitude"      // 感恩
    case intention = "intention"      // 意图设定
    case insight = "insight"          // 洞察
    case emotion = "emotion"          // 情绪处理
    case action = "action"            // 行动建议
    case connection = "connection"    // 关联现实
    
    public var icon: String {
        switch self {
        case .gratitude: return "🙏"
        case .intention: return "🎯"
        case .insight: return "💡"
        case .emotion: return "💖"
        case .action: return "✨"
        case .connection: return "🔗"
        }
    }
    
    public var title: String {
        switch self {
        case .gratitude: return "感恩"
        case .intention: return "意图"
        case .insight: return "洞察"
        case .emotion: return "情绪"
        case .action: return "行动"
        case .connection: return "关联"
        }
    }
    
    public var prompt: String {
        switch self {
        case .gratitude: return "从这个梦中，你感恩什么？"
        case .intention: return "这个梦启发你今天如何行动？"
        case .insight: return "这个梦揭示了什么？"
        case .emotion: return "这个梦让你感受到什么？"
        case .action: return "基于这个梦，你今天可以做什么？"
        case .connection: return "这个梦与你现实生活有什么关联？"
        }
    }
}

// MARK: - 晨间反思模型

/// 晨间反思记录
@Model
public final class DreamMorningReflection {
    public var id: UUID
    public var dreamId: UUID?
    public var date: Date
    public var type: MorningReflectionType
    public var content: String
    public var mood: String?
    public var tags: [String]
    public var isCompleted: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        dreamId: UUID? = nil,
        date: Date = Date(),
        type: MorningReflectionType,
        content: String,
        mood: String? = nil,
        tags: [String] = [],
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.dreamId = dreamId
        self.date = date
        self.type = type
        self.content = content
        self.mood = mood
        self.tags = tags
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 反思提示模板

/// 反思提示模板
public struct ReflectionPrompt: Identifiable, Codable {
    public let id: UUID
    public let type: MorningReflectionType
    public let question: String
    public let guidance: String
    public let example: String
    public var isFavorite: Bool
    
    public init(
        id: UUID = UUID(),
        type: MorningReflectionType,
        question: String,
        guidance: String,
        example: String,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.type = type
        self.question = question
        self.guidance = guidance
        self.example = example
        self.isFavorite = isFavorite
    }
    
    // MARK: - 预设提示
    
    public static let defaultPrompts: [ReflectionPrompt] = [
        // 感恩
        ReflectionPrompt(
            type: .gratitude,
            question: "从这个梦中，你感恩什么？",
            guidance: "即使是不安的梦，也可能带来成长的机会。试着找到值得感恩的地方。",
            example: "我感恩这个梦让我意识到我对未知的恐惧，这帮助我更好地理解自己。"
        ),
        // 意图
        ReflectionPrompt(
            type: .intention,
            question: "这个梦启发你今天如何行动？",
            guidance: "梦中的场景或情绪可能暗示你今天的行动方向。",
            example: "梦中我勇敢地面对挑战，今天我也想带着这份勇气去开会。"
        ),
        // 洞察
        ReflectionPrompt(
            type: .insight,
            question: "这个梦揭示了什么？",
            guidance: "梦境往往是潜意识的表达，试着解读其中的象征意义。",
            example: "这个反复出现的梦可能反映了我对变化的抗拒。"
        ),
        // 情绪
        ReflectionPrompt(
            type: .emotion,
            question: "这个梦让你感受到什么？",
            guidance: "允许自己感受梦中的情绪，不评判，只是观察。",
            example: "我感到有些焦虑，但也有一丝兴奋，这可能意味着我即将迎来新的开始。"
        ),
        // 行动
        ReflectionPrompt(
            type: .action,
            question: "基于这个梦，你今天可以做什么？",
            guidance: "将梦境的启发转化为具体的行动。",
            example: "今天我会花 10 分钟冥想，平静内心的不安。"
        ),
        // 关联
        ReflectionPrompt(
            type: .connection,
            question: "这个梦与你现实生活有什么关联？",
            guidance: "寻找梦境与现实生活的连接点，发现潜在的模式。",
            example: "梦中的场景让我想起最近工作中的压力，我需要更好地平衡生活。"
        )
    ]
}

// MARK: - 反思统计

/// 晨间反思统计
public struct MorningReflectionStats: Codable {
    public var totalReflections: Int
    public var completedToday: Int
    public var streakDays: Int
    public var reflectionsByType: [MorningReflectionType: Int]
    public var averageMoodRating: Double?
    public var mostCommonTags: [String]
    
    public init(
        totalReflections: Int = 0,
        completedToday: Int = 0,
        streakDays: Int = 0,
        reflectionsByType: [MorningReflectionType: Int] = [:],
        averageMoodRating: Double? = nil,
        mostCommonTags: [String] = []
    ) {
        self.totalReflections = totalReflections
        self.completedToday = completedToday
        self.streakDays = streakDays
        self.reflectionsByType = reflectionsByType
        self.averageMoodRating = averageMoodRating
        self.mostCommonTags = mostCommonTags
    }
}

// MARK: - 反思配置

/// 晨间反思配置
public struct MorningReflectionConfig: Codable {
    public var enabled: Bool
    public var reminderTime: String // HH:mm 格式
    public var enabledTypes: [MorningReflectionType]
    public var showOnWake: Bool // 醒来时显示
    public var dailyGoal: Int // 每日反思目标
    
    public static let `default` = MorningReflectionConfig(
        enabled: true,
        reminderTime: "07:00",
        enabledTypes: MorningReflectionType.allCases,
        showOnWake: true,
        dailyGoal: 3
    )
}
