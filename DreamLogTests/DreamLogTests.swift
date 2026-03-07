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
    
    // MARK: - SpeechSynthesisService 测试
    
    func testSpeechConfigDefault() throws {
        let config = SpeechConfig.default
        
        XCTAssertEqual(config.rate, 0.5)
        XCTAssertEqual(config.pitchMultiplier, 1.0)
        XCTAssertEqual(config.volume, 1.0)
        XCTAssertEqual(config.language, "zh-CN")
        XCTAssertNil(config.voiceIdentifier)
    }
    
    func testSpeechConfigEncoding() throws {
        let config = SpeechConfig(
            voiceIdentifier: "com.apple.ttsbundle.Ting-Ting",
            rate: 0.6,
            pitchMultiplier: 1.2,
            volume: 0.8,
            language: "en-US"
        )
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SpeechConfig.self, from: data)
        
        XCTAssertEqual(decoded.voiceIdentifier, config.voiceIdentifier)
        XCTAssertEqual(decoded.rate, config.rate)
        XCTAssertEqual(decoded.pitchMultiplier, config.pitchMultiplier)
        XCTAssertEqual(decoded.volume, config.volume)
        XCTAssertEqual(decoded.language, config.language)
    }
    
    func testSpeechConfigEquatable() throws {
        let config1 = SpeechConfig.default
        let config2 = SpeechConfig.default
        let config3 = SpeechConfig(voiceIdentifier: "test", rate: 0.6, pitchMultiplier: 1.0, volume: 1.0, language: "zh-CN")
        
        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }
    
    func testSpeechServiceSingleton() throws {
        let service1 = SpeechSynthesisService.shared
        let service2 = SpeechSynthesisService.shared
        
        XCTAssertTrue(service1 === service2, "SpeechSynthesisService 应该是单例")
    }
    
    func testSpeechServiceInitialState() throws {
        let service = SpeechSynthesisService.shared
        
        XCTAssertFalse(service.isSpeaking)
        XCTAssertFalse(service.isPaused)
        XCTAssertGreaterThan(service.availableVoices.count, 0, "应该有可用的语音")
    }
    
    func testSpeechServiceConfigPersistence() throws {
        let service = SpeechSynthesisService.shared
        
        // 保存配置
        service.config.rate = 0.7
        service.config.pitchMultiplier = 1.3
        service.config.volume = 0.9
        service.saveConfig()
        
        // 重新加载配置
        service.loadConfig()
        
        XCTAssertEqual(service.config.rate, 0.7, accuracy: 0.01)
        XCTAssertEqual(service.config.pitchMultiplier, 1.3, accuracy: 0.01)
        XCTAssertEqual(service.config.volume, 0.9, accuracy: 0.01)
        
        // 恢复默认
        service.config = .default
        service.saveConfig()
    }
    
    func testSpeechServiceVoiceFiltering() throws {
        let service = SpeechSynthesisService.shared
        
        // 验证语音列表只包含中文和英文
        for voice in service.availableVoices {
            XCTAssertTrue(
                voice.language.hasPrefix("zh") || voice.language.hasPrefix("en"),
                "语音应该是中文或英文：\(voice.name) - \(voice.language)"
            )
        }
    }
    
    func testSpeechServiceEmptyText() throws {
        let service = SpeechSynthesisService.shared
        let expectation = XCTestExpectation(description: "Empty text should not crash")
        
        // 空文本不应该导致崩溃
        service.speak("")
        service.speak("   ")
        
        expectation.fulfill()
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - ImageCacheService 测试
    
    func testImageCacheServiceSingleton() throws {
        let cache1 = ImageCacheService.shared
        let cache2 = ImageCacheService.shared
        
        XCTAssertTrue(cache1 === cache2, "ImageCacheService 应该是单例")
    }
    
    func testImageCacheServiceMemoryLimit() throws {
        let cache = ImageCacheService.shared
        
        // 验证内存缓存限制
        XCTAssertEqual(cache.memoryCache.countLimit, 100, "内存缓存应该限制 100 张图片")
    }
    
    func testImageCacheServiceCacheKey() throws {
        let cache = ImageCacheService.shared
        
        let url1 = "https://example.com/image1.jpg"
        let url2 = "https://example.com/image2.jpg"
        let url3 = "https://example.com/image1.jpg"
        
        let key1 = cache.cacheKey(for: url1)
        let key2 = cache.cacheKey(for: url2)
        let key3 = cache.cacheKey(for: url3)
        
        XCTAssertNotEqual(key1, key2, "不同 URL 应该有不同的缓存键")
        XCTAssertEqual(key1, key3, "相同 URL 应该有相同的缓存键")
    }
    
    func testImageCacheServiceClearCache() throws {
        let cache = ImageCacheService.shared
        
        // 清除缓存不应该崩溃
        cache.clearMemoryCache()
        cache.clearDiskCache()
        cache.clearCache()
    }
    
    // MARK: - CloudSyncService 测试
    
    func testCloudSyncServiceSingleton() throws {
        let service1 = CloudSyncService.shared
        let service2 = CloudSyncService.shared
        
        XCTAssertTrue(service1 === service2, "CloudSyncService 应该是单例")
    }
    
    func testCloudSyncStatusDescriptions() throws {
        let statuses: [CloudSyncStatus] = [.idle, .syncing, .success, .failed("error"), .unavailable, .conflict]
        
        for status in statuses {
            XCTAssertGreaterThan(status.description.count, 0, "状态应该有描述")
            XCTAssertGreaterThan(status.icon.count, 0, "状态应该有图标")
        }
    }
    
    func testSyncConflictDescription() throws {
        let dream = Dream(title: "测试梦境", content: "内容", tags: [], emotions: [])
        let conflict = SyncConflict(
            dreamId: dream.id,
            localVersion: dream,
            cloudVersion: dream,
            modifiedField: "content"
        )
        
        XCTAssertGreaterThan(conflict.resolutionDescription.count, 0)
        XCTAssertTrue(conflict.resolutionDescription.contains("测试梦境"))
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
    
    func testPerformanceImageCache() throws {
        let cache = ImageCacheService.shared
        
        self.measure {
            for i in 0..<50 {
                let url = "https://example.com/image\(i).jpg"
                _ = cache.cacheKey(for: url)
            }
        }
    }
    
    // MARK: - DreamTrendService 测试
    
    func testTrendServiceSingleton() throws {
        let service1 = DreamTrendService.shared
        let service2 = DreamTrendService.shared
        
        XCTAssertTrue(service1 === service2, "DreamTrendService 应该是单例")
    }
    
    func testTrendServiceInitialState() throws {
        let service = DreamTrendService.shared
        
        XCTAssertFalse(service.isAnalyzing, "初始状态不应在分析中")
        XCTAssertNil(service.trendReport, "初始状态不应有报告")
        XCTAssertNil(service.error, "初始状态不应有错误")
    }
    
    func testTrendReportGeneration() async throws {
        let service = DreamTrendService.shared
        
        // 创建测试梦境数据
        let dreams = createTestDreams(count: 10)
        
        let report = await service.generateTrendReport(dreams: dreams, periodDays: 30)
        
        XCTAssertNotNil(report, "应该生成趋势报告")
        XCTAssertFalse(service.isAnalyzing, "分析完成后 should not be analyzing")
        
        if let report = report {
            XCTAssertGreaterThan(report.emotionTrends.count, 0, "应该有情绪趋势数据")
            XCTAssertGreaterThan(report.themeTrends.count, 0, "应该有主题趋势数据")
            XCTAssertGreaterThan(report.predictions.count, 0, "应该有预测数据")
            XCTAssertGreaterThan(report.recommendations.count, 0, "应该有建议数据")
            
            // 验证数据范围
            XCTAssertGreaterThanOrEqual(report.emotionStability, 0)
            XCTAssertLessThanOrEqual(report.emotionStability, 1)
            
            XCTAssertGreaterThanOrEqual(report.averageClarity, 1)
            XCTAssertLessThanOrEqual(report.averageClarity, 5)
            
            XCTAssertGreaterThanOrEqual(report.lucidDreamFrequency, 0)
            XCTAssertLessThanOrEqual(report.lucidDreamFrequency, 100)
        }
    }
    
    func testTrendReportWithInsufficientData() async throws {
        let service = DreamTrendService.shared
        
        // 只创建 2 个梦境 (少于最低要求的 3 个)
        let dreams = createTestDreams(count: 2)
        
        let report = await service.generateTrendReport(dreams: dreams, periodDays: 30)
        
        XCTAssertNil(report, "数据不足时不应生成报告")
        XCTAssertNotNil(service.error, "应该有错误信息")
    }
    
    func testTrendReportWithEmptyData() async throws {
        let service = DreamTrendService.shared
        
        let report = await service.generateTrendReport(dreams: [], periodDays: 30)
        
        XCTAssertNil(report, "空数据不应生成报告")
        XCTAssertNotNil(service.error, "应该有错误信息")
    }
    
    func testTrendDirectionCalculation() async throws {
        let service = DreamTrendService.shared
        
        // 创建具有明显趋势的梦境数据
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        // 最近 14 天的梦境 (更多快乐情绪)
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dreams.append(Dream(
                    title: "近期梦境\(i)",
                    content: "快乐的梦境内容",
                    tags: ["快乐", "美好"],
                    emotions: [.happy, .excited],
                    clarity: 4,
                    isLucid: false,
                    date: date
                ))
            }
        }
        
        // 14 天前的梦境 (更多焦虑情绪)
        for i in 7..<14 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dreams.append(Dream(
                    title: "早期梦境\(i)",
                    content: "焦虑的梦境内容",
                    tags: ["焦虑", "压力"],
                    emotions: [.anxious, .fearful],
                    clarity: 2,
                    isLucid: false,
                    date: date
                ))
            }
        }
        
        let report = await service.generateTrendReport(dreams: dreams, periodDays: 30)
        
        XCTAssertNotNil(report)
        
        if let report = report {
            // 验证快乐情绪呈上升趋势
            let happyTrend = report.emotionTrends.first(where: { $0.emotion == .happy })
            XCTAssertNotNil(happyTrend)
            XCTAssertEqual(happyTrend?.trend, .increasing, "快乐情绪应该呈上升趋势")
            
            // 验证焦虑情绪呈下降趋势
            let anxiousTrend = report.emotionTrends.first(where: { $0.emotion == .anxious })
            XCTAssertNotNil(anxiousTrend)
            XCTAssertEqual(anxiousTrend?.trend, .decreasing, "焦虑情绪应该呈下降趋势")
        }
    }
    
    func testTimePatternAnalysis() async throws {
        let service = DreamTrendService.shared
        var dreams: [Dream] = []
        
        // 创建不同时间段的梦境
        let calendar = Calendar.current
        let now = Date()
        
        // 清晨梦境 (6-12 点)
        for i in 0..<5 {
            if var date = calendar.date(byAdding: .hour, value: 8, to: now) {
                date = calendar.date(byAdding: .day, value: -i, to: date) ?? now
                dreams.append(Dream(
                    title: "清晨梦境\(i)",
                    content: "清晨的梦境",
                    tags: ["清晨"],
                    emotions: [.calm],
                    clarity: 3,
                    isLucid: false,
                    date: date
                ))
            }
        }
        
        let report = await service.generateTrendReport(dreams: dreams, periodDays: 30)
        
        XCTAssertNotNil(report)
        
        if let report = report {
            XCTAssertEqual(report.timePatterns.morningDreams, 5, "应该有 5 个清晨梦境")
            XCTAssertEqual(report.bestRecallTime, .morning, "最佳时段应该是清晨")
        }
    }
    
    func testPredictionGeneration() async throws {
        let service = DreamTrendService.shared
        let dreams = createTestDreams(count: 10)
        
        let report = await service.generateTrendReport(dreams: dreams, periodDays: 30)
        
        XCTAssertNotNil(report)
        
        if let report = report {
            for prediction in report.predictions {
                XCTAssertGreaterThan(prediction.confidence, 0)
                XCTAssertLessThanOrEqual(prediction.confidence, 1)
                XCTAssertGreaterThan(prediction.description.count, 0)
                XCTAssertGreaterThan(prediction.timeFrame.count, 0)
            }
        }
    }
    
    // MARK: - DreamGraphService 测试
    
    func testGraphServiceSingleton() throws {
        let service = DreamGraphService.shared
        XCTAssertNotNil(service)
        XCTAssertTrue(DreamGraphService.shared === service, "应该是单例")
    }
    
    func testGraphServiceInitialState() throws {
        let service = DreamGraphService.shared
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.graphData)
        XCTAssertNil(service.errorMessage)
    }
    
    func testGraphNodeCreation() throws {
        let dream = Dream(
            title: "测试梦境",
            content: "测试内容",
            tags: ["标签 1", "标签 2"],
            emotions: [.happy, .excited],
            clarity: 4,
            isLucid: true
        )
        
        let node = GraphNode(dream: dream)
        
        XCTAssertEqual(node.title, "测试梦境")
        XCTAssertEqual(node.tags.count, 2)
        XCTAssertEqual(node.emotions.count, 2)
        XCTAssertEqual(node.clarity, 4)
        XCTAssertTrue(node.isLucid)
        XCTAssertGreaterThan(node.size, 0)
        XCTAssertFalse(node.color.isEmpty)
    }
    
    func testGraphEdgeRelationshipTypes() throws {
        let allTypes = GraphEdge.RelationshipType.allCases
        XCTAssertEqual(allTypes.count, 6, "应该有 6 种关联类型")
        
        for type in allTypes {
            XCTAssertFalse(type.icon.isEmpty, "图标不应为空")
            XCTAssertFalse(type.color.isEmpty, "颜色不应为空")
            XCTAssertFalse(type.rawValue.isEmpty, "名称不应为空")
        }
    }
    
    func testGraphGenerationWithEmptyData() async throws {
        let service = DreamGraphService.shared
        await service.generateGraph(from: [])
        
        XCTAssertNotNil(service.graphData)
        XCTAssertEqual(service.graphData?.nodes.count, 0)
        XCTAssertEqual(service.graphData?.edges.count, 0)
    }
    
    func testGraphGenerationWithSingleDream() async throws {
        let service = DreamGraphService.shared
        let dreams = [
            Dream(
                title: "单个梦境",
                content: "测试内容",
                tags: ["测试"],
                emotions: [.calm],
                clarity: 3,
                isLucid: false
            )
        ]
        
        await service.generateGraph(from: dreams)
        
        XCTAssertNotNil(service.graphData)
        XCTAssertEqual(service.graphData?.nodes.count, 1)
        XCTAssertEqual(service.graphData?.statistics.totalNodes, 1)
        XCTAssertEqual(service.graphData?.statistics.isolatedNodes, 1)
    }
    
    func testGraphGenerationWithMultipleDreams() async throws {
        let service = DreamGraphService.shared
        let dreams = createTestDreams(count: 5)
        
        await service.generateGraph(from: dreams)
        
        XCTAssertNotNil(service.graphData)
        XCTAssertEqual(service.graphData?.nodes.count, 5)
        XCTAssertGreaterThan(service.graphData?.edges.count ?? 0, 0)
        
        let stats = service.graphData?.statistics
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.totalNodes, 5)
        XCTAssertGreaterThanOrEqual(stats?.density ?? 0, 0)
        XCTAssertLessThanOrEqual(stats?.density ?? 0, 1)
    }
    
    func testGraphStatisticsCalculation() async throws {
        let service = DreamGraphService.shared
        let dreams = createTestDreams(count: 10)
        
        await service.generateGraph(from: dreams)
        
        guard let stats = service.graphData?.statistics else {
            XCTFail("应该有统计数据")
            return
        }
        
        XCTAssertEqual(stats.totalNodes, 10)
        XCTAssertGreaterThanOrEqual(stats.totalEdges, 0)
        XCTAssertGreaterThanOrEqual(stats.averageConnections, 0)
        XCTAssertGreaterThanOrEqual(stats.density, 0)
        XCTAssertLessThanOrEqual(stats.density, 1)
        XCTAssertGreaterThanOrEqual(stats.largestCluster, 1)
        XCTAssertGreaterThanOrEqual(stats.isolatedNodes, 0)
    }
    
    // MARK: - SleepQualityAnalysisService 测试
    
    func testSleepServiceSingleton() throws {
        let service = SleepQualityAnalysisService.shared
        XCTAssertNotNil(service)
        XCTAssertTrue(SleepQualityAnalysisService.shared === service, "应该是单例")
    }
    
    func testSleepServiceInitialState() throws {
        let service = SleepQualityAnalysisService.shared
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.currentReport)
        XCTAssertNil(service.errorMessage)
        XCTAssertEqual(service.historicalReports.count, 0)
    }
    
    func testSleepStageDistributionCoding() throws {
        let distribution = SleepStageDistribution(
            deepSleepPercent: 20.0,
            remSleepPercent: 25.0,
            coreSleepPercent: 50.0,
            awakePercent: 5.0,
            deepSleepDuration: 7200,
            remSleepDuration: 9000,
            coreSleepDuration: 18000,
            awakeDuration: 1800,
            deepSleepQuality: .good,
            remSleepQuality: .excellent
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(distribution)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SleepStageDistribution.self, from: data)
        
        XCTAssertEqual(decoded.deepSleepPercent, distribution.deepSleepPercent)
        XCTAssertEqual(decoded.remSleepPercent, distribution.remSleepPercent)
        XCTAssertEqual(decoded.coreSleepPercent, distribution.coreSleepPercent)
        XCTAssertEqual(decoded.awakePercent, distribution.awakePercent)
    }
    
    func testSleepQualityRatingColors() throws {
        let ratings: [SleepStageDistribution.SleepQualityRating] = [.excellent, .good, .fair, .poor]
        
        for rating in ratings {
            XCTAssertFalse(rating.color.isEmpty, "\(rating.rawValue) 应该有颜色")
            XCTAssertEqual(rating.color.count, 6, "颜色应该是 6 位十六进制")
        }
    }
    
    func testSleepRecommendationPriority() throws {
        let priorities: [SleepRecommendation.Priority] = [.high, .medium, .low]
        
        for priority in priorities {
            XCTAssertFalse(priority.color.isEmpty, "\(priority.rawValue) 应该有颜色")
        }
    }
    
    func testTrendDirectionCases() throws {
        let directions: [SleepQualityReport.TrendDirection] = [.improving, .stable, .declining, .fluctuating]
        
        for direction in directions {
            XCTAssertFalse(direction.rawValue.isEmpty)
        }
    }
    
    func testDreamSleepCorrelationStructure() throws {
        let correlation = DreamSleepCorrelation(
            correlationStrength: 0.75,
            bestSleepQualityDreams: 10,
            poorSleepQualityDreams: 3,
            averageClarityAfterGoodSleep: 4.2,
            averageClarityAfterPoorSleep: 2.8,
            lucidDreamCorrelation: 0.6,
            emotionCorrelation: [.happy: 0.8, .anxious: -0.5],
            insight: "优质睡眠后梦境更清晰"
        )
        
        XCTAssertGreaterThan(correlation.correlationStrength, 0)
        XCTAssertLessThanOrEqual(correlation.correlationStrength, 1)
        XCTAssertGreaterThan(correlation.insight.count, 0)
    }
    
    // MARK: - FriendService 测试
    
    func testFriendInitialization() throws {
        let friend = Friend(
            userId: "user123",
            username: "测试用户",
            bio: "这是一个测试简介",
            dreamCount: 50,
            lucidDreamCount: 10,
            streakDays: 7,
            isFavorite: true
        )
        
        XCTAssertEqual(friend.userId, "user123")
        XCTAssertEqual(friend.username, "测试用户")
        XCTAssertEqual(friend.bio, "这是一个测试简介")
        XCTAssertEqual(friend.dreamCount, 50)
        XCTAssertEqual(friend.lucidDreamCount, 10)
        XCTAssertEqual(friend.streakDays, 7)
        XCTAssertTrue(friend.isFavorite)
        XCTAssertNotNil(friend.id)
        XCTAssertNotNil(friend.addedAt)
    }
    
    func testFriendRequestInitialization() throws {
        let request = FriendRequest(
            fromUserId: "user456",
            fromUsername: "请求用户",
            message: "想加你为好友",
            status: .pending
        )
        
        XCTAssertEqual(request.fromUserId, "user456")
        XCTAssertEqual(request.fromUsername, "请求用户")
        XCTAssertEqual(request.message, "想加你为好友")
        XCTAssertEqual(request.status, .pending)
        XCTAssertNotNil(request.id)
        XCTAssertNotNil(request.createdAt)
    }
    
    func testFriendRequestStatusCases() throws {
        let statuses: [FriendRequestStatus] = [.pending, .accepted, .declined, .blocked]
        
        for status in statuses {
            XCTAssertFalse(status.rawValue.isEmpty)
        }
    }
    
    func testDreamCircleInitialization() throws {
        let circle = DreamCircle(
            name: "测试圈子",
            description: "这是一个测试梦境圈",
            isPrivate: true,
            createdBy: "user123"
        )
        
        XCTAssertEqual(circle.name, "测试圈子")
        XCTAssertEqual(circle.description, "这是一个测试梦境圈")
        XCTAssertTrue(circle.isPrivate)
        XCTAssertEqual(circle.createdBy, "user123")
        XCTAssertEqual(circle.members.count, 0)
        XCTAssertEqual(circle.sharedDreams.count, 0)
        XCTAssertNotNil(circle.id)
        XCTAssertNotNil(circle.createdAt)
    }
    
    func testFriendCommentInitialization() throws {
        let comment = FriendComment(
            dreamId: UUID(),
            userId: "user789",
            username: "评论用户",
            content: "这是一个有趣的梦！",
            reactions: ["👍": 5, "❤️": 3]
        )
        
        XCTAssertEqual(comment.userId, "user789")
        XCTAssertEqual(comment.username, "评论用户")
        XCTAssertEqual(comment.content, "这是一个有趣的梦！")
        XCTAssertEqual(comment.reactions["👍"], 5)
        XCTAssertEqual(comment.reactions["❤️"], 3)
        XCTAssertFalse(comment.isEdited)
        XCTAssertNotNil(comment.id)
        XCTAssertNotNil(comment.createdAt)
    }
    
    func testFriendServiceSingleton() throws {
        let service = FriendService.shared
        XCTAssertNotNil(service)
        XCTAssertTrue(FriendService.shared === service, "应该是单例")
    }
    
    func testFriendServiceInitialState() throws {
        let service = FriendService.shared
        XCTAssertFalse(service.isLoading)
        XCTAssertEqual(service.friends.count, 0)
        XCTAssertEqual(service.pendingRequests.count, 0)
        XCTAssertEqual(service.dreamCircles.count, 0)
        XCTAssertNil(service.errorMessage)
    }
    
    func testFriendServiceAddFriend() async throws {
        let service = FriendService.shared
        
        let friend = Friend(
            userId: "test_user_001",
            username: "测试好友",
            bio: "测试简介",
            dreamCount: 20
        )
        
        await service.addFriend(friend)
        
        XCTAssertEqual(service.friends.count, 1)
        XCTAssertEqual(service.friends.first?.username, "测试好友")
    }
    
    func testFriendServiceToggleFavorite() async throws {
        let service = FriendService.shared
        
        let friend = Friend(
            userId: "test_user_002",
            username: "可收藏好友",
            isFavorite: false
        )
        
        await service.addFriend(friend)
        await service.toggleFavorite(friend)
        
        XCTAssertTrue(service.friends.first?.isFavorite ?? false)
        
        await service.toggleFavorite(friend)
        XCTAssertFalse(service.friends.first?.isFavorite ?? false)
    }
    
    func testFriendServiceRemoveFriend() async throws {
        let service = FriendService.shared
        
        let friend = Friend(
            userId: "test_user_003",
            username: "待删除好友"
        )
        
        await service.addFriend(friend)
        XCTAssertEqual(service.friends.count, 1)
        
        await service.removeFriend(friend)
        XCTAssertEqual(service.friends.count, 0)
    }
    
    func testFriendServiceCreateDreamCircle() async throws {
        let service = FriendService.shared
        
        await service.createDreamCircle(
            name: "测试梦境圈",
            description: "测试描述",
            isPrivate: true
        )
        
        XCTAssertEqual(service.dreamCircles.count, 1)
        XCTAssertEqual(service.dreamCircles.first?.name, "测试梦境圈")
        XCTAssertTrue(service.dreamCircles.first?.isPrivate ?? false)
    }
    
    // MARK: - DreamTimelineService 测试 (Phase 6)
    
    func testTimelineServiceSingleton() throws {
        let service1 = DreamTimelineService.shared
        let service2 = DreamTimelineService.shared
        XCTAssertTrue(service1 === service2, "DreamTimelineService 应该是单例")
    }
    
    func testTimelineServiceInitialState() throws {
        let service = DreamTimelineService.shared
        let filter = TimelineFilter()
        
        XCTAssertFalse(filter.isActive, "初始过滤条件应该是非激活状态")
        XCTAssertEqual(filter.granularity, .week, "默认分组级别应该是周")
        XCTAssertFalse(filter.lucidOnly, "默认不应该只过滤清醒梦")
        XCTAssertEqual(filter.minClarity, 1, "默认最低清晰度应该是 1")
        XCTAssertTrue(filter.selectedTags.isEmpty, "初始标签过滤应该为空")
        XCTAssertTrue(filter.selectedEmotions.isEmpty, "初始情绪过滤应该为空")
    }
    
    func testTimelineDataGeneration() throws {
        let service = DreamTimelineService.shared
        let dreams = createTestDreams(count: 20)
        
        let dataPoints = service.generateTimelineData(dreams: dreams, filter: TimelineFilter())
        
        XCTAssertGreaterThan(dataPoints.count, 0, "应该生成时间轴数据点")
        
        for point in dataPoints {
            XCTAssertGreaterThanOrEqual(point.dreamCount, 0, "梦境数量应该非负")
            XCTAssertGreaterThanOrEqual(point.avgClarity, 0, "平均清晰度应该非负")
            XCTAssertLessThanOrEqual(point.avgClarity, 5, "平均清晰度应该不超过 5")
            XCTAssertGreaterThanOrEqual(point.avgIntensity, 0, "平均强度应该非负")
            XCTAssertLessThanOrEqual(point.avgIntensity, 5, "平均强度应该不超过 5")
            XCTAssertGreaterThanOrEqual(point.lucidDreamCount, 0, "清醒梦数量应该非负")
        }
    }
    
    func testTimelineDataWithEmptyDreams() throws {
        let service = DreamTimelineService.shared
        let dataPoints = service.generateTimelineData(dreams: [], filter: TimelineFilter())
        
        XCTAssertEqual(dataPoints.count, 0, "空梦境列表应该返回空数据点")
    }
    
    func testTimelineFilterByTags() throws {
        let service = DreamTimelineService.shared
        let dreams = createTestDreams(count: 10)
        
        var filter = TimelineFilter()
        filter.selectedTags = ["标签 0"]
        
        let filteredData = service.generateTimelineData(dreams: dreams, filter: filter)
        let allData = service.generateTimelineData(dreams: dreams, filter: TimelineFilter())
        
        XCTAssertLessThanOrEqual(filteredData.count, allData.count, "过滤后数据点应该不多于全部数据")
    }
    
    func testTimelineFilterByLucidDreams() throws {
        let service = DreamTimelineService.shared
        let dreams = createTestDreams(count: 15)
        
        var filter = TimelineFilter()
        filter.lucidOnly = true
        
        let lucidData = service.generateTimelineData(dreams: dreams, filter: filter)
        let allData = service.generateTimelineData(dreams: dreams, filter: TimelineFilter())
        
        let totalLucidInAllData = lucidData.reduce(0) { $0 + $1.lucidDreamCount }
        let totalInAllData = allData.reduce(0) { $0 + $1.dreamCount }
        
        XCTAssertLessThanOrEqual(totalLucidInAllData, totalInAllData, "清醒梦数量应该不超过总梦境数")
    }
    
    func testTimelineFilterByClarity() throws {
        let service = DreamTimelineService.shared
        let dreams = createTestDreams(count: 15)
        
        var filter = TimelineFilter()
        filter.minClarity = 4
        
        let highClarityData = service.generateTimelineData(dreams: dreams, filter: filter)
        let allData = service.generateTimelineData(dreams: dreams, filter: TimelineFilter())
        
        XCTAssertLessThanOrEqual(highClarityData.count, allData.count, "高清晰度过滤后数据应该不多于全部数据")
    }
    
    func testTimelineStatsGeneration() throws {
        let service = DreamTimelineService.shared
        let dreams = createTestDreams(count: 20)
        
        let stats = service.getTimelineStats(dreams: dreams, filter: TimelineFilter())
        
        XCTAssertEqual(stats.totalDreams, dreams.count, "总梦境数应该匹配")
        XCTAssertGreaterThanOrEqual(stats.avgClarity, 0, "平均清晰度应该非负")
        XCTAssertLessThanOrEqual(stats.avgClarity, 5, "平均清晰度应该不超过 5")
        XCTAssertGreaterThanOrEqual(stats.avgIntensity, 0, "平均强度应该非负")
        XCTAssertLessThanOrEqual(stats.avgIntensity, 5, "平均强度应该不超过 5")
        XCTAssertGreaterThanOrEqual(stats.lucidDreamPercentage, 0, "清醒梦百分比应该非负")
        XCTAssertLessThanOrEqual(stats.lucidDreamPercentage, 100, "清醒梦百分比应该不超过 100")
    }
    
    func testTimelineStatsWithEmptyData() throws {
        let service = DreamTimelineService.shared
        let stats = service.getTimelineStats(dreams: [], filter: TimelineFilter())
        
        XCTAssertEqual(stats.totalDreams, 0, "空数据总梦境数应该为 0")
        XCTAssertEqual(stats.avgClarity, 0, "空数据平均清晰度应该为 0")
        XCTAssertEqual(stats.avgIntensity, 0, "空数据平均强度应该为 0")
        XCTAssertEqual(stats.lucidDreamPercentage, 0, "空数据清醒梦百分比应该为 0")
    }
    
    func testTimelineGranularityAllCases() throws {
        let granularities = TimelineGranularity.allCases
        
        XCTAssertEqual(granularities.count, 4, "应该有 4 种分组级别")
        XCTAssertTrue(granularities.contains(.day), "应该包含天")
        XCTAssertTrue(granularities.contains(.week), "应该包含周")
        XCTAssertTrue(granularities.contains(.month), "应该包含月")
        XCTAssertTrue(granularities.contains(.year), "应该包含年")
        
        for granularity in granularities {
            XCTAssertFalse(granularity.icon.isEmpty, "分组级别应该有图标")
            XCTAssertFalse(granularity.rawValue.isEmpty, "分组级别应该有名称")
        }
    }
    
    // MARK: - 辅助方法
    
    private func createTestDreams(count: Int) -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        for i in 0..<count {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dreams.append(Dream(
                    title: "测试梦境\(i)",
                    content: "这是第\(i)个测试梦境的内容，包含一些描述性的文字。",
                    tags: ["测试", "标签\(i % 3)"],
                    emotions: i % 2 == 0 ? [.happy] : [.calm],
                    clarity: 3 + (i % 3),
                    isLucid: i % 3 == 0,
                    date: date
                ))
            }
        }
        
        return dreams
    }
}
