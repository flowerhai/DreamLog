//
//  DreamCollaborationModels.swift
//  DreamLog - 梦境协作解读数据模型
//
//  Phase 67: 梦境协作解读板
//  创建时间：2026-03-18
//

import Foundation
import SwiftData

// MARK: - 协作会话模型

/// 协作会话状态
enum CollaborationSessionStatus: String, Codable, CaseIterable {
    case active = "进行中"
    case completed = "已完成"
    case archived = "已归档"
    
    var description: String {
        switch self {
        case .active: return "🟢 进行中"
        case .completed: return "🔵 已完成"
        case .archived: return "⚪ 已归档"
        }
    }
}

/// 协作会话可见性
enum CollaborationVisibility: String, Codable, CaseIterable {
    case `private` = "私密"
    case friends = "仅好友"
    case `public` = "公开"
    
    var icon: String {
        switch self {
        case .private: return "🔒"
        case .friends: return "👥"
        case .public: return "🌍"
        }
    }
}

/// 协作会话主模型
@Model
final class DreamCollaborationSession {
    var id: UUID
    var dreamId: UUID
    var title: String
    var description: String
    var createdBy: String // 创建者 ID
    var createdAt: Date
    var updatedAt: Date
    var status: CollaborationSessionStatus
    var visibility: CollaborationVisibility
    var maxParticipants: Int
    var inviteCode: String // 6 位邀请码
    var expiresAt: Date? // 过期时间
    
    // 统计信息
    var participantCount: Int = 0
    var interpretationCount: Int = 0
    var voteCount: Int = 0
    var viewCount: Int = 0
    
    // 关系
    @Relationship(deleteRule: .cascade) var interpretations: [DreamInterpretation]
    @Relationship(deleteRule: .cascade) var comments: [CollaborationComment]
    @Relationship(deleteRule: .cascade) var participants: [CollaborationParticipant]
    
    init(
        dreamId: UUID,
        title: String,
        description: String,
        createdBy: String,
        visibility: CollaborationVisibility = .friends,
        maxParticipants: Int = 10
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.title = title
        self.description = description
        self.createdBy = createdBy
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = .active
        self.visibility = visibility
        self.maxParticipants = maxParticipants
        self.inviteCode = generateInviteCode()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) // 默认 7 天过期
    }
    
    // MARK: - Helper Methods
    
    /// 生成 6 位邀请码
    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        // chars is non-empty, randomElement() will never return nil
        return String((0..<6).compactMap { _ in chars.randomElement() })
    }
    
    /// 检查会话是否有效
    var isValid: Bool {
        guard status == .active else { return false }
        if let expires = expiresAt, Date() > expires { return false }
        return participantCount < maxParticipants
    }
    
    /// 获取剩余席位
    var availableSpots: Int {
        max(0, maxParticipants - participantCount)
    }
}

// MARK: - 参与者模型

/// 参与者角色
enum ParticipantRole: String, Codable, CaseIterable {
    case owner = "创建者"
    case moderator = "主持人"
    case member = "成员"
    case observer = "观察者"
    
    var icon: String {
        switch self {
        case .owner: return "👑"
        case .moderator: return "🛡️"
        case .member: return "👤"
        case .observer: return "👁️"
        }
    }
}

/// 协作参与者
@Model
final class CollaborationParticipant {
    var id: UUID
    var sessionId: UUID
    var userId: String
    var username: String
    var avatar: String?
    var role: ParticipantRole
    var joinedAt: Date
    var lastActiveAt: Date
    var contributionScore: Int = 0 // 贡献积分
    var isOnline: Bool = false
    
    init(
        sessionId: UUID,
        userId: String,
        username: String,
        avatar: String? = nil,
        role: ParticipantRole = .member
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.userId = userId
        self.username = username
        self.avatar = avatar
        self.role = role
        self.joinedAt = Date()
        self.lastActiveAt = Date()
    }
}

// MARK: - 解读贡献模型

/// 解读类型
enum InterpretationType: String, Codable, CaseIterable {
    case symbolic = "符号解读"
    case psychological = "心理分析"
    case spiritual = "精神启示"
    case cultural = "文化背景"
    case personal = "个人联想"
    case creative = "创意启发"
    
    var icon: String {
        switch self {
        case .symbolic: return "🔮"
        case .psychological: return "🧠"
        case .spiritual: return "✨"
        case .cultural: return "🏛️"
        case .personal: return "💭"
        case .creative: return "🎨"
        }
    }
    
    var color: String {
        switch self {
        case .symbolic: return "purple"
        case .psychological: return "blue"
        case .spiritual: return "gold"
        case .cultural: return "green"
        case .personal: return "pink"
        case .creative: return "orange"
        }
    }
}

