//
//  DreamEBookExportModels.swift
//  DreamLog
//
//  Phase 83: 梦境电子书导出功能
//  数据模型：定义电子书配置、章节、主题等数据结构
//

import Foundation
import SwiftUI

// MARK: - 电子书配置模型

/// 电子书导出配置
struct EBookExportConfig: Codable, Equatable {
    var title: String
    var subtitle: String
    var authorName: String
    var coverEmoji: String
    var theme: EBookTheme
    var dateRange: EBookDateRange
    var includeDreams: [UUID]  // 空表示包含所有符合条件的梦境
    var chapters: [EBookChapter]
    var tableOfContents: Bool
    var pageNumbering: Bool
    var dreamDetails: DreamDetailOptions
    var exportFormat: EBookExportFormat
    
    init(
        title: String = "我的梦境日记",
        subtitle: String = "",
        authorName: String = "",
        coverEmoji: String = "🌙",
        theme: EBookTheme = .classic,
        dateRange: EBookDateRange = .all,
        includeDreams: [UUID] = [],
        chapters: [EBookChapter] = [],
        tableOfContents: Bool = true,
        pageNumbering: Bool = true,
        dreamDetails: DreamDetailOptions = DreamDetailOptions(),
        exportFormat: EBookExportFormat = .pdf
    ) {
        self.title = title
        self.subtitle = subtitle
        self.authorName = authorName
        self.coverEmoji = coverEmoji
        self.theme = theme
        self.dateRange = dateRange
        self.includeDreams = includeDreams
        self.chapters = chapters
        self.tableOfContents = tableOfContents
        self.pageNumbering = pageNumbering
        self.dreamDetails = dreamDetails
        self.exportFormat = exportFormat
    }
}

// MARK: - 电子书主题

/// 电子书视觉主题
enum EBookTheme: String, Codable, CaseIterable, Identifiable {
    case classic = "classic"           // 经典黑白
    case elegant = "elegant"           // 优雅深色
    case dreamy = "dreamy"             // 梦幻紫色
    case nature = "nature"             // 自然绿色
    case ocean = "ocean"               // 海洋蓝色
    case sunset = "sunset"             // 日落橙色
    case minimalist = "minimalist"     // 极简主义
    case luxury = "luxury"             // 奢华金色
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .classic: return "经典黑白"
        case .elegant: return "优雅深色"
        case .dreamy: return "梦幻紫色"
        case .nature: return "自然绿色"
        case .ocean: return "海洋蓝色"
        case .sunset: return "日落橙色"
        case .minimalist: return "极简主义"
        case .luxury: return "奢华金色"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .classic: return .black
        case .elegant: return Color(hex: "1a1a2e")
        case .dreamy: return Color(hex: "6b5b95")
        case .nature: return Color(hex: "4a7c59")
        case .ocean: return Color(hex: "006994")
        case .sunset: return Color(hex: "fd5e53")
        case .minimalist: return .gray
        case .luxury: return Color(hex: "d4af37")
        }
    }
    
    var accentColor: Color {
        switch self {
        case .classic: return .gray
        case .elegant: return Color(hex: "16213e")
        case .dreamy: return Color(hex: "8b7b9b")
        case .nature: return Color(hex: "6b9080")
        case .ocean: return Color(hex: "00a8cc")
        case .sunset: return Color(hex: "fcbf49")
        case .minimalist: return .lightGray
        case .luxury: return Color(hex: "f4e4bc")
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .classic: return .white
        case .elegant: return Color(hex: "0f0f1a")
        case .dreamy: return Color(hex: "f5f3ff")
        case .nature: return Color(hex: "f0f7f4")
        case .ocean: return Color(hex: "f0f8ff")
        case .sunset: return Color(hex: "fff8f0")
        case .minimalist: return .white
        case .luxury: return Color(hex: "fefefe")
        }
    }
    
    var fontFamily: String {
        switch self {
        case .classic, .elegant, .luxury: return "Georgia"
        case .dreamy, .nature, .ocean, .sunset: return "Palatino"
        case .minimalist: return "Helvetica Neue"
        }
    }
}

// MARK: - 日期范围

/// 电子书包含的日期范围
enum EBookDateRange: String, Codable, CaseIterable, Identifiable {
    case all = "all"                   // 全部
    case last7Days = "last7Days"       // 最近 7 天
    case last30Days = "last30Days"     // 最近 30 天
    case last90Days = "last90Days"     // 最近 90 天
    case thisYear = "thisYear"         // 今年
    case lastYear = "lastYear"         // 去年
    case custom = "custom"             // 自定义
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "全部梦境"
        case .last7Days: return "最近 7 天"
        case .last30Days: return "最近 30 天"
        case .last90Days: return "最近 90 天"
        case .thisYear: return "今年"
        case .lastYear: return "去年"
        case .custom: return "自定义范围"
        }
    }
}

// MARK: - 章节配置

