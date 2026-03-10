//
//  DreamChallengeService.swift
//  DreamLog
//
//  梦境挑战系统服务
//  Phase 15 - 梦境挑战系统
//

import Foundation
import Combine

/// 梦境挑战服务
@MainActor
class DreamChallengeService: ObservableObject {
    
    // MARK: - 单例
    
    static let shared = DreamChallengeService()
    
    // MARK: - Published Properties
    
    @Published var activeChallenges: [DreamChallenge] = []
    @Published var completedChallenges: [DreamChallenge] = []
    @Published var userProgress: [UUID: UserChallengeProgress] = [:]
    @Published var unlockedBadges: [ChallengeBadge] = []
    @Published var statistics: ChallengeStatistics = ChallengeStatistics()
    @Published var totalPoints: Int = 0
    @Published var currentLevel: Int = 1
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    
    private let userDefaultsKey = "DreamLog_Challenges"
    private let badgesKey = "DreamLog_Badges"
    private let statsKey = "DreamLog_ChallengeStats"
    private let pointsKey = "DreamLog_ChallengePoints"
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    private init() {
        loadData()
        checkAndActivateChallenges()
    }
    
    // MARK: - 数据加载/保存
    
    /// 加载数据
    func loadData() {
        // 加载积分
        totalPoints = UserDefaults.standard.integer(forKey: pointsKey)
        currentLevel = totalPoints / 100 + 1
        
        // 加载徽章
        if let badgesData = UserDefaults.standard.data(forKey: badgesKey),
           let badges = try? JSONDecoder().decode([ChallengeBadge].self, from: badgesData) {
            unlockedBadges = badges
        }
        
        // 加载统计数据
        if let statsData = UserDefaults.standard.data(forKey: statsKey),
           let stats = try? JSONDecoder().decode(ChallengeStatistics.self, from: statsData) {
            statistics = stats
        }
        
        // 加载用户进度
        if let progressData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let progress = try? JSONDecoder().decode([UserChallengeProgress].self, from: progressData) {
            for p in progress {
                userProgress[p.challengeId] = p
            }
        }
        
        print("🎯 ChallengeService: 加载数据完成 - 积分：\(totalPoints), 徽章：\(unlockedBadges.count)")
    }
    
    /// 保存数据
    private func saveData() {
        // 保存积分
        UserDefaults.standard.set(totalPoints, forKey: pointsKey)
        
        // 保存徽章
        if let badgesData = try? JSONEncoder().encode(unlockedBadges) {
            UserDefaults.standard.set(badgesData, forKey: badgesKey)
        }
        
        // 保存统计数据
        if let statsData = try? JSONEncoder().encode(statistics) {
            UserDefaults.standard.set(statsData, forKey: statsKey)
        }
        
        // 保存用户进度
        let progressArray = Array(userProgress.values)
        if let progressData = try? JSONEncoder().encode(progressArray) {
            UserDefaults.standard.set(progressData, forKey: userDefaultsKey)
        }
    }
    
    // MARK: - 挑战管理
    
    /// 检查并激活挑战
    func checkAndActivateChallenges() {
        let now = Date()
        
        // 获取预设挑战
        let dailyChallenges = DreamChallengeTemplate.dailyChallenges()
        let weeklyChallenges = DreamChallengeTemplate.weeklyChallenges()
        let monthlyChallenges = DreamChallengeTemplate.monthlyChallenges()
        
        var allChallenges = dailyChallenges + weeklyChallenges + monthlyChallenges
        
        // 过滤激活的挑战
        activeChallenges = allChallenges.filter { challenge in
            challenge.isActive &&
            challenge.startDate <= now &&
            challenge.endDate >= now &&
            !(userProgress[challenge.id]?.isCompleted ?? false)
        }
        
        // 更新每个挑战的当前进度
        updateAllChallengesProgress()
    }
    
    /// 更新所有挑战进度
    func updateAllChallengesProgress() {
        for challenge in activeChallenges {
            updateChallengeProgress(challenge)
        }
    }
    
