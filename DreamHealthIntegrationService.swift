//
//  DreamHealthIntegrationService.swift
//  DreamLog - 健康集成与睡眠追踪服务
//
//  Phase 64: 健康集成与睡眠追踪 🍎💤
//  创建时间：2026-03-18
//

import Foundation
import SwiftData

// MARK: - 健康集成服务

/// 健康集成核心服务
@ModelActor
final class DreamHealthIntegrationService {
    
    // MARK: - 单例
    
    static var shared: DreamHealthIntegrationService?
    
    /// 初始化共享实例 (由 App 入口调用)
    static func initialize(modelContainer: ModelContainer) -> DreamHealthIntegrationService {
        if shared == nil {
            shared = DreamHealthIntegrationService(modelContext: ModelContext(modelContainer))
        }
        return shared!
    }
    
    // MARK: - 初始化
    
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - HealthKit 授权
    
    /// 请求 HealthKit 授权
    /// - Returns: 是否授权成功
    func requestAuthorization() async throws -> Bool {
        // 注意：实际实现需要导入 HealthKit 并调用 HKHealthStore
        // 这里提供框架实现
        #if canImport(HealthKit)
        // 在实际应用中实现 HealthKit 授权
        return try await withCheckedThrowingContinuation { continuation in
            // 模拟授权成功
            continuation.resume(returning: true)
        }
        #else
        return false
        #endif
    }
    
    /// 检查 HealthKit 授权状态
    /// - Returns: 授权状态
    func checkAuthorizationStatus() async -> HealthAuthorizationStatus {
        #if canImport(HealthKit)
        // 在实际应用中检查授权状态
        return .sharingAuthorized
        #else
        return .unavailable
        #endif
    }
    
    // MARK: - 睡眠数据同步
    
