//
//  DreamAIAnalysisModels.swift
//  DreamLog - Phase 28: AI 梦境解析增强与智能洞察 2.0
//
//  AI 梦境解析增强数据模型
//

import Foundation

// MARK: - 梦境解析深度

enum AnalysisDepth: String, Codable, CaseIterable {
    case surface      // 表层解析 - 基本符号和情绪
    case deep        // 深层解析 - 心理含义和关联
    case archetypal  // 原型层解析 - 荣格原型和集体潜意识
    
    var displayName: String {
        switch self {
        case .surface: return "📖 表层解析"
        case .deep: return "🧠 深层解析"
        case .archetypal: return "✨ 原型层解析"
        }
    }
    
    var description: String {
        switch self {
        case .surface:
            return "分析梦境中的基本符号、情绪和直接含义"
        case .deep:
            return "探索梦境背后的心理动机和潜意识信息"
        case .archetypal:
            return "解读荣格原型和集体潜意识的深层象征"
        }
    }
    
    var estimatedTime: String {
        switch self {
        case .surface: return "约 30 秒"
        case .deep: return "约 1-2 分钟"
        case .archetypal: return "约 2-3 分钟"
        }
    }
}

// MARK: - 梦境类型

enum DreamType: String, Codable, CaseIterable {
    case normal          // 普通梦境
    case lucid           // 清醒梦
    case recurring       // 重复梦境
    case nightmare       // 噩梦
    case prophetic       // 预知梦
    case inspirational   // 灵感梦
    case vivid           // 生动梦
    case fragmented      // 碎片梦
    case flying          // 飞行梦
    case falling         // 坠落梦
    case chasing         // 被追逐梦
    case examination     // 考试梦
    
    var displayName: String {
        switch self {
        case .normal: return "😐 普通梦境"
        case .lucid: return "🌟 清醒梦"
        case .recurring: return "🔄 重复梦境"
        case .nightmare: return "😱 噩梦"
        case .prophetic: return "🔮 预知梦"
        case .inspirational: return "💡 灵感梦"
        case .vivid: return "🎨 生动梦"
        case .fragmented: return "🧩 碎片梦"
        case .flying: return "🕊️ 飞行梦"
        case .falling: return "🪂 坠落梦"
        case .chasing: return "🏃 被追逐梦"
        case .examination: return "📝 考试梦"
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "😐"
        case .lucid: return "🌟"
        case .recurring: return "🔄"
        case .nightmare: return "😱"
        case .prophetic: return "🔮"
        case .inspirational: return "💡"
        case .vivid: return "🎨"
        case .fragmented: return "🧩"
        case .flying: return "🕊️"
        case .falling: return "🪂"
        case .chasing: return "🏃"
        case .examination: return "📝"
        }
    }
    
    var description: String {
        switch self {
        case .normal:
            return "日常生活场景的普通梦境，无特殊特征"
        case .lucid:
            return "意识到自己在做梦，可能控制梦境内容"
        case .recurring:
            return "反复出现的相似梦境，通常有未解决的心理议题"
        case .nightmare:
            return "引发恐惧、焦虑的噩梦，可能与压力相关"
        case .prophetic:
            return "似乎预示未来的梦境，细节清晰"
        case .inspirational:
            return "带来创意灵感或问题解决方案的梦境"
        case .vivid:
            return "异常清晰、生动的梦境，感觉真实"
        case .fragmented:
            return "不连贯、碎片化的梦境片段"
        case .flying:
            return "在空中飞行的梦境，象征自由或逃避"
        case .falling:
            return "从高处坠落的梦境，常与失控感相关"
        case .chasing:
            return "被追赶或追逐的梦境，反映逃避心理"
        case .examination:
            return "参加考试或测试的梦境，与焦虑相关"
        }
    }
    
