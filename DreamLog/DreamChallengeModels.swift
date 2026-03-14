//
//  DreamChallengeModels.swift
//  DreamLog
//
//  Phase 41 - 梦境挑战系统
//  数据模型
//

import Foundation
import SwiftData

// MARK: - 挑战类型

/// 梦境挑战类型
enum DreamChallengeType: String, CaseIterable, Codable, Identifiable {
    case recall = "recall"           // 梦境回忆挑战
    case lucid = "lucid"             // 清醒梦挑战
    case theme = "theme"             // 主题探索挑战
    case creative = "creative"       // 创意梦境挑战
    case mindfulness = "mindfulness" // 正念梦境挑战
    case streak = "streak"           // 连续记录挑战
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .recall: return "🧠 梦境回忆"
        case .lucid: return "💫 清醒梦"
        case .theme: return "🎨 主题探索"
        case .creative: return "✨ 创意梦境"
        case .mindfulness: return "🧘 正念梦境"
        case .streak: return "🔥 连续记录"
        }
    }
    
    var description: String {
        switch self {
        case .recall: return "提高梦境回忆能力，记住更多梦境细节"
        case .lucid: return "练习清醒梦技巧，在梦中保持意识"
        case .theme: return "探索特定主题的梦境，发现潜意识秘密"
        case .creative: return "激发创意灵感，从梦境中获取创作素材"
        case .mindfulness: return "培养正念意识，改善睡眠质量"
        case .streak: return "坚持记录梦境，养成良好习惯"
        }
    }
    
    var icon: String {
        switch self {
        case .recall: return "🧠"
        case .lucid: return "💫"
        case .theme: return "🎨"
        case .creative: return "✨"
        case .mindfulness: return "🧘"
        case .streak: return "🔥"
        }
    }
}

// MARK: - 挑战难度

/// 挑战难度等级
enum ChallengeDifficulty: String, CaseIterable, Codable {
    case easy = "easy"       // 简单
    case medium = "medium"   // 中等
    case hard = "hard"       // 困难
    case expert = "expert"   // 专家
    
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
}

// MARK: - 挑战状态

/// 挑战参与状态
enum ChallengeStatus: String, CaseIterable, Codable {
    case available = "available"       // 可参与
    case inProgress = "inProgress"     // 进行中
    case completed = "completed"       // 已完成
    case failed = "failed"             // 已失败
    case expired = "expired"           // 已过期
    
    var displayName: String {
        switch self {
        case .available: return "可参与"
        case .inProgress: return "进行中"
        case .completed: return "已完成"
        case .failed: return "已失败"
        case .expired: return "已过期"
        }
    }
    
    var color: String {
        switch self {
        case .available: return "green"
        case .inProgress: return "blue"
        case .completed: return "purple"
        case .failed: return "red"
        case .expired: return "gray"
        }
    }
}

// MARK: - 挑战任务

/// 挑战任务类型
enum ChallengeTaskType: String, CaseIterable, Codable {
    case recordDream = "recordDream"           // 记录梦境
    case achieveLucid = "achieveLucid"         // 达成清醒梦
    case specificTheme = "specificTheme"       // 特定主题梦境
    case realityCheck = "realityCheck"         // 现实检查
    case meditation = "meditation"             // 冥想练习
    case sleepSchedule = "sleepSchedule"       // 规律作息
    case dreamRecall = "dreamRecall"           // 梦境回忆练习
    case creativeWriting = "creativeWriting"   // 创意写作
    case shareDream = "shareDream"             // 分享梦境
    
    var displayName: String {
        switch self {
        case .recordDream: return "记录梦境"
        case .achieveLucid: return "清醒梦"
        case .specificTheme: return "主题梦境"
        case .realityCheck: return "现实检查"
        case .meditation: return "冥想练习"
        case .sleepSchedule: return "规律作息"
        case .dreamRecall: return "回忆练习"
        case .creativeWriting: return "创意写作"
        case .shareDream: return "分享梦境"
        }
    }
}

// MARK: - 挑战任务模型

