//
//  DreamWeeklyReportService.swift
//  DreamLog
//
//  梦境周报生成服务
//  Phase 18 - 梦境周报功能
//

import Foundation
import Combine

// MARK: - 周报服务

class DreamWeeklyReportService: ObservableObject {
    static let shared = DreamWeeklyReportService()
    
    @Published var currentReport: DreamWeeklyReport?
    @Published var isGenerating = false
    @Published var generatedReports: [DreamWeeklyReport] = []
    
    private let dreamStore: DreamStore
    private let configKey = "weeklyReportConfig"
    
    init(dreamStore: DreamStore = .shared) {
        self.dreamStore = dreamStore
        loadSavedReports()
    }
    
    // MARK: - 配置管理
    
    var config: WeeklyReportConfig {
        get {
            guard let data = UserDefaults.standard.data(forKey: configKey),
                  let config = try? JSONDecoder().decode(WeeklyReportConfig.self, from: data) else {
                return .default
            }
            return config
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: configKey)
            }
        }
    }
    
    // MARK: - 报告生成
    
    /// 生成本周报告
    func generateCurrentWeekReport() async -> DreamWeeklyReport? {
        await generateReport(for: Date())
    }
    
    /// 生成指定日期的周报告
    func generateReport(for date: Date) async -> DreamWeeklyReport? {
        isGenerating = true
        defer { isGenerating = false }
        
        let calendar = Calendar.current
        let weekInterval = getWeekInterval(for: date, in: calendar)
        
        guard let startDate = weekInterval.start,
              let endDate = weekInterval.end else {
            return nil
        }
        
        // 获取本周梦境
        let dreams = dreamStore.allDreams.filter { dream in
            calendar.isDate(dream.date, inHalfOpenRange: startDate..<endDate)
        }
        
        guard !dreams.isEmpty else {
            // 即使没有梦境也生成报告（显示空状态）
            let emptyReport = createEmptyReport(startDate: startDate, endDate: endDate)
            await MainActor.run {
                self.currentReport = emptyReport
            }
            return emptyReport
        }
        
        // 分析数据
        let report = await analyzeDreams(dreams, startDate: startDate, endDate: endDate)
        
        await MainActor.run {
            self.currentReport = report
            saveReport(report)
        }
        
        return report
    }
    
    /// 生成指定周范围的报告
    func generateReport(startDate: Date, endDate: Date) async -> DreamWeeklyReport? {
        isGenerating = true
        defer { isGenerating = false }
        
        let dreams = dreamStore.allDreams.filter { dream in
            dream.date >= startDate && dream.date < endDate
        }
        
        guard !dreams.isEmpty else {
            let emptyReport = createEmptyReport(startDate: startDate, endDate: endDate)
            await MainActor.run {
                self.currentReport = emptyReport
            }
            return emptyReport
        }
        
        let report = await analyzeDreams(dreams, startDate: startDate, endDate: endDate)
        
        await MainActor.run {
            self.currentReport = report
            saveReport(report)
        }
        
        return report
    }
    
    // MARK: - 数据分析
    
    private func analyzeDreams(_ dreams: [Dream], startDate: Date, endDate: Date) async -> DreamWeeklyReport {
        let calendar = Calendar.current
        
        // 基础统计
        let totalDreams = dreams.count
        let lucidDreams = dreams.filter { $0.isLucid }.count
        let averageClarity = dreams.isEmpty ? 0 : dreams.reduce(0.0) { $0 + Double($1.clarity) } / Double(dreams.count)
        let averageIntensity = dreams.isEmpty ? 0 : dreams.reduce(0.0) { $0 + Double($1.intensity) } / Double(dreams.count)
        
        // 计算连续记录天数
        let recordingStreak = calculateRecordingStreak(endingAt: endDate)
        
        // 情绪分析
        let emotionDistribution = analyzeEmotions(dreams)
        let dominantEmotion = emotionDistribution.max(by: { $0.value < $1.value })?.key ?? "中性"
        let moodTrend = analyzeMoodTrend(dreams)
        
        // 主题分析
        let topTags = analyzeTags(dreams)
        let emergingThemes = findEmergingThemes(dreams)
        let fadingThemes = findFadingThemes(dreams)
        
        // 时间分析
        let dreamsByTimeOfDay = analyzeTimeOfDay(dreams)
        let dreamsByWeekday = analyzeWeekday(dreams)
        let mostActiveDay = dreamsByWeekday.max(by: { $0.value < $1.value })?.key ?? 1
        let bestRecallHour = findBestRecallHour(dreams)
        
        // 亮点梦境
        let highlightDreams = findHighlightDreams(dreams)
        
        // 洞察与建议
        let insights = generateInsights(dreams, totalDreams: totalDreams, lucidDreams: lucidDreams, 
                                       averageClarity: averageClarity, recordingStreak: recordingStreak)
        let suggestions = generateSuggestions(dreams, insights: insights)
        
        // 对比数据
        let lastWeekComparison = await generateWeekComparison(currentDreams: dreams, endDate: endDate)
        
        return DreamWeeklyReport(
            weekStartDate: startDate,
            weekEndDate: endDate,
            generatedAt: Date(),
            totalDreams: totalDreams,
            lucidDreams: lucidDreams,
            averageClarity: averageClarity,
            averageIntensity: averageIntensity,
            recordingStreak: recordingStreak,
            emotionDistribution: emotionDistribution,
            dominantEmotion: dominantEmotion,
            moodTrend: moodTrend,
            topTags: topTags,
            emergingThemes: emergingThemes,
            fadingThemes: fadingThemes,
            dreamsByTimeOfDay: dreamsByTimeOfDay,
            dreamsByWeekday: dreamsByWeekday,
            mostActiveDay: mostActiveDay,
            bestRecallHour: bestRecallHour,
            highlightDreams: highlightDreams,
            insights: insights,
            suggestions: suggestions,
            lastWeekComparison: lastWeekComparison
        )
    }
    
    // MARK: - 情绪分析
    
    private func analyzeEmotions(_ dreams: [Dream]) -> [String: Int] {
        var distribution: [String: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                distribution[emotion.rawValue, default: 0] += 1
            }
        }
        return distribution
    }
    
    private func analyzeMoodTrend(_ dreams: [Dream]) -> DreamWeeklyReport.MoodTrend {
        guard dreams.count >= 2 else { return .stable }
        
        let sortedDreams = dreams.sorted { $0.date < $1.date }
        let midPoint = sortedDreams.count / 2
        
        let firstHalf = sortedDreams.prefix(midPoint)
        let secondHalf = sortedDreams.suffix(from: midPoint)
        
        let firstHalfAvg = firstHalf.isEmpty ? 0 : firstHalf.reduce(0.0) { $0 + Double($1.clarity) } / Double(firstHalf.count)
        let secondHalfAvg = secondHalf.isEmpty ? 0 : secondHalf.reduce(0.0) { $0 + Double($1.clarity) } / Double(secondHalf.count)
        
        let diff = secondHalfAvg - firstHalfAvg
        
        if diff > 0.5 { return .improving }
        if diff < -0.5 { return .declining }
        if abs(diff) > 0.2 { return .fluctuating }
        return .stable
    }
    
    // MARK: - 主题分析
    
    private func analyzeTags(_ dreams: [Dream]) -> [TagFrequency] {
        var tagCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts.map { TagFrequency(tag: $0.key, count: $0.value, change: nil) }
            .sorted { $0.count > $1.count }
            .prefix(10)
            .map { $0 }
    }
    
    private func findEmergingThemes(_ dreams: [Dream]) -> [String] {
        // 简化实现：返回本周新增的标签
        let allTags = Set(dreams.flatMap { $0.tags })
        return Array(allTags.prefix(3))
    }
    
    private func findFadingThemes(_ dreams: [Dream]) -> [String] {
        // 简化实现：返回出现频率较低的标签
        var tagCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts.filter { $0.value == 1 }.keys.prefix(3).map { $0 }
    }
    
    // MARK: - 时间分析
    
    private func analyzeTimeOfDay(_ dreams: [Dream]) -> [String: Int] {
        var distribution: [String: Int] = [
            "清晨 (5-8 点)": 0,
            "上午 (8-12 点)": 0,
            "下午 (12-18 点)": 0,
            "傍晚 (18-22 点)": 0,
            "深夜 (22-5 点)": 0
        ]
        
        for dream in dreams {
            let hour = Calendar.current.component(.hour, from: dream.date)
            switch hour {
            case 5..<8: distribution["清晨 (5-8 点)", default: 0] += 1
            case 8..<12: distribution["上午 (8-12 点)", default: 0] += 1
            case 12..<18: distribution["下午 (12-18 点)", default: 0] += 1
            case 18..<22: distribution["傍晚 (18-22 点)", default: 0] += 1
            default: distribution["深夜 (22-5 点)", default: 0] += 1
            }
        }
        
        return distribution
    }
    
    private func analyzeWeekday(_ dreams: [Dream]) -> [Int: Int] {
        var distribution: [Int: Int] = [:]
        for dream in dreams {
            let weekday = Calendar.current.component(.weekday, from: dream.date)
            distribution[weekday, default: 0] += 1
        }
        return distribution
    }
    
    private func findBestRecallHour(_ dreams: [Dream]) -> Int {
        var hourClarity: [Int: [Double]] = [:]
        
        for dream in dreams {
            let hour = Calendar.current.component(.hour, from: dream.date)
            hourClarity[hour, default: []].append(Double(dream.clarity))
        }
        
        var bestHour = 8
        var bestAvgClarity = 0.0
        
        for (hour, clarities) in hourClarity {
            let avg = clarities.reduce(0, +) / Double(clarities.count)
            if avg > bestAvgClarity {
                bestAvgClarity = avg
                bestHour = hour
            }
        }
        
        return bestHour
    }
    
    // MARK: - 亮点梦境
    
    private func findHighlightDreams(_ dreams: [Dream]) -> [DreamHighlight] {
        var highlights: [DreamHighlight] = []
        
        // 最清晰的清醒梦
        if let lucidDream = dreams.filter({ $0.isLucid }).max(by: { $0.clarity < $1.clarity }) {
            highlights.append(DreamHighlight(
                id: lucidDream.id,
                dreamId: lucidDream.id,
                title: lucidDream.title,
                date: lucidDream.date,
                type: .mostLucid,
                reason: "清晰度：\(lucidDream.clarity)/5"
            ))
        }
        
        // 最高清晰度
        if let clearestDream = dreams.max(by: { $0.clarity < $1.clarity }) {
            highlights.append(DreamHighlight(
                id: clearestDream.id,
                dreamId: clearestDream.id,
                title: clearestDream.title,
                date: clearestDream.date,
                type: .highestClarity,
                reason: "清晰度：\(clearestDream.clarity)/5"
            ))
        }
        
        // 情绪最强烈
        if let mostEmotional = dreams.max(by: { $0.intensity < $1.intensity }) {
            highlights.append(DreamHighlight(
                id: mostEmotional.id,
                dreamId: mostEmotional.id,
                title: mostEmotional.title,
                date: mostEmotional.date,
                type: .mostEmotional,
                reason: "强度：\(mostEmotional.intensity)/5"
            ))
        }
        
        // 标签最多
        if let mostTagged = dreams.max(by: { $0.tags.count < $1.tags.count }) {
            highlights.append(DreamHighlight(
                id: mostTagged.id,
                dreamId: mostTagged.id,
                title: mostTagged.title,
                date: mostTagged.date,
                type: .mostTags,
                reason: "\(mostTagged.tags.count) 个标签"
            ))
        }
        
        return Array(highlights.prefix(4))
    }
    
    // MARK: - 洞察生成
    
    private func generateInsights(_ dreams: [Dream], totalDreams: Int, lucidDreams: Int, 
                                  averageClarity: Double, recordingStreak: Int) -> [ReportInsight] {
        var insights: [ReportInsight] = []
        
        // 成就认可
        if totalDreams >= 7 {
            insights.append(ReportInsight(
                type: .achievement,
                title: "记录达人",
                description: "本周记录了 \(totalDreams) 个梦境，超过 80% 的用户！",
                icon: "trophy.fill",
                confidence: 1.0
            ))
        }
        
        if recordingStreak >= 7 {
            insights.append(ReportInsight(
                type: .achievement,
                title: "坚持不懈",
                description: "连续记录 \(recordingStreak) 天，养成好习惯！",
                icon: "flame.fill",
                confidence: 1.0
            ))
        }
        
        // 清醒梦洞察
        if lucidDreams > 0 {
            let percentage = Int(Double(lucidDreams) / Double(totalDreams) * 100)
            insights.append(ReportInsight(
                type: .pattern,
                title: "清醒梦探索",
                description: "本周有 \(lucidDreams) 个清醒梦，占比 \(percentage)%",
                icon: "eye.fill",
                confidence: 1.0
            ))
        }
        
        // 清晰度趋势
        if averageClarity >= 4.0 {
            insights.append(ReportInsight(
                type: .trend,
                title: "记忆清晰",
                description: "平均清晰度 \(String(format: "%.1f", averageClarity))/5，记忆状态很好！",
                icon: "star.fill",
                confidence: 0.9
            ))
        }
        
        // 模式发现
        let emotions = analyzeEmotions(dreams)
        if let topEmotion = emotions.max(by: { $0.value < $1.value }), topEmotion.value >= 3 {
            insights.append(ReportInsight(
                type: .pattern,
                title: "情绪模式",
                description: "\"\(topEmotion.key)\"出现 \(topEmotion.value) 次，是本周主导情绪",
                icon: "heart.fill",
                confidence: 0.8
            ))
        }
        
        return insights
    }
    
    private func generateSuggestions(_ dreams: [Dream], insights: [ReportInsight]) -> [String] {
        var suggestions: [String] = []
        
        if dreams.isEmpty {
            suggestions.append("本周还没有记录梦境，试试今晚开始记录吧！")
            return suggestions
        }
        
        // 基于洞察生成建议
        let hasAchievement = insights.contains { $0.type == .achievement }
        let hasPattern = insights.contains { $0.type == .pattern }
        
        if !hasAchievement {
            suggestions.append("设定一个小目标：下周记录 5 个梦境")
        }
        
        if dreams.filter({ $0.isLucid }).isEmpty {
            suggestions.append("试试清醒梦训练，探索意识边界")
        }
        
        if dreams.averageClarity < 3.0 {
            suggestions.append("睡前冥想可以提高梦境回忆清晰度")
        }
        
        return suggestions
    }
    
    // MARK: - 周对比
    
    private func generateWeekComparison(currentDreams: [Dream], endDate: Date) async -> WeekComparison? {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return nil
        }
        
        let lastWeekDreams = dreamStore.allDreams.filter { dream in
            dream.date >= weekStart && dream.date < endDate
        }
        
        let currentCount = currentDreams.count
        let lastCount = lastWeekDreams.count
        
        guard lastCount > 0 else { return nil }
        
        let dreamsChange = currentCount - lastCount
        let dreamsChangePercent = Double(dreamsChange) / Double(lastCount) * 100
        
        let currentClarity = currentDreams.isEmpty ? 0 : currentDreams.reduce(0.0) { $0 + Double($1.clarity) } / Double(currentDreams.count)
        let lastClarity = lastWeekDreams.isEmpty ? 0 : lastWeekDreams.reduce(0.0) { $0 + Double($1.clarity) } / Double(lastWeekDreams.count)
        let clarityChange = currentClarity - lastClarity
        
        let currentLucid = currentDreams.filter { $0.isLucid }.count
        let lastLucid = lastWeekDreams.filter { $0.isLucid }.count
        let lucidChange = currentLucid - lastLucid
        
        return WeekComparison(
            dreamsChange: dreamsChange,
            dreamsChangePercent: dreamsChangePercent,
            clarityChange: clarityChange,
            lucidChange: lucidChange,
            streakChange: 0
        )
    }
    
    // MARK: - 辅助方法
    
    private func getWeekInterval(for date: Date, in calendar: Calendar) -> (start: Date?, end: Date?) {
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart ?? date)
        return (weekStart, weekEnd)
    }
    
    private func calculateRecordingStreak(endingAt date: Date) -> Int {
        // 简化实现：计算连续记录天数
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: date)
        
        while streak < 365 { // 最多计算一年的连续记录
            let dreamsOnDay = dreamStore.allDreams.filter { dream in
                calendar.isDate(dream.date, inSameDayAs: currentDate)
            }
            
            if dreamsOnDay.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    private func createEmptyReport(startDate: Date, endDate: Date) -> DreamWeeklyReport {
        DreamWeeklyReport(
            weekStartDate: startDate,
            weekEndDate: endDate,
            generatedAt: Date(),
            totalDreams: 0,
            lucidDreams: 0,
            averageClarity: 0,
            averageIntensity: 0,
            recordingStreak: 0,
            emotionDistribution: [:],
            dominantEmotion: "无数据",
            moodTrend: .stable,
            topTags: [],
            emergingThemes: [],
            fadingThemes: [],
            dreamsByTimeOfDay: [:],
            dreamsByWeekday: [:],
            mostActiveDay: 1,
            bestRecallHour: 8,
            highlightDreams: [],
            insights: [],
            suggestions: ["开始记录你的第一个梦境吧！"],
            lastWeekComparison: nil
        )
    }
    
    // MARK: - 持久化
    
    private func saveReport(_ report: DreamWeeklyReport) {
        // 保存到已生成报告列表
        if !generatedReports.contains(where: { $0.weekStartDate == report.weekStartDate }) {
            generatedReports.append(report)
            generatedReports.sort { $0.weekStartDate > $1.weekStartDate }
        }
        
        // 保存到 UserDefaults
        if let data = try? JSONEncoder().encode(report) {
            let key = "weeklyReport_\(report.weekStartDate.timeIntervalSince1970)"
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func loadSavedReports() {
        // 加载最近 4 周的报告
        for i in 0..<4 {
            let date = Date().addingTimeInterval(Double(-i * 7 * 24 * 60 * 60))
            let calendar = Calendar.current
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))
            
            if let weekStart = weekStart {
                let key = "weeklyReport_\(weekStart.timeIntervalSince1970)"
                if let data = UserDefaults.standard.data(forKey: key),
                   let report = try? JSONDecoder().decode(DreamWeeklyReport.self, from: data) {
                    if !generatedReports.contains(where: { $0.weekStartDate == report.weekStartDate }) {
                        generatedReports.append(report)
                    }
                }
            }
        }
        
        generatedReports.sort { $0.weekStartDate > $1.weekStartDate }
    }
    
    // MARK: - 自动提醒
    
    func scheduleWeeklyReminder() {
        guard config.isEnabled && config.autoGenerate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📊 梦境周报已生成"
        content.body = "查看你本周的梦境统计和洞察"
        content.sound = .default
        content.categoryIdentifier = "weeklyReport"
        
        var dateComponents = DateComponents()
        dateComponents.weekday = config.generateDay + 1 // 转换为 1-7
        dateComponents.hour = config.generateHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weeklyReportReminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule weekly reminder: \(error)")
            }
        }
    }
}

// MARK: - 扩展

extension Array where Element == Dream {
    var averageClarity: Double {
        guard !isEmpty else { return 0 }
        return reduce(0.0) { $0 + Double($1.clarity) } / Double(count)
    }
}
