//
//  DreamWidgetModels.swift
//  DreamLog
//
//  iOS 小组件数据模型 - Phase 33
//

import Foundation
import WidgetKit

// MARK: - 小组件配置

/// 小组件类型枚举
enum DreamWidgetKind: String, CaseIterable, Codable, Identifiable {
    case quickRecord = "quick_record"
    case dailyStats = "daily_stats"
    case dreamQuote = "dream_quote"
    case moodTracker = "mood_tracker"
    case tagFilter = "tag_filter"
    case recentDreams = "recent_dreams"
    case streakCounter = "streak_counter"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .quickRecord: return "快速记录"
        case .dailyStats: return "今日统计"
        case .dreamQuote: return "梦境名言"
        case .moodTracker: return "情绪追踪"
        case .tagFilter: return "标签筛选"
        case .recentDreams: return "最近梦境"
        case .streakCounter: return "连续记录"
        }
    }
    
    var icon: String {
        switch self {
        case .quickRecord: return "🎤"
        case .dailyStats: return "📊"
        case .dreamQuote: return "💭"
        case .moodTracker: return "😊"
        case .tagFilter: return "🏷️"
        case .recentDreams: return "🌙"
        case .streakCounter: return "🔥"
        }
    }
    
    var supportedFamilies: [WidgetFamily] {
        switch self {
        case .quickRecord, .moodTracker, .streakCounter:
            return [.systemSmall, .accessoryCircular, .accessoryRectangular]
        case .dailyStats, .dreamQuote:
            return [.systemSmall, .systemMedium, .accessoryRectangular]
        case .tagFilter, .recentDreams:
            return [.systemMedium, .systemLarge]
        }
    }
}

/// 小组件主题配置
struct WidgetTheme: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var nameKey: String
    var backgroundColor: String
    var textColor: String
    var accentColor: String
    var gradientStart: String
    var gradientEnd: String
    var isDark: Bool
    
    init(id: UUID = UUID(), name: String, nameKey: String, backgroundColor: String, textColor: String, accentColor: String, gradientStart: String, gradientEnd: String, isDark: Bool) {
        self.id = id
        self.name = name
        self.nameKey = nameKey
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.accentColor = accentColor
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.isDark = isDark
    }
    
    static let allThemes: [WidgetTheme] = [
        WidgetTheme(
            name: "星空紫",
            nameKey: "theme_starry_purple",
            backgroundColor: "1A1A2E",
            textColor: "FFFFFF",
            accentColor: "9D4EDD",
            gradientStart: "1A1A2E",
            gradientEnd: "4A1C6E",
            isDark: true
        ),
        WidgetTheme(
            name: "日落橙",
            nameKey: "theme_sunset_orange",
            backgroundColor: "FF6B35",
            textColor: "FFFFFF",
            accentColor: "FFD23F",
            gradientStart: "FF6B35",
            gradientEnd: "F7C59F",
            isDark: false
        ),
        WidgetTheme(
            name: "森林绿",
            nameKey: "theme_forest_green",
            backgroundColor: "2D6A4F",
            textColor: "FFFFFF",
            accentColor: "52B788",
            gradientStart: "1B4332",
            gradientEnd: "52B788",
            isDark: true
        ),
        WidgetTheme(
            name: "海洋蓝",
            nameKey: "theme_ocean_blue",
            backgroundColor: "0077B6",
            textColor: "FFFFFF",
            accentColor: "90E0EF",
            gradientStart: "03045E",
            gradientEnd: "0077B6",
            isDark: true
        ),
        WidgetTheme(
            name: "午夜黑",
            nameKey: "theme_midnight_black",
            backgroundColor: "000000",
            textColor: "FFFFFF",
            accentColor: "6C757D",
            gradientStart: "000000",
            gradientEnd: "2C2C2C",
            isDark: true
        ),
        WidgetTheme(
            name: "玫瑰粉",
            nameKey: "theme_rose_pink",
            backgroundColor: "FFC2D1",
            textColor: "590D22",
            accentColor: "FF8FA3",
            gradientStart: "FFC2D1",
            gradientEnd: "FF8FA3",
            isDark: false
        ),
        WidgetTheme(
            name: "奢华金",
            nameKey: "theme_luxury_gold",
            backgroundColor: "1A1A1A",
            textColor: "FFD700",
            accentColor: "FFA500",
            gradientStart: "1A1A1A",
            gradientEnd: "4A3C00",
            isDark: true
        ),
        WidgetTheme(
            name: "薰衣草",
            nameKey: "theme_lavender",
            backgroundColor: "E6E6FA",
            textColor: "4B0082",
            accentColor: "9370DB",
            gradientStart: "E6E6FA",
            gradientEnd: "D8BFD8",
            isDark: false
        )
    ]
    
    static let `default` = WidgetTheme.allThemes[0]
}

