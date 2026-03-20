//
//  DreamCollaborationPermissions.swift
//  DreamLog - 协作权限控制
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import Foundation

// MARK: - 权限定义

/// 协怍权限类型
enum CollaborationPermission: String, CaseIterable {
    case view = "查看"
    case addInterpretation = "添加解读"
    case editOwnInterpretation = "编辑自己的解读"
    case deleteOwnInterpretation = "删除自己的解读"
    case vote = "投票"
    case comment = "评论"
    case editOwnComment = "编辑自己的评论"
    case deleteOwnComment = "删除自己的评论"
    case inviteParticipants = "邀请参与者"
    case removeParticipants = "移除参与者"
    case editSession = "编辑会话"
    case deleteSession = "删除会话"
    case moderateContent = "审核内容"
    case adoptInterpretation = "采纳解读"
    case closeSession = "关闭会话"
    case manageRoles = "管理角色"
    
    var icon: String {
        switch self {
        case .view: return "👁️"
        case .addInterpretation: return "➕"
        case .editOwnInterpretation: return "✏️"
        case .deleteOwnInterpretation: return "🗑️"
        case .vote: return "👍"
        case .comment: return "💬"
        case .editOwnComment: return "✏️"
        case .deleteOwnComment: return "🗑️"
        case .inviteParticipants: return "📧"
        case .removeParticipants: return "❌"
        case .editSession: return "📝"
        case .deleteSession: return "🗑️"
        case .moderateContent: return "🛡️"
        case .adoptInterpretation: return "✅"
        case .closeSession: return "🔒"
        case .manageRoles: return "👑"
        }
    }
}

// MARK: - 权限检查器

/// 协作权限检查器
struct CollaborationPermissionChecker {
    
    /// 检查用户是否有指定权限
    static func hasPermission(
        userRole: ParticipantRole,
        isOwner: Bool,
        permission: CollaborationPermission
    ) -> Bool {
        switch userRole {
        case .owner:
            return true // 创建者拥有所有权限
            
        case .moderator:
            return hasModeratorPermission(permission)
            
        case .member:
            return hasMemberPermission(permission)
            
        case .observer:
            return hasObserverPermission(permission)
        }
    }
    
    /// 检查 moderator 权限
    private static func hasModeratorPermission(_ permission: CollaborationPermission) -> Bool {
        let moderatorPermissions: Set<CollaborationPermission> = [
            .view,
            .addInterpretation,
            .editOwnInterpretation,
            .deleteOwnInterpretation,
            .vote,
            .comment,
            .editOwnComment,
            .deleteOwnComment,
            .inviteParticipants,
            .moderateContent,
            .adoptInterpretation
        ]
        return moderatorPermissions.contains(permission)
    }
    
    /// 检查 member 权限
    private static func hasMemberPermission(_ permission: CollaborationPermission) -> Bool {
        let memberPermissions: Set<CollaborationPermission> = [
            .view,
            .addInterpretation,
            .editOwnInterpretation,
            .deleteOwnInterpretation,
            .vote,
            .comment,
            .editOwnComment,
            .deleteOwnComment
        ]
        return memberPermissions.contains(permission)
    }
    
    /// 检查 observer 权限
    private static func hasObserverPermission(_ permission: CollaborationPermission) -> Bool {
        let observerPermissions: Set<CollaborationPermission> = [
            .view
        ]
        return observerPermissions.contains(permission)
    }
    
    /// 检查是否可以编辑解读
    static func canEditInterpretation(
        userRole: ParticipantRole,
        isOwner: Bool,
        interpretationOwnerId: String,
        currentUserId: String
    ) -> Bool {
        // 创建者可以编辑任何解读
        if isOwner { return true }
        
        // 用户可以编辑自己的解读
        if interpretationOwnerId == currentUserId {
            return hasPermission(userRole: userRole, isOwner: false, permission: .editOwnInterpretation)
        }
        
        // 主持人可以编辑任何解读
        if userRole == .moderator { return true }
        
        return false
    }
    
