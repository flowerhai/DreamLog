//
//  DreamNotificationModels.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  通知系统数据模型
//

import Foundation
import SwiftData

// MARK: - 通知类型枚举

/// 梦境通知类型
@Model
public class DreamNotificationType: @unchecked Sendable {
    public var identifier: String
    public var name: String
    public var nameKey: String
    public var description: String
    public var descriptionKey: String
    public var icon: String
    public var category: NotificationCategory
    public var isDefaultEnabled: Bool
    public var priority: NotificationPriority
    
    public enum NotificationCategory: String, Codable, CaseIterable {
        case reminder = "提醒"
        case insight = "洞察"
        case social = "社交"
        case challenge = "挑战"
        case health = "健康"
    }
    
    public enum NotificationPriority: Int, Codable, CaseIterable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
        
        var userNotificationsPriority: UNNotificationPriority {
            switch self {
            case .low: return .low
            case .medium: return .default
            case .high: return .high
            case .critical: return .timeSensitive
            }
        }
    }
    
    public init(
        identifier: String,
        name: String,
        nameKey: String,
        description: String,
        descriptionKey: String,
        icon: String,
        category: NotificationCategory,
        isDefaultEnabled: Bool = true,
        priority: NotificationPriority = .medium
    ) {
        self.identifier = identifier
        self.name = name
        self.nameKey = nameKey
        self.description = description
        self.descriptionKey = descriptionKey
        self.icon = icon
        self.category = category
        self.isDefaultEnabled = isDefaultEnabled
        self.priority = priority
    }
    
    /// 预设通知类型
    public static let allTypes: [DreamNotificationType] = [
        // 提醒类
        DreamNotificationType(
            identifier: "sleep_reminder",
            name: "睡前提醒",
            nameKey: "notification.sleep_reminder.name",
            description: "睡前提醒你记录梦境意图",
            descriptionKey: "notification.sleep_reminder.desc",
            icon: "🌙",
            category: .reminder,
            isDefaultEnabled: true,
            priority: .low
        ),
        DreamNotificationType(
            identifier: "morning_recall",
            name: "晨间回忆",
            nameKey: "notification.morning_recall.name",
            description: "醒来后提醒你记录夜间梦境",
            descriptionKey: "notification.morning_recall.desc",
            icon: "☀️",
            category: .reminder,
            isDefaultEnabled: true,
            priority: .medium
        ),
        DreamNotificationType(
            identifier: "lucid_prompt",
            name: "清醒梦提示",
            nameKey: "notification.lucid_prompt.name",
            description: "随机时间发送清醒梦现实检查提示",
            descriptionKey: "notification.lucid_prompt.desc",
            icon: "👁️",
            category: .reminder,
            isDefaultEnabled: false,
            priority: .low
        ),
        
        // 洞察类
        DreamNotificationType(
            identifier: "pattern_insight",
            name: "模式洞察",
            nameKey: "notification.pattern_insight.name",
            description: "发现重复梦境模式时推送",
            descriptionKey: "notification.pattern_insight.desc",
            icon: "📊",
            category: .insight,
            isDefaultEnabled: true,
            priority: .medium
        ),
        DreamNotificationType(
            identifier: "weekly_report",
            name: "周报推送",
            nameKey: "notification.weekly_report.name",
            description: "每周日发送梦境周报",
            descriptionKey: "notification.weekly_report.desc",
            icon: "📰",
            category: .insight,
            isDefaultEnabled: true,
            priority: .low
        ),
        DreamNotificationType(
            identifier: "mood_check",
            name: "情绪检查",
            nameKey: "notification.mood_check.name",
            description: "定期询问当前情绪状态",
            descriptionKey: "notification.mood_check.desc",
            icon: "😊",
            category: .insight,
            isDefaultEnabled: false,
            priority: .low
        ),
        
        // 挑战类
        DreamNotificationType(
            identifier: "challenge_progress",
            name: "挑战进度",
            nameKey: "notification.challenge_progress.name",
            description: "梦境挑战即将到期提醒",
            descriptionKey: "notification.challenge_progress.desc",
            icon: "🎯",
            category: .challenge,
            isDefaultEnabled: true,
            priority: .medium
        ),
        DreamNotificationType(
            identifier: "challenge_complete",
            name: "挑战完成",
            nameKey: "notification.challenge_complete.name",
            description: "挑战完成时发送庆祝通知",
            descriptionKey: "notification.challenge_complete.desc",
            icon: "🏆",
            category: .challenge,
            isDefaultEnabled: true,
            priority: .high
        ),
        DreamNotificationType(
            identifier: "achievement_unlock",
            name: "成就解锁",
            nameKey: "notification.achievement_unlock.name",
            description: "解锁新成就时通知",
            descriptionKey: "notification.achievement_unlock.desc",
            icon: "🏅",
            category: .challenge,
            isDefaultEnabled: true,
            priority: .high
        ),
        
        // 健康类
        DreamNotificationType(
            identifier: "meditation_suggestion",
            name: "冥想建议",
            nameKey: "notification.meditation_suggestion.name",
            description: "基于压力和情绪状态推荐冥想",
            descriptionKey: "notification.meditation_suggestion.desc",
            icon: "🧘",
            category: .health,
            isDefaultEnabled: false,
            priority: .low
        ),
        DreamNotificationType(
            identifier: "sleep_quality",
            name: "睡眠质量",
            nameKey: "notification.sleep_quality.name",
            description: "每周睡眠质量报告",
            descriptionKey: "notification.sleep_quality.desc",
            icon: "💤",
            category: .health,
            isDefaultEnabled: true,
            priority: .low
        ),
        
        // 社交类
        DreamNotificationType(
            identifier: "social_interaction",
            name: "社交互动",
            nameKey: "notification.social_interaction.name",
            description: "收到点赞、评论或关注时通知",
            descriptionKey: "notification.social_interaction.desc",
            icon: "💬",
            category: .social,
            isDefaultEnabled: true,
            priority: .medium
        ),
        DreamNotificationType(
            identifier: "new_follower",
            name: "新关注者",
            nameKey: "notification.new_follower.name",
            description: "有新粉丝关注时通知",
            descriptionKey: "notification.new_follower.desc",
            icon: "👥",
            category: .social,
            isDefaultEnabled: true,
            priority: .medium
        )
    ]
}

