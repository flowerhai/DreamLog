//
//  DreamArchetypeModels.swift
//  DreamLog
//
//  Phase 91: AI 梦境解读增强 - 荣格原型模型 🧠✨
//  创建时间：2026-03-22
//

import Foundation
import SwiftData

// MARK: - 荣格 12 原型枚举

/// 荣格心理学 12 种经典原型
enum JungianArchetype: String, Codable, CaseIterable, Identifiable {
    // 自我导向原型
    case innocent = "innocent"           // 天真者
    case orphan = "orphan"               // 孤儿
    case hero = "hero"                   // 英雄
    case caregiver = "caregiver"         // 照顾者
    
    // 社会导向原型
    case explorer = "explorer"           // 探索者
    case rebel = "rebel"                 // 反叛者
    case lover = "lover"                 // 爱人
    case creator = "creator"             // 创造者
    
    // 精神导向原型
    case jester = "jester"               // 弄臣
    case sage = "sage"                   // 智者
    case magician = "magician"           // 魔法师
    case ruler = "ruler"                 // 统治者
    
    var id: String { rawValue }
    
    /// 原型中文名称
    var localizedName: String {
        switch self {
        case .innocent: return "天真者"
        case .orphan: return "孤儿"
        case .hero: return "英雄"
        case .caregiver: return "照顾者"
        case .explorer: return "探索者"
        case .rebel: return "反叛者"
        case .lover: return "爱人"
        case .creator: return "创造者"
        case .jester: return "弄臣"
        case .sage: return "智者"
        case .magician: return "魔法师"
        case .ruler: return "统治者"
        }
    }
    
    /// 原型图标
    var icon: String {
        switch self {
        case .innocent: return "star.fill"
        case .orphan: return "person.fill"
        case .hero: return "shield.fill"
        case .caregiver: return "heart.fill"
        case .explorer: return "compass.fill"
        case .rebel: return "flame.fill"
        case .lover: return "heart.circle.fill"
        case .creator: return "pencil.and.outline"
        case .jester: return "face.smiling"
        case .sage: return "book.fill"
        case .magician: return "wand.and.stars"
        case .ruler: return "crown.fill"
        }
    }
    
    /// 原型颜色
    var color: String {
        switch self {
        case .innocent: return "FFD700"  // 金色
        case .orphan: return "6B7280"    // 灰色
        case .hero: return "EF4444"      // 红色
        case .caregiver: return "10B981" // 绿色
        case .explorer: return "3B82F6"  // 蓝色
        case .rebel: return "8B5CF6"     // 紫色
        case .lover: return "EC4899"     // 粉色
        case .creator: return "F59E0B"   // 橙色
        case .jester: return "FBBF24"    // 琥珀色
        case .sage: return "6366F1"      // 靛蓝
        case .magician: return "A855F7"  // 紫罗兰
        case .ruler: return "7C3AED"     // 深紫
        }
    }
    
    /// 原型核心欲望
    var coreDesire: String {
        switch self {
        case .innocent: return "获得天堂/幸福"
        case .orphan: return "归属/连接"
        case .hero: return "证明自我价值"
        case .caregiver: return "保护他人"
        case .explorer: return "发现自我/自由"
        case .rebel: return "颠覆/革命"
        case .lover: return "亲密/连接"
        case .creator: return "创造永恒价值"
        case .jester: return "享受当下/快乐"
        case .sage: return "追求真理/智慧"
        case .magician: return "理解宇宙/转化"
        case .ruler: return "控制/领导"
        }
    }
    
    /// 原型恐惧
    var fear: String {
        switch self {
        case .innocent: return "被惩罚/做错事"
        case .orphan: return "被遗弃/孤立"
        case .hero: return "软弱/失败"
        case .caregiver: return "忘恩负义"
        case .explorer: return "被困/从众"
        case .rebel: return "被忽视/平庸"
        case .lover: return "孤独/不被爱"
        case .creator: return "平庸/缺乏想象力"
        case .jester: return "无聊/沉闷"
        case .sage: return "无知/被欺骗"
        case .magician: return "混乱/失控"
        case .ruler: return "混乱/失去控制"
        }
    }
    
    /// 典型梦境符号
    var dreamSymbols: [String] {
        switch self {
        case .innocent: return ["孩子", "天使", "光明", "花园", "白色", "纯真"]
        case .orphan: return ["迷路", "孤独", "寻找", "人群", "遗弃", "流浪"]
        case .hero: return ["战斗", "挑战", "胜利", "武器", "怪物", "拯救"]
        case .caregiver: return ["照顾", "医院", "孩子", "受伤", "保护", "奉献"]
        case .explorer: return ["旅行", "地图", "未知", "冒险", "边界", "发现"]
        case .rebel: return ["反抗", "破坏", "规则", "自由", "冲突", "突破"]
        case .lover: return ["亲密", "拥抱", "浪漫", "美丽", "连接", "激情"]
        case .creator: return ["艺术", "创作", "建造", "设计", "想象", "作品"]
        case .jester: return ["笑话", "游戏", "欢乐", "面具", "表演", "幽默"]
        case .sage: return ["书籍", "老师", "学习", "智慧", "冥想", "真理"]
        case .magician: return ["魔法", "变形", "神秘", "能量", "转化", "奇迹"]
        case .ruler: return ["王座", "权力", "命令", "王国", "责任", "领导"]
        }
    }
    