    /// 检查是否可以删除解读
    static func canDeleteInterpretation(
        userRole: ParticipantRole,
        isOwner: Bool,
        interpretationOwnerId: String,
        currentUserId: String
    ) -> Bool {
        // 创建者可以删除任何解读
        if isOwner { return true }
        
        // 用户可以删除自己的解读
        if interpretationOwnerId == currentUserId {
            return hasPermission(userRole: userRole, isOwner: false, permission: .deleteOwnInterpretation)
        }
        
        // 主持人可以删除任何解读
        if userRole == .moderator { return true }
        
        return false
    }
    
    /// 检查是否可以审核内容
    static func canModerateContent(userRole: ParticipantRole, isOwner: Bool) -> Bool {
        if isOwner { return true }
        return userRole == .moderator
    }
    
    /// 检查是否可以采纳解读
    static func canAdoptInterpretation(userRole: ParticipantRole, isOwner: Bool) -> Bool {
        if isOwner { return true }
        return userRole == .moderator
    }
    
    /// 检查是否可以管理参与者
    static func canManageParticipants(userRole: ParticipantRole, isOwner: Bool) -> Bool {
        if isOwner { return true }
        return userRole == .moderator
    }
}

// MARK: - 内容审核

/// 内容审核状态
enum ContentModerationStatus: String, Codable {
    case pending = "待审核"
    case approved = "已通过"
    case rejected = "已拒绝"
    case hidden = "已隐藏"
    
    var icon: String {
        switch self {
        case .pending: return "⏳"
        case .approved: return "✅"
        case .rejected: return "❌"
        case .hidden: return "👁️"
        }
    }
}

/// 内容审核记录
struct ContentModerationRecord: Codable {
    var id: UUID
    var contentId: String // 解读或评论 ID
    var contentType: ContentType
    var reportedBy: String // 举报者 ID
    var reason: ReportReason
    var description: String?
    var createdAt: Date
    var status: ContentModerationStatus
    var reviewedBy: String? // 审核者 ID
    var reviewedAt: Date?
    var reviewNotes: String?
    
    init(
        contentId: String,
        contentType: ContentType,
        reportedBy: String,
        reason: ReportReason,
        description: String? = nil
    ) {
        self.id = UUID()
        self.contentId = contentId
        self.contentType = contentType
        self.reportedBy = reportedBy
        self.reason = reason
        self.description = description
        self.createdAt = Date()
        self.status = .pending
    }
}

/// 内容类型
enum ContentType: String, Codable {
    case interpretation = "解读"
    case comment = "评论"
    case session = "会话"
}

/// 举报原因
enum ReportReason: String, Codable, CaseIterable {
    case spam = "垃圾内容"
    case harassment = "骚扰"
    case misinformation = "虚假信息"
    case inappropriate = "不当内容"
    case copyright = "版权侵犯"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .spam: return "🗑️"
        case .harassment: return "😠"
        case .misinformation: return "❌"
        case .inappropriate: return "⚠️"
        case .copyright: return "©️"
        case .other: return "📝"
        }
    }
    
    var description: String {
        switch self {
        case .spam: return "广告、重复内容或无意义内容"
        case .harassment: return "人身攻击、威胁或骚扰行为"
        case .misinformation: return "虚假或误导性信息"
        case .inappropriate: return "不适合公开的内容"
        case .copyright: return "侵犯版权的内容"
        case .other: return "其他原因"
        }
    }
}

