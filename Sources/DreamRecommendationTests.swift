//
//  DreamRecommendationTests.swift
//  DreamLog
//
//  Phase 55 - AI 梦境推荐与智能洞察
//  单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamRecommendationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([
            DreamRecommendation.self,
            DreamInsight.self,
            DreamSuggestion.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 推荐类型测试
    
    func testRecommendationTypeDisplayNames() {
        XCTAssertEqual(DreamRecommendationType.similarDream.displayName, "相似梦境")
        XCTAssertEqual(DreamRecommendationType.meditation.displayName, "冥想推荐")
        XCTAssertEqual(DreamRecommendationType.music.displayName, "音乐推荐")
        XCTAssertEqual(DreamRecommendationType.inspiration.displayName, "灵感提示")
        XCTAssertEqual(DreamRecommendationType.lucidTraining.displayName, "清醒梦训练")
    }
    
    func testRecommendationTypeIcons() {
        XCTAssertEqual(DreamRecommendationType.similarDream.icon, "moon.stars.fill")
        XCTAssertEqual(DreamRecommendationType.meditation.icon, "figure.mind.and.body")
        XCTAssertEqual(DreamRecommendationType.music.icon, "music.note")
        XCTAssertEqual(DreamRecommendationType.inspiration.icon, "lightbulb.fill")
    }
    
    func testRecommendationTypeColors() {
        XCTAssertEqual(DreamRecommendationType.similarDream.color, "purple")
        XCTAssertEqual(DreamRecommendationType.meditation.color, "green")
        XCTAssertEqual(DreamRecommendationType.music.color, "blue")
    }
    
    // MARK: - 推荐模型测试
    
    func testRecommendationCreation() {
        let recommendation = DreamRecommendation(
            type: .meditation,
            title: "测试推荐",
            description: "测试描述",
            reason: "推荐理由",
            confidence: 0.8,
            priority: 4
        )
        
        XCTAssertEqual(recommendation.type, .meditation)
        XCTAssertEqual(recommendation.title, "测试推荐")
        XCTAssertEqual(recommendation.confidence, 0.8)
        XCTAssertEqual(recommendation.priority, 4)
        XCTAssertFalse(recommendation.isRead)
        XCTAssertFalse(recommendation.isLiked)
        XCTAssertFalse(recommendation.isDismissed)
    }
    
    func testRecommendationExpiration() {
        let pastRecommendation = DreamRecommendation(
            type: .music,
            title: "过期推荐",
            description: "描述",
            reason: "原因",
            expiresAt: Date().addingTimeInterval(-1000)
        )
        
        let futureRecommendation = DreamRecommendation(
            type: .music,
            title: "有效推荐",
            description: "描述",
            reason: "原因",
            expiresAt: Date().addingTimeInterval(1000)
        )
        
        XCTAssertTrue(pastRecommendation.isExpired)
        XCTAssertFalse(futureRecommendation.isExpired)
    }
    
    func testRecommendationActiveState() {
        let activeRec = DreamRecommendation(
            type: .inspiration,
            title: "活跃推荐",
            description: "描述",
            reason: "原因"
        )
        
        let dismissedRec = DreamRecommendation(
            type: .inspiration,
            title: "已关闭推荐",
            description: "描述",
            reason: "原因"
        )
        dismissedRec.isDismissed = true
        
        XCTAssertTrue(activeRec.isActive)
        XCTAssertFalse(dismissedRec.isActive)
    }
    
    // MARK: - 洞察类型测试
    
    func testInsightTypeDisplayNames() {
        XCTAssertEqual(DreamInsightType.pattern.displayName, "模式洞察")
        XCTAssertEqual(DreamInsightType.trend.displayName, "趋势分析")
        XCTAssertEqual(DreamInsightType.correlation.displayName, "关联分析")
        XCTAssertEqual(DreamInsightType.prediction.displayName, "预测")
        XCTAssertEqual(DreamInsightType.achievement.displayName, "成就")
    }
    
    func testInsightCreation() {
        let insight = DreamInsight(
            type: .pattern,
            title: "测试洞察",
            description: "测试描述",
            details: "详细信息",
            confidence: 0.75,
            isImportant: true
        )
        
        XCTAssertEqual(insight.type, .pattern)
        XCTAssertEqual(insight.title, "测试洞察")
        XCTAssertEqual(insight.confidence, 0.75)
        XCTAssertTrue(insight.isImportant)
    }
    
    // MARK: - 建议模型测试
    
    func testSuggestionCreation() {
        let suggestion = DreamSuggestion(
            category: .recording,
            title: "测试建议",
            action: "执行动作",
            reason: "建议原因",
            expectedBenefit: "预期收益",
            difficulty: 3,
            estimatedTime: 15
        )
        
        XCTAssertEqual(suggestion.category, .recording)
        XCTAssertEqual(suggestion.difficulty, 3)
        XCTAssertEqual(suggestion.estimatedTime, 15)
        XCTAssertFalse(suggestion.isCompleted)
        XCTAssertFalse(suggestion.isAccepted)
    }
    
    func testSuggestionAcceptance() {
        let suggestion = DreamSuggestion(
            category: .sleep,
            title: "睡眠建议",
            action: "早睡",
            reason: "原因",
            expectedBenefit: "收益"
        )
        
        XCTAssertFalse(suggestion.isAccepted)
        XCTAssertNil(suggestion.acceptedAt)
        
        suggestion.accept()
        
        XCTAssertTrue(suggestion.isAccepted)
        XCTAssertNotNil(suggestion.acceptedAt)
    }
    
    func testSuggestionCompletion() {
        let suggestion = DreamSuggestion(
            category: .lucidDream,
            title: "清醒梦训练",
            action: "练习",
            reason: "原因",
            expectedBenefit: "收益"
        )
        
        XCTAssertFalse(suggestion.isCompleted)
        XCTAssertNil(suggestion.completedAt)
        
        suggestion.complete()
        
        XCTAssertTrue(suggestion.isCompleted)
        XCTAssertNotNil(suggestion.completedAt)
    }
    
    // MARK: - 时间范围测试
    
    func testTimeRangeDisplayNames() {
        XCTAssertEqual(TimeRange.last7Days.displayName, "最近 7 天")
        XCTAssertEqual(TimeRange.last30Days.displayName, "最近 30 天")
        XCTAssertEqual(TimeRange.last90Days.displayName, "最近 90 天")
        XCTAssertEqual(TimeRange.all.displayName, "全部")
    }
    
    func testTimeRangeDays() {
        XCTAssertEqual(TimeRange.last7Days.days, 7)
        XCTAssertEqual(TimeRange.last30Days.days, 30)
        XCTAssertEqual(TimeRange.last90Days.days, 90)
        XCTAssertNil(TimeRange.all.days)
    }
    
    func testTimeRangeStartDate() {
        let now = Date()
        let last7Days = TimeRange.last7Days
        let startDate = last7Days.startDate
        
        let calendar = Calendar.current
        let daysDiff = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
        
        XCTAssertGreaterThanOrEqual(daysDiff, 6)
        XCTAssertLessThanOrEqual(daysDiff, 8)
    }
    
    // MARK: - 推荐配置测试
    
    func testDefaultConfig() {
        let config = RecommendationConfig.default
        
        XCTAssertTrue(config.enableSimilarDreams)
        XCTAssertTrue(config.enableMeditationRecommendations)
        XCTAssertTrue(config.enableMusicRecommendations)
        XCTAssertTrue(config.enableInspirationRecommendations)
        XCTAssertTrue(config.enableLucidTrainingRecommendations)
        XCTAssertEqual(config.minConfidenceThreshold, 0.3)
        XCTAssertEqual(config.maxRecommendationsPerDay, 10)
        XCTAssertEqual(config.diversityFactor, 0.3)
    }
    
    // MARK: - 推荐统计测试
    
    func testRecommendationStats() {
        let stats = RecommendationStats(
            totalRecommendations: 100,
            readCount: 60,
            likedCount: 30,
            dismissedCount: 10,
            clickThroughRate: 0.6,
            averageFeedbackScore: 4.2
        )
        
        XCTAssertEqual(stats.totalRecommendations, 100)
        XCTAssertEqual(stats.readCount, 60)
        XCTAssertEqual(stats.likedCount, 30)
        XCTAssertEqual(stats.dismissedCount, 10)
        XCTAssertEqual(stats.clickThroughRate, 0.6)
        XCTAssertEqual(stats.averageFeedbackScore, 4.2)
    }
    
    func testRecommendationStatsCalculation() {
        let total = 100
        let read = 50
        let expectedCTR = Double(read) / Double(total)
        
        let stats = RecommendationStats(
            totalRecommendations: total,
            readCount: read
        )
        
        XCTAssertEqual(stats.clickThroughRate, expectedCTR, accuracy: 0.01)
    }
    
    // MARK: - 性能测试
    
    func testRecommendationCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = DreamRecommendation(
                    type: .meditation,
                    title: "测试",
                    description: "描述",
                    reason: "原因"
                )
            }
        }
    }
    
    func testInsightCreationPerformance() {
        measure {
            for _ in 0..<100 {
                _ = DreamInsight(
                    type: .pattern,
                    title: "测试",
                    description: "描述"
                )
            }
        }
    }
    
    // MARK: - 边界测试
    
    func testZeroConfidenceRecommendation() {
        let rec = DreamRecommendation(
            type: .music,
            title: "测试",
            description: "描述",
            reason: "原因",
            confidence: 0.0
        )
        
        XCTAssertEqual(rec.confidence, 0.0)
    }
    
    func testMaxConfidenceRecommendation() {
        let rec = DreamRecommendation(
            type: .music,
            title: "测试",
            description: "描述",
            reason: "原因",
            confidence: 1.0
        )
        
        XCTAssertEqual(rec.confidence, 1.0)
    }
    
    func testEmptyMetadataRecommendation() {
        let rec = DreamRecommendation(
            type: .inspiration,
            title: "测试",
            description: "描述",
            reason: "原因",
            metadata: [:]
        )
        
        XCTAssertTrue(rec.metadata.isEmpty)
    }
    
    func testEmptyRelatedDreamsRecommendation() {
        let rec = DreamRecommendation(
            type: .similarDream,
            title: "测试",
            description: "描述",
            reason: "原因",
            relatedDreamIds: []
        )
        
        XCTAssertTrue(rec.relatedDreamIds.isEmpty)
    }
}
