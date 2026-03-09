//
//  DreamTrendService.swift
//  DreamLog
//
//  Phase 5: AI 梦境趋势预测服务
//  分析用户梦境模式，预测未来梦境趋势，提供个性化洞察
//

import Foundation
import Combine

/// 梦境趋势预测服务
class DreamTrendService: ObservableObject {
    static let shared = DreamTrendService()
    
    @Published var isAnalyzing = false
    @Published var trendReport: DreamTrendReport?
    @Published var error: String?
    
    // MARK: - 数据结构
    
    /// 梦境趋势报告
    struct DreamTrendReport: Codable, Identifiable {
        let id: UUID
        let generatedAt: Date
        let analysisPeriod: DateInterval
        
        // 情绪趋势
        let emotionTrends: [EmotionTrend]
        let dominantEmotion: Emotion?
        let emotionStability: Double // 0-1, 1 表示情绪稳定
        
        // 主题趋势
        let themeTrends: [ThemeTrend]
        let emergingThemes: [String] // 新出现的主题
        let fadingThemes: [String]   // 减弱的主题
        
        // 时间模式
        let timePatterns: TimePatternAnalysis
        let bestRecallTime: TimeOfDay // 最佳梦境回忆时段
        
        // 清晰度趋势
        let clarityTrend: TrendDirection // 上升/下降/稳定
        let averageClarity: Double
        
        // 清醒梦趋势
        let lucidDreamFrequency: Double // 百分比
        let lucidTrend: TrendDirection
        
        // 预测
        let predictions: [DreamPrediction]
        let recommendations: [String] // 个性化建议
        
        var id: UUID { UUID() }
    }
    
    /// 情绪趋势
    struct EmotionTrend: Codable, Identifiable {
        let emotion: Emotion
        let frequency: Int
        let trend: TrendDirection
        let changePercent: Double // 相比上个周期的变化百分比
        let id: UUID { UUID() }
    }
    
    /// 主题趋势
    struct ThemeTrend: Codable, Identifiable {
        let theme: String
        let frequency: Int
        let trend: TrendDirection
        let firstSeen: Date
        let lastSeen: Date
        let id: UUID { UUID() }
    }
    
    /// 时间模式分析
    struct TimePatternAnalysis: Codable {
        let morningDreams: Int
        let afternoonDreams: Int
        let eveningDreams: Int
        let nightDreams: Int
        let peakTime: TimeOfDay
        let weekdayVsWeekend: (weekday: Int, weekend: Int)
    }
    
    /// 梦境预测
    struct DreamPrediction: Codable, Identifiable {
        let type: PredictionType
        let confidence: Double // 0-1
        let description: String
        let timeFrame: String
        let id: UUID { UUID() }
    }
    
    /// 预测类型
    enum PredictionType: String, Codable {
        case emotion = "emotion"           // 情绪预测
        case theme = "theme"               // 主题预测
        case clarity = "clarity"           // 清晰度预测
        case lucid = "lucid"               // 清醒梦预测
        case recurrence = "recurrence"     // 重复梦境预测
    }
    
    /// 趋势方向
    enum TrendDirection: String, Codable {
        case increasing = "increasing"     // 上升
        case decreasing = "decreasing"     // 下降
        case stable = "stable"             // 稳定
        case fluctuating = "fluctuating"   // 波动
    }
    
    // Note: TimeOfDay is defined in Dream.swift - using the shared enum to avoid conflicts
    
    // MARK: - 公开方法
    
    /// 生成梦境趋势报告
    /// - Parameters:
    ///   - dreams: 梦境列表
    ///   - periodDays: 分析周期 (天数)
    /// - Returns: 梦境趋势报告
    func generateTrendReport(dreams: [Dream], periodDays: Int = 30) async -> DreamTrendReport? {
        isAnalyzing = true
        error = nil
        
        guard !dreams.isEmpty else {
            error = "没有足够的梦境数据进行分析"
            isAnalyzing = false
            return nil
        }
        
        // 过滤指定周期内的梦境
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -periodDays, to: Date()) ?? Date.distantPast
        let filteredDreams = dreams.filter { $0.date >= startDate }
        
        guard filteredDreams.count >= 3 else {
            error = "至少需要 3 条梦境数据才能生成趋势报告"
            isAnalyzing = false
            return nil
        }
        
        // 模拟分析延迟
        await Task.sleep(nanoseconds: 1_500_000_000)
        
