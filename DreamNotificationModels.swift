//
//  DreamNotificationModels.swift
//  DreamLog
//
//  Phase 69 - 梦境通知中心与小组件增强
//  通知数据模型
//

import Foundation
import UserNotifications

// MARK: - 通知类型枚举

/// 梦境通知类型
enum DreamNotificationType: String, Codable, CaseIterable {
    case sleepReminder      /// 睡前提醒
    case morningRecall      /// 晨间回忆提醒
    case patternInsight     /// 模式洞察
    case challengeProgress  /// 挑战进度
    case meditationSuggestion /// 冥想建议
    case weeklyReport       /// 周报推送
    case lucidPrompt        /// 清醒梦提示
    case moodCheck          /// 情绪检查
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .sleepReminder: return "睡前提醒"
        case .morningRecall: return "晨间回忆"
        case .patternInsight: return "模式洞察"
        case .challengeProgress: return "挑战进度"
        case .meditationSuggestion: return "冥想建议"
        case .weeklyReport: return "周报推送"
        case .lucidPrompt: return "清醒梦提示"
        case .moodCheck: return "情绪检查"
        }
    }
    
    /// 默认图标
    var icon: String {
        switch self {
        case .sleepReminder: return "moon.fill"
        case .morningRecall: return "sunrise.fill"
        case .patternInsight: return "lightbulb.fill"
        case .challengeProgress: return "target"
        case .meditationSuggestion: return "sparkles"
        case .weeklyReport: return "chart.bar.fill"
        case .lucidPrompt: return "eye.fill"
        case .moodCheck: return "heart.fill"
        }
    }
    
    /// 默认颜色
    var color: String {
        switch self {
        case .sleepReminder: return "#6B46C1"
        case .morningRecall: return "#ED8936"
        case .patternInsight: return "#ECC94B"
        case .challengeProgress: return "#48BB78"
        case .meditationSuggestion: return "#4299E1"
        case .weeklyReport: return "#ED64A6"
        case .lucidPrompt: return "#9F7AEA"
        case .moodCheck: return "#F56565"
        }
    }
}

// MARK: - 通知配置模型

/// 单个通知配置
struct DreamNotificationConfig: Identifiable, Codable {
    let id: String
    var type: DreamNotificationType
    var isEnabled: Bool
    var scheduledTime: String? // HH:mm 格式
    var customMessage: String?
    var frequency: NotificationFrequency
    
    init(id: String = UUID().uuidString,
         type: DreamNotificationType,
         isEnabled: Bool = true,
         scheduledTime: String? = nil,
         customMessage: String? = nil,
         frequency: NotificationFrequency = .daily) {
        self.id = id
        self.type = type
        self.isEnabled = isEnabled
        self.scheduledTime = scheduledTime
        self.customMessage = customMessage
        self.frequency = frequency
    }
}

/// 通知频率
enum NotificationFrequency: String, Codable, CaseIterable {
    case once          /// 仅一次
    case daily         /// 每天
    case weekly        /// 每周
    case weekdays      /// 工作日
    case weekends      /// 周末
    case custom        /// 自定义
    
    var displayName: String {
        switch self {
        case .once: return "仅一次"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .weekdays: return "工作日"
        case .weekends: return "周末"
        case .custom: return "自定义"
        }
    }
}

// MARK: - 通知设置

/// 全局通知设置
struct DreamNotificationSettings: Codable {
    var isNotificationsEnabled: Bool
    var isSmartSchedulingEnabled: Bool
    var quietHoursStart: String // HH:mm
    var quietHoursEnd: String   // HH:mm
    var configurations: [DreamNotificationConfig]
    var lastWeeklyReportDate: Date?
    
    static var `default`: DreamNotificationSettings {
        DreamNotificationSettings(
            isNotificationsEnabled: true,
            isSmartSchedulingEnabled: true,
            quietHoursStart: "22:00",
            quietHoursEnd: "08:00",
            configurations: DreamNotificationConfig.defaultConfigurations,
            lastWeeklyReportDate: nil
        )
    }
}

extension DreamNotificationConfig {
    /// 默认配置列表
    static var defaultConfigurations: [DreamNotificationConfig] {
        [
            DreamNotificationConfig(
                type: .sleepReminder,
                isEnabled: true,
                scheduledTime: "22:00",
                frequency: .daily
            ),
            DreamNotificationConfig(
                type: .morningRecall,
                isEnabled: true,
                scheduledTime: "07:30",
                frequency: .daily
            ),
            DreamNotificationConfig(
                type: .patternInsight,
                isEnabled: true,
                frequency: .weekly
            ),
            DreamNotificationConfig(
                type: .challengeProgress,
                isEnabled: true,
                frequency: .daily
            ),
            DreamNotificationConfig(
                type: .meditationSuggestion,
                isEnabled: false,
                frequency: .daily
            ),
            DreamNotificationConfig(
                type: .weeklyReport,
                isEnabled: true,
                scheduledTime: "20:00",
                frequency: .weekly
            ),
            DreamNotificationConfig(
                type: .lucidPrompt,
                isEnabled: false,
                frequency: .daily
            ),
            DreamNotificationConfig(
                type: .moodCheck,
                isEnabled: false,
                scheduledTime: "18:00",
                frequency: .weekdays
            )
        ]
    }
}

