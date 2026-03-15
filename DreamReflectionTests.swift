//
//  DreamReflectionTests.swift
//  DreamLogTests
//
//  梦境反思日记 - 单元测试
//  Phase 49: 梦境反思与洞察整合
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamReflectionTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamReflectionService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            DreamReflection.self,
            Dream.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: DreamReflection.self, Dream.self,
            configurations: [modelConfiguration]
        )
        
        modelContext = ModelContext(modelContainer)
        service = DreamReflectionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createTestDream() throws -> Dream {
        let dream = Dream(
            title: "测试梦境",
            content: "这是一个用于测试的梦境内容",
            date: Date(),
            tags: ["测试", "梦境"],
            emotions: [.happy],
            clarity: 4,
            intensity: 3,
            isLucid: false
        )
        modelContext.insert(dream)
        try modelContext.save()
        return dream
    }
    
    // MARK: - CRUD Tests
    
    /// 测试创建反思
    func testCreateReflection() async throws {
        let dream = try createTestDream()
        
        let reflection = try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "这是一个重要的洞察",
            tags: ["洞察", "成长"],
            rating: 5,
            isPrivate: false,
            relatedLifeEvents: ["最近工作压力大"],
            actionItems: ["多休息", "练习冥想"]
        )
        
        XCTAssertEqual(reflection.dreamId, dream.id)
        XCTAssertEqual(reflection.reflectionType, .insight)
        XCTAssertEqual(reflection.content, "这是一个重要的洞察")
        XCTAssertEqual(reflection.tags, ["洞察", "成长"])
        XCTAssertEqual(reflection.rating, 5)
        XCTAssertFalse(reflection.isPrivate)
        XCTAssertEqual(reflection.relatedLifeEvents, ["最近工作压力大"])
        XCTAssertEqual(reflection.actionItems, ["多休息", "练习冥想"])
        XCTAssertNotNil(reflection.id)
    }
    
    /// 测试更新反思
    func testUpdateReflection() async throws {
        let dream = try createTestDream()
        
        let reflection = try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "原始内容"
        )
        
        let updated = try await service.updateReflection(
            id: reflection.id,
            content: "更新后的内容",
            rating: 4,
            tags: ["新标签"]
        )
        
        XCTAssertEqual(updated.content, "更新后的内容")
        XCTAssertEqual(updated.rating, 4)
        XCTAssertEqual(updated.tags, ["新标签"])
        XCTAssertGreaterThan(updated.updatedAt, updated.createdAt)
    }
    
    /// 测试删除反思
    func testDeleteReflection() async throws {
        let dream = try createTestDream()
        
        let reflection = try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "待删除的反思"
        )
        
        try await service.deleteReflection(id: reflection.id)
        
        let fetched = try await service.fetchReflection(by: reflection.id)
        XCTAssertNil(fetched)
    }
    
    /// 测试批量删除反思
    func testDeleteReflectionsForDream() async throws {
        let dream = try createTestDream()
        
        // 创建 3 个反思
        for i in 1...3 {
            try await service.createReflection(
                dreamId: dream.id,
                type: .insight,
                content: "反思 \(i)"
            )
        }
        
        try await service.deleteReflections(for: dream.id)
        
        let reflections = try await service.fetchReflections(for: dream.id)
        XCTAssertEqual(reflections.count, 0)
    }
    
    // MARK: - Fetch Tests
    
    /// 测试获取单个反思
    func testFetchReflection() async throws {
        let dream = try createTestDream()
        
        let reflection = try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "测试内容"
        )
        
        let fetched = try await service.fetchReflection(by: reflection.id)
        
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, reflection.id)
        XCTAssertEqual(fetched?.content, "测试内容")
    }
    
    /// 测试获取梦境的所有反思
    func testFetchReflectionsForDream() async throws {
        let dream = try createTestDream()
        
        for i in 1...5 {
            try await service.createReflection(
                dreamId: dream.id,
                type: .insight,
                content: "反思 \(i)"
            )
        }
        
        let reflections = try await service.fetchReflections(for: dream.id)
        XCTAssertEqual(reflections.count, 5)
    }
    
    /// 测试获取所有反思（带筛选）
    func testFetchAllReflectionsWithFilters() async throws {
        let dream = try createTestDream()
        
        // 创建不同类型的反思
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "洞察 1", rating: 5)
        try await service.createReflection(dreamId: dream.id, type: .emotion, content: "情绪 1", rating: 3)
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "洞察 2", rating: 4, isPrivate: true)
        
        // 获取所有（不含私密）
        let allPublic = try await service.fetchAllReflections(includePrivate: false)
        XCTAssertEqual(allPublic.count, 2)
        
        // 获取所有（含私密）
        let all = try await service.fetchAllReflections(includePrivate: true)
        XCTAssertEqual(all.count, 3)
        
        // 按类型筛选
        let insights = try await service.fetchAllReflections(types: [.insight])
        XCTAssertEqual(insights.count, 2)
    }
    
    /// 测试搜索反思
    func testSearchReflections() async throws {
        let dream = try createTestDream()
        
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "关于工作的洞察", tags: ["工作"])
        try await service.createReflection(dreamId: dream.id, type: .emotion, content: "关于情感的探索", tags: ["情感"])
        try await service.createReflection(dreamId: dream.id, type: .question, content: "关于未来的问题", tags: ["未来"])
        
        // 按内容搜索
        let workResults = try await service.searchReflections(query: "工作")
        XCTAssertEqual(workResults.count, 1)
        XCTAssertEqual(workResults.first?.content, "关于工作的洞察")
        
        // 按标签搜索
        let emotionResults = try await service.searchReflections(query: "情感")
        XCTAssertEqual(emotionResults.count, 1)
    }
    
    /// 测试获取需要跟进的反思
    func testFetchReflectionsNeedingFollowUp() async throws {
        let dream = try createTestDream()
        let futureDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        try await service.createReflection(
            dreamId: dream.id,
            type: .intention,
            content: "需要跟进的意图",
            followUpDate: futureDate
        )
        
        try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "不需要跟进的洞察",
            followUpDate: nil
        )
        
        let followUps = try await service.fetchReflectionsNeedingFollowUp()
        XCTAssertEqual(followUps.count, 1)
        XCTAssertEqual(followUps.first?.content, "需要跟进的意图")
    }
    
    // MARK: - Statistics Tests
    
    /// 测试获取反思统计
    func testGetReflectionStats() async throws {
        let dream = try createTestDream()
        
        // 创建不同类型的反思
        for _ in 0..<3 {
            try await service.createReflection(dreamId: dream.id, type: .insight, content: "洞察", rating: 5)
        }
        for _ in 0..<2 {
            try await service.createReflection(dreamId: dream.id, type: .emotion, content: "情绪", rating: 3)
        }
        try await service.createReflection(dreamId: dream.id, type: .question, content: "问题", rating: 4)
        
        let stats = try await service.getReflectionStats()
        
        XCTAssertEqual(stats.totalReflections, 6)
        XCTAssertEqual(stats.byType[.insight], 3)
        XCTAssertEqual(stats.byType[.emotion], 2)
        XCTAssertEqual(stats.byType[.question], 1)
        XCTAssertEqual(stats.averageRating, 4.16, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(stats.reflectionStreak, 1)
    }
    
    /// 测试获取洞察卡片
    func testGetInsightCards() async throws {
        let dream = try createTestDream()
        
        // 创建高评分洞察
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "重要洞察 1", rating: 5)
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "重要洞察 2", rating: 4)
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "普通洞察", rating: 3)
        
        let cards = try await service.getInsightCards(limit: 10, minRating: 4)
        
        XCTAssertEqual(cards.count, 2)
        XCTAssertTrue(cards.allSatisfy { $0.rating >= 4 })
    }
    
    // MARK: - Export Tests
    
    /// 测试导出为 Markdown
    func testExportToMarkdown() async throws {
        let dream = try createTestDream()
        
        try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "测试洞察内容",
            tags: ["测试"],
            rating: 5,
            relatedLifeEvents: ["事件 1"],
            actionItems: ["行动 1"]
        )
        
        let config = ReflectionExportConfig(
            includePrivate: false,
            dateRange: .all,
            types: [.insight],
            format: .markdown
        )
        
        let data = try await service.exportReflections(config: config)
        let markdown = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(markdown.contains("梦境反思日记"))
        XCTAssertTrue(markdown.contains("测试洞察内容"))
        XCTAssertTrue(markdown.contains("#测试"))
        XCTAssertTrue(markdown.contains("事件 1"))
        XCTAssertTrue(markdown.contains("行动 1"))
    }
    
    /// 测试导出为 JSON
    func testExportToJSON() async throws {
        let dream = try createTestDream()
        
        try await service.createReflection(
            dreamId: dream.id,
            type: .insight,
            content: "JSON 测试",
            rating: 4
        )
        
        let config = ReflectionExportConfig(
            includePrivate: false,
            dateRange: .all,
            types: [.insight],
            format: .json
        )
        
        let data = try await service.exportReflections(config: config)
        
        // 验证 JSON 格式
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
    }
    
    // MARK: - Edge Cases
    
    /// 测试删除不存在的反思
    func testDeleteNonExistentReflection() async throws {
        let nonExistentId = UUID()
        
        do {
            try await service.deleteReflection(id: nonExistentId)
            XCTFail("应该抛出错误")
        } catch ReflectionError.notFound {
            // 预期错误
        } catch {
            XCTFail("抛出意外错误：\(error)")
        }
    }
    
    /// 测试更新不存在的反思
    func testUpdateNonExistentReflection() async throws {
        let nonExistentId = UUID()
        
        do {
            try await service.updateReflection(id: nonExistentId, content: "新内容")
            XCTFail("应该抛出错误")
        } catch ReflectionError.notFound {
            // 预期错误
        } catch {
            XCTFail("抛出意外错误：\(error)")
        }
    }
    
    /// 测试空数据统计
    func testStatsWithNoData() async throws {
        let stats = try await service.getReflectionStats()
        
        XCTAssertEqual(stats.totalReflections, 0)
        XCTAssertEqual(stats.averageRating, 0)
        XCTAssertEqual(stats.reflectionStreak, 0)
        XCTAssertEqual(stats.mostUsedTags.count, 0)
    }
    
    /// 测试私密反思筛选
    func testPrivateReflectionFiltering() async throws {
        let dream = try createTestDream()
        
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "公开", isPrivate: false)
        try await service.createReflection(dreamId: dream.id, type: .insight, content: "私密", isPrivate: true)
        
        let publicOnly = try await service.fetchAllReflections(includePrivate: false)
        XCTAssertEqual(publicOnly.count, 1)
        XCTAssertEqual(publicOnly.first?.content, "公开")
        
        let all = try await service.fetchAllReflections(includePrivate: true)
        XCTAssertEqual(all.count, 2)
    }
    
    // MARK: - Performance Tests
    
    /// 测试大量数据性能
    func testPerformanceWithLargeDataset() async throws {
        let dream = try createTestDream()
        
        // 创建 100 个反思
        measure {
            let expectation = XCTestExpectation(description: "Create 100 reflections")
            
            Task {
                for i in 0..<100 {
                    try await service.createReflection(
                        dreamId: dream.id,
                        type: .insight,
                        content: "反思 \(i)",
                        tags: ["批量测试"]
                    )
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30)
        }
        
        let reflections = try await service.fetchAllReflections()
        XCTAssertEqual(reflections.count, 100)
    }
}

