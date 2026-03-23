//
//  DreamARSocialTests.swift
//  DreamLogTests
//
//  Created for Phase 40 - AR 社交功能
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import Foundation
import SwiftUI
import SwiftData
@testable import DreamLog

// MARK: - AR 会话模型测试

final class ARSessionModelTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ARSession.self, ARParticipant.self, ARElement.self, ARMessage.self, configurations: config)
        modelContext = ModelContext(container)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - ARSession 初始化测试
    
    func testARSessionInitialization() {
        let session = ARSession(
            sessionCode: "ABC123",
            hostUserID: UUID(),
            hostDisplayName: "测试用户",
            sceneTemplate: .starryNight,
            maxParticipants: 8,
            isPublic: false,
            durationMinutes: 60
        )
        
        XCTAssertEqual(session.sessionCode, "ABC123")
        XCTAssertEqual(session.hostDisplayName, "测试用户")
        XCTAssertEqual(session.sceneTemplate, .starryNight)
        XCTAssertEqual(session.maxParticipants, 8)
        XCTAssertFalse(session.isPublic)
        XCTAssertTrue(session.isActive)
        XCTAssertEqual(session.participantCount, 1)
    }
    
    func testARSessionWithCustomDuration() {
        let session = ARSession(
            sessionCode: "XYZ789",
            hostUserID: UUID(),
            hostDisplayName: "主持人",
            durationMinutes: 120
        )
        
        let expectedExpiry = Date().addingTimeInterval(120 * 60)
        XCTAssertGreaterThan(session.expiresAt, expectedExpiry.addingTimeInterval(-10))
        XCTAssertLessThan(session.expiresAt, expectedExpiry.addingTimeInterval(10))
    }
    
    // MARK: - ARSession 有效性测试
    
    func testSessionValidity() {
        let session = ARSession(
            sessionCode: "TEST01",
            hostUserID: UUID(),
            hostDisplayName: "Host"
        )
        
        XCTAssertTrue(session.isValid)
    }
    
    func testSessionExpired() {
        let session = ARSession(
            sessionCode: "TEST02",
            hostUserID: UUID(),
            hostDisplayName: "Host",
            durationMinutes: -1 // 已过期的会话
        )
        
        XCTAssertFalse(session.isValid)
    }
    
    func testSessionFull() {
        let session = ARSession(
            sessionCode: "TEST03",
            hostUserID: UUID(),
            hostDisplayName: "Host",
            maxParticipants: 2
        )
        
        session.participantCount = 2
        
        XCTAssertFalse(session.isValid)
    }
    
    func testSessionCanJoin() {
        let hostID = UUID()
        let user1ID = UUID()
        let user2ID = UUID()
        
        let session = ARSession(
            sessionCode: "TEST04",
            hostUserID: hostID,
            hostDisplayName: "Host",
            maxParticipants: 3
        )
        
        // 主持人不能再次加入
        XCTAssertFalse(session.canJoin(for: hostID))
        
        // 新用户可以加入
        XCTAssertTrue(session.canJoin(for: user1ID))
        
        // 添加参与者
        let participant = ARParticipant(
            sessionID: session.id,
            userID: user1ID,
            displayName: "用户 1"
        )
        session.participants.append(participant)
        session.participantCount = 2
        
        // 用户 1 不能再次加入
        XCTAssertFalse(session.canJoin(for: user1ID))
        
        // 用户 2 可以加入
        XCTAssertTrue(session.canJoin(for: user2ID))
    }
    
    // MARK: - ARSceneTemplate 测试
    
    func testSceneTemplateCount() {
        XCTAssertEqual(ARSceneTemplate.allCases.count, 8)
    }
    
    func testSceneTemplateDisplayNames() {
        let templates: [(ARSceneTemplate, String)] = [
            (.starryNight, "星空梦境"),
            (.oceanWorld, "海洋世界"),
            (.mountainPeak, "雪山奇境"),
            (.forestMyst, "迷雾森林"),
            (.crystalCave, "水晶洞穴"),
            (.skyGarden, "天空花园"),
            (.desertOasis, "沙漠绿洲"),
            (.auroraField, "极光原野")
        ]
        
        for (template, expectedName) in templates {
            XCTAssertEqual(template.displayName, expectedName)
        }
    }
    
    func testSceneTemplateIcons() {
        let templates: [(ARSceneTemplate, String)] = [
            (.starryNight, "star.fill"),
            (.oceanWorld, "water.waves"),
            (.mountainPeak, "mountain.fill"),
            (.forestMyst, "tree.fill"),
            (.crystalCave, "gemstone.fill"),
            (.skyGarden, "flower.open"),
            (.desertOasis, "sun.max.fill"),
            (.auroraField, "cloud.bolt.fill")
        ]
        
        for (template, expectedIcon) in templates {
            XCTAssertEqual(template.icon, expectedIcon)
        }
    }
    
    func testSceneTemplateRawValues() {
        for template in ARSceneTemplate.allCases {
            XCTAssertEqual(template.rawValue, template.id)
        }
    }
    
    // MARK: - ARParticipant 测试
    
    func testARParticipantInitialization() {
        let sessionID = UUID()
        let userID = UUID()
        
        let participant = ARParticipant(
            sessionID: sessionID,
            userID: userID,
            displayName: "测试参与者"
        )
        
        XCTAssertEqual(participant.sessionID, sessionID)
        XCTAssertEqual(participant.userID, userID)
        XCTAssertEqual(participant.displayName, "测试参与者")
        XCTAssertEqual(participant.role, .participant)
        XCTAssertTrue(participant.isActive)
        XCTAssertNotNil(participant.joinedAt)
    }
    
    func testARParticipantHostRole() {
        let participant = ARParticipant(
            sessionID: UUID(),
            userID: UUID(),
            displayName: "主持人",
            role: .host
        )
        
        XCTAssertEqual(participant.role, .host)
        XCTAssertTrue(participant.canModerate)
    }
    
    func testARParticipantModeratorPrivileges() {
        let host = ARParticipant(
            sessionID: UUID(),
            userID: UUID(),
            displayName: "Host",
            role: .host
        )
        
        let participant = ARParticipant(
            sessionID: UUID(),
            userID: UUID(),
            displayName: "User"
        )
        
        XCTAssertTrue(host.canModerate)
        XCTAssertFalse(participant.canModerate)
    }
    
    // MARK: - ARElement 测试
    
    func testARElementInitialization() {
        let element = ARElement(
            sessionID: UUID(),
            creatorID: UUID(),
            elementType: .crystal,
            position: SIMD3<Float>(0, 0, 0)
        )
        
        XCTAssertEqual(element.elementType, .crystal)
        XCTAssertEqual(element.position, SIMD3<Float>(0, 0, 0))
        XCTAssertEqual(element.scale, SIMD3<Float>(1, 1, 1))
        XCTAssertEqual(element.colorHex, "#FFFFFF")
        XCTAssertTrue(element.isVisible)
    }
    
    func testARElementWithCustomProperties() {
        let element = ARElement(
            sessionID: UUID(),
            creatorID: UUID(),
            elementType: .light,
            position: SIMD3<Float>(10, 20, 30),
            rotation: SIMD4<Float>(0, 1, 0, 0),
            scale: SIMD3<Float>(2, 2, 2),
            colorHex: "#FF5733"
        )
        
        XCTAssertEqual(element.position, SIMD3<Float>(10, 20, 30))
        XCTAssertEqual(element.scale, SIMD3<Float>(2, 2, 2))
        XCTAssertEqual(element.colorHex, "#FF5733")
    }
    
    func testARElementTypeCount() {
        XCTAssertEqual(ARElementType.allCases.count, 10)
    }
    
    func testARElementTypeDisplayNames() {
        let types: [(ARElementType, String)] = [
            (.crystal, "水晶"),
            (.light, "光点"),
            (.water, "水元素"),
            (.fire, "火焰"),
            (.earth, "岩石"),
            (.wind, "风"),
            (.butterfly, "蝴蝶"),
            (.flower, "花朵"),
            (.orb, "能量球"),
            (.custom, "自定义")
        ]
        
        for (type, expectedName) in types {
            XCTAssertEqual(type.displayName, expectedName)
        }
    }
    
    // MARK: - ARMessage 测试
    
    func testARMessageInitialization() {
        let message = ARMessage(
            sessionID: UUID(),
            senderID: UUID(),
            senderDisplayName: "发送者",
            messageType: .text,
            content: "Hello, World!"
        )
        
        XCTAssertEqual(message.messageType, .text)
        XCTAssertEqual(message.content, "Hello, World!")
        XCTAssertFalse(message.isSystemMessage)
        XCTAssertNil(message.position)
    }
    
    func testARMessageWithPosition() {
        let position = SIMD3<Float>(5, 10, 15)
        let message = ARMessage(
            sessionID: UUID(),
            senderID: UUID(),
            senderDisplayName: "Sender",
            messageType: .text,
            content: "Spatial message",
            position: position
        )
        
        XCTAssertEqual(message.position, position)
    }
    
    func testARMessageMessageTypeCount() {
        XCTAssertEqual(ARMessageType.allCases.count, 4)
    }
    
    func testARMessageIsSystemMessage() {
        let userMessage = ARMessage(
            sessionID: UUID(),
            senderID: UUID(),
            senderDisplayName: "User",
            messageType: .text,
            content: "Hello"
        )
        
        let systemMessage = ARMessage(
            sessionID: UUID(),
            senderID: UUID(),
            senderDisplayName: "System",
            messageType: .system,
            content: "User joined"
        )
        
        XCTAssertFalse(userMessage.isSystemMessage)
        XCTAssertTrue(systemMessage.isSystemMessage)
    }
    
    // MARK: - ARSessionState 测试
    
    func testARSessionStateDefault() {
        let state = ARSessionState()
        
        XCTAssertEqual(state.status, .disconnected)
        XCTAssertNil(state.currentSession)
        XCTAssertEqual(state.participants.count, 0)
        XCTAssertEqual(state.elements.count, 0)
        XCTAssertTrue(state.availableTemplates.isEmpty)
    }
    
    func testARSessionStateReset() {
        var state = ARSessionState()
        state.status = .connected
        state.currentSession = ARSession(
            sessionCode: "TEST",
            hostUserID: UUID(),
            hostDisplayName: "Host"
        )
        
        state.reset()
        
        XCTAssertEqual(state.status, .disconnected)
        XCTAssertNil(state.currentSession)
    }
}