        // 分析各个维度
        let emotionTrends = analyzeEmotionTrends(dreams: filteredDreams)
        let themeTrends = analyzeThemeTrends(dreams: filteredDreams)
        let timePatterns = analyzeTimePatterns(dreams: filteredDreams)
        let clarityTrend = analyzeClarityTrend(dreams: filteredDreams)
        let lucidTrend = analyzeLucidTrend(dreams: filteredDreams)
        
        // 生成预测和建议
        let predictions = generatePredictions(
            emotionTrends: emotionTrends,
            themeTrends: themeTrends,
            clarityTrend: clarityTrend,
            lucidTrend: lucidTrend
        )
        let recommendations = generateRecommendations(
            emotionTrends: emotionTrends,
            themeTrends: themeTrends,
            timePatterns: timePatterns,
            clarityTrend: clarityTrend,
            lucidTrend: lucidTrend
        )
        
        // 确定主导情绪
        let dominantEmotion = emotionTrends.max(by: { $0.frequency < $1.frequency })?.emotion
        
        // 计算情绪稳定性
        let emotionStability = calculateEmotionStability(emotionTrends: emotionTrends)
        
        // 找出新兴和减弱的主题
        let emergingThemes = themeTrends.filter { $0.trend == .increasing }.map { $0.theme }.prefix(3).map { String($0) }
        let fadingThemes = themeTrends.filter { $0.trend == .decreasing }.map { $0.theme }.prefix(3).map { String($0) }
        
        // 确定最佳回忆时段
        let bestRecallTime = timePatterns.peakTime
        
        // 计算平均清晰度
        let averageClarity = filteredDreams.map { Double($0.clarity) }.reduce(0, +) / Double(filteredDreams.count)
        
        // 计算清醒梦频率
        let lucidCount = filteredDreams.filter { $0.isLucid }.count
        let lucidDreamFrequency = Double(lucidCount) / Double(filteredDreams.count) * 100
        
        let report = DreamTrendReport(
            generatedAt: Date(),
            analysisPeriod: DateInterval(start: startDate, end: Date()),
            emotionTrends: emotionTrends,
            dominantEmotion: dominantEmotion,
            emotionStability: emotionStability,
            themeTrends: themeTrends,
            emergingThemes: Array(emergingThemes),
            fadingThemes: Array(fadingThemes),
            timePatterns: timePatterns,
            bestRecallTime: bestRecallTime,
            clarityTrend: clarityTrend.trend,
            averageClarity: averageClarity,
            lucidDreamFrequency: lucidDreamFrequency,
            lucidTrend: lucidTrend.trend,
            predictions: predictions,
            recommendations: recommendations
        )
        
        self.trendReport = report
        isAnalyzing = false
        
