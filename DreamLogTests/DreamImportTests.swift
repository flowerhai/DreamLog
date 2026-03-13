//
//  DreamImportTests.swift
//  DreamLogTests - 梦境导入中心单元测试
//
//  Phase 34: 梦境导入中心 - 支持多格式导入
//  Created: 2026-03-13 20:04 UTC
//

import Testing
import Foundation
import SwiftData
@testable import DreamLog

// MARK: - 导入模型测试

@Suite("DreamImportModels Tests")
struct DreamImportModelsTests {
    
    @Test("ImportSourceType 所有案例")
    func testImportSourceTypes() {
        let allTypes = ImportSourceType.allCases
        
        #expect(allTypes.count == 7)
        #expect(allTypes.contains(.json))
        #expect(allTypes.contains(.csv))
        #expect(allTypes.contains(.notion))
        #expect(allTypes.contains(.obsidian))
        #expect(allTypes.contains(.dreamJournal))
        #expect(allTypes.contains(.lucid))
        #expect(allTypes.contains(.other))
    }
    
    @Test("ImportSourceType 显示名称")
    func testImportSourceTypeDisplayNames() {
        #expect(ImportSourceType.json.displayName == "JSON 文件")
        #expect(ImportSourceType.csv.displayName == "CSV 文件")
        #expect(ImportSourceType.notion.displayName == "Notion 数据库")
        #expect(ImportSourceType.obsidian.displayName == "Obsidian 笔记")
    }
    
    @Test("ImportSourceType 支持的文件扩展名")
    func testImportSourceTypeExtensions() {
        #expect(ImportSourceType.json.supportedExtensions.contains("json"))
        #expect(ImportSourceType.csv.supportedExtensions.contains("csv"))
        #expect(ImportSourceType.obsidian.supportedExtensions.contains("md"))
        #expect(ImportSourceType.notion.supportedExtensions.count >= 2)
    }
    
    @Test("ImportStatus 所有状态")
    func testImportStatusValues() {
        #expect(ImportStatus.pending.rawValue == "pending")
        #expect(ImportStatus.processing.rawValue == "processing")
        #expect(ImportStatus.completed.rawValue == "completed")
        #expect(ImportStatus.partial.rawValue == "partial")
        #expect(ImportStatus.failed.rawValue == "failed")
        #expect(ImportStatus.cancelled.rawValue == "cancelled")
    }
    
    @Test("DreamImportResult 初始化")
    func testDreamImportResultInitialization() {
        let result = DreamImportResult(
            sourceId: "test-123",
            status: .completed,
            importedFields: ["content", "date"]
        )
        
        #expect(result.sourceId == "test-123")
        #expect(result.status == .completed)
        #expect(result.importedFields.count == 2)
        #expect(!result.isDuplicate)
        #expect(result.errorMessage == nil)
    }
    
    @Test("ImportSettings 默认值")
    func testImportSettingsDefaults() {
        let settings = ImportSettings()
        
        #expect(settings.skipDuplicates == true)
        #expect(settings.mergeDuplicates == false)
        #expect(settings.importTags == true)
        #expect(settings.importEmotions == true)
        #expect(settings.importAudio == true)
        #expect(settings.importImages == true)
        #expect(settings.autoAnalyze == false)
    }
    
    @Test("ImportSettings 自定义配置")
    func testImportSettingsCustomization() {
        let settings = ImportSettings(
            skipDuplicates: false,
            mergeDuplicates: true,
            importTags: false,
            autoAnalyze: true
        )
        
        #expect(settings.skipDuplicates == false)
        #expect(settings.mergeDuplicates == true)
        #expect(settings.importTags == false)
        #expect(settings.autoAnalyze == true)
    }
    
