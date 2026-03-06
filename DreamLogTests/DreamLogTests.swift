//
//  DreamLogTests.swift
//  DreamLogTests
//
//  单元测试
//

import XCTest
@testable import DreamLog

final class DreamLogTests: XCTestCase {
    
    var dreamStore: DreamStore!
    var speechService: SpeechService!
    var aiService: AIService!
    
    override func setUpWithError() throws {
        dreamStore = DreamStore()
        speechService = SpeechService()
        aiService = AIService()
    }
    
    override func tearDownWithError() throws {
        dreamStore = nil
        speechService = nil
        aiService = nil
    }
    
    // MARK: - DreamStore 测试
    
    func testAddDream() throws {
        let initialCount = dreamStore.dreams.count
        
        let dream = Dream(
            title: "测试梦境",
            content: "这是一个测试梦境内容",
            tags: ["测试"],
            emotions: [.happy]
        )
        
        dreamStore.addDream(dream)
        
        XCTAssertEqual(dreamStore.dreams.count, initialCount + 1)
        XCTAssertEqual(dreamStore.dreams.first?.title, "测试梦境")
    }
    
    func testUpdateDream() throws {
        let dream = Dream(
            title: "原始标题",
            content: "原始内容",
            tags: ["原始"],
            emotions: [.calm]
        )
        
        dreamStore.addDream(dream)
        
        let updatedDream = dream
        updatedDream.title = "更新后的标题"
        updatedDream.content = "更新后的内容"
        
        dreamStore.updateDream(updatedDream)
        
        XCTAssertEqual(dreamStore.dreams.first?.title, "更新后的标题")
        XCTAssertEqual(dreamStore.dreams.first?.content, "更新后的内容")
    }
    
    func testDeleteDream() throws {
        let dream = Dream(
            title: "待删除梦境",
            content: "这个梦境将被删除",
            tags: ["删除"],
            emotions: [.sad]
        )
        
        dreamStore.addDream(dream)
        let dreamId = dream.id
        
        dreamStore.deleteDream(dream)
        
        XCTAssertNil(dreamStore.getDream(by: dreamId))
    }
    
    func testFilterDreamsByText() throws {
        let dream1 = Dream(title: "飞行梦", content: "我在天空中飞翔", tags: ["飞行"], emotions: [.excited])
        let dream2 = Dream(title: "海边梦", content: "我在海边散步", tags: ["水", "海滩"], emotions: [.calm])
        
        dreamStore.addDream(dream1)
        dreamStore.addDream(dream2)
        
        dreamStore.filterDreams(searchText: "飞行")
        
        XCTAssertEqual(dreamStore.filteredDreams.count, 1)
        XCTAssertEqual(dreamStore.filteredDreams.first?.title, "飞行梦")
    }
    
    func testFilterByTag() throws {
        let dream1 = Dream(title: "梦 1", content: "内容 1", tags: ["飞行", "自由"], emotions: [.happy])
        let dream2 = Dream(title: "梦 2", content: "内容 2", tags: ["水", "海滩"], emotions: [.calm])
        
        dreamStore.addDream(dream1)
        dreamStore.addDream(dream2)
        
        dreamStore.filterByTag("飞行")
        
        XCTAssertEqual(dreamStore.filteredDreams.count, 1)
    }
    
    func testFilterByEmotion() throws {
        let dream1 = Dream(title: "梦 1", content: "内容 1", tags: [], emotions: [.happy, .excited])
        let dream2 = Dream(title: "梦 2", content: "内容 2", tags: [], emotions: [.calm, .sad])
        
        dreamStore.addDream(dream1)
        dreamStore.addDream(dream2)
        
        dreamStore.filterByEmotion(.happy)
        
        XCTAssertEqual(dreamStore.filteredDreams.count, 1)
    }
    
    func testGetStatistics() throws {
        let dream1 = Dream(title: "梦 1", content: "内容 1", tags: [], emotions: [.happy], clarity: 4, intensity: 3, isLucid: true)
        let dream2 = Dream(title: "梦 2", content: "内容 2", tags: [], emotions: [.calm], clarity: 3, intensity: 2, isLucid: false)
        
        dreamStore.addDream(dream1)
        dreamStore.addDream(dream2)
        
        let stats = dreamStore.getStatistics()
        
        XCTAssertEqual(stats.totalDreams, 2)
        XCTAssertEqual(stats.lucidDreams, 1)
        XCTAssertEqual(stats.averageClarity, 3.5, accuracy: 0.01)
    }
    
