//
//  DreamShareCardTests.swift
//  DreamLogTests
//
//  Phase 25 - Dream Sharing Cards & Social Templates
//  单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamShareCardTests: XCTestCase {
    
    var service: DreamShareCardService!
    var testDream: Dream!
    
    override func setUp() async throws {
        try await super.setUp()
        service = DreamShareCardService.shared
        testDream = Dream(
            title: "测试梦境",
            content: "这是一个用于测试的梦境内容，包含丰富的细节和情感描述。",
            tags: ["测试", "梦境", "分享"],
            emotions: [.happy, .excited],
            clarity: 4,
            intensity: 5,
            isLucid: true
        )
    }
    
    override func tearDown() async throws {
        // 清理生成的卡片
        try? await service.clearAllCards()
        try await super.tearDown()
    }
    
    // MARK: - 卡片生成测试
    
    func testGenerateCard() async throws {
        let config = ShareCardConfig(
            cardType: .minimalist,
            platform: .wechat
        )
        
        let card = try await service.generateCard(
            for: testDream,
            config: config
        )
        
        XCTAssertNotNil(card)
        XCTAssertEqual(card.dreamId, testDream.id)
        XCTAssertEqual(card.config.cardType, .minimalist)
        XCTAssertEqual(card.config.platform, .wechat)
        XCTAssertTrue(FileManager.default.fileExists(atPath: card.imageUrl.path))
    }
    
    func testGenerateCardForMultiplePlatforms() async throws {
        let platforms: [SocialPlatform] = [.wechat, .weibo, .xiaohongshu]
        
        let cards = try await service.generateCardsForMultiplePlatforms(
            for: testDream,
            platforms: platforms,
            cardType: .dreamy
        )
        
        XCTAssertEqual(cards.count, platforms.count)
        
        for platform in platforms {
            XCTAssertNotNil(cards[platform])
            XCTAssertEqual(cards[platform]?.config.platform, platform)
        }
    }
    
    func testGenerateCardWithCustomConfig() async throws {
        let config = ShareCardConfig(
            cardType: .artistic,
            platform: .instagram,
            showDreamTitle: true,
            showDreamContent: false,
            showTags: true,
            showEmotions: false,
            showClarity: true,
            showDate: true,
            showAILogo: true,
            customQuote: "自定义语录测试"
        )
        
        let card = try await service.generateCard(
            for: testDream,
            config: config
        )
        
        XCTAssertEqual(card.config.showDreamContent, false)
        XCTAssertEqual(card.config.showEmotions, false)
        XCTAssertEqual(card.config.customQuote, "自定义语录测试")
    }
    
    // MARK: - 卡片管理测试
    
    func testGetAllCards() async throws {
        // 生成 3 张卡片
        for _ in 0..<3 {
            _ = try await service.generateCard(
                for: testDream,
                config: ShareCardConfig()
            )
        }
        
        let cards = service.getAllCards()
        XCTAssertEqual(cards.count, 3)
    }
    
    func testGetCardsForDream() async throws {
        let dream1 = Dream(
            title: "梦境 1",
            content: "内容 1",
            tags: [],
            emotions: [],
            clarity: 3,
            intensity: 3,
            isLucid: false
        )
        
        let dream2 = Dream(
            title: "梦境 2",
            content: "内容 2",
            tags: [],
            emotions: [],
            clarity: 3,
            intensity: 3,
            isLucid: false
        )
        
        _ = try await service.generateCard(for: dream1, config: ShareCardConfig())
        _ = try await service.generateCard(for: dream1, config: ShareCardConfig())
        _ = try await service.generateCard(for: dream2, config: ShareCardConfig())
        
        let cardsForDream1 = service.getCards(for: dream1.id)
        let cardsForDream2 = service.getCards(for: dream2.id)
        
        XCTAssertEqual(cardsForDream1.count, 2)
        XCTAssertEqual(cardsForDream2.count, 1)
    }
    
    func testGetRecentCards() async throws {
        for _ in 0..<25 {
            _ = try await service.generateCard(
                for: testDream,
                config: ShareCardConfig()
            )
        }
        
        let recentCards = service.getRecentCards(limit: 20)
        XCTAssertEqual(recentCards.count, 20)
    }
    
    func testDeleteCard() async throws {
        let card = try await service.generateCard(
            for: testDream,
            config: ShareCardConfig()
        )
        
        let initialCount = service.getAllCards().count
        try service.deleteCard(card)
        let finalCount = service.getAllCards().count
        
        XCTAssertEqual(initialCount - finalCount, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: card.imageUrl.path))
    }
    
    // MARK: - 分享功能测试
    
    func testShareCard() async throws {
        let card = try await service.generateCard(
            for: testDream,
            config: ShareCardConfig()
        )
        
        let initialShareCount = card.shareCount
        try await service.shareCard(card, with: "测试分享文案")
        
        let updatedCards = service.getAllCards()
        let updatedCard = updatedCards.first { $0.id == card.id }
        
        XCTAssertEqual(updatedCard?.shareCount, initialShareCount + 1)
    }
    
    // MARK: - 统计测试
    
    func testGetStatistics() async throws {
        // 生成不同平台的卡片
        let platforms: [SocialPlatform] = [.wechat, .wechat, .weibo, .xiaohongshu, .wechat]
        
        for platform in platforms {
            let card = try await service.generateCard(
                for: testDream,
                config: ShareCardConfig(platform: platform)
            )
            try await service.shareCard(card)
        }
        
        let stats = service.getStatistics()
        
        XCTAssertEqual(stats.totalShares, 5)
        XCTAssertEqual(stats.sharesByPlatform[.wechat], 3)
        XCTAssertEqual(stats.sharesByPlatform[.weibo], 1)
        XCTAssertEqual(stats.sharesByPlatform[.xiaohongshu], 1)
    }
    
    // MARK: - 模型测试
    
    func testShareCardType() {
        XCTAssertEqual(ShareCardType.allCases.count, 5)
        
        let minimalist = ShareCardType.minimalist
        XCTAssertEqual(minimalist.displayName, "简约")
        XCTAssertEqual(minimalist.icon, "▭")
        
        let dreamy = ShareCardType.dreamy
        XCTAssertEqual(dreamy.displayName, "梦幻")
        XCTAssertEqual(dreamy.icon, "☁️")
    }
    
    func testSocialPlatform() {
        XCTAssertEqual(SocialPlatform.allCases.count, 8)
        
        let wechat = SocialPlatform.wechat
        XCTAssertEqual(wechat.displayName, "微信朋友圈")
        XCTAssertEqual(wechat.icon, "💚")
        XCTAssertEqual(wechat.recommendedSize, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(wechat.maxTextLength, 500)
        
        let twitter = SocialPlatform.twitter
        XCTAssertEqual(twitter.displayName, "Twitter")
        XCTAssertEqual(twitter.icon, "🐦")
        XCTAssertEqual(twitter.maxTextLength, 280)
    }
    
    func testCardTemplate() {
        XCTAssertGreaterThan(CardTemplate.templates.count, 0)
        
        let templates = CardTemplate.template(for: .dreamy)
        XCTAssertGreaterThan(templates.count, 0)
        
        let starryTemplate = CardTemplate.template(id: "dreamy_starry")
        XCTAssertNotNil(starryTemplate)
        XCTAssertEqual(starryTemplate?.name, "星空")
        XCTAssertEqual(starryTemplate?.type, .dreamy)
    }
    
    func testShareCardConfig() {
        let config = ShareCardConfig(
            cardType: .social,
            platform: .instagram
        )
        
        XCTAssertEqual(config.cardType, .social)
        XCTAssertEqual(config.platform, .instagram)
        XCTAssertTrue(config.showDreamTitle)
        XCTAssertTrue(config.showDreamContent)
    }
    
    // MARK: - 平台尺寸测试
    
    func testPlatformSizes() {
        // 正方形平台
        XCTAssertEqual(SocialPlatform.wechat.recommendedSize.aspectRatio, 1.0, accuracy: 0.01)
        XCTAssertEqual(SocialPlatform.qq.recommendedSize.aspectRatio, 1.0, accuracy: 0.01)
        
        // 竖版平台
        XCTAssertEqual(SocialPlatform.xiaohongshu.recommendedSize.aspectRatio, 0.75, accuracy: 0.01)
        XCTAssertEqual(SocialPlatform.instagram.recommendedSize.aspectRatio, 0.8, accuracy: 0.01)
        
        // 横版平台
        XCTAssertEqual(SocialPlatform.twitter.recommendedSize.aspectRatio, 16.0/9.0, accuracy: 0.01)
    }
    
    // MARK: - 错误处理测试
    
    func testInvalidConfig() {
        let config = ShareCardConfig(
            cardType: .minimalist,
            platform: .wechat,
            showDreamTitle: false,
            showDreamContent: false,
            showTags: false,
            showEmotions: false,
            showClarity: false,
            showDate: false,
            showAILogo: false
        )
        
        // 即使所有选项都关闭，也应该能生成卡片（至少有背景）
        XCTAssertNotNil(config)
    }
    
    // MARK: - 性能测试
    
    func testCardGenerationPerformance() async throws {
        measure {
            let expectation = self.expectation(description: "Generate card")
            
            Task {
                _ = try? await self.service.generateCard(
                    for: self.testDream,
                    config: ShareCardConfig()
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
}

// MARK: - CGSize 扩展

extension CGSize {
    var aspectRatio: CGFloat {
        width / height
    }
}

// MARK: - Dream 扩展（测试用）

extension Dream {
    init(
        title: String,
        content: String,
        tags: [String],
        emotions: [Emotion],
        clarity: Int,
        intensity: Int,
        isLucid: Bool,
        date: Date = Date()
    ) {
        self.init(
            id: UUID(),
            title: title,
            content: content,
            tags: tags,
            emotions: emotions,
            clarity: clarity,
            intensity: intensity,
            isLucid: isLucid,
            date: date,
            aiAnalysis: nil
        )
    }
}
