//
//  DreamFamilyModels.swift
//  DreamLog - Family Sharing Data Models
//  Phase 96: Family Sharing 👨‍👩‍👧‍👦✨
//
//  Created on 2026-03-23
//

import Foundation
import SwiftUI

// MARK: - Family Group Models

/// 家庭组信息
public struct FamilyGroup: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var avatar: Data?
    public let createdAt: Date
    public var adminId: UUID
    public var memberCount: Int
    public let inviteCode: String
    public var settings: FamilySettings
    public var statistics: FamilyStatistics?
    
    public init(
        id: UUID = UUID(),
        name: String,
        avatar: Data? = nil,
        createdAt: Date = Date(),
        adminId: UUID,
        memberCount: Int = 1,
        inviteCode: String? = nil,
        settings: FamilySettings = FamilySettings(),
        statistics: FamilyStatistics? = nil
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.createdAt = createdAt
        self.adminId = adminId
        self.memberCount = memberCount
        self.inviteCode = inviteCode ?? Self.generateInviteCode()
        self.settings = settings
        self.statistics = statistics
    }
    
    /// 生成邀请码（8 位字母数字组合）
    private static func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // 排除易混淆字符
        return String((0..<8).map { _ in chars.randomElement() ?? "A" })
    }
}

/// 家庭组设置
public struct FamilySettings: Codable, Equatable {
    public var defaultPrivacyLevel: PrivacyLevel
    public var enableContentFilter: Bool
    public var childProtectionMode: Bool
    public var allowDreamSharing: Bool
    public var allowPatternAnalysis: Bool
    public var notificationPreferences: NotificationPreferences
    
    public init(
        defaultPrivacyLevel: PrivacyLevel = .family,
        enableContentFilter: Bool = true,
        childProtectionMode: Bool = false,
        allowDreamSharing: Bool = true,
        allowPatternAnalysis: Bool = true,
        notificationPreferences: NotificationPreferences = NotificationPreferences()
    ) {
        self.defaultPrivacyLevel = defaultPrivacyLevel
        self.enableContentFilter = enableContentFilter
        self.childProtectionMode = childProtectionMode
        self.allowDreamSharing = allowDreamSharing
        self.allowPatternAnalysis = allowPatternAnalysis
        self.notificationPreferences = notificationPreferences
    }
}

/// 隐私级别
public enum PrivacyLevel: String, Codable, CaseIterable {
    case privateLevel = "private"      // 仅自己可见
    case family = "family"             // 家庭成员可见
    case publicLevel = "public"        // 公开可见
    
    public var displayName: String {
        switch self {
        case .privateLevel: return "🔒 私密"
        case .family: return "👨‍👩‍👧‍👦 家庭可见"
        case .publicLevel: return "🌍 公开"
        }
    }
    
    public var icon: String {
        switch self {
        case .privateLevel: return "🔒"
        case .family: return "🏠"
        case .publicLevel: return "🌍"
        }
    }
}

/// 通知偏好设置
public struct NotificationPreferences: Codable, Equatable {
    public var newMemberJoin: Bool
    public var newDreamShared: Bool
    public var challengeReminder: Bool
    public var patternDiscovered: Bool
    public var milestoneReached: Bool
    
    public init(
        newMemberJoin: Bool = true,
        newDreamShared: Bool = true,
        challengeReminder: Bool = true,
        patternDiscovered: Bool = true,
        milestoneReached: Bool = true
    ) {
        self.newMemberJoin = newMemberJoin
        self.newDreamShared = newDreamShared
        self.challengeReminder = challengeReminder
        self.patternDiscovered = patternDiscovered
        self.milestoneReached = milestoneReached
    }
}

/// 家庭统计
public struct FamilyStatistics: Codable, Equatable {
    public var totalDreams: Int
    public var activeMembers: Int
    public var totalChallenges: Int
    public var completedChallenges: Int
    public var discoveredPatterns: Int
    public var familyLevel: Int
    public var familyXP: Int
    public var createdAt: Date
    