    var commonCauses: [String] {
        switch self {
        case .normal:
            return ["日常经历", "近期事件", "随机神经活动"]
        case .lucid:
            return ["清醒梦训练", "高自我意识", "REM 睡眠增强"]
        case .recurring:
            return ["未解决的心理冲突", "持续的压力源", "重要生活议题"]
        case .nightmare:
            return ["压力和焦虑", "创伤经历", "睡眠障碍"]
        case .prophetic:
            return ["直觉敏锐", "潜意识信息处理", "巧合"]
        case .inspirational:
            return ["创造性思维", "问题沉浸", "潜意识整合"]
        case .vivid:
            return ["睡眠质量高", "情绪强烈", "某些药物影响"]
        case .fragmented:
            return ["睡眠中断", "压力过大", "酒精或药物"]
        case .flying:
            return ["渴望自由", "逃避现实", "控制感"]
        case .falling:
            return ["失控感", "不安全感", "生活变化"]
        case .chasing:
            return ["逃避问题", "恐惧面对", "压力源"]
        case .examination:
            return ["表现焦虑", "自我怀疑", "被评价恐惧"]
        }
    }
    
    var suggestions: [String] {
        switch self {
        case .normal:
            return ["保持梦境记录", "注意梦境模式", "探索梦境含义"]
        case .lucid:
            return ["练习现实检查", "尝试控制梦境", "记录清醒梦体验"]
        case .recurring:
            return ["识别共同主题", "探索潜在原因", "考虑专业咨询"]
        case .nightmare:
            return ["放松技巧", "改善睡眠环境", "处理压力源"]
        case .prophetic:
            return ["记录细节", "保持开放心态", "验证预言"]
        case .inspirational:
            return ["立即记录灵感", "付诸实践", "培养创造力"]
        case .vivid:
            return ["详细记录", "探索情绪", "分析象征"]
        case .fragmented:
            return ["改善睡眠质量", "减少干扰", "放松练习"]
        case .flying:
            return ["享受自由感", "探索控制感", "注意逃避倾向"]
        case .falling:
            return ["寻找安全感", "接受变化", "建立支持系统"]
        case .chasing:
            return ["面对恐惧", "解决问题", "寻求支持"]
        case .examination:
            return ["增强自信", "准备充分", "接受不完美"]
        }
    }
}

// MARK: - 荣格原型

enum JungianArchetype: String, Codable, CaseIterable {
    case self_         // 自性
    case shadow        // 阴影
    case anima         // 阿尼玛 (男性内心的女性面)
    case animus        // 阿尼姆斯 (女性内心的男性面)
    case persona       // 人格面具
    case wiseOldMan    // 智慧老人
    case greatMother   // 大地母亲
    case hero          // 英雄
    case trickster     // 捣蛋鬼
    case child         // 儿童
    
    var displayName: String {
        switch self {
        case .self_: return "⭕ 自性"
        case .shadow: return "🌑 阴影"
        case .anima: return "♀️ 阿尼玛"
        case .animus: return "♂️ 阿尼姆斯"
        case .persona: return "🎭 人格面具"
        case .wiseOldMan: return "🧙 智慧老人"
        case .greatMother: return "🌍 大地母亲"
        case .hero: return "🦸 英雄"
        case .trickster: return "🃏 捣蛋鬼"
        case .child: return "👶 儿童"
        }
    }
    
    var description: String {
        switch self {
        case .self_:
            return "完整的自我，意识和潜意识的统一，常以曼荼罗、珍宝等形象出现"
        case .shadow:
            return "被压抑的黑暗面，包含不愿承认的特质，常以敌人、怪物形象出现"
        case .anima:
            return "男性潜意识中的女性原型，代表情感、直觉和关系能力"
        case .animus:
            return "女性潜意识中的男性原型，代表理性、决断和行动力"
        case .persona:
            return "社会面具，我们在外界展现的形象，保护真实自我"
        case .wiseOldMan:
            return "智慧和指导的象征，常以导师、智者形象出现"
        case .greatMother:
            return "养育和毁灭的双重面向，代表自然、丰饶和转化"
        case .hero:
            return "勇气和成长的象征，踏上旅程克服困难"
        case .trickster:
            return "混乱和变革的使者，打破规则带来转变"
        case .child:
            return "新生、潜力和未来的象征，代表新的开始"
        }
    }
    
