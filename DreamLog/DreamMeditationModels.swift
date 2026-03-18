//
//  DreamMeditationModels.swift
//  DreamLog
//
//  Phase 65: 梦境冥想与放松增强
//  冥想功能数据模型
//

import Foundation
import SwiftData

// MARK: - 冥想类型枚举

/// 冥想类型分类
enum MeditationType: String, Codable, CaseIterable {
    // 引导冥想
    case guidedDream = "guided_dream"           // 梦境引导冥想
    case sleepStory = "sleep_story"             // 睡眠故事
    case lucidDreamInduction = "lucid_induction" // 清醒梦诱导
    
    // 呼吸练习
    case breathing478 = "breathing_478"         // 4-7-8 呼吸法
    case boxBreathing = "box_breathing"         // 盒子呼吸法
    case wildBreathing = "wild_breathing"       // WILD 呼吸法
    case morningWake = "morning_wake"           // 晨间唤醒呼吸
    
    // 放松扫描
    case bodyScan = "body_scan"                 // 身体扫描
    case dreamRecall = "dream_recall"           // 梦境回忆扫描
    case stressRelief = "stress_relief"         // 压力释放扫描
    
    // 正念冥想
    case dreamAwareness = "dream_awareness"     // 梦境觉察
    case realityCheck = "reality_check"         // 现实检查正念
    case emotionalAwareness = "emotional_awareness" // 情绪觉察
    case gratitude = "gratitude"                // 感恩冥想
    
    // 音乐疗法
    case musicTherapy = "music_therapy"         // 音乐疗法
    case whiteNoise = "white_noise"             // 白噪音
    case binauralBeats = "binaural_beats"       // 双耳节拍
    case customMix = "custom_mix"               // 自定义混音
    
    var displayName: String {
        switch self {
        case .guidedDream: return "梦境引导"
        case .sleepStory: return "睡眠故事"
        case .lucidDreamInduction: return "清醒梦诱导"
        case .breathing478: return "4-7-8 呼吸"
        case .boxBreathing: return "盒子呼吸"
        case .wildBreathing: return "WILD 呼吸"
        case .morningWake: return "晨间唤醒"
        case .bodyScan: return "身体扫描"
        case .dreamRecall: return "梦境回忆"
        case .stressRelief: return "压力释放"
        case .dreamAwareness: return "梦境觉察"
        case .realityCheck: return "现实检查"
        case .emotionalAwareness: return "情绪觉察"
        case .gratitude: return "感恩冥想"
        case .musicTherapy: return "音乐疗法"
        case .whiteNoise: return "白噪音"
        case .binauralBeats: return "双耳节拍"
        case .customMix: return "自定义混音"
        }
    }
    
    var icon: String {
        switch self {
        case .guidedDream, .sleepStory, .lucidDreamInduction: return "moon.stars"
        case .breathing478, .boxBreathing, .wildBreathing, .morningWake: return "wind"
        case .bodyScan, .dreamRecall, .stressRelief: return "figure.mind.and.body"
        case .dreamAwareness, .realityCheck, .emotionalAwareness, .gratitude: return "brain.head.profile"
        case .musicTherapy, .whiteNoise, .binauralBeats, .customMix: return "music.note"
        }
    }
    
    var category: MeditationCategory {
        switch self {
        case .guidedDream, .sleepStory, .lucidDreamInduction: return .guided
        case .breathing478, .boxBreathing, .wildBreathing, .morningWake: return .breathing
        case .bodyScan, .dreamRecall, .stressRelief: return .relaxation
        case .dreamAwareness, .realityCheck, .emotionalAwareness, .gratitude: return .mindfulness
        case .musicTherapy, .whiteNoise, .binauralBeats, .customMix: return .music
        }
    }
}

/// 冥想分类
enum MeditationCategory: String, Codable, CaseIterable {
    case guided = "guided"           // 引导冥想
    case breathing = "breathing"     // 呼吸练习
    case relaxation = "relaxation"   // 放松扫描
    case mindfulness = "mindfulness" // 正念冥想
    case music = "music"             // 音乐疗法
    
    var displayName: String {
        switch self {
        case .guided: return "引导冥想"
        case .breathing: return "呼吸练习"
        case .relaxation: return "放松扫描"
        case .mindfulness: return "正念冥想"
        case .music: return "音乐疗法"
        }
    }
    
    var icon: String {
        switch self {
        case .guided: return "sparkles"
        case .breathing: return "wind"
        case .relaxation: return "figure.stand"
        case .mindfulness: return "brain.head.profile"
        case .music: return "music.note.list"
        }
    }
}

// MARK: - 冥想难度级别

enum MeditationDifficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "入门"
        case .intermediate: return "中级"
        case .advanced: return "高级"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "star"
        case .intermediate: return "star.fill"
        case .advanced: return "star.circle.fill"
        }
    }
}

