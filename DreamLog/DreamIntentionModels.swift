//
//  DreamIntentionModels.swift
//  DreamLog - Phase 66: Dream Intention Setting & Manifestation Tracking
//
//  Created by DreamLog Team on 2026/03/19.
//

import Foundation
import SwiftData

// MARK: - Dream Intention Data Models

/// 梦境意图类型
enum DreamIntentionType: String, Codable, CaseIterable {
    case problemSolving = "问题解决"
    case creativity = "创意启发"
    case emotionalHealing = "情绪疗愈"
    case skillPractice = "技能练习"
    case lucidDreaming = "清醒梦诱导"
    case exploration = "探索体验"
    case meeting = "与人相遇"
    case place = "场景体验"
    case custom = "自定义"
    
    var icon: String {
        switch self {
        case .problemSolving: return "🧩"
        case .creativity: return "💡"
        case .emotionalHealing: return "💚"
        case .skillPractice: return "🎯"
        case .lucidDreaming: return "👁️"
        case .exploration: return "🗺️"
        case .meeting: return "👥"
        case .place: return "🏰"
        case .custom: return "⭐"
        }
    }
    
    var color: String {
        switch self {
        case .problemSolving: return "blue"
        case .creativity: return "orange"
        case .emotionalHealing: return "green"
        case .skillPractice: return "red"
        case .lucidDreaming: return "purple"
        case .exploration: return "teal"
        case .meeting: return "pink"
        case .place: return "indigo"
        case .custom: return "gray"
        }
    }
}

/// 意图状态
enum DreamIntentionStatus: String, Codable {
    case active = "进行中"
    case manifested = "已显化"
    case partial = "部分显化"
    case notManifested = "未显化"
    case expired = "已过期"
    case cancelled = "已取消"
}

/// 显化强度
enum ManifestationStrength: Int, Codable {
    case none = 0
    case weak = 1
    case moderate = 2
    case strong = 3
    case exact = 4
    
    var description: String {
        switch self {
        case .none: return "未显化"
        case .weak: return "弱显化"
        case .moderate: return "中等显化"
        case .strong: return "强显化"
        case .exact: return "完全显化"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "⚪"
        case .weak: return "🌑"
        case .moderate: return "🌓"
        case .strong: return "🌕"
        case .exact: return "✨"
        }
    }
}

/// 梦境意图模型
@Model
final class DreamIntention {
    @Attribute(.unique) var id: UUID
    var title: String
    var description: String
    var type: DreamIntentionType
    var status: DreamIntentionStatus
    var createdAt: Date
    var targetDate: Date?
    var completedAt: Date?
    var priority: Int // 1-5
    var affirmation: String? // 肯定语
    var visualizationNotes: String? // 可视化笔记
    var manifestationStrength: Int // 0-4
    var relatedDreamIds: [UUID] // 关联的梦境 ID
    var notes: String? // 备注
    var isRecurring: Bool // 是否重复意图
    var recurrencePattern: String? // 重复模式 (daily, weekly, monthly)
    var successRate: Double // 成功率统计
    var totalAttempts: Int // 总尝试次数
    var successfulManifestations: Int // 成功显化次数
    
    @Relationship(deleteRule: .nullify) var linkedDreams: [Dream]?
    
    init(
        title: String,
        description: String,
        type: DreamIntentionType,
        priority: Int = 3,
        affirmation: String? = nil,
        visualizationNotes: String? = nil,
        targetDate: Date? = nil,
        isRecurring: Bool = false,
        recurrencePattern: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.type = type
        self.status = .active
        self.createdAt = Date()
        self.targetDate = targetDate
        self.priority = priority
        self.affirmation = affirmation
        self.visualizationNotes = visualizationNotes
        self.manifestationStrength = 0
        self.relatedDreamIds = []
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
        self.successRate = 0.0
        self.totalAttempts = 0
        self.successfulManifestations = 0
    }
    
