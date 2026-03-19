//
//  DreamNotificationService.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  通知核心服务
//

import Foundation
import UserNotifications
import SwiftData

@MainActor
public final class DreamNotificationService: @unchecked Sendable {
    
    // MARK: - Singleton
    
    public static let shared = DreamNotificationService()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?
    private var settingsCache: DreamNotificationSettings?
    private let scheduleCache = NSCache<NSString, NotificationScheduleConfig>()
    
    // MARK: - Initialization
    
    private init() {}
    
    /// 初始化服务
    public func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupNotificationDelegate()
        loadSettings()
    }
    
    // MARK: - Setup
    
    private func setupNotificationDelegate() {
        notificationCenter.delegate = self
    }
    
    /// 请求通知权限
    public func requestAuthorization() async throws -> Bool {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        return try await withCheckedThrowingContinuation { continuation in
            notificationCenter.requestAuthorization(options: authOptions) { granted, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// 检查通知权限状态
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// 注册通知类别和动作
    public func registerNotificationCategories() {
        // 记录梦境动作
        let recordAction = UNNotificationAction(
            identifier: DreamNotificationAction.recordDream.rawValue,
            title: DreamNotificationAction.recordDream.title,
            options: .foreground
        )
        
        // 稍后提醒动作
        let snoozeAction = UNNotificationAction(
            identifier: DreamNotificationAction.snooze.rawValue,
            title: DreamNotificationAction.snooze.title,
            options: []
        )
        
        // 查看详情动作
        let viewAction = UNNotificationAction(
            identifier: DreamNotificationAction.viewDetails.rawValue,
            title: DreamNotificationAction.viewDetails.title,
            options: .foreground
        )
        
        // 现实检查动作
        let realityCheckAction = UNNotificationAction(
            identifier: DreamNotificationAction.realityCheck.rawValue,
            title: DreamNotificationAction.realityCheck.title,
            options: .foreground
        )
        
        // 开始冥想动作
        let meditationAction = UNNotificationAction(
            identifier: DreamNotificationAction.startMeditation.rawValue,
            title: DreamNotificationAction.startMeditation.title,
            options: .foreground
        )
        
        // 提醒类别
        let reminderCategory = UNNotificationCategory(
            identifier: "DREAM_REMINDER",
            actions: [recordAction, snoozeAction, viewAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 洞察类别
        let insightCategory = UNNotificationCategory(
            identifier: "DREAM_INSIGHT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 清醒梦类别
        let lucidCategory = UNNotificationCategory(
            identifier: "DREAM_LUCID",
            actions: [realityCheckAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 冥想类别
        let meditationCategory = UNNotificationCategory(
            identifier: "DREAM_MEDITATION",
            actions: [meditationAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            reminderCategory,
            insightCategory,
            lucidCategory,
            meditationCategory
        ])
    }
    
    private var dismissAction: UNNotificationAction {
        UNNotificationAction(
            identifier: DreamNotificationAction.dismiss.rawValue,
            title: DreamNotificationAction.dismiss.title,
            options: .destructive
        )
    }
    
    // MARK: - Settings Management
    
    /// 加载设置
    public func loadSettings() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationSettings>()
            let settings = try context.fetch(descriptor).first
            self.settingsCache = settings ?? DreamNotificationSettings()
        } catch {
            print("Failed to load notification settings: \(error)")
            self.settingsCache = DreamNotificationSettings()
        }
    }
    
    /// 获取设置
    public var settings: DreamNotificationSettings {
        settingsCache ?? DreamNotificationSettings()
    }
    
    /// 更新设置
    public func updateSettings(_ settings: DreamNotificationSettings) async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationSettings>()
            let existing = try context.fetch(descriptor).first
            
            if let existing = existing {
                existing.isNotificationsEnabled = settings.isNotificationsEnabled
                existing.enabledTypeIds = settings.enabledTypeIds
                existing.quietStartHour = settings.quietStartHour
                existing.quietEndHour = settings.quietEndHour
                existing.isQuietHoursEnabled = settings.isQuietHoursEnabled
                existing.isCrossDayQuietHours = settings.isCrossDayQuietHours
                existing.soundEnabled = settings.soundEnabled
                existing.vibrationEnabled = settings.vibrationEnabled
                existing.badgeEnabled = settings.badgeEnabled
                existing.showOnLockScreen = settings.showOnLockScreen
                existing.showInHistory = settings.showInHistory
                existing.smartSchedulingEnabled = settings.smartSchedulingEnabled
                existing.lastModified = Date()
            } else {
                context.insert(settings)
            }
            
            try context.save()
            settingsCache = settings
        } catch {
            print("Failed to update notification settings: \(error)")
        }
    }
    
    // MARK: - Scheduling
    
    /// 调度通知
    public func scheduleNotification(
        type: DreamNotificationType,
        config: NotificationScheduleConfig,
        title: String,
        body: String,
        userInfo: [String: Any] = [:]
    ) async throws -> String {
        guard settings.isTypeEnabled(type.identifier) else {
            throw NotificationError.typeDisabled
        }
        
        guard !settings.isCurrentlyInQuietHours || type.priority == .critical else {
            throw NotificationError.inQuietHours
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = settings.soundEnabled ? .default : nil
        content.badge = settings.badgeEnabled ? 1 : nil
        content.userInfo = userInfo
        content.categoryIdentifier = categoryIdentifierForType(type)
        
        let trigger = createTriggerForConfig(config)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        
        // 记录到历史
        await recordScheduledNotification(
            typeId: type.identifier,
            title: title,
            body: body,
            scheduledDate: triggerNextDate(from: trigger),
            metadata: userInfo as? [String: String] ?? [:]
        )
        
        return request.identifier
    }
    
    /// 创建触发器
    private func createTriggerForConfig(_ config: NotificationScheduleConfig) -> UNNotificationTrigger {
        switch config.type {
        case .fixedTime:
            guard let time = config.time else {
                return createDefaultTrigger()
            }
            
            var dateComponents = DateComponents()
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            dateComponents.timeZone = TimeZone(identifier: time.timeZone ?? TimeZone.current.identifier)
            
            if let recurrence = config.recurrence {
                switch recurrence.frequency {
                case .daily:
                    return UNCalendarNotificationTrigger(
                        dateMatching: dateComponents,
                        repeats: true
                    )
                case .weekly:
                    if let day = config.recurrence?.daysOfWeek?.first {
                        dateComponents.weekday = day
                    }
                    return UNCalendarNotificationTrigger(
                        dateMatching: dateComponents,
                        repeats: true
                    )
                default:
                    break
                }
            }
            
            return UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: config.recurrence != nil
            )
            
        case .relativeTime:
            let timeInterval = TimeInterval(config.metadata["interval"] ?? "3600") ?? 3600
            return UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            )
            
        case .smartTime, .eventTrigger:
            return createDefaultTrigger()
        }
    }
    
    private func createDefaultTrigger() -> UNTimeIntervalNotificationTrigger {
        UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
    }
    
    private func triggerNextDate(from trigger: UNNotificationTrigger?) -> Date {
        guard let calendarTrigger = trigger as? UNCalendarNotificationTrigger,
              let nextDate = calendarTrigger.nextTriggerDate() else {
            return Date()
        }
        return nextDate
    }
    
    private func categoryIdentifierForType(_ type: DreamNotificationType) -> String {
        switch type.category {
        case .reminder:
            return "DREAM_REMINDER"
        case .insight:
            return "DREAM_INSIGHT"
        case .challenge:
            return "DREAM_REMINDER"
        case .health:
            return "DREAM_MEDITATION"
        case .social:
            return "DREAM_INSIGHT"
        }
    }
    
    // MARK: - Smart Scheduling
    
    /// 基于用户习惯智能调度睡前提醒
    public func scheduleSmartSleepReminder() async {
        guard settings.smartSchedulingEnabled else { return }
        
        // 分析用户历史记录时间
        let bestTime = await analyzeBestReminderTime()
        
        let config = NotificationScheduleConfig(
            identifier: "smart_sleep_reminder",
            type: .smartTime,
            time: .init(hour: bestTime.hour, minute: bestTime.minute),
            recurrence: .init(frequency: .daily),
            smartAdjustment: .init(isEnabled: true)
        )
        
        guard let type = DreamNotificationType.allTypes.first(where: { $0.identifier == "sleep_reminder" }) else {
            print("Failed to find sleep_reminder notification type")
            return
        }
        
        do {
            try await scheduleNotification(
                type: type,
                config: config,
                title: "🌙 睡前准备",
                body: "是时候准备睡觉了，想想今晚可能会做什么梦吧！",
                userInfo: ["action": "sleep_reminder"]
            )
        } catch {
            print("Failed to schedule smart sleep reminder: \(error)")
        }
    }
    
    /// 分析最佳提醒时间
    private func analyzeBestReminderTime() async -> (hour: Int, minute: Int) {
        // TODO: 分析用户梦境记录历史，找出最佳时间
        // 这里返回默认时间 22:30
        return (22, 30)
    }
    
    /// 调度晨间回忆提醒
    public func scheduleMorningRecall() async {
        guard let type = DreamNotificationType.allTypes.first(where: { $0.identifier == "morning_recall" }) else {
            print("Failed to find morning_recall notification type")
            return
        }
        
        let config = NotificationScheduleConfig(
            identifier: "morning_recall",
            type: .fixedTime,
            time: .init(hour: 7, minute: 30),
            recurrence: .init(frequency: .daily)
        )
        
        do {
            try await scheduleNotification(
                type: type,
                config: config,
                title: "☀️ 晨间回忆",
                body: "早上好！还记得昨晚做了什么梦吗？趁现在记录下来吧～",
                userInfo: ["action": "morning_recall"]
            )
        } catch {
            print("Failed to schedule morning recall: \(error)")
        }
    }
    
    // MARK: - History Management
    
    /// 记录已调度的通知
    private func recordScheduledNotification(
        typeId: String,
        title: String,
        body: String,
        scheduledDate: Date,
        metadata: [String: String]
    ) async {
        guard let context = modelContext else { return }
        
        let history = DreamNotificationHistory(
            typeId: typeId,
            title: title,
            body: body,
            scheduledDate: scheduledDate,
            metadata: metadata
        )
        
        context.insert(history)
        
        do {
            try context.save()
        } catch {
            print("Failed to record notification history: \(error)")
        }
    }
    
    /// 获取通知历史
    public func getNotificationHistory(limit: Int = 50) async -> [DreamNotificationHistory] {
        guard let context = modelContext else { return [] }
        
        do {
            var descriptor = FetchDescriptor<DreamNotificationHistory>(
                sortBy: [SortDescriptor(\.scheduledDate, order: .reverse)]
            )
            descriptor.fetchLimit = limit
            
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch notification history: \(error)")
            return []
        }
    }
    
    /// 获取未读通知数量
    public func getUnreadCount() async -> Int {
        guard let context = modelContext else { return 0 }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationHistory>(
                predicate: #Predicate<DreamNotificationHistory> { $0.isRead == false && !$0.isDeleted }
            )
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    /// 标记通知为已读
    public func markAsRead(notificationId: UUID) async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationHistory>(
                predicate: #Predicate<DreamNotificationHistory> { $0.id == notificationId }
            )
            let notifications = try context.fetch(descriptor)
            
            for notification in notifications {
                notification.markAsRead()
            }
            
            try context.save()
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }
    
    /// 清除所有通知历史
    public func clearHistory() async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationHistory>()
            let notifications = try context.fetch(descriptor)
            
            for notification in notifications {
                notification.isDeleted = true
            }
            
            try context.save()
        } catch {
            print("Failed to clear notification history: \(error)")
        }
    }
    
    // MARK: - Statistics
    
    /// 获取通知统计
    public func getStatistics() async -> NotificationStats {
        guard let context = modelContext else {
            return NotificationStats()
        }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationHistory>()
            let all = try context.fetch(descriptor)
            
            let totalScheduled = all.count
            let totalDelivered = all.filter { $0.deliveredDate != nil }.count
            let totalRead = all.filter { $0.isRead }.count
            let totalActions = all.filter { $0.actionTaken != nil }.count
            
            var byType: [String: NotificationStats.TypeStats] = [:]
            for notification in all {
                if byType[notification.typeId] == nil {
                    byType[notification.typeId] = .init()
                }
                byType[notification.typeId]?.scheduled += 1
                if notification.deliveredDate != nil {
                    byType[notification.typeId]?.delivered += 1
                }
                if notification.isRead {
                    byType[notification.typeId]?.read += 1
                }
                if notification.actionTaken != nil {
                    byType[notification.typeId]?.actions += 1
                }
            }
            
            return NotificationStats(
                totalScheduled: totalScheduled,
                totalDelivered: totalDelivered,
                totalRead: totalRead,
                totalActions: totalActions,
                byType: byType
            )
        } catch {
            return NotificationStats()
        }
    }
    
    // MARK: - Utility
    
    /// 取消所有待处理通知
    public func cancelAllPending() async {
        await notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// 取消特定通知
    public func cancel(identifier: String) async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// 获取待处理通知
    public func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension DreamNotificationService: UNUserNotificationCenterDelegate {
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        Task { @MainActor in
            let settings = self.settings
            
            var options: UNNotificationPresentationOptions = []
            
            if settings.showOnLockScreen {
                options.insert(.banner)
            }
            if settings.soundEnabled {
                options.insert(.sound)
            }
            if settings.badgeEnabled {
                options.insert(.badge)
            }
            
            completionHandler(options)
            
            // 记录送达
            await recordDelivery(notificationId: notification.request.identifier)
        }
    }
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            let actionId = response.actionIdentifier
            
            if let action = DreamNotificationAction(rawValue: actionId) {
                await handleNotificationAction(action, userInfo: response.notification.request.content.userInfo)
            }
            
            // 记录操作
            await recordAction(
                notificationId: response.notification.request.identifier,
                action: actionId
            )
            
            completionHandler()
        }
    }
    
    private func recordDelivery(notificationId: String) async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationHistory>(
                predicate: #Predicate<DreamNotificationHistory> { $0.id == UUID(uuidString: notificationId) }
            )
            let notifications = try context.fetch(descriptor)
            
            for notification in notifications {
                notification.deliveredDate = Date()
            }
            
            try context.save()
        } catch {
            print("Failed to record notification delivery: \(error)")
        }
    }
    
    private func recordAction(notificationId: String, action: String) async {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<DreamNotificationHistory>(
                predicate: #Predicate<DreamNotificationHistory> { $0.id == UUID(uuidString: notificationId) }
            )
            let notifications = try context.fetch(descriptor)
            
            for notification in notifications {
                notification.recordAction(action)
            }
            
            try context.save()
        } catch {
            print("Failed to record notification action: \(error)")
        }
    }
    
    private func handleNotificationAction(_ action: DreamNotificationAction, userInfo: [String: Any]) async {
        // 处理通知动作 - 实际导航由 App 处理
        print("Handling notification action: \(action)")
        
        switch action {
        case .recordDream:
            // 导航到记录页面
            break
        case .viewDetails:
            // 导航到详情页面
            break
        case .snooze:
            // 稍后提醒
            break
        case .startMeditation:
            // 开始冥想
            break
        case .realityCheck:
            // 现实检查
            break
        default:
            break
        }
    }
}

// MARK: - Errors

public enum NotificationError: LocalizedError {
    case typeDisabled
    case inQuietHours
    case noAuthorization
    case schedulingFailed
    
    public var errorDescription: String? {
        switch self {
        case .typeDisabled:
            return "该通知类型已禁用"
        case .inQuietHours:
            return "当前在免打扰时段"
        case .noAuthorization:
            return "未获得通知权限"
        case .schedulingFailed:
            return "通知调度失败"
        }
    }
}