// MARK: - 冥想会话模型

/// 冥想练习会话记录
@Model
final class MeditationSession {
    @Attribute(.unique) var id: UUID
    var type: String // MeditationType.rawValue
    var duration: TimeInterval // 秒
    var completed: Bool
    var moodBefore: String? // MoodType.rawValue
    var moodAfter: String?
    var dreamId: UUID? // 关联的梦境 ID
    var sleepQuality: Int? // 1-5 睡眠质量评分
    var notes: String? // 用户笔记
    var createdAt: Date
    
    // 播放详情
    var audioFile: String? // 音频文件名
    var voiceType: String? // TTS 语音类型
    var backgroundSound: String? // 背景音
    var volume: Double // 0.0-1.0
    var timerDuration: TimeInterval? // 定时关闭时长
    
    // 统计
    var focusLevel: Int? // 专注度 1-5
    var relaxationLevel: Int? // 放松度 1-5
    var wouldRecommend: Bool? // 是否会推荐
    
    init(
        id: UUID = UUID(),
        type: MeditationType,
        duration: TimeInterval,
        completed: Bool = false,
        moodBefore: String? = nil,
        moodAfter: String? = nil,
        dreamId: UUID? = nil,
        sleepQuality: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        audioFile: String? = nil,
        voiceType: String? = nil,
        backgroundSound: String? = nil,
        volume: Double = 0.8,
        timerDuration: TimeInterval? = nil,
        focusLevel: Int? = nil,
        relaxationLevel: Int? = nil,
        wouldRecommend: Bool? = nil
    ) {
        self.id = id
        self.type = type.rawValue
        self.duration = duration
        self.completed = completed
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.dreamId = dreamId
        self.sleepQuality = sleepQuality
        self.notes = notes
        self.createdAt = createdAt
        self.audioFile = audioFile
        self.voiceType = voiceType
        self.backgroundSound = backgroundSound
        self.volume = volume
        self.timerDuration = timerDuration
        self.focusLevel = focusLevel
        self.relaxationLevel = relaxationLevel
        self.wouldRecommend = wouldRecommend
    }
    
    var meditationType: MeditationType? {
        MeditationType(rawValue: type)
    }
    
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes)分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)小时\(mins)分钟"
        }
    }
}

// MARK: - 冥想偏好设置

/// 用户冥想偏好设置
@Model
final class MeditationPreference {
    @Attribute(.unique) var id: UUID
    var favoriteTypes: [String] // MeditationType.rawValue
    var preferredDuration: TimeInterval // 默认时长（秒）
    var preferredVoice: String // TTS 语音
    var reminderTime: Date? // 提醒时间
    var reminderEnabled: Bool
    var backgroundSound: String? // 默认背景音
    var autoSleepTimer: Bool // 自动睡眠定时器
    var sleepTimerDuration: TimeInterval // 睡眠定时器时长
    var streakGoal: Int // 连续练习目标天数
    var dailyGoal: TimeInterval // 每日目标时长
    
    // 智能推荐设置
    var enableSmartRecommendations: Bool
    var considerMood: Bool // 考虑情绪状态
    var considerSleepQuality: Bool // 考虑睡眠质量
    var considerDreamContent: Bool // 考虑梦境内容
    
    init(
        id: UUID = UUID(),
        favoriteTypes: [String] = [],
        preferredDuration: TimeInterval = 600, // 10 分钟
        preferredVoice: String = "default",
        reminderTime: Date? = nil,
        reminderEnabled: Bool = false,
        backgroundSound: String? = nil,
        autoSleepTimer: Bool = true,
        sleepTimerDuration: TimeInterval = 1800, // 30 分钟
        streakGoal: Int = 7,
        dailyGoal: TimeInterval = 900, // 15 分钟
        enableSmartRecommendations: Bool = true,
        considerMood: Bool = true,
        considerSleepQuality: Bool = true,
        considerDreamContent: Bool = true
    ) {
        self.id = id
        self.favoriteTypes = favoriteTypes
        self.preferredDuration = preferredDuration
        self.preferredVoice = preferredVoice
        self.reminderTime = reminderTime
        self.reminderEnabled = reminderEnabled
        self.backgroundSound = backgroundSound
        self.autoSleepTimer = autoSleepTimer
        self.sleepTimerDuration = sleepTimerDuration
        self.streakGoal = streakGoal
        self.dailyGoal = dailyGoal
        self.enableSmartRecommendations = enableSmartRecommendations
        self.considerMood = considerMood
        self.considerSleepQuality = considerSleepQuality
        self.considerDreamContent = considerDreamContent
    }
}

// MARK: - 冥想模板

