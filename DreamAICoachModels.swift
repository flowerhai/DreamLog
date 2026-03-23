//
//  DreamAICoachModels.swift
//  DreamLog
//
//  Phase 97: AI 教练 - 数据模型
//  提供个性化数字健康计划、习惯养成追踪、AI 驱动的干预建议
//

import Foundation
import SwiftData

// MARK: - AI 教练核心模型

/// AI 教练计划
@Model
final class DreamAICoachPlan {
    var id: UUID
    var userId: UUID
    var planType: CoachPlanType
    var title: String
    var description: String
    var goals: [CoachGoal]
    var duration: Int // 天数
    var startDate: Date
    var endDate: Date
    var status: CoachPlanStatus
    var progress: Double // 0-100
    var completedDays: Int
    var streak: Int // 连续完成天数
    var lastCompletedDate: Date?
    var habits: [DreamAICoachHabit]
    var interventions: [DreamAICoachIntervention]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        userId: UUID,
        planType: CoachPlanType,
        title: String,
        description: String,
        goals: [CoachGoal],
        duration: Int,
        startDate: Date = Date(),
        status: CoachPlanStatus = .active,
        habits: [DreamAICoachHabit] = [],
        interventions: [DreamAICoachIntervention] = []
    ) {
        self.id = UUID()
        self.userId = userId
        self.planType = planType
        self.title = title
        self.description = description
        self.goals = goals
        self.duration = duration
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? Date()
        self.status = status
        self.progress = 0
        self.completedDays = 0
        self.streak = 0
        self.habits = habits
        self.interventions = interventions
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 教练计划类型
enum CoachPlanType: String, Codable, CaseIterable {
    case sleepImprovement = "sleep_improvement" // 睡眠改善
    case dreamRecall = "dream_recall" // 梦境回忆增强
    case lucidDreaming = "lucid_dreaming" // 清醒梦训练
    case stressReduction = "stress_reduction" // 压力缓解
    case creativityBoost = "creativity_boost" // 创意提升
    case emotionalBalance = "emotional_balance" // 情绪平衡
    case mindfulness = "mindfulness" // 正念练习
    case custom = "custom" // 自定义
    
    var displayName: String {
        switch self {
        case .sleepImprovement: return "睡眠改善计划"
        case .dreamRecall: return "梦境回忆增强"
        case .lucidDreaming: return "清醒梦训练"
        case .stressReduction: return "压力缓解计划"
        case .creativityBoost: return "创意提升计划"
        case .emotionalBalance: return "情绪平衡计划"
        case .mindfulness: return "正念练习计划"
        case .custom: return "自定义计划"
        }
    }
    
    var icon: String {
        switch self {
        case .sleepImprovement: return "moon.stars"
        case .dreamRecall: return "brain.headprofile"
        case .lucidDreaming: return "eye"
        case .stressReduction: return "heart.circle"
        case .creativityBoost: return "lightbulb"
        case .emotionalBalance: return "heart.fill"
        case .mindfulness: return "figure.mind.and.body"
        case .custom: return "star"
        }
    }
}

/// 教练计划状态
enum CoachPlanStatus: String, Codable {
    case draft = "draft" // 草稿
    case active = "active" // 进行中
    case paused = "paused" // 已暂停
    case completed = "completed" // 已完成
    case archived = "archived" // 已归档
}

/// 计划目标
struct CoachGoal: Codable, Identifiable {
    var id: UUID
    var title: String
    var description: String
    var metric: GoalMetric
    var targetValue: Double
    var currentValue: Double
    var unit: String
    var deadline: Date?
    var isCompleted: Bool
    
    init(
        title: String,
        description: String,
        metric: GoalMetric,
        targetValue: Double,
        unit: String,
        deadline: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.metric = metric
        self.targetValue = targetValue
        self.currentValue = 0
        self.unit = unit
        self.deadline = deadline
        self.isCompleted = false
    }
}

/// 目标指标类型
enum GoalMetric: String, Codable {
    case dreamCount = "dream_count" // 梦境数量
    case sleepDuration = "sleep_duration" // 睡眠时长
    case sleepQuality = "sleep_quality" // 睡眠质量
    case dreamRecallRate = "dream_recall_rate" // 梦境回忆率
    case lucidDreamFrequency = "lucid_dream_frequency" // 清醒梦频率
    case meditationMinutes = "meditation_minutes" // 冥想时长
    case stressLevel = "stress_level" // 压力水平
    case moodScore = "mood_score" // 情绪评分
    case habitCompletion = "habit_completion" // 习惯完成率
    case streak = "streak" // 连续天数
}

// MARK: - 习惯追踪模型

/// AI 教练习惯
@Model
final class DreamAICoachHabit {
    var id: UUID
    var planId: UUID
    var habitType: HabitType
    var title: String
    var description: String
    var frequency: HabitFrequency
    var scheduledTime: Date? // 每日计划时间
    var reminderEnabled: Bool
    var reminderTime: Date?
    var completionHistory: [HabitCompletion]
    var streak: Int // 当前连续完成天数
    var longestStreak: Int
    var totalCompletions: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        planId: UUID,
        habitType: HabitType,
        title: String,
        description: String,
        frequency: HabitFrequency,
        scheduledTime: Date? = nil,
        reminderEnabled: Bool = true
    ) {
        self.id = UUID()
        self.planId = planId
        self.habitType = habitType
        self.title = title
        self.description = description
        self.frequency = frequency
        self.scheduledTime = scheduledTime
        self.reminderEnabled = reminderEnabled
        self.completionHistory = []
        self.streak = 0
        self.longestStreak = 0
        self.totalCompletions = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 习惯类型
enum HabitType: String, Codable, CaseIterable {
    case dreamJournal = "dream_journal" // 记录梦境
    case sleepSchedule = "sleep_schedule" // 规律作息
    case meditation = "meditation" // 冥想练习
    case realityCheck = "reality_check" // 现实检查
    case dreamIncubation = "dream_incubation" // 梦境孵化
    case morningReflection = "morning_reflection" // 晨间反思
    case gratitudeJournal = "gratitude_journal" // 感恩日记
    case screenTimeLimit = "screen_time_limit" // 屏幕时间限制
    case caffeineLimit = "caffeine_limit" // 咖啡因限制
    case exercise = "exercise" // 运动
    case breathingExercise = "breathing_exercise" // 呼吸练习
    case custom = "custom" // 自定义
    
    var displayName: String {
        switch self {
        case .dreamJournal: return "记录梦境"
        case .sleepSchedule: return "规律作息"
        case .meditation: return "冥想练习"
        case .realityCheck: return "现实检查"
        case .dreamIncubation: return "梦境孵化"
        case .morningReflection: return "晨间反思"
        case .gratitudeJournal: return "感恩日记"
        case .screenTimeLimit: return "屏幕时间限制"
        case .caffeineLimit: return "咖啡因限制"
        case .exercise: return "运动"
        case .breathingExercise: return "呼吸练习"
        case .custom: return "自定义习惯"
        }
    }
    
    var icon: String {
        switch self {
        case .dreamJournal: return "book"
        case .sleepSchedule: return "bed.double"
        case .meditation: return "figure.mind.and.body"
        case .realityCheck: return "hand.point.up.left"
        case .dreamIncubation: return "lightbulb"
        case .morningReflection: return "sunrise"
        case .gratitudeJournal: return "heart"
        case .screenTimeLimit: return "iphone"
        case .caffeineLimit: return "cup.and.saucer"
        case .exercise: return "figure.run"
        case .breathingExercise: return "wind"
        case .custom: return "star"
        }
    }
}

/// 习惯频率
enum HabitFrequency: String, Codable {
    case daily = "daily" // 每日
    case weekdays = "weekdays" // 工作日
    case weekends = "weekends" // 周末
    case weekly = "weekly" // 每周
    case custom = "custom" // 自定义
    
    var displayName: String {
        switch self {
        case .daily: return "每日"
        case .weekdays: return "工作日"
        case .weekends: return "周末"
        case .weekly: return "每周"
        case .custom: return "自定义"
        }
    }
}

/// 习惯完成记录
struct HabitCompletion: Codable, Identifiable {
    var id: UUID
    var date: Date
    var completedAt: Date
    var notes: String?
    var mood: Int? // 1-5
    var difficulty: Int? // 1-5
    
    init(date: Date, notes: String? = nil, mood: Int? = nil, difficulty: Int? = nil) {
        self.id = UUID()
        self.date = date
        self.completedAt = Date()
        self.notes = notes
        self.mood = mood
        self.difficulty = difficulty
    }
}

// MARK: - AI 干预模型

/// AI 教练干预
@Model
final class DreamAICoachIntervention {
    var id: UUID
    var planId: UUID
    var interventionType: InterventionType
    var title: String
    var message: String
    var triggerReason: String
    var priority: InterventionPriority
    var status: InterventionStatus
    var suggestedAction: String?
    var dismissedAt: Date?
    var completedAt: Date?
    var createdAt: Date
    
    init(
        planId: UUID,
        interventionType: InterventionType,
        title: String,
        message: String,
        triggerReason: String,
        priority: InterventionPriority,
        suggestedAction: String? = nil
    ) {
        self.id = UUID()
        self.planId = planId
        self.interventionType = interventionType
        self.title = title
        self.message = message
        self.triggerReason = triggerReason
        self.priority = priority
        self.status = .pending
        self.suggestedAction = suggestedAction
        self.createdAt = Date()
    }
}

/// 干预类型
enum InterventionType: String, Codable {
    case sleepQualityAlert = "sleep_quality_alert" // 睡眠质量警告
    case stressWarning = "stress_warning" // 压力警告
    case dreamPatternChange = "dream_pattern_change" // 梦境模式变化
    case habitSlip = "habit_slip" // 习惯中断
    case milestoneAchieved = "milestone_achieved" // 达成里程碑
    case encouragement = "encouragement" // 鼓励
    case suggestion = "suggestion" // 建议
    case healthAlert = "health_alert" // 健康警告
    
    var displayName: String {
        switch self {
        case .sleepQualityAlert: return "睡眠质量警告"
        case .stressWarning: return "压力警告"
        case .dreamPatternChange: return "梦境模式变化"
        case .habitSlip: return "习惯中断"
        case .milestoneAchieved: return "达成里程碑"
        case .encouragement: return "鼓励"
        case .suggestion: return "建议"
        case .healthAlert: return "健康警告"
        }
    }
}

/// 干预优先级
enum InterventionPriority: String, Codable {
    case low = "low" // 低
    case medium = "medium" // 中
    case high = "高"
    case urgent = "urgent" // 紧急
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .medium: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

/// 干预状态
enum InterventionStatus: String, Codable {
    case pending = "pending" // 待处理
    case viewed = "viewed" // 已查看
    case dismissed = "dismissed" // 已忽略
    case completed = "completed" // 已完成
}

// MARK: - 统计数据模型

/// AI 教练统计
struct CoachStatistics {
    var totalPlans: Int
    var activePlans: Int
    var completedPlans: Int
    var totalHabits: Int
    var activeHabits: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalCompletions: Int
    var habitCompletionRate: Double
    var averageSleepQuality: Double
    var averageDreamRecall: Double
    var interventionCount: Int
    var milestonesAchieved: Int
    
    static var empty: CoachStatistics {
        CoachStatistics(
            totalPlans: 0,
            activePlans: 0,
            completedPlans: 0,
            totalHabits: 0,
            activeHabits: 0,
            currentStreak: 0,
            longestStreak: 0,
            totalCompletions: 0,
            habitCompletionRate: 0,
            averageSleepQuality: 0,
            averageDreamRecall: 0,
            interventionCount: 0,
            milestonesAchieved: 0
        )
    }
}

/// 每日进度
struct DailyProgress: Identifiable {
    var id: UUID
    var date: Date
    var habitsCompleted: Int
    var habitsTotal: Int
    var sleepDuration: Double?
    var sleepQuality: Int?
    var dreamsRecorded: Int
    var meditationMinutes: Double?
    var moodScore: Int?
    var notes: String?
    
    init(
        date: Date,
        habitsCompleted: Int = 0,
        habitsTotal: Int = 0,
        sleepDuration: Double? = nil,
        sleepQuality: Int? = nil,
        dreamsRecorded: Int = 0,
        meditationMinutes: Double? = nil,
        moodScore: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.habitsCompleted = habitsCompleted
        self.habitsTotal = habitsTotal
        self.sleepDuration = sleepDuration
        self.sleepQuality = sleepQuality
        self.dreamsRecorded = dreamsRecorded
        self.meditationMinutes = meditationMinutes
        self.moodScore = moodScore
        self.notes = notes
    }
}

// MARK: - 预设计划模板

/// 预设教练计划模板
struct CoachPlanTemplate: Identifiable {
    var id: UUID
    var planType: CoachPlanType
    var name: String
    var description: String
    var duration: Int // 天数
    var habits: [HabitTemplate]
    var goals: [GoalTemplate]
    var difficulty: DifficultyLevel
    
    init(
        planType: CoachPlanType,
        name: String,
        description: String,
        duration: Int,
        habits: [HabitTemplate],
        goals: [GoalTemplate],
        difficulty: DifficultyLevel = .medium
    ) {
        self.id = UUID()
        self.planType = planType
        self.name = name
        self.description = description
        self.duration = duration
        self.habits = habits
        self.goals = goals
        self.difficulty = difficulty
    }
}

/// 习惯模板
struct HabitTemplate: Codable {
    var habitType: HabitType
    var title: String
    var description: String
    var frequency: HabitFrequency
    var scheduledTime: String? // HH:mm 格式
    
    init(habitType: HabitType, title: String, description: String, frequency: HabitFrequency = .daily, scheduledTime: String? = nil) {
        self.habitType = habitType
        self.title = title
        self.description = description
        self.frequency = frequency
        self.scheduledTime = scheduledTime
    }
}

/// 目标模板
struct GoalTemplate: Codable {
    var metric: GoalMetric
    var title: String
    var targetValue: Double
    var unit: String
    var deadline: Int? // 天数
    
    init(metric: GoalMetric, title: String, targetValue: Double, unit: String, deadline: Int? = nil) {
        self.metric = metric
        self.title = title
        self.targetValue = targetValue
        self.unit = unit
        self.deadline = deadline
    }
}

/// 难度等级
enum DifficultyLevel: String, Codable {
    case easy = "easy" // 简单
    case medium = "medium" // 中等
    case hard = "hard" // 困难
    
    var displayName: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "hare"
        case .medium: return "tortoise"
        case .hard: return "flame"
        }
    }
}
