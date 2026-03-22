//
//  DreamTimelineModels.swift
//  DreamLog
//
//  Phase 86: Dream Timeline & Life Events
//  Visual timeline correlating dreams with significant life events
//

import Foundation
import SwiftData

// MARK: - Life Event Models

/// Significant life event that may influence dreams
@Model
final class LifeEvent {
    var id: UUID
    var title: String
    var description: String?
    var date: Date
    var endDate: Date?  // For events with duration
    var category: LifeEventCategory
    var impactLevel: ImpactLevel
    var emotions: [Emotion]
    var tags: [String]
    var relatedDreamIds: [UUID]
    var isPublic: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        date: Date,
        endDate: Date? = nil,
        category: LifeEventCategory,
        impactLevel: ImpactLevel = .medium,
        emotions: [Emotion] = [],
        tags: [String] = [],
        relatedDreamIds: [UUID] = [],
        isPublic: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.endDate = endDate
        self.category = category
        self.impactLevel = impactLevel
        self.emotions = emotions
        self.tags = tags
        self.relatedDreamIds = relatedDreamIds
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Enums

/// Life event categories
enum LifeEventCategory: String, Codable, CaseIterable {
    case personal = "personal"  // Personal growth, achievements
    case relationship = "relationship"  // Relationships, family, friends
    case career = "career"  // Work, education, career changes
    case health = "health"  // Health, fitness, wellness
    case travel = "travel"  // Trips, moves, relocations
    case creative = "creative"  // Creative projects, hobbies
    case spiritual = "spiritual"  // Spiritual experiences, meditation
    case challenge = "challenge"  // Difficulties, losses, challenges
    case celebration = "celebration"  // Celebrations, holidays
    case other = "other"  // Other events
    
    var displayName: String {
        switch self {
        case .personal: return "个人成长"
        case .relationship: return "人际关系"
        case .career: return "职业学业"
        case .health: return "健康健身"
        case .travel: return "旅行搬迁"
        case .creative: return "创意爱好"
        case .spiritual: return "精神灵性"
        case .challenge: return "挑战困难"
        case .celebration: return "庆祝节日"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "🌱"
        case .relationship: return "💕"
        case .career: return "💼"
        case .health: return "💪"
        case .travel: return "✈️"
        case .creative: return "🎨"
        case .spiritual: return "🧘"
        case .challenge: return "⚡"
        case .celebration: return "🎉"
        case .other: return "📌"
        }
    }
    
    var color: String {
        switch self {
        case .personal: return "34C759"
        case .relationship: return "FF2D55"
        case .career: return "5856D6"
        case .health: return "FF9500"
        case .travel: return "007AFF"
        case .creative: return "FF2D55"
        case .spiritual: return "AF52DE"
        case .challenge: return "FF3B30"
        case .celebration: return "FFCC00"
        case .other: return "8E8E93"
        }
    }
}

/// Impact level of life event
enum ImpactLevel: Int, Codable, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case transformative = 4
    
    var displayName: String {
        switch self {
        case .low: return "轻微"
        case .medium: return "中等"
        case .high: return "重大"
        case .transformative: return "变革性"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "34C759"
        case .medium: return "FFCC00"
        case .high: return "FF9500"
        case .transformative: return "FF3B30"
        }
    }
}

// MARK: - Timeline Models

/// Timeline entry (unified dream or life event)
struct TimelineEntry: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let type: EntryType
    let title: String
    let subtitle: String?
    let description: String?
    let category: String?
    let impactLevel: ImpactLevel?
    let emotions: [Emotion]
    let tags: [String]
    let clarity: Int?  // For dreams only
    let isLucid: Bool?  // For dreams only
    
    enum EntryType: String, CaseIterable {
        case dream = "dream"
        case lifeEvent = "life_event"
        
        var displayName: String {
            switch self {
            case .dream: return "梦境"
            case .lifeEvent: return "生活事件"
            }
        }
        
        var icon: String {
            switch self {
            case .dream: return "🌙"
            case .lifeEvent: return "📍"
            }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TimelineEntry, rhs: TimelineEntry) -> Bool {
        lhs.id == rhs.id
    }
}

/// Timeline correlation between life events and dreams
struct DreamLifeCorrelation {
    let lifeEvent: LifeEvent
    let relatedDreams: [Dream]
    let correlationScore: Double  // 0-1
    let patternType: PatternType
    let insights: [String]
    let recommendations: [String]
    
