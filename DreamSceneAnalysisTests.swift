//
//  DreamSceneAnalysisTests.swift
//  DreamLogTests
//
//  梦境场景分析单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamSceneAnalysisTests: XCTestCase {
    
    var service: DreamSceneAnalysisService!
    var store: DreamStore!
    
    override func setUp() async throws {
        try await super.setUp()
        store = DreamStore.shared
        service = DreamSceneAnalysisService(store: store)
    }
    
    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - Scene Detection Tests
    
    func testAnalyzeDream_WithIndoorKeywords() async throws {
        // Given
        let dream = Dream(
            title: "在房间里",
            content: "我在一个房间里，周围有很多家具和装饰品",
            date: Date(),
            emotions: [.happy],
            emotionIntensity: 0.7,
            clarity: 0.8,
            intensity: 0.6,
            tags: ["室内", "家"]
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertTrue(analysis.detectedScenes.contains(.indoor))
        XCTAssertTrue(analysis.detectedScenes.contains(.home))
        XCTAssertEqual(analysis.primaryScene, .indoor)
        XCTAssertGreaterThan(analysis.confidence, 0)
    }
    
    func testAnalyzeDream_WithOutdoorKeywords() async throws {
        // Given
        let dream = Dream(
            title: "公园散步",
            content: "我在户外的公园里散步，周围有很多树木和草地",
            date: Date(),
            emotions: [.calm],
            emotionIntensity: 0.6,
            clarity: 0.7,
            intensity: 0.5,
            tags: ["户外", "自然"]
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertTrue(analysis.detectedScenes.contains(.outdoor))
        XCTAssertTrue(analysis.detectedScenes.contains(.nature))
        XCTAssertTrue([.outdoor, .nature].contains(analysis.primaryScene))
    }
    
    func testAnalyzeDream_WithWaterKeywords() async throws {
        // Given
        let dream = Dream(
            title: "海边",
            content: "我在海边，看着海浪拍打沙滩，海水很蓝",
            date: Date(),
            emotions: [.calm, .happy],
            emotionIntensity: 0.8,
            clarity: 0.9,
            intensity: 0.7,
            tags: ["水", "自然"]
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertTrue(analysis.detectedScenes.contains(.water))
        XCTAssertTrue(analysis.detectedScenes.contains(.nature))
    }
    
    func testAnalyzeDream_WithFantasticalKeywords() async throws {
        // Given
        let dream = Dream(
            title: "奇幻世界",
            content: "我在一个奇幻的异世界，有魔法和神奇的生物",
            date: Date(),
            emotions: [.excited, .curious],
            emotionIntensity: 0.9,
            clarity: 0.6,
            intensity: 0.8,
            tags: ["奇幻", "魔法"]
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertTrue(analysis.detectedScenes.contains(.fantastical))
        XCTAssertEqual(analysis.primaryScene, .fantastical)
    }
    
    func testAnalyzeDream_WithNoKeywords() async throws {
        // Given
        let dream = Dream(
            title: "普通的一天",
            content: "就是很普通的一天，没什么特别的",
            date: Date(),
            emotions: [.neutral],
            emotionIntensity: 0.3,
            clarity: 0.5,
            intensity: 0.3,
            tags: []
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertEqual(analysis.primaryScene, .other)
        XCTAssertTrue(analysis.detectedScenes.isEmpty || analysis.detectedScenes.contains(.other))
    }
    
    // MARK: - Environmental Factor Tests
    
    func testAnalyzeDream_DetectsEnvironmentalFactors() async throws {
        // Given
        let dream = Dream(
            title: "明亮的雨天",
            content: "外面下着雨，但是光线很明亮，天气有点冷",
            date: Date(),
            emotions: [.calm],
            emotionIntensity: 0.5,
            clarity: 0.7,
            intensity: 0.5,
            tags: []
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertGreaterThan(analysis.environmentalFactors.count, 0)
        XCTAssertTrue(analysis.environmentalFactors.contains { $0.type == .weather })
        XCTAssertTrue(analysis.environmentalFactors.contains { $0.type == .lighting })
        XCTAssertTrue(analysis.environmentalFactors.contains { $0.type == .temperature })
    }
    
    // MARK: - Scene Description Tests
    
    func testAnalyzeDream_GeneratesDescription() async throws {
        // Given
        let dream = Dream(
            title: "在学校",
            content: "我回到了小时候的学校，教室里有很多同学",
            date: Date(),
            emotions: [.nostalgic],
            emotionIntensity: 0.7,
            clarity: 0.8,
            intensity: 0.6,
            tags: ["学校", "童年"]
        )
        
        // When
        let analysis = await service.analyzeDream(dream)
        
        // Then
        XCTAssertFalse(analysis.sceneDescription.isEmpty)
        XCTAssertTrue(analysis.sceneDescription.contains("学校") || 
                      analysis.sceneDescription.contains("童年"))
    }
    
    // MARK: - Summary Tests
    
    func testGetSummary_WithMultipleDreams() async throws {
        // Given
        let dreams = [
            Dream(title: "在家", content: "我在家里休息", date: Date(), emotions: [.calm], emotionIntensity: 0.5, clarity: 0.7, intensity: 0.5, tags: []),
            Dream(title: "在公司", content: "我在公司开会", date: Date(), emotions: [.stressed], emotionIntensity: 0.7, clarity: 0.8, intensity: 0.7, tags: []),
            Dream(title: "在公园", content: "我在公园散步", date: Date(), emotions: [.happy], emotionIntensity: 0.8, clarity: 0.9, intensity: 0.6, tags: [])
        ]
        
        // Analyze all dreams
        for dream in dreams {
            _ = await service.analyzeDream(dream)
        }
        
        // When
        let summary = await service.getSummary()
        
        // Then
        XCTAssertEqual(summary.analyzedDreams, 3)
        XCTAssertGreaterThan(summary.topScenes.count, 0)
    }
    
    func testGetSummary_CalculatesDiversity() async throws {
        // Given - dreams with same scene
        let dreams = [
            Dream(title: "在家 1", content: "我在家里", date: Date(), emotions: [.calm], emotionIntensity: 0.5, clarity: 0.7, intensity: 0.5, tags: ["家"]),
            Dream(title: "在家 2", content: "我还在家里", date: Date(), emotions: [.calm], emotionIntensity: 0.5, clarity: 0.7, intensity: 0.5, tags: ["家"]),
            Dream(title: "在家 3", content: "我仍然在家里", date: Date(), emotions: [.calm], emotionIntensity: 0.5, clarity: 0.7, intensity: 0.5, tags: ["家"])
        ]
        
        for dream in dreams {
            _ = await service.analyzeDream(dream)
        }
        
        // When
        let summary = await service.getSummary()
        
        // Then - low diversity for same scenes
        XCTAssertLessThan(summary.sceneDiversity, 0.5)
    }
    
    // MARK: - Insights Tests
    
    func testGenerateInsights_WithEnoughData() async throws {
        // Given - create enough dreams to generate insights
        var dreams: [Dream] = []
        for i in 0..<10 {
            dreams.append(Dream(
                title: "梦境 \(i)",
                content: "我在家里休息，感觉很放松",
                date: Date(),
                emotions: [.calm, .happy],
                emotionIntensity: 0.7,
                clarity: 0.8,
                intensity: 0.6,
                tags: ["家", "室内"]
            ))
        }
        
        for dream in dreams {
            _ = await service.analyzeDream(dream)
        }
        
        // When
        let insights = await service.generateInsights()
        
        // Then
        XCTAssertGreaterThan(insights.count, 0)
    }
    
    // MARK: - Emotion Correlation Tests
    
    func testGetSceneEmotionCorrelations() async throws {
        // Given
        var dreams: [Dream] = []
        for i in 0..<5 {
            dreams.append(Dream(
                title: "快乐的家 \(i)",
                content: "我在家里很开心",
                date: Date(),
                emotions: [.happy],
                emotionIntensity: 0.8,
                clarity: 0.7,
                intensity: 0.7,
                tags: ["家"]
            ))
        }
        
        for dream in dreams {
            _ = await service.analyzeDream(dream)
        }
        
        // When
        let correlations = await service.getSceneEmotionCorrelations()
        
        // Then
        XCTAssertGreaterThan(correlations.count, 0)
    }
    
    // MARK: - Config Tests
    
    func testUpdateConfig() async throws {
        // Given
        var newConfig = SceneAnalysisConfig.default
        newConfig.autoAnalyze = false
        newConfig.minConfidence = 0.8
        
        // When
        await service.updateConfig(newConfig)
        let retrievedConfig = await service.getConfig()
        
        // Then
        XCTAssertEqual(retrievedConfig.autoAnalyze, false)
        XCTAssertEqual(retrievedConfig.minConfidence, 0.8)
    }
    
    // MARK: - Scene Type Enum Tests
    
    func testSceneType_AllCasesHaveValidData() {
        // Test all scene types have proper display names and icons
        for sceneType in DreamSceneType.allCases {
            XCTAssertFalse(sceneType.displayName.isEmpty)
            XCTAssertFalse(sceneType.icon.isEmpty)
        }
    }
    
    func testSceneType_ColorsAreValid() {
        // Test all scene types have valid colors
        for sceneType in DreamSceneType.allCases {
            // Color is a struct, just ensure it's initialized
            _ = sceneType.color
        }
    }
    
    // MARK: - Environmental Factor Enum Tests
    
    func testEnvironmentalFactorType_AllCasesHaveValidNames() {
        for factorType in EnvironmentalFactor.EnvironmentalFactorType.allCases {
            XCTAssertFalse(factorType.displayName.isEmpty)
        }
    }
    
    // MARK: - Insight Type Enum Tests
    
    func testInsightType_AllCasesHaveValidNames() {
        for insightType in SceneInsight.InsightType.allCases {
            XCTAssertFalse(insightType.displayName.isEmpty)
        }
    }
    
    // MARK: - Performance Tests
    
    func testAnalyzeDream_Performance() async throws {
        // Given
        let dream = Dream(
            title: "性能测试",
            content: "这是一个用于性能测试的梦境，包含很多关键词：家、房间、室内、户外、公园、树木、水、海洋、天空、飞行",
            date: Date(),
            emotions: [.curious],
            emotionIntensity: 0.6,
            clarity: 0.7,
            intensity: 0.6,
            tags: []
        )
        
        // When & Then - should complete in reasonable time
        measure {
            let expectation = self.expectation(description: "Analyze dream")
            Task {
                _ = await service.analyzeDream(dream)
                expectation.fulfill()
            }
            waitForExpectations(timeout: 5.0)
        }
    }
    
    func testBatchAnalyze_Performance() async throws {
        // Given
        let dreams = (0..<20).map { i in
            Dream(
                title: "梦境 \(i)",
                content: "这是第 \(i) 个梦境，用于批量分析测试",
                date: Date(),
                emotions: [.neutral],
                emotionIntensity: 0.5,
                clarity: 0.6,
                intensity: 0.5,
                tags: []
            )
        }
        
        // When & Then
        measure {
            let expectation = self.expectation(description: "Batch analyze")
            Task {
                _ = await service.analyzeDreams(dreams)
                expectation.fulfill()
            }
            waitForExpectations(timeout: 10.0)
        }
    }
}
