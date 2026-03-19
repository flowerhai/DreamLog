//
//  DreamIntentionService.swift
//  DreamLog - Phase 66: Dream Intention Setting & Manifestation Tracking
//
//  Created by DreamLog Team on 2026/03/19.
//

import Foundation
import SwiftData

@available(iOS 17.0, *)
@ModelActor
actor DreamIntentionService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let userDefaults: UserDefaults
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, userDefaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.userDefaults = userDefaults
    }
    
    // MARK: - CRUD Operations
    
    /// 创建新的梦境意图
    func createIntention(
        title: String,
        description: String,
        type: DreamIntentionType,
        priority: Int = 3,
        affirmation: String? = nil,
        visualizationNotes: String? = nil,
        targetDate: Date? = nil,
        isRecurring: Bool = false,
        recurrencePattern: String? = nil
    ) throws -> DreamIntention {
        let intention = DreamIntention(
            title: title,
            description: description,
            type: type,
            priority: priority,
            affirmation: affirmation,
            visualizationNotes: visualizationNotes,
            targetDate: targetDate,
            isRecurring = isRecurring,
            recurrencePattern = recurrencePattern
        )
        
        modelContext.insert(intention)
        try modelContext.save()
        
        // 更新连续记录
        updateStreak()
        
        return intention
    }
    
    /// 获取所有意图
    func getAllIntentions() -> [DreamIntention] {
        let descriptor = FetchDescriptor<DreamIntention>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    /// 获取活跃意图
    func getActiveIntentions() -> [DreamIntention] {
        let descriptor = FetchDescriptor<DreamIntention>(
            predicate: #Predicate<DreamIntention> { $0.status == .active },
            sortBy: [SortDescriptor(\.priority, order: .reverse)]
        )
        
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    /// 获取指定类型的意图
    func getIntentions(by type: DreamIntentionType) -> [DreamIntention] {
        let descriptor = FetchDescriptor<DreamIntention>(
            predicate: #Predicate<DreamIntention> { $0.type == type },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    /// 获取单个意图
    func getIntention(by id: UUID) -> DreamIntention? {
        let descriptor = FetchDescriptor<DreamIntention>(
            predicate: #Predicate<DreamIntention> { $0.id == id }
        )
        
        return try? modelContext.fetch(descriptor)?.first
    }
    
    /// 更新意图
    func updateIntention(_ intention: DreamIntention) throws {
        try modelContext.save()
    }
    
    /// 删除意图
    func deleteIntention(_ intention: DreamIntention) throws {
        modelContext.delete(intention)
        try modelContext.save()
    }
    
    /// 更新显化状态
    func updateManifestation(
        for intentionId: UUID,
        strength: ManifestationStrength,
        dreamIds: [UUID]
    ) throws {
        guard let intention = getIntention(by: intentionId) else {
            throw IntentionError.notFound
        }
        
        intention.updateManifestation(strength: strength, dreamIds: dreamIds)
        try modelContext.save()
    }
    
    /// 取消意图
    func cancelIntention(_ intentionId: UUID) throws {
        guard let intention = getIntention(by: intentionId) else {
            throw IntentionError.notFound
        }
        
        intention.status = .cancelled
        try modelContext.save()
    }
    
    // MARK: - Statistics
    
    /// 获取统计数据
    func getStatistics() -> DreamIntentionStats {
        let allIntentions = getAllIntentions()
        
        let active = allIntentions.filter { $0.status == .active }
        let manifested = allIntentions.filter { $0.status == .manifested }
        let partial = allIntentions.filter { $0.status == .partial }
        
        let byType = Dictionary(grouping: allIntentions, by: { $0.type })
            .mapValues { $0.count }
        
        let totalAttempts = allIntentions.reduce(0) { $0 + $1.totalAttempts }
        let totalSuccess = allIntentions.reduce(0) { $0 + $1.successfulManifestations }
        let overallRate = totalAttempts > 0 ? Double(totalSuccess) / Double(totalAttempts) : 0.0
        
        // 找出成功率最高的类型
        let bestType = byType.keys.max {
            let type1Intentions = getIntentions(by: $0)
            let type2Intentions = getIntentions(by: $1)
            let rate1 = type1Intentions.isEmpty ? 0 : Double(type1Intentions.filter { $0.status == .manifested }.count) / Double(type1Intentions.count)
            let rate2 = type2Intentions.isEmpty ? 0 : Double(type2Intentions.filter { $0.status == .manifested }.count) / Double(type2Intentions.count)
            return rate1 < rate2
        }
        
        let recent = Array(allIntentions.prefix(5))
        
        return DreamIntentionStats(
            totalIntentions: allIntentions.count,
            activeIntentions: active.count,
            manifestedIntentions: manifested.count,
            partialManifestations: partial.count,
            overallSuccessRate: overallRate,
            byType: byType,
            recentIntentions: recent,
            streakDays: getStreak(),
            bestPerformingType: bestType
        )
    }
    
    /// 获取今日建议
    func getDailySuggestions() -> [IntentionSuggestion] {
        var suggestions: [IntentionSuggestion] = []
        
        // 根据用户历史推荐
        let stats = getStatistics()
        
        // 如果某种类型成功率高，推荐该类型
        if let bestType = stats.bestPerformingType {
            suggestions.append(contentsOf: IntentionSuggestion.suggestionsForType(bestType))
        }
        
        // 添加通用建议
        for type in DreamIntentionType.allCases.prefix(4) {
            suggestions.append(contentsOf: IntentionSuggestion.suggestionsForType(type))
        }
        
        return Array(suggestions.prefix(8))
    }
    
    // MARK: - Dream Integration
    
    /// 检查梦境是否匹配活跃意图
    func checkDreamMatch(dream: Dream) -> [DreamIntention] {
        let activeIntentions = getActiveIntentions()
        var matchedIntentions: [DreamIntention] = []
        
        for intention in activeIntentions {
            if isDreamMatched(dream: dream, intention: intention) {
                matchedIntentions.append(intention)
            }
        }
        
        return matchedIntentions
    }
    
    /// 判断梦境是否匹配意图
    private func isDreamMatched(dream: Dream, intention: DreamIntention) -> Bool {
        // 检查标题和内容是否包含意图关键词
        let dreamText = "\(dream.title) \(dream.content)".lowercased()
        let intentionKeywords = intention.title.lowercased()
            .components(separatedBy: .whitespaces)
            .filter { $0.count > 2 }
        
        let matchCount = intentionKeywords.filter { dreamText.contains($0) }.count
        
        // 检查标签匹配
        let tagMatch = intention.description.lowercased()
            .components(separatedBy: .whitespaces)
            .contains { tag in
                dream.tags.contains { $0.lowercased().contains(tag) }
            }
        
        // 如果关键词匹配度超过 50% 或标签匹配，认为匹配
        let keywordMatchRate = Double(matchCount) / Double(max(1, intentionKeywords.count))
        return keywordMatchRate >= 0.5 || tagMatch
    }
    
    /// 自动建议显化强度
    func suggestManifestationStrength(dream: Dream, intention: DreamIntention) -> ManifestationStrength {
        let dreamText = "\(dream.title) \(dream.content)".lowercased()
        let intentionText = "\(intention.title) \(intention.description)".lowercased()
        
        // 计算文本相似度
        var matchScore = 0.0
        
        // 关键词匹配
        let intentionWords = intentionText.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
        
        for word in intentionWords {
            if dreamText.contains(word) {
                matchScore += 1.0
            }
        }
        
        let normalizedScore = matchScore / Double(max(1, intentionWords.count))
        
        // 根据匹配度返回强度
        if normalizedScore >= 0.8 {
            return .exact
        } else if normalizedScore >= 0.6 {
            return .strong
        } else if normalizedScore >= 0.4 {
            return .moderate
        } else if normalizedScore >= 0.2 {
            return .weak
        } else {
            return .none
        }
    }
    
    // MARK: - Streak Management
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastStreakDate = userDefaults.object(forKey: "intentionStreakLastDate") as? Date
        
        if let lastDate = lastStreakDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            if daysSince == 1 {
                // 连续一天
                let currentStreak = userDefaults.integer(forKey: "intentionStreak")
                userDefaults.set(currentStreak + 1, forKey: "intentionStreak")
            } else if daysSince > 1 {
                // 中断，重置
                userDefaults.set(1, forKey: "intentionStreak")
            }
            // daysSince == 0 表示今天已经记录过
        } else {
            // 第一次
            userDefaults.set(1, forKey: "intentionStreak")
        }
        
        userDefaults.set(today, forKey: "intentionStreakLastDate")
    }
    
    private func getStreak() -> Int {
        return userDefaults.integer(forKey: "intentionStreak")
    }
    
    // MARK: - Cleanup
    
    /// 清理过期意图
    func cleanupExpiredIntentions() throws {
        let allIntentions = getAllIntentions()
        let expired = allIntentions.filter { $0.isExpired }
        
        for intention in expired {
            intention.status = .expired
        }
        
        try modelContext.save()
    }
    
    /// 创建周期性意图的新实例
    func createRecurringInstances() throws {
        let activeIntentions = getActiveIntentions()
        let recurring = activeIntentions.filter { $0.isRecurring }
        
        for intention in recurring {
            // 检查是否需要创建新实例
            // 这里可以根据 recurrencePattern 实现具体逻辑
        }
    }
}

// MARK: - Errors

enum IntentionError: LocalizedError {
    case notFound
    case invalidData
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "意图未找到"
        case .invalidData: return "数据无效"
        case .saveFailed: return "保存失败"
        }
    }
}

// MARK: - Dream Extension

extension Dream {
    /// 检查是否有匹配的活跃意图
    func hasMatchingIntentions(service: DreamIntentionService) async -> [DreamIntention] {
        await service.checkDreamMatch(dream: self)
    }
}