    var dreamSymbols: [String] {
        switch self {
        case .self_:
            return ["曼荼罗", "珍宝", "圆圈", "四方", "完整", "统一"]
        case .shadow:
            return ["敌人", "怪物", "黑暗", "追赶者", "陌生人", "罪犯"]
        case .anima:
            return ["神秘女子", "女神", "母亲", "姐妹", "女性向导"]
        case .animus:
            return ["神秘男子", "英雄", "父亲", "兄弟", "男性向导"]
        case .persona:
            return ["面具", "服装", "角色", "表演", "社交场合"]
        case .wiseOldMan:
            return ["老人", "智者", "导师", "巫师", "老师", "先知"]
        case .greatMother:
            return ["母亲", "大地", "海洋", "洞穴", "子宫", "丰饶"]
        case .hero:
            return ["战士", "冒险者", "拯救者", "屠龙者", "旅行者"]
        case .trickster:
            return ["小丑", "骗子", "变形者", "恶作剧者", "叛逆者"]
        case .child:
            return ["婴儿", "小孩", "新生儿", "学生", "学徒"]
        }
    }
}

// MARK: - 心理健康指标

struct MentalHealthMetrics: Codable {
    var stressLevel: Int           // 压力水平 1-10
    var anxietyIndex: Int          // 焦虑指数 1-10
    var moodScore: Int             // 情绪评分 1-10
    var sleepQualityScore: Int     // 睡眠质量评分 1-10
    var emotionalStability: Int    // 情绪稳定性 1-10
    var overallWellbeing: Int      // 整体健康评分 1-10
    
    var stressLevelDescription: String {
        switch stressLevel {
        case 1...3: return "😌 低压力"
        case 4...6: return "😐 中等压力"
        case 7...8: return "😟 较高压力"
        case 9...10: return "😰 高压力"
        default: return "未知"
        }
    }
    
    var anxietyIndexDescription: String {
        switch anxietyIndex {
        case 1...3: return "😌 放松"
        case 4...6: return "😐 轻度焦虑"
        case 7...8: return "😟 中度焦虑"
        case 9...10: return "😰 严重焦虑"
        default: return "未知"
        }
    }
    
    var overallWellbeingDescription: String {
        switch overallWellbeing {
        case 1...3: return "😔 需要关注"
        case 4...6: return "😐 一般"
        case 7...8: return "🙂 良好"
        case 9...10: return "🌟 优秀"
        default: return "未知"
        }
    }
    
    // 计算综合评分
    var compositeScore: Int {
        let scores = [stressLevel, anxietyIndex, moodScore, sleepQualityScore, emotionalStability, overallWellbeing]
        // 压力和焦虑需要反向计算（越低越好）
        let adjustedScores = [
            11 - stressLevel,
            11 - anxietyIndex,
            moodScore,
            sleepQualityScore,
            emotionalStability,
            overallWellbeing
        ]
        return adjustedScores.reduce(0, +) / adjustedScores.count
    }
    
    var compositeDescription: String {
        switch compositeScore {
        case 1...3: return "😔 需要立即关注"
        case 4...5: return "😟 需要改善"
        case 6...7: return "🙂 状态良好"
        case 8...9: return "🌟 状态优秀"
        case 10: return "🏆 最佳状态"
        default: return "未知"
        }
    }
}

// MARK: - 梦境解析结果

struct DreamAnalysisResult: Codable, Identifiable {
    let id: UUID
    let dreamId: UUID
    let analysisDate: Date
    
    // 解析内容
    var title: String
    var summary: String                // 简短总结
    var surfaceAnalysis: String        // 表层解析
    var deepAnalysis: String           // 深层解析
    var archetypalAnalysis: String     // 原型层解析
    
    // 分类和标签
    var dreamType: DreamType
    var identifiedArchetypes: [JungianArchetype]
    var keySymbols: [DreamSymbol]
    
    // 心理健康评估
    var mentalHealthMetrics: MentalHealthMetrics
    
    // 建议和洞察
    var insights: [DreamInsight]
    var suggestions: [DreamSuggestion]
    var warnings: [DreamWarning]
    
