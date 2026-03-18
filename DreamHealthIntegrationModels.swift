//
//  DreamHealthIntegrationModels.swift
//  DreamLog - 健康集成与睡眠追踪数据模型
//
//  Phase 64: 健康集成与睡眠追踪 🍎💤
//  创建时间：2026-03-18
//

import Foundation
import SwiftData

// MARK: - 睡眠会话模型

/// 睡眠会话数据模型
@Model
final class SleepSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var duration: TimeInterval
    var quality: SleepQuality
    var remDuration: TimeInterval?
    var coreDuration: TimeInterval?
    var deepDuration: TimeInterval?
    var awakeDuration: TimeInterval?
    var source: String
    var inBedStartDate: Date?
    var inBedEndDate: Date?
    
    // 关联的梦境
    @Relationship var dreams: [Dream]
    
    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        quality: SleepQuality,
        remDuration: TimeInterval? = nil,
        coreDuration: TimeInterval? = nil,
        deepDuration: TimeInterval? = nil,
        awakeDuration: TimeInterval? = nil,
        source: String = "Unknown",
        inBedStartDate: Date? = nil,
        inBedEndDate: Date? = nil,
        dreams: [Dream] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.quality = quality
        self.remDuration = remDuration
        self.coreDuration = coreDuration
        self.deepDuration = deepDuration
        self.awakeDuration = awakeDuration
        self.source = source
        self.inBedStartDate = inBedStartDate
        self.inBedEndDate = inBedEndDate
        self.dreams = dreams
    }
    
    // MARK: - 计算属性
    
    /// 睡眠开始时间的小时数
    var startHour: Int {
        Calendar.current.component(.hour, from: startDate)
    }
    
    /// 睡眠效率 (实际睡眠/卧床时间)
    var sleepEfficiency: Double? {
        guard let inBedStart = inBedStartDate,
              let inBedEnd = inBedEndDate else {
            return nil
        }
        let inBedDuration = inBedEnd.timeIntervalSince(inBedStart)
        guard inBedDuration > 0 else { return nil }
        return min(duration / inBedDuration, 1.0)
    }
    
    /// 睡眠阶段总时长
    var totalStageDuration: TimeInterval {
        (remDuration ?? 0) + (coreDuration ?? 0) + (deepDuration ?? 0) + (awakeDuration ?? 0)
    }
    
    /// REM 睡眠百分比
    var remPercentage: Double? {
        guard totalStageDuration > 0 else { return nil }
        return (remDuration ?? 0) / totalStageDuration
    }
    
    /// 深度睡眠百分比
    var deepPercentage: Double? {
        guard totalStageDuration > 0 else { return nil }
        return (deepDuration ?? 0) / totalStageDuration
    }
    
    /// 核心睡眠百分比
    var corePercentage: Double? {
        guard totalStageDuration > 0 else { return nil }
        return (coreDuration ?? 0) / totalStageDuration
    }
    
    /// 清醒时间百分比
    var awakePercentage: Double? {
        guard totalStageDuration > 0 else { return nil }
        return (awakeDuration ?? 0) / totalStageDuration
    }
}

// MARK: - 睡眠质量枚举

/// 睡眠质量等级
enum SleepQuality: String, CaseIterable, Codable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
    
    /// 对应的分数 (0-100)
    var score: Int {
        switch self {
        case .excellent: return 90
        case .good: return 75
        case .fair: return 60
        case .poor: return 40
        }
    }
    
    /// 对应的颜色
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
    
    /// 对应的 SF Symbol
    var symbol: String {
        switch self {
        case .excellent: return "moon.stars.fill"
        case .good: return "moon.fill"
        case .fair: return "moon"
        case .poor: return "moon.zzz"
        }
    }
    
    /// 从分数创建睡眠质量
    static func from(score: Int) -> SleepQuality {
        switch score {
        case 85...: return .excellent
        case 70..<85: return .good
        case 55..<70: return .fair
        default: return .poor
        }
    }
}

// MARK: - 健康指标模型

/// 健康指标数据模型
@Model
final class HealthMetrics {
    var id: UUID
    var date: Date
    var restingHeartRate: Double?
    var heartRateVariability: Double?
    var respiratoryRate: Double?
    var sleepGoal: TimeInterval
    var actualSleep: TimeInterval
    var stepCount: Int?
    var activeEnergy: Double?
    var mindfulMinutes: Double?
    
    init(
        id: UUID = UUID(),
        date: Date,
        restingHeartRate: Double? = nil,
        heartRateVariability: Double? = nil,
        respiratoryRate: Double? = nil,
        sleepGoal: TimeInterval = 28800, // 8 hours
        actualSleep: TimeInterval = 0,
        stepCount: Int? = nil,
        activeEnergy: Double? = nil,
        mindfulMinutes: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.respiratoryRate = respiratoryRate
        self.sleepGoal = sleepGoal
        self.actualSleep = actualSleep
        self.stepCount = stepCount
        self.activeEnergy = activeEnergy
        self.mindfulMinutes = mindfulMinutes
    }
    
    // MARK: - 计算属性
    
    /// 睡眠目标达成率
    var sleepGoalCompletion: Double {
        guard sleepGoal > 0 else { return 0 }
        return min(actualSleep / sleepGoal, 2.0) // Cap at 200%
    }
    
    /// 静息心率是否正常 (60-100 bpm)
    var isRestingHeartRateNormal: Bool? {
        guard let rhr = restingHeartRate else { return nil }
        return rhr >= 60 && rhr <= 100
    }
    
