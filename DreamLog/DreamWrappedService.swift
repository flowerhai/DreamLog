//
//  DreamWrappedService.swift
//  DreamLog
//
//  Dream Wrapped - 年度/月度梦境总结服务
//  类似 Spotify Wrapped 的梦境年度回顾功能
//

import Foundation
import Combine

// MARK: - Dream Wrapped 数据结构

/// 梦境总结时间段
enum WrappedPeriod: String, CaseIterable, Codable {
    case week = "本周"
    case month = "本月"
    case quarter = "本季度"
    case year = "年度"
    case allTime = "全部"
    
    var displayName: String { rawValue }
    
    var dayCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .allTime: return Int.max
        }
    }
}

/// 梦境总结卡片类型
enum WrappedCardType: String, CaseIterable, Identifiable {
    case overview = "总览"
    case emotionJourney = "情绪之旅"
    case topThemes = "热门主题"
    case lucidDreams = "清醒梦"
    case dreamStreak = "连续记录"
    case vividDream = "最清晰的梦"
    case dreamTime = "梦境时间"
    case uniqueStats = "独特统计"
    case yearComparison = "年度对比"
    case shareCard = "分享卡片"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .emotionJourney: return "heart.fill"
        case .topThemes: return "tag.fill"
        case .lucidDreams: return "eye.fill"
        case .dreamStreak: return "flame.fill"
        case .vividDream: return "star.fill"
        case .dreamTime: return "clock.fill"
        case .uniqueStats: return "sparkles"
        case .yearComparison: return "arrow.left.arrow.right"
        case .shareCard: return "square.and.arrow.up.fill"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .overview: return ["#7B61FF", "#4A90E2"]
        case .emotionJourney: return ["#FF6B6B", "#FF8E8E"]
        case .topThemes: return ["#2ECC71", "#27AE60"]
        case .lucidDreams: return ["#9D50DD", "#C77DFF"]
        case .dreamStreak: return ["#FF6B35", "#FF9F1C"]
        case .vividDream: return ["#FFD700", "#FFA500"]
        case .dreamTime: return ["#00B4DB", "#0083B0"]
        case .uniqueStats: return ["#F093FB", "#F5576C"]
        case .yearComparison: return ["#6366F1", "#8B5CF6"]
        case .shareCard: return ["#667EEA", "#764BA2"]
        }
    }
}

/// 梦境总结数据
struct DreamWrappedData: Codable, Equatable {
    var period: WrappedPeriod
    var generatedAt: Date
    var totalDreams: Int
    var lucidDreamCount: Int
    var averageClarity: Double
    var averageIntensity: Double
    var topEmotions: [EmotionStat]
    var topTags: [TagStat]
    var dreamStreak: Int
    var longestStreak: Int
    case mostVividDream: Dream?
    case mostIntenseDream: Dream?
    var timeOfDayDistribution: [String: Int]
    var weeklyPattern: [Int]  // 0=周日，6=周六
    case monthlyTrend: [MonthStat]
    case uniqueStats: [UniqueStat]
    case shareCardQuote: String
    
    struct EmotionStat: Codable, Equatable {
        var name: String
        var count: Int
        var percentage: Double
    }
    
    struct TagStat: Codable, Equatable {
        var name: String
        var count: Int
        var percentage: Double
    }
    
    struct MonthStat: Codable, Equatable {
        var month: String
        var count: Int
        var averageClarity: Double
    }
    
    struct UniqueStat: Codable, Equatable {
        var title: String
        var value: String
        var icon: String
    }
}

// MARK: - Dream Wrapped Service

class DreamWrappedService: ObservableObject {
    static let shared = DreamWrappedService()
    
    @Published var currentWrappedData: DreamWrappedData?
    @Published var isGenerating: Bool = false
    @Published var generatedPeriod: WrappedPeriod = .year
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 生成梦境总结
    
    /// 生成指定时间段的梦境总结
    func generateWrapped(for period: WrappedPeriod, dreams: [Dream]) {
        isGenerating = true
        generatedPeriod = period
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // 过滤时间段内的梦境
            let calendar = Calendar.current
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -period.dayCount, to: endDate) ?? Date.distantPast
            