    // 元数据
    var confidence: Double             // 解析置信度 0-1
    var analysisDepth: AnalysisDepth
    var processingTimeMs: Int
    
    init(
        dreamId: UUID,
        title: String,
        summary: String,
        surfaceAnalysis: String,
        deepAnalysis: String,
        archetypalAnalysis: String,
        dreamType: DreamType,
        identifiedArchetypes: [JungianArchetype],
        keySymbols: [DreamSymbol],
        mentalHealthMetrics: MentalHealthMetrics,
        insights: [DreamInsight],
        suggestions: [DreamSuggestion],
        warnings: [DreamWarning],
        confidence: Double,
        analysisDepth: AnalysisDepth,
        processingTimeMs: Int
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.analysisDate = Date()
        self.title = title
        self.summary = summary
        self.surfaceAnalysis = surfaceAnalysis
        self.deepAnalysis = deepAnalysis
        self.archetypalAnalysis = archetypalAnalysis
        self.dreamType = dreamType
        self.identifiedArchetypes = identifiedArchetypes
        self.keySymbols = keySymbols
        self.mentalHealthMetrics = mentalHealthMetrics
        self.insights = insights
        self.suggestions = suggestions
        self.warnings = warnings
        self.confidence = confidence
        self.analysisDepth = analysisDepth
        self.processingTimeMs = processingTimeMs
    }
}

// MARK: - 梦境符号

struct DreamSymbol: Codable, Identifiable {
    let id: UUID
    var name: String                   // 符号名称
    var category: SymbolCategory       // 符号类别
    var meanings: [SymbolMeaning]      // 多种含义
    var culturalInterpretations: [CulturalInterpretation]  // 文化解读
    var relatedSymbols: [String]       // 相关符号
    var frequency: Int                 // 在用户梦境中出现频率
    
    init(
        name: String,
        category: SymbolCategory,
        meanings: [SymbolMeaning],
        culturalInterpretations: [CulturalInterpretation] = [],
        relatedSymbols: [String] = [],
        frequency: Int = 1
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.meanings = meanings
        self.culturalInterpretations = culturalInterpretations
        self.relatedSymbols = relatedSymbols
        self.frequency = frequency
    }
}

enum SymbolCategory: String, Codable, CaseIterable {
    case object       // 物体
    case animal       // 动物
    case person       // 人物
    case place        // 地点
    case action       // 动作
    case emotion      // 情绪
    case nature       // 自然
    case supernatural // 超自然
    case body         // 身体
    case food         // 食物
    
    var displayName: String {
        switch self {
        case .object: return "📦 物体"
        case .animal: return "🐾 动物"
        case .person: return "👤 人物"
        case .place: return "📍 地点"
        case .action: return "⚡ 动作"
        case .emotion: return "❤️ 情绪"
        case .nature: return "🌿 自然"
        case .supernatural: return "🔮 超自然"
        case .body: return "🦴 身体"
        case .food: return "🍎 食物"
        }
    }
}

struct SymbolMeaning: Codable {
    var interpretation: String         // 解读
    var context: String                // 适用情境
    var psychological: String          // 心理学解释
    var spiritual: String              // 灵性解释
    var positive: Bool                 // 是否为积极含义
}

struct CulturalInterpretation: Codable {
    var culture: String                // 文化名称
    var interpretation: String         // 文化解读
    var significance: String           // 重要性
}

// MARK: - 洞察和建议

struct DreamInsight: Codable, Identifiable {
    let id: UUID
    var type: InsightType
    var title: String
    var description: String
    var confidence: Double
    var evidence: [String]             // 支持证据
    
    init(type: InsightType, title: String, description: String, confidence: Double, evidence: [String]) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.confidence = confidence
        self.evidence = evidence
    }
}

enum InsightType: String, Codable, CaseIterable {
    case pattern       // 模式发现
    case trend         // 趋势分析
    case correlation   // 关联发现
    case anomaly       // 异常检测
    case achievement   // 成就认可
    case warning       // 预警提示
    case opportunity   // 成长机会
    
