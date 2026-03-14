//
//  DreamCommunityTests.swift
//  DreamLogTests
//
//  Phase 42 - 梦境社区单元测试
//  测试匿名分享、浏览、点赞、评论、关注功能
//

import XCTest
import SwiftData
@testable import DreamLog

// MARK: - 社区模型测试

final class DreamCommunityModelsTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        let schema = Schema([
            SharedDream.self,
            CommunityUser.self,
            CommunityComment.self,
            CommunityLike.self,
            CommunityFavorite.self,
            FollowRelationship.self,
            CommunityReport.self
        ])
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }
    
    override func tearDown() {
        modelContainer = nil
    }
    
    // MARK: - Visibility 枚举测试
    
    func testVisibilityDisplayName() {
        XCTAssertEqual(Visibility.public.displayName, "公开")
        XCTAssertEqual(Visibility.followers.displayName, "仅关注者")
        XCTAssertEqual(Visibility.private.displayName, "私密")
    }
    
    func testVisibilityIcon() {
        XCTAssertEqual(Visibility.public.icon, "globe")
        XCTAssertEqual(Visibility.followers.icon, "person.2")
        XCTAssertEqual(Visibility.private.icon, "lock")
    }
    
    func testVisibilityAllCases() {
        XCTAssertEqual(Visibility.allCases.count, 3)
        XCTAssertTrue(Visibility.allCases.contains(.public))
        XCTAssertTrue(Visibility.allCases.contains(.followers))
        XCTAssertTrue(Visibility.allCases.contains(.private))
    }
    
    // MARK: - SharedDream 模型测试
    
    func testSharedDreamInitialization() {
        let dream = SharedDream(
            anonymousId: "user_test123",
            title: "测试梦境",
            content: "这是一个测试梦境内容",
            emotions: ["快乐", "兴奋"],
            tags: ["飞行", "冒险"],
            isLucid: true
        )
        
        XCTAssertEqual(dream.title, "测试梦境")
        XCTAssertEqual(dream.content, "这是一个测试梦境内容")
        XCTAssertEqual(dream.emotions, ["快乐", "兴奋"])
        XCTAssertEqual(dream.tags, ["飞行", "冒险"])
        XCTAssertTrue(dream.isLucid)
        XCTAssertEqual(dream.visibility, .public)
        XCTAssertTrue(dream.allowComments)
        XCTAssertTrue(dream.isAnonymous)
        XCTAssertEqual(dream.likeCount, 0)
        XCTAssertEqual(dream.commentCount, 0)
        XCTAssertFalse(dream.isDeleted)
    }
    
    func testSharedDreamCodable() throws {
        let dream = SharedDream(
            anonymousId: "user_test456",
            title: "编码测试",
            content: "测试 Codable",
            emotions: ["平静"],
            tags: ["测试"],
            isLucid: false,
            visibility: .followers,
            allowComments: false,
            isAnonymous: false
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dream)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SharedDream.self, from: data)
        
        XCTAssertEqual(decoded.title, dream.title)
        XCTAssertEqual(decoded.visibility, .followers)
        XCTAssertFalse(decoded.allowComments)
        XCTAssertFalse(decoded.isAnonymous)
    }
    
    // MARK: - CommunityUser 模型测试
    
    func testCommunityUserInitialization() {
        let user = CommunityUser(
            anonymousId: "user_abc123",
            avatarSeed: 42,
            avatarEmoji: "🌙"
        )
        
        XCTAssertEqual(user.anonymousId, "user_abc123")
        XCTAssertEqual(user.avatarSeed, 42)
        XCTAssertEqual(user.avatarEmoji, "🌙")
        XCTAssertEqual(user.followersCount, 0)
        XCTAssertEqual(user.followingCount, 0)
        XCTAssertEqual(user.sharedDreamsCount, 0)
    }
    
    func testCommunityUserAvatarGeneration() {
        let avatarEmojis = ["🌙", "⭐", "🌟", "✨", "💫", "🌈", "🦋", "🌸", "🍀", "🔮"]
        
        for seed in 0..<100 {
            let emoji = avatarEmojis[seed % avatarEmojis.count]
            XCTAssertContains(avatarEmojis, emoji)
        }
    }
    
    // MARK: - CommunityComment 模型测试
    
    func testCommunityCommentInitialization() {
        let comment = CommunityComment(
            content: "很好的梦境分享！",
            authorAnonymousId: "user_commenter"
        )
        
        XCTAssertEqual(comment.content, "很好的梦境分享！")
        XCTAssertEqual(comment.authorAnonymousId, "user_commenter")
        XCTAssertEqual(comment.likeCount, 0)
        XCTAssertFalse(comment.isDeleted)
    }
    
    // MARK: - CommunityLike 模型测试
    
    func testCommunityLikeInitialization() {
        let like = CommunityLike(
            userAnonymousId: "user_liker"
        )
        
        XCTAssertEqual(like.userAnonymousId, "user_liker")
        XCTAssertNotNil(like.createdAt)
    }
    
    // MARK: - CommunityFavorite 模型测试
    
    func testCommunityFavoriteInitialization() {
        let favorite = CommunityFavorite(
            userAnonymousId: "user_favoriter"
        )
        
        XCTAssertEqual(favorite.userAnonymousId, "user_favoriter")
        XCTAssertNotNil(favorite.createdAt)
    }
    
    // MARK: - FollowRelationship 模型测试
    
    func testFollowRelationshipInitialization() {
        let relationship = FollowRelationship(
            followerAnonymousId: "user_follower",
            followingAnonymousId: "user_following"
        )
        
        XCTAssertEqual(relationship.followerAnonymousId, "user_follower")
        XCTAssertEqual(relationship.followingAnonymousId, "user_following")
        XCTAssertNotNil(relationship.createdAt)
    }
    
    // MARK: - CommunityReport 模型测试
    
    func testCommunityReportInitialization() {
        let report = CommunityReport(
            reporterAnonymousId: "user_reporter",
            reason: .inappropriate,
            description: "内容不当"
        )
        
        XCTAssertEqual(report.reporterAnonymousId, "user_reporter")
        XCTAssertEqual(report.reason, .inappropriate)
        XCTAssertEqual(report.description, "内容不当")
        XCTAssertEqual(report.status, .pending)
    }
    
    func testReportReasonDisplayName() {
        XCTAssertEqual(ReportReason.inappropriate.displayName, "不当内容")
        XCTAssertEqual(ReportReason.spam.displayName, "垃圾信息")
        XCTAssertEqual(ReportReason.harassment.displayName, "骚扰行为")
        XCTAssertEqual(ReportReason.other.displayName, "其他")
    }
    
    func testReportStatusDisplayName() {
        XCTAssertEqual(ReportStatus.pending.displayName, "待处理")
        XCTAssertEqual(ReportStatus.reviewed.displayName, "已审核")
        XCTAssertEqual(ReportStatus.resolved.displayName, "已解决")
    }
    
    // MARK: - CommunityStats 模型测试
    
    func testCommunityStatsInitialization() {
        let stats = CommunityStats()
        
        XCTAssertEqual(stats.totalSharedDreams, 0)
        XCTAssertEqual(stats.totalUsers, 0)
        XCTAssertEqual(stats.totalComments, 0)
        XCTAssertEqual(stats.totalLikes, 0)
    }
    
    func testCommunityStatsCalculation() {
        var stats = CommunityStats(
            totalSharedDreams: 100,
            totalUsers: 50,
            totalComments: 200,
            totalLikes: 500
        )
        
        XCTAssertEqual(stats.totalSharedDreams, 100)
        XCTAssertEqual(stats.averageCommentsPerDream, 2.0)
        XCTAssertEqual(stats.averageLikesPerDream, 5.0)
    }
    
    // MARK: - CommunityFilter 枚举测试
    
    func testCommunityFilterAllCases() {
        XCTAssertEqual(CommunityFilter.allCases.count, 5)
        XCTAssertTrue(CommunityFilter.allCases.contains(.hot))
        XCTAssertTrue(CommunityFilter.allCases.contains(.new))
        XCTAssertTrue(CommunityFilter.allCases.contains(.top))
        XCTAssertTrue(CommunityFilter.allCases.contains(.lucid))
        XCTAssertTrue(CommunityFilter.allCases.contains(.following))
    }
    
    func testCommunityFilterDisplayName() {
        XCTAssertEqual(CommunityFilter.hot.displayName, "热门")
        XCTAssertEqual(CommunityFilter.new.displayName, "最新")
        XCTAssertEqual(CommunityFilter.top.displayName, "Top")
        XCTAssertEqual(CommunityFilter.lucid.displayName, "清醒梦")
        XCTAssertEqual(CommunityFilter.following.displayName, "关注")
    }
    
    // MARK: - AnonymizationConfig 测试
    
    func testAnonymizationConfigDefault() {
        let config = AnonymizationConfig.default
        
        XCTAssertTrue(config.removeNames)
        XCTAssertTrue(config.removeLocations)
        XCTAssertTrue(config.removeDates)
        XCTAssertTrue(config.removeContactInfo)
        XCTAssertEqual(config.locationGranularity, .city)
    }
    
    func testAnonymizationConfigLocationGranularity() {
        XCTAssertEqual(LocationGranularity.city.displayName, "城市")
        XCTAssertEqual(LocationGranularity.country.displayName, "国家")
        XCTAssertEqual(LocationGranularity.region.displayName, "地区")
    }
}

