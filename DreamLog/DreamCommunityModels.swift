//
//  DreamCommunityModels.swift
//  DreamLog
//
//  Phase 42 - 梦境社区数据模型
//  匿名分享、浏览、点赞、评论、关注
//

import Foundation
import SwiftData

// MARK: - 可见性枚举

/// 梦境可见性
@Model
enum Visibility: String, Codable, CaseIterable {
    case public = "public"           // 公开 (所有人可见)
    case followers = "followers"     // 仅关注者
    case private = "private"         // 私密 (仅自己可见)
    
    var displayName: String {
        switch self {
        case .public: return "公开"
        case .followers: return "仅关注者"
        case .private: return "私密"
        }
    }
    
    var icon: String {
        switch self {
        case .public: return "globe"
        case .followers: return "person.2"
        case .private: return "lock"
        }
    }
}

// MARK: - 共享梦境模型

/// 社区共享梦境
@Model
final class SharedDream {
    var id: UUID
    var anonymousId: String          // 匿名 ID
    var dreamId: UUID?               // 原始梦境 ID (可选)
    
    // 梦境内容
    var title: String
    var content: String
    var emotions: [String]
    var tags: [String]
    var dreamType: String?           // 梦境类型 (冒险/奇幻/恐怖/浪漫等)
    var aiAnalysis: String?          // AI 解析 (可选分享)
    var moodScore: Double?           // 情绪评分 (-1.0 到 1.0)
    var clarityScore: Double?        // 清晰度评分 (0.0 到 1.0)
    var isLucid: Bool                // 是否清醒梦
    
    // 隐私设置
    var visibility: Visibility       // 可见性
    var allowComments: Bool          // 允许评论
    var isAnonymous: Bool            // 是否完全匿名
    
    // 互动统计
    var likeCount: Int
    var commentCount: Int
    var favoriteCount: Int
    var shareCount: Int
    var viewCount: Int
    
    // 用户关系
    var isLikedByCurrentUser: Bool   // 当前用户是否点赞
    var isFavoritedByCurrentUser: Bool // 当前用户是否收藏
    var isFollowedByCurrentUser: Bool // 当前用户是否关注作者
    
    // 时间戳
    var createdAt: Date
    var updatedAt: Date
    
    // 删除标记
    var isDeleted: Bool
    var deletedAt: Date?
    
    // 关系
    @Relationship(deleteRule: .nullify) var author: CommunityUser?
    @Relationship(deleteRule: .cascade) var comments: [CommunityComment]
    @Relationship(deleteRule: .cascade) var likes: [CommunityLike]
    
    init(
        id: UUID = UUID(),
        anonymousId: String,
        dreamId: UUID? = nil,
        title: String,
        content: String,
        emotions: [String],
        tags: [String],
        dreamType: String? = nil,
        aiAnalysis: String? = nil,
        moodScore: Double? = nil,
        clarityScore: Double? = nil,
        isLucid: Bool = false,
        visibility: Visibility = .public,
        allowComments: Bool = true,
        isAnonymous: Bool = true,
        likeCount: Int = 0,
        commentCount: Int = 0,
        favoriteCount: Int = 0,
        shareCount: Int = 0,
        viewCount: Int = 0,
        isLikedByCurrentUser: Bool = false,
        isFavoritedByCurrentUser: Bool = false,
        isFollowedByCurrentUser: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        author: CommunityUser? = nil,
        comments: [CommunityComment] = [],
        likes: [CommunityLike] = []
    ) {
        self.id = id
        self.anonymousId = anonymousId
        self.dreamId = dreamId
        self.title = title
        self.content = content
        self.emotions = emotions
        self.tags = tags
        self.dreamType = dreamType
        self.aiAnalysis = aiAnalysis
        self.moodScore = moodScore
        self.clarityScore = clarityScore
        self.isLucid = isLucid
        self.visibility = visibility
        self.allowComments = allowComments
        self.isAnonymous = isAnonymous
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.favoriteCount = favoriteCount
        self.shareCount = shareCount
        self.viewCount = viewCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
        self.isFavoritedByCurrentUser = isFavoritedByCurrentUser
        self.isFollowedByCurrentUser = isFollowedByCurrentUser
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.author = author
        self.comments = comments
        self.likes = likes
    }
    
    // MARK: - 计算属性
    
    var displayTitle: String {
        isAnonymous ? "匿名梦境 #\(id.uuidString.prefix(8))" : title
    }
    
