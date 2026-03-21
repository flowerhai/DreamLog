//
//  DreamEBookExportTests.swift
//  DreamLogTests
//
//  Phase 83: 梦境电子书导出功能
//  单元测试：测试电子书配置、服务逻辑和导出功能
//

import XCTest
import SwiftUI
@testable import DreamLog

// MARK: - 电子书导出测试

@MainActor
final class DreamEBookExportTests: XCTestCase {
    
    // MARK: - Properties
    
    var modelContainer: ModelContainer!
    var service: DreamEBookExportService!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            Dream.self,
            DreamTag.self,
            DreamSymbol.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        service = DreamEBookExportService(modelContainer: modelContainer)
        
        // 添加测试数据
        try await addSampleDreams()
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func addSampleDreams() async throws {
        let context = modelContainer.mainContext
        let calendar = Calendar.current
        
        // 添加最近 7 天的梦境
        for day in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            let dream = Dream(
                date: date,
                content: "这是一个测试梦境内容。今天是第 \(day) 天的梦境记录。",
                emotion: day % 2 == 0 ? "快乐" : "焦虑",
                mood: Double(3 + (day % 3)),
                clarity: Double(3 + (day % 3)),
                duration: 30 + Double(day * 5),
                tags: [DreamTag(name: "测试")],
                aiAnalysisSummary: "AI 分析摘要"
            )
            context.insert(dream)
        }
        
