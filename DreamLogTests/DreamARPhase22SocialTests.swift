//
//  DreamARPhase22SocialTests.swift
//  DreamLog - Phase 22: AR Enhancement & 3D Dream World
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
@testable import DreamLog

final class DreamARPhase22SocialTests: XCTestCase {
    
    var shareService: DreamARShareService!
    var socialService: DreamARSocialService!
    
    override func setUp() async throws {
        try await super.setUp()
        shareService = DreamARShareService.shared
        socialService = DreamARSocialService.shared
    }
    
    override func tearDown() async throws {
        shareService = nil
        socialService = nil
        try await super.tearDown()
    }
    
    // MARK: - Share Service Tests
    
    func testShareService_Singleton() {
        let service1 = DreamARShareService.shared
        let service2 = DreamARShareService.shared
        XCTAssertEqual(service1, service2, "ShareService 应该是单例")
    }
    
    func testShareService_InitialState() {
        XCTAssertFalse(shareService.isHost)
        XCTAssertFalse(shareService.isConnected)
        XCTAssertEqual(shareService.participantCount, 1)
        XCTAssertNil(shareService.shareCode)
        XCTAssertFalse(shareService.isSharing)
        XCTAssertEqual(shareService.syncStatus, .idle)
    }
    
    func testShareService_GenerateShareCode() {
        shareService.startHosting(sceneData: Data())
        
        XCTAssertNotNil(shareService.shareCode)
        XCTAssertEqual(shareService.shareCode?.count, 6, "分享码应该是 6 位")
        
        // 验证分享码只包含有效字符
        let validChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        for char in shareService.shareCode ?? "" {
            XCTAssertTrue(validChars.contains(char), "分享码包含无效字符：\(char)")
        }
    }
    
    func testShareService_StartHosting() {
        let testData = "Test Scene Data".data(using: .utf8)!
        shareService.startHosting(sceneData: testData)
        
        XCTAssertTrue(shareService.isHost)
        XCTAssertTrue(shareService.isSharing)
        XCTAssertNotNil(shareService.shareCode)
        XCTAssertEqual(shareService.participantCount, 1)
    }
    
    func testShareService_StopHosting() {
        shareService.startHosting(sceneData: Data())
        shareService.stopHosting()
        
        XCTAssertFalse(shareService.isHost)
        XCTAssertFalse(shareService.isSharing)
        XCTAssertNil(shareService.shareCode)
        XCTAssertEqual(shareService.participantCount, 1)
        XCTAssertEqual(shareService.syncStatus, .idle)
    }
    
    func testShareService_SyncStatus() {
        XCTAssertEqual(shareService.syncStatus, .idle)
        
        // 测试状态描述
        XCTAssertEqual(SyncStatus.idle.description, "未同步")
        XCTAssertEqual(SyncStatus.syncing.description, "同步中...")
        XCTAssertEqual(SyncStatus.synced.description, "已同步")
        XCTAssertEqual(SyncStatus.failed.description, "同步失败")
        
        // 测试状态图标
        XCTAssertEqual(SyncStatus.idle.icon, "circle")
        XCTAssertEqual(SyncStatus.syncing.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(SyncStatus.synced.icon, "checkmark.circle.fill")
        XCTAssertEqual(SyncStatus.failed.icon, "exclamationmark.circle.fill")
    }
    
    // MARK: - Social Service Tests
    
    func testSocialService_Singleton() {
        let service1 = DreamARSocialService.shared
        let service2 = DreamARSocialService.shared
        XCTAssertEqual(service1, service2, "SocialService 应该是单例")
    }
    
    func testSocialService_LikeScene() {
        let sceneId = "test_scene_001"
        
        // 初始未点赞
        XCTAssertFalse(socialService.isLiked(sceneId))
        
        // 点赞
        socialService.likeScene(sceneId)
        XCTAssertTrue(socialService.isLiked(sceneId))
        
        // 取消点赞
        socialService.likeScene(sceneId)
        XCTAssertFalse(socialService.isLiked(sceneId))
    }
    
    func testSocialService_FavoriteScene() {
        let sceneId = "test_scene_002"
        
        // 初始未收藏
        XCTAssertFalse(socialService.isFavorited(sceneId))
        
        // 收藏
        socialService.favoriteScene(sceneId)
        XCTAssertTrue(socialService.isFavorited(sceneId))
        
        // 取消收藏
        socialService.favoriteScene(sceneId)
        XCTAssertFalse(socialService.isFavorited(sceneId))
    }
    
    func testSocialService_GetFavoritedScenes() {
        let sceneId1 = "test_scene_003"
        let sceneId2 = "test_scene_004"
        
        socialService.favoriteScene(sceneId1)
        socialService.favoriteScene(sceneId2)
        
        let favorited = socialService.getFavoritedScenes()
        XCTAssertEqual(favorited.count, 2)
        XCTAssertTrue(favorited.contains(sceneId1))
        XCTAssertTrue(favorited.contains(sceneId2))
    }
    
    func testSocialService_ViewHistory() {
        let sceneId1 = "test_scene_005"
        let sceneId2 = "test_scene_006"
        let sceneId3 = "test_scene_007"
        
        // 记录浏览历史
        socialService.recordView(sceneId1)
        socialService.recordView(sceneId2)
        socialService.recordView(sceneId3)
        
        let history = socialService.getViewHistory()
        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0], sceneId3, "最近浏览的应该在最前面")
        XCTAssertEqual(history[1], sceneId2)
        XCTAssertEqual(history[2], sceneId1)
        
