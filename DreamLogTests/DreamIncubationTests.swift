//
//  DreamIncubationTests.swift
//  DreamLogTests - 梦境孵化功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamIncubationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamIncubationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: DreamIncubation.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
        service = DreamIncubationService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 数据模型测试
    
    /// 测试孵化类型枚举完整性
    func testIncubationTargetTypeAllCases() {
        let allCases = IncubationTargetType.allCases
        XCTAssertEqual(allCases.count, 8, "应该有 8 种孵化类型")
        
        let expectedTypes: [IncubationTargetType] = [
            .problemSolving, .creativity, .emotionalHealing,
            .skillPractice, .exploration, .spiritual,
            .memory, .general
        ]
        
        for type in expectedTypes {
            XCTAssertTrue(allCases.contains(type), "应该包含 \(type.rawValue)")
            XCTAssertFalse(type.icon.isEmpty, "\(type.rawValue) 应该有图标")
            XCTAssertFalse(type.color.isEmpty, "\(type.rawValue) 应该有颜色")
            XCTAssertFalse(type.description.isEmpty, "\(type.rawValue) 应该有描述")
        }
    }
    
    /// 测试孵化强度枚举
    func testIncubationIntensityAllCases() {
        let allCases = IncubationIntensity.allCases
        XCTAssertEqual(allCases.count, 4, "应该有 4 种强度等级")
        
        XCTAssertEqual(IncubationIntensity.light.rawValue, 1)
        XCTAssertEqual(IncubationIntensity.moderate.rawValue, 2)
        XCTAssertEqual(IncubationIntensity.strong.rawValue, 3)
        XCTAssertEqual(IncubationIntensity.intense.rawValue, 4)
        
        // 测试推荐时长
        XCTAssertEqual(IncubationIntensity.light.recommendedDuration, 2)
        XCTAssertEqual(IncubationIntensity.moderate.recommendedDuration, 10)
        XCTAssertEqual(IncubationIntensity.strong.recommendedDuration, 20)
        XCTAssertEqual(IncubationIntensity.intense.recommendedDuration, 30)
    }
    
    /// 测试 DreamIncubation 模型初始化
    func testDreamIncubationInitialization() {
        let incubation = DreamIncubation(
            targetType: .creativity,
            title: "测试标题",
            intention: "测试意图",
            intensity: .moderate,
            tags: ["创意", "写作"],
            affirmations: ["肯定语 1", "肯定语 2"]
        )
        
        XCTAssertNotNil(incubation.id)
        XCTAssertEqual(incubation.title, "测试标题")
        XCTAssertEqual(incubation.intention, "测试意图")
        XCTAssertEqual(incubation.targetType, .creativity)
        XCTAssertEqual(incubation.intensity, .moderate)
        XCTAssertEqual(incubation.tags, ["创意", "写作"])
        XCTAssertEqual(incubation.affirmations, ["肯定语 1", "肯定语 2"])
        XCTAssertFalse(incubation.completed)
        XCTAssertNil(incubation.successRating)
    }
    
    /// 测试 DreamIncubation 持久化
    func testDreamIncubationPersistence() throws {
        let incubation = DreamIncubation(
            targetType: .problemSolving,
            title: "持久化测试",
            intention: "测试持久化"
        )
        
        modelContext.insert(incubation)
        try modelContext.save()
        
        let descriptor = FetchDescriptor<DreamIncubation>()
        let fetched = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "持久化测试")
    }
    
    // MARK: - 模板测试
    
    /// 测试预设模板
    func testIncubationTemplates() {
        let templates = IncubationTemplate.templates
        XCTAssertGreaterThan(templates.count, 0, "应该有预设模板")
        
        for template in templates {
            XCTAssertFalse(template.name.isEmpty, "模板应该有名称")
            XCTAssertFalse(template.defaultIntention.isEmpty, "模板应该有默认意图")
            XCTAssertGreaterThan(template.suggestedAffirmations.count, 0, "模板应该有肯定语")
            XCTAssertFalse(template.guidance.isEmpty, "模板应该有指南")
        }
        
        // 验证特定模板存在
        let templateNames = templates.map { $0.name }
        XCTAssertTrue(templateNames.contains("问题解决"))
        XCTAssertTrue(templateNames.contains("创意灵感"))
        XCTAssertTrue(templateNames.contains("清醒梦诱导"))
        XCTAssertTrue(templateNames.contains("情绪疗愈"))
        XCTAssertTrue(templateNames.contains("飞行体验"))
    }
    
    /// 测试从模板创建孵化
    func testCreateFromTemplate() async throws {
        let template = IncubationTemplate.templates.first!
        
        let incubation = try await service.createFromTemplate(template)
        
        XCTAssertEqual(incubation.targetType, template.targetType)
        XCTAssertEqual(incubation.title, template.name)
        XCTAssertEqual(incubation.intention, template.defaultIntention)
        XCTAssertEqual(incubation.intensity, template.recommendedIntensity)
    }
    
    // MARK: - 服务测试
    
    /// 测试服务初始化
    func testServiceInitialization() {
        XCTAssertNotNil(service)
        XCTAssertTrue(service.incubations.isEmpty)
        XCTAssertEqual(service.stats.totalIncubations, 0)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.error)
    }
    
    /// 测试创建孵化
    func testCreateIncubation() async throws {
        let incubation = try await service.createIncubation(
            targetType: .creativity,
            title: "创意孵化",
            intention: "获得创意灵感",
            intensity: .moderate,
            tags: ["创意"]
        )
        
        XCTAssertEqual(service.incubations.count, 1)
        XCTAssertEqual(service.incubations.first?.title, "创意孵化")
        XCTAssertEqual(service.stats.totalIncubations, 1)
    }
    
    /// 测试更新孵化
    func testUpdateIncubation() async throws {
        let incubation = try await service.createIncubation(
            targetType: .general,
            title: "原始标题",
            intention: "原始意图"
        )
        
        incubation.title = "更新后的标题"
        incubation.intention = "更新后的意图"
        
        try await service.updateIncubation(incubation)
        
        let updated = service.incubations.first { $0.id == incubation.id }
        XCTAssertEqual(updated?.title, "更新后的标题")
        XCTAssertEqual(updated?.intention, "更新后的意图")
    }
    
    /// 测试标记完成
    func testMarkAsCompleted() async throws {
        let incubation = try await service.createIncubation(
            targetType: .skillPractice,
            title: "技能练习",
            intention: "练习清醒梦"
        )
        
        XCTAssertFalse(incubation.completed)
        
        try await service.markAsCompleted(incubation, meditationMinutes: 15)
        
        XCTAssertTrue(incubation.completed)
        XCTAssertEqual(incubation.meditationMinutes, 15)
        XCTAssertNotNil(incubation.completedAt)
    }
    
    /// 测试删除孵化
    func testDeleteIncubation() async throws {
        let incubation = try await service.createIncubation(
            targetType: .general,
            title: "待删除",
            intention: "测试删除"
        )
        
        XCTAssertEqual(service.incubations.count, 1)
        
        try await service.deleteIncubation(incubation)
        
        XCTAssertEqual(service.incubations.count, 0)
    }
    
    /// 测试成功评级
    func testRecordSuccessRating() async throws {
        let incubation = try await service.createIncubation(
            targetType: .creativity,
            title: "创意测试",
            intention: "测试评级"
        )
        
        try await service.recordSuccessRating(incubation, rating: 4, notes: "很好的体验")
        
        XCTAssertEqual(incubation.successRating, 4)
        XCTAssertEqual(incubation.success, true)
        XCTAssertEqual(incubation.notes, "很好的体验")
    }
    
    /// 测试无效评级
    func testInvalidRating() async throws {
        let incubation = try await service.createIncubation(
            targetType: .general,
            title: "测试",
            intention: "测试"
        )
        
        do {
            try await service.recordSuccessRating(incubation, rating: 6)
            XCTFail("应该抛出错误")
        } catch IncubationError.invalidRating {
            // 预期错误
        } catch {
            XCTFail("应该抛出 IncubationError.invalidRating")
        }
    }
    
    // MARK: - 统计测试
    
    /// 测试统计数据计算
    func testStatsCalculation() async throws {
        // 创建多个孵化记录
        _ = try await service.createIncubation(targetType: .creativity, title: "1", intention: "i1")
        _ = try await service.createIncubation(targetType: .problemSolving, title: "2", intention: "i2")
        
        let incubation3 = try await service.createIncubation(targetType: .creativity, title: "3", intention: "i3")
        try await service.markAsCompleted(incubation3)
        try await service.recordSuccessRating(incubation3, rating: 5)
        
        service.calculateStats()
        
        XCTAssertEqual(service.stats.totalIncubations, 3)
        XCTAssertEqual(service.stats.completedIncubations, 1)
        XCTAssertEqual(service.stats.averageSuccessRating, 5.0)
        XCTAssertEqual(service.stats.successRate, 1.0)
    }
    
    /// 测试连续天数计算
    func testStreakCalculation() async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 创建今天的孵化
        let incubation1 = try await service.createIncubation(
            targetType: .general,
            title: "今天",
            intention: "今天",
            targetDate: today
        )
        try await service.markAsCompleted(incubation1)
        
        // 创建昨天的孵化
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let incubation2 = try await service.createIncubation(
            targetType: .general,
            title: "昨天",
            intention: "昨天",
            targetDate: yesterday
        )
        try await service.markAsCompleted(incubation2)
        
        service.calculateStats()
        
        XCTAssertEqual(service.stats.currentStreak, 2)
    }
    
    // MARK: - 筛选和搜索测试
    
    /// 测试按类型筛选
    func testFilterByType() async throws {
        _ = try await service.createIncubation(targetType: .creativity, title: "创意 1", intention: "i1")
        _ = try await service.createIncubation(targetType: .creativity, title: "创意 2", intention: "i2")
        _ = try await service.createIncubation(targetType: .problemSolving, title: "问题 1", intention: "i3")
        
        let creativityIncubations = service.filterByType(.creativity)
        XCTAssertEqual(creativityIncubations.count, 2)
        
        let problemIncubations = service.filterByType(.problemSolving)
        XCTAssertEqual(problemIncubations.count, 1)
    }
    
    /// 测试按完成状态筛选
    func testFilterByCompleted() async throws {
        let incubation1 = try await service.createIncubation(targetType: .general, title: "1", intention: "i1")
        let incubation2 = try await service.createIncubation(targetType: .general, title: "2", intention: "i2")
        
        try await service.markAsCompleted(incubation1)
        
        let completed = service.filterByCompleted(true)
        XCTAssertEqual(completed.count, 1)
        
        let notCompleted = service.filterByCompleted(false)
        XCTAssertEqual(notCompleted.count, 1)
    }
    
    /// 测试搜索
    func testSearch() async throws {
        _ = try await service.createIncubation(
            targetType: .creativity,
            title: "写作灵感",
            intention: "获得写作相关的灵感",
            tags: ["写作", "创意"]
        )
        
        _ = try await service.createIncubation(
            targetType: .problemSolving,
            title: "工作问题",
            intention: "解决工作上的难题",
            tags: ["工作", "问题"]
        )
        
        // 按标题搜索
        let writingResults = service.search("写作")
        XCTAssertEqual(writingResults.count, 1)
        
        // 按意图搜索
        let workResults = service.search("工作")
        XCTAssertEqual(workResults.count, 1)
        
        // 按标签搜索
        let creativeResults = service.search("创意")
        XCTAssertEqual(creativeResults.count, 1)
    }
    
    // MARK: - 指南测试
    
    /// 测试孵化指南生成
    func testGuidanceGeneration() {
        let guidance = service.getGuidance(for: .creativity, intensity: .moderate)
        
        XCTAssertFalse(guidance.isEmpty)
        XCTAssertTrue(guidance.contains("创意"))
        XCTAssertTrue(guidance.contains("🧘"))
    }
    
    /// 测试肯定语生成
    func testAffirmationsGeneration() {
        let affirmations = service.generateAffirmations(for: .creativity)
        
        XCTAssertGreaterThan(affirmations.count, 0)
        
        for affirmation in affirmations {
            XCTAssertFalse(affirmation.isEmpty)
        }
    }
    
    // MARK: - 性能测试
    
    /// 测试批量创建性能
    func testBulkCreationPerformance() async throws {
        let count = 50
        var incubations: [DreamIncubation] = []
        
        measure {
            let expectation = XCTestExpectation(description: "批量创建")
            
            Task {
                for i in 0..<count {
                    let incubation = try? await service.createIncubation(
                        targetType: .general,
                        title: "测试\(i)",
                        intention: "意图\(i)"
                    )
                    if let incubation = incubation {
                        incubations.append(incubation)
                    }
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30)
        }
        
        XCTAssertEqual(incubations.count, count)
    }
}

// MARK: - 错误类型测试

final class IncubationErrorTests: XCTestCase {
    
    func testErrorDescriptions() {
        XCTAssertEqual(IncubationError.invalidRating.errorDescription, "评级必须在 1-5 之间")
        XCTAssertEqual(IncubationError.invalidDate.errorDescription, "日期无效")
        XCTAssertEqual(IncubationError.notFound.errorDescription, "孵化记录未找到")
        XCTAssertEqual(IncubationError.saveFailed.errorDescription, "保存失败")
    }
}

// MARK: - 预览数据测试

final class DreamIncubationPreviewTests: XCTestCase {
    
    func testPreviewData() {
        let preview = DreamIncubation.preview
        
        XCTAssertEqual(preview.targetType, .creativity)
        XCTAssertEqual(preview.title, "获取写作灵感")
        XCTAssertTrue(preview.completed)
        XCTAssertEqual(preview.meditationMinutes, 15)
        XCTAssertEqual(preview.successRating, 4)
    }
}