    var contentPreview: String {
        let previewLength = 100
        if content.count > previewLength {
            return String(content.prefix(previewLength)) + "..."
        }
        return content
    }
    
    var emotionIcons: String {
        emotions.map { emotion -> String in
            switch emotion.lowercased() {
            case "happy", "joyful": return "😊"
            case "calm", "peaceful": return "😌"
            case "excited": return "🤩"
            case "surprised": return "😮"
            case "scared", "fearful": return "😨"
            case "sad": return "😢"
            case "anxious": return "😰"
            case "confused": return "😕"
            default: return "💭"
            }
        }.joined()
    }
    
    // MARK: - 方法
    
    func incrementLikeCount() {
        likeCount += 1
        updatedAt = Date()
    }
    
    func decrementLikeCount() {
        likeCount = max(0, likeCount - 1)
        updatedAt = Date()
    }
    
    func incrementViewCount() {
        viewCount += 1
    }
    
    func softDelete() {
        isDeleted = true
        deletedAt = Date()
        updatedAt = Date()
    }
}

// MARK: - 社区用户模型

/// 社区匿名用户
@Model
final class CommunityUser {
    var id: UUID
    var anonymousId: String          // 匿名 ID (公开显示)
    var avatarSeed: Int              // 基于 ID 生成的头像种子
    var avatarEmoji: String          // 头像表情
    
    // 统计
    var followingCount: Int
    var followerCount: Int
    var sharedCount: Int
    var totalLikes: Int              // 收到的总点赞数
    
    // 等级/成就
    var level: Int
    var badges: [String]             // 徽章 ID 列表
    var joinDate: Date
    
    // 隐私设置
    var allowFollowers: Bool         // 允许被关注
    var showActivity: Bool           // 显示活动状态
    var blockedUsers: [String]       // 屏蔽的用户 ID 列表
    
    // 关系
    @Relationship(deleteRule: .cascade) var sharedDreams: [SharedDream]
    @Relationship(deleteRule: .cascade) var comments: [CommunityComment]
    @Relationship(deleteRule: .cascade) var likes: [CommunityLike]
    
    init(
        id: UUID = UUID(),
        anonymousId: String,
        avatarSeed: Int = 0,
        avatarEmoji: String = "🌙",
        followingCount: Int = 0,
        followerCount: Int = 0,
        sharedCount: Int = 0,
        totalLikes: Int = 0,
        level: Int = 1,
        badges: [String] = [],
        joinDate: Date = Date(),
        allowFollowers: Bool = true,
        showActivity: Bool = true,
        blockedUsers: [String] = [],
        sharedDreams: [SharedDream] = [],
        comments: [CommunityComment] = [],
        likes: [CommunityLike] = []
    ) {
        self.id = id
        self.anonymousId = anonymousId
        self.avatarSeed = avatarSeed
        self.avatarEmoji = avatarEmoji
        self.followingCount = followingCount
        self.followerCount = followerCount
        self.sharedCount = sharedCount
        self.totalLikes = totalLikes
        self.level = level
        self.badges = badges
        self.joinDate = joinDate
        self.allowFollowers = allowFollowers
        self.showActivity = showActivity
        self.blockedUsers = blockedUsers
        self.sharedDreams = sharedDreams
        self.comments = comments
        self.likes = likes
    }
    
    // MARK: - 计算属性
    
    var displayLevel: String {
        switch level {
        case 1..<5: return "🌱 梦境新手"
        case 5..<10: return "🌿 梦境探索者"
        case 10..<20: return "🌳 梦境行者"
        case 20..<50: return "🌟 梦境大师"
        default: return "✨ 梦境传奇"
        }
    }
    
    var levelProgress: Double {
        let levelStart = level * level * 10
        let levelEnd = (level + 1) * (level + 1) * 10
        let progress = Double(totalLikes - levelStart) / Double(levelEnd - levelStart)
        return min(1.0, max(0.0, progress))
    }
    
    // MARK: - 方法
    
    func incrementSharedCount() {
        sharedCount += 1
        updateLevel()
    }
    
    func incrementTotalLikes(_ count: Int = 1) {
        totalLikes += count
        updateLevel()
    }
    
    private func updateLevel() {
        let newLevel = Int(sqrt(Double(totalLikes) / 10.0)) + 1
        if newLevel > level {
            level = newLevel
            // 可以添加升级逻辑
        }
    }
    
    func isUserBlocked(_ userId: String) -> Bool {
        return blockedUsers.contains(userId)
    }
    
    func blockUser(_ userId: String) {
        if !blockedUsers.contains(userId) {
            blockedUsers.append(userId)
        }
    }
    
