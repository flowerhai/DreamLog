//
//  DreamExportGalleryModels.swift
//  DreamLog - 梦境导出画廊数据模型
//
//  Phase 75: 梦境导出画廊
//  统一管理所有导出内容 (PDF/音频/视频/分享卡片)
//

import Foundation
import SwiftData

// MARK: - 导出类型枚举

/// 导出内容类型
@Model
public enum DreamExportType: String, CaseIterable, Codable {
    case pdf = "pdf"           // PDF 日记
    case audio = "audio"       // 音频播客
    case video = "video"       // 梦境视频
    case shareCard = "card"    // 分享卡片
    case arScene = "ar"        // AR 场景
    case story = "story"       // 梦境故事
    
    var displayName: String {
        switch self {
        case .pdf: return "📕 PDF 日记"
        case .audio: return "🎙️ 音频播客"
        case .video: return "🎬 梦境视频"
        case .shareCard: return "🎴 分享卡片"
        case .arScene: return "🥽 AR 场景"
        case .story: return "📖 梦境故事"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.fill"
        case .audio: return "waveform"
        case .video: return "film"
        case .shareCard: return "card.fill"
        case .arScene: return "glasses"
        case .story: return "book.fill"
        }
    }
}

// MARK: - 导出项模型

/// 导出内容项
@Model
public final class DreamExportItem {
    public var id: UUID
    public var type: DreamExportType
    public var title: String
    public var description: String
    public var filePath: String?          // 本地文件路径
    public var thumbnailPath: String?     // 缩略图路径
    public var shareURL: String?          // 分享链接
    public var shareCode: String?         // 分享码 (8 位)
    public var fileSize: Int64            // 文件大小 (字节)
    public var duration: TimeInterval?    // 时长 (音频/视频)
    public var dreamCount: Int            // 包含的梦境数量
    public var exportDate: Date
    public var lastSharedDate: Date?
    public var shareCount: Int
    public var viewCount: Int
    public var isFavorite: Bool
    public var tags: [String]
    public var metadata: [String: String] // 额外元数据
    
    public init(
        id: UUID = UUID(),
        type: DreamExportType,
        title: String,
        description: String = "",
        filePath: String? = nil,
        thumbnailPath: String? = nil,
        shareURL: String? = nil,
        shareCode: String? = nil,
        fileSize: Int64 = 0,
        duration: TimeInterval? = nil,
        dreamCount: Int = 0,
        exportDate: Date = Date(),
        lastSharedDate: Date? = nil,
        shareCount: Int = 0,
        viewCount: Int = 0,
        isFavorite: Bool = false,
        tags: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.shareURL = shareURL
        self.shareCode = shareCode
        self.fileSize = fileSize
        self.duration = duration
        self.dreamCount = dreamCount
        self.exportDate = exportDate
        self.lastSharedDate = lastSharedDate
        self.shareCount = shareCount
        self.viewCount = viewCount
        self.isFavorite = isFavorite
        self.tags = tags
        self.metadata = metadata
    }
    
    /// 格式化文件大小
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /// 格式化时长
    public var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
    
    /// 格式化导出日期
    public var formattedExportDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: exportDate)
    }
}

// MARK: - 导出统计模型

/// 导出统计信息
public struct DreamExportStats {
    public var totalExports: Int
    public var totalFileSize: Int64
    public var totalShareCount: Int
    public var totalViewCount: Int
    public var exportsByType: [DreamExportType: Int]
    public var recentExports: [DreamExportItem]
    public var favoriteExports: [DreamExportItem]
    public var mostSharedExport: DreamExportItem?
    public var storageUsage: String
    
    public init(
        totalExports: Int = 0,
        totalFileSize: Int64 = 0,
        totalShareCount: Int = 0,
        totalViewCount: Int = 0,
        exportsByType: [DreamExportType: Int] = [:],
        recentExports: [DreamExportItem] = [],
        favoriteExports: [DreamExportItem] = [],
        mostSharedExport: DreamExportItem? = nil,
        storageUsage: String = "0 MB"
    ) {
        self.totalExports = totalExports
        self.totalFileSize = totalFileSize
        self.totalShareCount = totalShareCount
        self.totalViewCount = totalViewCount
        self.exportsByType = exportsByType
        self.recentExports = recentExports
        self.favoriteExports = favoriteExports
        self.mostSharedExport = mostSharedExport
        self.storageUsage = storageUsage
    }
    
    /// 格式化总文件大小
    public static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - 导出筛选选项

/// 导出画廊筛选选项
public struct ExportGalleryFilter {
    public var type: DreamExportType?
    public var dateRange: DateRange
    public var isFavorite: Bool?
    public var sortBy: ExportSortOption
    public var searchText: String
    
    public enum DateRange {
        case all
        case today
        case thisWeek
        case thisMonth
        case thisYear
        case custom(start: Date, end: Date)
    }
    
    public enum ExportSortOption: String, CaseIterable {
        case dateDesc = "dateDesc"
        case dateAsc = "dateAsc"
        case sizeDesc = "sizeDesc"
        case sharesDesc = "sharesDesc"
        case viewsDesc = "viewsDesc"
        case titleAsc = "titleAsc"
        
        var displayName: String {
            switch self {
            case .dateDesc: return "最新导出"
            case .dateAsc: return "最早导出"
            case .sizeDesc: return "文件大小"
            case .sharesDesc: return "分享次数"
            case .viewsDesc: return "浏览次数"
            case .titleAsc: return "标题"
            }
        }
    }
    
    public init(
        type: DreamExportType? = nil,
        dateRange: DateRange = .all,
        isFavorite: Bool? = nil,
        sortBy: ExportSortOption = .dateDesc,
        searchText: String = ""
    ) {
        self.type = type
        self.dateRange = dateRange
        self.isFavorite = isFavorite
        self.sortBy = sortBy
        self.searchText = searchText
    }
}

// MARK: - 导出操作

/// 导出操作类型
public enum ExportAction {
    case share
    case delete
    case favorite
    case rename
    case exportToFile
    case viewDetails
    case reExport
}