    enum PatternType: String {
        case increasedFrequency = "increased_frequency"  // More dreams after event
        case emotionalShift = "emotional_shift"  // Emotion change in dreams
        case themeChange = "theme_change"  // New dream themes
        case clarityChange = "clarity_change"  // Clarity increase/decrease
        case lucidIncrease = "lucid_increase"  // More lucid dreams
        case none = "none"
        
        var displayName: String {
            switch self {
            case .increasedFrequency: return "频率增加"
            case .emotionalShift: return "情绪变化"
            case .themeChange: return "主题变化"
            case .clarityChange: return "清晰度变化"
            case .lucidIncrease: return "清醒梦增加"
            case .none: return "无明显关联"
            }
        }
    }
}

/// Timeline statistics
struct TimelineStatistics {
    let totalDreams: Int
    let totalLifeEvents: Int
    let dateRange: ClosedRange<Date>
    let dreamsPerMonth: Double
    let eventsPerMonth: Double
    let categoryDistribution: [LifeEventCategory: Int]
    let impactDistribution: [ImpactLevel: Int]
    let topCorrelations: [DreamLifeCorrelation]
    let milestoneEvents: [LifeEvent]
    let dreamFrequencyTrend: TrendDirection
    let averageCorrelationScore: Double
    
    enum TrendDirection: String {
        case increasing = "increasing"
        case decreasing = "decreasing"
        case stable = "stable"
        case fluctuating = "fluctuating"
        
        var displayName: String {
            switch self {
            case .increasing: return "上升"
            case .decreasing: return "下降"
            case .stable: return "稳定"
            case .fluctuating: return "波动"
            }
        }
        
        var icon: String {
            switch self {
            case .increasing: return "📈"
            case .decreasing: return "📉"
            case .stable: return "➡️"
            case .fluctuating: return "〰️"
            }
        }
    }
}

/// Timeline view configuration
struct TimelineConfig {
    var showDreams: Bool
    var showLifeEvents: Bool
    var selectedCategories: Set<LifeEventCategory>
    var minImpactLevel: ImpactLevel
    var dateRange: DateRange
    var groupByTime: TimeGrouping
    
    enum TimeGrouping: String, CaseIterable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
        
        var displayName: String {
            switch self {
            case .day: return "按天"
            case .week: return "按周"
            case .month: return "按月"
            case .year: return "按年"
            }
        }
    }
    
    enum DateRange: String, CaseIterable {
        case last30Days = "最近 30 天"
        case last90Days = "最近 90 天"
        case last6Months = "最近 6 个月"
        case lastYear = "最近 1 年"
        case all = "全部"
        
        var dateRange: ClosedRange<Date>? {
            let now = Date()
            switch self {
            case .last30Days:
                guard let start = Calendar.current.date(byAdding: .day, value: -30, to: now) else { return nil }
                return start...now
            case .last90Days:
                guard let start = Calendar.current.date(byAdding: .day, value: -90, to: now) else { return nil }
                return start...now
            case .last6Months:
                guard let start = Calendar.current.date(byAdding: .month, value: -6, to: now) else { return nil }
                return start...now
            case .lastYear:
                guard let start = Calendar.current.date(byAdding: .year, value: -1, to: now) else { return nil }
                return start...now
            case .all:
                return nil
            }
        }
    }
    
    static var `default`: TimelineConfig {
        TimelineConfig(
            showDreams: true,
            showLifeEvents: true,
            selectedCategories: Set(LifeEventCategory.allCases),
            minImpactLevel: .low,
            dateRange: .last90Days,
            groupByTime: .week
        )
    }
}

// MARK: - Milestone Models

/// Milestone achievement in dream journey
struct TimelineMilestone: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let achievedDate: Date
    let requirement: MilestoneRequirement
    let reward: String?
    
    enum MilestoneRequirement {
        case dreamCount(Int)
        case consecutiveDays(Int)
        case lifeEventsCount(Int)
        case correlationDiscovered
        case categoryCompletion(Set<LifeEventCategory>)
        case timeTracked(Double)  // Days
        
        var displayName: String {
            switch self {
            case .dreamCount(let count): return "记录 \(count) 个梦境"
            case .consecutiveDays(let days): return "连续记录 \(days) 天"
            case .lifeEventsCount(let count): return "标记 \(count) 个生活事件"
            case .correlationDiscovered: return "发现梦境 - 生活关联"
            case .categoryCompletion: return "完成所有类别事件记录"
            case .timeTracked(let days): return "追踪 \(Int(days)) 天"
            }
        }
    }
}