    public init(
        totalDreams: Int = 0,
        activeMembers: Int = 0,
        totalChallenges: Int = 0,
        completedChallenges: Int = 0,
        discoveredPatterns: Int = 0,
        familyLevel: Int = 1,
        familyXP: Int = 0,
        createdAt: Date = Date()
    ) {
        self.totalDreams = totalDreams
        self.activeMembers = activeMembers
        self.totalChallenges = totalChallenges
        self.completedChallenges = completedChallenges
        self.discoveredPatterns = discoveredPatterns
        self.familyLevel = familyLevel
        self.familyXP = familyXP
        self.createdAt = createdAt
    }
    
    /// 计算升级到下一级所需经验
    public var xpForNextLevel: Int {
        return familyLevel * 1000
    }
    
    /// 计算当前等级进度百分比
    public var levelProgress: Double {
        let currentLevelXP = (familyLevel - 1) * 1000
        let xpInCurrentLevel = familyXP - currentLevelXP
        return min(1.0, Double(xpInCurrentLevel) / Double(xpForNextLevel))
    }
}

// MARK: - Family Member Models

/// 家庭成员
public struct FamilyMember: Identifiable, Codable, Equatable {
    public let id: UUID
    public let userId: UUID
    public let familyId: UUID
    public var nickname: String
    public var avatar: Data?
    public var relationship: Relationship
    public var role: MemberRole
    public let joinedAt: Date
    public var permissions: [MemberPermission]
    public var isActive: Bool
    public var lastActiveAt: Date?
    public var dreamCount: Int
    public var contributionPoints: Int
    
    public init(
        id: UUID = UUID(),
        userId: UUID,
        familyId: UUID,
        nickname: String,
        avatar: Data? = nil,
        relationship: Relationship,
        role: MemberRole,
        joinedAt: Date = Date(),
        permissions: [MemberPermission] = [],
        isActive: Bool = true,
        lastActiveAt: Date? = nil,
        dreamCount: Int = 0,
        contributionPoints: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.familyId = familyId
        self.nickname = nickname
        self.avatar = avatar
        self.relationship = relationship
        self.role = role
        self.joinedAt = joinedAt
        self.permissions = permissions
        self.isActive = isActive
        self.lastActiveAt = lastActiveAt
        self.dreamCount = dreamCount
        self.contributionPoints = contributionPoints
    }
    
    /// 成员默认权限
    public static func defaultPermissions(for role: MemberRole) -> [MemberPermission] {
        switch role {
        case .admin:
            return [.viewDreams, .shareDreams, .inviteMembers, .removeMembers, .editSettings, .createChallenges, .viewPatterns]
        case .adult:
            return [.viewDreams, .shareDreams, .createChallenges, .viewPatterns]
        case .child:
            return [.viewDreams, .shareDreams]
        }
    }
}

/// 家庭成员关系
public enum Relationship: String, Codable, CaseIterable {
    case selfRel = "self"
    case parent = "parent"
    case child = "child"
    case spouse = "spouse"
    case sibling = "sibling"
    case grandparent = "grandparent"
    case grandchild = "grandchild"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .selfRel: return "自己"
        case .parent: return "父母"
        case .child: return "孩子"
        case .spouse: return "配偶"
        case .sibling: return "兄弟姐妹"
        case .grandparent: return "祖父母"
        case .grandchild: return "孙辈"
        case .other: return "其他"
        }
    }
    
    public var icon: String {
        switch self {
        case .selfRel: return "👤"
        case .parent: return "👨‍👦"
        case .child: return "👶"
        case .spouse: return "💑"
        case .sibling: return "👫"
        case .grandparent: return "👴"
        case .grandchild: return "👧"
        case .other: return "👥"
        }
    }
}

/// 家庭成员角色
public enum MemberRole: String, Codable, CaseIterable {
    case admin = "admin"
    case adult = "adult"
    case child = "child"
    
    public var displayName: String {
        switch self {
        case .admin: return "👑 管理员"
        case .adult: return "👤 成人"
        case .child: return "🧒 儿童"
        }
    }
    
