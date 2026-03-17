//
//  DreamSmartNotificationService.swift
//  DreamLog
//
//  Phase 61: 智能通知与梦境洞察推送
//  核心服务：智能定时、洞察生成、推送管理
//

import Foundation
import UserNotifications
import SwiftData
import NaturalLanguage

@MainActor
class DreamSmartNotificationService: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var pendingNotifications: Int = 0
    @Published var lastWeeklySummaryDate: Date?
    @Published var lastMonthlyInsightDate: Date?
    
    static let shared = DreamSmartNotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?
    private var activityTimer: Timer?
    
    // 用户活跃时间追踪
    @Published var userActiveHours: [Int: Int] = [:] // hour -> count
    
    init() {
        setupNotificationCategories()
        checkAuthorization()
        startActivityTracking()
    }
    
    // MARK: - 初始化
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadNotificationConfig()
    }
    
    // MARK: - 通知分类设置
    
    private func setupNotificationCategories() {
        center.setNotificationCategories([
            .dreamReminder,
            .weeklySummary
        ])
        
        center.delegate = self as? UNUserNotificationCenterDelegate
    }
    
    // MARK: - 权限管理
    
    func checkAuthorization() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            
            if granted {
                await scheduleAllNotifications()
            }
            
            return granted
        } catch {
            print("❌ 通知权限请求失败：\(error)")
            return false
        }
    }
    
    // MARK: - 智能定时
    
    /// 基于用户活跃时间智能调整通知时间
    func calculateOptimalReminderTime() -> (hour: Int, minute: Int) {
        // 找出用户最活跃的时段
        let sortedHours = userActiveHours.sorted { $0.value > $1.value }
        
        if let mostActiveHour = sortedHours.first?.key {
            // 在用户最活跃时间前 1 小时提醒
            let reminderHour = (mostActiveHour - 1 + 24) % 24
            return (reminderHour, 0)
        }
        
        // 默认早上 8 点
        return (8, 0)
    }
    
    /// 追踪用户活跃时间
    private func startActivityTracking() {
        // 记录当前时间为活跃时间
        recordActivity()
        
        // 每 30 分钟记录一次
        activityTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordActivity()
            }
        }
    }
    
    private func recordActivity() {
        let hour = Calendar.current.component(.hour, from: Date())
        userActiveHours[hour, default: 0] += 1
    }
    
    // MARK: - 通知调度
    
    /// 调度所有通知
    func scheduleAllNotifications() async {
        guard let context = modelContext else { return }
        
        do {
            let configs = try context.fetch(FetchDescriptor<SmartNotificationConfig>())
            
            if let config = configs.first {
                // 基础提醒
                if config.isDreamReminderEnabled {
                    scheduleDreamReminder(hour: config.dreamReminderHour, minute: config.dreamReminderMinute)
                }
                
                if config.isBedtimeReminderEnabled {
                    scheduleBedtimeReminder(hour: config.bedtimeHour, minute: config.bedtimeMinute)
                }
                
                if config.isMorningReflectionEnabled {
                    scheduleMorningReflection()
                }
                
                // 定期摘要
                if config.isWeeklySummaryEnabled {
                    scheduleWeeklySummary()
                }
                
                if config.isMonthlyInsightEnabled {
                    scheduleMonthlyInsight()
                }
                
                // 挑战与成就
                if config.isChallengeReminderEnabled {
                    scheduleChallengeReminders()
                }
                
                // 清醒梦提示
                if config.isLucidDreamPromptEnabled {
                    scheduleLucidDreamPrompts(frequency: config.lucidDreamPromptFrequency)
                }
            }
        } catch {
            print("❌ 加载通知配置失败：\(error)")
        }
    }
    
    // MARK: - 梦境记录提醒
    
    func scheduleDreamReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🌙 记录你的梦"
        content.body = "昨晚的梦境还记得吗？花 1 分钟记录下来，发现潜意识的秘密！"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "dream_reminder"
        content.threadIdentifier = "dream_reminders"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.timeZone = TimeZone.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_dream_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ 设置梦境提醒失败：\(error)")
            } else {
                print("✅ 梦境提醒已设置：\(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // MARK: - 睡前提醒
    
    func scheduleBedtimeReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "😴 准备睡觉了吗？"
        content.body = "睡前放松，可能会有精彩的梦境哦～记得在床头准备好 DreamLog！"
        content.sound = .default
        content.categoryIdentifier = "bedtime_reminder"
        content.threadIdentifier = "bedtime_reminders"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.timeZone = TimeZone.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "bedtime_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - 晨间反思提醒
    
    func scheduleMorningReflection() {
        let content = UNMutableNotificationContent()
        content.title = "🌅 晨间反思时间"
        content.body = "昨晚的梦境带给你什么启示？花 2 分钟记录反思，深化自我认知。"
        content.sound = .default
        content.categoryIdentifier = "morning_reflection"
        content.threadIdentifier = "reflection_reminders"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        dateComponents.timeZone = TimeZone.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "morning_reflection",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - 每周摘要
    
    func scheduleWeeklySummary() {
        let content = UNMutableNotificationContent()
        content.title = "📊 本周梦境摘要"
        content.body = "查看你本周的梦境统计和洞察发现！"
        content.sound = .default
        content.categoryIdentifier = "weekly_summary"
        content.threadIdentifier = "weekly_summaries"
        
        // 每周日上午 10 点
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        dateComponents.timeZone = TimeZone.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "weekly_summary",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    /// 生成并发送每周摘要
    func generateAndSendWeeklySummary() async {
        guard let context = modelContext else { return }
        
        // 计算本周日期范围
        let calendar = Calendar.current
        let now = Date()
        guard let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)),
              let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return
        }
        
        // 检查是否已发送
        if let lastSent = lastWeeklySummaryDate,
           calendar.isDate(lastSent, inSameWeekAs: now) {
            return
        }
        
        // 生成摘要数据
        let summary = await generateWeeklySummaryData(
            from: weekStartDate,
            to: weekEndDate,
            context: context
        )
        
        // 创建通知
        let content = UNMutableNotificationContent()
        content.title = "📊 本周梦境摘要"
        content.body = "本周记录了 \(summary.totalDreams) 个梦境，主要情绪：\(summary.topEmotions.first?.emotion ?? "未知")"
        content.sound = .default
        content.categoryIdentifier = "weekly_summary"
        content.threadIdentifier = "weekly_summaries"
        
        // 编码摘要数据
        if let data = try? JSONEncoder().encode(summary) {
            content.userInfo["summaryData"] = data
        }
        
        let request = UNNotificationRequest(
            identifier: "weekly_summary_\(weekStartDate.timeIntervalSince1970)",
            content: content,
            trigger: nil // 立即发送
        )
        
        await center.add(request)
        
        // 更新最后发送时间
        lastWeeklySummaryDate = now
    }
    
    /// 生成每周摘要数据
    private func generateWeeklySummaryData(
        from startDate: Date,
        to endDate: Date,
        context: ModelContext
    ) async -> WeeklySummaryData {
        // 这里需要从 DreamStore 或其他数据源获取梦境数据
        // 简化实现，返回示例数据
        
        return WeeklySummaryData(
            totalDreams: Int.random(in: 3...10),
            averageClarity: Double.random(in: 3.0...5.0),
            topEmotions: [("平静", 5), ("快乐", 3), ("兴奋", 2)],
            topTags: ["飞行", "水", "自由"],
            lucidDreamCount: Int.random(in: 0...3),
            insight: "本周你的梦境以积极情绪为主，飞行元素频繁出现，可能反映了对自由的渴望。",
            weekStartDate: startDate,
            weekEndDate: endDate
        )
    }
    
    // MARK: - 月度洞察
    
    func scheduleMonthlyInsight() {
        let content = UNMutableNotificationContent()
        content.title = "🧠 月度梦境洞察"
        content.body = "深度分析你上个月的梦境模式和趋势！"
        content.sound = .default
        content.categoryIdentifier = "monthly_insight"
        content.threadIdentifier = "monthly_insights"
        
        // 每月 1 日上午 10 点
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 10
        dateComponents.minute = 0
        dateComponents.timeZone = TimeZone.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "monthly_insight",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - 挑战提醒
    
    func scheduleChallengeReminders() {
        // 每天早上 9 点提醒查看挑战
        let content = UNMutableNotificationContent()
        content.title = "🎯 今日挑战"
        content.body = "看看今天的梦境挑战是什么？完成挑战获得积分和徽章！"
        content.sound = .default
        content.categoryIdentifier = "challenge_reminder"
        content.threadIdentifier = "challenge_reminders"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        dateComponents.timeZone = TimeZone.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_challenge",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - 清醒梦提示
    
    func scheduleLucidDreamPrompts(frequency: LucidDreamPromptFrequency) {
        let content = UNMutableNotificationContent()
        content.title = "👁️ 现实检查"
        content.body = "你现在是在做梦吗？捏住鼻子试试能不能呼吸～"
        content.sound = .default
        content.categoryIdentifier = "lucid_dream_prompt"
        content.threadIdentifier = "lucid_dream_prompts"
        
        // 使用间隔触发器
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: frequency.intervalSeconds,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "lucid_dream_prompt",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - 模式发现提醒
    
    func checkAndNotifyPatterns() async {
        guard let context = modelContext else { return }
        
        // 检查是否有新的梦境模式发现
        // 这里需要集成 DreamPatternPredictionService
        
        // 示例：如果发现重复梦境元素
        let hasNewPattern = false // 实际实现中需要检查
        
        if hasNewPattern {
            let content = UNMutableNotificationContent()
            content.title = "🔍 发现梦境模式"
            content.body = "我们发现你的梦境中反复出现「水」元素，这可能代表情绪波动。点击查看详细分析！"
            content.sound = .default
            content.categoryIdentifier = "pattern_alert"
            
            let request = UNNotificationRequest(
                identifier: "pattern_discovery_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            await center.add(request)
        }
    }
    
    // MARK: - 配置管理
    
    func loadNotificationConfig() {
        guard let context = modelContext else { return }
        
        do {
            let configs = try context.fetch(FetchDescriptor<SmartNotificationConfig>())
            if let config = configs.first {
                // 应用配置
                print("✅ 已加载通知配置")
            }
        } catch {
            print("❌ 加载通知配置失败：\(error)")
        }
    }
    
    func saveNotificationConfig(_ config: SmartNotificationConfig) {
        guard let context = modelContext else { return }
        
        config.updatedAt = Date()
        
        do {
            try context.save()
            print("✅ 通知配置已保存")
            
            // 重新调度所有通知
            Task {
                await scheduleAllNotifications()
            }
        } catch {
            print("❌ 保存通知配置失败：\(error)")
        }
    }
    
    // MARK: - 清理
    
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
    
    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension DreamSmartNotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 前台显示通知
        DispatchQueue.main.async {
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 处理通知交互
        let actionIdentifier = response.actionIdentifier
        
        switch actionIdentifier {
        case "RECORD_DREAM":
            // 打开快速记录界面
            break
        case "SNOOZE":
            // 稍后提醒 (15 分钟后)
            break
        case "VIEW_SUMMARY":
            // 打开摘要页面
            break
        case "SHARE":
            // 打开分享界面
            break
        default:
            break
        }
        
        completionHandler()
    }
}
