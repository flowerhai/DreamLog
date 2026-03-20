//
//  DreamCalendarIntegrationModels.swift
//  DreamLog
//
//  Phase 77: Dream Calendar Integration
//  梦境与日历事件关联分析
//

import Foundation
import SwiftData
import EventKit

// MARK: - 日历事件数据模型

/// 日历事件模型
@Model
final class CalendarEvent {
    var eventId: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var notes: String?
    var calendarName: String
    var eventType: CalendarEventType
    var isAllDay: Bool
    
    // 关联的梦境
    @Relationship(deleteRule: .nullify)
    var linkedDreams: [Dream]
    
    // 元数据
    var createdAt: Date
    var lastSyncedAt: Date?
    
    init(
        eventId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        notes: String? = nil,
        calendarName: String,
        eventType: CalendarEventType = .other,
        isAllDay: Bool = false
    ) {
        self.eventId = eventId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.calendarName = calendarName
        self.eventType = eventType
        self.isAllDay = isAllDay
        self.linkedDreams = []
        self.createdAt = Date()
    }
}

/// 日历事件类型
enum CalendarEventType: String, Codable, CaseIterable {
    case work = "工作"
    case meeting = "会议"
    case personal = "个人"
    case family = "家庭"
    case social = "社交"
    case exercise = "运动"
    case travel = "旅行"
    case medical = "医疗"
    case education = "学习"
    case entertainment = "娱乐"
    case sleep = "睡眠"
    case meal = "用餐"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .work: return "💼"
        case .meeting: return "📅"
        case .personal: return "👤"
        case .family: return "👨‍👩‍👧‍👦"
        case .social: return "🎉"
        case .exercise: return "🏃"
        case .travel: return "✈️"
        case .medical: return "🏥"
        case .education: return "📚"
        case .entertainment: return "🎬"
        case .sleep: return "😴"
        case .meal: return "🍽️"
        case .other: return "📌"
        }
    }
    
    var color: String {
        switch self {
        case .work: return "FF6B6B"
        case .meeting: return "4ECDC4"
        case .personal: return "45B7D1"
        case .family: return "96CEB4"
        case .social: return "FFEEAD"
        case .exercise: return "FF6B6B"
        case .travel: return "D4A5A5"
        case .medical: return "9B59B6"
        case .education: return "3498DB"
        case .entertainment: return "E74C3C"
        case .sleep: return "5D6D7E"
        case .meal: return "F39C12"
        case .other: return "95A5A6"
        }
    }
}

// MARK: - 梦境 - 事件关联分析

/// 梦境与事件关联数据
@Model
final class DreamEventCorrelation {
    var id: UUID
    var dreamId: UUID
    var eventId: String
    var timeRelation: TimeRelation
    var correlationStrength: Double // 0-1
    var analysisNotes: String?
    var createdAt: Date
    
    init(
        dreamId: UUID,
        eventId: String,
        timeRelation: TimeRelation,
        correlationStrength: Double,
        analysisNotes: String? = nil
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.eventId = eventId
        self.timeRelation = timeRelation
        self.correlationStrength = correlationStrength
        self.analysisNotes = analysisNotes
        self.createdAt = Date()
    }
}

/// 时间关系类型
enum TimeRelation: String, Codable, CaseIterable {
    case beforeSameDay = "当天之前"      // 事件发生在梦境当天之前
    case beforeNight = "睡前"           // 事件发生在梦境前一晚
    case afterMorning = "醒后"          // 事件发生在梦境次日早晨
    case afterSameDay = "当天之后"      // 事件发生在梦境当天之后
    case recurring = "重复事件"         // 重复发生的事件
    
    var description: String {
        switch self {
        case .beforeSameDay: return "梦境反映了白天的经历"
        case .beforeNight: return "梦境可能是睡前思绪的延续"
        case .afterMorning: return "梦境可能预示了对未来的期待"
        case .afterSameDay: return "梦境可能与未来计划相关"
        case .recurring: return "梦境与长期事件模式相关"
        }
    }
}

// MARK: - 统计数据