    /// 是否为儿童账户
    public var isChild: Bool {
        return self == .child
    }
}

/// 成员权限
public enum MemberPermission: String, Codable, CaseIterable {
    case viewDreams = "view_dreams"
    case shareDreams = "share_dreams"
    case inviteMembers = "invite_members"
    case removeMembers = "remove_members"
    case editSettings = "edit_settings"
    case createChallenges = "create_challenges"
    case viewPatterns = "view_patterns"
}

// MARK: - Shared Dream Models

/// 共享梦境
public struct SharedDream: Identifiable, Codable, Equatable {
    public let id: UUID
    public let dreamId: UUID
    public let ownerId: UUID
    public let ownerName: String
    public let familyId: UUID
    public var title: String
    public var content: String
    public var emotions: [String]
    public var tags: [String]
    public var dreamDate: Date
    public let sharedAt: Date
    public var privacyLevel: PrivacyLevel
    public var visibleTo: [UUID]? // 特定成员可见（nil 表示所有成员）
    public var reactions: [FamilyReaction]
    public var comments: [FamilyComment]
    public var isSensitive: Bool
    
    public init(
        id: UUID = UUID(),
        dreamId: UUID,
        ownerId: UUID,
        ownerName: String,
        familyId: UUID,
        title: String,
        content: String,
        emotions: [String] = [],
        tags: [String] = [],
        dreamDate: Date = Date(),
        sharedAt: Date = Date(),
        privacyLevel: PrivacyLevel = .family,
        visibleTo: [UUID]? = nil,
        reactions: [FamilyReaction] = [],
        comments: [FamilyComment] = [],
        isSensitive: Bool = false
    ) {
        self.id = id
        self.dreamId = dreamId
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.familyId = familyId
        self.title = title
        self.content = content
        self.emotions = emotions
        self.tags = tags
        self.dreamDate = dreamDate
        self.sharedAt = sharedAt
        self.privacyLevel = privacyLevel
        self.visibleTo = visibleTo
        self.reactions = reactions
        self.comments = comments
        self.isSensitive = isSensitive
    }
    
    /// 检查某成员是否可见
    public func isVisible(to memberId: UUID) -> Bool {
        if privacyLevel == .privateLevel {
            return ownerId == memberId
        }
        
        if let visibleTo = visibleTo {
            return visibleTo.contains(memberId)
        }
        
        return privacyLevel == .family || privacyLevel == .publicLevel
    }
}

/// 家庭反应
public struct FamilyReaction: Identifiable, Codable, Equatable {
    public let id: UUID
    public let memberId: UUID
    public let memberName: String
    public let emoji: String
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        memberId: UUID,
        memberName: String,
        emoji: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.emoji = emoji
        self.createdAt = createdAt
    }
}

/// 家庭评论
public struct FamilyComment: Identifiable, Codable, Equatable {
    public let id: UUID
    public let memberId: UUID
    public let memberName: String
    public var content: String
    public let createdAt: Date
    public var isEdited: Bool
    
    public init(
        id: UUID = UUID(),
        memberId: UUID,
        memberName: String,
        content: String,
        createdAt: Date = Date(),
        isEdited: Bool = false
    ) {
        self.id = id
        self.memberId = memberId
        self.memberName = memberName
        self.content = content
        self.createdAt = createdAt
        self.isEdited = isEdited
    }
}

// MARK: - Family Pattern Models

