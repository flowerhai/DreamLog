//
//  DreamCollaborationNotifications.swift
//  DreamLog - 协作通知服务
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import Foundation
import UserNotifications

// MARK: - 协作通知类型

/// 协作通知类型
enum CollaborationNotificationType: String, Codable {
    case newParticipant = "新参与者"
    case newInterpretation = "新解读"
    case interpretationAdopted = "解读被采纳"
    case commentReply = "评论回复"
    case mention = "@提及"
    case sessionComplete = "会话完成"
    case invitation = "邀请加入"
    case roleChanged = "角色变更"
    
    var icon: String {
        switch self {
        case .newParticipant: return "👤"
        case .newInterpretation: return "💡"
        case .interpretationAdopted: return "✅"
        case .commentReply: return "💬"
        case .mention: return "@"
        case .sessionComplete: return "🎉"
        case .invitation: return "📧"
        case .roleChanged: return "👑"
        }
    }
    
    var categoryIdentifier: String {
        "DREAMLOG_COLLAB_\(rawValue.uppercased().replacingOccurrences(of: " ", with: "_"))"
    }
}

// MARK: - 协作通知模型

/// 协作通知
struct CollaborationNotification: Codable, Identifiable {
    var id: UUID
    var type: CollaborationNotificationType
    var title: String
    var body: String
    var sessionId: UUID?
    var sessionTitle: String?
    var fromUserId: String?
    var fromUsername: String?
    var targetUserId: String
    var createdAt: Date
    var isRead: Bool = false
    var actionUrl: String?
    
    init(
        type: CollaborationNotificationType,
        title: String,
        body: String,
        sessionId: UUID? = nil,
        sessionTitle: String? = nil,
        fromUserId: String? = nil,
        fromUsername: String? = nil,
        targetUserId: String,
        actionUrl: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.body = body
        self.sessionId = sessionId
        self.sessionTitle = sessionTitle
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.targetUserId = targetUserId
        self.createdAt = Date()
        self.actionUrl = actionUrl
    }
}

// MARK: - 通知设置

/// 用户通知设置
struct CollaborationNotificationSettings: Codable {
    var enabled: Bool = true
    var newParticipant: Bool = true
    var newInterpretation: Bool = true
    var interpretationAdopted: Bool = true
    var commentReply: Bool = true
    var mention: Bool = true
    var sessionComplete: Bool = true
    var invitation: Bool = true
    var roleChanged: Bool = true
    
    // 通知频率
    var frequency: NotificationFrequency = .immediate
    
    // 免打扰时间
    var quietHoursEnabled: Bool = true
    var quietHoursStart: String = "22:00"
    var quietHoursEnd: String = "08:00"
    
    /// 检查是否允许发送某类型通知
    func allowsType(_ type: CollaborationNotificationType) -> Bool {
        guard enabled else { return false }
        
        switch type {
        case .newParticipant: return newParticipant
        case .newInterpretation: return newInterpretation
        case .interpretationAdopted: return interpretationAdopted
        case .commentReply: return commentReply
        case .mention: return mention
        case .sessionComplete: return sessionComplete
        case .invitation: return invitation
        case .roleChanged: return roleChanged
        }
    }
}

/// 通知频率
enum NotificationFrequency: String, Codable, CaseIterable {
    case immediate = "即时"
    case hourly = "每小时汇总"
    case daily = "每日汇总"
    
    var icon: String {
        switch self {
        case .immediate: return "⚡"
        case .hourly: return "🕐"
        case .daily: return "📅"
        }
    }
}

// MARK: - 通知服务

