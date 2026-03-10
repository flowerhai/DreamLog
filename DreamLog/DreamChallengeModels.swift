//
//  DreamChallengeModels.swift
//  DreamLog
//
//  梦境挑战系统数据模型
//  Phase 15 - 梦境挑战系统
//

import Foundation

// MARK: - 挑战类型

/// 挑战类型枚举
enum DreamChallengeType: String, Codable, CaseIterable, Identifiable {
    case recording = "recording"           // 记录挑战
    case lucid = "lucid"                   // 清醒梦挑战
    case emotion = "emotion"               // 情绪探索挑战
    case theme = "theme"                   // 主题挑战
    case creativity = "creativity"         // 创意挑战
    case mindfulness = "mindfulness"       // 正念挑战
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .recording: return "📝 记录挑战"
        case .lucid: return "👁️ 清醒梦挑战"
        case .emotion: return "💖 情绪探索"
        case .theme: return "🎨 主题挑战"
        case .creativity: return "✨ 创意挑战"
        case .mindfulness: return "🧘 正念挑战"
        }
    }
    
    var icon: String {
        switch self {
        case .recording: return "text.badge.checkmark"
        case .lucid: return "eye.fill"
        case .emotion: return "heart.fill"
        case .theme: return "paintpalette.fill"
        case .creativity: return "sparkles"
        case .mindfulness: return "figure.mind.and.body"
        }
    }
    
    var description: String {
        switch self {
        case .recording: return "坚持记录梦境，培养记录习惯"
        case .lucid: return "练习清醒梦技巧，探索意识边界"
        case .emotion: return "探索不同情绪，了解内心世界"
        case .theme: return "聚焦特定主题，发现梦境模式"
        case .creativity: return "发挥创意想象，记录奇幻梦境"
        case .mindfulness: return "保持正念觉知，提升梦境清晰度"
        }
    }
}

// MARK: - 挑战难度

/// 挑战难度级别
enum DreamChallengeDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"         // 简单
    case medium = "medium"     // 中等
    case hard = "hard"         // 困难
    case expert = "expert"     // 专家
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy: return "⭐ 简单"
        case .medium: return "⭐⭐ 中等"
        case .hard: return "⭐⭐⭐ 困难"
        case .expert: return "⭐⭐⭐⭐ 专家"
        }
    }
    
    var pointsMultiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .expert: return 3.0
        }
    }
    
    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "blue"
        case .hard: return "orange"
        case .expert: return "purple"
        }
    }
}

// MARK: - 挑战周期

/// 挑战周期类型
enum DreamChallengePeriod: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"           // 每日
    case weekly = "weekly"         // 每周
    case biweekly = "biweekly"     // 双周
    case monthly = "monthly"       // 每月
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .daily: return "每日挑战"
        case .weekly: return "每周挑战"
        case .biweekly: return "双周挑战"
        case .monthly: return "每月挑战"
        }
    }
    
    var durationDays: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        }
    }
}

// MARK: - 挑战模型

/// 梦境挑战数据模型
struct DreamChallenge: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String                   // 挑战标题
    var description: String             // 挑战描述
    var type: DreamChallengeType        // 挑战类型
    var difficulty: DreamChallengeDifficulty  // 难度级别
    var period: DreamChallengePeriod    // 周期
    var goal: DreamChallengeGoal        // 挑战目标
    var reward: DreamChallengeReward    // 奖励
    var startDate: Date                 // 开始日期
    var endDate: Date                   // 结束日期
    var isActive: Bool = true           // 是否激活
    var isCompleted: Bool = false       // 是否已完成
    var participantCount: Int = 0       // 参与人数 (社区挑战)
    var completionRate: Double = 0.0    // 完成率 (社区挑战)
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, type, difficulty, period, goal, reward
        case startDate, endDate, isActive, isCompleted, participantCount, completionRate
    }
}

// MARK: - 挑战目标

/// 挑战目标类型
enum DreamChallengeGoalType: String, Codable, CaseIterable {
    case recordCount = "recordCount"         // 记录数量
    case lucidCount = "lucidCount"           // 清醒梦数量
    case emotionVariety = "emotionVariety"   // 情绪多样性
    case themeExploration = "themeExploration" // 主题探索
    case clarityAverage = "clarityAverage"   // 平均清晰度
    case consecutiveDays = "consecutiveDays" // 连续天数
    case realityChecks = "realityChecks"     // 现实检查次数
    case dreamLength = "dreamLength"         // 梦境长度
    