/// 日历关联统计
struct CalendarCorrelationStats: Codable {
    var totalLinkedDreams: Int
    var totalEvents: Int
    var averageCorrelationStrength: Double
    var topEventTypes: [(type: CalendarEventType, count: Int)]
    var topTimeRelations: [(relation: TimeRelation, count: Int)]
    var weeklyPattern: [Int] // 每周每天的梦境 - 事件关联数
    var recentCorrelations: [DreamEventCorrelationInfo]
    
    struct DreamEventCorrelationInfo: Codable {
        var dreamTitle: String
        var eventTitle: String
        var eventType: String
        var timeRelation: String
        var date: Date
    }
}

// MARK: - 智能建议

/// 基于日历的梦境建议
struct CalendarBasedSuggestion: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var suggestionType: CalendarSuggestionType
    var priority: Priority
    var relatedEvents: [String] // 事件 ID
    var actionItems: [String]
    var createdAt: Date
    
    init(
        title: String,
        description: String,
        suggestionType: CalendarSuggestionType,
        priority: Priority = .medium,
        relatedEvents: [String] = [],
        actionItems: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.suggestionType = suggestionType
        self.priority = priority
        self.relatedEvents = relatedEvents
        self.actionItems = actionItems
        self.createdAt = Date()
    }
}

/// 建议类型
enum CalendarSuggestionType: String, Codable, CaseIterable {
    case incubation = "梦境孵育"
    case reflection = "反思建议"
    case preparation = "准备建议"
    case stress = "压力管理"
    case opportunity = "创意机会"
    case wellness = "健康建议"
    
    var icon: String {
        switch self {
        case .incubation: return "🌱"
        case .reflection: return "💭"
        case .preparation: return "📋"
        case .stress: return "🧘"
        case .opportunity: return "💡"
        case .wellness: return "💚"
        }
    }
}

/// 优先级
enum Priority: String, Codable, CaseIterable {
    case low = "低"
    case medium = "中"
    case high = "高"
    
    var color: String {
        switch self {
        case .low: return "3498DB"
        case .medium: return "F39C12"
        case .high: return "E74C3C"
        }
    }
}

// MARK: - 时间线视图数据

/// 时间线索引项
struct TimelineItem: Identifiable {
    let id: UUID
    var date: Date
    var itemType: TimelineItemType
    var title: String
    var subtitle: String?
    var icon: String
    var color: String
    var isLinked: Bool // 是否与梦境/事件关联
    
    enum TimelineItemType {
        case dream
        case event
        case milestone
    }
}

// MARK: - 配置

/// 日历集成配置
struct CalendarIntegrationConfig: Codable {
    var enabled: Bool
    var autoSync: Bool
    var syncFrequency: SyncFrequency
    var allowedCalendars: [String] // 允许同步的日历名称
    var defaultLinkWindow: Int // 默认关联时间窗口（小时）
    var notifyOnCorrelation: Bool
    var privacyMode: Bool // 隐私模式：不存储事件详情
    
    static var `default`: CalendarIntegrationConfig {
        CalendarIntegrationConfig(
            enabled: true,
            autoSync: true,
            syncFrequency: .daily,
            allowedCalendars: [], // 空表示所有日历
            defaultLinkWindow: 24,
            notifyOnCorrelation: true,
            privacyMode: false
        )
    }
}

/// 同步频率
enum SyncFrequency: String, Codable, CaseIterable {
    case hourly = "每小时"
    case daily = "每天"
    case weekly = "每周"
    case manual = "手动"
}

// MARK: - 权限状态

/// 日历权限状态
enum CalendarPermissionStatus: String, Codable {
    case notDetermined = "未确定"
    case restricted = "受限"
    case denied = "已拒绝"
    case authorized = "已授权"
    case fullAccess = "完全访问"
    
    var canAccess: Bool {
        self == .authorized || self == .fullAccess
    }
    
    var message: String {
        switch self {
        case .notDetermined: return "需要授权访问日历"
        case .restricted: return "日历访问受限制"
        case .denied: return "请在设置中允许访问日历"
        case .authorized: return "已授权访问日历事件"
        case .fullAccess: return "完全访问日历和提醒"
        }
    }
}
