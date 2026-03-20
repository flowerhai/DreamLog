//
//  DreamMentionService.swift
//  DreamLog - @提及功能服务
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import Foundation

// MARK: - 提及模型

/// 提及信息
struct MentionInfo: Codable, Identifiable {
    var id: UUID
    var mentionedUserId: String
    var mentionedUsername: String
    var position: Int // 在文本中的位置
    var context: String // 提及的上下文
    
    init(mentionedUserId: String, mentionedUsername: String, position: Int, context: String = "") {
        self.id = UUID()
        self.mentionedUserId = mentionedUserId
        self.mentionedUsername = mentionedUsername
        self.position = position
        self.context = context
    }
}

/// 提及通知
struct MentionNotification: Codable {
    var id: UUID
    var fromUserId: String
    var fromUsername: String
    var toUserId: String
    var contentType: ContentType
    var contentId: String
    var contentPreview: String
    var createdAt: Date
    var isRead: Bool = false
    
    init(
        fromUserId: String,
        fromUsername: String,
        toUserId: String,
        contentType: ContentType,
        contentId: String,
        contentPreview: String
    ) {
        self.id = UUID()
        self.fromUserId = fromUserId
        self.fromUsername = fromUsername
        self.toUserId = toUserId
        self.contentType = contentType
        self.contentId = contentId
        self.contentPreview = contentPreview
        self.createdAt = Date()
    }
}

// MARK: - 提及服务

/// @提及服务
actor DreamMentionService {
    private var usernameToUserId: [String: String] = [:]
    private var notifications: [MentionNotification] = []
    
    /// 注册用户名到 ID 的映射
    func registerUser(username: String, userId: String) {
        usernameToUserId[username.lowercased()] = userId
    }
    
    /// 解析文本中的提及
    func parseMentions(text: String) -> [MentionInfo] {
        let mentions: [MentionInfo] = []
        
        // 匹配 @用户名 模式
        let pattern = "@(\\w+)"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return mentions
        }
        
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            guard let usernameRange = Range(match.range(at: 1), in: text) else { continue }
            
            let username = String(text[usernameRange])
            let position = match.range.location
            
            // 获取上下文（前后各 20 个字符）
            let contextStart = max(0, position - 20)
            let contextEnd = min(text.count, position + username.count + 20)
            let context = String(text[text.index(text.startIndex, offsetBy: contextStart)..<text.index(text.startIndex, offsetBy: contextEnd)])
            
            // 查找用户 ID
            if let userId = usernameToUserId[username.lowercased()] {
                let mention = MentionInfo(
                    mentionedUserId: userId,
                    mentionedUsername: username,
                    position: position,
                    context: context
                )
                mentions.append(mention)
            }
        }
        
        return mentions
    }
    
    /// 创建提及通知
    func createMentionNotification(
        fromUserId: String,
        fromUsername: String,
        toUserId: String,
        contentType: ContentType,
        contentId: String,
        contentPreview: String
    ) -> MentionNotification {
        let notification = MentionNotification(
            fromUserId: fromUserId,
            fromUsername: fromUsername,
            toUserId: toUserId,
            contentType: contentType,
            contentId: contentId,
            contentPreview: contentPreview
        )
        notifications.append(notification)
        return notification
    }
    
    /// 获取用户的未读提及通知
    func getUnreadMentions(userId: String) -> [MentionNotification] {
        notifications.filter { $0.toUserId == userId && !$0.isRead }
    }
    
    /// 标记提及为已读
    func markAsRead(notificationId: UUID) -> Bool {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else {
            return false
        }
        notifications[index].isRead = true
        return true
    }
    
    /// 标记所有提及为已读
    func markAllAsRead(userId: String) {
        for index in notifications.indices {
            if notifications[index].toUserId == userId {
                notifications[index].isRead = true
            }
        }
    }
    
    /// 获取提及通知数量
    func getUnreadCount(userId: String) -> Int {
        notifications.filter { $0.toUserId == userId && !$0.isRead }.count
    }
}

// MARK: - 提及文本处理

extension DreamMentionService {
    /// 将文本中的提及转换为可点击链接
    static func formatMentions(text: String, base_url: String = "dreamlog://user/") -> AttributedString {
        var attributedString = AttributedString(text)
        
        let pattern = "@(\\w+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return attributedString
        }
        
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        let matches = regex.matches(in: text, options: [], range: range)
        
        // 从后向前处理，避免索引偏移
        for match in matches.reversed() {
            guard let usernameRange = Range(match.range(at: 1), in: text) else { continue }
            
            let username = String(text[usernameRange])
            let fullRange = Range(match.range, in: text)!
            
            // 创建链接属性
            var mentionAttr = AttributedString("@\(username)")
            mentionAttr.link = URL(string: "\(base_url)\(username)")
            mentionAttr.foregroundColor = .systemBlue
            mentionAttr.font = .systemFont(ofSize: 14, weight: .medium)
            
            // 替换原文本
            attributedString.replaceSubrange(fullRange, with: mentionAttr)
        }
        
        return attributedString
    }
    
    /// 移除文本中的提及标记（用于纯文本显示）
    static func stripMentions(text: String) -> String {
        let pattern = "@\\w+"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: ""
        )
    }
}

// MARK: - 提及建议

/// 提及建议结果
struct MentionSuggestion: Identifiable {
    var id: String { userId }
    var userId: String
    var username: String
    var displayName: String
    var avatar: String?
    var matchScore: Int // 匹配分数
}

/// 提及建议服务
actor MentionSuggestionService {
    private var users: [(userId: String, username: String, displayName: String, avatar: String?)] = []
    
    /// 注册用户
    func registerUser(userId: String, username: String, displayName: String, avatar: String? = nil) {
        users.append((userId, username, displayName, avatar))
    }
    
    /// 获取提及建议
    func getSuggestions(query: String, limit: Int = 5) -> [MentionSuggestion] {
        let queryLower = query.lowercased()
        
        var suggestions: [MentionSuggestion] = users.compactMap { user in
            let usernameMatch = user.username.lowercased().contains(queryLower)
            let displayNameMatch = user.displayName.lowercased().contains(queryLower)
            
            if usernameMatch || displayNameMatch {
                let score = usernameMatch ? 10 : 5
                return MentionSuggestion(
                    userId: user.userId,
                    username: user.username,
                    displayName: user.displayName,
                    avatar: user.avatar,
                    matchScore: score
                )
            }
            return nil
        }
        
        // 按匹配分数排序
        suggestions.sort { $0.matchScore > $1.matchScore }
        
        return Array(suggestions.prefix(limit))
    }
}
