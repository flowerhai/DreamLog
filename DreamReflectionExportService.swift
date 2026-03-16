//
//  DreamReflectionExportService.swift
//  DreamLog
//
//  Phase 50: 梦境反思导出服务
//  支持 PDF/Markdown/JSON 格式导出反思日记
//

import Foundation
import SwiftData

// MARK: - 导出配置

/// 反思导出配置
struct ReflectionExportConfig: Codable {
    var format: ExportFormat
    var dateRange: DateRange
    var reflectionTypes: [ReflectionType]
    var includePrivate: Bool
    var includeActionItems: Bool
    var includeTags: Bool
    var sortBy: SortOption
    var sortOrder: SortOrder
    
    enum ExportFormat: String, CaseIterable, Codable {
        case pdf = "PDF 日记"
        case markdown = "Markdown"
        case json = "JSON"
        
        var fileExtension: String {
            switch self {
            case .pdf: return "pdf"
            case .markdown: return "md"
            case .json: return "json"
            }
        }
    }
    
    enum DateRange: String, CaseIterable, Codable {
        case all = "全部"
        case last7Days = "最近 7 天"
        case last30Days = "最近 30 天"
        case last3Months = "最近 3 个月"
        case lastYear = "最近 1 年"
        case custom = "自定义"
        
        var displayName: String { rawValue }
    }
    
    enum SortOption: String, CaseIterable, Codable {
        case date = "日期"
        case rating = "重要性"
        case type = "类型"
        
        var displayName: String { rawValue }
    }
    
    enum SortOrder: String, CaseIterable, Codable {
        case ascending = "升序"
        case descending = "降序"
        
        var displayName: String { rawValue }
    }
    
    static var `default`: ReflectionExportConfig {
        ReflectionExportConfig(
            format: .pdf,
            dateRange: .all,
            reflectionTypes: ReflectionType.allCases,
            includePrivate: true,
            includeActionItems: true,
            includeTags: true,
            sortBy: .date,
            sortOrder: .descending
        )
    }
}

// MARK: - 导出服务

/// 反思导出服务
@MainActor
class ReflectionExportService {
    
    static let shared = ReflectionExportService()
    
    private let modelContext: ModelContext
    private let fileManager: FileManager
    
    init(modelContext: ModelContext? = nil) {
        if let context = modelContext {
            self.modelContext = context
        } else if let container = SharedModelContainer.main,
                  let context = try? ModelContext(container) {
            self.modelContext = context
        } else {
            // Fallback to in-memory context for previews/tests
            let container = try? ModelContainer(for: DreamReflection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            self.modelContext = ModelContext(container ?? try! ModelContainer(for: DreamReflection.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        }
        self.fileManager = FileManager.default
    }
    
    // MARK: - 导出主方法
    
    /// 导出反思日记
    func exportReflections(config: ReflectionExportConfig) async throws -> URL {
        let reflections = fetchReflections(config: config)
        
        switch config.format {
        case .pdf:
            return try await exportToPDF(reflections: reflections, config: config)
        case .markdown:
            return try exportToMarkdown(reflections: reflections, config: config)
        case .json:
            return try exportToJSON(reflections: reflections, config: config)
        }
    }
    
    // MARK: - 数据获取
    
    /// 获取反思列表
    func fetchReflections(config: ReflectionExportConfig) -> [DreamReflection] {
        var descriptor = FetchDescriptor<DreamReflection>()
        
        // 日期范围过滤
        if config.dateRange != .all {
            let endDate = Date()
            let startDate: Date
            switch config.dateRange {
            case .last7Days: startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
            case .last30Days: startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            case .last3Months: startDate = Calendar.current.date(byAdding: .month, value: -3, to: endDate) ?? endDate
            case .lastYear: startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
            case .all, .custom: startDate = Date.distantPast
            }
            descriptor.predicate = #Predicate<DreamReflection> { reflection in
                reflection.createdAt >= startDate && reflection.createdAt <= endDate
            }
        }
        
        // 隐私过滤
        if !config.includePrivate {
            let existingPredicate = descriptor.predicate
            descriptor.predicate = #Predicate<DreamReflection> { reflection in
                !reflection.isPrivate && (existingPredicate?.evaluate(reflection) ?? true)
            }
        }
        
        // 类型过滤
        if config.reflectionTypes.count < ReflectionType.allCases.count {
            let typeRawValues = config.reflectionTypes.map { $0.rawValue }
            let existingPredicate = descriptor.predicate
            descriptor.predicate = #Predicate<DreamReflection> { reflection in
                typeRawValues.contains(reflection.type) && (existingPredicate?.evaluate(reflection) ?? true)
            }
        }
        
        // 排序
        descriptor.sortBy = switch config.sortBy {
        case .date:
            switch config.sortOrder {
            case .ascending: [SortDescriptor(\.createdAt, order: .forward)]
            case .descending: [SortDescriptor(\.createdAt, order: .reverse)]
            }
        case .rating:
            switch config.sortOrder {
            case .ascending: [SortDescriptor(\.rating, order: .forward)]
            case .descending: [SortDescriptor(\.rating, order: .reverse)]
            }
        case .type:
            switch config.sortOrder {
            case .ascending: [SortDescriptor(\.type, order: .forward)]
            case .descending: [SortDescriptor(\.type, order: .reverse)]
            }
        }
        
        return try? modelContext.fetch(descriptor) ?? []
    }
    
