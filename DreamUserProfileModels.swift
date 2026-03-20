//
//  DreamUserProfileModels.swift
//  DreamLog - 用户档案数据模型
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import Foundation
import SwiftData

// MARK: - 用户档案模型

/// 用户档案主模型
@Model
final class DreamUserProfile {
    var id: String // 用户 ID（主键）
    var username: String // 用户名
    var displayName: String // 显示名称
    var avatar: String? // 头像 URL 或数据
    var bio: String? // 个人简介
    var createdAt: Date
    var updatedAt: Date
    var lastLoginAt: Date?
    
    // 专长领域（梦境解析方向）
    var specialties: [DreamSpecialty] = []
    
    // 统计信息
    var stats: DreamUserStats
    
    // 成就徽章
    @Relationship(deleteRule: .cascade) var badges: [DreamUserBadge]
    
    // 偏好设置
    var preferences: DreamUserPreferences
    
    // 社交关系
    @Relationship(deleteRule: .nullify) var following: [DreamUserProfile]
    @Relationship(deleteRule: .nullify) var followers: [DreamUserProfile]
    
    init(
        id: String,
        username: String,
        displayName: String,
        bio: String? = nil
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.bio = bio
        self.createdAt = Date()
        self.updatedAt = Date()
        self.stats = DreamUserStats()
        self.badges = []
        self.preferences = DreamUserPreferences()
        self.specialties = []
        self.following = []
        self.followers = []
    }
    
    // MARK: - Helper Methods
    
    /// 更新最后登录时间
    func updateLastLogin() {
        lastLoginAt = Date()
        updatedAt = Date()
    }
    
    /// 更新统计信息
    func updateStats(
        sessionsCreated: Int = 0,
        interpretationsAdded: Int = 0,
        likesReceived: Int = 0
    ) {
        stats.sessionsCreated += sessionsCreated
        stats.interpretationsAdded += interpretationsAdded
        stats.likesReceived += likesReceived
        updatedAt = Date()
    }
    
    /// 检查是否关注某用户
    func isFollowing(_ user: DreamUserProfile) -> Bool {
        following.contains { $0.id == user.id }
    }
    
    /// 关注用户
    func follow(_ user: DreamUserProfile) {
        if !isFollowing(user) {
            following.append(user)
            stats.followingCount += 1
        }
    }
    
    /// 取消关注
    func unfollow(_ user: DreamUserProfile) {
        if let index = following.firstIndex(where: { $0.id == user.id }) {
            following.remove(at: index)
            stats.followingCount -= 1
        }
    }
}

// MARK: - 用户统计模型

/// 用户统计数据
struct DreamUserStats: Codable {
    // 协作统计
    var sessionsCreated: Int = 0 // 创建的会话数
    var sessionsJoined: Int = 0 // 加入的会话数
    var interpretationsAdded: Int = 0 // 添加的解读数
    var interpretationsAdopted: Int = 0 // 被采纳的解读数
    var commentsPosted: Int = 0 // 发布的评论数
    
    // 社交统计
    var likesReceived: Int = 0 // 收到的点赞数
    var likesGiven: Int = 0 // 给出的点赞数
    var followersCount: Int = 0 // 粉丝数
    var followingCount: Int = 0 // 关注数
    
    // 成就统计
    var badgesEarned: Int = 0 // 获得的徽章数
    var contributionScore: Int = 0 // 贡献积分
    
    // 活跃度
    var activeDays: Int = 0 // 活跃天数
    var longestStreak: Int = 0 // 最长连续活跃天数
    var currentStreak: Int = 0 // 当前连续活跃天数
    
    // MARK: - 计算属性
    
    /// 总贡献数
    var totalContributions: Int {
        interpretationsAdded + commentsPosted
    }
    
    /// 平均采纳率
    var adoptionRate: Double {
        guard interpretationsAdded > 0 else { return 0 }
        return Double(interpretationsAdopted) / Double(interpretationsAdded) * 100
    }
    
    /// 影响力评分
    var influenceScore: Int {
        let sessionScore = sessionsCreated * 10
        let interpretationScore = interpretationsAdded * 5
        let adoptionBonus = interpretationsAdopted * 20
        let likeScore = likesReceived * 2
        let followerScore = followersCount * 5
        return sessionScore + interpretationScore + adoptionBonus + likeScore + followerScore
    }
    
    /// 活跃度等级
    var activityLevel: UserActivityLevel {
        switch activeDays {
        case 0..<7: return .newcomer
        case 7..<30: return .active
        case 30..<90: return .veteran
        case 90..<365: return .expert
        default: return .master
        }
    }
}

/// 用户活跃度等级
enum UserActivityLevel: String, Codable, CaseIterable {
    case newcomer = "新手"
    case active = "活跃"
    case veteran = "资深"
    case expert = "专家"
    case master = "大师"
    
    var icon: String {
        switch self {
        case .newcomer: return "🌱"
        case .active: return "🌿"
        case .veteran: return "🌳"
        case .expert: return "🌟"
        case .master: return "👑"
        }
    }
    
    var color: String {
        switch self {
        case .newcomer: return "8B9BB4"
        case .active: return "4CAF50"
        case .veteran: return "2196F3"
        case .expert: return "FF9800"
        case .master: return "9C27B0"
        }
    }
}

// MARK: - 用户徽章模型

/// 用户成就徽章
@Model
final class DreamUserBadge {
    var id: UUID
    var badgeId: String // 徽章 ID
    var name: String
    var description: String
    var icon: String
    var category: BadgeCategory
    var earnedAt: Date
    var userId: String
    
    init(
        badgeId: String,
        name: String,
        description: String,
        icon: String,
        category: BadgeCategory,
        userId: String
    ) {
        self.id = UUID()
        self.badgeId = badgeId
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.earnedAt = Date()
        self.userId = userId
    }
}