/// 电子书章节配置
struct EBookChapter: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var type: EBookChapterType
    var dateRange: ClosedRange<Date>?
    var dreamIds: [UUID]
    var sortOrder: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        type: EBookChapterType = .manual,
        dateRange: ClosedRange<Date>? = nil,
        dreamIds: [UUID] = [],
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.dateRange = dateRange
        self.dreamIds = dreamIds
        self.sortOrder = sortOrder
    }
}

/// 章节类型
enum EBookChapterType: String, Codable, CaseIterable, Identifiable {
    case manual = "manual"             // 手动选择
    case byMonth = "byMonth"           // 按月份
    case byEmotion = "byEmotion"       // 按情绪
    case byTheme = "byTheme"           // 按主题
    case byTag = "byTag"               // 按标签
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .manual: return "手动选择"
        case .byMonth: return "按月份"
        case .byEmotion: return "按情绪"
        case .byTheme: return "按主题"
        case .byTag: return "按标签"
        }
    }
}

// MARK: - 梦境详情选项

/// 梦境详情显示选项
struct DreamDetailOptions: Codable, Equatable {
    var includeDate: Bool
    var includeEmotion: Bool
    var includeTags: Bool
    var includeAIAnalysis: Bool
    var includeMood: Bool
    var includeClarity: Bool
    var includeDuration: Bool
    var includeNotes: Bool
    
    init(
        includeDate: Bool = true,
        includeEmotion: Bool = true,
        includeTags: Bool = true,
        includeAIAnalysis: Bool = false,
        includeMood: Bool = true,
        includeClarity: Bool = false,
        includeDuration: Bool = false,
        includeNotes: Bool = true
    ) {
        self.includeDate = includeDate
        self.includeEmotion = includeEmotion
        self.includeTags = includeTags
        self.includeAIAnalysis = includeAIAnalysis
        self.includeMood = includeMood
        self.includeClarity = includeClarity
        self.includeDuration = includeDuration
        self.includeNotes = includeNotes
    }
}

// MARK: - 导出格式

/// 电子书导出格式
enum EBookExportFormat: String, Codable, CaseIterable, Identifiable {
    case pdf = "pdf"                   // PDF 格式
    case epub = "epub"                 // EPUB 格式
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .epub: return "EPUB"
        }
    }
    
    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .epub: return "application/epub+zip"
        }
    }
    
    var fileExtension: String { rawValue }
}

// MARK: - 导出状态

/// 电子书导出状态
enum EBookExportStatus: Equatable {
    case idle
    case preparing
    case generating(Int, Int)  // 当前进度，总进度
    case completing
    case success(URL)
    case failure(String)
}

// MARK: - 导出统计

/// 电子书导出统计信息
struct EBookExportStats {
    var totalDreams: Int
    var totalWords: Int
    var totalPages: Int
    var chapterCount: Int
    var dateRangeStart: Date
    var dateRangeEnd: Date
    var generatedAt: Date
    var fileSize: Int64
}

// MARK: - 预设模板

/// 电子书预设模板
struct EBookTemplate: Identifiable {
    var id: UUID
    var name: String
    var description: String
    var icon: String
    var config: EBookExportConfig
    
    static let templates: [EBookTemplate] = [
        EBookTemplate(
            id: UUID(),
            name: "经典日记",
            description: "传统日记风格，按时间顺序排列",
            icon: "📔",
            config: EBookExportConfig(
                title: "我的梦境日记",
                theme: .classic,
                dateRange: .all,
                tableOfContents: true,
                pageNumbering: true
            )
        ),
        EBookTemplate(
            id: UUID(),
            name: "月度精选",
            description: "按月份分章，回顾每月的梦境",
            icon: "📅",
            config: EBookExportConfig(
                title: "月度梦境集",
                theme: .elegant,
                dateRange: .last90Days,
                tableOfContents: true,
                pageNumbering: true
            )
        ),
        EBookTemplate(
            id: UUID(),
            name: "情绪之旅",
            description: "按情绪分类，探索情感变化",
            icon: "💭",
            config: EBookExportConfig(
                title: "情绪梦境集",
                theme: .dreamy,
                dateRange: .last90Days,
                tableOfContents: true,
                pageNumbering: true
            )
        ),
        EBookTemplate(
            id: UUID(),
            name: "年度回顾",
            description: "一整年的梦境精华",
            icon: "🎉",
            config: EBookExportConfig(
                title: "年度梦境回顾",
                theme: .luxury,
                dateRange: .thisYear,
                tableOfContents: true,
                pageNumbering: true
            )
        ),
        EBookTemplate(
            id: UUID(),
            name: "极简风格",
            description: "简洁设计，专注内容",
            icon: "✨",
            config: EBookExportConfig(
                title: "梦境集",
                theme: .minimalist,
                dateRange: .last30Days,
                tableOfContents: false,
                pageNumbering: false
            )
        )
    ]
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
