//
//  DreamShareCardTests.swift
//  DreamLogTests
//
//  Phase 54 - Dream Share Cards (梦境分享卡片)
//  单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamShareCardTests: XCTestCase {
    
    var service: DreamShareCardService!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContext
        let container = ModelContainer(for: DreamShareCard.self, Dream.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        modelContext = ModelContext(container)
        service = DreamShareCardService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 卡片创建测试
    
    func testCreateShareCard() async throws {
        // 创建测试梦境
        let dream = createTestDream()
        
        // 创建分享卡片
        let card = try await service.createShareCard(
            dreamId: dream.id,
            template: ShareCardTemplate.presets[0]
        )
        
        // 验证卡片属性
        XCTAssertEqual(card.dreamId, dream.id)
        XCTAssertEqual(card.templateId, ShareCardTemplate.presets[0].id)
        XCTAssertEqual(card.theme, .starry)
        XCTAssertEqual(card.shareCount, 0)
        XCTAssertFalse(card.isFavorite)
        XCTAssertTrue(card.showTags)
        XCTAssertTrue(card.showEmotions)
        XCTAssertTrue(card.showDate)
        XCTAssertTrue(card.showWatermark)
    }
    
    func testCreateShareCardWithCustomConfig() async throws {
        let dream = createTestDream()
        
        let config = ShareCardConfig(
            title: "自定义标题",
            content: "自定义内容",
            showTags: false,
            showEmotions: false,
            showDate: true,
            showWatermark: false
        )
        
        let card = try await service.createShareCard(
            dreamId: dream.id,
            template: ShareCardTemplate.presets[0],
            customConfig: config
        )
        
        XCTAssertEqual(card.customTitle, "自定义标题")
        XCTAssertEqual(card.customContent, "自定义内容")
        XCTAssertFalse(card.showTags)
        XCTAssertFalse(card.showEmotions)
        XCTAssertTrue(card.showDate)
        XCTAssertFalse(card.showWatermark)
    }
    
    // MARK: - 卡片管理测试
    
    func testGetAllShareCards() async throws {
        // 创建多个卡片
        let dream1 = createTestDream()
        let dream2 = createTestDream()
        
        _ = try await service.createShareCard(dreamId: dream1.id)
        _ = try await service.createShareCard(dreamId: dream2.id)
        
        let cards = service.getAllShareCards()
        XCTAssertEqual(cards.count, 2)
    }
    
    func testGetFavoriteCards() async throws {
        let dream = createTestDream()
        
        let card1 = try await service.createShareCard(dreamId: dream.id)
        let card2 = try await service.createShareCard(dreamId: dream.id)
        
        card1.isFavorite = true
        try service.updateCard(card1)
        
        let favorites = service.getFavoriteCards()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.id, card1.id)
    }
    
    func testGetCardsForDream() async throws {
        let dream1 = createTestDream()
        let dream2 = createTestDream()
        
        _ = try await service.createShareCard(dreamId: dream1.id)
        _ = try await service.createShareCard(dreamId: dream1.id)
        _ = try await service.createShareCard(dreamId: dream2.id)
        
        let cardsForDream1 = service.getCardsForDream(dreamId: dream1.id)
        XCTAssertEqual(cardsForDream1.count, 2)
        
        let cardsForDream2 = service.getCardsForDream(dreamId: dream2.id)
        XCTAssertEqual(cardsForDream2.count, 1)
    }
    
    func testDeleteCard() async throws {
        let dream = createTestDream()
        let card = try await service.createShareCard(dreamId: dream.id)
        
        XCTAssertEqual(service.getAllShareCards().count, 1)
        
        try service.deleteCard(card)
        
        XCTAssertEqual(service.getAllShareCards().count, 0)
    }
    
    func testToggleFavorite() async throws {
        let dream = createTestDream()
        let card = try await service.createShareCard(dreamId: dream.id)
        
        XCTAssertFalse(card.isFavorite)
        
        try service.toggleFavorite(card)
        XCTAssertTrue(card.isFavorite)
        
        try service.toggleFavorite(card)
        XCTAssertFalse(card.isFavorite)
    }
    
    // MARK: - 主题测试
    
    func testShareCardThemeCases() {
        let themes = ShareCardTheme.allCases
        XCTAssertEqual(themes.count, 12)
        
        // 验证每个主题都有正确的属性
        for theme in themes {
            XCTAssertFalse(theme.displayName.isEmpty)
            XCTAssertFalse(theme.icon.isEmpty)
            XCTAssertFalse(theme.gradientColors.isEmpty)
            XCTAssertEqual(theme.gradientColors.count, 3)
        }
    }
    
    func testShareCardThemeColors() {
        // 验证特定主题的颜色
        let starryColors = ShareCardTheme.starry.gradientColors
        XCTAssertEqual(starryColors.count, 3)
        
        let minimalColors = ShareCardTheme.minimal.gradientColors
        XCTAssertEqual(minimalColors.count, 3)
    }
    
    func testShareCardThemeTextColor() {
        // 验证文字颜色选择
        XCTAssertEqual(ShareCardTheme.starry.textColor, .white)
        XCTAssertEqual(ShareCardTheme.midnight.textColor, .white)
        XCTAssertEqual(ShareCardTheme.minimal.textColor, .black)
    }
    
    // MARK: - 模板测试
    
    func testShareCardTemplatePresets() {
        let presets = ShareCardTemplate.presets
        XCTAssertGreaterThanOrEqual(presets.count, 6)
        
        for template in presets {
            XCTAssertFalse(template.name.isEmpty)
            XCTAssertFalse(template.description.isEmpty)
            XCTAssertTrue(template.isPreset)
        }
    }
    
    func testCardLayoutAspectRatio() {
        // 验证布局宽高比
        XCTAssertEqual(CardLayout.standard.aspectRatio, 4.0 / 5.0)
        XCTAssertEqual(CardLayout.minimal.aspectRatio, 1.0)
        XCTAssertEqual(CardLayout.social.aspectRatio, 1.0)
        XCTAssertEqual(CardLayout.story.aspectRatio, 9.0 / 16.0)
    }
    
    func testCardLayoutDisplayNames() {
        let layouts = CardLayout.allCases
        for layout in layouts {
            XCTAssertFalse(layout.displayName.isEmpty)
        }
    }
    
    // MARK: - 分享平台测试
    
    func testSharePlatformCases() {
        let platforms = SharePlatformConfig.SharePlatform.allCases
        XCTAssertEqual(platforms.count, 9)
        
        for platform in platforms {
            XCTAssertFalse(platform.displayName.isEmpty)
            XCTAssertFalse(platform.icon.isEmpty)
        }
    }
    
    func testSharePlatformRecommendedSizes() {
        // 验证推荐尺寸
        let wechatSize = SharePlatformConfig.SharePlatform.wechat.recommendedSize
        XCTAssertEqual(wechatSize.width, 1080)
        XCTAssertEqual(wechatSize.height, 1350)
        
        let instagramSize = SharePlatformConfig.SharePlatform.instagram.recommendedSize
        XCTAssertEqual(instagramSize.width, 1080)
        XCTAssertEqual(instagramSize.height, 1080)
    }
    
    // MARK: - 统计数据测试
    
    func testGetStats() async throws {
        let dream = createTestDream()
        
        // 创建多个卡片
        let card1 = try await service.createShareCard(dreamId: dream.id, template: ShareCardTemplate.presets[0])
        let card2 = try await service.createShareCard(dreamId: dream.id, template: ShareCardTemplate.presets[1])
        
        card1.isFavorite = true
        try service.updateCard(card1)
        
        let stats = service.getStats()
        
        XCTAssertEqual(stats.totalCards, 2)
        XCTAssertEqual(stats.favoriteCards, 1)
        XCTAssertNotNil(stats.cardsByTheme)
    }
    
    func testEmptyStats() {
        let stats = ShareCardStats.empty
        
        XCTAssertEqual(stats.totalCards, 0)
        XCTAssertEqual(stats.totalShares, 0)
        XCTAssertEqual(stats.favoriteCards, 0)
        XCTAssertNil(stats.mostUsedTheme)
        XCTAssertTrue(stats.cardsByTheme.isEmpty)
        XCTAssertTrue(stats.recentShares.isEmpty)
    }
    
    // MARK: - 配置测试
    
    func testShareCardConfig() {
        let config = ShareCardConfig(
            title: "测试标题",
            content: "测试内容",
            showTags: true,
            showEmotions: false,
            showDate: true,
            showWatermark: false
        )
        
        XCTAssertEqual(config.title, "测试标题")
        XCTAssertEqual(config.content, "测试内容")
        XCTAssertTrue(config.showTags)
        XCTAssertFalse(config.showEmotions)
        XCTAssertTrue(config.showDate)
        XCTAssertFalse(config.showWatermark)
    }
    
    func testShareCardConfigDefaultValues() {
        let config = ShareCardConfig()
        
        XCTAssertNil(config.title)
        XCTAssertNil(config.content)
        XCTAssertTrue(config.showTags)
        XCTAssertTrue(config.showEmotions)
        XCTAssertTrue(config.showDate)
        XCTAssertTrue(config.showWatermark)
    }
    
    // MARK: - 颜色扩展测试
    
    func testColorFromHex() {
        // 测试十六进制颜色转换
        let color3Digit = Color(hex: "fff")
        XCTAssertNotNil(color3Digit)
        
        let color6Digit = Color(hex: "ffffff")
        XCTAssertNotNil(color6Digit)
        
        let color8Digit = Color(hex: "ffffffff")
        XCTAssertNotNil(color8Digit)
    }
    
    // MARK: - 性能测试
    
    func testCreateMultipleCardsPerformance() async throws {
        let dream = createTestDream()
        
        measure {
            let expectation = self.expectation(description: "Create cards")
            
            Task {
                for _ in 0..<10 {
                    _ = try? await service.createShareCard(dreamId: dream.id)
                }
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10)
        }
    }
    
    // MARK: - 辅助方法
    
    private func createTestDream() -> Dream {
        let dream = Dream(
            title: "测试梦境",
            content: "这是一个测试梦境的内容",
            date: Date(),
            tags: ["测试", "梦境"],
            emotions: [.happy, .calm],
            clarity: 4,
            intensity: 3,
            isLucid: false
        )
        modelContext.insert(dream)
        try? modelContext.save()
        return dream
    }
}

// MARK: - 视图测试

final class DreamShareCardViewTests: XCTestCase {
    
    func testShareCardViewInitialization() {
        let view = DreamShareCardView()
        XCTAssertNotNil(view)
    }
    
    func testCreateCardViewInitialization() {
        let view = CreateCardView()
        XCTAssertNotNil(view)
    }
    
    func testCardDetailViewInitialization() throws {
        let dream = Dream(
            title: "测试",
            content: "内容",
            date: Date()
        )
        
        let card = DreamShareCard(dreamId: dream.id)
        let view = CardDetailView(card: card)
        XCTAssertNotNil(view)
    }
    
    func testThemeButtonInitialization() {
        let button = ThemeButton(
            theme: .starry,
            isSelected: true
        ) { }
        XCTAssertNotNil(button)
    }
    
    func testShareStatsViewInitialization() {
        let stats = ShareCardStats.empty
        let view = ShareStatsView(stats: stats)
        XCTAssertNotNil(view)
    }
}