/// 徽章类别
enum BadgeCategory: String, Codable, CaseIterable {
    case collaboration = "协作"
    case interpretation = "解读"
    case social = "社交"
    case achievement = "成就"
    case special = "特殊"
    
    var icon: String {
        switch self {
        case .collaboration: return "🤝"
        case .interpretation: return "💡"
        case .social: return "💬"
        case .achievement: return "🏆"
        case .special: return "⭐"
        }
    }
}

// MARK: - 用户偏好设置

/// 用户偏好设置
struct DreamUserPreferences: Codable {
    // 通知设置
    var enableNotifications: Bool = true
    var notifyOnNewInterpretation: Bool = true
    var notifyOnComment: Bool = true
    var notifyOnMention: Bool = true
    var notifyOnAdoption: Bool = true
    var notifyOnSessionComplete: Bool = true
    
    // 隐私设置
    var showOnlineStatus: Bool = true
    var showActivityStats: Bool = true
    var allowDirectMessages: Bool = true
    var visibility: ProfileVisibility = .friends
    
    // 界面设置
    var theme: UserTheme = .system
    var fontSize: FontSize = .medium
    var compactMode: Bool = false
    
    // 协作设置
    var autoJoinSessions: Bool = false // 自动加入好友会话
    var defaultInterpretationVisibility: InterpretationVisibility = .public
}

/// 个人资料可见性
enum ProfileVisibility: String, Codable, CaseIterable {
    case `private` = "仅自己"
    case friends = "仅好友"
    case `public` = "公开"
    
    var description: String {
        switch self {
        case .private: return "🔒 仅自己可见"
        case .friends: return "👥 好友可见"
        case .public: return "🌍 所有人可见"
        }
    }
}

/// 用户主题
enum UserTheme: String, Codable, CaseIterable {
    case light = "浅色"
    case dark = "深色"
    case system = "跟随系统"
    
    var icon: String {
        switch self {
        case .light: return "☀️"
        case .dark: return "🌙"
        case .system: return "⚙️"
        }
    }
}

/// 字体大小
enum FontSize: String, Codable, CaseIterable {
    case small = "小"
    case medium = "中"
    case large = "大"
    
    var multiplier: CGFloat {
        switch self {
        case .small: return 0.9
        case .medium: return 1.0
        case .large: return 1.2
        }
    }
}

// MARK: - 解读可见性

/// 解读可见性
enum InterpretationVisibility: String, Codable, CaseIterable {
    case `private` = "仅自己"
    case session = "仅会话成员"
    case `public` = "公开"
    
    var icon: String {
        switch self {
        case .private: return "🔒"
        case .session: return "👥"
        case .public: return "🌍"
        }
    }
}

// MARK: - 专长领域

/// 梦境解析专长领域
enum DreamSpecialty: String, Codable, CaseIterable {
    case symbolAnalysis = "符号解析"
    case psychology = "心理学"
    case spirituality = "灵性"
    case creativity = "创意"
    case lucidDreaming = "清醒梦"
    case nightmareHealing = "噩梦疗愈"
    case patternRecognition = "模式识别"
    case culturalInterpretation = "文化解读"
    
    var icon: String {
        switch self {
        case .symbolAnalysis: return "🔍"
        case .psychology: return "🧠"
        case .spirituality: return "🌟"
        case .creativity: return "🎨"
        case .lucidDreaming: return "👁️"
        case .nightmareHealing: return "💚"
        case .patternRecognition: return "📊"
        case .culturalInterpretation: return "🌍"
        }
    }
    
    var description: String {
        switch self {
        case .symbolAnalysis: return "擅长解析梦境中的符号和象征"
        case .psychology: return "从心理学角度解读梦境含义"
        case .spirituality: return "探索梦境的灵性和精神层面"
        case .creativity: return "激发梦境中的创意和灵感"
        case .lucidDreaming: return "清醒梦技巧和体验分享"
        case .nightmareHealing: return "帮助转化和疗愈噩梦"
        case .patternRecognition: return "识别梦境模式和趋势"
        case .culturalInterpretation: return "不同文化背景的梦境解读"
        }
    }
}

// MARK: - 预设徽章

extension DreamUserBadge {
    /// 预设徽章库
    static let presetBadges: [String: (name: String, description: String, icon: String, category: BadgeCategory)] = [
        "first_session": ("初次协作", "创建第一个协作会话", "🎉", .collaboration),
        "session_creator": ("会话达人", "创建 10 个会话", "🏆", .collaboration),
        "interpretation_master": ("解读大师", "添加 50 个解读", "💡", .interpretation),
        "adopted_interpretation": ("被采纳", "第一个解读被采纳", "✅", .achievement),
        "social_butterfly": ("社交达人", "关注 20 个用户", "🦋", .social),
        "helpful_helper": ("乐于助人", "获得 100 个赞", "❤️", .social),
        "early_bird": ("早起鸟儿", "连续活跃 7 天", "🐦", .achievement),
        "streak_master": ("连续大师", "连续活跃 30 天", "🔥", .achievement),
        "veteran_dreamer": ("资深梦者", "活跃 90 天", "🌟", .special),
        "legend": ("传奇", "活跃 365 天", "👑", .special)
    ]
    
    /// 创建预设徽章
    static func createPresetBadge(_ badgeId: String, userId: String) -> DreamUserBadge? {
        guard let preset = presetBadges[badgeId] else { return nil }
        return DreamUserBadge(
            badgeId: badgeId,
            name: preset.name,
            description: preset.description,
            icon: preset.icon,
            category: preset.category,
            userId: userId
        )
    }
}