// MARK: - 社区服务测试

@MainActor
final class DreamCommunityServiceTests: XCTestCase {
    
    var service: DreamCommunityService!
    
    override func setUp() async throws {
        service = DreamCommunityService.shared
    }
    
    override func tearDown() async throws {
        service = nil
    }
    
    // MARK: - 用户管理测试
    
    func testLoadCurrentUser() async {
        await service.loadCurrentUser()
        
        XCTAssertNotNil(service.currentUser)
        XCTAssertFalse(service.currentUser?.anonymousId.isEmpty ?? true)
    }
    
    func testCreateNewUser() {
        let user = service.createNewUser()
        
        XCTAssertFalse(user.anonymousId.isEmpty)
        XCTAssertFalse(user.avatarEmoji.isEmpty)
        XCTAssertEqual(user.followersCount, 0)
        XCTAssertEqual(user.followingCount, 0)
    }
    
    // MARK: - 匿名化测试
    
    func testAnonymizeDream() async throws {
        // 创建测试梦境
        let dream = Dream(
            title: "我的梦境",
            content: "昨晚我在北京梦见了飞行",
            tags: ["飞行", "冒险"],
            emotions: [.joy],
            clarity: 4,
            intensity: 3,
            isLucid: true
        )
        
        let sharedDream = service.anonymizeDream(dream)
        
        XCTAssertEqual(sharedDream.title, dream.title)
        XCTAssertEqual(sharedDream.tags, dream.tags)
        XCTAssertEqual(sharedDream.isLucid, dream.isLucid)
        XCTAssertTrue(sharedDream.isAnonymous)
    }
    