    func testExportDreams() throws {
        let dream = Dream(title: "导出测试", content: "测试内容", tags: ["测试"], emotions: [.neutral])
        dreamStore.addDream(dream)
        
        let data = dreamStore.exportDreams()
        
        XCTAssertNotNil(data)
        
        // 验证可以重新导入
        let imported = dreamStore.importDreams(from: data!)
        XCTAssertTrue(imported)
    }
    
    // MARK: - AIService 测试
    
    func testExtractKeywords() async throws {
        let content = "我梦见在海边散步，看到了美丽的贝壳和海浪"
        let keywords = aiService.extractKeywords(from: content)
        
        XCTAssertGreaterThan(keywords.count, 0)
        XCTAssertLessThanOrEqual(keywords.count, 5)
    }
    
    func testDetectEmotions() async throws {
        let positiveContent = "我感到很开心和快乐，非常自由"
        let positiveEmotions = aiService.detectEmotions(from: positiveContent)
        
        XCTAssertTrue(positiveEmotions.contains(.happy))
        
        let negativeContent = "我很害怕和紧张，想要逃跑"
        let negativeEmotions = aiService.detectEmotions(from: negativeContent)
        
        XCTAssertTrue(negativeEmotions.contains(.fearful) || negativeEmotions.contains(.anxious))
    }
    
    func testAnalyzeDream() async throws {
        let content = "我梦见自己在海边散步，感觉很平静"
        let analysis = await aiService.analyzeDream(content: content, tags: ["水", "海滩"], emotions: [.calm])
        
        XCTAssertGreaterThan(analysis.count, 0)
        XCTAssertTrue(analysis.contains("水") || analysis.contains("情绪"))
    }
    
    // MARK: - 智能标签推荐测试
    
