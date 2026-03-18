//
//  DreamSleepReminderService.swift
//  DreamLog - 智能睡眠提醒服务
//
//  Phase 64: 健康集成与睡眠追踪 🍎💤
//  创建时间：2026-03-18
//

import Foundation
import UserNotifications

// MARK: - 智能睡眠提醒服务

/// 智能睡眠提醒服务
@MainActor
final class DreamSleepReminderService {
    
    // MARK: - 单例
    
    static let shared = DreamSleepReminderService()
    
    // MARK: - 属性
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var reminders: [String: UNNotificationRequest] = [:]
    
    // MARK: - 初始化
    
    init() {}
    
    // MARK: - 通知授权
    
    /// 请求通知授权
    func requestAuthorization() async throws -> Bool {
        let status = await notificationCenter.notificationSettings().authorizationStatus
        
        if status == .authorized || status == .provisional {
            return true
        }
        
        return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    /// 检查通知权限
    func checkNotificationPermission() async -> Bool {
        let status = await notificationCenter.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
    }
    
    // MARK: - 睡前提醒
    
    /// 安排睡前提醒
    /// - Parameters:
    ///   - preferredTime: 偏好睡前时间
    ///   - offset: 提前多久提醒（秒）
    func scheduleBedtimeReminder(preferredTime: Date, offset: TimeInterval = 1800) async {
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else { return }
        
        let calendar = Calendar.current
        let reminderTime = calendar.date(byAdding: .second, value: -Int(offset), to: preferredTime) ?? preferredTime
        
        let content = UNMutableNotificationContent()
        content.title = "🌙 睡前准备时间"
        content.body = "该放松一下准备睡觉了。记得睡前回顾今天的梦境，或尝试梦境孵育。"
        content.sound = .default
        content.categoryIdentifier = "BEDTIME_REMINDER"
        content.userInfo = ["type": "bedtime"]
        
        let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "dreamlog.bedtime.\(preferredTime.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            reminders["bedtime"] = request
            print("✅ 睡前提醒已安排：\(reminderTime)")
        } catch {
            print("❌ 安排睡前提醒失败：\(error)")
        }
    }
    
