//
//  DreamSmartSuggestionsService.swift
//  DreamLog - Phase 85: 梦境智能建议与个性化推荐系统
//
//  创建时间：2026-03-22
//  功能：智能建议核心服务
//

import Foundation
import SwiftData

// MARK: - 智能建议服务

@ModelActor
final class DreamSmartSuggestionsService {
    
    // MARK: - 属性
    
    private let modelContext: ModelContext
    private var config: SuggestionConfig {
        didSet { saveConfig() }
    }
    
    // MARK: - 建议模板库
    
    private let suggestionTemplates: [SuggestionTemplate] = [
        // 梦境改善类
        SuggestionTemplate(
            type: .dreamImprovement,
            titleTemplate: "提升梦境清晰度：{technique}",
            descriptionTemplate: "基于您最近的梦境记录，尝试 {technique} 可以帮助您获得更清晰的梦境体验。",
            actionTemplates: [
                "睡前花 5 分钟练习 {technique}",
                "在床边准备梦境日记本",
                "醒来后立即记录梦境细节",
                "持续练习 7 天观察效果"
            ],
            benefitTemplate: "提高梦境清晰度和回忆质量，增强梦境体验",
            timeCommitment: "每日 5-10 分钟",
            difficultyLevel: 2,
            applicablePatterns: ["模糊梦境", "回忆困难", "碎片化梦境"]
        ),
        
        SuggestionTemplate(
            type: .lucidDreaming,
            titleTemplate: "清醒梦入门：{technique} 练习",
            descriptionTemplate: "您已经具备了良好的梦境回忆能力，现在是尝试清醒梦的好时机。{technique} 是最适合初学者的方法。",
            actionTemplates: [
                "白天进行 5 次现实检查",
                "睡前重复意图：'我会知道自己在做梦'",
                "使用 {technique} 技巧入睡",
                "记录任何清醒梦体验"
            ],
            benefitTemplate: "体验掌控梦境的能力，探索无限可能",
            timeCommitment: "每日 10-15 分钟",
            difficultyLevel: 3,
            applicablePatterns: ["高梦境回忆", "规律睡眠", "对清醒梦感兴趣"]
        ),
        
        SuggestionTemplate(
            type: .dreamRecall,
            titleTemplate: "增强梦境回忆：{method}",
            descriptionTemplate: "提高梦境回忆能力是深入梦境探索的基础。{method} 被证明非常有效。",
            actionTemplates: [
                "设置固定起床时间",
                "醒来后保持姿势不变，回忆梦境",
                "使用 {method} 记录梦境",
                "睡前暗示自己会记住梦境"
            ],
            benefitTemplate: "显著提高梦境回忆数量和细节",
            timeCommitment: "每日 5 分钟",
            difficultyLevel: 1,
            applicablePatterns: ["低回忆率", "忘记梦境", "想要更多记录"]
        ),
        
        // 睡眠健康类
        SuggestionTemplate(
            type: .sleepQuality,
            titleTemplate: "改善睡眠质量：{tip}",
            descriptionTemplate: "优质的睡眠是精彩梦境的基础。{tip} 可以帮助您获得更好的睡眠。",
            actionTemplates: [
                "保持卧室温度在 18-22°C",
                "睡前 1 小时避免蓝光",
                "实践 {tip}",
                "建立固定的睡前仪式"
            ],
            benefitTemplate: "提升睡眠质量，增加 REM 睡眠时间",
            timeCommitment: "每日调整",
            difficultyLevel: 2,
            applicablePatterns: ["睡眠质量低", "睡眠中断", "疲劳感"]
        ),
        
        SuggestionTemplate(
            type: .sleepSchedule,
            titleTemplate: "优化作息时间：{schedule}",
            descriptionTemplate: "规律的作息可以显著改善梦境质量。建议尝试 {schedule}。",
            actionTemplates: [
                "固定每天起床时间",
                "逐步调整入睡时间",
                "避免周末补觉",
                "使用闹钟提醒睡前准备"
            ],
            benefitTemplate: "建立稳定的生物钟，提高梦境规律性",
            timeCommitment: "2 周适应期",
            difficultyLevel: 3,
            applicablePatterns: ["作息不规律", "晚睡", "起床困难"]
        ),
        
        SuggestionTemplate(
            type: .relaxationTechnique,
            titleTemplate: "睡前放松：{technique}",
            descriptionTemplate: "放松身心有助于更快入睡和更好的梦境。{technique} 是有效的放松方法。",
            actionTemplates: [
                "睡前 30 分钟开始放松",
                "练习 {technique} 10 分钟",
                "专注于呼吸和身体感受",
                "创造安静的睡眠环境"
            ],
            benefitTemplate: "减少入睡时间，提升睡眠深度",
            timeCommitment: "每晚 10-15 分钟",
            difficultyLevel: 1,
            applicablePatterns: ["入睡困难", "压力高", "思绪活跃"]
        ),
        
        // 心理健康类
        SuggestionTemplate(
            type: .stressManagement,
            titleTemplate: "管理压力：{method}",
            descriptionTemplate: "压力会影响梦境质量。{method} 可以帮助您更好地管理日常压力。",
            actionTemplates: [
                "识别压力源",
                "每天练习 {method}",
                "安排放松时间",
                "与朋友或专业人士交流"
            ],
            benefitTemplate: "降低压力水平，改善梦境情绪",
            timeCommitment: "每日 10-20 分钟",
            difficultyLevel: 2,
            applicablePatterns: ["高压力", "焦虑梦境", "紧张情绪"]
        ),
        
        SuggestionTemplate(
            type: .moodImprovement,
            titleTemplate: "提升情绪：{activity}",
            descriptionTemplate: "积极的情绪会带来更美好的梦境体验。尝试 {activity} 来改善心情。",
            actionTemplates: [
                "每天记录 3 件感恩的事",
                "进行 {activity}",
                "与积极的人交流",
                "练习积极的自我对话"
            ],
            benefitTemplate: "改善整体情绪状态，增加积极梦境",
            timeCommitment: "每日 15 分钟",
            difficultyLevel: 1,
            applicablePatterns: ["负面情绪", "消极梦境", "情绪波动"]
        ),
        
        SuggestionTemplate(
            type: .mindfulness,
            titleTemplate: "正念练习：{practice}",
            descriptionTemplate: "正念可以提高自我觉察，对梦境探索很有帮助。{practice} 是很好的开始。",
            actionTemplates: [
                "每天固定时间练习 {practice}",
                "专注于当下感受",
                "不加评判地观察思绪",
                "逐渐延长练习时间"
            ],
            benefitTemplate: "增强自我觉察，提升梦境意识",
            timeCommitment: "每日 10-20 分钟",
            difficultyLevel: 2,
            applicablePatterns: ["注意力分散", "想要自我提升", "对冥想感兴趣"]
        ),
        
        // 创意灵感类
        SuggestionTemplate(
            type: .creativeInspiration,
            titleTemplate: "激发创意：{exercise}",
            descriptionTemplate: "梦境是创意的宝库。通过 {exercise} 可以更好地利用梦境中的创意。",
            actionTemplates: [
                "记录梦境中的创意元素",
                "练习 {exercise}",
                "将梦境灵感应用到项目中",
                "与其他创作者交流"
            ],
            benefitTemplate: "从梦境中获取创意灵感，提升创造力",
            timeCommitment: "每周 2-3 次",
            difficultyLevel: 2,
            applicablePatterns: ["创意工作者", "寻求灵感", "有创意梦境"]
        ),
        
        SuggestionTemplate(
            type: .writingPrompt,
            titleTemplate: "梦境写作：{prompt}",
            descriptionTemplate: "将梦境转化为文字是很好的表达方式。试试这个写作提示：{prompt}",
            actionTemplates: [
                "选择一个印象深刻的梦境",
                "根据提示开始写作",
                "不要担心语法，自由表达",
                "完成后回顾并反思"
            ],
            benefitTemplate: "深化梦境理解，提升表达能力",
            timeCommitment: "每次 20-30 分钟",
            difficultyLevel: 2,
            applicablePatterns: ["喜欢写作", "有生动梦境", "想要表达"]
        ),
        
        // 分析洞察类
        SuggestionTemplate(
            type: .patternInsight,
            titleTemplate: "发现模式：{pattern}",
            descriptionTemplate: "我们注意到您的梦境中出现了 '{pattern}' 的模式，这可能反映了 {insight}。",
            actionTemplates: [
                "回顾相关梦境记录",
                "思考模式与生活的联系",
                "记录新的观察",
                "探索模式背后的意义"
            ],
            benefitTemplate: "更深入理解自己的潜意识和行为模式",
            timeCommitment: "30 分钟反思",
            difficultyLevel: 3,
            applicablePatterns: ["重复主题", " recurring 符号", "模式明显"]
        ),
        
        SuggestionTemplate(
            type: .symbolExploration,
            titleTemplate: "探索符号：{symbol}",
            descriptionTemplate: "'{symbol}' 在您的梦境中频繁出现。这个符号通常代表 {meaning}。",
            actionTemplates: [
                "查看符号词典解释",
                "反思符号与个人经历的关联",
                "记录出现该符号的梦境",
                "探索符号的多重含义"
            ],
            benefitTemplate: "理解梦境符号的个人意义",
            timeCommitment: "20-30 分钟",
            difficultyLevel: 2,
            applicablePatterns: ["重复符号", "好奇符号含义", "想要深入理解"]
        )
    ]
    
