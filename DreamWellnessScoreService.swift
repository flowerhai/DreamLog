//
//  DreamWellnessScoreService.swift
//  DreamLog
//
//  Phase 100: 梦境健康评分与预测引擎
//  健康评分计算服务
//

import Foundation
import SwiftData

// MARK: - 健康评分服务

actor DreamWellnessScoreService {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 计算当日健康评分
    
    func calculateTodayScore() async throws -> DreamWellnessScore {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 检查是否已存在今日评分
        let existingScore = try getScore(for: today)
        if let existing = existingScore {
            return existing
        }
        
        // 计算各维度评分
        let sleepScore = await calculateSleepQualityScore()
        let recallScore = try calculateDreamRecallScore()
        let emotionalScore = try calculateEmotionalHealthScore()
        let patternScore = try calculatePatternHealthScore()
        
        // 计算综合评分
        let overallScore = calculateOverallScore(
            sleep: sleepScore,
            recall: recallScore,
            emotional: emotionalScore,
            pattern: patternScore
        )
        
        // 确定评分等级
        let scoreLevel = ScoreLevel.from(score: overallScore)
        
        // 计算趋势
        let trend = await calculateScoreTrend(currentScore: overallScore, date: today)
        
        // 生成洞察和建议
        let insights = generateInsights(
            sleepScore: sleepScore,
            recallScore: recallScore,
            emotionalScore: emotionalScore,
            patternScore: patternScore,
            overallScore: overallScore,
            level: scoreLevel
        )
        
        let recommendations = generateRecommendations(
            sleepScore: sleepScore,
            recallScore: recallScore,
            emotionalScore: emotionalScore,
            patternScore: patternScore,
            level: scoreLevel
        )
        
        // 创建评分记录
        let score = DreamWellnessScore(
            date: today,
            overallScore: overallScore,
            sleepQualityScore: sleepScore,
            dreamRecallScore: recallScore,
            emotionalHealthScore: emotionalScore,
            patternHealthScore: patternScore,
            scoreLevel: scoreLevel,
            trend: trend,
            insights: insights,
            recommendations: recommendations
        )
        
        modelContext.insert(score)
        try modelContext.save()
        
        return score
    }
    
    // MARK: - 获取历史评分
    
    func getScore(for date: Date) throws -> DreamWellnessScore? {
        let descriptor = FetchDescriptor<DreamWellnessScore>(
            predicate: #Predicate { score in
                Calendar.current.isDate(score.date, inSameDayAs: date)
            }
        )
        
        let scores = try modelContext.fetch(descriptor)
        return scores.first
    }
    
    func getScores(for period: DateInterval) throws -> [DreamWellnessScore] {
        let descriptor = FetchDescriptor<DreamWellnessScore>(
            predicate: #Predicate { score in
                score.date >= period.start && score.date <= period.end
            },
            sortBy: [SortDescriptor(\.date)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    func getRecentScores(count: Int = 7) throws -> [DreamWellnessScore] {
        let descriptor = FetchDescriptor<DreamWellnessScore>(
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: count
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 睡眠质量评分计算
    
    private func calculateSleepQualityScore() async -> Double {
        // 从 HealthKit 获取睡眠数据
        // 这里简化实现，实际应从 DreamHealthIntegrationService 获取
        
        // 基于以下因素计算:
        // - 睡眠时长 (目标 7-9 小时)
        // - 睡眠效率 (实际睡眠时间/卧床时间)
        // - 深度睡眠比例
        // - REM 睡眠比例
        // - 醒来次数
        
        // 模拟计算 (实际应集成 HealthKit)
        let targetSleepHours = 8.0
        let actualSleepHours = 7.5  // 从 HealthKit 获取
        
        let durationScore = min(100, (actualSleepHours / targetSleepHours) * 100)
        let efficiencyScore = 85.0  // 睡眠效率
        let deepSleepScore = 80.0   // 深度睡眠评分
        let remSleepScore = 75.0    // REM 睡眠评分
        
        // 加权平均
        let sleepScore = durationScore * 0.3 +
                        efficiencyScore * 0.25 +
                        deepSleepScore * 0.25 +
                        remSleepScore * 0.2
        
        return min(100, max(0, sleepScore))
    }
    
    // MARK: - 梦境回忆评分计算
    
    private func calculateDreamRecallScore() throws -> Double {
        // 基于以下因素计算:
        // - 记录频率 (每周记录次数)
        // - 记录详细程度 (平均字数)
        // - 清晰度评分 (用户自评)
        // - 连续记录天数
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        // 获取最近 7 天的梦境
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        // 记录频率评分 (目标：每天记录)
        let frequencyScore = min(100, Double(dreams.count) / 7.0 * 100)
        
        // 详细程度评分 (目标：平均 100 字以上)
        let avgWordCount = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.content.count }) / Double(dreams.count)
        let detailScore = min(100, avgWordCount / 100.0 * 100)
        
        // 清晰度评分
        let avgClarity = dreams.isEmpty ? 3.0 : dreams.reduce(0.0) { $0 + Double($1.clarityRating) } / Double(dreams.count)
        let clarityScore = avgClarity / 5.0 * 100
        
        // 连续记录评分
        let streakScore = calculateRecordingStreak() * 10  // 最多 100 分
        
        // 加权平均
        let recallScore = frequencyScore * 0.35 +
                         detailScore * 0.25 +
                         clarityScore * 0.25 +
                         streakScore * 0.15
        
        return min(100, max(0, recallScore))
    }
    
    private func calculateRecordingStreak() -> Int {
        // 计算连续记录天数
        // 简化实现，实际应遍历梦境记录
        return 5  // 示例：连续 5 天
    }
    
    // MARK: - 情绪健康评分计算
    
    private func calculateEmotionalHealthScore() throws -> Double {
        // 基于以下因素计算:
        // - 情绪分布平衡度
        // - 积极情绪比例
        // - 情绪波动程度
        // - 负面情绪趋势
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate)!
        
        // 获取最近 14 天的梦境
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        guard !dreams.isEmpty else { return 50.0 }
        
        // 情绪分布评分
        let emotions = dreams.map { $0.primaryEmotion }
        let uniqueEmotions = Set(emotions).count
        let diversityScore = min(100, Double(uniqueEmotions) / 5.0 * 100)  // 目标：5 种以上情绪
        
        // 积极情绪比例
        let positiveEmotions = ["快乐", "兴奋", "平静", "满足", "爱"]
        let positiveCount = dreams.filter { positiveEmotions.contains($0.primaryEmotion) }.count
        let positiveRatio = Double(positiveCount) / Double(dreams.count)
        let positiveScore = positiveRatio * 100
        
        // 情绪波动评分 (标准差越小越稳定)
        let moodRatings = dreams.map { Double($0.moodRating) }
        let avgMood = moodRatings.reduce(0, +) / Double(moodRatings.count)
        let variance = moodRatings.reduce(0) { $0 + pow($1 - avgMood, 2) } / Double(moodRatings.count)
        let stabilityScore = max(0, 100 - variance * 20)  // 方差越大，分数越低
        
        // 负面情绪趋势
        let negativeEmotions = ["恐惧", "焦虑", "悲伤", "愤怒", "羞愧"]
        let recentNegativeCount = dreams.prefix(7).filter { negativeEmotions.contains($0.primaryEmotion) }.count
        let olderNegativeCount = dreams.suffix(7).filter { negativeEmotions.contains($0.primaryEmotion) }.count
        let trendScore = recentNegativeCount <= olderNegativeCount ? 100 : 60
        
        // 加权平均
        let emotionalScore = diversityScore * 0.25 +
                            positiveScore * 0.35 +
                            stabilityScore * 0.25 +
                            trendScore * 0.15
        
        return min(100, max(0, emotionalScore))
    }
    
    // MARK: - 模式健康评分计算
    
    private func calculatePatternHealthScore() throws -> Double {
        // 基于以下因素计算:
        // - 梦境主题多样性
        // - 符号丰富度
        // - 场景变化性
        // - 模式重复度 (过高可能表示压力)
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        // 获取最近 30 天的梦境
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        guard !dreams.isEmpty else { return 50.0 }
        
        // 主题多样性评分
        let themes = dreams.flatMap { $0.themes }
        let uniqueThemes = Set(themes).count
        let themeDiversityScore = min(100, Double(uniqueThemes) / 10.0 * 100)  // 目标：10 种以上主题
        
        // 符号丰富度评分
        let symbols = dreams.flatMap { $0.symbols }
        let uniqueSymbols = Set(symbols).count
        let symbolRichnessScore = min(100, Double(uniqueSymbols) / 20.0 * 100)  // 目标：20 种以上符号
        
        // 场景变化性评分
        let scenes = dreams.compactMap { $0.sceneType }
        let uniqueScenes = Set(scenes).count
        let sceneVarietyScore = min(100, Double(uniqueScenes) / 8.0 * 100)  // 目标：8 种以上场景
        
        // 模式重复度评分 (适度重复是正常的，过高可能表示压力)
        let themeCounts = Dictionary(grouping: themes, by: { $0 })
            .mapValues { Double($0.count) / Double(dreams.count) * 100 }
        let maxThemeRatio = themeCounts.max(by: { $0.value < $1.value })?.value ?? 0
        let repetitionScore = max(0, 100 - (maxThemeRatio - 20) * 2)  // 超过 20% 开始扣分
        
        // 加权平均
        let patternScore = themeDiversityScore * 0.35 +
                          symbolRichnessScore * 0.30 +
                          sceneVarietyScore * 0.20 +
                          repetitionScore * 0.15
        
        return min(100, max(0, patternScore))
    }
    
    // MARK: - 综合评分计算
    
    private func calculateOverallScore(
        sleep: Double,
        recall: Double,
        emotional: Double,
        pattern: Double
    ) -> Double {
        // 加权平均
        let overall = sleep * 0.30 +
                     recall * 0.25 +
                     emotional * 0.25 +
                     pattern * 0.20
        
        return min(100, max(0, overall))
    }
    
    // MARK: - 趋势计算
    
    private func calculateScoreTrend(currentScore: Double, date: Date) async -> ScoreTrend {
        // 获取前 7 天的评分
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: date)!
        let period = DateInterval(start: startDate, end: date)
        
        guard let historicalScores = try? getScores(for: period),
              historicalScores.count >= 3 else {
            return .stable
        }
        
        let avgHistorical = historicalScores.reduce(0) { $0 + $1.overallScore } / Double(historicalScores.count)
        
        let difference = currentScore - avgHistorical
        
        if difference > 5 {
            return .rising
        } else if difference < -5 {
            return .falling
        } else {
            return .stable
        }
    }
    
    // MARK: - 洞察生成
    
    private func generateInsights(
        sleepScore: Double,
        recallScore: Double,
        emotionalScore: Double,
        patternScore: Double,
        overallScore: Double,
        level: ScoreLevel
    ) -> [String] {
        var insights: [String] = []
        
        // 睡眠相关洞察
        if sleepScore >= 80 {
            insights.append("✨ 睡眠质量优秀，为清晰梦境打下良好基础")
        } else if sleepScore < 60 {
            insights.append("😴 睡眠质量有待提升，建议改善睡眠习惯")
        }
        
        // 记录相关洞察
        if recallScore >= 80 {
            insights.append("📝 梦境记录习惯非常好，继续保持！")
        } else if recallScore < 60 {
            insights.append("✍️ 增加记录频率可以提升梦境回忆能力")
        }
        
        // 情绪相关洞察
        if emotionalScore >= 80 {
            insights.append("💚 情绪状态健康，梦境内容丰富多样")
        } else if emotionalScore < 60 {
            insights.append("💭 近期情绪波动较大，建议关注压力管理")
        }
        
        // 模式相关洞察
        if patternScore >= 80 {
            insights.append("🎯 梦境模式健康，主题和符号丰富多样")
        } else if patternScore < 60 {
            insights.append("🔄 梦境内容较为单一，可以尝试新的体验")
        }
        
        // 总体洞察
        switch level {
        case .excellent:
            insights.append("🌟 整体梦境健康状况非常优秀！")
        case .good:
            insights.append("💚 梦境健康状况良好，有小幅提升空间")
        case .fair:
            insights.append("💛 梦境健康状况一般，建议关注改善")
        case .needsAttention:
            insights.append("🧡 梦境健康需要关注，建议调整生活习惯")
        case .needsImprovement:
            insights.append("❤️ 梦境健康需要改善，建议寻求专业建议")
        }
        
        return insights
    }
    
    // MARK: - 建议生成
    
    private func generateRecommendations(
        sleepScore: Double,
        recallScore: Double,
        emotionalScore: Double,
        patternScore: Double,
        level: ScoreLevel
    ) -> [String] {
        var recommendations: [String] = []
        
        // 睡眠建议
        if sleepScore < 70 {
            recommendations.append("😴 建立规律的睡眠时间，睡前 1 小时避免使用电子设备")
        }
        if sleepScore < 50 {
            recommendations.append("🌙 考虑使用冥想或放松技巧改善睡眠质量")
        }
        
        // 记录建议
        if recallScore < 70 {
            recommendations.append("📱 醒来后立即记录梦境，即使只记得片段")
        }
        if recallScore < 50 {
            recommendations.append("✍️ 设定每日提醒，养成记录习惯")
        }
        
        // 情绪建议
        if emotionalScore < 70 {
            recommendations.append("🧘 尝试冥想或深呼吸练习，平衡情绪")
        }
        if emotionalScore < 50 {
            recommendations.append("💚 考虑与朋友交流或寻求专业支持")
        }
        
        // 模式建议
        if patternScore < 70 {
            recommendations.append("🎨 尝试新的活动和体验，丰富梦境内容")
        }
        
        // 总体建议
        if level == .needsImprovement {
            recommendations.append("🏥 建议咨询睡眠专家或心理咨询师")
        }
        
        return recommendations
    }
    
    // MARK: - 评分历史统计
    
    func getScoreStatistics(period: DateInterval) throws -> ScoreStatistics {
        let scores = try getScores(for: period)
        
        guard !scores.isEmpty else {
            return ScoreStatistics(
                averageScore: 0,
                highestScore: 0,
                lowestScore: 0,
                trend: .stable,
                totalDays: 0,
                recordedDays: 0
            )
        }
        
        let averageScore = scores.reduce(0) { $0 + $1.overallScore } / Double(scores.count)
        let highestScore = scores.max(by: { $0.overallScore < $1.overallScore })?.overallScore ?? 0
        let lowestScore = scores.min(by: { $0.overallScore < $1.overallScore })?.overallScore ?? 0
        
        // 计算趋势
        let firstHalf = scores.prefix(scores.count / 2)
        let secondHalf = scores.suffix(scores.count / 2)
        let firstAvg = firstHalf.reduce(0) { $0 + $1.overallScore } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.overallScore } / Double(secondHalf.count)
        
        let trend: ScoreTrend
        if secondAvg > firstAvg + 3 {
            trend = .rising
        } else if secondAvg < firstAvg - 3 {
            trend = .falling
        } else {
            trend = .stable
        }
        
        return ScoreStatistics(
            averageScore: averageScore,
            highestScore: highestScore,
            lowestScore: lowestScore,
            trend: trend,
            totalDays: Int(period.duration / 86400),
            recordedDays: scores.count
        )
    }
}

// MARK: - 评分统计

struct ScoreStatistics {
    let averageScore: Double
    let highestScore: Double
    let lowestScore: Double
    let trend: ScoreTrend
    let totalDays: Int
    let recordedDays: Int
    
    var coverageRate: Double {
        guard totalDays > 0 else { return 0 }
        return Double(recordedDays) / Double(totalDays) * 100
    }
}