/// 挑战任务
@Model
final class ChallengeTask {
    var id: UUID
    var type: ChallengeTaskType
    var title: String
    var description: String
    var targetCount: Int           // 目标次数
    var currentCount: Int          // 当前进度
    var isCompleted: Bool
    var completedAt: Date?
    var points: Int                // 任务积分
    
    init(
        id: UUID = UUID(),
        type: ChallengeTaskType,
        title: String,
        description: String,
        targetCount: Int,
        currentCount: Int = 0,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        points: Int
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.points = points
    }
    
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - 挑战模型

/// 梦境挑战
@Model
final class DreamChallenge {
    var id: UUID
    var title: String
    var description: String
    var type: DreamChallengeType
    var difficulty: ChallengeDifficulty
    var status: ChallengeStatus
    var startDate: Date
    var endDate: Date
    var tasks: [ChallengeTask]
    var totalPoints: Int
    var earnedPoints: Int
    var badge: String?
    var isFavorite: Bool
    var participantCount: Int
    var completionRate: Double
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: DreamChallengeType,
        difficulty: ChallengeDifficulty,
        status: ChallengeStatus = .available,
        startDate: Date,
        endDate: Date,
        tasks: [ChallengeTask] = [],
        totalPoints: Int = 0,
        earnedPoints: Int = 0,
        badge: String? = nil,
        isFavorite: Bool = false,
        participantCount: Int = 0,
        completionRate: Double = 0,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.difficulty = difficulty
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.tasks = tasks
        self.totalPoints = totalPoints
        self.earnedPoints = earnedPoints
        self.badge = badge
        self.isFavorite = isFavorite
        self.participantCount = participantCount
        self.completionRate = completionRate
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
    
    var isExpired: Bool {
        Date() > endDate
    }
    
    var isOngoing: Bool {
        status == .inProgress && !isExpired
    }
    
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    var totalDays: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
    
    var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - 挑战成就

/// 挑战成就徽章
@Model
final class ChallengeBadge {
    var id: UUID
    var name: String
    var icon: String
    var description: String
    var requirement: String
    var earnedAt: Date
    var challengeId: UUID?
    var points: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        description: String,
        requirement: String,
        earnedAt: Date = Date(),
        challengeId: UUID? = nil,
        points: Int
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.description = description
        self.requirement = requirement
        self.earnedAt = earnedAt
        self.challengeId = challengeId
        self.points = points
    }
}

// MARK: - 挑战统计

/// 挑战统计数据
struct ChallengeStats {
    var totalChallenges: Int
    var completedChallenges: Int
    var inProgressChallenges: Int
    var totalPoints: Int
    var totalBadges: Int
    var completionRate: Double
    var favoriteType: DreamChallengeType?
    var currentStreak: Int
    var longestStreak: Int
    
    var completionRatePercentage: Int {
        guard totalChallenges > 0 else { return 0 }
        return Int((Double(completedChallenges) / Double(totalChallenges)) * 100)
    }
}

// MARK: - 预设挑战模板

extension DreamChallenge {
    /// 创建预设挑战模板
    static func createPresetChallenges() -> [DreamChallenge] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            // 7 天梦境回忆挑战
            DreamChallenge(
                title: "7 天梦境回忆大师",
                description: "连续 7 天记录梦境，提高梦境回忆能力",
                type: .recall,
                difficulty: .easy,
                status: .available,
                startDate: now,
                endDate: calendar.date(byAdding: .day, value: 7, to: now)!,
                tasks: [
                    ChallengeTask(type: .recordDream, title: "记录梦境", description: "每天至少记录 1 个梦境", targetCount: 7, points: 10),
                    ChallengeTask(type: .dreamRecall, title: "回忆练习", description: "醒来后静躺回忆 5 分钟", targetCount: 7, points: 5),
                    ChallengeTask(type: .creativeWriting, title: "细节描写", description: "为每个梦境添加至少 3 个细节", targetCount: 5, points: 15)
                ],
                totalPoints: 30,
                badge: "🧠 回忆大师"
            ),
            
