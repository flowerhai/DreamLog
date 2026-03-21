//
//  DreamSmartSuggestionsTests.swift
//  DreamLog - Phase 85: 梦境智能建议与个性化推荐系统
//
//  创建时间：2026-03-22
//  功能：智能建议单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

final class DreamSmartSuggestionsTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamSmartSuggestionsService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存模型容器
        let schema = Schema([
            SmartSuggestion.self,
            SuggestionConfig.self,
            Dream.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        service = DreamSmartSuggestionsService(modelContainer: modelContainer)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 数据模型测试
    
    func testSmartSuggestionCreation() throws {
        // Given
        let title = "提升梦境清晰度"
        let type = SmartSuggestionType.dreamImprovement
        let priority = SuggestionPriority.high
        
        // When
        let suggestion = SmartSuggestion(
            title: title,
            type: type,
            priority: priority,
            description: "测试描述",
            actionableSteps: ["步骤 1", "步骤 2"],
            expectedBenefit: "预期效果",
            timeCommitment: "每日 5 分钟"
        )
        
        // Then
        XCTAssertEqual(suggestion.title, title)
        XCTAssertEqual(suggestion.typedType, type)
        XCTAssertEqual(suggestion.typedPriority, priority)
        XCTAssertEqual(suggestion.actionableSteps.count, 2)
        XCTAssertFalse(suggestion.isDismissed)
        XCTAssertFalse(suggestion.isCompleted)
        XCTAssertFalse(suggestion.isActive == false)
    }
    
    func testSuggestionPriorityColors() {
        // Test priority color assignments
        XCTAssertEqual(SuggestionPriority.low.color, "secondary")
        XCTAssertEqual(SuggestionPriority.medium.color, "blue")
        XCTAssertEqual(SuggestionPriority.high.color, "orange")
    }
    
    func testSuggestionTypeIcons() {
        // Test that all suggestion types have icons
        for type in SmartSuggestionType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "Type \(type.displayName) should have an icon")
        }
    }
    
    func testSuggestionExpiration() throws {
        // Given
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        
        let expiredSuggestion = SmartSuggestion(
            title: "过期建议",
            type: .dreamImprovement,
            priority: .medium,
            description: "测试",
            actionableSteps: [],
            expectedBenefit: "测试",
            timeCommitment: "测试",
            expiresAt: pastDate
        )
        
        let activeSuggestion = SmartSuggestion(
            title: "活跃建议",
            type: .dreamImprovement,
            priority: .medium,
            description: "测试",
            actionableSteps: [],
            expectedBenefit: "测试",
            timeCommitment: "测试",
            expiresAt: futureDate
        )
        
        // Then
        XCTAssertTrue(expiredSuggestion.isExpired)
        XCTAssertFalse(expiredSuggestion.isActive)
        XCTAssertFalse(activeSuggestion.isExpired)
        XCTAssertTrue(activeSuggestion.isActive)
    }
    
    // MARK: - 配置测试
    
    func testSuggestionConfigCreation() throws {
        // Given & When
        let config = SuggestionConfig(
            enabledTypes: [.dreamImprovement, .lucidDreaming],
            minPriority: .medium,
            dailyLimit: 3,
            showNotifications: true,
            notificationTime: "08:00"
        )
        
        // Then
        XCTAssertEqual(config.enabledTypes.count, 2)
        XCTAssertTrue(config.isTypeEnabled(.dreamImprovement))
        XCTAssertTrue(config.isTypeEnabled(.lucidDreaming))
        XCTAssertFalse(config.isTypeEnabled(.sleepQuality))
        XCTAssertEqual(config.minPriority, 1)
        XCTAssertEqual(config.dailyLimit, 3)
        XCTAssertTrue(config.showNotifications)
    }
    
    func testConfigSaveAndLoad() throws {
        // Given
        let config = SuggestionConfig(
            enabledTypes: [.dreamRecall, .mindfulness],
            minPriority: .high,
            dailyLimit: 5
        )
        
        // When
        service.saveConfig(config)
        let loadedConfig = service.loadConfig()
        
        // Then
        XCTAssertEqual(loadedConfig.enabledTypes.count, 2)
        XCTAssertEqual(loadedConfig.minPriority, 2)
        XCTAssertEqual(loadedConfig.dailyLimit, 5)
    }
    
    // MARK: - 统计测试
    
    func testStatsCalculation() throws {
        // Given
        let suggestions = [
            createSuggestion(isActive: true, type: .dreamImprovement),
            createSuggestion(isActive: true, type: .lucidDreaming),
            createSuggestion(isCompleted: true, type: .dreamImprovement),
            createSuggestion(isDismissed: true, type: .sleepQuality)
        ]
        
        // When
        let stats = service.calculateStats(suggestions: suggestions)
        
        // Then
        XCTAssertEqual(stats.totalSuggestions, 4)
        XCTAssertEqual(stats.activeSuggestions, 2)
        XCTAssertEqual(stats.completedSuggestions, 1)
        XCTAssertEqual(stats.dismissedSuggestions, 1)
        XCTAssertEqual(stats.completionRate, 0.25, accuracy: 0.01)
    }
    
    func testStatsByType() throws {
        // Given
        let suggestions = [
            createSuggestion(isActive: true, type: .dreamImprovement),
            createSuggestion(isActive: true, type: .dreamImprovement),
            createSuggestion(isActive: true, type: .lucidDreaming),
            createSuggestion(isActive: true, type: .sleepQuality)
        ]
        
        // When
        let stats = service.calculateStats(suggestions: suggestions)
        
        // Then
        XCTAssertEqual(stats.suggestionsByType["dream_improvement"], 2)
        XCTAssertEqual(stats.suggestionsByType["lucid_dreaming"], 1)
        XCTAssertEqual(stats.suggestionsByType["sleep_quality"], 1)
    }
    
    func testStatsByPriority() throws {
        // Given
        let suggestions = [
            createSuggestion(isActive: true, priority: .low),
            createSuggestion(isActive: true, priority: .medium),
            createSuggestion(isActive: true, priority: .medium),
            createSuggestion(isActive: true, priority: .high)
        ]
        
        // When
        let stats = service.calculateStats(suggestions: suggestions)
        
        // Then
        XCTAssertEqual(stats.suggestionsByPriority["0"], 1) // low
        XCTAssertEqual(stats.suggestionsByPriority["1"], 2) // medium
        XCTAssertEqual(stats.suggestionsByPriority["2"], 1) // high
    }
    
    // MARK: - 建议生成测试
    
    func testDailySuggestionsGeneration() throws {
        // Given
        let context = SuggestionContext(
            recentDreams: createMockDreams(count: 5),
            dreamPatterns: ["模糊梦境", "回忆困难"],
            sleepQuality: 0.6,
            stressLevel: 0.4
        )
        
        // When
        let suggestions = service.generateSuggestions(context: context)
        
        // Then
        XCTAssertGreaterThan(suggestions.count, 0, "Should generate at least one suggestion")
        
        // Verify suggestions are relevant to the context
        let hasRelevantSuggestion = suggestions.contains { suggestion in
            suggestion.basedOnPatterns.contains("模糊梦境") ||
            suggestion.basedOnPatterns.contains("回忆困难")
        }
        XCTAssertTrue(hasRelevantSuggestion, "Should have suggestion based on provided patterns")
    }
    
    func testSuggestionTemplateGeneration() {
        // Given
        let template = SuggestionTemplate(
            type: .dreamImprovement,
            titleTemplate: "提升梦境清晰度：{technique}",
            descriptionTemplate: "尝试 {technique} 可以帮助您",
            actionTemplates: ["步骤 1: {technique}", "步骤 2: 记录结果"],
            benefitTemplate: "提高 {benefit}",
            timeCommitment: "每日 5 分钟",
            difficultyLevel: 2,
            applicablePatterns: ["模糊梦境"]
        )
        
        // When
        let suggestion = template.generate(
            variables: ["technique": "冥想", "benefit": "睡眠质量"],
            basedOnPatterns: ["模糊梦境", "回忆困难"]
        )
        
        // Then
        XCTAssertEqual(suggestion.title, "提升梦境清晰度：冥想")
        XCTAssertTrue(suggestion.description.contains("冥想"))
        XCTAssertTrue(suggestion.actionableSteps[0].contains("冥想"))
        XCTAssertEqual(suggestion.expectedBenefit, "提高 睡眠质量")
        XCTAssertEqual(suggestion.basedOnPatterns.count, 2)
    }
    
    // MARK: - 模式匹配测试
    
    func testPatternMatchingForLowSleepQuality() {
        // Given
        let context = SuggestionContext(sleepQuality: 0.3) // Low sleep quality
        
        // When
        let suggestions = service.generateSuggestions(context: context)
        
        // Then
        let hasSleepSuggestion = suggestions.contains { suggestion in
            suggestion.type == SmartSuggestionType.sleepQuality.rawValue ||
            suggestion.type == SmartSuggestionType.sleepSchedule.rawValue
        }
        XCTAssertTrue(hasSleepSuggestion, "Should suggest sleep improvements for low sleep quality")
    }
    
    func testPatternMatchingForHighStress() {
        // Given
        let context = SuggestionContext(stressLevel: 0.8) // High stress
        
        // When
        let suggestions = service.generateSuggestions(context: context)
        
        // Then
        let hasStressSuggestion = suggestions.contains { suggestion in
            suggestion.type == SmartSuggestionType.stressManagement.rawValue ||
            suggestion.type == SmartSuggestionType.relaxationTechnique.rawValue ||
            suggestion.type == SmartSuggestionType.mindfulness.rawValue
        }
        XCTAssertTrue(hasStressSuggestion, "Should suggest stress management for high stress")
    }
    
    // MARK: - 边界情况测试
    
    func testEmptyDreamsContext() {
        // Given
        let context = SuggestionContext(recentDreams: [])
        
        // When
        let suggestions = service.generateSuggestions(context: context)
        
        // Then
        // Should still generate general suggestions even with no dreams
        XCTAssertGreaterThanOrEqual(suggestions.count, 0)
    }
    
    func testSuggestionDismissal() throws {
        // Given
        let suggestion = createSuggestion(isActive: true)
        
        // When
        suggestion.isDismissed = true
        suggestion.dismissedAt = Date()
        
        // Then
        XCTAssertTrue(suggestion.isDismissed)
        XCTAssertNotNil(suggestion.dismissedAt)
        XCTAssertFalse(suggestion.isActive)
    }
    
    func testSuggestionCompletion() throws {
        // Given
        let suggestion = createSuggestion(isActive: true)
        let completionDate = Date()
        
        // When
        suggestion.isCompleted = true
        suggestion.completedAt = completionDate
        
        // Then
        XCTAssertTrue(suggestion.isCompleted)
        XCTAssertEqual(suggestion.completedAt, completionDate)
        XCTAssertFalse(suggestion.isActive)
    }
    
    // MARK: - 性能测试
    
    func testStatsCalculationPerformance() throws {
        // Given
        let suggestions = (0..<100).map { _ in createSuggestion(isActive: Bool.random()) }
        
        // When & Then
        measure {
            let stats = service.calculateStats(suggestions: suggestions)
            XCTAssertGreaterThan(stats.totalSuggestions, 0)
        }
    }
    
    func testSuggestionGenerationPerformance() throws {
        // Given
        let context = SuggestionContext(
            recentDreams: createMockDreams(count: 50),
            dreamPatterns: ["模式 1", "模式 2", "模式 3"]
        )
        
        // When & Then
        measure {
            let suggestions = service.generateSuggestions(context: context)
            XCTAssertGreaterThanOrEqual(suggestions.count, 0)
        }
    }
    
    // MARK: - 辅助方法
    
    private func createSuggestion(
        isActive: Bool = true,
        isCompleted: Bool = false,
        isDismissed: Bool = false,
        type: SmartSuggestionType = .dreamImprovement,
        priority: SuggestionPriority = .medium
    ) -> SmartSuggestion {
        let suggestion = SmartSuggestion(
            title: "测试建议",
            type: type,
            priority: priority,
            description: "测试描述",
            actionableSteps: ["步骤 1"],
            expectedBenefit: "测试效果",
            timeCommitment: "每日 5 分钟"
        )
        
        if isCompleted {
            suggestion.isCompleted = true
            suggestion.completedAt = Date()
        }
        
        if isDismissed {
            suggestion.isDismissed = true
            suggestion.dismissedAt = Date()
        }
        
        return suggestion
    }
    
    private func createMockDreams(count: Int) -> [Dream] {
        (0..<count).map { index in
            Dream(
                title: "测试梦境 \(index)",
                content: "这是一个测试梦境内容",
                date: Date().addingTimeInterval(-Double(index) * 86400),
                mood: ["平静", "焦虑", "兴奋"].randomElement(),
                tags: ["标签 1", "标签 2"]
            )
        }
    }
}

