//
//  SmartReminderService.swift
//  DreamLog
//
//  智能提醒服务 - Phase 6 个性化体验
//  基于用户数据分析，提供智能化的梦境记录提醒
//

import Foundation
import UserNotifications
import Combine

// MARK: - 提醒类型
enum ReminderType: String, Codable, CaseIterable, Identifiable {
    case optimalTime = "最佳时间"
    case bedtime = "睡前放松"
    case morning = "晨间回顾"
    case goalAchieved = "目标达成"
    case streak = "连续记录"
    case weekly = "每周总结"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .optimalTime: return "clock.fill"
        case .bedtime: return "moon.fill"
        case .morning: return "sun.max.fill"
        case .goalAchieved: return "trophy.fill"
        case .streak: return "flame.fill"
        case .weekly: return "calendar"
        }
    }
    
    var title: String {
        switch self {
        case .optimalTime: return "最佳记录时间"
        case .bedtime: return "睡前放松提醒"
        case .morning: return "晨间回顾提醒"
        case .goalAchieved: return "目标达成庆祝"
        case .streak: return "连续记录激励"
        case .weekly: return "每周总结"
        }
    }
}

// MARK: - 提醒配置
struct ReminderConfig: Codable {
    var isEnabled: Bool = true
    var optimalTimeEnabled: Bool = true
    var bedtimeEnabled: Bool = true
    var bedtimeTime: String = "22:00"
    var morningEnabled: Bool = true
    var morningTime: String = "08:00"
    var goalCelebrationEnabled: Bool = true
    var streakReminderEnabled: Bool = true
    var weeklySummaryEnabled: Bool = true
    var weeklySummaryDay: Int = 0 // 0 = Sunday, 1 = Monday, ...
    
    static let `default` = ReminderConfig()
}

// MARK: - 用户记录习惯分析
struct RecordingHabitAnalysis {
    var optimalHour: Int = 8 // 最佳记录小时 (0-23)
    var averageClarity: Double = 3.0
    var totalDreams: Int = 0
    var dreamsByHour: [Int: Int] = [:] // 按小时统计的梦境数量
    var mostActiveDay: Int = 0 // 最活跃的星期几
    var recordingStreak: Int = 0 // 连续记录天数
    var longestStreak: Int = 0
    
    // 分析用户记录习惯，找出最佳记录时间
    static func analyze(from dreamStore: DreamStore) -> RecordingHabitAnalysis {
        var analysis = RecordingHabitAnalysis()
        
        let dreams = dreamStore.dreams
        analysis.totalDreams = dreams.count
        
        if dreams.isEmpty {
            return analysis
        }
        
        // 统计每个时间段的记录数量
        var hourCounts: [Int: Int] = [:]
        var dayCounts: [Int: Int] = [:]
        var totalClarity: Double = 0
        var clarityCount: Int = 0
        
        for dream in dreams {
            let hour = Calendar.current.component(.hour, from: dream.date)
            let weekday = Calendar.current.component(.weekday, from: dream.date)
            
            hourCounts[hour, default: 0] += 1
            dayCounts[weekday, default: 0] += 1
            
            if dream.clarity > 0 {
                totalClarity += Double(dream.clarity)
                clarityCount += 1
            }
        }
        
        analysis.dreamsByHour = hourCounts
        analysis.averageClarity = clarityCount > 0 ? totalClarity / Double(clarityCount) : 3.0
        
        // 找出最活跃的小时
        if let mostActiveHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            analysis.optimalHour = mostActiveHour
        }
        
        // 找出最活跃的星期
        if let mostActiveDay = dayCounts.max(by: { $0.value < $1.value })?.key {
            analysis.mostActiveDay = mostActiveDay
        }
        
        // 计算连续记录天数
        analysis.recordingStreak = calculateStreak(from: dreams)
        analysis.longestStreak = calculateLongestStreak(from: dreams)
        
        return analysis
    }
    
    private static func calculateStreak(from dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let sortedDreams = dreams.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var streak = 1
        var currentDate = calendar.startOfDay(for: sortedDreams[0].date)
        
        for i in 1..<sortedDreams.count {
            let dreamDate = calendar.startOfDay(for: sortedDreams[i].date)
            let dayDifference = calendar.dateComponents([.day], from: dreamDate, to: currentDate).day ?? 0
            
            if dayDifference == 1 {
                streak += 1
                currentDate = dreamDate
            } else if dayDifference > 1 {
                break
            }
        }
        
        return streak
    }
    
    private static func calculateLongestStreak(from dreams: [Dream]) -> Int {
        guard !dreams.isEmpty else { return 0 }
        
        let sortedDreams = dreams.sorted { $0.date > $1.date }
        let calendar = Calendar.current
        var longestStreak = 1
        var currentStreak = 1
        var currentDate = calendar.startOfDay(for: sortedDreams[0].date)
        
        for i in 1..<sortedDreams.count {
            let dreamDate = calendar.startOfDay(for: sortedDreams[i].date)
            let dayDifference = calendar.dateComponents([.day], from: dreamDate, to: currentDate).day ?? 0
            
            if dayDifference == 1 {
                currentStreak += 1
                currentDate = dreamDate
            } else if dayDifference > 1 {
                longestStreak = max(longestStreak, currentStreak)
                currentStreak = 1
                currentDate = dreamDate
            }
        }
        
        return max(longestStreak, currentStreak)
    }
}

// MARK: - 智能提醒服务
class SmartReminderService: ObservableObject {
    static let shared = SmartReminderService()
    