/// 协作通知服务
actor DreamCollaborationNotificationService {
    private var notifications: [CollaborationNotification] = []
    private var userSettings: [String: CollaborationNotificationSettings] = [:]
    private var pendingNotifications: [String: [CollaborationNotification]] = [:] // userId -> notifications
    
    /// 获取用户通知设置
    func getSettings(userId: String) -> CollaborationNotificationSettings {
        userSettings[userId] ?? CollaborationNotificationSettings()
    }
    
    /// 更新用户通知设置
    func updateSettings(userId: String, settings: CollaborationNotificationSettings) {
        userSettings[userId] = settings
    }
    
    /// 发送通知
    func sendNotification(_ notification: CollaborationNotification) async {
        let settings = getSettings(userId: notification.targetUserId)
        
        // 检查用户是否允许此类型通知
        guard settings.allowsType(notification.type) else {
            return
        }
        
        // 检查免打扰时间
        if settings.quietHoursEnabled && isQuietHours(settings: settings) {
            // 存储待发送通知
            if pendingNotifications[notification.targetUserId] == nil {
                pendingNotifications[notification.targetUserId] = []
            }
            pendingNotifications[notification.targetUserId]?.append(notification)
            return
        }
        
        // 添加通知
        notifications.append(notification)
        
        // 根据频率处理
        switch settings.frequency {
        case .immediate:
            await scheduleLocalNotification(notification)
        case .hourly, .daily:
            // 存储待汇总通知
            if pendingNotifications[notification.targetUserId] == nil {
                pendingNotifications[notification.targetUserId] = []
            }
            pendingNotifications[notification.targetUserId]?.append(notification)
        }
    }
    
    /// 检查是否在免打扰时间
    private func isQuietHours(settings: CollaborationNotificationSettings) -> Bool {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: settings.quietHoursStart),
              let end = formatter.date(from: settings.quietHoursEnd) else {
            return false
        }
        
        let currentTime = formatter.string(from: now)
        
        if settings.quietHoursStart > settings.quietHoursEnd {
            // 跨夜情况（如 22:00 - 08:00）
            return currentTime >= settings.quietHoursStart || currentTime < settings.quietHoursEnd
        } else {
            return currentTime >= settings.quietHoursStart && currentTime < settings.quietHoursEnd
        }
    }
    
    /// 调度本地通知
    private func scheduleLocalNotification(_ notification: CollaborationNotification) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.categoryIdentifier = notification.type.categoryIdentifier
        content.sound = .default
        content.badge = 1
        
        // 添加用户头像（如果有）
        if let avatarUrl = notification.fromUserId, !avatarUrl.isEmpty {
            await attachAvatarToNotification(content: content, avatarUrl: avatarUrl)
        }
        
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil // 立即发送
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    /// 下载并附加用户头像到通知
    private func attachAvatarToNotification(content: UNMutableNotificationContent, avatarUrl: String) async {
        guard let url = URL(string: avatarUrl) else { return }
        
        do {
            // 下载头像图片
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 保存为临时文件
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("avatar_\(UUID().uuidString).jpg")
            try data.write(to: fileURL)
            
            // 创建通知附件
            let attachment = try UNNotificationAttachment(
                identifier: "avatar",
                url: fileURL,
                options: [
                    UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg",
                    UNNotificationAttachmentOptionsThumbnailHiddenKey: false
                ]
            )
            
            content.attachments = [attachment]
            
            // 清理临时文件（在通知发送后）
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            print("Failed to attach avatar: \(error)")
        }
    }
    
    /// 获取用户未读通知
    func getUnreadNotifications(userId: String, limit: Int = 50) -> [CollaborationNotification] {
        notifications
            .filter { $0.targetUserId == userId && !$0.isRead }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 获取用户所有通知
    func getNotifications(userId: String, limit: Int = 50) -> [CollaborationNotification] {
        notifications
            .filter { $0.targetUserId == userId }
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 标记通知为已读
    func markAsRead(notificationId: UUID) -> Bool {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else {
            return false
        }
        notifications[index].isRead = true
        return true
    }
    
    /// 标记所有通知为已读
    func markAllAsRead(userId: String) {
        for index in notifications.indices {
            if notifications[index].targetUserId == userId {
                notifications[index].isRead = true
            }
        }
    }
    
    /// 获取未读通知数量
    func getUnreadCount(userId: String) -> Int {
        notifications.filter { $0.targetUserId == userId && !$0.isRead }.count
    }
    
    /// 删除通知
    func deleteNotification(notificationId: UUID) -> Bool {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else {
            return false
        }
        notifications.remove(at: index)
        return true
    }
    
    /// 清除所有通知
    func clearAll(userId: String) {
        notifications.removeAll { $0.targetUserId == userId }
    }
    
    /// 发送待处理通知（免打扰时间结束后调用）
    func sendPendingNotifications(userId: String) async {
        guard let pending = pendingNotifications[userId], !pending.isEmpty else {
            return
        }
        
        // 创建汇总通知
        let summary = createSummaryNotification(userId: userId, notifications: pending)
        await sendNotification(summary)
        
        // 清空待处理队列
        pendingNotifications[userId] = nil
    }
    
    /// 创建汇总通知
    private func createSummaryNotification(userId: String, notifications: [CollaborationNotification]) -> CollaborationNotification {
        let count = notifications.count
        let types = Set(notifications.map { $0.type })
        
        var title: String
        var body: String
        
        if types.count == 1, let type = types.first {
            title = "\(count) 条\(type.rawValue)通知"
            body = "你有 \(count) 条新的\(type.rawValue.lowercased())"
        } else {
            title = "\(count) 条新通知"
            body = "你有 \(count) 条新的协作通知，快去查看吧"
        }
        
        return CollaborationNotification(
            type: .newInterpretation, // 使用默认类型
            title: title,
            body: body,
            targetUserId: userId
        )
    }
}

// MARK: - 通知工厂

extension DreamCollaborationNotificationService {
    /// 创建新参与者通知
    static func createNewParticipantNotification(
        participantName: String,
        sessionId: UUID,
        sessionTitle: String,
        targetUserId: String
    ) -> CollaborationNotification {
        CollaborationNotification(
            type: .newParticipant,
            title: "新参与者加入",
            body: "\(participantName) 加入了协作会话「\(sessionTitle)」",
            sessionId: sessionId,
            sessionTitle: sessionTitle,
            fromUsername: participantName,
            targetUserId: targetUserId,
            actionUrl: "dreamlog://collaboration/\(sessionId.uuidString)"
        )
    }
    
    /// 创建新解读通知
    static func createNewInterpretationNotification(
        authorName: String,
        sessionId: UUID,
        sessionTitle: String,
        targetUserId: String
    ) -> CollaborationNotification {
        CollaborationNotification(
            type: .newInterpretation,
            title: "新解读发布",
            body: "\(authorName) 在「\(sessionTitle)」中添加了解读",
            sessionId: sessionId,
            sessionTitle: sessionTitle,
            fromUsername: authorName,
            targetUserId: targetUserId,
            actionUrl: "dreamlog://collaboration/\(sessionId.uuidString)"
        )
    }
    
    /// 创建解读被采纳通知
    static func createInterpretationAdoptedNotification(
        sessionId: UUID,
        sessionTitle: String,
        targetUserId: String
    ) -> CollaborationNotification {
        CollaborationNotification(
            type: .interpretationAdopted,
            title: "解读被采纳",
            body: "你的解读在「\(sessionTitle)」中被采纳为最佳答案",
            sessionId: sessionId,
            sessionTitle: sessionTitle,
            targetUserId: targetUserId,
            actionUrl: "dreamlog://collaboration/\(sessionId.uuidString)"
        )
    }
    
    /// 创建@提及通知
    static func createMentionNotification(
        fromUsername: String,
        contentPreview: String,
        sessionId: UUID?,
        targetUserId: String
    ) -> CollaborationNotification {
        CollaborationNotification(
            type: .mention,
            title: "@提及",
            body: "\(fromUsername) 在评论中提及了你：\(contentPreview)",
            sessionId: sessionId,
            fromUserId: fromUsername,
            fromUsername: fromUsername,
            targetUserId: targetUserId,
            actionUrl: sessionId.map { "dreamlog://collaboration/\($0.uuidString)" }
        )
    }
    
    /// 创建会话完成通知
    static func createSessionCompleteNotification(
        sessionId: UUID,
        sessionTitle: String,
        targetUserId: String
    ) -> CollaborationNotification {
        CollaborationNotification(
            type: .sessionComplete,
            title: "会话完成",
            body: "协作会话「\(sessionTitle)」已完成，查看最终结果",
            sessionId: sessionId,
            sessionTitle: sessionTitle,
            targetUserId: targetUserId,
            actionUrl: "dreamlog://collaboration/\(sessionId.uuidString)"
        )
    }
    
    /// 创建邀请通知
    static func createInvitationNotification(
        inviterName: String,
        sessionId: UUID,
        sessionTitle: String,
        inviteCode: String,
        targetUserId: String
    ) -> CollaborationNotification {
        CollaborationNotification(
            type: .invitation,
            title: "协作邀请",
            body: "\(inviterName) 邀请你加入「\(sessionTitle)」，邀请码：\(inviteCode)",
            sessionId: sessionId,
            sessionTitle: sessionTitle,
            fromUsername: inviterName,
            targetUserId: targetUserId,
            actionUrl: "dreamlog://collaboration/join/\(inviteCode)"
        )
    }
}

// MARK: - 通知类别注册

extension DreamCollaborationNotificationService {
    /// 注册通知类别
    static func registerNotificationCategories() {
        let categories: [UNNotificationCategory] = CollaborationNotificationType.allCases.map { type in
            let category = UNNotificationCategory(
                identifier: type.categoryIdentifier,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
            return category
        }
        
        UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
    }
}