// MARK: - ReflectionType Tests

@available(iOS 17.0, *)
final class ReflectionTypeTests: XCTestCase {
    
    func testReflectionTypeCases() {
        XCTAssertEqual(ReflectionType.allCases.count, 6)
        
        XCTAssertTrue(ReflectionType.allCases.contains(.insight))
        XCTAssertTrue(ReflectionType.allCases.contains(.connection))
        XCTAssertTrue(ReflectionType.allCases.contains(.emotion))
        XCTAssertTrue(ReflectionType.allCases.contains(.question))
        XCTAssertTrue(ReflectionType.allCases.contains(.intention))
        XCTAssertTrue(ReflectionType.allCases.contains(.gratitude))
    }
    
    func testReflectionTypeDisplayNames() {
        for type in ReflectionType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertTrue(type.displayName.contains(type.icon))
        }
    }
    
    func testReflectionTypeRawValues() {
        for type in ReflectionType.allCases {
            XCTAssertEqual(ReflectionType(rawValue: type.rawValue), type)
        }
    }
}

// MARK: - ReflectionPrompt Tests

@available(iOS 17.0, *)
final class ReflectionPromptTests: XCTestCase {
    
    func testDefaultPromptsExist() {
        let prompts = ReflectionPrompt.defaultPrompts
        
        XCTAssertGreaterThan(prompts.count, 0)
        
        // 验证每种类型都有提示
        for type in ReflectionType.allCases {
            let typePrompts = prompts.filter { $0.type == type }
            XCTAssertGreaterThan(typePrompts.count, 0, "类型 \(type) 应该有提示")
        }
    }
    
    func testPromptCategories() {
        let prompts = ReflectionPrompt.defaultPrompts
        let categories = Set(prompts.map { $0.category })
        
        XCTAssertGreaterThan(categories.count, 0)
    }
}
