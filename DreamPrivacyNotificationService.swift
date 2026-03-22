//
//  DreamPrivacyNotificationService.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import UserNotifications

// MARK: - Privacy Notification Service

/// 隐私通知服务
@MainActor
final class DreamPrivacyNotificationService {
    
    // MARK: - Singleton
    
    static let shared = DreamPrivacyNotificationService()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var privacySettings: PrivacySettings?
    
    var isPrivacyModeEnabled: Bool {
        privacySettings?.hideNotificationContent ?? false
    }
    
    // MARK: - Initialization
    
    private init() {
        loadPrivacySettings()
    }
    
    // MARK: - Public Methods
    
    /// 加载隐私设置
    func loadPrivacySettings() {
        // 从数据存储加载隐私设置
        // 简化实现
        privacySettings = PrivacySettings()
    }
    
    /// 配置通知隐私
    func configurePrivacyMode(enabled: Bool) async {
        privacySettings?.hideNotificationContent = enabled
        privacySettings?.showOnlyGenericNotifications = enabled
        
        if enabled {
            await requestAuthorization()
        }
    }
    
    /// 请求通知授权
    func requestAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            print("通知授权：\(granted ? "已授予" : "已拒绝")")
        } catch {
            print("请求通知授权失败：\(error)")
        }
    }
    
    /// 发送梦境提醒通知
    func sendDreamReminder(dreamTitle: String, isPrivate: Bool = false) async {
        let content = UNMutableNotificationContent()
        
        if isPrivacyModeEnabled || isPrivate {
            // 隐私模式：显示通用文本
            content.title = "DreamLog"
            content.body = "你有新的梦境记录"
            content.sound = .default
        } else {
            // 正常模式：显示具体内容
            content.title = "梦境记录"
            content.body = truncateTitle(dreamTitle)
            content.sound = .default
        }
        
        content.categoryIdentifier = "DREAM_REMINDER"
        content.threadIdentifier = "dreamlog"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 立即发送
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("发送通知失败：\(error)")
        }
    }
    
    /// 发送梦境洞察通知
    func sendDreamInsight(title: String, insight: String, isPrivate: Bool = false) async {
        let content = UNMutableNotificationContent()
        
        if isPrivacyModeEnabled || isPrivate {
            content.title = "DreamLog 洞察"
            content.body = "发现新的梦境模式"
        } else {
            content.title = title
            content.body = truncateText(insight, maxLength: 100)
        }
        
        content.categoryIdentifier = "DREAM_INSIGHT"
        content.threadIdentifier = "dreamlog"
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("发送洞察通知失败：\(error)")
        }
    }
    
    /// 发送梦境提醒 (自定义时间)
    func scheduleDreamReminder(title: String, date: Date, isPrivate: Bool = false) async {
        let content = UNMutableNotificationContent()
        
        if isPrivacyModeEnabled || isPrivate {
            content.title = "DreamLog"
            content.body = "记录梦境的时间到了"
        } else {
            content.title = "记录梦境"
            content.body = "该记录你的梦境了"
        }
        
        content.categoryIdentifier = "DREAM_REMINDER"
        content.threadIdentifier = "dreamlog"
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("安排提醒失败：\(error)")
        }
    }
    
    /// 取消所有通知
    func cancelAllNotifications() async {
        await notificationCenter.removeAllPendingNotificationRequests()
        await notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// 获取通知设置
    func getNotificationSettings() async -> UNNotificationSettings {
        return await notificationCenter.notificationSettings()
    }
    
    // MARK: - Private Methods
    
    private func truncateTitle(_ title: String) -> String {
        if title.count <= 30 {
            return title
        }
        return String(title.prefix(27)) + "..."
    }
    
    private func truncateText(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength - 3)) + "..."
    }
}

// MARK: - Notification Category

/// 通知类别配置
extension DreamPrivacyNotificationService {
    
    /// 注册通知类别
    static func registerNotificationCategories() {
        // 梦境提醒类别
        let dreamReminderCategory = UNNotificationCategory(
            identifier: "DREAM_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // 梦境洞察类别
        let dreamInsightCategory = UNNotificationCategory(
            identifier: "DREAM_INSIGHT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            dreamReminderCategory,
            dreamInsightCategory
        ])
    }
}

// MARK: - Widget Privacy

/// 小组件隐私扩展
extension DreamPrivacyNotificationService {
    
    /// 获取小组件显示的梦境标题
    func getWidgetDreamTitle(_ title: String) -> String {
        if privacySettings?.hideWidgetContent ?? false {
            return "梦境记录"
        }
        return truncateTitle(title)
    }
    
    /// 获取小组件显示的梦境内容
    func getWidgetDreamContent(_ content: String) -> String {
        if privacySettings?.hideWidgetContent ?? false {
            return "内容已隐藏"
        }
        return truncateText(content, maxLength: 50)
    }
}

// MARK: - Lock Screen Preview

/// 锁屏预览控制
extension DreamPrivacyNotificationService {
    
    /// 是否应该在锁屏上显示预览
    var shouldShowLockScreenPreview: Bool {
        !(privacySettings?.hideLockScreenPreview ?? true)
    }
    
    /// 获取锁屏预览文本
    func getLockScreenPreview(for notification: String) -> String {
        if privacySettings?.hideLockScreenPreview ?? true {
            return "通知"
        }
        return notification
    }
}
