//
//  DreamExportHubService.swift
//  DreamLog
//
//  Phase 52 - 梦境导出中心
//  创建时间：2026-03-16
//

import Foundation
import SwiftData

/// 梦境导出中心服务
@ModelActor
actor DreamExportHubService {
    
    // MARK: - 单例
    
    static let shared = DreamExportHubService()
    
    // MARK: - 导出任务管理
    
    /// 创建导出任务
    func createExportTask(
        name: String,
        platform: ExportPlatform,
        format: ExportFormat = .markdown,
        dreamIds: [UUID] = [],
        exportAll: Bool = false,
        dateRange: DateRange? = nil,
        options: ExportOptions = .default,
        scheduledTime: Date? = nil,
        repeatInterval: String? = nil,
        destinationPath: String? = nil
    ) async throws -> ExportTask {
        let task = ExportTask(
            name: name,
            platform: platform,
            format: format,
            dreamIds: dreamIds,
            exportAll: exportAll,
            dateRange: dateRange,
            options: options,
            status: scheduledTime != nil ? .scheduled : .pending,
            scheduledTime: scheduledTime,
            repeatInterval: repeatInterval,
            nextExportTime: scheduledTime,
            destinationPath: destinationPath
        )
        
        modelContext.insert(task)
        try modelContext.save()
        
        return task
    }
    
    /// 获取所有导出任务
    func getAllExportTasks() async throws -> [ExportTask] {
        let descriptor = FetchDescriptor<ExportTask>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取启用的导出任务
    func getEnabledExportTasks() async throws -> [ExportTask] {
        let descriptor = FetchDescriptor<ExportTask>(
            predicate: #Predicate<ExportTask> { $0.isEnabled },
            sortBy: [SortDescriptor(\.nextExportTime, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取待处理的导出任务
    func getPendingExportTasks() async throws -> [ExportTask] {
        let descriptor = FetchDescriptor<ExportTask>(
            predicate: #Predicate<ExportTask> { $0.status == ExportStatus.pending.rawValue && $0.isEnabled },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 更新导出任务
    func updateExportTask(_ task: ExportTask) async throws {
        task.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 删除导出任务
    func deleteExportTask(_ task: ExportTask) async throws {
        modelContext.delete(task)
        try modelContext.save()
    }
    
    /// 启用/禁用导出任务
    func toggleExportTask(_ task: ExportTask, enabled: Bool) async throws {
        task.isEnabled = enabled
        task.updatedAt = Date()
        
        if enabled && task.scheduledTime != nil && task.nextExportTime == nil {
            task.nextExportTime = task.scheduledTime
            task.status = ExportStatus.scheduled.rawValue
        } else if !enabled {
            task.status = ExportStatus.cancelled.rawValue
        }
        
        try modelContext.save()
    }
    
    // MARK: - 导出执行
    
    /// 执行导出任务
    func executeExportTask(_ task: ExportTask) async throws -> ExportHistory {
        task.status = ExportStatus.processing.rawValue
        task.updatedAt = Date()
        try modelContext.save()
        
        let startTime = Date()
        
        do {
            // 获取要导出的梦境
            let dreams = try await getDreamsForExport(task)
            
            // 根据平台执行导出
            let exportResult = try await exportDreams(
                dreams: dreams,
                platform: task.platformEnum,
                format: task.formatEnum,
                options: task.exportOptions
            )
            
            // 创建导出历史
            let history = ExportHistory(
                taskId: task.id,
                platform: task.platformEnum,
                format: task.formatEnum,
                dreamCount: dreams.count,
                fileSize: exportResult.fileSize,
                filePath: exportResult.filePath,
                status: .completed,
                duration: Date().timeIntervalSince(startTime)
            )
            
            modelContext.insert(history)
            
            // 更新任务状态
            task.status = ExportStatus.completed.rawValue
            task.lastExportTime = Date()
            task.exportCount += 1
            task.nextExportTime = calculateNextExportTime(from: task.lastExportTime!, interval: task.repeatInterval)
            
            try modelContext.save()
            
            return history
            
        } catch {
            // 导出失败
            let history = ExportHistory(
                taskId: task.id,
                platform: task.platformEnum,
                format: task.formatEnum,
                dreamCount: 0,
                status: .failed,
                errorMessage: error.localizedDescription,
                duration: Date().timeIntervalSince(startTime)
            )
            
            modelContext.insert(history)
            task.status = ExportStatus.failed.rawValue
            try modelContext.save()
            
            throw error
        }
    }
    
    /// 获取要导出的梦境
    private func getDreamsForExport(_ task: ExportTask) async throws -> [Dream] {
        var descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if task.exportAll {
            // 导出所有梦境
            if let dateRange = task.dateRange {
                descriptor.predicate = #Predicate<Dream> { dream in
                    dream.date >= dateRange.startDate && dream.date <= dateRange.endDate
                }
            }
        } else if !task.dreamIds.isEmpty {
            // 导出指定梦境
            descriptor.predicate = #Predicate<Dream> { dream in
                task.dreamIds.contains(dream.id)
            }
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 导出梦境到指定平台
    private func exportDreams(
        dreams: [Dream],
        platform: ExportPlatform,
        format: ExportFormat,
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        
        switch platform {
        case .markdown, .obsidian:
            return try await exportToMarkdown(dreams: dreams, format: format, options: options)
        case .pdf:
            return try await exportToPDF(dreams: dreams, options: options)
        case .json:
            return try await exportToJSON(dreams: dreams, options: options)
        case .email:
            return try await exportToEmail(dreams: dreams, options: options)
        case .wechat:
            return try await exportToWechat(dreams: dreams, options: options)
        case .notion:
            return try await exportToNotion(dreams: dreams, options: options)
        case .dayOne:
            return try await exportToDayOne(dreams: dreams, options: options)
        case .evernote:
            return try await exportToEvernote(dreams: dreams, options: options)
        case .bear:
            return try await exportToBear(dreams: dreams, options: options)
        case .appleNotes:
            return try await exportToAppleNotes(dreams: dreams, options: options)
        case .custom:
            return try await exportToCustom(dreams: dreams, format: format, options: options)
        }
    }
    
    // MARK: - 导出实现
    
    /// 导出为 Markdown
    private func exportToMarkdown(
        dreams: [Dream],
        format: ExportFormat,
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        
        var content = ""
        
        for dream in dreams {
            content += formatDreamAsMarkdown(dream, options: options)
            content += "\n\n---\n\n"
        }
        
        let data = content.data(using: .utf8) ?? Data()
        let filePath = try saveExportFile(data: data, extension: format.fileExtension, prefix: "dreams")
        
        return (filePath, Int64(data.count))
    }
    
    /// 将梦境格式化为 Markdown
    private func formatDreamAsMarkdown(_ dream: Dream, options: ExportOptions) -> String {
        var md = ""
        
        if options.includeTitle {
            md += "# \(dream.title)\n\n"
        }
        
        if options.includeDate {
            let formatter = DateFormatter()
            formatter.dateFormat = options.dateFormat
            md += "**日期**: \(formatter.string(from: dream.date))\n\n"
        }
        
        md += "\(dream.content)\n\n"
        
        if options.includeEmotions && !dream.emotions.isEmpty {
            let emotionNames = dream.emotions.map { $0.displayName }
            md += "**情绪**: \(emotionNames.joined(separator: ", "))\n\n"
        }
        
        if options.includeTags && !dream.tags.isEmpty {
            let tagNames = dream.tags.map { "#\($0.name)" }
            md += "**标签**: \(tagNames.joined(separator: " "))\n\n"
        }
        
        if options.includeAIAnalysis, let analysis = dream.aiAnalysis {
            md += "## AI 解析\n\n"
            if let summary = analysis.summary {
                md += "**摘要**: \(summary)\n\n"
            }
            if let interpretation = analysis.interpretation {
                md += "**解读**: \(interpretation)\n\n"
            }
        }
        
        if options.includeLucidInfo && dream.isLucid {
            md += "**清醒梦**: ✅\n\n"
        }
        
        if options.includeRating && dream.rating > 0 {
            let stars = String(repeating: "⭐️", count: Int(dream.rating))
            md += "**评分**: \(stars)\n\n"
        }
        
        return md
    }
    
    /// 导出为 PDF
    private func exportToPDF(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        // PDF 导出需要使用 UIGraphicsPDFRenderer
        // 这里预留接口，实际实现在 DreamReflectionExportService 中
        throw NSError(domain: "DreamExportHub", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "PDF 导出需要 DreamReflectionExportService 支持"
        ])
    }
    
    /// 导出为 JSON
    private func exportToJSON(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(dreams)
        let filePath = try saveExportFile(data: data, extension: "json", prefix: "dreams")
        
        return (filePath, Int64(data.count))
    }
    
    /// 导出到邮件
    private func exportToEmail(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        
        var content = "以下是从 DreamLog 导出的梦境记录:\n\n"
        
        for dream in dreams {
            content += "━━━━━━━━━━━━━━━━━━━━\n"
            content += "🌙 \(dream.title)\n"
            content += "📅 \(formatDate(dream.date))\n\n"
            content += "\(dream.content)\n\n"
            
            if !dream.emotions.isEmpty {
                content += "情绪：\(dream.emotions.map { $0.displayName }.joined(separator: ", "))\n"
            }
            
            if !dream.tags.isEmpty {
                content += "标签：\(dream.tags.map { "#\($0.name)" }.joined(separator: " "))\n"
            }
            
            content += "\n"
        }
        
        content += "\n━━━━━━━━━━━━━━━━━━━━\n"
        content += "由 DreamLog 生成"
        
        let data = content.data(using: .utf8) ?? Data()
        return (nil, Int64(data.count))
    }
    
    /// 导出到微信
    private func exportToWechat(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        
        var content = ""
        
        for (index, dream) in dreams.enumerated() {
            if index > 0 {
                content += "\n─────────────\n\n"
            }
            
            content += "🌙 *\(dream.title)*\n"
            content += "📅 \(formatDate(dream.date, short: true))\n\n"
            content += "\(dream.content)\n"
            
            if !dream.emotions.isEmpty {
                content += "\n\(dream.emotions.map { $0.icon }.joined())"
            }
        }
        
        let data = content.data(using: .utf8) ?? Data()
        return (nil, Int64(data.count))
    }
    
    /// 导出到 Notion
    private func exportToNotion(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        // Notion 导出需要 API 密钥
        // 这里预留接口
        throw NSError(domain: "DreamExportHub", code: 2, userInfo: [
            NSLocalizedDescriptionKey: "Notion 导出需要配置 API 密钥"
        ])
    }
    
    /// 导出到 Day One
    private func exportToDayOne(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        // Day One 导出需要特定格式
        throw NSError(domain: "DreamExportHub", code: 3, userInfo: [
            NSLocalizedDescriptionKey: "Day One 导出尚未实现"
        ])
    }
    
    /// 导出到印象笔记
    private func exportToEvernote(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        throw NSError(domain: "DreamExportHub", code: 4, userInfo: [
            NSLocalizedDescriptionKey: "印象笔记导出尚未实现"
        ])
    }
    
    /// 导出到 Bear
    private func exportToBear(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        throw NSError(domain: "DreamExportHub", code: 5, userInfo: [
            NSLocalizedDescriptionKey: "Bear 导出尚未实现"
        ])
    }
    
    /// 导出到苹果备忘录
    private func exportToAppleNotes(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        throw NSError(domain: "DreamExportHub", code: 6, userInfo: [
            NSLocalizedDescriptionKey: "苹果备忘录导出尚未实现"
        ])
    }
    
    /// 自定义导出
    private func exportToCustom(
        dreams: [Dream],
        format: ExportFormat,
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        // 根据自定义配置导出
        return try await exportToMarkdown(dreams: dreams, format: format, options: options)
    }
    
    // MARK: - 辅助方法
    
    /// 保存导出文件
    private func saveExportFile(data: Data, extension ext: String, prefix: String) throws -> String {
        let fileManager = FileManager.default
        
        // 获取 Documents 目录
        let documentsDir = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        
        // 创建导出目录
        let exportDir = documentsDir.appendingPathComponent("Exports", isDirectory: true)
        try fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        // 生成文件名
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ":", with: "-")
        let filename = "\(prefix)_\(timestamp).\(ext)"
        let filePath = exportDir.appendingPathComponent(filename)
        
        // 保存文件
        try data.write(to: filePath)
        
        return filePath.path
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date, short: Bool = false) -> String {
        let formatter = DateFormatter()
        if short {
            formatter.dateFormat = "MM/dd"
        } else {
            formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        }
        return formatter.string(from: date)
    }
    
    /// 计算下次导出时间
    private func calculateNextExportTime(from date: Date, interval: String?) -> Date? {
        guard let interval = interval else { return nil }
        
        let calendar = Calendar.current
        
        switch interval {
        case "daily":
            return calendar.date(byAdding: .day, value: 1, to: date)
        case "weekly":
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case "monthly":
            return calendar.date(byAdding: .month, value: 1, to: date)
        default:
            return nil
        }
    }
    
    // MARK: - 统计数据
    
    /// 获取导出统计
    func getExportStats() async throws -> ExportStats {
        let descriptor = FetchDescriptor<ExportHistory>()
        let histories = try modelContext.fetch(descriptor)
        
        var totalExports = histories.count
        var totalDreamsExported = 0
        var totalDataSize: Int64 = 0
        var exportsByPlatform: [String: Int] = [:]
        var exportsByFormat: [String: Int] = [:]
        var lastExportDate: Date?
        
        for history in histories {
            totalDreamsExported += history.dreamCount
            totalDataSize += history.fileSize
            
            exportsByPlatform[history.platform, default: 0] += 1
            exportsByFormat[history.format, default: 0] += 1
            
            if lastExportDate == nil || history.createdAt > lastExportDate! {
                lastExportDate = history.createdAt
            }
        }
        
        return ExportStats(
            totalExports: totalExports,
            totalDreamsExported: totalDreamsExported,
            totalDataSize: totalDataSize,
            exportsByPlatform: exportsByPlatform,
            exportsByFormat: exportsByFormat,
            lastExportDate: lastExportDate
        )
    }
    
    /// 获取导出历史
    func getExportHistory(limit: Int = 50) async throws -> [ExportHistory] {
        let descriptor = FetchDescriptor<ExportHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
            fetchLimit: limit
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 删除导出历史
    func deleteExportHistory(_ history: ExportHistory) async throws {
        modelContext.delete(history)
        try modelContext.save()
    }
    
    /// 清除所有导出历史
    func clearExportHistory() async throws {
        let descriptor = FetchDescriptor<ExportHistory>()
        let histories = try modelContext.fetch(descriptor)
        
        for history in histories {
            modelContext.delete(history)
        }
        
        try modelContext.save()
    }
}
