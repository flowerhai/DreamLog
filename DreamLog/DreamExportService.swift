//
//  DreamExportService.swift
//  DreamLog
//
//  Phase 19 - Dream Data Export & Integration
//  Core export service for multiple formats
//

import Foundation
import SwiftData

@MainActor
class DreamExportService {
    
    static let shared = DreamExportService()
    
    private let modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // MARK: - Export Dreams
    
    func exportDreams(
        options: ExportOptions,
        customDateRange: (start: Date, end: Date)? = nil
    ) async -> ExportResult {
        do {
            // Fetch dreams based on options
            let dreams = try fetchDreams(options: options, customDateRange: customDateRange)
            
            guard !dreams.isEmpty else {
                return ExportResult(
                    success: false,
                    errorMessage: "没有找到符合条件的梦境"
                )
            }
            
            // Generate export content based on format
            let content: String
            switch options.format {
            case .json:
                content = try generateJSON(dreams: dreams, options: options)
            case .csv:
                content = try generateCSV(dreams: dreams, options: options)
            case .markdown:
                content = generateMarkdown(dreams: dreams, options: options)
            case .obsidian:
                content = generateObsidianMarkdown(dreams: dreams, options: options)
            case .notion:
                content = try generateCSV(dreams: dreams, options: options) // Notion uses CSV
            }
            
            // Write to temporary file
            let fileURL = try writeToFile(content: content, format: options.format)
            
            // Calculate file size
            let fileSize = ByteCountFormatter.string(fromByteCount: Int64(content.count), countStyle: .file)
            
            return ExportResult(
                success: true,
                fileURL: fileURL,
                dreamCount: dreams.count,
                fileSize: fileSize,
                exportedAt: Date()
            )
            
        } catch {
            return ExportResult(
                success: false,
                errorMessage: "导出失败：\(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Fetch Dreams
    
    private func fetchDreams(
        options: ExportOptions,
        customDateRange: (start: Date, end: Date)? = nil
    ) throws -> [Dream] {
        guard let modelContext = modelContext else {
            throw NSError(domain: "DreamExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model context not available"])
        }
        
        var sortDescriptor = SortDescriptor(\Dream.date, order: .reverse)
        
        switch options.sortOrder {
        case .dateDescending:
            sortDescriptor = SortDescriptor(\Dream.date, order: .reverse)
        case .dateAscending:
            sortDescriptor = SortDescriptor(\Dream.date, order: .forward)
        case .clarityDescending:
            sortDescriptor = SortDescriptor(\Dream.clarity, order: .reverse)
        case .intensityDescending:
            sortDescriptor = SortDescriptor(\Dream.intensity, order: .reverse)
        }
        
        var fetchDescriptor = FetchDescriptor<Dream>(sortBy: [sortDescriptor])
        
        // Apply date range filter
        if let dateRange = options.dateRange.dateRange() ?? customDateRange {
            fetchDescriptor.predicate = #Predicate<Dream> { dream in
                dream.date >= dateRange.start && dream.date <= dateRange.end
            }
        }
        
        return try modelContext.fetch(fetchDescriptor)
    }
    
    // MARK: - Generate JSON
    
    private func generateJSON(dreams: [Dream], options: ExportOptions) throws -> String {
        var exportData: [[String: Any]] = []
        
        for dream in dreams {
            var dreamDict: [String: Any] = [:]
            
            if options.includeFields.contains(.title) {
                dreamDict["title"] = dream.title
            }
            if options.includeFields.contains(.content) {
                dreamDict["content"] = dream.content
            }
            if options.includeFields.contains(.tags) {
                dreamDict["tags"] = dream.tags
            }
            if options.includeFields.contains(.emotions) {
                dreamDict["emotions"] = dream.emotions.map { $0.rawValue }
            }
            if options.includeFields.contains(.clarity) {
                dreamDict["clarity"] = dream.clarity
            }
            if options.includeFields.contains(.intensity) {
                dreamDict["intensity"] = dream.intensity
            }
            if options.includeFields.contains(.isLucid) {
                dreamDict["isLucid"] = dream.isLucid
            }
            if options.includeFields.contains(.aiAnalysis) {
                dreamDict["aiAnalysis"] = dream.aiAnalysis
            }
            if options.includeFields.contains(.date) {
                dreamDict["date"] = ISO8601DateFormatter().string(from: dream.date)
            }
            
            exportData.append(dreamDict)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw NSError(domain: "DreamExport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize JSON"])
        }
        
        return jsonString
    }
    
    // MARK: - Generate CSV
    