    // MARK: - 初始化
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.config = SuggestionConfig()
        loadConfig()
    }
    
    // MARK: - 配置管理
    
    func loadConfig() {
        let descriptor = FetchDescriptor<SuggestionConfig>()
        if let configs = try? modelContext.fetch(descriptor), let firstConfig = configs.first {
            self.config = firstConfig
        }
    }
    
    func saveConfig() {
        let descriptor = FetchDescriptor<SuggestionConfig>()
        if let configs = try? modelContext.fetch(descriptor), !configs.isEmpty {
            configs.first?.enabledTypes = config.enabledTypes
            configs.first?.minPriority = config.minPriority
            configs.first?.dailyLimit = config.dailyLimit
            configs.first?.showNotifications = config.showNotifications
            configs.first?.notificationTime = config.notificationTime
            configs.first?.autoGenerateOnPattern = config.autoGenerateOnPattern
            configs.first?.includeEducational = config.includeEducational
            configs.first?.language = config.language
        } else {
            modelContext.insert(config)
        }
        
        try? modelContext.save()
    }
    
    func updateConfig(_ updates: (inout SuggestionConfig) -> Void) {
        updates(&config)
        saveConfig()
    }
    
    // MARK: - 建议生成
    
    /// 根据上下文生成智能建议
    func generateSuggestions(context: SuggestionContext) -> [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // 根据模式生成建议
        for pattern in context.dreamPatterns {
            if let template = findTemplateForPattern(pattern) {
                let suggestion = template.generate(
                    variables: ["pattern": pattern, "technique": "MILD", "method": "梦境日记", "tip": "4-7-8 呼吸法", "schedule": "23:00-7:00"],
                    basedOnPatterns: [pattern]
                )
                if shouldAddSuggestion(suggestion, to: &suggestions, config: context.config) {
                    suggestions.append(suggestion)
                }
            }
        }
        
        // 根据睡眠质量生成建议
        if context.sleepQuality < 0.6 {
            let template = suggestionTemplates.first { $0.type == .sleepQuality }
            if let template = template {
                let suggestion = template.generate(
                    variables: ["tip": "渐进性肌肉放松"],
                    basedOnPatterns: ["睡眠质量低"]
                )
                suggestion.priority = SuggestionPriority.high.rawValue
                if shouldAddSuggestion(suggestion, to: &suggestions, config: context.config) {
                    suggestions.append(suggestion)
                }
            }
        }
        
        // 根据压力水平生成建议
        if context.stressLevel > 0.7 {
            let template = suggestionTemplates.first { $0.type == .stressManagement }
            if let template = template {
                let suggestion = template.generate(
                    variables: ["method": "正念冥想"],
                    basedOnPatterns: ["高压力"]
                )
                suggestion.priority = SuggestionPriority.high.rawValue
                if shouldAddSuggestion(suggestion, to: &suggestions, config: context.config) {
                    suggestions.append(suggestion)
                }
            }
        }
        
        // 根据梦境回忆率生成建议
        if context.dreamRecallRate < 0.5 {
            let template = suggestionTemplates.first { $0.type == .dreamRecall }
            if let template = template {
                let suggestion = template.generate(
                    variables: ["method": "醒来后立即记录"],
                    basedOnPatterns: ["低回忆率"]
                )
                if shouldAddSuggestion(suggestion, to: &suggestions, config: context.config) {
                    suggestions.append(suggestion)
                }
            }
        }
        
        // 根据清醒梦频率生成建议
        if context.lucidDreamFrequency < 0.1 && context.dreamRecallRate > 0.7 {
            let template = suggestionTemplates.first { $0.type == .lucidDreaming }
            if let template = template {
                let suggestion = template.generate(
                    variables: ["technique": "现实检查"],
                    basedOnPatterns: ["高回忆率", "准备尝试清醒梦"]
                )
                if shouldAddSuggestion(suggestion, to: &suggestions, config: context.config) {
                    suggestions.append(suggestion)
                }
            }
        }
        
        // 根据常见符号生成建议
        for symbol in context.commonSymbols.prefix(2) {
            let template = suggestionTemplates.first { $0.type == .symbolExploration }
            if let template = template {
                let suggestion = template.generate(
                    variables: ["symbol": symbol, "meaning": "潜意识的表达"],
                    basedOnPatterns: ["重复符号：\(symbol)"]
                )
                if shouldAddSuggestion(suggestion, to: &suggestions, config: context.config) {
                    suggestions.append(suggestion)
                }
            }
        }
        
        // 限制每日建议数量
        let limitedSuggestions = Array(suggestions.prefix(context.config.dailyLimit))
        
        return limitedSuggestions
    }
    
    private func findTemplateForPattern(_ pattern: String) -> SuggestionTemplate? {
        // 简单的模式匹配逻辑
        let patternLower = pattern.lowercased()
        
        if patternLower.contains("模糊") || patternLower.contains("碎片") {
            return suggestionTemplates.first { $0.type == .dreamImprovement }
        } else if patternLower.contains("回忆") || patternLower.contains("忘记") {
            return suggestionTemplates.first { $0.type == .dreamRecall }
        } else if patternLower.contains("清醒") || patternLower.contains("lucid") {
            return suggestionTemplates.first { $0.type == .lucidDreaming }
        } else if patternLower.contains("睡眠") || patternLower.contains("累") {
            return suggestionTemplates.first { $0.type == .sleepQuality }
        } else if patternLower.contains("压力") || patternLower.contains("焦虑") {
            return suggestionTemplates.first { $0.type == .stressManagement }
        } else if patternLower.contains("情绪") || patternLower.contains("心情") {
            return suggestionTemplates.first { $0.type == .moodImprovement }
        } else if patternLower.contains("符号") || patternLower.contains("象征") {
            return suggestionTemplates.first { $0.type == .symbolExploration }
        } else if patternLower.contains("模式") || patternLower.contains("重复") {
            return suggestionTemplates.first { $0.type == .patternInsight }
        }
        
        return nil
    }
    
    private func shouldAddSuggestion(
        _ suggestion: SmartSuggestion,
        to existingSuggestions: inout [SmartSuggestion],
        config: SuggestionConfig
    ) -> Bool {
        // 检查类型是否启用
        guard config.isTypeEnabled(suggestion.typedType ?? .dreamImprovement) else {
            return false
        }
        
        // 检查优先级
        guard suggestion.priority >= config.minPriority else {
            return false
        }
        
        // 避免重复
        let isDuplicate = existingSuggestions.contains {
            $0.type == suggestion.type && $0.title == suggestion.title
        }
        
        return !isDuplicate
    }
    
    // MARK: - 建议管理
    
    /// 保存建议
    func saveSuggestion(_ suggestion: SmartSuggestion) {
        modelContext.insert(suggestion)
        try? modelContext.save()
    }
    
    /// 保存多个建议
    func saveSuggestions(_ suggestions: [SmartSuggestion]) {
        for suggestion in suggestions {
            modelContext.insert(suggestion)
        }
        try? modelContext.save()
    }
    
    /// 获取所有活跃建议
    func getActiveSuggestions() -> [SmartSuggestion] {
        let descriptor = FetchDescriptor<SmartSuggestion>(
            predicate: #Predicate {
                !$0.isDismissed && !$0.isCompleted && !$0.isExpired
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取建议 by 类型
    func getSuggestionsByType(_ type: SmartSuggestionType) -> [SmartSuggestion] {
        let descriptor = FetchDescriptor<SmartSuggestion>(
            predicate: #Predicate { $0.type == type.rawValue && !$0.isDismissed },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 标记建议为已完成
    func markSuggestionCompleted(_ suggestion: SmartSuggestion) {
        suggestion.isCompleted = true
        suggestion.completedAt = Date()
        try? modelContext.save()
    }
    
    /// 标记建议为已关闭
    func markSuggestionDismissed(_ suggestion: SmartSuggestion) {
        suggestion.isDismissed = true
        suggestion.dismissedAt = Date()
        try? modelContext.save()
    }
    
    /// 记录建议查看
    func recordSuggestionView(_ suggestion: SmartSuggestion) {
        suggestion.viewCount += 1
        try? modelContext.save()
    }
    
    /// 记录有用性评分
    func rateSuggestionHelpfulness(_ suggestion: SmartSuggestion, rating: Int) {
        suggestion.helpfulness = rating
        try? modelContext.save()
    }
    
    /// 删除过期建议
    func cleanupExpiredSuggestions() {
        let descriptor = FetchDescriptor<SmartSuggestion>(
            predicate: #Predicate { $0.isExpired || ($0.isDismissed && $0.dismissedAt! < Date().addingTimeInterval(-30 * 24 * 60 * 60)) }
        )
        if let expired = try? modelContext.fetch(descriptor) {
            for suggestion in expired {
                modelContext.delete(suggestion)
            }
            try? modelContext.save()
        }
    }
    
    // MARK: - 统计
    
    /// 获取建议统计
    func getSuggestionStats() -> SuggestionStats {
        let descriptor = FetchDescriptor<SmartSuggestion>()
        let allSuggestions = (try? modelContext.fetch(descriptor)) ?? []
        
        let total = allSuggestions.count
        let active = allSuggestions.filter { $0.isActive }.count
        let completed = allSuggestions.filter { $0.isCompleted }.count
        let dismissed = allSuggestions.filter { $0.isDismissed }.count
        
        let avgHelpfulness = allSuggestions.filter { $0.helpfulness > 0 }
            .map { Double($0.helpfulness) }
            .reduce(0, +) / Double(max(1, allSuggestions.filter { $0.helpfulness > 0 }.count))
        
        let completionRate = total > 0 ? Double(completed) / Double(total) : 0
        
        var byType: [String: Int] = [:]
        var byPriority: [String: Int] = [:]
        
        for suggestion in allSuggestions {
            byType[suggestion.type, default: 0] += 1
            byPriority[String(suggestion.priority), default: 0] += 1
        }
        
        return SuggestionStats(
            totalSuggestions: total,
            activeSuggestions: active,
            completedSuggestions: completed,
            dismissedSuggestions: dismissed,
            avgHelpfulness: avgHelpfulness,
            completionRate: completionRate,
            suggestionsByType: byType,
            suggestionsByPriority: byPriority
        )
    }
    
    // MARK: - 自动建议生成
    
    /// 检查是否需要生成新建议
    func checkAndGenerateSuggestions() async {
        // 获取用户梦境数据
        let dreamDescriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: 30
        )
        let recentDreams = (try? modelContext.fetch(dreamDescriptor)) ?? []
        
        // 分析模式 (简化版)
        let patterns = analyzeDreamPatterns(recentDreams)
        
        // 获取睡眠质量数据
        let sleepQuality = await getSleepQuality()
        
        // 计算压力水平 (基于情绪数据)
        let stressLevel = calculateStressLevel(from: recentDreams)
        
        // 创建上下文
        let context = SuggestionContext(
            recentDreams: recentDreams,
            dreamPatterns: patterns,
            sleepQuality: sleepQuality,
            stressLevel: stressLevel,
            dreamRecallRate: Double(recentDreams.count) / 30.0,
            config: config
        )
        
        // 生成建议
        let suggestions = generateSuggestions(context: context)
        
        // 保存新建议
        if !suggestions.isEmpty {
            saveSuggestions(suggestions)
        }
    }
    
    /// 获取睡眠质量数据
    private func getSleepQuality() async -> Double {
        // 尝试从健康数据获取睡眠质量
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        let sleepPredicate = #Predicate<SleepSession> { session in
            session.startDate >= startDate && session.startDate <= endDate
        }
        
        let sleepDescriptor = FetchDescriptor<SleepSession>(predicate: sleepPredicate)
        let sleepSessions = (try? modelContext.fetch(sleepDescriptor)) ?? []
        
        guard !sleepSessions.isEmpty else {
            // 如果没有睡眠数据，使用默认值
            return 0.7
        }
        
        // 计算平均睡眠质量
        let qualityScores = sleepSessions.map { session -> Double in
            switch session.quality {
            case .excellent: return 1.0
            case .good: return 0.8
            case .fair: return 0.6
            case .poor: return 0.4
            case .veryPoor: return 0.2
            }
        }
        
        return qualityScores.reduce(0, +) / Double(qualityScores.count)
    }
    
    /// 从情绪数据计算压力水平
    private func calculateStressLevel(from dreams: [Dream]) -> Double {
        guard !dreams.isEmpty else {
            return 0.4 // 默认值
        }
        
        // 高压力情绪
        let highStressEmotions: Set<DreamEmotion> = [.焦虑，.恐惧，.悲伤，.困惑]
        
        // 计算高压力情绪的比例
        let stressEmotions = dreams.filter { dream in
            if let emotion = dream.emotion {
                return highStressEmotions.contains(emotion)
            }
            return false
        }
        
        // 压力水平 = 高压力情绪的比例
        return Double(stressEmotions.count) / Double(dreams.count)
    }
    
    private func analyzeDreamPatterns(_ dreams: [Dream]) -> [String] {
        // 简化的模式分析
        var patterns: Set<String> = []
        
        // 分析情绪模式
        let moods = dreams.compactMap { $0.mood }
        let moodCounts = Dictionary(grouping: moods, by: { $0 })
            .mapValues { $0.count }
        
        if let dominantMood = moodCounts.max(by: { $0.value < $1.value })?.key {
            patterns.insert("主要情绪：\(dominantMood)")
        }
        
        // 分析标签模式
        let allTags = dreams.flatMap { $0.tags }
        let tagCounts = Dictionary(grouping: allTags, by: { $0 })
            .mapValues { $0.count }
        
        for (tag, count) in tagCounts where count >= 3 {
            patterns.insert("常见标签：\(tag)")
        }
        
        // 分析梦境长度
        let avgLength = dreams.map { $0.content.count }.reduce(0, +) / max(1, dreams.count)
        if avgLength < 100 {
            patterns.insert("梦境记录简短")
        } else if avgLength > 500 {
            patterns.insert("梦境记录详细")
        }
        
        return Array(patterns)
    }
}