// MARK: - AR 会话服务测试

final class ARSessionServiceTests: XCTestCase {
    
    var service: ARSessionService!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ARSession.self, configurations: config)
        modelContext = ModelContext(container)
        service = ARSessionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 会话创建测试
    
    func testCreateSession() async throws {
        let session = try await service.createSession(
            sceneTemplate: .starryNight,
            maxParticipants: 8,
            isPublic: false
        )
        
        XCTAssertNotNil(session)
        XCTAssertEqual(session.sessionCode.count, 6)
        XCTAssertEqual(session.sceneTemplate, .starryNight)
        XCTAssertEqual(session.maxParticipants, 8)
        XCTAssertFalse(session.isPublic)
    }
    
    func testCreateSessionWithCustomDuration() async throws {
        let session = try await service.createSession(
            sceneTemplate: .oceanWorld,
            durationMinutes: 120
        )
        
        let expectedExpiry = Date().addingTimeInterval(120 * 60)
        XCTAssertGreaterThan(session.expiresAt, expectedExpiry.addingTimeInterval(-10))
    }
    
    // MARK: - 会话码生成测试
    
    func testSessionCodeFormat() async throws {
        let session = try await service.createSession(sceneTemplate: .starryNight)
        
        XCTAssertEqual(session.sessionCode.count, 6)
        XCTAssertTrue(session.sessionCode.allSatisfy { char in
            char.isLetter || char.isNumber
        })
    }
    
    func testSessionCodeUniqueness() async throws {
        let session1 = try await service.createSession(sceneTemplate: .starryNight)
        let session2 = try await service.createSession(sceneTemplate: .oceanWorld)
        
        XCTAssertNotEqual(session1.sessionCode, session2.sessionCode)
    }
    
    // MARK: - 会话查询测试
    
    func testGetSessionByCode() async throws {
        let createdSession = try await service.createSession(
            sceneTemplate: .forestMyst
        )
        
        let fetchedSession = try await service.getSession(byCode: createdSession.sessionCode)
        
        XCTAssertNotNil(fetchedSession)
        XCTAssertEqual(fetchedSession?.id, createdSession.id)
    }
    
    func testGetNonExistentSession() async throws {
        let session = try await service.getSession(byCode: "INVALID")
        
        XCTAssertNil(session)
    }
    
    // MARK: - 会话加入测试
    
    func testJoinSession() async throws {
        let session = try await service.createSession(
            sceneTemplate: .crystalCave,
            maxParticipants: 4
        )
        
        let participant = try await service.joinSession(
            sessionCode: session.sessionCode,
            userID: UUID(),
            displayName: "新参与者"
        )
        
        XCTAssertNotNil(participant)
        XCTAssertEqual(participant.displayName, "新参与者")
        XCTAssertEqual(participant.role, .participant)
    }
    
    func testJoinFullSession() async throws {
        let session = try await service.createSession(
            sceneTemplate: .mountainPeak,
            maxParticipants: 2
        )
        
        // 填充会话
        _ = try await service.joinSession(
            sessionCode: session.sessionCode,
            userID: UUID(),
            displayName: "用户 1"
        )
        
        // 尝试加入已满的会话
        XCTAssertThrowsError(try await service.joinSession(
            sessionCode: session.sessionCode,
            userID: UUID(),
            displayName: "用户 2"
        ))
    }
    
    // MARK: - 会话离开测试
    
    func testLeaveSession() async throws {
        let session = try await service.createSession(sceneTemplate: .skyGarden)
        
        let participant = try await service.joinSession(
            sessionCode: session.sessionCode,
            userID: UUID(),
            displayName: "测试用户"
        )
        
        try await service.leaveSession(sessionID: session.id, participantID: participant.id)
        
        // 验证参与者已标记为非活跃
        let updatedParticipant = try await service.getParticipant(byID: participant.id)
        XCTAssertFalse(updatedParticipant?.isActive ?? true)
    }
    
    // MARK: - 元素管理测试
    
    func testAddElement() async throws {
        let session = try await service.createSession(sceneTemplate: .starryNight)
        
        let element = try await service.addElement(
            sessionID: session.id,
            creatorID: UUID(),
            elementType: .crystal,
            position: SIMD3<Float>(0, 0, 0)
        )
        
        XCTAssertNotNil(element)
        XCTAssertEqual(element.elementType, .crystal)
    }
    
    func testUpdateElementPosition() async throws {
        let session = try await service.createSession(sceneTemplate: .oceanWorld)
        
        let element = try await service.addElement(
            sessionID: session.id,
            creatorID: UUID(),
            elementType: .light,
            position: SIMD3<Float>(0, 0, 0)
        )
        
        let newPosition = SIMD3<Float>(10, 20, 30)
        try await service.updateElementPosition(elementID: element.id, position: newPosition)
        
        let updatedElement = try await service.getElement(byID: element.id)
        XCTAssertEqual(updatedElement?.position, newPosition)
    }
    
    func testRemoveElement() async throws {
        let session = try await service.createSession(sceneTemplate: .forestMyst)
        
        let element = try await service.addElement(
            sessionID: session.id,
            creatorID: UUID(),
            elementType: .flower,
            position: SIMD3<Float>(0, 0, 0)
        )
        
        try await service.removeElement(elementID: element.id)
        
        let removedElement = try await service.getElement(byID: element.id)
        XCTAssertFalse(removedElement?.isVisible ?? true)
    }
    
    // MARK: - 消息发送测试
    
    func testSendMessage() async throws {
        let session = try await service.createSession(sceneTemplate: .crystalCave)
        
        let message = try await service.sendMessage(
            sessionID: session.id,
            senderID: UUID(),
            senderDisplayName: "发送者",
            messageType: .text,
            content: "测试消息"
        )
        
        XCTAssertNotNil(message)
        XCTAssertEqual(message.content, "测试消息")
        XCTAssertEqual(message.messageType, .text)
    }
    
    func testSendEmojiMessage() async throws {
        let session = try await service.createSession(sceneTemplate: .auroraField)
        
        let message = try await service.sendMessage(
            sessionID: session.id,
            senderID: UUID(),
            senderDisplayName: "用户",
            messageType: .emoji,
            content: "🌟"
        )
        
        XCTAssertEqual(message.messageType, .emoji)
        XCTAssertEqual(message.content, "🌟")
    }
    
    // MARK: - 会话清理测试
    
    func testCleanupExpiredSessions() async throws {
        // 创建已过期的会话
        let expiredSession = ARSession(
            sessionCode: "EXPIRED",
            hostUserID: UUID(),
            hostDisplayName: "Host",
            durationMinutes: -60 // 1 小时前过期
        )
        modelContext.insert(expiredSession)
        try modelContext.save()
        
        // 清理过期会话
        try await service.cleanupExpiredSessions()
        
        // 验证会话已被删除或标记为非活跃
        let fetchedSession = try await service.getSession(byCode: "EXPIRED")
        XCTAssertFalse(fetchedSession?.isActive ?? true)
    }
}

