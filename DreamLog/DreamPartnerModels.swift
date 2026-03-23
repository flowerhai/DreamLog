//
//  DreamPartnerModels.swift
//  DreamLog
//
//  梦境伴侣共享系统 - 数据模型
//  Phase 88: 梦境伴侣与家庭共享
//

import Foundation
import SwiftData

// MARK: - 伴侣关系模型

/// 伴侣关系状态
enum PartnerStatus: String, Codable, CaseIterable {
    case pending = "pending"           // 等待对方接受
    case accepted = "accepted"         // 已接受
    case declined = "declined"         // 已拒绝
    case suspended = "suspended"       // 已暂停
    case revoked = "revoked"           // 已撤销
    
    var displayText: String {
        switch self {
        case .pending: return "等待接受"
        case .accepted: return "已连接"
        case .declined: return "已拒绝"
        case .suspended: return "已暂停"
        case .revoked: return "已撤销"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .accepted: return "green"
        case .declined: return "red"
        case .suspended: return "gray"
        case .revoked: return "red"
        }
    }
}

/// 共享权限级别
enum SharingPermission: String, Codable, CaseIterable {
    case viewOnly = "viewOnly"                 // 仅查看
    case viewAndComment = "viewAndComment"     // 查看 + 评论
    case fullAccess = "fullAccess"             // 完全访问 (包括统计)
    
    var displayText: String {
        switch self {
        case .viewOnly: return "仅查看"
        case .viewAndComment: return "查看 + 评论"
        case .fullAccess: return "完全访问"
        }
    }
    
    var description: String {
        switch self {
        case .viewOnly: return "伴侣可以查看你的梦境，但不能评论"
        case .viewAndComment: return "伴侣可以查看并评论你的梦境"
        case .fullAccess: return "伴侣可以查看、评论并看到统计洞察"
        }
    }
}

/// 梦境共享记录
@Model
final class DreamPartnerShare {
    @Attribute(.unique) var id: String
    var dreamId: String
    var partnerId: String
    var sharedAt: Date
    var viewedAt: Date?
    var comment: String?
    var reaction: String?
    var isHidden: Bool = false
    
    init(id: String = UUID().uuidString,
         dreamId: String,
         partnerId: String,
         sharedAt: Date = Date(),
         comment: String? = nil,
         reaction: String? = nil,
         isHidden: Bool = false) {
        self.id = id
        self.dreamId = dreamId
        self.partnerId = partnerId
        self.sharedAt = sharedAt
        self.comment = comment
        self.reaction = reaction
        self.isHidden = isHidden
    }
}

/// 伴侣关系模型
@Model
final class DreamPartner {
    @Attribute(.unique) var id: String
    var userId: String
    var partnerUserId: String
    var partnerName: String
    var partnerAvatar: String?
    var status: PartnerStatus
    var myPermission: SharingPermission  // 我允许对方访问的权限
    var theirPermission: SharingPermission // 对方允许我访问的权限
    var connectedAt: Date?
    var createdAt: Date
    var lastActiveAt: Date?
    var shareCount: Int = 0
    var isFavorite: Bool = false
    var notes: String?
    
    // 关系
    @Relationship(deleteRule: .cascade) var shares: [DreamPartnerShare]
    
    init(id: String = UUID().uuidString,
         userId: String,
         partnerUserId: String,
         partnerName: String,
         partnerAvatar: String? = nil,
         status: PartnerStatus = .pending,
         myPermission: SharingPermission = .viewOnly,
         theirPermission: SharingPermission = .viewOnly,
         connectedAt: Date? = nil,
         createdAt: Date = Date(),
         lastActiveAt: Date? = nil,
         shareCount: Int = 0,
         isFavorite: Bool = false,
         notes: String? = nil) {
        self.id = id
        self.userId = userId
        self.partnerUserId = partnerUserId
        self.partnerName = partnerName
        self.partnerAvatar = partnerAvatar
        self.status = status
        self.myPermission = myPermission
        self.theirPermission = theirPermission
        self.connectedAt = connectedAt
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.shareCount = shareCount
        self.isFavorite = isFavorite
        self.notes = notes
        self.shares = []
    }
}

// MARK: - 邀请码模型

/// 伴侣邀请
struct PartnerInvite: Codable, Identifiable {
    var id: String
    var code: String  // 6 位邀请码
    var inviterName: String
    var inviterAvatar: String?
    var message: String?
    var expiresAt: Date
    var createdAt: Date
    var isUsed: Bool
    var usedAt: Date?
    
    init(id: String = UUID().uuidString,
         code: String,
         inviterName: String,
         inviterAvatar: String? = nil,
         message: String? = nil,
         expiresAt: Date,
         createdAt: Date = Date(),
         isUsed: Bool = false,
         usedAt: Date? = nil) {
        self.id = id
        self.code = code
        self.inviterName = inviterName
        self.inviterAvatar = inviterAvatar
        self.message = message
        self.expiresAt = expiresAt
        self.createdAt = createdAt
        self.isUsed = isUsed
        self.usedAt = usedAt
    }
    
    /// 生成 6 位邀请码
    static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  // 去掉易混淆字符
        return String((0..<6).map { _ in chars.randomElement()! })
    }
    
    /// 检查是否过期
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    /// 剩余时间描述
    var timeRemaining: String {
        let remaining = expiresAt.timeIntervalSince(Date())
        if remaining <= 0 { return "已过期" }
        if remaining < 3600 { return "\(Int(remaining / 60))分钟" }
        if remaining < 86400 { return "\(Int(remaining / 3600))小时" }
        return "\(Int(remaining / 86400))天"
    }
}

// MARK: - 共享统计

/// 伴侣共享统计
struct PartnerSharingStats {
    var totalPartners: Int
    var activePartners: Int
    var pendingInvites: Int
    var totalShares: Int
    var totalViews: Int
    var totalComments: Int
    var mostSharedDreamId: String?
    var lastSharedAt: Date?
    
    var shareViewRate: Double {
        guard totalShares > 0 else { return 0 }
        return Double(totalViews) / Double(totalShares) * 100
    }
}

// MARK: - 共享设置

/// 伴侣共享配置
struct PartnerSharingConfig: Codable {
    var isEnabled: Bool
    var autoShareLucid: Bool  // 自动分享清醒梦
    var autoShareHighClarity: Bool  // 自动分享高清晰度梦境
    var defaultPermission: SharingPermission
    var notifyOnView: Bool
    var notifyOnComment: Bool
    var showInStats: Bool
    var allowTheirStats: Bool
    
    static var `default`: PartnerSharingConfig {
        PartnerSharingConfig(
            isEnabled: true,
            autoShareLucid: false,
            autoShareHighClarity: false,
            defaultPermission: .viewOnly,
            notifyOnView: true,
            notifyOnComment: true,
            showInStats: true,
            allowTheirStats: false
        )
    }
}

// MARK: - 联合洞察

/// 联合梦境洞察
struct JointInsight: Identifiable {
    var id: String
    var type: JointInsightType
    var title: String
    var description: String
    var confidence: Double  // 0-1
    var relatedDreamIds: [String]
    var createdAt: Date
    
    enum JointInsightType: String, Codable {
        case commonTheme = "commonTheme"       // 共同主题
        case complementaryEmotions = "complementaryEmotions"  // 互补情绪
        case synchronizedPatterns = "synchronizedPatterns"   // 同步模式
        case recurringElements = "recurringElements"         // 重复元素
        case contrastingStyles = "contrastingStyles"         // 对比风格
    }
}