    // MARK: - PDF 导出
    
    /// 导出为 PDF
    private func exportToPDF(reflections: [DreamReflection], config: ReflectionExportConfig) async throws -> URL {
        let outputDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReflectionExports")
        try? fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let filename = "梦境反思日记_\(Date().formatted(.dateTime.year().month().day()))"
        let outputURL = outputDir.appendingPathComponent("\(filename).pdf")
        
        // 使用 UIGraphicsPDFRenderer 生成 PDF (iOS 11+)
        // 注意：此方法需要在 iOS 环境中运行
        let pdfData = generatePDFData(reflections: reflections, config: config)
        try pdfData.write(to: outputURL)
        
        return outputURL
    }
    
    /// 生成 PDF 数据
    private func generatePDFData(reflections: [DreamReflection], config: ReflectionExportConfig) -> Data {
        // 在 iOS 环境中使用 UIGraphicsPDFRenderer
        // 这里提供核心渲染逻辑，实际渲染在 iOS 端完成
        
        var pdfContent = ""
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        
        // PDF 封面
        pdfContent += """
        # 梦境反思日记
        
        导出日期：\(Date().formatted(.dateTime.year().month().day()))
        共 **\(reflections.count)** 篇反思
        
        ---
        
        """
        
        // 按配置排序
        let sortedReflections = reflections.sorted { r1, r2 in
            switch config.sortBy {
            case .date:
                return config.sortOrder == .ascending ? r1.createdAt < r2.createdAt : r1.createdAt > r2.createdAt
            case .rating:
                return config.sortOrder == .ascending ? r1.rating < r2.rating : r1.rating > r2.rating
            case .type:
                return config.sortOrder == .ascending ? r1.reflectionType.rawValue < r2.reflectionType.rawValue : r1.reflectionType.rawValue > r2.reflectionType.rawValue
            }
        }
        
        // 渲染每篇反思
        for reflection in sortedReflections {
            let type = reflection.reflectionType
            pdfContent += """
            ## \(type.icon) \(type.displayName)
            
            **日期**: \(dateFormatter.string(from: reflection.createdAt))
            **重要性**: \(String(repeating: "⭐", count: reflection.rating))
            
            \(reflection.tags.isEmpty ? "" : "**标签**: " + reflection.tags.joined(separator: ", "))
            
            ### 内容
            
            \(reflection.content)
            
            """
            
            if config.includeActionItems && !reflection.actionItems.isEmpty {
                pdfContent += """
                ### 行动项
                
                \(reflection.actionItems.map { "- [ ] \($0)" }.joined(separator: "\n"))
                
                """
            }
            
            if !reflection.followUpNotes.isEmpty {
                pdfContent += """
                ### 后续笔记
                
                \(reflection.followUpNotes)
                
                """
            }
            
            pdfContent += "---\n\n"
        }
        
        // 在 iOS 环境中，这里会使用 UIGraphicsPDFRenderer 将内容渲染为 PDF
        // 返回 UTF-8 编码的数据作为占位
        return pdfContent.data(using: .utf8) ?? Data()
    }
    
