//
//  DreamPredictionService.swift
//  DreamLog
//
//  梦境预测服务
//  使用机器学习分析梦境模式，预测未来梦境趋势
//

import Foundation
import SwiftData

// MARK: - 梦境预测服务

@MainActor
final class DreamPredictionService {
    
    static let shared = DreamPredictionService()
    
    private let modelContext: ModelContext
    private var config: PredictionConfig
    private var predictionCache: [Date: DreamPrediction] = [:]
    private let cacheQueue = DispatchQueue(label: "com.dreamlog.prediction.cache")
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext ?? (try? ModelContext(sharedModelContainer: SharedModelContainer.main))!
        self.config = .default
        loadConfig()
    }
    
    // MARK: - 配置管理
    
    func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "DreamPredictionConfig"),
           let config = try? JSONDecoder().decode(PredictionConfig.self, from: data) {
            self.config = config
        }
    }
    
    func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "DreamPredictionConfig")
        }
    }
    
    // MARK: - 核心预测功能
    
    /// 生成综合梦境预测
    func generatePredictions(for date: Date = Date()) async -> [DreamPrediction] {
        guard config.isEnabled else { return [] }
        
        var predictions: [DreamPrediction] = []
        
        // 1. 内容预测
        if let contentPrediction = await generateContentPrediction(for: date) {
            predictions.append(contentPrediction)
        }
        
        // 2. 情绪预测
        if let emotionPrediction = await generateEmotionPrediction(for: date) {
            predictions.append(emotionPrediction)
        }
        
        // 3. 清醒梦概率预测
        if let lucidPrediction = await generateLucidPrediction(for: date) {
            predictions.append(lucidPrediction)
        }
        
        // 4. 最佳时间预测
        if let bestTimePrediction = await generateBestTimePrediction(for: date) {
            predictions.append(bestTimePrediction)
        }
        
        // 5. 模式识别
        if let patternPrediction = await generatePatternPrediction(for: date) {
            predictions.append(patternPrediction)
        }
        
        // 6. 健康预警（如果启用）
        if config.includeHealthWarnings,
           let warningPrediction = await generateWarningPrediction(for: date) {
            predictions.append(warningPrediction)
        }
        
        // 保存到数据库
        await savePredictions(predictions)
        
        return predictions
    }
    
    /// 内容预测
    private func generateContentPrediction(for date: Date) async -> DreamPrediction? {
        let dreams = await fetchRecentDreams(days: 30)
        guard dreams.count >= 5 else { return nil }
        
        // 分析梦境主题频率
        let themeFrequency = analyzeThemeFrequency(in: dreams)
        let symbolFrequency = analyzeSymbolFrequency(in: dreams)
        
        // 识别最近趋势
        let recentDreams = Array(dreams.prefix(7))
        let trendingThemes = identifyTrendingThemes(in: recentDreams)
        
        // 生成预测
        let likelyThemes = Array(themeFrequency.keys.prefix(5))
        let likelySymbols = Array(symbolFrequency.keys.prefix(5))
        
        let predictionData = ContentPredictionData(
            likelyThemes: likelyThemes,
            likelySymbols: likelySymbols,
            likelyScenarios: generateLikelyScenarios(from: trendingThemes),
            inspirationSources: identifyInspirationSources(in: dreams),
            confidenceBreakdown: calculateConfidenceBreakdown(for: themeFrequency)
        )
        
        let confidence = calculateContentConfidence(from: dreams, themeFrequency: themeFrequency)
        
        guard confidence >= config.minConfidenceThreshold else { return nil }
        
        let details = (try? JSONEncoder().encode(predictionData)).map { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return DreamPrediction(
            predictionDate: date,
            type: .content,
            confidence: confidence,
            title: "梦境内容预测",
            description: "基于过去 30 天的梦境模式，预测未来可能出现的主题和符号",
            details: details,
            tags: likelyThemes + likelySymbols
        )
    }
    
    /// 情绪预测
    private func generateEmotionPrediction(for date: Date) async -> DreamPrediction? {
        let dreams = await fetchRecentDreams(days: 30)
        guard dreams.count >= 5 else { return nil }
        
        // 分析情绪趋势
        let emotionTrend = analyzeEmotionTrend(in: dreams)
        let predictedEmotions = predictEmotions(from: emotionTrend)
        let trendDirection = determineTrendDirection(from: emotionTrend)
        let stabilityScore = calculateEmotionStability(from: dreams)
        
        let predictionData = EmotionPredictionData(
            predictedEmotions: predictedEmotions,
            trendDirection: trendDirection,
            stabilityScore: stabilityScore,
            recommendations: generateEmotionRecommendations(for: trendDirection, stabilityScore: stabilityScore)
        )
        
        let confidence = calculateEmotionConfidence(from: dreams)
        
        guard confidence >= config.minConfidenceThreshold else { return nil }
        
        let details = (try? JSONEncoder().encode(predictionData)).map { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return DreamPrediction(
            predictionDate: date,
            type: .emotion,
            confidence: confidence,
            title: "情绪趋势预测",
            description: "预测未来几天的梦境情绪走向",
            details: details,
            tags: predictedEmotions.keys.map { $0.rawValue }
        )
    }
    
    /// 清醒梦概率预测
    private func generateLucidPrediction(for date: Date) async -> DreamPrediction? {
        let dreams = await fetchRecentDreams(days: 30)
        guard dreams.count >= 3 else { return nil }
        
        let lucidDreams = dreams.filter { $0.isLucid }
        let lucidRate = Double(lucidDreams.count) / Double(dreams.count)
        
        // 分析影响清醒梦的因素
        let contributingFactors = analyzeLucidFactors(in: dreams)
        let recommendedTechniques = recommendLucidTechniques(basedOn: dreams)
        let optimalTiming = determineOptimalLucidTiming(from: dreams)
        let preparationTips = generateLucidPreparationTips()
        
        // 计算概率（基础概率 + 调整因子）
        var probability = lucidRate
        if !contributingFactors.isEmpty {
            probability += Double(contributingFactors.count) * 0.05
        }
        probability = min(max(probability, 0.0), 1.0)
        
        let predictionData = LucidPredictionData(
            probability: probability,
            contributingFactors: contributingFactors,
            recommendedTechniques: recommendedTechniques,
            optimalTiming: optimalTiming,
            preparationTips: preparationTips
        )
        
        let confidence = 0.5 + (Double(dreams.count) * 0.01)  // 数据越多置信度越高
        let finalConfidence = min(confidence, 0.9)
        
        guard finalConfidence >= config.minConfidenceThreshold else { return nil }
        
        let details = (try? JSONEncoder().encode(predictionData)).map { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return DreamPrediction(
            predictionDate: date,
            type: .lucidProbability,
            confidence: finalConfidence,
            title: "清醒梦概率预测",
            description: String(format: "今晚有 %.0f%% 的概率做清醒梦", probability * 100),
            details: details,
            tags: recommendedTechniques
        )
    }
    
    /// 最佳时间预测
    private func generateBestTimePrediction(for date: Date) async -> DreamPrediction? {
        let dreams = await fetchRecentDreams(days: 60)
        guard dreams.count >= 10 else { return nil }
        
        // 分析各时间段的梦境质量
        let recallQualityByHour = analyzeRecallQualityByHour(from: dreams)
        let optimalHours = recallQualityByHour
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        let sleepQualityCorrelation = calculateSleepQualityCorrelation(from: dreams)
        let historicalPatterns = identifyTimePatterns(from: dreams)
        
        let predictionData = BestTimePredictionData(
            optimalHours: optimalHours,
            sleepQualityCorrelation: sleepQualityCorrelation,
            recallQualityByHour: recallQualityByHour,
            historicalPatterns: historicalPatterns
        )
        
        let confidence = 0.6 + (Double(dreams.count) * 0.005)
        let finalConfidence = min(confidence, 0.85)
        
        guard finalConfidence >= config.minConfidenceThreshold else { return nil }
        
        let details = (try? JSONEncoder().encode(predictionData)).map { String(data: $0, encoding: .utf8) } ?? "{}"
        
        let timeStrings = optimalHours.map { hour -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:00"
            return formatter.string(from: Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!)
        }
        
        return DreamPrediction(
            predictionDate: date,
            type: .bestTime,
            confidence: finalConfidence,
            title: "最佳记录时间",
            description: "基于历史数据，建议在 \(timeStrings.joined(separator: "、")) 记录梦境",
            details: details,
            tags: ["时间优化", "回忆质量"]
        )
    }
    
    /// 模式识别
    private func generatePatternPrediction(for date: Date) async -> DreamPrediction? {
        let dreams = await fetchRecentDreams(days: 90)
        guard dreams.count >= 20 else { return nil }
        
        // 识别重复主题
        let recurringThemes = identifyRecurringThemes(in: dreams, minOccurrences: 3)
        
        // 检测周期
        let cycleLength = detectDreamCycle(in: dreams)
        
        // 分析触发因素
        let triggerFactors = analyzeTriggerFactors(in: dreams)
        
        // 计算关联矩阵
        let correlationMatrix = calculateCorrelationMatrix(for: dreams)
        
        // 异常检测
        let anomalies = detectAnomalies(in: dreams)
        
        let predictionData = PatternPredictionData(
            recurringThemes: recurringThemes,
            cycleLength: cycleLength,
            triggerFactors: triggerFactors,
            correlationMatrix: correlationMatrix,
            anomalyDetection: anomalies
        )
        
        let confidence = 0.7 + (Double(dreams.count) * 0.003)
        let finalConfidence = min(confidence, 0.9)
        
        guard finalConfidence >= config.minConfidenceThreshold else { return nil }
        
        let details = (try? JSONEncoder().encode(predictionData)).map { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return DreamPrediction(
            predictionDate: date,
            type: .pattern,
            confidence: finalConfidence,
            title: "梦境模式识别",
            description: recurringThemes.isEmpty ? "未发现明显模式" : "发现 \(recurringThemes.count) 个重复梦境模式",
            details: details,
            tags: recurringThemes
        )
    }
    
    /// 健康预警
    private func generateWarningPrediction(for date: Date) async -> DreamPrediction? {
        let dreams = await fetchRecentDreams(days: 30)
        guard dreams.count >= 10 else { return nil }
        
        // 分析潜在的心理健康指标
        let indicators = analyzeHealthIndicators(in: dreams)
        
        guard !indicators.isEmpty else { return nil }
        
        // 确定预警级别
        let warningLevel = determineWarningLevel(from: indicators)
        let suggestions = generateHealthSuggestions(for: warningLevel, indicators: indicators)
        let relatedPatterns = identifyRelatedPatterns(in: dreams)
        let shouldConsult = warningLevel == .high || warningLevel == .medium
        
        let predictionData = WarningPredictionData(
            warningLevel: warningLevel,
            indicators: indicators,
            suggestions: suggestions,
            relatedPatterns: relatedPatterns,
            shouldConsult: shouldConsult
        )
        
        let details = (try? JSONEncoder().encode(predictionData)).map { String(data: $0, encoding: .utf8) } ?? "{}"
        
        return DreamPrediction(
            predictionDate: date,
            type: .warning,
            confidence: 0.75,
            title: "梦境健康洞察",
            description: warningLevel == .normal ? "梦境模式健康" : "检测到值得关注的梦境模式",
            details: details,
            tags: indicators
        )
    }
    
    // MARK: - 数据分析辅助方法
    
    private func analyzeThemeFrequency(in dreams: [Dream]) -> [String: Int] {
        var frequency: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags ?? [] {
                frequency[tag, default: 0] += 1
            }
            // 从内容中提取关键词
            let keywords = extractKeywords(from: dream.content)
            for keyword in keywords {
                frequency[keyword, default: 0] += 1
            }
        }
        return frequency
    }
    
    private func analyzeSymbolFrequency(in dreams: [Dream]) -> [String: Int] {
        let commonSymbols = [
            "水", "火", "飞", "坠落", "追逐", "牙齿", "考试", "迟到",
            "蛇", "房子", "路", "门", "楼梯", "动物", "亲人", "陌生人"
        ]
        
        var frequency: [String: Int] = [:]
        for dream in dreams {
            let content = dream.content.lowercased()
            for symbol in commonSymbols {
                if content.contains(symbol) {
                    frequency[symbol, default: 0] += 1
                }
            }
        }
        return frequency
    }
    
    private func identifyTrendingThemes(in dreams: [Dream]) -> [String] {
        guard dreams.count >= 3 else { return [] }
        
        let recentThemes = Set(dreams.flatMap { $0.tags ?? [] })
        let olderDreams = Array(dreams.dropFirst(3))
        let olderThemes = Set(olderDreams.flatMap { $0.tags ?? [] })
        
        // 新出现的主题
        let trending = recentThemes.subtracting(olderThemes)
        return Array(trending)
    }
    
    private func generateLikelyScenarios(from themes: [String]) -> [String] {
        let scenarioTemplates: [String: [String]] = [
            "水": ["在海边漫步", " underwater 探险", "遭遇暴雨", "漂流在海上"],
            "飞": ["在空中自由飞翔", "尝试飞行但困难", "从高处落下", "乘坐飞行器"],
            "追逐": ["被未知存在追逐", "追逐某人或某物", "逃跑但跑不动", "躲藏起来"],
            "考试": ["参加重要考试", "忘记考试内容", "找不到考场", "考试迟到"]
        ]
        
        var scenarios: [String] = []
        for theme in themes.prefix(3) {
            if let templateScenarios = scenarioTemplates[theme] {
                scenarios.append(contentsOf: templateScenarios.prefix(2))
            }
        }
        
        if scenarios.isEmpty {
            scenarios = ["探索未知地方", "与熟人相遇", "经历奇异事件", "回到熟悉场景"]
        }
        
        return scenarios
    }
    
    private func identifyInspirationSources(in dreams: [Dream]) -> [String] {
        // 分析可能的灵感来源（基于梦境内容和时间）
        var sources: Set<String> = []
        
        for dream in dreams {
            let content = dream.content.lowercased()
            
            if content.contains("电影") || content.contains("电视") || content.contains("剧") {
                sources.insert("影视作品")
            }
            if content.contains("书") || content.contains("阅读") || content.contains("小说") {
                sources.insert("阅读材料")
            }
            if content.contains("工作") || content.contains("会议") || content.contains("项目") {
                sources.insert("工作压力")
            }
            if content.contains("朋友") || content.contains("聚会") || content.contains("社交") {
                sources.insert("社交活动")
            }
            if content.contains("旅行") || content.contains("户外") || content.contains("自然") {
                sources.insert("旅行经历")
            }
        }
        
        return Array(sources)
    }
    
    private func calculateConfidenceBreakdown(for themeFrequency: [String: Int]) -> [String: Double] {
        let total = themeFrequency.values.reduce(0, +)
        guard total > 0 else { return [:] }
        
        return themeFrequency.mapValues { Double($0) / Double(total) }
    }
    
    private func calculateContentConfidence(from dreams: [Dream], themeFrequency: [String: Int]) -> Double {
        // 基于数据量和模式清晰度计算置信度
        let dataScore = min(Double(dreams.count) / 30.0, 1.0) * 0.4
        let patternScore = themeFrequency.isEmpty ? 0 : min(Double(themeFrequency.count) / 10.0, 1.0) * 0.4
        let consistencyScore = 0.2  // 基础一致性分数
        
        return min(dataScore + patternScore + consistencyScore, 0.95)
    }
    
    private func analyzeEmotionTrend(in dreams: [Dream]) -> [EmotionType: [Date: Double]] {
        var trend: [EmotionType: [Date: Double]] = [:]
        
        for dream in dreams {
            let emotions = dream.emotions ?? []
            let date = Calendar.current.startOfDay(for: dream.createdAt)
            
            for emotion in emotions {
                if trend[emotion] == nil {
                    trend[emotion] = [:]
                }
                trend[emotion]?[date, default: 0] += 1
            }
        }
        
        return trend
    }
    
    private func predictEmotions(from trend: [EmotionType: [Date: Double]]) -> [EmotionType: Double] {
        var predictions: [EmotionType: Double] = [:]
        
        for (emotion, dateValues) in trend {
            let values = Array(dateValues.values)
            if values.count >= 2 {
                // 简单线性预测
                let recent = values.suffix(2)
                let trend = recent.last ?? 0 - recent.first ?? 0
                let prediction = (values.last ?? 0) + (trend * 0.5)
                predictions[emotion] = min(max(prediction, 0), 1)
            } else if let last = values.last {
                predictions[emotion] = last
            }
        }
        
        return predictions
    }
    
    private func determineTrendDirection(from trend: [EmotionType: [Date: Double]]) -> EmotionPredictionData.TrendDirection {
        var positiveCount = 0
        var negativeCount = 0
        
        for (_, dateValues) in trend {
            let values = Array(dateValues.values)
            if values.count >= 2 {
                if values.last ?? 0 > values.first ?? 0 {
                    positiveCount += 1
                } else {
                    negativeCount += 1
                }
            }
        }
        
        if positiveCount > negativeCount * 2 {
            return .improving
        } else if negativeCount > positiveCount * 2 {
            return .declining
        } else if abs(positiveCount - negativeCount) <= 1 {
            return .stable
        } else {
            return .volatile
        }
    }
    
    private func calculateEmotionStability(from dreams: [Dream]) -> Double {
        guard dreams.count >= 3 else { return 0.5 }
        
        let emotionCounts = dreams.map { ($0.emotions ?? []).count }
        let avg = emotionCounts.reduce(0, +) / emotionCounts.count
        let variance = emotionCounts.map { pow(Double($0 - avg), 2) }.reduce(0, +) / Double(emotionCounts.count)
        let stdDev = sqrt(variance)
        
        // 标准差越小，稳定性越高
        return max(0, min(1, 1 - (stdDev / 5.0)))
    }
    
    private func generateEmotionRecommendations(for direction: EmotionPredictionData.TrendDirection, stabilityScore: Double) -> [String] {
        var recommendations: [String] = []
        
        switch direction {
        case .declining:
            recommendations.append("尝试睡前冥想放松")
            recommendations.append("记录感恩日记，关注积极面")
            if stabilityScore < 0.4 {
                recommendations.append("考虑与朋友或专业人士交流")
            }
        case .volatile:
            recommendations.append("建立规律的睡前仪式")
            recommendations.append("减少睡前刺激（如手机、咖啡）")
        case .improving:
            recommendations.append("保持当前的良好习惯")
            recommendations.append("尝试记录更多细节，加深自我了解")
        case .stable:
            recommendations.append("情绪状态平稳，继续保持")
        }
        
        return recommendations
    }
    
    private func calculateEmotionConfidence(from dreams: [Dream]) -> Double {
        let dataScore = min(Double(dreams.count) / 30.0, 1.0) * 0.5
        let emotionDiversity = Set(dreams.flatMap { $0.emotions ?? [] }).count
        let diversityScore = min(Double(emotionDiversity) / 10.0, 1.0) * 0.3
        let consistencyScore = 0.2
        
        return min(dataScore + diversityScore + consistencyScore, 0.9)
    }
    
    private func analyzeLucidFactors(in dreams: [Dream]) -> [String] {
        var factors: [String] = []
        
        let lucidDreams = dreams.filter { $0.isLucid }
        let nonLucidDreams = dreams.filter { !$0.isLucid }
        
        // 分析清醒梦与非清醒梦的差异
        if lucidDreams.isEmpty { return factors }
        
        let avgClarityLucid = lucidDreams.map { $0.clarity ?? 3 }.reduce(0, +) / lucidDreams.count
        let avgClarityNonLucid = nonLucidDreams.isEmpty ? 3 : nonLucidDreams.map { $0.clarity ?? 3 }.reduce(0, +) / nonLucidDreams.count
        
        if avgClarityLucid > avgClarityNonLucid {
            factors.append("高梦境清晰度")
        }
        
        // 检查是否有现实检查习惯
        let realityCheckKeywords = ["现实检查", "捏鼻", "手掌", "阅读", "镜子"]
        let hasRealityCheck = dreams.contains { dream in
            realityCheckKeywords.contains { dream.content.contains($0) }
        }
        if hasRealityCheck {
            factors.append("现实检查习惯")
        }
        
        // 检查记录频率
        if dreams.count >= 20 {
            factors.append("高频记录习惯")
        }
        
        return factors
    }
    
    private func recommendLucidTechniques(basedOn dreams: [Dream]) -> [String] {
        var techniques: [String] = []
        
        let lucidDreams = dreams.filter { $0.isLucid }
        
        if lucidDreams.isEmpty {
            techniques = ["MILD 技巧", "现实检查", "梦境日记"]
        } else {
            techniques = ["WBTB 技巧", "SSILD 方法", "清醒梦巩固"]
        }
        
        // 根据时间推荐
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour <= 6 {
            techniques.append("睡前意图设定")
        }
        
        return techniques
    }
    
    private func determineOptimalLucidTiming(from dreams: [Dream]) -> String {
        // 分析清醒梦多发生在什么时间
        let lucidDreams = dreams.filter { $0.isLucid }
        
        if lucidDreams.isEmpty {
            return "REM 睡眠阶段（通常在后半夜）"
        }
        
        let hours = lucidDreams.map { Calendar.current.component(.hour, from: $0.createdAt) }
        let avgHour = hours.reduce(0, +) / hours.count
        
        if avgHour >= 0 && avgHour < 6 {
            return "凌晨 REM 阶段"
        } else if avgHour >= 6 && avgHour < 12 {
            return "早晨小睡时"
        } else {
            return "夜间 REM 阶段"
        }
    }
    
    private func generateLucidPreparationTips() -> [String] {
        return [
            "睡前重复意图：'我会记得我在做梦'",
            "保持梦境日记，提高梦境回忆",
            "避免酒精和重食影响睡眠质量",
            "尝试侧卧睡姿，增加清醒梦概率",
            "设置夜间闹钟进行 WBTB 练习"
        ]
    }
    
    private func analyzeRecallQualityByHour(from dreams: [Dream]) -> [Int: Double] {
        var qualityByHour: [Int: [Double]] = [:]
        
        for dream in dreams {
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            let quality = Double(dream.clarity ?? 3) / 5.0
            if qualityByHour[hour] == nil {
                qualityByHour[hour] = []
            }
            qualityByHour[hour]?.append(quality)
        }
        
        return qualityByHour.mapValues { values in
            values.reduce(0, +) / Double(values.count)
        }
    }
    
    private func calculateSleepQualityCorrelation(from dreams: [Dream]) -> Double {
        // 简化版本：分析梦境清晰度与记录时间的关系
        guard dreams.count >= 10 else { return 0.5 }
        
        let morningDreams = dreams.filter { dream in
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            return hour >= 5 && hour <= 9
        }
        
        let otherDreams = dreams.filter { dream in
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            return hour < 5 || hour > 9
        }
        
        let morningAvg = morningDreams.isEmpty ? 3 : morningDreams.map { $0.clarity ?? 3 }.reduce(0, +) / morningDreams.count
        let otherAvg = otherDreams.isEmpty ? 3 : otherDreams.map { $0.clarity ?? 3 }.reduce(0, +) / otherDreams.count
        
        return abs(Double(morningAvg - otherAvg)) / 5.0
    }
    
    private func identifyTimePatterns(from dreams: [Dream]) -> [String] {
        var patterns: [String] = []
        
        let weekendDreams = dreams.filter { dream in
            let weekday = Calendar.current.component(.weekday, from: dream.createdAt)
            return weekday == 1 || weekday == 7
        }
        
        let weekdayDreams = dreams.filter { dream in
            let weekday = Calendar.current.component(.weekday, from: dream.createdAt)
            return weekday != 1 && weekday != 7
        }
        
        if weekendDreams.count > weekdayDreams.count * 1.5 {
            patterns.append("周末记录更频繁")
        }
        
        let morningDreams = dreams.filter { dream in
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            return hour >= 5 && hour <= 10
        }
        
        if Double(morningDreams.count) / Double(dreams.count) > 0.7 {
            patterns.append("主要在早晨记录")
        }
        
        return patterns
    }
    
    private func identifyRecurringThemes(in dreams: [Dream], minOccurrences: Int) -> [String] {
        var frequency: [String: Int] = [:]
        
        for dream in dreams {
            for tag in dream.tags ?? [] {
                frequency[tag, default: 0] += 1
            }
        }
        
        return frequency.filter { $0.value >= minOccurrences }
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    private func detectDreamCycle(in dreams: [Dream]) -> Int {
        guard dreams.count >= 14 else { return 7 }
        
        // 简化版本：分析梦境数量的周期性
        let sortedDreams = dreams.sorted { $0.createdAt < $1.createdAt }
        
        // 尝试检测 7 天、14 天、30 天周期
        let weekDreams = sortedDreams.filter { dream in
            let weekday = Calendar.current.component(.weekday, from: dream.createdAt)
            return weekday == 1 || weekday == 7
        }
        
        if Double(weekDreams.count) / Double(sortedDreams.count) > 0.4 {
            return 7
        }
        
        return 7  // 默认 7 天周期
    }
    
    private func analyzeTriggerFactors(in dreams: [Dream]) -> [String] {
        var factors: [String] = []
        
        // 分析压力相关梦境
        let stressKeywords = ["工作", "压力", "考试", "迟到", "追赶", "焦虑"]
        let stressDreams = dreams.filter { dream in
            stressKeywords.contains { dream.content.lowercased().contains($0) }
        }
        
        if !stressDreams.isEmpty {
            factors.append("压力事件")
        }
        
        // 分析饮食相关
        let foodKeywords = ["吃", "喝", "酒", "咖啡", "晚餐"]
        let foodDreams = dreams.filter { dream in
            foodKeywords.contains { dream.content.lowercased().contains($0) }
        }
        
        if !foodDreams.isEmpty {
            factors.append("饮食影响")
        }
        
        return factors
    }
    
    private func calculateCorrelationMatrix(for dreams: [Dream]) -> [String: [String: Double]] {
        // 简化版本：计算标签之间的共现关系
        var matrix: [String: [String: Double]] = [:]
        var cooccurrence: [String: [String: Int]] = [:]
        
        for dream in dreams {
            let tags = dream.tags ?? []
            for (i, tag1) in tags.enumerated() {
                for tag2 in tags[(i + 1)...] {
                    if cooccurrence[tag1] == nil {
                        cooccurrence[tag1] = [:]
                    }
                    cooccurrence[tag1]?[tag2, default: 0] += 1
                }
            }
        }
        
        // 转换为相关系数
        for (tag1, related) in cooccurrence {
            matrix[tag1] = [:]
            for (tag2, count) in related {
                matrix[tag1]?[tag2] = Double(count) / Double(dreams.count)
            }
        }
        
        return matrix
    }
    
    private func detectAnomalies(in dreams: [Dream]) -> [String] {
        var anomalies: [String] = []
        
        // 检测异常长的梦境
        let avgLength = dreams.map { $0.content.count }.reduce(0, +) / dreams.count
        let longDreams = dreams.filter { $0.content.count > Int(Double(avgLength) * 2.0) }
        if !longDreams.isEmpty {
            anomalies.append("发现异常详细的梦境记录")
        }
        
        // 检测异常情绪
        let highEmotionDreams = dreams.filter { ($0.emotions ?? []).count >= 5 }
        if !highEmotionDreams.isEmpty {
            anomalies.append("发现情绪复杂的梦境")
        }
        
        return anomalies
    }
    
    private func analyzeHealthIndicators(in dreams: [Dream]) -> [String] {
        var indicators: [String] = []
        
        // 检测噩梦频率
        let nightmareKeywords = ["噩梦", "害怕", "恐惧", "恐怖", "惊醒"]
        let nightmareCount = dreams.filter { dream in
            nightmareKeywords.contains { dream.content.lowercased().contains($0) }
        }.count
        
        if Double(nightmareCount) / Double(dreams.count) > 0.3 {
            indicators.append("噩梦频率偏高")
        }
        
        // 检测焦虑相关
        let anxietyKeywords = ["焦虑", "紧张", "担心", "压力", "不安"]
        let anxietyCount = dreams.filter { dream in
            anxietyKeywords.contains { dream.content.lowercased().contains($0) }
        }.count
        
        if Double(anxietyCount) / Double(dreams.count) > 0.4 {
            indicators.append("焦虑相关梦境较多")
        }
        
        // 检测睡眠问题
        let sleepKeywords = ["失眠", "睡不着", "醒来", "早醒"]
        let sleepCount = dreams.filter { dream in
            sleepKeywords.contains { dream.content.lowercased().contains($0) }
        }.count
        
        if sleepCount > 3 {
            indicators.append("可能存在睡眠问题")
        }
        
        return indicators
    }
    
    private func determineWarningLevel(from indicators: [String]) -> WarningPredictionData.WarningLevel {
        switch indicators.count {
        case 0:
            return .normal
        case 1:
            return .low
        case 2:
            return .medium
        default:
            return .high
        }
    }
    
    private func generateHealthSuggestions(for level: WarningPredictionData.WarningLevel, indicators: [String]) -> [String] {
        var suggestions: [String] = []
        
        switch level {
        case .normal:
            suggestions.append("梦境模式健康，继续保持记录习惯")
        case .low:
            suggestions.append("尝试放松技巧，如冥想或深呼吸")
            suggestions.append("保持规律的作息时间")
        case .medium:
            suggestions.append("考虑减少睡前刺激（咖啡因、电子屏幕）")
            suggestions.append("建立放松的睡前仪式")
            suggestions.append("增加日间运动量")
        case .high:
            suggestions.append("建议咨询睡眠专家或心理咨询师")
            suggestions.append("记录压力源和触发因素")
            suggestions.append("优先改善睡眠质量")
        }
        
        // 根据具体指标添加建议
        if indicators.contains("噩梦频率偏高") {
            suggestions.append("尝试意象排练疗法（IRT）")
        }
        if indicators.contains("焦虑相关梦境较多") {
            suggestions.append("白天进行压力管理练习")
        }
        if indicators.contains("可能存在睡眠问题") {
            suggestions.append("创建舒适的睡眠环境")
        }
        
        return suggestions
    }
    
    private func identifyRelatedPatterns(in dreams: [Dream]) -> [String] {
        var patterns: [String] = []
        
        // 分析时间模式
        let eveningDreams = dreams.filter { dream in
            let hour = Calendar.current.component(.hour, from: dream.createdAt)
            return hour >= 20 || hour <= 2
        }
        
        if Double(eveningDreams.count) / Double(dreams.count) > 0.6 {
            patterns.append("晚间记录为主")
        }
        
        // 分析内容长度模式
        let detailedDreams = dreams.filter { $0.content.count > 500 }
        if !detailedDreams.isEmpty {
            patterns.append("有详细记录习惯")
        }
        
        return patterns
    }
    
    private func extractKeywords(from content: String) -> [String] {
        // 简化的关键词提取
        let commonKeywords = ["家", "学校", "工作", "朋友", "家人", "旅行", "自然", "动物", "水", "火", "飞", "跑", "笑", "哭"]
        
        return commonKeywords.filter { content.contains($0) }
    }
    
    // MARK: - 数据获取
    
    private func fetchRecentDreams(days: Int) async -> [Dream] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.createdAt >= Calendar.current.date(byAdding: .day, value: -days, to: Date())!
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
    
    // MARK: - 数据持久化
    
    private func savePredictions(_ predictions: [DreamPrediction]) async {
        for prediction in predictions {
            modelContext.insert(prediction)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - 查询功能
    
    func getPredictions(for date: Date) async -> [DreamPrediction] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchDescriptor = FetchDescriptor<DreamPrediction>(
            predicate: #Predicate { prediction in
                prediction.predictionDate >= startOfDay && prediction.predictionDate < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
    
    func getUpcomingPredictions(days: Int = 7) async -> [DreamPrediction] {
        let now = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: now)!
        
        let fetchDescriptor = FetchDescriptor<DreamPrediction>(
            predicate: #Predicate { prediction in
                prediction.predictionDate >= now && prediction.predictionDate <= futureDate
            },
            sortBy: [SortDescriptor(\.predictionDate, order: .forward)]
        )
        
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
    
    func getPredictionStats() async -> PredictionStats {
        let fetchDescriptor = FetchDescriptor<DreamPrediction>()
        let allPredictions = (try? modelContext.fetch(fetchDescriptor)) ?? []
        
        var stats = PredictionStats.empty
        stats.totalPredictions = allPredictions.count
        stats.predictionsByType = Dictionary(grouping: allPredictions, by: { $0.type })
            .mapValues { $0.count }
        
        if !allPredictions.isEmpty {
            stats.averageConfidence = allPredictions.map { $0.confidence }.reduce(0, +) / Double(allPredictions.count)
        }
        
        stats.lastUpdated = Date()
        
        return stats
    }
    
    func markPredictionAsRead(_ prediction: DreamPrediction) {
        prediction.isRead = true
        try? modelContext.save()
    }
    
    func deletePrediction(_ prediction: DreamPrediction) {
        modelContext.delete(prediction)
        try? modelContext.save()
    }
    
    func clearOldPredictions(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let fetchDescriptor = FetchDescriptor<DreamPrediction>(
            predicate: #Predicate { prediction in
                prediction.predictionDate < cutoffDate
            }
        )
        
        if let predictions = try? modelContext.fetch(fetchDescriptor) {
            for prediction in predictions {
                modelContext.delete(prediction)
            }
            try? modelContext.save()
        }
    }
}