            // 14 天清醒梦挑战
            DreamChallenge(
                title: "14 天清醒梦入门",
                description: "学习清醒梦技巧，实现第一次清醒梦",
                type: .lucid,
                difficulty: .medium,
                status: .available,
                startDate: now,
                endDate: calendar.date(byAdding: .day, value: 14, to: now)!,
                tasks: [
                    ChallengeTask(type: .realityCheck, title: "现实检查", description: "每天进行 10 次现实检查", targetCount: 140, points: 20),
                    ChallengeTask(type: .meditation, title: "冥想练习", description: "睡前冥想 10 分钟", targetCount: 14, points: 15),
                    ChallengeTask(type: .achieveLucid, title: "清醒梦", description: "实现至少 1 次清醒梦", targetCount: 1, points: 50),
                    ChallengeTask(type: .recordDream, title: "记录梦境", description: "记录所有梦境", targetCount: 10, points: 20)
                ],
                totalPoints: 105,
                badge: "💫 清醒行者"
            ),
            
            // 30 天连续记录挑战
            DreamChallenge(
                title: "30 天连续记录挑战",
                description: "坚持 30 天每天记录梦境，养成习惯",
                type: .streak,
                difficulty: .hard,
                status: .available,
                startDate: now,
                endDate: calendar.date(byAdding: .day, value: 30, to: now)!,
                tasks: [
                    ChallengeTask(type: .recordDream, title: "连续记录", description: "连续 30 天每天记录", targetCount: 30, points: 100),
                    ChallengeTask(type: .sleepSchedule, title: "规律作息", description: "保持固定作息时间", targetCount: 30, points: 30)
                ],
                totalPoints: 130,
                badge: "🔥 毅力之王"
            ),
            
            // 创意梦境挑战
            DreamChallenge(
                title: "创意梦境探索",
                description: "从梦境中获取创意灵感，完成创意作品",
                type: .creative,
                difficulty: .medium,
                status: .available,
                startDate: now,
                endDate: calendar.date(byAdding: .day, value: 21, to: now)!,
                tasks: [
                    ChallengeTask(type: .recordDream, title: "记录梦境", description: "记录 15 个梦境", targetCount: 15, points: 30),
                    ChallengeTask(type: .creativeWriting, title: "创意写作", description: "基于梦境创作 3 篇故事", targetCount: 3, points: 45),
                    ChallengeTask(type: .shareDream, title: "分享灵感", description: "分享 5 个创意梦境", targetCount: 5, points: 25)
                ],
                totalPoints: 100,
                badge: "✨ 创意达人"
            ),
            
            // 主题探索：飞行梦
            DreamChallenge(
                title: "飞行梦探索",
                description: "探索和记录所有与飞行相关的梦境",
                type: .theme,
                difficulty: .easy,
                status: .available,
                startDate: now,
                endDate: calendar.date(byAdding: .day, value: 14, to: now)!,
                tasks: [
                    ChallengeTask(type: .specificTheme, title: "飞行梦境", description: "记录 5 个飞行主题的梦", targetCount: 5, points: 50),
                    ChallengeTask(type: .meditation, title: "意向设定", description: "睡前设定飞行意向", targetCount: 10, points: 20),
                    ChallengeTask(type: .recordDream, title: "记录细节", description: "详细记录飞行感受", targetCount: 5, points: 30)
                ],
                totalPoints: 100,
                badge: "🕊️ 飞行者"
            ),
            
            // 正念梦境挑战
            DreamChallenge(
                title: "正念梦境修行",
                description: "通过正念冥想改善睡眠质量和梦境体验",
                type: .mindfulness,
                difficulty: .medium,
                status: .available,
                startDate: now,
                endDate: calendar.date(byAdding: .day, value: 21, to: now)!,
                tasks: [
                    ChallengeTask(type: .meditation, title: "睡前冥想", description: "每天睡前冥想 15 分钟", targetCount: 21, points: 42),
                    ChallengeTask(type: .sleepSchedule, title: "规律作息", description: "固定时间睡觉起床", targetCount: 21, points: 42),
                    ChallengeTask(type: .dreamRecall, title: "正念回忆", description: "以正念态度回忆梦境", targetCount: 15, points: 30)
                ],
                totalPoints: 114,
                badge: "🧘 正念大师"
            )
        ]
    }
}