    var displayName: String {
        switch self {
        case .recordCount: return "记录数量"
        case .lucidCount: return "清醒梦数量"
        case .emotionVariety: return "情绪多样性"
        case .themeExploration: return "主题探索"
        case .clarityAverage: return "平均清晰度"
        case .consecutiveDays: return "连续记录"
        case .realityChecks: return "现实检查"
        case .dreamLength: return "梦境长度"
        }
    }
}

/// 挑战目标
struct DreamChallengeGoal: Codable {
    var type: DreamChallengeGoalType      // 目标类型
    var targetValue: Int                  // 目标值
    var currentValue: Int = 0             // 当前值
    var unit: String                      // 单位
    
    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var isCompleted: Bool {
        return progress >= 1.0
    }
}

// MARK: - 挑战奖励

/// 奖励类型
enum DreamChallengeRewardType: String, Codable, CaseIterable {
    case points = "points"               // 积分
    case badge = "badge"                 // 徽章
    case streak = "streak"               // 连续记录加成
    case theme = "theme"                 // 主题解锁
    case feature = "feature"             // 功能解锁
    
    var displayName: String {
        switch self {
        case .points: return "积分奖励"
        case .badge: return "徽章奖励"
        case .streak: return "连续加成"
        case .theme: return "主题解锁"
        case .feature: return "功能解锁"
        }
    }
}

/// 挑战奖励
struct DreamChallengeReward: Codable {
    var type: DreamChallengeRewardType    // 奖励类型
    var value: Int                        // 奖励值 (积分数量/徽章 ID 等)
    var description: String               // 奖励描述
    
    var icon: String {
        switch type {
        case .points: return "star.fill"
        case .badge: return "shield.fill"
        case .streak: return "flame.fill"
        case .theme: return "paintbrush.fill"
        case .feature: return "wrench.and.screwdriver.fill"
        }
    }
}

// MARK: - 用户挑战进度

/// 用户挑战进度
struct UserChallengeProgress: Identifiable, Codable {
    var id: UUID = UUID()
    var challengeId: UUID                 // 挑战 ID
    var userId: String                    // 用户 ID
    var startDate: Date                   // 开始日期
    var progress: [String: Int]           // 进度数据 (key: 梦境 ID, value: 贡献值)
    var currentTotal: Int = 0             // 当前总计
    var isCompleted: Bool = false         // 是否完成
    var completedDate: Date?              // 完成日期
    var claimedReward: Bool = false       // 是否领取奖励
    var lastUpdated: Date = Date()        // 最后更新时间
    
    var progressPercentage: Double {
        // 由服务层计算
        return 0.0
    }
}

// MARK: - 挑战徽章

/// 挑战徽章
struct ChallengeBadge: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String                      // 徽章名称
    var description: String               // 徽章描述
    var icon: String                      // 徽章图标 (SF Symbol)
    var category: BadgeCategory           // 徽章类别
    var requirement: String               // 获取要求
    var points: Int                       // 徽章积分
    var isUnlocked: Bool = false          // 是否已解锁
    var unlockedDate: Date?               // 解锁日期
    
    enum BadgeCategory: String, Codable, CaseIterable {
        case recording = "recording"       // 记录类
        case lucid = "lucid"               // 清醒梦类
        case streak = "streak"             // 连续类
        case exploration = "exploration"   // 探索类
        case creativity = "creativity"     // 创意类
        case special = "special"           // 特殊类
        
        var displayName: String {
            switch self {
            case .recording: return "📝 记录"
            case .lucid: return "👁️ 清醒梦"
            case .streak: return "🔥 连续"
            case .exploration: return "🔍 探索"
            case .creativity: return "✨ 创意"
            case .special: return "🌟 特殊"
            }
        }
    }
}

// MARK: - 预设挑战模板

/// 预设挑战模板
struct DreamChallengeTemplate {
    
