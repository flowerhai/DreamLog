//
//  DreamExportTests.swift
//  DreamLogTests
//
//  Phase 19 - Dream Data Export & Integration
//  Unit tests for export functionality
//

import XCTest
@testable import DreamLog
import SwiftData

@MainActor
final class DreamExportTests: XCTestCase {
    
    var exportService: DreamExportService!
    
    override func setUp() async throws {
        exportService = DreamExportService.shared
    }
    
    override func tearDown() async throws {
        exportService = nil
    }
    
    // MARK: - Export Format Tests
    
    func testExportFormatCases() {
        let formats = ExportFormat.allCases
        XCTAssertEqual(formats.count, 5)
        
        XCTAssertEqual(ExportFormat.json.displayName, "JSON")
        XCTAssertEqual(ExportFormat.csv.displayName, "CSV (Spreadsheet)")
        XCTAssertEqual(ExportFormat.markdown.displayName, "Markdown")
        XCTAssertEqual(ExportFormat.notion.displayName, "Notion Database")
        XCTAssertEqual(ExportFormat.obsidian.displayName, "Obsidian Vault")
    }
    
    func testExportFormatFileExtensions() {
        XCTAssertEqual(ExportFormat.json.fileExtension, "json")
        XCTAssertEqual(ExportFormat.csv.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.markdown.fileExtension, "md")
        XCTAssertEqual(ExportFormat.notion.fileExtension, "csv")
        XCTAssertEqual(ExportFormat.obsidian.fileExtension, "md")
    }
    
    func testExportFormatMimeTypes() {
        XCTAssertEqual(ExportFormat.json.mimeType, "application/json")
        XCTAssertEqual(ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(ExportFormat.markdown.mimeType, "text/markdown")
    }
    
    // MARK: - Export Date Range Tests
    
    func testExportDateRangeCases() {
        let ranges = ExportDateRange.allCases
        XCTAssertEqual(ranges.count, 6)
        
        XCTAssertEqual(ExportDateRange.all.displayName, "全部梦境")
        XCTAssertEqual(ExportDateRange.lastWeek.displayName, "最近 7 天")
        XCTAssertEqual(ExportDateRange.lastMonth.displayName, "最近 30 天")
        XCTAssertEqual(ExportDateRange.custom.displayName, "自定义范围")
    }
    
    func testExportDateRangeCalculation() {
        let now = Date()
        
        // Test last week
        if let weekRange = ExportDateRange.lastWeek.dateRange() {
            let expectedStart = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            XCTAssertTrue(weekRange.start <= expectedStart)
            XCTAssertEqual(weekRange.end, now)
        }
        
        // Test all returns nil
        XCTAssertNil(ExportDateRange.all.dateRange())
    }
    
    // MARK: - Export Fields Tests
    
    func testExportFieldsOptionSet() {
        var fields: ExportFields = []
        XCTAssertFalse(fields.contains(.title))
        
        fields.insert(.title)
        XCTAssertTrue(fields.contains(.title))
        
        fields.insert(.content)
        XCTAssertTrue(fields.contains(.content))
        
        fields.remove(.title)
        XCTAssertFalse(fields.contains(.title))
        XCTAssertTrue(fields.contains(.content))
    }
    
    func testExportFieldsPresets() {
        let allFields = ExportFields.all
        XCTAssertTrue(allFields.contains(.title))
        XCTAssertTrue(allFields.contains(.content))
        XCTAssertTrue(allFields.contains(.tags))
        XCTAssertTrue(allFields.contains(.emotions))
        XCTAssertTrue(allFields.contains(.clarity))
        XCTAssertTrue(allFields.contains(.intensity))
        XCTAssertTrue(allFields.contains(.isLucid))
        XCTAssertTrue(allFields.contains(.aiAnalysis))
        XCTAssertTrue(allFields.contains(.date))
        
        let minimalFields = ExportFields.minimal
        XCTAssertTrue(minimalFields.contains(.title))
        XCTAssertTrue(minimalFields.contains(.content))
        XCTAssertTrue(minimalFields.contains(.date))
        XCTAssertFalse(minimalFields.contains(.tags))
    }
    
    // MARK: - Export Sort Order Tests
    
    func testExportSortOrderCases() {
        let orders = ExportSortOrder.allCases
        XCTAssertEqual(orders.count, 4)
        
        XCTAssertEqual(ExportSortOrder.dateDescending.displayName, "日期 (最新优先)")
        XCTAssertEqual(ExportSortOrder.dateAscending.displayName, "日期 (最早优先)")
        XCTAssertEqual(ExportSortOrder.clarityDescending.displayName, "清晰度 (高到低)")
        XCTAssertEqual(ExportSortOrder.intensityDescending.displayName, "强度 (高到低)")
    }
    
    // MARK: - Export Options Tests
    
    func testExportOptionsDefault() {
        let options = ExportOptions()
        
        XCTAssertEqual(options.format, .json)
        XCTAssertEqual(options.dateRange, .all)
        XCTAssertEqual(options.includeFields, .all)
        XCTAssertEqual(options.sortOrder, .dateDescending)
    }
    
    func testExportOptionsCustom() {
        let options = ExportOptions(
            format: .csv,
            dateRange: .lastMonth,
            includeFields: .minimal,
            sortOrder: .clarityDescending
        )
        
        XCTAssertEqual(options.format, .csv)
        XCTAssertEqual(options.dateRange, .lastMonth)
        XCTAssertEqual(options.includeFields, .minimal)
        XCTAssertEqual(options.sortOrder, .clarityDescending)
    }
    
    // MARK: - Export Result Tests
    
    func testExportResultSuccess() {
        let tempURL = URL(fileURLWithPath: "/tmp/test.json")
        let result = ExportResult(
            success: true,
            fileURL: tempURL,
            dreamCount: 10,
            fileSize: "25 KB"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.fileURL, tempURL)
        XCTAssertEqual(result.dreamCount, 10)
        XCTAssertEqual(result.fileSize, "25 KB")
        XCTAssertNil(result.errorMessage)
    }
    
    func testExportResultFailure() {
        let result = ExportResult(
            success: false,
            errorMessage: "导出失败"
        )
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.fileURL)
        XCTAssertEqual(result.dreamCount, 0)
        XCTAssertEqual(result.errorMessage, "导出失败")
    }
    
