//
//  DreamInsightGenerator.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  洞察生成器 - 生成个性化梦境洞察和行动建议
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - 洞察生成器主类

actor DreamInsightGenerator {
    
    // MARK: - Properties
    
    private let symbolDictionary: DreamSymbolDictionary
    private let patternRecognition: DreamPatternRecognition
    private var userPreferences: UserAnalysisPreferences
    
    // MARK: - Initialization
    
    init(
        symbolDictionary: DreamSymbolDictionary = DreamSymbolDictionary(),
        patternRecognition: DreamPatternRecognition = DreamPatternRecognition(),
        userPreferences: UserAnalysisPreferences = UserAnalysisPreferences()
    ) {
        self.symbolDictionary = symbolDictionary
        self.patternRecognition = patternRecognition
        self.userPreferences = userPreferences
    }
    
    // MARK: - Public Methods
    
    /// 生成完整的梦境解析
    func generateAnalysis(
        for dream: DreamEntry,
        historicalDreams: [DreamEntry] = []
    ) async -> DreamAnalysis {
        // 1. 符号解析
        let symbols = await analyzeSymbols(in: dream)
        
        // 2. 模式识别
        let patterns = await recognizePatterns(
            currentDream: dream,
            historicalDreams: historicalDreams
        )
        
        // 3. 生成三层级解读
        let surfaceLayer = generateSurfaceLayer(dream: dream, symbols: symbols)
        let psychologicalLayer = generatePsychologicalLayer(dream: dream, symbols: symbols, patterns: patterns)
        let spiritualLayer = generateSpiritualLayer(dream: dream, symbols: symbols, patterns: patterns)
        
        // 4. 趋势预测
        let trendPrediction = await generateTrendPrediction(
            currentDream: dream,
            historicalDreams: historicalDreams,
            patterns: patterns
        )
        
        // 5. 生成个性化洞察
        let insights = await generateInsights(
            dream: dream,
            symbols: symbols,
            patterns: patterns,
            trendPrediction: trendPrediction
        )
        
        // 6. 生成行动建议
        let suggestions = await generateSuggestions(
            dream: dream,
            insights: insights,
            userPreferences: userPreferences
        )
        
        // 7. 计算置信度
        let confidence = calculateConfidence(
            symbolsCount: symbols.count,
            patternsCount: patterns.count,
            dreamDetailLevel: dream.content.count
        )
        
        return DreamAnalysis(
            dreamId: dream.id,
            surfaceLayer: surfaceLayer,
            psychologicalLayer: psychologicalLayer,
            spiritualLayer: spiritualLayer,
            symbols: symbols,
            patterns: patterns,
            trendPrediction: trendPrediction,
            insights: insights,
            suggestions: suggestions,
            confidence: confidence
        )
    }
    
    /// 生成符号探索洞察
    func generateSymbolInsight(symbol: String) async -> SymbolInsight {
        let symbolData = await symbolDictionary.lookupSymbol(symbol)
        
        return SymbolInsight(
            symbol: symbol,
            name: symbolData?.name ?? symbol,
            category: symbolData?.category ?? .object,
            surfaceMeaning: symbolData?.surfaceMeaning ?? "待解析",
            psychologicalMeaning: symbolData?.psychologicalMeaning ?? "待解析",
            spiritualMeaning: symbolData?.spiritualMeaning ?? "待解析",
            culturalInterpretations: symbolData?.culturalInterpretations ?? [],
            relatedSymbols: symbolData?.relatedSymbols ?? [],
            frequency: 0,
            firstSeen: nil,
            lastSeen: nil
        )
    }
    
    // MARK: - Private Methods
    
    /// 分析梦境中的符号
    private func analyzeSymbols(in dream: DreamEntry) async -> [DreamSymbolAnalysis] {
        var symbols: [DreamSymbolAnalysis] = []
        
        // 从标题提取符号
        let titleSymbols = extractSymbols(from: dream.title)
        for symbol in titleSymbols {
            if let symbolData = await symbolDictionary.lookupSymbol(symbol) {
                symbols.append(DreamSymbolAnalysis(
                    symbol: symbol,
                    name: symbolData.name,
                    category: symbolData.category,
                    surfaceMeaning: symbolData.surfaceMeaning,
                    psychologicalMeaning: symbolData.psychologicalMeaning,
                    spiritualMeaning: symbolData.spiritualMeaning,
                    emotionalTone: inferEmotionalTone(from: dream, symbol: symbol),
                    prominence: 0.8,
                    recurring: false
                ))
            }
        }
        
        // 从内容提取符号
        let contentSymbols = extractSymbols(from: dream.content)
        for symbol in contentSymbols {
            if let symbolData = await symbolDictionary.lookupSymbol(symbol) {
                // 检查是否已存在
                if !symbols.contains(where: { $0.symbol == symbol }) {
                    symbols.append(DreamSymbolAnalysis(
                        symbol: symbol,
                        name: symbolData.name,
                        category: symbolData.category,
                        surfaceMeaning: symbolData.surfaceMeaning,
                        psychologicalMeaning: symbolData.psychologicalMeaning,
                        spiritualMeaning: symbolData.spiritualMeaning,
                        emotionalTone: inferEmotionalTone(from: dream, symbol: symbol),
                        prominence: 0.6,
                        recurring: false
                    ))
                }
            }
        }
        
        // 从标签提取符号
        for tag in dream.tags {
            if let symbolData = await symbolDictionary.lookupSymbol(tag) {
                if !symbols.contains(where: { $0.symbol == tag }) {
                    symbols.append(DreamSymbolAnalysis(
                        symbol: tag,
                        name: symbolData.name,
                        category: symbolData.category,
                        surfaceMeaning: symbolData.surfaceMeaning,
                        psychologicalMeaning: symbolData.psychologicalMeaning,
                        spiritualMeaning: symbolData.spiritualMeaning,
                        emotionalTone: dream.emotions.first?.rawValue ?? "neutral",
                        prominence: 0.7,
                        recurring: false
                    ))
                }
            }
        }
        
        return symbols
    }
    
    /// 从文本中提取符号关键词
    private func extractSymbols(from text: String) -> [String] {
        // 简化的符号提取逻辑
        // 实际实现应该使用 NLP 进行更精确的提取
        let commonSymbols = [
            "水", "火", "风", "土", "山", "河", "海", "云", "雨", "雪",
            "树", "花", "草", "森林", "花园",
            "鸟", "鱼", "猫", "狗", "马", "龙", "蛇",
            "房子", "门", "窗", "路", "桥", "车", "飞机",
            "书", "笔", "手机", "电脑", "镜子",
            "飞", "跑", "跳", "走", "追", "逃",
            "笑", "哭", "害怕", "开心", "生气",
            "太阳", "月亮", "星星", "天空", "地球"
        ]
        
        var foundSymbols: [String] = []
        let lowerText = text.lowercased()
        
        for symbol in commonSymbols {
            if lowerText.contains(symbol) {
                foundSymbols.append(symbol)
            }
        }
        
        return foundSymbols
    }
    
    /// 推断符号的情感色调
    private func inferEmotionalTone(from dream: DreamEntry, symbol: String) -> String {
        // 根据梦境情绪和符号上下文推断
        if let primaryEmotion = dream.emotions.first {
            return primaryEmotion.rawValue
        }
        return "neutral"
    }
    
    /// 识别梦境模式
    private func recognizePatterns(
        currentDream: DreamEntry,
        historicalDreams: [DreamEntry]
    ) async -> [DreamPattern] {
        var patterns: [DreamPattern] = []
        
        // 1. 重复符号模式
        let recurringSymbols = await patternRecognition.findRecurringSymbols(
            in: [currentDream] + historicalDreams,
            minOccurrences: 2
        )
        
        for (symbol, occurrences) in recurringSymbols {
            patterns.append(DreamPattern(
                type: .recurringSymbol,
                description: "符号\"\(symbol)\"重复出现 \(occurrences) 次",
                significance: Double(occurrences) * 0.2,
                relatedDreams: [],
                firstOccurrence: nil,
                lastOccurrence: nil,
                metadata: ["symbol": symbol, "count": String(occurrences)]
            ))
        }
        
        // 2. 情绪模式
        if !historicalDreams.isEmpty {
            let emotionPattern = await patternRecognition.detectEmotionPatterns(
                in: [currentDream] + historicalDreams
            )
            patterns.append(contentsOf: emotionPattern)
        }
        
        // 3. 主题模式
        let themePatterns = await patternRecognition.detectThemePatterns(
            in: [currentDream] + historicalDreams
        )
        patterns.append(contentsOf: themePatterns)
        
        // 4. 时间模式
        let timePatterns = await patternRecognition.detectTimePatterns(
            in: [currentDream] + historicalDreams
        )
        patterns.append(contentsOf: timePatterns)
        
        return patterns
    }
    
    /// 生成表面层解读
    private func generateSurfaceLayer(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis]
    ) -> AnalysisLayerContent {
        var content = "这个梦境包含了"
        
        if !symbols.isEmpty {
            let symbolNames = symbols.prefix(5).map { $0.name }.joined(separator: "、")
            content += "\(symbolNames)等元素"
        }
        
        content += "。"
        
        if !dream.emotions.isEmpty {
            let emotions = dream.emotions.map { $0.rawValue }.joined(separator: "、")
            content += "梦境中主要的情绪是\(emotions)。"
        }
        
        content += "\n\n梦境描述：\(dream.content.prefix(200))"
        
        if dream.content.count > 200 {
            content += "..."
        }
        
        return AnalysisLayerContent(
            title: "梦境表面解读",
            content: content,
            keyPoints: symbols.prefix(5).map { "\($0.name): \($0.surfaceMeaning)" },
            confidence: 0.9
        )
    }
    
    /// 生成心理层解读
    private func generatePsychologicalLayer(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis],
        patterns: [DreamPattern]
    ) -> AnalysisLayerContent {
        var content = "从心理学角度来看，"
        
        if !symbols.isEmpty {
            content += "这个梦境反映了你潜意识中对"
            let meanings = symbols.prefix(3).map { $0.psychologicalMeaning }.joined(separator: "、")
            content += "\(meanings)的关注。"
        }
        
        if !patterns.isEmpty {
            content += "\n\n梦境中出现的模式表明，"
            if patterns.contains(where: { $0.type == .recurringSymbol }) {
                content += "某些主题在你的生活中反复出现，值得深入思考。"
            }
            if patterns.contains(where: { $0.type == .emotionPattern }) {
                content += "你的情绪状态呈现出特定的规律性。"
            }
        }
        
        content += "\n\n这个梦境可能与你最近的生活经历、压力源或未解决的问题有关。"
        
        return AnalysisLayerContent(
            title: "心理学解读",
            content: content,
            keyPoints: symbols.prefix(5).map { "\($0.name): \($0.psychologicalMeaning)" },
            confidence: 0.75
        )
    }
    
    /// 生成精神层解读
    private func generateSpiritualLayer(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis],
        patterns: [DreamPattern]
    ) -> AnalysisLayerContent {
        var content = "从精神成长的视角，"
        
        if !symbols.isEmpty {
            content += "这个梦境可能是在指引你关注"
            let meanings = symbols.prefix(3).map { $0.spiritualMeaning }.joined(separator: "、")
            content += "\(meanings)。"
        }
        
        content += "\n\n梦境是内在智慧的表达，它可能在提示你："
        
        if dream.emotions.contains(.fear) || dream.emotions.contains(.anxiety) {
            content += "\n• 面对内心的恐惧，它们是成长的契机"
        }
        if dream.emotions.contains(.joy) || dream.emotions.contains(.excitement) {
            content += "\n• 保持开放的心态，接纳生活中的积极变化"
        }
        if dream.emotions.contains(.sadness) {
            content += "\n• 允许自己感受悲伤，它是疗愈的一部分"
        }
        
        content += "\n\n试着冥想这个梦境带来的信息，看看它如何与你的生活旅程相呼应。"
        
        return AnalysisLayerContent(
            title: "精神层解读",
            content: content,
            keyPoints: symbols.prefix(5).map { "\($0.name): \($0.spiritualMeaning)" },
            confidence: 0.65
        )
    }
    
    /// 生成趋势预测
    private func generateTrendPrediction(
        currentDream: DreamEntry,
        historicalDreams: [DreamEntry],
        patterns: [DreamPattern]
    ) async -> TrendPrediction? {
        guard historicalDreams.count >= 3 else {
            return nil
        }
        
        // 分析梦境清晰度趋势
        let clarityTrend = analyzeClarityTrend(dreams: [currentDream] + historicalDreams)
        
        // 分析情绪趋势
        let emotionTrend = analyzeEmotionTrend(dreams: [currentDream] + historicalDreams)
        
        // 预测清醒梦概率
        let lucidProbability = predictLucidDreamProbability(
            currentDream: currentDream,
            historicalDreams: historicalDreams
        )
        
        // 生成预测文本
        var predictionText = "基于你的梦境历史，"
        
        if clarityTrend == .increasing {
            predictionText += "你的梦境清晰度正在提升，这是一个积极信号。"
        } else if clarityTrend == .decreasing {
            predictionText += "近期梦境清晰度有所下降，可能与压力或睡眠质量有关。"
        } else {
            predictionText += "你的梦境清晰度保持稳定。"
        }
        
        return TrendPrediction(
            prediction: predictionText,
            clarityTrend: clarityTrend,
            emotionTrend: emotionTrend,
            lucidDreamProbability: lucidProbability,
            timeRange: "未来 7 天",
            confidence: 0.6
        )
    }
    
    /// 分析清晰度趋势
    private func analyzeClarityTrend(dreams: [DreamEntry]) -> TrendDirection {
        guard dreams.count >= 3 else { return .stable }
        
        let recent = dreams.prefix(3).map { $0.clarity }.reduce(0, +) / 3.0
        let older = dreams.suffix(3).map { $0.clarity }.reduce(0, +) / 3.0
        
        if recent > older + 0.5 {
            return .increasing
        } else if recent < older - 0.5 {
            return .decreasing
        }
        return .stable
    }
    
    /// 分析情绪趋势
    private func analyzeEmotionTrend(dreams: [DreamEntry]) -> String {
        let emotionCounts: [String: Int] = dreams.reduce(into: [:]) { result, dream in
            for emotion in dream.emotions {
                result[emotion.rawValue, default: 0] += 1
            }
        }
        
        if let dominant = emotionCounts.max(by: { $0.value < $1.value })?.key {
            return "近期以\(dominant)情绪为主"
        }
        return "情绪分布较为均衡"
    }
    
    /// 预测清醒梦概率
    private func predictLucidDreamProbability(
        currentDream: DreamEntry,
        historicalDreams: [DreamEntry]
    ) -> Double {
        // 基础概率
        var probability = 0.3
        
        // 如果当前梦境清晰度高，增加概率
        if currentDream.clarity >= 4 {
            probability += 0.2
        }
        
        // 如果有清醒梦历史，增加概率
        let lucidCount = historicalDreams.filter { $0.isLucid }.count
        if lucidCount > 0 {
            probability += Double(lucidCount) / Double(historicalDreams.count) * 0.3
        }
        
        // 如果有反思习惯，增加概率
        if !currentDream.reflectionNotes.isEmpty {
            probability += 0.1
        }
        
        return min(probability, 0.9)
    }
    
    /// 生成个性化洞察
    private func generateInsights(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis],
        patterns: [DreamPattern],
        trendPrediction: TrendPrediction?
    ) async -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        // 1. 符号洞察
        for symbol in symbols.prefix(3) {
            insights.append(DreamInsight(
                type: .symbolDiscovery,
                title: "符号发现：\(symbol.name)",
                content: "\(symbol.name)在梦中出现，可能代表\(symbol.psychologicalMeaning.lowercased())。",
                category: .awareness,
                priority: .medium,
                actionText: "探索这个符号的更多含义"
            ))
        }
        
        // 2. 模式洞察
        for pattern in patterns.prefix(2) {
            insights.append(DreamInsight(
                type: .patternRecognition,
                title: "模式识别",
                content: pattern.description,
                category: .awareness,
                priority: pattern.significance > 0.5 ? .high : .medium,
                actionText: "思考这个模式与生活的关联"
            ))
        }
        
        // 3. 趋势洞察
        if let trend = trendPrediction {
            insights.append(DreamInsight(
                type: .trendAwareness,
                title: "梦境趋势",
                content: trend.prediction,
                category: .growth,
                priority: .medium,
                actionText: "关注梦境变化趋势"
            ))
        }
        
        // 4. 清醒梦洞察
        if dream.clarity >= 4 && !dream.isLucid {
            insights.append(DreamInsight(
                type: .lucidOpportunity,
                title: "清醒梦机会",
                content: "这个梦境清晰度很高，是练习清醒梦的好机会！",
                category: .growth,
                priority: .high,
                actionText: "尝试清醒梦技巧"
            ))
        }
        
        return insights
    }
    
    /// 生成行动建议
    private func generateSuggestions(
        dream: DreamEntry,
        insights: [DreamInsight],
        userPreferences: UserAnalysisPreferences
    ) async -> [ActionSuggestion] {
        var suggestions: [ActionSuggestion] = []
        
        // 1. 记录优化建议
        if dream.content.count < 100 {
            suggestions.append(ActionSuggestion(
                category: .recording,
                title: "丰富梦境记录",
                description: "尝试记录更多细节，包括颜色、声音、气味和身体感受。",
                priority: .medium,
                estimatedTime: "5 分钟",
                actionType: .journaling
            ))
        }
        
        // 2. 冥想建议
        if dream.emotions.contains(.anxiety) || dream.emotions.contains(.fear) {
            suggestions.append(ActionSuggestion(
                category: .meditation,
                title: "平静冥想练习",
                description: "尝试 10 分钟的呼吸引导冥想，帮助平复焦虑情绪。",
                priority: .high,
                estimatedTime: "10 分钟",
                actionType: .meditation
            ))
        }
        
        // 3. 创意表达建议
        if dream.clarity >= 4 || dream.intensity >= 4 {
            suggestions.append(ActionSuggestion(
                category: .creative,
                title: "创意表达",
                description: "这个梦境很生动，试着用绘画、写作或音乐来表达它。",
                priority: .medium,
                estimatedTime: "15-30 分钟",
                actionType: .creative
            ))
        }
        
        // 4. 睡眠改善建议
        if dream.clarity <= 2 {
            suggestions.append(ActionSuggestion(
                category: .sleep,
                title: "改善睡眠质量",
                description: "建立规律的睡前仪式，避免睡前使用电子设备。",
                priority: .medium,
                estimatedTime: "长期习惯",
                actionType: .lifestyle
            ))
        }
        
        // 5. 自我探索建议
        if !insights.isEmpty {
            suggestions.append(ActionSuggestion(
                category: .selfExploration,
                title: "深度反思",
                description: "花些时间思考这些洞察，写下它们与你生活的关联。",
                priority: .high,
                estimatedTime: "10-15 分钟",
                actionType: .reflection
            ))
        }
        
        // 根据用户偏好排序
        suggestions.sort { prioritizeSuggestion($0, $1, preferences: userPreferences) }
        
        return suggestions
    }
    
    /// 根据用户偏好排序建议
    private func prioritizeSuggestion(
        _ lhs: ActionSuggestion,
        _ rhs: ActionSuggestion,
        preferences: UserAnalysisPreferences
    ) -> Bool {
        // 优先显示高优先级建议
        if lhs.priority != rhs.priority {
            return lhs.priority.rawValue < rhs.priority.rawValue
        }
        
        // 根据用户偏好调整顺序
        if preferences.preferredCategories.contains(lhs.category) &&
           !preferences.preferredCategories.contains(rhs.category) {
            return true
        }
        
        return false
    }
    
    /// 计算解析置信度
    private func calculateConfidence(
        symbolsCount: Int,
        patternsCount: Int,
        dreamDetailLevel: Int
    ) -> Double {
        var confidence = 0.5
        
        // 符号数量贡献
        if symbolsCount >= 5 {
            confidence += 0.2
        } else if symbolsCount >= 3 {
            confidence += 0.1
        }
        
        // 模式数量贡献
        if patternsCount >= 3 {
            confidence += 0.15
        } else if patternsCount >= 1 {
            confidence += 0.08
        }
        
        // 梦境详细程度贡献
        if dreamDetailLevel >= 500 {
            confidence += 0.15
        } else if dreamDetailLevel >= 200 {
            confidence += 0.1
        }
        
        return min(confidence, 0.95)
    }
}

// MARK: - 用户分析偏好

struct UserAnalysisPreferences {
    var preferredCategories: [InsightCategory] = [.awareness, .growth]
    var preferredSuggestionTypes: [SuggestionCategory] = [.meditation, .reflection]
    var detailLevel: AnalysisDetailLevel = .detailed
    var includeCulturalInterpretations: Bool = true
    var language: String = "zh-CN"
}

enum AnalysisDetailLevel {
    case brief
    case standard
    case detailed
}
