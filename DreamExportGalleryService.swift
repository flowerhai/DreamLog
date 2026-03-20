//
//  DreamExportGalleryService.swift
//  DreamLog - 梦境导出画廊核心服务
//
//  Phase 75: 梦境导出画廊
//  统一管理所有导出内容 (PDF/音频/视频/分享卡片)
//

import Foundation
import SwiftData

@ModelActor
public actor DreamExportGalleryService {
    
    // MARK: - 属性
    
    public let modelContext: ModelContext
    public let fileManager: FileManager
    
    /// 导出目录路径
    public var exportDirectory: String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Exports").path
    }
    
    /// 缩略图目录路径
    public var thumbnailDirectory: String {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("Thumbnails").path
    }
    
    // MARK: - 初始化
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.fileManager = FileManager.default
        ensureDirectoriesExist()
    }
    
    // MARK: - 目录管理
    
    /// 确保导出目录存在
    private func ensureDirectoriesExist() {
        try? fileManager.createDirectory(atPath: exportDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(atPath: thumbnailDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - CRUD 操作
    
    /// 创建导出项
    public func createExport(_ item: DreamExportItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    
    /// 获取所有导出项
    public func getAllExports(filter: ExportGalleryFilter = ExportGalleryFilter()) -> [DreamExportItem] {
        let descriptor = FetchDescriptor<DreamExportItem>()
        
        guard let allExports = try? modelContext.fetch(descriptor) else {
            return []
        }
        
        var filtered = allExports
        
        // 按类型筛选
        if let type = filter.type {
            filtered = filtered.filter { $0.type == type }
        }
        
        // 按日期范围筛选
        filtered = filterByDateRange(filtered, range: filter.dateRange)
        
        // 按收藏筛选
        if let isFavorite = filter.isFavorite {
            filtered = filtered.filter { $0.isFavorite == isFavorite }
        }
        
        // 按搜索文本筛选
        if !filter.searchText.isEmpty {
            let searchLower = filter.searchText.lowercased()
            filtered = filtered.filter {
                $0.title.lowercased().contains(searchLower) ||
                $0.description.lowercased().contains(searchLower) ||
                $0.tags.contains { $0.lowercased().contains(searchLower) }
            }
        }
        
        // 排序
        filtered.sort { item1, item2 in
            switch filter.sortBy {
            case .dateDesc:
                return item1.exportDate > item2.exportDate
            case .dateAsc:
                return item1.exportDate < item2.exportDate
            case .sizeDesc:
                return item1.fileSize > item2.fileSize
            case .sharesDesc:
                return item1.shareCount > item2.shareCount
            case .viewsDesc:
                return item1.viewCount > item2.viewCount
            case .titleAsc:
                return item1.title < item2.title
            }
        }
        
        return filtered
    }
    
    /// 按日期范围筛选
    private func filterByDateRange(_ items: [DreamExportItem], range: ExportGalleryFilter.DateRange) -> [DreamExportItem] {
        let now = Date()
        let calendar = Calendar.current
        
        switch range {
        case .all:
            return items
        case .today:
            return items.filter { calendar.isDateInToday($0.exportDate) }
        case .thisWeek:
            return items.filter { calendar.isDate($0.exportDate, equalTo: now, toGranularity: .weekOfYear) }
        case .thisMonth:
            return items.filter { calendar.isDate($0.exportDate, equalTo: now, toGranularity: .month) }
        case .thisYear:
            return items.filter { calendar.isDate($0.exportDate, equalTo: now, toGranularity: .year) }
        case .custom(let start, let end):
            return items.filter { $0.exportDate >= start && $0.exportDate <= end }
        }
    }
    
    /// 更新导出项
    public func updateExport(_ item: DreamExportItem) throws {
        try modelContext.save()
    }
    
    /// 删除导出项
    public func deleteExport(_ item: DreamExportItem) throws {
        // 删除文件
        if let filePath = item.filePath {
            try? fileManager.removeItem(atPath: filePath)
        }
        if let thumbnailPath = item.thumbnailPath {
            try? fileManager.removeItem(atPath: thumbnailPath)
        }
        
        modelContext.delete(item)
        try modelContext.save()
    }
    
    /// 批量删除导出项
    public func deleteExports(_ items: [DreamExportItem]) throws {
        for item in items {
            try deleteExport(item)
        }
    }
    
    /// 切换收藏状态
    public func toggleFavorite(_ item: DreamExportItem) throws {
        item.isFavorite.toggle()
        try modelContext.save()
    }
    
    /// 增加分享次数
    public func incrementShareCount(_ item: DreamExportItem) throws {
        item.shareCount += 1
        item.lastSharedDate = Date()
        try modelContext.save()
    }
    
    /// 增加浏览次数
    public func incrementViewCount(_ item: DreamExportItem) throws {
        item.viewCount += 1
        try modelContext.save()
    }
    
    // MARK: - 统计
    
    /// 获取导出统计
    public func getExportStats() -> DreamExportStats {
        let allExports = getAllExports()
        
        let totalExports = allExports.count
        let totalFileSize = allExports.reduce(0) { $0 + $1.fileSize }
        let totalShareCount = allExports.reduce(0) { $0 + $1.shareCount }
        let totalViewCount = allExports.reduce(0) { $0 + $1.viewCount }
        
        // 按类型统计
        var exportsByType: [DreamExportType: Int] = [:]
        for type in DreamExportType.allCases {
            exportsByType[type] = allExports.filter { $0.type == type }.count
        }
        
        // 最近导出 (最近 7 天)
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentExports = allExports
            .filter { $0.exportDate >= weekAgo }
            .sorted { $0.exportDate > $1.exportDate }
            .prefix(5)
            .map { $0 }
        
        // 收藏的导出
        let favoriteExports = allExports.filter { $0.isFavorite }
        
        // 最多分享的导出
        let mostSharedExport = allExports.max { $0.shareCount < $1.shareCount }
        
        return DreamExportStats(
            totalExports: totalExports,
            totalFileSize: totalFileSize,
            totalShareCount: totalShareCount,
            totalViewCount: totalViewCount,
            exportsByType: exportsByType,
            recentExports: recentExports,
            favoriteExports: favoriteExports,
            mostSharedExport: mostSharedExport,
            storageUsage: DreamExportStats.formatBytes(totalFileSize)
        )
    }
    
    // MARK: - 文件管理
    
    /// 保存导出文件
    public func saveExportFile(data: Data, fileName: String, type: DreamExportType) throws -> String {
        let directory = exportDirectory + "/\(type.rawValue)"
        try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true)
        
        let filePath = directory + "/\(fileName)"
        try data.write(to: URL(fileURLWithPath: filePath))
        
        return filePath
    }
    
    /// 保存缩略图
    public func saveThumbnail(data: Data, fileName: String) throws -> String {
        let filePath = thumbnailDirectory + "/\(fileName)"
        try data.write(to: URL(fileURLWithPath: filePath))
        return filePath
    }
    
    /// 检查文件是否存在
    public func fileExists(atPath: String) -> Bool {
        return fileManager.fileExists(atPath: atPath)
    }
    
    /// 获取文件大小
    public func getFileSize(atPath: String) -> Int64? {
        guard let attributes = try? fileManager.attributesOfItem(atPath: atPath) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    /// 清理过期文件
    public func cleanupExpiredFiles(olderThan days: Int = 30) throws {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<DreamExportItem>()
        let allExports = try modelContext.fetch(descriptor)
        
        for item in allExports {
            if item.exportDate < cutoffDate && !item.isFavorite {
                try deleteExport(item)
            }
        }
    }
    
    /// 获取导出目录总大小
    public func getExportDirectorySize() -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(atPath: exportDirectory) {
            while let file = enumerator.nextObject() as? String {
                let filePath = exportDirectory + "/" + file
                if let size = getFileSize(atPath: filePath) {
                    totalSize += size
                }
            }
        }
        
        return totalSize
    }
    
    // MARK: - 导出建议
    
    /// 获取导出建议
    public func getExportSuggestions() -> [ExportSuggestion] {
        var suggestions: [ExportSuggestion] = []
        
        let stats = getExportStats()
        
        // 如果从未导出过
        if stats.totalExports == 0 {
            suggestions.append(ExportSuggestion(
                type: .firstExport,
                title: "创建第一个导出",
                description: "尝试将你的梦境导出为 PDF 或音频，随时回顾",
                icon: "doc.badge.plus"
            ))
        }
        
        // 如果有很多梦境但导出很少
        if stats.totalExports < 5 {
            suggestions.append(ExportSuggestion(
                type: .moreExports,
                title: "探索更多导出选项",
                description: "试试导出梦境视频或分享卡片，与朋友分享你的梦境",
                icon: "sparkles"
            ))
        }
        
        // 如果存储空间使用过多
        if stats.totalFileSize > 500 * 1024 * 1024 { // 500MB
            suggestions.append(ExportSuggestion(
                type: .cleanup,
                title: "清理旧导出",
                description: "你的导出文件已占用 \(DreamExportStats.formatBytes(stats.totalFileSize))，考虑清理不需要的文件",
                icon: "trash"
            ))
        }
        
        // 如果有收藏的导出
        if !stats.favoriteExports.isEmpty {
            suggestions.append(ExportSuggestion(
                type: .reviewFavorites,
                title: "回顾收藏的导出",
                description: "你有 \(stats.favoriteExports.count) 个收藏的导出，随时可以查看",
                icon: "heart.fill"
            ))
        }
        
        return suggestions
    }
}

// MARK: - 导出建议模型

/// 导出建议
public struct ExportSuggestion {
    public var type: SuggestionType
    public var title: String
    public var description: String
    public var icon: String
    
    public enum SuggestionType {
        case firstExport
        case moreExports
        case cleanup
        case reviewFavorites
        case shareMore
        case tryNewFormat
    }
}

// MARK: - 错误类型

public enum ExportGalleryError: LocalizedError {
    case fileNotFound
    case invalidFormat
    case storageFull
    case exportFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件未找到"
        case .invalidFormat:
            return "文件格式无效"
        case .storageFull:
            return "存储空间不足"
        case .exportFailed(let reason):
            return "导出失败：\(reason)"
        }
    }
}
