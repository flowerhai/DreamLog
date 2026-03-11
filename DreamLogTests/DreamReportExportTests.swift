//
//  DreamReportExportTests.swift
//  DreamLogTests
//
//  Phase 20: 梦境报告导出服务单元测试
//

import XCTest
@testable import DreamLog

@available(iOS 16.0, *)
final class DreamReportExportTests: XCTestCase {
    
    var exportService: DreamReportExportService!
    
    override func setUp() async throws {
        try await super.setUp()
        exportService = DreamReportExportService.shared
    }
    
    override func tearDown() async throws {
        exportService = nil
        try await super.tearDown()
    }
    
    // MARK: - PDF 导出测试
    
    func testExportPDFReport() async throws {
        let dreams = createSampleDreams(count: 10)
        let config = ExportConfig(
            includeCover: true,
            includeTableOfContents: true,
            includeStatistics: true,
            includeAIAnalysis: true,
            includeImages: false,
            style: .modern,
            pageSize: .a4
        )
        
        let result = try await exportService.exportPDFReport(
            dreams: dreams,
            config: config,
            dateRange: .last30Days
        )
        
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result.fileSize, 0)
        XCTAssertFalse(result.filePath.isEmpty)
        XCTAssertEqual(result.dreamCount, dreams.count)
        
