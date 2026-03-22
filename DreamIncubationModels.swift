//
//  DreamIncubationModels.swift
//  DreamLog - 梦境孵化数据模型
//
//  梦境孵化 (Dream Incubation) - 睡前设定意图来影响梦境内容
//  这是一种古老的实践，现代研究显示它可以提高特定主题梦境的出现概率
//

import Foundation
import SwiftData

// MARK: - 梦境孵化类型

/// 孵化目标类型
enum IncubationTargetType: String, Codable, CaseIterable {
    case problemSolving = "问题解决"      // 寻求问题的解决方案
    case creativity = "创意灵感"           // 获取创意和艺术灵感
    case emotionalHealing = "情绪疗愈"     // 处理情绪创伤
    case skillPractice = "技能练习"        // 练习某项技能 (如清醒梦)
    case exploration = "探索体验"          // 探索特定场景或体验
    case spiritual = "精神成长"            // 精神层面的探索
    case memory = "记忆处理"               // 处理特定记忆
    case general = "一般意图"              // 一般性意图设定
    
    var icon: String {
        switch self {
        case .problemSolving: return "lightbulb.fill"
        case .creativity: return "paintpalette.fill"
        case .emotionalHealing: return "heart.fill"
        case .skillPractice: return "target"
        case .exploration: return "globe"
        case .spiritual: return "star.fill"
        case .memory: return "clock.fill"
        case .general: return "sparkles"
        }
    }
    
    var color: String {
        switch self {
        case .problemSolving: return "FFD700"  // 金色
        case .creativity: return "FF6B6B"      // 珊瑚红
        case .emotionalHealing: return "FFB3BA" // 粉色
        case .skillPractice: return "4ECDC4"   // 青绿色
        case .exploration: return "45B7D1"     // 天蓝色
        case .spiritual: return "9B59B6"       // 紫色
        case .memory: return "95A5A6"          // 灰色
        case .general: return "3498DB"         // 蓝色
        }
    }
    
    var description: String {
        switch self {
        case .problemSolving: return "在梦中寻求现实问题的解决方案"
        case .creativity: return "激发创意灵感，获取艺术或写作灵感"
        case .emotionalHealing: return "处理情绪创伤，获得内心平静"
        case .skillPractice: return "在梦中练习清醒梦或其他技能"
        case .exploration: return "探索特定的场景、地点或体验"
        case .spiritual: return "精神层面的探索和成长"
        case .memory: return "处理和整合特定记忆"
        case .general: return "设定一般性的梦境意图"
        }
    }
}

// MARK: - 孵化强度等级

/// 孵化意图的强度等级
enum IncubationIntensity: Int, Codable, CaseIterable {
    case light = 1      // 轻度 - 简单的想法
    case moderate = 2   // 中度 - 明确的意图
    case strong = 3     // 强烈 - 深度专注
    case intense = 4    // 极致 - 完全沉浸
    
    var title: String {
        switch self {
        case .light: return "轻度"
        case .moderate: return "中度"
        case .strong: return "强烈"
        case .intense: return "极致"
        }
    }
    
    var description: String {
        switch self {
        case .light: return "睡前简单思考一下主题"
        case .moderate: return "花 5-10 分钟专注思考意图"
        case .strong: return "进行 15-20 分钟的深度冥想"
        case .intense: return "完整的孵化仪式，包括冥想和可视化"
        }
    }
    
    var recommendedDuration: Int {
        switch self {
        case .light: return 2       // 分钟
        case .moderate: return 10
        case .strong: return 20
        case .intense: return 30
        }
    }
}

// MARK: - 梦境孵化记录

/// 梦境孵化记录模型
@Model
final class DreamIncubation {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var targetDate: Date           // 目标日期 (通常是今晚)
    var targetType: IncubationTargetType
    var title: String              // 孵化标题
    var description: String        // 详细描述
    var intention: String          // 具体意图陈述
    var intensity: IncubationIntensity
    var completed: Bool            // 是否完成睡前仪式
    var completedAt: Date?         // 完成时间
    var relatedDreamIds: [UUID]    // 相关的梦境 ID
    var successRating: Int?        // 成功评级 (1-5)
    var notes: String              // 备注和观察
    var tags: [String]             // 标签
    var meditationMinutes: Int     // 冥想时长 (分钟)
    var visualizationUsed: Bool    // 是否使用可视化
    var affirmations: [String]     // 肯定语列表
    var success: Bool?             // 是否成功 (基于相关梦境)
    
