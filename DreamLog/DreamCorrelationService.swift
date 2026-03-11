//
//  DreamCorrelationService.swift
//  DreamLog
//
//  Phase 20: 梦境关联分析服务
//  分析梦境标签、情绪、时间、主题之间的关联性，发现深层模式
//

import Foundation
import Combine

/// 梦境关联分析服务
class DreamCorrelationService: ObservableObject {
    static let shared = DreamCorrelationService()
    
    @Published var isAnalyzing = false
    @Published var correlationReport: DreamCorrelationReport?
    @Published var error: String?
    
    // MARK: - 数据结构
    
    /// 梦境关联报告
    struct DreamCorrelationReport: Codable, Identifiable {
        let id: UUID
        let generatedAt: Date
        let analysisPeriod: DateInterval
        let totalDreamsAnalyzed: Int
        
        // 标签 - 情绪关联
        let tagEmotionCorrelations: [TagEmotionCorrelation]
        
        // 时间 - 主题关联
        let timeThemeCorrelations: [TimeThemeCorrelation]
        
        // 清晰度 - 内容关联
        let clarityContentCorrelations: [ClarityContentCorrelation]
        
        // 星期 - 模式关联
        let weekdayPatterns: [WeekdayPattern]
        
        // 强关联发现
        let strongCorrelations: [StrongCorrelation]
        
        // 洞察和建议
        let insights: [CorrelationInsight]
        let recommendations: [String]
        
        var id: UUID { UUID() }
    }
    
    /// 标签 - 情绪关联
    struct TagEmotionCorrelation: Codable, Identifiable {
        let tag: String
        let emotion: Emotion
        let correlationStrength: Double  // 0-1, 1 表示强关联
        let occurrenceCount: Int
        let confidence: Double  // 统计置信度
        let insight: String
        var id: UUID { UUID() }
    }
    
    /// 时间 - 主题关联
    struct TimeThemeCorrelation: Codable, Identifiable {
        let timeOfDay: TimeOfDay
        let theme: String
        let correlationStrength: Double
        let occurrenceCount: Int
        let percentage: Double  // 该时段该主题的占比
        var id: UUID { UUID() }
    }
    
    /// 清晰度 - 内容关联
    struct ClarityContentCorrelation: Codable, Identifiable {
        let clarityLevel: Int  // 1-5
        let avgDreamLength: Int  // 平均字数
        let avgSymbolCount: Int  // 平均符号数
        let commonThemes: [String]
        let lucidDreamPercentage: Double
        var id: UUID { UUID() }
    }
    
    /// 星期模式
    struct WeekdayPattern: Codable, Identifiable {
        let weekday: Int  // 1-7 (Sunday-Saturday)
        let weekdayName: String
        let avgDreamCount: Double
        let dominantEmotion: Emotion?
        let dominantTheme: String?
        let avgClarity: Double
        let lucidDreamPercentage: Double
        var id: UUID { UUID() }
    }
    
    /// 强关联发现
    struct StrongCorrelation: Codable, Identifiable {
        let type: CorrelationType
        let factorA: String
        let factorB: String
        let strength: Double  // 0-1
        let confidence: String  // "high", "medium", "low"
        let insight: String
        var id: UUID { UUID() }
    }
    
    /// 关联类型
    enum CorrelationType: String, Codable {
        case tagEmotion = "tag_emotion"
        case timeTheme = "time_theme"
        case clarityContent = "clarity_content"
        case weekdayPattern = "weekday_pattern"
        case custom = "custom"
    }
    
    /// 关联洞察
    struct CorrelationInsight: Codable, Identifiable {
        let title: String
        let description: String
        let confidence: Double
        let actionable: Bool
        var id: UUID { UUID() }
    }
    
    // MARK: - 公开方法
    