    /// HRV 健康评估
    var hrvStatus: HRVStatus? {
        guard let hrv = heartRateVariability else { return nil }
        if hrv >= 50 { return .excellent }
        if hrv >= 30 { return .good }
        if hrv >= 20 { return .fair }
        return .poor
    }
}

// MARK: - HRV 状态枚举

/// 心率变异性状态
enum HRVStatus: String, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case fair = "一般"
    case poor = "较差"
    
    var description: String {
        switch self {
        case .excellent: return "心率变异性优秀，身体状况良好"
        case .good: return "心率变异性良好，保持健康习惯"
        case .fair: return "心率变异性一般，注意休息"
        case .poor: return "心率变异性较低，建议放松和休息"
        }
    }
}

// MARK: - 梦境 - 睡眠关联模型

/// 梦境与睡眠的关联分析
@Model
final class DreamSleepCorrelation {
    var id: UUID
    var date: Date
    var sleepQuality: SleepQuality
    var dreamCount: Int
    var averageClarity: Double
    var averageIntensity: Double
    var lucidDreamCount: Int
    var positiveEmotionRatio: Double
    var negativeEmotionRatio: Double
    var topEmotions: [String]
    var topTags: [String]
    
    init(
        id: UUID = UUID(),
        date: Date,
        sleepQuality: SleepQuality,
        dreamCount: Int,
        averageClarity: Double,
        averageIntensity: Double,
        lucidDreamCount: Int,
        positiveEmotionRatio: Double,
        negativeEmotionRatio: Double,
        topEmotions: [String] = [],
        topTags: [String] = []
    ) {
        self.id = id
        self.date = date
        self.sleepQuality = sleepQuality
        self.dreamCount = dreamCount
        self.averageClarity = averageClarity
        self.averageIntensity = averageIntensity
        self.lucidDreamCount = lucidDreamCount
        self.positiveEmotionRatio = positiveEmotionRatio
        self.negativeEmotionRatio = negativeEmotionRatio
        self.topEmotions = topEmotions
        self.topTags = topTags
    }
}

// MARK: - 睡眠统计模型

/// 睡眠统计数据
struct SleepStatistics {
    var totalSessions: Int
    var averageDuration: TimeInterval
    var averageQuality: SleepQuality
    var qualityDistribution: [SleepQuality: Int]
    var averageRemPercentage: Double?
    var averageDeepPercentage: Double?
    var averageSleepEfficiency: Double?
    var bestSleepDate: Date?
    var worstSleepDate: Date?
    var currentStreak: Int // 连续达标天数
    var longestStreak: Int // 最长连续达标天数
    var totalDaysTracked: Int
    
    init(
        totalSessions: Int = 0,
        averageDuration: TimeInterval = 0,
        averageQuality: SleepQuality = .fair,
        qualityDistribution: [SleepQuality: Int] = [:],
        averageRemPercentage: Double? = nil,
        averageDeepPercentage: Double? = nil,
        averageSleepEfficiency: Double? = nil,
        bestSleepDate: Date? = nil,
        worstSleepDate: Date? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalDaysTracked: Int = 0
    ) {
        self.totalSessions = totalSessions
        self.averageDuration = averageDuration
        self.averageQuality = averageQuality
        self.qualityDistribution = qualityDistribution
        self.averageRemPercentage = averageRemPercentage
        self.averageDeepPercentage = averageDeepPercentage
        self.averageSleepEfficiency = averageSleepEfficiency
        self.bestSleepDate = bestSleepDate
        self.worstSleepDate = worstSleepDate
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalDaysTracked = totalDaysTracked
    }
    
    // MARK: - 格式化输出
    
    /// 平均睡眠时长格式化
    var formattedAverageDuration: String {
        let hours = Int(averageDuration) / 3600
        let minutes = (Int(averageDuration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
    
    /// 睡眠目标达成率
    var goalCompletionRate: Double {
        let goal: TimeInterval = 28800 // 8 hours
        guard goal > 0 else { return 0 }
        return min(averageDuration / goal, 2.0)
    }
}

// MARK: - 睡眠目标模型

/// 睡眠目标设置
@Model
final class SleepGoal {
    var id: UUID
    var targetDuration: TimeInterval
    var targetBedtime: Date?
    var targetWakeTime: Date?
    var remindersEnabled: Bool
    var bedtimeReminderOffset: TimeInterval // 提前多久提醒
    var wakeUpReminderOffset: TimeInterval // 起床后多久提醒
    
    init(
        id: UUID = UUID(),
        targetDuration: TimeInterval = 28800, // 8 hours
        targetBedtime: Date? = nil,
        targetWakeTime: Date? = nil,
        remindersEnabled: Bool = true,
        bedtimeReminderOffset: TimeInterval = 1800, // 30 minutes
        wakeUpReminderOffset: TimeInterval = 900 // 15 minutes
    ) {
        self.id = id
        self.targetDuration = targetDuration
        self.targetBedtime = targetBedtime
        self.targetWakeTime = targetWakeTime
        self.remindersEnabled = remindersEnabled
        self.bedtimeReminderOffset = bedtimeReminderOffset
        self.wakeUpReminderOffset = wakeUpReminderOffset
    }
    
    // MARK: - 计算属性
    
    /// 目标时长格式化
    var formattedTargetDuration: String {
        let hours = Int(targetDuration) / 3600
        let minutes = (Int(targetDuration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
}

// MARK: - 健康授权状态

/// HealthKit 授权状态
enum HealthAuthorizationStatus: String {
    case notDetermined = "未确定"
    case sharingDenied = "拒绝共享"
    case sharingAuthorized = "已授权"
    case unavailable = "不可用"
    
    var canAccess: Bool {
        self == .sharingAuthorized
    }
}
