//
//  DreamReflectionReminderService.swift
//  DreamLog
//
//  Phase 50: 反思提醒服务
//  智能提醒用户进行梦境反思
//

import Foundation
import UserNotifications

// MARK: - 提醒配置

/// 反思提醒配置
struct ReflectionReminderConfig: Codable {
    var isEnabled: Bool
    var reminderTime: String  // HH:mm 格式
    var reminderFrequency: ReminderFrequency
    var remindAfterDreamRecord: Bool
    var remindBeforeSleep: Bool
    var remindOnWeekend: Bool
    var customMessage: String?
    
    enum ReminderFrequency: String, CaseIterable, Codable {
        case daily = "每天"
        case weekdays = "工作日"
        case weekends = "周末"
        case weekly = "每周"
        case biweekly = "每两周"
        
        var displayName: String { rawValue }
    }
    
    static var `default`: ReflectionReminderConfig {
        ReflectionReminderConfig(
            isEnabled: true,
            reminderTime: "21:00",
            reminderFrequency: .daily,
            remindAfterDreamRecord: true,
            remindBeforeSleep: true,
            remindOnWeekend: true,
            customMessage: nil
        )
    }
}

// MARK: - 提醒服务

/// 反思提醒服务
@MainActor
class ReflectionReminderService {
    
    static let shared = ReflectionReminderService()
    
    private let userDefaults: UserDefaults
    private let notificationCenter: UNUserNotificationCenter
    
    private let configKey = "reflection_reminder_config"
    private let scheduledIDsKey = "reflection_reminder_scheduled_ids"
    