    /// 更新单个挑战进度
    func updateChallengeProgress(_ challenge: DreamChallenge) {
        // 这里需要根据挑战类型计算实际进度
        // 简化版本：从 DreamStore 获取数据计算
        
        guard var progress = userProgress[challenge.id] else {
            // 创建新进度
            let newProgress = UserChallengeProgress(
                challengeId: challenge.id,
                userId: "current_user",
                startDate: Date(),
                progress: [:],
                currentTotal: 0
            )
            userProgress[challenge.id] = newProgress
            return
        }
        
        // 根据挑战类型计算进度
        switch challenge.goal.type {
        case .recordCount:
            progress.currentTotal = calculateRecordCount(since: challenge.startDate)
        case .lucidCount:
            progress.currentTotal = calculateLucidCount(since: challenge.startDate)
        case .emotionVariety:
            progress.currentTotal = calculateEmotionVariety(since: challenge.startDate)
        case .themeExploration:
            progress.currentTotal = calculateThemeCount(since: challenge.startDate)
        case .clarityAverage:
            progress.currentTotal = Int(calculateAverageClarity(since: challenge.startDate) * 10)
        case .consecutiveDays:
            progress.currentTotal = calculateConsecutiveDays()
        case .realityChecks:
            progress.currentTotal = calculateRealityChecks(since: challenge.startDate)
        case .dreamLength:
            progress.currentTotal = calculateTotalDreamLength(since: challenge.startDate)
        }
        
        progress.currentTotal = min(progress.currentTotal, challenge.goal.targetValue)
        progress.lastUpdated = Date()
        
        // 检查是否完成
        if progress.currentTotal >= challenge.goal.targetValue {
            progress.isCompleted = true
            progress.completedDate = Date()
            completeChallenge(challenge)
        }
        
        userProgress[challenge.id] = progress
        saveData()
    }
    
    // MARK: - 进度计算辅助方法
    
    private func calculateRecordCount(since date: Date) -> Int {
        let dreamStore = DreamStore.shared
        return dreamStore.dreams.filter { $0.date >= date }.count
    }
    
    private func calculateLucidCount(since date: Date) -> Int {
        let dreamStore = DreamStore.shared
        return dreamStore.dreams.filter { $0.isLucid && $0.date >= date }.count
    }
    
    private func calculateEmotionVariety(since date: Date) -> Int {
        let dreamStore = DreamStore.shared
        var emotionSet = Set<Emotion>()
        for dream in dreamStore.dreams where dream.date >= date {
            emotionSet.formUnion(dream.emotions)
        }
        return emotionSet.count
    }
    
    private func calculateThemeCount(since date: Date) -> Int {
        let dreamStore = DreamStore.shared
        var tagSet = Set<String>()
        for dream in dreamStore.dreams where dream.date >= date {
            tagSet.formUnion(dream.tags)
        }
        return tagSet.count
    }
    
    private func calculateAverageClarity(since date: Date) -> Double {
        let dreamStore = DreamStore.shared
        let dreams = dreamStore.dreams.filter { $0.date >= date }
        guard !dreams.isEmpty else { return 0.0 }
        let total = dreams.reduce(0) { $0 + $1.clarity }
        return Double(total) / Double(dreams.count)
    }
    
    private func calculateConsecutiveDays() -> Int {
        let dreamStore = DreamStore.shared
        guard !dreamStore.dreams.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedDreams = dreamStore.dreams.sorted { $0.date > $1.date }
        var streak = 1
        var lastDate = calendar.startOfDay(for: sortedDreams[0].date)
        
        for i in 1..<sortedDreams.count {
            let currentDate = calendar.startOfDay(for: sortedDreams[i].date)
            let daysDiff = calendar.dateComponents([.day], from: currentDate, to: lastDate).day ?? 0
            
            if daysDiff == 1 {
                streak += 1
                lastDate = currentDate
            } else if daysDiff > 1 {
                break
            }
            // daysDiff == 0 表示同一天，跳过
        }
        
        return streak
    }
    
    private func calculateRealityChecks(since date: Date) -> Int {
        // TODO: 需要从 LucidDreamTrainingService 获取现实检查次数
        // 暂时返回清醒梦数量作为替代
        return calculateLucidCount(since: date)
    }
    
    private func calculateTotalDreamLength(since date: Date) -> Int {
        let dreamStore = DreamStore.shared
        let dreams = dreamStore.dreams.filter { $0.date >= date }
        // 估算：每个梦境平均字数 / 100 作为长度单位
        return dreams.reduce(0) { $0 + ($1.content.count / 100) }
    }
    