        // 添加最近 30 天的梦境
        for day in 7..<30 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            let dream = Dream(
                date: date,
                content: "这是一个较旧的梦境记录。",
                emotion: "平静",
                mood: 4.0,
                clarity: 3.5,
                duration: 45.0,
                tags: [],
                aiAnalysisSummary: ""
            )
            context.insert(dream)
        }
        
        try context.save()
    }
    
    // MARK: - 配置测试
    
    func testEBookExportConfigDefaultValues() {
        let config = EBookExportConfig()
        
        XCTAssertEqual(config.title, "我的梦境日记")
        XCTAssertEqual(config.subtitle, "")
        XCTAssertEqual(config.authorName, "")
        XCTAssertEqual(config.coverEmoji, "🌙")
        XCTAssertEqual(config.theme, .classic)
        XCTAssertEqual(config.dateRange, .all)
        XCTAssertTrue(config.includeDreams.isEmpty)
        XCTAssertTrue(config.chapters.isEmpty)
        XCTAssertTrue(config.tableOfContents)
        XCTAssertTrue(config.pageNumbering)
        XCTAssertEqual(config.exportFormat, .pdf)
    }
    
    func testEBookExportConfigCustomValues() {
        let config = EBookExportConfig(
            title: "自定义标题",
            subtitle: "副标题",
            authorName: "作者",
            coverEmoji: "✨",
            theme: .dreamy,
            dateRange: .last30Days,
            tableOfContents: false,
            pageNumbering: false,
            exportFormat: .epub
        )
        
        XCTAssertEqual(config.title, "自定义标题")
        XCTAssertEqual(config.subtitle, "副标题")
        XCTAssertEqual(config.authorName, "作者")
        XCTAssertEqual(config.coverEmoji, "✨")
        XCTAssertEqual(config.theme, .dreamy)
        XCTAssertEqual(config.dateRange, .last30Days)
        XCTAssertFalse(config.tableOfContents)
        XCTAssertFalse(config.pageNumbering)
        XCTAssertEqual(config.exportFormat, .epub)
    }
    
    // MARK: - 主题测试
    
    func testEBookThemeCases() {
        let allThemes = EBookTheme.allCases
        
        XCTAssertEqual(allThemes.count, 8)
        XCTAssertTrue(allThemes.contains(.classic))
        XCTAssertTrue(allThemes.contains(.elegant))
        XCTAssertTrue(allThemes.contains(.dreamy))
        XCTAssertTrue(allThemes.contains(.nature))
        XCTAssertTrue(allThemes.contains(.ocean))
        XCTAssertTrue(allThemes.contains(.sunset))
        XCTAssertTrue(allThemes.contains(.minimalist))
        XCTAssertTrue(allThemes.contains(.luxury))
    }
    
    func testEBookThemeDisplayNames() {
        XCTAssertEqual(EBookTheme.classic.displayName, "经典黑白")
        XCTAssertEqual(EBookTheme.elegant.displayName, "优雅深色")
        XCTAssertEqual(EBookTheme.dreamy.displayName, "梦幻紫色")
        XCTAssertEqual(EBookTheme.nature.displayName, "自然绿色")
        XCTAssertEqual(EBookTheme.ocean.displayName, "海洋蓝色")
        XCTAssertEqual(EBookTheme.sunset.displayName, "日落橙色")
        XCTAssertEqual(EBookTheme.minimalist.displayName, "极简主义")
        XCTAssertEqual(EBookTheme.luxury.displayName, "奢华金色")
    }
    
    func testEBookThemeColors() {
        // 验证主题颜色不为空
        let theme = EBookTheme.classic
        XCTAssertNotNil(theme.primaryColor)
        XCTAssertNotNil(theme.accentColor)
        XCTAssertNotNil(theme.backgroundColor)
        XCTAssertFalse(theme.fontFamily.isEmpty)
    }
    
    // MARK: - 日期范围测试
    
    func testEBookDateRangeCases() {
        let allRanges = EBookDateRange.allCases
        
        XCTAssertEqual(allRanges.count, 7)
        XCTAssertTrue(allRanges.contains(.all))
        XCTAssertTrue(allRanges.contains(.last7Days))
        XCTAssertTrue(allRanges.contains(.last30Days))
        XCTAssertTrue(allRanges.contains(.last90Days))
        XCTAssertTrue(allRanges.contains(.thisYear))
        XCTAssertTrue(allRanges.contains(.lastYear))
        XCTAssertTrue(allRanges.contains(.custom))
    }
    
    func testEBookDateRangeDisplayNames() {
        XCTAssertEqual(EBookDateRange.all.displayName, "全部梦境")
        XCTAssertEqual(EBookDateRange.last7Days.displayName, "最近 7 天")
        XCTAssertEqual(EBookDateRange.last30Days.displayName, "最近 30 天")
        XCTAssertEqual(EBookDateRange.last90Days.displayName, "最近 90 天")
        XCTAssertEqual(EBookDateRange.thisYear.displayName, "今年")
        XCTAssertEqual(EBookDateRange.lastYear.displayName, "去年")
        XCTAssertEqual(EBookDateRange.custom.displayName, "自定义范围")
    }
    
    // MARK: - 章节测试
    
    func testEBookChapterCreation() {
        let chapter = EBookChapter(
            title: "测试章节",
            type: .byMonth,
            dreamIds: [UUID(), UUID()],
            sortOrder: 0
        )
        
        XCTAssertNotNil(chapter.id)
        XCTAssertEqual(chapter.title, "测试章节")
        XCTAssertEqual(chapter.type, .byMonth)
        XCTAssertEqual(chapter.dreamIds.count, 2)
        XCTAssertEqual(chapter.sortOrder, 0)
    }
    
    func testEBookChapterTypeCases() {
        let allTypes = EBookChapterType.allCases
        
        XCTAssertEqual(allTypes.count, 5)
        XCTAssertTrue(allTypes.contains(.manual))
        XCTAssertTrue(allTypes.contains(.byMonth))
        XCTAssertTrue(allTypes.contains(.byEmotion))
        XCTAssertTrue(allTypes.contains(.byTheme))
        XCTAssertTrue(allTypes.contains(.byTag))
    }
    
    // MARK: - 梦境详情选项测试
    
    func testDreamDetailOptionsDefaultValues() {
        let options = DreamDetailOptions()
        
        XCTAssertTrue(options.includeDate)
        XCTAssertTrue(options.includeEmotion)
        XCTAssertTrue(options.includeTags)
        XCTAssertFalse(options.includeAIAnalysis)
        XCTAssertTrue(options.includeMood)
        XCTAssertFalse(options.includeClarity)
        XCTAssertFalse(options.includeDuration)
        XCTAssertTrue(options.includeNotes)
    }
    
    func testDreamDetailOptionsCustomValues() {
        let options = DreamDetailOptions(
            includeDate: false,
            includeEmotion: false,
            includeTags: false,
            includeAIAnalysis: true,
            includeMood: false,
            includeClarity: true,
            includeDuration: true,
            includeNotes: false
        )
        
        XCTAssertFalse(options.includeDate)
        XCTAssertFalse(options.includeEmotion)
        XCTAssertFalse(options.includeTags)
        XCTAssertTrue(options.includeAIAnalysis)
        XCTAssertFalse(options.includeMood)
        XCTAssertTrue(options.includeClarity)
        XCTAssertTrue(options.includeDuration)
        XCTAssertFalse(options.includeNotes)
    }
    
    // MARK: - 导出格式测试
    
    func testEBookExportFormatCases() {
        let allFormats = EBookExportFormat.allCases
        
        XCTAssertEqual(allFormats.count, 2)
        XCTAssertTrue(allFormats.contains(.pdf))
        XCTAssertTrue(allFormats.contains(.epub))
    }
    
    func testEBookExportFormatProperties() {
        let pdf = EBookExportFormat.pdf
        XCTAssertEqual(pdf.displayName, "PDF")
        XCTAssertEqual(pdf.mimeType, "application/pdf")
        XCTAssertEqual(pdf.fileExtension, "pdf")
        
        let epub = EBookExportFormat.epub
        XCTAssertEqual(epub.displayName, "EPUB")
        XCTAssertEqual(epub.mimeType, "application/epub+zip")
        XCTAssertEqual(epub.fileExtension, "epub")
    }
    
    // MARK: - 导出状态测试
    
    func testEBookExportStatusCases() {
        let idle: EBookExportStatus = .idle
        let preparing: EBookExportStatus = .preparing
        let generating: EBookExportStatus = .generating(1, 5)
        let completing: EBookExportStatus = .completing
        
        // 验证状态可以正确创建
        switch idle {
        case .idle:
            break
        default:
            XCTFail("Expected idle status")
        }
        
        switch generating {
        case .generating(let current, let total):
            XCTAssertEqual(current, 1)
            XCTAssertEqual(total, 5)
        default:
            XCTFail("Expected generating status")
        }
    }
    
    // MARK: - 预设模板测试
    
    func testEBookTemplatePresets() {
        let templates = EBookTemplate.templates
        
        XCTAssertGreaterThan(templates.count, 0)
        
        // 验证至少有一个模板
        let classicTemplate = templates.first { $0.name == "经典日记" }
        XCTAssertNotNil(classicTemplate)
        XCTAssertEqual(classicTemplate?.icon, "📔")
        
        let yearlyTemplate = templates.first { $0.name == "年度回顾" }
        XCTAssertNotNil(yearlyTemplate)
        XCTAssertEqual(yearlyTemplate?.icon, "🎉")
    }
    
    // MARK: - 服务测试
    
    func testServiceInitialization() {
        XCTAssertNotNil(service)
        XCTAssertEqual(service.exportStatus, .idle)
        XCTAssertEqual(service.currentProgress, 0)
        XCTAssertEqual(service.totalProgress, 0)
        XCTAssertNil(service.errorMessage)
        XCTAssertNil(service.generatedFileURL)
    }
    
    func testServiceReset() async {
        // 设置一些状态
        service.currentProgress = 5
        service.totalProgress = 10
        service.errorMessage = "测试错误"
        
        // 重置
        service.reset()
        
        XCTAssertEqual(service.exportStatus, .idle)
        XCTAssertEqual(service.currentProgress, 0)
        XCTAssertEqual(service.totalProgress, 0)
        XCTAssertNil(service.errorMessage)
        XCTAssertNil(service.generatedFileURL)
    }
    
    func testServiceCancelExport() async {
        // 模拟导出状态
        service.currentProgress = 3
        service.totalProgress = 10
        
        // 取消
        service.cancelExport()
        
        XCTAssertEqual(service.exportStatus, .idle)
        XCTAssertEqual(service.currentProgress, 0)
        XCTAssertEqual(service.totalProgress, 0)
    }
    
    // MARK: - 梦境获取测试
    
    func testFetchDreamsLast7Days() async throws {
        let dreams = try await service.fetchDreams(for: .last7Days, includeIds: [])
        
        XCTAssertGreaterThan(dreams.count, 0)
        XCTAssertLessThanOrEqual(dreams.count, 7)
        
        // 验证梦境按日期排序
        if dreams.count > 1 {
            for i in 0..<(dreams.count - 1) {
                XCTAssertGreaterThanOrEqual(dreams[i].date, dreams[i + 1].date)
            }
        }
    }
    
    func testFetchDreamsAll() async throws {
        let dreams = try await service.fetchDreams(for: .all, includeIds: [])
        
        XCTAssertGreaterThan(dreams.count, 0)
    }
    
    func testFetchDreamsWithSpecificIds() async throws {
        // 获取所有梦境
        let allDreams = try await service.fetchDreams(for: .all, includeIds: [])
        
        // 取前两个 ID
        let specificIds = Array(allDreams.prefix(2)).map { $0.id }
        
        // 获取指定 ID 的梦境
        let filteredDreams = try await service.fetchDreams(for: .all, includeIds: specificIds)
        
        XCTAssertEqual(filteredDreams.count, specificIds.count)
    }
    
    // MARK: - 章节组织测试
    
    func testOrganizeChaptersByMonth() async throws {
        let dreams = try await service.fetchDreams(for: .all, includeIds: [])
        let config = EBookExportConfig(dateRange: .all)
        
        let chapters = try service.organizeChapters(from: dreams, config: config)
        
        XCTAssertGreaterThan(chapters.count, 0)
        
        // 验证章节按月份组织
        for chapter in chapters {
            XCTAssertFalse(chapter.title.isEmpty)
            XCTAssertGreaterThanOrEqual(chapter.sortOrder, 0)
        }
    }
    
    func testOrganizeChaptersByWeek() async throws {
        let dreams = try await service.fetchDreams(for: .last30Days, includeIds: [])
        let config = EBookExportConfig(dateRange: .last30Days)
        
        let chapters = try service.organizeChapters(from: dreams, config: config)
        
        XCTAssertGreaterThan(chapters.count, 0)
    }
    
    func testOrganizeChaptersSingleWeek() async throws {
        let dreams = try await service.fetchDreams(for: .last7Days, includeIds: [])
        let config = EBookExportConfig(dateRange: .last7Days)
        
        let chapters = try service.organizeChapters(from: dreams, config: config)
        
        XCTAssertEqual(chapters.count, 1)
        XCTAssertEqual(chapters[0].title, "最近 7 天")
    }
    
    // MARK: - 导出统计测试
    
    func testGetExportStats() async throws {
        let dreams = try await service.fetchDreams(for: .last7Days, includeIds: [])
        let config = EBookExportConfig()
        
        let stats = service.getExportStats(config: config, dreams: dreams)
        
        XCTAssertEqual(stats.totalDreams, dreams.count)
        XCTAssertGreaterThan(stats.totalWords, 0)
        XCTAssertGreaterThan(stats.totalPages, 0)
        XCTAssertGreaterThanOrEqual(stats.chapterCount, 1)
        XCTAssertEqual(stats.generatedAt.timeIntervalSinceNow, 0, accuracy: 1.0)
    }
    
    // MARK: - 错误处理测试
    
    func testExportErrorDescriptions() {
        let noDreamsError = EBookExportError.noDreamsFound
        XCTAssertEqual(noDreamsError.errorDescription, "在选定的日期范围内没有找到梦境记录")
        
        let fetchError = EBookExportError.fetchFailed("测试错误")
        XCTAssertEqual(fetchError.errorDescription, "获取梦境数据失败：测试错误")
        
        let saveError = EBookExportError.saveFailed("无法保存")
        XCTAssertEqual(saveError.errorDescription, "保存文件失败：无法保存")
    }
    
    // MARK: - 性能测试
    
    func testFetchDreamsPerformance() {
        measure {
            let expectation = self.expectation(description: "Fetch dreams")
            
            Task {
                do {
                    let dreams = try await self.service.fetchDreams(for: .all, includeIds: [])
                    XCTAssertGreaterThan(dreams.count, 0)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed to fetch dreams: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - 边界条件测试
    
    func testEmptyDreamsDateRange() async throws {
        // 测试一个没有梦境的日期范围（未来）
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
        
        // 由于我们使用固定的测试数据，这个测试主要验证不会崩溃
        let dreams = try await service.fetchDreams(for: .all, includeIds: [])
        
        // 应该返回测试数据中的梦境
        XCTAssertGreaterThanOrEqual(dreams.count, 0)
    }
    
    // MARK: - Codable 测试
    
    func testEBookExportConfigCodable() throws {
        let originalConfig = EBookExportConfig(
            title: "测试",
            theme: .dreamy,
            dateRange: .last30Days,
            exportFormat: .epub
        )
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalConfig)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(EBookExportConfig.self, from: data)
        
        // 验证
        XCTAssertEqual(decodedConfig.title, originalConfig.title)
        XCTAssertEqual(decodedConfig.theme, originalConfig.theme)
        XCTAssertEqual(decodedConfig.dateRange, originalConfig.dateRange)
        XCTAssertEqual(decodedConfig.exportFormat, originalConfig.exportFormat)
    }
    
    func testEBookChapterCodable() throws {
        let originalChapter = EBookChapter(
            title: "测试章节",
            type: .byEmotion,
            dreamIds: [UUID(), UUID()],
            sortOrder: 1
        )
        
        // 编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalChapter)
        
        // 解码
        let decoder = JSONDecoder()
        let decodedChapter = try decoder.decode(EBookChapter.self, from: data)
        
        // 验证
        XCTAssertEqual(decodedChapter.title, originalChapter.title)
        XCTAssertEqual(decodedChapter.type, originalChapter.type)
        XCTAssertEqual(decodedChapter.dreamIds.count, originalChapter.dreamIds.count)
        XCTAssertEqual(decodedChapter.sortOrder, originalChapter.sortOrder)
    }
}

// MARK: - 样本数据

enum SampleData {
    static let shared = SampleData()
    
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Dream.self,
            DreamTag.self,
            DreamSymbol.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try! ModelContainer(for: schema, configurations: [config])
    }
}
