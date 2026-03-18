//
//  DreamNotificationScheduler.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  智能调度引擎
//

import Foundation
import UserNotifications
import Combine

@MainActor
class DreamNotificationScheduler: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DreamNotificationScheduler()
    
    // MARK: - Published Properties
    
    @Published var isRunning: Bool = false
    @Published var lastAnalysisDate: Date?
    @Published var upcomingNotifications: [ScheduledNotification] = []
    
    // MARK: - Properties
    
    private let notificationService: DreamNotificationService
    private var timers: [String: Timer] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(notificationService: DreamNotificationService = .shared) {
        self.notificationService = notificationService
    }
    
    // MARK: - Scheduler Control
    
    /// 启动调度器
    func start() {
        guard !isRunning else { return }
        
        isRunning = true
        print("通知调度器已启动")
        
        // 立即应用智能调度
        Task {
            await notificationService.applySmartScheduling()
            await rescheduleAllNotifications()
        }
        
        // 每小时检查一次
        startPeriodicCheck()
        
        // 每天午夜重新分析
        scheduleMidnightAnalysis()
    }
    
    /// 停止调度器
    func stop() {
        isRunning = false
        
        // 取消所有定时器
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
        
        print("通知调度器已停止")
    }
    
    // MARK: - Periodic Checks
    
    private func startPeriodicCheck() {
        let timer = Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkAndScheduleNotifications()
            }
        }
        timers["periodic"] = timer
    }
    
    private func scheduleMidnightAnalysis() {
        // 计算到下一个午夜的时间
        let calendar = Calendar.current
        let now = Date()
        
        guard var midnight = calendar.startOfDay(for: now) else { return }
        midnight = calendar.date(byAdding: .day, value: 1, to: midnight) ?? midnight
        
        let timeInterval = midnight.timeIntervalSince(now)
        
        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.performDailyAnalysis()
                self?.scheduleMidnightAnalysis() // 重新调度
            }
        }
        timers["midnight"] = timer
    }
    
    // MARK: - Analysis
    
    /// 执行每日分析
    private func performDailyAnalysis() async {
        print("执行每日通知分析...")
        
        await notificationService.applySmartScheduling()
        lastAnalysisDate = Date()
        
        print("每日分析完成")
    }
    
    /// 检查并调度通知
    private func checkAndScheduleNotifications() async {
        guard notificationService.settings.isNotificationsEnabled else { return }
        
        // 检查是否有需要立即发送的通知
        await processImmediateNotifications()
        
        // 更新即将到来的通知列表
        await updateUpcomingNotifications()
    }
    
    // MARK: - Immediate Notifications
    
    private func processImmediateNotifications() async {
        let now = Date()
        
        for config in notificationService.settings.configurations {
            guard config.isEnabled else { continue }
            
            // 检查是否需要发送
            if shouldSendNow(config: config, currentDate: now) {
                await sendNotification(config: config)
            }
        }
    }
    
    private func shouldSendNow(config: DreamNotificationConfig, currentDate: Date) -> Bool {
        guard let timeString = config.scheduledTime else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let scheduledTime = formatter.date(from: timeString) else { return false }
        
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: currentDate)
        let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        
        // 检查时间是否匹配（允许 1 分钟误差）
        let hourMatch = nowComponents.hour == scheduledComponents.hour
        let minuteMatch = abs((nowComponents.minute ?? 0) - (scheduledComponents.minute ?? 0)) <= 1
        
        guard hourMatch && minuteMatch else { return false }
        
        // 检查频率
        switch config.frequency {
        case .weekdays:
            let weekday = calendar.component(.weekday, from: currentDate)
            return weekday != 1 && weekday != 7
        case .weekends:
            let weekday = calendar.component(.weekday, from: currentDate)
            return weekday == 1 || weekday == 7
        case .weekly:
            // 简单实现：只在周日发送
            let weekday = calendar.component(.weekday, from: currentDate)
            return weekday == 1
        default:
            return true
        }
    }
    
    private func sendNotification(config: DreamNotificationConfig) async {
        let content = notificationService.getDefaultContent(for: config.type)
        let now = Date()
        
        do {
            try await notificationService.scheduleNotification(
                type: config.type,
                date: now,
                content: content,
                repeats: false
            )
            notificationService.trackNotificationSent(type: config.type)
            print("已发送通知：\(config.type)")
        } catch {
            print("发送通知失败：\(error)")
        }
    }
    
    // MARK: - Upcoming Notifications
    
    private func updateUpcomingNotifications() async {
        var upcoming: [ScheduledNotification] = []
        let now = Date()
        let calendar = Calendar.current
        
        for config in notificationService.settings.configurations where config.isEnabled {
            if let nextDate = nextScheduledDate(for: config, from: now) {
                let notification = ScheduledNotification(
                    type: config.type,
                    scheduledDate: nextDate,
                    title: config.type.displayName,
                    isRecurring: config.frequency != .once
                )
                upcoming.append(notification)
            }
        }
        
        // 按时间排序
        upcoming.sort { $0.scheduledDate < $1.scheduledDate }
        
        // 只保留未来 7 天的通知
        let sevenDaysLater = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        upcoming = upcoming.filter { $0.scheduledDate <= sevenDaysLater }
        
        self.upcomingNotifications = upcoming
    }
    
    private func nextScheduledDate(for config: DreamNotificationConfig, from date: Date) -> Date? {
        guard let timeString = config.scheduledTime else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let baseTime = formatter.date(from: timeString) else { return nil }
        
        var calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: baseTime)
        
        var nextDate = calendar.date(bySettingHour: components.hour ?? 0,
                                      minute: components.minute ?? 0,
                                      second: 0,
                                      of: date) ?? date
        
        // 如果是过去的时间，加一天
        if nextDate <= date {
            nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
        }
        
        // 根据频率调整
        switch config.frequency {
        case .weekdays:
            var weekday = calendar.component(.weekday, from: nextDate)
            while weekday == 1 || weekday == 7 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
                weekday = calendar.component(.weekday, from: nextDate)
            }
        case .weekends:
            var weekday = calendar.component(.weekday, from: nextDate)
            while weekday != 1 && weekday != 7 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
                weekday = calendar.component(.weekday, from: nextDate)
            }
        case .weekly:
            // 找到下一个匹配的星期几
            let targetWeekday = calendar.component(.weekday, from: date)
            var currentWeekday = calendar.component(.weekday, from: nextDate)
            while currentWeekday != targetWeekday {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
                currentWeekday = calendar.component(.weekday, from: nextDate)
            }
        case .once:
            return nil // 一次性通知不显示在即将到来的列表中
        default:
            break
        }
        
        return nextDate
    }
    
    // MARK: - Rescheduling
    
    /// 重新调度所有通知
    func rescheduleAllNotifications() async {
        await notificationService.rescheduleAllNotifications()
        await updateUpcomingNotifications()
    }
    
    /// 重新调度特定类型的通知
    func rescheduleNotification(type: DreamNotificationType) async {
        if let config = notificationService.getConfig(type: type) {
            await notificationService.cancelNotificationsOfType(type)
            await notificationService.rescheduleNotification(config: config)
            await updateUpcomingNotifications()
        }
    }
}

