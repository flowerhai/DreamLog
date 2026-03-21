//
//  DreamSmartSuggestionsModels.swift
//  DreamLog - Phase 85: 梦境智能建议与个性化推荐系统
//
//  创建时间：2026-03-22
//  功能：智能建议数据模型
//

import Foundation
import SwiftData

// MARK: - 建议类型

/// 智能建议类型
enum SmartSuggestionType: String, Codable, CaseIterable {
    // 梦境改善类
    case dreamImprovement = "dream_improvement"      // 梦境质量改善
    case lucidDreaming = "lucid_dreaming"            // 清醒梦技巧
    case dreamRecall = "dream_recall"                // 梦境回忆增强
    
    // 睡眠健康类
    case sleepQuality = "sleep_quality"              // 睡眠质量提升
    case sleepSchedule = "sleep_schedule"            // 作息时间建议
    case relaxationTechnique = "relaxation"          // 放松技巧
    
    // 心理健康类
    case stressManagement = "stress_management"      // 压力管理
    case moodImprovement = "mood_improvement"        // 情绪改善
    case mindfulness = "mindfulness"                 // 正念练习
    
    // 创意灵感类
    case creativeInspiration = "creative"            // 创意灵感
    case writingPrompt = "writing_prompt"            // 写作提示
    case artisticExpression = "artistic"             // 艺术表达
    
    // 分析洞察类
    case patternInsight = "pattern_insight"          // 模式洞察
    case symbolExploration = "symbol_exploration"    // 符号探索
    case themeAnalysis = "theme_analysis"            // 主题分析
    
    var displayName: String {
        switch self {
        case .dreamImprovement: return "梦境改善"
        case .lucidDreaming: return "清醒梦技巧"
        case .dreamRecall: return "回忆增强"
        case .sleepQuality: return "睡眠质量"
        case .sleepSchedule: return "作息建议"
        case .relaxationTechnique: return "放松技巧"
        case .stressManagement: return "压力管理"
        case .moodImprovement: return "情绪改善"
        case .mindfulness: return "正念练习"
        case .creativeInspiration: return "创意灵感"
        case .writingPrompt: return "写作提示"
        case .artisticExpression: return "艺术表达"
        case .patternInsight: return "模式洞察"
        case .symbolExploration: return "符号探索"
        case .themeAnalysis: return "主题分析"
        }
    }
    
    var icon: String {
        switch self {
        case .dreamImprovement: return "moon.stars.fill"
        case .lucidDreaming: return "lightbulb.fill"
        case .dreamRecall: return "brain.head.profile"
        case .sleepQuality: return "bed.double.fill"
        case .sleepSchedule: return "clock.fill"
        case .relaxationTechnique: return "sparkles"
        case .stressManagement: return "heart.fill"
        case .moodImprovement: return "smiley.fill"
        case .mindfulness: return "leaf.fill"
        case .creativeInspiration: return "paintbrush.fill"
        case .writingPrompt: return "pencil.tip.crop.circle"
        case .artisticExpression: return "palette.fill"
        case .patternInsight: return "chart.line.uptrend.xyaxis"
        case .symbolExploration: return "eye.fill"
        case .themeAnalysis: return "text.book.closed.fill"
        }
    }
}

// MARK: - 建议优先级

/// 建议优先级
enum SuggestionPriority: Int, Codable, CaseIterable {
    case low = 0      // 低优先级 - 可选阅读
    case medium = 1   // 中优先级 - 推荐尝试
    case high = 2     // 高优先级 - 强烈建议
    
    var displayName: String {
        switch self {
        case .low: return "可选"
        case .medium: return "推荐"
        case .high: return "重要"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "secondary"
        case .medium: return "blue"
        case .high: return "orange"
        }
    }
}

// MARK: - 智能建议模型