    // MARK: - 挑战完成
    
    /// 完成挑战
    func completeChallenge(_ challenge: DreamChallenge) {
        guard !challenge.isCompleted else { return }
        
        challenge.isCompleted = true
        
        // 移动到已完成列表
        if !completedChallenges.contains(where: { $0.id == challenge.id }) {
            completedChallenges.append(challenge)
        }
        
        // 从活跃列表移除
        activeChallenges.removeAll { $0.id == challenge.id }
        
        // 发放奖励
        distributeReward(challenge.reward)
        
        // 更新统计
        updateStatistics(for: challenge)
        
        // 检查徽章解锁
        checkBadgeUnlocks()
        
        saveData()
        
        print("🎉 挑战完成：\(challenge.title)")
    }
    
    /// 发放奖励
    func distributeReward(_ reward: DreamChallengeReward) {
        switch reward.type {
        case .points:
            totalPoints += reward.value
            currentLevel = totalPoints / 100 + 1
            print("⭐ 获得 \(reward.value) 积分，总积分：\(totalPoints)")
            
        case .badge:
            // 解锁徽章
            let allBadges = DreamChallengeTemplate.allBadges()
            if reward.value < allBadges.count {
                var badge = allBadges[reward.value]
                badge.isUnlocked = true
                badge.unlockedDate = Date()
                if !unlockedBadges.contains(badge) {
                    unlockedBadges.append(badge)
                    statistics.totalBadgesEarned += 1
                    print("🏅 解锁徽章：\(badge.name)")
                }
            }
            
        case .streak:
            // 连续记录加成 (简化处理)
            print("🔥 获得连续记录加成")
            
        case .theme:
            // 解锁主题 (简化处理)
            print("🎨 解锁新主题")
            
        case .feature:
            // 解锁功能 (简化处理)
            print("🔧 解锁新功能")
        }
        
        saveData()
    }
    
    /// 更新统计数据
    func updateStatistics(for challenge: DreamChallenge) {
        statistics.totalChallengesCompleted += 1
        
        // 按类型统计
        statistics.challengesByType[challenge.type, default: 0] += 1
        
        // 按难度统计
        statistics.challengesByDifficulty[challenge.difficulty, default: 0] += 1
        
        // 月度统计
        let month = Calendar.current.component(.month, from: Date())
        if month >= 1 && month <= 12 {
            statistics.monthlyProgress[month - 1] += 1
        }
        
        // 添加最近成就
        let achievement = "完成挑战：\(challenge.title)"
        statistics.recentAchievements.insert(achievement, at: 0)
        if statistics.recentAchievements.count > 10 {
            statistics.recentAchievements.removeLast()
        }
    }
    
    // MARK: - 徽章系统
    
    /// 检查徽章解锁
    func checkBadgeUnlocks() {
        let allBadges = DreamChallengeTemplate.allBadges()
        let dreamStore = DreamStore.shared
        
        for badge in allBadges where !unlockedBadges.contains(badge) {
            var shouldUnlock = false
            
            // 检查解锁条件
            switch badge.name {
            case "新手记录者":
                shouldUnlock = dreamStore.dreams.count >= 1
                
            case "坚持之星":
                shouldUnlock = calculateConsecutiveDays() >= 7
                
            case "记录达人":
                shouldUnlock = dreamStore.dreams.count >= 100
                
            case "梦境大师":
                shouldUnlock = dreamStore.dreams.count >= 500
                
            case "清醒新手":
                shouldUnlock = dreamStore.dreams.filter { $0.isLucid }.count >= 1
                
            case "清醒探索者":
                shouldUnlock = dreamStore.dreams.filter { $0.isLucid }.count >= 10
                
            case "清醒梦大师":
                shouldUnlock = dreamStore.dreams.filter { $0.isLucid }.count >= 50
                
            case "三日连记":
                shouldUnlock = calculateConsecutiveDays() >= 3
                
            case "周记不断":
                shouldUnlock = calculateConsecutiveDays() >= 7
                
            case "月记传奇":
                shouldUnlock = calculateConsecutiveDays() >= 30
                
            default:
                break
            }
            
            if shouldUnlock {
                var unlockedBadge = badge
                unlockedBadge.isUnlocked = true
                unlockedBadge.unlockedDate = Date()
                unlockedBadges.append(unlockedBadge)
                statistics.totalBadgesEarned += 1
                totalPoints += badge.points
                print("🏅 解锁徽章：\(badge.name) (+\(badge.points) 积分)")
            }
        }
        
        saveData()
    }
    