// MARK: - AR 同步引擎测试

final class ARSyncEngineTests: XCTestCase {
    
    var engine: ARSyncEngine!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ARSession.self, configurations: config)
        modelContext = ModelContext(container)
        engine = ARSyncEngine(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        engine = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 同步状态测试
    
    func testInitialSyncState() {
        XCTAssertEqual(engine.syncState.status, .idle)
        XCTAssertEqual(engine.syncState.pendingChanges.count, 0)
    }
    
    // MARK: - 变化追踪测试
    
    func testTrackParticipantUpdate() {
        let participant = ARParticipant(
            sessionID: UUID(),
            userID: UUID(),
            displayName: "测试"
        )
        
        engine.trackParticipantUpdate(participant)
        
        XCTAssertEqual(engine.syncState.pendingChanges.count, 1)
    }
    
    func testTrackElementUpdate() {
        let element = ARElement(
            sessionID: UUID(),
            creatorID: UUID(),
            elementType: .crystal,
            position: SIMD3<Float>(0, 0, 0)
        )
        
        engine.trackElementUpdate(element)
        
        XCTAssertEqual(engine.syncState.pendingChanges.count, 1)
    }
    
    // MARK: - 同步批次测试
    
    func testCreateSyncBatch() {
        let session = ARSession(
            sessionCode: "TEST",
            hostUserID: UUID(),
            hostDisplayName: "Host"
        )
        
        let batch = engine.createSyncBatch(for: session)
        
        XCTAssertNotNil(batch)
        XCTAssertEqual(batch.sessionID, session.id)
        XCTAssertEqual(batch.changes.count, 0)
    }
    
    func testSyncBatchWithChanges() {
        let session = ARSession(
            sessionCode: "TEST",
            hostUserID: UUID(),
            hostDisplayName: "Host"
        )
        
        let participant = ARParticipant(
            sessionID: session.id,
            userID: UUID(),
            displayName: "用户"
        )
        
        engine.trackParticipantUpdate(participant)
        
        let batch = engine.createSyncBatch(for: session)
        
        XCTAssertEqual(batch.changes.count, 1)
    }
    
    // MARK: - 冲突解决测试
    
    func testConflictResolutionLastWriteWins() {
        let older = Date().addingTimeInterval(-10)
        let newer = Date()
        
        let resolution = engine.resolveConflict(
            localTimestamp: older,
            remoteTimestamp: newer
        )
        
        XCTAssertEqual(resolution, .useRemote)
    }
    
    func testConflictResolutionLocalWins() {
        let local = Date()
        let remote = Date().addingTimeInterval(-10)
        
        let resolution = engine.resolveConflict(
            localTimestamp: local,
            remoteTimestamp: remote
        )
        
        XCTAssertEqual(resolution, .useLocal)
    }
    
    // MARK: - 性能测试
    
    func testSyncPerformanceWithManyElements() {
        let sessionID = UUID()
        
        // 添加 100 个元素变化
        for i in 0..<100 {
            let element = ARElement(
                sessionID: sessionID,
                creatorID: UUID(),
                elementType: .light,
                position: SIMD3<Float>(Float(i), 0, 0)
            )
            engine.trackElementUpdate(element)
        }
        
        let batch = engine.createSyncBatch(for: ARSession(
            sessionCode: "PERF",
            hostUserID: UUID(),
            hostDisplayName: "Host"
        ))
        
        XCTAssertEqual(batch.changes.count, 100)
    }
}

