//
//  DreamImportService.swift
//  DreamLog - 梦境导入中心服务
//
//  Phase 34: 梦境导入中心 - 支持多格式导入
//  Created: 2026-03-13 20:04 UTC
//

import Foundation
import SwiftData

// MARK: - 导入服务

@MainActor
final class DreamImportService {
    static let shared = DreamImportService()
    
    private let modelContext: ModelContext
    private var currentTask: DreamImportTask?
    private var isImporting = false
    
    // 导入进度更新回调
    var onProgressUpdate: ((Double, Int, Int, Int) -> Void)?
    var onComplete: ((DreamImportTask) -> Void)?
    
    init(modelContext: ModelContext? = nil) {
        if let context = modelContext {
            self.modelContext = context
        } else {
            // 创建临时 context 用于预览
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: Dream.self, configurations: config)
                self.modelContext = ModelContext(container)
            } catch {
                fatalError("Failed to create in-memory ModelContainer for DreamImportService: \(error)")
            }
        }
    }
    
    // MARK: - 文件预览
    
    /// 预览导入文件
    func previewFile(at url: URL, sourceType: ImportSourceType) async throws -> ImportPreview {
        let data = try Data(contentsOf: url)
        let fileName = url.lastPathComponent
        
        switch sourceType {
        case .json:
            return try await previewJSON(data: data, fileName: fileName)
        case .csv:
            return try await previewCSV(data: data, fileName: fileName)
        case .obsidian, .notion:
            if url.pathExtension == "md" {
                return try await previewMarkdown(data: data, fileName: fileName, sourceType: sourceType)
            } else if url.pathExtension == "csv" {
                return try await previewCSV(data: data, fileName: fileName)
            } else {
                return try await previewJSON(data: data, fileName: fileName)
            }
        default:
            // 尝试自动检测格式
            return try await autoPreview(data: data, fileName: fileName, url: url)
        }
    }
    
    /// 自动检测并预览文件
    private func autoPreview(data: Data, fileName: String, url: URL) async throws -> ImportPreview {
        // 尝试 JSON
        if data.starts(with: [0x7B]) || data.starts(with: [0x5B]) {
            return try await previewJSON(data: data, fileName: fileName)
        }
        // 尝试 CSV
        if let firstLine = String(data: data, encoding: .utf8)?.components(separatedBy: .newlines).first,
           firstLine.contains(",") {
            return try await previewCSV(data: data, fileName: fileName)
        }
        // 尝试 Markdown
        if url.pathExtension == "md" {
            return try await previewMarkdown(data: data, fileName: fileName, sourceType: .obsidian)
        }
        throw ImportError.unsupportedFormat
    }
    
    /// 预览 JSON 文件
    private func previewJSON(data: Data, fileName: String) async throws -> ImportPreview {
        var items: [ImportDreamData] = []
        var issues: [ImportIssue] = []
        
        // 尝试解析为数组
        if let jsonArray = try? JSONDecoder().decode([[String: AnyCodable]].self, from: data) {
            for (index, json) in jsonArray.prefix(5).enumerated() {
                if let item = parseJSONDream(json: json, index: index) {
                    items.append(item)
                }
            }
            if jsonArray.count > 5 {
                issues.append(ImportIssue(
                    type: .largeFile,
                    message: "文件包含 \(jsonArray.count) 条梦境，导入可能需要较长时间",
                    severity: .info,
                    affectedItems: jsonArray.count
                ))
            }
        }
        // 尝试解析为单个对象
        else if let jsonObject = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
            if let item = parseJSONDream(json: jsonObject, index: 0) {
                items.append(item)
            }
        }
        
        return ImportPreview(
            sourceType: .json,
            fileName: fileName,
            itemCount: items.isEmpty ? 1 : items.count,
            estimatedSize: ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file),
            sampleItems: items,
            potentialIssues: issues
        )
    }
    
    /// 解析 JSON 梦境数据
    private func parseJSONDream(json: [String: AnyCodable], index: Int) -> ImportDreamData? {
        guard let content = extractString(from: json["content"]) ?? extractString(from: json["text"]) ?? extractString(from: json["description"]) else {
            return nil
        }
        
        let date = extractDate(from: json["date"]) ?? extractDate(from: json["created_at"]) ?? extractDate(from: json["timestamp"]) ?? Date()
        
        return ImportDreamData(
            id: extractString(from: json["id"]) ?? extractString(from: json["_id"]),
            title: extractString(from: json["title"]) ?? extractString(from: json["name"]),
            content: content,
            date: date,
            createdAt: extractDate(from: json["created_at"]) ?? extractDate(from: json["createdAt"]),
            updatedAt: extractDate(from: json["updated_at"]) ?? extractDate(from: json["updatedAt"]),
            tags: extractStringArray(from: json["tags"]) ?? extractStringArray(from: json["labels"]),
            emotions: extractStringArray(from: json["emotions"]) ?? extractStringArray(from: json["moods"]),
            mood: extractString(from: json["mood"]),
            clarity: extractDouble(from: json["clarity"]) ?? extractDouble(from: json["quality"]),
            isLucid: extractBool(from: json["isLucid"]) ?? extractBool(from: json["lucid"]),
            metadata: json
        )
    }
    
    /// 预览 CSV 文件
    private func previewCSV(data: Data, fileName: String) async throws -> ImportPreview {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.encodingError
        }
        
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            throw ImportError.invalidFormat
        }
        
        let headers = lines[0].components(separatedBy: ",")
        var items: [ImportDreamData] = []
        
        for line in lines.dropFirst().prefix(5) {
            let values = line.components(separatedBy: ",")
            var itemDict: [String: AnyCodable] = [:]
            for (index, header) in headers.enumerated() {
                if index < values.count {
                    itemDict[header.trimmingCharacters(in: .whitespaces)] = AnyCodable(values[index].trimmingCharacters(in: .whitespaces))
                }
            }
            if let item = parseJSONDream(json: itemDict, index: 0) {
                items.append(item)
            }
        }
        
        return ImportPreview(
            sourceType: .csv,
            fileName: fileName,
            itemCount: lines.count - 1,
            estimatedSize: ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file),
            sampleItems: items
        )
    }
    
    /// 预览 Markdown 文件
    private func previewMarkdown(data: Data, fileName: String, sourceType: ImportSourceType) async throws -> ImportPreview {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.encodingError
        }
        
        // 按分隔符分割梦境
        let separators = ["\n---\n", "\n***\n", "\n### ", "\n## "]
        var sections: [String] = [content]
        
        for separator in separators {
            var newSections: [String] = []
            for section in sections {
                newSections.append(contentsOf: section.components(separatedBy: separator))
            }
            sections = newSections
        }
        
        var items: [ImportDreamData] = []
        for section in sections.prefix(5) {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.count > 50 {
                items.append(ImportDreamData(
                    content: trimmed,
                    date: extractDateFromMarkdown(trimmed) ?? Date()
                ))
            }
        }
        
        return ImportPreview(
            sourceType: sourceType,
            fileName: fileName,
            itemCount: max(sections.count, items.count),
            estimatedSize: ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file),
            sampleItems: items
        )
    }
    
    // MARK: - 执行导入
    
    /// 执行导入任务
    func startImport(
        from url: URL,
        sourceType: ImportSourceType,
        settings: ImportSettings = ImportSettings()
    ) async throws -> DreamImportTask {
        guard !isImporting else {
            throw ImportError.alreadyImporting
        }
        
        isImporting = true
        
        // 创建导入任务
        let task = DreamImportTask(
            name: url.lastPathComponent,
            sourceType: sourceType,
            sourceFile: url.path,
            settings: settings
        )
        
        currentTask = task
        
        do {
            // 读取文件
            let data = try Data(contentsOf: url)
            var importData: [ImportDreamData] = []
            
            // 解析数据
            switch sourceType {
            case .json:
                importData = try await parseJSON(data: data)
            case .csv:
                importData = try await parseCSV(data: data)
            case .obsidian, .notion:
                if url.pathExtension == "md" {
                    importData = try await parseMarkdown(data: data)
                } else {
                    importData = try await parseJSON(data: data)
                }
            default:
                importData = try await autoParse(data: data, url: url)
            }
            
            task.totalItems = importData.count
            task.startedAt = Date()
            
            // 执行导入
            try await executeImport(data: importData, task: task, settings: settings)
            
            task.completedAt = Date()
            task.status = task.failureCount > 0 ? .partial : .completed
            
        } catch {
            task.status = .failed
            task.errorMessage = error.localizedDescription
            throw error
        }
        
        isImporting = false
        onComplete?(task)
        
        return task
    }
    
    /// 解析 JSON 数据
    private func parseJSON(data: Data) async throws -> [ImportDreamData] {
        var items: [ImportDreamData] = []
        
        // 尝试数组格式
        if let jsonArray = try? JSONDecoder().decode([[String: AnyCodable]].self, from: data) {
            for (index, json) in jsonArray.enumerated() {
                if let item = parseJSONDream(json: json, index: index) {
                    items.append(item)
                }
            }
            return items
        }
        
        // 尝试单个对象
        if let jsonObject = try? JSONDecoder().decode([String: AnyCodable].self, from: data) {
            if let item = parseJSONDream(json: jsonObject, index: 0) {
                items.append(item)
            }
        }
        
        return items
    }
    
    /// 解析 CSV 数据
    private func parseCSV(data: Data) async throws -> [ImportDreamData] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.encodingError
        }
        
        let lines = csvString.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            return []
        }
        
        let headers = lines[0].components(separatedBy: ",")
        var items: [ImportDreamData] = []
        
        for line in lines.dropFirst() {
            let values = line.components(separatedBy: ",")
            var itemDict: [String: AnyCodable] = [:]
            for (index, header) in headers.enumerated() {
                if index < values.count {
                    itemDict[header.trimmingCharacters(in: .whitespaces)] = AnyCodable(values[index].trimmingCharacters(in: .whitespaces))
                }
            }
            if let item = parseJSONDream(json: itemDict, index: 0) {
                items.append(item)
            }
        }
        
        return items
    }
    
    /// 解析 Markdown 数据
    private func parseMarkdown(data: Data) async throws -> [ImportDreamData] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.encodingError
        }
        
        // 按分隔符分割
        let sections = content.components(separatedBy: "\n---\n")
        var items: [ImportDreamData] = []
        
        for section in sections {
            let trimmed = section.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.count > 50 {
                items.append(ImportDreamData(
                    content: trimmed,
                    date: extractDateFromMarkdown(trimmed) ?? Date()
                ))
            }
        }
        
        return items
    }
    
    /// 自动解析数据
    private func autoParse(data: Data, url: URL) async throws -> [ImportDreamData] {
        if data.starts(with: [0x7B]) || data.starts(with: [0x5B]) {
            return try await parseJSON(data: data)
        }
        if url.pathExtension == "md" {
            return try await parseMarkdown(data: data)
        }
        return try await parseCSV(data: data)
    }
    
    /// 执行实际导入
    private func executeImport(
        data: [ImportDreamData],
        task: DreamImportTask,
        settings: ImportSettings
    ) async throws {
        for (index, item) in data.enumerated() {
            // 更新进度
            let progress = Double(index) / Double(data.count)
            task.progress = progress
            onProgressUpdate?(progress, task.successCount, task.failureCount, task.duplicateCount)
            
            // 检查重复
            if let existing = findDuplicate(of: item) {
                task.duplicateCount += 1
                if settings.mergeDuplicates {
                    // 合并逻辑（简化版）
                    task.mergedCount += 1
                    task.results.append(DreamImportResult(
                        sourceId: item.id,
                        dreamId: existing,
                        status: .completed,
                        isDuplicate: true,
                        mergedWithId: existing
                    ))
                } else if settings.skipDuplicates {
                    task.results.append(DreamImportResult(
                        sourceId: item.id,
                        status: .completed,
                        isDuplicate: true
                    ))
                    continue
                }
            }
            
            // 创建梦境
            do {
                let dream = try createDream(from: item, settings: settings)
                task.successCount += 1
                task.results.append(DreamImportResult(
                    sourceId: item.id,
                    dreamId: dream.id,
                    status: .completed,
                    importedFields: ["content", "date", "title"]
                ))
            } catch {
                task.failureCount += 1
                task.results.append(DreamImportResult(
                    sourceId: item.id,
                    status: .failed,
                    errorMessage: error.localizedDescription
                ))
            }
        }
    }
    
    /// 查找重复梦境
    private func findDuplicate(of item: ImportDreamData) -> UUID? {
        // 基于内容和日期查找重复
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { dream in
                // 简化匹配逻辑
                if let existingContent = dream.content {
                    let contentMatch = existingContent.contains(item.content.prefix(100)) || item.content.contains(existingContent.prefix(100))
                    let dateMatch = abs(dream.date.timeIntervalSince(item.date)) < 86400 // 24 小时内
                    return contentMatch && dateMatch
                }
                return false
            }
        )
        
        do {
            let matches = try modelContext.fetch(descriptor)
            return matches.first?.id
        } catch {
            return nil
        }
    }
    
    /// 创建梦境
    private func createDream(from item: ImportDreamData, settings: ImportSettings) throws -> Dream {
        let dream = Dream(
            content: item.content,
            date: item.date,
            title: item.title,
            clarity: item.clarity ?? 0.5,
            emotions: item.emotions ?? [],
            tags: settings.importTags ? (item.tags ?? []) : [],
            isLucid: item.isLucid ?? false,
            visibility: settings.defaultVisibility
        )
        
        modelContext.insert(dream)
        try modelContext.save()
        
        return dream
    }
    
    // MARK: - 辅助方法
    
    private func extractString(from value: AnyCodable?) -> String? {
        guard let value = value else { return nil }
        return value.value as? String
    }
    
    private func extractDate(from value: AnyCodable?) -> Date? {
        guard let value = value else { return nil }
        
        if let date = value.value as? Date {
            return date
        }
        if let string = value.value as? String {
            let formatters: [DateFormatter] = [
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    return f
                }()
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: string) {
                    return date
                }
            }
        }
        if let timestamp = value.value as? TimeInterval {
            return Date(timeIntervalSince1970: timestamp / 1000)
        }
        if let timestamp = value.value as? Int64 {
            return Date(timeIntervalSince1970: Double(timestamp) / 1000)
        }
        
        return nil
    }
    
    private func extractStringArray(from value: AnyCodable?) -> [String]? {
        guard let value = value else { return nil }
        if let array = value.value as? [String] {
            return array
        }
        if let array = value.value as? [Any] {
            return array.compactMap { $0 as? String }
        }
        return nil
    }
    
    private func extractDouble(from value: AnyCodable?) -> Double? {
        guard let value = value else { return nil }
        if let double = value.value as? Double {
            return double
        }
        if let int = value.value as? Int {
            return Double(int)
        }
        if let string = value.value as? String {
            return Double(string)
        }
        return nil
    }
    
    private func extractBool(from value: AnyCodable?) -> Bool? {
        guard let value = value else { return nil }
        return value.value as? Bool
    }
    
    private func extractDateFromMarkdown(_ content: String) -> Date? {
        // 尝试从 Markdown 内容中提取日期
        let patterns = [
            #"(\d{4}-\d{2}-\d{2})"#,
            #"(\d{2}/\d{2}/\d{4})"#,
            #"(\d{2}-\d{2}-\d{4})"#
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let range = Range(match.range(at: 1), in: content) {
                let dateString = String(content[range])
                let formatters: [DateFormatter] = [
                    {
                        let f = DateFormatter()
                        f.dateFormat = "yyyy-MM-dd"
                        return f
                    }(),
                    {
                        let f = DateFormatter()
                        f.dateFormat = "MM/dd/yyyy"
                        return f
                    }(),
                    {
                        let f = DateFormatter()
                        f.dateFormat = "MM-dd-yyyy"
                        return f
                    }()
                ]
                
                for formatter in formatters {
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
            }
        }
        
        return nil
    }
}

// MARK: - 导入错误

enum ImportError: LocalizedError {
    case fileNotFound
    case unsupportedFormat
    case encodingError
    case invalidFormat
    case alreadyImporting
    case parseError(String)
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件不存在"
        case .unsupportedFormat:
            return "不支持的文件格式"
        case .encodingError:
            return "文件编码错误"
        case .invalidFormat:
            return "文件格式无效"
        case .alreadyImporting:
            return "已有导入任务正在进行"
        case .parseError(let message):
            return "解析错误：\(message)"
        case .importFailed(let message):
            return "导入失败：\(message)"
        }
    }
}