    var displayName: String {
        switch self {
        case .pattern: return "🔄 模式发现"
        case .trend: return "📈 趋势分析"
        case .correlation: return "🔗 关联发现"
        case .anomaly: return "⚠️ 异常检测"
        case .achievement: return "🏆 成就认可"
        case .warning: return "🚨 预警提示"
        case .opportunity: return "💡 成长机会"
        }
    }
    
    var icon: String {
        switch self {
        case .pattern: return "🔄"
        case .trend: return "📈"
        case .correlation: return "🔗"
        case .anomaly: return "⚠️"
        case .achievement: return "🏆"
        case .warning: return "🚨"
        case .opportunity: return "💡"
        }
    }
}

struct DreamSuggestion: Codable, Identifiable {
    let id: UUID
    var type: SuggestionType
    var title: String
    var description: String
    var actionItems: [String]          // 可执行项
    var priority: Priority             // 优先级
    
    init(type: SuggestionType, title: String, description: String, actionItems: [String], priority: Priority) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.actionItems = actionItems
        self.priority = priority
    }
}

enum SuggestionType: String, Codable, CaseIterable {
    case sleep        // 睡眠改善
    case stress       // 压力管理
    case creativity   // 创意提升
    case selfCare     // 自我关怀
    case professional // 专业帮助
    case journaling   // 记录建议
    case meditation   // 冥想练习
    
    var displayName: String {
        switch self {
        case .sleep: return "😴 睡眠改善"
        case .stress: return "😌 压力管理"
        case .creativity: return "🎨 创意提升"
        case .selfCare: return "💆 自我关怀"
        case .professional: return "👨‍⚕️ 专业帮助"
        case .journaling: return "📝 记录建议"
        case .meditation: return "🧘 冥想练习"
        }
    }
}

enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent
    
    var displayName: String {
        switch self {
        case .low: return "🟢 低"
        case .medium: return "🟡 中"
        case .high: return "🟠 高"
        case .urgent: return "🔴 紧急"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
}

struct DreamWarning: Codable, Identifiable {
    let id: UUID
    var type: WarningType
    var title: String
    var description: String
    var severity: Severity             // 严重程度
    var recommendedAction: String      // 建议行动
    
    init(type: WarningType, title: String, description: String, severity: Severity, recommendedAction: String) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.severity = severity
        self.recommendedAction = recommendedAction
    }
}

enum WarningType: String, Codable, CaseIterable {
    case recurringNightmare   // 反复噩梦
    case sleepDisturbance     // 睡眠障碍
    case highStress           // 高压力
    case anxietyIndicator     // 焦虑指标
    case traumaRelated        // 创伤相关
    case professionalHelp     // 建议专业帮助
    
    var displayName: String {
        switch self {
        case .recurringNightmare: return "😱 反复噩梦"
        case .sleepDisturbance: return "🌙 睡眠障碍"
        case .highStress: return "😰 高压力"
        case .anxietyIndicator: return "😟 焦虑指标"
        case .traumaRelated: return "💔 创伤相关"
        case .professionalHelp: return "👨‍⚕️ 建议专业帮助"
        }
    }
}

enum Severity: String, Codable, CaseIterable {
    case low
    case moderate
    case high
    case severe
    
    var displayName: String {
        switch self {
        case .low: return "🟢 轻微"
        case .moderate: return "🟡 中等"
        case .high: return "🟠 严重"
        case .severe: return "🔴 非常严重"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .severe: return "red"
        }
    }
}

// MARK: - 解析配置

struct AnalysisConfig: Codable {
    var depth: AnalysisDepth
    var includeArchetypes: Bool
    var includeMentalHealth: Bool
    var includeSuggestions: Bool
    var includeWarnings: Bool
    var culturalContext: String
    var language: String
    
    static var `default`: AnalysisConfig {
        AnalysisConfig(
            depth: .deep,
            includeArchetypes: true,
            includeMentalHealth: true,
            includeSuggestions: true,
            includeWarnings: true,
            culturalContext: "chinese",
            language: "zh-CN"
        )
    }
}
