//
//  DreamExportHubTests.swift
//  DreamLog
//
//  Phase 52 - 梦境导出中心 - 单元测试
//  创建时间：2026-03-16
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17, *)
final class DreamExportHubTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([
            ExportTask.self,
            ExportHistory.self,
            Dream.self,
            DreamEmotion.self,
            DreamTag.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 导出平台测试
    
    func testExportPlatformCases() {
        // 测试所有平台枚举值
        let platforms: [ExportPlatform] = [
            .notion, .obsidian, .dayOne, .evernote, .bear,
            .appleNotes, .markdown, .pdf, .json,
            .email, .wechat, .custom
        ]
        
        XCTAssertEqual(platforms.count, 12)
        
        // 测试显示名称
        XCTAssertEqual(ExportPlatform.notion.displayName, "Notion")
        XCTAssertEqual(ExportPlatform.obsidian.displayName, "Obsidian")
        XCTAssertEqual(ExportPlatform.markdown.displayName, "Markdown")
        XCTAssertEqual(ExportPlatform.pdf.displayName, "PDF")
        
        // 测试图标
        XCTAssertEqual(ExportPlatform.notion.icon, "📓")
        XCTAssertEqual(ExportPlatform.obsidian.icon, "🪨")
        XCTAssertEqual(ExportPlatform.pdf.icon, "📕")
        
        // 测试描述
        XCTAssertFalse(ExportPlatform.notion.description.isEmpty)
        XCTAssertFalse(ExportPlatform.markdown.description.isEmpty)
        
        // 测试批量导出支持
        XCTAssertTrue(ExportPlatform.notion.supportsBatch)
        XCTAssertTrue(ExportPlatform.markdown.supportsBatch)
        XCTAssertFalse(ExportPlatform.wechat.supportsBatch)
        
        // 测试定时导出支持
        XCTAssertTrue(ExportPlatform.notion.supportsScheduled)
        XCTAssertTrue(ExportPlatform.email.supportsScheduled)
        XCTAssertFalse(ExportPlatform.pdf.supportsScheduled)
    }
    
    func testExportPlatformID() {
        // 测试平台 ID 唯一性
        let platforms = ExportPlatform.allCases
        let ids = platforms.map { $0.id }
        
        XCTAssertEqual(ids.count, Set(ids).count, "平台 ID 应该唯一")
    }
    
    // MARK: - 导出格式测试
    
    func testExportFormatCases() {
        let formats: [ExportFormat] = [
            .markdown, .html, .pdf, .json, .plainText, .richText
        ]
        
        XCTAssertEqual(formats.count, 6)
        
        // 测试文件扩展名
        XCTAssertEqual(ExportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(ExportFormat.html.fileExtension, "html")
        XCTAssertEqual(ExportFormat.pdf.fileExtension, "pdf")
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.plainText.fileExtension, "txt")
        XCTAssertEqual(ExportFormat.richText.fileExtension, "rtf")
    }
    
    // MARK: - 导出选项测试
    
    func testExportOptionsDefault() {
        let options = ExportOptions.default
        
        XCTAssertTrue(options.includeTitle)
        XCTAssertTrue(options.includeDate)
        XCTAssertFalse(options.includeTime)
        XCTAssertTrue(options.includeEmotions)
        XCTAssertTrue(options.includeTags)
        XCTAssertTrue(options.includeAIAnalysis)
        XCTAssertTrue(options.includeImages)
        XCTAssertFalse(options.includeAudio)
        XCTAssertTrue(options.includeLucidInfo)
        XCTAssertTrue(options.includeRating)
    }
    
    func testExportOptionsMinimal() {
        let options = ExportOptions.minimal
        
        XCTAssertTrue(options.includeTitle)
        XCTAssertTrue(options.includeDate)
        XCTAssertFalse(options.includeTime)
        XCTAssertFalse(options.includeEmotions)
        XCTAssertFalse(options.includeTags)
        XCTAssertFalse(options.includeAIAnalysis)
        XCTAssertFalse(options.includeImages)
        XCTAssertFalse(options.includeAudio)
        XCTAssertFalse(options.includeLucidInfo)
        XCTAssertFalse(options.includeRating)
    }
    
    func testExportOptionsDetailed() {
        let options = ExportOptions.detailed
        
        XCTAssertTrue(options.includeTitle)
        XCTAssertTrue(options.includeDate)
        XCTAssertTrue(options.includeTime)
        XCTAssertTrue(options.includeEmotions)
        XCTAssertTrue(options.includeTags)
        XCTAssertTrue(options.includeAIAnalysis)
        XCTAssertTrue(options.includeImages)
        XCTAssertTrue(options.includeAudio)
        XCTAssertTrue(options.includeLucidInfo)
        XCTAssertTrue(options.includeRating)
    }
    
    func testExportOptionsTemplates() {
        // 测试 Notion 模板
        let notionOptions = ExportOptions.notionTemplate
        XCTAssertTrue(notionOptions.includeAIAnalysis)
        XCTAssertTrue(notionOptions.includeImages)
        
        // 测试 Obsidian 模板
        let obsidianOptions = ExportOptions.obsidianTemplate
        XCTAssertEqual(obsidianOptions.dateFormat, "yyyy-MM-dd")
        
        // 测试 PDF 模板
        let pdfOptions = ExportOptions.pdfTemplate
        XCTAssertEqual(pdfOptions, ExportOptions.detailed)
        
        // 测试分享模板
        let shareOptions = ExportOptions.shareTemplate
        XCTAssertFalse(shareOptions.includeAIAnalysis)
        XCTAssertEqual(shareOptions.dateFormat, "MM/dd")
    }
    
    // MARK: - 导出任务模型测试
    
    func testExportTaskCreation() async throws {
        let task = ExportTask(
            name: "测试导出任务",
            platform: .markdown,
            format: .markdown,
            exportAll: true
        )
        
        XCTAssertEqual(task.name, "测试导出任务")
        XCTAssertEqual(task.platformEnum, .markdown)
        XCTAssertEqual(task.formatEnum, .markdown)
        XCTAssertTrue(task.exportAll)
        XCTAssertEqual(task.statusEnum, .pending)
        XCTAssertTrue(task.isEnabled)
        XCTAssertNil(task.scheduledTime)
        XCTAssertNil(task.repeatInterval)
        XCTAssertEqual(task.exportCount, 0)
    }
    
    func testExportTaskWithSchedule() async throws {
        let futureDate = Date().addingTimeInterval(3600) // 1 小时后
        
        let task = ExportTask(
            name: "定时导出任务",
            platform: .email,
            format: .plainText,
            exportAll: true,
            scheduledTime: futureDate,
            repeatInterval: "daily"
        )
        
        XCTAssertEqual(task.statusEnum, .scheduled)
        XCTAssertEqual(task.nextExportTime, futureDate)
        XCTAssertEqual(task.repeatInterval, "daily")
    }
    
    func testExportTaskWithOptions() async throws {
        let options = ExportOptions(
            includeEmotions: false,
            includeTags: false,
            includeAIAnalysis: true
        )
        
        let task = ExportTask(
            name: "自定义选项任务",
            platform: .pdf,
            options: options
        )
        
        let decodedOptions = task.exportOptions
        XCTAssertFalse(decodedOptions.includeEmotions)
        XCTAssertFalse(decodedOptions.includeTags)
        XCTAssertTrue(decodedOptions.includeAIAnalysis)
    }
    
    // MARK: - 导出状态测试
    
    func testExportStatusCases() {
        let statuses: [ExportStatus] = [
            .pending, .processing, .completed, .failed, .cancelled, .scheduled
        ]
        
        XCTAssertEqual(statuses.count, 6)
        
        // 测试显示名称
        XCTAssertEqual(ExportStatus.pending.displayName, "等待中")
        XCTAssertEqual(ExportStatus.processing.displayName, "处理中")
        XCTAssertEqual(ExportStatus.completed.displayName, "已完成")
        XCTAssertEqual(ExportStatus.failed.displayName, "失败")
        XCTAssertEqual(ExportStatus.cancelled.displayName, "已取消")
        XCTAssertEqual(ExportStatus.scheduled.displayName, "已计划")
        
        // 测试图标
        XCTAssertEqual(ExportStatus.pending.icon, "⏳")
        XCTAssertEqual(ExportStatus.processing.icon, "⚙️")
        XCTAssertEqual(ExportStatus.completed.icon, "✅")
        XCTAssertEqual(ExportStatus.failed.icon, "❌")
    }
    
    // MARK: - 日期范围测试
    
    func testDateRangeThisWeek() {
        let range = DateRange.thisWeek
        let calendar = Calendar.current
        
        // 本周开始应该是周一
        let weekday = calendar.component(.weekday, from: range.startDate)
        XCTAssertEqual(weekday, 2, "本周开始应该是周一") // 2 = Monday in Gregorian calendar
        
        // 本周结束应该是周日
        let endWeekday = calendar.component(.weekday, from: range.endDate)
        XCTAssertEqual(endWeekday, 1, "本周结束应该是周日") // 1 = Sunday in Gregorian calendar
    }
    
    func testDateRangeThisMonth() {
        let range = DateRange.thisMonth
        let calendar = Calendar.current
        
        // 本月开始应该是 1 号
        let day = calendar.component(.day, from: range.startDate)
        XCTAssertEqual(day, 1)
        
        // 本月结束应该是最后一天
        let nextMonth = calendar.date(byAdding: .day, value: 1, to: range.endDate)!
        let nextDay = calendar.component(.day, from: nextMonth)
        XCTAssertEqual(nextDay, 1, "结束日期应该是本月最后一天")
    }
    
    func testDateRangeLast30Days() {
        let range = DateRange.last30Days
        let calendar = Calendar.current
        
        let daysDiff = calendar.dateComponents([.day], from: range.startDate, to: range.endDate).day
        XCTAssertEqual(daysDiff, 30)
        
        // 结束日期应该是今天
        let now = Date()
        let nowDay = calendar.component(.day, from: now)
        let endDateDay = calendar.component(.day, from: range.endDate)
        XCTAssertEqual(nowDay, endDateDay, "结束日期应该是今天")
    }
    
    // MARK: - 导出统计测试
    
    func testExportStatsCalculation() {
        let stats = ExportStats(
            totalExports: 10,
            totalDreamsExported: 50,
            totalDataSize: 1024 * 1024 * 10, // 10MB
            exportsByPlatform: ["markdown": 5, "pdf": 3, "json": 2],
            exportsByFormat: ["md": 5, "pdf": 3, "json": 2],
            lastExportDate: Date()
        )
        
        XCTAssertEqual(stats.totalExports, 10)
        XCTAssertEqual(stats.totalDreamsExported, 50)
        XCTAssertEqual(stats.totalDataSize, 1024 * 1024 * 10)
        
        // 测试平均导出大小计算
        let expectedAverage = Double(1024 * 1024 * 10) / 10.0
        XCTAssertEqual(stats.averageExportSize, expectedAverage, accuracy: 0.01)
        
        // 测试平台分布
        XCTAssertEqual(stats.exportsByPlatform["markdown"], 5)
        XCTAssertEqual(stats.exportsByPlatform["pdf"], 3)
        XCTAssertEqual(stats.exportsByPlatform["json"], 2)
    }
    
    func testExportStatsEmpty() {
        let stats = ExportStats(
            totalExports: 0,
            totalDreamsExported: 0,
            totalDataSize: 0,
            exportsByPlatform: [:],
            exportsByFormat: [:],
            lastExportDate: nil
        )
        
        XCTAssertEqual(stats.averageExportSize, 0)
        XCTAssertTrue(stats.exportsByPlatform.isEmpty)
        XCTAssertNil(stats.lastExportDate)
    }
    
    // MARK: - 导出历史测试
    
    func testExportHistoryCreation() {
        let history = ExportHistory(
            platform: .markdown,
            format: .markdown,
            dreamCount: 5,
            fileSize: 1024 * 50, // 50KB
            filePath: "/path/to/export.md",
            status: .completed,
            duration: 2.5
        )
        
        XCTAssertEqual(history.platformEnum, .markdown)
        XCTAssertEqual(history.formatEnum, .markdown)
        XCTAssertEqual(history.dreamCount, 5)
        XCTAssertEqual(history.fileSize, 1024 * 50)
        XCTAssertEqual(history.statusEnum, .completed)
        XCTAssertEqual(history.duration, 2.5)
        XCTAssertNotNil(history.createdAt)
    }
    
    func testExportHistoryWithFailure() {
        let history = ExportHistory(
            platform: .pdf,
            format: .pdf,
            dreamCount: 0,
            status: .failed,
            errorMessage: "PDF 导出需要 DreamReflectionExportService 支持"
        )
        
        XCTAssertEqual(history.statusEnum, .failed)
        XCTAssertEqual(history.dreamCount, 0)
        XCTAssertEqual(history.errorMessage, "PDF 导出需要 DreamReflectionExportService 支持")
    }
    
    // MARK: - 导出服务测试
    
    func testCreateExportTask() async throws {
        let service = DreamExportHubService(modelContext: modelContext)
        
        let task = try await service.createExportTask(
            name: "测试任务",
            platform: .markdown,
            format: .markdown,
            exportAll: true
        )
        
        XCTAssertEqual(task.name, "测试任务")
        XCTAssertEqual(task.platformEnum, .markdown)
        XCTAssertNotNil(task.id)
        
        // 验证任务已保存
        let tasks = try await service.getAllExportTasks()
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.name, "测试任务")
    }
    
    func testToggleExportTask() async throws {
        let service = DreamExportHubService(modelContext: modelContext)
        
        let task = try await service.createExportTask(
            name: "可切换任务",
            platform: .markdown,
            exportAll: true
        )
        
        XCTAssertTrue(task.isEnabled)
        
        // 禁用任务
        try await service.toggleExportTask(task, enabled: false)
        XCTAssertFalse(task.isEnabled)
        XCTAssertEqual(task.statusEnum, .cancelled)
        
        // 重新启用任务
        try await service.toggleExportTask(task, enabled: true)
        XCTAssertTrue(task.isEnabled)
    }
    
    func testDeleteExportTask() async throws {
        let service = DreamExportHubService(modelContext: modelContext)
        
        let task = try await service.createExportTask(
            name: "待删除任务",
            platform: .json,
            exportAll: true
        )
        
        var tasks = try await service.getAllExportTasks()
        XCTAssertEqual(tasks.count, 1)
        
        try await service.deleteExportTask(task)
        
        tasks = try await service.getAllExportTasks()
        XCTAssertEqual(tasks.count, 0)
    }
    
    func testGetExportStats() async throws {
        let service = DreamExportHubService(modelContext: modelContext)
        
        // 创建一些导出历史
        let history1 = ExportHistory(
            platform: .markdown,
            format: .markdown,
            dreamCount: 5,
            fileSize: 1024 * 100
        )
        
        let history2 = ExportHistory(
            platform: .pdf,
            format: .pdf,
            dreamCount: 3,
            fileSize: 1024 * 200
        )
        
        modelContext.insert(history1)
        modelContext.insert(history2)
        try modelContext.save()
        
        let stats = try await service.getExportStats()
        
        XCTAssertEqual(stats.totalExports, 2)
        XCTAssertEqual(stats.totalDreamsExported, 8)
        XCTAssertEqual(stats.totalDataSize, 1024 * 300)
        XCTAssertEqual(stats.exportsByPlatform["markdown"], 1)
        XCTAssertEqual(stats.exportsByPlatform["pdf"], 1)
    }
    
    // MARK: - 性能测试
    
    func testExportTaskPerformance() async throws {
        let service = DreamExportHubService(modelContext: modelContext)
        
        // 创建 100 个导出任务
        let startTime = Date()
        
        for i in 0..<100 {
            _ = try await service.createExportTask(
                name: "性能测试任务 \(i)",
                platform: .markdown,
                exportAll: true
            )
        }
        
        let creationTime = Date().timeIntervalSince(startTime)
        
        // 验证创建时间应该小于 1 秒
        XCTAssertLessThan(creationTime, 1.0, "创建 100 个任务应该小于 1 秒")
        
        // 验证所有任务都已创建
        let tasks = try await service.getAllExportTasks()
        XCTAssertEqual(tasks.count, 100)
    }
    
    // MARK: - 边界条件测试
    
    func testEmptyTaskName() async throws {
        let service = DreamExportHubService(modelContext: modelContext)
        
        // 空名称应该允许创建（由 UI 层验证）
        let task = try await service.createExportTask(
            name: "",
            platform: .markdown,
            exportAll: true
        )
        
        XCTAssertEqual(task.name, "")
    }
    
    func testInvalidPlatform() {
        // 测试无效平台字符串的处理
        let invalidPlatform = ExportPlatform(rawValue: "invalid_platform")
        XCTAssertNil(invalidPlatform)
    }
    
    func testInvalidFormat() {
        // 测试无效格式字符串的处理
        let invalidFormat = ExportFormat(rawValue: "invalid_format")
        XCTAssertNil(invalidFormat)
    }
    
    func testInvalidStatus() {
        // 测试无效状态字符串的处理
        let invalidStatus = ExportStatus(rawValue: "invalid_status")
        XCTAssertNil(invalidStatus)
    }
}
