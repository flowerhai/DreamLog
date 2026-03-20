//
//  DreamImportModels.swift
//  DreamLog - 梦境导入中心数据模型
//
//  Phase 34: 梦境导入中心 - 支持多格式导入
//  Created: 2026-03-13 20:04 UTC
//

import Foundation
import SwiftData

// MARK: - 导入源类型

/// 支持的导入源类型
enum ImportSourceType: String, Codable, CaseIterable, Identifiable {
    case json = "JSON"
    case csv = "CSV"
    case notion = "Notion"
    case obsidian = "Obsidian"
    case dreamJournal = "DreamJournal"
    case lucid = "Lucid"
    case other = "Other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .json: return "JSON 文件"
        case .csv: return "CSV 文件"
        case .notion: return "Notion 数据库"
        case .obsidian: return "Obsidian 笔记"
        case .dreamJournal: return "Dream Journal 应用"
        case .lucid: return "Lucid 应用"
        case .other: return "其他格式"
        }
    }
    
    var icon: String {
        switch self {
        case .json: return "doc.text"
        case .csv: return "tablecells"
        case .notion: return "cloud"
        case .obsidian: return "folder"
        case .dreamJournal: return "book"
        case .lucid: return "moon.stars"
        case .other: return "square.and.arrow.down"
        }
    }
    
    var supportedExtensions: [String] {
        switch self {
        case .json: return ["json"]
        case .csv: return ["csv"]
        case .notion: return ["csv", "json", "md"]
        case .obsidian: return ["md"]
        case .dreamJournal: return ["json", "xml"]
        case .lucid: return ["json", "csv"]
        case .other: return ["json", "csv", "md", "txt", "xml"]
        }
    }
}

// MARK: - 导入状态

/// 导入任务状态
enum ImportStatus: String, Codable {
    case pending = "pending"           // 等待导入
    case processing = "processing"     // 处理中
    case completed = "completed"       // 已完成
    case partial = "partial"           // 部分成功
    case failed = "failed"             // 失败
    case cancelled = "cancelled"       // 已取消
}

// MARK: - 导入结果

/// 单个梦境导入结果
struct DreamImportResult: Codable, Identifiable {
    let id: UUID
    let sourceId: String?               // 源数据 ID
    var dreamId: UUID?                  // 导入后的梦境 ID
    var status: ImportStatus
    var errorMessage: String?
    var isDuplicate: Bool               // 是否为重复梦境
    var mergedWithId: UUID?             // 如果合并了，合并到的梦境 ID
    var importedFields: [String]        // 成功导入的字段
    var skippedFields: [String]         // 跳过的字段
    
    init(
        id: UUID = UUID(),
        sourceId: String? = nil,
        dreamId: UUID? = nil,
        status: ImportStatus = .pending,
        errorMessage: String? = nil,
        isDuplicate: Bool = false,
        mergedWithId: UUID? = nil,
        importedFields: [String] = [],
        skippedFields: [String] = []
    ) {
        self.id = id
        self.sourceId = sourceId
        self.dreamId = dreamId
        self.status = status
        self.errorMessage = errorMessage
        self.isDuplicate = isDuplicate
        self.mergedWithId = mergedWithId
        self.importedFields = importedFields
        self.skippedFields = skippedFields
    }
}

// MARK: - 导入任务

/// 导入任务模型
@Model
final class DreamImportTask {
    var id: UUID
    var name: String                    // 任务名称
    var sourceType: ImportSourceType    // 导入源类型
    var sourceFile: String?             // 源文件路径
    var sourceUrl: String?              // 源 URL（网络导入）
    var status: ImportStatus
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var totalItems: Int                 // 总项目数
    var successCount: Int               // 成功数量
    var failureCount: Int               // 失败数量
    var duplicateCount: Int             // 重复数量
    var mergedCount: Int                // 合并数量
    var progress: Double                // 进度 0.0-1.0
    var errorMessage: String?
    var results: [DreamImportResult]    // 导入结果
    var settings: ImportSettings        // 导入设置
    
    init(
        id: UUID = UUID(),
        name: String,
        sourceType: ImportSourceType,
        sourceFile: String? = nil,
        sourceUrl: String? = nil,
        status: ImportStatus = .pending,
        totalItems: Int = 0,
        settings: ImportSettings = ImportSettings()
    ) {
        self.id = id
        self.name = name
        self.sourceType = sourceType
        self.sourceFile = sourceFile
        self.sourceUrl = sourceUrl
        self.status = status
        self.createdAt = Date()
        self.totalItems = totalItems
        self.successCount = 0
        self.failureCount = 0
        self.duplicateCount = 0
        self.mergedCount = 0
        self.progress = 0.0
        self.results = []
        self.settings = settings
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
    
    var isCompleted: Bool {
        status == .completed || status == .partial || status == .failed
    }
}

// MARK: - 导入设置

/// 导入配置选项
struct ImportSettings: Codable {
    var skipDuplicates: Bool            // 跳过重复梦境
    var mergeDuplicates: Bool           // 合并重复梦境
    var importTags: Bool                // 导入标签
    var importEmotions: Bool            // 导入情绪
    var importAudio: Bool               // 导入音频
    var importImages: Bool              // 导入图片
    var importLocation: Bool            // 导入位置
    var autoAnalyze: Bool               // 自动 AI 分析
    var defaultVisibility: DreamVisibility // 默认可见性
    var dateFormat: String              // 日期格式
    var timezone: String                // 时区
    
