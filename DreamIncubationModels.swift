//
//  DreamIncubationModels.swift
//  DreamLog
//
//  梦境孵育功能数据模型
//  支持设置睡前意图，引导特定主题的梦境
//

import Foundation
import SwiftData

// MARK: - 孵育类型

/// 梦境孵育类型
enum IncubationType: String, CaseIterable, Identifiable, Codable {
    case problemSolving = "问题解答"
    case creative = "创意启发"
    case healing = "情感疗愈"
    case skill = "技能练习"
    case exploration = "主题探索"
    case lucid = "清醒梦诱导"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .problemSolving: return "questionmark.circle.fill"
        case .creative: return "lightbulb.fill"
        case .healing: return "heart.fill"
        case .skill: return "star.fill"
        case .exploration: return "compass.fill"
        case .lucid: return "eye.fill"
        }
    }
    
    var color: String {
        switch self {
        case .problemSolving: return "FF9500"
        case .creative: return "FFD60A"
        case .healing: return "FF375F"
        case .skill: return "0A84FF"
        case .exploration: return "30D158"
        case .lucid: return "BF5AF2"
        }
    }
    
    var description: String {
        switch self {
        case .problemSolving: return "带着问题入睡，寻求梦境启示"
        case .creative: return "激发创意灵感，获取艺术启发"
        case .healing: return "处理情感创伤，获得内心平静"
        case .skill: return "在梦中练习技能，提升表现"
        case .exploration: return "探索特定主题，扩展认知"
        case .lucid: return "诱导清醒梦境，增强意识"
        }
    }
    
    var suggestedAffirmations: [String] {
        switch self {
        case .problemSolving:
            return [
                "今晚我会在梦中找到答案",
                "我的潜意识知道解决方案",
                "梦境会给我清晰的指引"
            ]
        case .creative:
            return [
                "今晚我会获得创意灵感",
                "我的梦境充满创意和想象",
                "我会梦到美妙的创意"
            ]
        case .healing:
            return [
                "今晚我会获得内心的平静",
                "我的梦境会帮助我疗愈",
                "我在梦中感到安全和被爱"
            ]
        case .skill:
            return [
                "今晚我会在梦中练习技能",
                "我的梦境会帮助我提升",
                "我在梦中表现得很好"
            ]
        case .exploration:
            return [
                "今晚我会探索新的领域",
                "我的梦境会带我到有趣的地方",
                "我会梦到有意义的场景"
            ]
        case .lucid:
            return [
                "今晚会做清醒梦",
                "我会意识到自己在做梦",
                "我在梦中保持清醒意识"
            ]
        }
    }
}

// MARK: - 孵育强度

/// 孵育强度等级
enum IncubationIntensity: String, CaseIterable, Identifiable, Codable {
    case light = "轻度"
    case moderate = "中度"
    case strong = "强度"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .light: return "轻松暗示，自然引导"
        case .moderate: return "明确意图，专注聚焦"
        case .strong: return "强烈暗示，深度沉浸"
        }
    }
    
    var recommendedDuration: Int {
        switch self {
        case .light: return 5 // 分钟
        case .moderate: return 10
        case .strong: return 15
        }
    }
}

// MARK: - 孵育会话模型

/// 梦境孵育会话
@Model
final class DreamIncubationSession {
    var id: UUID
    var type: String // IncubationType.rawValue
    var title: String
    var description: String
    var intention: String // 用户的意图陈述
    var affirmations: [String] // 使用的肯定语
    var intensity: String // IncubationIntensity.rawValue
    var duration: Int // 分钟
    var scheduledDate: Date
    var completedDate: Date?
    var status: String // pending, active, completed, cancelled
    var relatedDreamIds: [UUID] // 关联的梦境 ID
    var successRating: Int? // 1-5 评分
    var notes: String? // 用户备注
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        type: IncubationType,
        title: String,
        description: String = "",
        intention: String,
        affirmations: [String] = [],
        intensity: IncubationIntensity = .moderate,
        duration: Int = 10,
        scheduledDate: Date = Date(),
        completedDate: Date? = nil,
        status: String = "pending",
        relatedDreamIds: [UUID] = [],
        successRating: Int? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type.rawValue
        self.title = title
        self.description = description
        self.intention = intention
        self.affirmations = affirmations
        self.intensity = intensity.rawValue
        self.duration = duration
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.status = status
        self.relatedDreamIds = relatedDreamIds
        self.successRating = successRating
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var incubationType: IncubationType {
        IncubationType(rawValue: type) ?? .creative
    }
    