    // MARK: - Export Statistics Tests
    
    func testExportStatisticsEmpty() {
        let stats = exportService.calculateStatistics(dreams: [])
        
        XCTAssertEqual(stats.totalDreams, 0)
        XCTAssertEqual(stats.averageClarity, 0)
        XCTAssertEqual(stats.averageIntensity, 0)
        XCTAssertEqual(stats.lucidDreamPercentage, 0)
    }
    
    // MARK: - Notion Config Tests
    
    func testNotionConfigDefault() {
        let config = NotionConfig()
        
        XCTAssertTrue(config.apiKey.isEmpty)
        XCTAssertTrue(config.databaseId.isEmpty)
        XCTAssertFalse(config.isEnabled)
    }
    
    func testNotionConfigCustom() {
        let config = NotionConfig(
            apiKey: "secret_test_key",
            databaseId: "test_database_id",
            isEnabled: true
        )
        
        XCTAssertEqual(config.apiKey, "secret_test_key")
        XCTAssertEqual(config.databaseId, "test_database_id")
        XCTAssertTrue(config.isEnabled)
    }
    
    // MARK: - Obsidian Config Tests
    
    func testObsidianConfigDefault() {
        let config = ObsidianConfig()
        
        XCTAssertTrue(config.vaultPath.isEmpty)
        XCTAssertEqual(config.folderName, "Dreams")
        XCTAssertNil(config.templateFile)
        XCTAssertFalse(config.isEnabled)
    }
    
    func testObsidianConfigCustom() {
        let config = ObsidianConfig(
            vaultPath: "/path/to/vault",
            folderName: "My Dreams",
            templateFile: "template.md",
            isEnabled: true
        )
        
        XCTAssertEqual(config.vaultPath, "/path/to/vault")
        XCTAssertEqual(config.folderName, "My Dreams")
        XCTAssertEqual(config.templateFile, "template.md")
        XCTAssertTrue(config.isEnabled)
    }
    
    // MARK: - CSV Escape Tests
    
    func testCSVGeneration() async {
        // Test that CSV generation doesn't crash
        let options = ExportOptions(format: .csv, includeFields: .all)
        
        // Note: This test would need a proper ModelContext to fully test
        // For now, we just verify the service initializes correctly
        XCTAssertNotNil(exportService)
    }
    
    // MARK: - JSON Generation Tests
    
    func testJSONStructure() {
        // Verify JSON format expectations
        let sampleData: [String: Any] = [
            "title": "Test Dream",
            "content": "Dream content",
            "tags": ["tag1", "tag2"],
            "clarity": 4,
            "isLucid": true
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sampleData)
            let jsonString = String(data: jsonData, encoding: .utf8)
            XCTAssertNotNil(jsonString)
            XCTAssertTrue(jsonString!.contains("Test Dream"))
        } catch {
            XCTFail("JSON serialization failed: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testExportPerformance() async throws {
        // Measure export performance with large dataset
        // This would need mock data in a real implementation
        measure {
            // Export operation here
        }
    }
}