    /// 生成每日挑战
    static func dailyChallenges() -> [DreamChallenge] {
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return [
            DreamChallenge(
                title: "🌅 晨间记录",
                description: "起床后 30 分钟内记录一个梦境",
                type: .recording,
                difficulty: .easy,
                period: .daily,
                goal: DreamChallengeGoal(type: .recordCount, targetValue: 1, unit: "个梦境"),
                reward: DreamChallengeReward(type: .points, value: 10, description: "获得 10 积分"),
                startDate: today,
                endDate: endDate
            ),
            DreamChallenge(
                title: "👁️ 清醒梦练习",
                description: "记录一个清醒梦或进行 5 次现实检查",
                type: .lucid,
                difficulty: .medium,
                period: .daily,
                goal: DreamChallengeGoal(type: .lucidCount, targetValue: 1, unit: "个清醒梦"),
                reward: DreamChallengeReward(type: .points, value: 25, description: "获得 25 积分"),
                startDate: today,
                endDate: endDate
            ),
            DreamChallenge(
                title: "💖 情绪探索",
                description: "记录包含 3 种以上情绪的梦境",
                type: .emotion,
                difficulty: .medium,
                period: .daily,
                goal: DreamChallengeGoal(type: .emotionVariety, targetValue: 3, unit: "种情绪"),
                reward: DreamChallengeReward(type: .points, value: 20, description: "获得 20 积分"),
                startDate: today,
                endDate: endDate
            )
        ]
    }
    
    /// 生成每周挑战
    static func weeklyChallenges() -> [DreamChallenge] {
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        
        return [
            DreamChallenge(
                title: "📝 一周记录者",
                description: "连续 7 天记录梦境",
                type: .recording,
                difficulty: .hard,
                period: .weekly,
                goal: DreamChallengeGoal(type: .consecutiveDays, targetValue: 7, unit: "天"),
                reward: DreamChallengeReward(type: .badge, value: 1, description: "获得「坚持之星」徽章"),
                startDate: today,
                endDate: endDate
            ),
            DreamChallenge(
                title: "🎨 主题探索周",
                description: "记录 5 个包含「飞行」主题的梦境",
                type: .theme,
                difficulty: .hard,
                period: .weekly,
                goal: DreamChallengeGoal(type: .themeExploration, targetValue: 5, unit: "个梦境"),
                reward: DreamChallengeReward(type: .points, value: 100, description: "获得 100 积分"),
                startDate: today,
                endDate: endDate
            ),
            DreamChallenge(
                title: "✨ 创意大师",
                description: "记录 3 个超现实的奇幻梦境",
                type: .creativity,
                difficulty: .medium,
                period: .weekly,
                goal: DreamChallengeGoal(type: .recordCount, targetValue: 3, unit: "个创意梦境"),
                reward: DreamChallengeReward(type: .points, value: 75, description: "获得 75 积分"),
                startDate: today,
                endDate: endDate
            )
        ]
    }
    
    /// 生成每月挑战
    static func monthlyChallenges() -> [DreamChallenge] {
        let today = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 30, to: today)!
        
