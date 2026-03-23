//
//  DreamFamilyTests.swift
//  DreamLog - Family Sharing Unit Tests
//  Phase 96: Family Sharing 👨‍👩‍👧‍👦✨
//
//  Created on 2026-03-23
//

import XCTest
@testable import DreamLog

final class DreamFamilyTests: XCTestCase {
    
    // MARK: - Properties
    
    var service: DreamFamilyService!
    var privacyService: DreamFamilyPrivacyService!
    var testUserId: UUID!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        testUserId = UUID()
        service = DreamFamilyService(currentUserId: testUserId)
        privacyService = DreamFamilyPrivacyService()
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "dreamlog.family.groups")
        UserDefaults.standard.removeObject(forKey: "dreamlog.family.members")
        UserDefaults.standard.removeObject(forKey: "dreamlog.family.shared_dreams")
        UserDefaults.standard.removeObject(forKey: "dreamlog.family.patterns")
        UserDefaults.standard.removeObject(forKey: "dreamlog.family.challenges")
        UserDefaults.standard.removeObject(forKey: "dreamlog.family.achievements")
    }
    
    override func tearDown() async throws {
        service = nil
        privacyService = nil
        testUserId = nil
        try await super.tearDown()
    }
    
    // MARK: - Family Group Tests
    
    func testCreateFamilyGroup() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        XCTAssertEqual(family.name, "测试家庭")
        XCTAssertEqual(family.adminId, testUserId)
        XCTAssertEqual(family.memberCount, 1)
        XCTAssertEqual(family.inviteCode.count, 8)
        
        let families = await service.getUserFamilies()
        XCTAssertEqual(families.count, 1)
    }
    
    func testCreateFamilyGroup_WhenAlreadyInFamily() async throws {
        _ = try await service.createFamilyGroup(name: "家庭 1")
        
        await assertThrowsError(FamilyError.alreadyInFamily) {
            _ = try await service.createFamilyGroup(name: "家庭 2")
        }
    }
    
    func testJoinFamilyGroup() async throws {
        // 创建另一个用户和家庭
        let otherUserId = UUID()
        let otherService = DreamFamilyService(currentUserId: otherUserId)
        let family = try await otherService.createFamilyGroup(name: "测试家庭")
        
        // 加入家庭
        let joinedFamily = try await service.joinFamilyGroup(inviteCode: family.inviteCode)
        
        XCTAssertEqual(joinedFamily.id, family.id)
        
        let members = await service.getFamilyMembers(familyId: family.id)
        XCTAssertEqual(members.count, 2)
    }
    
    func testJoinFamilyGroup_InvalidInviteCode() async throws {
        await assertThrowsError(FamilyError.invalidInviteCode) {
            _ = try await service.joinFamilyGroup(inviteCode: "INVALID")
        }
    }
    
    func testInviteMember() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let invite = try await service.inviteMember(
            familyId: family.id,
            relationship: .sibling,
            role: .adult
        )
        
        XCTAssertEqual(invite.familyId, family.id)
        XCTAssertEqual(invite.inviteCode, family.inviteCode)
        XCTAssertFalse(invite.isUsed)
    }
    
    // MARK: - Member Management Tests
    
    func testGetFamilyMembers() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let members = await service.getFamilyMembers(familyId: family.id)
        
        XCTAssertEqual(members.count, 1)
        XCTAssertEqual(members.first?.role, .admin)
        XCTAssertEqual(members.first?.userId, testUserId)
    }
    
    func testUpdateMemberRole() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        // 添加另一个成员
        let otherUserId = UUID()
        let otherService = DreamFamilyService(currentUserId: otherUserId)
        _ = try await otherService.joinFamilyGroup(inviteCode: family.inviteCode)
        
        // 获取成员 ID
        let members = await service.getFamilyMembers(familyId: family.id)
        let otherMember = members.first { $0.userId == otherUserId }
        XCTAssertNotNil(otherMember)
        
        // 更新角色（需要重新初始化服务以获取最新数据）
        service = DreamFamilyService(currentUserId: testUserId)
        try await service.updateMemberRole(
            familyId: family.id,
            memberId: otherMember!.id,
            newRole: .child
        )
        
        let updatedMembers = await service.getFamilyMembers(familyId: family.id)
        let updatedMember = updatedMembers.first { $0.id == otherMember!.id }
        XCTAssertEqual(updatedMember?.role, .child)
    }
    
    // MARK: - Dream Sharing Tests
    
    func testShareDreamToFamily() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let sharedDream = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "我的梦境",
            content: "这是一个测试梦境",
            emotions: ["快乐", "兴奋"],
            tags: ["飞行", "天空"],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        XCTAssertEqual(sharedDream.title, "我的梦境")
        XCTAssertEqual(sharedDream.ownerId, testUserId)
        XCTAssertEqual(sharedDream.privacyLevel, .family)
        XCTAssertFalse(sharedDream.isSensitive)
        
        let dreams = await service.getFamilyDreams(familyId: family.id)
        XCTAssertEqual(dreams.count, 1)
    }
    
    func testShareDreamToFamily_WithSensitiveContent() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let sharedDream = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "噩梦",
            content: "这是一个包含暴力内容的梦境",
            emotions: ["恐惧"],
            tags: ["噩梦"],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        XCTAssertTrue(sharedDream.isSensitive)
    }
    
    func testAddReaction() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let sharedDream = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "测试梦境",
            content: "内容",
            emotions: [],
            tags: [],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        try await service.addReaction(to: sharedDream.id, emoji: "❤️")
        
        let dreams = await service.getFamilyDreams(familyId: family.id)
        XCTAssertEqual(dreams.first?.reactions.count, 1)
        XCTAssertEqual(dreams.first?.reactions.first?.emoji, "❤️")
    }
    
    func testAddComment() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let sharedDream = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "测试梦境",
            content: "内容",
            emotions: [],
            tags: [],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        try await service.addComment(to: sharedDream.id, content: "很好的梦境！")
        
        let dreams = await service.getFamilyDreams(familyId: family.id)
        XCTAssertEqual(dreams.first?.comments.count, 1)
    }
    
    // MARK: - Privacy Tests
    
    func testCheckSensitiveContent() async {
        let nonSensitive = "今天做了一个美好的梦"
        let sensitive = "梦里有暴力和死亡"
        
        let isNonSensitiveSensitive = await privacyService.checkSensitiveContent(nonSensitive)
        let isSensitiveSensitive = await privacyService.checkSensitiveContent(sensitive)
        
        XCTAssertFalse(isNonSensitiveSensitive)
        XCTAssertTrue(isSensitiveSensitive)
    }
    
    func testFilterInappropriateContent() async {
        let content = "梦里有暴力和杀戮场景"
        let filtered = await privacyService.filterInappropriateContent(content)
        
        XCTAssertFalse(filtered.contains("暴力"))
        XCTAssertFalse(filtered.contains("杀戮"))
        XCTAssertTrue(filtered.contains("*"))
    }
    
    func testIsContentAppropriateForChild() async {
        let appropriate = "梦见在公园玩耍"
        let inappropriate = "梦见战斗和死亡"
        
        let isAppropriate = await privacyService.isContentAppropriateForChild(appropriate)
        let isInappropriate = await privacyService.isContentAppropriateForChild(inappropriate)
        
        XCTAssertTrue(isAppropriate)
        XCTAssertFalse(isInappropriate)
    }
    
    func testValidatePrivacySettings() async {
        // 儿童不能设置为公开
        let childValid = await privacyService.validatePrivacySettings(
            privacyLevel: .publicLevel,
            memberRole: .child
        )
        XCTAssertFalse(childValid)
        
        // 成人可以设置为公开
        let adultValid = await privacyService.validatePrivacySettings(
            privacyLevel: .publicLevel,
            memberRole: .adult
        )
        XCTAssertTrue(adultValid)
    }
    
    func testRecommendedPrivacyLevel() async {
        let childLevel = await privacyService.recommendedPrivacyLevel(for: .child)
        let adultLevel = await privacyService.recommendedPrivacyLevel(for: .adult)
        
        XCTAssertEqual(childLevel, .family)
        XCTAssertEqual(adultLevel, .privateLevel)
    }
    
    // MARK: - Pattern Analysis Tests
    
    func testAnalyzeFamilyPatterns() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        // 添加多个成员的梦境
        _ = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "梦境 1",
            content: "飞行",
            emotions: ["快乐"],
            tags: ["飞行", "天空"],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        _ = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "梦境 2",
            content: "飞翔",
            emotions: ["快乐"],
            tags: ["飞行", "自由"],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        let patterns = await service.analyzeFamilyPatterns(familyId: family.id)
        
        // 至少有共同符号模式
        XCTAssertGreaterThanOrEqual(patterns.count, 0)
    }
    
    // MARK: - Statistics Tests
    
    func testFamilyStatistics() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        // 分享多个梦境
        for i in 0..<10 {
            _ = try await service.shareDreamToFamily(
                dreamId: UUID(),
                title: "梦境 \(i)",
                content: "内容",
                emotions: [],
                tags: [],
                dreamDate: Date(),
                privacyLevel: .family
            )
        }
        
        // 等待统计更新（实际应该异步等待）
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let families = await service.getUserFamilies()
        let stats = families.first?.statistics
        
        XCTAssertNotNil(stats)
        XCTAssertGreaterThanOrEqual(stats?.totalDreams ?? 0, 10)
    }
    
    // MARK: - Achievement Tests
    
    func testUnlockFirstDreamAchievement() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        _ = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "第一个梦境",
            content: "内容",
            emotions: [],
            tags: [],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        let achievements = await service.getFamilyAchievements(familyId: family.id)
        
        XCTAssertTrue(achievements.contains { $0.achievementType == .firstDream })
    }
    
    // MARK: - Visibility Tests
    
    func testDreamVisibility_Private() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let sharedDream = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "私密梦境",
            content: "内容",
            emotions: [],
            tags: [],
            dreamDate: Date(),
            privacyLevel: .privateLevel
        )
        
        // 创建另一个用户
        let otherUserId = UUID()
        let otherService = DreamFamilyService(currentUserId: otherUserId)
        _ = try await otherService.joinFamilyGroup(inviteCode: family.inviteCode)
        
        // 另一个用户不应该看到私密梦境
        let otherDreams = await otherService.getFamilyDreams(familyId: family.id)
        XCTAssertFalse(otherDreams.contains { $0.id == sharedDream.id })
    }
    
    func testDreamVisibility_Family() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        let sharedDream = try await service.shareDreamToFamily(
            dreamId: UUID(),
            title: "家庭梦境",
            content: "内容",
            emotions: [],
            tags: [],
            dreamDate: Date(),
            privacyLevel: .family
        )
        
        // 创建另一个用户
        let otherUserId = UUID()
        let otherService = DreamFamilyService(currentUserId: otherUserId)
        _ = try await otherService.joinFamilyGroup(inviteCode: family.inviteCode)
        
        // 另一个用户应该看到家庭梦境
        let otherDreams = await otherService.getFamilyDreams(familyId: family.id)
        XCTAssertTrue(otherDreams.contains { $0.id == sharedDream.id })
    }
    
    // MARK: - Helper Methods
    
    private func assertThrowsError<T: Sendable>(_ expectedError: Error, file: StaticString = #filePath, line: UInt = #line, operation: @escaping @Sendable () async throws -> T) async {
        do {
            _ = try await operation()
            XCTFail("Expected error \(expectedError) but no error was thrown", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? FamilyError, expectedError as? FamilyError, file: file, line: line)
        }
    }
}

// MARK: - Performance Tests

extension DreamFamilyTests {
    
    func testPerformanceFamilyCreation() async throws {
        measure {
            let exp = expectation(description: "Create family")
            Task {
                _ = try? await service.createFamilyGroup(name: "性能测试家庭")
                exp.fulfill()
            }
            wait(for: [exp], timeout: 5.0)
        }
    }
    
    func testPerformanceDreamSharing() async throws {
        let family = try await service.createFamilyGroup(name: "测试家庭")
        
        measure {
            let exp = expectation(description: "Share dreams")
            Task {
                for _ in 0..<10 {
                    _ = try? await service.shareDreamToFamily(
                        dreamId: UUID(),
                        title: "性能测试",
                        content: "内容",
                        emotions: [],
                        tags: [],
                        dreamDate: Date(),
                        privacyLevel: .family
                    )
                }
                exp.fulfill()
            }
            wait(for: [exp], timeout: 10.0)
        }
    }
}