/// 智能建议数据模型
@Model
final class SmartSuggestion {
    @Attribute(.unique) var id: UUID
    var title: String                    // 建议标题
    var type: String                     // 建议类型 (SmartSuggestionType.rawValue)
    var priority: Int                    // 优先级 (SuggestionPriority.rawValue)
    var description: String              // 详细描述
    var actionableSteps: [String]        // 可执行步骤
    var expectedBenefit: String          // 预期效果
    var timeCommitment: String           // 时间投入 (e.g., "5-10 分钟", "每日")
    var difficultyLevel: Int             // 难度等级 1-5
    var relatedDreamIds: [UUID]          // 相关梦境 ID
    var basedOnPatterns: [String]        // 基于的模式
    var isDismissed: Bool                // 是否已关闭
    var isCompleted: Bool                // 是否已完成
    var completedAt: Date?               // 完成时间
    var dismissedAt: Date?               // 关闭时间
    var createdAt: Date                  // 创建时间
    var expiresAt: Date?                 // 过期时间 (可选)
    var viewCount: Int                   // 查看次数
    var helpfulness: Int                 // 有用性评分 1-5
    
    init(
        title: String,
        type: SmartSuggestionType,
        priority: SuggestionPriority,
        description: String,
        actionableSteps: [String],
        expectedBenefit: String,
        timeCommitment: String,
        difficultyLevel: Int = 3,
        relatedDreamIds: [UUID] = [],
        basedOnPatterns: [String] = [],
        expiresAt: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.type = type.rawValue
        self.priority = priority.rawValue
        self.description = description
        self.actionableSteps = actionableSteps
        self.expectedBenefit = expectedBenefit
        self.timeCommitment = timeCommitment
        self.difficultyLevel = difficultyLevel
        self.relatedDreamIds = relatedDreamIds
        self.basedOnPatterns = basedOnPatterns
        self.isDismissed = false
        self.isCompleted = false
        self.createdAt = Date()
        self.expiresAt = expiresAt
        self.viewCount = 0
        self.helpfulness = 0
    }
    
    var typedType: SmartSuggestionType? {
        SmartSuggestionType(rawValue: type)
    }
    
    var typedPriority: SuggestionPriority {
        SuggestionPriority(rawValue: priority) ?? .medium
    }
    
    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
    
    var isActive: Bool {
        !isDismissed && !isCompleted && !isExpired
    }
}

// MARK: - 建议配置

/// 用户建议配置
@Model
final class SuggestionConfig {
    @Attribute(.unique) var id: UUID
    var enabledTypes: [String]           // 启用的建议类型
    var minPriority: Int                 // 最小优先级
    var dailyLimit: Int                  // 每日建议数量限制
    var showNotifications: Bool          // 显示通知
    var notificationTime: String         // 通知时间 (e.g., "08:00")
    var autoGenerateOnPattern: Bool      // 发现模式时自动生成
    var includeEducational: Bool         // 包含教育性内容
    var language: String                 // 语言偏好
    
    init(
        enabledTypes: [SmartSuggestionType] = SmartSuggestionType.allCases,
        minPriority: SuggestionPriority = .low,
        dailyLimit: Int = 5,
        showNotifications: Bool = true,
        notificationTime: String = "08:00",
        autoGenerateOnPattern: Bool = true,
        includeEducational: Bool = true,
        language: String = "zh-CN"
    ) {
        self.id = UUID()
        self.enabledTypes = enabledTypes.map { $0.rawValue }
        self.minPriority = minPriority.rawValue
        self.dailyLimit = dailyLimit
        self.showNotifications = showNotifications
        self.notificationTime = notificationTime
        self.autoGenerateOnPattern = autoGenerateOnPattern
        self.includeEducational = includeEducational
        self.language = language
    }
    
    func isTypeEnabled(_ type: SmartSuggestionType) -> Bool {
        enabledTypes.contains(type.rawValue)
    }
}

// MARK: - 建议统计

/// 建议使用统计
struct SuggestionStats {
    var totalSuggestions: Int            // 总建议数
    var activeSuggestions: Int           // 活跃建议数
    var completedSuggestions: Int        // 已完成数
    var dismissedSuggestions: Int        // 已关闭数
    var avgHelpfulness: Double           // 平均有用性
    var completionRate: Double           // 完成率
    var mostHelpfulType: String?         // 最有帮助的类型
    var suggestionsByType: [String: Int] // 按类型分类
    var suggestionsByPriority: [String: Int] // 按优先级分类
    
