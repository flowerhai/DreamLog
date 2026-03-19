//
//  DreamChallengeService.swift
//  DreamLog
//
//  Phase 58 - 梦境挑战系统服务
//  创建时间：2026-03-16
//

import Foundation
import SwiftData
import UserNotifications
import Combine
import ActivityKit

@MainActor
class DreamChallengeService: ObservableObject {
    
    // MARK: - Properties
    
    @Published private let modelContext: ModelContext
    @Published private let userId: String
    @Published private var stats: ChallengeStats?
    private let liveActivityService = DreamLiveActivityService.shared
    
    // MARK: - Singleton
    
    static let shared = DreamChallengeService(modelContext: SharedModelContainer.main.context)
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, userId: String = "current_user") {
        self.modelContext = modelContext
        self.userId = userId
    }
    
    // MARK: - 模板管理
    
    /// 获取所有挑战模板
    func getAllTemplates() throws -> [DreamChallengeTemplate] {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.isActive == true }
        )
        return try modelContext.fetch(descriptor).sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// 获取预设模板
    func getPresetTemplates() throws -> [DreamChallengeTemplate] {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.isPreset == true && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按类别获取模板
    func getTemplates(by category: ChallengeCategory) throws -> [DreamChallengeTemplate] {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.category == category && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按类型获取模板
    func getTemplates(by type: ChallengeType) throws -> [DreamChallengeTemplate] {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.type == type && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取每日挑战
    func getDailyChallenges() throws -> [DreamChallengeTemplate] {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.type == .daily && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取每周挑战
    func getWeeklyChallenges() throws -> [DreamChallengeTemplate] {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.type == .weekly && $0.isActive == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 初始化预设模板
    func initializePresetTemplates() throws {
        let existing = try getPresetTemplates()
        guard existing.isEmpty else { return }
        
        for template in DreamChallengeTemplate.presetTemplates {
            modelContext.insert(template)
        }
        try modelContext.save()
    }
    
    // MARK: - 徽章管理
    
    /// 获取所有徽章
    func getAllBadges() throws -> [AchievementBadge] {
        let descriptor = FetchDescriptor<AchievementBadge>()
        return try modelContext.fetch(descriptor).sorted { $0.points < $1.points }
    }
    
    /// 获取已解锁徽章
    func getUnlockedBadges() throws -> [AchievementBadge] {
        let descriptor = FetchDescriptor<AchievementBadge>(
            predicate: #Predicate<AchievementBadge> { $0.isUnlocked == true }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取未解锁徽章
    func getLockedBadges() throws -> [AchievementBadge] {
        let descriptor = FetchDescriptor<AchievementBadge>(
            predicate: #Predicate<AchievementBadge> { $0.isUnlocked == false }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 初始化预设徽章
    func initializePresetBadges() throws {
        let existing = try getAllBadges()
        guard existing.isEmpty else { return }
        
        for badge in AchievementBadge.presetBadges {
            modelContext.insert(badge)
        }
        try modelContext.save()
    }
    
    // MARK: - 用户挑战管理
    
    /// 获取用户所有挑战
    func getUserChallenges() throws -> [UserChallenge] {
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { $0.userId == userId }
        )
        return try modelContext.fetch(descriptor).sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 获取进行中的挑战
    func getActiveChallenges() throws -> [UserChallenge] {
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { $0.userId == userId && $0.status == .inProgress }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取已完成的挑战
    func getCompletedChallenges() throws -> [UserChallenge] {
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { $0.userId == userId && $0.isCompleted == true }
        )
        return try modelContext.fetch(descriptor).sorted { $0.completedAt ?? Date.distantPast > $1.completedAt ?? Date.distantPast }
    }
    
    /// 获取今日挑战
    func getTodayChallenges() throws -> [UserChallenge] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { 
                $0.userId == userId && 
                $0.createdAt >= startOfDay && 
                $0.createdAt < endOfDay
            }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 开始一个挑战
    func startChallenge(templateId: UUID) throws -> UserChallenge {
        // 检查是否已存在进行中的相同挑战
        let existingDescriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { 
                $0.userId == userId && 
                $0.templateId == templateId && 
                $0.status == .inProgress 
            }
        )
        let existing = try modelContext.fetch(existingDescriptor)
        if let existingChallenge = existing.first {
            return existingChallenge
        }
        
        // 获取模板
        let templateDescriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.id == templateId }
        )
        guard let template = try modelContext.fetch(templateDescriptor).first else {
            throw ChallengeError.templateNotFound
        }
        
        // 创建挑战实例
        let challenge = UserChallenge(
            templateId: templateId,
            userId: userId,
            status: .inProgress,
            targetProgress: template.targetValue
        )
        
        // 设置过期时间
        if let durationHours = template.durationHours {
            challenge.expiresAt = Date().addingTimeInterval(Double(durationHours) * 3600)
        }
        
        modelContext.insert(challenge)
        try modelContext.save()
        
        // 更新模板统计
        template.totalAttempts += 1
        try modelContext.save()
        
        // 发送通知
        scheduleChallengeStartedNotification(challenge: challenge, template: template)
        
        // 启动实时活动
        Task {
            try? await liveActivityService.startChallengeActivity(challenge: challenge)
        }
        
        return challenge
    }
    
    /// 更新挑战进度
    func updateChallengeProgress(challengeId: UUID, progress: Int, detail: String? = nil) throws {
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { $0.id == challengeId }
        )
        guard let challenge = try modelContext.fetch(descriptor).first else {
            throw ChallengeError.challengeNotFound
        }
        
        challenge.progress = progress
        challenge.updatedAt = Date()
        
        if let detail = detail {
            challenge.progressDetails.append(detail)
        }
        
        // 检查是否完成
        if progress >= challenge.targetProgress {
            completeChallenge(challengeId: challengeId)
        } else {
            // 更新实时活动
            Task {
                await liveActivityService.updateChallengeActivity(challengeId: challengeId.uuidString, challenge: challenge)
            }
        }
        
        try modelContext.save()
    }
    
    /// 完成挑战
    func completeChallenge(challengeId: UUID) throws {
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { $0.id == challengeId }
        )
        guard let challenge = try modelContext.fetch(descriptor).first else {
            throw ChallengeError.challengeNotFound
        }
        
        challenge.status = .completed
        challenge.isCompleted = true
        challenge.completedAt = Date()
        challenge.earnedPoints = getTemplate(for: challenge.templateId)?.rewardPoints ?? 0
        challenge.earnedBadgeId = getTemplate(for: challenge.templateId)?.rewardBadgeId
        challenge.earnedTitle = getTemplate(for: challenge.templateId)?.rewardTitle
        challenge.updatedAt = Date()
        
        // 更新模板统计
        if let template = getTemplate(for: challenge.templateId) {
            template.completedCount += 1
        }
        
        // 更新统计
        try updateStatsForCompletedChallenge(challenge)
        
        // 解锁徽章
        if let badgeId = challenge.earnedBadgeId {
            try unlockBadge(id: badgeId)
        }
        
        try modelContext.save()
        
        // 发送完成通知
        scheduleChallengeCompletedNotification(challenge: challenge)
        
        // 结束实时活动
        Task {
            await liveActivityService.endChallengeActivity(challengeId: challengeId.uuidString, reason: .completed)
        }
    }
    
    /// 领取奖励
    func claimReward(challengeId: UUID) throws {
        let descriptor = FetchDescriptor<UserChallenge>(
            predicate: #Predicate<UserChallenge> { $0.id == challengeId }
        )
        guard let challenge = try modelContext.fetch(descriptor).first else {
            throw ChallengeError.challengeNotFound
        }
        
        guard challenge.isCompleted && !challenge.isClaimed else {
            throw ChallengeError.rewardAlreadyClaimed
        }
        
        challenge.isClaimed = true
        try modelContext.save()
    }
    
    /// 删除挑战
    func deleteChallenge(_ challenge: UserChallenge) throws {
        modelContext.delete(challenge)
        try modelContext.save()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ challenge: UserChallenge) throws {
        challenge.isFavorite.toggle()
        challenge.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - 统计管理
    
    /// 获取用户统计
    func getStats() throws -> ChallengeStats {
        if let stats = self.stats {
            return stats
        }
        
        let descriptor = FetchDescriptor<ChallengeStats>(
            predicate: #Predicate<ChallengeStats> { $0.userId == userId }
        )
        
        if var stats = try modelContext.fetch(descriptor).first {
            self.stats = stats
            return stats
        } else {
            let newStats = ChallengeStats(userId: userId)
            modelContext.insert(newStats)
            try modelContext.save()
            self.stats = newStats
            return newStats
        }
    }
    
    /// 刷新统计
    func refreshStats() throws -> ChallengeStats {
        let stats = try getStats()
        
        // 统计完成的挑战
        let completedChallenges = try getCompletedChallenges()
        stats.totalChallengesCompleted = completedChallenges.count
        stats.totalPointsEarned = completedChallenges.reduce(0) { $0 + $1.earnedPoints }
        
        // 统计徽章
        let unlockedBadges = try getUnlockedBadges()
        stats.totalBadgesEarned = unlockedBadges.count
        
        // 按类别统计
        stats.recordingChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .recording 
        }.count
        stats.lucidChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .lucid 
        }.count
        stats.reflectionChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .reflection 
        }.count
        stats.creativityChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .creativity 
        }.count
        stats.socialChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .social 
        }.count
        stats.streakChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .streak 
        }.count
        stats.explorationChallengesCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.category == .exploration 
        }.count
        
        // 按难度统计
        stats.easyCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.difficulty == .easy 
        }.count
        stats.mediumCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.difficulty == .medium 
        }.count
        stats.hardCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.difficulty == .hard 
        }.count
        stats.expertCompleted = completedChallenges.filter { 
            getTemplate(for: $0.templateId)?.difficulty == .expert 
        }.count
        
        // 时间统计
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        stats.todayCompleted = completedChallenges.filter { $0.completedAt ?? Date.distantPast >= startOfDay }.count
        
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        stats.weekCompleted = completedChallenges.filter { $0.completedAt ?? Date.distantPast >= startOfWeek }.count
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        stats.monthCompleted = completedChallenges.filter { $0.completedAt ?? Date.distantPast >= startOfMonth }.count
        
        stats.updatedAt = Date()
        try modelContext.save()
        
        return stats
    }
    
    // MARK: - 自动进度追踪
    
    /// 记录梦境完成时自动更新相关挑战
    func onDreamRecorded(dreamId: UUID, hasEmotions: Bool, hasTags: Bool, hasAudio: Bool, isLucid: Bool) throws {
        let activeChallenges = try getActiveChallenges()
        
        for challenge in activeChallenges {
            guard let template = getTemplate(for: challenge.templateId) else { continue }
            
            var shouldUpdate = false
            var newProgress = challenge.progress
            
            switch template.targetType {
            case .recordDreams:
                shouldUpdate = true
                newProgress += 1
            case .recordWithEmotions:
                shouldUpdate = hasEmotions
                if shouldUpdate { newProgress += 1 }
            case .recordWithTags:
                shouldUpdate = hasTags
                if shouldUpdate { newProgress += 1 }
            case .recordWithAudio:
                shouldUpdate = hasAudio
                if shouldUpdate { newProgress += 1 }
            case .lucidDream:
                shouldUpdate = isLucid
                if shouldUpdate { newProgress += 1 }
            default:
                break
            }
            
            if shouldUpdate && newProgress > challenge.progress {
                try updateChallengeProgress(
                    challengeId: challenge.id,
                    progress: newProgress,
                    detail: dreamId.uuidString
                )
            }
        }
    }
    
    /// 分享梦境时自动更新相关挑战
    func onDreamShared(dreamId: UUID) throws {
        let activeChallenges = try getActiveChallenges()
        
        for challenge in activeChallenges {
            guard let template = getTemplate(for: challenge.templateId) else { continue }
            
            if template.targetType == .shareDream {
                let newProgress = challenge.progress + 1
                try updateChallengeProgress(
                    challengeId: challenge.id,
                    progress: newProgress,
                    detail: dreamId.uuidString
                )
            }
        }
    }
    
    /// 完成冥想时自动更新相关挑战
    func onMeditationCompleted() throws {
        let activeChallenges = try getActiveChallenges()
        
        for challenge in activeChallenges {
            guard let template = getTemplate(for: challenge.templateId) else { continue }
            
            if template.targetType == .meditation {
                let newProgress = challenge.progress + 1
                try updateChallengeProgress(
                    challengeId: challenge.id,
                    progress: newProgress
                )
            }
        }
    }
    
    // MARK: - 徽章管理
    
    /// 解锁徽章
    func unlockBadge(id: String) throws {
        let descriptor = FetchDescriptor<AchievementBadge>(
            predicate: #Predicate<AchievementBadge> { $0.id == id }
        )
        guard let badge = try modelContext.fetch(descriptor).first else {
            return
        }
        
        guard !badge.isUnlocked else { return }
        
        badge.isUnlocked = true
        badge.unlockedAt = Date()
        badge.unlockCount += 1
        try modelContext.save()
        
        // 发送通知
        scheduleBadgeUnlockedNotification(badge: badge)
    }
    
    // MARK: - 私有方法
    
    private func getTemplate(for templateId: UUID) -> DreamChallengeTemplate? {
        let descriptor = FetchDescriptor<DreamChallengeTemplate>(
            predicate: #Predicate<DreamChallengeTemplate> { $0.id == templateId }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    private func updateStatsForCompletedChallenge(_ challenge: UserChallenge) throws {
        let stats = try getStats()
        stats.totalChallengesCompleted += 1
        stats.totalPointsEarned += challenge.earnedPoints
        if challenge.earnedBadgeId != nil {
            stats.totalBadgesEarned += 1
        }
        try modelContext.save()
    }
    
    // MARK: - 通知
    
    private func scheduleChallengeStartedNotification(challenge: UserChallenge, template: DreamChallengeTemplate) {
        let content = UNMutableNotificationContent()
        content.title = "挑战开始！\(template.icon)"
        content.body = template.description
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_\(challenge.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleChallengeCompletedNotification(challenge: UserChallenge) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 挑战完成！"
        content.body = "恭喜你完成了挑战！获得了 \(challenge.earnedPoints) 积分"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "challenge_completed_\(challenge.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleBadgeUnlockedNotification(badge: AchievementBadge) {
        let content = UNMutableNotificationContent()
        content.title = "🏆 新徽章解锁！"
        content.body = "恭喜你获得\"\(badge.name)\"徽章！\(badge.icon)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "badge_unlocked_\(badge.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - 错误类型

enum ChallengeError: LocalizedError {
    case templateNotFound
    case challengeNotFound
    case rewardAlreadyClaimed
    case invalidProgress
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound: return "挑战模板不存在"
        case .challengeNotFound: return "挑战不存在"
        case .rewardAlreadyClaimed: return "奖励已领取"
        case .invalidProgress: return "无效的进度"
        }
    }
}
