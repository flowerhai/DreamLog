//
//  SocialInteractionModels.swift
//  DreamLog
//
//  Phase 60: 社交功能增强
//  数据模型：点赞、评论、收藏、关注、活动动态、社交成就
//

import Foundation
import SwiftData

// MARK: - 反应类型

/// 6 种社交反应类型
enum ReactionType: String, Codable, CaseIterable {
    case like = "👍"      // 点赞
    case love = "❤️"     // 喜爱
    case laugh = "😂"    // 大笑
    case wow = "😮"      // 惊讶
    case sad = "😢"      // 伤心
    case fire = "🔥"     // 火热
    
    var displayName: String {
        switch self {
        case .like: return "赞"
        case .love: return "喜欢"
        case .laugh: return "好笑"
        case .wow: return "惊讶"
        case .sad: return "难过"
        case .fire: return "火热"
        }
    }
}

// MARK: - 社交点赞

/// 社交点赞记录
@Model
final class SocialLike {
    @Attribute(.unique) var id: UUID
    var dreamId: UUID
    var userId: String
    var reaction: String // ReactionType.rawValue
    var createdAt: Date
    
    init(dreamId: UUID, userId: String, reaction: ReactionType = .like) {
        self.id = UUID()
        self.dreamId = dreamId
        self.userId = userId
        self.reaction = reaction.rawValue
        self.createdAt = Date()
    }
    
    var reactionType: ReactionType {
        ReactionType(rawValue: reaction) ?? .like
    }
}

// MARK: - 社交评论

/// 社交评论 (支持嵌套回复)
@Model
final class SocialComment {
    @Attribute(.unique) var id: UUID
    var dreamId: UUID
    var userId: String
    var userName: String
    var userAvatar: String?
    var content: String
    var parentId: UUID? // 父评论 ID，nil 表示顶级评论
    var likes: Int
    var replyCount: Int
    var isEdited: Bool
    var isAuthor: Bool // 是否为梦境作者
    var createdAt: Date
    var editedAt: Date?
    
    // 关联数据 (运行时填充)
    @Relationship(deleteRule: .nullify) var replies: [SocialComment]?
    
    init(
        dreamId: UUID,
        userId: String,
        userName: String,
        userAvatar: String? = nil,
        content: String,
        parentId: UUID? = nil,
        isAuthor: Bool = false
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.content = content
        self.parentId = parentId
        self.likes = 0
        self.replyCount = 0
        self.isEdited = false
        self.isAuthor = isAuthor
        self.createdAt = Date()
    }
    
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var isEditable: Bool {
        // 24 小时内可编辑
        Date().timeIntervalSince(createdAt) < 86400
    }
}

// MARK: - 评论点赞

/// 评论点赞记录
@Model
final class CommentLike {
    @Attribute(.unique) var id: UUID
    var commentId: UUID
    var userId: String
    var createdAt: Date
    
    init(commentId: UUID, userId: String) {
        self.id = UUID()
        self.commentId = commentId
        self.userId = userId
        self.createdAt = Date()
    }
}

// MARK: - 收藏夹

/// 梦境收藏夹
@Model
final class SocialBookmarkCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var emoji: String
    var isPublic: Bool
    var dreamCount: Int
    var viewCount: Int
    var shareCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    // 关联数据
    @Relationship(deleteRule: .cascade) var bookmarks: [SocialBookmark]
    
    init(
        name: String,
        description: String = "",
        emoji: String = "🔖",
        isPublic: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.emoji = emoji
        self.isPublic = isPublic
        self.dreamCount = 0
        self.viewCount = 0
        self.shareCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.bookmarks = []
    }
    
    func updateStats() {
        self.dreamCount = bookmarks.count
        self.updatedAt = Date()
    }
}

// MARK: - 收藏记录

/// 梦境收藏记录
@Model
final class SocialBookmark {
    @Attribute(.unique) var id: UUID
    var dreamId: UUID
    var dreamTitle: String
    var dreamPreview: String
    var dreamAuthorId: String
    var dreamAuthorName: String
    var notes: String?
    var createdAt: Date
    
    // 所属收藏夹
    var collectionId: UUID
    
    init(
        dreamId: UUID,
        dreamTitle: String,
        dreamPreview: String,
        dreamAuthorId: String,
        dreamAuthorName: String,
        collectionId: UUID,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.dreamTitle = dreamTitle
        self.dreamPreview = dreamPreview
        self.dreamAuthorId = dreamAuthorId
        self.dreamAuthorName = dreamAuthorName
        self.collectionId = collectionId
        self.notes = notes
        self.createdAt = Date()
    }
}

// MARK: - 关注关系

/// 关注分组
enum FollowGroup: String, Codable, CaseIterable {
    case friends = "朋友"
    case creators = "创作者"
    case family = "家人"
    case custom = "自定义"
}