    var incubationIntensity: IncubationIntensity {
        IncubationIntensity(rawValue: intensity) ?? .moderate
    }
    
    var isCompleted: Bool {
        status == "completed"
    }
    
    var isActive: Bool {
        status == "active"
    }
}

// MARK: - 孵育模板

/// 梦境孵育模板
struct IncubationTemplate: Identifiable, Codable {
    let id: UUID
    let type: IncubationType
    let name: String
    let description: String
    let defaultIntention: String
    let suggestedAffirmations: [String]
    let recommendedIntensity: IncubationIntensity
    let preSleepRitual: [String] // 睡前仪式步骤
    let morningReflection: [String] // 晨间反思问题
    
    static let templates: [IncubationTemplate] = [
        IncubationTemplate(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            type: .problemSolving,
            name: "问题解答孵育",
            description: "带着具体问题入睡，寻求梦境的智慧和启示",
            defaultIntention: "我会在梦中找到这个问题的答案",
            suggestedAffirmations: [
                "我的潜意识知道答案",
                "梦境会给我清晰的指引",
                "我信任内在的智慧"
            ],
            recommendedIntensity: .moderate,
            preSleepRitual: [
                "写下你的问题，越具体越好",
                "深呼吸 5 次，放松身心",
                "默念意图 3 遍",
                "想象问题已经解决的场景",
                "带着信任入睡"
            ],
            morningReflection: [
                "你记得梦到什么？",
                "梦中有任何线索或象征吗？",
                "醒来时的第一感觉是什么？",
                "有什么新的想法或洞察？"
            ]
        ),
        IncubationTemplate(
            id: UUID(uuidString: "B2C3D4E5-F6A7-8901-BCDE-F12345678901")!,
            type: .creative,
            name: "创意灵感孵育",
            description: "激发创意潜能，获取艺术、写作或项目的灵感",
            defaultIntention: "我会在梦中获得创意灵感",
            suggestedAffirmations: [
                "我的创意源源不断",
                "梦境充满创意和想象",
                "我是有创造力的人"
            ],
            recommendedIntensity: .light,
            preSleepRitual: [
                "回顾你正在创作的項目",
                "想象创意 flowing 的感觉",
                "感谢你的创造力",
                "默念意图 3 遍",
                "放松入睡"
            ],
            morningReflection: [
                "梦中有何创意元素？",
                "有什么新的想法或视角？",
                "颜色、形状、声音有什么特别？",
                "如何将梦中灵感应用到现实？"
            ]
        ),
        IncubationTemplate(
            id: UUID(uuidString: "C3D4E5F6-A7B8-9012-CDEF-123456789012")!,
            type: .healing,
            name: "情感疗愈孵育",
            description: "处理情感创伤，获得内心平静和疗愈",
            defaultIntention: "我会在梦中获得疗愈和平静",
            suggestedAffirmations: [
                "我值得被爱和疗愈",
                "我的梦境是安全的空间",
                "我正在释放和疗愈"
            ],
            recommendedIntensity: .light,
            preSleepRitual: [
                "找一个舒适的姿势",
                "深呼吸，感受身体",
                "想象被温暖的光包围",
                "对自己说温柔的话",
                "带着爱入睡"
            ],
            morningReflection: [
                "醒来时感觉如何？",
                "梦中有何疗愈元素？",
                "有什么情绪被释放？",
                "今天如何照顾自己？"
            ]
        ),
        IncubationTemplate(
            id: UUID(uuidString: "D4E5F6A7-B8C9-0123-DEF0-234567890123")!,
            type: .skill,
            name: "技能练习孵育",
            description: "在梦中练习技能，提升现实表现",
            defaultIntention: "我会在梦中练习并提升这项技能",
            suggestedAffirmations: [
                "我在梦中表现得很好",
                "我的技能在不断提升",
                "梦境是我的练习场"
            ],
            recommendedIntensity: .strong,
            preSleepRitual: [
                "回顾技能的要点",
                "想象完美执行的感觉",
                "感受成功的喜悦",
                "默念意图 5 遍",
                "自信入睡"
            ],
            morningReflection: [
                "梦中练习了什么？",
                "感觉如何？",
                "有什么新的领悟？",
                "今天如何在现实中练习？"
            ]
        ),
        IncubationTemplate(
            id: UUID(uuidString: "E5F6A7B8-C9D0-1234-EF01-345678901234")!,
            type: .exploration,
            name: "主题探索孵育",
            description: "探索特定主题、地点或概念",
            defaultIntention: "我会在梦中探索这个主题",
            suggestedAffirmations: [
                "我的梦境充满探索的乐趣",
                "我会梦到有趣的地方",
                "我的意识在扩展"
            ],
            recommendedIntensity: .moderate,
            preSleepRitual: [
                "了解你想探索的主题",
                "想象那个场景的样子",
                "保持开放和好奇",
                "默念意图 3 遍",
                "期待入睡"
            ],
            morningReflection: [
                "你探索了什么？",
                "有什么新发现？",
                "感觉如何？",
                "想继续探索什么？"
            ]
        ),
        IncubationTemplate(
            id: UUID(uuidString: "F6A7B8C9-D0E1-2345-F012-456789012345")!,
            type: .lucid,
            name: "清醒梦诱导孵育",
            description: "诱导清醒梦境，增强梦中意识",
            defaultIntention: "今晚我会做清醒梦",
            suggestedAffirmations: [
                "我会意识到自己在做梦",
                "我在梦中保持清醒",
                "清醒梦对我来说很自然"
            ],
            recommendedIntensity: .strong,
            preSleepRitual: [
                "回顾现实检查技巧",
                "想象意识到自己在做梦的场景",
                "感受清醒梦的兴奋",
                "默念意图 5 遍",
                "保持觉知入睡"
            ],
            morningReflection: [
                "有做清醒梦吗？",
                "何时意识到在做梦？",
                "在梦中做了什么？",
                "下次如何做得更好？"
            ]
        )
    ]
}

