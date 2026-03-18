//
//  DreamYearInReviewTests.swift
//  DreamLog - 梦境年度回顾单元测试
//  Phase 63: Dream Year in Review (梦境年度回顾)
//
//  Created by DreamLog Team on 2026-03-18.
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamYearInReviewTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            DreamYearInReview.self,
            DreamMonthInReview.self,
            YearInReviewShareCard.self,
            Dream.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 数据模型测试
    
    /// 测试年度回顾模型初始化
    func testYearInReviewInitialization() {
        let review = DreamYearInReview(
            year: 2025,
            totalDreams: 100,
            lucidDreams: 25,
            averageClarity: 3.8,
            averageIntensity: 3.2,
            longestStreak: 30,
            currentStreak: 15,
            totalRecordDays: 80,
            topEmotion: "平静",
            topTags: ["飞行", "水", "家"],
            yearTheme: "探索与发现",
            yearKeyword: "成长"
        )
        
        XCTAssertEqual(review.year, 2025)
        XCTAssertEqual(review.totalDreams, 100)
        XCTAssertEqual(review.lucidDreams, 25)
        XCTAssertEqual(review.averageClarity, 3.8)
        XCTAssertEqual(review.topEmotion, "平静")
        XCTAssertEqual(review.topTags, ["飞行", "水", "家"])
        XCTAssertEqual(review.yearTheme, "探索与发现")
        XCTAssertEqual(review.yearKeyword, "成长")
        XCTAssertTrue(review.isShareable)
    }
    
    /// 测试 AI 洞察模型
    func testYearInReviewInsight() {
        let insight = YearInReviewInsight(
            type: .achievement,
            title: "梦境记录大师",
            description: "你在这一年记录了 100 个梦境",
            icon: "🏆",
            confidence: 0.95,
            relatedTags: ["记录", "坚持"],
            actionSuggestion: "继续保持记录习惯"
        )
        
        XCTAssertEqual(insight.type, .achievement)
        XCTAssertEqual(insight.title, "梦境记录大师")
        XCTAssertEqual(insight.icon, "🏆")
        XCTAssertEqual(insight.confidence, 0.95)
        XCTAssertEqual(insight.relatedTags, ["记录", "坚持"])
        XCTAssertEqual(insight.actionSuggestion, "继续保持记录习惯")
    }
    
    /// 测试洞察类型枚举
    func testInsightTypeCases() {
        let types: [YearInReviewInsight.InsightType] = [.pattern, .trend, .achievement, .suggestion, .prediction, .curiosity]
        
        XCTAssertEqual(YearInReviewInsight.InsightType.pattern.displayName, "模式发现")
        XCTAssertEqual(YearInReviewInsight.InsightType.trend.displayName, "趋势分析")
        XCTAssertEqual(YearInReviewInsight.InsightType.achievement.displayName, "成就认可")
        XCTAssertEqual(YearInReviewInsight.InsightType.suggestion.displayName, "改进建议")
        XCTAssertEqual(YearInReviewInsight.InsightType.prediction.displayName, "未来预测")
        XCTAssertEqual(YearInReviewInsight.InsightType.curiosity.displayName, "有趣发现")
        
        XCTAssertEqual(YearInReviewInsight.InsightType.pattern.icon, "🔍")
        XCTAssertEqual(YearInReviewInsight.InsightType.achievement.icon, "🏆")
        XCTAssertEqual(YearInReviewInsight.InsightType.prediction.icon, "🔮")
    }
    
    /// 测试分享卡片模型
    func testShareCardInitialization() {
        let card = YearInReviewShareCard(
            year: 2025,
            cardType: .overview,
            title: "2025 梦境年度总览",
            subtitle: "你的梦境之旅",
            mainValue: "100 个梦境",
            description: "记录了 80 天，最长连续 30 天",
            backgroundImage: "starry",
            decorations: ["🌙", "✨", "💫"]
        )
        
        XCTAssertEqual(card.year, 2025)
        XCTAssertEqual(card.cardType, .overview)
        XCTAssertEqual(card.title, "2025 梦境年度总览")
        XCTAssertEqual(card.backgroundImage, "starry")
        XCTAssertEqual(card.decorations, ["🌙", "✨", "💫"])
        XCTAssertEqual(card.shareCount, 0)
    }
    
    /// 测试卡片类型枚举
    func testCardTypeCases() {
        let types: [YearInReviewShareCard.CardType] = [
            .overview, .emotion, .tags, .lucid, .streak,
            .highlight, .monthly, .insight, .theme, .prediction
        ]
        
        XCTAssertEqual(YearInReviewShareCard.CardType.overview.displayName, "年度总览")
        XCTAssertEqual(YearInReviewShareCard.CardType.emotion.displayName, "情绪之旅")
        XCTAssertEqual(YearInReviewShareCard.CardType.lucid.displayName, "清醒梦探索")
        XCTAssertEqual(YearInReviewShareCard.CardType.streak.displayName, "连续记录")
        
        XCTAssertEqual(YearInReviewShareCard.CardType.overview.icon, "📊")
        XCTAssertEqual(YearInReviewShareCard.CardType.emotion.icon, "💖")
        XCTAssertEqual(YearInReviewShareCard.CardType.lucid.icon, "👁️")
    }
    
    /// 测试月度回顾模型
    func testMonthInReviewInitialization() {
        let monthReview = DreamMonthInReview(
            year: 2025,
            month: 3,
            totalDreams: 12,
            lucidDreams: 3,
            averageClarity: 3.5,
            topEmotion: "快乐",
            topTags: ["飞行", "自由"]
        )
        
        XCTAssertEqual(monthReview.year, 2025)
        XCTAssertEqual(monthReview.month, 3)
        XCTAssertEqual(monthReview.totalDreams, 12)
        XCTAssertEqual(monthReview.lucidDreams, 3)
        XCTAssertEqual(monthReview.topEmotion, "快乐")
    }
    
    /// 测试年度对比模型
    func testYearComparison() {
        let comparison = YearComparison(
            currentYear: 2025,
            previousYear: 2024,
            dreamsChange: 25.5,
            lucidChange: 15.0,
            clarityChange: 5.2,
            streakChange: 100.0,
            improvedAreas: ["记录频率", "清醒梦比例"],
            areasToFocus: ["梦境清晰度"]
        )
        
        XCTAssertEqual(comparison.currentYear, 2025)
        XCTAssertEqual(comparison.previousYear, 2024)
        XCTAssertEqual(comparison.dreamsChange, 25.5)
        XCTAssertEqual(comparison.improvedAreas, ["记录频率", "清醒梦比例"])
    }
    
    /// 测试配置模型
    func testYearInReviewConfig() {
        let config = YearInReviewConfig.default
        
        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.autoGenerate)
        XCTAssertTrue(config.shareEnabled)
        XCTAssertEqual(config.defaultTheme, "starry")
    }
    
    // MARK: - 服务层测试
    
    /// 测试服务初始化
    func testServiceInitialization() async throws {
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        
        // 验证服务可以正常初始化
        let reviews = try await service.getAllYearInReviews()
        XCTAssertEqual(reviews.count, 0)
    }
    
    /// 测试获取不存在的年度回顾
    func testGetNonExistentYearReview() async throws {
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        
        let review = try await service.getYearInReview(for: 2025)
        XCTAssertNil(review)
    }
    
    /// 测试获取所有年度回顾（空）
    func testGetAllYearReviewsEmpty() async throws {
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        
        let reviews = try await service.getAllYearInReviews()
        XCTAssertTrue(reviews.isEmpty)
    }
    
    // MARK: - 数组扩展测试
    
    /// 测试 mostCommon 方法
    func testMostCommon() {
        let tags = ["飞行", "水", "飞行", "家", "飞行", "水"]
        
        XCTAssertEqual(tags.mostCommon, "飞行")
        XCTAssertEqual(tags.mostCommon(2), ["飞行", "水"])
        XCTAssertEqual(tags.mostCommon(3), ["飞行", "水", "家"])
    }
    
    /// 测试空数组的 mostCommon
    func testMostCommonEmpty() {
        let emptyTags: [String] = []
        
        XCTAssertNil(emptyTags.mostCommon)
        XCTAssertEqual(emptyTags.mostCommon(5), [])
    }
    
    // MARK: - 性能测试
    
    /// 测试大量数据的统计计算性能
    func testPerformanceWithLargeDataset() async throws {
        // 创建测试数据
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        
        for i in 0..<365 {
            let date = calendar.date(byAdding: .day, value: i, to: startDate)!
            let dream = Dream(
                title: "测试梦境\(i)",
                content: "这是一个测试梦境内容",
                date: date,
                tags: ["测试", "梦境"],
                emotions: [.平静],
                clarity: 3,
                intensity: 3,
                isLucid: i % 5 == 0
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        // 测试生成性能
        measure {
            Task {
                let service = DreamYearInReviewService(modelContainer: modelContainer)
                do {
                    _ = try await service.generateYearInReview(for: 2025)
                } catch {
                    XCTFail("生成年度回顾失败：\(error)")
                }
            }
        }
    }
    
    // MARK: - 边界情况测试
    
    /// 测试无梦境数据的年度回顾
    func testEmptyYearReview() async throws {
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        
        // 不插入任何梦境数据，直接生成年度回顾
        let review = try await service.generateYearInReview(for: 2025)
        
        XCTAssertEqual(review.year, 2025)
        XCTAssertEqual(review.totalDreams, 0)
        XCTAssertFalse(review.aiInsights.isEmpty)
        XCTAssertEqual(review.yearTheme, "新的开始")
        XCTAssertEqual(review.yearKeyword, "启程")
    }
    
    /// 测试单个梦境的年度回顾
    func testSingleDreamYearReview() async throws {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 15))!
        
        let dream = Dream(
            title: "唯一的梦境",
            content: "这是 2025 年唯一的梦境",
            date: startDate,
            tags: ["独特"],
            emotions: [.惊讶],
            clarity: 5,
            intensity: 4,
            isLucid: true
        )
        modelContext.insert(dream)
        try modelContext.save()
        
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        let review = try await service.generateYearInReview(for: 2025)
        
        XCTAssertEqual(review.totalDreams, 1)
        XCTAssertEqual(review.lucidDreams, 1)
        XCTAssertEqual(review.averageClarity, 5.0)
        XCTAssertEqual(review.topEmotion, "惊讶")
    }
    
    /// 测试删除年度回顾
    func testDeleteYearReview() async throws {
        // 先创建一些测试数据
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        _ = try await service.generateYearInReview(for: 2025)
        
        // 验证创建成功
        var reviews = try await service.getAllYearInReviews()
        XCTAssertEqual(reviews.count, 1)
        
        // 删除
        try await service.deleteYearInReview(for: 2025)
        
        // 验证删除成功
        reviews = try await service.getAllYearInReviews()
        XCTAssertEqual(reviews.count, 0)
    }
    
    /// 测试分享计数
    func testShareCountIncrement() async throws {
        let service = DreamYearInReviewService(modelContainer: modelContainer)
        
        // 创建年度回顾（会同时创建分享卡片）
        let review = try await service.generateYearInReview(for: 2025)
        
        // 获取分享卡片
        let cards = try await service.getShareCards(for: 2025)
        XCTAssertFalse(cards.isEmpty)
        
        // 记录分享
        if let firstCard = cards.first {
            try await service.recordShare(cardId: firstCard.id)
            
            // 验证分享计数增加
            let updatedCards = try await service.getShareCards(for: 2025)
            let updatedCard = updatedCards.first { $0.id == firstCard.id }
            XCTAssertEqual(updatedCard?.shareCount, 1)
        }
    }
}

// MARK: - 辅助扩展

@available(iOS 17.0, *)
extension DreamYearInReviewTests {
    /// 创建测试用梦境
    func createTestDream(
        title: String,
        date: Date,
        tags: [String] = [],
        emotions: [Emotion] = [.中性],
        clarity: Int = 3,
        isLucid: Bool = false
    ) -> Dream {
        Dream(
            title: title,
            content: "测试内容",
            date: date,
            tags: tags,
            emotions: emotions,
            clarity: clarity,
            intensity: 3,
            isLucid: isLucid
        )
    }
}
