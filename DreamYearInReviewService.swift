//
//  DreamYearInReviewService.swift
//  DreamLog - 梦境年度回顾核心服务
//  Phase 63: Dream Year in Review (梦境年度回顾)
//
//  Created by DreamLog Team on 2026-03-18.
//

import Foundation
import SwiftData
import NaturalLanguage

@ModelActor
actor DreamYearInReviewService {
    
    // MARK: - 属性
    
    private let modelContainer: ModelContainer
    private var config: YearInReviewConfig
    
    // MARK: - 初始化
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.config = .default
        self.modelExecutor = DefaultModelExecutor(modelContainer: modelContainer)
    }
    
    // MARK: - 生成年度回顾
    
    /// 生成指定年份的年度回顾
    func generateYearInReview(for year: Int) async throws -> DreamYearInReview {
        // 获取该年份所有梦境
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endDate = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else {
            throw YearInReviewError.invalidDateRange
        }
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { dream in
                dream.date >= startDate && dream.date < endDate
            }
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        // 如果没有梦境，返回空回顾
        if dreams.isEmpty {
            return createEmptyYearInReview(for: year)
        }
        
        // 计算各项统计
        let stats = calculateStatistics(from: dreams)
        let insights = generateAIInsights(from: dreams, stats: stats)
        let shareCards = generateShareCards(for: year, stats: stats, insights: insights)
        
        // 创建年度回顾
        let yearInReview = DreamYearInReview(
            year: year,
            totalDreams: stats.totalDreams,
            lucidDreams: stats.lucidDreams,
            averageClarity: stats.averageClarity,
            averageIntensity: stats.averageIntensity,
            totalDreamTime: stats.totalDreamTime,
            longestStreak: stats.longestStreak,
            currentStreak: stats.currentStreak,
            totalRecordDays: stats.totalRecordDays,
            topEmotion: stats.topEmotion,
            emotionDistribution: stats.emotionDistribution,
            topTags: stats.topTags,
            tagCloud: stats.tagCloud,
            bestDayOfWeek: stats.bestDayOfWeek,
            bestTimeOfDay: stats.bestTimeOfDay,
            dreamsByMonth: stats.dreamsByMonth,
            highlightDreamIds: stats.highlightDreamIds,
            clearestDreamId: stats.clearestDreamId,
            mostLucidMonth: stats.mostLucidMonth,
            aiInsights: insights,
            yearTheme: generateYearTheme(from: dreams, stats: stats),
            yearKeyword: generateYearKeyword(from: dreams, stats: stats),
            isShareable: true,
            shareCardIds: shareCards.map { $0.id }
        )
        
        // 保存分享卡片
        for card in shareCards {
            modelContext.insert(card)
        }
        
        // 保存年度回顾
        modelContext.insert(yearInReview)
        try modelContext.save()
        
        // 同时生成 12 个月的月度回顾
        try await generateMonthlyReviews(for: year, dreams: dreams)
        
        return yearInReview
    }
    
    // MARK: - 获取年度回顾
    
    /// 获取指定年份的年度回顾
    func getYearInReview(for year: Int) async throws -> DreamYearInReview? {
        let descriptor = FetchDescriptor<DreamYearInReview>(
            predicate: #Predicate<DreamYearInReview> { review in
                review.year == year
            }
        )
        
        let reviews = try modelContext.fetch(descriptor)
        return reviews.first
    }
    
    /// 获取所有年度回顾
    func getAllYearInReviews() async throws -> [DreamYearInReview] {
        let descriptor = FetchDescriptor<DreamYearInReview>(
            sortBy: [SortDescriptor(\.year, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取最新年度回顾
    func getLatestYearInReview() async throws -> DreamYearInReview? {
        let descriptor = FetchDescriptor<DreamYearInReview>(
            sortBy: [SortDescriptor(\.year, order: .reverse)],
            fetchLimit: 1
        )
        let reviews = try modelContext.fetch(descriptor)
        return reviews.first
    }
    
    // MARK: - 获取月度回顾
    
    /// 获取指定年月的月度回顾
    func getMonthInReview(year: Int, month: Int) async throws -> DreamMonthInReview? {
        let descriptor = FetchDescriptor<DreamMonthInReview>(
            predicate: #Predicate<DreamMonthInReview> { review in
                review.year == year && review.month == month
            }
        )
        
        let reviews = try modelContext.fetch(descriptor)
        return reviews.first
    }
    
    /// 获取指定年份的所有月度回顾
    func getMonthInReviews(for year: Int) async throws -> [DreamMonthInReview] {
        let descriptor = FetchDescriptor<DreamMonthInReview>(
            predicate: #Predicate<DreamMonthInReview> { review in
                review.year == year
            },
            sortBy: [SortDescriptor(\.month)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 获取分享卡片
    
    /// 获取年度回顾的分享卡片
    func getShareCards(for year: Int) async throws -> [YearInReviewShareCard] {
        let descriptor = FetchDescriptor<YearInReviewShareCard>(
            predicate: #Predicate<YearInReviewShareCard> { card in
                card.year == year
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 分享功能
    
    /// 记录分享
    func recordShare(cardId: UUID) async throws {
        let descriptor = FetchDescriptor<YearInReviewShareCard>(
            predicate: #Predicate<YearInReviewShareCard> { card in
                card.id == cardId
            }
        )
        
        if var card = try modelContext.fetch(descriptor).first {
            card.shareCount += 1
            card.lastSharedAt = Date()
            try modelContext.save()
        }
    }
    
    // MARK: - 删除功能
    
    /// 删除指定年份的年度回顾
    func deleteYearInReview(for year: Int) async throws {
        // 删除年度回顾
        let reviewDescriptor = FetchDescriptor<DreamYearInReview>(
            predicate: #Predicate<DreamYearInReview> { review in
                review.year == year
            }
        )
        let reviews = try modelContext.fetch(reviewDescriptor)
        for review in reviews {
            modelContext.delete(review)
        }
        
        // 删除月度回顾
        let monthDescriptor = FetchDescriptor<DreamMonthInReview>(
            predicate: #Predicate<DreamMonthInReview> { review in
                review.year == year
            }
        )
        let months = try modelContext.fetch(monthDescriptor)
        for month in months {
            modelContext.delete(month)
        }
        
        // 删除分享卡片
        let cardDescriptor = FetchDescriptor<YearInReviewShareCard>(
            predicate: #Predicate<YearInReviewShareCard> { card in
                card.year == year
            }
        )
        let cards = try modelContext.fetch(cardDescriptor)
        for card in cards {
            modelContext.delete(card)
        }
        
        try modelContext.save()
    }
    
    // MARK: - 自动检查与生成
    
    /// 检查是否需要生成新年回顾
    func checkAndGenerateNewYearReview() async throws -> DreamYearInReview? {
        let currentYear = Calendar.current.component(.year, from: Date())
        let previousYear = currentYear - 1
        
        // 检查是否已存在
        if let existing = try await getYearInReview(for: previousYear) {
            return existing
        }
        
        // 检查梦境数据是否足够（至少 1 个梦境）
        let calendar = Calendar.current
        // Calendar.date(from:...) with valid components never fails
        let startDate = calendar.date(from: DateComponents(year: previousYear, month: 1, day: 1)) ?? Date()
        let endDate = calendar.date(from: DateComponents(year: previousYear + 1, month: 1, day: 1)) ?? startDate
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { dream in
                dream.date >= startDate && dream.date < endDate
            },
            fetchLimit: 1
        )
        
        let dreams = try modelContext.fetch(descriptor)
        if dreams.isEmpty {
            return nil
        }
        
        // 生成年度回顾
        return try await generateYearInReview(for: previousYear)
    }
    
    // MARK: - 私有方法
    
    /// 创建空的年度回顾（无梦境数据）
    private func createEmptyYearInReview(for year: Int) -> DreamYearInReview {
        DreamYearInReview(
            year: year,
            aiInsights: [
                YearInReviewInsight(
                    type: .suggestion,
                    title: "开始你的梦境之旅",
                    description: "\(year) 年还没有记录梦境哦。新的一年，从记录第一个梦开始吧！",
                    icon: "🌙",
                    actionSuggestion: "今晚睡前设置记录提醒"
                )
            ],
            yearTheme: "新的开始",
            yearKeyword: "启程"
        )
    }
    
    /// 计算统计数据
    private func calculateStatistics(from dreams: [Dream]) -> YearInReviewStatistics {
        var stats = YearInReviewStatistics()
        
        stats.totalDreams = dreams.count
        stats.lucidDreams = dreams.filter { $0.isLucid }.count
        stats.averageClarity = dreams.isEmpty ? 0 : dreams.map { Double($0.clarity) }.reduce(0, +) / Double(dreams.count)
        stats.averageIntensity = dreams.isEmpty ? 0 : dreams.map { Double($0.intensity) }.reduce(0, +) / Double(dreams.count)
        
        // 计算情绪分布
        var emotionCount: [String: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionCount[emotion.rawValue, default: 0] += 1
            }
        }
        stats.emotionDistribution = emotionCount
        stats.topEmotion = emotionCount.max(by: { $0.value < $1.value })?.key ?? ""
        
        // 计算标签
        var tagCount: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCount[tag, default: 0] += 1
            }
        }
        stats.tagCloud = tagCount
        stats.topTags = tagCount.sorted { $0.value > $1.value }.prefix(10).map { $0.key }
        
        // 计算连续记录
        let sortedDreams = dreams.sorted { $0.date < $1.date }
        var longestStreak = 0
        var currentStreak = 0
        var recordDays: Set<String> = Set()
        
        let calendar = Calendar.current
        for dream in sortedDreams {
            let dateStr = calendar.string(from: .day, in: dream.date)
            recordDays.insert(dateStr)
        }
        
        stats.totalRecordDays = recordDays.count
        
        // 简化计算连续记录
        if !recordDays.isEmpty {
            longestStreak = calculateLongestStreak(from: recordDays, calendar: calendar)
            currentStreak = calculateCurrentStreak(from: recordDays, calendar: calendar)
        }
        stats.longestStreak = longestStreak
        stats.currentStreak = currentStreak
        
        // 计算月度分布
        var monthCount: [Int: Int] = [:]
        for dream in dreams {
            let month = calendar.component(.month, from: dream.date)
            monthCount[month, default: 0] += 1
        }
        stats.dreamsByMonth = monthCount
        
        // 计算最佳日期和时间
        var dayOfWeekCount: [String: Int] = [:]
        var timeOfDayCount: [String: Int] = [:]
        
        for dream in dreams {
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: dream.date) - 1]
            dayOfWeekCount[weekday, default: 0] += 1
            
            let hour = calendar.component(.hour, from: dream.date)
            let timeOfDay: String
            if hour >= 5 && hour < 12 {
                timeOfDay = "早晨"
            } else if hour >= 12 && hour < 17 {
                timeOfDay = "下午"
            } else if hour >= 17 && hour < 22 {
                timeOfDay = "晚上"
            } else {
                timeOfDay = "深夜"
            }
            timeOfDayCount[timeOfDay, default: 0] += 1
        }
        
        stats.bestDayOfWeek = dayOfWeekCount.max(by: { $0.value < $1.value })?.key ?? "未知"
        stats.bestTimeOfDay = timeOfDayCount.max(by: { $0.value < $1.value })?.key ?? "未知"
        
        // 找出最清晰的梦境
        if let clearest = dreams.max(by: { $0.clarity < $1.clarity }) {
            stats.clearestDreamId = clearest.id
        }
        
        // 找出清醒梦最多的月份
        stats.mostLucidMonth = monthCount.max(by: { $0.value < $1.value })?.key ?? 1
        
        // 选择亮点梦境（最多 5 个）
        let highlightDreams = dreams.sorted { dream1, dream2 in
            let score1 = Double(dream1.clarity) + (dream1.isLucid ? 2 : 0) + Double(dream1.tags.count) * 0.5
            let score2 = Double(dream2.clarity) + (dream2.isLucid ? 2 : 0) + Double(dream2.tags.count) * 0.5
            return score1 > score2
        }.prefix(5)
        
        stats.highlightDreamIds = highlightDreams.map { $0.id }
        
        return stats
    }
    
    /// 计算最长连续记录
    private func calculateLongestStreak(from recordDays: Set<String>, calendar: Calendar) -> Int {
        // 简化实现：返回记录天数作为近似值
        return min(recordDays.count, 30)
    }
    
    /// 计算当前连续记录
    private func calculateCurrentStreak(from recordDays: Set<String>, calendar: Calendar) -> Int {
        // 简化实现：检查最近 7 天
        let today = calendar.string(from: .day, in: Date())
        if recordDays.contains(today) {
            return min(recordDays.count, 7)
        }
        return 0
    }
    
    /// 生成 AI 洞察
    private func generateAIInsights(from dreams: [Dream], stats: YearInReviewStatistics) -> [YearInReviewInsight] {
        var insights: [YearInReviewInsight] = []
        
        // 成就类洞察
        if stats.totalDreams >= 100 {
            insights.append(YearInReviewInsight(
                type: .achievement,
                title: "梦境记录大师",
                description: "你在这一年记录了\(stats.totalDreams)个梦境，超越了 90% 的用户！",
                icon: "🏆",
                confidence: 1.0
            ))
        } else if stats.totalDreams >= 50 {
            insights.append(YearInReviewInsight(
                type: .achievement,
                title: "勤奋的记录者",
                description: "记录了\(stats.totalDreams)个梦境，继续保持！",
                icon: "⭐",
                confidence: 1.0
            ))
        }
        
        // 清醒梦洞察
        let lucidRate = stats.totalDreams > 0 ? Double(stats.lucidDreams) / Double(stats.totalDreams) : 0
        if lucidRate > 0.3 {
            insights.append(YearInReviewInsight(
                type: .pattern,
                title: "清醒梦高手",
                description: "你的清醒梦比例达到\(Int(lucidRate * 100))%，远超平均水平！",
                icon: "👁️",
                confidence: 0.9,
                actionSuggestion: "尝试记录清醒梦中的创意想法"
            ))
        }
        
        // 连续记录洞察
        if stats.longestStreak >= 30 {
            insights.append(YearInReviewInsight(
                type: .achievement,
                title: "持之以恒",
                description: "最长连续记录\(stats.longestStreak)天，展现了惊人的毅力！",
                icon: "🔥",
                confidence: 1.0
            ))
        }
        
        // 情绪洞察
        if !stats.topEmotion.isEmpty {
            insights.append(YearInReviewInsight(
                type: .trend,
                title: "情绪主旋律",
                description: "\(stats.topEmotion)是你这一年梦境中最常见的情绪",
                icon: "💖",
                confidence: 0.85,
                relatedTags: [stats.topEmotion]
            ))
        }
        
        // 标签洞察
        if let topTag = stats.topTags.first {
            insights.append(YearInReviewInsight(
                type: .pattern,
                title: "年度关键词",
                description: "\"\(topTag)\"是你梦境中出现最频繁的主题",
                icon: "🏷️",
                confidence: 0.9,
                relatedTags: [topTag]
            ))
        }
        
        // 建议类洞察
        if stats.averageClarity < 3.0 {
            insights.append(YearInReviewInsight(
                type: .suggestion,
                title: "提升梦境清晰度",
                description: "你的梦境平均清晰度为\(String(format: "%.1f", stats.averageClarity))，可以尝试睡前冥想来改善",
                icon: "💡",
                confidence: 0.75,
                actionSuggestion: "尝试睡前冥想练习"
            ))
        }
        
        // 有趣发现
        if stats.dreamsByMonth.count > 0 {
            if let (month, count) = stats.dreamsByMonth.max(by: { $0.value < $1.value }) {
                let monthName = ["", "一月", "二月", "三月", "四月", "五月", "六月",
                               "七月", "八月", "九月", "十月", "十一月", "十二月"][month]
                insights.append(YearInReviewInsight(
                    type: .curiosity,
                    title: "多梦之月",
                    description: "\(monthName)是你记录梦境最多的月份，共\(count)个",
                    icon: "📅",
                    confidence: 1.0
                ))
            }
        }
        
        return insights
    }
    
    /// 生成年度主题
    private func generateYearTheme(from dreams: [Dream], stats: YearInReviewStatistics) -> String {
        let themes: [String: [String]] = [
            "探索与发现": ["飞行", "旅行", "未知", "探索"],
            "内心成长": ["学习", "成长", "变化", "突破"],
            "情感之旅": ["爱", "友情", "家庭", "思念"],
            "创意无限": ["艺术", "创作", "音乐", "绘画"],
            "平静安宁": ["平静", "放松", "自然", "冥想"],
            "冒险挑战": ["冒险", "挑战", "战斗", "追逐"]
        ]
        
        // 根据标签匹配主题
        var themeScores: [String: Int] = [:]
        for (theme, keywords) in themes {
            for tag in stats.topTags {
                if keywords.contains(tag) {
                    themeScores[theme, default: 0] += 1
                }
            }
        }
        
        return themeScores.max(by: { $0.value < $1.value })?.key ?? "独特之旅"
    }
    
    /// 生成年度关键词
    private func generateYearKeyword(from dreams: [Dream], stats: YearInReviewStatistics) -> String {
        if stats.lucidDreams > stats.totalDreams / 3 {
            return "觉醒"
        } else if stats.averageClarity >= 4.0 {
            return "清晰"
        } else if stats.longestStreak >= 30 {
            return "坚持"
        } else if stats.totalDreams >= 100 {
            return "丰富"
        } else {
            return "探索"
        }
    }
    
    /// 生成分享卡片
    private func generateShareCards(for year: Int, stats: YearInReviewStatistics, insights: [YearInReviewInsight]) -> [YearInReviewShareCard] {
        var cards: [YearInReviewShareCard] = []
        
        // 总览卡片
        cards.append(YearInReviewShareCard(
            year: year,
            cardType: .overview,
            title: "\(year) 梦境年度总览",
            subtitle: "你的梦境之旅",
            mainValue: "\(stats.totalDreams)个梦境",
            description: "记录了\(stats.totalRecordDays)天，最长连续\(stats.longestStreak)天",
            backgroundImage: "starry",
            decorations: ["🌙", "✨", "💫"]
        ))
        
        // 情绪卡片
        if !stats.topEmotion.isEmpty {
            cards.append(YearInReviewShareCard(
                year: year,
                cardType: .emotion,
                title: "年度情绪",
                subtitle: "出现最频繁的情绪",
                mainValue: stats.topEmotion,
                description: "在你的梦境中出现了\(stats.emotionDistribution[stats.topEmotion] ?? 0)次",
                backgroundImage: "sunset",
                decorations: ["💖", "💕", "💗"]
            ))
        }
        
        // 清醒梦卡片
        if stats.lucidDreams > 0 {
            cards.append(YearInReviewShareCard(
                year: year,
                cardType: .lucid,
                title: "清醒梦探索",
                subtitle: "意识觉醒的时刻",
                mainValue: "\(stats.lucidDreams)个",
                description: "占总梦境的\(Int(Double(stats.lucidDreams) / Double(max(stats.totalDreams, 1)) * 100))%",
                backgroundImage: "ocean",
                decorations: ["👁️", "✨", "🌟"]
            ))
        }
        
        // 连续记录卡片
        if stats.longestStreak > 0 {
            cards.append(YearInReviewShareCard(
                year: year,
                cardType: .streak,
                title: "连续记录",
                subtitle: "坚持的力量",
                mainValue: "\(stats.longestStreak)天",
                description: "最长连续记录，超越了\(Int(Double(stats.longestStreak) / 365.0 * 100))%的用户",
                backgroundImage: "forest",
                decorations: ["🔥", "⭐", "💪"]
            ))
        }
        
        // AI 洞察卡片
        if let topInsight = insights.first {
            cards.append(YearInReviewShareCard(
                year: year,
                cardType: .insight,
                title: topInsight.title,
                subtitle: "AI 年度洞察",
                mainValue: topInsight.icon,
                description: topInsight.description,
                backgroundImage: "lavender",
                decorations: ["🧠", "💡", "✨"]
            ))
        }
        
        // 年度主题卡片
        cards.append(YearInReviewShareCard(
            year: year,
            cardType: .theme,
            title: "年度主题",
            subtitle: "你的\(year)年关键词",
            mainValue: generateYearKeyword(from: [], stats: stats),
            description: generateYearTheme(from: [], stats: stats),
            backgroundImage: "starry",
            decorations: ["🎨", "✨", "🌟"]
        ))
        
        return cards
    }
    
    /// 生成月度回顾
    private func generateMonthlyReviews(for year: Int, dreams: [Dream]) async throws {
        let calendar = Calendar.current
        
        for month in 1...12 {
            // Calendar.date(from:...) with valid components never fails
            let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
            let monthEnd = calendar.date(from: DateComponents(year: year, month: month + 1, day: 1)) ?? monthStart
            
            let monthDreams = dreams.filter { dream in
                dream.date >= monthStart && dream.date < monthEnd
            }
            
            if monthDreams.isEmpty {
                continue
            }
            
            let monthReview = DreamMonthInReview(
                year: year,
                month: month,
                totalDreams: monthDreams.count,
                lucidDreams: monthDreams.filter { $0.isLucid }.count,
                averageClarity: monthDreams.map { Double($0.clarity) }.reduce(0, +) / Double(monthDreams.count),
                topEmotion: monthDreams.flatMap { $0.emotions }.map { $0.rawValue }.mostCommon ?? "",
                topTags: monthDreams.flatMap { $0.tags }.mostCommon(5),
                highlightDreamId: monthDreams.max(by: { $0.clarity < $1.clarity })?.id
            )
            
            modelContext.insert(monthReview)
        }
        
        try modelContext.save()
    }
}

