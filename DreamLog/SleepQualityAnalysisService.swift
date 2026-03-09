//
//  SleepQualityAnalysisService.swift
//  DreamLog
//
//  睡眠质量深度分析服务 - Phase 5 智能增强功能
//  提供详细的睡眠质量分析、趋势追踪和梦境关联
//

import Foundation
import HealthKit
import SwiftUI

// MARK: - 数据模型

/// 睡眠质量分析报告
struct SleepQualityReport: Identifiable, Codable {
    var id: UUID = UUID()
    var generatedAt: Date
    var analysisPeriod: DateInterval
    
    // 基础指标
    var averageDuration: TimeInterval  // 平均时长 (秒)
    var averageEfficiency: Double      // 平均效率 (0-1)
    var consistencyScore: Double       // 一致性评分 (0-100)
    
    // 睡眠阶段分析
    var stageDistribution: SleepStageDistribution
    var deepSleepTrend: TrendDirection
    var remSleepTrend: TrendDirection
    
    // 睡眠质量
    var qualityDistribution: [SleepRecord.SleepQuality: Int]
    var dominantQuality: SleepRecord.SleepQuality?
    var qualityTrend: TrendDirection
    
    // 作息时间
    var averageBedtime: DateComponents
    var averageWakeTime: DateComponents
    var bedtimeConsistency: Double     // 就寝时间一致性 (0-1)
    var wakeTimeConsistency: Double    // 起床时间一致性 (0-1)
    
    // 梦境关联
    var dreamCorrelation: DreamSleepCorrelation
    
    // 个性化建议
    var recommendations: [SleepRecommendation]
    
    enum TrendDirection: String, Codable {
        case improving = "改善"
        case stable = "稳定"
        case declining = "下降"
        case fluctuating = "波动"
    }
}

/// 睡眠阶段分布
struct SleepStageDistribution: Codable {
    var deepSleepPercent: Double    // 深度睡眠百分比
    var remSleepPercent: Double     // REM 睡眠百分比
    var coreSleepPercent: Double    // 核心睡眠百分比
    var awakePercent: Double        // 清醒时间百分比
    
    var deepSleepDuration: TimeInterval
    var remSleepDuration: TimeInterval
    var coreSleepDuration: TimeInterval
    var awakeDuration: TimeInterval
    
    // 评估
    var deepSleepQuality: SleepQualityRating
    var remSleepQuality: SleepQualityRating
    
    enum SleepQualityRating: String, Codable {
        case excellent = "优秀"
        case good = "良好"
        case fair = "一般"
        case poor = "较差"
        
        var color: String {
            switch self {
            case .excellent: return "4CAF50"
            case .good: return "8BC34A"
            case .fair: return "FFC107"
            case .poor: return "F44336"
            }
        }
    }
}

/// 梦境与睡眠关联分析
struct DreamSleepCorrelation: Codable {
    var correlationStrength: Double          // 关联强度 (0-1)
    var bestSleepQualityDreams: Int          // 优质睡眠后的梦境数量
    var poorSleepQualityDreams: Int          // 差睡眠后的梦境数量
    var averageClarityAfterGoodSleep: Double // 好睡眠后的平均清晰度
    var averageClarityAfterPoorSleep: Double // 差睡眠后的平均清晰度
    var lucidDreamCorrelation: Double        // 清醒梦与睡眠质量关联
    var emotionCorrelation: [Emotion: Double] // 情绪与睡眠关联
    
    var insight: String                      // 关联洞察
}

/// 睡眠建议
struct SleepRecommendation: Identifiable, Codable {
    var id: UUID = UUID()
    var category: RecommendationCategory
    var title: String
    var description: String
    var priority: Priority
    var action: String?
    
    enum Category: String, Codable {
        case duration = "时长"
        case schedule = "作息"
        case environment = "环境"
        case habit = "习惯"
        case health = "健康"
    }
    
    enum Priority: String, Codable {
        case high = "高"
        case medium = "中"
        case low = "低"
        
        var color: String {
            switch self {
            case .high: return "F44336"
            case .medium: return "FF9800"
            case .low: return "4CAF50"
            }
        }
    }
}

// MARK: - 睡眠质量分析服务

@MainActor
class SleepQualityAnalysisService: ObservableObject {
    static let shared = SleepQualityAnalysisService()
    
    @Published var isLoading = false
    @Published var currentReport: SleepQualityReport?
    @Published var errorMessage: String?
    @Published var historicalReports: [SleepQualityReport] = []
    
    private let healthKitService = HealthKitService.shared
    private let dreamStore = DreamStore.shared
    