    func unblockUser(_ userId: String) {
        blockedUsers.removeAll { $0 == userId }
    }
}

// MARK: - 评论模型

/// 社区评论
@Model
final class CommunityComment {
    var id: UUID
    var sharedDreamId: UUID
    var anonymousId: String
    var content: String
    
    // 统计
    var likeCount: Int
    var replyCount: Int
    
    // 关系
    var parentCommentId: UUID?       // 父评论 ID (用于回复)
    
    // 状态
    var isDeleted: Bool
    var isEdited: Bool
    var isReported: Bool           // 是否被举报
    var reportCount: Int
    
    // 时间戳
    var createdAt: Date
    var updatedAt: Date
    
    // 关系
    @Relationship(deleteRule: .nullify) var author: CommunityUser?
    @Relationship(deleteRule: .nullify) var sharedDream: SharedDream?
    @Relationship(deleteRule: .cascade) var replies: [CommunityComment]
    @Relationship(deleteRule: .cascade) var likes: [CommunityLike]
    
    init(
        id: UUID = UUID(),
        sharedDreamId: UUID,
        anonymousId: String,
        content: String,
        likeCount: Int = 0,
        replyCount: Int = 0,
        parentCommentId: UUID? = nil,
        isDeleted: Bool = false,
        isEdited: Bool = false,
        isReported: Bool = false,
        reportCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        author: CommunityUser? = nil,
        sharedDream: SharedDream? = nil,
        replies: [CommunityComment] = [],
        likes: [CommunityLike] = []
    ) {
        self.id = id
        self.sharedDreamId = sharedDreamId
        self.anonymousId = anonymousId
        self.content = content
        self.likeCount = likeCount
        self.replyCount = replyCount
        self.parentCommentId = parentCommentId
        self.isDeleted = isDeleted
        self.isEdited = isEdited
        self.isReported = isReported
        self.reportCount = reportCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.sharedDream = sharedDream
        self.replies = replies
        self.likes = likes
    }
    
    // MARK: - 计算属性
    
    var contentPreview: String {
        let previewLength = 200
        if content.count > previewLength {
            return String(content.prefix(previewLength)) + "..."
        }
        return content
    }
    
    var isReply: Bool {
        parentCommentId != nil
    }
    
    // MARK: - 方法
    
    func softDelete() {
        isDeleted = true
        content = "[评论已删除]"
        updatedAt = Date()
    }
    
    func editContent(_ newContent: String) {
        content = newContent
        isEdited = true
        updatedAt = Date()
    }
    
    func incrementLikeCount() {
        likeCount += 1
        updatedAt = Date()
    }
    
    func report() {
        reportCount += 1
        if reportCount >= 5 {
            isReported = true
        }
    }
}

// MARK: - 点赞模型

/// 点赞记录
@Model
final class CommunityLike {
    var id: UUID
    var userId: String
    var targetType: LikeTargetType
    var targetId: UUID
    
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        targetType: LikeTargetType,
        targetId: UUID,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.targetType = targetType
        self.targetId = targetId
        self.createdAt = createdAt
    }
}

enum LikeTargetType: String, Codable {
    case dream
    case comment
}

// MARK: - 收藏模型

/// 收藏记录
@Model
final class CommunityFavorite {
    var id: UUID
    var userId: String
    var sharedDreamId: UUID
    var folderId: UUID?              // 收藏夹 ID (可选)
    
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        sharedDreamId: UUID,
        folderId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.sharedDreamId = sharedDreamId
        self.folderId = folderId
        self.createdAt = createdAt
    }
}

// MARK: - 关注关系模型

/// 关注关系
@Model
final class FollowRelationship {
    var id: UUID
    var followerId: String           // 关注者 ID
    var followingId: String          // 被关注者 ID
    
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        followerId: String,
        followingId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.createdAt = createdAt
    }
}

// MARK: - 举报模型

/// 举报记录
@Model
final class CommunityReport {
    var id: UUID
    var reporterId: String
    var targetType: ReportTargetType
    var targetId: UUID
    var reason: ReportReason
    var description: String?
    
    var status: ReportStatus
    var reviewedBy: String?
    var reviewedAt: Date?
    
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        reporterId: String,
        targetType: ReportTargetType,
        targetId: UUID,
        reason: ReportReason,
        description: String? = nil,
        status: ReportStatus = .pending,
        reviewedBy: String? = nil,
        reviewedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reporterId = reporterId
        self.targetType = targetType
        self.targetId = targetId
        self.reason = reason
        self.description = description
        self.status = status
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
        self.createdAt = createdAt
    }
}

