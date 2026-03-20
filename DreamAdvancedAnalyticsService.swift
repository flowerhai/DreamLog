//
//  DreamAdvancedAnalyticsService.swift
//  DreamLog
//
//  Phase 74: 梦境数据分析增强 📊🔍
//  高级分析服务引擎
//
//  Created: 2026-03-20
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - 高级分析服务

/// 高级梦境分析服务
public actor DreamAdvancedAnalyticsService {
    /// 共享实例
    public static let shared = DreamAdvancedAnalyticsService()
    
    /// 分析配置
    private var configuration: AdvancedAnalyticsConfiguration
    
    /// 缓存的分析结果
    private var analysisCache: [String: Any]
    
    /// 缓存过期时间（秒）
    private let cacheExpiration: TimeInterval = 3600
    
    private init() {
        self.configuration = .default
        self.analysisCache = [:]
    }
    
    // MARK: - 公共方法
    
    /// 执行交叉分析
    public func performCrossAnalysis(
        dimension: CrossAnalysisDimension,
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        let cacheKey = "cross_\(dimension.rawValue)"
        
        // 检查缓存
        if let cached = getCachedResult(forKey: cacheKey) as? CrossAnalysisResult {
            return cached
        }
        
        let result: CrossAnalysisResult
        switch dimension {
        case .emotionSymbol:
            result = try await analyzeEmotionVsSymbols(in: context)
        case .emotionTime:
            result = try await analyzeEmotionVsTime(in: context)
        case .weatherContent:
            result = try await analyzeWeatherVsContent(in: context)
        case .sleepQualityClarity:
            result = try await analyzeSleepVsClarity(in: context)
        case .dayOfWeekEmotion:
            result = try await analyzeDayOfWeekVsEmotion(in: context)
        case .hourOfDayEmotion:
            result = try await analyzeHourOfDayVsEmotion(in: context)
        }
        
        // 缓存结果
        setCachedResult(result, forKey: cacheKey)
        
        return result
    }
    
    /// 生成时间序列预测
    public func generateTimeSeriesForecast(
        type: TimeSeriesForecast.ForecastType,
        days: Int = 7,
        in context: ModelContext
    ) async throws -> TimeSeriesForecast {
        let cacheKey = "forecast_\(type.rawValue)_\(days)"
        
        // 检查缓存
        if let cached = getCachedResult(forKey: cacheKey) as? TimeSeriesForecast {
            return cached
        }
        
        // 获取历史数据
        let historicalData = try await fetchHistoricalData(for: type, in: context)
        
        guard !historicalData.isEmpty else {
            throw AnalyticsError.insufficientData
        }
        
        // 生成预测
        let forecast = try await calculateForecast(
            historicalData: historicalData,
            type: type,
            days: days
        )
        
        // 缓存结果
        setCachedResult(forecast, forKey: cacheKey)
        
        return forecast
    }
    
    /// 执行异常检测
    public func detectAnomalies(
        in context: ModelContext,
        threshold: Double? = nil
    ) async throws -> [AnomalyDetectionResult] {
        let effectiveThreshold = threshold ?? configuration.anomalyThreshold
        
        // 获取所有梦境
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        var anomalies: [AnomalyDetectionResult] = []
        
        for dream in dreams {
            let dreamAnomalies = await detectDreamAnomalies(
                dream: dream,
                in: context,
                threshold: effectiveThreshold
            )
            anomalies.append(contentsOf: dreamAnomalies)
        }
        
        // 按异常分数排序
        anomalies.sort { $0.anomalyScore > $1.anomalyScore }
        
        return anomalies
    }
    
    /// 执行聚类分析
    public func performClustering(
        algorithm: ClusteringResult.ClusteringAlgorithm = .kmeans,
        clusterCount: Int? = nil,
        in context: ModelContext
    ) async throws -> ClusteringResult {
        let k = clusterCount ?? configuration.clusterCount
        
        // 获取所有梦境
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        guard dreams.count >= k else {
            throw AnalyticsError.insufficientData
        }
        
        // 执行聚类
        let clusters: [ClusteringResult.DreamCluster]
        switch algorithm {
        case .kmeans:
            clusters = try await performKMeansClustering(dreams: dreams, k: k, in: context)
        case .hierarchical:
            clusters = try await performHierarchicalClustering(dreams: dreams, k: k, in: context)
        case .dbscan:
            clusters = try await performDBSCANClustering(dreams: dreams, in: context)
        }
        
        // 计算聚类质量
        let qualityScore = calculateClusteringQuality(clusters: clusters, dreams: dreams)
        
        return ClusteringResult(
            algorithm: algorithm,
            clusterCount: clusters.count,
            clusters: clusters,
            qualityScore: qualityScore,
            analyzedAt: Date()
        )
    }
    
    /// 获取综合分析概览
    public func getAnalyticsOverview(
        in context: ModelContext
    ) async throws -> AnalyticsOverview {
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        guard !dreams.isEmpty else {
            throw AnalyticsError.insufficientData
        }
        
        // 计算基础统计
        let totalDreams = dreams.count
        let averageClarity = dreams.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(totalDreams)
        let lucidCount = dreams.filter { $0.isLucid }.count
        
        // 情绪分布
        let emotionCounts: [String: Int] = Dictionary(grouping: dreams) { dream in
            dream.emotion?.rawValue ?? "neutral"
        }.mapValues { $0.count }
        
        let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key ?? "neutral"
        
        // 趋势分析
        let sortedDreams = dreams.sorted { $0.date < $1.date }
        let recentTrend = calculateRecentTrend(dreams: sortedDreams)
        
        return AnalyticsOverview(
            totalDreams: totalDreams,
            averageClarity: averageClarity,
            lucidDreamCount: lucidCount,
            dominantEmotion: dominantEmotion,
            recentTrend: recentTrend,
            lastUpdated: Date()
        )
    }
    
    // MARK: - 交叉分析实现
    
    /// 分析情绪 vs 符号
    private func analyzeEmotionVsSymbols(
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        // 收集所有情绪和符号
        let emotions = Set(dreams.compactMap { $0.emotion?.rawValue }).sorted()
        let allSymbols = dreams.flatMap { $0.symbols ?? [] }
        let topSymbols = Set(allSymbols.sorted().prefix(15))
        
        // 构建关联矩阵
        var matrix: [[Double]] = Array(repeating: Array(repeating: 0, count: topSymbols.count), count: emotions.count)
        var counts: [[Int]] = Array(repeating: Array(repeating: 0, count: topSymbols.count), count: emotions.count)
        
        for dream in dreams {
            guard let emotion = dream.emotion?.rawValue,
                  let emotionIndex = emotions.firstIndex(of: emotion),
                  let dreamSymbols = dream.symbols else { continue }
            
            for symbol in dreamSymbols {
                if let symbolIndex = topSymbols.sorted().firstIndex(of: symbol) {
                    counts[emotionIndex][symbolIndex] += 1
                }
            }
        }
        
        // 归一化矩阵
        let maxCount = counts.flatMap { $0 }.max() ?? 1
        for i in 0..<emotions.count {
            for j in 0..<topSymbols.count {
                matrix[i][j] = Double(counts[i][j]) / Double(maxCount)
            }
        }
        
        // 找出显著关联
        var significantCorrelations: [CrossAnalysisResult.SignificantCorrelation] = []
        for i in 0..<emotions.count {
            for j in 0..<topSymbols.count {
                if matrix[i][j] >= 0.7 {
                    significantCorrelations.append(.init(
                        rowLabel: emotions[i],
                        columnLabel: topSymbols.sorted()[j],
                        strength: matrix[i][j],
                        count: counts[i][j]
                    ))
                }
            }
        }
        
        return CrossAnalysisResult(
            dimension: .emotionSymbol,
            totalDataPoints: dreams.count,
            correlationMatrix: matrix,
            rowLabels: emotions,
            columnLabels: Array(topSymbols).sorted(),
            significantCorrelations: significantCorrelations,
            analyzedAt: Date()
        )
    }
    
    /// 分析情绪 vs 时间
    private func analyzeEmotionVsTime(
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        let emotions = Set(dreams.compactMap { $0.emotion?.rawValue }).sorted()
        let hours = Array(0..<24).map { String(format: "%02d:00", $0) }
        
        var matrix: [[Double]] = Array(repeating: Array(repeating: 0, count: 24), count: emotions.count)
        var counts: [[Int]] = Array(repeating: Array(repeating: 0, count: 24), count: emotions.count)
        var totals: [Int] = Array(repeating: 0, count: 24)
        
        for dream in dreams {
            guard let emotion = dream.emotion?.rawValue,
                  let emotionIndex = emotions.firstIndex(of: emotion) else { continue }
            
            let hour = Calendar.current.component(.hour, from: dream.date)
            counts[emotionIndex][hour] += 1
            totals[hour] += 1
        }
        
        // 计算比例
        for i in 0..<emotions.count {
            for j in 0..<24 {
                matrix[i][j] = totals[j] > 0 ? Double(counts[i][j]) / Double(totals[j]) : 0
            }
        }
        
        // 显著关联
        var significantCorrelations: [CrossAnalysisResult.SignificantCorrelation] = []
        for i in 0..<emotions.count {
            for j in 0..<24 {
                if matrix[i][j] >= 0.7 {
                    significantCorrelations.append(.init(
                        rowLabel: emotions[i],
                        columnLabel: hours[j],
                        strength: matrix[i][j],
                        count: counts[i][j]
                    ))
                }
            }
        }
        
        return CrossAnalysisResult(
            dimension: .hourOfDayEmotion,
            totalDataPoints: dreams.count,
            correlationMatrix: matrix,
            rowLabels: emotions,
            columnLabels: hours,
            significantCorrelations: significantCorrelations,
            analyzedAt: Date()
        )
    }
    
    /// 分析天气 vs 内容
    private func analyzeWeatherVsContent(
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        // 简化实现 - 实际应根据天气数据扩展
        return try await analyzeEmotionVsSymbols(in: context)
    }
    
    /// 分析睡眠 vs 清晰度
    private func analyzeSleepVsClarity(
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        // 睡眠质量分组
        let sleepQualityLevels = ["差", "一般", "好", "很好"]
        let clarityLevels = ["模糊", "一般", "清晰", "非常清晰"]
        
        var matrix: [[Double]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        var counts: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        
        for dream in dreams {
            let sleepQuality = dream.sleepQuality ?? 0.5
            let clarity = dream.clarity ?? 0.5
            
            let sleepIndex = min(Int(sleepQuality * 4), 3)
            let clarityIndex = min(Int(clarity * 4), 3)
            
            counts[sleepIndex][clarityIndex] += 1
        }
        
        // 归一化
        let maxCount = counts.flatMap { $0 }.max() ?? 1
        for i in 0..<4 {
            for j in 0..<4 {
                matrix[i][j] = Double(counts[i][j]) / Double(maxCount)
            }
        }
        
        return CrossAnalysisResult(
            dimension: .sleepQualityClarity,
            totalDataPoints: dreams.count,
            correlationMatrix: matrix,
            rowLabels: sleepQualityLevels,
            columnLabels: clarityLevels,
            significantCorrelations: [],
            analyzedAt: Date()
        )
    }
    
    /// 分析星期 vs 情绪
    private func analyzeDayOfWeekVsEmotion(
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        let descriptor = FetchDescriptor<DreamEntry>()
        let dreams = try context.fetch(descriptor)
        
        let emotions = Set(dreams.compactMap { $0.emotion?.rawValue }).sorted()
        let daysOfWeek = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        
        var matrix: [[Double]] = Array(repeating: Array(repeating: 0, count: 7), count: emotions.count)
        var counts: [[Int]] = Array(repeating: Array(repeating: 0, count: 7), count: emotions.count)
        var totals: [Int] = Array(repeating: 0, count: 7)
        
        for dream in dreams {
            guard let emotion = dream.emotion?.rawValue,
                  let emotionIndex = emotions.firstIndex(of: emotion) else { continue }
            
            let dayOfWeek = Calendar.current.component(.weekday, from: dream.date) - 1
            counts[emotionIndex][dayOfWeek] += 1
            totals[dayOfWeek] += 1
        }
        
        // 计算比例
        for i in 0..<emotions.count {
            for j in 0..<7 {
                matrix[i][j] = totals[j] > 0 ? Double(counts[i][j]) / Double(totals[j]) : 0
            }
        }
        
        return CrossAnalysisResult(
            dimension: .dayOfWeekEmotion,
            totalDataPoints: dreams.count,
            correlationMatrix: matrix,
            rowLabels: emotions,
            columnLabels: daysOfWeek,
            significantCorrelations: [],
            analyzedAt: Date()
        )
    }
    
    /// 分析时段 vs 情绪
    private func analyzeHourOfDayVsEmotion(
        in context: ModelContext
    ) async throws -> CrossAnalysisResult {
        // 复用情绪 vs 时间分析
        return try await analyzeEmotionVsTime(in: context)
    }
    
    // MARK: - 时间序列预测实现
    
    /// 获取历史数据
    private func fetchHistoricalData(
        for type: TimeSeriesForecast.ForecastType,
        in context: ModelContext
    ) async throws -> [TimeSeriesDataPoint] {
        let descriptor = FetchDescriptor<DreamEntry>(
            sortBy: [SortDescriptor(\.date)]
        )
        let dreams = try context.fetch(descriptor)
        
        switch type {
        case .dreamFrequency:
            return try await aggregateDreamFrequency(dreams: dreams)
        case .emotionTrend:
            return try await aggregateEmotionTrend(dreams: dreams)
        case .lucidProbability:
            return try await aggregateLucidProbability(dreams: dreams)
        case .symbolOccurrence:
            return try await aggregateSymbolOccurrence(dreams: dreams)
        case .sleepQuality:
            return try await aggregateSleepQuality(dreams: dreams)
        }
    }
    
    /// 聚合梦境频率
    private func aggregateDreamFrequency(
        dreams: [DreamEntry]
    ) async throws -> [TimeSeriesDataPoint] {
        let calendar = Calendar.current
        var dailyCounts: [Date: Int] = [:]
        
        for dream in dreams {
            let day = calendar.startOfDay(for: dream.date)
            dailyCounts[day, default: 0] += 1
        }
        
        return dailyCounts.map { date, count in
            TimeSeriesDataPoint(timestamp: date, value: Double(count), label: nil)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// 聚合情绪趋势
    private func aggregateEmotionTrend(
        dreams: [DreamEntry]
    ) async throws -> [TimeSeriesDataPoint] {
        let calendar = Calendar.current
        var dailyEmotions: [Date: [Double]] = [:]
        
        for dream in dreams {
            let day = calendar.startOfDay(for: dream.date)
            let emotionValue = dream.emotion?.emotionScore ?? 0.5
            dailyEmotions[day, default: []].append(emotionValue)
        }
        
        return dailyEmotions.map { date, emotions in
            let avg = emotions.reduce(0, +) / Double(emotions.count)
            return TimeSeriesDataPoint(timestamp: date, value: avg, label: nil)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// 聚合清醒梦概率
    private func aggregateLucidProbability(
        dreams: [DreamEntry]
    ) async throws -> [TimeSeriesDataPoint] {
        let calendar = Calendar.current
        var dailyLucid: [Date: (lucid: Int, total: Int)] = [:]
        
        for dream in dreams {
            let day = calendar.startOfDay(for: dream.date)
            let entry = dailyLucid[day] ?? (0, 0)
            dailyLucid[day] = (entry.lucid + (dream.isLucid ? 1 : 0), entry.total + 1)
        }
        
        return dailyLucid.map { date, data in
            let probability = Double(data.lucid) / Double(data.total)
            return TimeSeriesDataPoint(timestamp: date, value: probability, label: nil)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// 聚合符号出现
    private func aggregateSymbolOccurrence(
        dreams: [DreamEntry]
    ) async throws -> [TimeSeriesDataPoint] {
        // 简化实现 - 统计每日符号总数
        let calendar = Calendar.current
        var dailySymbols: [Date: Int] = [:]
        
        for dream in dreams {
            let day = calendar.startOfDay(for: dream.date)
            let symbolCount = dream.symbols?.count ?? 0
            dailySymbols[day, default: 0] += symbolCount
        }
        
        return dailySymbols.map { date, count in
            TimeSeriesDataPoint(timestamp: date, value: Double(count), label: nil)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// 聚合睡眠质量
    private func aggregateSleepQuality(
        dreams: [DreamEntry]
    ) async throws -> [TimeSeriesDataPoint] {
        let calendar = Calendar.current
        var dailyQuality: [Date: [Double]] = [:]
        
        for dream in dreams {
            let day = calendar.startOfDay(for: dream.date)
            let quality = dream.sleepQuality ?? 0.5
            dailyQuality[day, default: []].append(quality)
        }
        
        return dailyQuality.map { date, qualities in
            let avg = qualities.reduce(0, +) / Double(qualities.count)
            return TimeSeriesDataPoint(timestamp: date, value: avg, label: nil)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// 计算预测
    private func calculateForecast(
        historicalData: [TimeSeriesDataPoint],
        type: TimeSeriesForecast.ForecastType,
        days: Int
    ) async throws -> TimeSeriesForecast {
        guard historicalData.count >= 7 else {
            throw AnalyticsError.insufficientData
        }
        
        // 简单移动平均预测
        let windowSize = min(7, historicalData.count)
        let values = historicalData.map { $0.value }
        
        // 计算趋势
        let recentAvg = values.suffix(windowSize).reduce(0, +) / Double(windowSize)
        let olderAvg = values.prefix(windowSize).reduce(0, +) / Double(windowSize)
        let trend = recentAvg - olderAvg
        
        // 生成预测数据
        var forecastedData: [TimeSeriesDataPoint] = []
        var lowerBound: [Double] = []
        var upperBound: [Double] = []
        
        let lastDate = historicalData.last?.timestamp ?? Date()
        
        for i in 1...days {
            let forecastDate = Calendar.current.date(byAdding: .day, value: i, to: lastDate) ?? Date()
            let predictedValue = recentAvg + Double(i) * trend * 0.5
            
            // 置信区间（简化）
            let stdDev = calculateStandardDeviation(values)
            let margin = stdDev * Double(i) * 0.2
            
            forecastedData.append(TimeSeriesDataPoint(
                timestamp: forecastDate,
                value: predictedValue,
                label: nil
            ))
            lowerBound.append(max(0, predictedValue - margin))
            upperBound.append(predictedValue + margin)
        }
        
        // 确定趋势方向
        let trendDirection: TimeSeriesForecast.TrendDirection
        let trendStrength = abs(trend) / (recentAvg + 0.001)
        
        if trendStrength < 0.1 {
            trendDirection = .stable
        } else if trend > 0 {
            trendDirection = .increasing
        } else {
            trendDirection = .decreasing
        }
        
        return TimeSeriesForecast(
            forecastType: type,
            historicalData: historicalData,
            forecastedData: forecastedData,
            lowerBound: lowerBound,
            upperBound: upperBound,
            trendDirection: trendDirection,
            trendStrength: min(1.0, trendStrength),
            accuracy: nil,
            generatedAt: Date()
        )
    }
    
    /// 计算标准差
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
    
    // MARK: - 异常检测实现
    
    /// 检测梦境异常
    private func detectDreamAnomalies(
        dream: DreamEntry,
        in context: ModelContext,
        threshold: Double
    ) async -> [AnomalyDetectionResult] {
        var anomalies: [AnomalyDetectionResult] = []
        
        // 1. 情绪异常检测
        if let emotion = dream.emotion {
            let emotionScore = emotion.emotionScore
            if emotionScore < 0.1 || emotionScore > 0.9 {
                anomalies.append(.init(
                    dreamId: dream.id,
                    anomalyType: .emotionExtreme,
                    anomalyScore: max(emotionScore, 1 - emotionScore),
                    description: "此梦境的情绪强度异常（\(emotion.displayName)）",
                    metrics: ["emotionScore": emotionScore],
                    suggestedAction: "记录此梦境的详细背景，可能反映重要心理状态",
                    detectedAt: Date()
                ))
            }
        }
        
        // 2. 清晰度异常
        if let clarity = dream.clarity {
            if clarity < 0.1 || clarity > 0.95 {
                anomalies.append(.init(
                    dreamId: dream.id,
                    anomalyType: .clarityExtreme,
                    anomalyScore: clarity > 0.5 ? clarity : 1 - clarity,
                    description: "此梦境的清晰度异常（\(clarity * 100, specifier: "%.0f")%）",
                    metrics: ["clarity": clarity],
                    suggestedAction: clarity > 0.9 ? "尝试记录更多细节" : "考虑改善睡眠质量",
                    detectedAt: Date()
                ))
            }
        }
        
        // 3. 内容长度异常
        let contentLength = dream.content?.count ?? 0
        if contentLength > 5000 || (contentLength < 20 && contentLength > 0) {
            anomalies.append(.init(
                dreamId: dream.id,
                anomalyType: .contentLength,
                anomalyScore: contentLength > 5000 ? 0.8 : 0.7,
                description: contentLength > 5000 ? "此梦境记录异常详细" : "此梦境记录异常简短",
                metrics: ["contentLength": Double(contentLength)],
                suggestedAction: nil,
                detectedAt: Date()
            ))
        }
        
        return anomalies
    }
    
    // MARK: - 聚类分析实现
    
    /// K-Means 聚类
    private func performKMeansClustering(
        dreams: [DreamEntry],
        k: Int,
        in context: ModelContext
    ) async throws -> [ClusteringResult.DreamCluster] {
        // 简化实现 - 实际应使用完整的 K-Means 算法
        // 这里按情绪分组作为示例
        
        let dreamsByEmotion = Dictionary(grouping: dreams) { dream in
            dream.emotion?.rawValue ?? "neutral"
        }
        
        var clusters: [ClusteringResult.DreamCluster] = []
        let sortedEmotions = dreamsByEmotion.keys.sorted()
        
        for (index, emotion) in sortedEmotions.prefix(k).enumerated() {
            let emotionDreams = dreamsByEmotion[emotion] ?? []
            
            guard !emotionDreams.isEmpty else { continue }
            
            let centroid = calculateClusterCentroid(dreams: emotionDreams)
            let characteristics = generateClusterCharacteristics(dreams: emotionDreams)
            
            clusters.append(.init(
                id: UUID(),
                name: "情绪组 \(index + 1): \(emotion)",
                dreamIds: emotionDreams.map { $0.id },
                size: emotionDreams.count,
                centroid: centroid,
                characteristics: characteristics,
                dominantEmotion: DreamEmotion(rawValue: emotion),
                commonSymbols: extractCommonSymbols(dreams: emotionDreams),
                timeRange: nil
            ))
        }
        
        return clusters
    }
    
    /// 层次聚类（简化实现）
    private func performHierarchicalClustering(
        dreams: [DreamEntry],
        k: Int,
        in context: ModelContext
    ) async throws -> [ClusteringResult.DreamCluster] {
        // 简化实现 - 按时间分组
        let calendar = Calendar.current
        let dreamsByMonth = Dictionary(grouping: dreams) { dream in
            calendar.component(.month, from: dream.date)
        }
        
        return try await createClusters(from: dreamsByMonth, k: k)
    }
    
    /// DBSCAN 聚类（简化实现）
    private func performDBSCANClustering(
        dreams: [DreamEntry],
        in context: ModelContext
    ) async throws -> [ClusteringResult.DreamCluster] {
        // 简化实现 - 基于符号相似度
        let dreamsWithSymbols = dreams.filter { !($0.symbols ?? []).isEmpty }
        
        let dreamsBySymbolCount = Dictionary(grouping: dreamsWithSymbols) { dream in
            min((dream.symbols?.count ?? 0) / 5, 4)
        }
        
        return try await createClusters(from: dreamsBySymbolCount, k: 5)
    }
    
    /// 创建聚类
    private func createClusters<T>(
        from groups: [T: [DreamEntry]],
        k: Int
    ) async throws -> [ClusteringResult.DreamCluster] {
        var clusters: [ClusteringResult.DreamCluster] = []
        
        for (index, (_, dreams)) in groups.enumerated() {
            guard !dreams.isEmpty else { continue }
            
            let centroid = calculateClusterCentroid(dreams: dreams)
            let characteristics = generateClusterCharacteristics(dreams: dreams)
            
            clusters.append(.init(
                id: UUID(),
                name: "聚类组 \(index + 1)",
                dreamIds: dreams.map { $0.id },
                size: dreams.count,
                centroid: centroid,
                characteristics: characteristics,
                dominantEmotion: findDominantEmotion(dreams: dreams),
                commonSymbols: extractCommonSymbols(dreams: dreams),
                timeRange: nil
            ))
            
            if clusters.count >= k { break }
        }
        
        return clusters
    }
    
    /// 计算聚类中心
    private func calculateClusterCentroid(dreams: [DreamEntry]) -> ClusteringResult.ClusterCentroid {
        let emotionDistribution = Dictionary(grouping: dreams) { dream in
            dream.emotion?.rawValue ?? "neutral"
        }.mapValues { Double($0.count) / Double(dreams.count) }
        
        let averageClarity = dreams.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(dreams.count)
        let averageLength = dreams.map { Double($0.content?.count ?? 0) }.reduce(0, +) / Double(dreams.count)
        
        let allKeywords = dreams.flatMap { dream -> [String] in
            guard let content = dream.content else { return [] }
            return String(content.prefix(100)).split(separator: " ").map(String.init)
        }
        
        let commonKeywords = Dictionary(grouping: allKeywords) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
        
        return .init(
            emotionDistribution: emotionDistribution,
            averageClarity: averageClarity,
            averageLength: averageLength,
            commonKeywords: commonKeywords
        )
    }
    
    /// 生成聚类特征描述
    private func generateClusterCharacteristics(dreams: [DreamEntry]) -> [String] {
        var characteristics: [String] = []
        
        // 平均清晰度
        let avgClarity = dreams.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(dreams.count)
        characteristics.append("平均清晰度：\(Int(avgClarity * 100))%")
        
        // 清醒梦比例
        let lucidRatio = Double(dreams.filter { $0.isLucid }.count) / Double(dreams.count)
        characteristics.append("清醒梦比例：\(Int(lucidRatio * 100))%")
        
        // 平均长度
        let avgLength = dreams.map { $0.content?.count ?? 0 }.reduce(0, +) / dreams.count
        characteristics.append("平均长度：\(avgLength) 字")
        
        return characteristics
    }
    
    /// 提取常见符号
    private func extractCommonSymbols(dreams: [DreamEntry]) -> [String] {
        let allSymbols = dreams.flatMap { $0.symbols ?? [] }
        let symbolCounts = Dictionary(grouping: allSymbols) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return symbolCounts.prefix(10).map { $0.key }
    }
    
    /// 找出主导情绪
    private func findDominantEmotion(dreams: [DreamEntry]) -> DreamEmotion? {
        let emotionCounts = Dictionary(grouping: dreams) { dream in
            dream.emotion?.rawValue ?? "neutral"
        }.mapValues { $0.count }
        
        let dominant = emotionCounts.max(by: { $0.value < $1.value })?.key
        return dominant.flatMap { DreamEmotion(rawValue: $0) }
    }
    
    /// 计算聚类质量
    private func calculateClusteringQuality(
        clusters: [ClusteringResult.DreamCluster],
        dreams: [DreamEntry]
    ) -> Double {
        guard !clusters.isEmpty && !dreams.isEmpty else { return 0 }
        
        // 简化实现 - 基于聚类大小分布
        let sizes = clusters.map { Double($0.size) }
        let avgSize = sizes.reduce(0, +) / Double(sizes.count)
        let variance = sizes.map { pow($0 - avgSize, 2) }.reduce(0, +) / Double(sizes.count)
        let stdDev = sqrt(variance)
        
        // 质量分数：聚类大小越均匀，质量越高
        let quality = 1.0 / (1.0 + stdDev / avgSize)
        return min(1.0, max(0.0, quality))
    }
    
    // MARK: - 辅助方法
    
    /// 计算近期趋势
    private func calculateRecentTrend(dreams: [DreamEntry]) -> String {
        guard dreams.count >= 7 else { return "数据不足" }
        
        let recent7 = dreams.suffix(7)
        let previous7 = dreams.dropLast(7).suffix(7)
        
        let recentAvg = recent7.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(recent7.count)
        let previousAvg = previous7.map { $0.clarity ?? 0.5 }.reduce(0, +) / Double(previous7.count)
        
        let change = recentAvg - previousAvg
        
        if change > 0.1 {
            return "上升 ↗"
        } else if change < -0.1 {
            return "下降 ↘"
        } else {
            return "平稳 →"
        }
    }
    
    // MARK: - 缓存管理
    
    /// 获取缓存结果
    private func getCachedResult(forKey key: String) -> Any? {
        guard let cached = analysisCache[key] as? (data: Any, timestamp: Date) else {
            return nil
        }
        
        // 检查是否过期
        if Date().timeIntervalSince(cached.timestamp) > cacheExpiration {
            analysisCache.removeValue(forKey: key)
            return nil
        }
        
        return cached.data
    }
    
    /// 设置缓存结果
    private func setCachedResult(_ result: Any, forKey key: String) {
        analysisCache[key] = (data: result, timestamp: Date())
    }
    
    /// 清除缓存
    public func clearCache() {
        analysisCache.removeAll()
    }
}

// MARK: - 分析错误

public enum AnalyticsError: LocalizedError {
    case insufficientData
    case invalidConfiguration
    case calculationFailed
    case dataFetchFailed
    
    public var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "数据不足，无法进行分析"
        case .invalidConfiguration:
            return "配置无效"
        case .calculationFailed:
            return "计算失败"
        case .dataFetchFailed:
            return "数据获取失败"
        }
    }
}

// MARK: - 分析概览

/// 分析概览
public struct AnalyticsOverview {
    public let totalDreams: Int
    public let averageClarity: Double
    public let lucidDreamCount: Int
    public let dominantEmotion: String
    public let recentTrend: String
    public let lastUpdated: Date
}

// MARK: - DreamEmotion 扩展

extension DreamEmotion {
    /// 情绪分数（0-1）
    var emotionScore: Double {
        switch self {
        case .happy, .excited: return 0.8
        case .calm: return 0.6
        case .neutral: return 0.5
        case .confused: return 0.4
        case .sad: return 0.3
        case .anxious: return 0.25
        case .fearful: return 0.2
        }
    }
}
