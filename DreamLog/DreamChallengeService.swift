//
//  DreamChallengeService.swift
//  DreamLog
//
//  Phase 41 - 梦境挑战系统
//  核心服务
//

import Foundation
import SwiftData
import UserNotifications

actor DreamChallengeService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var challenges: [DreamChallenge] = []
    private var badges: [ChallengeBadge] = []
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadChallenges()
        loadBadges()
    }
    
    // MARK: - Load Data
    
    private func loadChallenges() {
        let descriptor = FetchDescriptor<DreamChallenge>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        
        do {
            challenges = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load challenges: \(error)")
        }
    }
    
    private func loadBadges() {
        let descriptor = FetchDescriptor<ChallengeBadge>(
            sortBy: [SortDescriptor(\.earnedAt, order: .reverse)]
        )
        
        do {
            badges = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load badges: \(error)")
        }
    }
    
    // MARK: - Challenge Management
    
    /// 获取所有挑战
    func getAllChallenges() -> [DreamChallenge] {
        loadChallenges()
        return challenges
    }
    
    /// 获取进行中的挑战
    func getInProgressChallenges() -> [DreamChallenge] {
        challenges.filter { $0.isOngoing }
    }
    
    /// 获取可参与的挑战
    func getAvailableChallenges() -> [DreamChallenge] {
        challenges.filter { $0.status == .available && !$0.isExpired }
    }
    
    /// 获取已完成的挑战
    func getCompletedChallenges() -> [DreamChallenge] {
        challenges.filter { $0.status == .completed }
    }
    
    /// 获取特定类型的挑战
    func getChallenges(by type: DreamChallengeType) -> [DreamChallenge] {
        challenges.filter { $0.type == type }
    }
    
    /// 获取收藏的挑战
    func getFavoriteChallenges() -> [DreamChallenge] {
        challenges.filter { $0.isFavorite }
    }
    
    /// 获取挑战详情
    func getChallenge(id: UUID) -> DreamChallenge? {
        challenges.first { $0.id == id }
    }
    
    // MARK: - Challenge Actions
    
    /// 开始挑战
    func startChallenge(id: UUID) async throws {
        guard let challenge = challenges.first(where: { $0.id == id }) else {
            throw ChallengeError.challengeNotFound
        }
        
        guard challenge.status == .available else {
            throw ChallengeError.challengeNotAvailable
        }
        
        challenge.status = .inProgress
        challenge.startedAt = Date()
        
        try modelContext.save()
        await scheduleChallengeReminders(for: challenge)
    }
    
    /// 更新任务进度
    func updateTaskProgress(challengeId: UUID, taskId: UUID, increment: Int = 1) async throws {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else {
            throw ChallengeError.challengeNotFound
        }
        
        guard let task = challenge.tasks.first(where: { $0.id == taskId }) else {
            throw ChallengeError.taskNotFound
        }
        
        task.currentCount += increment
        
        if task.currentCount >= task.targetCount && !task.isCompleted {
            task.isCompleted = true
            task.completedAt = Date()
            challenge.earnedPoints += task.points
            
            // 检查挑战是否完成
            await checkChallengeCompletion(challengeId: challengeId)
        }
        
        try modelContext.save()
    }
    
    /// 检查挑战完成状态
    private func checkChallengeCompletion(challengeId: UUID) async {
        guard let challenge = challenges.first(where: { $0.id == challengeId }) else {
            return
        }
        
        let allTasksCompleted = challenge.tasks.allSatisfy { $0.isCompleted }
        
        if allTasksCompleted {
            challenge.status = .completed
            challenge.completedAt = Date()
            
            // 授予徽章
            if let badgeName = challenge.badge {
                await awardBadge(name: badgeName, challengeId: challengeId, points: challenge.totalPoints)
            }
            
            // 发送完成通知
            await sendChallengeCompletedNotification(challenge: challenge)
        }
    }
    
    /// 放弃挑战
    func quitChallenge(id: UUID) async throws {
        guard let challenge = challenges.first(where: { $0.id == id }) else {
            throw ChallengeError.challengeNotFound
        }
        
        challenge.status = .failed
        try modelContext.save()
        await cancelChallengeReminders(challengeId: id)
    }
    
    /// 切换收藏状态
    func toggleFavorite(id: UUID) async throws {
        guard let challenge = challenges.first(where: { $0.id == id }) else {
            throw ChallengeError.challengeNotFound
        }
        
        challenge.isFavorite.toggle()
        try modelContext.save()
    }
    
    // MARK: - Badge Management
    
    /// 获取所有徽章
    func getAllBadges() -> [ChallengeBadge] {
        loadBadges()
        return badges
    }
    
    /// 授予徽章
    private func awardBadge(name: String, challengeId: UUID, points: Int) async {
        let badge = ChallengeBadge(
            name: name,
            icon: getBadgeIcon(for: name),
            description: "完成挑战获得",
            requirement: name,
            challengeId: challengeId,
            points: points
        )
        
        badges.append(badge)
        modelContext.insert(badge)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save badge: \(error)")
        }
        
        await sendBadgeEarnedNotification(badge: badge)
    }
    
    private func getBadgeIcon(for name: String) -> String {
        let iconMap: [String: String] = [
            "🧠 回忆大师": "🧠",
            "💫 清醒行者": "💫",
            "🔥 毅力之王": "🔥",
            "✨ 创意达人": "✨",
            "🕊️ 飞行者": "🕊️",
            "🧘 正念大师": "🧘"
        ]
        return iconMap[name] ?? "🏆"
    }
    
    // MARK: - Statistics
    
    /// 获取挑战统计
    func getChallengeStats() -> ChallengeStats {
        loadChallenges()
        loadBadges()
        
        let completed = challenges.filter { $0.status == .completed }.count
        let inProgress = challenges.filter { $0.isOngoing }.count
        let totalPoints = challenges.reduce(0) { $0 + $1.earnedPoints }
        
        // 计算最喜欢的挑战类型
        let typeCounts = Dictionary(grouping: challenges.filter { $0.status == .completed }, by: { $0.type })
        let favoriteType = typeCounts.max(by: { $0.value.count < $1.value.count })?.key
        
        // 计算连续记录
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        
        return ChallengeStats(
            totalChallenges: challenges.count,
            completedChallenges: completed,
            inProgressChallenges: inProgress,
            totalPoints: totalPoints,
            totalBadges: badges.count,
            completionRate: completed > 0 ? Double(completed) / Double(challenges.count) : 0,
            favoriteType: favoriteType,
            currentStreak: currentStreak,
            longestStreak: longestStreak
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        // 简化实现：计算连续记录天数
        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        
        for day in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -day, to: now) else { break }
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let descriptor = FetchDescriptor<DreamChallenge>(
                predicate: #Predicate<DreamChallenge> { challenge in
                    challenge.startedAt != nil &&
                    challenge.startedAt! >= startOfDay &&
                    challenge.startedAt! < endOfDay
                }
            )
            
            do {
                let count = try modelContext.fetch(descriptor).count
                if count > 0 {
                    streak += 1
                } else if day > 0 {
                    break
                }
            } catch {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        // 简化实现：返回历史最长连续记录
        return calculateCurrentStreak() // 实际应计算历史最大值
    }
    
    // MARK: - Notifications
    
    /// 安排挑战提醒
    private func scheduleChallengeReminders(for challenge: DreamChallenge) {
        let content = UNMutableNotificationContent()
        content.title = "🎯 挑战进行中"
        content.body = "\"\(challenge.title)\" - 加油！还剩 \(challenge.daysRemaining) 天"
        content.sound = .default
        content.categoryIdentifier = "DREAM_CHALLENGE"
        
        // 每天提醒
        let dateComponents = DateComponents(hour: 20, minute: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "challenge_\(challenge.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule challenge reminder: \(error)")
            }
        }
    }
    
    /// 取消挑战提醒
    private func cancelChallengeReminders(challengeId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["challenge_\(challengeId.uuidString)"]
        )
    }
    
    /// 发送挑战完成通知
    private func sendChallengeCompletedNotification(challenge: DreamChallenge) async {
        let content = UNMutableNotificationContent()
        content.title = "🎉 挑战完成!"
        content.body = "恭喜完成\"\(challenge.title)\"! 获得 \(challenge.earnedPoints) 积分"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "challenge_completed_\(challenge.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        await UNUserNotificationCenter.current().add(request)
    }
    
    /// 发送徽章获得通知
    private func sendBadgeEarnedNotification(badge: ChallengeBadge) async {
        let content = UNMutableNotificationContent()
        content.title = "🏆 新徽章解锁!"
        content.body = "获得\"\(badge.name)\"徽章! +\(badge.points) 积分"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "badge_earned_\(badge.id.uuidString)",
            content: content,
            trigger: nil
        )
        
        await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Preset Challenges
    
    /// 初始化预设挑战
    func initializePresetChallenges() async {
        let existingTitles = challenges.map { $0.title }
        let presetChallenges = DreamChallenge.createPresetChallenges()
        
        for challenge in presetChallenges {
            if !existingTitles.contains(challenge.title) {
                challenges.append(challenge)
                modelContext.insert(challenge)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save preset challenges: \(error)")
        }
    }
}

// MARK: - Errors

enum ChallengeError: LocalizedError {
    case challengeNotFound
    case taskNotFound
    case challengeNotAvailable
    case challengeAlreadyStarted
    case challengeExpired
    
    var errorDescription: String? {
        switch self {
        case .challengeNotFound: return "挑战不存在"
        case .taskNotFound: return "任务不存在"
        case .challengeNotAvailable: return "挑战不可参与"
        case .challengeAlreadyStarted: return "挑战已开始"
        case .challengeExpired: return "挑战已过期"
        }
    }
}