    /// 取消睡前提醒
    func cancelBedtimeReminder() async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dreamlog.bedtime"])
        reminders.removeValue(forKey: "bedtime")
        print("✅ 睡前提醒已取消")
    }
    
    // MARK: - 晨间记录提醒
    
    /// 安排晨间梦境记录提醒
    /// - Parameters:
    ///   - wakeUpTime: 起床时间
    ///   - offset: 起床后多久提醒（秒）
    func scheduleMorningRecordingReminder(wakeUpTime: Date, offset: TimeInterval = 900) async {
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else { return }
        
        let calendar = Calendar.current
        let reminderTime = calendar.date(byAdding: .second, value: Int(offset), to: wakeUpTime) ?? wakeUpTime
        
        let content = UNMutableNotificationContent()
        content.title = "☀️ 晨间记录时间"
        content.body = "起床后是记录梦境的最佳时机！趁记忆还清晰，快记录下昨晚的梦境吧。"
        content.sound = .default
        content.categoryIdentifier = "MORNING_RECORDING"
        content.userInfo = ["type": "morning_recording"]
        
        let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "dreamlog.morning.\(wakeUpTime.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            reminders["morning"] = request
            print("✅ 晨间记录提醒已安排：\(reminderTime)")
        } catch {
            print("❌ 安排晨间提醒失败：\(error)")
        }
    }
    
    /// 取消晨间记录提醒
    func cancelMorningRecordingReminder() async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dreamlog.morning"])
        reminders.removeValue(forKey: "morning")
        print("✅ 晨间记录提醒已取消")
    }
    
    // MARK: - 最佳记录时机提醒
    
    /// 安排最佳梦境记录时机提醒（REM 睡眠后）
    /// - Parameter estimatedWakeTime: 预计起床时间
    func scheduleOptimalRecordingReminder(estimatedWakeTime: Date) async {
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else { return }
        
        // REM 睡眠周期约 90 分钟，在预计起床时间前安排
        let calendar = Calendar.current
        let reminderTime = calendar.date(byAdding: .minute, value: -90, to: estimatedWakeTime) ?? estimatedWakeTime
        
        let content = UNMutableNotificationContent()
        content.title = "💭 梦境回忆时机"
        content.body = "现在处于 REM 睡眠后期，是回忆梦境的最佳时机。如果醒来，请立即记录！"
        content.sound = .default
        content.categoryIdentifier = "OPTIMAL_RECORDING"
        content.userInfo = ["type": "optimal_recording"]
        
        // 由于这是基于睡眠阶段的智能提醒，实际实现需要 HealthKit 数据
        // 这里简化为固定时间提醒
        let dateComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "dreamlog.optimal.\(estimatedWakeTime.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            reminders["optimal"] = request
            print("✅ 最佳记录时机提醒已安排：\(reminderTime)")
        } catch {
            print("❌ 安排最佳时机提醒失败：\(error)")
        }
    }
    
    /// 取消最佳记录时机提醒
    func cancelOptimalRecordingReminder() async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dreamlog.optimal"])
        reminders.removeValue(forKey: "optimal")
        print("✅ 最佳记录时机提醒已取消")
    }
    
    // MARK: - 睡眠目标提醒
    
    /// 安排睡眠目标达成提醒
    /// - Parameters:
    ///   - goal: 睡眠目标时长（秒）
    ///   - bedtime: 入睡时间
    func scheduleSleepGoalReminder(goal: TimeInterval, bedtime: Date) async {
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else { return }
        
        let calendar = Calendar.current
        let targetWakeTime = calendar.date(byAdding: .second, value: Int(goal), to: bedtime) ?? bedtime
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 睡眠目标"
        content.body = "你已设定 \(Int(goal / 3600)) 小时的睡眠目标。祝你有个好梦！"
        content.sound = .default
        content.categoryIdentifier = "SLEEP_GOAL"
        content.userInfo = ["type": "sleep_goal", "goal": goal]
        
        // 睡前提醒
        let bedtimeComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let bedtimeTrigger = UNCalendarNotificationTrigger(
            dateMatching: bedtimeComponents,
            repeats: false
        )
        
        let bedtimeRequest = UNNotificationRequest(
            identifier: "dreamlog.goal.bedtime.\(bedtime.timeIntervalSince1970)",
            content: content,
            trigger: bedtimeTrigger
        )
        
        do {
            try await notificationCenter.add(bedtimeRequest)
            reminders["goal_bedtime"] = bedtimeRequest
            
            // 起床提醒（目标达成）
            let wakeContent = UNMutableNotificationContent()
            wakeContent.title = "✅ 睡眠目标达成"
            wakeContent.body = "恭喜你完成了 \(Int(goal / 3600)) 小时的睡眠目标！"
            wakeContent.sound = .default
            wakeContent.categoryIdentifier = "SLEEP_GOAL_ACHIEVED"
            wakeContent.userInfo = ["type": "goal_achieved"]
            
            let wakeComponents = calendar.dateComponents([.hour, .minute], from: targetWakeTime)
            let wakeTrigger = UNCalendarNotificationTrigger(
                dateMatching: wakeComponents,
                repeats: false
            )
            
            let wakeRequest = UNNotificationRequest(
                identifier: "dreamlog.goal.wake.\(targetWakeTime.timeIntervalSince1970)",
                content: wakeContent,
                trigger: wakeTrigger
            )
            
            try await notificationCenter.add(wakeRequest)
            reminders["goal_wake"] = wakeRequest
            
            print("✅ 睡眠目标提醒已安排")
        } catch {
            print("❌ 安排睡眠目标提醒失败：\(error)")
        }
    }
    
    /// 取消睡眠目标提醒
    func cancelSleepGoalReminder() async {
        await notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["dreamlog.goal.bedtime", "dreamlog.goal.wake"]
        )
        reminders.removeValue(forKey: "goal_bedtime")
        reminders.removeValue(forKey: "goal_wake")
        print("✅ 睡眠目标提醒已取消")
    }
    
    // MARK: - 连续记录鼓励提醒
    
    /// 安排连续记录鼓励提醒
    /// - Parameter streak: 当前连续记录天数
    func scheduleStreakEncouragement(streak: Int) async {
        guard streak > 0 && streak % 7 == 0 else { return } // 每 7 天鼓励一次
        
        let hasPermission = await checkNotificationPermission()
        guard hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        
        if streak == 7 {
            content.title = "🔥 连续记录 7 天！"
            content.body = "太棒了！你已经连续记录了一周的梦境。继续保持这个好习惯！"
        } else if streak == 30 {
            content.title = "🏆 连续记录 30 天！"
            content.body = "惊人的成就！你已经连续记录了一个月的梦境。你是真正的梦境探索者！"
        } else {
            content.title = "✨ 连续记录 \(streak) 天"
            content.body = "继续保持！你的坚持会让梦境记忆越来越清晰。"
        }
        
        content.sound = .default
        content.categoryIdentifier = "STREAK_ENCOURAGEMENT"
        content.userInfo = ["type": "streak", "count": streak]
        
        // 立即触发（实际应用中应该安排在合适的时间）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "dreamlog.streak.\(streak)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            reminders["streak_\(streak)"] = request
            print("✅ 连续记录鼓励提醒已发送：\(streak) 天")
        } catch {
            print("❌ 发送鼓励提醒失败：\(error)")
        }
    }
    
    // MARK: - 批量取消所有提醒
    
    /// 取消所有提醒
    func cancelAllReminders() async {
        await notificationCenter.removeAllPendingNotificationRequests()
        reminders.removeAll()
        print("✅ 所有提醒已取消")
    }
    
    /// 获取所有待处理的提醒
    func getPendingReminders() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - 通知分类注册
    
    /// 注册通知分类
    func registerNotificationCategories() {
        // 睡前提醒分类
        let bedtimeAction = UNNotificationAction(
            identifier: "BEDTIME_ACTION",
            title: "开始睡前冥想",
            options: .foreground
        )
        
        let bedtimeCategory = UNNotificationCategory(
            identifier: "BEDTIME_REMINDER",
            actions: [bedtimeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 晨间记录分类
        let recordAction = UNNotificationAction(
            identifier: "RECORD_ACTION",
            title: "立即记录",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "15 分钟后提醒",
            options: []
        )
        
        let morningCategory = UNNotificationCategory(
            identifier: "MORNING_RECORDING",
            actions: [recordAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 注册分类
        notificationCenter.setNotificationCategories([bedtimeCategory, morningCategory])
    }
}

// MARK: - 通知扩展

extension DreamSleepReminderService {
    
    /// 智能提醒配置
    struct SmartReminderConfig {
        var bedtimeReminderEnabled: Bool = true
        var morningReminderEnabled: Bool = true
        var optimalTimingEnabled: Bool = false
        var goalRemindersEnabled: Bool = true
        var streakEncouragementEnabled: Bool = true
        
        var bedtimeOffset: TimeInterval = 1800 // 30 分钟
        var morningOffset: TimeInterval = 900 // 15 分钟
        
        var preferredBedtime: Date?
        var preferredWakeTime: Date?
        var sleepGoal: TimeInterval = 28800 // 8 小时
    }
    
    /// 应用智能提醒配置
    func applyConfig(_ config: SmartReminderConfig) async {
        // 取消所有现有提醒
        await cancelAllReminders()
        
        // 注册通知分类
        registerNotificationCategories()
        
        // 请求授权
        do {
            _ = try await requestAuthorization()
        } catch {
            print("通知授权失败：\(error)")
            return
        }
        
        // 根据配置重新安排提醒
        if config.bedtimeReminderEnabled, let bedtime = config.preferredBedtime {
            await scheduleBedtimeReminder(preferredTime: bedtime, offset: config.bedtimeOffset)
        }
        
        if config.morningReminderEnabled, let wakeTime = config.preferredWakeTime {
            await scheduleMorningRecordingReminder(wakeUpTime: wakeTime, offset: config.morningOffset)
        }
        
        if config.optimalTimingEnabled, let wakeTime = config.preferredWakeTime {
            await scheduleOptimalRecordingReminder(estimatedWakeTime: wakeTime)
        }
        
        if config.goalRemindersEnabled, let bedtime = config.preferredBedtime {
            await scheduleSleepGoalReminder(goal: config.sleepGoal, bedtime: bedtime)
        }
    }
}

// MARK: - Preview (用于 SwiftUI Preview)

#if DEBUG
struct DreamSleepReminderService_Previews: PreviewProvider {
    static var previews: some View {
        Text("DreamSleepReminderService")
            .onAppear {
                Task {
                    await DreamSleepReminderService.shared.requestAuthorization()
                }
            }
    }
}
#endif
