//
//  DreamPartnerActivityTests.swift
//  DreamLogTests
//
//  梦境伴侣活动动态 - 单元测试
//  Phase 88 Enhancement: 活动动态与通知增强
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamPartnerActivityTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var activityService: DreamPartnerActivityService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([PartnerActivity.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        activityService = DreamPartnerActivityService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        activityService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 活动记录测试
    
    func testLogActivity() async {
        await activityService.logActivity(
            type: .dreamShared,
            actorId: "user123",
            actorName: "Test User",
            targetId: "dream456",
            targetTitle: "Test Dream"
        )
        
        let activities = activityService.getAllActivities()
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].type, .dreamShared)
        XCTAssertEqual(activities[0].actorName, "Test User")
        XCTAssertFalse(activities[0].isRead)
    }
    
    func testLogDreamShare() async {
        await activityService.logDreamShare(
            dreamId: "dream123",
            dreamTitle: "Amazing Dream",
            partnerId: "partner456",
            partnerName: "Partner User"
        )
        
        let activities = activityService.getActivities(type: .dreamShared)
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].targetId, "dream123")
        XCTAssertEqual(activities[0].targetTitle, "Amazing Dream")
    }
    
    func testLogComment() async {
        await activityService.logComment(
            dreamId: "dream123",
            dreamTitle: "Test Dream",
            partnerId: "partner456",
            partnerName: "Partner User",
            comment: "Great dream!"
        )
        
        let activities = activityService.getActivities(type: .commentAdded)
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].content, "Great dream!")
    }
    
    func testLogReaction() async {
        await activityService.logReaction(
            dreamId: "dream123",
            partnerId: "partner456",
            partnerName: "Partner User",
            reaction: "❤️"
        )
        
        let activities = activityService.getActivities(type: .reactionAdded)
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].content, "❤️")
    }
    
    func testLogConnection() async {
        await activityService.logConnection(
            partnerId: "partner123",
            partnerName: "New Partner"
        )
        
        let activities = activityService.getActivities(type: .partnerConnected)
        XCTAssertEqual(activities.count, 1)
    }
    
    // MARK: - 查询测试
    
    func testGetAllActivities() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2")
        await activityService.logActivity(type: .reactionAdded, actorId: "3", actorName: "User3")
        
        let activities = activityService.getAllActivities()
        XCTAssertEqual(activities.count, 3)
    }
    
    func testGetUnreadActivities() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2")
        
        let unread = activityService.getUnreadActivities()
        XCTAssertEqual(unread.count, 2)
        
        if let first = unread.first {
            activityService.markAsRead(first)
        }
        
        let remainingUnread = activityService.getUnreadActivities()
        XCTAssertEqual(remainingUnread.count, 1)
    }
    
    func testGetActivitiesByType() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .dreamShared, actorId: "2", actorName: "User2")
        await activityService.logActivity(type: .commentAdded, actorId: "3", actorName: "User3")
        
        let shares = activityService.getActivities(type: .dreamShared)
        XCTAssertEqual(shares.count, 2)
        
        let comments = activityService.getActivities(type: .commentAdded)
        XCTAssertEqual(comments.count, 1)
    }
    
    func testGetActivitiesByTarget() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1", targetId: "dream1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2", targetId: "dream1")
        await activityService.logActivity(type: .reactionAdded, actorId: "3", actorName: "User3", targetId: "dream2")
        
        let dream1Activities = activityService.getActivities(targetId: "dream1")
        XCTAssertEqual(dream1Activities.count, 2)
    }
    
    func testGetStats() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2")
        await activityService.logActivity(type: .commentAdded, actorId: "3", actorName: "User3")
        
        let stats = activityService.getStats()
        XCTAssertEqual(stats.totalActivities, 3)
        XCTAssertEqual(stats.unreadCount, 3)
        XCTAssertEqual(stats.activitiesByType[.dreamShared], 1)
        XCTAssertEqual(stats.activitiesByType[.commentAdded], 2)
    }
    
    // MARK: - 标记已读测试
    
    func testMarkAsRead() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        
        let activities = activityService.getAllActivities()
        XCTAssertFalse(activities[0].isRead)
        
        activityService.markAsRead(activities[0])
        
        let updated = activityService.getAllActivities()
        XCTAssertTrue(updated[0].isRead)
    }
    
    func testMarkAllAsRead() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2")
        await activityService.logActivity(type: .reactionAdded, actorId: "3", actorName: "User3")
        
        activityService.markAllAsRead()
        
        let activities = activityService.getAllActivities()
        for activity in activities {
            XCTAssertTrue(activity.isRead)
        }
    }
    
    func testMarkTypeAsRead() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2")
        await activityService.logActivity(type: .dreamShared, actorId: "3", actorName: "User3")
        
        activityService.markTypeAsRead(.dreamShared)
        
        let shares = activityService.getActivities(type: .dreamShared)
        for share in shares {
            XCTAssertTrue(share.isRead)
        }
        
        let comments = activityService.getActivities(type: .commentAdded)
        XCTAssertFalse(comments[0].isRead)
    }
    
    // MARK: - 删除测试
    
    func testDeleteActivity() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        
        let activities = activityService.getAllActivities()
        XCTAssertEqual(activities.count, 1)
        
        activityService.deleteActivity(activities[0])
        
        XCTAssertEqual(activityService.getAllActivities().count, 0)
    }
    
    func testDeleteAllActivities() async {
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        await activityService.logActivity(type: .commentAdded, actorId: "2", actorName: "User2")
        await activityService.logActivity(type: .reactionAdded, actorId: "3", actorName: "User3")
        
        activityService.deleteAllActivities()
        
        XCTAssertEqual(activityService.getAllActivities().count, 0)
    }
    
    func testCleanupOldActivities() async {
        let oldDate = Date().addingTimeInterval(-Double(31 * 86400))  // 31 天前
        
        await activityService.logActivity(type: .dreamShared, actorId: "1", actorName: "User1")
        
        let oldActivity = PartnerActivity(
            type: .commentAdded,
            actorId: "2",
            actorName: "User2",
            createdAt: oldDate
        )
        try? modelContext.insert(oldActivity)
        try? modelContext.save()
        
        XCTAssertEqual(activityService.getAllActivities().count, 2)
        
        activityService.cleanupOldActivities(keepDays: 30)
        
        XCTAssertEqual(activityService.getAllActivities().count, 1)
    }
    
    // MARK: - 通知设置测试
    
    func testGetNotificationSettings() {
        let settings = activityService.getNotificationSettings()
        
        XCTAssertTrue(settings.enableDreamShared)
        XCTAssertFalse(settings.enableDreamViewed)
        XCTAssertTrue(settings.enableCommentAdded)
        XCTAssertTrue(settings.enableReactionAdded)
        XCTAssertTrue(settings.enablePartnerConnected)
        XCTAssertTrue(settings.enableInviteAccepted)
        XCTAssertTrue(settings.quietHoursEnabled)
        XCTAssertEqual(settings.quietHoursStart, "22:00")
        XCTAssertEqual(settings.quietHoursEnd, "08:00")
    }
    
    func testUpdateNotificationSettings() {
        var settings = activityService.getNotificationSettings()
        settings.enableDreamShared = false
        settings.enableDreamViewed = true
        settings.quietHoursEnabled = false
        
        activityService.updateNotificationSettings(settings)
        
        let updated = activityService.getNotificationSettings()
        XCTAssertFalse(updated.enableDreamShared)
        XCTAssertTrue(updated.enableDreamViewed)
        XCTAssertFalse(updated.quietHoursEnabled)
    }
    
    func testSetNotificationEnabled() {
        activityService.setNotificationEnabled(false, for: .dreamShared)
        activityService.setNotificationEnabled(false, for: .commentAdded)
        
        let settings = activityService.getNotificationSettings()
        XCTAssertFalse(settings.enableDreamShared)
        XCTAssertFalse(settings.enableCommentAdded)
        XCTAssertTrue(settings.enableDreamViewed)
    }
    
    func testShouldNotify() {
        var settings = PartnerNotificationSettings()
        settings.quietHoursEnabled = false
        
        XCTAssertTrue(settings.shouldNotify(for: .dreamShared))
        XCTAssertFalse(settings.shouldNotify(for: .dreamViewed))
        XCTAssertTrue(settings.shouldNotify(for: .commentAdded))
    }
    
    func testQuietHours() {
        var settings = PartnerNotificationSettings()
        settings.quietHoursStart = "22:00"
        settings.quietHoursEnd = "08:00"
        settings.quietHoursEnabled = true
        
        // 测试安静时段逻辑 (需要模拟时间，这里只测试设置)
        XCTAssertTrue(settings.quietHoursEnabled)
        XCTAssertEqual(settings.quietHoursStart, "22:00")
        XCTAssertEqual(settings.quietHoursEnd, "08:00")
    }
    
    // MARK: - 活动描述测试
    
    func testActivityDescription() {
        let shareActivity = PartnerActivity(
            type: .dreamShared,
            actorId: "1",
            actorName: "Alice",
            targetTitle: "Flying Dream"
        )
        XCTAssertEqual(shareActivity.activityDescription, "Alice 分享了梦境\"Flying Dream\"")
        
        let commentActivity = PartnerActivity(
            type: .commentAdded,
            actorId: "2",
            actorName: "Bob",
            content: "Nice dream!"
        )
        XCTAssertEqual(commentActivity.activityDescription, "Bob 评论了：Nice dream!")
        
        let connectionActivity = PartnerActivity(
            type: .partnerConnected,
            actorId: "3",
            actorName: "Charlie"
        )
        XCTAssertEqual(connectionActivity.activityDescription, "你与 Charlie 建立了梦境共享关系")
    }
    
    // MARK: - 时间格式化测试
    
    func testTimeAgo() {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        let oneHourAgo = now.addingTimeInterval(-3600)
        let oneDayAgo = now.addingTimeInterval(-86400)
        
        let recent = PartnerActivity(type: .dreamShared, actorId: "1", actorName: "User", createdAt: now)
        XCTAssertEqual(recent.timeAgo, "刚刚")
        
        let minute = PartnerActivity(type: .dreamShared, actorId: "1", actorName: "User", createdAt: oneMinuteAgo)
        XCTAssertTrue(minute.timeAgo.contains("分钟前"))
        
        let hour = PartnerActivity(type: .dreamShared, actorId: "1", actorName: "User", createdAt: oneHourAgo)
        XCTAssertTrue(hour.timeAgo.contains("小时前"))
        
        let day = PartnerActivity(type: .dreamShared, actorId: "1", actorName: "User", createdAt: oneDayAgo)
        XCTAssertTrue(day.timeAgo.contains("天前"))
    }
}
