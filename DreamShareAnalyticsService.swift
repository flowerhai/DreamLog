//
//  DreamShareAnalyticsService.swift
//  DreamLog - 梦境分享数据分析服务
//
//  Created by DreamLog Team on 2026-03-15.
//  Phase 46: Dream Share Analytics - 分享数据分析与洞察
//

import Foundation
import SwiftData

@ModelActor
actor DreamShareAnalyticsService {
    
    // MARK: - Properties
    
    private let configKey = "shareAnalyticsConfig"
    private let achievementsKey = "shareAchievements"
    
    // MARK: - 统计数据计算
    
    /// 计算分享统计数据
    func calculateStatistics(period: String = "all") async throws -> ShareStatistics {
        let calendar = Calendar.current
        let now = Date()
        
        // 计算周期日期范围
        let (periodStart, periodEnd) = calculatePeriodRange(period: period, from: now)
        
        // 获取分享历史
        let shareHistory = try getShareHistory(start: periodStart, end: periodEnd)
        
        // 计算基础统计
        let totalShares = shareHistory.count
        let uniqueDreams = Set(shareHistory.map { $0.dreamId }).count
        let averagePerDay = totalShares > 0 ? Double(totalShares) / max(1, calendar.dateComponents([.day], from: periodStart, to: periodEnd).day ?? 1) : 0
        
        // 计算平台分布
        var platformBreakdown: [String: Int] = [:]
        for share in shareHistory {
            platformBreakdown[share.platform, default: 0] += 1
        }
        
        // 计算模板分布
        var templateBreakdown: [String: Int] = [:]
        for share in shareHistory {
            if let template = share.template {
                templateBreakdown[template, default: 0] += 1
            }
        }
        
        // 计算小时分布
        var hourlyDistribution: [Int: Int] = [:]
        for share in shareHistory {
            let hour = calendar.component(.hour, from: share.sharedAt)
            hourlyDistribution[hour, default: 0] += 1
        }
        
        // 计算星期分布
        var weeklyDistribution: [Int: Int] = [:]
        for share in shareHistory {
            let weekday = calendar.component(.weekday, from: share.sharedAt)
            weeklyDistribution[weekday, default: 0] += 1
        }
        
        // 计算高峰时段
        let peakHour = hourlyDistribution.max(by: { $0.value < $1.value })?.key ?? 20
        let peakWeekday = weeklyDistribution.max(by: { $0.value < $1.value })?.key ?? 1
        
        // 计算连续分享天数
        let (streakDays, longestStreak) = calculateStreaks(from: shareHistory)
        
        // 获取热门标签和情绪
        let topTags = try calculateTopTags(from: shareHistory, limit: 10)
        let topEmotions = try calculateTopEmotions(from: shareHistory, limit: 5)
        
        // 最后分享日期
        let lastShareDate = shareHistory.max(by: { $0.sharedAt < $1.sharedAt })?.sharedAt
        
        // 创建统计对象
        let statistics = ShareStatistics(
            period: period,
            periodStart: periodStart,
            periodEnd: periodEnd,
            totalShares: totalShares,
            uniqueDreamsShared: uniqueDreams,
            platformBreakdown: platformBreakdown,
            templateBreakdown: templateBreakdown,
            hourlyDistribution: hourlyDistribution,
            weeklyDistribution: weeklyDistribution,
            topSharedTags: topTags,
            topSharedEmotions: topEmotions,
            averageSharesPerDay: averagePerDay,
            peakSharingHour: peakHour,
            peakSharingWeekday: peakWeekday,
            streakDays: streakDays,
            longestStreak: longestStreak,
            lastShareDate: lastShareDate
        )
        
        // 保存到数据库
        modelContext.insert(statistics)
        try modelContext.save()
        
        return statistics
    }
    
    /// 计算周期日期范围
    private func calculatePeriodRange(period: String, from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case "daily":
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case "weekly":
            let start = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return (start, now)
        case "monthly":
            let start = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return (start, now)
        case "yearly":
            let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return (start, now)
        default: // all
            return (Date.distantPast, now)
        }
    }
    
    /// 获取分享历史
    private func getShareHistory(start: Date, end: Date) throws -> [ShareHistory] {
        let descriptor = FetchDescriptor<ShareHistory>(
            predicate: #Predicate { history in
                history.sharedAt >= start && history.sharedAt <= end
            },
            sortBy: [SortDescriptor(\.sharedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 计算连续分享天数
    private func calculateStreaks(from history: [ShareHistory]) -> (current: Int, longest: Int) {
        guard !history.isEmpty else { return (0, 0) }
        
        let calendar = Calendar.current
        let uniqueDays = Set(history.map { calendar.startOfDay(for: $0.sharedAt) })
        let sortedDays = uniqueDays.sorted()
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 1
        
        let today = calendar.startOfDay(for: Date())
        
        // 检查今天是否已分享
        if uniqueDays.contains(today) {
            currentStreak = 1
            for i in stride(from: sortedDays.count - 2, through: 0, by: -1) {
                let expectedDay = calendar.date(byAdding: .day, value: -(sortedDays.count - 1 - i), to: today)
                if expectedDay == sortedDays[i] {
                    currentStreak += 1
                } else {
                    break
                }
            }
        }
        
        // 计算最长连续
        for i in 1..<sortedDays.count {
            let prevDay = calendar.date(byAdding: .day, value: -1, to: sortedDays[i])
            if prevDay == sortedDays[i - 1] {
                tempStreak += 1
            } else {
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 1
            }
        }
        longestStreak = max(longestStreak, tempStreak)
        
        return (currentStreak, longestStreak)
    }
    
    /// 计算热门标签
    private func calculateTopTags(from history: [ShareHistory], limit: Int) throws -> [String] {
        var tagCounts: [String: Int] = [:]
        
        for share in history {
            let descriptor = FetchDescriptor<Dream>(
                predicate: #Predicate { dream in dream.id == share.dreamId }
            )
            if let dream = try modelContext.fetch(descriptor).first {
                for tag in dream.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
        }
        
        return tagCounts.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
    
    /// 计算热门情绪
    private func calculateTopEmotions(from history: [ShareHistory], limit: Int) throws -> [String] {
        var emotionCounts: [String: Int] = [:]
        
        for share in history {
            let descriptor = FetchDescriptor<Dream>(
                predicate: #Predicate { dream in dream.id == share.dreamId }
            )
            if let dream = try modelContext.fetch(descriptor).first {
                for emotion in dream.emotions {
                    emotionCounts[emotion.rawValue, default: 0] += 1
                }
            }
        }
        
        return emotionCounts.sorted { $0.value > $1.value }.prefix(limit).map { $0.key }
    }
    
    // MARK: - 智能洞察生成
    
    /// 生成分享洞察
    func generateInsights(from statistics: ShareStatistics) async -> [ShareInsight] {
        var insights: [ShareInsight] = []
        
        // 最佳分享时间洞察
        if statistics.totalShares >= 5 {
            let hourStr = formatHour(statistics.peakSharingHour)
            insights.append(ShareInsight(
                type: .bestTime,
                title: "最佳分享时间",
                description: "您最常在第\(statistics.peakSharingHour)点分享梦境",
                suggestion: "建议在\(hourStr)分享，这是您的活跃时段",
                confidence: 0.85,
                dataPoints: statistics.totalShares
            ))
        }
        
        // 热门平台洞察
        if let topPlatform = statistics.platformBreakdown.max(by: { $0.value < $1.value }) {
            if let platform = SharePlatform(rawValue: topPlatform.key) {
                let percentage = Int(Double(topPlatform.value) / Double(max(1, statistics.totalShares)) * 100)
                insights.append(ShareInsight(
                    type: .popularPlatform,
                    title: "热门分享平台",
                    description: "\(platform.displayName)是您最常用的分享平台",
                    suggestion: "您在\(platform.displayName)分享了\(topPlatform.value)次，占\(percentage)%",
                    confidence: 0.9,
                    dataPoints: topPlatform.value
                ))
            }
        }
        
        // 连续分享成就
        if statistics.streakDays >= 3 {
            insights.append(ShareInsight(
                type: .milestone,
                title: "连续分享成就",
                description: "您已连续分享\(statistics.streakDays)天",
                suggestion: statistics.streakDays >= 7 ? "太棒了！保持这个好习惯！" : "继续加油，离 7 天成就更近了！",
                confidence: 1.0,
                dataPoints: statistics.streakDays
            ))
        }
        
        // 改进建议
        if statistics.averageSharesPerDay < 0.5 && statistics.totalShares > 0 {
            insights.append(ShareInsight(
                type: .improvement,
                title: "分享频率建议",
                description: "您的分享频率较低",
                suggestion: "尝试每天分享一个精彩梦境，让更多人看到",
                confidence: 0.7,
                dataPoints: statistics.totalShares
            ))
        }
        
        // 热门标签洞察
        if !statistics.topSharedTags.isEmpty {
            insights.append(ShareInsight(
                type: .trendingTag,
                title: "热门标签",
                description: "您分享最多的标签：\(statistics.topSharedTags.prefix(3).joined(separator: "、"))",
                suggestion: "这些主题的内容更受欢迎，可以继续分享类似梦境",
                confidence: 0.75,
                dataPoints: statistics.topSharedTags.count
            ))
        }
        
        return insights
    }
    
    /// 格式化小时
    private func formatHour(_ hour: Int) -> String {
        if hour >= 5 && hour < 12 { return "早上\(hour)点" }
        if hour >= 12 && hour < 18 { return "下午\(hour - 12)点" }
        if hour >= 18 && hour < 23 { return "晚上\(hour - 12)点" }
        return "凌晨\(hour)点"
    }
    
    // MARK: - 成就系统
    
    /// 预定义成就列表
    private func predefinedAchievements() -> [ShareAchievement] {
        [
            ShareAchievement(
                achievementId: "first_share",
                name: "首次分享",
                description: "完成第一次梦境分享",
                icon: "star",
                category: .count,
                requirement: 1
            ),
            ShareAchievement(
                achievementId: "share_10",
                name: "分享达人",
                description: "累计分享 10 次梦境",
                icon: "star.fill",
                category: .count,
                requirement: 10
            ),
            ShareAchievement(
                achievementId: "share_50",
                name: "分享大师",
                description: "累计分享 50 次梦境",
                icon: "star.circle.fill",
                category: .count,
                requirement: 50
            ),
            ShareAchievement(
                achievementId: "share_100",
                name: "分享传奇",
                description: "累计分享 100 次梦境",
                icon: "crown.fill",
                category: .count,
                requirement: 100
            ),
            ShareAchievement(
                achievementId: "streak_7",
                name: "持之以恒",
                description: "连续分享 7 天",
                icon: "flame.fill",
                category: .streak,
                requirement: 7
            ),
            ShareAchievement(
                achievementId: "streak_30",
                name: "坚持不懈",
                description: "连续分享 30 天",
                icon: "fire.fill",
                category: .streak,
                requirement: 30
            ),
            ShareAchievement(
                achievementId: "multi_platform",
                name: "多平台达人",
                description: "在 5 个不同平台分享",
                icon: "globe",
                category: .platform,
                requirement: 5
            ),
            ShareAchievement(
                achievementId: "night_owl",
                name: "夜猫子",
                description: "在深夜 (23-5 点) 分享 10 次",
                icon: "moon.stars.fill",
                category: .time,
                requirement: 10
            )
        ]
    }
    
    /// 获取所有成就
    func getAllAchievements() async throws -> [ShareAchievement] {
        let descriptor = FetchDescriptor<ShareAchievement>()
        var achievements = try modelContext.fetch(descriptor)
        
        // 如果没有成就，创建预定义成就
        if achievements.isEmpty {
            achievements = predefinedAchievements()
            for achievement in achievements {
                modelContext.insert(achievement)
            }
            try modelContext.save()
        }
        
        return achievements
    }
    
    /// 更新成就进度
    func updateAchievementProgress(totalShares: Int, streakDays: Int, platforms: Set<String>) async throws {
        let achievements = try getAllAchievements()
        var hasChanges = false
        
        for achievement in achievements {
            guard !achievement.isUnlocked else { continue }
            
            var newProgress = 0
            
            switch achievement.category {
            case .count:
                newProgress = totalShares
            case .streak:
                newProgress = streakDays
            case .platform:
                newProgress = platforms.count
            case .variety:
                newProgress = totalShares // 简化处理
            case .time:
                newProgress = totalShares // 需要更复杂的逻辑
            case .special:
                newProgress = totalShares
            }
            
            if newProgress != achievement.progress {
                achievement.progress = newProgress
                hasChanges = true
                
                // 检查是否解锁
                if newProgress >= achievement.requirement {
                    achievement.isUnlocked = true
                    achievement.unlockedAt = Date()
                    achievement.shareCount = totalShares
                }
            }
        }
        
        if hasChanges {
            try modelContext.save()
        }
    }
    
    // MARK: - 趋势分析
    
    /// 获取分享趋势
    func getShareTrend(days: Int = 30) async throws -> [ShareTrendPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        var trendPoints: [ShareTrendPoint] = []
        
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) ?? endDate
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let shares = try getShareHistory(start: dayStart, end: dayEnd)
            let uniqueDreams = Set(shares.map { $0.dreamId }).count
            
            // 找出当天最常用的平台
            var platformCounts: [String: Int] = [:]
            for share in shares {
                platformCounts[share.platform, default: 0] += 1
            }
            let topPlatform = platformCounts.max(by: { $0.value < $1.value })?.key ?? ""
            
            trendPoints.append(ShareTrendPoint(
                date: date,
                shareCount: shares.count,
                uniqueDreams: uniqueDreams,
                topPlatform: topPlatform
            ))
        }
        
        return trendPoints.reversed()
    }
    
    // MARK: - 平台使用详情
    
    /// 获取平台使用详情
    func getPlatformUsageDetails() async throws -> [PlatformUsageDetail] {
        let statistics = try calculateStatistics()
        var details: [PlatformUsageDetail] = []
        
        let totalShares = statistics.totalShares
        
        for platform in SharePlatform.allCases {
            let count = statistics.platformBreakdown[platform.rawValue] ?? 0
            let percentage = totalShares > 0 ? Double(count) / Double(totalShares) * 100 : 0
            
            // 获取该平台的分享历史
            let descriptor = FetchDescriptor<ShareHistory>(
                predicate: #Predicate { history in history.platform == platform.rawValue },
                sortBy: [SortDescriptor(\.sharedAt, order: .reverse)]
            )
            let platformShares = try modelContext.fetch(descriptor)
            
            let lastUsed = platformShares.first?.sharedAt
            let averagePerWeek = totalShares > 0 ? Double(count) / max(1, Double(totalShares) / 7) : 0
            
            // 计算常用模板
            var templateCounts: [String: Int] = [:]
            for share in platformShares {
                if let template = share.template {
                    templateCounts[template, default: 0] += 1
                }
            }
            let favoriteTemplates = templateCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
            
            details.append(PlatformUsageDetail(
                platform: platform,
                shareCount: count,
                percentage: percentage,
                lastUsed: lastUsed,
                favoriteTemplates: favoriteTemplates,
                averageSharesPerWeek: averagePerWeek
            ))
        }
        
        return details.sorted { $0.shareCount > $1.shareCount }
    }
    
    // MARK: - 配置管理
    
    /// 获取配置
    func getConfig() -> ShareAnalyticsConfig {
        // 简化实现，返回默认配置
        return .default
    }
    
    /// 保存配置
    func saveConfig(_ config: ShareAnalyticsConfig) {
        // 简化实现
    }
}
