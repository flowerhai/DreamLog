//
//  DreamInspirationTests.swift
//  DreamLogTests - Phase 23: Dream Inspiration & Creative Prompts
//
//  梦境灵感功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamInspirationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamInspirationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            CreativePrompt.self,
            DailyInspiration.self,
            CreativeChallenge.self,
            Dream.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        service = DreamInspirationService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 创意提示测试
    
    /// 测试创意提示创建
    func testCreativePromptCreation() throws {
        let prompt = CreativePrompt(
            title: "测试提示",
            description: "这是一个测试创意提示",
            type: .writing,
            difficulty: 3,
            estimatedTime: 30,
            tags: ["测试", "创意"]
        )
        
        XCTAssertEqual(prompt.title, "测试提示")
        XCTAssertEqual(prompt.description, "这是一个测试创意提示")
        XCTAssertEqual(prompt.inspirationType, .writing)
        XCTAssertEqual(prompt.difficulty, 3)
        XCTAssertEqual(prompt.estimatedTime, 30)
        XCTAssertEqual(prompt.tags, ["测试", "创意"])
        XCTAssertFalse(prompt.isCompleted)
        XCTAssertFalse(prompt.isFavorite)
    }
    
    /// 测试提示类型枚举
    func testInspirationTypeProperties() {
        let types: [(InspirationType, String, String)] = [
            (.writing, "写作", "📝"),
            (.art, "艺术", "🎨"),
            (.music, "音乐", "🎵"),
            (.photography, "摄影", "📷"),
            (.meditation, "冥想", "🧘"),
            (.project, "项目", "🚀"),
            (.reflection, "反思", "💭"),
            (.challenge, "挑战", "🎯")
        ]
        
        for (type, expectedName, expectedIcon) in types {
            XCTAssertEqual(type.rawValue, expectedName)
            XCTAssertEqual(type.icon, expectedIcon)
            XCTAssertFalse(type.color.isEmpty)
        }
    }
    
    /// 测试提示保存
    func testSavePrompt() throws {
        let prompt = CreativePrompt(
            title: "保存测试",
            description: "测试保存功能",
            type: .art
        )
        
        service.savePrompt(prompt)
        
        let descriptor = FetchDescriptor<CreativePrompt>(
            predicate: #Predicate { $0.title == "保存测试" }
        )
        let savedPrompts = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(savedPrompts.count, 1)
        XCTAssertEqual(savedPrompts.first?.description, "测试保存功能")
    }
    
    /// 测试标记提示完成
    func testMarkPromptAsCompleted() throws {
        let prompt = CreativePrompt(
            title: "完成测试",
            description: "测试完成功能",
            type: .writing
        )
        
        service.savePrompt(prompt)
        XCTAssertFalse(prompt.isCompleted)
        XCTAssertNil(prompt.completedDate)
        
        service.markPromptAsCompleted(prompt)
        
        XCTAssertTrue(prompt.isCompleted)
        XCTAssertNotNil(prompt.completedDate)
        XCTAssertLessThanOrEqual(prompt.completedDate!, Date())
    }
    
    /// 测试切换收藏状态
    func testToggleFavorite() throws {
        let prompt = CreativePrompt(
            title: "收藏测试",
            description: "测试收藏功能",
            type: .music
        )
        
        service.savePrompt(prompt)
        XCTAssertFalse(prompt.isFavorite)
        
        service.toggleFavorite(prompt)
        XCTAssertTrue(prompt.isFavorite)
        
        service.toggleFavorite(prompt)
        XCTAssertFalse(prompt.isFavorite)
    }
    
    // MARK: - 生成提示测试
    
    /// 测试从梦境生成提示
    func testGeneratePromptFromDream() throws {
        // 创建测试梦境
        let dream = Dream(
            content: "我梦见自己在飞翔，穿越云层，看到了美丽的彩虹。",
            date: Date(),
            mood: .happy
        )
        modelContext.insert(dream)
        try modelContext.save()
        
        let prompt = service.generatePrompt(from: dream, type: .writing)
        
        XCTAssertEqual(prompt.sourceDreamId, dream.id)
        XCTAssertEqual(prompt.inspirationType, .writing)
        XCTAssertFalse(prompt.title.isEmpty)
        XCTAssertFalse(prompt.description.isEmpty)
    }
    
    /// 测试批量生成提示
    func testGenerateMultiplePrompts() throws {
        let dream = Dream(
            content: "测试梦境内容",
            date: Date(),
            mood: .neutral
        )
        modelContext.insert(dream)
        try modelContext.save()
        
        let prompts = service.generatePrompts(from: dream, count: 3)
        
        XCTAssertEqual(prompts.count, 3)
        
        // 确保类型不重复
        let types = Set(prompts.map { $0.inspirationType })
        XCTAssertEqual(types.count, 3)
        
        // 确保都关联到同一个梦
        for prompt in prompts {
            XCTAssertEqual(prompt.sourceDreamId, dream.id)
        }
    }
    
    // MARK: - 每日灵感测试
    
    /// 测试生成每日灵感
    func testGenerateDailyInspiration() {
        let inspiration = service.generateDailyInspiration()
        
        XCTAssertFalse(inspiration.quote.isEmpty)
        XCTAssertFalse(inspiration.prompt.isEmpty)
        XCTAssertFalse(inspiration.theme.isEmpty)
        XCTAssertEqual(Calendar.current.isDate(inspiration.date, inSameDayAs: Date()), true)
    }
    
    /// 测试保存每日灵感
    func testSaveDailyInspiration() throws {
        let inspiration = service.generateDailyInspiration()
        service.saveDailyInspiration(inspiration)
        
        let descriptor = FetchDescriptor<DailyInspiration>(
            predicate: #Predicate { $0.id == inspiration.id }
        )
        let saved = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.quote, inspiration.quote)
    }
    
    /// 测试获取今日灵感
    func testFetchTodayInspiration() throws {
        // 先保存一个今日灵感
        let today = Date()
        let inspiration = DailyInspiration(
            date: today,
            quote: "今日语录",
            prompt: "今日提示",
            theme: "测试主题"
        )
        service.saveDailyInspiration(inspiration)
        
        let fetched = service.fetchTodayInspiration()
        
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.quote, "今日语录")
    }
    
    // MARK: - 创意挑战测试
    
    /// 测试挑战创建
    func testChallengeCreation() {
        let challenge = CreativeChallenge(
            name: "7 天写作挑战",
            description: "连续 7 天写作",
            type: .writing,
            duration: 7
        )
        
        XCTAssertEqual(challenge.name, "7 天写作挑战")
        XCTAssertEqual(challenge.duration, 7)
        XCTAssertEqual(challenge.totalPrompts, 7)
        XCTAssertEqual(challenge.completedPrompts, 0)
        XCTAssertEqual(challenge.progress, 0)
        XCTAssertTrue(challenge.isActive)
        XCTAssertFalse(challenge.isCompleted)
    }
    
    /// 测试挑战进度计算
    func testChallengeProgress() {
        let challenge = CreativeChallenge(
            name: "测试挑战",
            description: "测试",
            type: .art,
            duration: 10,
            totalPrompts: 10,
            completedPrompts: 5
        )
        
        XCTAssertEqual(challenge.progress, 0.5)
        XCTAssertEqual(Int(challenge.progress * 100), 50)
    }
    
    /// 测试创建挑战
    func testCreateChallenge() throws {
        // 创建一些测试梦境
        for i in 0..<7 {
            let dream = Dream(
                content: "测试梦境 \(i)",
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date())!,
                mood: .neutral
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        let challenge = service.createChallenge(type: .writing, duration: 7)
        
        XCTAssertEqual(challenge.duration, 7)
        XCTAssertEqual(challenge.totalPrompts, 7)
        XCTAssertFalse(challenge.name.isEmpty)
        XCTAssertFalse(challenge.description.isEmpty)
    }
    
    /// 测试保存挑战
    func testSaveChallenge() throws {
        let challenge = CreativeChallenge(
            name: "保存测试挑战",
            description: "测试保存",
            type: .music
        )
        
        service.saveChallenge(challenge)
        
        let descriptor = FetchDescriptor<CreativeChallenge>(
            predicate: #Predicate { $0.name == "保存测试挑战" }
        )
        let saved = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(saved.count, 1)
    }
    
    // MARK: - 统计测试
    
    /// 测试获取统计数据
    func testGetStatistics() throws {
        // 创建测试数据
        let completedPrompt = CreativePrompt(
            title: "已完成",
            description: "测试",
            type: .writing,
            isCompleted: true,
            completedDate: Date()
        )
        
        let favoritePrompt = CreativePrompt(
            title: "收藏",
            description: "测试",
            type: .art,
            isFavorite: true
        )
        
        let pendingPrompt = CreativePrompt(
            title: "待完成",
            description: "测试",
            type: .music
        )
        
        service.savePrompt(completedPrompt)
        service.savePrompt(favoritePrompt)
        service.savePrompt(pendingPrompt)
        
        let stats = service.getStatistics()
        
        XCTAssertEqual(stats.totalPrompts, 3)
        XCTAssertEqual(stats.completedPrompts, 1)
        XCTAssertEqual(stats.favoritePrompts, 1)
    }
    
    /// 测试查询未完成提示
    func testFetchPendingPrompts() throws {
        let completed = CreativePrompt(
            title: "已完成",
            description: "测试",
            type: .writing,
            isCompleted: true
        )
        
        let pending1 = CreativePrompt(
            title: "待完成 1",
            description: "测试",
            type: .art
        )
        
        let pending2 = CreativePrompt(
            title: "待完成 2",
            description: "测试",
            type: .music
        )
        
        service.savePrompt(completed)
        service.savePrompt(pending1)
        service.savePrompt(pending2)
        
        let pending = service.fetchPendingPrompts()
        
        XCTAssertEqual(pending.count, 2)
        XCTAssertTrue(pending.allSatisfy { !$0.isCompleted })
    }
    
    /// 测试查询收藏提示
    func testFetchFavoritePrompts() throws {
        let fav1 = CreativePrompt(
            title: "收藏 1",
            description: "测试",
            type: .writing,
            isFavorite: true
        )
        
        let fav2 = CreativePrompt(
            title: "收藏 2",
            description: "测试",
            type: .art,
            isFavorite: true
        )
        
        let notFav = CreativePrompt(
            title: "未收藏",
            description: "测试",
            type: .music,
            isFavorite: false
        )
        
        service.savePrompt(fav1)
        service.savePrompt(fav2)
        service.savePrompt(notFav)
        
        let favorites = service.fetchFavoritePrompts()
        
        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(favorites.allSatisfy { $0.isFavorite })
    }
    
    // MARK: - 性能测试
    
    /// 测试大量提示的查询性能
    func testQueryPerformance() throws {
        // 创建 100 个测试提示
        for i in 0..<100 {
            let prompt = CreativePrompt(
                title: "提示 \(i)",
                description: "测试描述 \(i)",
                type: InspirationType.allCases[i % InspirationType.allCases.count],
                difficulty: (i % 5) + 1,
                estimatedTime: (i % 60) + 10
            )
            service.savePrompt(prompt)
        }
        
        // 测量查询时间
        let measure = XCTMeasureOptions.default
        measure.iterationCount = 5
        
        self.measure(metrics: [XCTCPUMetric(), XCTClockMetric()], options: measure) {
            let prompts = service.fetchAllPrompts()
            XCTAssertEqual(prompts.count, 100)
        }
    }
    
    // MARK: - 边界条件测试
    
    /// 测试空数据情况
    func testEmptyData() {
        let stats = service.getStatistics()
        
        XCTAssertEqual(stats.totalPrompts, 0)
        XCTAssertEqual(stats.completedPrompts, 0)
        XCTAssertEqual(stats.streakDays, 0)
    }
    
    /// 测试提示类型转换
    func testTypeConversion() {
        let prompt = CreativePrompt(
            title: "测试",
            description: "测试",
            type: .writing
        )
        
        // 测试 rawValue 转换
        XCTAssertEqual(prompt.type, "写作")
        XCTAssertEqual(prompt.inspirationType, .writing)
        
        // 测试无效值处理
        let invalidPrompt = CreativePrompt(
            title: "测试",
            description: "测试",
            type: InspirationType(rawValue: "无效类型") ?? .writing
        )
        
        XCTAssertEqual(invalidPrompt.inspirationType, .writing)
    }
}

// MARK: - 辅助扩展

extension Dream {
    convenience init(content: String, date: Date, mood: DreamMood) {
        self.init(
            content: content,
            date: date,
            moods: [mood],
            tags: [],
            lucidLevel: 0,
            recallClarity: 3
        )
    }
}
