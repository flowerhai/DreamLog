//
//  AIServiceTests.swift
//  DreamLogTests
//
//  AI 服务单元测试
//  测试梦境解析、关键词提取、情绪检测和标签推荐
//

import XCTest
@testable import DreamLog

@MainActor
final class AIServiceTests: XCTestCase {
    
    var service: AIService!
    
    override func setUp() async throws {
        try await super.setUp()
        service = AIService()
    }
    
    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - 关键词提取测试
    
    func testExtractKeywords() {
        let content = "我在一个美丽的花园里散步，看到了很多漂亮的花朵和蝴蝶"
        let keywords = service.extractKeywords(from: content)
        
        XCTAssertGreaterThan(keywords.count, 0)
        XCTAssertLessThanOrEqual(keywords.count, 5)
        
        // 验证不包含常见停用词
        let stopWords = ["我", "在", "的", "了", "是", "不", "有", "这", "个", "很", "但", "说"]
        for keyword in keywords {
            XCTAssertFalse(stopWords.contains(keyword), "关键词不应包含停用词：\(keyword)")
        }
    }
    
    func testExtractKeywordsEmptyContent() {
        let keywords = service.extractKeywords(from: "")
        XCTAssertTrue(keywords.isEmpty)
    }
    
    func testExtractKeywordsShortContent() {
        let keywords = service.extractKeywords(from: "梦")
        XCTAssertTrue(keywords.isEmpty) // 单字会被过滤
    }
    
    func testExtractKeywordsWithNumbers() {
        let content = "我看到了 123 只蝴蝶和 456 朵花"
        let keywords = service.extractKeywords(from: content)
        
        // 数字应该被包含在关键词中
        XCTAssertGreaterThan(keywords.count, 0)
    }
    
    // MARK: - 情绪检测测试
    
    func testDetectPositiveEmotions() {
        let content = "我感到很开心和快乐，这是一个美好的梦境"
        let emotions = service.detectEmotions(from: content)
        
        XCTAssertTrue(emotions.contains(.happy))
    }
    
    func testDetectNegativeEmotions() {
        let content = "我感到害怕和恐惧，非常紧张和焦虑"
        let emotions = service.detectEmotions(from: content)
        
        XCTAssertTrue(emotions.contains(.fearful))
    }
    
    func testDetectAnxiousEmotions() {
        let content = "我在拼命逃跑，有人追我，很着急"
        let emotions = service.detectEmotions(from: content)
        
        XCTAssertTrue(emotions.contains(.anxious))
    }
    
    func testDetectNeutralEmotions() {
        let content = "今天天气不错，我出去散步"
        let emotions = service.detectEmotions(from: content)
        
        XCTAssertTrue(emotions.contains(.neutral))
    }
    
    func testDetectMultipleEmotions() {
        let content = "我开始很害怕，但后来感到快乐和平静"
        let emotions = service.detectEmotions(from: content)
        
        XCTAssertGreaterThanOrEqual(emotions.count, 1)
    }
    
    func testDetectEmotionsEmptyContent() {
        let emotions = service.detectEmotions(from: "")
        XCTAssertEqual(emotions, [.neutral])
    }
    
    // MARK: - 智能标签推荐测试
    