enum ReportTargetType: String, Codable {
    case dream
    case comment
    case user
}

enum ReportReason: String, Codable, CaseIterable {
    case spam = "spam"                      // 垃圾内容
    case harassment = "harassment"          // 骚扰
    case hateSpeech = "hate_speech"         // 仇恨言论
    case explicitContent = "explicit"       // 不当内容
    case privacyViolation = "privacy"       // 隐私泄露
    case misinformation = "misinformation"  // 虚假信息
    case other = "other"                    // 其他
    
    var displayName: String {
        switch self {
        case .spam: return "垃圾内容"
        case .harassment: return "骚扰行为"
        case .hateSpeech: return "仇恨言论"
        case .explicitContent: return "不当内容"
        case .privacyViolation: return "隐私泄露"
        case .misinformation: return "虚假信息"
        case .other: return "其他"
        }
    }
}

enum ReportStatus: String, Codable {
    case pending = "pending"        // 待处理
    case reviewing = "reviewing"    // 审核中
    case resolved = "resolved"      // 已处理
    case dismissed = "dismissed"    // 已驳回
}

// MARK: - 社区统计模型

/// 社区统计数据
struct CommunityStats {
    var totalSharedDreams: Int
    var totalUsers: Int
    var activeUsers: Int           // 24 小时内活跃用户
    var todayShares: Int
    var totalLikes: Int
    var totalComments: Int
    
    var trendingTags: [TagStat]
    var emotionDistribution: [EmotionStat]
    var dreamTypeDistribution: [DreamTypeStat]
    
    init() {
        self.totalSharedDreams = 0
        self.totalUsers = 0
        self.activeUsers = 0
        self.todayShares = 0
        self.totalLikes = 0
        self.totalComments = 0
        self.trendingTags = []
        self.emotionDistribution = []
        self.dreamTypeDistribution = []
    }
}

struct TagStat: Identifiable, Codable {
    var id: String { tag }
    var tag: String
    var count: Int
    var trend: Double              // 趋势 (正数表示上升)
}

struct EmotionStat: Identifiable, Codable {
    var id: String { emotion }
    var emotion: String
    var count: Int
    var percentage: Double
}

struct DreamTypeStat: Identifiable, Codable {
    var id: String { type }
    var type: String
    var count: Int
    var percentage: Double
}

// MARK: - 匿名化配置

/// 匿名化配置
struct AnonymizationConfig {
    var removeNames: Bool
    var removeLocations: Bool
    var removeDates: Bool
    var removeSpecificNumbers: Bool
    var generalizeContent: Bool
    
    static var `default`: AnonymizationConfig {
        AnonymizationConfig(
            removeNames: true,
            removeLocations: true,
            removeDates: true,
            removeSpecificNumbers: true,
            generalizeContent: false
        )
    }
    
    static var strict: AnonymizationConfig {
        AnonymizationConfig(
            removeNames: true,
            removeLocations: true,
            removeDates: true,
            removeSpecificNumbers: true,
            generalizeContent: true
        )
    }
}

// MARK: - 分享配置

/// 分享配置
struct ShareConfig: Codable {
    var includeTitle: Bool
    var includeContent: Bool
    var includeEmotions: Bool
    var includeTags: Bool
    var includeAIAnalysis: Bool
    var includeStats: Bool
    
    var visibility: Visibility
    var allowComments: Bool
    
    static var `default`: ShareConfig {
        ShareConfig(
            includeTitle: true,
            includeContent: true,
            includeEmotions: true,
            includeTags: true,
            includeAIAnalysis: false,
            includeStats: false,
            visibility: .public,
            allowComments: true
        )
    }
}

// MARK: - 社区筛选器

/// 社区内容筛选器
enum CommunityFilter: String, CaseIterable {
    case hot = "热门"
    case new = "最新"
    case following = "关注"
    case lucid = "清醒梦"
    case creative = "创意"
    case peaceful = "平静"
    
    var icon: String {
        switch self {
        case .hot: return "🔥"
        case .new: return "✨"
        case .following: return "💚"
        case .lucid: return "💫"
        case .creative: return "🎨"
        case .peaceful: return "😌"
        }
    }
    
    var apiValue: String {
        switch self {
        case .hot: return "hot"
        case .new: return "new"
        case .following: return "following"
        case .lucid: return "lucid"
        case .creative: return "creative"
        case .peaceful: return "peaceful"
        }
    }
}
