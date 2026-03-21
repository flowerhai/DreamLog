//
//  DreamWritingPromptsModels.swift
//  DreamLog - Phase 80: Dream Writing Prompts & Creative Exercises
//
//  Created by DreamLog Team on 2026-03-21.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Writing Prompt Types

/// 写作提示类型
enum WritingPromptType: String, Codable, CaseIterable, Identifiable {
    case continuation = "continuation"        // 续写梦境
    case perspective = "perspective"          // 改变视角
    case alternative = "alternative"          // 平行世界
    case dialogue = "dialogue"                // 对话扩展
    case emotion = "emotion"                  // 情绪探索
    case symbol = "symbol"                    // 符号深度探索
    case prequel = "prequel"                  // 前传故事
    case analysis = "analysis"                // 深度分析
    case creative = "creative"                // 创意写作
    case reflection = "reflection"            // 反思日记
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .continuation: return "续写梦境"
        case .perspective: return "改变视角"
        case .alternative: return "平行世界"
        case .dialogue: return "对话扩展"
        case .emotion: return "情绪探索"
        case .symbol: return "符号探索"
        case .prequel: return "前传故事"
        case .analysis: return "深度分析"
        case .creative: return "创意写作"
        case .reflection: return "反思日记"
        }
    }
    
    var iconName: String {
        switch self {
        case .continuation: return "arrow.right.circle"
        case .perspective: return "eye.circle"
        case .alternative: return "circle.lefthalf.righthalf"
        case .dialogue: return "bubble.left.and.bubble.right"
        case .emotion: return "heart.circle"
        case .symbol: return "star.circle"
        case .prequel: return "arrow.uturn.backward.circle"
        case .analysis: return "magnifyingglass.circle"
        case .creative: return "wand.and.stars"
        case .reflection: return "sparkles"
        }
    }
    
    var description: String {
        switch self {
        case .continuation: return "如果梦境继续下去，会发生什么？"
        case .perspective: return "从另一个角色的视角重新讲述这个梦"
        case .alternative: return "如果在关键节点做了不同选择会怎样？"
        case .dialogue: return "扩展梦中角色之间的对话"
        case .emotion: return "深入探索梦中的情绪变化"
        case .symbol: return "探索梦中关键符号的深层含义"
        case .prequel: return "这个梦境之前发生了什么？"
        case .analysis: return "分析梦境与现实的关联"
        case .creative: return "基于梦境元素创作新故事"
        case .reflection: return "记录对这个梦的思考与感悟"
        }
    }
    
    var difficulty: PromptDifficulty {
        switch self {
        case .continuation, .reflection: return .easy
        case .dialogue, .emotion, .prequel: return .medium
        case .perspective, .alternative, .symbol: return .medium
        case .analysis, .creative: return .hard
        }
    }
}

// MARK: - Difficulty Levels

/// 提示难度等级
enum PromptDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "34C759"
        case .medium: return "FF9500"
        case .hard: return "FF3B30"
        }
    }
    
    var estimatedMinutes: Int {
        switch self {
        case .easy: return 5
        case .medium: return 10
        case .hard: return 20
        }
    }
}

// MARK: - Writing Prompt Model

/// 写作提示
@Model
final class WritingPrompt {
    var id: UUID
    var title: String
    var content: String
    var type: String
    var difficulty: String
    var dreamId: UUID?
    var tags: [String]
    var estimatedMinutes: Int
    var isCompleted: Bool
    var completedAt: Date?
    var wordCount: Int
    var userNotes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        title: String,
        content: String,
        type: WritingPromptType,
        difficulty: PromptDifficulty = .medium,
        dreamId: UUID? = nil,
        tags: [String] = [],
        estimatedMinutes: Int? = nil,
        isCompleted: Bool = false,
        wordCount: Int = 0,
        userNotes: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.type = type.rawValue
        self.difficulty = difficulty.rawValue
        self.dreamId = dreamId
        self.tags = tags
        self.estimatedMinutes = estimatedMinutes ?? difficulty.estimatedMinutes
        self.isCompleted = isCompleted
        self.wordCount = wordCount
        self.userNotes = userNotes
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Writing Exercise Template

/// 写作练习模板
struct WritingExerciseTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let type: WritingPromptType
    let instructions: [String]
    let examplePrompt: String
    let tips: [String]
    let estimatedTime: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: WritingPromptType,
        instructions: [String],
        examplePrompt: String,
        tips: [String] = [],
        estimatedTime: Int
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.instructions = instructions
        self.examplePrompt = examplePrompt
        self.tips = tips
        self.estimatedTime = estimatedTime
    }
}

// MARK: - Writing Statistics

/// 写作统计
struct WritingStatistics: Codable {
    var totalPrompts: Int
    var completedPrompts: Int
    var totalWords: Int
    var streakDays: Int
    var lastWritingDate: Date?
    var promptsByType: [String: Int]
    var averageWordsPerSession: Int
    var favoriteType: WritingPromptType?
    var weeklyGoal: Int
    var weeklyProgress: Int
    
