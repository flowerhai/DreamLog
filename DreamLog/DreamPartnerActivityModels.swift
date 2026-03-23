//
//  DreamPartnerActivityModels.swift
//  DreamLog
//
//  梦境伴侣活动动态 - 数据模型
//  Phase 88 Enhancement: 活动动态与通知增强
//

import Foundation
import SwiftData

// MARK: - 活动类型

/// 伴侣活动类型
enum PartnerActivityType: String, Codable, CaseIterable {
    case dreamShared = "dreamShared"           // 分享了梦境
    case dreamViewed = "dreamViewed"           // 查看了梦境
    case commentAdded = "commentAdded"         // 添加了评论
    case reactionAdded = "reactionAdded"       // 添加了反应
    case partnerConnected = "partnerConnected" // 建立了连接
    case inviteAccepted = "inviteAccepted"     // 接受了邀请
    case inviteSent = "inviteSent"             // 发送了邀请
    case permissionChanged = "permissionChanged" // 权限变更
    
    var displayText: String {
        switch self {
        case .dreamShared: return "分享了梦境"
        case .dreamViewed: return "查看了梦境"
        case .commentAdded: return "评论了梦境"
        case .reactionAdded: return "反应了梦境"
        case .partnerConnected: return "建立了连接"
        case .inviteAccepted: return "接受了邀请"
        case .inviteSent: return "发送了邀请"
        case .permissionChanged: return "权限变更"
        }
    }
    
    var icon: String {
        switch self {
        case .dreamShared: return "square.and.arrow.up"
        case .dreamViewed: return "eye"
        case .commentAdded: return "bubble.left"
        case .reactionAdded: return "heart"
        case .partnerConnected: return "link.badge.plus"
        case .inviteAccepted: return "checkmark.circle"
        case .inviteSent: return "paperplane"
        case .permissionChanged: return "lock.shield"
        }
    }
    
    var color: String {
        switch self {
        case .dreamShared: return "blue"
        case .dreamViewed: return "gray"
        case .commentAdded: return "green"
        case .reactionAdded: return "pink"
        case .partnerConnected: return "purple"
        case .inviteAccepted: return "green"
        case .inviteSent: return "orange"
        case .permissionChanged: return "yellow"
        }
    }
}

// MARK: - 活动记录模型

/// 伴侣活动记录
@Model
final class PartnerActivity {
    @Attribute(.unique) var id: String
    var type: PartnerActivityType
    var actorId: String
    var actorName: String
    var actorAvatar: String?
    var targetId: String?  // 梦境 ID 或伴侣 ID
    var targetTitle: String?  // 梦境标题或描述
    var content: String?  // 评论内容或额外信息
    var createdAt: Date
    var isRead: Bool
    var metadata: [String: String]?
    
    init(id: String = UUID().uuidString,
         type: PartnerActivityType,
         actorId: String,
         actorName: String,
         actorAvatar: String? = nil,
         targetId: String? = nil,
         targetTitle: String? = nil,
         content: String? = nil,
         createdAt: Date = Date(),
         isRead: Bool = false,
         metadata: [String: String]? = nil) {
        self.id = id
        self.type = type
        self.actorId = actorId
        self.actorName = actorName
        self.actorAvatar = actorAvatar
        self.targetId = targetId
        self.targetTitle = targetTitle
        self.content = content
        self.createdAt = createdAt
        self.isRead = isRead
        self.metadata = metadata
    }
    
    /// 格式化时间
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) 分钟前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) 小时前"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days) 天前"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd"
            return formatter.format(from: createdAt)
        }
    }
    
    /// 活动描述
    var activityDescription: String {
        switch type {
        case .dreamShared:
            return "\(actorName) 分享了梦境\"\(targetTitle ?? "")\""
        case .dreamViewed:
            return "\(actorName) 查看了你的梦境"
        case .commentAdded:
            return "\(actorName) 评论了：\(content ?? "")"
        case .reactionAdded:
            return "\(actorName) 表达了\(content ?? "喜欢")"
        case .partnerConnected:
            return "你与 \(actorName) 建立了梦境共享关系"
        case .inviteAccepted:
            return "\(actorName) 接受了你的邀请"
        case .inviteSent:
            return "你向 \(actorName) 发送了邀请"
        case .permissionChanged:
            return "权限已更新：\(content ?? "")"
        }
    }
}

// MARK: - 活动统计

/// 活动统计
struct PartnerActivityStats {
    var totalActivities: Int = 0
    var unreadCount: Int = 0
    var activitiesByType: [PartnerActivityType: Int] = [:]
    var recentActivities: [PartnerActivity] = []
    
    mutating func calculate(from activities: [PartnerActivity]) {
        totalActivities = activities.count
        unreadCount = activities.filter { !$0.isRead }.count
        recentActivities = Array(activities.prefix(20))
        
        for activity in activities {
            activitiesByType[activity.type, default: 0] += 1
        }
    }
}

// MARK: - 通知设置

/// 伴侣通知设置
struct PartnerNotificationSettings: Codable {
    var enableDreamShared: Bool = true
    var enableDreamViewed: Bool = false
    var enableCommentAdded: Bool = true
    var enableReactionAdded: Bool = true
    var enablePartnerConnected: Bool = true
    var enableInviteAccepted: Bool = true
    var quietHoursEnabled: Bool = true
    var quietHoursStart: String = "22:00"
    var quietHoursEnd: String = "08:00"
    
    /// 检查是否在安静时段
    var isQuietHours: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let start = formatter.date(from: quietHoursStart),
              let end = formatter.date(from: quietHoursEnd),
              let now = formatter.date(from: formatter.string(from: Date())) else {
            return false
        }
        
        if start > end {
            // 跨夜时段 (如 22:00 - 08:00)
            return now >= start || now <= end
        } else {
            return now >= start && now <= end
        }
    }
    
    /// 检查是否应该发送某类通知
    func shouldNotify(for type: PartnerActivityType) -> Bool {
        // 安静时段不发送非紧急通知
        if isQuietHours && type != .partnerConnected {
            return false
        }
        
        switch type {
        case .dreamShared: return enableDreamShared
        case .dreamViewed: return enableDreamViewed
        case .commentAdded: return enableCommentAdded
        case .reactionAdded: return enableReactionAdded
        case .partnerConnected: return enablePartnerConnected
        case .inviteAccepted: return enableInviteAccepted
        default: return true
        }
    }
}