    @Test("ImportDreamData 初始化")
    func testImportDreamDataInitialization() {
        let data = ImportDreamData(
            id: "test-id",
            title: "测试梦境",
            content: "这是一个测试梦境内容",
            date: Date(),
            tags: ["标签 1", "标签 2"],
            emotions: ["开心", "兴奋"],
            clarity: 0.8,
            isLucid: true
        )
        
        #expect(data.id == "test-id")
        #expect(data.title == "测试梦境")
        #expect(data.content == "这是一个测试梦境内容")
        #expect(data.tags?.count == 2)
        #expect(data.emotions?.count == 2)
        #expect(data.clarity == 0.8)
        #expect(data.isLucid == true)
    }
    
    @Test("ImportPreview 初始化")
    func testImportPreviewInitialization() {
        let preview = ImportPreview(
            sourceType: .json,
            fileName: "test.json",
            itemCount: 100,
            estimatedSize: "1.5 MB"
        )
        
        #expect(preview.sourceType == .json)
        #expect(preview.fileName == "test.json")
        #expect(preview.itemCount == 100)
        #expect(preview.estimatedSize == "1.5 MB")
        #expect(preview.sampleItems.isEmpty)
        #expect(preview.potentialIssues.isEmpty)
    }
    
    @Test("ImportIssue 初始化")
    func testImportIssueInitialization() {
        let issue = ImportIssue(
            type: .largeFile,
            message: "文件过大",
            severity: .warning,
            affectedItems: 1000
        )
        
        #expect(issue.type == .largeFile)
        #expect(issue.message == "文件过大")
        #expect(issue.severity == .warning)
        #expect(issue.affectedItems == 1000)
    }
    
    @Test("ImportIssueSeverity 颜色")
    func testImportIssueSeverityColors() {
        #expect(ImportIssueSeverity.info.color == "blue")
        #expect(ImportIssueSeverity.warning.color == "orange")
        #expect(ImportIssueSeverity.error.color == "red")
        #expect(ImportIssueSeverity.critical.color == "purple")
    }
}

// MARK: - 导入服务测试

@Suite("DreamImportService Tests")
struct DreamImportServiceTests {
    
    @Test("服务单例初始化")
    func testServiceSingleton() {
        let service1 = DreamImportService.shared
        let service2 = DreamImportService.shared
        
        #expect(service1 === service2)
    }
    
