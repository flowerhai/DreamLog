//
//  DreamExportHubModels.swift
//  DreamLog
//
//  Phase 52 - 梦境导出中心
//  创建时间：2026-03-16
//

import Foundation
import SwiftData

// MARK: - 导出目标平台

/// 支持导出的目标平台
enum ExportPlatform: String, Codable, CaseIterable, Identifiable {
    case notion = "notion"
    case obsidian = "obsidian"
    case dayOne = "dayOne"
    case evernote = "evernote"
    case bear = "bear"
    case appleNotes = "appleNotes"
    case markdown = "markdown"
    case pdf = "pdf"
    case json = "json"
    case email = "email"
    case wechat = "wechat"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .notion: return "Notion"
        case .obsidian: return "Obsidian"
        case .dayOne: return "Day One"
        case .evernote: return "印象笔记"
        case .bear: return "Bear"
        case .appleNotes: return "苹果备忘录"
        case .markdown: return "Markdown"
        case .pdf: return "PDF"
        case .json: return "JSON"
        case .email: return "电子邮件"
        case .wechat: return "微信"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .notion: return "📓"
        case .obsidian: return "🪨"
        case .dayOne: return "📔"
        case .evernote: return "🐘"
        case .bear: return "🐻"
        case .appleNotes: return "📝"
        case .markdown: return "📄"
        case .pdf: return "📕"
        case .json: return "📋"
        case .email: return "📧"
        case .wechat: return "💬"
        case .custom: return "⚙️"
        }
    }
    
    var description: String {
        switch self {
        case .notion: return "导出到 Notion 数据库，支持双向同步"
        case .obsidian: return "导出为 Markdown 文件，支持双向链接"
        case .dayOne: return "导出到 Day One 日记应用"
        case .evernote: return "导出到印象笔记，支持标签同步"
        case .bear: return "导出到 Bear 笔记，支持标签"
        case .appleNotes: return "导出到苹果备忘录"
        case .markdown: return "导出为 Markdown 文件"
        case .pdf: return "导出为精美 PDF 文档"
        case .json: return "导出为 JSON 数据格式"
        case .email: return "通过邮件发送梦境"
        case .wechat: return "分享到微信"
        case .custom: return "自定义导出格式和路径"
        }
    }
    
    var supportsBatch: Bool {
        switch self {
        case .notion, .obsidian, .markdown, .pdf, .json, .email:
            return true
        default:
            return false
        }
    }
    
    var supportsScheduled: Bool {
        switch self {
        case .notion, .obsidian, .email, .custom:
            return true
        default:
            return false
        }
    }
}

// MARK: - 导出格式

/// 导出文件格式
enum ExportFormat: String, Codable, CaseIterable {
    case markdown = "markdown"
    case html = "html"
    case pdf = "pdf"
    case json = "json"
    case plainText = "plainText"
    case richText = "richText"
    
    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .html: return "HTML"
        case .pdf: return "PDF"
        case .json: return "JSON"
        case .plainText: return "纯文本"
        case .richText: return "富文本"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .markdown: return "md"
        case .html: return "html"
        case .pdf: return "pdf"
        case .json: return "json"
        case .plainText: return "txt"
        case .richText: return "rtf"
        }
    }
}

// MARK: - 导出配置

/// 导出配置选项
struct ExportOptions: Codable {
    var includeTitle: Bool = true
    var includeDate: Bool = true
    var includeTime: Bool = false
    var includeEmotions: Bool = true
    var includeTags: Bool = true
    var includeAIAnalysis: Bool = true
    var includeImages: Bool = true
    var includeAudio: Bool = false
    var includeLucidInfo: Bool = true
    var includeRating: Bool = true
    var dateFormat: String = "yyyy-MM-dd HH:mm"
    var template: String? = nil
    var customFields: [String: String] = [:]
    
    static var `default`: ExportOptions {
        ExportOptions()
    }
    