/// 家族梦境模式
public struct FamilyPattern: Identifiable, Codable, Equatable {
    public let id: UUID
    public let familyId: UUID
    public var patternType: PatternType
    public var title: String
    public var description: String
    public var involvedMembers: [UUID]
    public var memberNames: [String]
    public var dreamIds: [UUID]
    public var dreamCount: Int
    public var confidence: Double
    public let createdAt: Date
    public var lastUpdatedAt: Date
    public var isDiscovered: Bool
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        patternType: PatternType,
        title: String,
        description: String,
        involvedMembers: [UUID],
        memberNames: [String] = [],
        dreamIds: [UUID] = [],
        dreamCount: Int = 0,
        confidence: Double = 0.0,
        createdAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        isDiscovered: Bool = false
    ) {
        self.id = id
        self.familyId = familyId
        self.patternType = patternType
        self.title = title
        self.description = description
        self.involvedMembers = involvedMembers
        self.memberNames = memberNames
        self.dreamIds = dreamIds
        self.dreamCount = dreamCount
        self.confidence = confidence
        self.createdAt = createdAt
        self.lastUpdatedAt = lastUpdatedAt
        self.isDiscovered = isDiscovered
    }
}

/// 模式类型
public enum PatternType: String, Codable, CaseIterable {
    case commonSymbols = "common_symbols"      // 共同符号
    case sharedThemes = "shared_themes"        // 共同主题
    case emotionalInheritance = "emotional_inheritance" // 情绪传承
    case recurringScenes = "recurring_scenes"  // 重复场景
    case generationalDreams = "generational_dreams" // 代际梦境
    case lucidDreamTendency = "lucid_dream_tendency" // 清醒梦倾向
    
    public var displayName: String {
        switch self {
        case .commonSymbols: return "🔮 共同符号"
        case .sharedThemes: return "📖 共同主题"
        case .emotionalInheritance: return "💝 情绪传承"
        case .recurringScenes: return "🏠 重复场景"
        case .generationalDreams: return "🌳 代际梦境"
        case .lucidDreamTendency: return "✨ 清醒梦倾向"
        }
    }
    
    public var icon: String {
        switch self {
        case .commonSymbols: return "🔮"
        case .sharedThemes: return "📖"
        case .emotionalInheritance: return "💝"
        case .recurringScenes: return "🏠"
        case .generationalDreams: return "🌳"
        case .lucidDreamTendency: return "✨"
        }
    }
}

// MARK: - Family Challenge Models

/// 家庭挑战
public struct FamilyChallenge: Identifiable, Codable, Equatable {
    public let id: UUID
    public let familyId: UUID
    public let creatorId: UUID
    public var title: String
    public var description: String
    public var challengeType: ChallengeType
    public let startDate: Date
    public let endDate: Date
    public var participants: [UUID]
    public var submissions: [ChallengeSubmission]
    public var status: ChallengeStatus
    public var prize: String?
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        creatorId: UUID,
        title: String,
        description: String,
        challengeType: ChallengeType,
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60), // 默认 7 天
        participants: [UUID] = [],
        submissions: [ChallengeSubmission] = [],
        status: ChallengeStatus = .active,
        prize: String? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.creatorId = creatorId
        self.title = title
        self.description = description
        self.challengeType = challengeType
        self.startDate = startDate
        self.endDate = endDate
        self.participants = participants
        self.submissions = submissions
        self.status = status
        self.prize = prize
    }
    
    /// 剩余天数
    public var daysRemaining: Int {
        let now = Date()
        if now > endDate {
            return 0
        }
        return Calendar.current.dateComponents([.day], from: now, to: endDate).day ?? 0
    }
    
    /// 参与进度
    public var participationRate: Double {
        guard !participants.isEmpty else { return 0 }
        return Double(submissions.count) / Double(participants.count)
    }
}

/// 挑战类型
public enum ChallengeType: String, Codable, CaseIterable {
    case dreamCount = "dream_count"          // 记录数量挑战
    case lucidDream = "lucid_dream"          // 清醒梦挑战
    case themeChallenge = "theme_challenge"  // 主题挑战
    case dreamIncubation = "dream_incubation" // 梦境孵化挑战
    case dreamArt = "dream_art"              // 梦境绘画挑战
    case dreamSharing = "dream_sharing"      // 分享挑战
    
    public var displayName: String {
        switch self {
        case .dreamCount: return "📝 记录达人"
        case .lucidDream: return "✨ 清醒梦大师"
        case .themeChallenge: return "🎯 主题挑战"
        case .dreamIncubation: return "🌙 梦境孵化"
        case .dreamArt: return "🎨 梦境画家"
        case .dreamSharing: return "💬 分享之星"
        }
    }
}

