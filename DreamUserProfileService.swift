//
//  DreamUserProfileService.swift
//  DreamLog - 用户服务实现
//
//  Phase 73: 梦境协作功能增强
//  创建时间：2026-03-20
//

import Foundation
import SwiftData

/// 用户服务协议
protocol DreamUserProfileServiceProtocol {
    /// 获取当前用户
    func getCurrentUser() -> DreamUserProfile?
    
    /// 获取当前用户 ID
    func getCurrentUserId() -> String?
    
    /// 登录用户
    func login(username: String, displayName: String) async throws -> DreamUserProfile
    
    /// 登出用户
    func logout() async throws
    
    /// 更新用户档案
    func updateProfile(userId: String, updates: ProfileUpdates) async throws -> DreamUserProfile
    
    /// 获取用户档案
    func getUserProfile(userId: String) async throws -> DreamUserProfile?
    
    /// 获取用户统计
    func getUserStats(userId: String) async throws -> DreamUserStats?
    
    /// 关注用户
    func followUser(followerId: String, followingId: String) async throws
    
    /// 取消关注
    func unfollowUser(followerId: String, followingId: String) async throws
    
    /// 检查是否关注
    func isFollowing(followerId: String, followingId: String) async throws -> Bool
    
    /// 更新用户统计
    func updateStats(userId: String, updates: StatsUpdates) async throws
    
    /// 授予徽章
    func awardBadge(userId: String, badgeId: String) async throws -> DreamUserBadge?
    
    /// 检查并授予成就
    func checkAndAwardAchievements(userId: String) async throws -> [DreamUserBadge]
}

/// 档案更新数据
struct ProfileUpdates {
    var displayName: String?
    var bio: String?
    var avatar: String?
    var specialties: [DreamSpecialty]?
    var preferences: DreamUserPreferences?
}

/// 统计更新数据
struct StatsUpdates {
    var sessionsCreated: Int = 0
    var sessionsJoined: Int = 0
    var interpretationsAdded: Int = 0
    var interpretationsAdopted: Int = 0
    var commentsPosted: Int = 0
    var likesReceived: Int = 0
    var likesGiven: Int = 0
    var activeDay: Bool = false
}