    /// 心理学解读模板
    var interpretation: String {
        switch self {
        case .innocent: return "你的梦境展现了内心对纯真和幸福的渴望。这可能反映了你希望回归简单、无忧无虑的状态，或者正在寻求新的开始。"
        case .orphan: return "梦境中的孤独感可能反映了你在现实生活中对归属感的渴望。这是探索自我认同和寻找真正归属的契机。"
        case .hero: return "你正在面对内心的挑战，准备证明自己的能力。这个原型鼓励你勇敢面对困难，但也要记得接受自己的局限。"
        case .caregiver: return "你的照顾者原型被激活，表明你关心他人的福祉。记得也要照顾好自己的需求，避免过度付出。"
        case .explorer: return "探索者原型显示你渴望发现和成长。你可能正站在人生新阶段的边缘，准备踏上未知的旅程。"
        case .rebel: return "反叛者原型的出现意味着你可能感到被束缚。这是重新评估规则、寻找真正自由的信号。"
        case .lover: return "爱人原型反映了对亲密和连接的深层渴望。这可能指向浪漫关系，也可能是与自我的和解。"
        case .creator: return "创造者原型被唤醒，表明你有强烈的表达和创造欲望。这是将想象力转化为现实的好时机。"
        case .jester: return "弄臣原型提醒你不要太严肃。生活中需要欢笑和轻松，这是平衡压力的重要方式。"
        case .sage: return "智者原型显示你正在寻求更深的理解和智慧。这是学习、反思和内在成长的时期。"
        case .magician: return "魔法师原型代表转化和改变的潜力。你拥有将困境转化为机遇的内在力量。"
        case .ruler: return "统治者原型反映了对掌控和领导的需求。这是承担责任、发挥影响力的时刻。"
        }
    }
}

// MARK: - 梦境原型出现模型

@Model
final class DreamArchetypeOccurrence {
    var id: UUID
    var dreamId: UUID
    var archetype: String  // JungianArchetype.rawValue
    var confidence: Double  // 0.0 - 1.0
    var symbols: [String]   // 触发此原型的符号
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        archetype: JungianArchetype,
        confidence: Double,
        symbols: [String],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dreamId = dreamId
        self.archetype = archetype.rawValue
        self.confidence = confidence
        self.symbols = symbols
        self.createdAt = createdAt
    }
}

// MARK: - 阴影面模型

/// 阴影面类型
enum ShadowType: String, Codable, CaseIterable {
    case repressed = "repressed"         // 被压抑的特质
    case denied = "denied"               // 否认的特质
    case projected = "projected"         // 投射到他人的特质
    case unacknowledged = "unacknowledged" // 未承认的潜力
    
    var localizedName: String {
        switch self {
        case .repressed: return "被压抑"
        case .denied: return "否认"
        case .projected: return "投射"
        case .unacknowledged: return "未承认"
        }
    }
}

@Model
final class DreamShadowAspect {
    var id: UUID
    var dreamId: UUID
    var shadowType: String  // ShadowType.rawValue
    var trait: String       // 阴影特质描述
    var triggerSymbols: [String]
    var integrationAdvice: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        shadowType: ShadowType,
        trait: String,
        triggerSymbols: [String],
        integrationAdvice: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dreamId = dreamId
        self.shadowType = shadowType.rawValue
        self.trait = trait
        self.triggerSymbols = triggerSymbols
        self.integrationAdvice = integrationAdvice
        self.createdAt = createdAt
    }
}

// MARK: - 原型模式模型

@Model
final class ArchetypePattern {
    var id: UUID
    var userId: String
    var archetype: String  // JungianArchetype.rawValue
    var frequency: Int
    var lastOccurrence: Date
    var trend: String  // "increasing", "decreasing", "stable"
    var associatedEmotions: [String]
    var associatedThemes: [String]
    
    init(
        id: UUID = UUID(),
        userId: String,
        archetype: JungianArchetype,
        frequency: Int = 1,
        lastOccurrence: Date = Date(),
        trend: String = "stable",
        associatedEmotions: [String] = [],
        associatedThemes: [String] = []
    ) {
        self.id = id
        self.userId = userId
        self.archetype = archetype.rawValue
        self.frequency = frequency
        self.lastOccurrence = lastOccurrence
        self.trend = trend
        self.associatedEmotions = associatedEmotions
        self.associatedThemes = associatedThemes
    }
}

// MARK: - 原型分析结果

struct ArchetypeAnalysisResult: Codable {
    let primaryArchetype: JungianArchetype
    let secondaryArchetypes: [JungianArchetype]
    let confidence: Double
    let detectedSymbols: [String]
    let interpretation: String
    let shadowAspects: [ShadowAnalysis]
    let integrationSuggestions: [String]
}

struct ShadowAnalysis: Codable {
    let shadowType: ShadowType
    let trait: String
    let confidence: Double
    let integrationAdvice: String
}

// MARK: - 原型统计

struct ArchetypeStats: Codable {
    let totalDreams: Int
    let archetypeDistribution: [String: Int]  // archetype -> count
    let dominantArchetype: JungianArchetype?
    let emergingArchetypes: [JungianArchetype]
    let shadowFrequency: Int
    let integrationProgress: Double  // 0.0 - 1.0
    
    var distributionPercentages: [String: Double] {
        guard totalDreams > 0 else { return [:] }
        return archetypeDistribution.mapValues { Double($0) / Double(totalDreams) * 100.0 }
    }
}