        return [
            DreamChallenge(
                title: "🏆 月度记录大师",
                description: "本月记录 30 个梦境",
                type: .recording,
                difficulty: .expert,
                period: .monthly,
                goal: DreamChallengeGoal(type: .recordCount, targetValue: 30, unit: "个梦境"),
                reward: DreamChallengeReward(type: .badge, value: 2, description: "获得「月度大师」徽章"),
                startDate: today,
                endDate: endDate
            ),
            DreamChallenge(
                title: "👁️ 清醒梦修行者",
                description: "本月记录 10 个清醒梦",
                type: .lucid,
                difficulty: .expert,
                period: .monthly,
                goal: DreamChallengeGoal(type: .lucidCount, targetValue: 10, unit: "个清醒梦"),
                reward: DreamChallengeReward(type: .badge, value: 3, description: "获得「清醒梦大师」徽章"),
                startDate: today,
                endDate: endDate
            ),
            DreamChallenge(
                title: "🧘 正念修行",
                description: "本月平均梦境清晰度达到 4.0 以上",
                type: .mindfulness,
                difficulty: .expert,
                period: .monthly,
                goal: DreamChallengeGoal(type: .clarityAverage, targetValue: 4, unit: "清晰度"),
                reward: DreamChallengeReward(type: .badge, value: 4, description: "获得「正念大师」徽章"),
                startDate: today,
                endDate: endDate
            )
        ]
    }
    
    /// 获取所有预设徽章
    static func allBadges() -> [ChallengeBadge] {
        return [
            // 记录类徽章
            ChallengeBadge(
                name: "新手记录者",
                description: "首次记录梦境",
                icon: "pencil.circle.fill",
                category: .recording,
                requirement: "记录第一个梦境",
                points: 10
            ),
            ChallengeBadge(
                name: "坚持之星",
                description: "连续 7 天记录梦境",
                icon: "star.circle.fill",
                category: .recording,
                requirement: "连续记录 7 天",
                points: 50
            ),
            ChallengeBadge(
                name: "记录达人",
                description: "累计记录 100 个梦境",
                icon: "book.fill",
                category: .recording,
                requirement: "累计记录 100 个梦境",
                points: 200
            ),
            ChallengeBadge(
                name: "梦境大师",
                description: "累计记录 500 个梦境",
                icon: "crown.fill",
                category: .recording,
                requirement: "累计记录 500 个梦境",
                points: 1000
            ),
            
            // 清醒梦类徽章
            ChallengeBadge(
                name: "清醒新手",
                description: "首次记录清醒梦",
                icon: "eye.circle.fill",
                category: .lucid,
                requirement: "记录第一个清醒梦",
                points: 50
            ),
            ChallengeBadge(
                name: "清醒探索者",
                description: "累计记录 10 个清醒梦",
                icon: "eye.fill",
                category: .lucid,
                requirement: "累计记录 10 个清醒梦",
                points: 200
            ),
            ChallengeBadge(
                name: "清醒梦大师",
                description: "累计记录 50 个清醒梦",
                icon: "sparkles",
                category: .lucid,
                requirement: "累计记录 50 个清醒梦",
                points: 500
            ),
            
            // 连续类徽章
            ChallengeBadge(
                name: "三日连记",
                description: "连续记录 3 天",
                icon: "flame.circle.fill",
                category: .streak,
                requirement: "连续记录 3 天",
                points: 30
            ),
            ChallengeBadge(
                name: "周记不断",
                description: "连续记录 7 天",
                icon: "flame.fill",
                category: .streak,
                requirement: "连续记录 7 天",
                points: 100
            ),
            ChallengeBadge(
                name: "月记传奇",
                description: "连续记录 30 天",
                icon: "fire.fill",
                category: .streak,
                requirement: "连续记录 30 天",
                points: 500
            ),
            
            // 探索类徽章
            ChallengeBadge(
                name: "情绪探索者",
                description: "记录包含 10 种不同情绪的梦境",
                icon: "heart.circle.fill",
                category: .exploration,
                requirement: "体验 10 种不同情绪",
                points: 100
            ),
            ChallengeBadge(
                name: "主题猎手",
                description: "记录 20 种不同主题的梦境",
                icon: "tag.circle.fill",
                category: .exploration,
                requirement: "探索 20 种不同主题",
                points: 150
            ),
            
            // 创意类徽章
            ChallengeBadge(
                name: "创意新星",
                description: "记录 10 个超现实梦境",
                icon: "lightbulb.fill",
                category: .creativity,
                requirement: "10 个超现实梦境",
                points: 100
            ),
            ChallengeBadge(
                name: "奇幻作家",
                description: "记录 50 个创意梦境",
                icon: "wand.and.stars",
                category: .creativity,
                requirement: "50 个创意梦境",
                points: 300
            ),
            
            // 特殊徽章
            ChallengeBadge(
                name: "午夜记录者",
                description: "在凌晨 3 点记录梦境",
                icon: "moon.stars.fill",
                category: .special,
                requirement: "凌晨 3 点记录",
                points: 50
            ),
            ChallengeBadge(
                name: "百日修行",
                description: "连续记录 100 天",
                icon: "trophy.fill",
                category: .special,
                requirement: "连续记录 100 天",
                points: 2000
            )
        ]
    }
}

// MARK: - 挑战统计数据

/// 挑战统计数据
struct ChallengeStatistics: Codable {
    var totalChallengesCompleted: Int = 0       // 总完成挑战数
    var totalPointsEarned: Int = 0              // 总获得积分
    var totalBadgesEarned: Int = 0              // 总获得徽章数
    var currentStreak: Int = 0                  // 当前连续天数
    var longestStreak: Int = 0                  // 最长连续天数
    var challengesByType: [DreamChallengeType: Int] = [:]  // 按类型统计
    var challengesByDifficulty: [DreamChallengeDifficulty: Int] = [:]  // 按难度统计
    var monthlyProgress: [Int] = Array(repeating: 0, count: 12)  // 每月完成数
    var recentAchievements: [String] = []       // 最近成就
    
    var level: Int {
        // 根据积分计算等级
        return totalPointsEarned / 100 + 1
    }
    
    var nextLevelPoints: Int {
        return (level + 1) * 100 - totalPointsEarned
    }
}
