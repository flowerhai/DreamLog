//
//  DreamSmartInsightsService.swift
//  DreamLog
//
//  Phase 78: Smart Dream Insights & Notifications
//  智能梦境洞察与通知服务
//

import Foundation
import SwiftData
import UserNotifications
import NaturalLanguage

@available(iOS 17.0, *)
@ModelActor
public actor DreamSmartInsightsService {
    
    // MARK: - Properties
    
    public let modelContext: ModelContext
    private let notificationCenter: UNUserNotificationCenter
    
    // MARK: - Initialization
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.notificationCenter = UNUserNotificationCenter.current()
    }
    
    // MARK: - 洞察生成核心
    
    /// 生成智能洞察
    public func generateInsights() async throws -> [DreamSmartInsight] {
        guard let settings = try getSettings(), settings.enabled else {
            return []
        }
        
        // 检查免打扰时间
        if isQuietHours(settings: settings) {
            return []
        }
        
        // 检查每日限制
        if shouldResetDailyCount(settings: settings) {
            settings.dailyInsightCount = 0
            settings.lastResetDate = Date()
        }
        
        guard settings.dailyInsightCount < settings.config.maxDailyInsights else {
            return []
        }
        
        var newInsights: [DreamSmartInsight] = []
        
        // 1. 模式发现洞察
        if let patternInsight = try await generatePatternInsight(config: settings.config) {
            newInsights.append(patternInsight)
        }
        
        // 2. 情绪趋势洞察
        if let emotionInsight = try await generateEmotionTrendInsight(config: settings.config) {
            newInsights.append(emotionInsight)
        }
        
        // 3. 主题演变洞察
        if let themeInsight = try await generateThemeEvolutionInsight(config: settings.config) {
            newInsights.append(themeInsight)
        }
        
        // 4. 清醒梦机会洞察
        if let lucidInsight = try await generateLucidOpportunityInsight(config: settings.config) {
            newInsights.append(lucidInsight)
        }
        
        // 5. 睡眠质量洞察
        if let sleepInsight = try await generateSleepQualityInsight(config: settings.config) {
            newInsights.append(sleepInsight)
        }
        
        // 6. 创意启发洞察
        if let creativeInsight = try await generateCreativeInsight(config: settings.config) {
            newInsights.append(creativeInsight)
        }
        
        // 7. 里程碑洞察
        if let milestoneInsight = try await generateMilestoneInsight(config: settings.config) {
            newInsights.append(milestoneInsight)
        }
        
        // 过滤置信度并保存
        let validInsights = newInsights.filter { $0.confidence >= settings.config.minConfidence }
        
        for insight in validInsights {
            modelContext.insert(insight)
            settings.dailyInsightCount += 1
            
            // 高优先级发送通知
            if insight.priority == .high || insight.priority == .urgent {
                if settings.config.notifyOnHighPriority {
                    await sendNotification(for: insight)
                }
            }
        }
        
        settings.lastCheckDate = Date()
        
        try modelContext.save()
        
        return validInsights
    }
    
    // MARK: - 各类洞察生成
    
    /// 生成模式发现洞察
    private func generatePatternInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            }
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        guard dreams.count >= 10 else { return nil }
        
        // 分析标签频率
        var tagFrequency: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagFrequency[tag, default: 0] += 1
            }
        }
        
        // 找出重复出现的标签（>= 3 次）
        let recurringTags = tagFrequency.filter { $0.value >= 3 }
        guard !recurringTags.isEmpty else { return nil }
        
        let topTag = recurringTags.max(by: { $0.value < $1.value })!
        let confidence = min(Double(topTag.value) / Double(dreams.count) * 2, 0.95)
        
        return DreamSmartInsight(
            title: "梦境模式发现",
            content: "过去 30 天，「\(topTag.key)」是你梦境中出现最频繁的主题（\(topTag.value) 次）。这可能反映了你当前生活中的关注点或潜意识中的持续思考。",
            type: DreamInsightType.allTypes[0], // 模式发现
            priority: topTag.value >= 5 ? .high : .medium,
            confidence: confidence,
            relatedDreamIds: dreams.filter { $0.tags.contains(topTag.key) }.map { $0.id },
            tags: [topTag.key],
            actionSuggestion: "尝试记录这些梦境发生时的心情和环境，寻找更深层的联系。"
        )
    }
    
    /// 生成情绪趋势洞察
    private func generateEmotionTrendInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= Calendar.current.date(byAdding: .day, value: -14, to: Date())!
            },
            sortBy: [SortDescriptor(\.date)]
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        guard dreams.count >= 7 else { return nil }
        
        // 分析情绪变化
        var emotionTrend: [String: [Int]] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                if emotionTrend[emotion] == nil {
                    emotionTrend[emotion] = []
                }
                emotionTrend[emotion]?.append(1)
            }
        }
        
        // 找出主导情绪
        guard let dominantEmotion = emotionTrend.max(by: { $0.value.count < $1.value.count }) else {
            return nil
        }
        
        let percentage = Double(dominantEmotion.value.count) / Double(dreams.count) * 100
        guard percentage >= 40 else { return nil }
        
        return DreamSmartInsight(
            title: "情绪趋势洞察",
            content: "过去两周，「\(dominantEmotion.key)」是你梦境中的主导情绪（占比 \(Int(percentage))%）。这可能反映了你当前的情绪状态或心理压力。",
            type: DreamInsightType.allTypes[1], // 情绪趋势
            priority: percentage >= 60 ? .high : .medium,
            confidence: percentage / 100,
            relatedDreamIds: dreams.filter { $0.emotions.contains(dominantEmotion.key) }.map { $0.id },
            tags: [dominantEmotion.key],
            actionSuggestion: percentage >= 60 
                ? "建议关注这种情绪的来源，考虑通过冥想或写日记来探索。"
                : "继续观察情绪变化，记录触发这种情绪的梦境内容。"
        )
    }
    
    /// 生成主题演变洞察
    private func generateThemeEvolutionInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= Calendar.current.date(byAdding: .day, value: -60, to: Date())!
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        guard dreams.count >= 20 else { return nil }
        
        // 比较前后 30 天的主题变化
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        
        let recentDreams = dreams.filter { $0.date >= thirtyDaysAgo }
        let olderDreams = dreams.filter { $0.date < thirtyDaysAgo }
        
        var recentTags = Set<String>()
        var olderTags = Set<String>()
        
        for dream in recentDreams {
            recentTags.formUnion(dream.tags)
        }
        for dream in olderDreams {
            olderTags.formUnion(dream.tags)
        }
        
        // 找出新出现的主题
        let newThemes = recentTags.subtracting(olderTags)
        guard !newThemes.isEmpty else { return nil }
        
        return DreamSmartInsight(
            title: "主题演变洞察",
            content: "最近 30 天，你的梦境中出现了新的主题：\(newThemes.joined(separator: "、"))。这可能意味着你的生活重心或关注点正在发生变化。",
            type: DreamInsightType.allTypes[2], // 主题演变
            priority: .medium,
            confidence: 0.75,
            relatedDreamIds: recentDreams.filter { dream in
                !dream.tags.filter { newThemes.contains($0) }.isEmpty
            }.map { $0.id },
            tags: Array(newThemes),
            actionSuggestion: "思考这些新主题与现实生活的关联，记录触发这些梦境的事件。"
        )
    }
    
    /// 生成清醒梦机会洞察
    private func generateLucidOpportunityInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            }
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        guard dreams.count >= 10 else { return nil }
        
        let lucidDreams = dreams.filter { $0.isLucid }
        let lucidRate = Double(lucidDreams.count) / Double(dreams.count)
        
        // 如果清醒梦比例较低，提供建议
        guard lucidRate < 0.3 else { return nil }
        
        // 分析最佳清醒梦时间
        var hourFrequency: [Int: Int] = [:]
        for dream in lucidDreams {
            let hour = Calendar.current.component(.hour, from: dream.date)
            hourFrequency[hour, default: 0] += 1
        }
        
        let bestHour = hourFrequency.max(by: { $0.value < $1.value })?.key ?? 6
        
        return DreamSmartInsight(
            title: "清醒梦机会",
            content: "你的清醒梦比例为 \(Int(lucidRate * 100))%。数据显示你在早上 \(bestHour) 点左右记录的梦境更容易成为清醒梦。",
            type: DreamInsightType.allTypes[3], // 清醒梦机会
            priority: .medium,
            confidence: 0.7,
            relatedDreamIds: lucidDreams.map { $0.id },
            tags: ["清醒梦", "机会"],
            actionSuggestion: "尝试在睡前进行现实检查练习，并在早上设置闹钟进行 WBTB（醒来再睡）技巧。"
        )
    }
    
    /// 生成睡眠质量洞察
    private func generateSleepQualityInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        // 检查是否有健康数据
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            }
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        guard dreams.count >= 5 else { return nil }
        
        let avgClarity = dreams.map { $0.clarity }.reduce(0, +) / dreams.count
        let avgIntensity = dreams.map { $0.intensity }.reduce(0, +) / dreams.count
        
        // 清晰度低可能表示睡眠质量差
        guard avgClarity < 3 else { return nil }
        
        return DreamSmartInsight(
            title: "睡眠质量提醒",
            content: "过去一周，你的梦境平均清晰度为 \(avgClarity, specifier: "%.1f")/5，低于正常水平。这可能与睡眠质量不佳有关。",
            type: DreamInsightType.allTypes[4], // 睡眠质量
            priority: avgClarity < 2 ? .high : .medium,
            confidence: 0.65,
            relatedDreamIds: dreams.map { $0.id },
            tags: ["睡眠", "健康"],
            actionSuggestion: "尝试改善睡眠环境，保持规律作息，睡前避免使用电子设备。"
        )
    }
    
    /// 生成创意启发洞察
    private func generateCreativeInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { dream in
                dream.date >= Calendar.current.date(byAdding: .day, value: -14, to: Date())!
                && dream.clarity >= 4
            }
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        guard dreams.count >= 3 else { return nil }
        
        // 找出高清晰度的梦境中的创意元素
        let creativeTags = ["创意", "艺术", "音乐", "写作", "发明", "灵感", "新奇", "探索"]
        let creativeDreams = dreams.filter { dream in
            !dream.tags.filter { creativeTags.contains($0) }.isEmpty
        }
        
        guard !creativeDreams.isEmpty else { return nil }
        
        return DreamSmartInsight(
            title: "创意灵感",
            content: "你最近有 \(creativeDreams.count) 个高清晰度的梦境包含创意元素。这些梦境可能是绝佳的创作灵感来源！",
            type: DreamInsightType.allTypes[5], // 创意启发
            priority: .medium,
            confidence: 0.8,
            relatedDreamIds: creativeDreams.map { $0.id },
            tags: creativeDreams.flatMap { $0.tags }.uniqued().prefix(5).map { String($0) },
            actionSuggestion: "考虑将这些梦境内容整理成创作素材，或尝试在醒来后立即记录细节。"
        )
    }
    
    /// 生成里程碑洞察
    private func generateMilestoneInsight(config: InsightGenerationConfig) async throws -> DreamSmartInsight? {
        let fetchDescriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        let dreams = try modelContext.fetch(fetchDescriptor)
        let totalDreams = dreams.count
        
        // 检查里程碑（100, 200, 500, 1000...）
        let milestones = [100, 200, 500, 1000, 2000, 5000]
        guard let nextMilestone = milestones.first(where: { totalDreams >= $0 && totalDreams < $0 + 10 }) else {
            return nil
        }
        
        // 避免重复通知
        let existingMilestoneInsights = try modelContext.fetch(
            FetchDescriptor<DreamSmartInsight>(
                predicate: #Predicate { insight in
                    insight.type.name == "里程碑" &&
                    insight.createdAt >= Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                }
            )
        )
        guard existingMilestoneInsights.isEmpty else { return nil }
        
        return DreamSmartInsight(
            title: "🎉 里程碑达成！",
            content: "恭喜你已记录 \(totalDreams) 个梦境！持续记录是探索潜意识的关键。",
            type: DreamInsightType.allTypes[7], // 里程碑
            priority: .high,
            confidence: 1.0,
            relatedDreamIds: Array(dreams.prefix(10).map { $0.id }),
            tags: ["里程碑", "成就"],
            actionSuggestion: "回顾你的梦境旅程，看看有哪些有趣的模式和变化！"
        )
    }
    
    // MARK: - 通知管理
    
    /// 发送通知
    private func sendNotification(for insight: DreamSmartInsight) async {
        do {
            let content = UNMutableNotificationContent()
            content.title = insight.title
            content.body = String(insight.content.prefix(100)) + (insight.content.count > 100 ? "..." : "")
            content.userInfo = ["insightId": insight.id.uuidString]
            content.categoryIdentifier = "DREAM_INSIGHT"
            
            // 根据优先级设置声音
            if insight.priority == .urgent {
                content.sound = .defaultCritical
            } else {
                content.sound = .default
            }
            
            let request = UNNotificationRequest(
                identifier: "insight_\(insight.id.uuidString)",
                content: content,
                trigger: nil // 立即发送
            )
            
            try await notificationCenter.add(request)
            
            // 标记已发送
            insight.notificationSent = true
            try modelContext.save()
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
    
    // MARK: - 辅助方法
    
    /// 获取设置
    private func getSettings() throws -> DreamSmartNotificationSettings? {
        let fetchDescriptor = FetchDescriptor<DreamSmartNotificationSettings>()
        let settings = try modelContext.fetch(fetchDescriptor)
        return settings.first
    }
    
    /// 检查是否在免打扰时间
    private func isQuietHours(settings: DreamSmartNotificationSettings) -> Bool {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let start = settings.config.quietHoursStart
        let end = settings.config.quietHoursEnd
        
        if start > end {
            // 跨天情况（如 23:00 - 08:00）
            return currentHour >= start || currentHour < end
        } else {
            return currentHour >= start && currentHour < end
        }
    }
    
    /// 检查是否需要重置每日计数
    private func shouldResetDailyCount(settings: DreamSmartNotificationSettings) -> Bool {
        let now = Date()
        let lastReset = settings.lastResetDate
        return Calendar.current.isDateInToday(now) && !Calendar.current.isDateInToday(lastReset)
    }
    
    // MARK: - 查询方法
    
    /// 获取所有洞察
    public func getAllInsights(limit: Int = 50) throws -> [DreamSmartInsight] {
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
            fetchLimit: limit
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 获取未读洞察
    public func getUnreadInsights() throws -> [DreamSmartInsight] {
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { insight in
                !insight.isRead
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 获取已保存的洞察
    public func getSavedInsights() throws -> [DreamSmartInsight] {
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { insight in
                insight.isSaved
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(fetchDescriptor)
    }
    
    /// 获取洞察统计
    public func getStatistics() throws -> InsightStatistics {
        let allInsights = try getAllInsights(limit: 1000)
        
        var byType: [String: Int] = [:]
        var byPriority: [String: Int] = [:]
        var weeklyTrend: [Date: Int] = [:]
        var totalConfidence: Double = 0
        
        for insight in allInsights {
            byType[insight.type.name, default: 0] += 1
            byPriority[insight.priority.displayName, default: 0] += 1
            totalConfidence += insight.confidence
            
            let weekStart = Calendar.current.startOfDay(for: insight.createdAt)
            weeklyTrend[weekStart, default: 0] += 1
        }
        
        let mostCommonType = byType.max(by: { $0.value < $1.value })?.key
        let avgConfidence = allInsights.isEmpty ? 0 : totalConfidence / Double(allInsights.count)
        
        return InsightStatistics(
            totalInsights: allInsights.count,
            unreadCount: try getUnreadInsights().count,
            savedCount: try getSavedInsights().count,
            byType: byType,
            byPriority: byPriority,
            weeklyTrend: weeklyTrend,
            mostCommonType: mostCommonType,
            averageConfidence: avgConfidence
        )
    }
    
    /// 标记洞察为已读
    public func markAsRead(insightId: UUID) throws {
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { insight in
                insight.id == insightId
            }
        )
        let insights = try modelContext.fetch(fetchDescriptor)
        if let insight = insights.first {
            insight.isRead = true
            try modelContext.save()
        }
    }
    
    /// 标记所有洞察为已读
    public func markAllAsRead() throws {
        let insights = try getAllInsights(limit: 1000)
        for insight in insights {
            insight.isRead = true
        }
        try modelContext.save()
    }
    
    /// 保存/取消保存洞察
    public func toggleSave(insightId: UUID) throws {
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { insight in
                insight.id == insightId
            }
        )
        let insights = try modelContext.fetch(fetchDescriptor)
        if let insight = insights.first {
            insight.isSaved.toggle()
            try modelContext.save()
        }
    }
    
    /// 删除洞察
    public func deleteInsight(insightId: UUID) throws {
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { insight in
                insight.id == insightId
            }
        )
        let insights = try modelContext.fetch(fetchDescriptor)
        if let insight = insights.first {
            modelContext.delete(insight)
            try modelContext.save()
        }
    }
    
    /// 更新设置
    public func updateSettings(enabled: Bool? = nil, config: InsightGenerationConfig? = nil) throws {
        var settings = try getSettings()
        
        if settings == nil {
            settings = DreamSmartNotificationSettings()
            modelContext.insert(settings!)
        }
        
        if let enabled = enabled {
            settings!.enabled = enabled
        }
        if let config = config {
            settings!.config = config
        }
        
        try modelContext.save()
    }
}
