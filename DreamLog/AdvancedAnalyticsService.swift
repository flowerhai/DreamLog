//
//  AdvancedAnalyticsService.swift
//  DreamLog - Phase 20: Advanced Analytics Dashboard
//
//  高级数据分析服务 - 提供深度梦境数据分析和洞察
//

import Foundation
import SwiftData
import NaturalLanguage

/// 高级数据分析服务
@ModelActor
actor AdvancedAnalyticsService {
    
    // MARK: - 单例
    
    static let shared = AdvancedAnalyticsService()
    
    // MARK: - 数据结构
    
    /// 仪表板数据
    struct DashboardData {
        let summary: SummaryMetrics
        let emotionTrend: [EmotionTrendPoint]
        let tagCorrelation: TagCorrelationMatrix
        let timePatterns: TimePatternAnalysis
        let predictions: TrendPredictions
        let insights: [AnalyticsInsight]
        
        struct SummaryMetrics {
            let totalDreams: Int
            let lucidPercentage: Double
            let averageClarity: Double
            let averageIntensity: Double
            let recordingStreak: Int
            let activeTags: Int
            let dominantEmotion: String
            let clarityTrend: String // "上升", "下降", "稳定"
        }
        
        struct EmotionTrendPoint {
            let date: Date
            let emotions: [String: Double]
        }
        
        struct TagCorrelationMatrix {
            let tags: [String]
            let correlations: [[Double]]
            let strongPairs: [(tag1: String, tag2: String, strength: Double)]
        }
        
        struct TimePatternAnalysis {
            let hourDistribution: [Int: Int] // 小时 -> 梦境数
            let weekdayDistribution: [Int: Int] // 星期 -> 梦境数
            let peakHours: [Int]
            let peakWeekdays: [Int]
            let consistencyScore: Double
        }
        
        struct TrendPredictions {
            let clarityPrediction: (trend: String, confidence: Double, value: Double)
            let emotionPrediction: (trend: String, confidence: Double, dominant: String)
            let lucidPrediction: (trend: String, confidence: Double, probability: Double)
            let recordingPrediction: (trend: String, confidence: Double, weeklyCount: Int)
        }
    }
    
    /// 分析洞察
    struct AnalyticsInsight: Identifiable, Hashable {
        let id = UUID()
        let type: InsightType
        let title: String
        let description: String
        let confidence: Double
        let actionable: Bool
        let suggestion: String?
        
        enum InsightType: String, CaseIterable {
            case pattern = "pattern"
            case improvement = "improvement"
            case achievement = "achievement"
            case warning = "warning"
            case opportunity = "opportunity"
        }
    }
    
    // MARK: - 主分析方法
    
    /// 生成完整仪表板数据
    func generateDashboardData(for dateRange: DateRange = .last30Days) async -> DashboardData {
        let dreams = await fetchDreams(for: dateRange)
        
        let summary = await calculateSummaryMetrics(from: dreams)
        let emotionTrend = await analyzeEmotionTrend(from: dreams)
        let tagCorrelation = await analyzeTagCorrelations(from: dreams)
        let timePatterns = await analyzeTimePatterns(from: dreams)
        let predictions = await generatePredictions(from: dreams)
        let insights = await generateInsights(from: dreams, summary: summary, predictions: predictions)
        
        return DashboardData(
            summary: summary,
            emotionTrend: emotionTrend,
            tagCorrelation: tagCorrelation,
            timePatterns: timePatterns,
            predictions: predictions,
            insights: insights
        )
    }
    
    // MARK: - 数据获取
    
    private func fetchDreams(for dateRange: DateRange) async -> [Dream] {
        let now = Date()
        let startDate: Date
        
        switch dateRange {
        case .last7Days:
            startDate = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .last30Days:
            startDate = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        case .last90Days:
            startDate = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
        case .lastYear:
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            startDate = Date.distantPast
        case .custom(let start, _):
            startDate = start
        }
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { dream in
                dream.date >= startDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    // MARK: - 摘要指标计算
    
    private func calculateSummaryMetrics(from dreams: [Dream]) async -> DashboardData.SummaryMetrics {
        let total = dreams.count
        guard total > 0 else {
            return DashboardData.SummaryMetrics(
                totalDreams: 0,
                lucidPercentage: 0,
                averageClarity: 0,
                averageIntensity: 0,
                recordingStreak: 0,
                activeTags: 0,
                dominantEmotion: "无数据",
                clarityTrend: "稳定"
            )
        }
        
        // 清醒梦比例
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidPercentage = Double(lucidCount) / Double(total) * 100
        
        // 平均清晰度和强度
        let avgClarity = dreams.map { Double($0.clarity) }.reduce(0, +) / Double(total)
        let avgIntensity = dreams.map { Double($0.intensity) }.reduce(0, +) / Double(total)
        
        // 连续记录天数
        let streak = calculateRecordingStreak(from: dreams)
        
        // 活跃标签数
        let allTags = Set(dreams.flatMap { $0.tags })
        let activeTags = allTags.count
        
        // 主导情绪
        let emotionCounts: [String: Int] = Dictionary(grouping: dreams.flatMap { $0.emotions.map { $0.rawValue } }) { $0 }
            .mapValues { $0.count }
        let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "无数据"
        
        // 清晰度趋势 (最近 7 天 vs 前 7 天)
        let clarityTrend = calculateClarityTrend(from: dreams)
        
        return DashboardData.SummaryMetrics(
            totalDreams: total,
            lucidPercentage: lucidPercentage,
            averageClarity: avgClarity,
            averageIntensity: avgIntensity,
            recordingStreak: streak,
            activeTags: activeTags,
            dominantEmotion: dominantEmotion,
            clarityTrend: clarityTrend
        )
    }
    
    private func calculateRecordingStreak(from dreams: [Dream]) -> Int {
        guard let latest = dreams.max(by: { $0.date < $1.date }) else { return 0 }
        
        let calendar = Calendar.current
        var streak = 1
        var currentDate = calendar.startOfDay(for: latest.date)
        
        while true {
            guard let previousDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            let hasDreamOnPrevious = dreams.contains { dream in
                calendar.isDate(dream.date, inSameDayAs: previousDate)
            }
            
            if hasDreamOnPrevious {
                streak += 1
                currentDate = previousDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateClarityTrend(from dreams: [Dream]) -> String {
        guard dreams.count >= 14 else { return "数据不足" }
        
        let sorted = dreams.sorted { $0.date < $1.date }
        let recent7 = sorted.suffix(7).map { Double($0.clarity) }
        let previous7 = sorted.dropLast(7).suffix(7).map { Double($0.clarity) }
        
        let recentAvg = recent7.reduce(0, +) / Double(recent7.count)
        let previousAvg = previous7.reduce(0, +) / Double(previous7.count)
        
        let diff = recentAvg - previousAvg
        if diff > 0.3 { return "上升" }
        if diff < -0.3 { return "下降" }
        return "稳定"
    }
    
    // MARK: - 情绪趋势分析
    
    private func analyzeEmotionTrend(from dreams: [Dream]) async -> [DashboardData.EmotionTrendPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: dreams) { dream in
            calendar.startOfDay(for: dream.date)
        }
        
        return grouped.map { date, dayDreams in
            let emotionCounts: [String: Int] = Dictionary(grouping: dayDreams.flatMap { $0.emotions.map { $0.rawValue } }) { $0 }
                .mapValues { $0.count }
            
            let total = Double(dayDreams.count)
            let emotionRatios = emotionCounts.mapValues { $0 / total }
            
            return DashboardData.EmotionTrendPoint(date: date, emotions: emotionRatios)
        }.sorted { $0.date < $1.date }
    }
    
    // MARK: - 标签关联分析
    
    private func analyzeTagCorrelations(from dreams: [Dream]) async -> DashboardData.TagCorrelationMatrix {
        // 获取所有标签
        let allTags = Array(Set(dreams.flatMap { $0.tags }))
        let tagCount = allTags.count
        
        guard tagCount > 1 else {
            return DashboardData.TagCorrelationMatrix(tags: allTags, correlations: [], strongPairs: [])
        }
        
        // 构建标签共现矩阵
        var cooccurrence = Array(repeating: Array(repeating: 0, count: tagCount), count: tagCount)
        var tagFrequency = Array(repeating: 0, count: tagCount)
        
        for dream in dreams {
            let dreamTags = dream.tags
            for tag in dreamTags {
                if let i = allTags.firstIndex(of: tag) {
                    tagFrequency[i] += 1
                }
            }
            
            for i in 0..<dreamTags.count {
                for j in (i+1)..<dreamTags.count {
                    if let idx1 = allTags.firstIndex(of: dreamTags[i]),
                       let idx2 = allTags.firstIndex(of: dreamTags[j]) {
                        cooccurrence[idx1][idx2] += 1
                        cooccurrence[idx2][idx1] += 1
                    }
                }
            }
        }
        
        // 计算皮尔逊相关系数
        var correlations = Array(repeating: Array(repeating: 0.0, count: tagCount), count: tagCount)
        var strongPairs: [(String, String, Double)] = []
        
        for i in 0..<tagCount {
            for j in 0..<tagCount {
                if i == j {
                    correlations[i][j] = 1.0
                } else if i < j {
                    let phi = calculatePhiCoefficient(
                        n11: cooccurrence[i][j],
                        n1: tagFrequency[i],
                        n2: tagFrequency[j],
                        n: dreams.count
                    )
                    correlations[i][j] = phi
                    correlations[j][i] = phi
                    
                    if abs(phi) > 0.3 {
                        strongPairs.append((allTags[i], allTags[j], phi))
                    }
                }
            }
        }
        
        // 按强度排序
        strongPairs.sort { $0.2 > $1.2 }
        
        return DashboardData.TagCorrelationMatrix(
            tags: allTags,
            correlations: correlations,
            strongPairs: Array(strongPairs.prefix(10))
        )
    }
    
    private func calculatePhiCoefficient(n11: Int, n1: Int, n2: Int, n: Int) -> Double {
        let n00 = n - n1 - n2 + n11
        let n10 = n1 - n11
        let n01 = n2 - n11
        
        let numerator = Double(n11 * n00 - n10 * n01)
        let denominator = sqrt(Double(n1 * n0 * n2 * (n - n2)))
        
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }
    
    // MARK: - 时间模式分析
    
    private func analyzeTimePatterns(from dreams: [Dream]) async -> DashboardData.TimePatternAnalysis {
        let calendar = Calendar.current
        
        // 小时分布
        var hourDistribution: [Int: Int] = Dictionary(uniqueKeysWithValues: (0..<24).map { ($0, 0) })
        // 星期分布
        var weekdayDistribution: [Int: Int] = Dictionary(uniqueKeysWithValues: (0..<7).map { ($0, 0) })
        
        for dream in dreams {
            let hour = calendar.component(.hour, from: dream.date)
            let weekday = calendar.component(.weekday, from: dream.date)
            
            hourDistribution[hour, default: 0] += 1
            weekdayDistribution[weekday, default: 0] += 1
        }
        
        // 找出高峰时段
        let sortedHours = hourDistribution.sorted { $0.value > $1.value }
        let peakHours = sortedHours.prefix(3).map { $0.key }
        
        let sortedWeekdays = weekdayDistribution.sorted { $0.value > $1.value }
        let peakWeekdays = sortedWeekdays.prefix(2).map { $0.key }
        
        // 计算规律性评分
        let consistencyScore = calculateRecordingConsistency(from: dreams)
        
        return DashboardData.TimePatternAnalysis(
            hourDistribution: hourDistribution,
            weekdayDistribution: weekdayDistribution,
            peakHours: peakHours,
            peakWeekdays: peakWeekdays,
            consistencyScore: consistencyScore
        )
    }
    
    private func calculateRecordingConsistency(from dreams: [Dream]) -> Double {
        guard dreams.count > 1 else { return 0 }
        
        let calendar = Calendar.current
        let sorted = dreams.sorted { $0.date < $1.date }
        
        var intervals: [Double] = []
        for i in 1..<sorted.count {
            let interval = sorted[i].date.timeIntervalSince(sorted[i-1].date)
            intervals.append(interval)
        }
        
        guard !intervals.isEmpty else { return 0 }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let variance = intervals.map { pow($0 - avgInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let stdDev = sqrt(variance)
        
        // 变异系数 (越小越规律)
        let cv = stdDev / avgInterval
        // 转换为 0-100 的评分
        let score = max(0, min(100, (1 - cv) * 100))
        
        return score
    }
    
    // MARK: - 趋势预测
    
    private func generatePredictions(from dreams: [Dream]) async -> DashboardData.TrendPredictions {
        let sorted = dreams.sorted { $0.date < $1.date }
        
        // 清晰度预测 (线性回归)
        let clarityPrediction = performLinearRegression(
            data: sorted.enumerated().map { (Double($0.offset), Double($0.element.clarity)) }
        )
        
        // 情绪预测
        let emotionPrediction = predictEmotionTrend(from: sorted)
        
        // 清醒梦预测
        let lucidPrediction = predictLucidDreamProbability(from: sorted)
        
        // 记录频率预测
        let recordingPrediction = predictRecordingFrequency(from: sorted)
        
        return DashboardData.TrendPredictions(
            clarityPrediction: clarityPrediction,
            emotionPrediction: emotionPrediction,
            lucidPrediction: lucidPrediction,
            recordingPrediction: recordingPrediction
        )
    }
    
    private func performLinearRegression(data: [(Double, Double)]) -> (trend: String, confidence: Double, value: Double) {
        guard data.count >= 5 else {
            return ("数据不足", 0, 0)
        }
        
        let n = Double(data.count)
        let sumX = data.map { $0.0 }.reduce(0, +)
        let sumY = data.map { $0.1 }.reduce(0, +)
        let sumXY = data.map { $0.0 * $0.1 }.reduce(0, +)
        let sumX2 = data.map { pow($0.0, 2) }.reduce(0, +)
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - pow(sumX, 2))
        let intercept = (sumY - slope * sumX) / n
        
        // 计算 R²
        let meanY = sumY / n
        let ssTot = data.map { pow($0.1 - meanY, 2) }.reduce(0, +)
        let ssRes = data.map { pow($0.1 - (slope * $0.0 + intercept), 2) }.reduce(0, +)
        let rSquared = 1 - (ssRes / ssTot)
        
        let trend: String
        if slope > 0.05 { trend = "上升" }
        else if slope < -0.05 { trend = "下降" }
        else { trend = "稳定" }
        
        // 预测下一个值
        let nextX = n
        let predictedY = slope * nextX + intercept
        
        return (trend, rSquared, predictedY)
    }
    
    private func predictEmotionTrend(from dreams: [Dream]) -> (trend: String, confidence: Double, dominant: String) {
        guard dreams.count >= 10 else {
            return ("数据不足", 0, "无数据")
        }
        
        let recent = dreams.suffix(10)
        let emotionCounts: [String: Int] = Dictionary(grouping: recent.flatMap { $0.emotions.map { $0.rawValue } }) { $0 }
            .mapValues { $0.count }
        
        let dominant = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "无数据"
        
        // 简单趋势分析
        let firstHalf = recent.prefix(5)
        let secondHalf = recent.suffix(5)
        
        let firstDominant = Dictionary(grouping: firstHalf.flatMap { $0.emotions.map { $0.rawValue } }) { $0 }
            .mapValues { $0.count }.max(by: { $0.value < $1.value })?.key
        let secondDominant = dominant
        
        let trend = (firstDominant == secondDominant) ? "稳定" : "变化"
        
        return (trend, 0.7, dominant)
    }
    
    private func predictLucidDreamProbability(from dreams: [Dream]) -> (trend: String, confidence: Double, probability: Double) {
        guard dreams.count >= 10 else {
            return ("数据不足", 0, 0)
        }
        
        let recent = dreams.suffix(10)
        let lucidCount = recent.filter { $0.isLucid }.count
        let probability = Double(lucidCount) / Double(recent.count)
        
        let older = dreams.dropLast(10).suffix(10)
        let olderLucidCount = older.filter { $0.isLucid }.count
        let olderProbability = Double(olderLucidCount) / Double(older.count)
        
        let trend: String
        if probability > olderProbability + 0.1 { trend = "上升" }
        else if probability < olderProbability - 0.1 { trend = "下降" }
        else { trend = "稳定" }
        
        return (trend, 0.6, probability)
    }
    
    private func predictRecordingFrequency(from dreams: [Dream]) -> (trend: String, confidence: Double, weeklyCount: Int) {
        guard dreams.count >= 14 else {
            return ("数据不足", 0, 0)
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 最近 2 周
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        let recentDreams = dreams.filter { $0.date >= twoWeeksAgo }
        
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let lastWeek = recentDreams.filter { $0.date >= sevenDaysAgo }
        let previousWeek = recentDreams.filter { $0.date < sevenDaysAgo }
        
        let trend: String
        if lastWeek.count > previousWeek.count + 2 { trend = "上升" }
        else if lastWeek.count < previousWeek.count - 2 { trend = "下降" }
        else { trend = "稳定" }
        
        return (trend, 0.7, lastWeek.count)
    }
    
    // MARK: - 洞察生成
    
    private func generateInsights(from dreams: [Dream], summary: DashboardData.SummaryMetrics, predictions: DashboardData.TrendPredictions) async -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []
        
        // 成就类洞察
        if summary.recordingStreak >= 7 {
            insights.append(AnalyticsInsight(
                type: .achievement,
                title: "连续记录达人",
                description: "已连续记录 \(summary.recordingStreak) 天，保持得很好！",
                confidence: 1.0,
                actionable: false,
                suggestion: nil
            ))
        }
        
        // 清醒梦洞察
        if summary.lucidPercentage > 20 {
            insights.append(AnalyticsInsight(
                type: .achievement,
                title: "清醒梦探索者",
                description: "你的清醒梦比例达到 \(Int(summary.lucidPercentage))%，高于平均水平！",
                confidence: 0.9,
                actionable: false,
                suggestion: nil
            ))
        } else if summary.lucidPercentage < 5 && dreams.count > 20 {
            insights.append(AnalyticsInsight(
                type: .opportunity,
                title: "清醒梦潜力",
                description: "清醒梦比例较低，可以尝试清醒梦训练技巧。",
                confidence: 0.7,
                actionable: true,
                suggestion: "试试「清醒梦训练」功能中的现实检查练习。"
            ))
        }
        
        // 清晰度趋势洞察
        if predictions.clarityPrediction.trend == "上升" && predictions.clarityPrediction.confidence > 0.5 {
            insights.append(AnalyticsInsight(
                type: .improvement,
                title: "梦境清晰度提升",
                description: "你的梦境清晰度正在提升，说明记录习惯正在改善梦境回忆能力。",
                confidence: predictions.clarityPrediction.confidence,
                actionable: false,
                suggestion: nil
            ))
        } else if predictions.clarityPrediction.trend == "下降" && predictions.clarityPrediction.confidence > 0.5 {
            insights.append(AnalyticsInsight(
                type: .warning,
                title: "清晰度下降提醒",
                description: "近期梦境清晰度有所下降，可能与睡眠质量或压力有关。",
                confidence: predictions.clarityPrediction.confidence,
                actionable: true,
                suggestion: "尝试睡前冥想或改善睡眠环境。"
            ))
        }
        
        // 记录频率洞察
        if predictions.recordingPrediction.trend == "下降" && dreams.count > 10 {
            insights.append(AnalyticsInsight(
                type: .warning,
                title: "记录频率降低",
                description: "最近记录频率有所下降，继续保持记录习惯哦。",
                confidence: predictions.recordingPrediction.confidence,
                actionable: true,
                suggestion: "设置智能提醒，在最佳时间提醒你记录梦境。"
            ))
        }
        
        // 情绪洞察
        if predictions.emotionPrediction.dominant == "焦虑" || predictions.emotionPrediction.dominant == "恐惧" {
            insights.append(AnalyticsInsight(
                type: .opportunity,
                title: "情绪模式发现",
                description: "近期梦境中「\(predictions.emotionPrediction.dominant)」情绪较为突出。",
                confidence: predictions.emotionPrediction.confidence,
                actionable: true,
                suggestion: "可以尝试睡前冥想或放松练习来改善情绪状态。"
            ))
        }
        
        // 模式洞察
        if dreams.count >= 30 {
            insights.append(AnalyticsInsight(
                type: .pattern,
                title: "数据积累充足",
                description: "已积累 \(dreams.count) 个梦境数据，可以进行深度模式分析。",
                confidence: 1.0,
                actionable: true,
                suggestion: "查看「梦境关联图谱」发现更多隐藏模式。"
            ))
        }
        
        return insights
    }
    
    // MARK: - 导出报告
    
    /// 生成分析报告
    func generateReport(for dateRange: DateRange = .last30Days) async -> String {
        let dashboard = await generateDashboardData(for: dateRange)
        
        var report = """
        # DreamLog 数据分析报告
        
        **生成时间**: \(ISO8601DateFormatter().string(from: Date()))
        **分析周期**: \(dateRange.description)
        
        ---
        
        ## 📊 概览
        
        - 总梦境数：\(dashboard.summary.totalDreams)
        - 清醒梦比例：\(String(format: "%.1f", dashboard.summary.lucidPercentage))%
        - 平均清晰度：\(String(format: "%.2f", dashboard.summary.averageClarity))/5.0
        - 平均强度：\(String(format: "%.2f", dashboard.summary.averageIntensity))/5.0
        - 连续记录：\(dashboard.summary.recordingStreak) 天
        - 活跃度标签：\(dashboard.summary.activeTags) 个
        - 主导情绪：\(dashboard.summary.dominantEmotion)
        - 清晰度趋势：\(dashboard.summary.clarityTrend)
        
        ---
        
        ## 🔮 趋势预测
        
        ### 清晰度预测
        - 趋势：\(dashboard.predictions.clarityPrediction.trend)
        - 置信度：\(String(format: "%.0f", dashboard.predictions.clarityPrediction.confidence * 100))%
        
        ### 情绪趋势
        - 趋势：\(dashboard.predictions.emotionPrediction.trend)
        - 主导情绪：\(dashboard.predictions.emotionPrediction.dominant)
        
        ### 清醒梦概率
        - 趋势：\(dashboard.predictions.lucidPrediction.trend)
        - 当前概率：\(String(format: "%.1f", dashboard.predictions.lucidPrediction.probability * 100))%
        
        ### 记录频率
        - 趋势：\(dashboard.predictions.recordingPrediction.trend)
        - 本周记录：\(dashboard.predictions.recordingPrediction.weeklyCount) 次
        
        ---
        
        ## 💡 智能洞察
        
        """
        
        for insight in dashboard.insights {
            report += """
            ### \(insight.title)
            \(insight.description)
            
            """
            if let suggestion = insight.suggestion {
                report += "**建议**: \(suggestion)\n\n"
            }
        }
        
        report += """
        
        ---
        
        ## 🔗 强关联标签
        
        """
        
        for pair in dashboard.tagCorrelation.strongPairs.prefix(5) {
            report += "- **\(pair.tag1)** ↔️ **\(pair.tag2)** (相关系数：\(String(format: "%.2f", pair.strength)))\n"
        }
        
        report += """
        
        ---
        
        *报告由 DreamLog 高级分析引擎生成*
        """
        
        return report
    }
}

// MARK: - DateRange Extension

extension AdvancedAnalyticsService.DashboardData {
    enum DateRange: Hashable {
        case last7Days
        case last30Days
        case last90Days
        case lastYear
        case all
        case custom(start: Date, end: Date)
        
        var description: String {
            switch self {
            case .last7Days: return "最近 7 天"
            case .last30Days: return "最近 30 天"
            case .last90Days: return "最近 90 天"
            case .lastYear: return "最近 1 年"
            case .all: return "全部"
            case .custom: return "自定义"
            }
        }
    }
}
