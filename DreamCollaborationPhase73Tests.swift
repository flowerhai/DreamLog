//
//  DreamCollaborationPhase73Tests.swift
//  DreamLog - Phase 73 单元测试
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import XCTest
import SwiftData
@testable import DreamLog

// MARK: - User Profile Tests

final class DreamUserProfileTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: DreamUserProfile.self,
            DreamUserBadge.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - User Creation Tests
    
    func testUserCreation() throws {
        let user = DreamUserProfile(
            id: "test-user-1",
            username: "testuser",
            displayName: "Test User"
        )
        
        XCTAssertEqual(user.id, "test-user-1")
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.displayName, "Test User")
        XCTAssertEqual(user.stats.sessionsCreated, 0)
        XCTAssertEqual(user.stats.activityLevel, .newcomer)
    }
    
    func testUserStatsCalculation() throws {
        let user = DreamUserProfile(
            id: "test-user-2",
            username: "testuser2",
            displayName: "Test User 2"
        )
        
        // 更新统计
        user.updateStats(sessionsCreated: 10, interpretationsAdded: 50, likesReceived: 100)
        
        XCTAssertEqual(user.stats.sessionsCreated, 10)
        XCTAssertEqual(user.stats.interpretationsAdded, 50)
        XCTAssertEqual(user.stats.likesReceived, 100)
        XCTAssertGreaterThan(user.stats.influenceScore, 0)
    }
    
    func testUserFollowUnfollow() throws {
        let user1 = DreamUserProfile(id: "user-1", username: "user1", displayName: "User 1")
        let user2 = DreamUserProfile(id: "user-2", username: "user2", displayName: "User 2")
        
        modelContext.insert(user1)
        modelContext.insert(user2)
        try modelContext.save()
        
        // 关注
        user1.follow(user2)
        XCTAssertTrue(user1.isFollowing(user2))
        XCTAssertEqual(user1.stats.followingCount, 1)
        
        // 取消关注
        user1.unfollow(user2)
        XCTAssertFalse(user1.isFollowing(user2))
        XCTAssertEqual(user1.stats.followingCount, 0)
    }
    
    func testUserActivityLevel() throws {
        let user = DreamUserProfile(id: "user-3", username: "user3", displayName: "User 3")
        
        // 测试不同活跃度等级
        user.stats.activeDays = 5
        XCTAssertEqual(user.stats.activityLevel, .newcomer)
        
        user.stats.activeDays = 15
        XCTAssertEqual(user.stats.activityLevel, .active)
        
        user.stats.activeDays = 60
        XCTAssertEqual(user.stats.activityLevel, .veteran)
        
        user.stats.activeDays = 200
        XCTAssertEqual(user.stats.activityLevel, .expert)
        
        user.stats.activeDays = 400
        XCTAssertEqual(user.stats.activityLevel, .master)
    }
    
    // MARK: - Badge Tests
    
    func testBadgeCreation() throws {
        let badge = DreamUserBadge.createPresetBadge("first_session", userId: "user-1")
        
        XCTAssertNotNil(badge)
        XCTAssertEqual(badge?.name, "初次协作")
        XCTAssertEqual(badge?.icon, "🎉")
        XCTAssertEqual(badge?.category, .collaboration)
    }
    
    func testBadgeCategories() throws {
        let categories: [BadgeCategory] = [.collaboration, .interpretation, .social, .achievement, .special]
        
        XCTAssertEqual(BadgeCategory.collaboration.icon, "🤝")
        XCTAssertEqual(BadgeCategory.interpretation.icon, "💡")
        XCTAssertEqual(BadgeCategory.social.icon, "💬")
        XCTAssertEqual(BadgeCategory.achievement.icon, "🏆")
        XCTAssertEqual(BadgeCategory.special.icon, "⭐")
    }
    
    // MARK: - Specialty Tests
    
    func testDreamSpecialties() throws {
        let specialties: [DreamSpecialty] = [
            .symbolAnalysis, .psychology, .spirituality, .creativity,
            .lucidDreaming, .nightmareHealing, .patternRecognition, .culturalInterpretation
        ]
        
        XCTAssertEqual(DreamSpecialty.symbolAnalysis.icon, "🔍")
        XCTAssertEqual(DreamSpecialty.psychology.icon, "🧠")
        XCTAssertEqual(DreamSpecialty.spirituality.icon, "🌟")
        XCTAssertEqual(DreamSpecialty.creativity.icon, "🎨")
    }
    
    // MARK: - Preferences Tests
    
    func testUserPreferences() throws {
        var preferences = DreamUserPreferences()
        
        XCTAssertTrue(preferences.enableNotifications)
        XCTAssertTrue(preferences.notifyOnNewInterpretation)
        XCTAssertEqual(preferences.theme, .system)
        XCTAssertEqual(preferences.fontSize, .medium)
        XCTAssertEqual(preferences.visibility, .friends)
        
        // 修改设置
        preferences.enableNotifications = false
        preferences.theme = .dark
        preferences.fontSize = .large
        
        XCTAssertFalse(preferences.enableNotifications)
        XCTAssertEqual(preferences.theme, .dark)
        XCTAssertEqual(preferences.fontSize, .large)
    }
}

