//
//  DreamChallengeModels.swift
//  DreamLog
//
//  Phase 58 - 梦境挑战系统
//  创建时间：2026-03-16
//

import Foundation
import SwiftData
import UIKit

// MARK: - 挑战类型

/// 挑战类型枚举
enum ChallengeType: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"           // 每日挑战
    case weekly = "weekly"         // 每周挑战
    case special = "special"       // 特殊挑战
    case achievement = "achievement" // 成就挑战
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "每日挑战"
        case .weekly: return "每周挑战"
        case .special: return "特殊挑战"
        case .achievement: return "成就挑战"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "📅"
        case .weekly: return "📆"
        case .special: return "⭐"
        case .achievement: return "🏆"
        }
    }
    
    var duration: Duration {
        switch self {
        case .daily: return .day
        case .weekly: return .week
        case .special: return .custom
        case .achievement: return .lifetime
        }
    }
}

enum Duration: String, Codable, CaseIterable {
    case hour = "hour"
    case day = "day"
    case week = "week"
    case month = "month"
    case custom = "custom"
    case lifetime = "lifetime"
    
    var displayName: String {
        switch self {
        case .hour: return "小时"
        case .day: return "天"
        case .week: return "周"
        case .month: return "月"
        case .custom: return "自定义"
        case .lifetime: return "永久"
        }
    }
}

// MARK: - 挑战类别

/// 挑战类别
enum ChallengeCategory: String, Codable, CaseIterable, Identifiable {
    case recording = "recording"       // 记录挑战
    case lucid = "lucid"              // 清醒梦挑战
    case reflection = "reflection"     // 反思挑战
    case creativity = "creativity"     // 创意挑战
    case social = "social"            // 社交挑战
    case streak = "streak"            // 连续挑战
    case exploration = "exploration"   // 探索挑战
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .recording: return "记录挑战"
        case .lucid: return "清醒梦挑战"
        case .reflection: return "反思挑战"
        case .creativity: return "创意挑战"
        case .social: return "社交挑战"
        case .streak: return "连续挑战"
        case .exploration: return "探索挑战"
        }
    }
    
    var icon: String {
        switch self {
        case .recording: return "🎤"
        case .lucid: return "🌙"
        case .reflection: return "🧘"
        case .creativity: return "🎨"
        case .social: return "👥"
        case .streak: return "🔥"
        case .exploration: return "🔍"
        }
    }
    
    var description: String {
        switch self {
        case .recording: return "提升梦境记录频率和质量"
        case .lucid: return "培养清醒梦能力"
        case .reflection: return "深度反思梦境含义"
        case .creativity: return "激发创意灵感"
        case .social: return "与他人分享梦境"
        case .streak: return "保持连续记录习惯"
        case .exploration: return "探索新的梦境领域"
        }
    }
}

// MARK: - 挑战难度

/// 挑战难度等级
enum ChallengeDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    case expert = "expert"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .expert: return "专家"
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "⭐"
        case .medium: return "⭐⭐"
        case .hard: return "⭐⭐⭐"
        case .expert: return "⭐⭐⭐⭐"
        }
    }
    
    var pointsMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .expert: return 3.0
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "#4CAF50"
        case .medium: return "#FF9800"
        case .hard: return "#F44336"
        case .expert: return "#9C27B0"
        }
    }
}

// MARK: - 挑战进度

/// 挑战进度状态
enum ChallengeProgressStatus: String, Codable, CaseIterable {
    case notStarted = "notStarted"
    case inProgress = "inProgress"
    case completed = "completed"
    case failed = "failed"
    case expired = "expired"
    
    var displayName: String {
        switch self {
        case .notStarted: return "未开始"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .expired: return "已过期"
        }
    }
    
    var color: String {
        switch self {
        case .notStarted: return "#9E9E9E"
        case .inProgress: return "#2196F3"
        case .completed: return "#4CAF50"
        case .failed: return "#F44336"
        case .expired: return "#9E9E9E"
        }
    }
}

// MARK: - 挑战数据模型

/// 挑战模板
@Model
final class DreamChallengeTemplate {
    var id: UUID
    var title: String
    var description: String
    var category: ChallengeCategory
    var type: ChallengeType
    var difficulty: ChallengeDifficulty
    var isPreset: Bool
    var isActive: Bool
    
    // 目标配置
    var targetType: ChallengeTargetType
    var targetValue: Int
    var targetUnit: String
    
    // 奖励配置
    var rewardPoints: Int
    var rewardBadgeId: String?
    var rewardTitle: String?
    
    // 时间配置
    var startDate: Date?
    var endDate: Date?
    var durationHours: Int?
    