    var completionRate: Double {
        guard totalPrompts > 0 else { return 0 }
        return Double(completedPrompts) / Double(totalPrompts) * 100
    }
    
    var weeklyGoalProgress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return Double(weeklyProgress) / Double(weeklyGoal) * 100
    }
    
    init(
        totalPrompts: Int = 0,
        completedPrompts: Int = 0,
        totalWords: Int = 0,
        streakDays: Int = 0,
        lastWritingDate: Date? = nil,
        promptsByType: [String: Int] = [:],
        averageWordsPerSession: Int = 0,
        favoriteType: WritingPromptType? = nil,
        weeklyGoal: Int = 3,
        weeklyProgress: Int = 0
    ) {
        self.totalPrompts = totalPrompts
        self.completedPrompts = completedPrompts
        self.totalWords = totalWords
        self.streakDays = streakDays
        self.lastWritingDate = lastWritingDate
        self.promptsByType = promptsByType
        self.averageWordsPerSession = averageWordsPerSession
        self.favoriteType = favoriteType
        self.weeklyGoal = weeklyGoal
        self.weeklyProgress = weeklyProgress
    }
}

// MARK: - Writing Session

/// 写作会话记录
@Model
final class WritingSession {
    var id: UUID
    var promptId: UUID
    var startTime: Date
    var endTime: Date?
    var wordCount: Int
    var content: String
    var mood: String?
    var tags: [String]
    var isSaved: Bool
    
    init(
        promptId: UUID,
        startTime: Date = Date(),
        wordCount: Int = 0,
        content: String = "",
        mood: String? = nil,
        tags: [String] = [],
        isSaved: Bool = false
    ) {
        self.id = UUID()
        self.promptId = promptId
        self.startTime = startTime
        self.wordCount = wordCount
        self.content = content
        self.mood = mood
        self.tags = tags
        self.isSaved = isSaved
    }
}

// MARK: - Writing Preferences

/// 写作偏好设置
@Model
final class WritingPreferences {
    var id: UUID
    var dailyGoal: Int
    var weeklyGoal: Int
    var preferredTypes: [String]
    var reminderEnabled: Bool
    var reminderTime: String?
    var autoSaveEnabled: Bool
    var showTips: Bool
    var defaultDifficulty: String
    
    init(
        dailyGoal: Int = 1,
        weeklyGoal: Int = 3,
        preferredTypes: [String] = [],
        reminderEnabled: Bool = false,
        reminderTime: String? = nil,
        autoSaveEnabled: Bool = true,
        showTips: Bool = true,
        defaultDifficulty: String = PromptDifficulty.medium.rawValue
    ) {
        self.id = UUID()
        self.dailyGoal = dailyGoal
        self.weeklyGoal = weeklyGoal
        self.preferredTypes = preferredTypes
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.autoSaveEnabled = autoSaveEnabled
        self.showTips = showTips
        self.defaultDifficulty = defaultDifficulty
    }
}

// MARK: - Prompt Generation Request

/// 提示生成请求
struct PromptGenerationRequest: Codable {
    let dreamContent: String
    let dreamEmotions: [String]
    let dreamTags: [String]
    let preferredType: WritingPromptType?
    let difficulty: PromptDifficulty
    let count: Int
    
    init(
        dreamContent: String,
        dreamEmotions: [String] = [],
        dreamTags: [String] = [],
        preferredType: WritingPromptType? = nil,
        difficulty: PromptDifficulty = .medium,
        count: Int = 3
    ) {
        self.dreamContent = dreamContent
        self.dreamEmotions = dreamEmotions
        self.dreamTags = dreamTags
        self.preferredType = preferredType
        self.difficulty = difficulty
        self.count = count
    }
}

// MARK: - Writing Achievement

/// 写作成就
struct WritingAchievement: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let iconName: String
    let requirement: Int
    var progress: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        iconName: String,
        requirement: Int,
        progress: Int = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.requirement = requirement
        self.progress = progress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
    }
    
    static let allAchievements: [WritingAchievement] = [
        WritingAchievement(
            name: "初次尝试",
            description: "完成第一次写作练习",
            iconName: "pencil.circle",
            requirement: 1
        ),
        WritingAchievement(
            name: "持之以恒",
            description: "连续写作 7 天",
            iconName: "calendar.circle",
            requirement: 7
        ),
        WritingAchievement(
            name: "多产作家",
            description: "完成 10 次写作练习",
            iconName: "book.circle",
            requirement: 10
        ),
        WritingAchievement(
            name: "万字达人",
            description: "累计写作 10000 字",
            iconName: "text.alignleft",
            requirement: 10000
        ),
        WritingAchievement(
            name: "全能写手",
            description: "尝试所有类型的写作提示",
            iconName: "star.circle",
            requirement: 10
        ),
        WritingAchievement(
            name: "深夜作家",
            description: "在深夜完成 5 次写作",
            iconName: "moon.circle",
            requirement: 5
        )
    ]
}