    static var minimal: ExportOptions {
        ExportOptions(
            includeTitle: true,
            includeDate: true,
            includeTime: false,
            includeEmotions: false,
            includeTags: false,
            includeAIAnalysis: false,
            includeImages: false,
            includeAudio: false,
            includeLucidInfo: false,
            includeRating: false
        )
    }
    
    static var detailed: ExportOptions {
        ExportOptions(
            includeTitle: true,
            includeDate: true,
            includeTime: true,
            includeEmotions: true,
            includeTags: true,
            includeAIAnalysis: true,
            includeImages: true,
            includeAudio: true,
            includeLucidInfo: true,
            includeRating: true
        )
    }
}

// MARK: - 导出任务模型

/// 导出任务
@Model
final class ExportTask {
    @Attribute(.unique) var id: UUID
    var name: String
    var platform: String
    var format: String
    var dreamIds: [UUID]
    var exportAll: Bool
    var dateRange: DateRange?
    var options: Data  // ExportOptions encoded
    var status: String
    var scheduledTime: Date?
    var repeatInterval: String?  // "daily", "weekly", "monthly"
    var lastExportTime: Date?
    var nextExportTime: Date?
    var exportCount: Int
    var destinationPath: String?
    var apiKey: String?  // For platforms like Notion
    var webhookUrl: String?
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        platform: ExportPlatform,
        format: ExportFormat = .markdown,
        dreamIds: [UUID] = [],
        exportAll: Bool = false,
        dateRange: DateRange? = nil,
        options: ExportOptions = .default,
        status: ExportStatus = .pending,
        scheduledTime: Date? = nil,
        repeatInterval: String? = nil,
        lastExportTime: Date? = nil,
        nextExportTime: Date? = nil,
        exportCount: Int = 0,
        destinationPath: String? = nil,
        apiKey: String? = nil,
        webhookUrl: String? = nil,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.platform = platform.rawValue
        self.format = format.rawValue
        self.dreamIds = dreamIds
        self.exportAll = exportAll
        self.dateRange = dateRange
        self.options = try? JSONEncoder().encode(options)
        self.status = status.rawValue
        self.scheduledTime = scheduledTime
        self.repeatInterval = repeatInterval
        self.lastExportTime = lastExportTime
        self.nextExportTime = nextExportTime
        self.exportCount = exportCount
        self.destinationPath = destinationPath
        self.apiKey = apiKey
        self.webhookUrl = webhookUrl
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var platformEnum: ExportPlatform {
        ExportPlatform(rawValue: platform) ?? .markdown
    }
    
    var formatEnum: ExportFormat {
        ExportFormat(rawValue: format) ?? .markdown
    }
    
    var statusEnum: ExportStatus {
        ExportStatus(rawValue: status) ?? .pending
    }
    
    var exportOptions: ExportOptions {
        guard let data = options,
              let decoded = try? JSONDecoder().decode(ExportOptions.self, from: data) else {
            return .default
        }
        return decoded
    }
}

// MARK: - 导出历史记录

/// 导出历史记录
@Model
final class ExportHistory {
    @Attribute(.unique) var id: UUID
    var taskId: UUID?
    var platform: String
    var format: String
    var dreamCount: Int
    var fileSize: Int64
    var filePath: String?
    var status: String
    var errorMessage: String?
    var duration: TimeInterval
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        taskId: UUID? = nil,
        platform: ExportPlatform,
        format: ExportFormat,
        dreamCount: Int,
        fileSize: Int64 = 0,
        filePath: String? = nil,
        status: ExportStatus = .pending,
        errorMessage: String? = nil,
        duration: TimeInterval = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.taskId = taskId
        self.platform = platform.rawValue
        self.format = format.rawValue
        self.dreamCount = dreamCount
        self.fileSize = fileSize
        self.filePath = filePath
        self.status = status.rawValue
        self.errorMessage = errorMessage
        self.duration = duration
        self.createdAt = createdAt
    }
    
    var platformEnum: ExportPlatform {
        ExportPlatform(rawValue: platform) ?? .markdown
    }
    
    var formatEnum: ExportFormat {
        ExportFormat(rawValue: format) ?? .markdown
    }
    
    var statusEnum: ExportStatus {
        ExportStatus(rawValue: status) ?? .pending
    }
}

