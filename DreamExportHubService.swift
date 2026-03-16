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
    
    // MARK: - 导出队列管理
    
    /// 获取导出队列
    func getExportQueue() async throws -> [ExportTask] {
        let descriptor = FetchDescriptor<ExportTask>(
            predicate: #Predicate<ExportTask> {
                $0.status == ExportStatus.pending.rawValue ||
                $0.status == ExportStatus.processing.rawValue ||
                $0.status == ExportStatus.scheduled.rawValue
            },
            sortBy: [
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 暂停队列中的所有任务
    func pauseAllTasks() async throws {
        let descriptor = FetchDescriptor<ExportTask>(
            predicate: #Predicate<ExportTask> {
                $0.status == ExportStatus.pending.rawValue ||
                $0.status == ExportStatus.processing.rawValue
            }
        )
        let tasks = try modelContext.fetch(descriptor)
        
        for task in tasks {
            if task.status == ExportStatus.processing.rawValue {
                task.status = ExportStatus.paused.rawValue
            } else {
                task.status = ExportStatus.paused.rawValue
            }
            task.updatedAt = Date()
        }
        
        try modelContext.save()
    }
    
    /// 恢复队列中的所有任务
    func resumeAllTasks() async throws {
        let descriptor = FetchDescriptor<ExportTask>(
            predicate: #Predicate<ExportTask> { $0.status == ExportStatus.paused.rawValue }
        )
        let tasks = try modelContext.fetch(descriptor)
        
        for task in tasks {
            task.status = ExportStatus.pending.rawValue
            task.updatedAt = Date()
        }
        
        try modelContext.save()
    }
    
    /// 取消队列中的任务
    func cancelTask(_ task: ExportTask) async throws {
        guard task.status != ExportStatus.completed.rawValue else {
            throw NSError(domain: "DreamExportHub", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "已完成的任务无法取消"
            ])
        }
        
        task.status = ExportStatus.cancelled.rawValue
        task.isEnabled = false
        task.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 清空已完成的导出历史
    func clearCompletedTasks() async throws {
        let descriptor = FetchDescriptor<ExportTask>(
            predicate: #Predicate<ExportTask> {
                $0.status == ExportStatus.completed.rawValue ||
                $0.status == ExportStatus.failed.rawValue ||
                $0.status == ExportStatus.cancelled.rawValue
            }
        )
        let tasks = try modelContext.fetch(descriptor)
        
        for task in tasks {
            modelContext.delete(task)
        }
        
        try modelContext.save()
    }
    
    /// 获取队列统计
    func getQueueStats() async throws -> ExportQueueStats {
        let descriptor = FetchDescriptor<ExportTask>()
        let tasks = try modelContext.fetch(descriptor)
        
        var pending = 0
        var processing = 0
        var scheduled = 0
        var paused = 0
        var completed = 0
        var failed = 0
        var cancelled = 0
        
        for task in tasks {
            switch task.statusEnum {
            case .pending: pending += 1
            case .processing: processing += 1
            case .scheduled: scheduled += 1
            case .paused: paused += 1
            case .completed: completed += 1
            case .failed: failed += 1
            case .cancelled: cancelled += 1
            }
        }
        
        return ExportQueueStats(
            pending: pending,
            processing: processing,
            scheduled: scheduled,
            paused: paused,
            completed: completed,
            failed: failed,
            cancelled: cancelled,
            total: tasks.count
        )
    }
    
    // MARK: - 压缩支持
    
    /// 压缩导出文件为 ZIP
    func compressExportFiles(filePaths: [String], outputName: String) throws -> String {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let zipPath = tempDir.appendingPathComponent("\(outputName).zip")
        
        // 移除已存在的文件
        try? fileManager.removeItem(at: zipPath)
        
        // 创建 ZIP 文件
        let coordinator = NSFileCoordinator()
        var error: NSError?
        
        coordinator.coordinate(writingItemAt: tempDir, options: .forReplacing, error: &error) { zipURL in
            let zipWriter = try? FileZipWriter(zipURL: zipURL)
            
            for filePath in filePaths {
                let fileURL = URL(fileURLWithPath: filePath)
                if fileManager.fileExists(atPath: filePath) {
                    try? zipWriter?.addFile(fileURL: fileURL, relativePath: fileURL.lastPathComponent)
                }
            }
            
            try? zipWriter?.close()
        }
        
        if let error = error {
            throw error
        }
        
        return zipPath.path
    }
    
    /// 批量导出并压缩
    func batchExportAndCompress(
        tasks: [ExportTask],
        outputName: String
    ) async throws -> String {
        var exportedPaths: [String] = []
        
        for task in tasks {
            let history = try await executeExportTask(task)
            if let filePath = history.filePath {
                exportedPaths.append(filePath)
            }
        }
        
        return try compressExportFiles(filePaths: exportedPaths, outputName: outputName)
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
            // 如果指定了模板，使用模板渲染
            if let templateName = options.template {
                let template = try? await DreamExportTemplateService.shared.findTemplate(byName: templateName)
                if let template = template {
                    content += await DreamExportTemplateService.shared.renderTemplate(template, dream: dream)
                    content += "\n\n---\n\n"
                    continue
                }
            }
            
            // 否则使用默认格式化
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
            let emotionNames = dream.emotions.map { $0.rawValue }
            md += "**情绪**: \(emotionNames.joined(separator: ", "))\n\n"
        }
        
        if options.includeTags && !dream.tags.isEmpty {
            let tagNames = dream.tags.map { "#\($0)" }
            md += "**标签**: \(tagNames.joined(separator: " "))\n\n"
        }
        
        if options.includeAIAnalysis, let analysis = dream.aiAnalysis, !analysis.isEmpty {
            md += "## AI 解析\n\n"
            md += "\(analysis)\n\n"
        }
        
        if options.includeLucidInfo && dream.isLucid {
            md += "**清醒梦**: ✅\n\n"
        }
        
        if options.includeRating && dream.clarity > 0 {
            let stars = String(repeating: "⭐️", count: Int(dream.clarity))
            md += "**评分**: \(stars)\n\n"
        }
        
        return md
    }
    
    /// 导出为 PDF
    private func exportToPDF(
        dreams: [Dream],
        options: ExportOptions
    ) async throws -> (filePath: String?, fileSize: Int64) {
        // 准备导出数据
        let exportData = dreams.map { $0.toExportData() }
        
        // 创建 PDF 渲染器
        let renderer = DreamPDFExportRenderer()
        
        // 生成 PDF 数据
        let pdfData = renderer.generatePDF(
            dreams: exportData,
            title: options.template != nil ? "梦境导出 - \(options.template!)" : "梦境记录"
        )
        
        // 保存文件
        let filePath = try saveExportFile(data: pdfData, extension: "pdf", prefix: "dreams")
        
        return (filePath, Int64(pdfData.count))
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
                content += "情绪：\(dream.emotions.map { $0.rawValue }.joined(separator: ", "))\n"
            }
            
            if !dream.tags.isEmpty {
                content += "标签：\(dream.tags.map { "#\($0)" }.joined(separator: " "))\n"
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
    
    // MARK: - 导出预览
    
    /// 生成导出预览
    func generateExportPreview(
        dreamIds: [UUID],
        exportAll: Bool,
        dateRange: DateRange?,
        options: ExportOptions,
        platform: ExportPlatform,
        format: ExportFormat
    ) async throws -> ExportPreview {
        // 获取梦境
        let dreams = try await getDreamsForExport(
            dreamIds: dreamIds,
            exportAll: exportAll,
            dateRange: dateRange
        )
        
        // 生成预览内容
        let previewContent: String
        switch format {
        case .markdown, .text:
            previewContent = try await generateMarkdownPreview(dreams: dreams, options: options)
        case .json:
            previewContent = try await generateJSONPreview(dreams: dreams, options: options)
        case .html:
            previewContent = try await generateHTMLPreview(dreams: dreams, options: options)
        default:
            previewContent = try await generateMarkdownPreview(dreams: dreams, options: options)
        }
        
        // 计算统计
        let totalCharacters = previewContent.count
        let estimatedFileSize = Int64(previewContent.utf8.count)
        
        return ExportPreview(
            dreamCount: dreams.count,
            totalCharacters: totalCharacters,
            estimatedFileSize: estimatedFileSize,
            previewContent: String(previewContent.prefix(2000)),
            platform: platform,
            format: format
        )
    }
    
    /// 生成 Markdown 预览
    private func generateMarkdownPreview(dreams: [Dream], options: ExportOptions) async throws -> String {
        var content = ""
        
        for (index, dream) in dreams.prefix(3).enumerated() {
            if index > 0 {
                content += "\n---\n\n"
            }
            
            content += "# \(dream.title)\n\n"
            
            if options.includeMetadata {
                content += "**日期**: \(formatDate(dream.date))\n"
                if !dream.tags.isEmpty {
                    content += "**标签**: \(dream.tags.prefix(5).joined(separator: ", "))\n"
                }
                if let mood = dream.mood {
                    content += "**情绪**: \(mood.displayName)\n"
                }
                content += "\n"
            }
            
            content += "\(dream.content.prefix(300))"
            if dream.content.count > 300 {
                content += "..."
            }
            content += "\n"
        }
        
        if dreams.count > 3 {
            content += "\n... 还有 \(dreams.count - 3) 个梦境\n"
        }
        
        return content
    }
    
    /// 生成 JSON 预览
    private func generateJSONPreview(dreams: [Dream], options: ExportOptions) async throws -> String {
        let previewDreams = dreams.prefix(2).map { dream in
            return [
                "title": dream.title,
                "date": formatDate(dream.date),
                "content": String(dream.content.prefix(200)) + "...",
                "mood": dream.mood?.rawValue ?? "unknown",
                "tags": Array(dream.tags.prefix(5))
            ]
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(previewDreams)
        var content = String(data: data, encoding: .utf8) ?? "[]"
        
        if dreams.count > 2 {
            content += "\n// ... 还有 \(dreams.count - 2) 个梦境"
        }
        
        return content
    }
    
    /// 生成 HTML 预览
    private func generateHTMLPreview(dreams: [Dream], options: ExportOptions) async throws -> String {
        var content = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>梦境导出预览</title>
            <style>
                body { font-family: -apple-system, sans-serif; padding: 20px; }
                .dream { margin-bottom: 30px; padding-bottom: 20px; border-bottom: 1px solid #eee; }
                h1 { color: #333; }
                .meta { color: #666; font-size: 14px; }
                .content { line-height: 1.6; }
            </style>
        </head>
        <body>
        
        """
        
        for (index, dream) in dreams.prefix(2).enumerated() {
            content += """
            <div class="dream">
                <h1>\(dream.title)</h1>
                <div class="meta">
                    <p>日期：\(formatDate(dream.date))</p>
                    \(dream.mood != nil ? "<p>情绪：\(dream.mood!.displayName)</p>" : "")
                </div>
                <div class="content">
                    <p>\(dream.content.prefix(300))...</p>
                </div>
            </div>
            
            """
        }
        
        if dreams.count > 2 {
            content += "<p style='color: #999;'>... 还有 \(dreams.count - 2) 个梦境</p>\n"
        }
        
        content += """
        </body>
        </html>
        """
        
        return content
    }
    
    /// 获取待导出梦境
    private func getDreamsForExport(
        dreamIds: [UUID],
        exportAll: Bool,
        dateRange: DateRange?
    ) async throws -> [Dream] {
        var descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        if !dreamIds.isEmpty {
            descriptor.predicate = #Predicate<Dream> { dreamIds.contains($0.id) }
        } else if let dateRange = dateRange {
            descriptor.predicate = #Predicate<Dream> {
                $0.date >= dateRange.startDate && $0.date <= dateRange.endDate
            }
        } else if !exportAll {
            // 默认最近 30 天
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            descriptor.predicate = #Predicate<Dream> { $0.date >= thirtyDaysAgo }
        }
        
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - 导出预览模型

/// 导出预览结果
struct ExportPreview {
    let dreamCount: Int
    let totalCharacters: Int
    let estimatedFileSize: Int64
    let previewContent: String
    let platform: ExportPlatform
    let format: ExportFormat
    
    /// 格式化文件大小
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: estimatedFileSize)
    }
    
    /// 获取平台图标
    var platformIcon: String {
        platform.icon
    }
    
    /// 获取格式图标
    var formatIcon: String {
        switch format {
        case .markdown: return "📝"
        case .html: return "🌐"
        case .pdf: return "📕"
        case .json: return "📊"
        case .text: return "📄"
        case .rtf: return "📋"
        }
    }
}

// MARK: - ZIP 压缩辅助类

/// 简单的 ZIP 文件写入器
class FileZipWriter {
    private var zipURL: URL
    private var archive: ZIPArchive?
    
    init(zipURL: URL) throws {
        self.zipURL = zipURL
        self.archive = try ZIPArchive(url: zipURL)
    }
    
    func addFile(fileURL: URL, relativePath: String) throws {
        guard let archive = archive else {
            throw NSError(domain: "FileZipWriter", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Archive not initialized"
            ])
        }
        
        try archive.addFile(fileURL: fileURL, relativePath: relativePath)
    }
    
    func close() throws {
        try archive?.close()
        archive = nil
    }
}

/// ZIP 归档包装器
class ZIPArchive {
    private var archive: OpaquePointer?
    
    init(url: URL) throws {
        // 使用 libarchive 或自定义 ZIP 实现
        // 这里使用简化版本，实际项目中建议使用 ZIPFoundation 等成熟库
        let fileManager = FileManager.default
        
        // 创建空文件
        fileManager.createFile(atPath: url.path, contents: Data())
        
        // 注：完整的 ZIP 实现需要 libarchive 或 ZIPFoundation
        // 这里仅提供接口框架
    }
    
    func addFile(fileURL: URL, relativePath: String) throws {
        // 简化实现 - 实际应使用 ZIPFoundation
        // try archive.addEntry(relativePath, relativeTo: fileURL.deletingLastPathComponent)
    }
    
    func close() throws {
        // 清理资源
    }
}
