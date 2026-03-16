//
//  DreamSuggestionService.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  个性化建议生成服务
//

import Foundation
import SwiftData

actor DreamSuggestionService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var suggestionHistory: [UUID: Date] = [:]
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// 生成个性化建议
    public func generateSuggestions(limit: Int = 10) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        // 1. 记录优化建议
        let recordingSuggestions = try await generateRecordingSuggestions(limit: 2)
        suggestions.append(contentsOf: recordingSuggestions)
        
        // 2. 清醒梦训练建议
        let lucidSuggestions = try await generateLucidDreamSuggestions(limit: 2)
        suggestions.append(contentsOf: lucidSuggestions)
        
        // 3. 睡眠改善建议
        let sleepSuggestions = try await generateSleepSuggestions(limit: 2)
        suggestions.append(contentsOf: sleepSuggestions)
        
        // 4. 创意启发建议
        let creativitySuggestions = try await generateCreativitySuggestions(limit: 2)
        suggestions.append(contentsOf: creativitySuggestions)
        
        // 5. 健康建议
        let healthSuggestions = try await generateHealthSuggestions(limit: 1)
        suggestions.append(contentsOf: healthSuggestions)
        
        // 6. 社交建议
        let socialSuggestions = try await generateSocialSuggestions(limit: 1)
        suggestions.append(contentsOf: socialSuggestions)
        
        // 过滤已接受的建议
        suggestions = suggestions.filter { !$0.isAccepted }
        
        // 按难度和优先级排序
        suggestions.sort { s1, s2 in
            // 优先推荐低难度、高收益的建议
            let score1 = Double(6 - s1.difficulty) * 0.6 + Double(s1.estimatedTime < 15 ? 1 : 0) * 0.4
            let score2 = Double(6 - s2.difficulty) * 0.6 + Double(s2.estimatedTime < 15 ? 1 : 0) * 0.4
            return score1 > score2
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    /// 获取指定类别的建议
    public func getSuggestions(category: SuggestionCategory, limit: Int = 5) async throws -> [DreamSuggestion] {
        let fetchDescriptor = FetchDescriptor<DreamSuggestion>(
            predicate: #Predicate { $0.category == category && $0.isDismissed == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        var suggestions = try modelContext.fetch(fetchDescriptor)
        return Array(suggestions.prefix(limit))
    }
    
    /// 接受建议
    public func acceptSuggestion(_ suggestionId: UUID) async throws {
        let fetchDescriptor = FetchDescriptor<DreamSuggestion>(
            predicate: #Predicate { $0.id == suggestionId }
        )
        
        if var suggestion = try modelContext.fetch(fetchDescriptor).first {
            suggestion.accept()
            try modelContext.save()
        }
    }
    
    /// 完成建议
    public func completeSuggestion(_ suggestionId: UUID) async throws {
        let fetchDescriptor = FetchDescriptor<DreamSuggestion>(
            predicate: #Predicate { $0.id == suggestionId }
        )
        
        if var suggestion = try modelContext.fetch(fetchDescriptor).first {
            suggestion.complete()
            try modelContext.save()
        }
    }
    
    /// 关闭建议
    public func dismissSuggestion(_ suggestionId: UUID) async throws {
        let fetchDescriptor = FetchDescriptor<DreamSuggestion>(
            predicate: #Predicate { $0.id == suggestionId }
        )
        
        if var suggestion = try modelContext.fetch(fetchDescriptor).first {
            suggestion.isDismissed = true
            try modelContext.save()
        }
    }
    
    /// 获取建议统计
    public func getStats() async throws -> SuggestionStats {
        let fetchDescriptor = FetchDescriptor<DreamSuggestion>()
        let allSuggestions = try modelContext.fetch(fetchDescriptor)
        
        let total = allSuggestions.count
        let acceptedCount = allSuggestions.filter { $0.isAccepted }.count
        let completedCount = allSuggestions.filter { $0.isCompleted }.count
        let dismissedCount = allSuggestions.filter { $0.isDismissed }.count
        
        let acceptanceRate = total > 0 ? Double(acceptedCount) / Double(total) : 0
        let completionRate = acceptedCount > 0 ? Double(completedCount) / Double(acceptedCount) : 0
        
        // 按类别统计
        var byCategory: [SuggestionCategory: Int] = [:]
        for suggestion in allSuggestions {
            byCategory[suggestion.category, default: 0] += 1
        }
        
        return SuggestionStats(
            totalSuggestions: total,
            acceptedCount: acceptedCount,
            completedCount: completedCount,
            dismissedCount: dismissedCount,
            acceptanceRate: acceptanceRate,
            completionRate: completionRate,
            suggestionsByCategory: byCategory
        )
    }
    
    /// 清理已完成的建议
    public func cleanupCompletedSuggestions(olderThan days: Int = 30) async throws {
        let fetchDescriptor = FetchDescriptor<DreamSuggestion>()
        let allSuggestions = try modelContext.fetch(fetchDescriptor)
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        for suggestion in allSuggestions {
            if suggestion.isCompleted,
               let completedAt = suggestion.completedAt,
               completedAt < cutoffDate {
                modelContext.delete(suggestion)
            }
        }
        
        try modelContext.save()
    }
    
    // MARK: - Private Methods - 建议生成
    
    /// 生成记录优化建议
    private func generateRecordingSuggestions(limit: Int) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        let dreams = try getAllDreams()
        guard !dreams.isEmpty else { return [] }
        
        // 分析记录频率
        let calendar = Calendar.current
        let last7Days = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentDreams = dreams.filter { $0.createdAt >= last7Days }
        
        // 如果记录频率低
        if recentDreams.count < 3 {
            let suggestion = DreamSuggestion(
                category: .recording,
                title: "提高记录频率",
                action: "每天早晨花 2 分钟记录梦境",
                reason: "你最近 7 天只记录了\(recentDreams.count)个梦境",
                expectedBenefit: "更高的记录频率有助于发现更多梦境模式",
                difficulty: 2,
                estimatedTime: 2,
                tags: ["习惯养成", "晨间仪式"]
            )
            suggestions.append(suggestion)
        }
        
        // 分析标签使用
        let dreamsWithoutTags = dreams.filter { $0.tags.isEmpty }
        if Double(dreamsWithoutTags.count) / Double(dreams.count) > 0.5 {
            let suggestion = DreamSuggestion(
                category: .recording,
                title: "添加梦境标签",
                action: "为每个梦境添加 3-5 个标签",
                reason: "你\(Int(Double(dreamsWithoutTags.count) / Double(dreams.count) * 100))%的梦境没有标签",
                expectedBenefit: "标签可以帮助你更好地分类和搜索梦境",
                difficulty: 1,
                estimatedTime: 1,
                tags: ["标签管理", "组织"]
            )
            suggestions.append(suggestion)
        }
        
        // 分析图片使用
        let dreamsWithoutImages = dreams.filter { $0.images?.isEmpty ?? true }
        if Double(dreamsWithoutImages.count) / Double(dreams.count) > 0.8 {
            let suggestion = DreamSuggestion(
                category: .recording,
                title: "生成梦境图片",
                action: "为重要梦境生成 AI 图片",
                reason: "只有\(Int(Double(dreams.count - dreamsWithoutImages.count) / Double(dreams.count) * 100))%的梦境有图片",
                expectedBenefit: "视觉化可以帮助你更好地回忆和理解梦境",
                difficulty: 2,
                estimatedTime: 5,
                tags: ["AI 生成", "视觉化"]
            )
            suggestions.append(suggestion)
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    /// 生成清醒梦训练建议
    private func generateLucidDreamSuggestions(limit: Int) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        let dreams = try getAllDreams()
        let lucidDreams = dreams.filter { $0.isLucid }
        let lucidRate = dreams.isEmpty ? 0 : Double(lucidDreams.count) / Double(dreams.count)
        
        // 如果清醒梦比例低
        if lucidRate < 0.2 && dreams.count >= 5 {
            let suggestion = DreamSuggestion(
                category: .lucidDream,
                title: "开始清醒梦训练",
                action: "每天进行 3 次现实检查",
                reason: "你的清醒梦比例只有\(Int(lucidRate * 100))%",
                expectedBenefit: "清醒梦可以让你在梦中保持意识，探索潜意识",
                difficulty: 2,
                estimatedTime: 1,
                tags: ["清醒梦", "现实检查"]
            )
            suggestions.append(suggestion)
        }
        
        // 如果已经有清醒梦经验
        if lucidRate >= 0.2 && lucidRate < 0.5 {
            let suggestion = DreamSuggestion(
                category: .lucidDream,
                title: "提升清醒梦质量",
                action: "尝试 WBTB 技巧（睡梦中醒来再睡）",
                reason: "你的清醒梦比例不错，可以进一步提升",
                expectedBenefit: "WBTB 是最有效的清醒梦诱导技巧之一",
                difficulty: 3,
                estimatedTime: 0,
                tags: ["清醒梦", "WBTB", "进阶技巧"]
            )
            suggestions.append(suggestion)
        }
        
        // 梦境日记建议
        if dreams.count >= 10 && lucidRate < 0.3 {
            let suggestion = DreamSuggestion(
                category: .lucidDream,
                title: "坚持梦境日记",
                action: "每天早晨记录梦境细节",
                reason: "梦境日记可以提高梦境回忆和清醒梦频率",
                expectedBenefit: "持续记录可以提高梦境意识和回忆能力",
                difficulty: 2,
                estimatedTime: 5,
                tags: ["梦境日记", "回忆训练"]
            )
            suggestions.append(suggestion)
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    /// 生成睡眠改善建议
    private func generateSleepSuggestions(limit: Int) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        let dreams = try getAllDreams()
        guard !dreams.isEmpty else { return [] }
        
        // 分析记录时间
        let recordingHours = dreams.map { Calendar.current.component(.hour, from: $0.createdAt) }
        let lateNightRecordings = recordingHours.filter { $0 >= 23 || $0 <= 6 }
        
        if Double(lateNightRecordings.count) / Double(recordingHours.count) > 0.7 {
            let suggestion = DreamSuggestion(
                category: .sleep,
                title: "调整作息时间",
                action: "尝试在晚上 11 点前入睡",
                reason: "你\(Int(Double(lateNightRecordings.count) / Double(recordingHours.count) * 100))%的梦境记录在深夜",
                expectedBenefit: "规律的作息可以改善睡眠质量和梦境回忆",
                difficulty: 3,
                estimatedTime: 0,
                tags: ["作息", "睡眠卫生"]
            )
            suggestions.append(suggestion)
        }
        
        // 睡前仪式建议
        let suggestion2 = DreamSuggestion(
            category: .sleep,
            title: "建立睡前仪式",
            action: "睡前 30 分钟进行放松活动",
            reason: "睡前仪式可以帮助大脑进入睡眠状态",
            expectedBenefit: "更好的睡眠质量和更清晰的梦境",
            difficulty: 2,
            estimatedTime: 30,
            tags: ["睡前仪式", "放松"]
        )
        suggestions.append(suggestion2)
        
        return Array(suggestions.prefix(limit))
    }
    
    /// 生成创意启发建议
    private func generateCreativitySuggestions(limit: Int) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        let dreams = try getAllDreams()
        
        // 查找创意相关的梦境
        let creativeTags = ["创意", "艺术", "音乐", "写作", "灵感", "发明", "设计"]
        let creativeDreams = dreams.filter { dream in
            dream.tags.contains { tag in creativeTags.contains(tag) }
        }
        
        if !creativeDreams.isEmpty {
            let suggestion = DreamSuggestion(
                category: .creativity,
                title: "探索创意梦境",
                action: "将创意梦境转化为实际项目",
                reason: "你已经有\(creativeDreams.count)个创意相关的梦境",
                expectedBenefit: "梦境中的创意可以成为现实中的灵感来源",
                difficulty: 3,
                estimatedTime: 30,
                tags: ["创意", "项目"]
            )
            suggestions.append(suggestion)
        }
        
        // 头脑风暴建议
        let suggestion2 = DreamSuggestion(
            category: .creativity,
            title: "梦境头脑风暴",
            action: "睡前思考一个问题，让梦境帮你解答",
            reason: "梦境可以提供独特的视角和创意解决方案",
            expectedBenefit: "利用潜意识解决现实问题",
            difficulty: 2,
            estimatedTime: 10,
            tags: ["头脑风暴", "问题解决"]
        )
        suggestions.append(suggestion2)
        
        return Array(suggestions.prefix(limit))
    }
    
    /// 生成健康建议
    private func generateHealthSuggestions(limit: Int) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        let dreams = try getAllDreams()
        
        // 分析负面情绪
        let negativeEmotions = ["anxious", "fearful", "sad", "angry"]
        let dreamsWithNegativeEmotions = dreams.filter { dream in
            dream.emotions.contains { emotion in negativeEmotions.contains(emotion.rawValue) }
        }
        
        if Double(dreamsWithNegativeEmotions.count) / Double(dreams.count) > 0.4 {
            let suggestion = DreamSuggestion(
                category: .health,
                title: "关注情绪健康",
                action: "尝试冥想或放松练习",
                reason: "你\(Int(Double(dreamsWithNegativeEmotions.count) / Double(dreams.count) * 100))%的梦境包含负面情绪",
                expectedBenefit: "改善情绪状态，减少焦虑和压力",
                difficulty: 2,
                estimatedTime: 10,
                tags: ["情绪健康", "冥想"]
            )
            suggestions.append(suggestion)
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    /// 生成社交建议
    private func generateSocialSuggestions(limit: Int) async throws -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        let dreams = try getAllDreams()
        
        // 如果有有趣的梦境
        if dreams.count >= 10 {
            let suggestion = DreamSuggestion(
                category: .social,
                title: "分享你的梦境",
                action: "选择一个有趣的梦境分享到社区",
                reason: "分享可以连接到志同道合的梦友",
                expectedBenefit: "获得反馈，发现共鸣，建立连接",
                difficulty: 2,
                estimatedTime: 5,
                tags: ["分享", "社区"]
            )
            suggestions.append(suggestion)
        }
        
        return Array(suggestions.prefix(limit))
    }
    
    // MARK: - Helper Methods
    
    private func getAllDreams() async throws -> [Dream] {
        let fetchDescriptor = FetchDescriptor<Dream>()
        return try modelContext.fetch(fetchDescriptor)
    }
}

// MARK: - 建议统计

public struct SuggestionStats: Codable {
    public var totalSuggestions: Int
    public var acceptedCount: Int
    public var completedCount: Int
    public var dismissedCount: Int
    public var acceptanceRate: Double
    public var completionRate: Double
    public var suggestionsByCategory: [SuggestionCategory: Int]
    
    public init(
        totalSuggestions: Int = 0,
        acceptedCount: Int = 0,
        completedCount: Int = 0,
        dismissedCount: Int = 0,
        acceptanceRate: Double = 0,
        completionRate: Double = 0,
        suggestionsByCategory: [SuggestionCategory: Int] = [:]
    ) {
        self.totalSuggestions = totalSuggestions
        self.acceptedCount = acceptedCount
        self.completedCount = completedCount
        self.dismissedCount = dismissedCount
        self.acceptanceRate = acceptanceRate
        self.completionRate = completionRate
        self.suggestionsByCategory = suggestionsByCategory
    }
}