// MARK: - Permission Tests

final class CollaborationPermissionTests: XCTestCase {
    
    // MARK: - Role Permission Tests
    
    func testOwnerPermissions() {
        let permissions: [CollaborationPermission] = [
            .view, .addInterpretation, .editSession, .deleteSession,
            .moderateContent, .adoptInterpretation, .manageRoles
        ]
        
        for permission in permissions {
            XCTAssertTrue(
                CollaborationPermissionChecker.hasPermission(
                    userRole: .owner,
                    isOwner: true,
                    permission: permission
                )
            )
        }
    }
    
    func testModeratorPermissions() {
        // 主持人应该有审核权限
        XCTAssertTrue(
            CollaborationPermissionChecker.hasPermission(
                userRole: .moderator,
                isOwner: false,
                permission: .moderateContent
            )
        )
        
        XCTAssertTrue(
            CollaborationPermissionChecker.hasPermission(
                userRole: .moderator,
                isOwner: false,
                permission: .adoptInterpretation
            )
        )
        
        // 主持人不能删除会话
        XCTAssertFalse(
            CollaborationPermissionChecker.hasPermission(
                userRole: .moderator,
                isOwner: false,
                permission: .deleteSession
            )
        )
    }
    
    func testMemberPermissions() {
        // 成员应该能添加解读
        XCTAssertTrue(
            CollaborationPermissionChecker.hasPermission(
                userRole: .member,
                isOwner: false,
                permission: .addInterpretation
            )
        )
        
        // 成员不能审核内容
        XCTAssertFalse(
            CollaborationPermissionChecker.hasPermission(
                userRole: .member,
                isOwner: false,
                permission: .moderateContent
            )
        )
    }
    
    func testObserverPermissions() {
        // 观察者只能查看
        XCTAssertTrue(
            CollaborationPermissionChecker.hasPermission(
                userRole: .observer,
                isOwner: false,
                permission: .view
            )
        )
        
        // 观察者不能添加解读
        XCTAssertFalse(
            CollaborationPermissionChecker.hasPermission(
                userRole: .observer,
                isOwner: false,
                permission: .addInterpretation
            )
        )
    }
    
    // MARK: - Content Moderation Tests
    
    func testCanEditInterpretation() {
        // 用户可以编辑自己的解读
        XCTAssertTrue(
            CollaborationPermissionChecker.canEditInterpretation(
                userRole: .member,
                isOwner: false,
                interpretationOwnerId: "user-1",
                currentUserId: "user-1"
            )
        )
        
        // 用户不能编辑他人的解读
        XCTAssertFalse(
            CollaborationPermissionChecker.canEditInterpretation(
                userRole: .member,
                isOwner: false,
                interpretationOwnerId: "user-2",
                currentUserId: "user-1"
            )
        )
        
        // 创建者可以编辑任何解读
        XCTAssertTrue(
            CollaborationPermissionChecker.canEditInterpretation(
                userRole: .owner,
                isOwner: true,
                interpretationOwnerId: "user-2",
                currentUserId: "user-1"
            )
        )
    }
    
    // MARK: - Report Reason Tests
    
    func testReportReasons() {
        let reasons: [ReportReason] = [.spam, .harassment, .misinformation, .inappropriate, .copyright, .other]
        
        XCTAssertEqual(ReportReason.spam.icon, "🗑️")
        XCTAssertEqual(ReportReason.harassment.icon, "😠")
        XCTAssertEqual(ReportReason.misinformation.icon, "❌")
        XCTAssertEqual(ReportReason.inappropriate.icon, "⚠️")
    }
    
    // MARK: - Session Access Tests
    
    func testSessionAccessValid() {
        let session = DreamCollaborationSession(
            dreamId: UUID(),
            title: "Test Session",
            description: "Test",
            createdBy: "user-1"
        )
        
        let result = SessionAccessController.checkAccess(
            session: session,
            userId: "user-1",
            isParticipant: true
        )
        
        XCTAssertTrue(result.canAccess)
        XCTAssertNil(result.reason)
    }
    
    func testSessionAccessExpired() {
        let session = DreamCollaborationSession(
            dreamId: UUID(),
            title: "Test Session",
            description: "Test",
            createdBy: "user-1"
        )
        session.expiresAt = Date().addingTimeInterval(-3600) // 1 小时前过期
        
        let result = SessionAccessController.checkAccess(
            session: session,
            userId: "user-1",
            isParticipant: true
        )
        
        XCTAssertFalse(result.canAccess)
        XCTAssertEqual(result.reason, .sessionExpired)
    }
}

// MARK: - Mention Tests

final class DreamMentionTests: XCTestCase {
    
    // MARK: - Mention Parsing Tests
    