/// 关注关系记录
@Model
final class SocialFollow {
    @Attribute(.unique) var id: UUID
    var followerId: String // 关注者 ID
    var followerName: String
    var followingId: String // 被关注者 ID
    var followingName: String
    var group: String // FollowGroup.rawValue
    var isMutual: Bool // 是否互相关注
    var createdAt: Date
    
    init(
        followerId: String,
        followerName: String,
        followingId: String,
        followingName: String,
        group: FollowGroup = .friends
    ) {
        self.id = UUID()
        self.followerId = followerId
        self.followerName = followerName
        self.followingId = followingId
        self.followingName = followingName
        self.group = group.rawValue
        self.isMutual = false
        self.createdAt = Date()
    }
    
    var followGroup: FollowGroup {
        FollowGroup(rawValue: group) ?? .friends
    }
}

// MARK: - 活动动态类型

/// 活动动态类型
enum ActivityType: String, Codable {
    case dreamPublished = "dream_published"      // 发布梦境
    case dreamLiked = "dream_liked"              // 点赞梦境
    case dreamCommented = "dream_commented"      // 评论梦境
    case dreamBookmarked = "dream_bookmarked"    // 收藏梦境
    case userFollowed = "user_followed"          // 关注用户
    case achievementUnlocked = "achievement_unlocked" // 解锁成就
    case challengeCompleted = "challenge_completed"   // 完成挑战
    
    var displayName: String {
        switch self {
        case .dreamPublished: return "发布了新梦境"
        case .dreamLiked: return "点赞了梦境"
        case .dreamCommented: return "评论了梦境"
        case .dreamBookmarked: return "收藏了梦境"
        case .userFollowed: return "关注了"
        case .achievementUnlocked: return "解锁了成就"
        case .challengeCompleted: return "完成了挑战"
        }
    }
    
    var icon: String {
        switch self {
        case .dreamPublished: return "🌙"
        case .dreamLiked: return "👍"
        case .dreamCommented: return "💬"
        case .dreamBookmarked: return "🔖"
        case .userFollowed: return "👥"
        case .achievementUnlocked: return "🏆"
        case .challengeCompleted: return "🎮"
        }
    }
}

// MARK: - 活动动态

/// 社交活动动态
@Model
final class SocialActivity {
    @Attribute(.unique) var id: UUID
    var type: String // ActivityType.rawValue
    var userId: String
    var userName: String
    var userAvatar: String?
    var dreamId: UUID?
    var dreamTitle: String?
    var dreamPreview: String?
    var targetUserId: String? // 被点赞/评论/关注的用户 ID
    var targetUserName: String?
    var content: String // 动态内容描述
    var metadata: [String: String]? // 额外数据
    var isVisible: Bool // 是否可见 (用户可隐藏)
    var createdAt: Date
    
    init(
        type: ActivityType,
        userId: String,
        userName: String,
        userAvatar: String? = nil,
        dreamId: UUID? = nil,
        dreamTitle: String? = nil,
        dreamPreview: String? = nil,
        targetUserId: String? = nil,
        targetUserName: String? = nil,
        content: String,
        metadata: [String: String]? = nil
    ) {
        self.id = UUID()
        self.type = type.rawValue
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.dreamId = dreamId
        self.dreamTitle = dreamTitle
        self.dreamPreview = dreamPreview
        self.targetUserId = targetUserId
        self.targetUserName = targetUserName
        self.content = content
        self.metadata = metadata
        self.isVisible = true
        self.createdAt = Date()
    }
    
    var activityType: ActivityType {
        ActivityType(rawValue: type) ?? .dreamPublished
    }
    
    var displayTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - 社交成就

/// 社交成就类型
enum SocialAchievementType: String, Codable, CaseIterable {
    case firstInteraction = "first_interaction"    // 首次互动
    case commentMaster = "comment_master"          // 评论达人
    case likeMaster = "like_master"                // 点赞大师
    case collector = "collector"                   // 收藏家
    case socialButterfly = "social_butterfly"      // 社交达人
    case creator = "creator"                       // 创作者
    case popular = "popular"                       // 热门创作者
    case star = "star"                            // 社交明星
    
    var displayName: String {
        switch self {
        case .firstInteraction: return "首次互动"
        case .commentMaster: return "评论达人"
        case .likeMaster: return "点赞大师"
        case .collector: return "收藏家"
        case .socialButterfly: return "社交达人"
        case .creator: return "创作者"
        case .popular: return "热门创作者"
        case .star: return "社交明星"
        }
    }
    