    init(
        skipDuplicates: Bool = true,
        mergeDuplicates: Bool = false,
        importTags: Bool = true,
        importEmotions: Bool = true,
        importAudio: Bool = true,
        importImages: Bool = true,
        importLocation: Bool = true,
        autoAnalyze: Bool = false,
        defaultVisibility: DreamVisibility = .private,
        dateFormat: String = "yyyy-MM-dd HH:mm:ss",
        timezone: String = TimeZone.current.identifier
    ) {
        self.skipDuplicates = skipDuplicates
        self.mergeDuplicates = mergeDuplicates
        self.importTags = importTags
        self.importEmotions = importEmotions
        self.importAudio = importAudio
        self.importImages = importImages
        self.importLocation = importLocation
        self.autoAnalyze = autoAnalyze
        self.defaultVisibility = defaultVisibility
        self.dateFormat = dateFormat
        self.timezone = timezone
    }
}

// MARK: - 导入数据格式

/// 通用梦境导入数据格式
struct ImportDreamData: Codable {
    var id: String?                     // 源 ID
    var title: String?                  // 标题
    var content: String                 // 梦境内容
    var date: Date                      // 梦境日期
    var createdAt: Date?                // 创建时间
    var updatedAt: Date?                // 更新时间
    var tags: [String]?                 // 标签
    var emotions: [String]?             // 情绪
    var mood: String?                   // 心情
    var clarity: Double?                // 清晰度 0-1
    var isLucid: Bool?                  // 是否清醒梦
    var location: LocationData?         // 位置
    var audioUrl: String?               // 音频 URL
    var imageUrls: [String]?            // 图片 URLs
    var metadata: [String: AnyCodable]? // 元数据
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, date, createdAt, updatedAt
        case tags, emotions, mood, clarity, isLucid, location
        case audioUrl, imageUrls, metadata
    }
    
    init(
        id: String? = nil,
        title: String? = nil,
        content: String,
        date: Date = Date(),
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        tags: [String]? = nil,
        emotions: [String]? = nil,
        mood: String? = nil,
        clarity: Double? = nil,
        isLucid: Bool? = nil,
        location: LocationData? = nil,
        audioUrl: String? = nil,
        imageUrls: [String]? = nil,
        metadata: [String: AnyCodable]? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.emotions = emotions
        self.mood = mood
        self.clarity = clarity
        self.isLucid = isLucid
        self.location = location
        self.audioUrl = audioUrl
        self.imageUrls = imageUrls
        self.metadata = metadata
    }
}

// MARK: - 辅助类型

// Note: AnyCodable is defined in Sources/DreamRecommendationModels.swift

/// 位置数据
struct LocationData: Codable {
    var latitude: Double
    var longitude: Double
    var name: String?
    var city: String?
    var country: String?
    
    init(latitude: Double, longitude: Double, name: String? = nil, city: String? = nil, country: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.city = city
        self.country = country
    }
}

// MARK: - 导入预览

/// 导入预览数据
struct ImportPreview: Identifiable {
    let id: UUID
    var sourceType: ImportSourceType
    var fileName: String
    var itemCount: Int
    var estimatedSize: String
    var sampleItems: [ImportDreamData]
    var potentialIssues: [ImportIssue]
    
    init(
        id: UUID = UUID(),
        sourceType: ImportSourceType,
        fileName: String,
        itemCount: Int,
        estimatedSize: String,
        sampleItems: [ImportDreamData] = [],
        potentialIssues: [ImportIssue] = []
    ) {
        self.id = id
        self.sourceType = sourceType
        self.fileName = fileName
        self.itemCount = itemCount
        self.estimatedSize = estimatedSize
        self.sampleItems = sampleItems
        self.potentialIssues = potentialIssues
    }
}

/// 导入潜在问题
struct ImportIssue: Identifiable {
    let id: UUID
    var type: ImportIssueType
    var message: String
    var severity: ImportIssueSeverity
    var affectedItems: Int
    
    init(
        id: UUID = UUID(),
        type: ImportIssueType,
        message: String,
        severity: ImportIssueSeverity,
        affectedItems: Int = 0
    ) {
        self.id = id
        self.type = type
        self.message = message
        self.severity = severity
        self.affectedItems = affectedItems
    }
}

enum ImportIssueType: String, Codable {
    case missingDate = "missingDate"
    case missingContent = "missingContent"
    case invalidFormat = "invalidFormat"
    case duplicateDetected = "duplicateDetected"
    case encodingIssue = "encodingIssue"
    case largeFile = "largeFile"
    case unsupportedField = "unsupportedField"
}

enum ImportIssueSeverity: String, Codable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        case .critical: return "purple"
        }
    }
}
