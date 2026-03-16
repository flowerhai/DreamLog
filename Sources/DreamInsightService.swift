//
//  DreamInsightService.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  洞察生成服务
//

import Foundation
import SwiftData

actor DreamInsightService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 生成洞察
    public func generateInsights(timeRange: TimeRange = .last30Days) async throws -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        // 1. 模式识别
        let patternInsights = try await generatePatternInsights(timeRange: timeRange)
        insights.append(contentsOf: patternInsights)
        
        // 2. 趋势分析
        let trendInsights = try await generateTrendInsights(timeRange: timeRange)
        insights.append(contentsOf: trendInsights)
        
        // 3. 关联分析
        let correlationInsights = try await generateCorrelationInsights(timeRange: timeRange)
        insights.append(contentsOf: correlationInsights)
        
        // 4. 成就洞察
        let achievementInsights = try await generateAchievementInsights(timeRange: timeRange)
        insights.append(contentsOf: achievementInsights)
        
        return insights
    }
    
    /// 保存洞察
    public func saveInsight(_ insight: DreamInsight) async throws {
        modelContext.insert(insight)
        try modelContext.save()
    }
    
    /// 获取所有洞察
    public func getInsights(timeRange: TimeRange = .last30Days) async throws -> [DreamInsight] {
        let fetchDescriptor = FetchDescriptor<DreamInsight>(
            predicate: #Predicate { $0.createdAt >= timeRange.startDate },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 获取重要洞察
    public func getImportantInsights() async throws -> [DreamInsight] {
        let fetchDescriptor = FetchDescriptor<DreamInsight>(
            predicate: #Predicate { $0.isImportant == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    // MARK: - Private Methods - 洞察生成
    
    /// 生成模式识别洞察
    private func generatePatternInsights(timeRange: TimeRange) async throws -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        let dreams = try getDreams(timeRange: timeRange)
        guard dreams.count >= 5 else { return [] }
        
        // 1. 重复标签模式
        let tagCounts = Dictionary(grouping: dreams.flatMap { $0.tags }) { $0 }
            .mapValues { $0.count }
            .filter { $0.value >= 3 }
        
        if let topTag = tagCounts.max(by: { $0.value < $1.value }) {
            let insight = DreamInsight(
                type: .pattern,
                title: "重复出现的主题",
                description: "标签「\(topTag.key)」在你的梦境中频繁出现",
                details: "在\(timeRange.displayName)内，这个标签出现了\(topTag.value)次，占所有梦境的\(Int(Double(topTag.value) / Double(dreams.count) * 100))%",
                dataPoints: ["tag": AnyCodable(topTag.key), "count": AnyCodable(topTag.value)],
                confidence: Double(topTag.value) / Double(dreams.count),
                timeRange: timeRange,
                isImportant: topTag.value >= 5
            )
            insights.append(insight)
        }
        
        // 2. 情绪模式
        let emotionCounts = Dictionary(grouping: dreams.flatMap { $0.emotions.map { $0.rawValue } }) { $0 }
            .mapValues { $0.count }
        
        if let topEmotion = emotionCounts.max(by: { $0.value < $1.value }) {
            let percentage = Int(Double(topEmotion.value) / Double(dreams.count) * 100)
            if percentage >= 40 {
                let insight = DreamInsight(
                    type: .pattern,
                    title: "主导情绪",
                    description: "「\(translateEmotion(topEmotion.key))」是你最近的主要情绪",
                    details: "在\(timeRange.displayName)内，\(percentage)%的梦境包含这种情绪",
                    dataPoints: ["emotion": AnyCodable(topEmotion.key), "percentage": AnyCodable(percentage)],
                    confidence: Double(percentage) / 100.0,
                    timeRange: timeRange,
                    isImportant: percentage >= 60
                )
                insights.append(insight)
            }
        }
        
        // 3. 时间模式
        let hourCounts = Dictionary(grouping: dreams) { dream in
            Calendar.current.component(.hour, from: dream.createdAt)
        }
        .mapValues { $0.count }
        
        if let peakHour = hourCounts.max(by: { $0.value < $1.value }) {
            if peakHour.value >= 3 {
                let timeOfDay = getTimeOfDay(hour: peakHour.key)
                let insight = DreamInsight(
                    type: .pattern,
                    title: "记录习惯",
                    description: "你倾向于在\(timeOfDay)记录梦境",
                    details: "在\(timeRange.displayName)内，\(peakHour.value)个梦境在这个时段记录",
                    dataPoints: ["hour": AnyCodable(peakHour.key), "count": AnyCodable(peakHour.value)],
                    confidence: Double(peakHour.value) / Double(dreams.count),
                    timeRange: timeRange
                )
                insights.append(insight)
            }
        }
        
        return insights
    }
    
    /// 生成趋势分析洞察
    private func generateTrendInsights(timeRange: TimeRange) async throws -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        let dreams = try getDreams(timeRange: timeRange)
        guard dreams.count >= 10 else { return [] }
        
        // 按周分组
        let weeklyGroups = Dictionary(grouping: dreams) { dream -> Date in
            Calendar.current.startOfWeek(for: dream.createdAt) ?? dream.createdAt
        }
        
        let weeklyCounts = weeklyGroups.mapValues { $0.count }
        let sortedWeeks = weeklyCounts.sorted { $0.key < $1.key }
        
        if sortedWeeks.count >= 2 {
            let firstHalf = sortedWeeks.prefix(sortedWeeks.count / 2).map { $0.value }.reduce(0, +)
            let secondHalf = sortedWeeks.suffix(sortedWeeks.count / 2).map { $0.value }.reduce(0, +)
            
            let trend = secondHalf > firstHalf ? "上升" : (secondHalf < firstHalf ? "下降" : "稳定")
            let changePercent = firstHalf > 0 ? Int(Double(secondHalf - firstHalf) / Double(firstHalf) * 100) : 0
            
            let insight = DreamInsight(
                type: .trend,
                title: "记录频率趋势",
                description: "你的梦境记录频率呈\(trend)趋势",
                details: "相比前\(sortedWeeks.count / 2)周，后\(sortedWeeks.count / 2)周的记录数量变化了\(abs(changePercent))%",
                dataPoints: ["trend": AnyCodable(trend), "changePercent": AnyCodable(changePercent)],
                confidence: 0.7,
                timeRange: timeRange,
                isImportant: abs(changePercent) >= 50
            )
            insights.append(insight)
        }
        
        // 清醒梦趋势
        let lucidDreams = dreams.filter { $0.isLucid }
        let lucidRate = Double(lucidDreams.count) / Double(dreams.count)
        
        if lucidRate >= 0.3 {
            let insight = DreamInsight(
                type: .trend,
                title: "清醒梦进展",
                description: "你的清醒梦比例达到\(Int(lucidRate * 100))%",
                details: "在\(timeRange.displayName)内，\(lucidDreams.count)个梦境是清醒梦",
                dataPoints: ["lucidCount": AnyCodable(lucidDreams.count), "lucidRate": AnyCodable(lucidRate)],
                confidence: lucidRate,
                timeRange: timeRange,
                isImportant: lucidRate >= 0.5
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    /// 生成关联分析洞察
    private func generateCorrelationInsights(timeRange: TimeRange) async throws -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        let dreams = try getDreams(timeRange: timeRange)
        guard dreams.count >= 10 else { return [] }
        
        // 标签与情绪关联
        let tagEmotionPairs = dreams.flatMap { dream in
            dream.tags.map { tag in
                (tag: tag, emotions: dream.emotions.map { $0.rawValue })
            }
        }
        
        let tagEmotionCounts = Dictionary(grouping: tagEmotionPairs) { $0.tag }
            .mapValues { pairs in
                Dictionary(grouping: pairs.flatMap { $0.emotions }) { $0 }
                    .mapValues { $0.count }
            }
        
        // 找出强关联
        for (tag, emotionCounts) in tagEmotionCounts {
            if let topEmotion = emotionCounts.max(by: { $0.value < $1.value }) {
                let totalForTag = emotionCounts.values.reduce(0, +)
                if totalForTag >= 3 && Double(topEmotion.value) / Double(totalForTag) >= 0.6 {
                    let insight = DreamInsight(
                        type: .correlation,
                        title: "标签与情绪关联",
                        description: "「\(tag)」常与「\(translateEmotion(topEmotion.key))」情绪一起出现",
                        details: "在包含「\(tag)」的梦境中，\(Int(Double(topEmotion.value) / Double(totalForTag) * 100))%伴随这种情绪",
                        dataPoints: ["tag": AnyCodable(tag), "emotion": AnyCodable(topEmotion.key)],
                        confidence: Double(topEmotion.value) / Double(totalForTag),
                        timeRange: timeRange
                    )
                    insights.append(insight)
                }
            }
        }
        
        return insights
    }
    
    /// 生成成就洞察
    private func generateAchievementInsights(timeRange: TimeRange) async throws -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        let dreams = try getDreams(timeRange: timeRange)
        
        // 连续记录成就
        if let streak = calculateStreak(dreams: dreams) {
            if streak >= 7 {
                let insight = DreamInsight(
                    type: .achievement,
                    title: "连续记录\(streak)天",
                    description: "太棒了！你已经连续记录\(streak)天梦境",
                    details: "继续保持这个好习惯！",
                    dataPoints: ["streak": AnyCodable(streak)],
                    confidence: 1.0,
                    timeRange: timeRange,
                    isImportant: streak >= 14
                )
                insights.append(insight)
            }
        }
        
        // 总记录数成就
        if dreams.count >= 50 {
            let insight = DreamInsight(
                type: .achievement,
                title: "记录里程碑",
                description: "你已经记录了\(dreams.count)个梦境！",
                details: "感谢你的坚持，这些珍贵的记录都是潜意识的宝藏",
                dataPoints: ["totalDreams": AnyCodable(dreams.count)],
                confidence: 1.0,
                timeRange: timeRange,
                isImportant: dreams.count >= 100
            )
            insights.append(insight)
        }
        
        return insights
    }
    
    // MARK: - Helper Methods
    
    private func getDreams(timeRange: TimeRange) async throws -> [Dream] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.createdAt >= timeRange.startDate }
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    private func translateEmotion(_ emotion: String) -> String {
        switch emotion {
        case "calm": return "平静"
        case "happy": return "快乐"
        case "anxious": return "焦虑"
        case "fearful": return "恐惧"
        case "confused": return "困惑"
        case "excited": return "兴奋"
        case "sad": return "悲伤"
        case "angry": return "愤怒"
        case "surprised": return "惊讶"
        default: return "中性"
        }
    }
    
    private func getTimeOfDay(hour: Int) -> String {
        switch hour {
        case 0..<6: return "深夜"
        case 6..<12: return "早晨"
        case 12..<18: return "下午"
        case 18..<24: return "晚上"
        default: return "未知时间"
        }
    }
    
    private func calculateStreak(dreams: [Dream]) -> Int? {
        guard !dreams.isEmpty else { return nil }
        
        let sortedDreams = dreams.sorted { $0.createdAt > $1.createdAt }
        let calendar = Calendar.current
        
        var streak = 1
        for i in 1..<sortedDreams.count {
            let prevDate = sortedDreams[i - 1].createdAt
            let currDate = sortedDreams[i].createdAt
            
            let daysDiff = calendar.dateComponents([.day], from: currDate, to: prevDate).day ?? 0
            
            if daysDiff <= 1 {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}
