//
//  DreamMorningReflectionTests.swift
//  DreamLogTests
//
//  Phase 79: Morning Reflection Guide - 晨间反思引导
//  单元测试
//

import Testing
import Foundation
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
struct DreamMorningReflectionTests {
    
    // MARK: - 数据模型测试
    
    @Test("反思类型枚举")
    func reflectionTypeCases() async throws {
        let allTypes = MorningReflectionType.allCases
        
        #expect(allTypes.count == 6)
        #expect(allTypes.contains(.gratitude))
        #expect(allTypes.contains(.intention))
        #expect(allTypes.contains(.insight))
        #expect(allTypes.contains(.emotion))
        #expect(allTypes.contains(.action))
        #expect(allTypes.contains(.connection))
    }
    
    @Test("反思类型图标")
    func reflectionTypeIcons() async throws {
        #expect(MorningReflectionType.gratitude.icon == "🙏")
        #expect(MorningReflectionType.intention.icon == "🎯")
        #expect(MorningReflectionType.insight.icon == "💡")
        #expect(MorningReflectionType.emotion.icon == "💖")
        #expect(MorningReflectionType.action.icon == "✨")
        #expect(MorningReflectionType.connection.icon == "🔗")
    }
    
    @Test("反思类型提示")
    func reflectionTypePrompts() async throws {
        #expect(MorningReflectionType.gratitude.prompt.contains("感恩"))
        #expect(MorningReflectionType.intention.prompt.contains("行动"))
        #expect(MorningReflectionType.insight.prompt.contains("揭示"))
        #expect(MorningReflectionType.emotion.prompt.contains("感受"))
        #expect(MorningReflectionType.action.prompt.contains("做"))
        #expect(MorningReflectionType.connection.prompt.contains("关联"))
    }
    
    @Test("反思模型创建")
    func reflectionModelCreation() async throws {
        let reflection = DreamMorningReflection(
            type: .insight,
            content: "这个梦让我意识到我需要更多休息",
            mood: "平静",
            tags: ["觉察", "健康"]
        )
        
        #expect(reflection.id != UUID())
        #expect(reflection.type == .insight)
        #expect(reflection.content == "这个梦让我意识到我需要更多休息")
        #expect(reflection.mood == "平静")
        #expect(reflection.tags.count == 2)
        #expect(reflection.isCompleted == false)
    }
    
    @Test("反思提示模板")
    func reflectionPromptTemplate() async throws {
        let prompt = ReflectionPrompt(
            type: .gratitude,
            question: "测试问题",
            guidance: "测试指导",
            example: "测试示例"
        )
        
        #expect(prompt.id != UUID())
        #expect(prompt.type == .gratitude)
        #expect(prompt.question == "测试问题")
        #expect(prompt.guidance == "测试指导")
        #expect(prompt.example == "测试示例")
        #expect(prompt.isFavorite == false)
    }
    
    @Test("预设提示数量")
    func defaultPromptsCount() async throws {
        #expect(ReflectionPrompt.defaultPrompts.count == 6)
        
        let gratitudePrompt = ReflectionPrompt.defaultPrompts.first { $0.type == .gratitude }
        #expect(gratitudePrompt != nil)
        #expect(gratitudePrompt?.guidance.contains("感恩") == true)
    }
    
    @Test("统计模型")
    func statsModel() async throws {
        let stats = MorningReflectionStats(
            totalReflections: 50,
            completedToday: 3,
            streakDays: 7,
            reflectionsByType: [.insight: 20, .gratitude: 15],
            mostCommonTags: ["觉察", "成长", "感恩"]
        )
        
        #expect(stats.totalReflections == 50)
        #expect(stats.completedToday == 3)
        #expect(stats.streakDays == 7)
        #expect(stats.reflectionsByType[.insight] == 20)
        #expect(stats.mostCommonTags.count == 3)
    }
    
    @Test("配置模型")
    func configModel() async throws {
        let config = MorningReflectionConfig.default
        
        #expect(config.enabled == true)
        #expect(config.reminderTime == "07:00")
        #expect(config.enabledTypes.count == 6)
        #expect(config.showOnWake == true)
        #expect(config.dailyGoal == 3)
    }
    
