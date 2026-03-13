//
//  DreamExportHubModels.swift
//  DreamLog
//
//  Phase 31 - Dream Export Hub & Knowledge Base Integration
//  统一导出中心数据模型
//

import Foundation

// MARK: - 导出平台枚举

enum ExportPlatform: String, CaseIterable, Identifiable, Codable {
    case notion = "notion"
    case obsidian = "obsidian"
    case logseq = "logseq"
    case dayone = "dayone"
    case csv = "csv"
    case json = "json"
    case markdown = "markdown"
    case pdf = "pdf"
    case html = "html"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .notion: return "Notion"
        case .obsidian: return "Obsidian"
        case .logseq: return "Logseq"
        case .dayone: return "Day One"
        case .csv: return "CSV"
        case .json: return "JSON"
        case .markdown: return "Markdown"
        case .pdf: return "PDF"
        case .html: return "HTML"
        }
    }
    
    var icon: String {
        switch self {
        case .notion: return "📓"
        case .obsidian: return "🪨"
        case .logseq: return "📝"
        case .dayone: return "📖"
        case .csv: return "📊"
        case .json: return "📄"
        case .markdown: return "📝"
        case .pdf: return "📕"
        case .html: return "🌐"
        }
    }
    
    var description: String {
        switch self {
        case .notion: return "同步到 Notion 数据库"
        case .obsidian: return "导出到 Obsidian 知识库"
        case .logseq: return "导出到 Logseq 日记"
        case .dayone: return "导出到 Day One 日记"
        case .csv: return "导出为 CSV 表格"
        case .json: return "导出为 JSON 数据"
        case .markdown: return "导出为 Markdown 文件"
        case .pdf: return "导出为 PDF 文档"
        case .html: return "导出为 HTML 网页"
        }
    }
    
    var requiresConfig: Bool {
        [.notion, .obsidian, .logseq, .dayone].contains(self)
    }
}

// MARK: - 导出配置协议

protocol ExportPlatformConfig: Codable {
    var platform: ExportPlatform { get }
    var isEnabled: Bool { get set }
}

// MARK: - Notion 配置

struct NotionConfig: ExportPlatformConfig {
    var platform: ExportPlatform = .notion
    var isEnabled: Bool = false
    var apiKey: String = ""
    var databaseId: String = ""
    var syncAutomatically: Bool = false
    var syncFrequency: SyncFrequency = .daily
    
    enum SyncFrequency: String, Codable, CaseIterable {
        case manual = "manual"
        case daily = "daily"
        case weekly = "weekly"
        
        var displayName: String {
            switch self {
            case .manual: return "手动"
            case .daily: return "每天"
            case .weekly: return "每周"
            }
        }
    }
}

// MARK: - Obsidian 配置

struct ObsidianConfig: ExportPlatformConfig {
    var platform: ExportPlatform = .obsidian
    var isEnabled: Bool = false
    var vaultPath: String = ""
    var folderName: String = "Dreams"
    var templateFile: String? = nil
    var useBacklinks: Bool = true
    var useTags: Bool = true
    var includeAIAnalysis: Bool = true
}

// MARK: - Logseq 配置

struct LogseqConfig: ExportPlatformConfig {
    var platform: ExportPlatform = .logseq
    var isEnabled: Bool = false
    var graphPath: String = ""
    var journalFolder: String = "journals"
    var pagesFolder: String = "pages"
    var useJournalFormat: Bool = true
    var includeTags: Bool = true
    var includeProperties: Bool = true
    
    var defaultTags: [String] = ["dream", "dreamlog"]
}

// MARK: - Day One 配置

struct DayOneConfig: ExportPlatformConfig {
    var platform: ExportPlatform = .dayone
    var isEnabled: Bool = false
    var exportPath: String = ""
    var includePhotos: Bool = true
    var includeAudio: Bool = true
    var useDayOneFormat: Bool = true
    
    var defaultTags: [String] = ["dream", "dreamlog"]
}

// MARK: - 通用导出配置

