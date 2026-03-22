//
//  DreamScreenTimeService.swift
//  DreamLog
//
//  Phase 93: 屏幕时间与数字健康追踪服务
//  追踪睡前屏幕使用时间，分析与梦境质量的关联
//

import Foundation
import Combine

// MARK: - 屏幕时间服务

@MainActor
class DreamScreenTimeService: ObservableObject {
    static let shared = DreamScreenTimeService()
    
    // MARK: - Published Properties
    
    @Published var isTracking: Bool = false
    @Published var currentSession: ScreenTimeSession?
    @Published var todayStats: DailyScreenTimeStats?
    @Published var weeklyReport: ScreenTimeWeeklyReport?
    @Published var correlation: ScreenTimeDreamCorrelation?
    @Published var settings: DigitalWellnessSettings = .default
    @Published var quickStats: ScreenTimeQuickStats?
    @Published var achievements: [ScreenTimeAchievement] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    private let modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    private let sessionsKey = "screen_time_sessions"
    private let settingsKey = "digital_wellness_settings"
    private let achievementsKey = "screen_time_achievements"
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard, modelContext: ModelContext? = nil) {
        self.userDefaults = userDefaults
        self.modelContext = modelContext
        loadSettings()
        loadAchievements()
        setupAutoTracking()
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(DigitalWellnessSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func updateSettings(_ update: (inout DigitalWellnessSettings) -> Void) {
        update(&settings)
        saveSettings()
    }
    
    // MARK: - Session Tracking
    
    /// 记录屏幕使用会话
    func logSession(duration: TimeInterval, category: ScreenTimeCategory, appName: String, minutesBeforeSleep: Int? = nil) async {
        let isBeforeBed = (minutesBeforeSleep ?? 60) <= settings.windDownMinutes
        
        let session = ScreenTimeSession(
            duration: duration,
            category: category,
            appName: appName,
            isBeforeBed: isBeforeBed,
            minutesBeforeSleep: minutesBeforeSleep
        )
        
        var sessions = getAllSessions()
        sessions.append(session)
        saveSessions(sessions)
        
        await updateTodayStats()
        checkGoalsAndNotify(session: session)
    }
    
    /// 批量导入屏幕时间数据（从 iOS Screen Time API）
    func importScreenTimeData(_ sessions: [ScreenTimeSession]) async {
        isLoading = true
        defer { isLoading = false }
        
        var existingSessions = getAllSessions()
        existingSessions.append(contentsOf: sessions)
        
        // 去重（基于日期 + 应用 + 类别）
        let uniqueSessions = Dictionary(grouping: existingSessions) { session in
            "\(session.date.timeIntervalSince1970)_\(session.appName)_\(session.category.rawValue)"
        }.values.map { $0[0] }
        
        saveSessions(uniqueSessions)
        await updateTodayStats()
        await analyzeCorrelations()
    }
    
    // MARK: - Statistics
    
    /// 更新今日统计
    func updateTodayStats() async {
        let sessions = getSessionsForDate(Date())
        todayStats = DailyScreenTimeStats(date: Date(), sessions: sessions)
        await updateQuickStats()
    }
    
    /// 获取指定日期的统计
    func getStatsForDate(_ date: Date) -> DailyScreenTimeStats {
        let sessions = getSessionsForDate(date)
        return DailyScreenTimeStats(date: date, sessions: sessions)
    }
    
    /// 获取日期范围内的统计
    func getStatsForDateRange(start: Date, end: Date) -> [DailyScreenTimeStats] {
        let sessions = getAllSessions().filter { session in
            session.date >= start && session.date <= end
        }
        
        let grouped = Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.date)
        }
        
        return grouped.map { date, sessions in
            DailyScreenTimeStats(date: date, sessions: sessions)
        }.sorted { $0.date < $1.date }
    }
    
    /// 生成周报
    func generateWeeklyReport(for weekStart: Date) -> ScreenTimeWeeklyReport {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? Date()
        let dailyStats = getStatsForDateRange(start: weekStart, end: weekEnd)
        
        let totalScreenTime = dailyStats.reduce(0) { $0 + $1.totalDuration }
        let beforeBedTotal = dailyStats.reduce(0) { $0 + $1.beforeBedDuration }
        let beforeBedPercentage = totalScreenTime > 0 ? (beforeBedTotal / totalScreenTime) * 100 : 0
        
        // 找出主要使用类别
        var categoryTotals: [ScreenTimeCategory: TimeInterval] = [:]
        for stats in dailyStats {
            for (category, duration) in stats.categoryBreakdown {
                categoryTotals[category, default: 0] += duration
            }
        }
        let topCategory = categoryTotals.max(by: { $0.value < $1.value })?.key
        
        // 计算梦境质量趋势
        let dreamQualityTrend = calculateDreamQualityTrend(for: weekStart, to: weekEnd)
        
        // 生成关联洞察
        let correlationInsight = generateCorrelationInsight()
        
        // 计算周目标进度
        let weeklyGoal = calculateWeeklyGoalProgress(dailyStats: dailyStats)
        
        // 检查本周成就
        let weeklyAchievements = checkWeeklyAchievements(dailyStats: dailyStats)
        
        return ScreenTimeWeeklyReport(
            weekStart: weekStart,
            weekEnd: weekEnd,
            dailyStats: dailyStats,
            totalScreenTime: totalScreenTime,
            averageDailyScreenTime: totalScreenTime / Double(dailyStats.count),
            beforeBedPercentage: beforeBedPercentage,
            topCategory: topCategory,
            dreamQualityTrend: dreamQualityTrend,
            correlationInsight: correlationInsight,
            weeklyGoal: weeklyGoal,
            achievements: weeklyAchievements
        )
    }
    
    // MARK: - Correlation Analysis
    
    /// 分析屏幕时间与梦境的关联
    func analyzeCorrelations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let sessions = getAllSessions()
            let dreams = await fetchDreams()
            
            guard !dreams.isEmpty else {
                errorMessage = "需要梦境数据才能进行分析"
                isLoading = false
                return
            }
            
            let correlation = performCorrelationAnalysis(sessions: sessions, dreams: dreams)
            self.correlation = correlation
            saveCorrelation(correlation)
            
            // 如果发现显著关联且启用通知，发送通知
            if settings.notifyOnCorrelation && abs(correlation.overallCorrelation) > 0.5 {
                await sendCorrelationNotification(correlation)
            }
            
        } catch {
            errorMessage = "分析失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func performCorrelationAnalysis(sessions: [ScreenTimeSession], dreams: [DreamEntity]) -> ScreenTimeDreamCorrelation {
        let calendar = Calendar.current
        let now = Date()
        let daysToAnalyze = 30
        
        // 筛选最近 30 天的数据
        let startDate = calendar.date(byAdding: .day, value: -daysToAnalyze, to: now)!
        let recentSessions = sessions.filter { $0.date >= startDate }
        let recentDreams = dreams.filter { $0.date >= startDate }
        
        // 按日期分组
        let sessionsByDate = Dictionary(grouping: recentSessions) { session in
            calendar.startOfDay(for: session.date)
        }
        
        let dreamsByDate = Dictionary(grouping: recentDreams) { dream in
            calendar.startOfDay(for: dream.date)
        }
        
        // 计算每日数据
        var dailyData: [(date: Date, beforeBedMinutes: Double, clarity: Double, quality: Double)] = []
        
        for date in calendar.dateRange(from: startDate, to: now, interval: .day) ?? [] {
            let daySessions = sessionsByDate[date] ?? []
            let dayDreams = dreamsByDate[date] ?? []
            
            let beforeBedMinutes = daySessions.filter { $0.isBeforeBed }.reduce(0) { $0 + $1.duration } / 60
            
            if !dayDreams.isEmpty {
                let avgClarity = dayDreams.reduce(0) { $0 + ($1.clarity ?? 3) } / Double(dayDreams.count)
                let avgQuality = dayDreams.reduce(0) { $0 + ($1.quality ?? 3) } / Double(dayDreams.count)
                dailyData.append((date, beforeBedMinutes, avgClarity, avgQuality))
            }
        }
        
        // 计算关联度（皮尔逊相关系数简化版）
        let overallCorrelation = calculateCorrelation(
            dailyData.map { $0.beforeBedMinutes },
            dailyData.map { $0.clarity }
        )
        
        // 分类关联度
        var categoryCorrelations: [ScreenTimeCategory: Double] = [:]
        for category in ScreenTimeCategory.allCases {
            let categorySessions = recentSessions.filter { $0.category == category && $0.isBeforeBed }
            let categoryByDate = Dictionary(grouping: categorySessions) { session in
                calendar.startOfDay(for: session.date)
            }
            
            var categoryDailyData: [(minutes: Double, clarity: Double)] = []
            for date in calendar.dateRange(from: startDate, to: now, interval: .day) ?? [] {
                let dayMinutes = (categoryByDate[date] ?? []).reduce(0) { $0 + $1.duration } / 60
                if let dayDreams = dreamsByDate[date], !dayDreams.isEmpty {
                    let avgClarity = dayDreams.reduce(0) { $0 + ($1.clarity ?? 3) } / Double(dayDreams.count)
                    categoryDailyData.append((dayMinutes, avgClarity))
                }
            }
            
            if categoryDailyData.count >= 3 {
                categoryCorrelations[category] = calculateCorrelation(
                    categoryDailyData.map { $0.minutes },
                    categoryDailyData.map { $0.clarity }
                )
            }
        }
        
        // 生成关键发现
        let findings = generateFindings(overallCorrelation: overallCorrelation, categoryCorrelations: categoryCorrelations, dailyData: dailyData)
        
        // 生成建议
        let recommendations = generateRecommendations(overallCorrelation: overallCorrelation, categoryCorrelations: categoryCorrelations)
        
        // 计算统计
        let stats = calculateStats(dailyData: dailyData, dreams: recentDreams)
        
        return ScreenTimeDreamCorrelation(
            analysisDate: now,
            dataRangeDays: daysToAnalyze,
            totalDreamsAnalyzed: recentDreams.count,
            overallCorrelation: overallCorrelation,
            categoryCorrelations: categoryCorrelations,
            keyFindings: findings,
            recommendations: recommendations,
            stats: stats
        )
    }
    
    private func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 2 else { return 0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).reduce(0) { $0 + $1.0 * $1.1 }
        let sumX2 = x.reduce(0) { $0 + $1 * $1 }
        let sumY2 = y.reduce(0) { $0 + $1 * $1 }
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator == 0 ? 0 : numerator / denominator
    }
    
    // MARK: - Goals & Achievements
    
    /// 检查目标并发送通知
    func checkGoalsAndNotify(session: ScreenTimeSession) {
        guard settings.trackingEnabled else { return }
        
        let todaySessions = getSessionsForDate(Date())
        let todayTotalByCategory = Dictionary(grouping: todaySessions) { $0.category }
            .mapValues { $0.reduce(0) { $0 + $1.duration } / 60 }
        
        for goal in settings.goals where goal.isEnabled {
            let currentMinutes = todayTotalByCategory[goal.category] ?? 0
            
            if goal.notifyWhenExceeded && currentMinutes > goal.dailyLimitMinutes {
                // 可以发送通知
                print("📱 通知：\(goal.category.displayName) 今日已使用\(Int(currentMinutes))分钟，超过目标\(goal.dailyLimitMinutes)分钟")
            }
        }
    }
    
    /// 检查周成就
    func checkWeeklyAchievements(dailyStats: [DailyScreenTimeStats]) -> [ScreenTimeAchievement] {
        var newAchievements: [ScreenTimeAchievement] = []
        
        // 检查无屏幕日
        let detoxDays = dailyStats.filter { $0.totalDuration == 0 }.count
        if detoxDays >= 1 && !hasAchievement(.digitalDetox) {
            newAchievements.append(ScreenTimeAchievement(
                id: UUID(),
                type: .digitalDetox,
                title: "数字排毒",
                description: "成功度过\(detoxDays)天无屏幕日",
                icon: "phone.slash.fill",
                earnedDate: Date(),
                level: detoxDays
            ))
        }
        
        // 检查连续达标周
        let goal = settings.goals.first { $0.isEnabled }
        if let goal = goal {
            let compliantDays = dailyStats.filter { stats in
                let categoryMinutes = (stats.categoryBreakdown[goal.category] ?? 0) / 60
                return categoryMinutes <= Double(goal.dailyLimitMinutes)
            }.count
            
            if compliantDays == 7 && !hasAchievement(.consistentWeek) {
                newAchievements.append(ScreenTimeAchievement(
                    id: UUID(),
                    type: .consistentWeek,
                    title: "持之以恒",
                    description: "连续 7 天达成屏幕时间目标",
                    icon: "checkmark.seal.fill",
                    earnedDate: Date(),
                    level: 1
                ))
            }
        }
        
        // 保存新成就
        if !newAchievements.isEmpty {
            achievements.append(contentsOf: newAchievements)
            saveAchievements()
        }
        
        return newAchievements
    }
    
    private func hasAchievement(_ type: ScreenTimeAchievement.AchievementType) -> Bool {
        achievements.contains { $0.type == type }
    }
    
    // MARK: - Data Persistence
    
    private func getAllSessions() -> [ScreenTimeSession] {
        guard let data = userDefaults.data(forKey: sessionsKey),
              let decoded = try? JSONDecoder().decode([ScreenTimeSession].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func getSessionsForDate(_ date: Date) -> [ScreenTimeSession] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return getAllSessions().filter { session in
            session.date >= startOfDay && session.date < endOfDay
        }
    }
    
    private func saveSessions(_ sessions: [ScreenTimeSession]) {
        if let encoded = try? JSONEncoder().encode(sessions) {
            userDefaults.set(encoded, forKey: sessionsKey)
        }
    }
    
    private func loadAchievements() {
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([ScreenTimeAchievement].self, from: data) {
            achievements = decoded
        }
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func saveCorrelation(_ correlation: ScreenTimeDreamCorrelation) {
        // 可以保存到 UserDefaults 或文件系统
    }
    
    // MARK: - Helper Methods
    
    private func setupAutoTracking() {
        // 设置自动追踪（实际应用中需要集成 iOS Screen Time API）
        isTracking = settings.trackingEnabled
    }
    
    private func fetchDreams() async -> [DreamEntity] {
        // 从模型上下文获取梦境数据
        // 这里简化处理，实际需要从 Core Data 获取
        return []
    }
    
    private func calculateDreamQualityTrend(for weekStart: Date, to weekEnd: Date) -> ScreenTimeWeeklyReport.TrendDirection {
        // 计算梦境质量趋势
        return .stable
    }
    
    private func generateCorrelationInsight() -> String {
        guard let correlation = correlation else {
            return "数据不足，无法生成洞察"
        }
        
        if correlation.overallCorrelation < -0.3 {
            return "数据显示睡前屏幕使用与梦境质量呈负相关，减少屏幕时间可能改善梦境质量"
        } else if correlation.overallCorrelation > 0.3 {
            return "数据显示睡前屏幕使用与梦境质量无明显负面影响"
        } else {
            return "屏幕使用对梦境质量影响不明显"
        }
    }
    
    private func generateFindings(overallCorrelation: Double, categoryCorrelations: [ScreenTimeCategory: Double], dailyData: [(date: Date, beforeBedMinutes: Double, clarity: Double, quality: Double)]) -> [ScreenTimeFinding] {
        var findings: [ScreenTimeFinding] = []
        
        // 整体关联发现
        if overallCorrelation < -0.5 {
            findings.append(ScreenTimeFinding(
                id: UUID(),
                type: .warning,
                title: "显著负相关",
                description: "睡前屏幕使用与梦境质量呈强负相关",
                severity: .high,
                supportingData: "相关系数：\(String(format: "%.2f", overallCorrelation))"
            ))
        }
        
        // 分类发现
        for (category, corr) in categoryCorrelations {
            if corr < -0.5 {
                findings.append(ScreenTimeFinding(
                    id: UUID(),
                    type: .negativeImpact,
                    title: "\(category.displayName)影响显著",
                    description: "睡前使用\(category.displayName)类应用与梦境质量下降相关",
                    severity: .medium,
                    supportingData: "相关系数：\(String(format: "%.2f", corr))"
                ))
            }
        }
        
        // 模式发现
        let avgBeforeBed = dailyData.reduce(0) { $0 + $1.beforeBedMinutes } / Double(dailyData.count)
        if avgBeforeBed > 60 {
            findings.append(ScreenTimeFinding(
                id: UUID(),
                type: .pattern,
                title: "高屏幕使用模式",
                description: "平均睡前屏幕使用时间超过 1 小时",
                severity: .medium,
                supportingData: "平均：\(String(format: "%.0f", avgBeforeBed))分钟"
            ))
        }
        
        return findings
    }
    
    private func generateRecommendations(overallCorrelation: Double, categoryCorrelations: [ScreenTimeCategory: Double]) -> [ScreenTimeRecommendation] {
        var recommendations: [ScreenTimeRecommendation] = []
        
        if overallCorrelation < -0.3 {
            recommendations.append(ScreenTimeRecommendation(
                id: UUID(),
                category: .reduceBeforeBed,
                title: "减少睡前屏幕时间",
                description: "数据显示睡前屏幕使用影响梦境质量",
                actionItems: [
                    "睡前 1 小时停止使用电子设备",
                    "使用夜间模式减少蓝光",
                    "用阅读或冥想替代刷手机"
                ],
                expectedBenefit: "预期可提升梦境清晰度 20-30%",
                priority: .high
            ))
        }
        
        // 针对特定类别的建议
        for (category, corr) in categoryCorrelations where corr < -0.4 {
            recommendations.append(ScreenTimeRecommendation(
                id: UUID(),
                category: .changeCategory,
                title: "调整\(category.displayName)使用习惯",
                description: "\(category.displayName)类应用对梦境质量影响较大",
                actionItems: [
                    "限制\(category.displayName)使用时间",
                    "避免在睡前使用",
                    "寻找替代活动"
                ],
                expectedBenefit: "减少负面影响",
                priority: .medium
            ))
        }
        
        return recommendations
    }
    
    private func calculateStats(dailyData: [(date: Date, beforeBedMinutes: Double, clarity: Double, quality: Double)], dreams: [DreamEntity]) -> CorrelationStats {
        let avgBeforeBed = dailyData.reduce(0) { $0 + $1.beforeBedMinutes } / Double(dailyData.count)
        let avgClarity = dailyData.reduce(0) { $0 + $1.clarity } / Double(dailyData.count)
        let avgQuality = dailyData.reduce(0) { $0 + $1.quality } / Double(dailyData.count)
        
        let highScreenTimeData = dailyData.filter { $0.beforeBedMinutes > 60 }
        let lowScreenTimeData = dailyData.filter { $0.beforeBedMinutes < 30 }
        
        return CorrelationStats(
            averageScreenTimeBeforeBed: avgBeforeBed * 60,
            averageDreamClarity: avgClarity,
            averageDreamQuality: avgQuality,
            highScreenTimeGroup: CorrelationStats.GroupStats(
                count: highScreenTimeData.count,
                averageClarity: highScreenTimeData.isEmpty ? 0 : highScreenTimeData.reduce(0) { $0 + $1.clarity } / Double(highScreenTimeData.count),
                averageQuality: highScreenTimeData.isEmpty ? 0 : highScreenTimeData.reduce(0) { $0 + $1.quality } / Double(highScreenTimeData.count),
                averageNightmareRate: 0 // 简化处理
            ),
            lowScreenTimeGroup: CorrelationStats.GroupStats(
                count: lowScreenTimeData.count,
                averageClarity: lowScreenTimeData.isEmpty ? 0 : lowScreenTimeData.reduce(0) { $0 + $1.clarity } / Double(lowScreenTimeData.count),
                averageQuality: lowScreenTimeData.isEmpty ? 0 : lowScreenTimeData.reduce(0) { $0 + $1.quality } / Double(lowScreenTimeData.count),
                averageNightmareRate: 0 // 简化处理
            )
        )
    }
    
    private func calculateWeeklyGoalProgress(dailyStats: [DailyScreenTimeStats]) -> ScreenTimeWeeklyGoal {
        let goal = settings.goals.first { $0.isEnabled } ?? settings.goals.first!
        let totalMinutes = dailyStats.reduce(0) { $0 + ($1.categoryBreakdown[goal.category] ?? 0) / 60 }
        let beforeBedMinutes = dailyStats.reduce(0) { $0 + $1.beforeBedDuration } / 60
        
        let targetMinutes = goal.dailyLimitMinutes * 7
        let beforeBedTargetMinutes = goal.beforeBedLimitMinutes * 7
        
        return ScreenTimeWeeklyGoal(
            targetMinutes: targetMinutes,
            actualMinutes: Int(totalMinutes),
            beforeBedTargetMinutes: beforeBedTargetMinutes,
            beforeBedActualMinutes: Int(beforeBedMinutes),
            isAchieved: totalMinutes <= Double(targetMinutes),
            progressPercentage: min(100, (totalMinutes / Double(targetMinutes)) * 100)
        )
    }
    
    private func sendCorrelationNotification(_ correlation: ScreenTimeDreamCorrelation) async {
        // 发送通知的逻辑
        print("📊 发现显著关联：\(correlation.overallCorrelation)")
    }
    
    private func updateQuickStats() async {
        let todaySessions = getSessionsForDate(Date())
        let todayMinutes = todaySessions.reduce(0) { $0 + $1.duration } / 60
        let beforeBedMinutes = todaySessions.filter { $0.isBeforeBed }.reduce(0) { $0 + $1.duration } / 60
        
        quickStats = ScreenTimeQuickStats(
            todayMinutes: Int(todayMinutes),
            beforeBedTodayMinutes: Int(beforeBedMinutes),
            weeklyAverageMinutes: 0, // 简化处理
            correlationScore: correlation?.overallCorrelation ?? 0,
            streakDays: 0, // 简化处理
            dreamQualityScore: 0 // 简化处理
        )
    }
    
    // MARK: - Data Export
    
    /// 导出屏幕时间数据为 JSON
    func exportData() -> Data? {
        let sessions = getAllSessions()
        let exportData = ScreenTimeExportData(
            exportDate: Date(),
            settings: settings,
            sessions: sessions,
            achievements: achievements,
            stats: generateExportStats()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(exportData)
        } catch {
            errorMessage = "导出数据失败：\(error.localizedDescription)"
            return nil
        }
    }
    
    /// 生成导出统计
    private func generateExportStats() -> ScreenTimeExportStats {
        let allSessions = getAllSessions()
        let totalSessions = allSessions.count
        let totalDuration = allSessions.reduce(0) { $0 + $1.duration }
        let beforeBedSessions = allSessions.filter { $0.isBeforeBed }
        let beforeBedDuration = beforeBedSessions.reduce(0) { $0 + $1.duration }
        
        let categoryBreakdown = Dictionary(grouping: allSessions) { $0.category }
            .mapValues { sessions in
                sessions.reduce(0) { $0 + $1.duration }
            }
        
        return ScreenTimeExportStats(
            totalSessions: totalSessions,
            totalDurationMinutes: Int(totalDuration / 60),
            beforeBedSessions: beforeBedSessions.count,
            beforeBedDurationMinutes: Int(beforeBedDuration / 60),
            categoryBreakdown: categoryBreakdown,
            trackingStartDate: settings.trackingStartDate,
            trackingDays: Calendar.current.dateComponents([.day], from: settings.trackingStartDate ?? Date(), to: Date()).day ?? 0
        )
    }
    
    // MARK: - Data Clear
    
    /// 清除所有屏幕时间数据
    func clearAllData(keepSettings: Bool = true) {
        userDefaults.removeObject(forKey: sessionsKey)
        userDefaults.removeObject(forKey: achievementsKey)
        
        if !keepSettings {
            userDefaults.removeObject(forKey: settingsKey)
        }
        
        // 重置发布状态
        currentSession = nil
        todayStats = nil
        weeklyReport = nil
        correlation = nil
        achievements = []
        quickStats = nil
        
        // 重新加载设置
        if keepSettings {
            loadSettings()
        }
        
        print("✅ 屏幕时间数据已清除")
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func dateRange(from start: Date, to end: Date, interval: Component) -> [Date]? {
        var dates: [Date] = []
        var current = start
        
        while current <= end {
            dates.append(current)
            guard let next = date(byAdding: interval, value: 1, to: current) else { break }
            current = next
        }
        
        return dates.isEmpty ? nil : dates
    }
}
