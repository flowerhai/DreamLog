//
//  SocialInteractionService.swift
//  DreamLog
//
//  Phase 60: 社交功能增强
//  社交互动核心服务：点赞、评论、收藏、关注、活动动态、成就系统
//

import Foundation
import SwiftData
import UserNotifications

/// 社交互动服务 (Actor 并发安全)
@ModelActor
actor SocialInteractionService {
    
    // MARK: - 单例
    
    static let shared = SocialInteractionService(modelContainer: ModelContainer.shared)
    
    // MARK: - 属性
    
    private let userId: String
    private var currentUserName: String = "匿名用户"
    
    // 回调闭包
    var onLikesChanged: ((UUID) -> Void)? // 梦境点赞变化
    var onCommentsChanged: ((UUID) -> Void)? // 梦境评论变化
    var onBookmarksChanged: (() -> Void)? // 收藏变化
    var onFollowsChanged: (() -> Void)? // 关注变化
    var onAchievementUnlocked: ((SocialAchievement) -> Void)? // 成就解锁
    
    // MARK: - 初始化
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.userId = UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
        self.currentUserName = UserDefaults.standard.string(forKey: "userName") ?? "匿名用户"
    }
    
    // MARK: - 点赞管理
    
    /// 点赞梦境
    func likeDream(_ dreamId: UUID, reaction: ReactionType = .like) async throws {
        // 检查是否已点赞
        let existing = try modelContext.fetch(
            FetchDescriptor<SocialLike>(
                predicate: #Predicate { $0.dreamId == dreamId && $0.userId == userId }
            )
        ).first
        
        if let existing = existing {
            // 更新反应类型
            existing.reaction = reaction.rawValue
        } else {
            // 创建新点赞
            let like = SocialLike(dreamId: dreamId, userId: userId, reaction: reaction)
            modelContext.insert(like)
            
            // 创建活动动态
            await createActivity(
                type: .dreamLiked,
                dreamId: dreamId,
                content: "\(currentUserName) 点赞了梦境"
            )
        }
        
        try modelContext.save()
        
        // 更新统计
        try await updateLikeStats(dreamId: dreamId)
        
        // 通知监听者
        onLikesChanged?(dreamId)
    }
    
    /// 取消点赞
    func unlikeDream(_ dreamId: UUID) async throws {
        let likes = try modelContext.fetch(
            FetchDescriptor<SocialLike>(
                predicate: #Predicate { $0.dreamId == dreamId && $0.userId == userId }
            )
        )
        
        for like in likes {
            modelContext.delete(like)
        }
        
        try modelContext.save()
        
        // 更新统计
        try await updateLikeStats(dreamId: dreamId)
        
        // 通知监听者
        onLikesChanged?(dreamId)
    }
    
    /// 获取梦境点赞数
    func getLikeCount(for dreamId: UUID) async throws -> Int {
        try modelContext.fetch(
            FetchDescriptor<SocialLike>(
                predicate: #Predicate { $0.dreamId == dreamId }
            )
        ).count
    }
    
    /// 获取梦境点赞详情
    func getLikes(for dreamId: UUID, limit: Int = 50) async throws -> [SocialLike] {
        var descriptor = FetchDescriptor<SocialLike>(
            predicate: #Predicate { $0.dreamId == dreamId }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 检查用户是否已点赞
    func isLiked(_ dreamId: UUID) async throws -> Bool {
        try modelContext.fetch(
            FetchDescriptor<SocialLike>(
                predicate: #Predicate { $0.dreamId == dreamId && $0.userId == userId }
            )
        ).first != nil
    }
    
    /// 获取用户的点赞历史
    func getUserLikes(limit: Int = 100) async throws -> [SocialLike] {
        var descriptor = FetchDescriptor<SocialLike>(
            predicate: #Predicate { $0.userId == userId }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - 评论管理
    
    /// 发布评论
    func postComment(
        dreamId: UUID,
        content: String,
        parentId: UUID? = nil,
        isAuthor: Bool = false
    ) async throws -> SocialComment {
        let comment = SocialComment(
            dreamId: dreamId,
            userId: userId,
            userName: currentUserName,
            content: content,
            parentId: parentId,
            isAuthor: isAuthor
        )
        
        modelContext.insert(comment)
        try modelContext.save()
        
        // 更新父评论的回复数
        if let parentId = parentId {
            if let parent = try modelContext.fetch(
                FetchDescriptor<SocialComment>(
                    predicate: #Predicate { $0.id == parentId }
                )
            ).first {
                parent.replyCount += 1
                try modelContext.save()
            }
        }
        
        // 创建活动动态 (仅顶级评论)
        if parentId == nil {
            await createActivity(
                type: .dreamCommented,
                dreamId: dreamId,
                content: "\(currentUserName) 评论了梦境"
            )
        }
        
        // 更新统计
        try await updateCommentStats()
        
        // 通知监听者
        onCommentsChanged?(dreamId)
        
        // 检查成就
        try await checkCommentAchievement()
        
        return comment
    }
    
    /// 编辑评论
    func editComment(_ commentId: UUID, content: String) async throws {
        guard let comment = try modelContext.fetch(
            FetchDescriptor<SocialComment>(
                predicate: #Predicate { $0.id == commentId && $0.userId == userId }
            )
        ).first else {
            throw NSError(domain: "Comment not found", code: 404)
        }
        
        guard comment.isEditable else {
            throw NSError(domain: "Comment can only be edited within 24 hours", code: 400)
        }
        
        comment.content = content
        comment.isEdited = true
        comment.editedAt = Date()
        
        try modelContext.save()
    }
    
    /// 删除评论
    func deleteComment(_ commentId: UUID) async throws {
        guard let comment = try modelContext.fetch(
            FetchDescriptor<SocialComment>(
                predicate: #Predicate { $0.id == commentId && $0.userId == userId }
            )
        ).first else {
            throw NSError(domain: "Comment not found", code: 404)
        }
        
        // 删除所有回复
        if let replies = comment.replies {
            for reply in replies {
                modelContext.delete(reply)
            }
        }
        
        // 更新父评论的回复数
        if let parentId = comment.parentId {
            if let parent = try modelContext.fetch(
                FetchDescriptor<SocialComment>(
                    predicate: #Predicate { $0.id == parentId }
                )
            ).first {
                parent.replyCount = max(0, parent.replyCount - 1)
            }
        }
        
        modelContext.delete(comment)
        try modelContext.save()
        
        // 更新统计
        try await updateCommentStats()
        
        // 通知监听者
        onCommentsChanged?(comment.dreamId)
    }
    
    /// 获取梦境评论
    func getComments(for dreamId: UUID, limit: Int = 100) async throws -> [SocialComment] {
        var descriptor = FetchDescriptor<SocialComment>(
            predicate: #Predicate { $0.dreamId == dreamId && $0.parentId == nil }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取评论的回复
    func getReplies(for commentId: UUID) async throws -> [SocialComment] {
        try modelContext.fetch(
            FetchDescriptor<SocialComment>(
                predicate: #Predicate { $0.parentId == commentId }
            )
        ).sorted { $0.createdAt < $1.createdAt }
    }
    
    /// 点赞评论
    func likeComment(_ commentId: UUID) async throws {
        let like = CommentLike(commentId: commentId, userId: userId)
        modelContext.insert(like)
        
        if let comment = try modelContext.fetch(
            FetchDescriptor<SocialComment>(
                predicate: #Predicate { $0.id == commentId }
            )
        ).first {
            comment.likes += 1
            try modelContext.save()
        }
    }
    
    /// 获取评论数
    func getCommentCount(for dreamId: UUID) async throws -> Int {
        try modelContext.fetch(
            FetchDescriptor<SocialComment>(
                predicate: #Predicate { $0.dreamId == dreamId && $0.parentId == nil }
            )
        ).count
    }
    
    // MARK: - 收藏管理
    
    /// 创建收藏夹
    func createBookmarkCollection(
        name: String,
        description: String = "",
        emoji: String = "🔖",
        isPublic: Bool = true
    ) async throws -> SocialBookmarkCollection {
        let collection = SocialBookmarkCollection(
            name: name,
            description: description,
            emoji: emoji,
            isPublic: isPublic
        )
        modelContext.insert(collection)
        try modelContext.save()
        return collection
    }
    
    /// 收藏梦境到收藏夹
    func bookmarkDream(
        dreamId: UUID,
        dreamTitle: String,
        dreamPreview: String,
        dreamAuthorId: String,
        dreamAuthorName: String,
        to collectionId: UUID,
        notes: String? = nil
    ) async throws {
        // 检查是否已收藏
        let existing = try modelContext.fetch(
            FetchDescriptor<SocialBookmark>(
                predicate: #Predicate { $0.dreamId == dreamId && $0.collectionId == collectionId }
            )
        ).first
        
        guard existing == nil else {
            return // 已收藏
        }
        
        let bookmark = SocialBookmark(
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            dreamPreview: dreamPreview,
            dreamAuthorId: dreamAuthorId,
            dreamAuthorName: dreamAuthorName,
            collectionId: collectionId,
            notes: notes
        )
        
        modelContext.insert(bookmark)
        
        // 更新收藏夹统计
        if let collection = try modelContext.fetch(
            FetchDescriptor<SocialBookmarkCollection>(
                predicate: #Predicate { $0.id == collectionId }
            )
        ).first {
            collection.updateStats()
            try modelContext.save()
        }
        
        // 创建活动动态
        await createActivity(
            type: .dreamBookmarked,
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            content: "\(currentUserName) 收藏了梦境"
        )
        
        try modelContext.save()
        
        // 更新统计
        try await updateBookmarkStats()
        
        // 通知监听者
        onBookmarksChanged?()
        
        // 检查成就
        try await checkBookmarkAchievement()
    }
    
    /// 取消收藏
    func removeBookmark(_ dreamId: UUID, from collectionId: UUID) async throws {
        let bookmarks = try modelContext.fetch(
            FetchDescriptor<SocialBookmark>(
                predicate: #Predicate { $0.dreamId == dreamId && $0.collectionId == collectionId }
            )
        )
        
        for bookmark in bookmarks {
            modelContext.delete(bookmark)
        }
        
        // 更新收藏夹统计
        if let collection = try modelContext.fetch(
            FetchDescriptor<SocialBookmarkCollection>(
                predicate: #Predicate { $0.id == collectionId }
            )
        ).first {
            collection.updateStats()
            try modelContext.save()
        }
        
        try modelContext.save()
        
        // 更新统计
        try await updateBookmarkStats()
        
        // 通知监听者
        onBookmarksChanged?()
    }
    
    /// 获取收藏夹列表
    func getBookmarkCollections() async throws -> [SocialBookmarkCollection] {
        var descriptor = FetchDescriptor<SocialBookmarkCollection>()
        descriptor.sortBy = [SortDescriptor(\.updatedAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取收藏夹中的梦境
    func getBookmarks(in collectionId: UUID) async throws -> [SocialBookmark] {
        var descriptor = FetchDescriptor<SocialBookmark>(
            predicate: #Predicate { $0.collectionId == collectionId }
        )
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 更新收藏夹
    func updateCollection(
        _ collectionId: UUID,
        name: String? = nil,
        description: String? = nil,
        emoji: String? = nil,
        isPublic: Bool? = nil
    ) async throws {
        guard let collection = try modelContext.fetch(
            FetchDescriptor<SocialBookmarkCollection>(
                predicate: #Predicate { $0.id == collectionId }
            )
        ).first else {
            throw NSError(domain: "Collection not found", code: 404)
        }
        
        if let name = name { collection.name = name }
        if let description = description { collection.description = description }
        if let emoji = emoji { collection.emoji = emoji }
        if let isPublic = isPublic { collection.isPublic = isPublic }
        
        try modelContext.save()
    }
    
    /// 删除收藏夹
    func deleteCollection(_ collectionId: UUID) async throws {
        guard let collection = try modelContext.fetch(
            FetchDescriptor<SocialBookmarkCollection>(
                predicate: #Predicate { $0.id == collectionId }
            )
        ).first else {
            throw NSError(domain: "Collection not found", code: 404)
        }
        
        modelContext.delete(collection)
        try modelContext.save()
        
        onBookmarksChanged?()
    }
    
    /// 获取收藏总数
    func getTotalBookmarkCount() async throws -> Int {
        try modelContext.fetch(FetchDescriptor<SocialBookmark>()).count
    }
    
    // MARK: - 关注管理
    
    /// 关注用户
    func followUser(_ targetUserId: String, targetUserName: String, group: FollowGroup = .friends) async throws {
        // 检查是否已关注
        let existing = try modelContext.fetch(
            FetchDescriptor<SocialFollow>(
                predicate: #Predicate { $0.followerId == userId && $0.followingId == targetUserId }
            )
        ).first
        
        guard existing == nil else {
            return // 已关注
        }
        
        let follow = SocialFollow(
            followerId: userId,
            followerName: currentUserName,
            followingId: targetUserId,
            followingName: targetUserName,
            group: group
        )
        
        modelContext.insert(follow)
        
        // 检查是否互相关注
        let mutualFollow = try modelContext.fetch(
            FetchDescriptor<SocialFollow>(
                predicate: #Predicate { $0.followerId == targetUserId && $0.followingId == userId }
            )
        ).first
        
        if mutualFollow != nil {
            follow.isMutual = true
            mutualFollow?.isMutual = true
        }
        
        // 创建活动动态
        await createActivity(
            type: .userFollowed,
            targetUserId: targetUserId,
            targetUserName: targetUserName,
            content: "\(currentUserName) 关注了 \(targetUserName)"
        )
        
        try modelContext.save()
        
        // 更新统计
        try await updateFollowStats()
        
        // 通知监听者
        onFollowsChanged?()
    }
    
    /// 取消关注
    func unfollowUser(_ targetUserId: String) async throws {
        let follows = try modelContext.fetch(
            FetchDescriptor<SocialFollow>(
                predicate: #Predicate { $0.followerId == userId && $0.followingId == targetUserId }
            )
        )
        
        for follow in follows {
            // 更新互相关注状态
            if follow.isMutual {
                if let mutualFollow = try modelContext.fetch(
                    FetchDescriptor<SocialFollow>(
                        predicate: #Predicate { $0.followerId == targetUserId && $0.followingId == userId }
                    )
                ).first {
                    mutualFollow.isMutual = false
                }
            }
            
            modelContext.delete(follow)
        }
        
        try modelContext.save()
        
        // 更新统计
        try await updateFollowStats()
        
        // 通知监听者
        onFollowsChanged?()
    }
    
    /// 获取关注列表
    func getFollowing(limit: Int = 100) async throws -> [SocialFollow] {
        var descriptor = FetchDescriptor<SocialFollow>(
            predicate: #Predicate { $0.followerId == userId }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取粉丝列表
    func getFollowers(limit: Int = 100) async throws -> [SocialFollow] {
        var descriptor = FetchDescriptor<SocialFollow>(
            predicate: #Predicate { $0.followingId == userId }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 检查是否关注
    func isFollowing(_ targetUserId: String) async throws -> Bool {
        try modelContext.fetch(
            FetchDescriptor<SocialFollow>(
                predicate: #Predicate { $0.followerId == userId && $0.followingId == targetUserId }
            )
        ).first != nil
    }
    
    /// 获取关注数
    func getFollowingCount() async throws -> Int {
        try modelContext.fetch(
            FetchDescriptor<SocialFollow>(
                predicate: #Predicate { $0.followerId == userId }
            )
        ).count
    }
    
    /// 获取粉丝数
    func getFollowerCount() async throws -> Int {
        try modelContext.fetch(
            FetchDescriptor<SocialFollow>(
                predicate: #Predicate { $0.followingId == userId }
            )
        ).count
    }
    
    // MARK: - 活动动态
    
    /// 创建活动动态
    private func createActivity(
        type: ActivityType,
        dreamId: UUID? = nil,
        dreamTitle: String? = nil,
        dreamPreview: String? = nil,
        targetUserId: String? = nil,
        targetUserName: String? = nil,
        content: String
    ) async {
        let activity = SocialActivity(
            type: type,
            userId: userId,
            userName: currentUserName,
            dreamId: dreamId,
            dreamTitle: dreamTitle,
            dreamPreview: dreamPreview,
            targetUserId: targetUserId,
            targetUserName: targetUserName,
            content: content
        )
        
        modelContext.insert(activity)
        try? modelContext.save()
    }
    
    /// 获取活动动态 Feed
    func getActivityFeed(limit: Int = 50) async throws -> [SocialActivity] {
        // 获取关注的用户 ID 列表
        let following = try getFollowing()
        let followingIds = following.map { $0.followingId } + [userId]
        
        var descriptor = FetchDescriptor<SocialActivity>(
            predicate: #Predicate { followingIds.contains($0.userId) && $0.isVisible }
        )
        descriptor.fetchLimit = limit
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 隐藏活动动态
    func hideActivity(_ activityId: UUID) async throws {
        guard let activity = try modelContext.fetch(
            FetchDescriptor<SocialActivity>(
                predicate: #Predicate { $0.id == activityId }
            )
        ).first else {
            return
        }
        
        activity.isVisible = false
        try modelContext.save()
    }
    
    // MARK: - 成就系统
    
    /// 初始化成就
    func initializeAchievements() async throws {
        let existing = try modelContext.fetch(FetchDescriptor<SocialAchievement>()).count
        
        guard existing == 0 else {
            return // 已初始化
        }
        
        for preset in SocialAchievement.presets {
            modelContext.insert(preset)
        }
        
        try modelContext.save()
    }
    
    /// 检查评论成就
    private func checkCommentAchievement() async throws {
        let commentCount = try modelContext.fetch(FetchDescriptor<SocialComment>(
            predicate: #Predicate { $0.userId == userId }
        )).count
        
        // 检查首次互动成就
        if commentCount >= 1 {
            try await unlockAchievement(type: .firstInteraction)
        }
        
        // 检查评论达人成就
        if commentCount >= 50 {
            try await unlockAchievement(type: .commentMaster)
        }
    }
    
    /// 检查收藏成就
    private func checkBookmarkAchievement() async throws {
        let bookmarkCount = try modelContext.fetch(FetchDescriptor<SocialBookmark>(
            predicate: #Predicate { true } // 所有收藏
        )).count
        
        // 检查收藏家成就
        if bookmarkCount >= 100 {
            try await unlockAchievement(type: .collector)
        }
    }
    
    /// 解锁成就
    private func unlockAchievement(type: SocialAchievementType) async throws {
        guard let achievement = try modelContext.fetch(
            FetchDescriptor<SocialAchievement>(
                predicate: #Predicate { $0.type == type.rawValue }
            )
        ).first else {
            return
        }
        
        guard !achievement.isUnlocked else {
            return // 已解锁
        }
        
        achievement.isUnlocked = true
        achievement.unlockedAt = Date()
        achievement.progress = achievement.requirement
        
        try modelContext.save()
        
        // 更新统计
        try await updateAchievementStats()
        
        // 发送通知
        sendAchievementNotification(achievement)
        
        // 通知监听者
        onAchievementUnlocked?(achievement)
    }
    
    /// 获取所有成就
    func getAchievements() async throws -> [SocialAchievement] {
        var descriptor = FetchDescriptor<SocialAchievement>()
        descriptor.sortBy = [SortDescriptor(\.requirement, order: .forward)]
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取已解锁成就
    func getUnlockedAchievements() async throws -> [SocialAchievement] {
        try modelContext.fetch(
            FetchDescriptor<SocialAchievement>(
                predicate: #Predicate { $0.isUnlocked }
            )
        )
    }
    
    // MARK: - 统计更新
    
    private func updateLikeStats(dreamId: UUID) async throws {
        // 更新收到的点赞数
        let receivedCount = try getLikeCount(for: dreamId)
        // TODO: 更新梦境的 likeCount 字段
    }
    
    private func updateCommentStats() async throws {
        let commentCount = try modelContext.fetch(FetchDescriptor<SocialComment>(
            predicate: #Predicate { $0.userId == userId }
        )).count
        
        // 更新用户统计
        try await updateStats { $0.totalComments = commentCount }
    }
    
    private func updateBookmarkStats() async throws {
        let bookmarkCount = try getTotalBookmarkCount()
        
        try await updateStats { $0.totalBookmarks = bookmarkCount }
    }
    
    private func updateFollowStats() async throws {
        let followingCount = try getFollowingCount()
        let followerCount = try getFollowerCount()
        let mutualCount = try modelContext.fetch(FetchDescriptor<SocialFollow>(
            predicate: #Predicate { $0.followerId == userId && $0.isMutual }
        )).count
        
        try await updateStats {
            $0.followingCount = followingCount
            $0.followersCount = followerCount
            $0.mutualFollowsCount = mutualCount
        }
    }
    
    private func updateAchievementStats() async throws {
        let unlockedCount = try getUnlockedAchievements().count
        let totalPoints = try getUnlockedAchievements().reduce(0) { $0 + $1.points }
        
        try await updateStats {
            $0.totalAchievements = unlockedCount
            $0.socialPoints = totalPoints
            $0.calculateLevel()
        }
    }
    
    private func updateStats(_ update: (SocialStats) -> Void) async throws {
        var stats = try modelContext.fetch(
            FetchDescriptor<SocialStats>(
                predicate: #Predicate { $0.userId == userId }
            )
        ).first
        
        if stats == nil {
            stats = SocialStats(userId: userId)
            modelContext.insert(stats!)
        }
        
        update(stats!)
        stats!.updatedAt = Date()
        stats!.calculateInfluenceScore()
        
        try modelContext.save()
    }
    
    /// 获取社交统计
    func getSocialStats() async throws -> SocialStats {
        var stats = try modelContext.fetch(
            FetchDescriptor<SocialStats>(
                predicate: #Predicate { $0.userId == userId }
            )
        ).first
        
        if stats == nil {
            stats = SocialStats(userId: userId)
            modelContext.insert(stats!)
            try modelContext.save()
        }
        
        return stats!
    }
    
    // MARK: - 通知
    
    private func sendAchievementNotification(_ achievement: SocialAchievement) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 成就解锁!"
        content.body = "恭喜解锁「\(achievement.name)」成就! +\(achievement.points) 积分"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