// MARK: - 孵育统计

/// 梦境孵育统计数据
struct IncubationStats {
    let totalSessions: Int
    let completedSessions: Int
    let pendingSessions: Int
    let averageSuccessRating: Double
    let sessionsByType: [String: Int]
    let successRate: Double // 评分>=4 的比例
    let streakDays: Int // 连续孵育天数
    
    init(
        totalSessions: Int = 0,
        completedSessions: Int = 0,
        pendingSessions: Int = 0,
        averageSuccessRating: Double = 0,
        sessionsByType: [String: Int] = [:],
        successRate: Double = 0,
        streakDays: Int = 0
    ) {
        self.totalSessions = totalSessions
        self.completedSessions = completedSessions
        self.pendingSessions = pendingSessions
        self.averageSuccessRating = averageSuccessRating
        self.sessionsByType = sessionsByType
        self.successRate = successRate
        self.streakDays = streakDays
    }
}

// MARK: - 孵育提醒配置

/// 孵育提醒配置
struct IncubationReminder: Codable, Identifiable {
    var id: UUID
    var isEnabled: Bool
    var reminderTime: Date // 每天提醒时间
    var preSleepMinutes: Int // 睡前多少分钟提醒
    var message: String
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = false,
        reminderTime: Date = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date(),
        preSleepMinutes: Int = 30,
        message: String = "睡前孵育时间到了"
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.reminderTime = reminderTime
        self.preSleepMinutes = preSleepMinutes
        self.message = message
    }
}