/// 小组件布局配置
struct WidgetLayout: Codable, Hashable {
    var showTitle: Bool
    var showIcon: Bool
    var showDate: Bool
    var showStats: Bool
    var fontSize: WidgetFontSize
    var cornerRadius: CGFloat
    var padding: CGFloat
    
    enum WidgetFontSize: String, Codable, CaseIterable {
        case small = "小"
        case medium = "中"
        case large = "大"
        
        var title: String { rawValue }
    }
    
    static let `default` = WidgetLayout(
        showTitle: true,
        showIcon: true,
        showDate: true,
        showStats: true,
        fontSize: .medium,
        cornerRadius: 16,
        padding: 12
    )
}

// MARK: - 小组件数据

/// 快速记录入口数据
struct QuickRecordEntry: Codable {
    var isRecording: Bool
    var lastRecordDate: Date?
    var todayCount: Int
    var weeklyGoal: Int
    var progress: Double
    
    static let empty = QuickRecordEntry(
        isRecording: false,
        lastRecordDate: nil,
        todayCount: 0,
        weeklyGoal: 7,
        progress: 0
    )
}

/// 统计数据
struct DreamStats: Codable {
    var todayCount: Int
    var weekCount: Int
    var monthCount: Int
    var totalCount: Int
    var streakDays: Int
    var longestStreak: Int
    var averageClarity: Double
    var commonEmotions: [String]
    var commonTags: [String]
    
    static let empty = DreamStats(
        todayCount: 0,
        weekCount: 0,
        monthCount: 0,
        totalCount: 0,
        streakDays: 0,
        longestStreak: 0,
        averageClarity: 0,
        commonEmotions: [],
        commonTags: []
    )
}

/// 梦境名言
struct DreamQuote: Codable {
    var content: String
    var date: Date
    var tags: [String]
    var emotions: [String]
    var clarity: Int
    
    static let empty = DreamQuote(
        content: "记录你的第一个梦境...",
        date: Date(),
        tags: [],
        emotions: [],
        clarity: 0
    )
}

/// 情绪追踪数据
struct MoodTracking: Codable {
    var currentMood: String?
    var moodHistory: [MoodEntry]
    var commonMoods: [String: Int]
    
    struct MoodEntry: Codable {
        var mood: String
        var date: Date
        var intensity: Int
    }
    
    static let empty = MoodTracking(
        currentMood: nil,
        moodHistory: [],
        commonMoods: [:]
    )
}

/// 标签筛选数据
struct TagFilterData: Codable {
    var frequentTags: [TagInfo]
    var recentTags: [TagInfo]
    var totalCount: Int
    
    struct TagInfo: Codable {
        var name: String
        var count: Int
        var category: String?
    }
    
    static let empty = TagFilterData(
        frequentTags: [],
        recentTags: [],
        totalCount: 0
    )
}

/// 最近梦境数据
struct RecentDreamsData: Codable {
    var dreams: [DreamSummary]
    var hasMore: Bool
    
    struct DreamSummary: Codable {
        var id: String
        var title: String
        var preview: String
        var date: Date
        var emotions: [String]
        var tags: [String]
        var clarity: Int
    }
    
    static let empty = RecentDreamsData(dreams: [], hasMore: false)
}

/// 连续记录数据
struct StreakData: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastRecordDate: Date?
    var nextMilestone: Int
    var weeklyGoal: Int
    var weeklyProgress: Int
    
    static let empty = StreakData(
        currentStreak: 0,
        longestStreak: 0,
        lastRecordDate: nil,
        nextMilestone: 7,
        weeklyGoal: 7,
        weeklyProgress: 0
    )
}

// MARK: - 小组件意图

/// 小组件操作意图
enum WidgetIntent: String, Codable, CaseIterable {
    case startRecording = "start_recording"
    case stopRecording = "stop_recording"
    case likeDream = "like_dream"
    case favoriteDream = "favorite_dream"
    case filterByTag = "filter_by_tag"
    case setMood = "set_mood"
    case viewStats = "view_stats"
    case openApp = "open_app"
    
    var displayName: String {
        switch self {
        case .startRecording: return "开始记录"
        case .stopRecording: return "停止记录"
        case .likeDream: return "点赞"
        case .favoriteDream: return "收藏"
        case .filterByTag: return "筛选标签"
        case .setMood: return "设置情绪"
        case .viewStats: return "查看统计"
        case .openApp: return "打开应用"
        }
    }
}

// MARK: - 时间线提供者

/// 小组件时间线条目
struct WidgetTimelineEntry: TimelineEntry {
    var date: Date
    var kind: DreamWidgetKind
    var theme: WidgetTheme
    var layout: WidgetLayout
    
    // 数据
    var quickRecord: QuickRecordEntry?
    var stats: DreamStats?
    var quote: DreamQuote?
    var mood: MoodTracking?
    var tags: TagFilterData?
    var recentDreams: RecentDreamsData?
    var streak: StreakData?
    
    var configuration: WidgetConfigurationIntent?
}