/// 冥想引导模板（用于生成个性化冥想）
@Model
final class MeditationTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: String // MeditationType.rawValue
    var category: String // MeditationCategory.rawValue
    var duration: TimeInterval
    var difficulty: String // MeditationDifficulty.rawValue
    var script: String // 引导脚本文本
    var tags: [String] // 标签：飞行/水下/森林/平静/焦虑等
    var voiceType: String // 推荐语音
    var backgroundSound: String? // 推荐背景音
    var musicTrack: String? // 背景音乐
    var thumbnailImage: String? // 缩略图
    var description: String // 描述
    var instructions: String // 使用说明
    var benefits: [String] // 益处列表
    var isPremium: Bool // 是否高级内容
    var usageCount: Int // 使用次数统计
    var averageRating: Double // 平均评分
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        type: MeditationType,
        category: MeditationCategory,
        duration: TimeInterval,
        difficulty: MeditationDifficulty = .beginner,
        script: String = "",
        tags: [String] = [],
        voiceType: String = "default",
        backgroundSound: String? = nil,
        musicTrack: String? = nil,
        thumbnailImage: String? = nil,
        description: String = "",
        instructions: String = "",
        benefits: [String] = [],
        isPremium: Bool = false,
        usageCount: Int = 0,
        averageRating: Double = 0.0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type.rawValue
        self.category = category.rawValue
        self.duration = duration
        self.difficulty = difficulty.rawValue
        self.script = script
        self.tags = tags
        self.voiceType = voiceType
        self.backgroundSound = backgroundSound
        self.musicTrack = musicTrack
        self.thumbnailImage = thumbnailImage
        self.description = description
        self.instructions = instructions
        self.benefits = benefits
        self.isPremium = isPremium
        self.usageCount = usageCount
        self.averageRating = averageRating
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var meditationType: MeditationType? {
        MeditationType(rawValue: type)
    }
    
    var meditationCategory: MeditationCategory? {
        MeditationCategory(rawValue: category)
    }
    
    var meditationDifficulty: MeditationDifficulty? {
        MeditationDifficulty(rawValue: difficulty)
    }
}

// MARK: - 冥想成就

/// 冥想成就徽章
@Model
final class MeditationAchievement {
    @Attribute(.unique) var id: UUID
    var type: String // 成就类型
    var name: String
    var description: String
    var icon: String
    var requirement: Int // 达成要求（次数/天数等）
    var progress: Int // 当前进度
    var isUnlocked: Bool
    var unlockedAt: Date?
    var category: String // 成就分类
    
    init(
        id: UUID = UUID(),
        type: String,
        name: String,
        description: String,
        icon: String,
        requirement: Int,
        progress: Int = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        category: String = "general"
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.progress = progress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.category = category
    }
}

// MARK: - 冥想统计

/// 冥想统计数据（聚合模型）
struct MeditationStats {
    var totalSessions: Int // 总会话数
    var totalDuration: TimeInterval // 总时长
    var averageDuration: TimeInterval // 平均时长
    var currentStreak: Int // 当前连续天数
    var longestStreak: Int // 最长连续天数
    var sessionsByType: [String: Int] // 按类型统计
    var sessionsByCategory: [String: Int] // 按分类统计
    var moodImprovementRate: Double // 情绪改善率
    var sleepQualityCorrelation: Double // 睡眠质量关联度
    var dreamRecallCorrelation: Double // 梦境回忆关联度
    var favoriteTimeOfDay: String // 偏好时间段
    var weeklyProgress: [Int] // 周进度（每天分钟数）
    var monthlyProgress: [Int] // 月进度
    
    static var empty: MeditationStats {
        MeditationStats(
            totalSessions: 0,
            totalDuration: 0,
            averageDuration: 0,
            currentStreak: 0,
            longestStreak: 0,
            sessionsByType: [:],
            sessionsByCategory: [:],
            moodImprovementRate: 0,
            sleepQualityCorrelation: 0,
            dreamRecallCorrelation: 0,
            favoriteTimeOfDay: "未知",
            weeklyProgress: Array(repeating: 0, count: 7),
            monthlyProgress: Array(repeating: 0, count: 30)
        )
    }
}

// MARK: - 推荐配置

/// 智能推荐配置
struct MeditationRecommendationConfig {
    var timeOfDay: String // 时间段：morning/afternoon/evening/night
    var mood: String? // 当前情绪
    var sleepQuality: Int? // 昨晚睡眠质量
    var recentDreams: [String] // 最近梦境标签
    var stressLevel: Int? // 压力水平 1-5
    var energyLevel: Int? // 能量水平 1-5
    var goal: String? // 目标：sleep/relax/focus/recall/lucid
    var availableTime: TimeInterval? // 可用时间
    var seed: Int // 随机种子，用于"换一批"功能
    
    static var empty: MeditationRecommendationConfig {
        MeditationRecommendationConfig(
            timeOfDay: "unknown",
            mood: nil,
            sleepQuality: nil,
            recentDreams: [],
            stressLevel: nil,
            energyLevel: nil,
            goal: nil,
            availableTime: nil,
            seed: 0
        )
    }
}