/// 梦境解读贡献
@Model
final class DreamInterpretation {
    var id: UUID
    var sessionId: UUID
    var dreamId: UUID
    var authorId: String
    var authorName: String
    var authorAvatar: String?
    var content: String
    var type: InterpretationType
    var createdAt: Date
    var updatedAt: Date
    var voteCount: Int = 0
    var isAccepted: Bool = false // 是否被采纳为最佳解读
    var isEdited: Bool = false
    
    // 关系
    @Relationship(deleteRule: .cascade) var votes: [InterpretationVote]
    @Relationship(deleteRule: .cascade) var comments: [InterpretationComment]
    
    init(
        sessionId: UUID,
        dreamId: UUID,
        authorId: String,
        authorName: String,
        content: String,
        type: InterpretationType = .symbolic
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.dreamId = dreamId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.type = type
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 获取解读质量评分
    var qualityScore: Int {
        var score = voteCount * 2
        if isAccepted { score += 50 }
        if content.count > 100 { score += 10 }
        if content.count > 300 { score += 20 }
        return score
    }
}

// MARK: - 投票模型

/// 解读投票
@Model
final class InterpretationVote {
    var id: UUID
    var interpretationId: UUID
    var voterId: String
    var createdAt: Date
    
    init(interpretationId: UUID, voterId: String) {
        self.id = UUID()
        self.interpretationId = interpretationId
        self.voterId = voterId
        self.createdAt = Date()
    }
}

// MARK: - 评论模型

/// 协作评论（会话级别）
@Model
final class CollaborationComment {
    var id: UUID
    var sessionId: UUID
    var parentId: UUID? // 支持回复
    var authorId: String
    var authorName: String
    var authorAvatar: String?
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var voteCount: Int = 0
    var isEdited: Bool = false
    
    @Relationship(deleteRule: .cascade) var replies: [CollaborationComment]
    @Relationship(deleteRule: .cascade) var votes: [CommentVote]
    
    init(
        sessionId: UUID,
        authorId: String,
        authorName: String,
        content: String,
        parentId: UUID? = nil
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.parentId = parentId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

/// 解读评论
@Model
final class InterpretationComment {
    var id: UUID
    var interpretationId: UUID
    var authorId: String
    var authorName: String
    var content: String
    var createdAt: Date
    
    init(interpretationId: UUID, authorId: String, authorName: String, content: String) {
        self.id = UUID()
        self.interpretationId = interpretationId
        self.authorId = authorId
        self.authorName = authorName
        self.content = content
        self.createdAt = Date()
    }
}

/// 评论投票
@Model
final class CommentVote {
    var id: UUID
    var commentId: UUID
    var voterId: String
    var createdAt: Date
    
    init(commentId: UUID, voterId: String) {
        self.id = UUID()
        self.commentId = commentId
        self.voterId = voterId
        self.createdAt = Date()
    }
}

// MARK: - 通知模型

/// 协作通知类型
enum CollaborationNotificationType: String, Codable {
    case newParticipant = "新参与者加入"
    case newInterpretation = "新解读发布"
    case newComment = "新评论"
    case voteReceived = "收到投票"
    case interpretationAccepted = "解读被采纳"
    case sessionEnding = "会话即将结束"
    
    var icon: String {
        switch self {
        case .newParticipant: return "👋"
        case .newInterpretation: return "💡"
        case .newComment: return "💬"
        case .voteReceived: return "👍"
        case .interpretationAccepted: return "🏆"
        case .sessionEnding: return "⏰"
        }
    }
}

/// 协作通知
@Model
final class CollaborationNotification {
    var id: UUID
    var userId: String
    var sessionId: UUID
    var type: CollaborationNotificationType
    var title: String
    var message: String
    var isRead: Bool = false
    var createdAt: Date
    
    init(
        userId: String,
        sessionId: UUID,
        type: CollaborationNotificationType,
        title: String,
        message: String
    ) {
        self.id = UUID()
        self.userId = userId
        self.sessionId = sessionId
        self.type = type
        self.title = title
        self.message = message
        self.createdAt = Date()
    }
}

// MARK: - 统计模型

/// 协作会话统计
struct CollaborationStats {
    var totalSessions: Int = 0
    var activeSessions: Int = 0
    var totalInterpretations: Int = 0
    var totalComments: Int = 0
    var totalVotes: Int = 0
    var acceptedInterpretations: Int = 0
    var averageParticipantsPerSession: Double = 0
    var mostActiveType: InterpretationType?
    
    var completionRate: Double {
        guard totalSessions > 0 else { return 0 }
        return Double(acceptedInterpretations) / Double(totalSessions) * 100
    }
}

// MARK: - 筛选选项

/// 协作会话筛选选项
struct CollaborationFilterOptions {
    var status: CollaborationSessionStatus?
    var visibility: CollaborationVisibility?
    var sortBy: CollaborationSortOption = .recent
    var showOnlyJoined: Bool = false
    
    enum CollaborationSortOption: String, CaseIterable {
        case recent = "最近更新"
        case popular = "最热门"
        case interpretations = "解读最多"
        case participants = "参与者最多"
    }
}