    /// 生成关联分析报告
    func generateCorrelationReport(dreams: [Dream], periodDays: Int = 90) async -> DreamCorrelationReport? {
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
        
        guard filteredDreams.count >= 5 else {
            error = "至少需要 5 条梦境数据才能生成关联报告"
            isAnalyzing = false
            return nil
        }
        
        // 模拟分析延迟
        await Task.sleep(nanoseconds: 2_000_000_000)
        
        // 分析各个维度的关联
        let tagEmotionCorrelations = analyzeTagEmotionCorrelations(dreams: filteredDreams)
        let timeThemeCorrelations = analyzeTimeThemeCorrelations(dreams: filteredDreams)
        let clarityContentCorrelations = analyzeClarityContentCorrelations(dreams: filteredDreams)
        let weekdayPatterns = analyzeWeekdayPatterns(dreams: filteredDreams)
        
        // 发现强关联
        let strongCorrelations = discoverStrongCorrelations(
            tagEmotion: tagEmotionCorrelations,
            timeTheme: timeThemeCorrelations,
            clarityContent: clarityContentCorrelations,
            weekdayPatterns: weekdayPatterns
        )
        
        // 生成洞察和建议
        let insights = generateInsights(
            tagEmotion: tagEmotionCorrelations,
            timeTheme: timeThemeCorrelations,
            strongCorrelations: strongCorrelations
        )
        let recommendations = generateRecommendations(insights: insights, strongCorrelations: strongCorrelations)
        
        let report = DreamCorrelationReport(
            id: UUID(),
            generatedAt: Date(),
            analysisPeriod: DateInterval(start: startDate, end: Date()),
            totalDreamsAnalyzed: filteredDreams.count,
            tagEmotionCorrelations: tagEmotionCorrelations,
            timeThemeCorrelations: timeThemeCorrelations,
            clarityContentCorrelations: clarityContentCorrelations,
            weekdayPatterns: weekdayPatterns,
            strongCorrelations: strongCorrelations,
            insights: insights,
            recommendations: recommendations
        )
        
        self.correlationReport = report
        isAnalyzing = false
        
        return report
    }
    
    // MARK: - 关联分析
    
    /// 分析标签 - 情绪关联
    private func analyzeTagEmotionCorrelations(dreams: [Dream]) -> [TagEmotionCorrelation] {
        var tagEmotionMap: [String: [Emotion: Int]] = [:]
        var tagTotalMap: [String: Int] = [:]
        
        // 统计每个标签对应的情绪分布
        for dream in dreams {
            for tag in dream.tags {
                if tagEmotionMap[tag] == nil {
                    tagEmotionMap[tag] = [:]
                }
                if let emotion = dream.emotion {
                    tagEmotionMap[tag]?[emotion, default: 0] += 1
                }
                tagTotalMap[tag, default: 0] += 1
            }
        }
        
        var correlations: [TagEmotionCorrelation] = []
        
        for (tag, emotionCounts) in tagEmotionMap {
            guard let total = tagTotalMap[tag], total >= 3 else { continue }
            
            for (emotion, count) in emotionCounts {
                guard count >= 2 else { continue }
                
                let strength = Double(count) / Double(total)
                let confidence = calculateConfidence(sampleSize: total, proportion: strength)
                
                let insight = generateTagEmotionInsight(tag: tag, emotion: emotion, strength: strength, count: count)
                
                correlations.append(TagEmotionCorrelation(
                    tag: tag,
                    emotion: emotion,
                    correlationStrength: strength,
                    occurrenceCount: count,
                    confidence: confidence,
                    insight: insight
                ))
            }
        }
        
        // 按关联强度排序
        return correlations.sorted { $0.correlationStrength > $1.correlationStrength }
    }
    
    /// 分析时间 - 主题关联
    private func analyzeTimeThemeCorrelations(dreams: [Dream]) -> [TimeThemeCorrelation] {
        var timeThemeMap: [TimeOfDay: [String: Int]] = [:]
        var timeTotalMap: [TimeOfDay: Int] = [:]
        
        for dream in dreams {
            let timeOfDay = getTimeOfDay(from: dream.date)
            
            if timeThemeMap[timeOfDay] == nil {
                timeThemeMap[timeOfDay] = [:]
            }
            
            for theme in dream.themes {
                timeThemeMap[timeOfDay]?[theme, default: 0] += 1
            }
            timeTotalMap[timeOfDay, default: 0] += 1
        }
        
        var correlations: [TimeThemeCorrelation] = []
        
        for (timeOfDay, themeCounts) in timeThemeMap {
            guard let total = timeTotalMap[timeOfDay], total >= 3 else { continue }
            
            for (theme, count) in themeCounts {
                guard count >= 2 else { continue }
                
                let percentage = Double(count) / Double(total) * 100
                let strength = percentage / 100
                
                correlations.append(TimeThemeCorrelation(
                    timeOfDay: timeOfDay,
                    theme: theme,
                    correlationStrength: strength,
                    occurrenceCount: count,
                    percentage: percentage
                ))
            }
        }
        
        return correlations.sorted { $0.correlationStrength > $1.correlationStrength }
    }
    
