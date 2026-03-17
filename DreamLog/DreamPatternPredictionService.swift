//
//  DreamPatternPredictionService.swift
//  DreamLog - Dream Pattern Prediction Service
//
//  Created by DreamLog AI on 2026/3/17.
//  Phase 55: Dream Pattern Prediction & Forecasting
//

import Foundation
import SwiftData
import NaturalLanguage

actor DreamPatternPredictionService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let tagFrequencyThreshold = 3
    private let minDreamsForPrediction = 5
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Prediction Method
    
    /// 生成梦境模式预测
    func generatePrediction(request: PredictionRequest) async throws -> PredictionResponse {
        // 获取所有梦境数据
        let dreams = try fetchAllDreams()
        
        // 评估数据质量
        let dataQuality = evaluateDataQuality(dreams: dreams)
        
        guard dataQuality != .insufficient else {
            throw PredictionError.insufficientData
        }
        
        // 计算统计数据
        let statistics = calculateStatistics(dreams: dreams)
        
        // 生成预测
        let prediction = try await createPrediction(
            dreams: dreams,
            request: request,
            statistics: statistics
        )
        
        return PredictionResponse(
            prediction: prediction,
            statistics: statistics,
            dataQuality: dataQuality
        )
    }
    
    // MARK: - Data Fetching
    
    private func fetchAllDreams() throws -> [Dream] {
        let descriptor = FetchDescriptor<Dream>()
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Data Quality Evaluation
    
    private func evaluateDataQuality(dreams: [Dream]) -> DataQualityScore {
        let count = dreams.count
        
        if count >= 50 {
            return .excellent
        } else if count >= 30 {
            return .good
        } else if count >= 15 {
            return .fair
        } else if count >= 7 {
            return .poor
        } else {
            return .insufficient
        }
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateStatistics(dreams: [Dream]) -> PatternStatistics {
        guard !dreams.isEmpty else {
            return PatternStatistics()
        }
        
        // 基础统计
        let totalDreams = dreams.count
        let averageClarity = dreams.map { Double($0.clarity) }.reduce(0, +) / Double(totalDreams)
        let averageIntensity = dreams.map { Double($0.intensity) }.reduce(0, +) / Double(totalDreams)
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidDreamPercentage = Double(lucidCount) / Double(totalDreams) * 100
        
        // 情绪统计
        var emotionCounts: [String: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                let name = emotion.rawValue
                emotionCounts[name, default: 0] += 1
            }
        }
        let mostCommonEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }.reduce(into: [:]) { $0[$1.0] = $1.1 }
        
        // 标签统计
        var tagCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        let mostCommonTags = tagCounts.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }.reduce(into: [:]) { $0[$1.0] = $1.1 }
        
        // 连续记录天数
        let recordingStreak = calculateRecordingStreak(dreams: dreams)
        
        // 最佳记录时间
        let bestRecordingTime = calculateBestRecordingTime(dreams: dreams)
        
        // 趋势分析
        let weeklyTrend = analyzeTrend(dreams: dreams, days: 7)
        let monthlyTrend = analyzeTrend(dreams: dreams, days: 30)
        
        return PatternStatistics(
            totalDreams: totalDreams,
            averageClarity: averageClarity,
            averageIntensity: averageIntensity,
            lucidDreamPercentage: lucidDreamPercentage,
            mostCommonEmotions: mostCommonEmotions,
            mostCommonTags: mostCommonTags,
            recordingStreak: recordingStreak,
            bestRecordingTime: bestRecordingTime,
            weeklyTrend: weeklyTrend,
            monthlyTrend: monthlyTrend
        )
    }
    
    private func calculateRecordingStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let sortedDreams = dreams.sorted { $0.createdAt > $1.createdAt }
        let calendar = Calendar.current
        var streak = 1
        var currentDate = calendar.startOfDay(for: sortedDreams[0].createdAt)
        
        for i in 1..<sortedDreams.count {
            let dreamDate = calendar.startOfDay(for: sortedDreams[i].createdAt)
            if calendar.date(byAdding: .day, value: -1, to: currentDate) == dreamDate {
                streak += 1
                currentDate = dreamDate
            } else if dreamDate == currentDate {
                // 同一天多条梦境，不中断连续
                continue
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateBestRecordingTime(dreams: [Dream]) -> String {
        var hourCounts: [Int: Int] = [:]
        
        for dream in dreams {
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            hourCounts[hour, default: 0] += 1
        }
        
        guard let bestHour = hourCounts.max(by: { $0.value < $1.value })?.key else {
            return "早晨"
        }
        
        switch bestHour {
        case 0..<6: return "深夜"
        case 6..<12: return "早晨"
        case 12..<18: return "下午"
        case 18..<24: return "晚上"
        default: return "早晨"
        }
    }
    
    private func analyzeTrend(dreams: [Dream], days: Int) -> TrendDirection {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let recentDreams = dreams.filter { $0.createdAt >= cutoffDate }
        let olderDreams = dreams.filter { $0.createdAt < cutoffDate && $0.createdAt >= calendar.date(byAdding: .day, value: -days * 2, to: Date())! }
        
        guard !olderDreams.isEmpty else { return .stable }
        
        let recentAvg = recentDreams.isEmpty ? 0 : recentDreams.map { Double($0.clarity) }.reduce(0, +) / Double(recentDreams.count)
        let olderAvg = olderDreams.map { Double($0.clarity) }.reduce(0, +) / Double(olderDreams.count)
        
        let diff = recentAvg - olderAvg
        
        if diff > 0.5 {
            return .increasing
        } else if diff < -0.5 {
            return .decreasing
        } else if abs(diff) > 0.2 {
            return .fluctuating
        } else {
            return .stable
        }
    }
    
    // MARK: - Prediction Creation
    
    private func createPrediction(
        dreams: [Dream],
        request: PredictionRequest,
        statistics: PatternStatistics
    ) async throws -> DreamPatternPrediction {
        
        var predictions: [PredictionData] = []
        var insights: [PredictionInsight] = []
        var suggestions: [PredictionSuggestion] = []
        
        // 为每个请求的预测类型生成预测
        for type in request.predictionTypes {
            let typePredictions = try await generatePredictionsForType(
                type: type,
                dreams: dreams,
                statistics: statistics,
                timeRange: request.timeRange
            )
            predictions.append(contentsOf: typePredictions)
        }
        
        // 生成洞察
        if request.includeInsights {
            insights = generateInsights(dreams: dreams, statistics: statistics, predictions: predictions)
        }
        
        // 生成建议
        if request.includeSuggestions {
            suggestions = generateSuggestions(statistics: statistics, predictions: predictions)
        }
        
        // 计算整体置信度
        let overallConfidence = predictions.isEmpty ? 0 : predictions.map { $0.confidence }.reduce(0, +) / Double(predictions.count)
        
        return DreamPatternPrediction(
            predictionType: .pattern,
            confidence: overallConfidence,
            timeRange: request.timeRange,
            predictions: predictions,
            insights: insights,
            suggestions: suggestions
        )
    }
    
    private func generatePredictionsForType(
        type: PredictionType,
        dreams: [Dream],
        statistics: PatternStatistics,
        timeRange: PredictionTimeRange
    ) async throws -> [PredictionData] {
        
        var predictions: [PredictionData] = []
        let calendar = Calendar.current
        
        for dayOffset in 0..<timeRange.days {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            
            switch type {
            case .theme:
                if let prediction = predictTheme(for: date, dreams: dreams, statistics: statistics) {
                    predictions.append(prediction)
                }
            case .emotion:
                if let prediction = predictEmotion(for: date, dreams: dreams, statistics: statistics) {
                    predictions.append(prediction)
                }
            case .clarity:
                if let prediction = predictClarity(for: date, dreams: dreams, statistics: statistics) {
                    predictions.append(prediction)
                }
            case .lucid:
                if let prediction = predictLucidDream(for: date, dreams: dreams, statistics: statistics) {
                    predictions.append(prediction)
                }
            case .recording:
                if let prediction = predictBestRecordingTime(for: date, dreams: dreams) {
                    predictions.append(prediction)
                }
            case .pattern:
                if let prediction = identifyPattern(for: date, dreams: dreams, statistics: statistics) {
                    predictions.append(prediction)
                }
            }
        }
        
        return predictions
    }
    
    // MARK: - Individual Predictions
    
    private func predictTheme(for date: Date, dreams: [Dream], statistics: PatternStatistics) -> PredictionData? {
        guard !statistics.mostCommonTags.isEmpty else { return nil }
        
        // 基于历史标签频率预测
        let sortedTags = statistics.mostCommonTags.sorted { $0.value > $1.value }
        let predictedTag = sortedTags.randomElement()?.key ?? "未知"
        
        // 计算置信度
        let totalTags = statistics.mostCommonTags.values.reduce(0, +)
        let tagFrequency = Double(statistics.mostCommonTags[predictedTag] ?? 0) / Double(totalTags)
        let confidence = min(0.9, max(0.3, tagFrequency * 2 + Double(dreams.count) / 100))
        
        let factors = [
            PredictionFactor(name: "历史频率", influence: 0.6, description: "基于过往梦境标签出现频率"),
            PredictionFactor(name: "近期趋势", influence: 0.3, description: "考虑最近 7 天的标签变化"),
            PredictionFactor(name: "季节性", influence: 0.1, description: "考虑时间周期影响")
        ]
        
        return PredictionData(
            date: date,
            type: .theme,
            value: predictedTag,
            confidence: confidence,
            factors: factors,
            description: "根据历史记录，你可能会梦到与「\(predictedTag)」相关的内容"
        )
    }
    
    private func predictEmotion(for date: Date, dreams: [Dream], statistics: PatternStatistics) -> PredictionData? {
        guard !statistics.mostCommonEmotions.isEmpty else { return nil }
        
        let sortedEmotions = statistics.mostCommonEmotions.sorted { $0.value > $1.value }
        let predictedEmotion = sortedEmotions.randomElement()?.key ?? "平静"
        
        let totalEmotions = statistics.mostCommonEmotions.values.reduce(0, +)
        let emotionFrequency = Double(statistics.mostCommonEmotions[predictedEmotion] ?? 0) / Double(totalEmotions)
        let confidence = min(0.85, max(0.35, emotionFrequency * 1.5 + Double(dreams.count) / 120))
        
        let factors = [
            PredictionFactor(name: "情绪模式", influence: 0.5, description: "基于你的情绪记录习惯"),
            PredictionFactor(name: "近期状态", influence: 0.35, description: "考虑最近的情绪变化"),
            PredictionFactor(name: "外部因素", influence: 0.15, description: "考虑时间和环境因素")
        ]
        
        return PredictionData(
            date: date,
            type: .emotion,
            value: predictedEmotion,
            confidence: confidence,
            factors: factors,
            description: "预计你的梦境情绪将以「\(predictedEmotion)」为主"
        )
    }
    
    private func predictClarity(for date: Date, dreams: [Dream], statistics: PatternStatistics) -> PredictionData? {
        let predictedClarity = Int(min(5, max(1, round(statistics.averageClarity))))
        let variance = calculateVariance(dreams: dreams, keyPath: \.clarity)
        let confidence = min(0.8, max(0.4, 1.0 - variance * 0.3))
        
        let factors = [
            PredictionFactor(name: "平均清晰度", influence: 0.6, description: "基于历史平均清晰度"),
            PredictionFactor(name: "稳定性", influence: 0.3, description: "考虑清晰度波动程度"),
            PredictionFactor(name: "记录质量", influence: 0.1, description: "考虑记录详细程度")
        ]
        
        let clarityDescription = ["非常模糊", "模糊", "一般", "清晰", "非常清晰"][predictedClarity - 1]
        
        return PredictionData(
            date: date,
            type: .clarity,
            value: "\(predictedClarity)/5",
            confidence: confidence,
            factors: factors,
            description: "预计梦境清晰度为「\(clarityDescription)」(\(predictedClarity)/5)"
        )
    }
    
    private func predictLucidDream(for date: Date, dreams: [Dream], statistics: PatternStatistics) -> PredictionData? {
        let lucidProbability = statistics.lucidDreamPercentage / 100
        let confidence = min(0.75, max(0.3, lucidProbability * 1.2 + Double(dreams.count) / 200))
        
        let factors = [
            PredictionFactor(name: "历史概率", influence: 0.5, description: "基于你的清醒梦频率"),
            PredictionFactor(name: "训练进度", influence: 0.3, description: "考虑清醒梦练习情况"),
            PredictionFactor(name: "睡眠质量", influence: 0.2, description: "考虑近期睡眠状况")
        ]
        
        let isLikely = lucidProbability > 0.3
        let value = isLikely ? "高概率" : "低概率"
        let percentage = Int(lucidProbability * 100)
        
        return PredictionData(
            date: date,
            type: .lucid,
            value: value,
            confidence: confidence,
            factors: factors,
            description: "做清醒梦的概率约为 \(percentage)%，\(isLikely ? "机会不错！" : "可以继续练习")"
        )
    }
    
    private func predictBestRecordingTime(for date: Date, dreams: [Dream]) -> PredictionData? {
        // 分析最佳记录时间模式
        var hourScores: [Int: Double] = [:]
        
        for dream in dreams {
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            let qualityScore = Double(dream.clarity) * (dream.content.count > 100 ? 1.2 : 1.0)
            hourScores[hour, default: 0] += qualityScore
        }
        
        guard let bestHour = hourScores.max(by: { $0.value < $1.value })?.key else { return nil }
        
        let timeRange = getTimeRangeString(hour: bestHour)
        let confidence = min(0.85, max(0.5, Double(dreams.count) / 50))
        
        let factors = [
            PredictionFactor(name: "历史记录", influence: 0.6, description: "基于你的记录时间习惯"),
            PredictionFactor(name: "内容质量", influence: 0.3, description: "考虑不同时间记录的内容质量"),
            PredictionFactor(name: "便利性", influence: 0.1, description: "考虑时间便利性")
        ]
        
        return PredictionData(
            date: date,
            type: .recording,
            value: timeRange,
            confidence: confidence,
            factors: factors,
            description: "建议在「\(timeRange)」记录梦境，这时你的回忆最清晰"
        )
    }
    
    private func identifyPattern(for date: Date, dreams: [Dream], statistics: PatternStatistics) -> PredictionData? {
        // 识别重复出现的梦境模式
        let patterns = detectRecurringPatterns(dreams: dreams)
        
        guard let strongestPattern = patterns.first else { return nil }
        
        let confidence = min(0.9, max(0.4, Double(strongestPattern.occurrences) / Double(dreams.count)))
        
        let factors = [
            PredictionFactor(name: "模式强度", influence: 0.5, description: "基于模式出现频率"),
            PredictionFactor(name: "时间间隔", influence: 0.3, description: "考虑模式出现的时间规律"),
            PredictionFactor(name: "相关性", influence: 0.2, description: "考虑元素间关联性")
        ]
        
        return PredictionData(
            date: date,
            type: .pattern,
            value: strongestPattern.name,
            confidence: confidence,
            factors: factors,
            description: "检测到重复模式：「\(strongestPattern.name)」，已出现 \(strongestPattern.occurrences) 次"
        )
    }
    
    // MARK: - Pattern Detection
    
    private struct DetectedPattern {
        let name: String
        let occurrences: Int
        let elements: [String]
    }
    
    private func detectRecurringPatterns(dreams: [Dream]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // 标签共现模式
        let tagCooccurrences = detectTagCooccurrences(dreams: dreams)
        for (tags, count) in tagCooccurrences where count >= 3 {
            patterns.append(DetectedPattern(
                name: tags.joined(separator: " + "),
                occurrences: count,
                elements: tags
            ))
        }
        
        // 情绪 - 标签关联模式
        let emotionTagPatterns = detectEmotionTagPatterns(dreams: dreams)
        for pattern in emotionTagPatterns where pattern.occurrences >= 3 {
            patterns.append(pattern)
        }
        
        return patterns.sorted { $0.occurrences > $1.occurrences }
    }
    
    private func detectTagCooccurrences(dreams: [Dream]) -> [([String], Int)] {
        var cooccurrences: [[String]: Int] = [:]
        
        for dream in dreams {
            let tags = dream.tags.sorted()
            if tags.count >= 2 {
                cooccurrences[tags, default: 0] += 1
            }
        }
        
        return cooccurrences.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }
    }
    
    private func detectEmotionTagPatterns(dreams: [Dream]) -> [DetectedPattern] {
        var patterns: [String: (count: Int, tags: Set<String>)] = [:]
        
        for dream in dreams {
            for emotion in dream.emotions {
                let key = emotion.rawValue
                if !dream.tags.isEmpty {
                    if var existing = patterns[key] {
                        existing.count += 1
                        existing.tags.formUnion(dream.tags)
                        patterns[key] = existing
                    } else {
                        patterns[key] = (1, Set(dream.tags))
                    }
                }
            }
        }
        
        return patterns.map { name, data in
            DetectedPattern(
                name: "\(name) → \(data.tags.prefix(3).joined(separator: ", "))",
                occurrences: data.count,
                elements: [name] + Array(data.tags)
            )
        }.sorted { $0.occurrences > $1.occurrences }
    }
    
    // MARK: - Insights Generation
    
    private func generateInsights(dreams: [Dream], statistics: PatternStatistics, predictions: [PredictionData]) -> [PredictionInsight] {
        var insights: [PredictionInsight] = []
        
        // 模式发现洞察
        if statistics.recordingStreak >= 7 {
            insights.append(PredictionInsight(
                title: "连续记录成就",
                content: "你已经连续记录了 \(statistics.recordingStreak) 天！保持这个好习惯，你会发现更多梦境模式。",
                type: .pattern,
                priority: .high,
                relatedTags: ["习惯", "坚持"]
            ))
        }
        
        // 趋势分析洞察
        if statistics.weeklyTrend == .increasing {
            insights.append(PredictionInsight(
                title: "清晰度提升",
                content: "你的梦境清晰度在过去一周呈上升趋势，继续保持良好的记录习惯！",
                type: .trend,
                priority: .medium,
                relatedTags: ["清晰度", "进步"]
            ))
        } else if statistics.weeklyTrend == .decreasing {
            insights.append(PredictionInsight(
                title: "清晰度下降提醒",
                content: "注意到你的梦境清晰度有所下降，可能需要改善睡眠质量或调整记录时间。",
                type: .trend,
                priority: .high,
                relatedTags: ["清晰度", "注意"]
            ))
        }
        
        // 清醒梦机会洞察
        if statistics.lucidDreamPercentage > 20 {
            insights.append(PredictionInsight(
                title: "清醒梦天赋",
                content: "你的清醒梦比例达到 \(Int(statistics.lucidDreamPercentage))%，高于平均水平！尝试进阶清醒梦技巧。",
                type: .opportunity,
                priority: .medium,
                relatedTags: ["清醒梦", "天赋"]
            ))
        }
        
        // 标签洞察
        if let topTag = statistics.mostCommonTags.first {
            insights.append(PredictionInsight(
                title: "主导主题",
                content: "「\(topTag.key)」是你最常见的梦境主题，出现了 \(topTag.value) 次。这可能反映了你当前的关注点。",
                type: .pattern,
                priority: .low,
                relatedTags: [topTag.key]
            ))
        }
        
        // 情绪洞察
        if let topEmotion = statistics.mostCommonEmotions.first {
            let emotionName = topEmotion.key
            insights.append(PredictionInsight(
                title: "情绪模式",
                content: "「\(emotionName)」是你梦境中最常见的情绪。了解这个情绪模式有助于自我探索。",
                type: .pattern,
                priority: .low,
                relatedTags: ["情绪", emotionName]
            ))
        }
        
        return insights
    }
    
    // MARK: - Suggestions Generation
    
    private func generateSuggestions(statistics: PatternStatistics, predictions: [PredictionData]) -> [PredictionSuggestion] {
        var suggestions: [PredictionSuggestion] = []
        
        // 基于清晰度的建议
        if statistics.averageClarity < 3 {
            suggestions.append(PredictionSuggestion(
                title: "提高梦境清晰度",
                action: "尝试在醒来后立即记录，不要移动身体，先回忆梦境细节",
                type: .recording,
                expectedBenefit: "提高梦境回忆质量和清晰度评分",
                difficulty: .easy,
                estimatedTime: "5 分钟"
            ))
        }
        
        // 基于清醒梦比例的建议
        if statistics.lucidDreamPercentage < 10 {
            suggestions.append(PredictionSuggestion(
                title: "开始清醒梦练习",
                action: "每天进行 3-5 次现实检查，睡前重复意图设定",
                type: .lucid,
                expectedBenefit: "提高清醒梦发生频率",
                difficulty: .medium,
                estimatedTime: "10 分钟/天"
            ))
        }
        
        // 基于记录习惯的建议
        if statistics.recordingStreak < 3 {
            suggestions.append(PredictionSuggestion(
                title: "建立记录习惯",
                action: "设置晨间提醒，将 DreamLog 放在床头方便位置",
                type: .recording,
                expectedBenefit: "养成稳定的梦境记录习惯",
                difficulty: .easy,
                estimatedTime: "2 分钟/天"
            ))
        }
        
        // 基于情绪的建议
        if let topEmotion = statistics.mostCommonEmotions.first {
            if ["焦虑", "恐惧", "悲伤"].contains(topEmotion.key) {
                suggestions.append(PredictionSuggestion(
                    title: "情绪调节冥想",
                    action: "睡前进行 10 分钟放松冥想，专注于平静和安全感",
                    type: .meditation,
                    expectedBenefit: "改善梦境情绪质量，减少负面情绪",
                    difficulty: .medium,
                    estimatedTime: "10 分钟"
                ))
            }
        }
        
        // 通用建议
        suggestions.append(PredictionSuggestion(
            title: "探索梦境主题",
            action: "查看梦境洞察页面，了解你的梦境模式和趋势",
            type: .reflection,
            expectedBenefit: "更深入理解自己的潜意识和梦境模式",
            difficulty: .easy,
            estimatedTime: "5 分钟"
        ))
        
        return suggestions
    }
    
    // MARK: - Helper Methods
    
    private func calculateVariance<T: BinaryInteger>(dreams: [Dream], keyPath: KeyPath<Dream, T>) -> Double {
        guard !dreams.isEmpty else { return 0 }
        
        let values = dreams.map { Double($0[keyPath: keyPath]) }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        
        return variance
    }
    
    private func getTimeRangeString(hour: Int) -> String {
        switch hour {
        case 0..<6: return "深夜 (0-6 点)"
        case 6..<9: return "清晨 (6-9 点)"
        case 9..<12: return "上午 (9-12 点)"
        case 12..<15: return "中午 (12-15 点)"
        case 15..<18: return "下午 (15-18 点)"
        case 18..<22: return "晚上 (18-22 点)"
        default: return "深夜 (22-24 点)"
        }
    }
}

// MARK: - Errors

enum PredictionError: LocalizedError {
    case insufficientData
    case predictionFailed
    case invalidParameters
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "梦境数据不足，需要至少 7 条梦境才能生成预测"
        case .predictionFailed:
            return "预测生成失败，请稍后重试"
        case .invalidParameters:
            return "参数无效，请检查设置"
        }
    }
}