// MARK: - 测试套件

extension ARSessionModelTests {
    static var allTests: [(String, (ARSessionModelTests) -> () throws -> Void)] {
        [
            ("testARSessionInitialization", testARSessionInitialization),
            ("testARSessionWithCustomDuration", testARSessionWithCustomDuration),
            ("testSessionValidity", testSessionValidity),
            ("testSessionExpired", testSessionExpired),
            ("testSessionFull", testSessionFull),
            ("testSessionCanJoin", testSessionCanJoin),
            ("testSceneTemplateCount", testSceneTemplateCount),
            ("testSceneTemplateDisplayNames", testSceneTemplateDisplayNames),
            ("testSceneTemplateIcons", testSceneTemplateIcons),
            ("testARParticipantInitialization", testARParticipantInitialization),
            ("testARParticipantHostRole", testARParticipantHostRole),
            ("testARElementInitialization", testARElementInitialization),
            ("testARElementTypeCount", testARElementTypeCount),
            ("testARMessageInitialization", testARMessageInitialization),
            ("testARSessionStateDefault", testARSessionStateDefault)
        ]
    }
}

extension ARSessionServiceTests {
    static var allTests: [(String, (ARSessionServiceTests) -> () throws -> Void)] {
        [
            ("testCreateSession", testCreateSession),
            ("testCreateSessionWithCustomDuration", testCreateSessionWithCustomDuration),
            ("testSessionCodeFormat", testSessionCodeFormat),
            ("testSessionCodeUniqueness", testSessionCodeUniqueness),
            ("testGetSessionByCode", testGetSessionByCode),
            ("testJoinSession", testJoinSession),
            ("testLeaveSession", testLeaveSession),
            ("testAddElement", testAddElement),
            ("testSendMessage", testSendMessage)
        ]
    }
}

extension ARSyncEngineTests {
    static var allTests: [(String, (ARSyncEngineTests) -> () throws -> Void)] {
        [
            ("testInitialSyncState", testInitialSyncState),
            ("testTrackParticipantUpdate", testTrackParticipantUpdate),
            ("testCreateSyncBatch", testCreateSyncBatch),
            ("testConflictResolutionLastWriteWins", testConflictResolutionLastWriteWins),
            ("testSyncPerformanceWithManyElements", testSyncPerformanceWithManyElements)
        ]
    }
}