    /// 分析清晰度 - 内容关联
    private func analyzeClarityContentCorrelations(dreams: [Dream]) -> [ClarityContentCorrelation] {
        var clarityGroups: [Int: [Dream]] = [:]
        
        for dream in dreams {
            let clarityLevel = dream.clarity
            if clarityGroups[clarityLevel] == nil {
                clarityGroups[clarityLevel] = []
            }
            clarityGroups[clarityLevel]?.append(dream)
        }
        
        var correlations: [ClarityContentCorrelation] = []
        
        for (clarityLevel, groupDreams) in clarityGroups {
            guard !groupDreams.isEmpty else { continue }
            
            let avgLength = Int(groupDreams.map { $0.content.count }.reduce(0, +) / Double(groupDreams.count))
            let avgSymbolCount = Int(groupDreams.map { Double($0.symbols.count) }.reduce(0, +) / Double(groupDreams.count))
            
            // 收集常见主题
            var themeCounts: [String: Int] = [:]
            var lucidCount = 0
            
            for dream in groupDreams {
                for theme in dream.themes {
                    themeCounts[theme, default: 0] += 1
                }
                if dream.isLucid {
                    lucidCount += 1
                }
            }
            
            let commonThemes = themeCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
            let lucidPercentage = Double(lucidCount) / Double(groupDreams.count) * 100
            
            correlations.append(ClarityContentCorrelation(
                clarityLevel: clarityLevel,
                avgDreamLength: avgLength,
                avgSymbolCount: avgSymbolCount,
                commonThemes: commonThemes,
                lucidDreamPercentage: lucidPercentage
            ))
        }
        
        return correlations.sorted { $0.clarityLevel > $1.clarityLevel }
    }
    
    /// 分析星期模式
    private func analyzeWeekdayPatterns(dreams: [Dream]) -> [WeekdayPattern] {
        let calendar = Calendar.current
        var weekdayData: [Int: [Dream]] = [:]
        
        for dream in dreams {
            let weekday = calendar.component(.weekday, from: dream.date)
            if weekdayData[weekday] == nil {
                weekdayData[weekday] = []
            }
            weekdayData[weekday]?.append(dream)
        }
        
        var patterns: [WeekdayPattern] = []
        let weekdayNames = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        
        for (weekday, groupDreams) in weekdayData {
            guard !groupDreams.isEmpty else { continue }
            
            // 计算平均梦境数（按周数）
            let uniqueWeeks = Set(groupDreams.map { calendar.component(.weekOfYear, from: $0.date) }).count
            let avgDreamCount = Double(groupDreams.count) / max(Double(uniqueWeeks), 1)
            
            // 主导情绪
            var emotionCounts: [Emotion: Int] = [:]
            for dream in groupDreams {
                if let emotion = dream.emotion {
                    emotionCounts[emotion, default: 0] += 1
                }
            }
            let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key
            
            // 主导主题
            var themeCounts: [String: Int] = [:]
            for dream in groupDreams {
                for theme in dream.themes {
                    themeCounts[theme, default: 0] += 1
                }
            }
            let dominantTheme = themeCounts.max(by: { $0.value < $1.value })?.key
            
            // 平均清晰度
            let avgClarity = groupDreams.map { Double($0.clarity) }.reduce(0, +) / Double(groupDreams.count)
            
            // 清醒梦比例
            let lucidCount = groupDreams.filter { $0.isLucid }.count
            let lucidPercentage = Double(lucidCount) / Double(groupDreams.count) * 100
            
            patterns.append(WeekdayPattern(
                weekday: weekday,
                weekdayName: weekdayNames[weekday] ?? "未知",
                avgDreamCount: avgDreamCount,
                dominantEmotion: dominantEmotion,
                dominantTheme: dominantTheme,
                avgClarity: avgClarity,
                lucidDreamPercentage: lucidPercentage
            ))
        }
        
        return patterns.sorted { $0.weekday < $1.weekday }
    }
    
    // MARK: - 强关联发现
    
    /// 发现强关联
    private func discoverStrongCorrelations(
        tagEmotion: [TagEmotionCorrelation],
        timeTheme: [TimeThemeCorrelation],
        clarityContent: [ClarityContentCorrelation],
        weekdayPatterns: [WeekdayPattern]
    ) -> [StrongCorrelation] {
        var strongCorrelations: [StrongCorrelation] = []
        
        // 标签 - 情绪强关联
        for corr in tagEmotion where corr.correlationStrength > 0.6 && corr.confidence > 0.5 {
            strongCorrelations.append(StrongCorrelation(
                type: .tagEmotion,
                factorA: corr.tag,
                factorB: corr.emotion.rawValue,
                strength: corr.correlationStrength,
                confidence: corr.confidence > 0.7 ? "high" : "medium",
                insight: corr.insight
            ))
        }
        
        // 时间 - 主题强关联
        for corr in timeTheme where corr.correlationStrength > 0.5 {
            strongCorrelations.append(StrongCorrelation(
                type: .timeTheme,
                factorA: corr.timeOfDay.rawValue,
                factorB: corr.theme,
                strength: corr.correlationStrength,
                confidence: corr.percentage > 50 ? "high" : "medium",
                insight: "在\(corr.timeOfDay.rawValue)时段，\"\(corr.theme)\"主题出现频率高达\(String(format: "%.1f", corr.percentage))%"
            ))
        }
        
        // 星期模式强关联
        for pattern in weekdayPatterns where pattern.lucidDreamPercentage > 30 {
            strongCorrelations.append(StrongCorrelation(
                type: .weekdayPattern,
                factorA: pattern.weekdayName,
                factorB: "清醒梦",
                strength: pattern.lucidDreamPercentage / 100,
                confidence: pattern.avgDreamCount > 1 ? "high" : "medium",
                insight: "\(pattern.weekdayName)的清醒梦比例显著较高 (\(String(format: "%.1f", pattern.lucidDreamPercentage))%)"
            ))
        }
        
        return strongCorrelations.sorted { $0.strength > $1.strength }
    }
    