    var icon: String {
        switch self {
        case .firstInteraction: return "🌟"
        case .commentMaster: return "💬"
        case .likeMaster: return "👍"
        case .collector: return "🔖"
        case .socialButterfly: return "👥"
        case .creator: return "📰"
        case .popular: return "🔥"
        case .star: return "👑"
        }
    }
}

/// 社交成就记录
@Model
final class SocialAchievement {
    @Attribute(.unique) var id: UUID
    var type: String // SocialAchievementType.rawValue
    var name: String
    var description: String
    var icon: String
    var requirement: Int // 达成要求
    var progress: Int // 当前进度
    var isUnlocked: Bool
    var unlockedAt: Date?
    var points: Int // 成就积分
    var createdAt: Date
    
    init(
        type: SocialAchievementType,
        name: String,
        description: String,
        icon: String,
        requirement: Int,
        points: Int = 100
    ) {
        self.id = UUID()
        self.type = type.rawValue
        self.name = name
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.progress = 0
        self.isUnlocked = false
        self.points = points
        self.createdAt = Date()
    }
    
    var achievementType: SocialAchievementType {
        SocialAchievementType(rawValue: type) ?? .firstInteraction
    }
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(progress) / Double(requirement), 1.0)
    }
}

// MARK: - 社交统计

/// 用户社交统计
@Model
final class SocialStats {
    @Attribute(.unique) var id: UUID
    var userId: String
    
    // 点赞统计
    var totalLikesGiven: Int // 给出的点赞数
    var totalLikesReceived: Int // 收到的点赞数
    
    // 评论统计
    var totalComments: Int // 发布的评论数
    var totalCommentLikes: Int // 评论收到的赞
    
    // 收藏统计
    var totalBookmarks: Int // 收藏的梦境数
    var totalBookmarksReceived: Int // 被收藏次数
    
    // 关注统计
    var followingCount: Int // 关注的人数
    var followersCount: Int // 粉丝数
    var mutualFollowsCount: Int // 互相关注数
    
    // 成就统计
    var totalAchievements: Int // 解锁的成就数
    var socialPoints: Int // 社交积分
    var socialLevel: Int // 社交等级
    
    // 影响力
    var influenceScore: Double // 影响力评分
    
    // 动态统计
    var totalActivities: Int // 总动态数
    
    var createdAt: Date
    var updatedAt: Date
    
    init(userId: String) {
        self.id = UUID()
        self.userId = userId
        self.totalLikesGiven = 0
        self.totalLikesReceived = 0
        self.totalComments = 0
        self.totalCommentLikes = 0
        self.totalBookmarks = 0
        self.totalBookmarksReceived = 0
        self.followingCount = 0
        self.followersCount = 0
        self.mutualFollowsCount = 0
        self.totalAchievements = 0
        self.socialPoints = 0
        self.socialLevel = 1
        self.influenceScore = 0
        self.totalActivities = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // 计算社交等级
    func calculateLevel() {
        // 每 1000 积分升一级
        self.socialLevel = max(1, socialPoints / 1000 + 1)
    }
    
    // 计算影响力评分
    func calculateInfluenceScore() {
        // 影响力 = 粉丝数 * 2 + 点赞数 * 0.5 + 评论数 * 1 + 收藏数 * 1.5
        self.influenceScore = Double(followersCount) * 2.0
            + Double(totalLikesReceived) * 0.5
            + Double(totalComments) * 1.0
            + Double(totalBookmarksReceived) * 1.5
    }
}

// MARK: - 关注推荐

/// 关注推荐用户
@Model
final class FollowRecommendation {
    @Attribute(.unique) var id: UUID
    var userId: String
    var userName: String
    var userAvatar: String?
    var bio: String?
    var dreamCount: Int
    var followerCount: Int
    var commonTags: [String] // 共同标签
    var commonDreams: Int // 共同梦境数
    var reason: String // 推荐理由
    var score: Double // 推荐分数
    var isFollowed: Bool // 是否已关注
    var createdAt: Date
    