    init(
        totalSuggestions: Int = 0,
        activeSuggestions: Int = 0,
        completedSuggestions: Int = 0,
        dismissedSuggestions: Int = 0,
        avgHelpfulness: Double = 0,
        completionRate: Double = 0,
        mostHelpfulType: String? = nil,
        suggestionsByType: [String: Int] = [:],
        suggestionsByPriority: [String: Int] = [:]
    ) {
        self.totalSuggestions = totalSuggestions
        self.activeSuggestions = activeSuggestions
        self.completedSuggestions = completedSuggestions
        self.dismissedSuggestions = dismissedSuggestions
        self.avgHelpfulness = avgHelpfulness
        self.completionRate = completionRate
        self.mostHelpfulType = mostHelpfulType
        self.suggestionsByType = suggestionsByType
        self.suggestionsByPriority = suggestionsByPriority
    }
}

// MARK: - 建议模板

/// 建议模板 (用于生成标准化建议)
struct SuggestionTemplate {
    let type: SmartSuggestionType
    let titleTemplate: String
    let descriptionTemplate: String
    let actionTemplates: [String]
    let benefitTemplate: String
    let timeCommitment: String
    let difficultyLevel: Int
    let applicablePatterns: [String]
    
    func generate(
        variables: [String: String],
        relatedDreamIds: [UUID] = [],
        basedOnPatterns: [String] = []
    ) -> SmartSuggestion {
        var title = titleTemplate
        var description = descriptionTemplate
        var benefit = benefitTemplate
        
        for (key, value) in variables {
            title = title.replacingOccurrences(of: "{\(key)}", with: value)
            description = description.replacingOccurrences(of: "{\(key)}", with: value)
            benefit = benefit.replacingOccurrences(of: "{\(key)}", with: value)
        }
        
        let actions = actionTemplates.map { template in
            var action = template
            for (key, value) in variables {
                action = action.replacingOccurrences(of: "{\(key)}", with: value)
            }
            return action
        }
        
        return SmartSuggestion(
            title: title,
            type: type,
            priority: .medium,
            description: description,
            actionableSteps: actions,
            expectedBenefit: benefit,
            timeCommitment: timeCommitment,
            difficultyLevel: difficultyLevel,
            relatedDreamIds: relatedDreamIds,
            basedOnPatterns: basedOnPatterns
        )
    }
}

// MARK: - 建议生成上下文

/// 建议生成上下文
struct SuggestionContext {
    var recentDreams: [Dream]              // 最近的梦境
    var dreamPatterns: [String]            // 梦境模式
    var sleepQuality: Double               // 睡眠质量 (0-1)
    var stressLevel: Double                // 压力水平 (0-1)
    var moodTrend: String                  // 情绪趋势
    var lucidDreamFrequency: Double        // 清醒梦频率
    var dreamRecallRate: Double            // 梦境回忆率
    var commonSymbols: [String]            // 常见符号
    var commonThemes: [String]             // 常见主题
    var userGoals: [String]                // 用户目标
    var config: SuggestionConfig           // 用户配置
    
    init(
        recentDreams: [Dream] = [],
        dreamPatterns: [String] = [],
        sleepQuality: Double = 0.5,
        stressLevel: Double = 0.5,
        moodTrend: String = "stable",
        lucidDreamFrequency: Double = 0,
        dreamRecallRate: Double = 0.5,
        commonSymbols: [String] = [],
        commonThemes: [String] = [],
        userGoals: [String] = [],
        config: SuggestionConfig = SuggestionConfig()
    ) {
        self.recentDreams = recentDreams
        self.dreamPatterns = dreamPatterns
        self.sleepQuality = sleepQuality
        self.stressLevel = stressLevel
        self.moodTrend = moodTrend
        self.lucidDreamFrequency = lucidDreamFrequency
        self.dreamRecallRate = dreamRecallRate
        self.commonSymbols = commonSymbols
        self.commonThemes = commonThemes
        self.userGoals = userGoals
        self.config = config
    }
}

// MARK: - Dream 模型引用 (简化版)

/// Dream 模型引用 (实际使用项目中的 Dream 模型)
@Model
final class Dream {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var date: Date
    var mood: String?
    var tags: [String]
    
    init(title: String, content: String, date: Date = Date(), mood: String? = nil, tags: [String] = []) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.date = date
        self.mood = mood
        self.tags = tags
    }
}