    // MARK: - 梦境记录触发
    
    /// 当新梦境记录时调用
    func onDreamRecorded(_ dream: Dream) {
        // 更新所有活跃挑战的进度
        for challenge in activeChallenges {
            updateChallengeProgress(challenge)
        }
        
        // 检查徽章解锁
        checkBadgeUnlocks()
    }
    
    /// 当清醒梦记录时调用
    func onLucidDreamRecorded(_ dream: Dream) {
        // 特殊处理清醒梦相关挑战
        for challenge in activeChallenges where challenge.type == .lucid {
            updateChallengeProgress(challenge)
        }
    }
    
    // MARK: - 查询方法
    
    /// 获取挑战详情
    func getChallenge(by id: UUID) -> DreamChallenge? {
        return activeChallenges.first { $0.id == id }
            ?? completedChallenges.first { $0.id == id }
    }
    
    /// 获取挑战进度
    func getProgress(for challengeId: UUID) -> UserChallengeProgress? {
        return userProgress[challengeId]
    }
    
    /// 获取进度百分比
    func getProgressPercentage(for challengeId: UUID) -> Double {
        guard let progress = userProgress[challengeId],
              let challenge = getChallenge(by: challengeId) else {
            return 0.0
        }
        return Double(progress.currentTotal) / Double(challenge.goal.targetValue)
    }
    
    /// 获取按类型筛选的挑战
    func getChallenges(by type: DreamChallengeType) -> [DreamChallenge] {
        return activeChallenges.filter { $0.type == type }
    }
    
    /// 获取按难度筛选的挑战
    func getChallenges(by difficulty: DreamChallengeDifficulty) -> [DreamChallenge] {
        return activeChallenges.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - 领取奖励
    
    /// 领取挑战奖励
    func claimReward(for challengeId: UUID) -> Bool {
        guard let progress = userProgress[challengeId],
              progress.isCompleted,
              !progress.claimedReward,
              let challenge = getChallenge(by: challengeId) else {
            return false
        }
        
        // 标记为已领取
        var updatedProgress = progress
        updatedProgress.claimedReward = true
        userProgress[challengeId] = updatedProgress
        
        // 发放奖励
        distributeReward(challenge.reward)
        
        saveData()
        return true
    }
    
    // MARK: - 重置
    
    /// 重置每日挑战
    func resetDailyChallenges() {
        let today = Date()
        let calendar = Calendar.current
        
        // 检查是否需要重置 (新的一天)
        let lastReset = UserDefaults.standard.object(forKey: "DreamLog_LastDailyReset") as? Date ?? Date.distantPast
        
        if !calendar.isDate(today, inSameDayAs: lastReset) {
            // 移除过期的每日挑战
            activeChallenges.removeAll { challenge in
                challenge.period == .daily && challenge.endDate < today
            }
            
            // 添加新的每日挑战
            let newDailyChallenges = DreamChallengeTemplate.dailyChallenges()
            for challenge in newDailyChallenges {
                if !activeChallenges.contains(where: { $0.id == challenge.id }) {
                    activeChallenges.append(challenge)
                }
            }
            
            UserDefaults.standard.set(today, forKey: "DreamLog_LastDailyReset")
            saveData()
            
            print("🔄 每日挑战已重置")
        }
    }
    
    /// 重置每周挑战
    func resetWeeklyChallenges() {
        // 类似每日挑战的逻辑
    }
    
    /// 重置每月挑战
    func resetMonthlyChallenges() {
        // 类似每日挑战的逻辑
    }
}

// MARK: - 扩展：与 DreamStore 集成

extension DreamChallengeService {
    
    /// 设置梦境记录监听
    func setupDreamListener() {
        // 这里可以监听 DreamStore 的变化
        // 当新梦境添加时自动更新挑战进度
    }
}