    @Published var config: ReminderConfig = .default
    @Published var isAuthorized: Bool = false
    @Published var lastAnalysis: RecordingHabitAnalysis?
    
    private var cancellables = Set<AnyCancellable>()
    private let configKey = "smartReminderConfig"
    
    init() {
        loadConfig()
        checkAuthorization()
    }
    
    // MARK: - 配置管理
    
    func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(ReminderConfig.self, from: data) {
            self.config = config
        }
    }
    
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: configKey)
            scheduleAllReminders()
        }
    }
    
    // MARK: - 通知授权
    
    func checkAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                completion(granted)
            }
        }
    }
    
    // MARK: - 提醒调度
    
    func scheduleAllReminders() {
        guard config.isEnabled && isAuthorized else {
            cancelAllReminders()
            return
        }
        
        // 调度各类提醒
        if config.optimalTimeEnabled {
            scheduleOptimalTimeReminder()
        }
        
        if config.bedtimeEnabled {
            scheduleBedtimeReminder()
        }
        
        if config.morningEnabled {
            scheduleMorningReminder()
        }
        
        if config.weeklySummaryEnabled {
            scheduleWeeklySummaryReminder()
        }
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - 最佳时间提醒
    
    private func scheduleOptimalTimeReminder() {
        guard let analysis = lastAnalysis else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🌙 最佳记录时间"
        content.body = "根据数据分析，现在是您记录梦境的最佳时间！"
        content.sound = .default
        content.categoryIdentifier = "dream_reminder"
        content.userInfo["reminderType"] = ReminderType.optimalTime.rawValue
        
        var dateComponents = DateComponents()
        dateComponents.hour = analysis.optimalHour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "optimal_time_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 最佳时间提醒调度失败：\(error)")
            }
        }
    }
    
    // MARK: - 睡前提醒
    
    private func scheduleBedtimeReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🌙 睡前放松"
        content.body = "睡前花几分钟回顾今天的梦境，有助于提高梦境回忆能力哦~"
        content.sound = .default
        content.categoryIdentifier = "dream_reminder"
        content.userInfo["reminderType"] = ReminderType.bedtime.rawValue
        
        // 解析配置的时间
        let timeParts = config.bedtimeTime.split(separator: ":")
        guard let hour = Int(timeParts[0]), let minute = Int(timeParts[1]) else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "bedtime_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 睡前提醒调度失败：\(error)")
            }
        }
    }
    
    // MARK: - 晨间提醒
    
    private func scheduleMorningReminder() {
        let content = UNMutableNotificationContent()
        content.title = "☀️ 晨间回顾"
        content.body = "早上好！还记得昨晚做了什么梦吗？趁现在赶紧记录下来吧！"
        content.sound = .default
        content.categoryIdentifier = "dream_reminder"
        content.userInfo["reminderType"] = ReminderType.morning.rawValue
        
        // 解析配置的时间
        let timeParts = config.morningTime.split(separator: ":")
        guard let hour = Int(timeParts[0]), let minute = Int(timeParts[1]) else { return }
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "morning_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 晨间提醒调度失败：\(error)")
            }
        }
    }
    
    // MARK: - 每周总结提醒
    
    private func scheduleWeeklySummaryReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📊 每周梦境总结"
        content.body = "来看看你这周的梦境有什么有趣的发现吧！"
        content.sound = .default
        content.categoryIdentifier = "dream_reminder"
        content.userInfo["reminderType"] = ReminderType.weekly.rawValue
        
        var dateComponents = DateComponents()
        dateComponents.weekday = config.weeklySummaryDay + 1 // UNCalendarNotificationTrigger 使用 1-7
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_summary_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ 每周总结提醒调度失败：\(error)")
            }
        }
    }
    
    // MARK: - 目标达成庆祝
    
    func sendGoalAchievedNotification(goal: String) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 目标达成！"
        content.body = "恭喜你完成了\"\(goal)\"！继续保持这个好习惯！"
        content.sound = .default
        content.categoryIdentifier = "dream_celebration"
        content.userInfo["reminderType"] = ReminderType.goalAchieved.rawValue
        
        let request = UNNotificationRequest(
            identifier: "goal_achieved_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // 立即发送
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 连续记录激励
    
    func sendStreakNotification(days: Int) {
        let emojis = ["🔥", "⭐", "🌟", "✨", "💫", "🎯"]
        let emoji = emojis[min(days / 7, emojis.count - 1)]
        
        let content = UNMutableNotificationContent()
        content.title = "\(emoji) 连续记录 \(days) 天！"
        content.body = "太棒了！你已经连续记录了 \(days) 天的梦境，继续保持这个惊人的习惯！"
        content.sound = .default
        content.categoryIdentifier = "dream_celebration"
        content.userInfo["reminderType"] = ReminderType.streak.rawValue
        
        let request = UNNotificationRequest(
            identifier: "streak_\(days)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - 分析更新
    
    func updateAnalysis(from dreamStore: DreamStore) {
        lastAnalysis = RecordingHabitAnalysis.analyze(from: dreamStore)
        
        // 如果启用了最佳时间提醒且分析结果有变化，重新调度
        if config.isEnabled && config.optimalTimeEnabled && isAuthorized {
            scheduleOptimalTimeReminder()
        }
    }
    
    // MARK: - 通知类别注册
    
    static func registerNotificationCategories() {
        // 梦境提醒类别
        let dreamReminderCategory = UNNotificationCategory(
            identifier: "dream_reminder",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // 庆祝类别
        let celebrationCategory = UNNotificationCategory(
            identifier: "dream_celebration",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            dreamReminderCategory,
            celebrationCategory
        ])
    }
}