    init(
        id: UUID = UUID(),
        targetDate: Date = Date(),
        targetType: IncubationTargetType,
        title: String,
        description: String = "",
        intention: String,
        intensity: IncubationIntensity = .moderate,
        completed: Bool = false,
        notes: String = "",
        tags: [String] = [],
        meditationMinutes: Int = 0,
        visualizationUsed: Bool = false,
        affirmations: [String] = []
    ) {
        self.id = id
        self.createdAt = Date()
        self.targetDate = targetDate
        self.targetType = targetType
        self.title = title
        self.description = description
        self.intention = intention
        self.intensity = intensity
        self.completed = completed
        self.notes = notes
        self.tags = tags
        self.meditationMinutes = meditationMinutes
        self.visualizationUsed = visualizationUsed
        self.affirmations = affirmations
        self.relatedDreamIds = []
    }
}

// MARK: - 孵化模板

/// 预设的孵化模板
struct IncubationTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let targetType: IncubationTargetType
    let defaultIntention: String
    let suggestedAffirmations: [String]
    let recommendedIntensity: IncubationIntensity
    let guidance: String
    
    static let templates: [IncubationTemplate] = [
        IncubationTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "问题解决",
            targetType: .problemSolving,
            defaultIntention: "今晚我将在梦中探索 [问题] 的解决方案",
            suggestedAffirmations: [
                "我的潜意识拥有答案",
                "我会在梦中获得清晰的洞察",
                "我信任我的内在智慧"
            ],
            recommendedIntensity: .moderate,
            guidance: "睡前花 10 分钟思考你的问题，想象在梦中获得答案的场景。"
        ),
        IncubationTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "创意灵感",
            targetType: .creativity,
            defaultIntention: "今晚我将在梦中获得关于 [创作项目] 的灵感",
            suggestedAffirmations: [
                "创意能量在我体内流动",
                "我的梦境充满创意的启示",
                "我醒来时会记住这些灵感"
            ],
            recommendedIntensity: .moderate,
            guidance: "想象你的创作项目已经完成，感受那种成就感。"
        ),
        IncubationTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "清醒梦诱导",
            targetType: .skillPractice,
            defaultIntention: "今晚我会意识到自己在做梦",
            suggestedAffirmations: [
                "我会记得我做梦了",
                "我会认出梦境的迹象",
                "我会保持清醒的意识"
            ],
            recommendedIntensity: .strong,
            guidance: "进行现实检查，回顾过去的梦境，设定清晰的意图。"
        ),
        IncubationTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "情绪疗愈",
            targetType: .emotionalHealing,
            defaultIntention: "今晚我将在梦中处理 [情绪/情况]，获得平静",
            suggestedAffirmations: [
                "我释放所有的恐惧和担忧",
                "我的内心充满平静和爱",
                "我在梦中得到疗愈"
            ],
            recommendedIntensity: .strong,
            guidance: "创建一个安全的心理空间，允许情绪自然流动。"
        ),
        IncubationTemplate(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "飞行体验",
            targetType: .exploration,
            defaultIntention: "今晚我会在梦中飞翔，体验自由的感觉",
            suggestedAffirmations: [
                "我可以在梦中自由飞翔",
                "飞翔的感觉自然而轻松",
                "我享受飞行的每一刻"
            ],
            recommendedIntensity: .light,
            guidance: "想象自己轻盈地飘浮在空中，感受风的触感。"
        )
    ]
}

// MARK: - 孵化统计

/// 梦境孵化统计数据
struct IncubationStats: Codable {
    var totalIncubations: Int           // 总孵化次数
    var completedIncubations: Int       // 完成的孵化次数
    var successRate: Double             // 成功率
    var averageSuccessRating: Double    // 平均成功评级
    var mostSuccessfulType: IncubationTargetType?  // 最成功的类型
    var totalMeditationMinutes: Int     // 总冥想时长
    var currentStreak: Int              // 当前连续天数
    var longestStreak: Int              // 最长连续天数
    var incubationsByType: [IncubationTargetType: Int]  // 按类型统计
    var successByType: [IncubationTargetType: Double]   // 按类型成功率
    
    init() {
        self.totalIncubations = 0
        self.completedIncubations = 0
        self.successRate = 0.0
        self.averageSuccessRating = 0.0
        self.mostSuccessfulType = nil
        self.totalMeditationMinutes = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.incubationsByType = [:]
        self.successByType = [:]
    }
}

// MARK: - 孵化提醒配置

/// 孵化提醒配置
struct IncubationReminder: Codable, Identifiable {
    var id: UUID
    var isEnabled: Bool
    var reminderTime: DateComponents      // 提醒时间
    var preSleepMinutes: Int              // 睡前多少分钟提醒
    var soundEnabled: Bool                // 声音提醒
    var vibrationEnabled: Bool            // 震动提醒
    var customMessage: String?            // 自定义消息
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        reminderTime: DateComponents = DateComponents(hour: 21, minute: 30),
        preSleepMinutes: Int = 30,
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true,
        customMessage: String? = nil
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.preSleepMinutes = preSleepMinutes
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
        self.customMessage = customMessage
    }
}