    @Test("自定义 ModelContext 初始化")
    func testServiceWithCustomContext() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Dream.self, configurations: config)
        let context = ModelContext(container)
        
        let service = DreamImportService(modelContext: context)
        
        #expect(service != nil)
    }
    
    @Test("JSON 数据解析")
    @MainActor
    func testJSONParsing() async throws {
        let service = DreamImportService()
        
        // 创建测试 JSON 数据
        let jsonData = """
        [
            {
                "id": "1",
                "title": "测试梦境 1",
                "content": "这是一个测试梦境内容",
                "date": "2026-03-13T10:00:00Z",
                "tags": ["测试", "梦境"],
                "emotions": ["开心"]
            },
            {
                "id": "2",
                "title": "测试梦境 2",
                "content": "这是另一个测试梦境",
                "date": "2026-03-12T10:00:00Z",
                "tags": ["测试"],
                "isLucid": true
            }
        ]
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 2)
        #expect(items[0].title == "测试梦境 1")
        #expect(items[1].title == "测试梦境 2")
        #expect(items[0].tags?.count == 2)
        #expect(items[1].isLucid == true)
    }
    
    @Test("CSV 数据解析")
    @MainActor
    func testCSVParsing() async throws {
        let service = DreamImportService()
        
        let csvData = """
        id,title,content,date,tags
        1,测试梦境 1，这是一个测试，2026-03-13，测试，梦境
        2,测试梦境 2，这是另一个测试，2026-03-12，测试
        """.data(using: .utf8)!
        
        let items = try await service.parseCSV(data: csvData)
        
        #expect(items.count == 2)
        #expect(items[0].content.contains("这是一个测试"))
    }
    
    @Test("Markdown 数据解析")
    @MainActor
    func testMarkdownParsing() async throws {
        let service = DreamImportService()
        
        let markdownData = """
        # 梦境 1
        
        这是第一个梦境内容。
        
        2026-03-13
        
        ---
        
        # 梦境 2
        
        这是第二个梦境内容。
        
        2026-03-12
        
        ---
        
        # 梦境 3
        
        这是第三个梦境内容。
        """.data(using: .utf8)!
        
        let items = try await service.parseMarkdown(data: markdownData)
        
        #expect(items.count >= 2)
    }
    
    @Test("日期提取 - ISO8601 格式")
    @MainActor
    func testDateExtractionISO8601() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "content": "测试内容",
            "date": "2026-03-13T10:00:00Z"
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 1)
        #expect(items[0].date.timeIntervalSince1970 > 0)
    }
    
    @Test("日期提取 - 简单格式")
    @MainActor
    func testDateExtractionSimpleFormat() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "content": "测试内容",
            "date": "2026-03-13"
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 1)
    }
    
    @Test("标签提取")
    @MainActor
    func testTagExtraction() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "content": "测试内容",
            "tags": ["标签 1", "标签 2", "标签 3"]
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 1)
        #expect(items[0].tags?.count == 3)
        #expect(items[0].tags?.contains("标签 1") == true)
    }
    
    @Test("情绪提取")
    @MainActor
    func testEmotionExtraction() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "content": "测试内容",
            "emotions": ["开心", "兴奋", "期待"]
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 1)
        #expect(items[0].emotions?.count == 3)
    }
    
    @Test("清醒梦标志提取")
    @MainActor
    func testLucidFlagExtraction() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "content": "测试内容",
            "isLucid": true
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 1)
        #expect(items[0].isLucid == true)
    }
    
    @Test("清晰度提取")
    @MainActor
    func testClarityExtraction() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "content": "测试内容",
            "clarity": 0.85
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.count == 1)
        #expect(items[0].clarity == 0.85)
    }
    
    @Test("无效 JSON 处理")
    @MainActor
    func testInvalidJSONHandling() async throws {
        let service = DreamImportService()
        
        let invalidJsonData = """
        { invalid json }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: invalidJsonData)
        
        #expect(items.isEmpty)
    }
    
    @Test("空 JSON 数组处理")
    @MainActor
    func testEmptyJSONArrayHandling() async throws {
        let service = DreamImportService()
        
        let emptyJsonData = "[]".data(using: .utf8)!
        
        let items = try await service.parseJSON(data: emptyJsonData)
        
        #expect(items.isEmpty)
    }
    
    @Test("缺失内容字段处理")
    @MainActor
    func testMissingContentHandling() async throws {
        let service = DreamImportService()
        
        let jsonData = """
        {
            "id": "1",
            "title": "无内容梦境"
        }
        """.data(using: .utf8)!
        
        let items = try await service.parseJSON(data: jsonData)
        
        #expect(items.isEmpty) // 没有 content 字段应该被跳过
    }
    
    @Test("导入错误类型")
    func testImportErrorTypes() {
        let errors: [ImportError] = [
            .fileNotFound,
            .unsupportedFormat,
            .encodingError,
            .invalidFormat,
            .alreadyImporting,
            .parseError("测试错误"),
            .importFailed("测试失败")
        ]
        
        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }
}

// MARK: - 导入任务测试

@Suite("DreamImportTask Tests")
struct DreamImportTaskTests {
    
    @Test("任务初始化")
    func testTaskInitialization() {
        let task = DreamImportTask(
            name: "测试导入",
            sourceType: .json,
            totalItems: 100
        )
        
        #expect(task.name == "测试导入")
        #expect(task.sourceType == .json)
        #expect(task.totalItems == 100)
        #expect(task.status == .pending)
        #expect(task.progress == 0.0)
        #expect(task.successCount == 0)
        #expect(task.failureCount == 0)
    }
    
    @Test("任务进度百分比")
    func testTaskProgressPercentage() {
        let task = DreamImportTask(
            name: "测试",
            sourceType: .json
        )
        
        task.progress = 0.0
        #expect(task.progressPercentage == 0)
        
        task.progress = 0.5
        #expect(task.progressPercentage == 50)
        
        task.progress = 1.0
        #expect(task.progressPercentage == 100)
    }
    