        // 验证文件存在
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: result.filePath))
    }
    
    func testExportPDFWithDifferentStyles() async throws {
        let dreams = createSampleDreams(count: 5)
        let styles: [ExportStyle] = [.minimal, .classic, .artistic, .modern, .nature, .sunset, .ocean, .forest]
        
        for style in styles {
            let config = ExportConfig(style: style)
            let result = try await exportService.exportPDFReport(
                dreams: dreams,
                config: config,
                dateRange: .last30Days
            )
            
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result.fileSize, 0)
        }
    }
    
    func testExportPDFWithDifferentPageSizes() async throws {
        let dreams = createSampleDreams(count: 5)
        let pageSizes: [PageSize] = [.a4, .letter, .square]
        
        for pageSize in pageSizes {
            let config = ExportConfig(pageSize: pageSize)
            let result = try await exportService.exportPDFReport(
                dreams: dreams,
                config: config,
                dateRange: .last30Days
            )
            
            XCTAssertNotNil(result)
            XCTAssertGreaterThan(result.fileSize, 0)
        }
    }
    
    func testExportPDFWithEmptyData() async throws {
        let config = ExportConfig()
        
        let result = try await exportService.exportPDFReport(
            dreams: [],
            config: config,
            dateRange: .last30Days
        )
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result.dreamCount, 0)
    }
    
    // MARK: - 导出配置测试
    
    func testExportConfigDefaults() {
        let config = ExportConfig()
        
        XCTAssertTrue(config.includeCover)
        XCTAssertTrue(config.includeTableOfContents)
        XCTAssertTrue(config.includeStatistics)
        XCTAssertTrue(config.includeAIAnalysis)
        XCTAssertFalse(config.includeImages)
        XCTAssertEqual(config.style, .modern)
        XCTAssertEqual(config.pageSize, .a4)
    }
    
    func testExportConfigCustomization() {
        let config = ExportConfig(
            includeCover: false,
            includeTableOfContents: false,
            includeStatistics: true,
            includeAIAnalysis: false,
            includeImages: true,
            style: .classic,
            pageSize: .letter
        )
        
        XCTAssertFalse(config.includeCover)
        XCTAssertFalse(config.includeTableOfContents)
        XCTAssertTrue(config.includeStatistics)
        XCTAssertFalse(config.includeAIAnalysis)
        XCTAssertTrue(config.includeImages)
        XCTAssertEqual(config.style, .classic)
        XCTAssertEqual(config.pageSize, .letter)
    }
    
    // MARK: - 日期范围测试
    
    func testExportWithDifferentDateRanges() async throws {
        let dreams = createSampleDreams(count: 100)
        let dateRanges: [ExportDateRange] = [
            .last7Days,
            .last30Days,
            .last3Months,
            .lastYear,
            .all
        ]
        
        for range in dateRanges {
            let config = ExportConfig()
            let result = try await exportService.exportPDFReport(
                dreams: dreams,
                config: config,
                dateRange: range
            )
            
            XCTAssertNotNil(result)
        }
    }
    
    func testExportWithCustomDateRange() async throws {
        let dreams = createSampleDreams(count: 50)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -15, to: endDate) ?? Date()
        
        let config = ExportConfig()
        let result = try await exportService.exportPDFReport(
            dreams: dreams,
            config: config,
            dateRange: .custom(start: startDate, end: endDate)
        )
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - 统计信息测试
    
    func testGenerateStatistics() async throws {
        let dreams = createSampleDreams(count: 30)
        
        let stats = await exportService.generateStatistics(from: dreams)
        
        XCTAssertEqual(stats.totalDreams, dreams.count)
        XCTAssertGreaterThanOrEqual(stats.lucidPercentage, 0)
        XCTAssertLessThanOrEqual(stats.lucidPercentage, 100)
        XCTAssertGreaterThanOrEqual(stats.averageClarity, 1.0)
        XCTAssertLessThanOrEqual(stats.averageClarity, 5.0)
        XCTAssertGreaterThan(stats.topTags.count, 0)
        XCTAssertFalse(stats.dominantEmotion.isEmpty)
    }
    
    func testGenerateStatisticsWithEmptyData() async throws {
        let stats = await exportService.generateStatistics(from: [])
        
        XCTAssertEqual(stats.totalDreams, 0)
        XCTAssertEqual(stats.lucidPercentage, 0)
        XCTAssertEqual(stats.averageClarity, 0)
        XCTAssertEqual(stats.averageIntensity, 0)
        XCTAssertEqual(stats.topTags.count, 0)
        XCTAssertTrue(stats.dominantEmotion.isEmpty)
    }
    
    // MARK: - 封面页生成测试
    
    func testGenerateCoverPage() async throws {
        let stats = await exportService.generateStatistics(from: createSampleDreams(count: 20))
        
        let coverData = await exportService.generateCoverPageData(statistics: stats)
        
        XCTAssertFalse(coverData.title.isEmpty)
        XCTAssertFalse(coverData.subtitle.isEmpty)
        XCTAssertEqual(coverData.totalDreams, stats.totalDreams)
        XCTAssertFalse(coverData.dateRange.isEmpty)
    }
    
    // MARK: - 目录页生成测试
    
    func testGenerateTableOfContents() async throws {
        let dreams = createSampleDreams(count: 10)
        
        let toc = await exportService.generateTableOfContents(dreams: dreams)
        
        XCTAssertGreaterThan(toc.count, 0)
        
        for item in toc {
            XCTAssertFalse(item.title.isEmpty)
            XCTAssertGreaterThanOrEqual(item.pageNumber, 1)
        }
    }
    
    // MARK: - 样式枚举测试
    
    func testExportStyleCases() {
        let allStyles: [ExportStyle] = [.minimal, .classic, .artistic, .modern, .nature, .sunset, .ocean, .forest]
        
        for style in allStyles {
            XCTAssertFalse(style.rawValue.isEmpty)
            XCTAssertFalse(style.displayName.isEmpty)
            XCTAssertNotNil(style.primaryColor)
        }
    }
    
    func testPageSizeCases() {
        let allSizes: [PageSize] = [.a4, .letter, .square]
        
        for size in allSizes {
            XCTAssertGreaterThan(size.width, 0)
            XCTAssertGreaterThan(size.height, 0)
            XCTAssertFalse(size.displayName.isEmpty)
        }
    }
    
    // MARK: - 性能测试
    
    func testPerformancePDFExport() async throws {
        let dreams = createSampleDreams(count: 50)
        let config = ExportConfig()
        
        measure {
            let expectation = self.expectation(description: "PDF export complete")
            
            Task {
                _ = try? await exportService.exportPDFReport(
                    dreams: dreams,
                    config: config,
                    dateRange: .last30Days
                )
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 30.0)
        }
    }
    
    // MARK: - 错误处理测试
    
    func testExportWithInvalidConfig() async throws {
        let dreams = createSampleDreams(count: 5)
        
        // 测试极端配置
        let config = ExportConfig(
            includeCover: false,
            includeTableOfContents: false,
            includeStatistics: false,
            includeAIAnalysis: false,
            includeImages: false,
            style: .minimal,
            pageSize: .a4
        )
        
        // 即使所有选项都关闭，也应该能生成基本 PDF
        let result = try await exportService.exportPDFReport(
            dreams: dreams,
            config: config,
            dateRange: .last30Days
        )
        
        XCTAssertNotNil(result)
    }
    
    // MARK: - 辅助方法
    
    private func createSampleDreams(count: Int) -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        for i in 0..<count {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "这是一个测试梦境内容，包含详细的梦境描述和分析。",
                tags: ["测试", "样本", "梦境"].shuffled().prefix(2).map { String($0) },
                emotions: Emotion.allCases.shuffled().prefix(2),
                clarity: Int32(Int.random(in: 1...5)),
                intensity: Int32(Int.random(in: 1...5)),
                isLucid: Bool.random(),
                aiAnalysis: "这是 AI 生成的梦境解析内容。",
                date: date
            )
            dreams.append(dream)
        }
        
        return dreams
    }
}

// MARK: - ExportResult 测试

final class ExportResultTests: XCTestCase {
    
    func testExportResultInitialization() {
        let result = ExportResult(
            success: true,
            filePath: "/path/to/file.pdf",
            fileSize: 1024,
            dreamCount: 10,
            errorMessage: nil
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.filePath, "/path/to/file.pdf")
        XCTAssertEqual(result.fileSize, 1024)
        XCTAssertEqual(result.dreamCount, 10)
        XCTAssertNil(result.errorMessage)
    }
    
    func testExportResultWithSuccess() {
        let result = ExportResult.success(
            filePath: "/path/to/file.pdf",
            fileSize: 2048,
            dreamCount: 20
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.fileSize, 2048)
        XCTAssertNil(result.errorMessage)
    }
    
    func testExportResultWithFailure() {
        let result = ExportResult.failure(
            errorMessage: "导出失败：文件无法创建"
        )
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.errorMessage, "导出失败：文件无法创建")
    }
}