    // MARK: - Markdown 导出
    
    /// 导出为 Markdown
    private func exportToMarkdown(reflections: [DreamReflection], config: ReflectionExportConfig) throws -> URL {
        let outputDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReflectionExports")
        try? fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let filename = "梦境反思日记_\(Date().formatted(.dateTime.year().month().day()))"
        let outputURL = outputDir.appendingPathComponent("\(filename).md")
        
        var markdown = """
        # 梦境反思日记
        
        导出日期：\(Date().formatted(.dateTime.year().month().day()))
        共 **\(reflections.count)** 篇反思
        
        ---
        
        """
        
        for reflection in reflections {
            let type = reflection.reflectionType
            markdown += """
            ## \(type.icon) \(type.displayName)
            
            **日期**: \(reflection.createdAt.formatted(.dateTime.year().month().day().hour().minute()))
            **重要性**: \(String(repeating: "⭐", count: reflection.rating))
            \(reflection.tags.isEmpty ? "" : "**标签**: " + reflection.tags.joined(separator: " "))
            
            ### 内容
            
            \(reflection.content)
            
            """
            
            if config.includeActionItems && !reflection.actionItems.isEmpty {
                markdown += "### 行动项\n\n"
                for item in reflection.actionItems {
                    markdown += "- [ ] \(item)\n"
                }
                markdown += "\n"
            }
            
            if !reflection.relatedLifeEvents.isEmpty {
                markdown += "### 关联事件\n\n"
                for event in reflection.relatedLifeEvents {
                    markdown += "- \(event)\n"
                }
                markdown += "\n"
            }
            
            markdown += "---\n\n"
        }
        
        try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }
    
    // MARK: - JSON 导出
    
    /// 导出为 JSON
    private func exportToJSON(reflections: [DreamReflection], config: ReflectionExportConfig) throws -> URL {
        let outputDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReflectionExports")
        try? fileManager.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        let filename = "梦境反思日记_\(Date().formatted(.dateTime.year().month().day()))"
        let outputURL = outputDir.appendingPathComponent("\(filename).json")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(reflections)
        try data.write(to: outputURL)
        
        return outputURL
    }
    
    // MARK: - 分享功能
    
    /// 分享导出文件
    func shareExport(url: URL) {
        // 使用 UIActivityViewController 分享
        // 在实际应用中由 UI 层调用
        print("分享文件：\(url)")
    }
    
    // MARK: - 清理旧导出
    
    /// 清理超过 30 天的导出文件
    func cleanupOldExports() {
        let outputDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ReflectionExports")
        
        guard let files = try? fileManager.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        
        for file in files {
            guard let resources = try? file.resourceValues(forKeys: [.creationDateKey]),
                  let created = resources.creationDate,
                  created < thirtyDaysAgo else {
                continue
            }
            try? fileManager.removeItem(at: file)
        }
    }
}

// MARK: - 导出历史

/// 导出历史记录
@Model
final class ReflectionExportHistory {
    var id: UUID
    var format: String
    var reflectionCount: Int
    var dateRange: String
    var filePath: String
    var fileSize: Int64
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        format: String,
        reflectionCount: Int,
        dateRange: String,
        filePath: String,
        fileSize: Int64,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.format = format
        self.reflectionCount = reflectionCount
        self.dateRange = dateRange
        self.filePath = filePath
        self.fileSize = fileSize
        self.createdAt = createdAt
    }
}