    // MARK: - 服务测试
    
    @Test("服务初始化")
    func serviceInitialization() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        #expect(service.modelContext === context)
    }
    
    @Test("创建反思")
    func createReflection() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let reflection = try service.createReflection(
            type: .insight,
            content: "测试反思内容",
            mood: "平静",
            tags: ["测试"]
        )
        
        #expect(reflection.content == "测试反思内容")
        #expect(reflection.type == .insight)
        #expect(reflection.mood == "平静")
    }
    
    @Test("获取今日反思")
    func getTodayReflections() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        // 创建今日反思
        _ = try service.createReflection(type: .insight, content: "今日反思 1")
        _ = try service.createReflection(type: .gratitude, content: "今日反思 2")
        
        let todayReflections = try service.getTodayReflections()
        
        #expect(todayReflections.count >= 2)
    }
    
    @Test("更新反思")
    func updateReflection() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let reflection = try service.createReflection(
            type: .insight,
            content: "原始内容"
        )
        
        try service.updateReflection(
            id: reflection.id,
            content: "更新后的内容",
            isCompleted: true
        )
        
        let updated = try service.getAllReflections().first { $0.id == reflection.id }
        #expect(updated?.content == "更新后的内容")
        #expect(updated?.isCompleted == true)
    }
    
    @Test("删除反思")
    func deleteReflection() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let reflection = try service.createReflection(
            type: .insight,
            content: "待删除"
        )
        
        try service.deleteReflection(id: reflection.id)
        
        let all = try service.getAllReflections()
        #expect(!all.contains { $0.id == reflection.id })
    }
    
    @Test("统计功能")
    func statistics() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        // 创建多个反思
        for i in 0..<5 {
            _ = try service.createReflection(
                type: i % 2 == 0 ? .insight : .gratitude,
                content: "反思 \(i)"
            )
        }
        
        let stats = try service.getStatistics()
        
        #expect(stats.totalReflections >= 5)
        #expect(stats.reflectionsByType[.insight] ?? 0 >= 2)
        #expect(stats.reflectionsByType[.gratitude] ?? 0 >= 2)
    }
    
    @Test("导出 Markdown")
    func exportToMarkdown() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let reflection = try service.createReflection(
            type: .insight,
            content: "测试内容",
            mood: "平静",
            tags: ["测试", "觉察"]
        )
        
        let markdown = service.exportReflectionsToMarkdown(reflections: [reflection])
        
        #expect(markdown.contains("# 晨间反思记录"))
        #expect(markdown.contains("💡 洞察"))
        #expect(markdown.contains("测试内容"))
        #expect(markdown.contains("#测试"))
        #expect(markdown.contains("#觉察"))
    }
    
    // MARK: - 边界情况测试
    
    @Test("空数据统计")
    func emptyStats() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let stats = try service.getStatistics()
        
        #expect(stats.totalReflections == 0)
        #expect(stats.streakDays == 0)
        #expect(stats.mostCommonTags.isEmpty)
    }
    
    @Test("删除不存在的反思")
    func deleteNonExistentReflection() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let nonExistentId = UUID()
        
        #expect(throws: MorningReflectionError.self) {
            try service.deleteReflection(id: nonExistentId)
        }
    }
    
    // MARK: - 性能测试
    
    @Test("批量创建性能")
    func bulkCreatePerformance() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        let startTime = Date()
        
        for i in 0..<50 {
            _ = try service.createReflection(
                type: MorningReflectionType.allCases[i % 6],
                content: "反思 \(i)"
            )
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < 1.0) // 50 次创建应在 1 秒内完成
    }
    
    @Test("查询性能")
    func queryPerformance() async throws {
        let container = try ModelContainer(for: DreamMorningReflection.self)
        let context = ModelContext(container)
        let service = DreamMorningReflectionService(modelContext: context)
        
        // 创建测试数据
        for i in 0..<100 {
            _ = try service.createReflection(
                type: .insight,
                content: "反思 \(i)"
            )
        }
        
        let startTime = Date()
        let reflections = try service.getAllReflections(limit: 100)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(reflections.count == 100)
        #expect(duration < 0.5) // 查询应在 0.5 秒内完成
    }
}
