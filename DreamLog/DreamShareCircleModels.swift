//
//  DreamShareCircleModels.swift
//  DreamLog
//
//  梦境分享圈数据模型
//  Phase 17: 梦境分享圈功能
//

import Foundation

// MARK: - 分享圈模型

/// 分享圈类型
enum ShareCircleType: String, Codable, CaseIterable {
    case closeFriends = "closeFriends"      // 密友圈
    case family = "family"                  // 家人圈
    case dreamGroup = "dreamGroup"          // 梦境研究小组
    case therapy = "therapy"                // 治疗小组
    case custom = "custom"                  // 自定义
    
    var displayName: String {
        switch self {
        case .closeFriends: return "密友圈"
        case .family: return "家人圈"
        case .dreamGroup: return "梦境研究小组"
        case .therapy: return "治疗小组"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .closeFriends: return "heart.fill"
        case .family: return "house.fill"
        case .dreamGroup: return "brain.head.profile"
        case .therapy: return "cross.fill"
        case .custom: return "person.3.fill"
        }
    }
}

/// 分享圈成员角色
enum CircleMemberRole: String, Codable, CaseIterable {
    case owner = "owner"            // 圈主
    case admin = "admin"            // 管理员
    case member = "member"          // 普通成员
    case viewer = "viewer"          // 仅查看
    
    var displayName: String {
        switch self {
        case .owner: return "圈主"
        case .admin: return "管理员"
        case .member: return "成员"
        case .viewer: return "访客"
        }
    }
    
    var permissions: CirclePermissions {
        switch self {
        case .owner:
            return CirclePermissions(
                canShareDreams: true,
                canComment: true,
                canInvite: true,
                canRemoveMembers: true,
                canEditCircle: true,
                canDeleteCircle: true,
                canViewAnalytics: true
            )
        case .admin:
            return CirclePermissions(
                canShareDreams: true,
                canComment: true,
                canInvite: true,
                canRemoveMembers: true,
                canEditCircle: true,
                canDeleteCircle: false,
                canViewAnalytics: true
            )
        case .member:
            return CirclePermissions(
                canShareDreams: true,
                canComment: true,
                canInvite: false,
                canRemoveMembers: false,
                canEditCircle: false,
                canDeleteCircle: false,
                canViewAnalytics: false
            )
        case .viewer:
            return CirclePermissions(
                canShareDreams: false,
                canComment: true,
                canInvite: false,
                canRemoveMembers: false,
                canEditCircle: false,
                canDeleteCircle: false,
                canViewAnalytics: false
            )
        }
    }
}

/// 分享圈权限
struct CirclePermissions: Codable {
    var canShareDreams: Bool       // 可以分享梦境
    var canComment: Bool           // 可以评论
    var canInvite: Bool            // 可以邀请成员
    var canRemoveMembers: Bool     // 可以移除成员
    var canEditCircle: Bool        // 可以编辑分享圈
    var canDeleteCircle: Bool      // 可以删除分享圈
    var canViewAnalytics: Bool     // 可以查看统计
    
    static let `default` = CirclePermissions(
        canShareDreams: true,
        canComment: true,
        canInvite: false,
        canRemoveMembers: false,
        canEditCircle: false,
        canDeleteCircle: false,
        canViewAnalytics: false
    )
}

/// 分享圈成员
struct CircleMember: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var userId: String
    var userName: String
    var avatar: String?
    var role: CircleMemberRole
    var joinedAt: Date
    var lastActiveAt: Date?
    var sharedDreamCount: Int = 0
    var commentCount: Int = 0
    
    static func mock(userId: String, userName: String, role: CircleMemberRole) -> CircleMember {
        return CircleMember(
            userId: userId,
            userName: userName,
            role: role,
            joinedAt: Date().addingTimeInterval(-Double.random(in: 1000...86400)),
            sharedDreamCount: Int.random(in: 0...20),
            commentCount: Int.random(in: 0...50)
        )
    }
}

/// 分享圈信息
struct ShareCircle: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var type: ShareCircleType
    var description: String?
    var coverImage: String?
    var owner: CircleMember
    var members: [CircleMember]
    var createdAt: Date
    var settings: CircleSettings
    var isPrivate: Bool = true
    var inviteCode: String?
    
    var memberCount: Int {
        members.count
    }
    
    var totalSharedDreams: Int {
        members.reduce(0) { $0 + $1.sharedDreamCount }
    }
    
    static func mock(name: String, type: ShareCircleType, memberCount: Int) -> ShareCircle {
        let owner = CircleMember.mock(userId: "user_0", userName: "我", role: .owner)
        var members = [owner]
        for i in 1..<memberCount {
            members.append(CircleMember.mock(
                userId: "user_\(i)",
                userName: "用户\(i)",
                role: i < 2 ? .admin : .member
            ))
        }
        return ShareCircle(
            name: name,
            type: type,
            owner: owner,
            members: members,
            createdAt: Date().addingTimeInterval(-Double.random(in: 1000...86400))
        )
    }
}

/// 分享圈设置
struct CircleSettings: Codable {
    var allowMemberInvites: Bool = false           // 允许成员邀请
    var requireApproval: Bool = true               // 需要审核
    var allowComments: Bool = true                 // 允许评论
    var allowReactions: Bool = true                // 允许表情回应
    var showMemberList: Bool = true                // 显示成员列表
    var dreamVisibility: DreamVisibility = .all    // 梦境可见性
    var notificationPreferences: NotificationPreferences = .default
    
