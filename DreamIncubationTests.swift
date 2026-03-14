//
//  DreamIncubationTests.swift
//  DreamLogTests
//
//  梦境孵育功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamIncubationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamIncubationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存中的 ModelContainer
        let schema = Schema([
            DreamIncubationSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        service = DreamIncubationService.shared
        service.setModelContext(modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 孵育类型测试
    
    func testIncubationTypeCases() {
        XCTAssertEqual(IncubationType.allCases.count, 6)
        
        XCTAssertEqual(IncubationType.problemSolving.rawValue, "问题解答")
        XCTAssertEqual(IncubationType.creative.rawValue, "创意启发")
        XCTAssertEqual(IncubationType.healing.rawValue, "情感疗愈")
        XCTAssertEqual(IncubationType.skill.rawValue, "技能练习")
        XCTAssertEqual(IncubationType.exploration.rawValue, "主题探索")
        XCTAssertEqual(IncubationType.lucid.rawValue, "清醒梦诱导")
    }
    
    func testIncubationTypeIcons() {
        XCTAssertEqual(IncubationType.problemSolving.icon, "questionmark.circle.fill")
        XCTAssertEqual(IncubationType.creative.icon, "lightbulb.fill")
        XCTAssertEqual(IncubationType.healing.icon, "heart.fill")
        XCTAssertEqual(IncubationType.skill.icon, "star.fill")
        XCTAssertEqual(IncubationType.exploration.icon, "compass.fill")
        XCTAssertEqual(IncubationType.lucid.icon, "eye.fill")
    }
    
    func testIncubationTypeColors() {
        XCTAssertEqual(IncubationType.problemSolving.color, "FF9500")
        XCTAssertEqual(IncubationType.creative.color, "FFD60A")
        XCTAssertEqual(IncubationType.healing.color, "FF375F")
        XCTAssertEqual(IncubationType.skill.color, "0A84FF")
        XCTAssertEqual(IncubationType.exploration.color, "30D158")
        XCTAssertEqual(IncubationType.lucid.color, "BF5AF2")
    }
    
    func testIncubationTypeAffirmations() {
        for type in IncubationType.allCases {
            XCTAssertFalse(type.suggestedAffirmations.isEmpty)
            XCTAssertTrue(type.suggestedAffirmations.count >= 3)
        }
    }
    
    // MARK: - 孵育强度测试
    
    func testIncubationIntensityCases() {
        XCTAssertEqual(IncubationIntensity.allCases.count, 3)
        
        XCTAssertEqual(IncubationIntensity.light.rawValue, "轻度")
        XCTAssertEqual(IncubationIntensity.moderate.rawValue, "中度")
        XCTAssertEqual(IncubationIntensity.strong.rawValue, "强度")
    }
    
    func testIncubationIntensityDuration() {
        XCTAssertEqual(IncubationIntensity.light.recommendedDuration, 5)
        XCTAssertEqual(IncubationIntensity.moderate.recommendedDuration, 10)
        XCTAssertEqual(IncubationIntensity.strong.recommendedDuration, 15)
    }
    
    // MARK: - 孵育会话模型测试
    
    func testDreamIncubationSessionCreation() {
        let session = DreamIncubationSession(
            type: .creative,
            title: "创意灵感",
            description: "获取项目灵感",
            intention: "我会在梦中获得创意",
            affirmations: ["我的创意源源不断"],
            intensity: .moderate,
            scheduledDate: Date()
        )
        
        XCTAssertEqual(session.type, "创意启发")
        XCTAssertEqual(session.title, "创意灵感")
        XCTAssertEqual(session.intention, "我会在梦中获得创意")
        XCTAssertEqual(session.intensity, "中度")
        XCTAssertEqual(session.status, "pending")
        XCTAssertEqual(session.incubationType, .creative)
        XCTAssertEqual(session.incubationIntensity, .moderate)
        XCTAssertFalse(session.isCompleted)
        XCTAssertFalse(session.isActive)
    }
    
    func testDreamIncubationSessionStatus() {
        let session = DreamIncubationSession(
            type: .creative,
            title: "Test",
            intention: "Test intention"
        )
        
        // 初始状态
        XCTAssertEqual(session.status, "pending")
        XCTAssertFalse(session.isCompleted)
        XCTAssertFalse(session.isActive)
        
        // 激活状态
        session.status = "active"
        XCTAssertTrue(session.isActive)
        XCTAssertFalse(session.isCompleted)
        
        // 完成状态
        session.status = "completed"
        session.completedDate = Date()
        XCTAssertTrue(session.isCompleted)
        XCTAssertFalse(session.isActive)
    }
    
    // MARK: - 模板测试
    
    func testIncubationTemplatesExist() {
        let templates = IncubationTemplate.templates
        XCTAssertEqual(templates.count, 6)
        
        // 每个类型都应该有对应的模板
        for type in IncubationType.allCases {
            let template = templates.first { $0.type == type }
            XCTAssertNotNil(template, "Missing template for \(type.rawValue)")
        }
    }
    
    func testIncubationTemplateProperties() {
        let template = IncubationTemplate.templates.first { $0.type == .problemSolving }!
        
        XCTAssertEqual(template.type, .problemSolving)
        XCTAssertEqual(template.name, "问题解答孵育")
        XCTAssertFalse(template.description.isEmpty)
        XCTAssertFalse(template.defaultIntention.isEmpty)
        XCTAssertFalse(template.suggestedAffirmations.isEmpty)
        XCTAssertFalse(template.preSleepRitual.isEmpty)
        XCTAssertFalse(template.morningReflection.isEmpty)
    }
    
    func testIncubationTemplateRituals() {
        for template in IncubationTemplate.templates {
            // 睡前仪式至少 3 步
            XCTAssertGreaterThanOrEqual(template.preSleepRitual.count, 3)
            
            // 晨间反思至少 3 个问题
            XCTAssertGreaterThanOrEqual(template.morningReflection.count, 3)
        }
    }
    
    // MARK: - 服务测试
    
    func testCreateSession() async throws {
        let initialCount = service.sessions.count
        
        let session = try await service.createSession(
            type: .creative,
            title: "测试孵育",
            intention: "我会在梦中获得创意"
        )
        
        XCTAssertEqual(service.sessions.count, initialCount + 1)
        XCTAssertEqual(session.title, "测试孵育")
        XCTAssertEqual(session.status, "pending")
    }
    
    func testActivateSession() async throws {
        let session = try await service.createSession(
            type: .creative,
            title: "测试孵育",
            intention: "测试"
        )
        
        XCTAssertNil(service.activeSession)
        
        await service.activateSession(session.id)
        
        XCTAssertNotNil(service.activeSession)
        XCTAssertEqual(service.activeSession?.id, session.id)
        XCTAssertEqual(service.activeSession?.status, "active")
    }
    
    func testCompleteSession() async throws {
        let session = try await service.createSession(
            type: .creative,
            title: "测试孵育",
            intention: "测试"
        )
        
        await service.activateSession(session.id)
        await service.completeSession(session.id, successRating: 4, notes: "效果不错")
        
        XCTAssertEqual(service.sessions.first { $0.id == session.id }?.status, "completed")
        XCTAssertEqual(service.sessions.first { $0.id == session.id }?.successRating, 4)
        XCTAssertNil(service.activeSession)
    }
    
    func testCancelSession() async throws {
        let session = try await service.createSession(
            type: .creative,
            title: "测试孵育",
            intention: "测试"
        )
        
        await service.cancelSession(session.id)
        
        XCTAssertEqual(service.sessions.first { $0.id == session.id }?.status, "cancelled")
    }
    
    func testDeleteSession() async throws {
        let session = try await service.createSession(
            type: .creative,
            title: "测试孵育",
            intention: "测试"
        )
        
        let initialCount = service.sessions.count
        await service.deleteSession(session.id)
        
        XCTAssertEqual(service.sessions.count, initialCount - 1)
        XCTAssertNil(service.sessions.first { $0.id == session.id })
    }
    
    // MARK: - 统计测试
    
    func testCalculateStats() async throws {
        // 创建多个会话
        _ = try await service.createSession(type: .creative, title: "会话 1", intention: "测试")
        _ = try await service.createSession(type: .problemSolving, title: "会话 2", intention: "测试")
        _ = try await service.createSession(type: .healing, title: "会话 3", intention: "测试")
        
        // 完成其中一个
        let session2 = service.sessions.first { $0.type == "问题解答" }!
        await service.completeSession(session2.id, successRating: 5)
        
        service.calculateStats()
        
        XCTAssertEqual(service.stats.totalSessions, 3)
        XCTAssertEqual(service.stats.completedSessions, 1)
        XCTAssertEqual(service.stats.pendingSessions, 2)
        XCTAssertEqual(service.stats.averageSuccessRating, 5.0)
    }
    
    func testSuccessRateCalculation() async throws {
        // 创建 4 个会话并完成
        for i in 1...4 {
            let session = try await service.createSession(
                type: .creative,
                title: "会话\(i)",
                intention: "测试"
            )
            await service.completeSession(session.id, successRating: i >= 3 ? 4 : 2)
        }
        
        service.calculateStats()
        
        XCTAssertEqual(service.stats.completedSessions, 4)
        XCTAssertEqual(service.stats.successRate, 0.5) // 2/4 = 50%
    }
    
    func testStreakCalculation() async throws {
        let calendar = Calendar.current
        
        // 创建连续 3 天的会话
        for dayOffset in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let session = try await service.createSession(
                type: .creative,
                title: "会话",
                intention: "测试",
                scheduledDate: date
            )
            await service.completeSession(session.id, successRating: 4)
            service.sessions.first { $0.id == session.id }?.completedDate = date
        }
        
        service.calculateStats()
        
        XCTAssertGreaterThanOrEqual(service.stats.streakDays, 3)
    }
    
    // MARK: - 洞察测试
    
    func testGetInsights() async throws {
        let insights = service.getInsights()
        XCTAssertFalse(insights.isEmpty)
        
        // 创建一些会话后应该有不同洞察
        for _ in 0..<7 {
            let session = try await service.createSession(
                type: .creative,
                title: "测试",
                intention: "测试"
            )
            await service.completeSession(session.id, successRating: 5)
        }
        
        let newInsights = service.getInsights()
        XCTAssertTrue(newInsights.contains { $0.contains("连续") || $0.contains("成功率") })
    }
    
    // MARK: - 提醒配置测试
    
    func testReminderConfigPersistence() {
        var config = IncubationReminder()
        config.isEnabled = true
        config.preSleepMinutes = 45
        config.message = "自定义提醒"
        
        service.reminderConfig = config
        service.saveReminderConfig()
        
        // 重新加载
        service.loadReminderConfig()
        
        XCTAssertTrue(service.reminderConfig.isEnabled)
        XCTAssertEqual(service.reminderConfig.preSleepMinutes, 45)
        XCTAssertEqual(service.reminderConfig.message, "自定义提醒")
    }
    
    // MARK: - 性能测试
    
    func testLoadSessionsPerformance() async throws {
        // 创建大量会话
        for i in 0..<100 {
            _ = try await service.createSession(
                type: IncubationType.allCases[i % 6],
                title: "会话\(i)",
                intention: "测试"
            )
        }
        
        measure {
            let expectation = XCTestExpectation(description: "Load sessions")
            Task {
                await service.loadSessions()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - 错误处理测试
    
    func testCreateSessionWithoutContext() async {
        service.setModelContext(nil)
        
        do {
            _ = try await service.createSession(
                type: .creative,
                title: "测试",
                intention: "测试"
            )
            XCTFail("Should throw error")
        } catch IncubationError.noModelContext {
            // 预期错误
        } catch {
            XCTFail("Wrong error type")
        }
    }
}

// MARK: - 模型扩展测试

final class IncubationTypeTests: XCTestCase {
    
    func testTypeRawValueConversion() {
        for type in IncubationType.allCases {
            let rawValue = type.rawValue
            let converted = IncubationType(rawValue: rawValue)
            XCTAssertEqual(type, converted)
        }
    }
    
    func testIntensityRawValueConversion() {
        for intensity in IncubationIntensity.allCases {
            let rawValue = intensity.rawValue
            let converted = IncubationIntensity(rawValue: rawValue)
            XCTAssertEqual(intensity, converted)
        }
    }
}

// MARK: - 统计数据测试

final class IncubationStatsTests: XCTestCase {
    
    func testStatsInitialization() {
        let stats = IncubationStats()
        
        XCTAssertEqual(stats.totalSessions, 0)
        XCTAssertEqual(stats.completedSessions, 0)
        XCTAssertEqual(stats.pendingSessions, 0)
        XCTAssertEqual(stats.averageSuccessRating, 0)
        XCTAssertEqual(stats.successRate, 0)
        XCTAssertEqual(stats.streakDays, 0)
    }
    
    func testStatsWithValues() {
        let stats = IncubationStats(
            totalSessions: 10,
            completedSessions: 7,
            pendingSessions: 3,
            averageSuccessRating: 4.2,
            sessionsByType: ["创意启发": 5, "问题解答": 5],
            successRate: 0.7,
            streakDays: 5
        )
        
        XCTAssertEqual(stats.totalSessions, 10)
        XCTAssertEqual(stats.completedSessions, 7)
        XCTAssertEqual(stats.pendingSessions, 3)
        XCTAssertEqual(stats.averageSuccessRating, 4.2)
        XCTAssertEqual(stats.successRate, 0.7)
        XCTAssertEqual(stats.streakDays, 5)
    }
}