// MARK: - 通知设置

/// 用户通知设置
@Model
public class DreamNotificationSettings: @unchecked Sendable {
    public var isNotificationsEnabled: Bool
    public var enabledTypeIds: [String]
    public var quietStartHour: Int
    public var quietEndHour: Int
    public var isQuietHoursEnabled: Bool
    public var isCrossDayQuietHours: Bool
    public var soundEnabled: Bool
    public var vibrationEnabled: Bool
    public var badgeEnabled: Bool
    public var showOnLockScreen: Bool
    public var showInHistory: Bool
    public var smartSchedulingEnabled: Bool
    public var lastModified: Date
    
    public init(
        isNotificationsEnabled: Bool = true,
        enabledTypeIds: [String] = [],
        quietStartHour: Int = 23,
        quietEndHour: Int = 7,
        isQuietHoursEnabled: Bool = true,
        isCrossDayQuietHours: Bool = true,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        badgeEnabled: Bool = true,
        showOnLockScreen: Bool = true,
        showInHistory: Bool = true,
        smartSchedulingEnabled: Bool = true,
        lastModified: Date = Date()
    ) {
        self.isNotificationsEnabled = isNotificationsEnabled
        self.enabledTypeIds = enabledTypeIds.isEmpty ? 
            DreamNotificationType.allTypes.filter { $0.isDefaultEnabled }.map { $0.identifier } : 
            enabledTypeIds
        self.quietStartHour = quietStartHour
        self.quietEndHour = quietEndHour
        self.isQuietHoursEnabled = isQuietHoursEnabled
        self.isCrossDayQuietHours = isCrossDayQuietHours
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.badgeEnabled = badgeEnabled
        self.showOnLockScreen = showOnLockScreen
        self.showInHistory = showInHistory
        self.smartSchedulingEnabled = smartSchedulingEnabled
        self.lastModified = lastModified
    }
    
    /// 检查通知类型是否启用
    public func isTypeEnabled(_ typeId: String) -> Bool {
        return isNotificationsEnabled && enabledTypeIds.contains(typeId)
    }
    
