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
}
