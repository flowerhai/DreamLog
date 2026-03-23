//
//  DreamDigitalWellnessService.swift
//  DreamLog
//
//  数字健康核心服务 - 分析屏幕使用与梦境的关联
//

import Foundation
import SwiftData

@ModelActor
final actor DreamDigitalWellnessService {
    
    // MARK: - Properties
    
    private var config: DigitalWellnessConfig
    
    // MARK: - Initialization
    
    init(config: DigitalWellnessConfig = .default) {
        self.config = config
    }
    
    // MARK: - Screen Time Tracking
    
    /// 记录屏幕使用时间
    func recordScreenTime(
        date: Date,
        totalMinutes: Int,
        category: AppCategory,
        topApps: [String],
        pickups: Int,
        notifications: Int
    ) async throws {
        let record = ScreenTimeRecord(
            date: date,
            totalMinutes: totalMinutes,
            category: category.rawValue,
            topApps: topApps,
            pickups: pickups,
            notifications: notifications
        )
        modelContext.insert(record)
        try modelContext.save()
    }
    
    /// 记录睡前屏幕使用
    func recordPreSleepScreenTime(
        date: Date,
        minutesBeforeSleep: Int,
        lastUseTime: Date,
        blueLightExposure: String,
        stimulatingContent: Bool
    ) async throws {
        let record = PreSleepScreenTime(
            date: date,
            minutesBeforeSleep: minutesBeforeSleep,
            lastUseTime: lastUseTime,
            blueLightExposure: blueLightExposure,
            stimulatingContent: stimulatingContent
        )
        modelContext.insert(record)
        try modelContext.save()
    }
    
    // MARK: - Analysis
    
    /// 分析屏幕使用与梦境质量的关联
    func analyzeScreenTimeImpact(days: Int = 30) async throws -> DigitalWellnessStats {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // 获取屏幕使用记录
        let screenTimePredicate = #Predicate<ScreenTimeRecord> {
            $0.date >= startDate
        }
        let screenTimeRecords = try modelContext.fetch(FetchDescriptor(predicate: screenTimePredicate))
        
        // 获取睡前屏幕使用记录
        let preSleepPredicate = #Predicate<PreSleepScreenTime> {
            $0.date >= startDate
        }
        let preSleepRecords = try modelContext.fetch(FetchDescriptor(predicate: preSleepPredicate))
        
        // 获取梦境记录
        let dreamPredicate = #Predicate<Dream> {
            $0.date >= startDate
        }
        let dreams = try modelContext.fetch(FetchDescriptor(predicate: dreamPredicate))
        
        // 计算统计数据
        let avgScreenTimeBeforeSleep = preSleepRecords.isEmpty ? 0 :
            Int(preSleepRecords.map { $0.minutesBeforeSleep }.reduce(0, +) / Double(preSleepRecords.count))
        
        let highScreenTimeDays = preSleepRecords.filter { $0.minutesBeforeSleep > config.screenTimeLimit }.count
        
        // 计算相关性
        let correlation = calculateCorrelation(
            screenTimeRecords: screenTimeRecords,
            dreams: dreams
        )
        
        // 识别问题类别
        let problematicCategories = identifyProblematicCategories(
            records: screenTimeRecords,
            dreams: dreams
        )
        
        // 计算趋势
        let trend = calculateTrend(
            records: preSleepRecords,
            dreams: dreams
        )
        
        // 周统计
        let weeklyStats = calculateWeeklyStats(
            screenTimeRecords: screenTimeRecords,
            preSleepRecords: preSleepRecords,
            dreams: dreams
        )
        
        return DigitalWellnessStats(
            avgScreenTimeBeforeSleep: avgScreenTimeBeforeSleep,
            highScreenTimeDays: highScreenTimeDays,
            correlationWithDreamQuality: correlation.dream,
            correlationWithSleepQuality: correlation.sleep,
            topProblematicCategories: problematicCategories,
            improvementTrend: trend,
            weeklyStats: weeklyStats
        )
    }
    
    /// 生成数字健康洞察
    func generateInsights(days: Int = 7) async throws -> [DigitalWellnessInsight] {
        let stats = try await analyzeScreenTimeImpact(days: days)
        var insights: [DigitalWellnessInsight] = []
        
        // 睡前屏幕时间过长
        if stats.avgScreenTimeBeforeSleep > config.screenTimeLimit {
            let insight = DigitalWellnessInsight(
                type: WellnessInsightType.screenTimeImpact.rawValue,
                title: "睡前屏幕时间过长",
                description: "过去\(days)天，您平均睡前使用屏幕\(stats.avgScreenTimeBeforeSleep)分钟，超过建议的\(config.screenTimeLimit)分钟。",
                severity: stats.avgScreenTimeBeforeSleep > 60 ? "high" : "medium",
                recommendations: [
                    "睡前\(config.screenTimeLimit/2)分钟停止使用电子设备",
                    "启用夜览模式减少蓝光",
                    "尝试阅读纸质书代替刷手机",
                    "使用冥想或深呼吸帮助放松"
                ]
            )
            insights.append(insight)
        }
        
        // 蓝光暴露
        let highBlueLightDays = try await countHighBlueLightDays(days: days)
        if highBlueLightDays > days / 2 {
            let insight = DigitalWellnessInsight(
                type: WellnessInsightType.blueLightEffect.rawValue,
                title: "蓝光暴露频繁",
                description: "过去\(days)天中有\(highBlueLightDays)天存在高蓝光暴露，可能影响褪黑激素分泌。",
                severity: "medium",
                recommendations: [
                    "日落后启用夜览模式",
                    "考虑使用防蓝光眼镜",
                    "调整屏幕色温至暖色调",
                    "使用蓝光过滤应用"
                ]
            )
            insights.append(insight)
        }
        
        // 刺激性内容
        let stimulatingContentDays = try await countStimulatingContentDays(days: days)
        if stimulatingContentDays > 0 {
            let insight = DigitalWellnessInsight(
                type: WellnessInsightType.contentStimulation.rawValue,
                title: "睡前接触刺激内容",
                description: "检测到\(stimulatingContentDays)天睡前接触了刺激性内容（如激烈游戏/惊悚视频）。",
                severity: "medium",
                recommendations: [
                    "睡前避免观看刺激/恐怖内容",
                    "选择轻松的音乐或播客",
                    "尝试听白噪音或自然声音",
                    "建立放松的睡前例行程序"
                ]
            )
            insights.append(insight)
        }
        
        // 使用模式问题
        if !stats.topProblematicCategories.isEmpty {
            let categories = stats.topProblematicCategories.prefix(2).joined(separator: "、")
            let insight = DigitalWellnessInsight(
                type: WellnessInsightType.usagePattern.rawValue,
                title: "特定应用类别影响睡眠",
                description: "\(categories)类应用的使用与较差的梦境质量相关。",
                severity: "low",
                recommendations: [
                    "设置应用使用时间限制",
                    "睡前将这些应用移到主屏幕外",
                    "关闭这些应用的通知",
                    "寻找更健康的替代活动"
                ]
            )
            insights.append(insight)
        }
        
        // 改善趋势
        if stats.improvementTrend == "declining" {
            let insight = DigitalWellnessInsight(
                type: WellnessInsightType.improvement.rawValue,
                title: "数字习惯需要改善",
                description: "近期数字健康指标呈下降趋势，建议调整使用习惯。",
                severity: "medium",
                recommendations: [
                    "设定固定的数字排毒时间",
                    "增加户外活动时间",
                    "培养非电子设备的爱好",
                    "使用屏幕时间管理工具"
                ]
            )
            insights.append(insight)
        }
        
        // 保存洞察
        for insight in insights {
            modelContext.insert(insight)
        }
        try modelContext.save()
        
        return insights
    }
    
    // MARK: - Recommendations
    
    /// 获取个性化建议
    func getPersonalizedRecommendations() async throws -> [String] {
        let stats = try await analyzeScreenTimeImpact(days: 7)
        var recommendations: [String] = []
        
        if stats.avgScreenTimeBeforeSleep > 60 {
            recommendations.append("🌙 建立 30 分钟睡前放松时间，远离电子设备")
        }
        
        if stats.correlationWithDreamQuality < -0.3 {
            recommendations.append("📊 数据显示屏幕时间与梦境清晰度呈负相关，建议减少睡前使用")
        }
        
        if !stats.topProblematicCategories.isEmpty {
            let category = stats.topProblematicCategories.first ?? "某些"
            recommendations.append("⚠️ 限制\(category)类应用的使用时间，尤其是晚上")
        }
        
        if stats.highScreenTimeDays > 3 {
            recommendations.append("📱 本周有\(stats.highScreenTimeDays)天睡前屏幕时间过长，尝试设定使用限制")
        }
        
        if recommendations.isEmpty {
            recommendations.append("✨ 您的数字习惯良好，继续保持！")
            recommendations.append("💡 可以尝试在睡前进行冥想或阅读")
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    
    private func calculateCorrelation(
        screenTimeRecords: [ScreenTimeRecord],
        dreams: [Dream]
    ) -> (dream: Double, sleep: Double) {
        // 简化的相关性计算
        // 实际实现应使用皮尔逊相关系数
        
        if dreams.isEmpty || screenTimeRecords.isEmpty {
            return (0.0, 0.0)
        }
        
        // 模拟计算 - 实际应基于真实数据
        let avgClarity = dreams.map { $0.clarity ?? 3 }.reduce(0, +) / Double(dreams.count)
        let avgScreenTime = screenTimeRecords.map { Double($0.totalMinutes) }.reduce(0, +) / Double(screenTimeRecords.count)
        
        // 简化的负相关模拟
        let dreamCorrelation = avgScreenTime > 120 ? -0.5 : (avgScreenTime > 60 ? -0.3 : -0.1)
        let sleepCorrelation = dreamCorrelation * 0.8
        
        return (dreamCorrelation, sleepCorrelation)
    }
    
    private func identifyProblematicCategories(
        records: [ScreenTimeRecord],
        dreams: [Dream]
    ) -> [String] {
        // 识别与较差梦境质量相关的应用类别
        var categoryImpact: [String: Double] = [:]
        
        for record in records {
            // 简化的影响计算
            categoryImpact[record.category, default: 0] += Double(record.totalMinutes)
        }
        
        // 返回影响最大的类别
        return categoryImpact
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    private func calculateTrend(
        records: [PreSleepScreenTime],
        dreams: [Dream]
    ) -> String {
        guard records.count >= 2 else { return "stable" }
        
        let sorted = records.sorted { $0.date < $1.date }
        let firstHalf = sorted.prefix(sorted.count / 2)
        let secondHalf = sorted.suffix(sorted.count / 2)
        
        let firstAvg = firstHalf.map { $0.minutesBeforeSleep }.reduce(0, +) / Double(firstHalf.count)
        let secondAvg = secondHalf.map { $0.minutesBeforeSleep }.reduce(0, +) / Double(secondHalf.count)
        
        let change = (firstAvg - secondAvg) / firstAvg
        
        if change > 0.2 {
            return "improving"
        } else if change < -0.2 {
            return "declining"
        } else {
            return "stable"
        }
    }
    
    private func calculateWeeklyStats(
        screenTimeRecords: [ScreenTimeRecord],
        preSleepRecords: [PreSleepScreenTime],
        dreams: [Dream]
    ) -> DigitalWellnessStats.WeeklyWellnessStats {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        let weekRecords = preSleepRecords.filter { record in
            calendar.isDate(record.date, inSameWeekAs: Date())
        }
        
        let avgScreenTime = weekRecords.isEmpty ? 0 :
            Int(weekRecords.map { $0.minutesBeforeSleep }.reduce(0, +) / Double(weekRecords.count))
        
        let weekDreams = dreams.filter { dream in
            calendar.isDate(dream.date, inSameWeekAs: Date())
        }
        
        let dreamRecallRate = Double(weekDreams.count) / 7.0
        
        // 计算质量评分 (0-100)
        let screenTimeScore = max(0, 100 - avgScreenTime)
        let recallScore = Int(dreamRecallRate * 100)
        let qualityScore = (screenTimeScore + recallScore) / 2
        
        return DigitalWellnessStats.WeeklyWellnessStats(
            weekStart: weekStart,
            avgScreenTime: avgScreenTime,
            avgSleepLatency: 15, // 模拟值
            dreamRecallRate: dreamRecallRate,
            qualityScore: Double(qualityScore)
        )
    }
    
    private func countHighBlueLightDays(days: Int) async throws -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let predicate = #Predicate<PreSleepScreenTime> {
            $0.date >= startDate && $0.blueLightExposure == "高"
        }
        let records = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return records.count
    }
    
    private func countStimulatingContentDays(days: Int) async throws -> Int {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let predicate = #Predicate<PreSleepScreenTime> {
            $0.date >= startDate && $0.stimulatingContent == true
        }
        let records = try modelContext.fetch(FetchDescriptor(predicate: predicate))
        return records.count
    }
    
    // MARK: - Configuration
    
    func updateConfig(_ newConfig: DigitalWellnessConfig) async throws {
        self.config = newConfig
    }
    
    func getConfig() async -> DigitalWellnessConfig {
        return config
    }
    
    // MARK: - Cleanup
    
    func cleanupOldRecords(olderThan days: Int = 90) async throws {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // 删除旧的屏幕使用记录
        let screenTimePredicate = #Predicate<ScreenTimeRecord> {
            $0.date < cutoffDate
        }
        let oldScreenTime = try modelContext.fetch(FetchDescriptor(predicate: screenTimePredicate))
        for record in oldScreenTime {
            modelContext.delete(record)
        }
        
        // 删除旧的睡前记录
        let preSleepPredicate = #Predicate<PreSleepScreenTime> {
            $0.date < cutoffDate
        }
        let oldPreSleep = try modelContext.fetch(FetchDescriptor(predicate: preSleepPredicate))
        for record in oldPreSleep {
            modelContext.delete(record)
        }
        
        // 删除旧的洞察
        let insightPredicate = #Predicate<DigitalWellnessInsight> {
            $0.createdAt < cutoffDate
        }
        let oldInsights = try modelContext.fetch(FetchDescriptor(predicate: insightPredicate))
        for insight in oldInsights {
            modelContext.delete(insight)
        }
        
        try modelContext.save()
    }
}