// MARK: - 导出状态

/// 导出任务状态
enum ExportStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case scheduled = "scheduled"
    
    var displayName: String {
        switch self {
        case .pending: return "等待中"
        case .processing: return "处理中"
        case .completed: return "已完成"
        case .failed: return "失败"
        case .cancelled: return "已取消"
        case .scheduled: return "已计划"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "⏳"
        case .processing: return "⚙️"
        case .completed: return "✅"
        case .failed: return "❌"
        case .cancelled: return "🚫"
        case .scheduled: return "📅"
        }
    }
}

// MARK: - 日期范围

/// 日期范围
struct DateRange: Codable {
    var startDate: Date
    var endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    static var thisWeek: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
        return DateRange(startDate: startOfWeek, endDate: endOfWeek)
    }
    
    static var thisMonth: DateRange {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .day, value: -1, to: calendar.date(byAdding: .month, value: 1, to: startOfMonth)!)!
        return DateRange(startDate: startOfMonth, endDate: endOfMonth)
    }
    
    static var last30Days: DateRange {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        return DateRange(startDate: thirtyDaysAgo, endDate: now)
    }
}

// MARK: - 导出统计

/// 导出统计数据
struct ExportStats {
    var totalExports: Int
    var totalDreamsExported: Int
    var totalDataSize: Int64
    var exportsByPlatform: [String: Int]
    var exportsByFormat: [String: Int]
    var lastExportDate: Date?
    var averageExportSize: Double {
        guard totalExports > 0 else { return 0 }
        return Double(totalDataSize) / Double(totalExports)
    }
}

// MARK: - 预设模板

extension ExportOptions {
    /// Notion 导出模板
    static var notionTemplate: ExportOptions {
        ExportOptions(
            includeTitle: true,
            includeDate: true,
            includeTime: true,
            includeEmotions: true,
            includeTags: true,
            includeAIAnalysis: true,
            includeImages: true,
            includeAudio: false,
            includeLucidInfo: true,
            includeRating: true,
            dateFormat: "yyyy-MM-dd HH:mm"
        )
    }
    
    /// Obsidian 导出模板
    static var obsidianTemplate: ExportOptions {
        ExportOptions(
            includeTitle: true,
            includeDate: true,
            includeTime: false,
            includeEmotions: true,
            includeTags: true,
            includeAIAnalysis: true,
            includeImages: false,
            includeAudio: false,
            includeLucidInfo: true,
            includeRating: false,
            dateFormat: "yyyy-MM-dd"
        )
    }
    
    /// PDF 导出模板
    static var pdfTemplate: ExportOptions {
        ExportOptions.detailed
    }
    
    /// 分享模板（微信/邮件）
    static var shareTemplate: ExportOptions {
        ExportOptions(
            includeTitle: true,
            includeDate: true,
            includeTime: false,
            includeEmotions: true,
            includeTags: true,
            includeAIAnalysis: false,
            includeImages: true,
            includeAudio: false,
            includeLucidInfo: false,
            includeRating: false,
            dateFormat: "MM/dd"
        )
    }
}

// MARK: - 导出队列统计

/// 导出队列统计数据
struct ExportQueueStats {
    let pending: Int
    let processing: Int
    let scheduled: Int
    let paused: Int
    let completed: Int
    let failed: Int
    let cancelled: Int
    let total: Int
    
    /// 活跃任务数（待处理 + 处理中）
    var activeTasks: Int {
        pending + processing
    }
    
    /// 是否有正在处理的任务
    var hasProcessingTasks: Bool {
        processing > 0
    }
    
    /// 是否有待处理的任务
    var hasPendingTasks: Bool {
        pending > 0
    }
}