    // MARK: - 洞察生成
    
    /// 生成洞察
    private func generateInsights(
        tagEmotion: [TagEmotionCorrelation],
        timeTheme: [TimeThemeCorrelation],
        strongCorrelations: [StrongCorrelation]
    ) -> [CorrelationInsight] {
        var insights: [CorrelationInsight] = []
        
        // 基于标签 - 情绪关联的洞察
        if let topCorr = tagEmotion.first(where: { $0.correlationStrength > 0.5 }) {
            insights.append(CorrelationInsight(
                title: "标签与情绪关联",
                description: "当你记录\"\(topCorr.tag)\"时，往往伴随着\(topCorr.emotion.rawValue)的情绪",
                confidence: topCorr.confidence,
                actionable: true
            ))
        }
        
        // 基于时间 - 主题关联的洞察
        if let topCorr = timeTheme.first(where: { $0.correlationStrength > 0.4 }) {
            insights.append(CorrelationInsight(
                title: "时段与主题关联",
                description: "\(topCorr.timeOfDay.rawValue)的梦境更容易出现\"\(topCorr.theme)\"主题",
                confidence: topCorr.percentage / 100,
                actionable: true
            ))
        }
        
        // 基于强关联的洞察
        for corr in strongCorrelations.prefix(3) {
            insights.append(CorrelationInsight(
                title: "发现：\(corr.factorA) ↔ \(corr.factorB)",
                description: corr.insight,
                confidence: corr.strength,
                actionable: corr.confidence == "high"
            ))
        }
        
        return insights
    }
    
    /// 生成建议
    private func generateRecommendations(insights: [CorrelationInsight], strongCorrelations: [StrongCorrelation]) -> [String] {
        var recommendations: [String] = []
        
        if !insights.isEmpty {
            recommendations.append("尝试在梦境记录时关注已发现的关联模式，可能帮助你更好地理解梦境")
        }
        
        if strongCorrelations.contains(where: { $0.type == .weekdayPattern }) {
            recommendations.append("某些日期的梦境质量更高，可以在这些日子尝试清醒梦练习")
        }
        
        if strongCorrelations.contains(where: { $0.type == .timeTheme }) {
            recommendations.append("不同时间段的梦境主题不同，可以根据你的兴趣选择最佳记录时间")
        }
        
        if recommendations.isEmpty {
            recommendations.append("继续记录梦境，随着数据积累，关联分析将更加准确")
        }
        
        return recommendations
    }
    
    // MARK: - 辅助方法
    
    /// 计算置信度
    private func calculateConfidence(sampleSize: Int, proportion: Double) -> Double {
        // 简化的置信度计算
        let sampleFactor = min(Double(sampleSize) / 20.0, 1.0)
        let proportionFactor = 1.0 - abs(proportion - 0.5) * 2
        return sampleFactor * proportionFactor
    }
    
    /// 获取时间段
    private func getTimeOfDay(from date: Date) -> TimeOfDay {
        let hour = Calendar.current.component(.hour, from: date)
        
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .night
        }
    }
    
    /// 生成标签 - 情绪洞察
    private func generateTagEmotionInsight(tag: String, emotion: Emotion, strength: Double, count: Int) -> String {
        let strengthDesc: String
        if strength > 0.7 {
            strengthDesc = "非常强"
        } else if strength > 0.5 {
            strengthDesc = "较强"
        } else {
            strengthDesc = "中等"
        }
        
        return "标签\"\(tag)\"与\(emotion.rawValue)情绪呈现\(strengthDesc)关联 (\(count)次出现，\(String(format: "%.0f", strength * 100))%)"
    }
}