    enum DreamVisibility: String, Codable, CaseIterable {
        case all = "all"               // 全部可见
        case recent7Days = "recent7"   // 最近 7 天
        case recent30Days = "recent30" // 最近 30 天
        case none = "none"             // 不可见
    }
    
    struct NotificationPreferences: Codable {
        var newDreamShared: Bool = true
        var newComment: Bool = true
        var memberJoined: Bool = true
        var memberLeft: Bool = false
        
        static let `default` = NotificationPreferences()
    }
}

// MARK: - 分享的梦境

/// 分享的梦境
struct SharedDream: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var dreamId: String
    var circleId: String
    var sharedBy: CircleMember
    var sharedAt: Date
    var title: String
    var content: String
    var emotions: [String]
    var tags: [String]
    var dreamDate: Date
    var isLucid: Bool
    var clarity: Int
    var comments: [DreamComment]
    var reactions: [DreamReaction]
    var viewCount: Int = 0
    var isPinned: Bool = false
    var isArchived: Bool = false
    
    var commentCount: Int {
        comments.count
    }
    
    var reactionCount: Int {
        reactions.count
    }
    
    static func mock(circleId: String, sharedBy: CircleMember) -> SharedDream {
        return SharedDream(
            dreamId: "dream_\(UUID().uuidString.prefix(8))",
            circleId: circleId,
            sharedBy: sharedBy,
            sharedAt: Date().addingTimeInterval(-Double.random(in: 1000...86400)),
            title: "一个奇妙的梦",
            content: "我梦见自己在天空中飞翔...",
            emotions: ["joy", "wonder"],
            tags: ["飞行", "天空"],
            dreamDate: Date().addingTimeInterval(-Double.random(in: 1000...86400)),
            isLucid: Bool.random(),
            clarity: Int.random(in: 1...5),
            comments: [],
            reactions: []
        )
    }
}

/// 梦境评论
struct DreamComment: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var sharedDreamId: String
    var author: CircleMember
    var content: String
    var createdAt: Date
    var updatedAt: Date?
    var parentId: String?
    var reactions: [DreamReaction]
    var isEdited: Bool = false
    
    var reactionCount: Int {
        reactions.count
    }
}

/// 梦境表情回应
struct DreamReaction: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var type: ReactionType
    var userId: String
    var userName: String
    var createdAt: Date
    
    enum ReactionType: String, Codable, CaseIterable {
        case heart = "heart"
        case star = "star"
        case moon = "moon"
        case sparkle = "sparkle"
        case brain = "brain"
        case sleep = "sleep"
        
        var emoji: String {
            switch self {
            case .heart: return "❤️"
            case .star: return "⭐"
            case .moon: return "🌙"
            case .sparkle: return "✨"
            case .brain: return "🧠"
            case .sleep: return "💤"
            }
        }
    }
}

// MARK: - 邀请相关

/// 分享圈邀请
struct CircleInvitation: Codable, Identifiable {
    var id: String = UUID().uuidString
    var circleId: String
    var circleName: String
    var circleType: ShareCircleType
    var inviter: CircleMember
    var inviteeEmail: String?
    var inviteeUserId: String?
    var inviteCode: String
    var createdAt: Date
    var expiresAt: Date
    var status: InvitationStatus = .pending
    var message: String?
    
    enum InvitationStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case declined = "declined"
        case expired = "expired"
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

// MARK: - 活动动态

/// 分享圈活动
struct CircleActivity: Codable, Identifiable {
    var id: String = UUID().uuidString
    var circleId: String
    var type: ActivityType
    var actor: CircleMember
    var targetUser: CircleMember?
    var sharedDream: SharedDream?
    var comment: DreamComment?
    var createdAt: Date
    
    enum ActivityType: String, Codable {
        case memberJoined = "memberJoined"
        case memberLeft = "memberLeft"
        case dreamShared = "dreamShared"
        case commentAdded = "commentAdded"
        case reactionAdded = "reactionAdded"
        case circleUpdated = "circleUpdated"
    }
}

// MARK: - 错误类型

enum ShareCircleError: LocalizedError {
    case circleNotFound
    case memberNotFound
    case insufficientPermissions
    case invitationExpired
    case invitationInvalid
    case alreadyMember
    case circleFull
    case networkError
    case syncError
    case dreamAlreadyShared
    
    var errorDescription: String? {
        switch self {
        case .circleNotFound: return "分享圈不存在"
        case .memberNotFound: return "成员不存在"
        case .insufficientPermissions: return "权限不足"
        case .invitationExpired: return "邀请已过期"
        case .invitationInvalid: return "邀请码无效"
        case .alreadyMember: return "已是分享圈成员"
        case .circleFull: return "分享圈已满"
        case .networkError: return "网络错误"
        case .syncError: return "同步失败"
        case .dreamAlreadyShared: return "该梦境已分享到此圈子"
        }
    }
}

// MARK: - 简要统计

/// 分享圈简要统计
struct CircleStats {
    var totalDreams: Int
    var totalComments: Int
    var totalReactions: Int
    var recentDreamCount: Int
}