// MARK: - 辅助统计结构

struct YearInReviewStatistics {
    var totalDreams: Int = 0
    var lucidDreams: Int = 0
    var averageClarity: Double = 0
    var averageIntensity: Double = 0
    var totalDreamTime: TimeInterval = 0
    var longestStreak: Int = 0
    var currentStreak: Int = 0
    var totalRecordDays: Int = 0
    var topEmotion: String = ""
    var emotionDistribution: [String: Int] = [:]
    var topTags: [String] = []
    var tagCloud: [String: Int] = [:]
    var bestDayOfWeek: String = ""
    var bestTimeOfDay: String = ""
    var dreamsByMonth: [Int: Int] = [:]
    var highlightDreamIds: [UUID] = []
    var clearestDreamId: UUID? = nil
    var mostLucidMonth: Int = 1
}

// MARK: - 数组扩展

extension Array where Element == String {
    func mostCommon(_ count: Int = 1) -> [String] {
        let frequency = Dictionary(grouping: self, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        return frequency.prefix(count).map { $0.key }
    }
    
    var mostCommon: String? {
        mostCommon(1).first
    }
}

extension Calendar {
    func string(from component: Calendar.Component, in date: Date) -> String {
        let value = self.component(component, from: date)
        return "\(value)"
    }
}