/// 挑战状态
public enum ChallengeStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case expired = "expired"
    
    public var displayName: String {
        switch self {
        case .active: return "🔥 进行中"
        case .completed: return "✅ 已完成"
        case .expired: return "⏰ 已过期"
        }
    }
}

/// 挑战提交
public struct ChallengeSubmission: Identifiable, Codable, Equatable {
    public let id: UUID
    public let challengeId: UUID
    public let participantId: UUID
    public let participantName: String
    public var dreamIds: [UUID]
    public var note: String?
    public let submittedAt: Date
    public var points: Int
    
    public init(
        id: UUID = UUID(),
        challengeId: UUID,
        participantId: UUID,
        participantName: String,
        dreamIds: [UUID] = [],
        note: String? = nil,
        submittedAt: Date = Date(),
        points: Int = 0
    ) {
        self.id = id
        self.challengeId = challengeId
        self.participantId = participantId
        self.participantName = participantName
        self.dreamIds = dreamIds
        self.note = note
        self.submittedAt = submittedAt
        self.points = points
    }
}

// MARK: - Family Achievement Models

/// 家庭成就
public struct FamilyAchievement: Identifiable, Codable, Equatable {
    public let id: UUID
    public let familyId: UUID
    public var achievementType: AchievementType
    public var title: String
    public var description: String
    public var icon: String
    public let unlockedAt: Date
    public var unlockedBy: [UUID]
    public var progress: Double
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        achievementType: AchievementType,
        title: String,
        description: String,
        icon: String,
        unlockedAt: Date = Date(),
        unlockedBy: [UUID] = [],
        progress: Double = 1.0
    ) {
        self.id = id
        self.familyId = familyId
        self.achievementType = achievementType
        self.title = title
        self.description = description
        self.icon = icon
        self.unlockedAt = unlockedAt
        self.unlockedBy = unlockedBy
        self.progress = progress
    }
}

/// 成就类型
public enum AchievementType: String, Codable, CaseIterable {
    case firstDream = "first_dream"              // 第一个家庭梦境
    case hundredDreams = "hundred_dreams"        // 100 个家庭梦境
    case activeFamily = "active_family"          // 活跃家庭
    case patternDiscovered = "pattern_discovered" // 发现模式
    case challengeMaster = "challenge_master"    // 挑战大师
    case generationalConnection = "generational_connection" // 代际连接
    
    public var displayName: String {
        switch self {
        case .firstDream: return "🌟 家庭首梦"
        case .hundredDreams: return "💯 百梦家庭"
        case .activeFamily: return "🔥 活跃家庭"
        case .patternDiscovered: return "🔮 模式发现者"
        case .challengeMaster: return "🏆 挑战大师"
        case .generationalConnection: return "🌳 代际连接"
        }
    }
}

// MARK: - Invite Models

/// 家庭邀请
public struct FamilyInvite: Identifiable, Codable, Equatable {
    public let id: UUID
    public let familyId: UUID
    public let familyName: String
    public let inviterId: UUID
    public let inviterName: String
    public let inviteCode: String
    public let createdAt: Date
    public let expiresAt: Date
    public var isUsed: Bool
    public var usedBy: UUID?
    
    public init(
        id: UUID = UUID(),
        familyId: UUID,
        familyName: String,
        inviterId: UUID,
        inviterName: String,
        inviteCode: String,
        createdAt: Date = Date(),
        expiresAt: Date = Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 天有效期
        isUsed: Bool = false,
        usedBy: UUID? = nil
    ) {
        self.id = id
        self.familyId = familyId
        self.familyName = familyName
        self.inviterId = inviterId
        self.inviterName = inviterName
        self.inviteCode = inviteCode
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isUsed = isUsed
        self.usedBy = usedBy
    }
    
    /// 是否已过期
    public var isExpired: Bool {
        return Date() > expiresAt || isUsed
    }
}