    /// 启用或禁用通知类型
    public func setTypeEnabled(_ typeId: String, enabled: Bool) {
        if enabled {
            if !enabledTypeIds.contains(typeId) {
                enabledTypeIds.append(typeId)
            }
        } else {
            enabledTypeIds.removeAll { $0 == typeId }
        }
        lastModified = Date()
    }
    
    /// 检查当前是否在免打扰时段
    public var isCurrentlyInQuietHours: Bool {
        guard isQuietHoursEnabled else { return false }
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        
        if isCrossDayQuietHours {
            // 跨天时段 (如 23:00 - 07:00)
            if quietStartHour > quietEndHour {
                return currentHour >= quietStartHour || currentHour < quietEndHour
            }
        }
        
        // 同一天时段
        return currentHour >= quietStartHour && currentHour < quietEndHour
    }
}

// MARK: - 通知调度配置

/// 通知调度配置
public struct NotificationScheduleConfig: Codable, Sendable {
    public var identifier: String
    public var type: ScheduleType
    public var time: TimeConfig?
    public var recurrence: RecurrenceConfig?
    public var smartAdjustment: SmartAdjustmentConfig?
    public var metadata: [String: String]
    
    public enum ScheduleType: String, Codable {
        case fixedTime = "固定时间"
        case relativeTime = "相对时间"
        case smartTime = "智能时间"
        case eventTrigger = "事件触发"
    }
    
    public struct TimeConfig: Codable, Sendable {
        public var hour: Int
        public var minute: Int
        public var timeZone: String?
        
        public init(hour: Int, minute: Int = 0, timeZone: String? = nil) {
            self.hour = hour
            self.minute = minute
            self.timeZone = timeZone
        }
    }
    
    public struct RecurrenceConfig: Codable, Sendable {
        public var frequency: Frequency
        public var interval: Int
        public var daysOfWeek: Set<Int>?
        public var endDate: Date?
        
        public enum Frequency: String, Codable {
            case hourly = "每小时"
            case daily = "每天"
            case weekly = "每周"
            case monthly = "每月"
            case custom = "自定义"
        }
        
        public init(
            frequency: Frequency,
            interval: Int = 1,
            daysOfWeek: Set<Int>? = nil,
            endDate: Date? = nil
        ) {
            self.frequency = frequency
            self.interval = interval
            self.daysOfWeek = daysOfWeek
            self.endDate = endDate
        }
    }
    
    public struct SmartAdjustmentConfig: Codable, Sendable {
        public var isEnabled: Bool
        public var basedOn: [AdjustmentFactor]
        public var minHour: Int
        public var maxHour: Int
        public var learnFromUserAction: Bool
        
        public enum AdjustmentFactor: String, Codable {
            case userHistory = "用户历史"
            case sleepData = "睡眠数据"
            case calendar = "日程"
            case location = "位置"
            case activity = "活动状态"
        }
        
        public init(
            isEnabled: Bool = true,
            basedOn: [AdjustmentFactor] = [.userHistory],
            minHour: Int = 6,
            maxHour: Int = 23,
            learnFromUserAction: Bool = true
        ) {
            self.isEnabled = isEnabled
            self.basedOn = basedOn
            self.minHour = minHour
            self.maxHour = maxHour
            self.learnFromUserAction = learnFromUserAction
        }
    }
    
    public init(
        identifier: String,
        type: ScheduleType,
        time: TimeConfig? = nil,
        recurrence: RecurrenceConfig? = nil,
        smartAdjustment: SmartAdjustmentConfig? = nil,
        metadata: [String: String] = [:]
    ) {
        self.identifier = identifier
        self.type = type
        self.time = time
        self.recurrence = recurrence
        self.smartAdjustment = smartAdjustment
        self.metadata = metadata
    }
}

// MARK: - 通知历史

/// 通知历史记录
@Model
public class DreamNotificationHistory: @unchecked Sendable {
    public var id: UUID
    public var typeId: String
    public var title: String
    public var body: String
    public var scheduledDate: Date
    public var deliveredDate: Date?
    public var readDate: Date?
    public var isRead: Bool
    public var actionTaken: String?
    public var actionDate: Date?
    public var metadata: [String: String]
    public var isDeleted: Bool
    