// MARK: - 通知内容模型

/// 通知内容
struct DreamNotificationContent: Codable {
    let title: String
    let body: String
    let subtitle: String?
    let sound: String
    let badge: Int?
    let categoryIdentifier: String
    let userInfo: [String: AnyCodable]
    
    init(title: String,
         body: String,
         subtitle: String? = nil,
         sound: String = "default",
         badge: Int? = nil,
         categoryIdentifier: String = "DREAM_CATEGORY",
         userInfo: [String: AnyCodable] = [:]) {
        self.title = title
        self.body = body
        self.subtitle = subtitle
        self.sound = sound
        self.badge = badge
        self.categoryIdentifier = categoryIdentifier
        self.userInfo = userInfo
    }
}

/// 支持 Any 类型的 Codable 包装器
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to encode value"
                )
            )
        }
    }
}

// MARK: - 智能调度数据

/// 智能调度分析结果
struct SmartScheduleAnalysis: Codable {
    var bestSleepTime: String?      // 最佳入睡时间
    var bestWakeTime: String?       // 最佳醒来时间
    var averageDreamRecallTime: Int // 平均梦境回忆时间（分钟）
    var recordFrequencyPattern: String // 记录频率模式
    var sleepQualityScore: Double   // 睡眠质量评分
    var recommendedReminders: [DreamNotificationType] // 推荐的通知类型
    
    init() {
        self.bestSleepTime = nil
        self.bestWakeTime = nil
        self.averageDreamRecallTime = 15
        self.recordFrequencyPattern = "irregular"
        self.sleepQualityScore = 0.0
        self.recommendedReminders = [.sleepReminder, .morningRecall]
    }
}

/// 用户活动模式
struct UserActivityPattern: Codable {
    var typicalBedTime: String?     // 通常上床时间
    var typicalWakeTime: String?    // 通常起床时间
    var recordTimes: [String]       // 常见记录时间
    var activeHours: Set<Int>       // 活跃小时
    var timezone: String            // 时区
    
    init() {
        self.typicalBedTime = nil
        self.typicalWakeTime = nil
        self.recordTimes = []
        self.activeHours = Set()
        self.timezone = TimeZone.current.identifier
    }
}

// MARK: - 通知统计

/// 通知统计
struct NotificationStatistics: Codable {
    var totalSent: Int              // 总发送数
    var totalOpened: Int            // 总打开数
    var openRate: Double            // 打开率
    var byType: [String: TypeStats] // 按类型统计
    var lastSentDate: Date?         // 最后发送时间
    var bestPerformingType: String? // 表现最好的类型
    
    init() {
        self.totalSent = 0
        self.totalOpened = 0
        self.openRate = 0.0
        self.byType = [:]
        self.lastSentDate = nil
        self.bestPerformingType = nil
    }
    
    struct TypeStats: Codable {
        var sent: Int
        var opened: Int
        var openRate: Double
        
        init() {
            self.sent = 0
            self.opened = 0
            self.openRate = 0.0
        }
    }
}

// MARK: - 小组件数据模型

/// 小组件数据
struct DreamWidgetData: Codable {
    var dreamsCountToday: Int       // 今日梦境数
    var dreamsCountWeek: Int        // 本周梦境数
    var streakDays: Int             // 连续记录天数
    var averageClarity: Double      // 平均清晰度
    var currentChallenge: ChallengeWidgetData?
    var dailyInsight: InsightWidgetData?
    var lastUpdated: Date           // 最后更新时间
    
    init() {
        self.dreamsCountToday = 0
        self.dreamsCountWeek = 0
        self.streakDays = 0
        self.averageClarity = 0.0
        self.currentChallenge = nil
        self.dailyInsight = nil
        self.lastUpdated = Date()
    }
}

/// 挑战小组件数据
struct ChallengeWidgetData: Codable {
    var id: String
    var name: String
    var progress: Double
    var target: Int
    var current: Int
    var timeRemaining: TimeInterval?
    var icon: String
    
