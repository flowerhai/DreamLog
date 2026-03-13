//
//  DreamWidgetService.swift
//  DreamLog
//
//  iOS 小组件数据服务 - Phase 33
//

import Foundation
import WidgetKit

@MainActor
class DreamWidgetService {
    
    static let shared = DreamWidgetService()
    
    private let userDefaults: UserDefaults
    private var dreamStore: DreamStore?
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func setDreamStore(_ store: DreamStore) {
        self.dreamStore = store
    }
    
    // MARK: - 主题管理
    
    func getCurrentTheme() -> WidgetTheme {
        let themeIndex = userDefaults.integer(forKey: "widget_theme_index")
        if themeIndex >= 0 && themeIndex < WidgetTheme.allThemes.count {
            return WidgetTheme.allThemes[themeIndex]
        }
        return WidgetTheme.default
    }
    
    func setTheme(_ theme: WidgetTheme) {
        if let index = WidgetTheme.allThemes.firstIndex(where: { $0.id == theme.id }) {
            userDefaults.set(index, forKey: "widget_theme_index")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - 布局管理
    
    func getCurrentLayout() -> WidgetLayout {
        if let data = userDefaults.data(forKey: "widget_layout"),
           let layout = try? JSONDecoder().decode(WidgetLayout.self, from: data) {
            return layout
        }
        return WidgetLayout.default
    }
    
    func setLayout(_ layout: WidgetLayout) {
        if let data = try? JSONEncoder().encode(layout) {
            userDefaults.set(data, forKey: "widget_layout")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - 快速记录
    
    func getQuickRecordEntry() async -> QuickRecordEntry {
        guard let store = dreamStore else {
            return QuickRecordEntry.empty
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let dreams = await store.fetchDreams(from: today, to: Date())
        
        let weeklyGoal = userDefaults.integer(forKey: "weekly_dream_goal") || 7
        let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? today
        let weekDreams = await store.fetchDreams(from: weekStart, to: Date())
        
        return QuickRecordEntry(
            isRecording: false, // 实际状态需要从录音服务获取
            lastRecordDate: dreams.first?.date,
            todayCount: dreams.count,
            weeklyGoal: weeklyGoal,
            progress: Double(weekDreams.count) / Double(weeklyGoal)
        )
    }
    
    func startRecording() async {
        // 触发快速记录
        userDefaults.set(Date(), forKey: "last_widget_recording_start")
        WidgetCenter.shared.reloadTimelines(ofKind: DreamWidgetKind.quickRecord.rawValue)
        
        // 通知主应用开始录音
        NotificationCenter.default.post(name: .widgetStartRecording, object: nil)
    }
    
    func stopRecording() async {
        userDefaults.removeObject(forKey: "last_widget_recording_start")
        WidgetCenter.shared.reloadTimelines(ofKind: DreamWidgetKind.quickRecord.rawValue)
        
        // 通知主应用停止录音
        NotificationCenter.default.post(name: .widgetStopRecording, object: nil)
    }
    
    // MARK: - 统计数据
    
    func getDreamStats() async -> DreamStats {
        guard let store = dreamStore else {
            return DreamStats.empty
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let today = calendar.startOfDay(for: now)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today) ?? today
        
        let todayDreams = await store.fetchDreams(from: today, to: now)
        let weekDreams = await store.fetchDreams(from: weekAgo, to: now)
        let monthDreams = await store.fetchDreams(from: monthAgo, to: now)
        let allDreams = await store.fetchAllDreams()
        
        // 计算连续记录天数
        let streakDays = calculateStreak(dreams: allDreams)
        let longestStreak = calculateLongestStreak(dreams: allDreams)
        
        // 计算平均清晰度
        let clarityValues = allDreams.compactMap { $0.clarity }
        let averageClarity = clarityValues.isEmpty ? 0 : Double(clarityValues.reduce(0, +)) / Double(clarityValues.count)
        
        // 常见情绪
        let emotionCounts = Dictionary(grouping: allDreams.flatMap { $0.emotions }, by: { $0.rawValue })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        // 常见标签
        let tagCounts = Dictionary(grouping: allDreams.flatMap { $0.tags }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        return DreamStats(
            todayCount: todayDreams.count,
            weekCount: weekDreams.count,
            monthCount: monthDreams.count,
            totalCount: allDreams.count,
            streakDays: streakDays,
            longestStreak: longestStreak,
            averageClarity: averageClarity,
            commonEmotions: emotionCounts,
            commonTags: tagCounts
        )
    }
    
    // MARK: - 梦境名言
    
    func getDreamQuote() async -> DreamQuote {
        guard let store = dreamStore else {
            return DreamQuote.empty
        }
        
        let allDreams = await store.fetchAllDreams()
        guard !allDreams.isEmpty else {
            return DreamQuote.empty
        }
        
        // 随机选择一个有内容的梦境
        let dreamsWithContent = allDreams.filter { $0.content.count > 50 }
        guard let selectedDream = dreamsWithContent.randomElement() ?? allDreams.randomElement() else {
            return DreamQuote.empty
        }
        
        // 提取精彩片段
        let previewLength = 100
        let content = selectedDream.content
        let preview: String
        if content.count > previewLength {
            let endIndex = content.index(content.startIndex, offsetBy: previewLength)
            preview = String(content[..<endIndex]) + "..."
        } else {
            preview = content
        }
        
        return DreamQuote(
            content: preview,
            date: selectedDream.date ?? Date(),
            tags: selectedDream.tags,
            emotions: selectedDream.emotions.map { $0.rawValue },
            clarity: selectedDream.clarity ?? 0
        )
    }
    
    // MARK: - 情绪追踪
    
    func getMoodTracking() async -> MoodTracking {
        guard let store = dreamStore else {
            return MoodTracking.empty
        }
        
        let allDreams = await store.fetchAllDreams()
        
        // 统计情绪
        let moodCounts = Dictionary(grouping: allDreams.flatMap { $0.emotions }, by: { $0.rawValue })
            .mapValues { $0.count }
        
        // 最近情绪
        let recentDreams = allDreams.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.prefix(7)
        let moodHistory = recentDreams.compactMap { dream -> MoodTracking.MoodEntry? in
            guard let primaryEmotion = dream.emotions.first else { return nil }
            return MoodTracking.MoodEntry(
                mood: primaryEmotion.rawValue,
                date: dream.date ?? Date(),
                intensity: dream.intensity ?? 3
            )
        }
        
        return MoodTracking(
            currentMood: moodHistory.first?.mood,
            moodHistory: Array(moodHistory),
            commonMoods: moodCounts
        )
    }
    
    // MARK: - 标签筛选
    
    func getTagFilterData() async -> TagFilterData {
        guard let store = dreamStore else {
            return TagFilterData.empty
        }
        
        let allDreams = await store.fetchAllDreams()
        
        // 统计标签使用次数
        let tagCounts = Dictionary(grouping: allDreams.flatMap { $0.tags }, by: { $0 })
            .mapValues { $0.count }
        
        // 按使用频率排序
        let sortedTags = tagCounts.sorted { $0.value > $1.value }
        
        let frequentTags = sortedTags.prefix(10).map { (name, count) in
            TagFilterData.TagInfo(name: name, count: count, category: nil)
        }
        
        // 最近使用的标签
        let recentDreams = allDreams.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }.prefix(20)
        let recentTagSet = Set(recentDreams.flatMap { $0.tags })
        let recentTags = sortedTags
            .filter { recentTagSet.contains($0.key) }
            .prefix(5)
            .map { (name, count) in
                TagFilterData.TagInfo(name: name, count: count, category: nil)
            }
        
        return TagFilterData(
            frequentTags: Array(frequentTags),
            recentTags: Array(recentTags),
            totalCount: tagCounts.count
        )
    }
    
    // MARK: - 最近梦境
    
    func getRecentDreams(limit: Int = 5) async -> RecentDreamsData {
        guard let store = dreamStore else {
            return RecentDreamsData.empty
        }
        
        let allDreams = await store.fetchAllDreams()
        let sorted = allDreams.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        let recent = sorted.prefix(limit)
        
        let dreams = recent.map { dream -> RecentDreamsData.DreamSummary in
            let previewLength = 50
            let content = dream.content
            let preview: String
            if content.count > previewLength {
                let endIndex = content.index(content.startIndex, offsetBy: previewLength)
                preview = String(content[..<endIndex]) + "..."
            } else {
                preview = content
            }
            
            return RecentDreamsData.DreamSummary(
                id: dream.id?.uuidString ?? UUID().uuidString,
                title: dream.title ?? "无题梦境",
                preview: preview,
                date: dream.date ?? Date(),
                emotions: dream.emotions.map { $0.rawValue },
                tags: dream.tags,
                clarity: dream.clarity ?? 0
            )
        }
        
        return RecentDreamsData(
            dreams: Array(dreams),
            hasMore: sorted.count > limit
        )
    }
    
    // MARK: - 连续记录
    
    func getStreakData() async -> StreakData {
        guard let store = dreamStore else {
            return StreakData.empty
        }
        
        let allDreams = await store.fetchAllDreams()
        let currentStreak = calculateStreak(dreams: allDreams)
        let longestStreak = calculateLongestStreak(dreams: allDreams)
        
        let lastRecordDate = allDreams.max(by: { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) })?.date
        
        let weeklyGoal = userDefaults.integer(forKey: "weekly_dream_goal") ?? 7
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let weekDreams = await store.fetchDreams(from: weekStart, to: Date())
        
        let nextMilestone = currentStreak >= 7 ? 14 : 7
        
        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastRecordDate: lastRecordDate,
            nextMilestone: nextMilestone,
            weeklyGoal: weeklyGoal,
            weeklyProgress: weekDreams.count
        )
    }
    
    // MARK: - 辅助方法
    
    private func calculateStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sortedDates = Set(dreams.compactMap { calendar.startOfDay(for: $0.date ?? Date()) })
            .sorted(by: >)
        
        var streak = 0
        var currentDate = today
        
        for date in sortedDates {
            let daysDiff = calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0
            if daysDiff <= 1 {
                streak += 1
                currentDate = date
            } else {
                break
            }
        }
        
        // 检查今天是否已记录
        if !sortedDates.contains(today) {
            streak = 0
        }
        
        return streak
    }
    
    private func calculateLongestStreak(dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDates = Set(dreams.compactMap { calendar.startOfDay(for: $0.date ?? Date()) })
            .sorted(by: <)
        
        var longestStreak = 1
        var currentStreak = 1
        
        for i in 1..<sortedDates.count {
            let daysDiff = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            if daysDiff == 1 {
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return longestStreak
    }
    
    // MARK: - 时间线刷新
    
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func reloadTimeline(for kind: DreamWidgetKind) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind.rawValue)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let widgetStartRecording = Notification.Name("widgetStartRecording")
    static let widgetStopRecording = Notification.Name("widgetStopRecording")
    static let widgetLikeDream = Notification.Name("widgetLikeDream")
    static let widgetFavoriteDream = Notification.Name("widgetFavoriteDream")
}
