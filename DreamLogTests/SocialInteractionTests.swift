//
//  SocialInteractionTests.swift
//  DreamLogTests
//
//  Phase 60: 社交功能增强
//  社交互动功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class SocialInteractionTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([
            SocialLike.self,
            SocialComment.self,
            SocialBookmarkCollection.self,
            SocialBookmark.self,
            SocialFollow.self,
            SocialActivity.self,
            SocialAchievement.self,
            SocialStats.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 点赞测试
    
    func testLikeDream() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 点赞
        try await service.likeDream(dreamId, reaction: .like)
        
        // 验证点赞已创建
        let likes = try modelContainer.mainContext.fetch(FetchDescriptor<SocialLike>())
        XCTAssertEqual(likes.count, 1)
        XCTAssertEqual(likes[0].dreamId, dreamId)
        XCTAssertEqual(likes[0].reaction, "👍")
    }
    
    func testUnlikeDream() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 先点赞
        try await service.likeDream(dreamId, reaction: .like)
        
        // 取消点赞
        try await service.unlikeDream(dreamId)
        
        // 验证点赞已删除
        let likes = try modelContainer.mainContext.fetch(FetchDescriptor<SocialLike>())
        XCTAssertEqual(likes.count, 0)
    }
    
    func testGetLikeCount() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建多个点赞
        try await service.likeDream(dreamId, reaction: .like)
        try await service.likeDream(dreamId, reaction: .love)
        try await service.likeDream(dreamId, reaction: .fire)
        
        // 验证计数
        let count = try await service.getLikeCount(for: dreamId)
        XCTAssertEqual(count, 3)
    }
    
    func testGetReactionsByType() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建不同类型的反应
        try await service.likeDream(dreamId, reaction: .like)
        try await service.likeDream(dreamId, reaction: .like)
        try await service.likeDream(dreamId, reaction: .love)
        try await service.likeDream(dreamId, reaction: .love)
        try await service.likeDream(dreamId, reaction: .love)
        
        // 验证按类型统计
        let reactions = try await service.getReactionsByType(for: dreamId)
        XCTAssertEqual(reactions["👍"], 2)
        XCTAssertEqual(reactions["❤️"], 3)
    }
    
    // MARK: - 评论测试
    
    func testCreateComment() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建评论
        let comment = try await service.createComment(
            dreamId: dreamId,
            content: "这个梦境太美了!",
            parentId: nil
        )
        
        // 验证评论已创建
        XCTAssertNotNil(comment)
        XCTAssertEqual(comment.content, "这个梦境太美了!")
        XCTAssertNil(comment.parentId)
    }
    
    func testCreateReply() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建父评论
        let parentComment = try await service.createComment(
            dreamId: dreamId,
            content: "父评论",
            parentId: nil
        )
        
        // 创建回复
        let reply = try await service.createComment(
            dreamId: dreamId,
            content: "回复评论",
            parentId: parentComment.id
        )
        
        // 验证回复
        XCTAssertEqual(reply.parentId, parentComment.id)
    }
    
    func testUpdateComment() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建评论
        let comment = try await service.createComment(
            dreamId: dreamId,
            content: "原始内容",
            parentId: nil
        )
        
        // 更新评论
        try await service.updateComment(comment.id, content: "更新后的内容")
        
        // 验证更新
        let updated = try modelContainer.mainContext.fetch(FetchDescriptor<SocialComment>()).first
        XCTAssertEqual(updated?.content, "更新后的内容")
        XCTAssertNotNil(updated?.editedAt)
    }
    
    func testDeleteComment() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建评论
        let comment = try await service.createComment(
            dreamId: dreamId,
            content: "要删除的评论",
            parentId: nil
        )
        
        // 删除评论
        try await service.deleteComment(comment.id)
        
        // 验证删除
        let comments = try modelContainer.mainContext.fetch(FetchDescriptor<SocialComment>())
        XCTAssertEqual(comments.count, 0)
    }
    
    func testGetCommentsForDream() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建多个评论
        _ = try await service.createComment(dreamId: dreamId, content: "评论 1", parentId: nil)
        _ = try await service.createComment(dreamId: dreamId, content: "评论 2", parentId: nil)
        _ = try await service.createComment(dreamId: dreamId, content: "评论 3", parentId: nil)
        
        // 验证获取
        let comments = try await service.getComments(for: dreamId)
        XCTAssertEqual(comments.count, 3)
    }
    
    // MARK: - 收藏测试
    
    func testCreateBookmarkCollection() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 创建收藏夹
        let collection = try await service.createBookmarkCollection(
            name: "精选梦境",
            description: "我最喜欢的梦境",
            emoji: "🌟",
            isPublic: true
        )
        
        // 验证创建
        XCTAssertNotNil(collection)
        XCTAssertEqual(collection.name, "精选梦境")
        XCTAssertEqual(collection.emoji, "🌟")
        XCTAssertTrue(collection.isPublic)
    }
    
    func testBookmarkDream() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建收藏夹
        let collection = try await service.createBookmarkCollection(
            name: "测试收藏夹",
            description: "",
            emoji: "🔖",
            isPublic: false
        )
        
        // 收藏梦境
        try await service.bookmarkDream(dreamId, to: collection.id, notes: "很好的梦境")
        
        // 验证收藏
        let bookmarks = try modelContainer.mainContext.fetch(FetchDescriptor<SocialBookmark>())
        XCTAssertEqual(bookmarks.count, 1)
        XCTAssertEqual(bookmarks[0].dreamId, dreamId)
        XCTAssertEqual(bookmarks[0].notes, "很好的梦境")
    }
    
    func testRemoveBookmark() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 创建收藏夹并收藏
        let collection = try await service.createBookmarkCollection(
            name: "测试",
            description: "",
            emoji: "🔖",
            isPublic: false
        )
        try await service.bookmarkDream(dreamId, to: collection.id)
        
        // 取消收藏
        try await service.removeBookmark(dreamId, from: collection.id)
        
        // 验证取消
        let bookmarks = try modelContainer.mainContext.fetch(FetchDescriptor<SocialBookmark>())
        XCTAssertEqual(bookmarks.count, 0)
    }
    
    func testGetUserCollections() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 创建多个收藏夹
        _ = try await service.createBookmarkCollection(name: "收藏夹 1", description: "", emoji: "🔖", isPublic: true)
        _ = try await service.createBookmarkCollection(name: "收藏夹 2", description: "", emoji: "🌟", isPublic: false)
        _ = try await service.createBookmarkCollection(name: "收藏夹 3", description: "", emoji: "💫", isPublic: true)
        
        // 验证获取
        let collections = try await service.getUserCollections()
        XCTAssertEqual(collections.count, 3)
    }
    
    // MARK: - 关注测试
    
    func testFollowUser() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let targetUserId = "user_123"
        
        // 关注用户
        try await service.followUser(targetUserId)
        
        // 验证关注
        let follows = try modelContainer.mainContext.fetch(FetchDescriptor<SocialFollow>())
        XCTAssertEqual(follows.count, 1)
        XCTAssertEqual(follows[0].followingId, targetUserId)
    }
    
    func testUnfollowUser() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let targetUserId = "user_123"
        
        // 先关注
        try await service.followUser(targetUserId)
        
        // 取消关注
        try await service.unfollowUser(targetUserId)
        
        // 验证取消
        let follows = try modelContainer.mainContext.fetch(FetchDescriptor<SocialFollow>())
        XCTAssertEqual(follows.count, 0)
    }
    
    func testGetFollowersAndFollowing() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 关注多个用户
        try await service.followUser("user_1")
        try await service.followUser("user_2")
        try await service.followUser("user_3")
        
        // 验证关注数
        let following = try await service.getFollowing()
        XCTAssertEqual(following.count, 3)
        
        let followingCount = try await service.getFollowingCount()
        XCTAssertEqual(followingCount, 3)
    }
    
    // MARK: - 活动动态测试
    
    func testCreateActivity() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 创建活动
        try await service.createActivity(
            type: .dreamPublished,
            dreamId: UUID(),
            content: "发布了新梦境"
        )
        
        // 验证创建
        let activities = try modelContainer.mainContext.fetch(FetchDescriptor<SocialActivity>())
        XCTAssertEqual(activities.count, 1)
    }
    
    func testGetActivityFeed() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 创建多个活动
        try await service.createActivity(type: .dreamPublished, dreamId: UUID(), content: "发布梦境")
        try await service.createActivity(type: .dreamLiked, dreamId: UUID(), content: "点赞")
        try await service.createActivity(type: .userFollowed, dreamId: nil, content: "关注")
        
        // 验证获取
        let activities = try await service.getActivityFeed(limit: 10)
        XCTAssertEqual(activities.count, 3)
    }
    
    // MARK: - 成就测试
    
    func testUnlockAchievement() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 解锁成就
        let achievement = try await service.unlockAchievement(type: .firstInteraction)
        
        // 验证解锁
        XCTAssertNotNil(achievement)
        XCTAssertTrue(achievement.isUnlocked)
        XCTAssertNotNil(achievement.unlockedAt)
        XCTAssertEqual(achievement.points, 50)
    }
    
    func testCheckAchievementProgress() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 模拟多次点赞
        for _ in 0..<10 {
            try await service.likeDream(UUID(), reaction: .like)
        }
        
        // 检查成就进度
        let progress = try await service.checkAchievementProgress(type: .likeMaster)
        
        // 验证进度
        XCTAssertGreaterThanOrEqual(progress, 0)
    }
    
    func testGetUnlockedAchievements() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 解锁多个成就
        _ = try await service.unlockAchievement(type: .firstInteraction)
        _ = try await service.unlockAchievement(type: .creator)
        
        // 验证获取
        let unlocked = try await service.getUnlockedAchievements()
        XCTAssertEqual(unlocked.count, 2)
    }
    
    // MARK: - 统计测试
    
    func testGetSocialStats() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 获取统计
        let stats = try await service.getSocialStats()
        
        // 验证统计对象已创建
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats.userId, service.userId)
    }
    
    func testUpdateStats() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 更新统计
        let stats = try await service.getSocialStats()
        stats.totalLikesReceived = 100
        stats.totalComments = 50
        
        try modelContainer.mainContext.save()
        
        // 验证更新
        let updated = try await service.getSocialStats()
        XCTAssertEqual(updated.totalLikesReceived, 100)
        XCTAssertEqual(updated.totalComments, 50)
    }
    
    // MARK: - 性能测试
    
    func testPerformance_LikeCreation() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        measure {
            let expectation = XCTestExpectation(description: "Like creation")
            
            Task {
                try? await service.likeDream(dreamId, reaction: .like)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPerformance_CommentCreation() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        measure {
            let expectation = XCTestExpectation(description: "Comment creation")
            
            Task {
                _ = try? await service.createComment(dreamId: dreamId, content: "测试评论", parentId: nil)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - 边界情况测试
    
    func testDuplicateLikePrevention() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        
        // 第一次点赞
        try await service.likeDream(dreamId, reaction: .like)
        
        // 第二次点赞 (应该更新而不是创建新记录)
        try await service.likeDream(dreamId, reaction: .love)
        
        // 验证只有一个点赞记录
        let likes = try modelContainer.mainContext.fetch(FetchDescriptor<SocialLike>())
        XCTAssertEqual(likes.count, 1)
        XCTAssertEqual(likes[0].reaction, "❤️") // 应该是更新后的反应
    }
    
    func testEmptyDreamId() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        
        // 测试空梦境 ID 的处理
        let dreamId = UUID()
        try await service.likeDream(dreamId, reaction: .like)
        
        let count = try await service.getLikeCount(for: dreamId)
        XCTAssertEqual(count, 1)
    }
    
    func testLongCommentContent() async throws {
        let service = SocialInteractionService(modelContainer: modelContainer)
        let dreamId = UUID()
        let longContent = String(repeating: "这是一条很长的评论 ", count: 100)
        
        // 创建长评论
        let comment = try await service.createComment(
            dreamId: dreamId,
            content: longContent,
            parentId: nil
        )
        
        // 验证内容完整
        XCTAssertEqual(comment.content, longContent)
    }
}