/// 内容审核服务
actor ContentModerationService {
    private var reports: [ContentModerationRecord] = []
    private let autoHideThreshold = 3 // 自动隐藏阈值
    
    /// 提交举报
    func submitReport(
        contentId: String,
        contentType: ContentType,
        reportedBy: String,
        reason: ReportReason,
        description: String? = nil
    ) -> ContentModerationRecord {
        let report = ContentModerationRecord(
            contentId: contentId,
            contentType: contentType,
            reportedBy: reportedBy,
            reason: reason,
            description: description
        )
        reports.append(report)
        return report
    }
    
    /// 获取内容的举报数量
    func getReportCount(contentId: String) -> Int {
        reports.filter { $0.contentId == contentId && $0.status == .pending }.count
    }
    
    /// 检查内容是否应自动隐藏
    func shouldAutoHide(contentId: String) -> Bool {
        getReportCount(contentId: contentId) >= autoHideThreshold
    }
    
    /// 审核举报
    func reviewReport(
        reportId: UUID,
        reviewedBy: String,
        status: ContentModerationStatus,
        notes: String? = nil
    ) -> Bool {
        guard let index = reports.firstIndex(where: { $0.id == reportId }) else {
            return false
        }
        
        reports[index].status = status
        reports[index].reviewedBy = reviewedBy
        reports[index].reviewedAt = Date()
        reports[index].reviewNotes = notes
        
        return true
    }
    
    /// 获取待审核举报列表
    func getPendingReports() -> [ContentModerationRecord] {
        reports.filter { $0.status == .pending }
    }
}

// MARK: - 会话访问控制

/// 会话访问检查结果
struct SessionAccessResult {
    var canAccess: Bool
    var reason: AccessDenialReason?
    var requiredAction: RequiredAction?
}

/// 拒绝访问原因
enum AccessDenialReason: String {
    case sessionNotFound = "会话不存在"
    case sessionExpired = "会话已过期"
    case sessionClosed = "会话已关闭"
    case notParticipant = "不是参与者"
    case visibilityRestricted = "可见性受限"
    case userBanned = "用户已被禁止"
}

/// 需要执行的操作
enum RequiredAction {
    case requestAccess // 请求访问
    case joinSession // 加入会话
    case enterInviteCode // 输入邀请码
}

/// 会话访问控制器
struct SessionAccessController {
    
    /// 检查用户是否可以访问会话
    static func checkAccess(
        session: DreamCollaborationSession?,
        userId: String,
        isParticipant: Bool
    ) -> SessionAccessResult {
        // 检查会话是否存在
        guard let session = session else {
            return SessionAccessResult(
                canAccess: false,
                reason: .sessionNotFound,
                requiredAction: nil
            )
        }
        
        // 检查会话是否过期
        if let expires = session.expiresAt, Date() > expires {
            return SessionAccessResult(
                canAccess: false,
                reason: .sessionExpired,
                requiredAction: nil
            )
        }
        
        // 检查会话是否已关闭
        if session.status != .active {
            return SessionAccessResult(
                canAccess: false,
                reason: .sessionClosed,
                requiredAction: nil
            )
        }
        
        // 根据可见性检查访问权限
        switch session.visibility {
        case .private:
            if !isParticipant {
                return SessionAccessResult(
                    canAccess: false,
                    reason: .visibilityRestricted,
                    requiredAction: .requestAccess
                )
            }
            
        case .friends:
            if !isParticipant {
                // 检查是否是好友
                let isFriend = session.participants.contains { participant in
                    participant.userId == userId && participant.role != .observer
                }
                
                if !isFriend {
                    return SessionAccessResult(
                        canAccess: false,
                        reason: .visibilityRestricted,
                        requiredAction: .requestAccess
                    )
                }
            }
            
        case .public:
            // 公开会话，任何人都可以查看
            break
        }
        
        // 检查是否是参与者
        if !isParticipant {
            return SessionAccessResult(
                canAccess: true, // 可以查看但不能参与
                reason: nil,
                requiredAction: .joinSession
            )
        }
        
        return SessionAccessResult(
            canAccess: true,
            reason: nil,
            requiredAction: nil
        )
    }
    
    /// 验证邀请码
    static func verifyInviteCode(session: DreamCollaborationSession, code: String) -> Bool {
        session.inviteCode.uppercased() == code.uppercased()
    }
}