    /// 同步指定日期范围的睡眠会话
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 同步的睡眠会话列表
    func syncSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession] {
        // 在实际应用中从 HealthKit 读取睡眠数据
        // 这里提供模拟数据用于开发和测试
        
        let calendar = Calendar.current
        var sessions: [SleepSession] = []
        
        var currentDate = startDate
        while currentDate <= endDate {
            // 生成模拟睡眠数据
            let session = createMockSleepSession(for: currentDate)
            sessions.append(session)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // 保存到 SwiftData
        for session in sessions {
            modelContext.insert(session)
        }
        
        try? modelContext.save()
        
        return sessions
    }
    
    /// 创建模拟睡眠会话 (用于开发和测试)
    private func createMockSleepSession(for date: Date) -> SleepSession {
        let calendar = Calendar.current
        
        // 模拟晚上 11 点入睡，早上 7 点起床
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 23
        components.minute = 0
        let startDate = calendar.date(from: components) ?? date
        
        components.hour = 7
        components.minute = 0
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components) ?? date) ?? date
        
        let duration = endDate.timeIntervalSince(startDate)
        
        // 随机生成睡眠质量
        let qualities: [SleepQuality] = [.excellent, .good, .fair, .poor]
        let quality = qualities.randomElement() ?? .good
        
        // 模拟睡眠阶段
        let remDuration = duration * Double.random(in: 0.18...0.25)
        let deepDuration = duration * Double.random(in: 0.15...0.22)
        let awakeDuration = duration * Double.random(in: 0.02...0.08)
        let coreDuration = duration - remDuration - deepDuration - awakeDuration
        
        return SleepSession(
            startDate: startDate,
            endDate: endDate,
            duration: duration,
            quality: quality,
            remDuration: remDuration,
            coreDuration: coreDuration,
            deepDuration: deepDuration,
            awakeDuration: awakeDuration,
            source: "Apple Watch",
            inBedStartDate: calendar.date(byAdding: .minute, value: -15, to: startDate),
            inBedEndDate: calendar.date(byAdding: .minute, value: 10, to: endDate)
        )
    }
    
    /// 获取指定日期的睡眠会话
    /// - Parameter date: 日期
    /// - Returns: 睡眠会话 (如果存在)
    func getSleepSession(for date: Date) async throws -> SleepSession? {
        let calendar = Calendar.current
        
        let predicate = #Predicate<SleepSession> { session in
            calendar.isDate(session.startDate, inSameDayAs: date)
        }
        
        let descriptor = FetchDescriptor<SleepSession>(predicate: predicate)
        let sessions = try modelContext.fetch(descriptor)
        
        return sessions.first
    }
    
    /// 获取日期范围内的睡眠会话
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 睡眠会话列表
    func getSleepSessions(from startDate: Date, to endDate: Date) async throws -> [SleepSession] {
        let predicate = #Predicate<SleepSession> { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
        
        let descriptor = FetchDescriptor<SleepSession>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 睡眠质量分析
    
    /// 分析指定日期的睡眠质量
    /// - Parameter date: 日期
    /// - Returns: 睡眠质量评估
    func analyzeSleepQuality(for date: Date) async throws -> SleepQuality {
        guard let session = try await getSleepSession(for: date) else {
            return .poor
        }
        
        return session.quality
    }
    
    /// 计算平均睡眠质量
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 平均睡眠质量
    func averageSleepQuality(from startDate: Date, to endDate: Date) async throws -> SleepQuality {
        let sessions = try await getSleepSessions(from: startDate, to: endDate)
        
        guard !sessions.isEmpty else {
            return .fair
        }
        
        let totalScore = sessions.reduce(0) { $0 + $1.quality.score }
        let averageScore = totalScore / sessions.count
        
        return SleepQuality.from(score: averageScore)
    }
    
    // MARK: - 梦境 - 睡眠关联分析
    
    /// 分析梦境与睡眠的关联
    /// - Parameter date: 日期
    /// - Returns: 关联分析结果
    func correlateDreamsWithSleep(for date: Date) async throws -> DreamSleepCorrelation? {
        guard let sleepSession = try await getSleepSession(for: date) else {
            return nil
        }
        
        // 获取该日期的梦境
        let calendar = Calendar.current
        let dreamsPredicate = #Predicate<Dream> { dream in
            calendar.isDate(dream.date, inSameDayAs: date)
        }
        
        let dreamsDescriptor = FetchDescriptor<Dream>(predicate: dreamsPredicate)
        let dreams = try modelContext.fetch(dreamsDescriptor)
        
        guard !dreams.isEmpty else {
            return nil
        }
        
        // 计算统计数据
        let dreamCount = dreams.count
        let averageClarity = dreams.map { $0.clarity }.average ?? 0
        let averageIntensity = dreams.map { $0.intensity }.average ?? 0
        let lucidDreamCount = dreams.filter { $0.isLucid }.count
        
        // 情绪分析
        let emotions = dreams.compactMap { $0.emotion?.rawValue }
        let emotionCounts = Dictionary(grouping: emotions, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let topEmotions = emotionCounts.prefix(3).map { $0.key }
        
        // 计算积极/消极情绪比例
        let positiveEmotions = ["平静", "兴奋", "快乐", "中性"]
        let negativeEmotions = ["焦虑", "悲伤", "困惑", "恐惧"]
        
        let positiveCount = emotions.filter { positiveEmotions.contains($0) }.count
        let negativeCount = emotions.filter { negativeEmotions.contains($0) }.count
        
        let positiveRatio = Double(positiveCount) / Double(emotions.count)
        let negativeRatio = Double(negativeCount) / Double(emotions.count)
        
        // 标签分析
        let allTags = dreams.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let topTags = tagCounts.prefix(5).map { $0.key }
        
        return DreamSleepCorrelation(
            date: date,
            sleepQuality: sleepSession.quality,
            dreamCount: dreamCount,
            averageClarity: averageClarity,
            averageIntensity: averageIntensity,
            lucidDreamCount: lucidDreamCount,
            positiveEmotionRatio: positiveRatio,
            negativeEmotionRatio: negativeRatio,
            topEmotions: topEmotions,
            topTags: topTags
        )
    }
    
    /// 获取关联分析列表
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 关联分析列表
    func correlateDreamsWithSleep(from startDate: Date, to endDate: Date) async throws -> [DreamSleepCorrelation] {
        var correlations: [DreamSleepCorrelation] = []
        
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            if let correlation = try await correlateDreamsWithSleep(for: currentDate) {
                correlations.append(correlation)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return correlations
    }
    
    // MARK: - 智能推荐
    
    /// 基于睡眠质量获取梦境推荐
    /// - Parameter sleepQuality: 睡眠质量
    /// - Returns: 推荐列表
    func getDreamRecommendations(basedOn sleepQuality: SleepQuality) -> [DreamRecommendation] {
        var recommendations: [DreamRecommendation] = []
        
        switch sleepQuality {
        case .excellent:
            // 优秀睡眠：推荐创意和清醒梦相关
            recommendations.append(
                DreamRecommendation(
                    type: .incubation,
                    title: "创意启发孵育",
                    description: "昨晚睡眠质量优秀，适合尝试创意启发类梦境孵育",
                    action: "开始孵育",
                    priority: .high
                )
            )
            recommendations.append(
                DreamRecommendation(
                    type: .lucid,
                    title: "清醒梦训练",
                    description: "REM 睡眠充足，今晚适合练习清醒梦技巧",
                    action: "开始训练",
                    priority: .medium
                )
            )
            
        case .good:
            // 良好睡眠：推荐深度探索
            recommendations.append(
                DreamRecommendation(
                    type: .exploration,
                    title: "深度梦境探索",
                    description: "睡眠质量良好，适合深入探索梦境内容",
                    action: "开始记录",
                    priority: .medium
                )
            )
            
        case .fair:
            // 一般睡眠：推荐正念和放松
            recommendations.append(
                DreamRecommendation(
                    type: .meditation,
                    title: "睡前冥想",
                    description: "尝试睡前冥想来改善睡眠质量",
                    action: "开始冥想",
                    priority: .high
                )
            )
            
        case .poor:
            // 较差睡眠：推荐疗愈和放松
            recommendations.append(
                DreamRecommendation(
                    type: .healing,
                    title: "疗愈音效",
                    description: "播放疗愈音效帮助放松和改善睡眠",
                    action: "播放音效",
                    priority: .high
                )
            )
            recommendations.append(
                DreamRecommendation(
                    type: .relaxation,
                    title: "放松练习",
                    description: "进行放松练习，减轻压力",
                    action: "开始练习",
                    priority: .medium
                )
            )
        }
        
        return recommendations
    }
    
    // MARK: - 睡眠统计
    
    /// 计算睡眠统计
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 统计数据
    func calculateSleepStatistics(from startDate: Date, to endDate: Date) async throws -> SleepStatistics {
        let sessions = try await getSleepSessions(from: startDate, to: endDate)
        
        guard !sessions.isEmpty else {
            return SleepStatistics()
        }
        
        // 平均时长
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let averageDuration = totalDuration / Double(sessions.count)
        
        // 平均质量
        let totalScore = sessions.reduce(0) { $0 + $1.quality.score }
        let averageScore = totalScore / sessions.count
        let averageQuality = SleepQuality.from(score: averageScore)
        
        // 质量分布
        var qualityDistribution: [SleepQuality: Int] = [:]
        for quality in SleepQuality.allCases {
            qualityDistribution[quality] = sessions.filter { $0.quality == quality }.count
        }
        
        // 平均 REM 百分比
        let remPercentages = sessions.compactMap { $0.remPercentage }
        let averageRemPercentage = remPercentages.isEmpty ? nil : remPercentages.reduce(0, +) / Double(remPercentages.count)
        
        // 平均深度睡眠百分比
        let deepPercentages = sessions.compactMap { $0.deepPercentage }
        let averageDeepPercentage = deepPercentages.isEmpty ? nil : deepPercentages.reduce(0, +) / Double(deepPercentages.count)
        
        // 平均睡眠效率
        let efficiencies = sessions.compactMap { $0.sleepEfficiency }
        let averageSleepEfficiency = efficiencies.isEmpty ? nil : efficiencies.reduce(0, +) / Double(efficiencies.count)
        
        // 最佳和最差睡眠
        let bestSleep = sessions.max(by: { $0.quality.score < $1.quality.score })
        let worstSleep = sessions.min(by: { $0.quality.score < $1.quality.score })
        
        // 连续达标天数 (目标 8 小时)
        let goal: TimeInterval = 28800 // 8 hours
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        let sortedSessions = sessions.sorted { $0.startDate > $1.startDate }
        
        for session in sortedSessions {
            if session.duration >= goal {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                if currentStreak == 0 {
                    currentStreak = tempStreak
                }
                tempStreak = 0
            }
        }
        
        if currentStreak == 0 {
            currentStreak = tempStreak
        }
        
        return SleepStatistics(
            totalSessions: sessions.count,
            averageDuration: averageDuration,
            averageQuality: averageQuality,
            qualityDistribution: qualityDistribution,
            averageRemPercentage: averageRemPercentage,
            averageDeepPercentage: averageDeepPercentage,
            averageSleepEfficiency: averageSleepEfficiency,
            bestSleepDate: bestSleep?.startDate,
            worstSleepDate: worstSleep?.startDate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysTracked: sessions.count
        )
    }
    
    // MARK: - 健康指标
    
    /// 获取指定日期的健康指标
    /// - Parameter date: 日期
    /// - Returns: 健康指标
    func getHealthMetrics(for date: Date) async throws -> HealthMetrics? {
        let calendar = Calendar.current
        
        let predicate = #Predicate<HealthMetrics> { metrics in
            calendar.isDate(metrics.date, inSameDayAs: date)
        }
        
        let descriptor = FetchDescriptor<HealthMetrics>(predicate: predicate)
        let metrics = try modelContext.fetch(descriptor)
        
        return metrics.first
    }
    
    /// 保存健康指标
    /// - Parameter metrics: 健康指标
    func saveHealthMetrics(_ metrics: HealthMetrics) {
        modelContext.insert(metrics)
        try? modelContext.save()
    }
    
    // MARK: - 工具方法
    
    /// 格式化时长
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return "\(hours)小时\(minutes)分钟"
    }
}

// MARK: - 梦境推荐模型

/// 梦境推荐类型
enum DreamRecommendationType: String, CaseIterable {
    case incubation = "孵育"
    case lucid = "清醒梦"
    case exploration = "探索"
    case meditation = "冥想"
    case healing = "疗愈"
    case relaxation = "放松"
    case recording = "记录"
    case reflection = "反思"
}

/// 推荐优先级
enum RecommendationPriority: String {
    case low = "低"
    case medium = "中"
    case high = "高"
}

/// 梦境推荐模型
struct DreamRecommendation {
    var type: DreamRecommendationType
    var title: String
    var description: String
    var action: String
    var priority: RecommendationPriority
}

// MARK: - Array 扩展

extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
