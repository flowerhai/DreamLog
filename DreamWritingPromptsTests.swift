//
//  DreamWritingPromptsTests.swift
//  DreamLog - Phase 80: Dream Writing Prompts & Creative Exercises
//
//  Created by DreamLog Team on 2026-03-21.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import SwiftData
@testable import DreamLog

// MARK: - Writing Prompts Tests

@available(iOS 17.0, *)
final class DreamWritingPromptsTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamWritingPromptsService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存存储容器
        let schema = Schema([
            WritingPrompt.self,
            WritingSession.self,
            WritingPreferences.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // 创建服务实例
        service = DreamWritingPromptsService(modelContainer: modelContainer)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Prompt Generation Tests
    
    /// 测试生成写作提示
    func testGeneratePrompts() async throws {
        // 创建测试梦境
        let dream = DreamRecord(
            title: "测试梦境",
            content: "这是一个测试梦境，包含丰富的情感和符号。",
            emotions: [.happy, .anxious],
            tags: ["测试", "梦境", "符号"]
        )
        modelContainer.mainContext.insert(dream)
        try modelContainer.mainContext.save()
        
        // 生成提示
        let prompts = try await service.generatePrompts(for: dream, count: 3)
        
        // 验证
        XCTAssertEqual(prompts.count, 3, "应该生成 3 个提示")
        
        for prompt in prompts {
            XCTAssertNotNil(prompt.title, "提示应该有标题")
            XCTAssertNotNil(prompt.content, "提示应该有内容")
            XCTAssertNotNil(WritingPromptType(rawValue: prompt.type), "提示类型应该有效")
            XCTAssertEqual(prompt.dreamId, dream.id, "提示应该关联到正确的梦境")
        }
    }
    
    /// 测试生成不同类型的提示
    func testGenerateDifferentPromptTypes() async throws {
        let dream = DreamRecord(
            title: "测试梦境",
            content: "测试内容",
            emotions: [.happy],
            tags: ["测试"]
        )
        modelContainer.mainContext.insert(dream)
        try modelContainer.mainContext.save()
        
        let prompts = try await service.generatePrompts(for: dream, count: 5)
        
        // 验证生成了不同类型的提示
        let types = Set(prompts.map { $0.type })
        XCTAssertGreaterThanOrEqual(types.count, 3, "应该生成至少 3 种不同类型的提示")
    }
    
    /// 测试续写提示生成
    func testGenerateContinuationPrompt() async throws {
        let dream = DreamRecord(
            title: "飞行梦",
            content: "我在空中自由飞翔，感受着风的拥抱。",
            emotions: [.happy, .excited],
            tags: ["飞行", "自由"]
        )
        modelContainer.mainContext.insert(dream)
        try modelContainer.mainContext.save()
        
        let prompts = try await service.generatePrompts(for: dream, count: 1)
        let continuationPrompt = prompts.first { $0.type == WritingPromptType.continuation.rawValue }
        
        if let prompt = continuationPrompt {
            XCTAssertContains(prompt.content, "继续", "续写提示应该包含继续相关的内容")
        }
    }
    
    /// 测试情绪提示生成
    func testGenerateEmotionPrompt() async throws {
        let dream = DreamRecord(
            title: "情绪梦",
            content: "我感到非常焦虑和不安。",
            emotions: [.anxious, .sad],
            tags: ["情绪"]
        )
        modelContainer.mainContext.insert(dream)
        try modelContainer.mainContext.save()
        
        let prompts = try await service.generatePrompts(for: dream, count: 3)
        let emotionPrompt = prompts.first { $0.type == WritingPromptType.emotion.rawValue }
        
        if let prompt = emotionPrompt {
            XCTAssertContains(prompt.title, "情绪", "情绪提示标题应该包含情绪相关词汇")
        }
    }
    
    // MARK: - CRUD Tests
    
    /// 测试保存提示
    func testSavePrompt() throws {
        let prompt = WritingPrompt(
            title: "测试提示",
            content: "这是一个测试写作提示",
            type: .creative,
            difficulty: .medium,
            tags: ["测试", "创意"]
        )
        
        try service.savePrompt(prompt)
        
        let savedPrompts = try service.getAllPrompts()
        XCTAssertEqual(savedPrompts.count, 1, "应该保存了 1 个提示")
        XCTAssertEqual(savedPrompts.first?.title, "测试提示")
    }
    
    /// 测试获取特定梦境的提示
    func testGetPromptsForDream() throws {
        let dreamId1 = UUID()
        let dreamId2 = UUID()
        
        let prompt1 = WritingPrompt(
            title: "提示 1",
            content: "内容 1",
            type: .creative,
            dreamId: dreamId1
        )
        
        let prompt2 = WritingPrompt(
            title: "提示 2",
            content: "内容 2",
            type: .continuation,
            dreamId: dreamId1
        )
        
        let prompt3 = WritingPrompt(
            title: "提示 3",
            content: "内容 3",
            type: .reflection,
            dreamId: dreamId2
        )
        
        try service.savePrompt(prompt1)
        try service.savePrompt(prompt2)
        try service.savePrompt(prompt3)
        
        let promptsForDream1 = try service.getPrompts(for: dreamId1)
        XCTAssertEqual(promptsForDream1.count, 2, "梦境 1 应该有 2 个提示")
        
        let promptsForDream2 = try service.getPrompts(for: dreamId2)
        XCTAssertEqual(promptsForDream2.count, 1, "梦境 2 应该有 1 个提示")
    }
    
    /// 测试获取未完成的提示
    func testGetIncompletePrompts() throws {
        let completedPrompt = WritingPrompt(
            title: "已完成提示",
            content: "内容",
            type: .creative,
            isCompleted: true
        )
        
        let incompletePrompt = WritingPrompt(
            title: "未完成提示",
            content: "内容",
            type: .continuation,
            isCompleted: false
        )
        
        try service.savePrompt(completedPrompt)
        try service.savePrompt(incompletePrompt)
        
        let incomplete = try service.getIncompletePrompts()
        XCTAssertEqual(incomplete.count, 1, "应该有 1 个未完成的提示")
        XCTAssertEqual(incomplete.first?.title, "未完成提示")
    }
    
    /// 测试标记提示为完成
    func testCompletePrompt() throws {
        let prompt = WritingPrompt(
            title: "测试提示",
            content: "内容",
            type: .creative,
            isCompleted: false
        )
        
        try service.savePrompt(prompt)
        try service.completePrompt(prompt, wordCount: 500, notes: "测试笔记")
        
        let updatedPrompts = try service.getAllPrompts()
        let updatedPrompt = updatedPrompts.first
        
        XCTAssertNotNil(updatedPrompt)
        XCTAssertTrue(updatedPrompt!.isCompleted, "提示应该标记为已完成")
        XCTAssertEqual(updatedPrompt!.wordCount, 500, "字数应该是 500")
        XCTAssertEqual(updatedPrompt!.userNotes, "测试笔记", "笔记应该保存")
        XCTAssertNotNil(updatedPrompt!.completedAt, "应该有完成时间")
    }
    
    /// 测试删除提示
    func testDeletePrompt() throws {
        let prompt = WritingPrompt(
            title: "要删除的提示",
            content: "内容",
            type: .creative
        )
        
        try service.savePrompt(prompt)
        
        var allPrompts = try service.getAllPrompts()
        XCTAssertEqual(allPrompts.count, 1)
        
        try service.deletePrompt(prompt)
        
        allPrompts = try service.getAllPrompts()
        XCTAssertEqual(allPrompts.count, 0, "提示应该被删除")
    }
    
    // MARK: - Writing Session Tests
    
    /// 测试创建写作会话
    func testCreateSession() throws {
        let promptId = UUID()
        let session = try service.createSession(for: promptId)
        
        XCTAssertEqual(session.promptId, promptId)
        XCTAssertFalse(session.isSaved)
        XCTAssertNil(session.endTime)
    }
    
    /// 测试更新写作会话
    func testUpdateSession() throws {
        let promptId = UUID()
        let session = try service.createSession(for: promptId)
        
        try service.updateSession(session, content: "测试内容", wordCount: 300)
        
        XCTAssertEqual(session.content, "测试内容")
        XCTAssertEqual(session.wordCount, 300)
    }
    
    /// 测试保存写作会话
    func testSaveSession() throws {
        let promptId = UUID()
        let session = try service.createSession(for: promptId)
        
        try service.updateSession(session, content: "测试内容", wordCount: 300)
        try service.saveSession(session, mood: "happy", tags: ["测试", "创意"])
        
        XCTAssertTrue(session.isSaved)
        XCTAssertEqual(session.mood, "happy")
        XCTAssertEqual(session.tags, ["测试", "创意"])
        XCTAssertNotNil(session.endTime)
    }
    
    /// 测试获取会话历史
    func testGetSessionHistory() throws {
        // 创建多个会话
        for i in 0..<5 {
            let session = try service.createSession(for: UUID())
            try service.updateSession(session, content: "内容\(i)", wordCount: 100 * (i + 1))
            try service.saveSession(session)
        }
        
        let history = try service.getSessionHistory(limit: 20)
        XCTAssertEqual(history.count, 5, "应该返回 5 个会话")
        
        // 验证按时间倒序
        if history.count >= 2 {
            XCTAssertGreaterThan(history[0].startTime, history[1].startTime, "应该按时间倒序排列")
        }
    }
    
    // MARK: - Statistics Tests
    
    /// 测试获取统计信息
    func testGetStatistics() throws {
        // 创建一些已完成的提示
        for i in 0..<5 {
            let prompt = WritingPrompt(
                title: "提示\(i)",
                content: "内容",
                type: i % 2 == 0 ? .creative : .continuation,
                isCompleted: true,
                wordCount: 200
            )
            prompt.completedAt = Calendar.current.date(byAdding: .day, value: -i, to: Date())
            try service.savePrompt(prompt)
        }
        
        let stats = try service.getStatistics()
        
        XCTAssertEqual(stats.totalPrompts, 5)
        XCTAssertEqual(stats.completedPrompts, 5)
        XCTAssertEqual(stats.totalWords, 1000)
        XCTAssertGreaterThanOrEqual(stats.streakDays, 1)
    }
    
    /// 测试统计信息计算
    func testStatisticsCalculation() throws {
        let stats = WritingStatistics(
            totalPrompts: 10,
            completedPrompts: 7,
            totalWords: 3500,
            streakDays: 5
        )
        
        XCTAssertEqual(stats.completionRate, 70.0, "完成率应该是 70%")
        XCTAssertEqual(stats.averageWordsPerSession, 0) // 需要会话数据
    }
    
    // MARK: - Preferences Tests
    
    /// 测试保存和获取偏好设置
    func testPreferences() throws {
        let prefs = WritingPreferences(
            dailyGoal: 2,
            weeklyGoal: 10,
            preferredTypes: ["creative", "continuation"],
            reminderEnabled: true,
            reminderTime: "08:00"
        )
        
        try service.savePreferences(prefs)
        
        let retrieved = try service.getPreferences()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.dailyGoal, 2)
        XCTAssertEqual(retrieved?.weeklyGoal, 10)
        XCTAssertEqual(retrieved?.reminderTime, "08:00")
    }
    
    /// 测试更新偏好设置
    func testUpdatePreferences() throws {
        var prefs = WritingPreferences(dailyGoal: 1, weeklyGoal: 3)
        try service.savePreferences(prefs)
        
        prefs.dailyGoal = 3
        prefs.weeklyGoal = 15
        try service.savePreferences(prefs)
        
        let retrieved = try service.getPreferences()
        XCTAssertEqual(retrieved?.dailyGoal, 3)
        XCTAssertEqual(retrieved?.weeklyGoal, 15)
    }
    
    // MARK: - Achievements Tests
    
    /// 测试成就检查
    func testCheckAchievements() throws {
        // 创建一些已完成的提示
        for i in 0..<10 {
            let prompt = WritingPrompt(
                title: "提示\(i)",
                content: "内容",
                type: WritingPromptType.allCases[i % WritingPromptType.allCases.count],
                isCompleted: true,
                wordCount: 500
            )
            try service.savePrompt(prompt)
        }
        
        let achievements = try service.checkAchievements()
        
        XCTAssertGreaterThan(achievements.count, 0)
        
        // 检查"初次尝试"成就
        let firstTryAchievement = achievements.first { $0.name == "初次尝试" }
        XCTAssertNotNil(firstTryAchievement)
        XCTAssertEqual(firstTryAchievement?.progress, 10)
        XCTAssertTrue(firstTryAchievement?.isUnlocked ?? false)
    }
    
    /// 测试成就进度计算
    func testAchievementProgress() throws {
        let achievement = WritingAchievement(
            name: "测试成就",
            description: "测试",
            iconName: "star",
            requirement: 10,
            progress: 5
        )
        
        XCTAssertEqual(achievement.progress, 5)
        XCTAssertFalse(achievement.isUnlocked)
    }
    
    // MARK: - Daily Prompt Tests
    
    /// 测试生成每日提示
    func testGenerateDailyPrompt() async throws {
        let dailyPrompt = try await service.generateDailyPrompt()
        
        XCTAssertNotNil(dailyPrompt)
        XCTAssertTrue(dailyPrompt!.tags.contains("每日"))
        XCTAssertTrue(dailyPrompt!.tags.contains("推荐"))
    }
    
    /// 测试每日提示不重复生成
    func testDailyPromptNotRegenerated() async throws {
        // 生成第一个每日提示
        let firstPrompt = try await service.generateDailyPrompt()
        XCTAssertNotNil(firstPrompt)
        
        // 再次生成，应该返回同一个
        let secondPrompt = try await service.generateDailyPrompt()
        XCTAssertEqual(firstPrompt?.id, secondPrompt?.id, "同一天应该返回同一个提示")
    }
    
    // MARK: - Writing Prompt Type Tests
    
    /// 测试提示类型枚举
    func testWritingPromptTypeCases() {
        XCTAssertEqual(WritingPromptType.allCases.count, 10)
        
        let continuation = WritingPromptType.continuation
        XCTAssertEqual(continuation.displayName, "续写梦境")
        XCTAssertEqual(continuation.iconName, "arrow.right.circle")
        XCTAssertEqual(continuation.difficulty, .easy)
    }
    
    /// 测试难度等级
    func testPromptDifficulty() {
        XCTAssertEqual(PromptDifficulty.easy.estimatedMinutes, 5)
        XCTAssertEqual(PromptDifficulty.medium.estimatedMinutes, 10)
        XCTAssertEqual(PromptDifficulty.hard.estimatedMinutes, 20)
        
        XCTAssertEqual(PromptDifficulty.easy.displayName, "简单")
        XCTAssertEqual(PromptDifficulty.medium.displayName, "中等")
        XCTAssertEqual(PromptDifficulty.hard.displayName, "困难")
    }
    
    // MARK: - Writing Exercise Template Tests
    
    /// 测试写作练习模板
    func testWritingExerciseTemplate() {
        let template = WritingExerciseTemplate(
            name: "测试模板",
            description: "测试描述",
            type: .creative,
            instructions: ["步骤 1", "步骤 2"],
            examplePrompt: "示例提示",
            tips: ["提示 1", "提示 2"],
            estimatedTime: 15
        )
        
        XCTAssertEqual(template.name, "测试模板")
        XCTAssertEqual(template.instructions.count, 2)
        XCTAssertEqual(template.estimatedTime, 15)
    }
    
    // MARK: - Performance Tests
    
    /// 测试批量创建提示的性能
    func testBulkPromptCreation() throws {
        let startTime = Date()
        
        for i in 0..<50 {
            let prompt = WritingPrompt(
                title: "提示\(i)",
                content: "内容\(i)",
                type: .creative,
                difficulty: .medium
            )
            try service.savePrompt(prompt)
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsed, 5.0, "批量创建 50 个提示应该在 5 秒内完成")
        
        let allPrompts = try service.getAllPrompts()
        XCTAssertEqual(allPrompts.count, 50)
    }
    
    // MARK: - Edge Cases
    
    /// 测试空内容提示
    func testEmptyContentPrompt() throws {
        let prompt = WritingPrompt(
            title: "空内容提示",
            content: "",
            type: .creative
        )
        
        try service.savePrompt(prompt)
        let saved = try service.getAllPrompts()
        XCTAssertEqual(saved.count, 1)
    }
    
    /// 测试特殊字符标题
    func testSpecialCharactersInTitle() throws {
        let prompt = WritingPrompt(
            title: "特殊字符测试！@#$%^&*()",
            content: "内容",
            type: .creative
        )
        
        try service.savePrompt(prompt)
        let saved = try service.getAllPrompts()
        XCTAssertEqual(saved.first?.title, "特殊字符测试！@#$%^&*()")
    }
    
    /// 测试长内容提示
    func testLongContentPrompt() throws {
        let longContent = String(repeating: "这是一个很长的内容。", count: 100)
        
        let prompt = WritingPrompt(
            title: "长内容提示",
            content: longContent,
            type: .creative
        )
        
        try service.savePrompt(prompt)
        let saved = try service.getAllPrompts()
        XCTAssertEqual(saved.first?.content.count, longContent.count)
    }
    
    // MARK: - Helper Methods
    
    private func XCTAssertContains(_ string: String, _ substring: String, _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(string.localizedCaseInsensitiveContains(substring), "\(message) - 期望包含: \(substring), 实际：\(string)", file: file, line: line)
    }
}

// MARK: - Writing Prompts Performance Tests

@available(iOS 17.0, *)
extension DreamWritingPromptsTests {
    
    /// 性能测试：生成提示
    func testPerformancePromptGeneration() async throws {
        let dream = DreamRecord(
            title: "性能测试梦境",
            content: String(repeating: "测试内容。", count: 50),
            emotions: [.happy, .excited, .anxious],
            tags: ["测试", "性能", "梦境"]
        )
        modelContainer.mainContext.insert(dream)
        try modelContainer.mainContext.save()
        
        measure {
            let expectation = self.expectation(description: "Generate prompts")
            Task {
                _ = try? await service.generatePrompts(for: dream, count: 5)
                expectation.fulfill()
            }
            waitForExpectations(timeout: 10)
        }
    }
    
    /// 性能测试：获取统计信息
    func testPerformanceGetStatistics() throws {
        // 准备数据
        for i in 0..<100 {
            let prompt = WritingPrompt(
                title: "提示\(i)",
                content: "内容",
                type: .creative,
                isCompleted: true,
                wordCount: 200
            )
            try service.savePrompt(prompt)
        }
        
        measure {
            _ = try? service.getStatistics()
        }
    }
}