    init(userDefaults: UserDefaults = .standard,
         notificationCenter: UNUserNotificationCenter = .current()) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
    }
    
    // MARK: - 配置管理
    
    var config: ReflectionReminderConfig {
        get {
            guard let data = userDefaults.data(forKey: configKey),
                  let config = try? JSONDecoder().decode(ReflectionReminderConfig.self, from: data) else {
                return .default
            }
            return config
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults.set(encoded, forKey: configKey)
            }
            scheduleReminders()
        }
    }
    
    // MARK: - 提醒调度
    
    /// 调度提醒
    func scheduleReminders() {
        guard config.isEnabled else {
            cancelAllReminders()
            return
        }
        
        let timeComponents = config.reminderTime.split(separator: ":")
        guard timeComponents.count == 2,
              let hour = Int(timeComponents[0]),
              let minute = Int(timeComponents[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return
        }
        
        // 移除旧提醒
        cancelAllReminders()
        
        // 创建新提醒
        switch config.reminderFrequency {
        case .daily:
            scheduleDailyReminder(hour: hour, minute: minute)
        case .weekdays:
            scheduleWeekdayReminders(hour: hour, minute: minute)
        case .weekends:
            scheduleWeekendReminders(hour: hour, minute: minute)
        case .weekly:
            scheduleWeeklyReminder(hour: hour, minute: minute)
        case .biweekly:
            scheduleBiweeklyReminder(hour: hour, minute: minute)
        }
        
        // 记录梦境后提醒
        if config.remindAfterDreamRecord {
            scheduleAfterDreamRecordReminder()
        }
        
        // 睡前提醒
        if config.remindBeforeSleep {
            scheduleBeforeSleepReminder()
        }
    }
    
    private func scheduleDailyReminder(hour: Int, minute: Int) {
        let content = createReminderContent(
            title: "🌙 梦境反思时间",
            body: "花几分钟记录今天的梦境洞察吧",
            identifier: "daily_reflection"
        )
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.calendar = Calendar.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        scheduleNotification(content: content, trigger: trigger, identifier: "daily_reflection")
    }
    
    private func scheduleWeekdayReminders(hour: Int, minute: Int) {
        for weekday in 2...6 {  // Monday to Friday
            let content = createReminderContent(
                title: "🌙 梦境反思时间",
                body: "花几分钟记录今天的梦境洞察吧",
                identifier: "weekday_reflection_\(weekday)"
            )
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday
            dateComponents.calendar = Calendar.current
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            scheduleNotification(content: content, trigger: trigger, identifier: "weekday_reflection_\(weekday)")
        }
    }
    
    private func scheduleWeekendReminders(hour: Int, minute: Int) {
        for weekday in [1, 7] {  // Sunday and Saturday
            let content = createReminderContent(
                title: "🌙 周末梦境反思",
                body: "周末是深度反思的好时机，记录你的梦境洞察吧",
                identifier: "weekend_reflection_\(weekday)"
            )
            
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.weekday = weekday
            dateComponents.calendar = Calendar.current
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            scheduleNotification(content: content, trigger: trigger, identifier: "weekend_reflection_\(weekday)")
        }
    }
    
    private func scheduleWeeklyReminder(hour: Int, minute: Int) {
        let content = createReminderContent(
            title: "📊 每周梦境反思",
            body: "回顾这一周的梦境，有什么新的发现吗？",
            identifier: "weekly_reflection"
        )
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = 1  // Sunday
        dateComponents.calendar = Calendar.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        scheduleNotification(content: content, trigger: trigger, identifier: "weekly_reflection")
    }
    
    private func scheduleBiweeklyReminder(hour: Int, minute: Int) {
        // 每两周提醒一次，使用间隔触发器
        let content = createReminderContent(
            title: "🌟 双周梦境反思",
            body: "深度回顾过去两周的梦境模式和洞察",
            identifier: "biweekly_reflection"
        )
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 14 * 24 * 60 * 60,  // 14 days
            repeats: true
        )
        scheduleNotification(content: content, trigger: trigger, identifier: "biweekly_reflection")
    }
    
    private func scheduleAfterDreamRecordReminder() {
        // 这个提醒在记录梦境后动态调度
        // 由 DreamStore 在保存梦境后调用
    }
    
    private func scheduleBeforeSleepReminder() {
        // 睡前 30 分钟提醒
        let content = createReminderContent(
            title: "😴 睡前准备",
            body: "睡前回顾一下今天的梦境，有助于提高梦境回忆能力",
            identifier: "before_sleep"
        )
        
        // 假设睡前时间是 22:30
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 30
        dateComponents.calendar = Calendar.current
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        scheduleNotification(content: content, trigger: trigger, identifier: "before_sleep")
    }
    
    // MARK: - 通知内容创建
    
    private func createReminderContent(title: String, body: String, identifier: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "reflection_reminder"
        
        if let customMessage = config.customMessage, !customMessage.isEmpty {
            content.body = customMessage
        }
        
        content.userInfo = ["type": "reflection_reminder", "identifier": identifier]
        
        return content
    }
    
    // MARK: - 通知调度
    
    private func scheduleNotification(content: UNMutableNotificationContent,
                                      trigger: UNNotificationTrigger,
                                      identifier: String) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ 调度反思提醒失败：\(error)")
            } else {
                print("✅ 反思提醒已调度：\(identifier)")
            }
        }
    }
    
    // MARK: - 取消提醒
    
    /// 取消所有提醒
    func cancelAllReminders() {
        let identifiers = userDefaults.stringArray(forKey: scheduledIDsKey) ?? []
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
        userDefaults.set([], forKey: scheduledIDsKey)
    }
    
    /// 取消特定提醒
    func cancelReminder(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    // MARK: - 触发反思提醒
    
    /// 记录梦境后触发反思提醒
    func triggerAfterDreamRecord() {
        guard config.remindAfterDreamRecord else { return }
        
        let content = createReminderContent(
            title: "📝 记录反思",
            body: "梦境已保存！现在花 2 分钟记录你的洞察吧",
            identifier: "after_dream_record"
        )
        
        // 5 分钟后提醒
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 300, repeats: false)
        scheduleNotification(content: content, trigger: trigger, identifier: "after_dream_record")
    }
    
    // MARK: - 权限请求
    
    /// 请求通知权限
    func requestAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    /// 检查通知权限
    var hasPermission: Bool {
        get async {
            let settings = await notificationCenter.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }
}

// MARK: - 通知类别

extension ReflectionReminderService {
    
    /// 注册通知类别
    static func registerNotificationCategories() {
        let reflectAction = UNNotificationAction(
            identifier: "REFLECT_NOW",
            title: "立即反思",
            options: .foreground
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "稍后提醒",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "reflection_reminder",
            actions: [reflectAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
