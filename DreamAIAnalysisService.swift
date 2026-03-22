//
//  DreamAIAnalysisService.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  Phase 87: 订阅系统集成 💎✨
//  核心服务层 - AI 梦境解析引擎
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData
import NaturalLanguage

// MARK: - AI 分析错误

enum AIAnalysisError: LocalizedError {
    case dailyLimitReached
    case premiumFeatureRequired
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .dailyLimitReached:
            return "已达到今日 AI 解析次数限制"
        case .premiumFeatureRequired:
            return "此功能需要高级版订阅"
        case .analysisFailed:
            return "AI 解析失败，请重试"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dailyLimitReached:
            return "升级至高级版可获得无限 AI 解析，或明日继续使用"
        case .premiumFeatureRequired:
            return "升级至高级版即可解锁此功能"
        case .analysisFailed:
            return "请检查网络连接后重试"
        }
    }
}

// MARK: - AI 分析服务

/// AI 梦境解析服务
public actor DreamAIAnalysisService {
    /// 共享实例
    public static let shared = DreamAIAnalysisService()
    
    /// 符号词典
    private let symbolDictionary = DreamSymbolDictionary.shared
    
    /// 模式识别引擎
    private let patternRecognition = DreamPatternRecognition.shared
    
    /// 洞察生成器
    private let insightGenerator = DreamInsightGenerator.shared
    
    /// 模型上下文
    private var modelContext: ModelContext?
    
    /// 分析配置
    public var configuration: AIAnalysisConfiguration = .default
    
    /// 当前用户 ID（用于个性化分析）
    public var currentUserId: String?
    
    private init() {}
    
    // MARK: - 公共方法
    
    /// 设置模型上下文
    public func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /// 分析梦境
    public func analyzeDream(
        dream: DreamEntry,
        configuration: AIAnalysisConfiguration? = nil
    ) async throws -> DreamAnalysis {
        // 检查订阅状态和使用限制
        try await checkUsageLimit()
        
        let config = configuration ?? self.configuration
        
        // 1. 提取关键词和符号
        let symbols = await extractSymbols(from: dream, maxSymbols: config.maxSymbols)
        
        // 2. 生成三层级解读
        let surfaceLayer = await generateSurfaceLayer(dream: dream, symbols: symbols)
        let psychologicalLayer = await generatePsychologicalLayer(dream: dream, symbols: symbols)
        let spiritualLayer = await generateSpiritualLayer(dream: dream, symbols: symbols)
        
        // 3. 模式识别
        var patterns: [DreamPattern] = []
        if config.enablePatternRecognition, let context = modelContext {
            patterns = await patternRecognition.identifyPatterns(
                dream: dream,
                in: context
            )
        }
        
        // 4. 趋势预测
        var trendPrediction: TrendPrediction?
        if config.enableTrendPrediction, let context = modelContext {
            trendPrediction = await generateTrendPrediction(
                dream: dream,
                in: context
            )
        }
        
        // 5. 生成个性化洞察
        var insights: [DreamInsight] = []
        if config.enablePersonalizedInsights, let context = modelContext {
            insights = await insightGenerator.generateInsights(
                dream: dream,
                symbols: symbols,
                patterns: patterns,
                in: context
            )
        }
        
        // 6. 生成行动建议
        let suggestions = await generateSuggestions(
            dream: dream,
            symbols: symbols,
            insights: insights
        )
        
        // 7. 计算置信度
        let confidence = calculateConfidence(
            symbols: symbols,
            patterns: patterns,
            dream: dream
        )
        
        // 8. 创建分析结果
        let analysis = DreamAnalysis(
            dreamId: dream.id,
            surfaceLayer: surfaceLayer,
            psychologicalLayer: psychologicalLayer,
            spiritualLayer: spiritualLayer,
            symbols: symbols,
            patterns: patterns,
            trendPrediction: trendPrediction,
            insights: insights,
            suggestions: suggestions,
            confidence: confidence,
            modelVersion: "1.0",
            language: config.language
        )
        
        // 9. 保存到数据库
        if let context = modelContext {
            context.insert(analysis)
            try context.save()
        }
        
        return analysis
    }
    
    /// 获取梦境的分析结果
    public func getAnalysis(for dreamId: UUID) async throws -> DreamAnalysis? {
        guard let context = modelContext else {
            throw AnalysisError.noModelContext
        }
        
        let descriptor = FetchDescriptor<DreamAnalysis>(
            predicate: #Predicate { $0.dreamId == dreamId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let results = try context.fetch(descriptor)
        return results.first
    }
    
    /// 获取所有分析结果
    public func getAllAnalyses() async throws -> [DreamAnalysis] {
        guard let context = modelContext else {
            throw AnalysisError.noModelContext
        }
        
        let descriptor = FetchDescriptor<DreamAnalysis>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// 删除分析结果
    public func deleteAnalysis(_ analysis: DreamAnalysis) async throws {
        guard let context = modelContext else {
            throw AnalysisError.noModelContext
        }
        
        context.delete(analysis)
        try context.save()
    }
    
    // MARK: - 订阅检查
    
    /// 检查使用限制
    private func checkUsageLimit() async throws {
        // Premium 用户无限制
        if SubscriptionManager.shared.isPremium {
            return
        }
        
        // 检查免费版每日限制
        let usageTracker = DreamUsageTracker.shared
        guard usageTracker.canUseAIAnalysis() else {
            throw AIAnalysisError.dailyLimitReached
        }
        
        // 记录使用
        usageTracker.recordAIAnalysisUsage()
    }
    
    // MARK: - 符号提取
    
    /// 从梦境中提取符号
    private func extractSymbols(
        from dream: DreamEntry,
        maxSymbols: Int
    ) async -> [DreamSymbolAnalysis] {
        var symbols: [DreamSymbolAnalysis] = []
        
        // 1. 文本分析提取关键词
        let keywords = extractKeywords(from: dream.content)
        
        // 2. 情绪分析
        let emotions = analyzeEmotions(from: dream.content)
        
        // 3. 匹配符号词典
        for keyword in keywords {
            if let symbolEntry = await symbolDictionary.getSymbol(keyword) {
                let frequency = await countSymbolFrequency(symbolEntry.name)
                
                let symbolAnalysis = DreamSymbolAnalysis(
                    symbolName: symbolEntry.name,
                    category: symbolEntry.category,
                    context: findContext(for: keyword, in: dream.content),
                    surfaceMeaning: symbolEntry.surfaceMeaning,
                    psychologicalMeaning: symbolEntry.psychologicalMeaning,
                    spiritualMeaning: symbolEntry.spiritualMeaning,
                    culturalInterpretations: symbolEntry.culturalInterpretations,
                    relatedSymbols: symbolEntry.relatedSymbols,
                    frequency: frequency,
                    emotionalAssociations: emotions,
                    confidence: 0.8
                )
                
                symbols.append(symbolAnalysis)
            }
        }
        
        // 4. 按置信度和频率排序
        symbols.sort {
            ($0.confidence, $0.frequency) > ($1.confidence, $1.frequency)
        }
        
        return Array(symbols.prefix(maxSymbols))
    }
    
    /// 提取关键词
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var keywords: [String] = []
        
        // 提取名词
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag {
                if tag == .nouns || tag == .properNouns {
                    let word = String(text[range])
                    if word.count > 1 {
                        keywords.append(word)
                    }
                }
            }
        }
        
        // 添加预设的梦境符号关键词
        let commonDreamSymbols = [
            "飞行", "坠落", "追逐", "考试", "迟到", "迷路",
            "水", "火", "山", "树", "蛇", "龙", "鸟",
            "家", "学校", "医院", "森林", "海洋",
            "母亲", "父亲", "朋友", "陌生人",
            "钥匙", "门", "镜子", "书", "手机"
        ]
        
        for symbol in commonDreamSymbols {
            if text.contains(symbol) && !keywords.contains(symbol) {
                keywords.append(symbol)
            }
        }
        
        return keywords
    }
    
    /// 分析情绪
    private func analyzeEmotions(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        var emotions: [String] = []
        
        // 简单的情绪关键词匹配
        let emotionKeywords: [String: String] = [
            "快乐": "happy", "开心": "happy", "高兴": "happy", "兴奋": "excited",
            "悲伤": "sad", "难过": "sad", "痛苦": "painful",
            "恐惧": "fearful", "害怕": "fearful", "紧张": "anxious",
            "愤怒": "angry", "生气": "angry", "恼火": "angry",
            "惊讶": "surprised", "吃惊": "surprised",
            "平静": "calm", "安宁": "calm", "放松": "relaxed"
        ]
        
        for (keyword, emotion) in emotionKeywords {
            if text.contains(keyword) {
                emotions.append(emotion)
            }
        }
        
        return emotions.isEmpty ? ["neutral"] : emotions
    }
    
    /// 查找符号在文本中的上下文
    private func findContext(for symbol: String, in text: String) -> String {
        if let range = text.range(of: symbol) {
            let start = text.index(range.lowerBound, offsetBy: -20, limitedBy: text.startIndex) ?? text.startIndex
            let end = text.index(range.upperBound, offsetBy: 20, limitedBy: text.endIndex) ?? text.endIndex
            return String(text[start..<end]).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }
    
    /// 计算符号出现频率
    private func countSymbolFrequency(_ symbolName: String) async -> Int {
        guard let context = modelContext else { return 1 }
        
        do {
            let descriptor = FetchDescriptor<DreamEntry>(
                predicate: #Predicate { $0.content.contains(symbolName) }
            )
            let count = try context.fetch(descriptor).count
            return count
        } catch {
            return 1
        }
    }
    
    // MARK: - 三层级解读生成
    
    /// 生成表面层解读
    private func generateSurfaceLayer(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis]
    ) -> AnalysisLayerContent {
        var keyPoints: [String] = []
        
        // 总结梦境内容
        let summary = summarizeDream(dream.content)
        keyPoints.append("梦境概述：\(summary)")
        
        // 识别的主要符号
        if !symbols.isEmpty {
            let symbolNames = symbols.prefix(5).map { $0.symbolName }.joined(separator: "、")
            keyPoints.append("主要符号：\(symbolNames)")
        }
        
        // 情绪基调
        let emotions = analyzeEmotions(from: dream.content)
        keyPoints.append("情绪基调：\(emotions.joined(separator: ", "))")
        
        return AnalysisLayerContent(
            layerType: .surface,
            title: "📖 表面解读",
            interpretation: "这个梦境包含了\(symbols.count)个可识别的符号。\(generateSurfaceSummary(symbols))",
            keyPoints: keyPoints,
            references: [],
            emotionalTone: emotions.first ?? "neutral"
        )
    }
    
    /// 生成心理层解读
    private func generatePsychologicalLayer(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis]
    ) -> AnalysisLayerContent {
        var keyPoints: [String] = []
        var references: [String] = []
        
        // 心理分析
        for symbol in symbols.prefix(3) {
            keyPoints.append("• **\(symbol.symbolName)**: \(symbol.psychologicalMeaning)")
        }
        
        // 添加心理学参考
        if !symbols.isEmpty {
            references.append("荣格心理学：梦境是潜意识的表达")
            references.append("弗洛伊德理论：梦是愿望的满足")
        }
        
        let interpretation = """
        从心理学角度来看，这个梦境反映了你当前的内心状态和潜意识活动。
        
        \(symbols.map { "• \($0.symbolName): \($0.psychologicalMeaning)" }.joined(separator: "\n\n"))
        
        这些符号共同揭示了你内心深处的\(generatePsychologicalTheme(symbols))。
        """
        
        return AnalysisLayerContent(
            layerType: .psychological,
            title: "🧠 心理分析",
            interpretation: interpretation,
            keyPoints: keyPoints,
            references: references,
            emotionalTone: "analytical"
        )
    }
    
    /// 生成精神层解读
    private func generateSpiritualLayer(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis]
    ) -> AnalysisLayerContent {
        var keyPoints: [String] = []
        
        // 精神启示
        for symbol in symbols.prefix(3) {
            keyPoints.append("• \(symbol.symbolName): \(symbol.spiritualMeaning)")
        }
        
        let interpretation = """
        从精神层面来看，这个梦境传递了关于你灵魂旅程的重要信息。
        
        \(symbols.map { "• \($0.symbolName): \($0.spiritualMeaning)" }.joined(separator: "\n\n"))
        
        这个梦境邀请你\(generateSpiritualGuidance(symbols))。
        """
        
        return AnalysisLayerContent(
            layerType: .spiritual,
            title: "✨ 精神启示",
            interpretation: interpretation,
            keyPoints: keyPoints,
            references: ["精神传统中的梦境智慧"],
            emotionalTone: "inspirational"
        )
    }
    
    // MARK: - 辅助方法
    
    /// 总结梦境
    private func summarizeDream(_ content: String) -> String {
        let words = content.split(separator: " ")
        if words.count <= 50 {
            return content
        }
        return String(words.prefix(50)) + "..."
    }
    
    /// 生成表面总结
    private func generateSurfaceSummary(_ symbols: [DreamSymbolAnalysis]) -> String {
        guard !symbols.isEmpty else {
            return "梦境内容较为抽象，难以识别具体符号。"
        }
        
        let categories = Set(symbols.map { $0.category })
        return "梦境涉及\(categories.count)个类别的符号，包括\(categories.map { $0.displayName }.joined(separator: "、"))。"
    }
    
    /// 生成心理主题
    private func generatePsychologicalTheme(_ symbols: [DreamSymbolAnalysis]) -> String {
        // 简单实现，可根据符号组合生成更复杂的主题
        if symbols.contains(where: { $0.category == .person }) {
            return "人际关系和自我认同的探索"
        } else if symbols.contains(where: { $0.category == .action }) {
            return "行动力和生活方向的思考"
        } else if symbols.contains(where: { $0.category == .place }) {
            return "安全感和归属感的探索"
        }
        return "内在成长和自我的探索"
    }
    
    /// 生成精神指引
    private func generateSpiritualGuidance(_ symbols: [DreamSymbolAnalysis]) -> String {
        if symbols.contains(where: { $0.symbolName == "光" || $0.symbolName == "太阳" }) {
            return "关注内在的光明，信任你的精神指引"
        } else if symbols.contains(where: { $0.symbolName == "黑暗" || $0.symbolName == "迷宫" }) {
            return "在黑暗中保持信心，这是转化的必经之路"
        } else if symbols.contains(where: { $0.symbolName == "飞行" }) {
            return "拥抱你的自由，超越限制"
        }
        return "保持开放的心态，聆听内在的智慧"
    }
    
    /// 生成趋势预测
    private func generateTrendPrediction(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> TrendPrediction? {
        // 简单实现：基于历史数据生成预测
        let predictions: [PredictionItem] = [
            PredictionItem(
                content: "未来 7 天可能出现与\(analyzeEmotions(from: dream.content).first ?? "当前情绪")相关的梦境",
                probability: 0.7,
                timeFrame: "7 天内"
            ),
            PredictionItem(
                content: "清醒梦的概率有所提升",
                probability: 0.5,
                timeFrame: "2 周内"
            )
        ]
        
        return TrendPrediction(
            predictionType: .theme,
            title: "📈 梦境趋势预测",
            description: "基于你的梦境历史，以下是未来可能的趋势",
            timeRange: "未来 7-14 天",
            predictions: predictions,
            confidence: 0.6,
            influencingFactors: ["近期梦境模式", "情绪状态", "睡眠质量"],
            recommendedActions: [
                "继续保持梦境记录",
                "睡前进行冥想练习",
                "注意情绪变化"
            ]
        )
    }
    
    /// 生成行动建议
    private func generateSuggestions(
        dream: DreamEntry,
        symbols: [DreamSymbolAnalysis],
        insights: [DreamInsight]
    ) -> [ActionSuggestion] {
        var suggestions: [ActionSuggestion] = []
        
        // 基于符号生成建议
        for symbol in symbols.prefix(2) {
            if symbol.category == .action && symbol.symbolName == "飞行" {
                suggestions.append(ActionSuggestion(
                    category: .meditation,
                    title: "尝试飞行冥想",
                    description: "既然梦中出现飞行符号，可以尝试相关的冥想练习",
                    actionSteps: [
                        "找一个安静的地方坐下或躺下",
                        "闭上眼睛，深呼吸",
                        "想象自己轻盈地飘浮在空中",
                        "感受自由和轻松的感觉",
                        "保持 5-10 分钟"
                    ],
                    expectedOutcome: "增强自由感和内在力量",
                    difficulty: .easy,
                    estimatedTime: "10 分钟",
                    priority: 8
                ))
            }
            
            if symbol.category == .abstract && symbol.symbolName == "黑暗" {
                suggestions.append(ActionSuggestion(
                    category: .reflection,
                    title: "阴影工作练习",
                    description: "黑暗符号提示需要探索内在的阴影面",
                    actionSteps: [
                        "准备纸笔",
                        "写下让你感到恐惧或不安的事情",
                        "思考这些恐惧背后的原因",
                        "问自己：这个恐惧想告诉我什么？",
                        "写下新的理解和接纳"
                    ],
                    expectedOutcome: "更好地整合内在阴影，获得成长",
                    difficulty: .medium,
                    estimatedTime: "20 分钟",
                    priority: 7
                ))
            }
        }
        
        // 通用建议
        suggestions.append(ActionSuggestion(
            category: .recording,
            title: "优化梦境记录",
            description: "提高梦境记录质量可以获得更深入的解析",
            actionSteps: [
                "醒来后立即记录",
                "记录尽可能多的细节",
                "注意梦境中的情绪",
                "记录醒来时的感受"
            ],
            expectedOutcome: "更清晰的梦境记忆和更准确的解析",
            difficulty: .easy,
            estimatedTime: "5 分钟",
            priority: 9
        ))
        
        return suggestions.sorted { $0.priority > $1.priority }
    }
    
    /// 计算置信度
    private func calculateConfidence(
        symbols: [DreamSymbolAnalysis],
        patterns: [DreamPattern],
        dream: DreamEntry
    ) -> Double {
        var confidence = 0.5
        
        // 符号数量影响
        if symbols.count >= 5 {
            confidence += 0.2
        } else if symbols.count >= 3 {
            confidence += 0.1
        }
        
        // 符号频率影响
        let highFrequencySymbols = symbols.filter { $0.frequency > 1 }.count
        confidence += Double(highFrequencySymbols) * 0.05
        
        // 模式识别影响
        if !patterns.isEmpty {
            confidence += 0.1
        }
        
        // 梦境长度影响
        if dream.content.count > 200 {
            confidence += 0.1
        }
        
        return min(confidence, 0.95)
    }
}

// MARK: - 错误类型

public enum AnalysisError: LocalizedError {
    case noModelContext
    case analysisNotFound
    case extractionFailed
    case saveFailed
    
    public var errorDescription: String? {
        switch self {
        case .noModelContext:
            return "未设置模型上下文"
        case .analysisNotFound:
            return "未找到分析结果"
        case .extractionFailed:
            return "符号提取失败"
        case .saveFailed:
            return "保存失败"
        }
    }
}
