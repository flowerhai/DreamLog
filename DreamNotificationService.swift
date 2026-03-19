//
//  DreamNotificationService.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  通知核心服务
//

import Foundation
import UserNotifications
import Combine

@MainActor
class DreamNotificationService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DreamNotificationService()
    
    // MARK: - Published Properties
    
    @Published var settings: DreamNotificationSettings = .default
    @Published var isAuthorized: Bool = false
    @Published var statistics: NotificationStatistics = .init()
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let notificationCenter: UNUserNotificationCenter
    private var cancellables = Set<AnyCancellable>()
    
    private let settingsKey = "dream_notification_settings"
    private let statisticsKey = "dream_notification_statistics"
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard,
         notificationCenter: UNUserNotificationCenter = .current()) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        loadSettings()
        loadStatistics()
        setupDelegates()
    }
    
    // MARK: - Setup
    
    private func setupDelegates() {
        notificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    /// 请求通知授权
    func requestAuthorization() async throws -> Bool {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: authOptions)
            isAuthorized = granted
            
            if granted {
                await registerNotificationCategories()
                await registerNotificationTriggers()
            }
            
            return granted
        } catch {
            print("通知授权失败：\(error)")
            isAuthorized = false
            throw error
        }
    }
    
    /// 检查通知权限
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
        case .denied, .ephemeral, .notDetermined:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Notification Categories
    
    private func registerNotificationCategories() async {
        // 记录梦境操作
        let recordAction = UNNotificationAction(
            identifier: NotificationActionType.recordDream.identifier,
            title: NotificationActionType.recordDream.title,
            options: .foreground
        )
        
        let recordCategory = UNNotificationCategory(
            identifier: "DREAM_CATEGORY",
            actions: [recordAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // 查看洞察操作
        let viewAction = UNNotificationAction(
            identifier: NotificationActionType.viewInsight.identifier,
            title: NotificationActionType.viewInsight.title,
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationActionType.snooze.identifier,
            title: NotificationActionType.snooze.title,
            options: []
        )
        
        let insightCategory = UNNotificationCategory(
            identifier: "INSIGHT_CATEGORY",
            actions: [viewAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 挑战操作
        let startAction = UNNotificationAction(
            identifier: NotificationActionType.startChallenge.identifier,
            title: NotificationActionType.startChallenge.title,
            options: .foreground
        )
        
        let challengeCategory = UNNotificationCategory(
            identifier: "CHALLENGE_CATEGORY",
            actions: [startAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            recordCategory,
            insightCategory,
            challengeCategory
        ])
    }
    
    // MARK: - Notification Triggers
    
    private func registerNotificationTriggers() async {
        // 注册时间间隔触发器（用于稍后提醒）
        let snoozeTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 15 * 60, // 15 分钟后
            repeats: false
        )
        
        let snoozeRequest = UNNotificationRequest(
            identifier: "snooze_template",
            content: UNNotificationContent(),
            trigger: snoozeTrigger
        )
        
        // 模板不实际添加，仅用于注册
    }
    
    // MARK: - Scheduling
    
    /// 调度通知
    func scheduleNotification(type: DreamNotificationType,
                              date: Date,
                              content: DreamNotificationContent,
                              repeats: Bool = false) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        guard settings.isNotificationsEnabled else {
            print("通知已禁用")
            return
        }
        
        // 检查是否在安静时间内
        if isQuietHours(date: date) && type != .weeklyReport {
            print("在安静时间内，跳过通知：\(type)")
            return
        }
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents(from: date),
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)_\(date.timeIntervalSince1970)",
            content: createContent(from: content, type: type),
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
        print("已调度通知：\(type) at \(date)")
    }
    
    /// 调度一次性通知
    func scheduleOneTimeNotification(type: DreamNotificationType,
                                     delay: TimeInterval,
                                     content: DreamNotificationContent) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delay,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)_onetime_\(Date().timeIntervalSince1970)",
            content: createContent(from: content, type: type),
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    /// 取消通知
    func cancelNotification(identifier: String) async {
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    /// 取消所有通知
    func cancelAllNotifications() async {
        await notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// 取消特定类型的所有通知
    func cancelNotificationsOfType(_ type: DreamNotificationType) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let identifiers = pending
            .filter { $0.identifier.hasPrefix(type.rawValue) }
            .map { $0.identifier }
        
        await notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Content Creation
    
    private func createContent(from content: DreamNotificationContent,
                               type: DreamNotificationType) -> UNNotificationContent {
        let ncContent = UNMutableNotificationContent()
        ncContent.title = content.title
        ncContent.body = content.body
        ncContent.sound = UNNotificationSound(named: UNNotificationSoundName(content.sound))
        
        if let subtitle = content.subtitle {
            ncContent.subtitle = subtitle
        }
        
        if let badge = content.badge {
            ncContent.badge = NSNumber(value: badge)
        }
        
        ncContent.categoryIdentifier = content.categoryIdentifier
        ncContent.userInfo = content.userInfo.reduce(into: [String: Any]()) {
            $0[$1.key] = $1.value.value
        }
        
        // 添加类型标识
        ncContent.userInfo["notificationType"] = type.rawValue
        
        return ncContent
    }
    
    // MARK: - Smart Scheduling
    
    /// 基于用户模式智能调度通知
    func applySmartScheduling() async {
        guard settings.isSmartSchedulingEnabled else { return }
        
        let analysis = await analyzeUserPattern()
        
        // 更新睡前提醒时间
        if let bestSleepTime = analysis.bestSleepTime,
           let config = findConfig(type: .sleepReminder) {
            var updatedConfig = config
            updatedConfig.scheduledTime = bestSleepTime
            updateConfig(updatedConfig)
            await rescheduleNotification(config: updatedConfig)
        }
        
        // 更新晨间回忆时间
        if let bestWakeTime = analysis.bestWakeTime,
           let config = findConfig(type: .morningRecall) {
            var updatedConfig = config
            updatedConfig.scheduledTime = bestWakeTime
            updateConfig(updatedConfig)
            await rescheduleNotification(config: updatedConfig)
        }
    }
    
    /// 分析用户模式
    private func analyzeUserPattern() async -> SmartScheduleAnalysis {
        var analysis = SmartScheduleAnalysis()
        
        // TODO: 集成 DreamStore 分析用户记录模式
        // 这里使用占位实现
        
        return analysis
    }
    
    // MARK: - Configuration Management
    
    /// 获取通知配置
    func getConfig(type: DreamNotificationType) -> DreamNotificationConfig? {
        settings.configurations.first { $0.type == type }
    }
    
    /// 更新通知配置
    func updateConfig(_ config: DreamNotificationConfig) {
        if let index = settings.configurations.firstIndex(where: { $0.id == config.id }) {
            settings.configurations[index] = config
        } else {
            settings.configurations.append(config)
        }
        saveSettings()
    }
    
    /// 启用/禁用通知类型
    func toggleNotification(type: DreamNotificationType, enabled: Bool) async {
        if var config = getConfig(type: type) {
            config.isEnabled = enabled
            updateConfig(config)
            
            if !enabled {
                await cancelNotificationsOfType(type)
            } else {
                await rescheduleNotification(config: config)
            }
        }
    }
    
    /// 重新调度通知
    private func rescheduleNotification(config: DreamNotificationConfig) async {
        guard config.isEnabled else { return }
        
        let content = getDefaultContent(for: config.type)
        
        if let timeString = config.scheduledTime {
            if let date = nextDate(from: timeString, frequency: config.frequency) {
                do {
                    try await scheduleNotification(
                        type: config.type,
                        date: date,
                        content: content,
                        repeats: config.frequency != .once
                    )
                } catch {
                    print("重新调度通知失败：\(error)")
                }
            }
        }
    }
    
    /// 重新调度所有通知
    func rescheduleAllNotifications() async {
        await cancelAllNotifications()
        
        for config in settings.configurations where config.isEnabled {
            await rescheduleNotification(config: config)
        }
    }
    
    // MARK: - Default Content
    
    private func getDefaultContent(for type: DreamNotificationType) -> DreamNotificationContent {
        switch type {
        case .sleepReminder:
            return DreamNotificationContent(
                title: "🌙 睡前时间到了",
                body: "准备睡觉了吗？花几分钟记录今天的梦境或设置梦境意图吧。",
                subtitle: "梦境记录提醒"
            )
            
        case .morningRecall:
            return DreamNotificationContent(
                title: "☀️ 早上好",
                body: "还记得昨晚的梦吗？趁记忆还新鲜，快记录下来吧！",
                subtitle: "梦境回忆提醒"
            )
            
        case .patternInsight:
            return DreamNotificationContent(
                title: "💡 发现梦境模式",
                body: "我们注意到你最近经常梦到相似的主题，点击查看详细分析。",
                subtitle: "每周洞察"
            )
            
        case .challengeProgress:
            return DreamNotificationContent(
                title: "🎯 挑战进度更新",
                body: "你的梦境挑战正在进行中，继续加油！",
                subtitle: "挑战提醒"
            )
            
        case .meditationSuggestion:
            return DreamNotificationContent(
                title: "🧘 放松时刻",
                body: "今天过得怎么样？试试 5 分钟冥想放松一下吧。",
                subtitle: "冥想建议"
            )
            
        case .weeklyReport:
            return DreamNotificationContent(
                title: "📊 本周梦境报告",
                body: "你的本周梦境报告已生成，快来看看有什么有趣的发现！",
                subtitle: "周报"
            )
            
        case .lucidPrompt:
            return DreamNotificationContent(
                title: "👁️ 清醒梦提示",
                body: "今晚试试问自己：'我在做梦吗？' 培养清醒梦意识。",
                subtitle: "清醒梦训练"
            )
            
        case .moodCheck:
            return DreamNotificationContent(
                title: "💗 情绪检查",
                body: "今天感觉怎么样？记录一下你的情绪状态吧。",
                subtitle: "情绪追踪"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func isQuietHours(date: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let currentTime = formatter.string(from: date)
        let quietStart = settings.quietHoursStart
        let quietEnd = settings.quietHoursEnd
        
        if quietStart <= quietEnd {
            return currentTime >= quietStart && currentTime <= quietEnd
        } else {
            // 跨夜情况（如 22:00 - 08:00）
            return currentTime >= quietStart || currentTime <= quietEnd
        }
    }
    
    private func dateComponents(from date: Date) -> DateComponents {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: date)
        components.second = 0
        return components
    }
    
    private func nextDate(from timeString: String, frequency: NotificationFrequency) -> Date? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]),
              hour >= 0 && hour < 24,
              minute >= 0 && minute < 60 else {
            return nil
        }
        
        var calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        guard var nextDate = calendar.nextDate(after: Date(),
                                                matching: dateComponents,
                                                matchingPolicy: .nextTime) else {
            return nil
        }
        
        // 根据频率调整
        switch frequency {
        case .weekdays:
            var weekday = calendar.component(.weekday, from: nextDate)
            while weekday == 1 || weekday == 7 { // 周日 = 1, 周六 = 7
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
            nextDate = calendar.date(byAdding: .day, value: 7, to: nextDate) ?? nextDate
        default:
            break
        }
        
        return nextDate
    }
    
    private func findConfig(type: DreamNotificationType) -> DreamNotificationConfig? {
        settings.configurations.first { $0.type == type }
    }
    
    // MARK: - Persistence
    
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    private func loadSettings() {
        if let data = userDefaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(DreamNotificationSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }
    
    private func saveStatistics() {
        if let encoded = try? JSONEncoder().encode(statistics) {
            userDefaults.set(encoded, forKey: statisticsKey)
        }
    }
    
    private func loadStatistics() {
        if let data = userDefaults.data(forKey: statisticsKey),
           let decoded = try? JSONDecoder().decode(NotificationStatistics.self, from: data) {
            statistics = decoded
        }
    }
    
    // MARK: - Statistics Tracking
    
    func trackNotificationSent(type: DreamNotificationType) {
        statistics.totalSent += 1
        statistics.lastSentDate = Date()
        
        if statistics.byType[type.rawValue] == nil {
            statistics.byType[type.rawValue] = .init()
        }
        statistics.byType[type.rawValue]?.sent += 1
        
        saveStatistics()
    }
    
    func trackNotificationOpened(type: DreamNotificationType) {
        statistics.totalOpened += 1
        statistics.openRate = Double(statistics.totalOpened) / Double(max(statistics.totalSent, 1))
        
        var typeStats = statistics.byType[type.rawValue] ?? .init()
        typeStats.opened += 1
        typeStats.openRate = Double(typeStats.opened) / Double(max(typeStats.sent, 1))
        statistics.byType[type.rawValue] = typeStats
        
        saveStatistics()
    }
    
    // MARK: - Live Activity Integration
    
    /// 开始挑战实时活动
    @available(iOS 16.2, *)
    func startChallengeLiveActivity(challenge: UserChallenge) async {
        guard #available(iOS 16.2, *) else { return }
        
        do {
            try await DreamLiveActivityService.shared.startChallengeActivity(challenge: challenge)
        } catch {
            print("启动挑战实时活动失败：\(error)")
        }
    }
    
    /// 更新挑战实时活动
    @available(iOS 16.2, *)
    func updateChallengeLiveActivity(challengeId: String, challenge: UserChallenge) async {
        guard #available(iOS 16.2, *) else { return }
        
        await DreamLiveActivityService.shared.updateChallengeActivity(
            challengeId: challengeId,
            challenge: challenge
        )
    }
    
    /// 结束挑战实时活动
    @available(iOS 16.2, *)
    func endChallengeLiveActivity(challengeId: String) async {
        guard #available(iOS 16.2, *) else { return }
        
        await DreamLiveActivityService.shared.endChallengeActivity(challengeId: challengeId)
    }
    
    /// 开始孵育实时活动
    @available(iOS 16.2, *)
    func startIncubationLiveActivity(incubation: DreamIncubationSession) async {
        guard #available(iOS 16.2, *) else { return }
        
        do {
            try await DreamLiveActivityService.shared.startIncubationActivity(incubation: incubation)
        } catch {
            print("启动孵育实时活动失败：\(error)")
        }
    }
    
    /// 更新孵育实时活动
    @available(iOS 16.2, *)
    func updateIncubationLiveActivity(incubationId: String, incubation: DreamIncubationSession) async {
        guard #available(iOS 16.2, *) else { return }
        
        await DreamLiveActivityService.shared.updateIncubationActivity(
            incubationId: incubationId,
            incubation: incubation
        )
    }
    
    /// 结束孵育实时活动
    @available(iOS 16.2, *)
    func endIncubationLiveActivity(incubationId: String) async {
        guard #available(iOS 16.2, *) else { return }
        
        await DreamLiveActivityService.shared.endIncubationActivity(incubationId: incubationId)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension DreamNotificationService: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 前台显示通知
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        // 处理通知操作
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            if let typeString = userInfo["notificationType"] as? String,
               let type = DreamNotificationType(rawValue: typeString) {
                trackNotificationOpened(type: type)
            }
            
            // 处理具体操作
            switch actionIdentifier {
            case NotificationActionType.recordDream.identifier:
                // TODO: 导航到记录页面
                break
            case NotificationActionType.viewInsight.identifier:
                // TODO: 导航到洞察页面
                break
            case NotificationActionType.startChallenge.identifier:
                // TODO: 开始挑战
                break
            case NotificationActionType.snooze.identifier:
                // TODO: 稍后提醒
                break
            default:
                break
            }
        }
        
        completionHandler()
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "未获得通知授权"
        case .schedulingFailed: return "通知调度失败"
        case .invalidConfiguration: return "配置无效"
        }
    }
}