    public init(
        id: UUID = UUID(),
        typeId: String,
        title: String,
        body: String,
        scheduledDate: Date,
        deliveredDate: Date? = nil,
        readDate: Date? = nil,
        isRead: Bool = false,
        actionTaken: String? = nil,
        actionDate: Date? = nil,
        metadata: [String: String] = [:],
        isDeleted: Bool = false
    ) {
        self.id = id
        self.typeId = typeId
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.deliveredDate = deliveredDate
        self.readDate = readDate
        self.isRead = isRead
        self.actionTaken = actionTaken
        self.actionDate = actionDate
        self.metadata = metadata
        self.isDeleted = isDeleted
    }
    
    /// 标记为已读
    public func markAsRead() {
        isRead = true
        readDate = Date()
    }
    
    /// 记录用户操作
    public func recordAction(_ action: String) {
        actionTaken = action
        actionDate = Date()
    }
}

// MARK: - 通知统计

/// 通知统计数据
public struct NotificationStats: Codable, Sendable {
    public var totalScheduled: Int
    public var totalDelivered: Int
    public var totalRead: Int
    public var totalActions: Int
    public var deliveryRate: Double
    public var readRate: Double
    public var actionRate: Double
    public var byType: [String: TypeStats]
    public var last7Days: [DailyStats]
    
    public struct TypeStats: Codable, Sendable {
        public var scheduled: Int
        public var delivered: Int
        public var read: Int
        public var actions: Int
        
        public init(scheduled: Int = 0, delivered: Int = 0, read: Int = 0, actions: Int = 0) {
            self.scheduled = scheduled
            self.delivered = delivered
            self.read = read
            self.actions = actions
        }
    }
    
    public struct DailyStats: Codable, Sendable {
        public var date: Date
        public var scheduled: Int
        public var delivered: Int
        public var read: Int
        
        public init(date: Date, scheduled: Int = 0, delivered: Int = 0, read: Int = 0) {
            self.date = date
            self.scheduled = scheduled
            self.delivered = delivered
            self.read = read
        }
    }
    
    public init(
        totalScheduled: Int = 0,
        totalDelivered: Int = 0,
        totalRead: Int = 0,
        totalActions: Int = 0,
        byType: [String: TypeStats] = [:],
        last7Days: [DailyStats] = []
    ) {
        self.totalScheduled = totalScheduled
        self.totalDelivered = totalDelivered
        self.totalRead = totalRead
        self.totalActions = totalActions
        self.deliveryRate = totalScheduled > 0 ? Double(totalDelivered) / Double(totalScheduled) : 0
        self.readRate = totalDelivered > 0 ? Double(totalRead) / Double(totalDelivered) : 0
        self.actionRate = totalDelivered > 0 ? Double(totalActions) / Double(totalDelivered) : 0
        self.byType = byType
        self.last7Days = last7Days
    }
}

// MARK: - 通知动作

/// 通知交互动作
public enum DreamNotificationAction: String, Codable, Sendable {
    case recordDream = "record_dream"
    case viewDetails = "view_details"
    case snooze = "snooze"
    case dismiss = "dismiss"
    case startChallenge = "start_challenge"
    case startMeditation = "start_meditation"
    case viewReport = "view_report"
    case realityCheck = "reality_check"
    
    var title: String {
        switch self {
        case .recordDream: return "立即记录"
        case .viewDetails: return "查看详情"
        case .snooze: return "稍后提醒"
        case .dismiss: return "忽略"
        case .startChallenge: return "开始挑战"
        case .startMeditation: return "开始冥想"
        case .viewReport: return "查看报告"
        case .realityCheck: return "现实检查"
        }
    }
    
    var icon: String {
        switch self {
        case .recordDream: return "🎤"
        case .viewDetails: return "📱"
        case .snooze: return "⏰"
        case .dismiss: return "❌"
        case .startChallenge: return "🎯"
        case .startMeditation: return "🧘"
        case .viewReport: return "📊"
        case .realityCheck: return "👁️"
        }
    }
}