    @Test("任务完成状态")
    func testTaskCompletionStatus() {
        var task = DreamImportTask(
            name: "测试",
            sourceType: .json
        )
        
        task.status = .pending
        #expect(!task.isCompleted)
        
        task.status = .processing
        #expect(!task.isCompleted)
        
        task.status = .completed
        #expect(task.isCompleted)
        
        task.status = .partial
        #expect(task.isCompleted)
        
        task.status = .failed
        #expect(task.isCompleted)
    }
    
    @Test("任务统计更新")
    func testTaskStatisticsUpdate() {
        let task = DreamImportTask(
            name: "测试",
            sourceType: .json,
            totalItems: 100
        )
        
        task.successCount = 80
        task.failureCount = 10
        task.duplicateCount = 10
        
        #expect(task.successCount + task.failureCount + task.duplicateCount == task.totalItems)
    }
}

// MARK: - 导入设置测试

@Suite("ImportSettings Tests")
struct ImportSettingsTests {
    
    @Test("设置编码和解码")
    func testSettingsCodable() throws {
        let original = ImportSettings(
            skipDuplicates: false,
            mergeDuplicates: true,
            importTags: false,
            importEmotions: false,
            autoAnalyze: true
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ImportSettings.self, from: data)
        
        #expect(decoded.skipDuplicates == original.skipDuplicates)
        #expect(decoded.mergeDuplicates == original.mergeDuplicates)
        #expect(decoded.importTags == original.importTags)
        #expect(decoded.autoAnalyze == original.autoAnalyze)
    }
    
    @Test("设置默认值验证")
    func testSettingsDefaultValues() {
        let settings = ImportSettings()
        
        // 默认应该跳过重复
        #expect(settings.skipDuplicates == true)
        // 默认不合并
        #expect(settings.mergeDuplicates == false)
        // 默认导入所有元数据
        #expect(settings.importTags == true)
        #expect(settings.importEmotions == true)
        #expect(settings.importAudio == true)
        #expect(settings.importImages == true)
        #expect(settings.importLocation == true)
        // 默认不自动分析
        #expect(settings.autoAnalyze == false)
    }
}

// MARK: - 辅助类型测试

@Suite("AnyCodable Tests")
struct AnyCodableTests {
    
    @Test("编码和解码字符串")
    func testStringEncoding() throws {
        let original = AnyCodable("测试字符串")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        #expect(decoded.value as? String == "测试字符串")
    }
    
    @Test("编码和解码数字")
    func testNumberEncoding() throws {
        let intVal = AnyCodable(42)
        let intData = try JSONEncoder().encode(intVal)
        let intDecoded = try JSONDecoder().decode(AnyCodable.self, from: intData)
        #expect(intDecoded.value as? Int == 42)
        
        let doubleVal = AnyCodable(3.14)
        let doubleData = try JSONEncoder().encode(doubleVal)
        let doubleDecoded = try JSONDecoder().decode(AnyCodable.self, from: doubleData)
        #expect((doubleDecoded.value as? Double).map { abs($0 - 3.14) < 0.001 } == true)
    }
    
    @Test("编码和解码数组")
    func testArrayEncoding() throws {
        let array = ["a", "b", "c"]
        let anyCodable = AnyCodable(array)
        let data = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        let decodedArray = decoded.value as? [String]
        #expect(decodedArray == array)
    }
    
    @Test("编码和解码字典")
    func testDictionaryEncoding() throws {
        let dict = ["key1": "value1", "key2": "value2"]
        let anyCodable = AnyCodable(dict)
        let data = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        let decodedDict = decoded.value as? [String: String]
        #expect(decodedDict == dict)
    }
    
    @Test("编码和解码 nil")
    func testNilEncoding() throws {
        let nilVal = AnyCodable(NSNull())
        let data = try JSONEncoder().encode(nilVal)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        
        #expect(decoded.value is NSNull)
    }
}