    // 显示配置
    var icon: String
    var backgroundColor: String
    var sortOrder: Int
    
    // 统计
    var completedCount: Int
    var totalAttempts: Int
    
    createdAt: Date
    updatedAt: Date
    
    init(
        title: String,
        description: String,
        category: ChallengeCategory,
        type: ChallengeType,
        difficulty: ChallengeDifficulty = .medium,
        targetType: ChallengeTargetType = .recordDreams,
        targetValue: Int = 1,
        targetUnit: String = "次",
        rewardPoints: Int = 100,
        rewardBadgeId: String? = nil,
        rewardTitle: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        durationHours: Int? = 24,
        icon: String = "🎯",
        backgroundColor: String = "#6366F1",
        sortOrder: Int = 0,
        isPreset: Bool = true,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.type = type
        self.difficulty = difficulty
        self.targetType = targetType
        self.targetValue = targetValue
        self.targetUnit = targetUnit
        self.rewardPoints = rewardPoints
        self.rewardBadgeId = rewardBadgeId
        self.rewardTitle = rewardTitle
        self.startDate = startDate
        self.endDate = endDate
        self.durationHours = durationHours
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.sortOrder = sortOrder
        self.isPreset = isPreset
        self.isActive = isActive
        self.completedCount = 0
        self.totalAttempts = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 挑战目标类型
enum ChallengeTargetType: String, Codable, CaseIterable {
    case recordDreams = "recordDreams"           // 记录梦境
    case recordWithEmotions = "recordWithEmotions" // 记录带情绪的梦境
    case recordWithTags = "recordWithTags"       // 记录带标签的梦境
    case recordWithAudio = "recordWithAudio"     // 记录带音频的梦境
    case lucidDream = "lucidDream"              // 清醒梦
    case realityCheck = "realityCheck"          // 现实检查
    case meditation = "meditation"              // 冥想
    case shareDream = "shareDream"              // 分享梦境
    case analyzeDream = "analyzeDream"          // 分析梦境
    case incubation = "incubation"              // 梦境孵育
    case streak = "streak"                      // 连续记录
    case exploreCategory = "exploreCategory"    // 探索类别
    
    var displayName: String {
        switch self {
        case .recordDreams: return "记录梦境"
        case .recordWithEmotions: return "记录情绪"
        case .recordWithTags: return "添加标签"
        case .recordWithAudio: return "语音记录"
        case .lucidDream: return "清醒梦"
        case .realityCheck: return "现实检查"
        case .meditation: return "冥想练习"
        case .shareDream: return "分享梦境"
        case .analyzeDream: return "AI 解析"
        case .incubation: return "梦境孵育"
        case .streak: return "连续记录"
        case .exploreCategory: return "探索类别"
        }
    }
    
    var icon: String {
        switch self {
        case .recordDreams: return "📝"
        case .recordWithEmotions: return "😊"
        case .recordWithTags: return "🏷️"
        case .recordWithAudio: return "🎙️"
        case .lucidDream: return "🌟"
        case .realityCheck: return "👀"
        case .meditation: return "🧘"
        case .shareDream: return "📤"
        case .analyzeDream: return "🧠"
        case .incubation: return "🌱"
        case .streak: return "🔥"
        case .exploreCategory: return "🔍"
        }
    }
}

/// 用户挑战实例
@Model
final class UserChallenge {
    var id: UUID
    var templateId: UUID
    var userId: String
    
    // 状态
    var status: ChallengeProgressStatus
    var progress: Int
    var targetProgress: Int
    var isCompleted: Bool
    var isFavorite: Bool
    var isClaimed: Bool // 奖励是否已领取
    
    // 时间
    var startedAt: Date
    var completedAt: Date?
    var expiresAt: Date?
    
    // 进度详情
    var progressDetails: [String] // 记录完成的梦境 ID 等
    
    // 奖励
    var earnedPoints: Int
    var earnedBadgeId: String?
    var earnedTitle: String?
    
    // 统计
    var attemptCount: Int
    
    createdAt: Date
    updatedAt: Date
    
    init(
        templateId: UUID,
        userId: String = "current_user",
        status: ChallengeProgressStatus = .notStarted,
        targetProgress: Int = 1
    ) {
        self.id = UUID()
        self.templateId = templateId
        self.userId = userId
        self.status = status
        self.progress = 0
        self.targetProgress = targetProgress
        self.isCompleted = false
        self.isFavorite = false
        self.isClaimed = false
        self.startedAt = Date()
        self.completedAt = nil
        self.expiresAt = nil
        self.progressDetails = []
        self.earnedPoints = 0
        self.earnedBadgeId = nil
        self.earnedTitle = nil
        self.attemptCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var progressPercentage: Double {
        guard targetProgress > 0 else { return 0 }
        return min(Double(progress) / Double(targetProgress), 1.0)
    }
}

// MARK: - 成就徽章

/// 成就徽章
@Model
final class AchievementBadge {
    var id: String
    var name: String
    var description: String
    var icon: String
    var category: ChallengeCategory
    var difficulty: ChallengeDifficulty
    var points: Int
    var isUnlocked: Bool
    var unlockedAt: Date?
    var requirementDescription: String
    
    // 统计
    var unlockCount: Int // 全局解锁次数
    
    createdAt: Date
    
    init(
        id: String,
        name: String,
        description: String,
        icon: String,
        category: ChallengeCategory,
        difficulty: ChallengeDifficulty = .medium,
        points: Int = 100,
        requirementDescription: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.difficulty = difficulty
        self.points = points
        self.isUnlocked = false
        self.unlockedAt = nil
        self.requirementDescription = requirementDescription
        self.unlockCount = 0
        self.createdAt = Date()
    }
}

// MARK: - 挑战统计

/// 挑战统计数据
@Model
final class ChallengeStats {
    var id: UUID
    var userId: String
    
    // 总体统计
    var totalChallengesCompleted: Int
    var totalPointsEarned: Int
    var totalBadgesEarned: Int
    var currentStreak: Int
    var longestStreak: Int
    
    // 按类别统计
    var recordingChallengesCompleted: Int
    var lucidChallengesCompleted: Int
    var reflectionChallengesCompleted: Int
    var creativityChallengesCompleted: Int
    var socialChallengesCompleted: Int
    var streakChallengesCompleted: Int
    var explorationChallengesCompleted: Int
    
    // 按难度统计
    var easyCompleted: Int
    var mediumCompleted: Int
    var hardCompleted: Int
    var expertCompleted: Int
    
    // 时间统计
    var todayCompleted: Int
    var weekCompleted: Int
    var monthCompleted: Int
    
    createdAt: Date
    updatedAt: Date
    
    init(userId: String = "current_user") {
        self.id = UUID()
        self.userId = userId
        self.totalChallengesCompleted = 0
        self.totalPointsEarned = 0
        self.totalBadgesEarned = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.recordingChallengesCompleted = 0
        self.lucidChallengesCompleted = 0
        self.reflectionChallengesCompleted = 0
        self.creativityChallengesCompleted = 0
        self.socialChallengesCompleted = 0
        self.streakChallengesCompleted = 0
        self.explorationChallengesCompleted = 0
        self.easyCompleted = 0
        self.mediumCompleted = 0
        self.hardCompleted = 0
        self.expertCompleted = 0
        self.todayCompleted = 0
        self.weekCompleted = 0
        self.monthCompleted = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 预设挑战模板

extension DreamChallengeTemplate {
    static var presetTemplates: [DreamChallengeTemplate] {
        [
            // 记录挑战
            DreamChallengeTemplate(
                title: "晨间记录者",
                description: "在起床后 1 小时内记录一个梦境",
                category: .recording,
                type: .daily,
                difficulty: .easy,
                targetType: .recordDreams,
                targetValue: 1,
                rewardPoints: 50,
                icon: "🌅",
                backgroundColor: "#FF9800"
            ),
            
            DreamChallengeTemplate(
                title: "一周记录达人",
                description: "连续 7 天每天记录至少一个梦境",
                category: .streak,
                type: .weekly,
                difficulty: .medium,
                targetType: .streak,
                targetValue: 7,
                rewardPoints: 300,
                rewardBadgeId: "streak_master",
                icon: "📆",
                backgroundColor: "#2196F3"
            ),
            
            DreamChallengeTemplate(
                title: "情绪观察者",
                description: "记录 5 个带有详细情绪标注的梦境",
                category: .recording,
                type: .special,
                difficulty: .medium,
                targetType: .recordWithEmotions,
                targetValue: 5,
                rewardPoints: 200,
                icon: "😊",
                backgroundColor: "#E91E63"
            ),
            
            // 清醒梦挑战
            DreamChallengeTemplate(
                title: "清醒梦初体验",
                description: "完成第一次清醒梦记录",
                category: .lucid,
                type: .achievement,
                difficulty: .hard,
                targetType: .lucidDream,
                targetValue: 1,
                rewardPoints: 500,
                rewardBadgeId: "lucid_first",
                icon: "🌟",
                backgroundColor: "#9C27B0"
            ),
            
            DreamChallengeTemplate(
                title: "现实检查大师",
                description: "完成 20 次现实检查练习",
                category: .lucid,
                type: .special,
                difficulty: .medium,
                targetType: .realityCheck,
                targetValue: 20,
                rewardPoints: 250,
                icon: "👀",
                backgroundColor: "#673AB7"
            ),
            
            // 反思挑战
            DreamChallengeTemplate(
                title: "深度思考者",
                description: "对 3 个梦境进行 AI 解析和反思",
                category: .reflection,
                type: .special,
                difficulty: .medium,
                targetType: .analyzeDream,
                targetValue: 3,
                rewardPoints: 200,
                icon: "🧠",
                backgroundColor: "#3F51B5"
            ),
            
            // 创意挑战
            DreamChallengeTemplate(
                title: "创意启发",
                description: "基于梦境灵感完成一次创意练习",
                category: .creativity,
                type: .special,
                difficulty: .easy,
                targetType: .incubation,
                targetValue: 1,
                rewardPoints: 150,
                icon: "🎨",
                backgroundColor: "#00BCD4"
            ),
            
            // 社交挑战
            DreamChallengeTemplate(
                title: "分享使者",
                description: "分享第一个梦境到社区",
                category: .social,
                type: .achievement,
                difficulty: .easy,
                targetType: .shareDream,
                targetValue: 1,
                rewardPoints: 100,
                rewardBadgeId: "first_share",
                icon: "📤",
                backgroundColor: "#4CAF50"
            ),
            
            // 探索挑战
            DreamChallengeTemplate(
                title: "标签收集家",
                description: "在梦境中使用 10 个不同的标签",
                category: .exploration,
                type: .special,
                difficulty: .medium,
                targetType: .recordWithTags,
                targetValue: 10,
                rewardPoints: 200,
                icon: "🏷️",
                backgroundColor: "#FF5722"
            ),
            
            // 连续挑战
            DreamChallengeTemplate(
                title: "30 天挑战",
                description: "连续 30 天记录梦境",
                category: .streak,
                type: .special,
                difficulty: .expert,
                targetType: .streak,
                targetValue: 30,
                rewardPoints: 1000,
                rewardBadgeId: "monthly_warrior",
                icon: "🔥",
                backgroundColor: "#F44336"
            )
        ]
    }
}

// MARK: - 预设徽章

extension AchievementBadge {
    static var presetBadges: [AchievementBadge] {
        [
            AchievementBadge(
                id: "first_dream",
                name: "初次记录",
                description: "完成第一个梦境记录",
                icon: "🎉",
                category: .recording,
                difficulty: .easy,
                points: 50,
                requirementDescription: "记录 1 个梦境"
            ),
            
            AchievementBadge(
                id: "streak_master",
                name: "坚持大师",
                description: "连续 7 天记录梦境",
                icon: "🔥",
                category: .streak,
                difficulty: .medium,
                points: 300,
                requirementDescription: "连续记录 7 天"
            ),
            
            AchievementBadge(
                id: "lucid_first",
                name: "清醒觉醒",
                description: "完成第一次清醒梦记录",
                icon: "🌟",
                category: .lucid,
                difficulty: .hard,
                points: 500,
                requirementDescription: "记录 1 个清醒梦"
            ),
            
            AchievementBadge(
                id: "first_share",
                name: "分享先锋",
                description: "第一次分享梦境",
                icon: "📤",
                category: .social,
                difficulty: .easy,
                points: 100,
                requirementDescription: "分享 1 个梦境"
            ),
            
            AchievementBadge(
                id: "monthly_warrior",
                name: "月度勇士",
                description: "连续 30 天记录梦境",
                icon: "🏆",
                category: .streak,
                difficulty: .expert,
                points: 1000,
                requirementDescription: "连续记录 30 天"
            ),
            
            AchievementBadge(
                id: "emotion_expert",
                name: "情绪专家",
                description: "记录 50 个带情绪的梦境",
                icon: "😊",
                category: .recording,
                difficulty: .hard,
                points: 400,
                requirementDescription: "记录 50 个带情绪的梦境"
            ),
            
            AchievementBadge(
                id: "tag_collector",
                name: "标签收集家",
                description: "使用 100 个不同的标签",
                icon: "🏷️",
                category: .exploration,
                difficulty: .hard,
                points: 350,
                requirementDescription: "使用 100 个不同标签"
            ),
            
            AchievementBadge(
                id: "meditation_master",
                name: "冥想大师",
                description: "完成 30 次梦境冥想",
                icon: "🧘",
                category: .reflection,
                difficulty: .hard,
                points: 400,
                requirementDescription: "完成 30 次冥想"
            )
        ]
    }
}
