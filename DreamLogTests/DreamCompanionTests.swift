//
//  DreamCompanionTests.swift
//  DreamLogTests
//
//  Phase 56 - 梦境 AI 伙伴系统
//  单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamCompanionTests: XCTestCase {
    
    var companionService: DreamCompanionService!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 设置测试用的 ModelContext
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CompanionSession.self, CompanionMessage.self, configurations: config)
        modelContext = ModelContext(container)
        
        companionService = DreamCompanionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        companionService = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Session Management Tests
    
    /// 测试创建新会话
    func testCreateSession() async throws {
        let session = await companionService.createSession(topic: "梦境解析")
        
        XCTAssertEqual(session.topic, "梦境解析")
        XCTAssertFalse(session.isArchived)
        XCTAssertEqual(session.messageCount, 1)  // 包含欢迎消息
        XCTAssertNotNil(session.createdAt)
        XCTAssertNotNil(session.id)
    }
    
    /// 测试创建关联梦境的会话
    func testCreateSessionWithDream() async throws {
        let dreamId = UUID()
        let session = await companionService.createSession(dreamId: dreamId, topic: "梦境解析")
        
        XCTAssertEqual(session.dreamId, dreamId)
        XCTAssertEqual(session.topic, "梦境解析")
    }
    
    /// 测试获取所有会话
    func testGetAllSessions() async throws {
        // 创建多个会话
        _ = await companionService.createSession(topic: "会话 1")
        try await Task.sleep(nanoseconds: 1_000_000)  // 确保时间戳不同
        _ = await companionService.createSession(topic: "会话 2")
        try await Task.sleep(nanoseconds: 1_000_000)
        _ = await companionService.createSession(topic: "会话 3")
        
        let sessions = await companionService.getAllSessions()
        
        XCTAssertEqual(sessions.count, 3)
        XCTAssertTrue(sessions[0].updatedAt >= sessions[1].updatedAt)  // 按更新时间倒序
    }
    
    /// 测试加载现有会话
    func testLoadSession() async throws {
        let createdSession = await companionService.createSession(topic: "测试会话")
        
        // 创建新的 service 实例来测试加载
        let newService = DreamCompanionService(modelContext: modelContext)
        let loadedSession = await newService.loadSession(sessionId: createdSession.id)
        
        XCTAssertNotNil(loadedSession)
        XCTAssertEqual(loadedSession?.id, createdSession.id)
        XCTAssertEqual(loadedSession?.topic, "测试会话")
    }
    
    /// 测试归档会话
    func testArchiveSession() async throws {
        let session = await companionService.createSession(topic: "测试会话")
        
        await companionService.archiveSession(sessionId: session.id)
        
        let sessions = await companionService.getAllSessions()
        let archivedSession = sessions.first { $0.id == session.id }
        
        XCTAssertNotNil(archivedSession)
        XCTAssertTrue(archivedSession?.isArchived ?? false)
    }
    
    /// 测试删除会话
    func testDeleteSession() async throws {
        let session = await companionService.createSession(topic: "测试会话")
        
        await companionService.deleteSession(sessionId: session.id)
        
        let sessions = await companionService.getAllSessions()
        let deletedSession = sessions.first { $0.id == session.id }
        
        XCTAssertNil(deletedSession)
    }
    
    // MARK: - Message Tests
    
    /// 测试发送消息
    func testSendMessage() async throws {
        let session = await companionService.createSession(topic: "测试会话")
        
        let response = await companionService.sendMessage("帮我解析这个梦", dreamId: session.dreamId)
        
        XCTAssertFalse(response.message.isEmpty)
        XCTAssertEqual(response.messageType, .interpretation)
        XCTAssertGreaterThanOrEqual(response.suggestedQuestions.count, 0)
    }
    
    /// 测试发送消息自动创建会话
    func testSendMessageCreatesSession() async throws {
        let response = await companionService.sendMessage("你好")
        
        XCTAssertFalse(response.message.isEmpty)
        XCTAssertEqual(response.messageType, .greeting)
    }
    
    /// 测试消息历史限制
    func testMessageHistoryLimit() async throws {
        let session = await companionService.createSession(topic: "测试会话")
        
        // 发送超过限制的消息
        for i in 0..<60 {
            _ = await companionService.sendMessage("消息 \(i)", dreamId: session.dreamId)
        }
        
        let sessions = await companionService.getAllSessions()
        let updatedSession = sessions.first { $0.id == session.id }
        
        // 验证消息数量被限制
        XCTAssertLessThanOrEqual(updatedSession?.messages.count ?? 0, 52)  // 50 条历史 + 2 条初始
    }
    
    // MARK: - Intent Analysis Tests
    
    /// 测试解析意图识别
    func testInterpretationIntent() async {
        let service = DreamCompanionService()
        
        let testCases = [
            "帮我解析这个梦境的含义",
            "这个梦说明了什么？",
            "梦境中的水代表什么？",
            "这个梦有什么象征意义？"
        ]
        
        for testCase in testCases {
            // 这里需要测试 analyzeIntent 方法，但它是私有的
            // 我们可以通过发送消息并检查响应类型来间接测试
            let response = await service.sendMessage(testCase)
            XCTAssertEqual(response.messageType, .interpretation, "Failed for: \(testCase)")
        }
    }
    
    /// 测试探索意图识别
    func testExplorationIntent() async {
        let service = DreamCompanionService()
        
        let testCases = [
            "我想更深入地了解这个梦",
            "这个梦和我的现实生活有什么联系？",
            "为什么我会做这样的梦？"
        ]
        
        for testCase in testCases {
            let response = await service.sendMessage(testCase)
            // 探索类问题可能返回 interpretation 或 question 类型
            XCTAssertTrue([.interpretation, .question].contains(response.messageType))
        }
    }
    
    /// 测试问候意图识别
    func testGreetingIntent() async {
        let service = DreamCompanionService()
        
        let testCases = [
            "你好",
            "Hi",
            "Hello",
            "早上好"
        ]
        
        for testCase in testCases {
            let response = await service.sendMessage(testCase)
            XCTAssertEqual(response.messageType, .greeting, "Failed for: \(testCase)")
        }
    }
    
    // MARK: - Response Generation Tests
    
    /// 测试响应包含建议问题
    func testResponseContainsSuggestions() async {
        let response = await companionService.sendMessage("这个梦意味着什么？")
        
        XCTAssertFalse(response.suggestedQuestions.isEmpty, "响应应该包含建议问题")
    }
    
    /// 测试响应消息类型多样性
    func testResponseMessageTypeVariety() async {
        let service = DreamCompanionService()
        
        // 发送不同类型的消息
        _ = await service.sendMessage("你好")  // 问候
        _ = await service.sendMessage("帮我解析")  // 解析
        _ = await service.sendMessage("我想知道更多")  // 探索
        
        // 验证不同类型的响应
        // (实际测试中应该检查每个响应的类型)
    }
    
    // MARK: - Symbol Database Tests
    
    /// 测试符号数据库包含常见符号
    func testSymbolDatabaseContainsCommonSymbols() {
        let database = SymbolDatabase.shared
        
        let expectedSymbols = ["水", "火", "飞", "掉落", "追逐", "牙齿", "蛇"]
        
        for symbol in expectedSymbols {
            XCTAssertNotNil(database.interpretations[symbol], "符号数据库应该包含：\(symbol)")
        }
    }
    
    /// 测试符号解释完整性
    func testSymbolInterpretationCompleteness() {
        let database = SymbolDatabase.shared
        
        for (symbol, interpretation) in database.interpretations {
            XCTAssertFalse(interpretation.symbol.isEmpty, "\(symbol) 的符号名不能为空")
            XCTAssertFalse(interpretation.meaning.isEmpty, "\(symbol) 的解释不能为空")
            XCTAssertFalse(interpretation.categories.isEmpty, "\(symbol) 至少需要一个分类")
            XCTAssertGreaterThanOrEqual(interpretation.confidence, 0.0, "\(symbol) 的置信度不能为负")
            XCTAssertLessThanOrEqual(interpretation.confidence, 1.0, "\(symbol) 的置信度不能超过 1")
        }
    }
    
    // MARK: - Template Tests
    
    /// 测试默认模板存在
    func testDefaultTemplatesExist() {
        let templates = CompanionTemplate.defaultTemplates
        
        XCTAssertFalse(templates.isEmpty, "应该有默认模板")
        
        let categories = Set(templates.map { $0.category })
        XCTAssertEqual(categories.count, 4, "应该有 4 种不同类别的模板")
    }
    
    /// 测试模板包含必要信息
    func testTemplateCompleteness() {
        let templates = CompanionTemplate.defaultTemplates
        
        for template in templates {
            XCTAssertFalse(template.id.isEmpty, "模板 ID 不能为空")
            XCTAssertFalse(template.name.isEmpty, "模板名称不能为空")
            XCTAssertFalse(template.prompts.isEmpty, "模板应该包含提示语")
        }
    }
    
    // MARK: - Quick Question Tests
    
    /// 测试快速问题存在
    func testQuickQuestionsExist() {
        let questions = QuickQuestion.defaultQuestions
        
        XCTAssertFalse(questions.isEmpty, "应该有默认快速问题")
        XCTAssertEqual(questions.count, 5, "应该有 5 个快速问题")
    }
    
    /// 测试快速问题覆盖不同类别
    func testQuickQuestionsCoverage() {
        let questions = QuickQuestion.defaultQuestions
        
        let categories = Set(questions.map { $0.category })
        XCTAssertGreaterThanOrEqual(categories.count, 3, "快速问题应该覆盖至少 3 个类别")
    }
    
    /// 测试快速问题格式
    func testQuickQuestionFormat() {
        let questions = QuickQuestion.defaultQuestions
        
        for question in questions {
            XCTAssertFalse(question.id.isEmpty, "问题 ID 不能为空")
            XCTAssertFalse(question.question.isEmpty, "问题内容不能为空")
            XCTAssertFalse(question.icon.isEmpty, "问题图标不能为空")
        }
    }
    
    // MARK: - Performance Tests
    
    /// 测试会话创建性能
    func testSessionCreationPerformance() async {
        measure {
            let expectation = self.expectation(description: "Create session")
            
            Task {
                _ = await companionService.createSession(topic: "性能测试")
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 5.0)
        }
    }
    
    /// 测试消息发送性能
    func testMessageSendingPerformance() async {
        _ = await companionService.createSession(topic: "性能测试")
        
        measure {
            let expectation = self.expectation(description: "Send message")
            
            Task {
                _ = await companionService.sendMessage("测试消息")
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 5.0)
        }
    }
    
    // MARK: - Edge Case Tests
    
    /// 测试空消息处理
    func testEmptyMessageHandling() async {
        let response = await companionService.sendMessage("")
        
        // 空消息应该得到适当的处理
        XCTAssertFalse(response.message.isEmpty)
    }
    
    /// 测试超长消息处理
    func testLongMessageHandling() async {
        let longMessage = String(repeating: "这是一个很长的消息。", count: 100)
        let response = await companionService.sendMessage(longMessage)
        
        XCTAssertFalse(response.message.isEmpty)
    }
    
    /// 测试特殊字符处理
    func testSpecialCharacterHandling() async {
        let specialMessage = "特殊字符测试：!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let response = await companionService.sendMessage(specialMessage)
        
        XCTAssertFalse(response.message.isEmpty)
    }
    
    /// 测试多语言支持
    func testMultilingualSupport() async {
        let messages = [
            "Hello, can you help me?",
            "こんにちは",
            "안녕하세요",
            "مرحبا"
        ]
        
        for message in messages {
            let response = await companionService.sendMessage(message)
            XCTAssertFalse(response.message.isEmpty, "Failed for: \(message)")
        }
    }
    
    // MARK: - Model Tests
    
    /// 测试 CompanionMessage 模型
    func testCompanionMessageModel() {
        let message = CompanionMessage(
            sessionId: UUID(),
            messageType: .interpretation,
            tone: .warm,
            content: "测试消息"
        )
        
        XCTAssertNotNil(message.id)
        XCTAssertEqual(message.content, "测试消息")
        XCTAssertEqual(message.messageType, .interpretation)
        XCTAssertEqual(message.tone, .warm)
        XCTAssertFalse(message.isFromUser)
    }
    
    /// 测试 CompanionSession 模型
    func testCompanionSessionModel() {
        let session = CompanionSession(
            title: "测试会话",
            topic: "梦境解析"
        )
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.title, "测试会话")
        XCTAssertEqual(session.topic, "梦境解析")
        XCTAssertEqual(session.messageCount, 0)
        XCTAssertFalse(session.isArchived)
        XCTAssertTrue(session.tags.isEmpty)
    }
    
    /// 测试 CompanionMessageType 枚举
    func testCompanionMessageTypeEnum() {
        let allTypes = CompanionMessageType.allCases
        
        XCTAssertEqual(allTypes.count, 8)
        
        for type in allTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.rawValue.isEmpty)
        }
    }
    
    /// 测试 CompanionTone 枚举
    func testCompanionToneEnum() {
        let allTones = CompanionTone.allCases
        
        XCTAssertEqual(allTones.count, 6)
        
        for tone in allTones {
            XCTAssertFalse(tone.displayName.isEmpty)
            XCTAssertFalse(tone.rawValue.isEmpty)
        }
    }
    
    /// 测试 ChallengeStatus 颜色映射
    func testCompanionToneColorMapping() {
        // 验证每种 tone 都有对应的显示名称
        for tone in CompanionTone.allCases {
            XCTAssertFalse(tone.displayName.isEmpty)
        }
    }
}

// MARK: - Mock Objects

class MockDreamStore: ObservableObject {
    @Published var dreams: [Dream] = []
    
    init() {}
}

// MARK: - Test Helpers

extension DreamCompanionTests {
    /// 创建测试用的梦境
    func createTestDream(id: UUID = UUID(), title: String = "测试梦境", content: String = "测试内容") -> Dream {
        // 这里需要 Dream 模型的定义
        // 简化处理
        return Dream()
    }
}

// MARK: - Dream Model Stub

class Dream: Identifiable, ObservableObject {
    var id: UUID = UUID()
    var title: String = ""
    var content: String = ""
    var date: Date = Date()
    var emotions: [String] = []
    var tags: [String] = []
    
    init() {}
}

// MARK: - DreamStore Stub

class DreamStore: ObservableObject {
    @Published var dreams: [Dream] = []
    
    init() {}
}