    func testParseMentions() async {
        let service = DreamMentionService()
        
        // 注册用户
        await service.registerUser(username: "alice", userId: "user-1")
        await service.registerUser(username: "bob", userId: "user-2")
        
        // 解析提及
        let text = "Hey @alice and @bob, check this out!"
        let mentions = await service.parseMentions(text: text)
        
        XCTAssertEqual(mentions.count, 2)
        XCTAssertEqual(mentions[0].mentionedUsername, "alice")
        XCTAssertEqual(mentions[1].mentionedUsername, "bob")
    }
    
    func testParseMentionsNotFound() async {
        let service = DreamMentionService()
        
        let text = "Hey @unknown, check this out!"
        let mentions = await service.parseMentions(text: text)
        
        XCTAssertEqual(mentions.count, 0)
    }
    
    // MARK: - Mention Notification Tests
    
    func testCreateMentionNotification() async {
        let service = DreamMentionService()
        
        await service.registerUser(username: "alice", userId: "user-1")
        
        let notification = await service.createMentionNotification(
            fromUserId: "user-2",
            fromUsername: "bob",
            toUserId: "user-1",
            contentType: .comment,
            contentId: "comment-1",
            contentPreview: "Great point!"
        )
        
        XCTAssertEqual(notification.fromUsername, "bob")
        XCTAssertEqual(notification.toUserId, "user-1")
        XCTAssertEqual(notification.contentType, .comment)
        
        // 检查未读数量
        let unreadCount = await service.getUnreadCount(userId: "user-1")
        XCTAssertEqual(unreadCount, 1)
    }
    
    // MARK: - Text Formatting Tests
    
    func testStripMentions() {
        let text = "Hey @alice and @bob, check this out!"
        let stripped = DreamMentionService.stripMentions(text: text)
        
        XCTAssertEqual(stripped, "Hey  and , check this out!")
    }
}

// MARK: - Notification Tests

final class CollaborationNotificationTests: XCTestCase {
    
    // MARK: - Notification Type Tests
    
    func testNotificationTypes() {
        let types: [CollaborationNotificationType] = [
            .newParticipant, .newInterpretation, .interpretationAdopted,
            .commentReply, .mention, .sessionComplete, .invitation, .roleChanged
        ]
        
        XCTAssertEqual(CollaborationNotificationType.newParticipant.icon, "👤")
        XCTAssertEqual(CollaborationNotificationType.newInterpretation.icon, "💡")
        XCTAssertEqual(CollaborationNotificationType.interpretationAdopted.icon, "✅")
        XCTAssertEqual(CollaborationNotificationType.mention.icon, "@")
    }
    
    // MARK: - Notification Settings Tests
    
    func testNotificationSettings() {
        var settings = CollaborationNotificationSettings()
        
        XCTAssertTrue(settings.enabled)
        XCTAssertTrue(settings.allowsType(.newInterpretation))
        XCTAssertTrue(settings.allowsType(.mention))
        
        // 禁用某类型
        settings.newInterpretation = false
        XCTAssertFalse(settings.allowsType(.newInterpretation))
        XCTAssertTrue(settings.allowsType(.mention))
        
        // 禁用所有
        settings.enabled = false
        XCTAssertFalse(settings.allowsType(.mention))
    }
    
    // MARK: - Notification Factory Tests
    
    func testCreateNewParticipantNotification() {
        let sessionId = UUID()
        let notification = DreamCollaborationNotificationService.createNewParticipantNotification(
            participantName: "Alice",
            sessionId: sessionId,
            sessionTitle: "Test Session",
            targetUserId: "user-1"
        )
        
        XCTAssertEqual(notification.type, .newParticipant)
        XCTAssertEqual(notification.title, "新参与者加入")
        XCTAssertTrue(notification.body.contains("Alice"))
        XCTAssertTrue(notification.body.contains("Test Session"))
    }
    
    func testCreateMentionNotification() {
        let sessionId = UUID()
        let notification = DreamCollaborationNotificationService.createMentionNotification(
            fromUsername: "Bob",
            contentPreview: "Great point!",
            sessionId: sessionId,
            targetUserId: "user-1"
        )
        
        XCTAssertEqual(notification.type, .mention)
        XCTAssertEqual(notification.title, "@提及")
        XCTAssertTrue(notification.body.contains("Bob"))
        XCTAssertTrue(notification.body.contains("Great point!"))
    }
}

// MARK: - Performance Tests

final class CollaborationPerformanceTests: XCTestCase {
    
    func testUserCreationPerformance() {
        measure {
            for _ in 0..<100 {
                let user = DreamUserProfile(
                    id: UUID().uuidString,
                    username: "testuser",
                    displayName: "Test User"
                )
                _ = user.stats.influenceScore
            }
        }
    }
    
    func testMentionParsingPerformance() async {
        let service = DreamMentionService()
        let text = "Hey @alice @bob @charlie @david @eve, check this out!"
        
        measure {
            Task {
                await service.parseMentions(text: text)
            }
        }
    }
}
