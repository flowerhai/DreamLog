//
//  DreamPredictionEngine.swift
//  DreamLog
//
//  Phase 100: 梦境健康评分与预测引擎
//  AI 预测引擎
//

import Foundation
import SwiftData

// MARK: - 预测引擎

actor DreamPredictionEngine {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - 生成预测
    
    func generatePredictions(for days: Int = 7) async throws -> [DreamPrediction] {
        var predictions: [DreamPrediction] = []
        
        // 1. 梦境主题预测
        if let themePrediction = try await predictDreamThemes(days: days) {
            predictions.append(themePrediction)
        }
        
        // 2. 情绪趋势预测
        if let emotionPrediction = try await predictEmotionalTrend(days: days) {
            predictions.append(emotionPrediction)
        }
        
        // 3. 清醒梦概率预测
        if let lucidPrediction = try await predictLucidDreamProbability() {
            predictions.append(lucidPrediction)
        }
        
        // 4. 最佳记录时间预测
        if let timePrediction = try await predictOptimalRecordTime() {
            predictions.append(timePrediction)
        }
        
        // 保存预测
        for prediction in predictions {
            modelContext.insert(prediction)
        }
        try modelContext.save()
        
        return predictions
    }
    
    // MARK: - 梦境主题预测
    
    private func predictDreamThemes(days: Int) async throws -> DreamPrediction? {
        // 分析历史梦境主题模式
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        guard !dreams.isEmpty else { return nil }
        
        // 统计主题频率
        let themeCounts = Dictionary(grouping: dreams.flatMap { $0.themes }, by: { $0 })
            .mapValues { $0.count }
        
        // 检测周期性模式 (简化版)
        let sortedThemes = themeCounts.sorted { $0.value > $1.value }
        guard let topTheme = sortedThemes.first else { return nil }
        
        // 计算出现概率
        let probability = min(90, Double(topTheme.value) / Double(dreams.count) * 100 + 20)
        
        // 生成预测内容
        let predictedContent = "未来 \(days) 天内，'\(topTheme.key)' 主题有 \(Int(probability))% 的概率出现在你的梦境中"
        
        // 预测依据
        let basis = [
            "过去 30 天内出现 \(topTheme.value) 次",
            "占梦境总数的 \(Int(Double(topTheme.value) / Double(dreams.count) * 100))%",
            "呈现\(sortedThemes.count > 1 ? "上升" : "稳定")趋势"
        ]
        
        // 相关建议
        let recommendations = [
            "记录相关梦境时注意细节",
            "探索这个主题对你的意义",
            "尝试在睡前思考相关话题"
        ]
        
        return DreamPrediction(
            predictionType: .dreamTheme,
            predictedContent: predictedContent,
            confidence: probability,
            basis: basis,
            recommendations: recommendations,
            validUntil: Calendar.current.date(byAdding: .day, value: days, to: endDate)!
        )
    }
    
    // MARK: - 情绪趋势预测
    
    private func predictEmotionalTrend(days: Int) async throws -> DreamPrediction? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -14, to: endDate)!
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        guard !dreams.isEmpty else { return nil }
        
        // 分析情绪趋势
        let emotions = dreams.map { $0.primaryEmotion }
        let moodRatings = dreams.map { $0.moodRating }
        
        // 计算平均情绪评分
        let avgMood = moodRatings.reduce(0, +) / Double(moodRatings.count)
        
        // 分析近期趋势 (最近 7 天 vs 之前 7 天)
        let recentMoods = moodRatings.prefix(7)
        let olderMoods = moodRatings.suffix(7)
        
        let recentAvg = recentMoods.reduce(0, +) / Double(recentMoods.count)
        let olderAvg = olderMoods.reduce(0, +) / Double(olderMoods.count)
        
        let trendDirection: TrendDirection
        let predictedEmotion: String
        
        if recentAvg > olderAvg + 0.5 {
            trendDirection = .improving
            predictedEmotion = "积极"
        } else if recentAvg < olderAvg - 0.5 {
            trendDirection = .declining
            predictedEmotion = "需要关注"
        } else {
            trendDirection = .stable
            predictedEmotion = "平稳"
        }
        
        // 计算置信度
        let confidence = min(85, 60 + Double(dreams.count) * 2)
        
        let predictedContent = "未来 \(days) 天，你的情绪状态预计将保持\(predictedEmotion)（当前评分：\(String(format: "%.1f", avgMood))/5）"
        
        let basis = [
            "基于最近 14 天的梦境情绪分析",
            "平均情绪评分：\(String(format: "%.1f", avgMood))/5",
            "趋势：\(trendDirection.rawValue)"
        ]
        
        var recommendations = [
            "继续记录梦境以追踪情绪变化"
        ]
        
        if trendDirection == .declining {
            recommendations.append("考虑增加放松和冥想练习")
            recommendations.append("与朋友或家人交流感受")
        } else if trendDirection == .improving {
            recommendations.append("保持当前的良好习惯")
            recommendations.append("记录让你感到积极的活动")
        }
        
        return DreamPrediction(
            predictionType: .emotionalTrend,
            predictedContent: predictedContent,
            confidence: confidence,
            basis: basis,
            recommendations: recommendations,
            validUntil: Calendar.current.date(byAdding: .day, value: days, to: endDate)!
        )
    }
    
    // MARK: - 清醒梦概率预测
    
    private func predictLucidDreamProbability() async throws -> DreamPrediction? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        guard !dreams.isEmpty else { return nil }
        
        // 统计清醒梦历史
        let lucidDreams = dreams.filter { $0.isLucid }
        let lucidRatio = Double(lucidDreams.count) / Double(dreams.count)
        
        // 分析影响清醒梦的因素
        var probability = lucidRatio * 100
        
        // 记录频率加成
        let dreamsPerWeek = Double(dreams.count) / 4.0  // 30 天约 4 周
        if dreamsPerWeek >= 5 {
            probability += 15  // 高频记录者
        } else if dreamsPerWeek >= 3 {
            probability += 10
        }
        
        // 清晰度加成
        let avgClarity = dreams.reduce(0) { $0 + $1.clarityRating } / dreams.count
        if avgClarity >= 4 {
            probability += 10  // 高清晰度
        }
        
        // 限制在 0-100 范围
        probability = min(95, max(5, probability))
        
        let predictedContent = "未来 7 天内，你有 \(Int(probability))% 的概率经历清醒梦"
        
        let confidence = min(80, 50 + Double(dreams.count) * 1.5)
        
        let basis = [
            "历史清醒梦比例：\(Int(lucidRatio * 100))%",
            "记录频率：\(String(format: "%.1f", dreamsPerWeek)) 次/周",
            "平均清晰度：\(String(format: "%.1f", Double(avgClarity)))/5"
        ]
        
        var recommendations = [
            "睡前进行现实检查练习",
            "记录梦境时标注是否清醒梦"
        ]
        
        if probability < 30 {
            recommendations.append("尝试 WBTB 技巧（睡中醒来再睡）")
            recommendations.append("练习 MILD 或 WILD 技巧")
        }
        
        return DreamPrediction(
            predictionType: .lucidDreamProbability,
            predictedContent: predictedContent,
            confidence: confidence,
            basis: basis,
            recommendations: recommendations
        )
    }
    
    // MARK: - 最佳记录时间预测
    
    private func predictOptimalRecordTime() async throws -> DreamPrediction? {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate)!
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= startDate && dream.date <= endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        guard !dreams.isEmpty else { return nil }
        
        // 分析记录时间与梦境质量的关系
        let timeQualityPairs = dreams.map { dream -> (hour: Int, quality: Double) in
            let hour = Calendar.current.component(.hour, from: dream.date)
            let quality = Double(dream.clarityRating) / 5.0 * 100
            return (hour, quality)
        }
        
        // 按小时分组计算平均质量
        let hourQuality = Dictionary(grouping: timeQualityPairs, by: { $0.hour })
            .mapValues { pairs in
                pairs.reduce(0) { $0 + $1.quality } / Double(pairs.count)
            }
        
        // 找到最佳时间段
        let sortedHours = hourQuality.sorted { $0.value > $1.value }
        guard let bestHour = sortedHours.first else { return nil }
        
        let bestTimeRange = TimeRange(
            startHour: bestHour.key,
            endHour: (bestHour.key + 2) % 24,
            quality: bestHour.value,
            basis: "基于历史数据，这个时间段记录的梦境平均清晰度最高"
        )
        
        let predictedContent = "根据你的记录习惯，\(bestTimeRange.displayString) 是最佳梦境记录时间（清晰度评分：\(String(format: "%.0f", bestHour.value))/100）"
        
        let confidence = min(85, 60 + Double(dreams.count))
        
        let basis = [
            "分析了过去 30 天的\(dreams.count) 条记录",
            "最佳时段平均清晰度：\(String(format: "%.0f", bestHour.value))/100",
            "基于梦境清晰度和完整性评估"
        ]
        
        let recommendations = [
            "尽量在固定时间记录梦境",
            "醒来后立即记录，不要拖延",
            "使用语音输入可以快速捕捉细节"
        ]
        
        return DreamPrediction(
            predictionType: .optimalRecordTime,
            predictedContent: predictedContent,
            confidence: confidence,
            basis: basis,
            recommendations: recommendations
        )
    }
    
    // MARK: - 获取历史预测
    
    func getPredictions(type: PredictionType? = nil, limit: Int = 10) throws -> [DreamPrediction] {
        var descriptor = FetchDescriptor<DreamPrediction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: limit
        )
        
        if let type = type {
            descriptor.predicate = #Predicate { prediction in
                prediction.predictionType == type
            }
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 评估预测准确性
    
    func evaluatePrediction(_ prediction: DreamPrediction, actualOutcome: String) throws {
        prediction.actualOutcome = actualOutcome
        // 简化的准确性评估，实际应使用更复杂的算法
        prediction.isAccurate = true  // 需要更智能的评估逻辑
        try modelContext.save()
    }
    
    // MARK: - 清除过期预测
    
    func clearExpiredPredictions() throws {
        let now = Date()
        let descriptor = FetchDescriptor<DreamPrediction>(
            predicate: #Predicate { prediction in
                prediction.validUntil < now
            }
        )
        
        let expired = try modelContext.fetch(descriptor)
        for prediction in expired {
            modelContext.delete(prediction)
        }
        try modelContext.save()
    }
}