            let filteredDreams = dreams.filter { dream in
                dream.timestamp >= startDate && dream.timestamp <= endDate
            }
            
            // 生成总结数据
            let wrappedData = self.analyzeDreams(filteredDreams, period: period)
            
            DispatchQueue.main.async {
                self.currentWrappedData = wrappedData
                self.isGenerating = false
            }
        }
    }
    
    // MARK: - 数据分析
    
    private func analyzeDreams(_ dreams: [Dream], period: WrappedPeriod) -> DreamWrappedData {
        let totalDreams = dreams.count
        
        // 清醒梦统计
        let lucidDreamCount = dreams.filter { $0.isLucid }.count
        
        // 平均清晰度和强度
        let averageClarity = totalDreams > 0 ? Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(totalDreams) : 0
        let averageIntensity = totalDreams > 0 ? Double(dreams.reduce(0) { $0 + $1.intensity }) / Double(totalDreams) : 0
        
        // 情绪统计
        let emotionCounts: [String: Int] = Dictionary(grouping: dreams.flatMap { $0.emotions }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let topEmotions = emotionCounts.prefix(5).map { (name, count) in
            DreamWrappedData.EmotionStat(
                name: name,
                count: count,
                percentage: totalDreams > 0 ? Double(count) / Double(totalDreams) * 100 : 0
            )
        }
        
        // 标签统计
        let tagCounts: [String: Int] = Dictionary(grouping: dreams.flatMap { $0.tags }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        let topTags = tagCounts.prefix(5).map { (name, count) in
            DreamWrappedData.TagStat(
                name: name,
                count: count,
                percentage: totalDreams > 0 ? Double(count) / Double(totalDreams) * 100 : 0
            )
        }
        
        // 连续记录天数
        let dreamStreak = calculateStreak(dreams: dreams)
        let longestStreak = calculateLongestStreak(dreams: dreams)
        
        // 最清晰和最强烈的梦境
        let mostVividDream = dreams.max { $0.clarity < $1.clarity }
        let mostIntenseDream = dreams.max { $0.intensity < $1.intensity }
        
        // 时间段分布
        let timeOfDayDistribution = Dictionary(grouping: dreams) { $0.timeOfDay.rawValue }
            .mapValues { $0.count }
        
        // 星期分布
        let weeklyPattern = calculateWeeklyPattern(dreams: dreams)
        
        // 月度趋势
        let monthlyTrend = calculateMonthlyTrend(dreams: dreams, period: period)
        
        // 独特统计
        let uniqueStats = generateUniqueStats(dreams: dreams, period: period)
        
        // 分享语录
        let shareCardQuote = generateShareQuote(dreams: dreams, period: period)
        
        return DreamWrappedData(
            period: period,
            generatedAt: Date(),
            totalDreams: totalDreams,
            lucidDreamCount: lucidDreamCount,
            averageClarity: averageClarity,
            averageIntensity: averageIntensity,
            topEmotions: Array(topEmotions),
            topTags: Array(topTags),
            dreamStreak: dreamStreak,
            longestStreak: longestStreak,
            mostVividDream: mostVividDream,
            mostIntenseDream: mostIntenseDream,
            timeOfDayDistribution: timeOfDayDistribution,
            weeklyPattern: weeklyPattern,
            monthlyTrend: monthlyTrend,
            uniqueStats: uniqueStats,
            shareCardQuote: shareCardQuote
        )
    }
    
    // MARK: - 统计算法
    
    private func calculateStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let sortedDreams = dreams.sorted { $0.timestamp > $1.timestamp }
        let calendar = Calendar.current
        var streak = 1
        var currentDate = calendar.startOfDay(for: sortedDreams[0].timestamp)
        
        for i in 1..<sortedDreams.count {
            let dreamDate = calendar.startOfDay(for: sortedDreams[i].timestamp)
            let daysDiff = calendar.dateComponents([.day], from: dreamDate, to: currentDate).day ?? 0
            
            if daysDiff == 1 {
                streak += 1
                currentDate = dreamDate
            } else if daysDiff > 1 {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let sortedDreams = dreams.sorted { $0.timestamp > $1.timestamp }
        let calendar = Calendar.current
        
        var longestStreak = 1
        var currentStreak = 1
        var currentDate = calendar.startOfDay(for: sortedDreams[0].timestamp)
        
        for i in 1..<sortedDreams.count {
            let dreamDate = calendar.startOfDay(for: sortedDreams[i].timestamp)
            let daysDiff = calendar.dateComponents([.day], from: dreamDate, to: currentDate).day ?? 0
            
            if daysDiff == 1 {
                currentStreak += 1
                currentDate = dreamDate
            } else if daysDiff > 1 {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
                currentDate = dreamDate
            }
        }
        
        return max(longestStreak, currentStreak)
    }
    
    private func calculateWeeklyPattern(dreams: [Dream]) -> [Int] {
        var pattern = Array(repeating: 0, count: 7)
        let calendar = Calendar.current
        
        for dream in dreams {
            let weekday = calendar.component(.weekday, from: dream.timestamp)
            pattern[weekday - 1] += 1
        }
        
        return pattern
    }
    
    private func calculateMonthlyTrend(dreams: [Dream], period: WrappedPeriod) -> [DreamWrappedData.MonthStat] {
        let calendar = Calendar.current
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        
        let monthGroups = Dictionary(grouping: dreams) { dream in
            monthFormatter.string(from: dream.timestamp)
        }
        
        return monthGroups.map { (month, dreams) in
            let avgClarity = dreams.reduce(0) { $0 + $1.clarity } / dreams.count
            let monthName = calendar.date(from: monthFormatter.date(from: month)!)?.formatted(.dateTime.month(.abbreviated)) ?? month
            
            return DreamWrappedData.MonthStat(
                month: monthName,
                count: dreams.count,
                averageClarity: Double(avgClarity)
            )
        }.sorted { $0.month < $1.month }
    }
    
    private func generateUniqueStats(dreams: [Dream], period: WrappedPeriod) -> [DreamWrappedData.UniqueStat] {
        var stats: [DreamWrappedData.UniqueStat] = []
        
        // 最早和最晚的梦境时间
        let timeComponents = dreams.compactMap { dream -> (hour: Int, minute: Int)? in
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: dream.timestamp)
            let minute = calendar.component(.minute, from: dream.timestamp)
            return (hour, minute)
        }
        
        if let earliest = timeComponents.min(by: { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }) {
            stats.append(DreamWrappedData.UniqueStat(
                title: "最早的梦境",
                value: String(format: "%02d:%02d", earliest.hour, earliest.minute),
                icon: "sunrise.fill"
            ))
        }
        
        // 平均梦境长度
        let avgLength = dreams.reduce(0) { $0 + $1.content.count } / max(dreams.count, 1)
        stats.append(DreamWrappedData.UniqueStat(
            title: "平均梦境长度",
            value: "\(avgLength) 字",
            icon: "text.alignleft"
        ))
        
        // 清醒梦比例
        if !dreams.isEmpty {
            let lucidRatio = dreams.filter { $0.isLucid }.count * 100 / dreams.count
            stats.append(DreamWrappedData.UniqueStat(
                title: "清醒梦比例",
                value: "\(lucidRatio)%",
                icon: "eye.fill"
            ))
        }
        
        // 周末梦境数量
        let calendar = Calendar.current
        let weekendDreams = dreams.filter { dream in
            let weekday = calendar.component(.weekday, from: dream.timestamp)
            return weekday == 1 || weekday == 7
        }.count
        stats.append(DreamWrappedData.UniqueStat(
            title: "周末梦境",
            value: "\(weekendDreams) 个",
            icon: "calendar"
        ))
        
        return stats
    }
    
    private func generateShareQuote(dreams: [Dream], period: WrappedPeriod) -> String {
        let quotes = [
            "在 \(period.displayName) 里，我记录了 \(dreams.count) 个梦境 🌙",
            "探索潜意识的深处，\(period.displayName) 的梦境之旅 ✨",
            "\(dreams.count) 个夜晚，\(dreams.count) 个故事，\(period.displayName) 的梦境回忆 💫",
            "每个梦都是一扇窗，\(period.displayName) 我看到了 \(dreams.count) 道风景 🌈",
        ]
        
        return quotes.randomElement() ?? quotes[0]
    }
    
    // MARK: - 导出功能
    
    /// 导出梦境总结为 JSON
    func exportWrappedData() -> Data? {
        guard let wrappedData = currentWrappedData else { return nil }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try? encoder.encode(wrappedData)
    }
    
    /// 清除当前总结
    func clearWrappedData() {
        currentWrappedData = nil
        generatedPeriod = .year
    }
    
    // MARK: - 年度对比功能 (Phase 11.5)
    
    /// 生成年度对比数据（今年 vs 去年）
    func generateYearOverYearComparison(dreams: [Dream]) -> YearComparisonData? {
        let calendar = Calendar.current
        let now = Date()
        
        // 今年的梦境
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
        let thisYearDreams = dreams.filter { $0.timestamp >= startOfYear }
        
        // 去年的梦境
        let lastYear = calendar.component(.year, from: now) - 1
        let startOfLastYear = calendar.date(from: DateComponents(year: lastYear))!
        let endOfLastYear = calendar.date(byAdding: .year, value: 1, to: startOfLastYear)!
        let lastYearDreams = dreams.filter { $0.timestamp >= startOfLastYear && $0.timestamp < endOfLastYear }
        
        // 如果去年没有数据，返回 nil
        if lastYearDreams.isEmpty {
            return nil
        }
        
        // 生成对比数据
        let thisYearData = analyzeDreams(thisYearDreams, period: .year)
        let lastYearData = analyzeDreams(lastYearDreams, period: .year)
        
        return YearComparisonData(
            thisYear: thisYearData,
            lastYear: lastYearData,
            dreamsChange: thisYearDreams.count - lastYearDreams.count,
            dreamsChangePercent: lastYearDreams.count > 0 
                ? Double(thisYearDreams.count - lastYearDreams.count) / Double(lastYearDreams.count) * 100 
                : 0,
            lucidChange: thisYearData.lucidDreamCount - lastYearData.lucidDreamCount,
            clarityChange: thisYearData.averageClarity - lastYearData.averageClarity,
            streakChange: thisYearData.dreamStreak - lastYearData.dreamStreak
        )
    }
    
    /// 生成月度对比数据（本月 vs 上月）
    func generateMonthOverMonthComparison(dreams: [Dream]) -> MonthComparisonData? {
        let calendar = Calendar.current
        let now = Date()
        
        // 本月的梦境
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let thisMonthDreams = dreams.filter { $0.timestamp >= startOfMonth }
        
        // 上月的梦境
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
        let lastMonthDreams = dreams.filter { $0.timestamp >= startOfLastMonth && $0.timestamp < startOfMonth }
        
        // 如果上月没有数据，返回 nil
        if lastMonthDreams.isEmpty {
            return nil
        }
        
        // 生成对比数据
        let thisMonthData = analyzeDreams(thisMonthDreams, period: .month)
        let lastMonthData = analyzeDreams(lastMonthDreams, period: .month)
        
        return MonthComparisonData(
            thisMonth: thisMonthData,
            lastMonth: lastMonthData,
            dreamsChange: thisMonthDreams.count - lastMonthDreams.count,
            dreamsChangePercent: lastMonthDreams.count > 0 
                ? Double(thisMonthDreams.count - lastMonthDreams.count) / Double(lastMonthDreams.count) * 100 
                : 0,
            lucidChange: thisMonthData.lucidDreamCount - lastMonthData.lucidDreamCount,
            clarityChange: thisMonthData.averageClarity - lastMonthData.averageClarity
        )
    }
    
    // MARK: - 图片导出功能 (Phase 11.5)
    
    /// 导出分享卡片图片
    func exportShareCard(type: ShareCardType, data: DreamWrappedData) -> URL? {
        var image: UIImage?
        var fileName: String
        
        switch type {
        case .standard:
            image = WrappedShareCardGenerator.generateStandardShareCard(data: data)
            fileName = "DreamWrapped_Standard_\(Date().formatted(.dateTime.year().month().day()))"
        case .square:
            image = WrappedShareCardGenerator.generateSquareShareCard(data: data)
            fileName = "DreamWrapped_Square_\(Date().formatted(.dateTime.year().month().day()))"
        case .wechat:
            image = WrappedShareCardGenerator.generateWeChatShareCard(data: data)
            fileName = "DreamWrapped_WeChat_\(Date().formatted(.dateTime.year().month().day()))"
        }
        
        guard let cardImage = image else { return nil }
        
        return WrappedShareCardGenerator.saveCard(image: cardImage, fileName: fileName)
    }
    
    /// 批量导出所有类型的分享卡片
    func exportAllShareCards(data: DreamWrappedData) -> [ShareCardType: URL] {
        var results: [ShareCardType: URL] = [:]
        
        for type in ShareCardType.allCases {
            if let url = exportShareCard(type: type, data: data) {
                results[type] = url
            }
        }
        
        return results
    }
}

// MARK: - 对比数据结构

/// 年度对比数据
struct YearComparisonData {
    let thisYear: DreamWrappedData
    let lastYear: DreamWrappedData
    let dreamsChange: Int
    let dreamsChangePercent: Double
    let lucidChange: Int
    let clarityChange: Double
    let streakChange: Int
    
    var insights: [String] {
        var insights: [String] = []
        
        if dreamsChange > 0 {
            insights.append("今年比去年多记录了 \(dreamsChange) 个梦境 (\(String(format: "%.1f", dreamsChangePercent))% 增长)")
        } else if dreamsChange < 0 {
            insights.append("今年比去年少记录了 \(abs(dreamsChange)) 个梦境")
        }
        
        if lucidChange > 0 {
            insights.append("清醒梦数量增加了 \(lucidChange) 个 🌟")
        }
        
        if clarityChange > 0 {
            insights.append("梦境清晰度提高了 \(String(format: "%.1f", clarityChange)) 分")
        }
        
        if streakChange > 0 {
            insights.append("连续记录天数增加了 \(streakChange) 天 🔥")
        }
        
        return insights.isEmpty ? ["今年和去年的梦境记录相当"] : insights
    }
}

/// 月度对比数据
struct MonthComparisonData {
    let thisMonth: DreamWrappedData
    let lastMonth: DreamWrappedData
    let dreamsChange: Int
    let dreamsChangePercent: Double
    let lucidChange: Int
    let clarityChange: Double
    
    var insights: [String] {
        var insights: [String] = []
        
        if dreamsChange > 0 {
            insights.append("本月比上月多记录了 \(dreamsChange) 个梦境")
        } else if dreamsChange < 0 {
            insights.append("本月比上月少记录了 \(abs(dreamsChange)) 个梦境")
        }
        
        if lucidChange > 0 {
            insights.append("清醒梦数量增加了 \(lucidChange) 个")
        }
        
        if clarityChange > 0 {
            insights.append("梦境清晰度提高了 \(String(format: "%.1f", clarityChange)) 分")
        }
        
        return insights.isEmpty ? ["本月和上月的梦境记录相当"] : insights
    }
}

/// 分享卡片类型
enum ShareCardType: String, CaseIterable {
    case standard = "标准"      // 1080x1920 - Instagram Story
    case square = "方形"        // 1080x1080 - Instagram Post
    case wechat = "微信"        // 1080x1350 - 微信朋友圈
    
    var displayName: String { rawValue }
    var sizeDescription: String {
        switch self {
        case .standard: return "1080×1920 (Story)"
        case .square: return "1080×1080 (Post)"
        case .wechat: return "1080×1350 (微信)"
        }
    }
}