// MARK: - 测试套件

extension DreamSmartSuggestionsTests {
    static var allTests: [(String, (DreamSmartSuggestionsTests) -> () throws -> Void)] {
        [
            ("testSmartSuggestionCreation", testSmartSuggestionCreation),
            ("testSuggestionPriorityColors", testSuggestionPriorityColors),
            ("testSuggestionTypeIcons", testSuggestionTypeIcons),
            ("testSuggestionExpiration", testSuggestionExpiration),
            ("testSuggestionConfigCreation", testSuggestionConfigCreation),
            ("testConfigSaveAndLoad", testConfigSaveAndLoad),
            ("testStatsCalculation", testStatsCalculation),
            ("testStatsByType", testStatsByType),
            ("testStatsByPriority", testStatsByPriority),
            ("testDailySuggestionsGeneration", testDailySuggestionsGeneration),
            ("testSuggestionTemplateGeneration", testSuggestionTemplateGeneration),
            ("testPatternMatchingForLowSleepQuality", testPatternMatchingForLowSleepQuality),
            ("testPatternMatchingForHighStress", testPatternMatchingForHighStress),
            ("testEmptyDreamsContext", testEmptyDreamsContext),
            ("testSuggestionDismissal", testSuggestionDismissal),
            ("testSuggestionCompletion", testSuggestionCompletion),
            ("testStatsCalculationPerformance", testStatsCalculationPerformance),
            ("testSuggestionGenerationPerformance", testSuggestionGenerationPerformance)
        ]
    }
}
