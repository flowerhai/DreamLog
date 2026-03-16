//
//  DreamArtCardTests.swift
//  DreamLogTests
//
//  Phase 54 - AI 梦境艺术分享卡片 - 单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamArtCardTests: XCTestCase {
    
    // MARK: - 属性
    
    var service: DreamArtCardService!
    var generator: DreamArtCardGenerator!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        service = DreamArtCardService.shared
        generator = DreamArtCardGenerator()
    }
    
    override func tearDown() async throws {
        service = nil
        generator = nil
    }
    
    // MARK: - 风格测试
    
    func testArtCardStyleCases() {
        // 验证所有风格都有正确的配置
        for style in ArtCardStyle.allCases {
            XCTAssertFalse(style.displayName.isEmpty, "风格 \(style.rawValue) 名称不应为空")
            XCTAssertFalse(style.icon.isEmpty, "风格 \(style.rawValue) 图标不应为空")
            XCTAssertFalse(style.description.isEmpty, "风格 \(style.rawValue) 描述不应为空")
            XCTAssertFalse(style.primaryColors.isEmpty, "风格 \(style.rawValue) 颜色不应为空")
        }
        
        XCTAssertEqual(ArtCardStyle.allCases.count, 12, "应该有 12 种风格")
    }
    
    func testArtCardStyleEmotionMatching() {
        // 测试星空风格推荐情绪
        let starryEmotions = ArtCardStyle.starry.recommendedEmotions
        XCTAssertTrue(starryEmotions.contains(.平静), "星空风格应推荐平静情绪")
        
        // 测试日出风格推荐情绪
        let sunriseEmotions = ArtCardStyle.sunrise.recommendedEmotions
        XCTAssertTrue(sunriseEmotions.contains(.快乐), "日出风格应推荐快乐情绪")
        XCTAssertTrue(sunriseEmotions.contains(.兴奋), "日出风格应推荐兴奋情绪")
    }
    
    func testArtCardStyleDecorations() {
        // 测试各风格的装饰元素
        XCTAssertFalse(ArtCardStyle.starry.defaultDecorations.isEmpty, "星空风格应有装饰")
        XCTAssertTrue(ArtCardStyle.minimal.defaultDecorations.isEmpty, "极简风格应无装饰")
        
        // 验证星空风格包含星星装饰
        let starryDecorations = ArtCardStyle.starry.defaultDecorations
        XCTAssertTrue(starryDecorations.contains(.stars), "星空风格应包含星星")
    }
    
    // MARK: - 模板分类测试
    
    func testTemplateCategoryCases() {
        XCTAssertEqual(TemplateCategory.allCases.count, 7, "应该有 7 种模板分类")
        
        for category in TemplateCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty, "分类 \(category.rawValue) 名称不应为空")
            XCTAssertFalse(category.icon.isEmpty, "分类 \(category.rawValue) 图标不应为空")
        }
    }
    
    // MARK: - 文本增强模式测试
    
    func testTextEnhancementModeCases() {
        XCTAssertEqual(TextEnhancementMode.allCases.count, 4, "应该有 4 种增强模式")
        
        // 验证各模式的图标
        XCTAssertEqual(TextEnhancementMode.none.icon, "📝")
        XCTAssertEqual(TextEnhancementMode.poetic.icon, "🎭")
        XCTAssertEqual(TextEnhancementMode.concise.icon, "✂️")
        XCTAssertEqual(TextEnhancementMode.vivid.icon, "🌟")
    }
    
    // MARK: - AI 文本增强测试
    
    func testEnhanceTextNoneMode() async throws {
        let text = "这是一个测试梦境"
        
        let result = try await service.enhanceText(text, mode: .none)
        
        XCTAssertEqual(result.originalText, text)
        XCTAssertEqual(result.enhancedText, text, "无增强模式应保持原文")
        XCTAssertEqual(result.mode, .none)
    }
    
    func testEnhanceTextConciseMode() async throws {
        let longText = String(repeating: "这是一个很长的梦境内容，", count: 20)
        
        let result = try await service.enhanceText(longText, mode: .concise)
        
        XCTAssertLessThanOrEqual(result.enhancedText.count, 103, "精简模式应限制在 100 字符左右")
        XCTAssertTrue(result.enhancedText.hasSuffix("..."), "精简模式应添加省略号")
    }
    
    func testEnhanceTextKeywordExtraction() async throws {
        let text = "梦见在海边散步，看到了美丽的海鸥和彩虹"
        
        let result = try await service.enhanceText(text, mode: .none)
        
        XCTAssertFalse(result.keywords.isEmpty, "应提取关键词")
        XCTAssertGreaterThanOrEqual(result.keywords.count, 1, "至少应提取 1 个关键词")
    }
    
    func testEnhanceTextEmojiSuggestion() async throws {
        let text = "梦见大海，感到很平静和快乐"
        
        let result = try await service.enhanceText(text, mode: .none)
        
        XCTAssertFalse(result.suggestedEmojis.isEmpty, "应建议 emoji")
        XCTAssertTrue(result.suggestedEmojis.contains("🌊"), "应包含海浪 emoji")
    }
    
    // MARK: - 平台优化测试
    
    func testPlatformOptimizationWechat() {
        let opt = PlatformOptimization.default(for: "wechat")
        
        XCTAssertEqual(opt.aspectRatio, 1.0, "微信应为正方形")
        XCTAssertEqual(opt.resolution, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(opt.maxTextLength, 200)
        XCTAssertTrue(opt.showWatermark, "微信应显示水印")
        XCTAssertEqual(opt.format, .png)
    }
    
    func testPlatformOptimizationXiaohongshu() {
        let opt = PlatformOptimization.default(for: "xiaohongshu")
        
        XCTAssertEqual(opt.aspectRatio, 1.25, "小红书应为 4:5")
        XCTAssertEqual(opt.resolution, CGSize(width: 1080, height: 1350))
        XCTAssertEqual(opt.maxTextLength, 500)
        XCTAssertEqual(opt.format, .jpg)
    }
    
    func testPlatformOptimizationInstagram() {
        let opt = PlatformOptimization.default(for: "instagram")
        
        XCTAssertEqual(opt.resolution, CGSize(width: 1080, height: 1350))
        XCTAssertFalse(opt.showWatermark, "Instagram 不应显示水印")
        XCTAssertEqual(opt.colorSpace, "Display P3")
    }
    
    func testPlatformOptimizationDefault() {
        let opt = PlatformOptimization.default(for: "unknown_platform")
        
        XCTAssertEqual(opt.aspectRatio, 1.0)
        XCTAssertEqual(opt.resolution, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(opt.maxTextLength, 300)
    }
    
    // MARK: - 背景配置测试
    
    func testBackgroundConfigDefault() {
        let config = BackgroundConfig.default
        
        XCTAssertEqual(config.colors, ["deepPurple", "midnightBlue"])
        XCTAssertEqual(config.gradientType, "linear")
        XCTAssertEqual(config.gradientAngle, 45)
        XCTAssertEqual(config.opacity, 0.9)
        XCTAssertEqual(config.blurRadius, 0)
        XCTAssertEqual(config.noiseIntensity, 0)
    }
    
    func testBackgroundConfigEquatable() {
        let config1 = BackgroundConfig.default
        let config2 = BackgroundConfig.default
        
        XCTAssertEqual(config1, config2, "相同的配置应相等")
        
        let config3 = BackgroundConfig(
            colors: ["red"],
            gradientType: "vertical",
            gradientAngle: 0,
            opacity: 1.0,
            blurRadius: 5,
            noiseIntensity: 0.1
        )
        
        XCTAssertNotEqual(config1, config3, "不同的配置应不相等")
    }
    
    // MARK: - 文字配置测试
    
    func testTextConfigDefault() {
        let config = TextConfig.default
        
        XCTAssertEqual(config.fontName, "PingFangSC-Regular")
        XCTAssertEqual(config.fontSize, 18)
        XCTAssertEqual(config.textColor, "white")
        XCTAssertEqual(config.alignment, .center)
        XCTAssertEqual(config.lineHeight, 1.5)
    }
    
    // MARK: - 装饰元素测试
    
    func testDecorationTypeCases() {
        XCTAssertGreaterThan(DecorationType.allCases.count, 0, "应有多种装饰类型")
        
        for decoration in DecorationType.allCases {
            XCTAssertFalse(decoration.displayName.isEmpty, "装饰 \(decoration.rawValue) 名称不应为空")
        }
    }
    
    // MARK: - 卡片生成配置测试
    
    func testCardGenerationConfigDefault() {
        let config = CardGenerationConfig.default
        
        XCTAssertEqual(config.style, "starry")
        XCTAssertNil(config.templateId)
        XCTAssertNil(config.platform)
        XCTAssertEqual(config.textEnhancementMode, .none)
        XCTAssertTrue(config.showWatermark)
        XCTAssertTrue(config.includeTags)
        XCTAssertTrue(config.includeEmotions)
        XCTAssertFalse(config.includeDate)
    }
    
    // MARK: - 生成结果测试
    
    func testArtCardGenerationResultEmpty() {
        let empty = ArtCardGenerationResult.empty
        
        XCTAssertFalse(empty.success)
        XCTAssertNil(empty.imagePath)
        XCTAssertNil(empty.imageData)
        XCTAssertEqual(empty.processingTime, 0)
    }
    
    func testCardMetadataEmpty() {
        let empty = CardMetadata.empty
        
        XCTAssertEqual(empty.dreamId, UUID())
        XCTAssertEqual(empty.style, "")
        XCTAssertNil(empty.templateId)
        XCTAssertEqual(empty.dimensions, .zero)
        XCTAssertEqual(empty.fileSize, 0)
    }
    
    // MARK: - 智能背景匹配测试
    
    func testMatchStyleByEmotion() async {
        let dream = Dream(
            title: "测试",
            content: "测试内容",
            tags: [],
            emotions: [.平静]
        )
        
        let style = await service.matchStyle(for: dream)
        
        // 平静情绪应匹配推荐平静的风格
        let recommendedStyles = ArtCardStyle.allCases.filter {
            $0.recommendedEmotions.contains(.平静)
        }
        XCTAssertTrue(
            recommendedStyles.contains(style),
            "应返回推荐平静情绪的风格"
        )
    }
    
    func testMatchStyleByTag() async {
        let dream = Dream(
            title: "星空之梦",
            content: "在星空下",
            tags: ["星空", "宇宙"],
            emotions: []
        )
        
        let style = await service.matchStyle(for: dream)
        
        XCTAssertEqual(style, .starry, "星空标签应匹配星空风格")
    }
    
    func testMatchStyleByContent() async {
        let dream = Dream(
            title: "飞行",
            content: "我在天空中飞翔",
            tags: [],
            emotions: []
        )
        
        let style = await service.matchStyle(for: dream)
        
        XCTAssertEqual(style, .sunrise, "飞行内容应匹配日出风格")
    }
    
    func testMatchStyleDefault() async {
        let dream = Dream(
            title: "普通梦境",
            content: "没有什么特别的内容",
            tags: [],
            emotions: []
        )
        
        let style = await service.matchStyle(for: dream)
        
        XCTAssertEqual(style, .dreamy, "无特征应返回梦幻风格")
    }
    
    // MARK: - 图片格式测试
    
    func testImageFormatCases() {
        XCTAssertEqual(ImageFormat.allCases.count, 3, "应有 3 种图片格式")
        
        XCTAssertEqual(ImageFormat.png.displayName, "PNG (无损)")
        XCTAssertEqual(ImageFormat.jpg.displayName, "JPEG (压缩)")
        XCTAssertEqual(ImageFormat.heic.displayName, "HEIC (高效)")
        
        XCTAssertEqual(ImageFormat.png.mimeType, "image/png")
        XCTAssertEqual(ImageFormat.jpg.mimeType, "image/jpeg")
        XCTAssertEqual(ImageFormat.heic.mimeType, "image/heic")
    }
    
    // MARK: - 卡片统计测试
    
    func testArtCardStatsEmpty() {
        let empty = ArtCardStats.empty
        
        XCTAssertEqual(empty.totalCards, 0)
        XCTAssertTrue(empty.cardsByStyle.isEmpty)
        XCTAssertTrue(empty.cardsByPlatform.isEmpty)
        XCTAssertTrue(empty.favoriteTemplates.isEmpty)
        XCTAssertTrue(empty.recentCards.isEmpty)
        XCTAssertEqual(empty.totalShares, 0)
        XCTAssertNil(empty.mostUsedStyle)
        XCTAssertNil(empty.mostUsedPlatform)
    }
    
    // MARK: - 性能测试
    
    func testTextEnhancementPerformance() async throws {
        let text = "这是一个测试梦境，用于性能测试"
        
        measure {
            let expectation = XCTestExpectation(description: "Text enhancement")
            
            Task {
                _ = try? await service.enhanceText(text, mode: .poetic)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - 边界测试
    
    func testEnhanceTextEmptyString() async throws {
        let result = try await service.enhanceText("", mode: .poetic)
        
        XCTAssertEqual(result.originalText, "")
        XCTAssertEqual(result.enhancedText, "")
    }
    
    func testPlatformOptimizationEmptyString() {
        let opt = PlatformOptimization.default(for: "")
        
        XCTAssertEqual(opt.aspectRatio, 1.0)
        XCTAssertEqual(opt.maxTextLength, 300)
    }
}
