//
//  DreamComparisonService.swift
//  DreamLog
//
//  Dream Comparison Feature - Core Service
//  Phase 77: Dream Comparison Tool
//

import Foundation
import SwiftData
import NaturalLanguage

@ModelActor
actor DreamComparisonService {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    private var comparisonHistory: [DreamComparisonResult] = []
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Core Comparison Functions
    
    /// 比较两个梦境
    func compareTwoDreams(dreamAId: UUID, dreamBId: UUID) async throws -> DreamComparisonResult {
        guard let dreamA = try fetchDream(by: dreamAId),
              let dreamB = try fetchDream(by: dreamBId) else {
            throw ComparisonError.dreamNotFound
        }
        
        let config = DreamComparisonConfig(
            dreamIds: [dreamAId, dreamBId],
            comparisonType: .twoDreams
        )
        
        return await performComparison(dreams: [dreamA, dreamB], config: config)
    }
    
    /// 比较多个梦境
    func compareMultipleDreams(dreamIds: [UUID]) async throws -> DreamComparisonResult {
        guard dreamIds.count >= 2 && dreamIds.count <= 5 else {
            throw ComparisonError.invalidDreamCount
        }
        
        var dreams: [Dream] = []
        for id in dreamIds {
            if let dream = try fetchDream(by: id) {
                dreams.append(dream)
            }
        }
        
        guard dreams.count >= 2 else {
            throw ComparisonError.dreamNotFound
        }
        
        let config = DreamComparisonConfig(
            dreamIds: dreamIds,
            comparisonType: dreamIds.count > 2 ? .multiDreams : .twoDreams
        )
        
        return await performComparison(dreams: dreams, config: config)
    }
    
    /// 执行对比分析
    private func performComparison(dreams: [Dream], config: DreamComparisonConfig) async -> DreamComparisonResult {
        let similarities = await findSimilarities(dreams: dreams, config: config)
        let differences = await findDifferences(dreams: dreams, config: config)
        let insights = await generateInsights(dreams: dreams, similarities: similarities, differences: differences)
        let similarityScore = calculateSimilarityScore(similarities: similarities, differences: differences)
        
        let result = DreamComparisonResult(
            dreamIds: config.dreamIds,
            comparisonType: config.comparisonType,
            similarities: similarities,
            differences: differences,
            insights: insights,
            similarityScore: similarityScore
        )
        
        // 保存结果
        await saveComparisonResult(result)
        
        return result
    }
    
    // MARK: - Similarity Detection
    
    /// 查找相似性
    private func findSimilarities(dreams: [Dream], config: DreamComparisonConfig) async -> [SimilarityCategory] {
        var similarities: [SimilarityCategory] = []
        
        // 共同标签
        if config.includeTags, let commonTags = findCommonTags(dreams: dreams), !commonTags.isEmpty {
            similarities.append(SimilarityCategory(
                category: .commonTags,
                items: commonTags,
                confidence: Double(commonTags.count) / Double(dreams.count)
            ))
        }
        
        // 共同情绪
        if config.includeEmotions, let commonEmotions = findCommonEmotions(dreams: dreams), !commonEmotions.isEmpty {
            similarities.append(SimilarityCategory(
                category: .commonEmotions,
                items: commonEmotions,
                confidence: Double(commonEmotions.count) / Double(dreams.count)
            ))
        }
        
        // 相似清晰度
        if let claritySimilarity = findClaritySimilarity(dreams: dreams) {
            similarities.append(claritySimilarity)
        }
        
        // 相似强度
        if let intensitySimilarity = findIntensitySimilarity(dreams: dreams) {
            similarities.append(intensitySimilarity)
        }
        
        // 共同主题 (基于 AI 分析)
        if config.includeAIAnalysis, let commonThemes = findCommonThemes(dreams: dreams), !commonThemes.isEmpty {
            similarities.append(SimilarityCategory(
                category: .commonThemes,
                items: commonThemes,
                confidence: 0.7
            ))
        }
        
        // 时间接近性
        if let timeProximity = findTimeProximity(dreams: dreams) {
            similarities.append(timeProximity)
        }
        
        return similarities
    }
    
    /// 查找共同标签
    private func findCommonTags(dreams: [Dream]) -> [String]? {
        guard dreams.count >= 2 else { return nil }
        
        let tagSets = dreams.map { Set($0.tags) }
        let commonTags = tagSets.reduce(tagSets.first ?? []) { $0.intersection($1) }
        
        return Array(commonTags)
    }
    
    /// 查找共同情绪
    private func findCommonEmotions(dreams: [Dream]) -> [String]? {
        guard dreams.count >= 2 else { return nil }
        
        let emotionSets = dreams.map { Set($0.emotions.map { $0.rawValue }) }
        let commonEmotions = emotionSets.reduce(emotionSets.first ?? []) { $0.intersection($1) }
        
        return Array(commonEmotions)
    }
    
    /// 查找清晰度相似性
    private func findClaritySimilarity(dreams: [Dream]) -> SimilarityCategory? {
        guard dreams.count >= 2 else { return nil }
        
        let clarityValues = dreams.map { $0.clarity }
        let avgClarity = clarityValues.reduce(0, +) / clarityValues.count
        let variance = clarityValues.map { pow(Double($0 - avgClarity), 2) }.reduce(0, +) / Double(clarityValues.count)
        
        // 方差小于 1 认为相似
        if variance < 1.0 {
            return SimilarityCategory(
                category: .similarClarity,
                items: ["平均清晰度：\(avgClarity)/5"],
                confidence: 1.0 - (variance / 4.0)
            )
        }
        
        return nil
    }
    
    /// 查找强度相似性
    private func findIntensitySimilarity(dreams: [Dream]) -> SimilarityCategory? {
        guard dreams.count >= 2 else { return nil }
        
        let intensityValues = dreams.map { $0.intensity }
        let avgIntensity = intensityValues.reduce(0, +) / intensityValues.count
        let variance = intensityValues.map { pow(Double($0 - avgIntensity), 2) }.reduce(0, +) / Double(intensityValues.count)
        
        if variance < 1.0 {
            return SimilarityCategory(
                category: .similarIntensity,
                items: ["平均强度：\(avgIntensity)/5"],
                confidence: 1.0 - (variance / 4.0)
            )
        }
        
        return nil
    }
    
    /// 查找共同主题
    private func findCommonThemes(dreams: [Dream]) -> [String]? {
        guard dreams.count >= 2 else { return nil }
        
        // 从 AI 分析中提取关键词
        let analyzer = NLTagger(tagSchemes: [.nameType])
        var themeCounts: [String: Int] = [:]
        
        for dream in dreams {
            if let analysis = dream.aiAnalysis {
                analyzer.string = analysis
                let tags = analyzer.tags(in: analysis.startIndex..<analysis.endIndex, unit: .word, scheme: .nameType)
                
                for tag in tags {
                    if let tag = tag.0, tag.rawValue == "PersonalName" || tag.rawValue == "LocationName" {
                        let word = String(tag.1)
                        themeCounts[word, default: 0] += 1
                    }
                }
            }
        }
        
        // 返回在多个梦中出现的主题
        let commonThemes = themeCounts.filter { $0.value >= 2 }.keys.map { String($0) }
        return commonThemes.isEmpty ? nil : commonThemes
    }
    
    /// 查找时间接近性
    private func findTimeProximity(dreams: [Dream]) -> SimilarityCategory? {
        guard dreams.count >= 2 else { return nil }
        
        let dates = dreams.map { $0.date }
        let sortedDates = dates.sorted()
        
        var totalDays: Double = 0
        for i in 1..<sortedDates.count {
            let interval = sortedDates[i].timeIntervalSince(sortedDates[i-1])
            totalDays += interval / (60 * 60 * 24)
        }
        
        let avgDays = totalDays / Double(dreams.count - 1)
        
        if avgDays < 7 {
            return SimilarityCategory(
                category: .timeProximity,
                items: ["平均间隔：\(Int(avgDays)) 天"],
                confidence: max(0.5, 1.0 - (avgDays / 7.0))
            )
        }
        
        return nil
    }
    
    // MARK: - Difference Detection
    
    /// 查找差异
    private func findDifferences(dreams: [Dream], config: DreamComparisonConfig) async -> [DifferenceCategory] {
        var differences: [DifferenceCategory] = []
        
        guard dreams.count >= 2 else { return differences }
        
        // 情绪变化
        if config.includeEmotions, let emotionDiff = findEmotionDifference(dreamA: dreams[0], dreamB: dreams[safe: 1]) {
            differences.append(emotionDiff)
        }
        
        // 清晰度变化
        if let clarityDiff = findClarityDifference(dreamA: dreams[0], dreamB: dreams[safe: 1]) {
            differences.append(clarityDiff)
        }
        
        // 强度变化
        if let intensityDiff = findIntensityDifference(dreamA: dreams[0], dreamB: dreams[safe: 1]) {
            differences.append(intensityDiff)
        }
        
        // 清醒梦状态差异
        if let lucidDiff = findLucidDifference(dreamA: dreams[0], dreamB: dreams[safe: 1]) {
            differences.append(lucidDiff)
        }
        
        return differences
    }
    
    private func findEmotionDifference(dreamA: Dream, dreamB: Dream?) -> DifferenceCategory? {
        guard let dreamB = dreamB else { return nil }
        
        let emotionA = dreamA.emotions.first?.rawValue ?? "未标记"
        let emotionB = dreamB.emotions.first?.rawValue ?? "未标记"
        
        if emotionA != emotionB {
            return DifferenceCategory(
                category: .emotionChange,
                dreamAValue: emotionA,
                dreamBValue: emotionB,
                significance: "情绪从\(emotionA)变为\(emotionB)"
            )
        }
        
        return nil
    }
    
    private func findClarityDifference(dreamA: Dream, dreamB: Dream?) -> DifferenceCategory? {
        guard let dreamB = dreamB else { return nil }
        
        let diff = abs(dreamA.clarity - dreamB.clarity)
        if diff >= 2 {
            return DifferenceCategory(
                category: .clarityChange,
                dreamAValue: "\(dreamA.clarity)/5",
                dreamBValue: "\(dreamB.clarity)/5",
                significance: "清晰度变化：\(diff > 2 ? "显著" : "轻微")"
            )
        }
        
        return nil
    }
    
    private func findIntensityDifference(dreamA: Dream, dreamB: Dream?) -> DifferenceCategory? {
        guard let dreamB = dreamB else { return nil }
        
        let diff = abs(dreamA.intensity - dreamB.intensity)
        if diff >= 2 {
            return DifferenceCategory(
                category: .intensityChange,
                dreamAValue: "\(dreamA.intensity)/5",
                dreamBValue: "\(dreamB.intensity)/5",
                significance: "强度变化：\(diff > 2 ? "显著" : "轻微")"
            )
        }
        
        return nil
    }
    
    private func findLucidDifference(dreamA: Dream, dreamB: Dream?) -> DifferenceCategory? {
        guard let dreamB = dreamB else { return nil }
        
        if dreamA.isLucid != dreamB.isLucid {
            return DifferenceCategory(
                category: .lucidStatus,
                dreamAValue: dreamA.isLucid ? "清醒梦" : "普通梦",
                dreamBValue: dreamB.isLucid ? "清醒梦" : "普通梦",
                significance: "清醒梦状态不同"
            )
        }
        
        return nil
    }
    
    // MARK: - Insight Generation
    
    /// 生成洞察
    private func generateInsights(dreams: [Dream], similarities: [SimilarityCategory], differences: [DifferenceCategory]) async -> [String] {
        var insights: [String] = []
        
        // 基于相似性生成洞察
        for similarity in similarities {
            switch similarity.category {
            case .commonTags:
                insights.append("这些梦境共享标签：\(similarity.items.joined(separator: "、"))，可能反映了持续的主题关注。")
            case .commonEmotions:
                insights.append("情绪模式一致：\(similarity.items.joined(separator: "、"))，表明情绪状态稳定。")
            case .commonThemes:
                insights.append("发现共同主题：\(similarity.items.joined(separator: "、"))，值得深入探索。")
            case .timeProximity:
                insights.append("这些梦境时间接近，可能存在连续性或关联性。")
            default:
                break
            }
        }
        
        // 基于差异生成洞察
        for difference in differences {
            switch difference.category {
            case .emotionChange:
                insights.append("情绪从\"\(difference.dreamAValue)\"转变为\"\(difference.dreamBValue)\"，可能反映了心理状态的变化。")
            case .clarityChange:
                insights.append("清晰度变化明显，可能与睡眠质量或记录时机有关。")
            case .lucidStatus:
                insights.append("清醒梦状态不同，可以尝试在普通梦中应用清醒梦技巧。")
            default:
                break
            }
        }
        
        return insights
    }
    
    // MARK: - Similarity Score Calculation
    
    /// 计算相似度分数
    private func calculateSimilarityScore(similarities: [SimilarityCategory], differences: [DifferenceCategory]) -> Double {
        let similarityWeight = similarities.reduce(0.0) { $0 + $1.confidence }
        let differencePenalty = Double(differences.count) * 0.1
        
        let score = max(0.0, min(1.0, similarityWeight - differencePenalty))
        return score
    }
    
    // MARK: - Data Persistence
    
    /// 保存对比结果
    private func saveComparisonResult(_ result: DreamComparisonResult) {
        modelContext.insert(result)
        comparisonHistory.append(result)
        
        try? modelContext.save()
    }
    
    /// 获取对比历史
    func getComparisonHistory(limit: Int = 10) async -> [DreamComparisonResult] {
        let descriptor = FetchDescriptor<DreamComparisonResult>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            return Array(results.prefix(limit))
        } catch {
            return comparisonHistory.prefix(limit).map { $0 }
        }
    }
    
    /// 获取对比统计
    func getComparisonStatistics() async -> ComparisonStatistics {
        let descriptor = FetchDescriptor<DreamComparisonResult>()
        
        do {
            let results = try modelContext.fetch(descriptor)
            let totalComparisons = results.count
            let averageSimilarity = results.reduce(0.0) { $0 + $1.similarityScore } / Double(max(1, totalComparisons))
            
            // 找出最常见的相似性类型
            var similarityCounts: [SimilarityType: Int] = [:]
            for result in results {
                for similarity in result.similarities {
                    similarityCounts[similarity.category, default: 0] += 1
                }
            }
            let mostCommonSimilarity = similarityCounts.max(by: { $0.value < $1.value })?.key
            
            // 找出最常见的差异类型
            var differenceCounts: [DifferenceType: Int] = [:]
            for result in results {
                for difference in result.differences {
                    differenceCounts[difference.category, default: 0] += 1
                }
            }
            let mostCommonDifference = differenceCounts.max(by: { $0.value < $1.value })?.key
            
            return ComparisonStatistics(
                totalComparisons: totalComparisons,
                averageSimilarity: averageSimilarity,
                mostCommonSimilarity: mostCommonSimilarity,
                mostCommonDifference: mostCommonDifference,
                recentComparisons: results.map { $0.createdAt }.prefix(10).map { $0 }
            )
        } catch {
            return ComparisonStatistics()
        }
    }
    
    /// 删除对比结果
    func deleteComparisonResult(id: UUID) async {
        let descriptor = FetchDescriptor<DreamComparisonResult>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            for result in results {
                modelContext.delete(result)
            }
            try modelContext.save()
        } catch {
            print("删除对比结果失败：\(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    /// 获取梦境
    private func fetchDream(by id: UUID) throws -> Dream? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == id }
        )
        
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Collection Extension

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Comparison Errors

enum ComparisonError: LocalizedError {
    case dreamNotFound
    case invalidDreamCount
    case comparisonFailed
    
    var errorDescription: String? {
        switch self {
        case .dreamNotFound:
            return "未找到指定的梦境"
        case .invalidDreamCount:
            return "请选择 2-5 个梦境进行对比"
        case .comparisonFailed:
            return "对比分析失败，请重试"
        }
    }
}