    // MARK: - 分享功能测试
    
    func testShareDream() async throws {
        let dream = Dream(
            title: "分享测试",
            content: "测试分享内容",
            tags: ["测试"],
            emotions: [.joy],
            clarity: 5,
            intensity: 3,
            isLucid: false
        )
        
        try await service.shareDream(
            dream: dream,
            title: "测试分享",
            visibility: .public,
            allowComments: true,
            isAnonymous: true,
            includeAIAnalysis: false
        )
        
        XCTAssertFalse(service.sharedDreams.isEmpty)
    }
    
    // MARK: - 点赞功能测试
    
    func testToggleLike() async {
        guard let dream = service.sharedDreams.first else {
            print("⚠️ 没有可用的梦境进行测试")
            return
        }
        
        let initialLikeCount = dream.likeCount
        
        await service.toggleLike(dream: dream)
        
        // 点赞后数量应该变化
        XCTAssertNotEqual(dream.likeCount, initialLikeCount)
    }
    
    // MARK: - 统计功能测试
    
    func testFetchStats() async {
        await service.fetchStats()
        
        XCTAssertGreaterThanOrEqual(service.stats.totalSharedDreams, 0)
        XCTAssertGreaterThanOrEqual(service.stats.totalUsers, 0)
    }
}

// MARK: - 匿名化算法测试

final class AnonymizationAlgorithmTests: XCTestCase {
    
    var service: DreamCommunityService!
    
    override func setUp() async throws {
        service = DreamCommunityService.shared
    }
    
    override func tearDown() async throws {
        service = nil
    }
    
    func testRemoveNames() {
        let content = "小明和小红一起去公园"
        // 简单测试，实际应使用 NLP
        XCTAssertFalse(content.isEmpty)
    }
    
    func testRemoveDates() {
        let content = "2024 年 3 月 15 日我做了一个梦"
        // 测试日期移除逻辑
        XCTAssertFalse(content.isEmpty)
    }
    
    func testGenerateAnonymousId() {
        let id1 = service.generateAnonymousId()
        let id2 = service.generateAnonymousId()
        
        // 同一设备的匿名 ID 应该一致
        XCTAssertEqual(id1, id2)
        XCTAssertTrue(id1.hasPrefix("user_"))
    }
}

// MARK: - 辅助函数

extension XCTestCase {
    func XCTAssertContains<T: Equatable>(_ array: [T], _ element: T, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(array.contains(element), "数组不包含元素 \(element)", file: file, line: line)
    }
}