    func testRecommendTags_Water() async throws {
        let content = "我梦见在海洋里游泳，海浪很大，还下雨了"
        let tags = aiService.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains("水"), "应该推荐'水'标签")
    }
    
    func testRecommendTags_Flying() async throws {
        let content = "我在天空中飞翔，漂浮在空中，看到了翅膀"
        let tags = aiService.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains("飞行"), "应该推荐'飞行'标签")
    }
    
    func testRecommendTags_Chase() async throws {
        let content = "有人在追我，我拼命逃跑，躲藏起来"
        let tags = aiService.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains("追逐"), "应该推荐'追逐'标签")
    }
    
    func testRecommendTags_Emotions() async throws {
        let content = "我感到很开心快乐，非常兴奋和激动"
        let tags = aiService.recommendTags(content: content)
        
        XCTAssertTrue(tags.contains("快乐") || tags.contains("兴奋"), "应该推荐情绪标签")
    }
    
    func testRecommendTags_ExcludeExisting() async throws {
        let content = "我梦见在海边游泳，很开心"
        let existingTags = ["水", "快乐"]
        let tags = aiService.recommendTags(content: content, existingTags: existingTags)
        
        XCTAssertFalse(tags.contains("水"), "不应推荐已存在的标签")
        XCTAssertFalse(tags.contains("快乐"), "不应推荐已存在的标签")
    }
    
    // MARK: - 梦境相似度匹配测试
    
    func testCalculateSimilarity_SameTags() async throws {
        let dream1 = Dream(title: "梦 1", content: "内容 1", tags: ["水", "飞行"], emotions: [.happy, .calm], clarity: 4, intensity: 3, isLucid: false)
        let dream2 = Dream(title: "梦 2", content: "内容 2", tags: ["水", "飞行"], emotions: [.happy, .calm], clarity: 4, intensity: 3, isLucid: false)
        
        let similarity = aiService.calculateSimilarity(between: dream1, and: dream2)
        
        XCTAssertGreaterThan(similarity, 0.8, "相同标签和情绪的梦境应该高度相似")
    }
    
    func testCalculateSimilarity_DifferentTags() async throws {
        let dream1 = Dream(title: "梦 1", content: "内容 1", tags: ["水"], emotions: [.happy], clarity: 4, intensity: 3, isLucid: false)
        let dream2 = Dream(title: "梦 2", content: "内容 2", tags: ["飞行"], emotions: [.fearful], clarity: 2, intensity: 5, isLucid: true)
        
        let similarity = aiService.calculateSimilarity(between: dream1, and: dream2)
        
        XCTAssertLessThan(similarity, 0.5, "不同标签和情绪的梦境应该相似度较低")
    }
    
    func testFindSimilarDreams() async throws {
        // 准备测试数据
        let dream1 = Dream(title: "海边梦", content: "在海边散步", tags: ["水", "海滩"], emotions: [.calm], clarity: 4, intensity: 2, isLucid: false)
        let dream2 = Dream(title: "飞行梦", content: "在空中飞翔", tags: ["飞行", "自由"], emotions: [.excited], clarity: 5, intensity: 5, isLucid: true)
        let dream3 = Dream(title: "海洋梦", content: "在海洋里游泳", tags: ["水", "海洋"], emotions: [.calm, .happy], clarity: 4, intensity: 3, isLucid: false)
        
        dreamStore.addDream(dream1)
        dreamStore.addDream(dream2)
        dreamStore.addDream(dream3)
        
        let targetDream = Dream(title: "测试梦", content: "在水边", tags: ["水"], emotions: [.calm], clarity: 4, intensity: 2, isLucid: false)
        let similarDreams = aiService.findSimilarDreams(to: targetDream, in: dreamStore.dreams, limit: 2)
        
        XCTAssertGreaterThan(similarDreams.count, 0, "应该找到相似梦境")
        
        // dream1 和 dream3 应该比 dream2 更相似 (因为都有"水"标签和 calm 情绪)
        if similarDreams.count >= 2 {
            XCTAssertGreaterThanOrEqual(similarDreams[0].similarity, similarDreams[1].similarity, "结果应该按相似度排序")
        }
    }
    
    func testJaccardSimilarity() async throws {
        let set1: Set<String> = ["a", "b", "c"]
        let set2: Set<String> = ["b", "c", "d"]
        
        // Jaccard = 交集/并集 = 2/4 = 0.5
        let similarity = aiService.jaccardSimilarity(set1: set1, set2: set2)
        
        XCTAssertEqual(similarity, 0.5, accuracy: 0.01)
    }
    
    // MARK: - Dream 模型测试
    
    func testDreamInitialization() throws {
        let dream = Dream(
            title: "测试",
            content: "内容",
            tags: ["标签"],
            emotions: [.happy],
            clarity: 4,
            intensity: 3,
            isLucid: true
        )
        
        XCTAssertEqual(dream.title, "测试")
        XCTAssertEqual(dream.content, "内容")
        XCTAssertEqual(dream.tags, ["标签"])
        XCTAssertEqual(dream.emotions, [.happy])
        XCTAssertEqual(dream.clarity, 4)
        XCTAssertEqual(dream.intensity, 3)
        XCTAssertTrue(dream.isLucid)
    }
    
    func testTimeOfDayFromHour() throws {
        let calendar = Calendar.current
        var components = DateComponents()
        
        // 凌晨 (0-6)
        components.hour = 3
        let earlyMorningDate = calendar.date(from: components)!
        XCTAssertEqual(TimeOfDay.from(date: earlyMorningDate), .earlyMorning)
        
        // 早上 (6-12)
        components.hour = 9
        let morningDate = calendar.date(from: components)!
        XCTAssertEqual(TimeOfDay.from(date: morningDate), .morning)
        
        // 下午 (12-18)
        components.hour = 15
        let afternoonDate = calendar.date(from: components)!
        XCTAssertEqual(TimeOfDay.from(date: afternoonDate), .afternoon)
        
        // 傍晚 (18-24)
        components.hour = 21
        let eveningDate = calendar.date(from: components)!
        XCTAssertEqual(TimeOfDay.from(date: eveningDate), .evening)
    }
    
    // MARK: - 性能测试
    
    func testPerformanceExample() throws {
        self.measure {
            for _ in 0..<100 {
                let dream = Dream(
                    title: "性能测试梦境",
                    content: "这是一个用于性能测试的梦境内容，包含一些描述性的文字。",
                    tags: ["测试", "性能"],
                    emotions: [.neutral]
                )
                dreamStore.addDream(dream)
            }
        }
    }
}
