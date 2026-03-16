//
//  DreamRecommendationEngine.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  推荐引擎核心服务
//

import Foundation
import SwiftData

actor DreamRecommendationEngine {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var config: RecommendationConfig
    private var recommendationHistory: [UUID: Date] = [:]  // 推荐历史记录
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, config: RecommendationConfig = .default) {
        self.modelContext = modelContext
        self.config = config
    }
    
    // MARK: - Public Methods
    
    /// 生成个性化推荐
    public func generateRecommendations(limit: Int = 10) async throws -> [DreamRecommendation] {
        var recommendations: [DreamRecommendation] = []
        
        // 1. 相似梦境推荐
        if config.enableSimilarDreams {
            let similarDreamRecs = try await generateSimilarDreamRecommendations(limit: 3)
            recommendations.append(contentsOf: similarDreamRecs)
        }
        
        // 2. 冥想推荐
        if config.enableMeditationRecommendations {
            let meditationRecs = try await generateMeditationRecommendations(limit: 2)
            recommendations.append(contentsOf: meditationRecs)
        }
        
        // 3. 音乐推荐
        if config.enableMusicRecommendations {
            let musicRecs = try await generateMusicRecommendations(limit: 2)
            recommendations.append(contentsOf: musicRecs)
        }
        
        // 4. 灵感提示推荐
        if config.enableInspirationRecommendations {
            let inspirationRecs = try await generateInspirationRecommendations(limit: 2)
            recommendations.append(contentsOf: inspirationRecs)
        }
        
        // 5. 清醒梦训练推荐
        if config.enableLucidTrainingRecommendations {
            let lucidRecs = try await generateLucidTrainingRecommendations(limit: 1)
            recommendations.append(contentsOf: lucidRecs)
        }
        
        // 过滤低置信度推荐
        recommendations = recommendations.filter { $0.confidence >= config.minConfidenceThreshold }
        
        // 按优先级和置信度排序
        recommendations.sort { rec1, rec2 in
            let score1 = Double(rec1.priority) * rec1.confidence
            let score2 = Double(rec2.priority) * rec2.confidence
            return score1 > score2
        }
        
        // 限制数量
        return Array(recommendations.prefix(limit))
    }
    
    /// 获取梦境的相关推荐
    public func getRecommendations(for dreamId: UUID, limit: Int = 5) async throws -> [DreamRecommendation] {
        guard let dream = try getDream(by: dreamId) else {
            return []
        }
        
        var recommendations: [DreamRecommendation] = []
        
        // 基于当前梦境的标签推荐相似梦境
        let similarRecs = try generateSimilarDreamRecs(for: dream, limit: limit)
        recommendations.append(contentsOf: similarRecs)
        
        return recommendations
    }
    
    /// 标记推荐为已读
    public func markAsRead(_ recommendationId: UUID) async throws {
        let fetchDescriptor = FetchDescriptor<DreamRecommendation>(
            predicate: #Predicate { $0.id == recommendationId }
        )
        
        if var recommendation = try modelContext.fetch(fetchDescriptor).first {
            recommendation.isRead = true
            try modelContext.save()
        }
    }
    
    /// 标记推荐为喜欢
    public func markAsLiked(_ recommendationId: UUID) async throws {
        let fetchDescriptor = FetchDescriptor<DreamRecommendation>(
            predicate: #Predicate { $0.id == recommendationId }
        )
        
        if var recommendation = try modelContext.fetch(fetchDescriptor).first {
            recommendation.isLiked = true
            try modelContext.save()
        }
    }
    
    /// 标记推荐为关闭
    public func markAsDismissed(_ recommendationId: UUID) async throws {
        let fetchDescriptor = FetchDescriptor<DreamRecommendation>(
            predicate: #Predicate { $0.id == recommendationId }
        )
        
        if var recommendation = try modelContext.fetch(fetchDescriptor).first {
            recommendation.isDismissed = true
            try modelContext.save()
        }
    }
    
    /// 提交反馈评分
    public func submitFeedback(for recommendationId: UUID, score: Int) async throws {
        let fetchDescriptor = FetchDescriptor<DreamRecommendation>(
            predicate: #Predicate { $0.id == recommendationId }
        )
        
        if var recommendation = try modelContext.fetch(fetchDescriptor).first {
            recommendation.feedbackScore = score
            try modelContext.save()
        }
    }
    
    /// 获取推荐统计
    public func getStats() async throws -> RecommendationStats {
        let fetchDescriptor = FetchDescriptor<DreamRecommendation>()
        let allRecommendations = try modelContext.fetch(fetchDescriptor)
        
        let total = allRecommendations.count
        let readCount = allRecommendations.filter { $0.isRead }.count
        let likedCount = allRecommendations.filter { $0.isLiked }.count
        let dismissedCount = allRecommendations.filter { $0.isDismissed }.count
        
        let ctr = total > 0 ? Double(readCount) / Double(total) : 0
        
        let feedbackScores = allRecommendations.compactMap { $0.feedbackScore }
        let avgScore = feedbackScores.isEmpty ? nil : feedbackScores.reduce(0, +) / feedbackScores.count
        
        // 按类型统计
        var byType: [DreamRecommendationType: Int] = [:]
        for rec in allRecommendations {
            byType[rec.type, default: 0] += 1
        }
        
        // 找出最多的类型
        let topType = byType.max(by: { $0.value < $1.value })?.key
        
        return RecommendationStats(
            totalRecommendations: total,
            readCount: readCount,
            likedCount: likedCount,
            dismissedCount: dismissedCount,
            clickThroughRate: ctr,
            averageFeedbackScore: avgScore,
            topRecommendationType: topType,
            recommendationsByType: byType
        )
    }
    
    /// 清理过期推荐
    public func cleanupExpiredRecommendations() async throws {
        let fetchDescriptor = FetchDescriptor<DreamRecommendation>()
        let allRecommendations = try modelContext.fetch(fetchDescriptor)
        
        for recommendation in allRecommendations {
            if recommendation.isExpired {
                modelContext.delete(recommendation)
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Private Methods - 推荐生成
    
    /// 生成相似梦境推荐
    private func generateSimilarDreamRecommendations(limit: Int) async throws -> [DreamRecommendation] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let dreams = try modelContext.fetch(fetchDescriptor)
        
        guard dreams.count > 5 else { return [] }
        
        // 获取最近的梦境
        let recentDreams = Array(dreams.prefix(10))
        
        // 为每个最近梦境找相似梦境
        var recommendations: [DreamRecommendation] = []
        
        for dream in recentDreams {
            let similarDreams = findSimilarDreams(to: dream, in: dreams, limit: 2)
            
            for similarDream in similarDreams {
                let confidence = calculateSimilarityScore(dream1: dream, dream2: similarDream)
                
                if confidence >= config.minConfidenceThreshold {
                    let rec = DreamRecommendation(
                        type: .similarDream,
                        title: "相似梦境",
                        description: "这个梦境与你 \(formatDate(dream.createdAt)) 记录的梦境很相似",
                        reason: "基于标签和情绪的相似度：\(Int(confidence * 100))%",
                        confidence: confidence,
                        priority: 4,
                        metadata: [
                            "sourceDreamId": AnyCodable(dream.id.uuidString),
                            "targetDreamId": AnyCodable(similarDream.id.uuidString)
                        ],
                        relatedDreamIds: [dream.id, similarDream.id],
                        expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
                    )
                    recommendations.append(rec)
                }
            }
            
            if recommendations.count >= limit {
                break
            }
        }
        
        return recommendations
    }
    
    /// 生成冥想推荐
    private func generateMeditationRecommendations(limit: Int) async throws -> [DreamRecommendation] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.createdAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let recentDreams = try modelContext.fetch(fetchDescriptor)
        
        guard !recentDreams.isEmpty else { return [] }
        
        // 分析最近梦境的情绪
        let emotionCounts = Dictionary(grouping: recentDreams) { dream in
            dream.emotions.first?.rawValue ?? "neutral"
        }
        
        let dominantEmotion = emotionCounts.max(by: { $0.value.count < $1.value.count })?.key
        
        var recommendations: [DreamRecommendation] = []
        
        // 根据情绪推荐冥想
        if let emotion = dominantEmotion {
            let meditationType = getMeditationType(for: emotion)
            let confidence = Double(emotionCounts[emotion]?.count ?? 0) / Double(recentDreams.count)
            
            let rec = DreamRecommendation(
                type: .meditation,
                title: "推荐冥想",
                description: "基于你最近的梦境情绪，推荐尝试\(meditationType)冥想",
                reason: "你最近\(emotionCounts[emotion]?.count ?? 0)个梦境呈现\(emotion)情绪",
                confidence: confidence,
                priority: 3,
                metadata: ["meditationType": AnyCodable(meditationType), "emotion": AnyCodable(emotion)],
                expiresAt: Calendar.current.date(byAdding: .day, value: 3, to: Date())
            )
            recommendations.append(rec)
        }
        
        return Array(recommendations.prefix(limit))
    }
    
    /// 生成音乐推荐
    private func generateMusicRecommendations(limit: Int) async throws -> [DreamRecommendation] {
        // 基于最近梦境的情绪推荐音乐
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.createdAt >= Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date() }
        )
        let recentDreams = try modelContext.fetch(fetchDescriptor)
        
        guard !recentDreams.isEmpty else { return [] }
        
        var recommendations: [DreamRecommendation] = []
        
        // 分析情绪分布
        let mood = analyzeMood(from: recentDreams)
        let musicType = getMusicType(for: mood)
        
        let rec = DreamRecommendation(
            type: .music,
            title: "梦境音乐推荐",
            description: "根据你的梦境情绪，推荐\(musicType)风格的音乐",
            reason: "最近梦境的整体情绪是\(mood)",
            confidence: 0.6,
            priority: 3,
            metadata: ["musicType": AnyCodable(musicType), "mood": AnyCodable(mood)],
            expiresAt: Calendar.current.date(byAdding: .day, value: 2, to: Date())
        )
        recommendations.append(rec)
        
        return Array(recommendations.prefix(limit))
    }
    
    /// 生成灵感提示推荐
    private func generateInspirationRecommendations(limit: Int) async throws -> [DreamRecommendation] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let dreams = try modelContext.fetch(fetchDescriptor)
        
        guard dreams.count > 3 else { return [] }
        
        var recommendations: [DreamRecommendation] = []
        
        // 查找有创意的梦境
        let creativeDreams = dreams.filter { dream in
            dream.tags.contains { tag in
                ["创意", "艺术", "音乐", "写作", "灵感"].contains(tag)
            }
        }
        
        if !creativeDreams.isEmpty {
            let rec = DreamRecommendation(
                type: .inspiration,
                title: "创意灵感",
                description: "你的梦境充满创意！试试将这些想法记录下来",
                reason: "发现\(creativeDreams.count)个创意相关的梦境",
                confidence: 0.7,
                priority: 4,
                metadata: ["creativeDreamCount": AnyCodable(creativeDreams.count)],
                expiresAt: Calendar.current.date(byAdding: .day, value: 1, to: Date())
            )
            recommendations.append(rec)
        }
        
        return Array(recommendations.prefix(limit))
    }
    
    /// 生成清醒梦训练推荐
    private func generateLucidTrainingRecommendations(limit: Int) async throws -> [DreamRecommendation] {
        let fetchDescriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let dreams = try modelContext.fetch(fetchDescriptor)
        
        let lucidDreams = dreams.filter { $0.isLucid }
        let lucidRate = dreams.isEmpty ? 0 : Double(lucidDreams.count) / Double(dreams.count)
        
        var recommendations: [DreamRecommendation] = []
        
        // 如果清醒梦比例低，推荐训练
        if lucidRate < 0.2 && dreams.count >= 5 {
            let rec = DreamRecommendation(
                type: .lucidTraining,
                title: "清醒梦训练",
                description: "你的清醒梦比例较低，试试这些训练技巧",
                reason: "当前清醒梦比例：\(Int(lucidRate * 100))%，目标是 20%+",
                confidence: 0.8,
                priority: 3,
                metadata: ["lucidRate": AnyCodable(lucidRate)],
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: Date())
            )
            recommendations.append(rec)
        }
        
        return Array(recommendations.prefix(limit))
    }
    
    // MARK: - 辅助方法
    
    /// 查找相似梦境
    private func findSimilarDreams(to dream: Dream, in dreams: [Dream], limit: Int) -> [Dream] {
        let scoredDreams = dreams.compactMap { otherDream -> (Dream, Double)? in
            guard otherDream.id != dream.id else { return nil }
            let score = calculateSimilarityScore(dream1: dream, dream2: otherDream)
            return (otherDream, score)
        }
        
        let sorted = scoredDreams.sorted { $0.1 > $1.1 }
        return sorted.prefix(limit).map { $0.0 }
    }
    
    /// 计算相似度分数
    private func calculateSimilarityScore(dream1: Dream, dream2: Dream) -> Double {
        var score = 0.0
        
        // 标签相似度 (40%)
        let commonTags = Set(dream1.tags).intersection(Set(dream2.tags))
        let tagScore = commonTags.isEmpty ? 0 : Double(commonTags.count) / Double(max(dream1.tags.count, dream2.tags.count))
        score += tagScore * 0.4
        
        // 情绪相似度 (30%)
        let commonEmotions = Set(dream1.emotions.map { $0.rawValue }).intersection(Set(dream2.emotions.map { $0.rawValue }))
        let emotionScore = commonEmotions.isEmpty ? 0 : Double(commonEmotions.count) / Double(max(dream1.emotions.count, dream2.emotions.count))
        score += emotionScore * 0.3
        
        // 清晰度相似度 (15%)
        let clarityDiff = abs(dream1.clarity - dream2.clarity)
        let clarityScore = max(0, 1 - Double(clarityDiff) / 5.0)
        score += clarityScore * 0.15
        
        // 清醒梦状态相似度 (15%)
        if dream1.isLucid == dream2.isLucid {
            score += 0.15
        }
        
        return min(1.0, score)
    }
    
    /// 分析整体情绪
    private func analyzeMood(from dreams: [Dream]) -> String {
        let emotionCounts = Dictionary(grouping: dreams) { dream in
            dream.emotions.first?.rawValue ?? "neutral"
        }
        
        guard let dominant = emotionCounts.max(by: { $0.value.count < $1.value.count }) else {
            return "neutral"
        }
        
        return dominant.key
    }
    
    /// 获取冥想类型
    private func getMeditationType(for emotion: String) -> String {
        switch emotion {
        case "anxious", "fearful": return "放松"
        case "sad": return "正念"
        case "excited", "happy": return "感恩"
        case "confused": return "清晰"
        default: return "基础"
        }
    }
    
    /// 获取音乐类型
    private func getMusicType(for mood: String) -> String {
        switch mood {
        case "calm", "peaceful": return "环境氛围"
        case "happy", "excited": return "欢快"
        case "sad", "melancholic": return "钢琴曲"
        case "anxious", "fearful": return "白噪音"
        case "mysterious": return "神秘"
        default: return "放松"
        }
    }
    
    /// 获取梦境
    private func getDream(by id: UUID) throws -> Dream? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(fetchDescriptor).first
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M 月 d 日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}