    /// 更新显化状态
    func updateManifestation(strength: ManifestationStrength, dreamIds: [UUID]) {
        self.manifestationStrength = strength.rawValue
        self.relatedDreamIds = dreamIds
        
        if strength == .exact || strength == .strong {
            self.status = .manifested
            self.completedAt = Date()
            self.successfulManifestations += 1
        } else if strength == .moderate {
            self.status = .partial
        } else {
            self.status = .notManifested
        }
        
        self.totalAttempts += 1
        self.successRate = Double(successfulManifestations) / Double(totalAttempts)
    }
    
    /// 检查是否过期
    var isExpired: Bool {
        if let target = targetDate {
            return Date() > target && status == .active
        }
        return false
    }
    
    /// 获取剩余天数
    var daysRemaining: Int? {
        guard let target = targetDate else { return nil }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: Date(), to: target).day
    }
}

/// 意图统计数据
struct DreamIntentionStats {
    var totalIntentions: Int
    var activeIntentions: Int
    var manifestedIntentions: Int
    var partialManifestations: Int
    var overallSuccessRate: Double
    var byType: [DreamIntentionType: Int]
    var recentIntentions: [DreamIntention]
    var streakDays: Int // 连续设置意图天数
    var bestPerformingType: DreamIntentionType?
    
    static var empty: DreamIntentionStats {
        DreamIntentionStats(
            totalIntentions: 0,
            activeIntentions: 0,
            manifestedIntentions: 0,
            partialManifestations: 0,
            overallSuccessRate: 0.0,
            byType: [:],
            recentIntentions: [],
            streakDays: 0,
            bestPerformingType: nil
        )
    }
}

/// 意图建议
struct IntentionSuggestion {
    var title: String
    var description: String
    var type: DreamIntentionType
    var affirmation: String
    var reasoning: String // 推荐原因
    
    static func suggestionsForType(_ type: DreamIntentionType) -> [IntentionSuggestion] {
        // 根据类型返回预设建议
        switch type {
        case .problemSolving:
            return [
                IntentionSuggestion(
                    title: "解决工作难题",
                    description: "在梦中寻求工作问题的解决方案",
                    type: .problemSolving,
                    affirmation: "我的潜意识会帮我找到答案",
                    reasoning: "适合面临复杂决策时"
                ),
                IntentionSuggestion(
                    title: "人际关系困扰",
                    description: "探索人际关系问题的根源",
                    type: .problemSolving,
                    affirmation: "我会在梦中获得清晰的洞察",
                    reasoning: "适合处理人际冲突"
                )
            ]
        case .creativity:
            return [
                IntentionSuggestion(
                    title: "艺术创作灵感",
                    description: "寻求艺术/写作/音乐的创意",
                    type: .creativity,
                    affirmation: "创意会自然流入我的意识",
                    reasoning: "适合创作者突破瓶颈"
                ),
                IntentionSuggestion(
                    title: "创新想法",
                    description: "为项目寻找创新解决方案",
                    type: .creativity,
                    affirmation: "我的思维充满无限可能",
                    reasoning: "适合需要突破性思维时"
                )
            ]
        case .emotionalHealing:
            return [
                IntentionSuggestion(
                    title: "释放焦虑",
                    description: "在梦中处理和释放焦虑情绪",
                    type: .emotionalHealing,
                    affirmation: "我释放所有担忧，拥抱平静",
                    reasoning: "适合压力大的时期"
                ),
                IntentionSuggestion(
                    title: "自我接纳",
                    description: "培养对自己的爱和接纳",
                    type: .emotionalHealing,
                    affirmation: "我完全接纳真实的自己",
                    reasoning: "适合提升自信"
                )
            ]
        case .lucidDreaming:
            return [
                IntentionSuggestion(
                    title: "清醒梦体验",
                    description: "在梦中保持清醒意识",
                    type: .lucidDreaming,
                    affirmation: "我会意识到自己在做梦",
                    reasoning: "适合练习清醒梦"
                ),
                IntentionSuggestion(
                    title: "飞行体验",
                    description: "体验在梦中自由飞翔",
                    type: .lucidDreaming,
                    affirmation: "我可以在梦中自由飞翔",
                    reasoning: "经典的清醒梦体验"
                )
            ]
        default:
            return []
        }
    }
}

// MARK: - Codable Support for SwiftData

extension DreamIntentionType: @retroactive Codable {}
extension DreamIntentionStatus: @retroactive Codable {}