        // 重复浏览应该移到前面
        socialService.recordView(sceneId1)
        let updatedHistory = socialService.getViewHistory()
        XCTAssertEqual(updatedHistory[0], sceneId1)
    }
    
    func testSocialService_ClearViewHistory() {
        socialService.recordView("test_scene_008")
        socialService.recordView("test_scene_009")
        
        XCTAssertEqual(socialService.getViewHistory().count, 2)
        
        socialService.clearViewHistory()
        XCTAssertEqual(socialService.getViewHistory().count, 0)
    }
    
    func testSocialService_AddComment() {
        let comment = ARComment(
            id: UUID(),
            sceneId: "test_scene_010",
            userId: "user_001",
            userName: "TestUser",
            content: "这是一个测试评论",
            likeCount: 0,
            createdAt: Date(),
            replies: []
        )
        
        let initialCount = socialService.myComments.count
        socialService.addComment(comment)
        XCTAssertEqual(socialService.myComments.count, initialCount + 1)
    }
    
    func testSocialService_DeleteComment() {
        let commentId = UUID()
        let comment = ARComment(
            id: commentId,
            sceneId: "test_scene_011",
            userId: "user_002",
            userName: "TestUser2",
            content: "测试评论",
            likeCount: 0,
            createdAt: Date(),
            replies: []
        )
        
        socialService.addComment(comment)
        XCTAssertTrue(socialService.myComments.contains { $0.id == commentId })
        
        socialService.deleteComment(commentId)
        XCTAssertFalse(socialService.myComments.contains { $0.id == commentId })
    }
    
    func testSocialService_GetComments() {
        let sceneId = "test_scene_012"
        let comments = socialService.getComments(for: sceneId)
        
        XCTAssertGreaterThan(comments.count, 0, "应该返回模拟评论数据")
    }
    
    func testSocialService_TrendingScenes() {
        let trending = socialService.getTrendingScenes(limit: 5)
        
        XCTAssertLessThanOrEqual(trending.count, 5)
        
        // 验证按点赞数排序
        for i in 0..<(trending.count - 1) {
            XCTAssertGreaterThanOrEqual(trending[i].likeCount, trending[i + 1].likeCount)
        }
    }
    
    func testSocialService_RecommendedScenes() {
        let recommended = socialService.getRecommendedScenes(limit: 5)
        
        XCTAssertLessThanOrEqual(recommended.count, 5)
    }
    
    func testSocialService_GenerateShareLink() {
        let sceneId = "test_scene_013"
        let url = socialService.generateShareLink(for: sceneId)
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains(sceneId) ?? false)
    }
    
    func testSocialService_GenerateShareCode() {
        let sceneId = "test_scene_014"
        let code = socialService.generateShareCode(for: sceneId)
        
        XCTAssertEqual(code.count, 8, "分享码应该是 8 位")
        
        // 验证分享码只包含有效字符
        let validChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        for char in code {
            XCTAssertTrue(validChars.contains(char), "分享码包含无效字符：\(char)")
        }
    }
    
    func testSocialSceneMetadata_FormattedCounts() {
        let scene = ARSceneMetadata(
            id: "test",
            title: "Test Scene",
            creator: "Tester",
            likeCount: 1500,
            viewCount: 2500000,
            commentCount: 100,
            category: .starry,
            thumbnail: "star.fill",
            createdAt: Date()
        )
        
        XCTAssertEqual(scene.formattedLikeCount, "1.5K")
        XCTAssertEqual(scene.formattedViewCount, "2500.0K")
    }
    
    func testARComment_FormattedTime() {
        let comment = ARComment(
            id: UUID(),
            sceneId: "test",
            userId: "user",
            userName: "User",
            content: "Test",
            likeCount: 0,
            createdAt: Date().addingTimeInterval(-3600), // 1 小时前
            replies: []
        )
        
        XCTAssertFalse(comment.formattedTime.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_LikeScene() {
        measure {
            for i in 0..<100 {
                socialService.likeScene("scene_\(i)")
            }
        }
    }
    
    func testPerformance_ViewHistory() {
        measure {
            for i in 0..<100 {
                socialService.recordView("scene_\(i)")
            }
        }
    }
}