        return report
    }
    
    // MARK: - 分析方法
    
    /// 分析情绪趋势
    private func analyzeEmotionTrends(dreams: [Dream]) -> [EmotionTrend] {
        var emotionCounts: [Emotion: (recent: Int, previous: Int)] = [:]
        
        let calendar = Calendar.current
        let now = Date()
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? Date.distantPast
        
        // 统计最近 14 天和之前 14 天的情绪
        for dream in dreams {
            for emotion in dream.emotions {
                if emotionCounts[emotion] == nil {
                    emotionCounts[emotion] = (recent: 0, previous: 0)
                }
                
                if dream.date >= fourteenDaysAgo {
                    emotionCounts[emotion]?.recent += 1
                } else {
                    emotionCounts[emotion]?.previous += 1
                }
            }
        }
        
        return emotionCounts.map { emotion, counts in
            let changePercent = counts.previous > 0
                ? Double(counts.recent - counts.previous) / Double(counts.previous) * 100
                : (counts.recent > 0 ? 100 : 0)
            
            let trend: TrendDirection
            if changePercent > 20 {
                trend = .increasing
            } else if changePercent < -20 {
                trend = .decreasing
            } else if abs(changePercent) > 5 {
                trend = .fluctuating
            } else {
                trend = .stable
            }
            
            return EmotionTrend(
                emotion: emotion.key,
                frequency: counts.recent,
                trend: trend,
                changePercent: changePercent
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    /// 分析主题趋势
    private func analyzeThemeTrends(dreams: [Dream]) -> [ThemeTrend] {
        var themeData: [String: (count: Int, first: Date, last: Date, recent: Int, previous: Int)] = [:]
        
        let calendar = Calendar.current
        let now = Date()
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? Date.distantPast
        
        for dream in dreams {
            for tag in dream.tags {
                if themeData[tag] == nil {
                    themeData[tag] = (count: 0, first: dream.date, last: dream.date, recent: 0, previous: 0)
                }
                
                var data = themeData[tag]!
                data.count += 1
                if dream.date < data.first { data.first = dream.date }
                if dream.date > data.last { data.last = dream.date }
                
                if dream.date >= fourteenDaysAgo {
                    data.recent += 1
                } else {
                    data.previous += 1
                }
                
                themeData[tag] = data
            }
        }
        
        return themeData.map { tag, data in
            let changePercent = data.previous > 0
                ? Double(data.recent - data.previous) / Double(data.previous) * 100
                : (data.recent > 0 ? 100 : 0)
            
            let trend: TrendDirection
            if changePercent > 20 {
                trend = .increasing
            } else if changePercent < -20 {
                trend = .decreasing
            } else {
                trend = .stable
            }
            
            return ThemeTrend(
                theme: tag,
                frequency: data.recent,
                trend: trend,
                firstSeen: data.first,
                lastSeen: data.last
            )
        }.sorted { $0.frequency > $1.frequency }
    }
    
    /// 分析时间模式
    private func analyzeTimePatterns(dreams: [Dream]) -> TimePatternAnalysis {
        var morning = 0, afternoon = 0, evening = 0, night = 0
        var weekday = 0, weekend = 0
        
        let calendar = Calendar.current
        
        for dream in dreams {
            let hour = calendar.component(.hour, from: dream.date)
            let weekdayComponent = calendar.component(.weekday, from: dream.date)
            
            // 按小时统计
            switch hour {
            case 6..<12: morning += 1
            case 12..<18: afternoon += 1
            case 18..<24: evening += 1
            default: night += 1
            }
            
            // 按工作日/周末统计
            if weekdayComponent == 1 || weekdayComponent == 7 {
                weekend += 1
            } else {
                weekday += 1
            }
        }
        
        // 确定高峰时段
        let maxCount = max(morning, afternoon, evening, night)
        let peakTime: TimeOfDay
        if morning == maxCount { peakTime = .morning }
        else if afternoon == maxCount { peakTime = .afternoon }
        else if evening == maxCount { peakTime = .evening }
        else { peakTime = .night }
        
        return TimePatternAnalysis(
            morningDreams: morning,
            afternoonDreams: afternoon,
            eveningDreams: evening,
            nightDreams: night,
            peakTime: peakTime,
            weekdayVsWeekend: (weekday, weekend)
        )
    }
    
    /// 分析清晰度趋势
    private func analyzeClarityTrend(dreams: [Dream]) -> (trend: TrendDirection, values: [Double]) {
        guard dreams.count >= 2 else {
            return (.stable, [])
        }
        
        let sortedDreams = dreams.sorted { $0.date < $1.date }
        let clarities = sortedDreams.map { Double($0.clarity) }
        
        // 计算趋势 (简单线性回归)
        let n = Double(clarities.count)
        let sumX = n * (n + 1) / 2
        let sumY = clarities.reduce(0, +)
        let sumXY = clarities.enumerated().map { (Double($0.offset + 1) * $0.element) }.reduce(0, +)
        let sumX2 = n * (n + 1) * (2 * n + 1) / 6
        
        let slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)
        
        let trend: TrendDirection
        if slope > 0.1 {
            trend = .increasing
        } else if slope < -0.1 {
            trend = .decreasing
        } else {
            trend = .stable
        }
        
        return (trend, clarities)
    }
    
    /// 分析清醒梦趋势
    private func analyzeLucidTrend(dreams: [Dream]) -> (trend: TrendDirection, frequency: Double) {
        let calendar = Calendar.current
        let now = Date()
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? Date.distantPast
        
        let recentDreams = dreams.filter { $0.date >= fourteenDaysAgo }
        let previousDreams = dreams.filter { $0.date < fourteenDaysAgo }
        
        let recentLucid = recentDreams.filter { $0.isLucid }.count
        let previousLucid = previousDreams.filter { $0.isLucid }.count
        
        let recentFreq = recentDreams.isEmpty ? 0 : Double(recentLucid) / Double(recentDreams.count)
        let previousFreq = previousDreams.isEmpty ? 0 : Double(previousLucid) / Double(previousDreams.count)
        
        let diff = recentFreq - previousFreq
        
        let trend: TrendDirection
        if diff > 0.1 {
            trend = .increasing
        } else if diff < -0.1 {
            trend = .decreasing
        } else {
            trend = .stable
        }
        
        return (trend, recentFreq * 100)
    }
    
    /// 计算情绪稳定性
    private func calculateEmotionStability(emotionTrends: [EmotionTrend]) -> Double {
        guard emotionTrends.count > 1 else { return 1.0 }
        
        let totalFrequency = Double(emotionTrends.map { $0.frequency }.reduce(0, +))
        guard totalFrequency > 0 else { return 1.0 }
        
        // 计算熵 (entropy)
        var entropy = 0.0
        for trend in emotionTrends {
            let p = Double(trend.frequency) / totalFrequency
            if p > 0 {
                entropy -= p * log2(p)
            }
        }
        
        // 归一化到 0-1 (1 表示稳定/单一情绪主导)
        let maxEntropy = log2(Double(emotionTrends.count))
        guard maxEntropy > 0 else { return 1.0 }
        
        return 1.0 - (entropy / maxEntropy)
    }
    
    /// 生成预测
    private func generatePredictions(
        emotionTrends: [EmotionTrend],
        themeTrends: [ThemeTrend],
        clarityTrend: TrendDirection,
        lucidTrend: TrendDirection
    ) -> [DreamPrediction] {
        var predictions: [DreamPrediction] = []
        
        // 情绪预测
        if let increasingEmotion = emotionTrends.first(where: { $0.trend == .increasing }) {
            predictions.append(DreamPrediction(
                type: .emotion,
                confidence: 0.7,
                description: "未来一周你的梦境中\(increasingEmotion.emotion.rawValue)情绪可能会继续增加",
                timeFrame: "未来 7 天"
            ))
        }
        
        // 主题预测
        if let emergingTheme = themeTrends.first(where: { $0.trend == .increasing }) {
            predictions.append(DreamPrediction(
                type: .theme,
                confidence: 0.65,
                description: "\(emergingTheme.theme)相关的梦境主题可能会频繁出现",
                timeFrame: "未来 2 周"
            ))
        }
        
        // 清晰度预测
        if clarityTrend == .increasing {
            predictions.append(DreamPrediction(
                type: .clarity,
                confidence: 0.75,
                description: "你的梦境清晰度正在提升，继续保持记录习惯",
                timeFrame: "持续趋势"
            ))
        } else if clarityTrend == .decreasing {
            predictions.append(DreamPrediction(
                type: .clarity,
                confidence: 0.6,
                description: "尝试在醒来后立即记录，可能会提高梦境清晰度",
                timeFrame: "建议改进"
            ))
        }
        
        // 清醒梦预测
        if lucidTrend == .increasing {
            predictions.append(DreamPrediction(
                type: .lucid,
                confidence: 0.8,
                description: "你的清醒梦频率正在上升，可能很快会经历更多清醒梦",
                timeFrame: "未来 1 个月"
            ))
        }
        
        return predictions
    }
    
    /// 生成个性化建议
    private func generateRecommendations(
        emotionTrends: [EmotionTrend],
        themeTrends: [ThemeTrend],
        timePatterns: TimePatternAnalysis,
        clarityTrend: TrendDirection,
        lucidTrend: TrendDirection
    ) -> [String] {
        var recommendations: [String] = []
        
        // 基于情绪的建议
        if let anxiousTrend = emotionTrends.first(where: { $0.emotion == .anxious && $0.trend == .increasing }) {
            recommendations.append("你最近的焦虑情绪在增加，尝试睡前冥想或深呼吸练习")
        }
        
        if let fearfulTrend = emotionTrends.first(where: { $0.emotion == .fearful && $0.trend == .increasing }) {
            recommendations.append("恐惧梦境增多可能与压力有关，考虑减少睡前刺激")
        }
        
        // 基于清晰度的建议
        if clarityTrend == .decreasing {
            recommendations.append("保持规律的睡眠时间有助于提高梦境清晰度")
            recommendations.append("醒来后先不要动，闭眼回忆梦境细节再记录")
        }
        
        // 基于清醒梦的建议
        if lucidTrend == .increasing {
            recommendations.append("你的清醒梦训练见效了！继续坚持现实检查练习")
        } else if lucidTrend == .stable || lucidTrend == .decreasing {
            recommendations.append("尝试 MILD 或 WBTB 技巧来提高清醒梦频率")
        }
        
        // 基于时间模式的建议
        if timePatterns.nightDreams > timePatterns.morningDreams * 2 {
            recommendations.append("你主要在深夜记录梦境，尝试在床头放置录音设备方便快速记录")
        }
        
        // 通用建议
        if recommendations.isEmpty {
            recommendations.append("继续保持梦境记录习惯，你已经做得很好了!")
            recommendations.append("尝试每周回顾一次梦境，发现隐藏的模式")
        }
        
        return recommendations
    }
}