/// 用户服务实现
@ModelActor
final actor DreamUserProfileService: DreamUserProfileServiceProtocol {
    private let userDefaults: UserDefaults
    private let currentUserIdKey = "dreamlog_current_user_id"
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.userDefaults = .standard
    }
    
    // MARK: - 当前用户管理
    
    func getCurrentUser() -> DreamUserProfile? {
        guard let userId = getCurrentUserId() else { return nil }
        return getUserProfileSync(userId: userId)
    }
    
    func getCurrentUserId() -> String? {
        userDefaults.string(forKey: currentUserIdKey)
    }
    
    func login(username: String, displayName: String) async throws -> DreamUserProfile {
        let userId = UUID().uuidString
        
        // 检查用户名是否已存在
        if let existing = getUserProfileSync(userId: userId) {
            // 用户已存在，直接登录
            existing.updateLastLogin()
            userDefaults.set(userId, forKey: currentUserIdKey)
            try modelContext.save()
            return existing
        }
        
        // 创建新用户
        let user = DreamUserProfile(
            id: userId,
            username: username,
            displayName: displayName
        )
        user.updateLastLogin()
        
        modelContext.insert(user)
        try modelContext.save()
        
        // 保存当前用户 ID
        userDefaults.set(userId, forKey: currentUserIdKey)
        
        // 授予新手徽章
        try await awardBadge(userId: userId, badgeId: "first_session")
        
        return user
    }
    
    func logout() async throws {
        userDefaults.removeObject(forKey: currentUserIdKey)
        try modelContext.save()
    }
    
    // MARK: - 用户档案管理
    
    func getUserProfile(userId: String) async throws -> DreamUserProfile? {
        getUserProfileSync(userId: userId)
    }
    
    private func getUserProfileSync(userId: String) -> DreamUserProfile? {
        let descriptor = FetchDescriptor<DreamUserProfile>(
            predicate: #Predicate { $0.id == userId }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func updateProfile(userId: String, updates: ProfileUpdates) async throws -> DreamUserProfile {
        guard var user = getUserProfileSync(userId: userId) else {
            throw UserProfileError.userNotFound
        }
        
        if let displayName = updates.displayName {
            user.displayName = displayName
        }
        if let bio = updates.bio {
            user.bio = bio
        }
        if let avatar = updates.avatar {
            user.avatar = avatar
        }
        if let specialties = updates.specialties {
            user.specialties = specialties
        }
        if let preferences = updates.preferences {
            user.preferences = preferences
        }
        
        user.updatedAt = Date()
        try modelContext.save()
        
        return user
    }
    
    func getUserStats(userId: String) async throws -> DreamUserStats? {
        guard let user = getUserProfileSync(userId: userId) else {
            return nil
        }
        return user.stats
    }
    
    // MARK: - 社交关系
    
    func followUser(followerId: String, followingId: String) async throws {
        guard followerId != followingId else {
            throw UserProfileError.cannotFollowSelf
        }
        
        guard var follower = getUserProfileSync(userId: followerId),
              var following = getUserProfileSync(userId: followingId) else {
            throw UserProfileError.userNotFound
        }
        
        follower.follow(following)
        following.followers.append(follower)
        following.stats.followersCount += 1
        
        try modelContext.save()
    }
    
    func unfollowUser(followerId: String, followingId: String) async throws {
        guard var follower = getUserProfileSync(userId: followerId),
              var following = getUserProfileSync(userId: followingId) else {
            throw UserProfileError.userNotFound
        }
        
        follower.unfollow(following)
        if let index = following.followers.firstIndex(where: { $0.id == followerId }) {
            following.followers.remove(at: index)
            following.stats.followersCount -= 1
        }
        
        try modelContext.save()
    }
    
    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        guard let follower = getUserProfileSync(userId: followerId) else {
            return false
        }
        return follower.isFollowing(DreamUserProfile(id: followingId, username: "", displayName: ""))
    }
    
    // MARK: - 统计更新
    
    func updateStats(userId: String, updates: StatsUpdates) async throws {
        guard var user = getUserProfileSync(userId: userId) else {
            throw UserProfileError.userNotFound
        }
        
        user.updateStats(
            sessionsCreated: updates.sessionsCreated,
            interpretationsAdded: updates.interpretationsAdded,
            likesReceived: updates.likesReceived
        )
        
        user.stats.sessionsJoined += updates.sessionsJoined
        user.stats.interpretationsAdopted += updates.interpretationsAdopted
        user.stats.commentsPosted += updates.commentsPosted
        user.stats.likesGiven += updates.likesGiven
        
        // 更新活跃天数
        if updates.activeDay {
            user.stats.activeDays += 1
            user.stats.currentStreak += 1
            user.stats.longestStreak = max(user.stats.longestStreak, user.stats.currentStreak)
        }
        
        // 更新贡献积分
        user.stats.contributionScore = calculateContributionScore(user.stats)
        
        try modelContext.save()
        
        // 检查并授予成就
        try await checkAndAwardAchievements(userId: userId)
    }
    
    private func calculateContributionScore(_ stats: DreamUserStats) -> Int {
        let sessionScore = stats.sessionsCreated * 10
        let interpretationScore = stats.interpretationsAdded * 5
        let adoptionBonus = stats.interpretationsAdopted * 20
        let commentScore = stats.commentsPosted * 2
        return sessionScore + interpretationScore + adoptionBonus + commentScore
    }
    
    // MARK: - 徽章系统
    
    func awardBadge(userId: String, badgeId: String) async throws -> DreamUserBadge? {
        guard var user = getUserProfileSync(userId: userId) else {
            throw UserProfileError.userNotFound
        }
        
        // 检查是否已获得
        if user.badges.contains(where: { $0.badgeId == badgeId }) {
            return nil
        }
        
        guard let badge = DreamUserBadge.createPresetBadge(badgeId, userId: userId) else {
            return nil
        }
        
        user.badges.append(badge)
        user.stats.badgesEarned += 1
        modelContext.insert(badge)
        try modelContext.save()
        
        return badge
    }
    
    func checkAndAwardAchievements(userId: String) async throws -> [DreamUserBadge] {
        guard let user = getUserProfileSync(userId: userId) else {
            return []
        }
        
        var earnedBadges: [DreamUserBadge] = []
        let stats = user.stats
        
        // 会话创建者
        if stats.sessionsCreated >= 10 && !user.badges.contains(where: { $0.badgeId == "session_creator" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "session_creator") {
                earnedBadges.append(badge)
            }
        }
        
        // 解读大师
        if stats.interpretationsAdded >= 50 && !user.badges.contains(where: { $0.badgeId == "interpretation_master" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "interpretation_master") {
                earnedBadges.append(badge)
            }
        }
        
        // 社交达人
        if stats.followingCount >= 20 && !user.badges.contains(where: { $0.badgeId == "social_butterfly" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "social_butterfly") {
                earnedBadges.append(badge)
            }
        }
        
        // 乐于助人
        if stats.likesReceived >= 100 && !user.badges.contains(where: { $0.badgeId == "helpful_helper" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "helpful_helper") {
                earnedBadges.append(badge)
            }
        }
        
        // 连续大师
        if stats.currentStreak >= 30 && !user.badges.contains(where: { $0.badgeId == "streak_master" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "streak_master") {
                earnedBadges.append(badge)
            }
        }
        
        // 资深梦者
        if stats.activeDays >= 90 && !user.badges.contains(where: { $0.badgeId == "veteran_dreamer" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "veteran_dreamer") {
                earnedBadges.append(badge)
            }
        }
        
        // 传奇
        if stats.activeDays >= 365 && !user.badges.contains(where: { $0.badgeId == "legend" }) {
            if let badge = try await awardBadge(userId: userId, badgeId: "legend") {
                earnedBadges.append(badge)
            }
        }
        
        return earnedBadges
    }
}

// MARK: - 错误类型

enum UserProfileError: LocalizedError {
    case userNotFound
    case cannotFollowSelf
    case usernameTaken
    case invalidUsername
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound: return "用户不存在"
        case .cannotFollowSelf: return "不能关注自己"
        case .usernameTaken: return "用户名已被使用"
        case .invalidUsername: return "用户名格式无效"
        case .databaseError: return "数据库操作失败"
        }
    }
}

// MARK: - CurrentUserService 扩展

extension DreamUserProfileService {
    /// 兼容旧的 CurrentUserService 协议
    func legacyGetCurrentUserId() -> String? {
        getCurrentUserId()
    }
    
    func legacyGetCurrentUserName() -> String {
        getCurrentUser()?.displayName ?? "我"
    }
    
    func legacyIsLoggedIn() -> Bool {
        getCurrentUserId() != nil
    }
}