    init(id: String = "",
         name: String = "",
         progress: Double = 0.0,
         target: Int = 0,
         current: Int = 0,
         timeRemaining: TimeInterval? = nil,
         icon: String = "target") {
        self.id = id
        self.name = name
        self.progress = progress
        self.target = target
        self.current = current
        self.timeRemaining = timeRemaining
        self.icon = icon
    }
}

/// 洞察小组件数据
struct InsightWidgetData: Codable {
    var title: String
    var content: String
    var type: String
    var icon: String
    
    init(title: String = "",
         content: String = "",
         type: String = "insight",
         icon: String = "lightbulb.fill") {
        self.title = title
        self.content = content
        self.type = type
        self.icon = icon
    }
}

// MARK: - 实时活动数据

/// 实时活动状态
enum LiveActivityState: String, Codable {
    case active      // 进行中
    case completed   // 已完成
    case dismissed   // 已关闭
}

/// 挑战实时活动数据
struct ChallengeLiveActivityData: Codable {
    var challengeId: String
    var challengeName: String
    var challengeType: String
    var progress: Double
    var currentCount: Int
    var targetCount: Int
    var timeRemaining: TimeInterval
    var state: LiveActivityState
    var startedAt: Date
    var endsAt: Date?
    
    init(challengeId: String = "",
         challengeName: String = "",
         challengeType: String = "",
         progress: Double = 0.0,
         currentCount: Int = 0,
         targetCount: Int = 0,
         timeRemaining: TimeInterval = 0,
         state: LiveActivityState = .active,
         startedAt: Date = Date(),
         endsAt: Date? = nil) {
        self.challengeId = challengeId
        self.challengeName = challengeName
        self.challengeType = challengeType
        self.progress = progress
        self.currentCount = currentCount
        self.targetCount = targetCount
        self.timeRemaining = timeRemaining
        self.state = state
        self.startedAt = startedAt
        self.endsAt = endsAt
    }
}

/// 孵育实时活动数据
struct IncubationLiveActivityData: Codable {
    var incubationId: String
    var goal: String
    var affirmations: [String]
    var currentAffirmationIndex: Int
    var timeRemaining: TimeInterval
    var state: LiveActivityState
    var startedAt: Date
    var targetSleepTime: Date?
    
    init(incubationId: String = "",
         goal: String = "",
         affirmations: [String] = [],
         currentAffirmationIndex: Int = 0,
         timeRemaining: TimeInterval = 0,
         state: LiveActivityState = .active,
         startedAt: Date = Date(),
         targetSleepTime: Date? = nil) {
        self.incubationId = incubationId
        self.goal = goal
        self.affirmations = affirmations
        self.currentAffirmationIndex = currentAffirmationIndex
        self.timeRemaining = timeRemaining
        self.state = state
        self.startedAt = startedAt
        self.targetSleepTime = targetSleepTime
    }
}

// MARK: - 通知操作

/// 通知操作类型
enum NotificationActionType: String, Codable {
    case recordDream      // 记录梦境
    case viewInsight      // 查看洞察
    case startChallenge   // 开始挑战
    case snooze           // 稍后提醒
    case dismiss          // 关闭
    
    var identifier: String {
        "DREAM_ACTION_\(rawValue.uppercased())"
    }
    
    var title: String {
        switch self {
        case .recordDream: return "记录梦境"
        case .viewInsight: return "查看详情"
        case .startChallenge: return "开始挑战"
        case .snooze: return "稍后提醒"
        case .dismiss: return "关闭"
        }
    }
}

// MARK: - 通知类别

/// 通知类别配置
struct DreamNotificationCategory: Codable {
    let identifier: String
    let actions: [NotificationActionType]
    let intentIdentifiers: [String]
    let hiddenPreviewsBodyPlaceholder: String?
    let categorySummaryFormat: String?
    let options: Options
    
    struct Options: OptionSet, Codable {
        let rawValue: Int
        static let customDismissAction = Options(rawValue: 1 << 0)
        static let allowInCarPlay = Options(rawValue: 1 << 1)
        static let hiddenPreviewsShowTitle = Options(rawValue: 1 << 2)
        static let hiddenPreviewsShowSubtitle = Options(rawValue: 1 << 3)
        static let threadNotifiesSummary = Options(rawValue: 1 << 4)
    }
    
    init(identifier: String,
         actions: [NotificationActionType],
         intentIdentifiers: [String] = [],
         hiddenPreviewsBodyPlaceholder: String? = nil,
         categorySummaryFormat: String? = nil,
         options: Options = []) {
        self.identifier = identifier
        self.actions = actions
        self.intentIdentifiers = intentIdentifiers
        self.hiddenPreviewsBodyPlaceholder = hiddenPreviewsBodyPlaceholder
        self.categorySummaryFormat = categorySummaryFormat
        self.options = options
    }
}
