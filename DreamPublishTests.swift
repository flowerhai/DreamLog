//
//  DreamPublishTests.swift
//  DreamLogTests
//
//  Phase 47: Dream Newsletter & Auto-Publishing
//  发布功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamPublishTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var publishService: DreamPublishService!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Dream.self, PublishTemplate.self, PublishTask.self, PublishConfig.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
        publishService = DreamPublishService(modelContext: modelContext)
        
        // 创建测试数据
        createSampleDreams()
        createSampleTemplates()
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        publishService = nil
    }
    
    // MARK: - Helper Methods
    
    private func createSampleDreams() {
        let dream1 = Dream(
            title: "飞行之梦",
            content: "我梦见自己在天空中自由飞翔，穿越云层，感受着风的轻抚。",
            date: Date(),
            tags: ["飞行", "自由", "天空"],
            emotions: [.happy, .excited],
            clarity: 4,
            intensity: 5,
            isLucid: true
        )
        
        let dream2 = Dream(
            title: "深海探险",
            content: "潜入深海，看到了五彩斑斓的珊瑚和奇异的海洋生物。",
            date: Date().addingTimeInterval(-86400),
            tags: ["海洋", "探险", "奇异"],
            emotions: [.curious, .calm],
            clarity: 3,
            intensity: 4,
            isLucid: false
        )
        
        modelContext.insert(dream1)
        modelContext.insert(dream2)
        try? modelContext.save()
    }
    
    private func createSampleTemplates() {
        let templates = PublishTemplate.presets()
        for template in templates {
            modelContext.insert(template)
        }
        try? modelContext.save()
    }
    
    // MARK: - Template Tests
    
    func testFetchTemplates() async throws {
        let templates = await publishService.fetchTemplates()
        XCTAssertGreaterThan(templates.count, 0, "应该至少有一个预设模板")
    }
    
    func testGetDefaultTemplate() async throws {
        let template = await publishService.getDefaultTemplate(for: .medium)
        XCTAssertNotNil(template, "Medium 平台应该有默认模板")
        XCTAssertEqual(template?.platform, PublishPlatform.medium.rawValue)
    }
    
    func testSaveTemplate() async throws {
        let template = PublishTemplate(
            name: "测试模板",
            platform: PublishPlatform.twitter.rawValue,
            titleTemplate: "{{title}}",
            contentTemplate: "{{content}}",
            includeTags: true,
            includeEmotions: false,
            includeAIAnalysis: false,
            includeImages: true,
            hashtagStyle: "suffix"
        )
        
        try await publishService.saveTemplate(template)
        
        let templates = await publishService.fetchTemplates()
        let savedTemplate = templates.first { $0.name == "测试模板" }
        XCTAssertNotNil(savedTemplate, "模板应该被保存")
    }
    
    func testDeleteTemplate() async throws {
        let template = PublishTemplate(
            name: "待删除模板",
            platform: PublishPlatform.twitter.rawValue,
            titleTemplate: "{{title}}",
            contentTemplate: "{{content}}"
        )
        
        try await publishService.saveTemplate(template)
        try await publishService.deleteTemplate(template)
        
        let templates = await publishService.fetchTemplates()
        let deletedTemplate = templates.first { $0.name == "待删除模板" }
        XCTAssertNil(deletedTemplate, "模板应该被删除")
    }
    
    // MARK: - Content Generation Tests
    
    func testGenerateContent() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        guard let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有默认模板")
            return
        }
        
        let preview = await publishService.generateContent(dream: dream, template: template)
        
        XCTAssertGreaterThan(preview.title.count, 0, "标题不应该为空")
        XCTAssertGreaterThan(preview.content.count, 0, "内容不应该为空")
        XCTAssertTrue(preview.title.contains(dream.title), "标题应该包含梦境标题")
        XCTAssertTrue(preview.content.contains(dream.content), "内容应该包含梦境内容")
    }
    
    func testGenerateContentWithTagSubstitution() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        let template = PublishTemplate(
            name: "标签测试",
            platform: PublishPlatform.twitter.rawValue,
            titleTemplate: "{{title}}",
            contentTemplate: "{{content}}\n\n#{{tagsJoined}}",
            includeTags: true,
            includeEmotions: false,
            includeAIAnalysis: false,
            includeImages: false,
            hashtagStyle: "suffix"
        )
        
        let preview = await publishService.generateContent(dream: dream, template: template)
        
        XCTAssertTrue(preview.content.contains("#飞行"), "应该包含标签")
        XCTAssertTrue(preview.content.contains("#自由"), "应该包含标签")
    }
    
    func testGenerateContentWithConditional() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        let template = PublishTemplate(
            name: "条件测试",
            platform: PublishPlatform.medium.rawValue,
            titleTemplate: "{{title}}",
            contentTemplate: """
            {{content}}
            
            {{#if aiAnalysis}}
            AI 解析：{{aiAnalysis}}
            {{/if}}
            """,
            includeTags: false,
            includeEmotions: false,
            includeAIAnalysis: true,
            includeImages: false,
            hashtagStyle: "none"
        )
        
        let preview = await publishService.generateContent(dream: dream, template: template)
        
        // 由于梦境没有 AI 解析，条件块应该被移除
        XCTAssertFalse(preview.content.contains("AI 解析："), "没有 AI 解析时应该移除条件块")
    }
    
    func testGenerateContentWithAIAnalysis() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        var dreams = try modelContext.fetch(descriptor)
        guard var dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        // 添加 AI 解析
        dream.aiAnalysis = "飞行梦通常象征着对自由的渴望和摆脱束缚的愿望。"
        
        let template = PublishTemplate(
            name: "AI 解析测试",
            platform: PublishPlatform.medium.rawValue,
            titleTemplate: "{{title}}",
            contentTemplate: """
            {{content}}
            
            {{#if aiAnalysis}}
            ## AI 解析
            
            {{aiAnalysis}}
            {{/if}}
            """,
            includeTags: false,
            includeEmotions: false,
            includeAIAnalysis: true,
            includeImages: false,
            hashtagStyle: "none"
        )
        
        let preview = await publishService.generateContent(dream: dream, template: template)
        
        XCTAssertTrue(preview.content.contains("AI 解析"), "应该包含 AI 解析部分")
        XCTAssertTrue(preview.content.contains("飞行梦"), "应该包含 AI 解析内容")
    }
    
    func testGenerateContentCharacterCount() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        guard let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有默认模板")
            return
        }
        
        let preview = await publishService.generateContent(dream: dream, template: template)
        
        XCTAssertEqual(preview.characterCount, (preview.title + preview.content).count, "字符数应该正确")
        XCTAssertGreaterThan(preview.estimatedReadTime, 0, "阅读时间应该大于 0")
    }
    
    func testExtractHashtags() async throws {
        let content = "这是一个测试 #梦境 #飞行 #自由 #天空"
        
        // 通过服务提取标签
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        let template = PublishTemplate(
            name: "标签提取测试",
            platform: PublishPlatform.twitter.rawValue,
            titleTemplate: "",
            contentTemplate: content,
            includeTags: false,
            includeEmotions: false,
            includeAIAnalysis: false,
            includeImages: false,
            hashtagStyle: "none"
        )
        
        let preview = await publishService.generateContent(dream: dream, template: template)
        
        XCTAssertEqual(preview.hashtags.count, 4, "应该提取 4 个标签")
        XCTAssertTrue(preview.hashtags.contains("#梦境"), "应该包含#梦境")
    }
    
    // MARK: - Publish Task Tests
    
    func testCreatePublishTask() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        guard let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有默认模板")
            return
        }
        
        let task = try await publishService.createPublishTask(
            dream: dream,
            platform: .medium,
            template: template
        )
        
        XCTAssertEqual(task.title, dream.title)
        XCTAssertEqual(task.platform, PublishPlatform.medium.rawValue)
        XCTAssertEqual(task.taskStatus, .pending)
        XCTAssertEqual(task.dreamIds.count, 1)
    }
    
    func testCreateScheduledTask() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first else {
            XCTFail("应该找到测试梦境")
            return
        }
        
        guard let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有默认模板")
            return
        }
        
        let scheduledDate = Date().addingTimeInterval(3600) // 1 小时后
        
        let task = try await publishService.createPublishTask(
            dream: dream,
            platform: .medium,
            template: template,
            scheduledAt: scheduledDate
        )
        
        XCTAssertEqual(task.taskStatus, .scheduled)
        XCTAssertEqual(task.scheduledAt, scheduledDate)
    }
    
    func testCreateNewsletterTask() async throws {
        let dreams: [Dream] = try modelContext.fetch(FetchDescriptor<Dream>())
        guard !dreams.isEmpty else {
            XCTFail("应该有测试梦境")
            return
        }
        
        guard let template = await publishService.getDefaultTemplate(for: .email) else {
            // 如果没有 email 模板，创建一个
            let emailTemplate = PublishTemplate(
                name: "邮件通讯",
                platform: "email",
                titleTemplate: "Weekly Digest",
                contentTemplate: "{{content}}",
                includeTags: false,
                includeEmotions: false,
                includeAIAnalysis: true,
                includeImages: true,
                hashtagStyle: "none"
            )
            try await publishService.saveTemplate(emailTemplate)
            template = emailTemplate
        }
        
        let task = try await publishService.createNewsletterTask(
            dreams: dreams,
            platform: .custom,
            template: template
        )
        
        XCTAssertEqual(task.dreamIds.count, dreams.count)
        XCTAssertEqual(task.taskStatus, .pending)
    }
    
    func testFetchTasks() async throws {
        // 创建一些任务
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first,
              let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有测试数据")
            return
        }
        
        _ = try await publishService.createPublishTask(dream: dream, platform: .medium, template: template)
        _ = try await publishService.createPublishTask(dream: dream, platform: .medium, template: template)
        
        let tasks = await publishService.fetchTasks()
        XCTAssertGreaterThanOrEqual(tasks.count, 2, "应该至少有 2 个任务")
    }
    
    func testFetchTasksByStatus() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first,
              let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有测试数据")
            return
        }
        
        _ = try await publishService.createPublishTask(dream: dream, platform: .medium, template: template)
        
        let pendingTasks = await publishService.fetchTasks(status: .pending)
        XCTAssertGreaterThan(pendingTasks.count, 0, "应该有待发布任务")
    }
    
    func testUpdateTaskStatus() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first,
              let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有测试数据")
            return
        }
        
        let task = try await publishService.createPublishTask(dream: dream, platform: .medium, template: template)
        
        try await publishService.updateTaskStatus(task, status: .success, url: "https://example.com/post")
        
        let updatedTasks = await publishService.fetchTasks(status: .success)
        XCTAssertEqual(updatedTasks.count, 1)
        XCTAssertEqual(updatedTasks.first?.publishedURL, "https://example.com/post")
    }
    
    func testDeleteTask() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first,
              let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有测试数据")
            return
        }
        
        let task = try await publishService.createPublishTask(dream: dream, platform: .medium, template: template)
        try await publishService.deleteTask(task)
        
        let tasks = await publishService.fetchTasks()
        let deletedTask = tasks.first { $0.id == task.id }
        XCTAssertNil(deletedTask, "任务应该被删除")
    }
    
    // MARK: - Configuration Tests
    
    func testSaveConfig() async throws {
        let config = PublishConfig(
            platform: PublishPlatform.medium.rawValue,
            apiKey: "test-api-key-123",
            autoPublish: true
        )
        
        try await publishService.saveConfig(config)
        
        let fetchedConfig = try await publishService.fetchConfig(for: PublishPlatform.medium.rawValue)
        XCTAssertNotNil(fetchedConfig)
        XCTAssertEqual(fetchedConfig?.apiKey, "test-api-key-123")
    }
    
    func testUpdateConfig() async throws {
        var config = PublishConfig(
            platform: PublishPlatform.wordpress.rawValue,
            apiKey: "old-key",
            endpoint: "https://old.com"
        )
        
        try await publishService.saveConfig(config)
        
        config.apiKey = "new-key"
        config.endpoint = "https://new.com"
        
        try await publishService.saveConfig(config)
        
        let fetchedConfig = try await publishService.fetchConfig(for: PublishPlatform.wordpress.rawValue)
        XCTAssertEqual(fetchedConfig?.apiKey, "new-key")
        XCTAssertEqual(fetchedConfig?.endpoint, "https://new.com")
    }
    
    func testDeleteConfig() async throws {
        let config = PublishConfig(
            platform: PublishPlatform.ghost.rawValue,
            apiKey: "test-key"
        )
        
        try await publishService.saveConfig(config)
        try await publishService.deleteConfig(config)
        
        let fetchedConfig = try await publishService.fetchConfig(for: PublishPlatform.ghost.rawValue)
        XCTAssertNil(fetchedConfig, "配置应该被删除")
    }
    
    // MARK: - Statistics Tests
    
    func testGetStats() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first,
              let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有测试数据")
            return
        }
        
        // 创建一些成功任务
        let task1 = try await publishService.createPublishTask(dream: dream, platform: .medium, template: template)
        let task2 = try await publishService.createPublishTask(dream: dream, platform: .wordpress, template: template)
        
        try await publishService.updateTaskStatus(task1, status: .success, url: "https://medium.com/post1")
        try await publishService.updateTaskStatus(task2, status: .success, url: "https://wordpress.com/post1")
        
        let stats = await publishService.getStats()
        
        XCTAssertEqual(stats.totalPublished, 2)
        XCTAssertEqual(stats.byPlatform["medium"], 1)
        XCTAssertEqual(stats.byPlatform["wordpress"], 1)
    }
    
    func testGetStatsEmpty() async throws {
        let stats = await publishService.getStats()
        
        XCTAssertEqual(stats.totalPublished, 0)
        XCTAssertNil(stats.mostPopularPlatform)
    }
    
    // MARK: - Platform Enum Tests
    
    func testPlatformProperties() {
        XCTAssertEqual(PublishPlatform.medium.displayName, "Medium")
        XCTAssertEqual(PublishPlatform.wechat.displayName, "微信公众号")
        XCTAssertEqual(PublishPlatform.xiaohongshu.displayName, "小红书")
        
        XCTAssertTrue(PublishPlatform.medium.requiresAPIKey)
        XCTAssertFalse(PublishPlatform.wechat.requiresAPIKey)
        
        XCTAssertTrue(PublishPlatform.medium.supportsAutoPublish)
        XCTAssertFalse(PublishPlatform.wechat.supportsAutoPublish)
    }
    
    func testPlatformIcons() {
        XCTAssertNotNil(PublishPlatform.medium.icon)
        XCTAssertNotNil(PublishPlatform.twitter.icon)
        XCTAssertNotNil(PublishPlatform.custom.icon)
    }
    
    // MARK: - Error Tests
    
    func testPublishErrorMessages() {
        XCTAssertEqual(PublishError.missingCredentials.errorDescription, "缺少平台凭证，请在设置中配置 API Key")
        XCTAssertEqual(PublishError.invalidTemplate.errorDescription, "模板格式无效")
        XCTAssertEqual(PublishError.platformNotSupported.errorDescription, "该平台不支持自动发布")
        XCTAssertEqual(PublishError.networkError.errorDescription, "网络错误，请检查连接")
        XCTAssertEqual(PublishError.rateLimitExceeded.errorDescription, "发布频率超限，请稍后再试")
    }
    
    // MARK: - Performance Tests
    
    func testContentGenerationPerformance() async throws {
        let descriptor = FetchDescriptor<Dream>(predicate: #Predicate<Dream> { $0.title == "飞行之梦" })
        let dreams = try modelContext.fetch(descriptor)
        guard let dream = dreams.first,
              let template = await publishService.getDefaultTemplate(for: .medium) else {
            XCTFail("应该有测试数据")
            return
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<100 {
            _ = await publishService.generateContent(dream: dream, template: template)
        }
        
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        let averageTime = elapsed / 100
        
        XCTAssertLessThan(averageTime, 0.1, "每次内容生成应该小于 100ms")
    }
}