    init(
        userId: String,
        userName: String,
        userAvatar: String? = nil,
        bio: String? = nil,
        dreamCount: Int = 0,
        followerCount: Int = 0,
        commonTags: [String] = [],
        commonDreams: Int = 0,
        reason: String = "",
        score: Double = 0
    ) {
        self.id = UUID()
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.bio = bio
        self.dreamCount = dreamCount
        self.followerCount = followerCount
        self.commonTags = commonTags
        self.commonDreams = commonDreams
        self.reason = reason
        self.score = score
        self.isFollowed = false
        self.createdAt = Date()
    }
}

// MARK: - 预设成就模板

extension SocialAchievement {
    /// 预设社交成就模板
    static var presets: [SocialAchievement] {
        [
            SocialAchievement(
                type: .firstInteraction,
                name: "首次互动",
                description: "第一次点赞或评论他人的梦境",
                icon: "🌟",
                requirement: 1,
                points: 50
            ),
            SocialAchievement(
                type: .commentMaster,
                name: "评论达人",
                description: "发布 50 条评论",
                icon: "💬",
                requirement: 50,
                points: 300
            ),
            SocialAchievement(
                type: .likeMaster,
                name: "点赞大师",
                description: "点赞 500 次",
                icon: "👍",
                requirement: 500,
                points: 400
            ),
            SocialAchievement(
                type: .collector,
                name: "收藏家",
                description: "收藏 100 个梦境",
                icon: "🔖",
                requirement: 100,
                points: 350
            ),
            SocialAchievement(
                type: .socialButterfly,
                name: "社交达人",
                description: "关注 50 人",
                icon: "👥",
                requirement: 50,
                points: 400
            ),
            SocialAchievement(
                type: .creator,
                name: "创作者",
                description: "发布 20 个梦境",
                icon: "📰",
                requirement: 20,
                points: 500
            ),
            SocialAchievement(
                type: .popular,
                name: "热门创作者",
                description: "单个梦境获得 100+ 点赞",
                icon: "🔥",
                requirement: 100,
                points: 600
            ),
            SocialAchievement(
                type: .star,
                name: "社交明星",
                description: "获得 1000+ 粉丝",
                icon: "👑",
                requirement: 1000,
                points: 1000
            )
        ]
    }
}

// MARK: - 社交梦境元数据

/// 社交梦境元数据 - 用于关联梦境与作者信息
@Model
final class SocialDream {
    @Attribute(.unique) var id: UUID
    var dreamId: UUID // 关联的梦境 ID
    var authorId: String // 作者用户 ID
    var authorName: String // 作者显示名称
    var authorAvatar: String? // 作者头像 URL
    var title: String // 梦境标题
    var preview: String // 梦境预览内容
    var mood: String? // 情绪
    var isLucid: Bool // 是否清醒梦
    var isPublic: Bool // 是否公开
    var tags: [String] // 标签列表
    
    // 社交统计 (缓存，避免频繁计算)
    var likeCount: Int // 点赞数
    var commentCount: Int // 评论数
    var bookmarkCount: Int // 收藏数
    var viewCount: Int // 浏览次数
    
    var createdAt: Date
    var updatedAt: Date
    var publishedAt: Date? // 发布时间 (公开时设置)
    
    init(
        dreamId: UUID,
        authorId: String,
        authorName: String,
        authorAvatar: String? = nil,
        title: String,
        preview: String,
        mood: String? = nil,
        isLucid: Bool = false,
        isPublic: Bool = true,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.authorId = authorId
        self.authorName = authorName
        self.authorAvatar = authorAvatar
        self.title = title
        self.preview = preview
        self.mood = mood
        self.isLucid = isLucid
        self.isPublic = isPublic
        self.tags = tags
        self.likeCount = 0
        self.commentCount = 0
        self.bookmarkCount = 0
        self.viewCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
        self.publishedAt = isPublic ? Date() : nil
    }
    
    /// 更新社交统计
    func updateStats(likes: Int, comments: Int, bookmarks: Int, views: Int) {
        self.likeCount = likes
        self.commentCount = comments
        self.bookmarkCount = bookmarks
        self.viewCount = views
        self.updatedAt = Date()
    }
    
    /// 切换公开状态
    func togglePublic() {
        self.isPublic.toggle()
        self.publishedAt = isPublic ? Date() : nil
        self.updatedAt = Date()
    }
    
    /// 显示用的格式化时间
    var displayTime: String {
        let date = publishedAt ?? createdAt
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// 梦境完整预览 (带截断)
    var truncatedPreview: String {
        if preview.count <= 100 {
            return preview
        }
        return String(preview.prefix(100)) + "..."
    }
}

// MARK: - 社交梦境排序选项

/// 社交梦境排序选项
enum SocialDreamSortOption: String, CaseIterable {
    case latest = "latest"           // 最新发布
    case popular = "popular"         // 最受欢迎
    case mostCommented = "mostCommented" // 最多评论
    case mostViewed = "mostViewed"   // 最多浏览
    
    var displayName: String {
        switch self {
        case .latest: return "最新"
        case .popular: return "热门"
        case .mostCommented: return "讨论"
        case .mostViewed: return "浏览"
        }
    }
}

// MARK: - 梦境浏览历史

/// 用户浏览梦境历史记录
@Model
final class DreamViewHistory {
    @Attribute(.unique) var id: UUID
    var userId: String
    var dreamId: UUID
    var viewedAt: Date
    var viewDuration: TimeInterval // 浏览时长 (秒)
    
    init(userId: String, dreamId: UUID, viewDuration: TimeInterval = 0) {
        self.id = UUID()
        self.userId = userId
        self.dreamId = dreamId
        self.viewedAt = Date()
        self.viewDuration = viewDuration
    }
}