    private func generateCSV(dreams: [Dream], options: ExportOptions) throws -> String {
        var csvRows: [String] = []
        
        // Header row
        var headers: [String] = []
        if options.includeFields.contains(.date) { headers.append("Date") }
        if options.includeFields.contains(.title) { headers.append("Title") }
        if options.includeFields.contains(.content) { headers.append("Content") }
        if options.includeFields.contains(.tags) { headers.append("Tags") }
        if options.includeFields.contains(.emotions) { headers.append("Emotions") }
        if options.includeFields.contains(.clarity) { headers.append("Clarity") }
        if options.includeFields.contains(.intensity) { headers.append("Intensity") }
        if options.includeFields.contains(.isLucid) { headers.append("Is Lucid") }
        if options.includeFields.contains(.aiAnalysis) { headers.append("AI Analysis") }
        
        csvRows.append(headers.map { escapeCSV($0) }.joined(separator: ","))
        
        // Data rows
        for dream in dreams {
            var row: [String] = []
            
            if options.includeFields.contains(.date) {
                row.append(ISO8601DateFormatter().string(from: dream.date))
            }
            if options.includeFields.contains(.title) {
                row.append(escapeCSV(dream.title))
            }
            if options.includeFields.contains(.content) {
                row.append(escapeCSV(dream.content.replacingOccurrences(of: "\n", with: " ")))
            }
            if options.includeFields.contains(.tags) {
                row.append(escapeCSV(dream.tags.joined(separator: "; ")))
            }
            if options.includeFields.contains(.emotions) {
                row.append(escapeCSV(dream.emotions.map { $0.rawValue }.joined(separator: "; ")))
            }
            if options.includeFields.contains(.clarity) {
                row.append(String(dream.clarity))
            }
            if options.includeFields.contains(.intensity) {
                row.append(String(dream.intensity))
            }
            if options.includeFields.contains(.isLucid) {
                row.append(dream.isLucid ? "Yes" : "No")
            }
            if options.includeFields.contains(.aiAnalysis) {
                row.append(escapeCSV((dream.aiAnalysis ?? "").replacingOccurrences(of: "\n", with: " ")))
            }
            
            csvRows.append(row.joined(separator: ","))
        }
        
        return csvRows.joined(separator: "\n")
    }
    
    private func escapeCSV(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }
    
    // MARK: - Generate Markdown
    
    private func generateMarkdown(dreams: [Dream], options: ExportOptions) -> String {
        var markdown = "# 梦境导出\n\n"
        markdown += "导出时间：\(formatDate(Date()))\n"
        markdown += "梦境数量：\(dreams.count)\n\n"
        markdown += "---\n\n"
        
        for (index, dream) in dreams.enumerated() {
            markdown += "## \(index + 1). \(dream.title)\n\n"
            
            if options.includeFields.contains(.date) {
                markdown += "**日期**: \(formatDate(dream.date))\n\n"
            }
            
            if options.includeFields.contains(.content) {
                markdown += "### 内容\n\n\(dream.content)\n\n"
            }
            
            if options.includeFields.contains(.tags) && !dream.tags.isEmpty {
                markdown += "**标签**: \(dream.tags.map { "#\($0)" }.joined(separator: " "))\n\n"
            }
            
            if options.includeFields.contains(.emotions) && !dream.emotions.isEmpty {
                markdown += "**情绪**: \(dream.emotions.map { $0.rawValue }.joined(separator: ", "))\n\n"
            }
            
            if options.includeFields.contains(.clarity) {
                markdown += "**清晰度**: \(String(repeating: "⭐️", count: dream.clarity))\n\n"
            }
            
            if options.includeFields.contains(.intensity) {
                markdown += "**强度**: \(String(repeating: "💪", count: dream.intensity))\n\n"
            }
            
            if options.includeFields.contains(.isLucid) {
                markdown += "**清醒梦**: \(dream.isLucid ? "✅ 是" : "❌ 否")\n\n"
            }
            
            if options.includeFields.contains(.aiAnalysis), let analysis = dream.aiAnalysis {
                markdown += "### AI 解析\n\n\(analysis)\n\n"
            }
            
            markdown += "---\n\n"
        }
        
        markdown += "\n*由 DreamLog 导出*"
        
        return markdown
    }
    
    // MARK: - Generate Obsidian Markdown
    
    private func generateObsidianMarkdown(dreams: [Dream], options: ExportOptions) -> String {
        var markdown = ""
        
        for dream in dreams {
            markdown += "---\n"
            markdown += "tags: [\(dream.tags.joined(separator: ", "))]\n"
            
            if !dream.emotions.isEmpty {
                markdown += "emotions: [\(dream.emotions.map { $0.rawValue }.joined(separator: ", "))]\n"
            }
            
            markdown += "clarity: \(dream.clarity)\n"
            markdown += "intensity: \(dream.intensity)\n"
            markdown += "lucid: \(dream.isLucid)\n"
            markdown += "date: \(formatDateForObsidian(dream.date))\n"
            markdown += "---\n\n"
            
            markdown += "# \(dream.title)\n\n"
            markdown += "\(dream.content)\n\n"
            
            if let analysis = dream.aiAnalysis {
                markdown += "## AI 解析\n\n\(analysis)\n\n"
            }
            
            markdown += "\n---\n\n"
        }
        
        return markdown
    }
    
    // MARK: - File Operations
    
    private func writeToFile(content: String, format: ExportFormat) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let filename = "DreamLog_Export_\(timestamp).\(format.fileExtension)"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    private func formatDateForObsidian(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Export Statistics
    
    func calculateStatistics(dreams: [Dream]) -> ExportStatistics {
        guard !dreams.isEmpty else {
            return ExportStatistics()
        }
        
        let totalDreams = dreams.count
        let averageClarity = dreams.map { Double($0.clarity) }.reduce(0, +) / Double(totalDreams)
        let averageIntensity = dreams.map { Double($0.intensity) }.reduce(0, +) / Double(totalDreams)
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidDreamPercentage = (Double(lucidCount) / Double(totalDreams)) * 100
        
        // Top tags
        let tagCounts = Dictionary(grouping: dreams.flatMap { $0.tags }) { $0 }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
        
        // Dominant emotions
        let emotionCounts = Dictionary(grouping: dreams.flatMap { $0.emotions }) { $0.rawValue }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return ExportStatistics(
            totalDreams: totalDreams,
            dateRange: "\(totalDreams) 个梦境",
            averageClarity: averageClarity,
            averageIntensity: averageIntensity,
            lucidDreamPercentage: lucidDreamPercentage,
            topTags: tagCounts,
            dominantEmotions: emotionCounts
        )
    }
}
