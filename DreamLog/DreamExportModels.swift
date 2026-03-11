//
//  DreamExportModels.swift
//  DreamLog
//
//  Phase 19 - Dream Data Export & Integration
//  Data models for export functionality
//

import Foundation

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    case markdown = "Markdown"
    case notion = "Notion"
    case obsidian = "Obsidian"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV (Spreadsheet)"
        case .markdown: return "Markdown"
        case .notion: return "Notion Database"
        case .obsidian: return "Obsidian Vault"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "doc.badge.gearshape"
        case .csv: return "tablecells"
        case .markdown: return "doc.text"
        case .notion: return "network"
        case .obsidian: return "folder"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        case .markdown, .obsidian: return "md"
        case .notion: return "csv" // Notion imports CSV
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        case .markdown, .obsidian: return "text/markdown"
        case .notion: return "text/csv"
        }
    }
}

// MARK: - Export Options

struct ExportOptions {
    var format: ExportFormat
    var dateRange: ExportDateRange
    var includeFields: ExportFields
    var sortOrder: ExportSortOrder
    
    init(
        format: ExportFormat = .json,
        dateRange: ExportDateRange = .all,
        includeFields: ExportFields = .all,
        sortOrder: ExportSortOrder = .dateDescending
    ) {
        self.format = format
        self.dateRange = dateRange
        self.includeFields = includeFields
        self.sortOrder = sortOrder
    }
}

enum ExportDateRange: String, CaseIterable, Identifiable {
    case all = "all"
    case lastWeek = "lastWeek"
    case lastMonth = "lastMonth"
    case last3Months = "last3Months"
    case lastYear = "lastYear"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "全部梦境"
        case .lastWeek: return "最近 7 天"
        case .lastMonth: return "最近 30 天"
        case .last3Months: return "最近 3 个月"
        case .lastYear: return "最近 1 年"
        case .custom: return "自定义范围"
        }
    }
    
    func dateRange() -> (start: Date, end: Date)? {
        let now = Date()
        switch self {
        case .all:
            return nil
        case .lastWeek:
            return (Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now, now)
        case .lastMonth:
            return (Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now, now)
        case .last3Months:
            return (Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now, now)
        case .lastYear:
            return (Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now, now)
        case .custom:
            return nil // Handled separately
        }
    }
}

struct ExportFields: OptionSet {
    let rawValue: Int
    
    static let title = ExportFields(rawValue: 1 << 0)
    static let content = ExportFields(rawValue: 1 << 1)
    static let tags = ExportFields(rawValue: 1 << 2)
    static let emotions = ExportFields(rawValue: 1 << 3)
    static let clarity = ExportFields(rawValue: 1 << 4)
    static let intensity = ExportFields(rawValue: 1 << 5)
    static let isLucid = ExportFields(rawValue: 1 << 6)
    static let aiAnalysis = ExportFields(rawValue: 1 << 7)
    static let date = ExportFields(rawValue: 1 << 8)
    
    static let all: ExportFields = [.title, .content, .tags, .emotions, .clarity, .intensity, .isLucid, .aiAnalysis, .date]
    static let minimal: ExportFields = [.title, .content, .date]
}

enum ExportSortOrder: String, CaseIterable, Identifiable {
    case dateDescending = "dateDescending"
    case dateAscending = "dateAscending"
    case clarityDescending = "clarityDescending"
    case intensityDescending = "intensityDescending"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .dateDescending: return "日期 (最新优先)"
        case .dateAscending: return "日期 (最早优先)"
        case .clarityDescending: return "清晰度 (高到低)"
        case .intensityDescending: return "强度 (高到低)"
        }
    }
}

// MARK: - Export Result

struct ExportResult {
    let success: Bool
    let fileURL: URL?
    let dreamCount: Int
    let fileSize: String
    let errorMessage: String?
    let exportedAt: Date
    
    init(
        success: Bool,
        fileURL: URL? = nil,
        dreamCount: Int = 0,
        fileSize: String = "0 KB",
        errorMessage: String? = nil,
        exportedAt: Date = Date()
    ) {
        self.success = success
        self.fileURL = fileURL
        self.dreamCount = dreamCount
        self.fileSize = fileSize
        self.errorMessage = errorMessage
        self.exportedAt = exportedAt
    }
}

// MARK: - Notion Integration

struct NotionConfig {
    var apiKey: String
    var databaseId: String
    var isEnabled: Bool
    
    init(apiKey: String = "", databaseId: String = "", isEnabled: Bool = false) {
        self.apiKey = apiKey
        self.databaseId = databaseId
        self.isEnabled = isEnabled
    }
}

struct NotionSyncResult {
    let success: Bool
    let syncedCount: Int
    let failedCount: Int
    let errorMessage: String?
    
    init(success: Bool, syncedCount: Int = 0, failedCount: Int = 0, errorMessage: String? = nil) {
        self.success = success
        self.syncedCount = syncedCount
        self.failedCount = failedCount
        self.errorMessage = errorMessage
    }
}

// MARK: - Obsidian Config

struct ObsidianConfig {
    var vaultPath: String
    var folderName: String
    var templateFile: String?
    var isEnabled: Bool
    
    init(vaultPath: String = "", folderName: String = "Dreams", templateFile: String? = nil, isEnabled: Bool = false) {
        self.vaultPath = vaultPath
        self.folderName = folderName
        self.templateFile = templateFile
        self.isEnabled = isEnabled
    }
}

struct ObsidianSyncResult {
    let success: Bool
    let exportedCount: Int
    let outputPath: String?
    let errorMessage: String?
    
    init(success: Bool, exportedCount: Int = 0, outputPath: String? = nil, errorMessage: String? = nil) {
        self.success = success
        self.exportedCount = exportedCount
        self.outputPath = outputPath
        self.errorMessage = errorMessage
    }
}

// MARK: - Export Statistics

struct ExportStatistics {
    let totalDreams: Int
    let dateRange: String
    let averageClarity: Double
    let averageIntensity: Double
    let lucidDreamPercentage: Double
    let topTags: [String]
    let dominantEmotions: [String]
    
    init(
        totalDreams: Int = 0,
        dateRange: String = "",
        averageClarity: Double = 0,
        averageIntensity: Double = 0,
        lucidDreamPercentage: Double = 0,
        topTags: [String] = [],
        dominantEmotions: [String] = []
    ) {
        self.totalDreams = totalDreams
        self.dateRange = dateRange
        self.averageClarity = averageClarity
        self.averageIntensity = averageIntensity
        self.lucidDreamPercentage = lucidDreamPercentage
        self.topTags = topTags
        self.dominantEmotions = dominantEmotions
    }
}
