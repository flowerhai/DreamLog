//
//  NotificationService.swift
//  DreamLog
//
//  通知服务：梦境提醒和每日推送
//

import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var hasPendingNotifications: Bool = false
    
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    init() {
        checkAuthorization()
    }
    
    // MARK: - 权限检查
    func checkAuthorization() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - 请求权限
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("❌ 通知权限请求失败：\(error)")
            return false
        }
    }
    
    // MARK: - 设置每日提醒
    func scheduleDailyReminder(hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "🌙 记录你的梦"
        content.body = "昨晚的梦境还记得吗？花 1 分钟记录下来吧！"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "dream_reminder"
        
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
                print("❌ 设置每日提醒失败：\(error)")
            } else {
                print("✅ 每日提醒已设置：\(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // MARK: - 设置睡前提醒
    func scheduleBedtimeReminder(hour: Int = 22, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "😴 准备睡觉了吗？"
        content.body = "睡前放松，可能会有精彩的梦境哦～记得在床头准备好 DreamLog！"
        content.sound = .default
        content.categoryIdentifier = "bedtime_reminder"
        
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
        
        center.add(request) { error in
            if let error = error {
                print("❌ 设置睡前提醒失败：\(error)")
            } else {
                print("✅ 睡前提醒已设置：\(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // MARK: - 取消所有提醒
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        print("✅ 已取消所有通知")
    }
    
    // MARK: - 取消特定提醒
    func cancelNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        print("✅ 已取消通知：\(id)")
    }
    
    // MARK: - 检查是否有待处理的通知
    func checkPendingNotifications() {
        center.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                self.hasPendingNotifications = !requests.isEmpty
            }
        }
    }
}

// MARK: - 通知分类
extension UNNotificationCategory {
    static let dreamReminder = UNNotificationCategory(
        identifier: "dream_reminder",
        actions: [],
        intentIdentifiers: [],
        options: []
    )
    
    static let bedtimeReminder = UNNotificationCategory(
        identifier: "bedtime_reminder",
        actions: [],
        intentIdentifiers: [],
        options: []
    )
}