    private init() {}
    
    // MARK: - 生成分析报告
    
    /// 生成睡眠质量深度分析报告
    func generateReport(periodDays: Int = 30) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 确保睡眠数据已同步
            if healthKitService.sleepRecords.isEmpty {
                await healthKitService.syncSleepData(days: periodDays)
            }
            
            guard !healthKitService.sleepRecords.isEmpty else {
                errorMessage = "暂无睡眠数据，请先同步 HealthKit 数据"
                isLoading = false
                return
            }
            
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -periodDays, to: endDate)!
            let period = DateInterval(start: startDate, end: endDate)
            
            // 过滤时间段内的记录
            let filteredRecords = healthKitService.sleepRecords.filter {
                $0.startDate >= startDate && $0.startDate <= endDate
            }
            
            guard !filteredRecords.isEmpty else {
                errorMessage = "选定时间段内无睡眠数据"
                isLoading = false
                return
            }
            
            // 计算各项指标
            let stageDistribution = calculateStageDistribution(from: filteredRecords)
            let qualityDistribution = calculateQualityDistribution(from: filteredRecords)
            let scheduleAnalysis = calculateScheduleConsistency(from: filteredRecords)
            let dreamCorrelation = analyzeDreamCorrelation(with: filteredRecords)
            let recommendations = generateRecommendations(
                stageDistribution: stageDistribution,
                qualityDistribution: qualityDistribution,
                scheduleAnalysis: scheduleAnalysis,
                dreamCorrelation: dreamCorrelation
            )
            
            currentReport = SleepQualityReport(
                generatedAt: Date(),
                analysisPeriod: period,
                averageDuration: filteredRecords.map { $0.duration }.reduce(0, +) / Double(filteredRecords.count),
                averageEfficiency: calculateAverageEfficiency(from: filteredRecords),
                consistencyScore: calculateConsistencyScore(from: filteredRecords),
                stageDistribution: stageDistribution,
                deepSleepTrend: calculateDeepSleepTrend(in: filteredRecords),
                remSleepTrend: calculateRemSleepTrend(in: filteredRecords),
                qualityDistribution: qualityDistribution,
                dominantQuality: qualityDistribution.max(by: { $0.value < $1.value })?.key,
                qualityTrend: calculateQualityTrend(from: filteredRecords),
                averageBedtime: scheduleAnalysis.averageBedtime,
                averageWakeTime: scheduleAnalysis.averageWakeTime,
                bedtimeConsistency: scheduleAnalysis.bedtimeConsistency,
                wakeTimeConsistency: scheduleAnalysis.wakeTimeConsistency,
                dreamCorrelation: dreamCorrelation,
                recommendations: recommendations
            )
            
        } catch {
            errorMessage = "生成报告失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - 计算睡眠阶段分布
    
    private func calculateStageDistribution(from records: [SleepRecord]) -> SleepStageDistribution {
        var totalDeep = 0
        var totalRem = 0
        var totalCore = 0
        var totalAwake = 0
        var totalStages = 0
        
        for record in records {
            for stage in record.stages {
                totalStages += 1
                switch stage {
                case .deep: totalDeep += 1
                case .rem: totalRem += 1
                case .core: totalCore += 1
                case .awake: totalAwake += 1
                case .unknown: break
                }
            }
        }
        
        guard totalStages > 0 else {
            return SleepStageDistribution(
                deepSleepPercent: 0,
                remSleepPercent: 0,
                coreSleepPercent: 0,
                awakePercent: 0,
                deepSleepDuration: 0,
                remSleepDuration: 0,
                coreSleepDuration: 0,
                awakeDuration: 0,
                deepSleepQuality: .poor,
                remSleepQuality: .poor
            )
        }
        
        let totalDuration = records.map { $0.duration }.reduce(0, +)
        
        let deepPercent = Double(totalDeep) / Double(totalStages)
        let remPercent = Double(totalRem) / Double(totalStages)
        
        return SleepStageDistribution(
            deepSleepPercent: deepPercent * 100,
            remSleepPercent: remPercent * 100,
            coreSleepPercent: Double(totalCore) / Double(totalStages) * 100,
            awakePercent: Double(totalAwake) / Double(totalStages) * 100,
            deepSleepDuration: totalDuration * deepPercent,
            remSleepDuration: totalDuration * remPercent,
            coreSleepDuration: totalDuration * (Double(totalCore) / Double(totalStages)),
            awakeDuration: totalDuration * (Double(totalAwake) / Double(totalStages)),
            deepSleepQuality: rateDeepSleep(deepPercent),
            remSleepQuality: rateRemSleep(remPercent)
        )
    }
    
    private func rateDeepSleep(_ percent: Double) -> SleepStageDistribution.SleepQualityRating {
        if percent >= 15 && percent <= 25 { return .excellent }
        if percent >= 10 { return .good }
        if percent >= 5 { return .fair }
        return .poor
    }
    
    private func rateRemSleep(_ percent: Double) -> SleepStageDistribution.SleepQualityRating {
        if percent >= 20 && percent <= 25 { return .excellent }
        if percent >= 15 { return .good }
        if percent >= 10 { return .fair }
        return .poor
    }
    
    // MARK: - 计算质量分布
    
    private func calculateQualityDistribution(from records: [SleepRecord]) -> [SleepRecord.SleepQuality: Int] {
        Dictionary(grouping: records) { $0.quality }
            .mapValues { $0.count }
    }
    
    // MARK: - 计算作息一致性
    
    private func calculateScheduleConsistency(from records: [SleepRecord]) -> (
        averageBedtime: DateComponents,
        averageWakeTime: DateComponents,
        bedtimeConsistency: Double,
        wakeTimeConsistency: Double
    ) {
        let calendar = Calendar.current
        
        var bedtimes: [TimeInterval] = []
        var waketimes: [TimeInterval] = []
        
        for record in records {
            if let bedtime = calendar.dateComponents([.hour, .minute], from: record.startDate).timeIntervalSinceReferenceDate {
                bedtimes.append(bedtime)
            }
            if let waketime = calendar.dateComponents([.hour, .minute], from: record.endDate).timeIntervalSinceReferenceDate {
                waketimes.append(waketime)
            }
        }
        
        let avgBedtime = bedtimes.isEmpty ? 0 : bedtimes.reduce(0, +) / Double(bedtimes.count)
        let avgWaketime = waketimes.isEmpty ? 0 : waketimes.reduce(0, +) / Double(waketimes.count)
        
        // 计算标准差作为一致性指标
        let bedtimeStdDev = calculateStandardDeviation(bedtimes)
        let waketimeStdDev = calculateStandardDeviation(waketimes)
        
        // 转换为 0-1 的一致性评分 (标准差越小越一致)
        let bedtimeConsistency = max(0, 1 - (bedtimeStdDev / 14400)) // 4 小时标准差为 0
        let wakeTimeConsistency = max(0, 1 - (waketimeStdDev / 14400))
        
        return (
            DateComponents(hour: Int(avgBedtime / 3600) % 24, minute: Int(avgBedtime / 60) % 60),
            DateComponents(hour: Int(avgWaketime / 3600) % 24, minute: Int(avgWaketime / 60) % 60),
            bedtimeConsistency,
            wakeTimeConsistency
        )
    }
    
    private func calculateStandardDeviation(_ values: [TimeInterval]) -> TimeInterval {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    // MARK: - 梦境关联分析
    
    private func analyzeDreamCorrelation(with sleepRecords: [SleepRecord]) -> DreamSleepCorrelation {
        let dreams = dreamStore.dreams
        var goodSleepDreams: [Dream] = []
        var poorSleepDreams: [Dream] = []
        
        for dream in dreams {
            if let sleepRecord = healthKitService.findSleepRecord(for: dream) {
                if sleepRecord.quality == .excellent || sleepRecord.quality == .good {
                    goodSleepDreams.append(dream)
                } else if sleepRecord.quality == .poor {
                    poorSleepDreams.append(dream)
                }
            }
        }
        
        let avgClarityGood = goodSleepDreams.isEmpty ? 0 :
            goodSleepDreams.map { Double($0.clarity) }.reduce(0, +) / Double(goodSleepDreams.count)
        let avgClarityPoor = poorSleepDreams.isEmpty ? 0 :
            poorSleepDreams.map { Double($0.clarity) }.reduce(0, +) / Double(poorSleepDreams.count)
        
        // 清醒梦关联
        let lucidAfterGoodSleep = goodSleepDreams.filter { $0.isLucid }.count
        let lucidAfterPoorSleep = poorSleepDreams.filter { $0.isLucid }.count
        let lucidCorrelation = goodSleepDreams.isEmpty && poorSleepDreams.isEmpty ? 0 :
            Double(lucidAfterGoodSleep) / max(Double(goodSleepDreams.count), 1) -
            Double(lucidAfterPoorSleep) / max(Double(poorSleepDreams.count), 1)
        
        // 情绪关联
        var emotionCorrelation: [Emotion: Double] = [:]
        for emotion in Emotion.allCases {
            let countAfterGoodSleep = goodSleepDreams.filter { $0.emotions.contains(emotion) }.count
            let countAfterPoorSleep = poorSleepDreams.filter { $0.emotions.contains(emotion) }.count
            let correlation = Double(countAfterGoodSleep) / max(Double(goodSleepDreams.count), 1) -
                             Double(countAfterPoorSleep) / max(Double(poorSleepDreams.count), 1)
            emotionCorrelation[emotion] = correlation
        }
        
        // 生成洞察
        let insight = generateCorrelationInsight(
            avgClarityGood: avgClarityGood,
            avgClarityPoor: avgClarityPoor,
            lucidCorrelation: lucidCorrelation
        )
        
        return DreamSleepCorrelation(
            correlationStrength: abs(avgClarityGood - avgClarityPoor) / 5.0,
            bestSleepQualityDreams: goodSleepDreams.count,
            poorSleepQualityDreams: poorSleepDreams.count,
            averageClarityAfterGoodSleep: avgClarityGood,
            averageClarityAfterPoorSleep: avgClarityPoor,
            lucidDreamCorrelation: lucidCorrelation,
            emotionCorrelation: emotionCorrelation,
            insight: insight
        )
    }
    
    private func generateCorrelationInsight(avgClarityGood: Double, avgClarityPoor: Double, lucidCorrelation: Double) -> String {
        let clarityDiff = avgClarityGood - avgClarityPoor
        
        if clarityDiff > 1.5 {
            return "睡眠质量对梦境清晰度有显著影响，优质睡眠后梦境回忆更清晰"
        } else if clarityDiff > 0.5 {
            return "睡眠质量与梦境清晰度呈正相关，保持良好睡眠有助于梦境记录"
        } else if lucidCorrelation > 0.3 {
            return "优质睡眠可能增加清醒梦的发生频率"
        } else {
            return "目前数据未显示睡眠质量与梦境特征的明显关联"
        }
    }
    
    // MARK: - 生成建议
    
    private func generateRecommendations(
        stageDistribution: SleepStageDistribution,
        qualityDistribution: [SleepRecord.SleepQuality: Int],
        scheduleAnalysis: (averageBedtime: DateComponents, averageWakeTime: DateComponents, bedtimeConsistency: Double, wakeTimeConsistency: Double),
        dreamCorrelation: DreamSleepCorrelation
    ) -> [SleepRecommendation] {
        var recommendations: [SleepRecommendation] = []
        
        // 深度睡眠建议
        if stageDistribution.deepSleepQuality == .poor || stageDistribution.deepSleepQuality == .fair {
            recommendations.append(SleepRecommendation(
                category: .health,
                title: "增加深度睡眠",
                description: "您的深度睡眠比例偏低，建议：避免睡前饮酒、保持卧室凉爽、规律运动",
                priority: .high,
                action: "尝试睡前冥想或深呼吸练习"
            ))
        }
        
        // REM 睡眠建议
        if stageDistribution.remSleepQuality == .poor || stageDistribution.remSleepQuality == .fair {
            recommendations.append(SleepRecommendation(
                category: .health,
                title: "改善 REM 睡眠",
                description: "REM 睡眠对记忆和情绪调节很重要，建议：保持充足睡眠时长、减少压力",
                priority: .medium,
                action: "避免睡前使用电子设备"
            ))
        }
        
        // 作息一致性建议
        if scheduleAnalysis.bedtimeConsistency < 0.7 {
            recommendations.append(SleepRecommendation(
                category: .schedule,
                title: "规律就寝时间",
                description: "您的就寝时间波动较大，建议每天固定时间上床睡觉",
                priority: .high,
                action: "设置睡前提醒，建立睡前例行程序"
            ))
        }
        
        // 睡眠时长建议
        let avgHours = scheduleAnalysis.averageWakeTime.hour! - scheduleAnalysis.averageBedtime.hour!
        if avgHours < 7 {
            recommendations.append(SleepRecommendation(
                category: .duration,
                title: "延长睡眠时间",
                description: "平均睡眠时长不足 7 小时，建议提前就寝或延后起床",
                priority: .high,
                action: "目标每晚 7-9 小时睡眠"
            ))
        }
        
        // 梦境关联建议
        if dreamCorrelation.correlationStrength > 0.5 {
            recommendations.append(SleepRecommendation(
                category: .habit,
                title: "优化睡眠提升梦境质量",
                description: "数据显示睡眠质量影响梦境清晰度，改善睡眠可提升梦境记录质量",
                priority: .medium,
                action: "保持睡眠日志，追踪睡眠与梦境的关系"
            ))
        }
        
        // 环境建议 (通用)
        if recommendations.isEmpty {
            recommendations.append(SleepRecommendation(
                category: .environment,
                title: "保持良好睡眠环境",
                description: "继续保持良好的睡眠习惯，注意卧室温度、光线和噪音控制",
                priority: .low,
                action: "使用遮光窗帘，保持卧室温度 18-22°C"
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    // MARK: - 辅助方法
    
    private func calculateAverageEfficiency(from records: [SleepRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        let scores = records.map { record -> Double in
            switch record.quality {
            case .excellent: return 1.0
            case .good: return 0.8
            case .fair: return 0.6
            case .poor: return 0.4
            }
        }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private func calculateConsistencyScore(from records: [SleepRecord]) -> Double {
        guard records.count > 1 else { return 100 }
        
        let durations = records.map { $0.duration }
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - avgDuration, 2) }.reduce(0, +) / Double(durations.count - 1)
        let stdDev = sqrt(variance)
        
        // 标准差越小，一致性越高
        let consistency = max(0, 100 - (stdDev / 3600 * 20)) // 每小时标准差扣 20 分
        return consistency
    }
    
    private func calculateDeepSleepTrend(in records: [SleepRecord]) -> SleepQualityReport.TrendDirection {
        guard records.count >= 4 else { return .stable }
        
        let sorted = records.sorted { $0.startDate < $1.startDate }
        let midPoint = sorted.count / 2
        
        let firstHalf = sorted.prefix(midPoint).map { $0.stages.filter { $0 == .deep }.count }.reduce(0, +) / midPoint
        let secondHalf = sorted.suffix(sorted.count - midPoint).map { $0.stages.filter { $0 == .deep }.count }.reduce(0, +) / (sorted.count - midPoint)
        
        let change = Double(secondHalf - firstHalf) / Double(max(firstHalf, 1))
        
        if change > 0.1 { return .improving }
        if change < -0.1 { return .declining }
        if abs(change) > 0.05 { return .fluctuating }
        return .stable
    }
    
    private func calculateRemSleepTrend(in records: [SleepRecord]) -> SleepQualityReport.TrendDirection {
        guard records.count >= 4 else { return .stable }
        
        let sorted = records.sorted { $0.startDate < $1.startDate }
        let midPoint = sorted.count / 2
        
        let firstHalf = sorted.prefix(midPoint).map { $0.stages.filter { $0 == .rem }.count }.reduce(0, +) / midPoint
        let secondHalf = sorted.suffix(sorted.count - midPoint).map { $0.stages.filter { $0 == .rem }.count }.reduce(0, +) / (sorted.count - midPoint)
        
        let change = Double(secondHalf - firstHalf) / Double(max(firstHalf, 1))
        
        if change > 0.1 { return .improving }
        if change < -0.1 { return .declining }
        if abs(change) > 0.05 { return .fluctuating }
        return .stable
    }
    
    private func calculateQualityTrend(from records: [SleepRecord]) -> SleepQualityReport.TrendDirection {
        guard records.count >= 4 else { return .stable }
        
        let sorted = records.sorted { $0.startDate < $1.startDate }
        let qualityScores: [Double] = sorted.map {
            switch $0.quality {
            case .excellent: return 4.0
            case .good: return 3.0
            case .fair: return 2.0
            case .poor: return 1.0
            }
        }
        
        let midPoint = qualityScores.count / 2
        let firstHalf = qualityScores.prefix(midPoint).reduce(0, +) / Double(midPoint)
        let secondHalf = qualityScores.suffix(qualityScores.count - midPoint).reduce(0, +) / Double(qualityScores.count - midPoint)
        
        let change = secondHalf - firstHalf
        
        if change > 0.3 { return .improving }
        if change < -0.3 { return .declining }
        if abs(change) > 0.15 { return .fluctuating }
        return .stable
    }
    
    // MARK: - 历史报告
    
    /// 保存当前报告到历史记录
    func saveCurrentReport() {
        if let report = currentReport {
            historicalReports.insert(report, at: 0)
            if historicalReports.count > 10 {
                historicalReports.removeLast()
            }
        }
    }
    
    /// 获取历史趋势
    func getHistoricalTrend() -> [(date: Date, efficiency: Double)] {
        historicalReports.map { ($0.generatedAt, $0.averageEfficiency) }
            .sorted { $0.date < $1.date }
    }
}