struct ExportOptions: Codable {
    var includeContent: Bool = true
    var includeAIAnalysis: Bool = true
    var includeTags: Bool = true
    var includeEmotions: Bool = true
    var includeAudio: Bool = false
    var includeImages: Bool = false
    var dateRange: DateRange = .all
    var selectedDreamIds: [UUID] = []
    
    enum DateRange: Codable, CaseIterable {
        case all
        case last7Days
        case last30Days
        case last90Days
        case custom
        
        var displayName: String {
            switch self {
            case .all: return "全部梦境"
            case .last7Days: return "最近 7 天"
            case .last30Days: return "最近 30 天"
            case .last90Days: return "最近 90 天"
            case .custom: return "自定义范围"
            }
        }
    }
}

// MARK: - 导出结果

struct ExportResult {
    var success: Bool
    var platform: ExportPlatform
    var exportedCount: Int = 0
    var failedCount: Int = 0
    var outputPath: String? = nil
    var errorMessage: String? = nil
    var warnings: [String] = []
    var duration: TimeInterval = 0
    
    var summary: String {
        if success {
            return "✅ 成功导出 \(exportedCount) 条梦境到 \(platform.displayName)"
        } else {
            return "❌ 导出失败：\(errorMessage ?? "未知错误")"
        }
    }
}

// MARK: - 导出历史

struct ExportHistory: Identifiable, Codable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var platform: ExportPlatform
    var exportedCount: Int
    var options: ExportOptions
    var outputPath: String?
    var success: Bool
    var duration: TimeInterval
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: timestamp)
    }
    
    var fileSize: String? {
        guard let path = outputPath else { return nil }
        let url = URL(fileURLWithPath: path)
        guard let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - 导出模板

struct ExportTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var platform: ExportPlatform
    var templateContent: String
    var isDefault: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    static var defaultTemplates: [ExportTemplate] {
        [
            ExportTemplate(
                name: "简约风格",
                platform: .markdown,
                templateContent: """
                # {{title}}
                
                **日期**: {{date}}
                **标签**: {{tags}}
                
                {{content}}
                
                ---
                _由 DreamLog 导出_
                """,
                isDefault: true
            ),
            ExportTemplate(
                name: "详细分析",
                platform: .markdown,
                templateContent: """
                ---
                title: {{title}}
                date: {{date}}
                tags: {{tags}}
                emotions: {{emotions}}
                clarity: {{clarity}}
                intensity: {{intensity}}
                lucid: {{lucid}}
                ---
                
                # {{title}}
                
                ## 🌙 梦境内容
                
                {{content}}
                
                ## 📊 统计
                
                - **清晰度**: {{clarity}}/5
                - **强度**: {{intensity}}/5
                - **清醒梦**: {{lucid}}
                
                ## 🧠 AI 解析
                
                {{aiAnalysis}}
                
                ---
                _由 DreamLog 导出 | #梦境 #日记_
                """,
                isDefault: true
            ),
            ExportTemplate(
                name: "Obsidian 标准",
                platform: .obsidian,
                templateContent: """
                ---
                tags: [{{tags}}]
                emotions: [{{emotions}}]
                clarity: {{clarity}}
                intensity: {{intensity}}
                lucid: {{lucid}}
                date: {{date}}
                exported: {{exportDate}}
                ---
                
                # {{title}}
                
                ## 梦境内容
                
                {{content}}
                
                ## AI 解析
                
                {{aiAnalysis}}
                
                ## 相关链接
                
                {{backlinks}}
                
                ---
                _由 DreamLog 导出_
                """,
                isDefault: true
            )
        ]
    }
}

// MARK: - 导出统计

struct ExportStatistics {
    var totalExports: Int = 0
    var exportsByPlatform: [ExportPlatform: Int] = [:]
    var totalDreamsExported: Int = 0
    var lastExportDate: Date?
    var averageExportSize: Int64 = 0
    
    var mostUsedPlatform: ExportPlatform? {
        exportsByPlatform.max(by: { $0.value < $1.value })?.key
    }
}
