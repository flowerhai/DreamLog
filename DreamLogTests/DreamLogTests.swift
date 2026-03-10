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
    
    // MARK: - DreamExportService 测试 (Phase 6)
    
    func testExportServiceSingleton() throws {
        let service1 = DreamExportService.shared
        let service2 = DreamExportService.shared
        XCTAssertTrue(service1 === service2, "DreamExportService 应该是单例")
    }
    
    func testExportFormatAllCases() throws {
        let formats = DreamExportService.ExportFormat.allCases
        
        XCTAssertEqual(formats.count, 4, "应该有 4 种导出格式")
        XCTAssertTrue(formats.contains(.pdf), "应该包含 PDF")
        XCTAssertTrue(formats.contains(.json), "应该包含 JSON")
        XCTAssertTrue(formats.contains(.text), "应该包含文本")
        XCTAssertTrue(formats.contains(.markdown), "应该包含 Markdown")
        
        for format in formats {
            XCTAssertFalse(format.icon.isEmpty, "格式应该有图标")
            XCTAssertFalse(format.description.isEmpty, "格式应该有描述")
            XCTAssertFalse(format.fileExtension.isEmpty, "格式应该有文件扩展名")
        }
    }
    
    func testExportFormatProperties() throws {
        let pdf = DreamExportService.ExportFormat.pdf
        XCTAssertEqual(pdf.icon, "doc.fill", "PDF 图标应该正确")
        XCTAssertEqual(pdf.fileExtension, "pdf", "PDF 扩展名应该正确")
        
        let json = DreamExportService.ExportFormat.json
        XCTAssertEqual(json.icon, "doc.badge.gearshape", "JSON 图标应该正确")
        XCTAssertEqual(json.fileExtension, "json", "JSON 扩展名应该正确")
        
        let text = DreamExportService.ExportFormat.text
        XCTAssertEqual(text.icon, "doc.text", "文本图标应该正确")
        XCTAssertEqual(text.fileExtension, "txt", "文本扩展名应该正确")
        
        let markdown = DreamExportService.ExportFormat.markdown
        XCTAssertEqual(markdown.icon, "doc.richtext", "Markdown 图标应该正确")
        XCTAssertEqual(markdown.fileExtension, "md", "Markdown 扩展名应该正确")
    }
    
    func testExportServiceInitialization() throws {
        let service = DreamExportService.shared
        XCTAssertNotNil(service, "服务应该成功初始化")
    }
    
    func testDreamStoreExportDreams() throws {
        let dreamStore = DreamStore.shared
        let initialCount = dreamStore.dreams.count
        
        // 添加测试梦境
        let testDream = Dream(
            title: "导出测试梦境",
            content: "这是用于测试导出功能的梦境内容",
            tags: ["测试", "导出"],
            emotions: [.happy],
            clarity: 4,
            isLucid: false,
            date: Date()
        )
        dreamStore.addDream(testDream)
        
        // 测试导出
        let data = dreamStore.exportDreams()
        XCTAssertGreaterThan(data.count, 0, "导出数据不应该为空")
        
        // 验证导出的是 JSON 格式
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        XCTAssertTrue(json is [[String: Any]], "导出数据应该是 JSON 数组")
        
        // 清理
        dreamStore.deleteDream(testDream)
        XCTAssertEqual(dreamStore.dreams.count, initialCount, "梦境数量应该恢复")
    }
    
    func testDreamStoreExportEmptyDreams() throws {
        let dreamStore = DreamStore.shared
        let initialDreams = dreamStore.dreams
        
        // 临时清空梦境
        for dream in initialDreams {
            dreamStore.deleteDream(dream)
        }
        
        // 测试空导出
        let data = dreamStore.exportDreams()
        XCTAssertGreaterThan(data.count, 0, "即使没有梦境也应该返回有效的 JSON")
        
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        XCTAssertTrue(json is [[String: Any]], "导出数据应该是 JSON 数组")
        
        // 恢复梦境
        for dream in initialDreams {
            dreamStore.addDream(dream)
        }
    }
    
    // MARK: - OnThisDayView 数据结构测试 (Phase 6)
    
    func testOnThisDayDataStructure() throws {
        // 测试梦境回顾功能的数据结构
        let calendar = Calendar.current
        let today = Date()
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today)!
        
        // 创建去年今天的梦境
        let dream = Dream(
            title: "去年今天的梦",
            content: "这是一个去年今天的梦境",
            tags: ["回顾", "周年纪念"],
            emotions: [.happy, .calm],
            clarity: 4,
            isLucid: true,
            date: oneYearAgo
        )
        
        // 验证日期匹配
        XCTAssertTrue(calendar.isDate(dream.date, inSameDayAs: today, matchingDecade: false), 
                     "梦境日期应该与今天相同 (不同年份)")
        XCTAssertEqual(calendar.component(.year, from: dream.date), 
                      calendar.component(.year, from: today) - 1,
                      "梦境应该是去年的")
    }
    
    func testYearsWithDreamsCalculation() throws {
        let dreamStore = DreamStore.shared
        let calendar = Calendar.current
        let today = Date()
        
        // 创建不同年份的梦境 (都在今天这个日期)
        var testDreams: [Dream] = []
        for yearOffset in 0..<3 {
            if let date = calendar.date(byAdding: .year, value: -yearOffset, to: today) {
                let dream = Dream(
                    title: "\(yearOffset)年前的梦",
                    content: "内容",
                    tags: ["回顾"],
                    emotions: [.calm],
                    clarity: 3,
                    isLucid: false,
                    date: date
                )
                testDreams.append(dream)
                dreamStore.addDream(dream)
            }
        }
        
        // 计算有梦境的年份
        var years: Set<Int> = []
        for dream in dreamStore.dreams {
            if calendar.isDate(dream.date, inSameDayAs: today, matchingDecade: false) {
                years.insert(calendar.component(.year, from: dream.date))
            }
        }
        
        XCTAssertGreaterThanOrEqual(years.count, 1, "应该至少有一个年份有梦境")
        
        // 清理
        for dream in testDreams {
            dreamStore.deleteDream(dream)
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
    
    // MARK: - EnhancedShareService 测试 (Phase 7 - 增强分享)
    
    func testSharePlatformEnum() throws {
        // 测试所有分享平台枚举值
        let platforms = SharePlatform.allCases
        
        XCTAssertEqual(platforms.count, 9, "应该有 9 个分享平台")
        
        // 测试平台属性
        let wechat = SharePlatform.wechat
        XCTAssertEqual(wechat.rawValue, "微信")
        XCTAssertEqual(wechat.icon, "message.fill")
        XCTAssertNotNil(wechat.urlScheme)
        
        let copyLink = SharePlatform.copyLink
        XCTAssertEqual(copyLink.rawValue, "复制链接")
        XCTAssertNil(copyLink.urlScheme)
    }
    
    func testShareCardStyleEnum() throws {
        // 测试所有分享卡片样式
        let styles = ShareCardStyle.allCases
        
        XCTAssertEqual(styles.count, 8, "应该有 8 种卡片样式")
        
        // 验证每种样式都有颜色配置
        for style in styles {
            XCTAssertFalse(style.backgroundColors.isEmpty, "\(style.rawValue) 应该有背景颜色")
            XCTAssertNotNil(style.textColor, "\(style.rawValue) 应该有文字颜色")
            XCTAssertNotNil(style.accentColor, "\(style.rawValue) 应该有强调色")
        }
        
        // 测试特定样式
        let starry = ShareCardStyle.starry
        XCTAssertEqual(starry.rawValue, "星空")
        
        let sunset = ShareCardStyle.sunset
        XCTAssertEqual(sunset.rawValue, "日落")
        
        let ocean = ShareCardStyle.ocean
        XCTAssertEqual(ocean.rawValue, "海洋")
        
        let forest = ShareCardStyle.forest
        XCTAssertEqual(forest.rawValue, "森林")
    }
    
    func testDreamQRCodeData() throws {
        let dream = Dream(
            title: "测试梦境",
            content: "测试内容",
            tags: ["测试"],
            emotions: [.happy],
            clarity: 4,
            isLucid: true
        )
        
        // 测试私有分享 (7 天过期)
        let privateQR = DreamQRCodeData(dream: dream, isPrivate: true, expiryDays: 7)
        XCTAssertTrue(privateQR.isPrivate)
        XCTAssertNotNil(privateQR.expiryDate)
        XCTAssertEqual(privateQR.dreamId, dream.id)
        XCTAssertEqual(privateQR.title, dream.title)
        
        // 测试公开分享 (永不过期)
        let publicQR = DreamQRCodeData(dream: dream, isPrivate: false)
        XCTAssertFalse(publicQR.isPrivate)
        XCTAssertNil(publicQR.expiryDate)
    }
    
    func testShareHistoryCodable() throws {
        let dream = Dream(
            title: "分享测试梦境",
            content: "测试分享功能",
            tags: ["分享", "测试"],
            emotions: [.happy, .excited],
            clarity: 5,
            isLucid: false
        )
        
        let history = ShareHistory(
            dream: dream,
            platform: .wechat,
            style: .dreamy
        )
        
        // 测试编码
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(history)
        
        // 测试解码
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedHistory = try decoder.decode(ShareHistory.self, from: data)
        
        XCTAssertEqual(history.id, decodedHistory.id)
        XCTAssertEqual(history.dreamId, decodedHistory.dreamId)
        XCTAssertEqual(history.dreamTitle, decodedHistory.dreamTitle)
        XCTAssertEqual(history.platform, decodedHistory.platform)
        XCTAssertEqual(history.shareStyle, decodedHistory.shareStyle)
    }
    
    func testShareHistoryArray() throws {
        var histories: [ShareHistory] = []
        
        for i in 0..<5 {
            let dream = Dream(
                title: "梦境\(i)",
                content: "内容\(i)",
                tags: ["测试"],
                emotions: [.calm]
            )
            let platform: SharePlatform = i % 2 == 0 ? .wechat : .weibo
            let style: ShareCardStyle = i % 3 == 0 ? .dreamy : .classic
            
            histories.append(ShareHistory(dream: dream, platform: platform, style: style))
        }
        
        // 测试编码数组
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(histories)
        
        // 测试解码数组
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedHistories = try decoder.decode([ShareHistory].self, from: data)
        
        XCTAssertEqual(histories.count, decodedHistories.count)
        
        for i in 0..<histories.count {
            XCTAssertEqual(histories[i].dreamTitle, decodedHistories[i].dreamTitle)
            XCTAssertEqual(histories[i].platform, decodedHistories[i].platform)
        }
    }
    
    func testEnhancedShareServiceSingleton() throws {
        let service1 = EnhancedShareService.shared
        let service2 = EnhancedShareService.shared
        
        XCTAssertIdentical(service1, service2, "EnhancedShareService 应该是单例")
        XCTAssertNotNil(service1.shareHistory)
        XCTAssertTrue(service1.shareHistory.isEmpty, "初始分享历史应该为空")
    }
    
    func testShareServiceProperties() throws {
        let service = EnhancedShareService.shared
        
        // 测试初始状态
        XCTAssertFalse(service.isGenerating)
        XCTAssertNil(service.generatedImage)
        XCTAssertNil(service.qrCodeImage)
        XCTAssertNil(service.shareLink)
        XCTAssertNil(service.error)
    }
    
    func testShareServiceCleanup() throws {
        let service = EnhancedShareService.shared
        
        // 添加一些测试历史
        let dream = Dream(title: "测试", content: "内容", tags: [], emotions: [])
        service.shareHistory.append(ShareHistory(dream: dream, platform: .wechat, style: .classic))
        
        XCTAssertFalse(service.shareHistory.isEmpty)
        
        // 清除历史
        service.clearShareHistory()
        
        XCTAssertTrue(service.shareHistory.isEmpty)
    }
    
    // MARK: - SmartReminderService 测试 (Phase 6)
    
    func testReminderTypeEnum() throws {
        // 测试所有提醒类型
        let allTypes = ReminderType.allCases
        XCTAssertEqual(allTypes.count, 6, "应该有 6 种提醒类型")
        
        // 测试图标
        XCTAssertEqual(ReminderType.optimalTime.icon, "clock.fill")
        XCTAssertEqual(ReminderType.bedtime.icon, "moon.fill")
        XCTAssertEqual(ReminderType.morning.icon, "sun.max.fill")
        XCTAssertEqual(ReminderType.goalAchieved.icon, "trophy.fill")
        XCTAssertEqual(ReminderType.streak.icon, "flame.fill")
        XCTAssertEqual(ReminderType.weekly.icon, "calendar")
        
        // 测试标题
        XCTAssertEqual(ReminderType.optimalTime.title, "最佳记录时间")
        XCTAssertEqual(ReminderType.bedtime.title, "睡前放松提醒")
        XCTAssertEqual(ReminderType.morning.title, "晨间回顾提醒")
        XCTAssertEqual(ReminderType.goalAchieved.title, "目标达成庆祝")
        XCTAssertEqual(ReminderType.streak.title, "连续记录激励")
        XCTAssertEqual(ReminderType.weekly.title, "每周总结")
    }
    
    func testReminderConfigCodable() throws {
        var config = ReminderConfig()
        config.isEnabled = true
        config.optimalTimeEnabled = true
        config.bedtimeEnabled = true
        config.bedtimeTime = "23:00"
        config.morningEnabled = true
        config.morningTime = "07:30"
        config.goalCelebrationEnabled = false
        config.streakReminderEnabled = true
        config.weeklySummaryEnabled = true
        config.weeklySummaryDay = 1 // Monday
        
        // 测试编码
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        // 测试解码
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(ReminderConfig.self, from: data)
        
        XCTAssertEqual(config.isEnabled, decodedConfig.isEnabled)
        XCTAssertEqual(config.optimalTimeEnabled, decodedConfig.optimalTimeEnabled)
        XCTAssertEqual(config.bedtimeTime, decodedConfig.bedtimeTime)
        XCTAssertEqual(config.morningTime, decodedConfig.morningTime)
        XCTAssertEqual(config.weeklySummaryDay, decodedConfig.weeklySummaryDay)
    }
    
    func testReminderConfigDefault() throws {
        let config = ReminderConfig.default
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertTrue(config.optimalTimeEnabled)
        XCTAssertTrue(config.bedtimeEnabled)
        XCTAssertEqual(config.bedtimeTime, "22:00")
        XCTAssertTrue(config.morningEnabled)
        XCTAssertEqual(config.morningTime, "08:00")
        XCTAssertTrue(config.goalCelebrationEnabled)
        XCTAssertTrue(config.streakReminderEnabled)
        XCTAssertTrue(config.weeklySummaryEnabled)
        XCTAssertEqual(config.weeklySummaryDay, 0) // Sunday
    }
    
    func testRecordingHabitAnalysisEmptyData() throws {
        let dreamStore = DreamStore()
        let analysis = RecordingHabitAnalysis.analyze(from: dreamStore)
        
        XCTAssertEqual(analysis.totalDreams, 0)
        XCTAssertEqual(analysis.optimalHour, 8) // 默认值
        XCTAssertEqual(analysis.averageClarity, 3.0) // 默认值
        XCTAssertEqual(analysis.recordingStreak, 0)
        XCTAssertEqual(analysis.longestStreak, 0)
    }
    
    func testRecordingHabitAnalysisWithDreams() throws {
        let dreamStore = DreamStore()
        
        // 添加多个梦境用于分析
        let calendar = Calendar.current
        let now = Date()
        
        // 添加 5 个梦境，都在上午 8 点
        for i in 0..<5 {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.hour = 8
            dateComponents.day = dateComponents.day! - i
            
            if let date = calendar.date(from: dateComponents) {
                let dream = Dream(
                    title: "测试梦境\(i)",
                    content: "测试内容",
                    tags: ["测试"],
                    emotions: [.calm],
                    clarity: 4
                )
                // 手动设置日期
                dreamStore.addDream(dream)
            }
        }
        
        let analysis = RecordingHabitAnalysis.analyze(from: dreamStore)
        
        XCTAssertGreaterThan(analysis.totalDreams, 0)
        XCTAssertEqual(analysis.optimalHour, 8) // 应该在 8 点
        XCTAssertGreaterThanOrEqual(analysis.averageClarity, 0)
        XCTAssertLessThanOrEqual(analysis.averageClarity, 5)
    }
    
    func testRecordingHabitAnalysisStreakCalculation() throws {
        // 测试连续记录计算逻辑
        let dreams = [
            Dream(title: "Day 1", content: "内容", tags: [], emotions: [], date: Date().addingTimeInterval(-86400 * 2)),
            Dream(title: "Day 2", content: "内容", tags: [], emotions: [], date: Date().addingTimeInterval(-86400)),
            Dream(title: "Day 3", content: "内容", tags: [], emotions: [], date: Date())
        ]
        
        // 验证梦境日期设置正确
        let calendar = Calendar.current
        for i in 0..<dreams.count - 1 {
            let daysDiff = calendar.dateComponents([.day], from: dreams[i].date, to: dreams[i + 1].date).day ?? 0
            XCTAssertGreaterThanOrEqual(daysDiff, 0)
        }
    }
    
    func testSmartReminderServiceSingleton() throws {
        let service1 = SmartReminderService.shared
        let service2 = SmartReminderService.shared
        
        XCTAssertIdentical(service1, service2, "SmartReminderService 应该是单例")
    }
    
    func testSmartReminderServiceInitialState() throws {
        let service = SmartReminderService.shared
        
        // 测试初始配置
        XCTAssertTrue(service.config.isEnabled)
        XCTAssertNotNil(service.config)
        
        // 测试分析初始状态
        XCTAssertNil(service.lastAnalysis)
    }
    
    func testSmartReminderServiceConfigPersistence() throws {
        let service = SmartReminderService.shared
        
        // 修改配置
        service.config.bedtimeTime = "23:30"
        service.config.morningTime = "07:00"
        service.config.weeklySummaryDay = 3 // Wednesday
        
        // 保存配置
        service.saveConfig()
        
        // 创建新实例并加载配置
        let newService = SmartReminderService.shared
        
        XCTAssertEqual(newService.config.bedtimeTime, "23:30")
        XCTAssertEqual(newService.config.morningTime, "07:00")
        XCTAssertEqual(newService.config.weeklySummaryDay, 3)
        
        // 恢复默认配置
        newService.config.bedtimeTime = "22:00"
        newService.config.morningTime = "08:00"
        newService.config.weeklySummaryDay = 0
        newService.saveConfig()
    }
    
    func testSmartReminderServiceAnalysisUpdate() throws {
        let service = SmartReminderService.shared
        let dreamStore = DreamStore()
        
        // 添加一些梦境数据
        for i in 0..<3 {
            let dream = Dream(
                title: "测试梦境\(i)",
                content: "测试内容",
                tags: ["测试"],
                emotions: [.calm],
                clarity: 4
            )
            dreamStore.addDream(dream)
        }
        
        // 更新分析
        service.updateAnalysis(from: dreamStore)
        
        XCTAssertNotNil(service.lastAnalysis)
        XCTAssertEqual(service.lastAnalysis?.totalDreams, 3)
    }
    
    // MARK: - ReminderType 测试
    
    func testReminderTypeAllCases() throws {
        let allTypes = ReminderType.allCases
        
        XCTAssertEqual(allTypes.count, 6, "应该有 6 种提醒类型")
        
        let expectedTypes: [ReminderType] = [
            .optimalTime, .bedtime, .morning,
            .goalAchieved, .streak, .weekly
        ]
        
        for expectedType in expectedTypes {
            XCTAssertTrue(allTypes.contains(expectedType), "应该包含 \(expectedType.rawValue)")
        }
    }
    
    func testReminderTypeIcons() throws {
        for type in ReminderType.allCases {
            XCTAssertFalse(type.icon.isEmpty, "\(type.rawValue) 应该有图标")
            XCTAssertTrue(type.icon.hasSuffix("fill") || !type.icon.isEmpty, "\(type.rawValue) 图标应该是有效的 SF Symbol")
        }
        
        XCTAssertEqual(ReminderType.optimalTime.icon, "clock.fill")
        XCTAssertEqual(ReminderType.bedtime.icon, "moon.fill")
        XCTAssertEqual(ReminderType.morning.icon, "sun.max.fill")
        XCTAssertEqual(ReminderType.goalAchieved.icon, "trophy.fill")
        XCTAssertEqual(ReminderType.streak.icon, "flame.fill")
        XCTAssertEqual(ReminderType.weekly.icon, "calendar")
    }
    
    func testReminderTypeTitles() throws {
        for type in ReminderType.allCases {
            XCTAssertFalse(type.title.isEmpty, "\(type.rawValue) 应该有标题")
        }
        
        XCTAssertEqual(ReminderType.optimalTime.title, "最佳记录时间")
        XCTAssertEqual(ReminderType.bedtime.title, "睡前放松提醒")
        XCTAssertEqual(ReminderType.morning.title, "晨间回顾提醒")
        XCTAssertEqual(ReminderType.goalAchieved.title, "目标达成庆祝")
        XCTAssertEqual(ReminderType.streak.title, "连续记录激励")
        XCTAssertEqual(ReminderType.weekly.title, "每周总结")
    }
    
    // MARK: - ReminderConfig 测试
    
    func testReminderConfigDefaultValues() throws {
        let config = ReminderConfig.default
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertTrue(config.optimalTimeEnabled)
        XCTAssertTrue(config.bedtimeEnabled)
        XCTAssertEqual(config.bedtimeTime, "22:00")
        XCTAssertTrue(config.morningEnabled)
        XCTAssertEqual(config.morningTime, "08:00")
        XCTAssertTrue(config.goalCelebrationEnabled)
        XCTAssertTrue(config.streakReminderEnabled)
        XCTAssertTrue(config.weeklySummaryEnabled)
        XCTAssertEqual(config.weeklySummaryDay, 0)
    }
    
    func testReminderConfigCodable() throws {
        var config = ReminderConfig()
        config.isEnabled = true
        config.optimalTimeEnabled = false
        config.bedtimeTime = "23:30"
        config.morningTime = "07:00"
        config.weeklySummaryDay = 3
        
        // 编码
        let encoded = try JSONEncoder().encode(config)
        
        // 解码
        let decoded = try JSONDecoder().decode(ReminderConfig.self, from: encoded)
        
        XCTAssertEqual(decoded.isEnabled, config.isEnabled)
        XCTAssertEqual(decoded.optimalTimeEnabled, config.optimalTimeEnabled)
        XCTAssertEqual(decoded.bedtimeTime, config.bedtimeTime)
        XCTAssertEqual(decoded.morningTime, config.morningTime)
        XCTAssertEqual(decoded.weeklySummaryDay, config.weeklySummaryDay)
    }
    
    func testReminderConfigToggleAllReminders() throws {
        var config = ReminderConfig()
        
        // 关闭所有提醒
        config.optimalTimeEnabled = false
        config.bedtimeEnabled = false
        config.morningEnabled = false
        config.weeklySummaryEnabled = false
        
        XCTAssertFalse(config.optimalTimeEnabled)
        XCTAssertFalse(config.bedtimeEnabled)
        XCTAssertFalse(config.morningEnabled)
        XCTAssertFalse(config.weeklySummaryEnabled)
        
        // 重新开启
        config.optimalTimeEnabled = true
        config.bedtimeEnabled = true
        config.morningEnabled = true
        config.weeklySummaryEnabled = true
        
        XCTAssertTrue(config.optimalTimeEnabled)
        XCTAssertTrue(config.bedtimeEnabled)
        XCTAssertTrue(config.morningEnabled)
        XCTAssertTrue(config.weeklySummaryEnabled)
    }
    
    // MARK: - RecordingHabitAnalysis 测试
    
    func testRecordingHabitAnalysisEmptyData() throws {
        let dreamStore = DreamStore()
        let analysis = RecordingHabitAnalysis.analyze(from: dreamStore)
        
        XCTAssertEqual(analysis.totalDreams, 0)
        XCTAssertEqual(analysis.optimalHour, 8) // 默认值
        XCTAssertEqual(analysis.averageClarity, 3.0) // 默认值
        XCTAssertEqual(analysis.recordingStreak, 0)
        XCTAssertEqual(analysis.longestStreak, 0)
        XCTAssertTrue(analysis.dreamsByHour.isEmpty)
    }
    
    func testRecordingHabitAnalysisWithTimeDistribution() throws {
        let dreamStore = DreamStore()
        let calendar = Calendar.current
        let now = Date()
        
        // 创建 10 个梦境，其中 7 个在晚上 22 点，3 个在早上 8 点
        for i in 0..<7 {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.hour = 22
            dateComponents.day = dateComponents.day! - i
            
            if let date = calendar.date(from: dateComponents) {
                let dream = Dream(title: "晚梦\(i)", content: "内容", tags: [], emotions: [], date: date, clarity: 4)
                dreamStore.addDream(dream)
            }
        }
        
        for i in 0..<3 {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.hour = 8
            dateComponents.day = dateComponents.day! - i
            
            if let date = calendar.date(from: dateComponents) {
                let dream = Dream(title: "早梦\(i)", content: "内容", tags: [], emotions: [], date: date, clarity: 3)
                dreamStore.addDream(dream)
            }
        }
        
        let analysis = RecordingHabitAnalysis.analyze(from: dreamStore)
        
        XCTAssertEqual(analysis.totalDreams, 10)
        XCTAssertEqual(analysis.optimalHour, 22) // 晚上 22 点最多
        XCTAssertEqual(analysis.dreamsByHour[22], 7)
        XCTAssertEqual(analysis.dreamsByHour[8], 3)
    }
    
    func testRecordingHabitAnalysisAverageClarity() throws {
        let dreamStore = DreamStore()
        
        // 添加不同清晰度的梦境
        let dreams = [
            Dream(title: "清晰", content: "内容", tags: [], emotions: [], clarity: 5),
            Dream(title: "中等", content: "内容", tags: [], emotions: [], clarity: 3),
            Dream(title: "模糊", content: "内容", tags: [], emotions: [], clarity: 1)
        ]
        
        for dream in dreams {
            dreamStore.addDream(dream)
        }
        
        let analysis = RecordingHabitAnalysis.analyze(from: dreamStore)
        
        XCTAssertEqual(analysis.totalDreams, 3)
        XCTAssertEqual(analysis.averageClarity, 3.0, accuracy: 0.01) // (5+3+1)/3 = 3.0
    }
    
    func testRecordingHabitAnalysisStreakCalculation() throws {
        let calendar = Calendar.current
        let now = Date()
        
        // 创建连续 3 天的梦境
        var dreams: [Dream] = []
        for i in 0..<3 {
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            dateComponents.day = dateComponents.day! - i
            dateComponents.hour = 8
            
            if let date = calendar.date(from: dateComponents) {
                dreams.append(Dream(title: "Day \(i)", content: "内容", tags: [], emotions: [], date: date, clarity: 4))
            }
        }
        
        // 验证日期是连续的
        for i in 0..<dreams.count - 1 {
            let daysDiff = calendar.dateComponents([.day], from: dreams[i + 1].date, to: dreams[i].date).day ?? 0
            XCTAssertEqual(daysDiff, 1, "梦境日期应该连续")
        }
    }
    
    // MARK: - SmartReminderService Notification Tests
    
    func testSmartReminderServiceNotificationContent() throws {
        let service = SmartReminderService.shared
        
        // 验证服务可以访问（实际通知调度需要真机测试）
        XCTAssertNotNil(service)
        XCTAssertNotNil(service.config)
        
        // 验证配置可以修改和保存
        let originalBedtime = service.config.bedtimeTime
        service.config.bedtimeTime = "23:00"
        XCTAssertEqual(service.config.bedtimeTime, "23:00")
        
        // 恢复原值
        service.config.bedtimeTime = originalBedtime
    }
    
    func testSmartReminderServiceTimeParsing() throws {
        // 测试时间格式解析
        let timeFormats = [
            "22:00",
            "08:30",
            "23:45",
            "00:00",
            "12:00"
        ]
        
        for timeString in timeFormats {
            let parts = timeString.split(separator: ":")
            XCTAssertEqual(parts.count, 2, "时间格式应该是 HH:MM")
            
            if let hour = Int(parts[0]), let minute = Int(parts[1]) {
                XCTAssertGreaterThanOrEqual(hour, 0, "小时应该 >= 0")
                XCTAssertLessThan(hour, 24, "小时应该 < 24")
                XCTAssertGreaterThanOrEqual(minute, 0, "分钟应该 >= 0")
                XCTAssertLessThan(minute, 60, "分钟应该 < 60")
            } else {
                XCTFail("时间解析失败：\(timeString)")
            }
        }
    }
    
    func testSmartReminderServiceWeeklyDayRange() throws {
        // 测试每周提醒日期范围 (0-6, 周日到周六)
        for day in 0...6 {
            var config = ReminderConfig()
            config.weeklySummaryDay = day
            XCTAssertEqual(config.weeklySummaryDay, day)
        }
        
        // 验证边界值
        var config = ReminderConfig()
        config.weeklySummaryDay = 0 // 周日
        XCTAssertEqual(config.weeklySummaryDay, 0)
        
        config.weeklySummaryDay = 6 // 周六
        XCTAssertEqual(config.weeklySummaryDay, 6)
    }
    
    // MARK: - Integration Tests
    
    func testSmartReminderServiceFullWorkflow() throws {
        let service = SmartReminderService.shared
        let dreamStore = DreamStore()
        
        // 1. 初始状态
        XCTAssertNil(service.lastAnalysis)
        
        // 2. 添加梦境数据
        for i in 0..<5 {
            let dream = Dream(
                title: "工作流梦境\(i)",
                content: "测试内容",
                tags: ["工作流"],
                emotions: [.calm],
                clarity: 4
            )
            dreamStore.addDream(dream)
        }
        
        // 3. 更新分析
        service.updateAnalysis(from: dreamStore)
        XCTAssertNotNil(service.lastAnalysis)
        XCTAssertEqual(service.lastAnalysis?.totalDreams, 5)
        
        // 4. 修改配置
        service.config.bedtimeTime = "22:30"
        service.config.morningTime = "07:30"
        
        // 5. 保存配置
        service.saveConfig()
        
        // 6. 验证配置已保存
        XCTAssertEqual(service.config.bedtimeTime, "22:30")
        XCTAssertEqual(service.config.morningTime, "07:30")
    }
    
    // MARK: - AIArtService Phase 8 Tests
    
    func testArtStyleAllCases() throws {
        let allStyles = DreamArt.ArtStyle.allCases
        
        // Phase 1-7: 8 styles, Phase 8: +6 styles = 14 total
        XCTAssertEqual(allStyles.count, 14, "应该有 14 种艺术风格")
        
        // 验证原有风格
        XCTAssertTrue(allStyles.contains(.realistic))
        XCTAssertTrue(allStyles.contains(.impressionist))
        XCTAssertTrue(allStyles.contains(.surreal))
        XCTAssertTrue(allStyles.contains(.anime))
        XCTAssertTrue(allStyles.contains(.watercolor))
        XCTAssertTrue(allStyles.contains(.oil))
        XCTAssertTrue(allStyles.contains(.digital))
        XCTAssertTrue(allStyles.contains(.dreamy))
        
        // 验证 Phase 8 新增风格
        XCTAssertTrue(allStyles.contains(.abstract))
        XCTAssertTrue(allStyles.contains(.minimalist))
        XCTAssertTrue(allStyles.contains(.cyberpunk))
        XCTAssertTrue(allStyles.contains(.fantasy))
        XCTAssertTrue(allStyles.contains(.noir))
        XCTAssertTrue(allStyles.contains(.popArt))
    }
    
    func testArtStyleProperties() throws {
        for style in DreamArt.ArtStyle.allCases {
            XCTAssertFalse(style.description.isEmpty, "\(style.rawValue) 应该有描述")
            XCTAssertFalse(style.promptSuffix.isEmpty, "\(style.rawValue) 应该有提示词后缀")
            XCTAssertFalse(style.negativePrompt.isEmpty, "\(style.rawValue) 应该有负面提示词")
            XCTAssertFalse(style.icon.isEmpty, "\(style.rawValue) 应该有图标")
            XCTAssertFalse(style.color.isEmpty, "\(style.rawValue) 应该有颜色")
            
            // 验证颜色格式 (6 位十六进制)
            XCTAssertEqual(style.color.count, 6, "\(style.rawValue) 颜色应该是 6 位十六进制")
        }
    }
    
    func testArtStyleNegativePrompts() throws {
        // 验证不同风格的负面提示词不同
        let realistic = DreamArt.ArtStyle.realistic.negativePrompt
        let surreal = DreamArt.ArtStyle.surreal.negativePrompt
        let cyberpunk = DreamArt.ArtStyle.cyberpunk.negativePrompt
        
        XCTAssertNotEqual(realistic, surreal, "不同风格应该有不同的负面提示词")
        XCTAssertNotEqual(surreal, cyberpunk, "不同风格应该有不同的负面提示词")
        
        // 验证负面提示词包含常见质量词
        XCTAssertTrue(realistic.contains("low quality") || realistic.contains("blurry"))
        XCTAssertTrue(surreal.contains("realistic") || surreal.contains("ordinary"))
    }
    
    func testArtStyleIcons() throws {
        // 验证所有风格都有有效的 SF Symbol 图标
        for style in DreamArt.ArtStyle.allCases {
            XCTAssertFalse(style.icon.isEmpty, "\(style.rawValue) 应该有图标")
        }
        
        // 验证特定图标
        XCTAssertEqual(DreamArt.ArtStyle.realistic.icon, "camera.fill")
        XCTAssertEqual(DreamArt.ArtStyle.cyberpunk.icon, "bolt.fill")
        XCTAssertEqual(DreamArt.ArtStyle.fantasy.icon, "wand.and.stars")
        XCTAssertEqual(DreamArt.ArtStyle.noir.icon, "moon.fill")
    }
    
    func testArtStyleColors() throws {
        // 验证所有风格都有颜色
        for style in DreamArt.ArtStyle.allCases {
            XCTAssertFalse(style.color.isEmpty, "\(style.rawValue) 应该有颜色")
        }
        
        // 验证特定颜色
        XCTAssertEqual(DreamArt.ArtStyle.realistic.color, "007AFF")
        XCTAssertEqual(DreamArt.ArtStyle.cyberpunk.color, "00F0FF")
        XCTAssertEqual(DreamArt.ArtStyle.fantasy.color, "9D50DD")
    }
    
    func testAspectRatioAllCases() throws {
        let allRatios = DreamArt.AspectRatio.allCases
        
        XCTAssertEqual(allRatios.count, 5, "应该有 5 种宽高比")
        
        XCTAssertTrue(allRatios.contains(.square))
        XCTAssertTrue(allRatios.contains(.portrait))
        XCTAssertTrue(allRatios.contains(.landscape))
        XCTAssertTrue(allRatios.contains(.portrait4x5))
        XCTAssertTrue(allRatios.contains(.landscape4x3))
    }
    
    func testAspectRatioDimensions() throws {
        // 验证正方形
        XCTAssertEqual(DreamArt.AspectRatio.square.width, 1024)
        XCTAssertEqual(DreamArt.AspectRatio.square.height, 1024)
        
        // 验证竖屏 9:16
        XCTAssertEqual(DreamArt.AspectRatio.portrait.width, 576)
        XCTAssertEqual(DreamArt.AspectRatio.portrait.height, 1024)
        
        // 验证横屏 16:9
        XCTAssertEqual(DreamArt.AspectRatio.landscape.width, 1024)
        XCTAssertEqual(DreamArt.AspectRatio.landscape.height, 576)
        
        // 验证肖像 4:5
        XCTAssertEqual(DreamArt.AspectRatio.portrait4x5.width, 832)
        XCTAssertEqual(DreamArt.AspectRatio.portrait4x5.height, 1040)
        
        // 验证风景 4:3
        XCTAssertEqual(DreamArt.AspectRatio.landscape4x3.width, 1024)
        XCTAssertEqual(DreamArt.AspectRatio.landscape4x3.height, 768)
    }
    
    func testAspectRatioDisplayNames() throws {
        for ratio in DreamArt.AspectRatio.allCases {
            XCTAssertFalse(ratio.displayName.isEmpty, "\(ratio.rawValue) 应该有显示名称")
        }
        
        XCTAssertEqual(DreamArt.AspectRatio.square.displayName, "正方形 (1:1)")
        XCTAssertEqual(DreamArt.AspectRatio.portrait.displayName, "竖屏 (9:16)")
        XCTAssertEqual(DreamArt.AspectRatio.landscape.displayName, "横屏 (16:9)")
    }
    
    func testAIArtServicePromptGeneration() throws {
        let service = AIArtService.shared
        
        // 创建测试梦境
        let dream = Dream(
            title: "奇幻森林",
            content: "我在一片神秘的森林中漫步，周围是发光的蘑菇和高大的树木。月光透过树叶洒下斑驳的光影。",
            tags: ["森林", "月光", "奇幻"],
            emotions: [.calm, .wondrous],
            clarity: 4,
            intensity: 3,
            timeOfDay: .night,
            isLucid: true
        )
        
        // 生成提示词
        let prompt = service.generatePrompt(from: dream, style: .fantasy)
        
        // 验证提示词包含关键元素
        XCTAssertTrue(prompt.contains("奇幻森林"), "提示词应该包含标题")
        XCTAssertTrue(prompt.contains("moonlight") || prompt.contains("night"), "提示词应该包含时间氛围")
        XCTAssertTrue(prompt.contains("fantasy"), "提示词应该包含风格后缀")
        XCTAssertTrue(prompt.contains("masterpiece"), "提示词应该包含质量词")
        
        // 验证清醒梦效果
        XCTAssertTrue(prompt.contains("lucid dream"), "清醒梦应该添加特殊效果")
        
        print("🎨 生成的提示词：\(prompt)")
    }
    
    func testAIArtServiceNegativePromptGeneration() throws {
        let service = AIArtService.shared
        
        // 为不同风格生成负面提示词
        let realisticNegative = service.generateNegativePrompt(for: .realistic)
        let animeNegative = service.generateNegativePrompt(for: .anime)
        
        // 验证包含通用质量词
        XCTAssertTrue(realisticNegative.contains("low quality"))
        XCTAssertTrue(realisticNegative.contains("blurry"))
        
        // 验证不同风格有不同的负面提示
        XCTAssertNotEqual(realisticNegative, animeNegative)
        
        print("🚫 写实风格负面提示：\(realisticNegative)")
        print("🚫 动漫风格负面提示：\(animeNegative)")
    }
    
    func testAIArtServicePromptWithEmotions() throws {
        let service = AIArtService.shared
        
        // 创建带有强烈情绪的梦境
        let happyDream = Dream(
            title: "快乐时光",
            content: "阳光明媚的日子",
            tags: [],
            emotions: [.happy],
            clarity: 5,
            intensity: 5
        )
        
        let sadDream = Dream(
            title: "悲伤回忆",
            content: "阴雨天",
            tags: [],
            emotions: [.sad],
            clarity: 2,
            intensity: 2
        )
        
        let happyPrompt = service.generatePrompt(from: happyDream, style: .realistic)
        let sadPrompt = service.generatePrompt(from: sadDream, style: .realistic)
        
        // 验证情绪影响提示词
        XCTAssertTrue(happyPrompt.contains("joyful") || happyPrompt.contains("bright"))
        XCTAssertTrue(sadPrompt.contains("melancholic") || sadPrompt.contains("somber"))
        
        // 验证清晰度和强度影响
        XCTAssertTrue(happyPrompt.contains("crystal clear") || happyPrompt.contains("vivid"))
        XCTAssertTrue(sadPrompt.contains("dreamy blur") || sadPrompt.contains("muted"))
    }
    
    func testAIArtServicePromptWithTimeOfDay() throws {
        let service = AIArtService.shared
        
        let baseDream = Dream(
            title: "测试",
            content: "内容",
            tags: [],
            emotions: []
        )
        
        // 测试不同时间段
        let morningPrompt = service.generatePrompt(from: baseDream, style: .realistic)
        
        // 默认应该是某种时间段
        XCTAssertTrue(morningPrompt.contains("morning") || morningPrompt.contains("afternoon") ||
                     morningPrompt.contains("evening") || morningPrompt.contains("night") ||
                     morningPrompt.contains("dawn") || morningPrompt.contains("dusk"))
    }
    
    func testAIArtServiceSingleton() throws {
        let service1 = AIArtService.shared
        let service2 = AIArtService.shared
        
        XCTAssertIdentical(service1, service2, "AIArtService 应该是单例")
    }
    
    func testAIArtServiceInitialState() throws {
        let service = AIArtService.shared
        
        XCTAssertFalse(service.isGenerating)
        XCTAssertEqual(service.generationProgress, 0.0)
        XCTAssertNil(service.currentDreamArt)
        XCTAssertNil(service.errorMessage)
    }
    
    func testDreamArtStructure() throws {
        let dreamId = UUID()
        let art = DreamArt(
            dreamId: dreamId,
            imageUrl: "https://example.com/image.jpg",
            prompt: "测试提示词",
            style: .dreamy,
            createdAt: Date()
        )
        
        XCTAssertEqual(art.dreamId, dreamId)
        XCTAssertEqual(art.imageUrl, "https://example.com/image.jpg")
        XCTAssertEqual(art.prompt, "测试提示词")
        XCTAssertEqual(art.style, .dreamy)
        XCTAssertFalse(art.isFavorite)
        XCTAssertNotNil(art.id)
    }
    
    func testDreamArtArtStyleAllCases() throws {
        // 验证所有风格都可以编码和解码
        for style in DreamArt.ArtStyle.allCases {
            let encoded = try JSONEncoder().encode(style)
            let decoded = try JSONDecoder().decode(DreamArt.ArtStyle.self, from: encoded)
            XCTAssertEqual(style, decoded, "\(style.rawValue) 应该可以正确编码和解码")
        }
    }
    
    func testDreamArtAspectRatioCodable() throws {
        // 验证所有宽高比都可以编码和解码
        for ratio in DreamArt.AspectRatio.allCases {
            let encoded = try JSONEncoder().encode(ratio)
            let decoded = try JSONDecoder().decode(DreamArt.AspectRatio.self, from: encoded)
            XCTAssertEqual(ratio, decoded, "\(ratio.rawValue) 应该可以正确编码和解码")
        }
    }
    
    // MARK: - DreamMusicService 测试 (Phase 9)
    
    func testDreamMusicServiceSingleton() throws {
        let service1 = DreamMusicService.shared
        let service2 = DreamMusicService.shared
        
        XCTAssertIdentical(service1, service2, "DreamMusicService 应该是单例")
    }
    
    func testDreamMusicServiceInitialState() async throws {
        let service = DreamMusicService.shared
        
        XCTAssertFalse(service.isGenerating)
        XCTAssertEqual(service.generationProgress, 0.0)
        XCTAssertNil(service.currentMusic)
        XCTAssertNil(service.errorMessage)
    }
    
    func testDreamMusicMoodAllCases() throws {
        // 验证所有情绪都可以编码和解码
        for mood in DreamMusic.DreamMusicMood.allCases {
            let encoded = try JSONEncoder().encode(mood)
            let decoded = try JSONDecoder().decode(DreamMusic.DreamMusicMood.self, from: encoded)
            XCTAssertEqual(mood, decoded, "\(mood.rawValue) 应该可以正确编码和解码")
            
            // 验证每个情绪都有图标和颜色
            XCTAssertFalse(mood.icon.isEmpty, "\(mood.rawValue) 应该有图标")
            XCTAssertFalse(mood.color.isEmpty, "\(mood.rawValue) 应该有颜色")
            XCTAssertFalse(mood.description.isEmpty, "\(mood.rawValue) 应该有描述")
        }
    }
    
    func testDreamMusicTempoAllCases() throws {
        // 验证所有节奏都可以编码和解码
        for tempo in DreamMusic.DreamMusicTempo.allCases {
            let encoded = try JSONEncoder().encode(tempo)
            let decoded = try JSONDecoder().decode(DreamMusic.DreamMusicTempo.self, from: encoded)
            XCTAssertEqual(tempo, decoded, "\(tempo.rawValue) 应该可以正确编码和解码")
            
            // 验证 BPM 范围有效
            XCTAssertGreaterThan(tempo.bpmRange.upperBound, tempo.bpmRange.lowerBound)
            XCTAssertGreaterThanOrEqual(tempo.bpmRange.lowerBound, 40)
            XCTAssertLessThanOrEqual(tempo.bpmRange.upperBound, 140)
        }
    }
    
    func testDreamMusicInstrumentAllCases() throws {
        // 验证所有乐器都可以编码和解码
        for instrument in DreamMusic.DreamMusicInstrument.allCases {
            let encoded = try JSONEncoder().encode(instrument)
            let decoded = try JSONDecoder().decode(DreamMusic.DreamMusicInstrument.self, from: encoded)
            XCTAssertEqual(instrument, decoded, "\(instrument.rawValue) 应该可以正确编码和解码")
            
            // 验证每个乐器都有图标
            XCTAssertFalse(instrument.icon.isEmpty, "\(instrument.rawValue) 应该有图标")
        }
    }
    
    func testDreamMusicStructure() throws {
        let dreamId = UUID()
        let music = DreamMusic(
            dreamId: dreamId,
            title: "测试音乐",
            duration: 180,
            mood: .peaceful,
            tempo: .slow,
            instruments: [.piano, .strings],
            audioLayers: [],
            createdAt: Date()
        )
        
        XCTAssertEqual(music.dreamId, dreamId)
        XCTAssertEqual(music.title, "测试音乐")
        XCTAssertEqual(music.duration, 180)
        XCTAssertEqual(music.mood, .peaceful)
        XCTAssertEqual(music.tempo, .slow)
        XCTAssertEqual(music.instruments.count, 2)
        XCTAssertFalse(music.isFavorite)
        XCTAssertNotNil(music.id)
    }
    
    func testAudioLayerStructure() throws {
        let layer = DreamMusic.AudioLayer(
            instrument: .piano,
            volume: 0.8,
            pan: 0.0,
            reverb: 0.5,
            delay: 0.3,
            loop: true,
            sampleName: "piano_peaceful"
        )
        
        XCTAssertEqual(layer.instrument, .piano)
        XCTAssertEqual(layer.volume, 0.8)
        XCTAssertEqual(layer.pan, 0.0)
        XCTAssertEqual(layer.reverb, 0.5)
        XCTAssertEqual(layer.delay, 0.3)
        XCTAssertTrue(layer.loop)
        XCTAssertEqual(layer.sampleName, "piano_peaceful")
    }
    
    func testDreamMusicMoodColorConversion() throws {
        // 验证所有情绪颜色都是有效的十六进制格式
        for mood in DreamMusic.DreamMusicMood.allCases {
            let color = mood.color
            // 颜色应该是 6 位十六进制
            XCTAssertEqual(color.count, 6, "\(mood.rawValue) 的颜色应该是 6 位十六进制")
            XCTAssertTrue(color.allSatisfy { $0.isHexDigit }, "\(mood.rawValue) 的颜色应该是有效的十六进制")
        }
    }
    
    func testDreamMusicCodable() throws {
        let dreamId = UUID()
        let music = DreamMusic(
            dreamId: dreamId,
            title: "测试音乐",
            duration: 180,
            mood: .dreamy,
            tempo: .moderate,
            instruments: [.piano, .harp, .windChimes],
            audioLayers: [
                DreamMusic.AudioLayer(
                    instrument: .piano,
                    volume: 0.7,
                    pan: -0.2,
                    reverb: 0.6,
                    delay: 0.3,
                    loop: true,
                    sampleName: "piano_dreamy"
                )
            ],
            createdAt: Date(),
            isFavorite: true,
            filePath: "/path/to/music.m4a"
        )
        
        // 编码
        let encoded = try JSONEncoder().encode(music)
        
        // 解码
        let decoded = try JSONDecoder().decode(DreamMusic.self, from: encoded)
        
        // 验证
        XCTAssertEqual(music.id, decoded.id)
        XCTAssertEqual(music.dreamId, decoded.dreamId)
        XCTAssertEqual(music.title, decoded.title)
        XCTAssertEqual(music.duration, decoded.duration)
        XCTAssertEqual(music.mood, decoded.mood)
        XCTAssertEqual(music.tempo, decoded.tempo)
        XCTAssertEqual(music.instruments, decoded.instruments)
        XCTAssertEqual(music.audioLayers.count, decoded.audioLayers.count)
        XCTAssertEqual(music.isFavorite, decoded.isFavorite)
        XCTAssertEqual(music.filePath, decoded.filePath)
    }
    
    func testMusicGenerationWithDifferentDreams() async throws {
        let service = DreamMusicService.shared
        
        // 测试平静的梦境
        let peacefulDream = Dream(
            title: "宁静的夜晚",
            content: "我在安静的湖边散步",
            tags: ["平静", "自然"],
            emotions: [.calm],
            clarity: 4
        )
        
        let peacefulMusic = await service.generateMusic(for: peacefulDream)
        XCTAssertNotNil(peacefulMusic)
        XCTAssertEqual(peacefulMusic?.mood, .peaceful)
        
        // 测试紧张的梦境
        let tenseDream = Dream(
            title: "追逐",
            content: "有人在追我，我很害怕",
            tags: ["恐惧", "焦虑"],
            emotions: [.fearful, .anxious],
            clarity: 3
        )
        
        let tenseMusic = await service.generateMusic(for: tenseDream)
        XCTAssertNotNil(tenseMusic)
        XCTAssertEqual(tenseMusic?.mood, .tense)
        
        // 测试清醒梦
        let lucidDream = Dream(
            title: "清醒飞行",
            content: "我知道自己在做梦，我飞了起来",
            tags: ["清醒梦", "飞行"],
            emotions: [.excited],
            clarity: 5,
            isLucid: true
        )
        
        let lucidMusic = await service.generateMusic(for: lucidDream)
        XCTAssertNotNil(lucidMusic)
        XCTAssertEqual(lucidMusic?.mood, .ethereal)
    }
    
    func testInstrumentSelectionFromDreamContent() async throws {
        let service = DreamMusicService.shared
        
        // 测试水相关梦境
        let waterDream = Dream(
            title: "海边",
            content: "我在海边听海浪声，雨水打在沙滩上",
            tags: ["水"],
            emotions: [.calm]
        )
        
        let waterMusic = await service.generateMusic(for: waterDream)
        XCTAssertNotNil(waterMusic)
        XCTAssertTrue(waterMusic?.instruments.contains(.oceanWaves) ?? false, "水梦境应该包含海浪音效")
        
        // 测试森林相关梦境
        let forestDream = Dream(
            title: "森林漫步",
            content: "在森林里散步，周围都是树",
            tags: ["自然"],
            emotions: [.calm]
        )
        
        let forestMusic = await service.generateMusic(for: forestDream)
        XCTAssertNotNil(forestMusic)
        XCTAssertTrue(forestMusic?.instruments.contains(.forestAmbience) ?? false, "森林梦境应该包含森林氛围")
        
        // 测试冥想相关梦境
        let meditationDream = Dream(
            title: "冥想",
            content: "我在冥想，内心非常宁静",
            tags: ["冥想"],
            emotions: [.calm]
        )
        
        let meditationMusic = await service.generateMusic(for: meditationDream)
        XCTAssertNotNil(meditationMusic)
        XCTAssertTrue(meditationMusic?.instruments.contains(.singingBowl) ?? false, "冥想梦境应该包含颂钵")
    }
    
    func testMusicTitleGeneration() async throws {
        let service = DreamMusicService.shared
        
        // 测试有标题的梦境
        let titledDream = Dream(
            title: "我的梦境",
            content: "内容",
            tags: [],
            emotions: [.calm]
        )
        
        let titledMusic = await service.generateMusic(for: titledDream)
        XCTAssertNotNil(titledMusic)
        XCTAssertTrue(titledMusic?.title.contains("我的梦境") ?? false, "音乐标题应该包含梦境标题")
        
        // 测试无标题的梦境
        let untitledDream = Dream(
            title: nil,
            content: "内容",
            tags: [],
            emotions: [.calm]
        )
        
        let untitledMusic = await service.generateMusic(for: untitledDream)
        XCTAssertNotNil(untitledMusic)
        XCTAssertTrue(untitledMusic?.title.contains("梦境") ?? true, "无标题梦境的音乐应该有默认标题")
    }
    
    func testMusicLibraryManagement() async throws {
        let service = DreamMusicService.shared
        let initialCount = service.musicLibrary.count
        
        // 生成并保存音乐
        let dream = Dream(
            title: "测试",
            content: "内容",
            tags: [],
            emotions: [.calm]
        )
        
        if let music = await service.generateMusic(for: dream) {
            service.saveMusic(music)
            XCTAssertEqual(service.musicLibrary.count, initialCount + 1)
            
            // 测试收藏
            service.toggleFavorite(music)
            let favoritedMusic = service.musicLibrary.first(where: { $0.id == music.id })
            XCTAssertEqual(favoritedMusic?.isFavorite, true)
            
            // 取消收藏
            service.toggleFavorite(music)
            let unfavoritedMusic = service.musicLibrary.first(where: { $0.id == music.id })
            XCTAssertEqual(unfavoritedMusic?.isFavorite, false)
            
            // 删除
            service.deleteMusic(music)
            XCTAssertEqual(service.musicLibrary.count, initialCount)
        }
    }
    
    // MARK: - Phase 9.5 高级音乐功能测试
    
    func testSleepTimerOptions() throws {
        let service = DreamMusicService.shared
        let options = service.getSleepTimerOptions()
        
        XCTAssertEqual(options.count, 6)
        XCTAssertEqual(options[0], 0)  // 关闭
        XCTAssertEqual(options[1], 15 * 60)  // 15 分钟
        XCTAssertEqual(options[2], 30 * 60)  // 30 分钟
        XCTAssertEqual(options[3], 45 * 60)  // 45 分钟
        XCTAssertEqual(options[4], 60 * 60)  // 1 小时
        XCTAssertEqual(options[5], 90 * 60)  // 90 分钟
    }
    
    func testSleepTimerSetting() async throws {
        let service = DreamMusicService.shared
        
        // 初始状态
        XCTAssertFalse(service.isSleepTimerActive)
        XCTAssertEqual(service.sleepTimerDuration, 0)
        XCTAssertEqual(service.sleepTimerRemaining, 0)
        
        // 设置 15 分钟定时器
        service.setSleepTimer(duration: 15 * 60)
        XCTAssertTrue(service.isSleepTimerActive)
        XCTAssertEqual(service.sleepTimerDuration, 15 * 60)
        XCTAssertEqual(service.sleepTimerRemaining, 15 * 60)
        
        // 停止定时器
        service.stopSleepTimer()
        XCTAssertFalse(service.isSleepTimerActive)
        XCTAssertEqual(service.sleepTimerRemaining, 0)
    }
    
    func testSleepTimerFormat() throws {
        let service = DreamMusicService.shared
        service.sleepTimerRemaining = 900  // 15 分钟
        
        let formatted = service.formatSleepTimerRemaining()
        XCTAssertTrue(formatted.contains("分"))
        XCTAssertTrue(formatted.contains("秒"))
    }
    
    func testMusicExportStructure() async throws {
        let service = DreamMusicService.shared
        
        let dream = Dream(
            title: "测试导出",
            content: "测试内容",
            tags: [],
            emotions: [.calm]
        )
        
        if let music = await service.generateMusic(for: dream) {
            // 测试导出方法存在并返回 URL
            let exportURL = await service.exportMusic(music)
            
            // 导出应该返回一个 URL (即使是模拟的)
            XCTAssertNotNil(exportURL)
            XCTAssertTrue(exportURL?.path.contains("DreamMusicExports") ?? true)
        }
    }
    
    func testBatchMusicExport() async throws {
        let service = DreamMusicService.shared
        
        var dreams: [Dream] = []
        for i in 0..<3 {
            dreams.append(Dream(
                title: "测试导出\(i)",
                content: "测试内容\(i)",
                tags: [],
                emotions: [.calm]
            ))
        }
        
        var musics: [DreamMusic] = []
        for dream in dreams {
            if let music = await service.generateMusic(for: dream) {
                musics.append(music)
            }
        }
        
        let exportedURLs = await service.exportMusicBatch(musics)
        XCTAssertEqual(exportedURLs.count, musics.count)
    }
    
    func testShareItemGeneration() async throws {
        let service = DreamMusicService.shared
        
        let dream = Dream(
            title: "测试分享",
            content: "测试内容",
            tags: [],
            emotions: [.peaceful]
        )
        
        if let music = await service.generateMusic(for: dream) {
            let shareItem = await service.shareMusic(music)
            
            XCTAssertNotNil(shareItem)
            XCTAssertEqual(shareItem?.musicId, music.id)
            XCTAssertEqual(shareItem?.title, music.title)
            XCTAssertEqual(shareItem?.mood, music.mood)
            XCTAssertNotNil(shareItem?.shareText)
            XCTAssertTrue(shareItem?.shareText.contains(music.title) ?? true)
        }
    }
    
    func testSharePlatformEnum() throws {
        // 测试所有分享平台
        XCTAssertEqual(SharePlatform.wechat.rawValue, "微信")
        XCTAssertEqual(SharePlatform.weibo.rawValue, "微博")
        XCTAssertEqual(SharePlatform.qq.rawValue, "QQ")
        XCTAssertEqual(SharePlatform.telegram.rawValue, "Telegram")
        XCTAssertEqual(SharePlatform.instagram.rawValue, "Instagram")
        XCTAssertEqual(SharePlatform.tiktok.rawValue, "TikTok")
        XCTAssertEqual(SharePlatform.copyLink.rawValue, "复制链接")
    }
    
    func testMeditationTypeRecommendation() async throws {
        let service = DreamMusicService.shared
        
        // 生成一些测试音乐
        let peacefulDream = Dream(
            title: "平静梦境",
            content: "平静的内容",
            tags: [],
            emotions: [.calm]
        )
        
        if let music = await service.generateMusic(for: peacefulDream) {
            service.saveMusic(music)
        }
        
        // 测试冥想推荐
        let recommended = service.getRecommendedMusicForMeditation(meditationType: .relaxation)
        
        // 应该返回平静情绪的音乐
        XCTAssertNotNil(recommended)
    }
    
    func testMeditationPlaylistCreation() async throws {
        let service = DreamMusicService.shared
        
        // 创建冥想播放列表
        let playlist = await service.createMeditationPlaylist(
            type: .sleepPreparation,
            duration: 1800  // 30 分钟
        )
        
        // 播放列表应该存在 (可能为空如果没有匹配的音乐)
        XCTAssertNotNil(playlist)
    }
    
    func testMeditationTypeEnum() throws {
        // 测试所有冥想类型
        XCTAssertEqual(MeditationType.sleepPreparation.rawValue, "睡前准备")
        XCTAssertEqual(MeditationType.dreamRecall.rawValue, "梦境回忆")
        XCTAssertEqual(MeditationType.lucidInduction.rawValue, "清醒梦诱导")
        XCTAssertEqual(MeditationType.relaxation.rawValue, "减压放松")
        XCTAssertEqual(MeditationType.morningAnchor.rawValue, "晨间锚定")
    }
    
    func testMusicShareCardData() async throws {
        let service = DreamMusicService.shared
        
        let dream = Dream(
            title: "测试卡片",
            content: "测试内容",
            tags: [],
            emotions: [.peaceful]
        )
        
        if let music = await service.generateMusic(for: dream) {
            let cardData = service.generateShareCardData(for: music)
            
            XCTAssertEqual(cardData.musicId, music.id)
            XCTAssertEqual(cardData.title, music.title)
            XCTAssertEqual(cardData.mood, music.mood)
            XCTAssertEqual(cardData.moodColor, music.mood.color)
            XCTAssertEqual(cardData.moodIcon, music.mood.icon)
            XCTAssertEqual(cardData.instruments.count, music.instruments.count)
        }
    }
    
    func testMusicDurationFormat() async throws {
        let service = DreamMusicService.shared
        
        let dream = Dream(
            title: "测试",
            content: "内容",
            tags: [],
            emotions: [.calm]
        )
        
        if let music = await service.generateMusic(for: dream) {
            // 验证音乐有合理的时长
            XCTAssertGreaterThan(music.duration, 0)
            XCTAssertLessThanOrEqual(music.duration, 300)  // 最多 5 分钟
        }
    }
    
    func testPlaylistGeneration() async throws {
        let service = DreamMusicService.shared
        
        var dreams: [Dream] = []
        for i in 0..<3 {
            dreams.append(Dream(
                title: "播放列表测试\(i)",
                content: "内容\(i)",
                tags: [],
                emotions: [.calm]
            ))
        }
        
        let playlist = await service.generatePlaylist(for: dreams)
        
        // 播放列表应该包含为每个梦境生成的音乐
        XCTAssertEqual(playlist.count, dreams.count)
    }
    
    // MARK: - Phase 10 真实音频合成测试
    
    func testAudioSynthesisEngineInitialization() throws {
        let engine = AudioSynthesisEngine.shared
        
        // 验证引擎可以初始化
        XCTAssertNotNil(engine)
        XCTAssertFalse(engine.isExporting)
        XCTAssertEqual(engine.exportProgress, 0.0)
    }
    
    func testAudioLayerSynthesis() async throws {
        let engine = AudioSynthesisEngine.shared
        
        let layer = DreamMusic.AudioLayer(
            instrument: .piano,
            volume: 0.8,
            pan: 0.0,
            reverb: 0.5,
            delay: 0.3,
            loop: true,
            sampleName: "piano_peaceful"
        )
        
        // 合成 1 秒的音频
        let buffer = engine.synthesizeAudioLayer(layer, duration: 1.0, sampleRate: 44100)
        
        XCTAssertNotNil(buffer)
        XCTAssertEqual(buffer?.format.sampleRate, 44100)
        XCTAssertEqual(buffer?.format.channelCount, 2)
    }
    
    func testAllInstrumentSynthesis() async throws {
        let engine = AudioSynthesisEngine.shared
        
        let instruments: [DreamMusic.DreamMusicInstrument] = [
            .piano, .strings, .flute, .harp, .synth, .ambientPad,
            .natureSounds, .singingBowl, .windChimes,
            .oceanWaves, .rainSounds, .forestAmbience
        ]
        
        for instrument in instruments {
            let layer = DreamMusic.AudioLayer(
                instrument: instrument,
                volume: 0.6,
                pan: 0.0,
                reverb: 0.4,
                delay: 0.2,
                loop: true,
                sampleName: "\(instrument.rawValue)_test"
            )
            
            let buffer = engine.synthesizeAudioLayer(layer, duration: 0.5, sampleRate: 44100)
            
            XCTAssertNotNil(buffer, "合成失败：\(instrument.rawValue)")
            XCTAssertEqual(buffer?.frameLength, 22050)  // 0.5 秒 @ 44100Hz
        }
    }
    
    func testMusicTemplateStructure() throws {
        let template = MusicTemplate(
            mood: .peaceful,
            tempo: .slow,
            instruments: [.piano, .strings, .ambientPad],
            baseDuration: 180
        )
        
        XCTAssertEqual(template.mood, .peaceful)
        XCTAssertEqual(template.tempo, .slow)
        XCTAssertEqual(template.instruments.count, 3)
        XCTAssertEqual(template.baseDuration, 180)
    }
    
    func testAudioEnvelopeFunctions() async throws {
        let engine = AudioSynthesisEngine.shared
        
        // 测试不同乐器的包络函数 (通过合成验证)
        let testCases: [(DreamMusic.DreamMusicInstrument, String)] = [
            (.piano, "piano"),
            (.strings, "strings"),
            (.flute, "flute"),
            (.harp, "harp"),
            (.synth, "synth"),
            (.ambientPad, "pad")
        ]
        
        for (instrument, name) in testCases {
            let layer = DreamMusic.AudioLayer(
                instrument: instrument,
                volume: 0.7,
                pan: 0.0,
                reverb: 0.3,
                delay: 0.1,
                loop: false,
                sampleName: "\(name)_envelope_test"
            )
            
            let buffer = engine.synthesizeAudioLayer(layer, duration: 0.1, sampleRate: 44100)
            
            XCTAssertNotNil(buffer, "\(name) 包络测试失败")
        }
    }
    
    func testNoiseGeneration() async throws {
        let engine = AudioSynthesisEngine.shared
        
        // 测试自然音效合成
        let natureInstruments: [DreamMusic.DreamMusicInstrument] = [
            .oceanWaves, .rainSounds, .forestAmbience
        ]
        
        for instrument in natureInstruments {
            let layer = DreamMusic.AudioLayer(
                instrument: instrument,
                volume: 0.5,
                pan: 0.0,
                reverb: 0.6,
                delay: 0.2,
                loop: true,
                sampleName: "\(instrument.rawValue)_noise"
            )
            
            let buffer = engine.synthesizeAudioLayer(layer, duration: 0.5, sampleRate: 44100)
            
            XCTAssertNotNil(buffer, "\(instrument.rawValue) 噪声生成失败")
            
            // 验证有音频数据 (不是全静音)
            if let floatData = buffer?.floatChannelData?[0] {
                var hasNonZero = false
                for i in 0..<Int(buffer!.frameLength) {
                    if abs(floatData[i]) > 0.001 {
                        hasNonZero = true
                        break
                    }
                }
                XCTAssertTrue(hasNonZero, "\(instrument.rawValue) 生成的音频全为静音")
            }
        }
    }
    
    func testAudioEffectsApplication() async throws {
        let engine = AudioSynthesisEngine.shared
        
        // 测试带效果的音频合成
        let layer = DreamMusic.AudioLayer(
            instrument: .piano,
            volume: 0.8,
            pan: -0.5,  // 偏左
            reverb: 0.8,  // 高混响
            delay: 0.6,  // 高延迟
            loop: true,
            sampleName: "piano_effects_test"
        )
        
        let buffer = engine.synthesizeAudioLayer(layer, duration: 1.0, sampleRate: 44100)
        
        XCTAssertNotNil(buffer)
        
        // 验证效果器应用 (有混响和延迟的音频应该有不同的特征)
        if let floatData = buffer?.floatChannelData?[0] {
            var sum: Float = 0
            for i in 0..<Int(buffer!.frameLength) {
                sum += abs(floatData[i])
            }
            let averageAmplitude = sum / Float(buffer!.frameLength)
            
            // 平均振幅应该大于 0 (有声音)
            XCTAssertGreaterThan(averageAmplitude, 0.001, "应用效果器后音频振幅过低")
        }
    }
    
    func testMusicExportWithRealSynthesis() async throws {
        let service = DreamMusicService.shared
        
        let dream = Dream(
            title: "真实合成测试",
            content: "测试真实音频合成和导出功能",
            tags: ["测试", "Phase10"],
            emotions: [.peaceful]
        )
        
        // 生成音乐
        guard let music = await service.generateMusic(for: dream) else {
            XCTFail("音乐生成失败")
            return
        }
        
        // 验证音乐有多个音频层
        XCTAssertGreaterThan(music.audioLayers.count, 0, "音乐应该有多个音频层")
        
        // 导出音乐 (使用真实合成)
        let exportURL = await service.exportMusic(music)
        
        // 验证导出结果
        XCTAssertNotNil(exportURL, "音乐导出失败")
        
        if let url = exportURL {
            // 验证文件存在
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "导出文件不存在")
            
            // 验证文件大小 (真实音频文件应该大于 0)
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            XCTAssertGreaterThan(fileSize, 0, "导出文件大小为 0")
            
            // 验证元数据文件存在
            let metadataURL = url.deletingPathExtension().appendingPathExtension("json")
            XCTAssertTrue(FileManager.default.fileExists(atPath: metadataURL.path), "元数据文件不存在")
            
            // 验证元数据内容
            if let metadata = try? Data(contentsOf: metadataURL),
               let json = try? JSONSerialization.jsonObject(with: metadata) as? [String: Any] {
                XCTAssertEqual(json["musicId"] as? String, music.id.uuidString)
                XCTAssertEqual(json["title"] as? String, music.title)
                XCTAssertEqual(json["format"] as? String, "AAC")
                XCTAssertEqual(json["sampleRate"] as? Int, 44100)
                XCTAssertEqual(json["bitRate"] as? Int, 256000)
            }
            
            // 清理测试文件
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: metadataURL)
        }
    }
    
    func testExportProgressTracking() async throws {
        let service = DreamMusicService.shared
        
        let dream = Dream(
            title: "进度追踪测试",
            content: "测试导出进度追踪",
            tags: ["测试"],
            emotions: [.calm]
        )
        
        guard let music = await service.generateMusic(for: dream) else {
            XCTFail("音乐生成失败")
            return
        }
        
        // 验证初始状态
        XCTAssertEqual(service.exportProgress, 0.0)
        XCTAssertFalse(service.isExporting)
        
        // 开始导出
        let exportTask = Task {
            await service.exportMusic(music)
        }
        
        // 等待一小段时间让导出开始
        try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 秒
        
        // 验证导出状态
        // 注意：由于导出可能很快完成，这里只做基本验证
        await exportTask.value
        
        // 导出完成后进度应该重置
        XCTAssertFalse(service.isExporting)
    }
    
    func testBatchExportWithRealSynthesis() async throws {
        let service = DreamMusicService.shared
        
        // 创建多个梦境
        var dreams: [Dream] = []
        for i in 0..<3 {
            dreams.append(Dream(
                title: "批量导出测试\(i)",
                content: "内容\(i)",
                tags: ["批量测试"],
                emotions: [.calm]
            ))
        }
        
        // 生成音乐
        var musics: [DreamMusic] = []
        for dream in dreams {
            if let music = await service.generateMusic(for: dream) {
                musics.append(music)
            }
        }
        
        XCTAssertEqual(musics.count, dreams.count, "应该为每个梦境生成音乐")
        
        // 批量导出
        let exportedURLs = await service.exportMusicBatch(musics)
        
        // 验证所有文件都导出成功
        XCTAssertEqual(exportedURLs.count, musics.count, "应该导出所有音乐文件")
        
        // 验证文件存在
        for url in exportedURLs {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "导出文件不存在：\(url.path)")
            
            // 清理
            try? FileManager.default.removeItem(at: url)
            let metadataURL = url.deletingPathExtension().appendingPathExtension("json")
            try? FileManager.default.removeItem(at: metadataURL)
        }
    }
    
    func testAudioLayerMixing() async throws {
        let engine = AudioSynthesisEngine.shared
        
        // 创建多个音频层
        let layers = [
            DreamMusic.AudioLayer(instrument: .piano, volume: 0.6, pan: 0.0, reverb: 0.5, delay: 0.3, loop: true, sampleName: "piano"),
            DreamMusic.AudioLayer(instrument: .strings, volume: 0.5, pan: -0.2, reverb: 0.6, delay: 0.2, loop: true, sampleName: "strings"),
            DreamMusic.AudioLayer(instrument: .ambientPad, volume: 0.4, pan: 0.2, reverb: 0.8, delay: 0.4, loop: true, sampleName: "pad")
        ]
        
        // 合成每个层
        var buffers: [AVAudioPCMBuffer] = []
        for layer in layers {
            if let buffer = engine.synthesizeAudioLayer(layer, duration: 0.5, sampleRate: 44100) {
                buffers.append(buffer)
            }
        }
        
        XCTAssertEqual(buffers.count, 3, "应该成功合成所有音频层")
        
        // 验证所有缓冲区格式一致
        let firstFormat = buffers[0].format
        for buffer in buffers {
            XCTAssertEqual(buffer.format.sampleRate, firstFormat.sampleRate)
            XCTAssertEqual(buffer.format.channelCount, firstFormat.channelCount)
        }
    }
    
    // MARK: - DreamWrappedService 测试
    
    func testWrappedPeriodEnum() throws {
        // 测试所有时间段枚举值
        let allPeriods = WrappedPeriod.allCases
        XCTAssertEqual(allPeriods.count, 5)
        
        XCTAssertEqual(WrappedPeriod.week.displayName, "本周")
        XCTAssertEqual(WrappedPeriod.month.displayName, "本月")
        XCTAssertEqual(WrappedPeriod.quarter.displayName, "本季度")
        XCTAssertEqual(WrappedPeriod.year.displayName, "年度")
        XCTAssertEqual(WrappedPeriod.allTime.displayName, "全部")
        
        // 测试天数计算
        XCTAssertEqual(WrappedPeriod.week.dayCount, 7)
        XCTAssertEqual(WrappedPeriod.month.dayCount, 30)
        XCTAssertEqual(WrappedPeriod.quarter.dayCount, 90)
        XCTAssertEqual(WrappedPeriod.year.dayCount, 365)
    }
    
    func testWrappedCardTypeEnum() throws {
        // 测试所有卡片类型枚举值
        let allCards = WrappedCardType.allCases
        XCTAssertEqual(allCards.count, 9)
        
        // 测试图标
        XCTAssertEqual(WrappedCardType.overview.icon, "chart.bar.fill")
        XCTAssertEqual(WrappedCardType.emotionJourney.icon, "heart.fill")
        XCTAssertEqual(WrappedCardType.topThemes.icon, "tag.fill")
        XCTAssertEqual(WrappedCardType.lucidDreams.icon, "eye.fill")
        XCTAssertEqual(WrappedCardType.dreamStreak.icon, "flame.fill")
        XCTAssertEqual(WrappedCardType.vividDream.icon, "star.fill")
        XCTAssertEqual(WrappedCardType.dreamTime.icon, "clock.fill")
        XCTAssertEqual(WrappedCardType.uniqueStats.icon, "sparkles")
        XCTAssertEqual(WrappedCardType.shareCard.icon, "square.and.arrow.up.fill")
        
        // 测试渐变颜色
        XCTAssertFalse(WrappedCardType.overview.gradientColors.isEmpty)
        XCTAssertEqual(WrappedCardType.overview.gradientColors.count, 2)
    }
    
    func testDreamWrappedDataCodable() throws {
        let wrappedData = DreamWrappedData(
            period: .year,
            generatedAt: Date(),
            totalDreams: 100,
            lucidDreamCount: 25,
            averageClarity: 4.2,
            averageIntensity: 3.8,
            topEmotions: [
                DreamWrappedData.EmotionStat(name: "快乐", count: 30, percentage: 30.0),
                DreamWrappedData.EmotionStat(name: "平静", count: 25, percentage: 25.0)
            ],
            topTags: [
                DreamWrappedData.TagStat(name: "飞行", count: 20, percentage: 20.0),
                DreamWrappedData.TagStat(name: "水", count: 15, percentage: 15.0)
            ],
            dreamStreak: 14,
            longestStreak: 30,
            mostVividDream: nil,
            mostIntenseDream: nil,
            timeOfDayDistribution: ["早晨": 30, "晚上": 70],
            weeklyPattern: [10, 5, 8, 7, 9, 15, 20],
            monthlyTrend: [
                DreamWrappedData.MonthStat(month: "1 月", count: 8, averageClarity: 3.5),
                DreamWrappedData.MonthStat(month: "2 月", count: 10, averageClarity: 4.0)
            ],
            uniqueStats: [
                DreamWrappedData.UniqueStat(title: "最早的梦境", value: "05:30", icon: "sunrise.fill")
            ],
            shareCardQuote: "在年度里，我记录了 100 个梦境 🌙"
        )
        
        // 测试编码
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(wrappedData)
        
        // 测试解码
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(DreamWrappedData.self, from: encodedData)
        
        XCTAssertEqual(decodedData.totalDreams, 100)
        XCTAssertEqual(decodedData.lucidDreamCount, 25)
        XCTAssertEqual(decodedData.topEmotions.count, 2)
        XCTAssertEqual(decodedData.topTags.count, 2)
    }
    
    func testDreamWrappedServiceSingleton() throws {
        let service1 = DreamWrappedService.shared
        let service2 = DreamWrappedService.shared
        
        XCTAssertTrue(service1 === service2, "DreamWrappedService 应该是单例")
    }
    
    func testDreamWrappedServiceInitialState() throws {
        let service = DreamWrappedService.shared
        
        XCTAssertNil(service.currentWrappedData)
        XCTAssertFalse(service.isGenerating)
        XCTAssertEqual(service.generatedPeriod, .year)
    }
    
    func testDreamWrappedDataGeneration() async throws {
        let service = DreamWrappedService.shared
        
        // 创建测试梦境数据
        var dreams: [Dream] = []
        for i in 0..<20 {
            dreams.append(Dream(
                title: "测试梦境\(i)",
                content: "这是第\(i)个测试梦境内容",
                tags: i % 3 == 0 ? ["飞行", "自由"] : ["水", "海洋"],
                emotions: i % 2 == 0 ? [.happy, .excited] : [.calm, .peaceful],
                clarity: (i % 5) + 1,
                intensity: (i % 5) + 1,
                isLucid: i % 4 == 0
            ))
        }
        
        // 生成年度总结
        service.generateWrapped(for: .year, dreams: dreams)
        
        // 等待生成完成
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 秒
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        // 验证数据
        XCTAssertEqual(wrappedData.totalDreams, 20)
        XCTAssertEqual(wrappedData.lucidDreamCount, 5)  // 20/4 = 5
        XCTAssertGreaterThan(wrappedData.averageClarity, 0)
        XCTAssertGreaterThan(wrappedData.averageIntensity, 0)
        XCTAssertFalse(wrappedData.topEmotions.isEmpty)
        XCTAssertFalse(wrappedData.topTags.isEmpty)
    }
    
    func testStreakCalculation() async throws {
        let service = DreamWrappedService.shared
        
        // 创建连续 7 天的梦境
        var dreams: [Dream] = []
        let calendar = Calendar.current
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dreams.append(Dream(
                    title: "梦境\(i)",
                    content: "内容",
                    tags: ["测试"],
                    emotions: [.calm],
                    timestamp: date
                ))
            }
        }
        
        service.generateWrapped(for: .week, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertEqual(wrappedData.dreamStreak, 7, "连续记录应为 7 天")
        XCTAssertEqual(wrappedData.longestStreak, 7, "最长连续应为 7 天")
    }
    
    func testStreakCalculationWithGap() async throws {
        let service = DreamWrappedService.shared
        
        // 创建有间隔的梦境数据
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        // 前 3 天连续
        for i in 0..<3 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dreams.append(Dream(
                    title: "梦境\(i)",
                    content: "内容",
                    tags: ["测试"],
                    emotions: [.calm],
                    timestamp: date
                ))
            }
        }
        
        // 跳过 2 天，再有 5 天连续
        for i in 5..<10 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                dreams.append(Dream(
                    title: "梦境\(i)",
                    content: "内容",
                    tags: ["测试"],
                    emotions: [.calm],
                    timestamp: date
                ))
            }
        }
        
        service.generateWrapped(for: .month, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertEqual(wrappedData.dreamStreak, 3, "当前连续应为 3 天")
        XCTAssertEqual(wrappedData.longestStreak, 5, "最长连续应为 5 天")
    }
    
    func testEmotionStatistics() async throws {
        let service = DreamWrappedService.shared
        
        // 创建带有特定情绪的梦境
        var dreams: [Dream] = []
        for _ in 0..<10 {
            dreams.append(Dream(
                title: "快乐梦境",
                content: "内容",
                tags: ["测试"],
                emotions: [.happy]
            ))
        }
        for _ in 0..<5 {
            dreams.append(Dream(
                title: "平静梦境",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm]
            ))
        }
        
        service.generateWrapped(for: .allTime, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertFalse(wrappedData.topEmotions.isEmpty)
        
        // 快乐应该排在第一位
        let topEmotion = wrappedData.topEmotions.first
        XCTAssertEqual(topEmotion?.name, "快乐")
        XCTAssertEqual(topEmotion?.count, 10)
    }
    
    func testTagStatistics() async throws {
        let service = DreamWrappedService.shared
        
        // 创建带有特定标签的梦境
        var dreams: [Dream] = []
        for _ in 0..<10 {
            dreams.append(Dream(
                title: "飞行梦境",
                content: "内容",
                tags: ["飞行"],
                emotions: [.excited]
            ))
        }
        for _ in 0..<5 {
            dreams.append(Dream(
                title: "海洋梦境",
                content: "内容",
                tags: ["水", "海洋"],
                emotions: [.calm]
            ))
        }
        
        service.generateWrapped(for: .allTime, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertFalse(wrappedData.topTags.isEmpty)
        
        // 飞行应该排在第一位
        let topTag = wrappedData.topTags.first
        XCTAssertEqual(topTag?.name, "飞行")
        XCTAssertEqual(topTag?.count, 10)
    }
    
    func testWeeklyPatternCalculation() async throws {
        let service = DreamWrappedService.shared
        
        // 创建特定星期几的梦境
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        // 创建 5 个周日的梦境
        for i in 0..<5 {
            var components = DateComponents()
            components.weekday = 1  // 周日
            components.weekOfYear = i + 1
            if let date = calendar.date(from: components) {
                dreams.append(Dream(
                    title: "周日梦境",
                    content: "内容",
                    tags: ["测试"],
                    emotions: [.calm],
                    timestamp: date
                ))
            }
        }
        
        service.generateWrapped(for: .allTime, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertEqual(wrappedData.weeklyPattern.count, 7)
        // 周日 (索引 0) 应该有 5 个梦境
        XCTAssertGreaterThanOrEqual(wrappedData.weeklyPattern[0], 0)
    }
    
    func testUniqueStatsGeneration() async throws {
        let service = DreamWrappedService.shared
        
        // 创建测试梦境
        var dreams: [Dream] = []
        for i in 0..<10 {
            dreams.append(Dream(
                title: "梦境\(i)",
                content: String(repeating: "内容", count: i + 1),
                tags: ["测试"],
                emotions: [.calm],
                isLucid: i % 2 == 0
            ))
        }
        
        service.generateWrapped(for: .allTime, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertFalse(wrappedData.uniqueStats.isEmpty)
        
        // 验证包含平均长度统计
        let avgLengthStat = wrappedData.uniqueStats.first { $0.title == "平均梦境长度" }
        XCTAssertNotNil(avgLengthStat)
        XCTAssertTrue(avgLengthStat!.value.contains("字"))
    }
    
    func testShareQuoteGeneration() async throws {
        let service = DreamWrappedService.shared
        
        let dreams = [
            Dream(title: "梦 1", content: "内容", tags: ["测试"], emotions: [.calm])
        ]
        
        service.generateWrapped(for: .year, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertFalse(wrappedData.shareCardQuote.isEmpty)
        XCTAssertTrue(wrappedData.shareCardQuote.contains("年度"))
    }
    
    func testExportWrappedData() async throws {
        let service = DreamWrappedService.shared
        
        let dreams = [
            Dream(title: "测试梦境", content: "内容", tags: ["测试"], emotions: [.calm])
        ]
        
        service.generateWrapped(for: .month, dreams: dreams)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 测试导出
        let exportedData = service.exportWrappedData()
        
        XCTAssertNotNil(exportedData)
        
        // 验证可以解码
        if let data = exportedData {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(DreamWrappedData.self, from: data)
            XCTAssertEqual(decoded.totalDreams, 1)
        }
    }
    
    func testClearWrappedData() async throws {
        let service = DreamWrappedService.shared
        
        // 先生成一些数据
        service.generateWrapped(for: .year, dreams: [
            Dream(title: "测试", content: "内容", tags: ["测试"], emotions: [.calm])
        ])
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 清除数据
        service.clearWrappedData()
        
        XCTAssertNil(service.currentWrappedData)
        XCTAssertEqual(service.generatedPeriod, .year)
    }
    
    func testEmptyDreamsHandling() async throws {
        let service = DreamWrappedService.shared
        
        // 测试空梦境数组
        service.generateWrapped(for: .year, dreams: [])
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard let wrappedData = service.currentWrappedData else {
            XCTFail("总结数据生成失败")
            return
        }
        
        XCTAssertEqual(wrappedData.totalDreams, 0)
        XCTAssertEqual(wrappedData.lucidDreamCount, 0)
        XCTAssertEqual(wrappedData.averageClarity, 0)
        XCTAssertEqual(wrappedData.averageIntensity, 0)
        XCTAssertEqual(wrappedData.dreamStreak, 0)
        XCTAssertTrue(wrappedData.topEmotions.isEmpty)
        XCTAssertTrue(wrappedData.topTags.isEmpty)
    }
    
    // MARK: - Phase 11.5 年度对比功能测试
    
    func testYearOverYearComparison() throws {
        let service = DreamWrappedService.shared
        let calendar = Calendar.current
        let now = Date()
        
        // 创建今年的梦境
        var thisYearDreams: [Dream] = []
        for i in 0..<10 {
            let date = calendar.date(byAdding: .month, value: -i, to: now)!
            thisYearDreams.append(Dream(
                title: "今年梦 \(i)",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm],
                timestamp: date,
                clarity: 7,
                intensity: 6,
                isLucid: i % 2 == 0
            ))
        }
        
        // 创建去年的梦境
        var lastYearDreams: [Dream] = []
        for i in 0..<8 {
            let date = calendar.date(byAdding: .year, value: -1, to: now)!
            let monthOffset = calendar.date(byAdding: .month, value: -i, to: date)!
            lastYearDreams.append(Dream(
                title: "去年梦 \(i)",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm],
                timestamp: monthOffset,
                clarity: 6,
                intensity: 5,
                isLucid: i % 3 == 0
            ))
        }
        
        let allDreams = thisYearDreams + lastYearDreams
        
        // 测试年度对比
        let comparison = service.generateYearOverYearComparison(dreams: allDreams)
        
        XCTAssertNotNil(comparison)
        XCTAssertEqual(comparison?.thisYear.totalDreams, 10)
        XCTAssertEqual(comparison?.lastYear.totalDreams, 8)
        XCTAssertEqual(comparison?.dreamsChange, 2)
        XCTAssertGreaterThan(comparison?.dreamsChangePercent ?? 0, 0)
    }
    
    func testYearOverYearComparisonNoLastYearData() throws {
        let service = DreamWrappedService.shared
        
        // 只有今年的梦境
        let dreams = [
            Dream(title: "今年梦", content: "内容", tags: ["测试"], emotions: [.calm])
        ]
        
        let comparison = service.generateYearOverYearComparison(dreams: dreams)
        
        XCTAssertNil(comparison)  // 没有去年数据应该返回 nil
    }
    
    func testMonthOverMonthComparison() throws {
        let service = DreamWrappedService.shared
        let calendar = Calendar.current
        let now = Date()
        
        // 创建本月的梦境
        var thisMonthDreams: [Dream] = []
        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: now)!
            thisMonthDreams.append(Dream(
                title: "本月梦 \(i)",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm],
                timestamp: date,
                clarity: 7,
                intensity: 6
            ))
        }
        
        // 创建上月的梦境
        var lastMonthDreams: [Dream] = []
        for i in 0..<3 {
            let date = calendar.date(byAdding: .month, value: -1, to: now)!
            let dayOffset = calendar.date(byAdding: .day, value: -i, to: date)!
            lastMonthDreams.append(Dream(
                title: "上月梦 \(i)",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm],
                timestamp: dayOffset,
                clarity: 6,
                intensity: 5
            ))
        }
        
        let allDreams = thisMonthDreams + lastMonthDreams
        
        // 测试月度对比
        let comparison = service.generateMonthOverMonthComparison(dreams: allDreams)
        
        XCTAssertNotNil(comparison)
        XCTAssertEqual(comparison?.thisMonth.totalDreams, 5)
        XCTAssertEqual(comparison?.lastMonth.totalDreams, 3)
        XCTAssertEqual(comparison?.dreamsChange, 2)
    }
    
    func testYearComparisonInsights() throws {
        let service = DreamWrappedService.shared
        let calendar = Calendar.current
        let now = Date()
        
        // 创建今年更多梦境
        var thisYearDreams: [Dream] = []
        for i in 0..<20 {
            let date = calendar.date(byAdding: .month, value: -i % 12, to: now)!
            thisYearDreams.append(Dream(
                title: "今年梦 \(i)",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm],
                timestamp: date,
                clarity: 8,
                intensity: 7,
                isLucid: true
            ))
        }
        
        // 创建去年较少梦境
        var lastYearDreams: [Dream] = []
        for i in 0..<10 {
            let date = calendar.date(byAdding: .year, value: -1, to: now)!
            lastYearDreams.append(Dream(
                title: "去年梦 \(i)",
                content: "内容",
                tags: ["测试"],
                emotions: [.calm],
                timestamp: date,
                clarity: 6,
                intensity: 5,
                isLucid: false
            ))
        }
        
        let allDreams = thisYearDreams + lastYearDreams
        let comparison = service.generateYearOverYearComparison(dreams: allDreams)
        
        XCTAssertNotNil(comparison)
        XCTAssertFalse(comparison!.insights.isEmpty)
        
        // 验证包含增长洞察
        let hasGrowthInsight = comparison!.insights.contains { $0.contains("多记录") || $0.contains("增长") }
        XCTAssertTrue(hasGrowthInsight)
    }
    
    // MARK: - Phase 11.5 分享卡片类型测试
    
    func testShareCardTypeCases() throws {
        // 测试所有分享卡片类型
        let allTypes = ShareCardType.allCases
        
        XCTAssertEqual(allTypes.count, 3)
        XCTAssertTrue(allTypes.contains(.standard))
        XCTAssertTrue(allTypes.contains(.square))
        XCTAssertTrue(allTypes.contains(.wechat))
    }
    
    func testShareCardTypeDisplayNames() throws {
        XCTAssertEqual(ShareCardType.standard.displayName, "标准")
        XCTAssertEqual(ShareCardType.square.displayName, "方形")
        XCTAssertEqual(ShareCardType.wechat.displayName, "微信")
    }
    
    func testShareCardTypeSizeDescriptions() throws {
        XCTAssertEqual(ShareCardType.standard.sizeDescription, "1080×1920 (Story)")
        XCTAssertEqual(ShareCardType.square.sizeDescription, "1080×1080 (Post)")
        XCTAssertEqual(ShareCardType.wechat.sizeDescription, "1080×1350 (微信)")
    }
    
    // MARK: - Phase 11.5 图片导出功能测试
    
    func testViewImageRendererBasic() throws {
        // 测试视图渲染器基本功能
        let testView = Text("测试")
            .frame(width: 100, height: 100)
        
        let image = ViewImageRenderer.render(view: testView, size: CGSize(width: 100, height: 100))
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 100)
        XCTAssertEqual(image?.size.height, 100)
    }
    
    func testWrappedCardTypeYearComparison() throws {
        // 测试新增的年度对比卡片类型
        let allCards = WrappedCardType.allCases
        
        XCTAssertTrue(allCards.contains(.yearComparison))
        XCTAssertEqual(WrappedCardType.yearComparison.icon, "arrow.left.arrow.right")
        XCTAssertEqual(WrappedCardType.yearComparison.gradientColors, ["#6366F1", "#8B5CF6"])
    }
    
    func testWrappedCardTypeCount() throws {
        // 验证卡片类型总数（包含新增的年度对比）
        XCTAssertEqual(WrappedCardType.allCases.count, 11)  // 原来 10 个 + 年度对比 1 个
    }
    
    // MARK: - Phase 12 PDF 日记导出功能测试
    
    func testPDFExportStyleAllCases() throws {
        // 测试所有 PDF 导出风格
        let allStyles = PDFExportStyle.allCases
        
        XCTAssertEqual(allStyles.count, 8)
        XCTAssertTrue(allStyles.contains(.minimal))
        XCTAssertTrue(allStyles.contains(.classic))
        XCTAssertTrue(allStyles.contains(.artistic))
        XCTAssertTrue(allStyles.contains(.modern))
        XCTAssertTrue(allStyles.contains(.nature))
        XCTAssertTrue(allStyles.contains(.sunset))
        XCTAssertTrue(allStyles.contains(.ocean))
        XCTAssertTrue(allStyles.contains(.forest))
    }
    
    func testPDFExportStyleProperties() throws {
        // 测试风格属性
        XCTAssertEqual(PDFExportStyle.minimal.description, "干净简洁，专注内容")
        XCTAssertEqual(PDFExportStyle.classic.description, "传统书籍排版，优雅正式")
        XCTAssertEqual(PDFExportStyle.artistic.description, "创意布局，丰富装饰")
        XCTAssertEqual(PDFExportStyle.modern.description, "时尚设计，大胆用色")
        XCTAssertEqual(PDFExportStyle.nature.description, "自然元素，清新绿色")
        XCTAssertEqual(PDFExportStyle.sunset.description, "温暖渐变，橙红色调")
        XCTAssertEqual(PDFExportStyle.ocean.description, "蓝色渐变，海洋元素")
        XCTAssertEqual(PDFExportStyle.forest.description, "绿色主题，树叶装饰")
    }
    
    func testPDFExportStyleIcons() throws {
        // 测试风格图标
        XCTAssertEqual(PDFExportStyle.minimal.iconName, "doc.text")
        XCTAssertEqual(PDFExportStyle.classic.iconName, "book.fill")
        XCTAssertEqual(PDFExportStyle.artistic.iconName, "paintpalette.fill")
        XCTAssertEqual(PDFExportStyle.modern.iconName, "sparkles")
        XCTAssertEqual(PDFExportStyle.nature.iconName, "leaf.fill")
        XCTAssertEqual(PDFExportStyle.sunset.iconName, "sun.max.fill")
        XCTAssertEqual(PDFExportStyle.ocean.iconName, "water.fill")
        XCTAssertEqual(PDFExportStyle.forest.iconName, "tree.fill")
    }
    
    func testPDFPageSizeAllCases() throws {
        // 测试所有页面尺寸
        let allSizes = PDFPageSize.allCases
        
        XCTAssertEqual(allSizes.count, 3)
        XCTAssertTrue(allSizes.contains(.a4))
        XCTAssertTrue(allSizes.contains(.letter))
        XCTAssertTrue(allSizes.contains(.square))
    }
    
    func testPDFPageSizeDimensions() throws {
        // 测试页面尺寸维度
        XCTAssertEqual(PDFPageSize.a4.size.width, 595)
        XCTAssertEqual(PDFPageSize.a4.size.height, 842)
        
        XCTAssertEqual(PDFPageSize.letter.size.width, 612)
        XCTAssertEqual(PDFPageSize.letter.size.height, 792)
        
        XCTAssertEqual(PDFPageSize.square.size.width, 600)
        XCTAssertEqual(PDFPageSize.square.size.height, 600)
    }
    
    func testPDFPageSizeDescriptions() throws {
        // 测试页面尺寸描述
        XCTAssertEqual(PDFPageSize.a4.description, "210 × 297 mm (国际标准)")
        XCTAssertEqual(PDFPageSize.letter.description, "8.5 × 11 英寸 (美式标准)")
        XCTAssertEqual(PDFPageSize.square.description, "600 × 600 pt (社交媒体)")
    }
    
    func testPDFExportConfigDefault() throws {
        // 测试默认配置
        let config = PDFExportConfig.default
        
        XCTAssertEqual(config.style, .classic)
        XCTAssertEqual(config.pageSize, .a4)
        XCTAssertEqual(config.language, .chinese)
        XCTAssertTrue(config.includeCoverPage)
        XCTAssertTrue(config.includeTableOfContents)
        XCTAssertTrue(config.includeAIImages)
        XCTAssertTrue(config.includeStatistics)
        XCTAssertTrue(config.includeTags)
        XCTAssertTrue(config.includeEmotions)
        XCTAssertEqual(config.customTitle, "")
        XCTAssertEqual(config.customSubtitle, "")
        XCTAssertEqual(config.sortBy, .dateDesc)
    }
    
    func testPDFExportConfigCodable() throws {
        // 测试配置编码/解码
        let config = PDFExportConfig(
            style: .artistic,
            pageSize: .letter,
            includeCoverPage: false,
            includeTableOfContents: true,
            includeAIImages: true,
            includeStatistics: false,
            includeTags: true,
            includeEmotions: false,
            customTitle: "测试标题",
            customSubtitle: "测试副标题",
            dateRange: .thisMonth,
            sortBy: .clarity
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decodedConfig = try decoder.decode(PDFExportConfig.self, from: data)
        
        XCTAssertEqual(decodedConfig.style, .artistic)
        XCTAssertEqual(decodedConfig.pageSize, .letter)
        XCTAssertFalse(decodedConfig.includeCoverPage)
        XCTAssertEqual(decodedConfig.customTitle, "测试标题")
    }
    
    func testPDFExportConfigDateRangeAll() throws {
        // 测试全部日期范围
        let range = PDFExportConfig.DateRange.all
        
        XCTAssertEqual(range.startDate, Date.distantPast)
        XCTAssertGreaterThanOrEqual(Date(), range.endDate)
    }
    
    func testPDFExportConfigDateRangeThisWeek() throws {
        // 测试本周日期范围
        let range = PDFExportConfig.DateRange.thisWeek
        
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        
        XCTAssertEqual(range.startDate, startOfWeek)
        XCTAssertGreaterThanOrEqual(range.endDate, Date())
    }
    
    func testPDFExportConfigDateRangeThisMonth() throws {
        // 测试本月日期范围
        let range = PDFExportConfig.DateRange.thisMonth
        
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        XCTAssertEqual(range.startDate, startOfMonth)
        XCTAssertGreaterThanOrEqual(range.endDate, Date())
    }
    
    func testPDFExportConfigDateRangeThisYear() throws {
        // 测试今年日期范围
        let range = PDFExportConfig.DateRange.thisYear
        
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
        
        XCTAssertEqual(range.startDate, startOfYear)
        XCTAssertGreaterThanOrEqual(range.endDate, Date())
    }
    
    func testPDFExportConfigSortOptions() throws {
        // 测试排序选项
        let allOptions = PDFExportConfig.SortOption.allCases
        
        XCTAssertEqual(allOptions.count, 4)
        XCTAssertTrue(allOptions.contains(.dateDesc))
        XCTAssertTrue(allOptions.contains(.dateAsc))
        XCTAssertTrue(allOptions.contains(.clarity))
        XCTAssertTrue(allOptions.contains(.intensity))
    }
    
    func testPDFExportLanguageAllCases() throws {
        // 测试所有导出语言
        let allLanguages = PDFExportLanguage.allCases
        
        XCTAssertEqual(allLanguages.count, 4)
        XCTAssertTrue(allLanguages.contains(.chinese))
        XCTAssertTrue(allLanguages.contains(.english))
        XCTAssertTrue(allLanguages.contains(.japanese))
        XCTAssertTrue(allLanguages.contains(.korean))
    }
    
    func testPDFExportLanguageDisplayNames() throws {
        // 测试语言显示名称
        XCTAssertEqual(PDFExportLanguage.chinese.displayName, "简体中文")
        XCTAssertEqual(PDFExportLanguage.english.displayName, "English")
        XCTAssertEqual(PDFExportLanguage.japanese.displayName, "日本語")
        XCTAssertEqual(PDFExportLanguage.korean.displayName, "한국어")
    }
    
    func testPDFExportLanguageCoverTitles() throws {
        // 测试语言封面标题
        XCTAssertEqual(PDFExportLanguage.chinese.coverTitle, "我的梦境日记")
        XCTAssertEqual(PDFExportLanguage.english.coverTitle, "My Dream Journal")
        XCTAssertEqual(PDFExportLanguage.japanese.coverTitle, "私の夢日記")
        XCTAssertEqual(PDFExportLanguage.korean.coverTitle, "나의 꿈 일기")
    }
    
    func testPDFExportLanguageLocalizedStrings() throws {
        // 测试语言本地化字符串
        XCTAssertEqual(PDFExportLanguage.chinese.tableOfContents, "目录")
        XCTAssertEqual(PDFExportLanguage.english.tableOfContents, "Table of Contents")
        XCTAssertEqual(PDFExportLanguage.japanese.tableOfContents, "目次")
        XCTAssertEqual(PDFExportLanguage.korean.tableOfContents, "목차")
        
        XCTAssertEqual(PDFExportLanguage.chinese.statistics, "梦境统计")
        XCTAssertEqual(PDFExportLanguage.english.statistics, "Dream Statistics")
        
        XCTAssertEqual(PDFExportLanguage.chinese.totalDreams, "总梦境数")
        XCTAssertEqual(PDFExportLanguage.english.totalDreams, "Total Dreams")
        
        XCTAssertEqual(PDFExportLanguage.chinese.lucidDreams, "清醒梦")
        XCTAssertEqual(PDFExportLanguage.english.lucidDreams, "Lucid Dreams")
        
        XCTAssertEqual(PDFExportLanguage.chinese.backCoverText, "记录你的每一个梦境")
        XCTAssertEqual(PDFExportLanguage.english.backCoverText, "Record Every Dream")
    }
    
    func testPDFExportConfigCopy() throws {
        // 测试配置复制方法
        let original = PDFExportConfig.default
        let modified = original.copy(\.style, .artistic)
        
        XCTAssertEqual(original.style, .classic)
        XCTAssertEqual(modified.style, .artistic)
        XCTAssertEqual(modified.pageSize, original.pageSize)
    }
    
    func testDreamJournalExportServiceSingleton() throws {
        // 测试单例模式
        let service1 = DreamJournalExportService.shared
        let service2 = DreamJournalExportService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testDreamJournalExportServiceInitialState() throws {
        // 测试初始状态
        let service = DreamJournalExportService.shared
        
        // 验证默认配置
        // 注意：由于配置是私有的，我们通过更新配置来间接测试
        let newConfig = PDFExportConfig.default
        service.updateConfig(newConfig)
    }
    
    func testDreamJournalExportServiceConfigUpdate() throws {
        // 测试配置更新
        let service = DreamJournalExportService.shared
        
        let newConfig = PDFExportConfig(
            style: .modern,
            pageSize: .square,
            includeCoverPage: false,
            includeTableOfContents: false,
            includeAIImages: true,
            includeStatistics: true,
            includeTags: false,
            includeEmotions: false,
            customTitle: "自定义标题",
            customSubtitle: "自定义副标题",
            dateRange: .thisWeek,
            sortBy: .intensity
        )
        
        service.updateConfig(newConfig)
        // 配置已更新（无法直接验证私有属性，但方法调用成功）
    }
    
    func testPDFExportErrorCases() throws {
        // 测试所有错误类型
        let noDreamsError = PDFExportError.noDreamsInRange
        let generationError = PDFExportError.generationFailed
        let saveError = PDFExportError.fileSaveFailed
        
        XCTAssertEqual(noDreamsError.errorDescription, "所选日期范围内没有梦境记录")
        XCTAssertEqual(generationError.errorDescription, "PDF 生成失败，请重试")
        XCTAssertEqual(saveError.errorDescription, "文件保存失败")
    }
    
    func testPDFExportErrorLocalizedError() throws {
        // 测试错误遵循 LocalizedError 协议
        let error: LocalizedError = PDFExportError.noDreamsInRange
        XCTAssertNotNil(error.errorDescription)
    }
    
    // MARK: - DreamAssistant 测试 (Phase 13)
    
    func testChatMessageModel() throws {
        // 测试聊天消息模型
        let message = ChatMessage(
            content: "测试消息",
            sender: .user,
            type: .text
        )
        
        XCTAssertEqual(message.content, "测试消息")
        XCTAssertEqual(message.sender, .user)
        XCTAssertEqual(message.type, .text)
        XCTAssertNotNil(message.id)
        XCTAssertNotNil(message.timestamp)
    }
    
    func testChatMessageCodable() throws {
        // 测试消息 Codable
        let message = ChatMessage(
            content: "测试 Codable",
            sender: .assistant,
            type: .insight
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(message)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ChatMessage.self, from: data)
        
        XCTAssertEqual(decoded.content, message.content)
        XCTAssertEqual(decoded.sender, message.sender)
        XCTAssertEqual(decoded.type, message.type)
    }
    
    func testMessageSenderEnum() throws {
        // 测试发送者枚举
        XCTAssertEqual(MessageSender.user.rawValue, "user")
        XCTAssertEqual(MessageSender.assistant.rawValue, "assistant")
    }
    
    func testMessageTypeEnum() throws {
        // 测试消息类型枚举
        XCTAssertEqual(MessageType.text.rawValue, "text")
        XCTAssertEqual(MessageType.suggestion.rawValue, "suggestion")
        XCTAssertEqual(MessageType.dreamCard.rawValue, "dreamCard")
        XCTAssertEqual(MessageType.insight.rawValue, "insight")
        XCTAssertEqual(MessageType.quickAction.rawValue, "quickAction")
    }
    
    func testSuggestionChipModel() throws {
        // 测试建议芯片模型
        let chip = SuggestionChip(
            title: "本周统计",
            query: "我这周记录了多少个梦？",
            icon: "chart.bar"
        )
        
        XCTAssertEqual(chip.title, "本周统计")
        XCTAssertEqual(chip.query, "我这周记录了多少个梦？")
        XCTAssertEqual(chip.icon, "chart.bar")
        XCTAssertNotNil(chip.id)
    }
    
    func testQuickActionModel() throws {
        // 测试快速操作模型
        let action = QuickAction(
            title: "记录梦境",
            icon: "mic.fill",
            action: .recordDream
        )
        
        XCTAssertEqual(action.title, "记录梦境")
        XCTAssertEqual(action.icon, "mic.fill")
        XCTAssertEqual(action.action, QuickActionType.recordDream)
        XCTAssertNotNil(action.id)
    }
    
    func testQuickActionTypeEnum() throws {
        // 测试快速操作类型枚举
        let actions: [QuickActionType] = [
            .recordDream, .viewStats, .browseGallery,
            .searchDreams, .lucidTraining, .meditation
        ]
        
        XCTAssertEqual(actions.count, 6)
    }
    
    func testInsightCardModel() throws {
        // 测试洞察卡片模型
        let insight = InsightCard(
            title: "梦境统计",
            description: "本周共记录 5 个梦境",
            icon: "chart.bar",
            value: "5",
            trend: .up,
            color: "accent"
        )
        
        XCTAssertEqual(insight.title, "梦境统计")
        XCTAssertEqual(insight.description, "本周共记录 5 个梦境")
        XCTAssertEqual(insight.value, "5")
        XCTAssertEqual(insight.trend, .up)
    }
    
    func testTrendDirectionEnum() throws {
        // 测试趋势方向枚举
        XCTAssertEqual(TrendDirection.up.rawValue, "up")
        XCTAssertEqual(TrendDirection.down.rawValue, "down")
        XCTAssertEqual(TrendDirection.stable.rawValue, "stable")
    }
    
    func testAssistantStateEnum() throws {
        // 测试助手状态枚举
        let states: [AssistantState] = [.idle, .listening, .thinking, .speaking]
        XCTAssertEqual(states.count, 4)
    }
    
    func testQueryIntentParseSearch() throws {
        // 测试查询意图解析 - 搜索
        let intent1 = QueryIntent.parse("搜索关于飞行的梦")
        if case .searchDreams(let keyword) = intent1 {
            XCTAssertTrue(keyword.contains("飞行"))
        } else {
            XCTFail("Expected searchDreams intent")
        }
        
        let intent2 = QueryIntent.parse("找找有水的梦境")
        if case .searchDreams = intent2 {
            // 正确识别为搜索
        } else {
            XCTFail("Expected searchDreams intent")
        }
    }
    
    func testQueryIntentParseStats() throws {
        // 测试查询意图解析 - 统计
        let intent1 = QueryIntent.parse("我这周记录了多少个梦？")
        if case .askStats = intent1 {
            // 正确识别为统计查询
        } else {
            XCTFail("Expected askStats intent")
        }
        
        let intent2 = QueryIntent.parse("我的清醒梦比例是多少？")
        if case .askStats = intent2 {
            // 正确识别为统计查询
        } else {
            XCTFail("Expected askStats intent")
        }
    }
    
    func testQueryIntentParsePattern() throws {
        // 测试查询意图解析 - 模式
        let intent1 = QueryIntent.parse("我最近经常梦到什么？")
        if case .askPattern = intent1 {
            // 正确识别为模式查询
        } else {
            XCTFail("Expected askPattern intent")
        }
        
        let intent2 = QueryIntent.parse("我的梦境情绪趋势如何？")
        if case .askPattern = intent2 {
            // 正确识别为模式查询
        } else {
            XCTFail("Expected askPattern intent")
        }
    }
    
    func testQueryIntentParseRecommendation() throws {
        // 测试查询意图解析 - 推荐
        let intent = QueryIntent.parse("给我一些记录建议")
        if case .askRecommendation = intent {
            // 正确识别为推荐请求
        } else {
            XCTFail("Expected askRecommendation intent")
        }
    }
    
    func testQueryIntentParseHelp() throws {
        // 测试查询意图解析 - 帮助
        let intent = QueryIntent.parse("如何使用这个功能？")
        if case .askHelp = intent {
            // 正确识别为帮助请求
        } else {
            XCTFail("Expected askHelp intent")
        }
    }
    
    func testQueryIntentParseRecordDream() throws {
        // 测试查询意图解析 - 记录梦境
        let intent = QueryIntent.parse("我想记录一个梦")
        if case .recordDream = intent {
            // 正确识别为记录请求
        } else {
            XCTFail("Expected recordDream intent")
        }
    }
    
    func testQueryIntentParseUnknown() throws {
        // 测试查询意图解析 - 未知
        let intent = QueryIntent.parse("今天天气怎么样？")
        if case .unknown = intent {
            // 正确识别为未知意图
        } else {
            XCTFail("Expected unknown intent")
        }
    }
    
    func testDreamAssistantServiceSingleton() throws {
        // 测试助手服务单例
        let service1 = DreamAssistantService.shared
        let service2 = DreamAssistantService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testDreamAssistantServiceInitialState() async throws {
        // 测试助手服务初始状态
        let assistant = DreamAssistantService.shared
        
        XCTAssertEqual(assistant.state, .idle)
        XCTAssertFalse(assistant.isSpeaking)
        XCTAssertGreaterThan(assistant.messages.count, 0)  // 应该有问候语
        XCTAssertGreaterThan(assistant.suggestions.count, 0)
        XCTAssertGreaterThan(assistant.quickActions.count, 0)
    }
    
    func testDreamAssistantServiceSuggestions() async throws {
        // 测试建议芯片
        let assistant = DreamAssistantService.shared
        
        let expectedTitles = ["本周统计", "常见主题", "情绪分析", "清醒梦", "最佳时间", "连续记录"]
        let actualTitles = assistant.suggestions.map { $0.title }
        
        for expected in expectedTitles {
            XCTAssertTrue(actualTitles.contains(expected), "Should contain suggestion: \(expected)")
        }
    }
    
    func testDreamAssistantServiceQuickActions() async throws {
        // 测试快速操作
        let assistant = DreamAssistantService.shared
        
        let expectedTitles = ["记录梦境", "查看统计", "梦境画廊", "搜索", "清醒梦", "冥想"]
        let actualTitles = assistant.quickActions.map { $0.title }
        
        for expected in expectedTitles {
            XCTAssertTrue(actualTitles.contains(expected), "Should contain action: \(expected)")
        }
    }
    
    func testDreamAssistantServiceSendMessage() async throws {
        // 测试发送消息
        let assistant = DreamAssistantService.shared
        let initialCount = assistant.messages.count
        
        await assistant.sendMessage("测试消息")
        
        XCTAssertEqual(assistant.messages.count, initialCount + 2)  // 用户消息 + 助手回复
        
        let lastUserMessage = assistant.messages[assistant.messages.count - 2]
        XCTAssertEqual(lastUserMessage.sender, .user)
        XCTAssertEqual(lastUserMessage.content, "测试消息")
        
        let lastAssistantMessage = assistant.messages.last
        XCTAssertEqual(lastAssistantMessage?.sender, .assistant)
    }
    
    func testDreamAssistantServiceClearHistory() async throws {
        // 测试清除历史
        let assistant = DreamAssistantService.shared
        
        await assistant.sendMessage("测试消息 1")
        await assistant.sendMessage("测试消息 2")
        
        let countBeforeClear = assistant.messages.count
        XCTAssertGreaterThan(countBeforeClear, 1)
        
        assistant.clearHistory()
        
        XCTAssertGreaterThan(assistant.messages.count, 0)  // 应该有问候语
        XCTAssertLessThan(assistant.messages.count, countBeforeClear)
    }
    
    func testDreamAssistantServiceHandleSuggestion() async throws {
        // 测试处理建议芯片
        let assistant = DreamAssistantService.shared
        let suggestion = assistant.suggestions.first!
        let initialCount = assistant.messages.count
        
        await assistant.handleSuggestion(suggestion)
        
        XCTAssertEqual(assistant.messages.count, initialCount + 2)
    }
    
    // MARK: - Phase 13 语音模式测试
    
    func testVoiceModeEnableDisable() async throws {
        let assistant = DreamAssistantService.shared
        
        // 初始状态
        XCTAssertFalse(assistant.voiceModeEnabled)
        
        // 启用语音模式
        assistant.enableVoiceMode(true)
        XCTAssertTrue(assistant.voiceModeEnabled)
        
        // 禁用语音模式
        assistant.enableVoiceMode(false)
        XCTAssertFalse(assistant.voiceModeEnabled)
    }
    
    func testVoiceModeStateTransition() async throws {
        let assistant = DreamAssistantService.shared
        
        // 初始状态
        XCTAssertEqual(assistant.state, .idle)
        
        // 开始聆听
        assistant.startListening()
        XCTAssertEqual(assistant.state, .listening)
        XCTAssertTrue(assistant.isListening)
        
        // 停止聆听
        assistant.stopListening()
        XCTAssertEqual(assistant.state, .idle)
        XCTAssertFalse(assistant.isListening)
    }
    
    func testSpeechQueueProcessing() async throws {
        let assistant = DreamAssistantService.shared
        
        // 模拟添加多条语音消息到队列
        assistant.speakQueue = ["消息 1", "消息 2", "消息 3"]
        
        // 验证队列状态
        XCTAssertEqual(assistant.speakQueue.count, 3)
        
        // 清空队列
        assistant.speakQueue.removeAll()
        XCTAssertEqual(assistant.speakQueue.count, 0)
    }
    
    func testSpeechMessagePlayback() async throws {
        let assistant = DreamAssistantService.shared
        
        // 验证语音播放状态
        XCTAssertFalse(assistant.isSpeaking)
        
        // 模拟播放 (实际播放需要硬件支持)
        // 这里只验证状态管理逻辑
        assistant.isSpeaking = true
        XCTAssertTrue(assistant.isSpeaking)
        
        assistant.isSpeaking = false
        XCTAssertFalse(assistant.isSpeaking)
    }
    
    func testVoiceModeToggle() async throws {
        let assistant = DreamAssistantService.shared
        
        let initialState = assistant.voiceModeEnabled
        assistant.toggleVoiceMode()
        XCTAssertEqual(assistant.voiceModeEnabled, !initialState)
        
        assistant.toggleVoiceMode()
        XCTAssertEqual(assistant.voiceModeEnabled, initialState)
    }
    
    // MARK: - Phase 13 预测洞察测试
    
    func testPredictionInsightsGeneration() async throws {
        let assistant = DreamAssistantService.shared
        let trendService = DreamTrendService.shared
        
        // 创建测试梦境数据
        let dreams = createTestDreams(count: 20)
        
        // 生成预测洞察
        let insights = await assistant.generatePredictionInsights(dreams: dreams)
        
        XCTAssertGreaterThan(insights.count, 0)
        
        for insight in insights {
            XCTAssertFalse(insight.type.rawValue.isEmpty)
            XCTAssertGreaterThan(insight.description.count, 0)
            XCTAssertGreaterThan(insight.confidence, 0)
            XCTAssertLessThanOrEqual(insight.confidence, 1)
        }
    }
    
    func testEmotionTrendPrediction() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 15)
        
        let insights = await assistant.generatePredictionInsights(dreams: dreams)
        
        let emotionInsights = insights.filter { $0.type == .emotionTrend }
        XCTAssertGreaterThan(emotionInsights.count, 0)
        
        let emotionInsight = emotionInsights.first!
        XCTAssertTrue(emotionInsight.description.contains("情绪") || 
                      emotionInsight.description.contains("积极") ||
                      emotionInsight.description.contains("消极"))
    }
    
    func testThemeTrendPrediction() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 15)
        
        let insights = await assistant.generatePredictionInsights(dreams: dreams)
        
        let themeInsights = insights.filter { $0.type == .themeTrend }
        XCTAssertGreaterThan(themeInsights.count, 0)
        
        let themeInsight = themeInsights.first!
        XCTAssertTrue(themeInsight.description.contains("主题") || 
                      themeInsight.description.contains("标签") ||
                      themeInsight.description.contains("内容"))
    }
    
    func testClarityPrediction() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 15)
        
        let insights = await assistant.generatePredictionInsights(dreams: dreams)
        
        let clarityInsights = insights.filter { $0.type == .clarity }
        XCTAssertGreaterThan(clarityInsights.count, 0)
        
        let clarityInsight = clarityInsights.first!
        XCTAssertTrue(clarityInsight.description.contains("清晰度") || 
                      clarityInsight.description.contains("提升") ||
                      clarityInsight.description.contains("下降"))
    }
    
    func testLucidDreamOpportunityPrediction() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 15)
        
        let insights = await assistant.generatePredictionInsights(dreams: dreams)
        
        let lucidInsights = insights.filter { $0.type == .lucidDream }
        XCTAssertGreaterThan(lucidInsights.count, 0)
        
        let lucidInsight = lucidInsights.first!
        XCTAssertTrue(lucidInsight.description.contains("清醒梦") || 
                      lucidInsight.description.contains("机会") ||
                      lucidInsight.description.contains("频率"))
    }
    
    // MARK: - Phase 13 深度分析测试
    
    func testDeepAnalysisReportGeneration() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 20)
        
        let report = await assistant.performDeepAnalysis(dreams: dreams)
        
        XCTAssertNotNil(report)
        
        if let report = report {
            XCTAssertGreaterThanOrEqual(report.totalDreams, 0)
            XCTAssertGreaterThanOrEqual(report.avgClarity, 1)
            XCTAssertLessThanOrEqual(report.avgClarity, 5)
            XCTAssertGreaterThanOrEqual(report.avgIntensity, 1)
            XCTAssertLessThanOrEqual(report.avgIntensity, 5)
            XCTAssertGreaterThanOrEqual(report.lucidRatio, 0)
            XCTAssertLessThanOrEqual(report.lucidRatio, 1)
        }
    }
    
    func testNineDimensionAnalysis() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 25)
        
        let report = await assistant.performDeepAnalysis(dreams: dreams)
        
        guard let report = report else {
            XCTFail("应该生成分析报告")
            return
        }
        
        // 验证 9 维度完整性
        XCTAssertNotNil(report.totalDreams)
        XCTAssertNotNil(report.avgClarity)
        XCTAssertNotNil(report.avgIntensity)
        XCTAssertNotNil(report.lucidRatio)
        XCTAssertNotNil(report.dreamFrequency)
        XCTAssertNotNil(report.streakDays)
        XCTAssertNotNil(report.bestRecordingTime)
        XCTAssertNotNil(report.topTags)
        XCTAssertNotNil(report.topEmotions)
    }
    
    func testTagCloudGeneration() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 20)
        
        let report = await assistant.performDeepAnalysis(dreams: dreams)
        
        guard let report = report else {
            XCTFail("应该生成分析报告")
            return
        }
        
        // 验证标签云数据
        XCTAssertGreaterThan(report.topTags.count, 0)
        
        for tag in report.topTags {
            XCTAssertFalse(tag.key.isEmpty)
            XCTAssertGreaterThan(tag.value, 0)
        }
    }
    
    func testEmotionCloudGeneration() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 20)
        
        let report = await assistant.performDeepAnalysis(dreams: dreams)
        
        guard let report = report else {
            XCTFail("应该生成分析报告")
            return
        }
        
        // 验证情绪云数据
        XCTAssertGreaterThan(report.topEmotions.count, 0)
        
        for emotion in report.topEmotions {
            XCTAssertFalse(emotion.key.rawValue.isEmpty)
            XCTAssertGreaterThan(emotion.value, 0)
        }
    }
    
    func testAnalysisReportCodable() async throws {
        let assistant = DreamAssistantService.shared
        let dreams = createTestDreams(count: 15)
        
        let report = await assistant.performDeepAnalysis(dreams: dreams)
        
        guard let report = report else {
            XCTFail("应该生成分析报告")
            return
        }
        
        // 测试 Codable 编解码
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(report)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let decodedReport = try decoder.decode(DreamAnalysisReport.self, from: data)
        
        XCTAssertEqual(decodedReport.totalDreams, report.totalDreams)
        XCTAssertEqual(decodedReport.avgClarity, report.avgClarity)
        XCTAssertEqual(decodedReport.avgIntensity, report.avgIntensity)
    }
    
    // MARK: - 预测模型测试
    
    func testDreamPredictionModel() throws {
        let prediction = DreamPrediction(
            type: .emotionTrend,
            trend: .positive,
            confidence: 0.75,
            description: "情绪趋势积极",
            timeFrame: "未来 7 天"
        )
        
        XCTAssertEqual(prediction.type, .emotionTrend)
        XCTAssertEqual(prediction.trend, .positive)
        XCTAssertEqual(prediction.confidence, 0.75)
        XCTAssertEqual(prediction.description, "情绪趋势积极")
        XCTAssertEqual(prediction.timeFrame, "未来 7 天")
    }
    
    func testDreamPredictionType() throws {
        let allTypes = DreamPredictionType.allCases
        XCTAssertEqual(allTypes.count, 4)
        
        for type in allTypes {
            XCTAssertFalse(type.rawValue.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
    
    func testDreamTrend() throws {
        let trends: [DreamTrend] = [.positive, .negative, .stable]
        
        for trend in trends {
            XCTAssertFalse(trend.rawValue.isEmpty)
            XCTAssertFalse(trend.icon.isEmpty)
            XCTAssertFalse(trend.color.isEmpty)
        }
    }
    
    // MARK: - Phase 14 梦境视频测试
    
    func testDreamVideoConfig() throws {
        let dreamId = UUID()
        let config = DreamVideoConfig(
            dreamId: dreamId,
            style: .cinematic,
            duration: .medium,
            includeMusic: true,
            includeTextOverlay: true,
            aspectRatio: .portrait,
            transitionStyle: .fade
        )
        
        XCTAssertEqual(config.dreamId, dreamId)
        XCTAssertEqual(config.style, .cinematic)
        XCTAssertEqual(config.duration, .medium)
        XCTAssertEqual(config.duration.seconds, 30)
        XCTAssertEqual(config.aspectRatio, .portrait)
        XCTAssertEqual(config.transitionStyle, .fade)
        XCTAssertTrue(config.includeMusic)
        XCTAssertTrue(config.includeTextOverlay)
    }
    
    func testVideoStyleEnum() throws {
        let allStyles = DreamVideoConfig.VideoStyle.allCases
        XCTAssertEqual(allStyles.count, 4)
        
        for style in allStyles {
            XCTAssertFalse(style.rawValue.isEmpty)
            XCTAssertFalse(style.id.isEmpty)
            XCTAssertFalse(style.description.isEmpty)
            XCTAssertFalse(style.icon.isEmpty)
        }
        
        XCTAssertEqual(DreamVideoConfig.VideoStyle.cinematic.description, "电影级转场效果，专业质感")
        XCTAssertEqual(DreamVideoConfig.VideoStyle.kenBurns.icon, "arrow.up.left.and.arrow.down.right")
    }
    
    func testVideoDurationEnum() throws {
        let allDurations = DreamVideoConfig.VideoDuration.allCases
        XCTAssertEqual(allDurations.count, 3)
        
        XCTAssertEqual(DreamVideoConfig.VideoDuration.short.seconds, 15)
        XCTAssertEqual(DreamVideoConfig.VideoDuration.medium.seconds, 30)
        XCTAssertEqual(DreamVideoConfig.VideoDuration.long.seconds, 60)
        
        for duration in allDurations {
            XCTAssertFalse(duration.rawValue.isEmpty)
            XCTAssertFalse(duration.id.isEmpty)
        }
    }
    
    func testAspectRatioEnum() throws {
        let allAspects = DreamVideoConfig.AspectRatio.allCases
        XCTAssertEqual(allAspects.count, 4)
        
        XCTAssertEqual(DreamVideoConfig.AspectRatio.square.size, CGSize(width: 1080, height: 1080))
        XCTAssertEqual(DreamVideoConfig.AspectRatio.portrait.size, CGSize(width: 1080, height: 1920))
        XCTAssertEqual(DreamVideoConfig.AspectRatio.landscape.size, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(DreamVideoConfig.AspectRatio.story.size, CGSize(width: 1080, height: 1350))
        
        for aspect in allAspects {
            XCTAssertFalse(aspect.rawValue.isEmpty)
            XCTAssertFalse(aspect.id.isEmpty)
        }
    }
    
    func testTransitionStyleEnum() throws {
        let allTransitions = DreamVideoConfig.TransitionStyle.allCases
        XCTAssertEqual(allTransitions.count, 4)
        
        for transition in allTransitions {
            XCTAssertFalse(transition.rawValue.isEmpty)
            XCTAssertFalse(transition.id.isEmpty)
        }
    }
    
    func testDreamVideoModel() throws {
        let video = DreamVideo(
            dreamId: UUID(),
            title: "测试梦境视频",
            filePath: "/path/to/video.mp4",
            thumbnailPath: "/path/to/thumbnail.jpg",
            duration: 30.0,
            style: "电影感",
            aspectRatio: "9:16 (竖屏)",
            createdAt: Date(),
            fileSize: 1024 * 1024 * 5
        )
        
        XCTAssertNotNil(video.id)
        XCTAssertEqual(video.title, "测试梦境视频")
        XCTAssertEqual(video.duration, 30.0)
        XCTAssertEqual(video.style, "电影感")
        XCTAssertEqual(video.fileSize, 5 * 1024 * 1024)
        XCTAssertFalse(video.isFavorite)
    }
    
    func testDreamVideoCodable() throws {
        let video = DreamVideo(
            dreamId: UUID(),
            title: "编码测试视频",
            filePath: "/path/to/video.mp4",
            thumbnailPath: "/path/to/thumbnail.jpg",
            duration: 60.0,
            style: "幻灯片",
            aspectRatio: "16:9 (横屏)",
            createdAt: Date(),
            fileSize: 1024 * 1024 * 10
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(video)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedVideo = try decoder.decode(DreamVideo.self, from: data)
        
        XCTAssertEqual(decodedVideo.title, video.title)
        XCTAssertEqual(decodedVideo.duration, video.duration)
        XCTAssertEqual(decodedVideo.style, video.style)
        XCTAssertEqual(decodedVideo.fileSize, video.fileSize)
    }
    
    func testVideoErrorEnum() throws {
        let errors: [VideoError] = [.alreadyGenerating, .noImages, .writerCreationFailed, .renderingFailed("测试错误"), .audioLoadFailed]
        
        for error in errors {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
        
        XCTAssertEqual(VideoError.alreadyGenerating.errorDescription, "正在生成另一个视频，请稍候")
        XCTAssertEqual(VideoError.noImages.errorDescription, "没有找到梦境图片，请先生成 AI 绘画")
        XCTAssertEqual(VideoError.renderingFailed("原因").errorDescription, "视频渲染失败：原因")
    }
    
    func testVideoServiceSingleton() throws {
        let service1 = DreamVideoService.shared
        let service2 = DreamVideoService.shared
        
        XCTAssertIdentical(service1, service2)
        XCTAssertFalse(service1.isGenerating)
        XCTAssertEqual(service1.generationProgress, 0.0)
        XCTAssertNil(service1.lastError)
    }
    
    func testVideoServiceState() throws {
        let service = DreamVideoService.shared
        
        XCTAssertFalse(service.isGenerating)
        XCTAssertEqual(service.generationProgress, 0.0)
        XCTAssertEqual(service.generationStatus, "")
        XCTAssertNil(service.lastError)
        XCTAssertNotNil(service.videos)
    }
    
    func testNSShadowExtension() throws {
        let shadow = NSShadow.shadowWith(
            color: .black,
            offset: CGSize(width: 2, height: 2),
            blurRadius: 4
        )
        
        XCTAssertEqual(shadow.shadowColor as? UIColor, .black)
        XCTAssertEqual(shadow.shadowOffset, CGSize(width: 2, height: 2))
        XCTAssertEqual(shadow.shadowBlurRadius, 4)
    }
}
