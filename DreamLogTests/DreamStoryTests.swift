//
//  DreamStoryTests.swift
//  DreamLogTests
//
//  梦境故事模式单元测试
//  Phase 70: Dream Story Mode
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamStoryTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        // 创建内存中的 ModelContainer 用于测试
        let schema = Schema([
            Dream.self,
            DreamStory.self,
            DreamStoryFrame.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 数据模型测试
    
    /// 测试 DreamStory 模型创建
    func testDreamStoryCreation() throws {
        let story = DreamStory(
            title: "测试故事",
            description: "这是一个测试故事",
            coverEmoji: "🌙",
            theme: .starry,
            storyType: .chronological,
            dreams: [],
            frames: [],
            tags: ["测试"],
            isPublic: false
        )
        
        modelContext.insert(story)
        try modelContext.save()
        
        XCTAssertEqual(story.title, "测试故事")
        XCTAssertEqual(story.description, "这是一个测试故事")
        XCTAssertEqual(story.coverEmoji, "🌙")
        XCTAssertEqual(story.theme, .starry)
        XCTAssertEqual(story.storyType, .chronological)
        XCTAssertEqual(story.tags, ["测试"])
        XCTAssertFalse(story.isPublic)
        XCTAssertEqual(story.viewCount, 0)
        XCTAssertEqual(story.likeCount, 0)
        XCTAssertEqual(story.shareCount, 0)
    }
    
    /// 测试 DreamStoryFrame 模型创建
    func testDreamStoryFrameCreation() throws {
        let story = DreamStory(title: "测试故事", description: "")
        modelContext.insert(story)
        
        let frame = DreamStoryFrame(
            storyId: story.id,
            dreamId: UUID(),
            order: 0,
            title: "第一帧",
            content: "这是第一帧的内容",
            aiArtPrompt: "测试提示词",
            transition: .fade,
            duration: 5.0,
            narration: "测试旁白"
        )
        
        modelContext.insert(frame)
        story.frames.append(frame)
        try modelContext.save()
        
        XCTAssertEqual(frame.order, 0)
        XCTAssertEqual(frame.title, "第一帧")
        XCTAssertEqual(frame.content, "这是第一帧的内容")
        XCTAssertEqual(frame.transition, .fade)
        XCTAssertEqual(frame.duration, 5.0)
        XCTAssertEqual(frame.narration, "测试旁白")
    }
    
    // MARK: - 主题枚举测试
    
    /// 测试 DreamStoryTheme 所有案例
    func testDreamStoryThemeCases() {
        let themes: [DreamStoryTheme] = [
            .starry, .sunset, .ocean, .forest, .midnight,
            .rose, .luxury, .lavender, .aurora, .crystal
        ]
        
        for theme in themes {
            XCTAssertFalse(theme.displayName.isEmpty, "主题 \(theme) 应该有显示名称")
            XCTAssertEqual(theme.colors.count, 3, "主题 \(theme) 应该有 3 种颜色")
        }
    }
    
    /// 测试主题颜色
    func testThemeColors() {
        let starryColors = DreamStoryTheme.starry.colors
        XCTAssertEqual(starryColors.count, 3)
        XCTAssertEqual(starryColors[0], "#4A148C")
        XCTAssertEqual(starryColors[1], "#7B1FA2")
        XCTAssertEqual(starryColors[2], "#9C27B0")
    }
    
    // MARK: - 故事类型枚举测试
    
    /// 测试 DreamStoryType 所有案例
    func testDreamStoryTypeCases() {
        let types: [DreamStoryType] = [
            .chronological, .thematic, .emotional, .lucid, .creative, .healing
        ]
        
        for type in types {
            XCTAssertFalse(type.displayName.isEmpty, "类型 \(type) 应该有显示名称")
            XCTAssertFalse(type.description.isEmpty, "类型 \(type) 应该有描述")
        }
    }
    
    // MARK: - 转场效果枚举测试
    
    /// 测试 DreamStoryTransition 所有案例
    func testDreamStoryTransitionCases() {
        let transitions: [DreamStoryTransition] = [
            .fade, .slide, .zoom, .dissolve, .pageTurn, .morph
        ]
        
        for transition in transitions {
            XCTAssertFalse(transition.displayName.isEmpty, "转场 \(transition) 应该有显示名称")
        }
    }
    
    // MARK: - 配置测试
    
    /// 测试 DreamStoryConfig 创建
    func testDreamStoryConfigCreation() {
        let config = DreamStoryConfig(
            title: "配置测试",
            description: "测试描述",
            selectedDreams: [UUID(), UUID()],
            theme: .ocean,
            storyType: .thematic,
            autoGenerateArt: true,
            autoGenerateNarration: true,
            frameDuration: 7.0,
            transition: .slide,
            backgroundMusic: "music_1",
            coverEmoji: "✨",
            tags: ["测试", "配置"],
            isPublic: true
        )
        
        XCTAssertEqual(config.title, "配置测试")
        XCTAssertEqual(config.description, "测试描述")
        XCTAssertEqual(config.selectedDreams.count, 2)
        XCTAssertEqual(config.theme, .ocean)
        XCTAssertEqual(config.storyType, .thematic)
        XCTAssertTrue(config.autoGenerateArt)
        XCTAssertTrue(config.autoGenerateNarration)
        XCTAssertEqual(config.frameDuration, 7.0)
        XCTAssertEqual(config.transition, .slide)
        XCTAssertEqual(config.coverEmoji, "✨")
        XCTAssertEqual(config.tags, ["测试", "配置"])
        XCTAssertTrue(config.isPublic)
    }
    
    /// 测试默认配置
    func testDefaultConfig() {
        let config = DreamStoryConfig(title: "默认配置")
        
        XCTAssertEqual(config.theme, .starry)
        XCTAssertEqual(config.storyType, .chronological)
        XCTAssertTrue(config.autoGenerateArt)
        XCTAssertTrue(config.autoGenerateNarration)
        XCTAssertEqual(config.frameDuration, 5.0)
        XCTAssertEqual(config.transition, .fade)
        XCTAssertEqual(config.coverEmoji, "🌙")
        XCTAssertFalse(config.isPublic)
    }
    
    // MARK: - 统计测试
    
    /// 测试 DreamStoryStats 创建
    func testDreamStoryStatsCreation() {
        let stats = DreamStoryStats(
            totalStories: 10,
            totalFrames: 50,
            totalViews: 100,
            totalLikes: 200,
            totalShares: 30,
            averageDuration: 120.0,
            favoriteTheme: .starry,
            favoriteType: .chronological
        )
        
        XCTAssertEqual(stats.totalStories, 10)
        XCTAssertEqual(stats.totalFrames, 50)
        XCTAssertEqual(stats.totalViews, 100)
        XCTAssertEqual(stats.totalLikes, 200)
        XCTAssertEqual(stats.totalShares, 30)
        XCTAssertEqual(stats.averageDuration, 120.0)
        XCTAssertEqual(stats.favoriteTheme, .starry)
        XCTAssertEqual(stats.favoriteType, .chronological)
    }
    
    /// 测试默认统计
    func testDefaultStats() {
        let stats = DreamStoryStats()
        
        XCTAssertEqual(stats.totalStories, 0)
        XCTAssertEqual(stats.totalFrames, 0)
        XCTAssertEqual(stats.totalViews, 0)
        XCTAssertEqual(stats.totalLikes, 0)
        XCTAssertEqual(stats.totalShares, 0)
        XCTAssertEqual(stats.averageDuration, 0)
        XCTAssertNil(stats.favoriteTheme)
        XCTAssertNil(stats.favoriteType)
    }
    
    // MARK: - 分享卡片测试
    
    /// 测试 DreamStoryShareCard 创建
    func testDreamStoryShareCardCreation() {
        let storyId = UUID()
        let card = DreamStoryShareCard(
            storyId: storyId,
            title: "分享卡片测试",
            frameCount: 5,
            duration: 300.0,
            theme: .sunset,
            shareUrl: "dreamlog://story/TEST123"
        )
        
        XCTAssertEqual(card.storyId, storyId)
        XCTAssertEqual(card.title, "分享卡片测试")
        XCTAssertEqual(card.frameCount, 5)
        XCTAssertEqual(card.duration, 300.0)
        XCTAssertEqual(card.theme, .sunset)
        XCTAssertEqual(card.shareUrl, "dreamlog://story/TEST123")
        
        // 测试默认过期时间（7 天后）
        let expectedExpiry = Date().addingTimeInterval(7 * 24 * 3600)
        let timeDifference = abs(card.expiresAt.timeIntervalSince(expectedExpiry))
        XCTAssertLessThan(timeDifference, 60) // 允许 1 分钟误差
    }
    
    // MARK: - 服务层测试
    
    /// 测试 DreamStoryService 初始化
    func testDreamStoryServiceInitialization() async throws {
        let service = DreamStoryService(modelContext: modelContext)
        
        // 验证服务可以正常初始化
        let stories = try await service.getAllStories()
        XCTAssertEqual(stories.count, 0)
    }
    
    /// 测试创建故事
    func testCreateStory() async throws {
        // 创建测试梦境
        let dream = Dream(
            title: "测试梦境",
            content: "这是一个测试梦境的内容",
            date: Date(),
            tags: ["测试"],
            emotions: [.calm],
            clarity: 4,
            intensity: 3,
            isLucid: false
        )
        modelContext.insert(dream)
        try modelContext.save()
        
        let service = DreamStoryService(modelContext: modelContext)
        
        let config = DreamStoryConfig(
            title: "测试故事",
            description: "测试描述",
            selectedDreams: [dream.id],
            theme: .starry,
            storyType: .chronological,
            autoGenerateArt: false, // 测试时不生成 AI 艺术
            autoGenerateNarration: true,
            frameDuration: 5.0
        )
        
        let story = try await service.createStory(config: config)
        
        XCTAssertEqual(story.title, "测试故事")
        XCTAssertEqual(story.dreams.count, 1)
        XCTAssertEqual(story.frames.count, 1)
        XCTAssertEqual(story.frames.first?.title, "测试梦境")
    }
    
    /// 测试获取所有故事
    func testGetAllStories() async throws {
        let service = DreamStoryService(modelContext: modelContext)
        
        // 创建多个测试故事
        for i in 1...3 {
            let story = DreamStory(
                title: "故事\(i)",
                description: "测试故事\(i)",
                theme: .starry,
                storyType: .chronological
            )
            modelContext.insert(story)
        }
        try modelContext.save()
        
        let stories = try await service.getAllStories()
        XCTAssertEqual(stories.count, 3)
    }
    
    /// 测试获取故事详情
    func testGetStoryById() async throws {
        let service = DreamStoryService(modelContext: modelContext)
        
        let story = DreamStory(
            title: "测试故事",
            description: "测试描述",
            theme: .starry,
            storyType: .chronological
        )
        modelContext.insert(story)
        try modelContext.save()
        
        let fetchedStory = try await service.getStoryById(story.id)
        
        XCTAssertNotNil(fetchedStory)
        XCTAssertEqual(fetchedStory?.id, story.id)
        XCTAssertEqual(fetchedStory?.title, "测试故事")
    }
    
    /// 测试获取不存在的故事
    func testGetNonExistentStory() async throws {
        let service = DreamStoryService(modelContext: modelContext)
        
        let fetchedStory = try await service.getStoryById(UUID())
        
        XCTAssertNil(fetchedStory)
    }
    
    /// 测试删除故事
    func testDeleteStory() async throws {
        let service = DreamStoryService(modelContext: modelContext)
        
        let story = DreamStory(
            title: "待删除故事",
            description: "测试",
            theme: .starry,
            storyType: .chronological
        )
        modelContext.insert(story)
        try modelContext.save()
        
        try await service.deleteStory(story)
        
        let stories = try await service.getAllStories()
        XCTAssertEqual(stories.count, 0)
    }
    
    /// 测试获取统计
    func testGetStats() async throws {
        let service = DreamStoryService(modelContext: modelContext)
        
        // 创建测试数据
        for i in 1...5 {
            let story = DreamStory(
                title: "故事\(i)",
                description: "测试",
                theme: i % 2 == 0 ? .starry : .ocean,
                storyType: .chronological,
                viewCount: i * 10,
                likeCount: i * 5,
                shareCount: i
            )
            
            // 添加帧
            for j in 0..<3 {
                let frame = DreamStoryFrame(
                    storyId: story.id,
                    dreamId: UUID(),
                    order: j,
                    title: "帧\(j)",
                    content: "内容",
                    duration: 5.0
                )
                modelContext.insert(frame)
                story.frames.append(frame)
            }
            
            modelContext.insert(story)
        }
        try modelContext.save()
        
        let stats = try await service.getStats()
        
        XCTAssertEqual(stats.totalStories, 5)
        XCTAssertEqual(stats.totalFrames, 15)
        XCTAssertEqual(stats.totalViews, 150) // 10+20+30+40+50
        XCTAssertEqual(stats.totalLikes, 75)  // 5+10+15+20+25
        XCTAssertEqual(stats.totalShares, 15) // 1+2+3+4+5
    }
    
    // MARK: - 性能测试
    
    /// 测试批量创建故事的性能
    func testBulkStoryCreationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let story = DreamStory(
                    title: "性能测试故事",
                    description: "测试",
                    theme: .starry,
                    storyType: .chronological
                )
                modelContext.insert(story)
                
                // 添加 5 个帧
                for j in 0..<5 {
                    let frame = DreamStoryFrame(
                        storyId: story.id,
                        dreamId: UUID(),
                        order: j,
                        title: "帧\(j)",
                        content: "内容",
                        duration: 5.0
                    )
                    modelContext.insert(frame)
                    story.frames.append(frame)
                }
            }
            
            try? modelContext.save()
        }
    }
}