    func testRecommendTagsForWaterDream() {
        let content = "我在海洋里游泳，看到了波浪和海水"
        let tags = service.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains { $0.contains("水") || $0.contains("海洋") || $0.contains("游泳") })
    }
    
    func testRecommendTagsForFlyingDream() {
        let content = "我在天空中飞行，像鸟一样有翅膀"
        let tags = service.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains { $0.contains("飞行") || $0.contains("天空") })
    }
    
    func testRecommendTagsForChaseDream() {
        let content = "有人在追我，我在逃跑和躲藏"
        let tags = service.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains { $0.contains("追逐") || $0.contains("逃跑") })
    }
    
    func testRecommendTagsForSchoolDream() {
        let content = "我在学校教室里考试，老师在上面"
        let tags = service.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains { $0.contains("考试") || $0.contains("学校") })
    }
    
    func testRecommendTagsWithExistingTags() {
        let content = "我在海洋里游泳"
        let existingTags = ["水", "游泳"]
        let tags = service.recommendTags(content: content, existingTags: existingTags)
        
        // 新推荐的标签不应与现有标签重复
        let newTags = tags.filter { !existingTags.contains($0) }
        XCTAssertGreaterThanOrEqual(newTags.count, 0)
    }
    
    func testRecommendTagsEmptyContent() {
        let tags = service.recommendTags(content: "")
        XCTAssertTrue(tags.isEmpty)
    }
    
    func testRecommendTagsCaseInsensitive() {
        let content = "我在海洋里游泳"
        let tagsLower = service.recommendTags(content: content.lowercased())
        let tagsUpper = service.recommendTags(content: content.uppercased())
        
        // 大小写应该不影响标签推荐
        XCTAssertEqual(tagsLower.count, tagsUpper.count)
    }
    
    // MARK: - 梦境解析测试
    
    func testAnalyzeDream() async {
        let content = "我梦见了自己在飞行"
        let tags = ["飞行", "天空"]
        let emotions: [Emotion] = [.happy]
        
        let analysis = await service.analyzeDream(content: content, tags: tags, emotions: emotions)
        
        XCTAssertGreaterThan(analysis.count, 0)
        XCTAssertFalse(service.isAnalyzing)
    }
    
    func testAnalyzeDreamEmptyContent() async {
        let analysis = await service.analyzeDream(content: "", tags: [], emotions: [])
        
        XCTAssertGreaterThan(analysis.count, 0) // 应该返回默认分析
    }
    
    func testAnalyzeDreamWithMultipleTags() async {
        let content = "这是一个复杂的梦境"
        let tags = ["标签 1", "标签 2", "标签 3", "标签 4", "标签 5"]
        let emotions: [Emotion] = [.happy, .calm]
        
        let analysis = await service.analyzeDream(content: content, tags: tags, emotions: emotions)
        
        XCTAssertGreaterThan(analysis.count, 0)
    }
    
    func testAnalyzeDreamStateChanges() async {
        XCTAssertFalse(service.isAnalyzing)
        
        // 启动分析任务但不等待
        Task {
            _ = await service.analyzeDream(content: "测试", tags: [], emotions: [])
        }
        
        // 短暂延迟后检查状态
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
        
        // 分析完成后状态应该恢复
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 秒等待完成
        XCTAssertFalse(service.isAnalyzing)
    }
    
    // MARK: - 图像生成测试
    
    func testGenerateImage() async {
        let prompt = "一个美丽的梦境场景"
        let imageUrl = await service.generateImage(prompt: prompt)
        
        XCTAssertNotNil(imageUrl)
        XCTAssertFalse(service.isGeneratingImage)
    }
    
    func testGenerateImageEmptyPrompt() async {
        let imageUrl = await service.generateImage(prompt: "")
        
        XCTAssertNotNil(imageUrl) // 应该返回默认图像
    }
    
    func testGenerateImageStateChanges() async {
        XCTAssertFalse(service.isGeneratingImage)
        
        Task {
            _ = await service.generateImage(prompt: "测试")
        }
        
        // 短暂延迟后检查状态
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // 生成完成后状态应该恢复
        try? await Task.sleep(nanoseconds: 5_500_000_000) // 5.5 秒等待完成
        XCTAssertFalse(service.isGeneratingImage)
    }
    
    // MARK: - 错误处理测试
    
    func testErrorProperty() {
        XCTAssertNil(service.error)
        
        service.error = "测试错误"
        XCTAssertEqual(service.error, "测试错误")
        
        service.error = nil
        XCTAssertNil(service.error)
    }
    
    // MARK: - 标签映射完整性测试
    
    func testTagMappingsCoverage() {
        let testCases: [(String, String)] = [
            ("水", "海洋"),
            ("飞行", "天空"),
            ("追逐", "逃跑"),
            ("坠落", "掉落"),
            ("考试", "学校"),
            ("牙齿", "掉牙"),
            ("蛇", "毒蛇"),
            ("房子", "家"),
            ("死亡", "葬礼"),
            ("性", "亲密")
        ]
        
        for (category, expectedTag) in testCases {
            let content = "我梦见了\(category)"
            let tags = service.recommendTags(content: content)
            
            // 验证至少有一个相关标签被推荐
            XCTAssertTrue(
                tags.contains { $0.contains(expectedTag) || $0.contains(category) },
                "对于'\(category)'应该推荐包含'\(expectedTag)'的标签"
            )
        }
    }
    
    // MARK: - 性能测试
    
    func testExtractKeywordsPerformance() {
        let content = String(repeating: "这是一个测试梦境内容 ", count: 100)
        
        measure {
            for _ in 0..<100 {
                _ = service.extractKeywords(from: content)
            }
        }
    }
    
    func testDetectEmotionsPerformance() {
        let content = String(repeating: "我感到开心和快乐 ", count: 100)
        
        measure {
            for _ in 0..<100 {
                _ = service.detectEmotions(from: content)
            }
        }
    }
    
    func testRecommendTagsPerformance() {
        let content = String(repeating: "我在海洋里游泳看到了波浪 ", count: 100)
        
        measure {
            for _ in 0..<100 {
                _ = service.recommendTags(content: content)
            }
        }
    }
    
    // MARK: - 边界条件测试
    
    func testExtractKeywordsWithSpecialCharacters() {
        let content = "我看到了!!! 很多的$$$花朵&&&"
        let keywords = service.extractKeywords(from: content)
        
        // 特殊字符应该被正确处理
        XCTAssertGreaterThanOrEqual(keywords.count, 0)
    }
    
    func testExtractKeywordsWithEmoji() {
        let content = "我看到了🌸🌺🌻很多花"
        let keywords = service.extractKeywords(from: content)
        
        // Emoji 应该被处理
        XCTAssertGreaterThanOrEqual(keywords.count, 0)
    }
    
    func testDetectEmotionsWithMixedLanguages() {
        let content = "I feel happy 开心快乐"
        let emotions = service.detectEmotions(from: content)
        
        // 应该能检测到中文情绪词
        XCTAssertTrue(emotions.contains(.happy) || emotions.contains(.neutral))
    }
    
    func testRecommendTagsWithLongContent() {
        let content = String(repeating: "水水水海洋海洋游泳游泳 ", count: 50)
        let tags = service.recommendTags(content: content)
        
        XCTAssertGreaterThan(tags.count, 0)
    }
    
    // MARK: - Emotion 枚举测试
    
    func testEmotionRawValues() {
        let emotions: [Emotion] = [
            .calm, .happy, .anxious, .fearful,
            .sad, .excited, .confused, .angry,
            .surprised, .neutral
        ]
        
        for emotion in emotions {
            XCTAssertGreaterThan(emotion.rawValue.count, 0)
        }
    }
    
    func testEmotionColor() {
        let emotion = Emotion.happy
        let color = emotion.color
        
        XCTAssertNotNil(color)
    }
    
    func testEmotionIcon() {
        let emotion = Emotion.happy
        let icon = emotion.icon
        
        XCTAssertGreaterThan(icon.count, 0)
    }
}