// MARK: - Scheduled Notification Model

struct ScheduledNotification: Identifiable, Codable {
    let id: String
    let type: DreamNotificationType
    let scheduledDate: Date
    let title: String
    let isRecurring: Bool
    
    init(id: String = UUID().uuidString,
         type: DreamNotificationType,
         scheduledDate: Date,
         title: String,
         isRecurring: Bool) {
        self.id = id
        self.type = type
        self.scheduledDate = scheduledDate
        self.title = title
        self.isRecurring = isRecurring
    }
    
    var timeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: scheduledDate, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: scheduledDate)
    }
}

// MARK: - Smart Scheduling Logic

extension DreamNotificationScheduler {
    
    /// 根据睡眠数据优化提醒时间
    func optimizeScheduleWithSleepData(sleepData: SleepData) async {
        // 分析最佳睡前提醒时间（睡前 30 分钟）
        if let bedtime = sleepData.typicalBedtime {
            let reminderTime = Calendar.current.date(byAdding: .minute, value: -30, to: bedtime)
            if let config = notificationService.getConfig(type: .sleepReminder) {
                var updated = config
                updated.scheduledTime = formatTime(reminderTime)
                notificationService.updateConfig(updated)
            }
        }
        
        // 分析最佳晨间提醒时间（醒来后 15 分钟）
        if let waketime = sleepData.typicalWaketime {
            let reminderTime = Calendar.current.date(byAdding: .minute, value: 15, to: waketime)
            if let config = notificationService.getConfig(type: .morningRecall) {
                var updated = config
                updated.scheduledTime = formatTime(reminderTime)
                notificationService.updateConfig(updated)
            }
        }
        
        await rescheduleAllNotifications()
    }
    
    private func formatTime(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Sleep Data Model

struct SleepData {
    var typicalBedtime: Date?
    var typicalWaketime: Date?
    var averageSleepDuration: TimeInterval
    var sleepEfficiency: Double
    var lastUpdated: Date
    
    init() {
        self.typicalBedtime = nil
        self.typicalWaketime = nil
        self.averageSleepDuration = 8 * 60 * 60
        self.sleepEfficiency = 0.85
        self.lastUpdated = Date()
    }
}
