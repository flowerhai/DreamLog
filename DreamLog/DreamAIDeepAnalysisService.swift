//
//  DreamAIDeepAnalysisService.swift
//  DreamLog
//
//  Phase 91: AI 深度梦境解读引擎 🧠✨
//  创建时间：2026-03-22
//

import Foundation
import SwiftData
import Combine

// MARK: - 深度分析服务

@MainActor
class DreamAIDeepAnalysisService: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var currentProgress: Double = 0.0
    @Published var currentStep: String = ""
    @Published var error: String?
    
    private let modelContext: ModelContext
    private let symbolDatabase: DreamSymbolDatabase
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.symbolDatabase = DreamSymbolDatabase.shared
    }
    
    // MARK: - 多层梦境分析
    
    /// 执行深度梦境分析
    func performDeepAnalysis(dream: Dream) async -> DreamAnalysisResult {
        isAnalyzing = true
        currentProgress = 0.0
        currentStep = "准备分析..."
        error = nil
        
        do {
            // 第 1 层：表层分析
            currentStep = "表层分析：关键词与情绪..."
            let surfaceAnalysis = try await performSurfaceAnalysis(dream: dream)
            currentProgress = 0.25
            
            // 第 2 层：中层分析
            currentStep = "中层分析：符号与原型..."
            let middleAnalysis = try await performMiddleAnalysis(dream: dream, surfaceAnalysis: surfaceAnalysis)
            currentProgress = 0.50
            
            // 第 3 层：深层分析
            currentStep = "深层分析：心理学解读..."
            let deepAnalysis = try await performDeepPsychologicalAnalysis(
                dream: dream,
                surfaceAnalysis: surfaceAnalysis,
                middleAnalysis: middleAnalysis
            )
            currentProgress = 0.75
            
            // 第 4 层：整合与洞察
            currentStep = "整合洞察：生成个性化建议..."
            let integratedResult = integrateAnalysis(
                dream: dream,
                surfaceAnalysis: surfaceAnalysis,
                middleAnalysis: middleAnalysis,
                deepAnalysis: deepAnalysis
            )
            currentProgress = 1.0
            
            // 保存分析结果
            try await saveAnalysisResult(dream: dream, result: integratedResult)
            
            isAnalyzing = false
            return integratedResult
            
        } catch {
            self.error = "分析失败：\(error.localizedDescription)"
            isAnalyzing = false
            return DreamAnalysisResult.errorResult(error: error.localizedDescription)
        }
    }
    
    // MARK: - 第 1 层：表层分析
    
    private func performSurfaceAnalysis(dream: Dream) async throws -> SurfaceAnalysis {
        // 关键词提取
        let keywords = extractAdvancedKeywords(from: dream.content)
        
        // 情绪分析
        let emotionProfile = analyzeEmotionProfile(dream: dream)
        
        // 主题识别
        let themes = identifyThemes(keywords: keywords, emotions: emotionProfile)
        
        // 梦境类型分类
        let dreamType = classifyDreamType(dream: dream, themes: themes)
        
        return SurfaceAnalysis(
            keywords: keywords,
            emotionProfile: emotionProfile,
            themes: themes,
            dreamType: dreamType,
            clarity: dream.clarity ?? 5,
            intensity: dream.intensity ?? 5
        )
    }
    
    private func extractAdvancedKeywords(from content: String) -> [KeywordInfo] {
        // 分词
        let words = content.components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { $0.count >= 2 }
        
        // 过滤停用词
        let stopWords = Set(["在", "的", "了", "是", "不", "有", "这", "个", "很", "但", "说", "和", "就", "都", "而", "及", "与", "着", "就", "那", "你", "我", "他"])
        let filteredWords = words.filter { !stopWords.contains($0) }
        
        // 计算词频
        var wordFrequency: [String: Int] = [:]
        for word in filteredWords {
            wordFrequency[word, default: 0] += 1
        }
        
        // 转换为 KeywordInfo
        return wordFrequency
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { KeywordInfo(word: $0.key, frequency: $0.value, relevance: Double($0.value) / Double(filteredWords.count)) }
    }
    
    private func analyzeEmotionProfile(dream: Dream) -> EmotionProfile {
        let emotions = dream.emotions
        
        guard !emotions.isEmpty else {
            return EmotionProfile(primary: .neutral, secondary: [], intensity: 0.3, complexity: 0.1)
        }
        
        // 计算情绪强度
        let totalIntensity = emotions.reduce(0.0) { $0 + Double($1.intensity) }
        let avgIntensity = totalIntensity / Double(emotions.count)
        
        // 情绪复杂度 (不同情绪的数量)
        let uniqueEmotionTypes = Set(emotions.map { $0.type }).count
        let complexity = Double(uniqueEmotionTypes) / 10.0  // 假设有 10 种基本情绪
        
        // 主要情绪
        let sortedEmotions = emotions.sorted { $0.intensity > $1.intensity }
        let primary = sortedEmotions.first?.type ?? .neutral
        let secondary = sortedEmotions.dropFirst().map { $0.type }
        
        return EmotionProfile(
            primary: primary,
            secondary: Array(secondary.prefix(3)),
            intensity: avgIntensity,
            complexity: complexity
        )
    }
    
    private func identifyThemes(keywords: [KeywordInfo], emotions: EmotionProfile) -> [ThemeInfo] {
        var themes: [ThemeInfo] = []
        
        // 基于关键词识别主题
        let keywordWords = keywords.map { $0.word }
        
        // 常见梦境主题映射
        let themeMappings: [(theme: DreamTheme, keywords: [String])] = [
            (.falling, ["掉", "落", "坠", "悬崖", "跌落"]),
            (.flying, ["飞", "天空", "空中", "漂浮", "翅膀"]),
            (.chasing, ["追", "跑", "逃", "躲", "被追"]),
            (.beingChased, ["被追", "逃跑", "躲藏", "害怕"]),
            (.teeth, ["牙", "牙齿", "掉牙", "嘴巴"]),
            (.exam, ["考试", "学校", "教室", "老师", "学习"]),
            (.water, ["水", "海", "河", "湖", "游泳", "下雨"]),
            (.house, ["房子", "家", "房间", "门", "窗户"]),
            (.death, ["死", "去世", "葬礼", "墓地", "鬼魂"]),
            (.naked, ["裸体", "没穿衣服", "光着"]),
            (.late, ["迟到", "来不及", "错过", "赶车"]),
            (.lost, ["迷路", "找不到", "陌生", "未知"])
        ]
        
        for mapping in themeMappings {
            let matchedKeywords = keywordWords.filter { word in
                mapping.keywords.contains { word.contains($0) }
            }
            
            if !matchedKeywords.isEmpty {
                let confidence = Double(matchedKeywords.count) / Double(mapping.keywords.count)
                themes.append(ThemeInfo(
                    theme: mapping.theme,
                    confidence: confidence,
                    matchedKeywords: matchedKeywords
                ))
            }
        }
        
        return themes.sorted { $0.confidence > $1.confidence }
    }
    
    private func classifyDreamType(dream: Dream, themes: [ThemeInfo]) -> DreamType {
        // 基于内容特征分类梦境类型
        let content = dream.content.lowercased()
        
        if content.contains("知道") && content.contains("梦") {
            return .lucid  // 清醒梦
        }
        
        if content.contains("重复") || content.contains("又做") {
            return .recurring  // 重复梦境
        }
        
        if content.contains("预知") || content.contains("预言") {
            return .precognitive  // 预知梦
        }
        
        if themes.contains(where: { $0.theme == .falling || $0.theme == .flying }) {
            return .typical  // 典型梦境
        }
        
        if dream.emotions.contains(where: { $0.type == .fearful && $0.intensity > 7 }) {
            return .nightmare  // 噩梦
        }
        
        return .ordinary  // 普通梦境
    }
    
    // MARK: - 第 2 层：中层分析
    
    private func performMiddleAnalysis(dream: Dream, surfaceAnalysis: SurfaceAnalysis) async throws -> MiddleAnalysis {
        // 符号识别
        let symbols = identifySymbols(keywords: surfaceAnalysis.keywords)
        
        // 原型识别
        let archetypes = identifyArchetypes(symbols: symbols, themes: surfaceAnalysis.themes)
        
        // 符号关联分析
        let symbolNetwork = analyzeSymbolNetwork(symbols: symbols)
        
        return MiddleAnalysis(
            symbols: symbols,
            archetypes: archetypes,
            symbolNetwork: symbolNetwork
        )
    }
    
    private func identifySymbols(keywords: [KeywordInfo]) -> [SymbolInfo] {
        var symbols: [SymbolInfo] = []
        
        for keyword in keywords {
            // 查询符号数据库
            if let symbolData = symbolDatabase.lookupSymbol(keyword.word) {
                symbols.append(SymbolInfo(
                    name: symbolData.name,
                    category: symbolData.category,
                    meanings: symbolData.meanings,
                    culturalVariants: symbolData.culturalVariants,
                    confidence: 0.8,
                    personalMeaning: nil  // TODO: 从用户个人符号词典获取
                ))
            } else {
                // 尝试模糊匹配
                let fuzzyMatches = symbolDatabase.fuzzySearch(keyword.word)
                if let match = fuzzyMatches.first {
                    symbols.append(SymbolInfo(
                        name: match.name,
                        category: match.category,
                        meanings: match.meanings,
                        culturalVariants: match.culturalVariants,
                        confidence: 0.6,
                        personalMeaning: nil
                    ))
                }
            }
        }
        
        return symbols
    }
    
    private func identifyArchetypes(symbols: [SymbolInfo], themes: [ThemeInfo]) -> [ArchetypeInfo] {
        var archetypeScores: [JungianArchetype: Double] = [:]
        var archetypeSymbols: [JungianArchetype: [String]] = [:]
        
        // 基于符号识别原型
        for symbol in symbols {
            for archetype in JungianArchetype.allCases {
                if archetype.dreamSymbols.contains(where: { symbol.name.contains($0) }) {
                    archetypeScores[archetype, default: 0.0] += 0.3
                    archetypeSymbols[archetype, default: []].append(symbol.name)
                }
            }
        }
        
        // 基于主题识别原型
        for theme in themes {
            for archetype in JungianArchetype.allCases {
                if archetype.dreamSymbols.contains(where: { theme.matchedKeywords.contains($0) }) {
                    archetypeScores[archetype, default: 0.0] += theme.confidence * 0.5
                    archetypeSymbols[archetype, default: []].append(contentsOf: theme.matchedKeywords)
                }
            }
        }
        
        // 转换为 ArchetypeInfo
        return archetypeScores
            .filter { $0.value > 0.3 }  // 阈值
            .sorted { $0.value > $1.value }
            .map { archetype, score in
                ArchetypeInfo(
                    archetype: archetype,
                    confidence: min(score, 1.0),
                    symbols: archetypeSymbols[archetype] ?? [],
                    interpretation: archetype.interpretation
                )
            }
    }
    
    private func analyzeSymbolNetwork(symbols: [SymbolInfo]) -> SymbolNetwork {
        // 构建符号关联网络
        var connections: [SymbolConnection] = []
        
        for i in 0..<symbols.count {
            for j in (i+1)..<symbols.count {
                let symbol1 = symbols[i]
                let symbol2 = symbols[j]
                
                // 计算关联强度
                let strength = calculateSymbolConnectionStrength(symbol1, symbol2)
                
                if strength > 0.3 {
                    connections.append(SymbolConnection(
                        symbol1: symbol1.name,
                        symbol2: symbol2.name,
                        strength: strength,
                        relationship: determineRelationship(symbol1, symbol2)
                    ))
                }
            }
        }
        
        return SymbolNetwork(symbols: symbols.map { $0.name }, connections: connections)
    }
    
    private func calculateSymbolConnectionStrength(_ s1: SymbolInfo, _ s2: SymbolInfo) -> Double {
        // 基于类别相同性
        if s1.category == s2.category {
            return 0.7
        }
        
        // 基于共同含义
        let commonMeanings = Set(s1.meanings).intersection(Set(s2.meanings)).count
        if commonMeanings > 0 {
            return Double(commonMeanings) / Double(max(s1.meanings.count, s2.meanings.count))
        }
        
        return 0.1
    }
    
    private func determineRelationship(_ s1: SymbolInfo, _ s2: SymbolInfo) -> SymbolRelationship {
        if s1.category == s2.category {
            return .complementary
        }
        
        let opposingCategories: [(String, String)] = [
            ("自然", "城市"),
            ("水", "火"),
            ("光明", "黑暗")
        ]
        
        for (cat1, cat2) in opposingCategories {
            if (s1.category == cat1 && s2.category == cat2) ||
               (s1.category == cat2 && s2.category == cat1) {
                return .opposing
            }
        }
        
        return .neutral
    }
    
    // MARK: - 第 3 层：深层心理学分析
    
    private func performDeepPsychologicalAnalysis(
        dream: Dream,
        surfaceAnalysis: SurfaceAnalysis,
        middleAnalysis: MiddleAnalysis
    ) async throws -> DeepAnalysis {
        // 荣格原型分析
        let archetypeAnalysis = performJungianAnalysis(archetypes: middleAnalysis.archetypes)
        
        // 阴影面分析
        let shadowAnalysis = performShadowAnalysis(
            dream: dream,
            emotions: surfaceAnalysis.emotionProfile,
            archetypes: middleAnalysis.archetypes
        )
        
        // 梦境工作分析 (弗洛伊德)
        let dreamWorkAnalysis = performFreudianAnalysis(
            dream: dream,
            symbols: middleAnalysis.symbols
        )
        
        // 整合解读
        let integratedInterpretation = generateIntegratedInterpretation(
            surfaceAnalysis: surfaceAnalysis,
            middleAnalysis: middleAnalysis,
            archetypeAnalysis: archetypeAnalysis,
            shadowAnalysis: shadowAnalysis,
            dreamWorkAnalysis: dreamWorkAnalysis
        )
        
        return DeepAnalysis(
            jungianAnalysis: archetypeAnalysis,
            shadowAnalysis: shadowAnalysis,
            freudianAnalysis: dreamWorkAnalysis,
            integratedInterpretation: integratedInterpretation
        )
    }
    
    private func performJungianAnalysis(archetypes: [ArchetypeInfo]) -> JungianAnalysis {
        guard let primary = archetypes.first else {
            return JungianAnalysis(
                primaryArchetype: nil,
                secondaryArchetypes: [],
                individuationStage: "unknown",
                integrationLevel: 0.3
            )
        }
        
        // 确定个体化阶段
        let individuationStage = determineIndividuationStage(archetypes: archetypes)
        
        // 计算整合水平
        let integrationLevel = calculateIntegrationLevel(archetypes: archetypes)
        
        return JungianAnalysis(
            primaryArchetype: primary.archetype,
            secondaryArchetypes: Array(archetypes.dropFirst(2)).map { $0.archetype },
            individuationStage: individuationStage,
            integrationLevel: integrationLevel
        )
    }
    
    private func determineIndividuationStage(archetypes: [ArchetypeInfo]) -> String {
        // 简化版个体化阶段判断
        let archetypeNames = archetypes.map { $0.archetype.rawValue }
        
        if archetypeNames.contains(.hero.rawValue) || archetypeNames.contains(.explorer.rawValue) {
            return "exploration"  // 探索阶段
        }
        
        if archetypeNames.contains(.sage.rawValue) || archetypeNames.contains(.magician.rawValue) {
            return "wisdom"  // 智慧阶段
        }
        
        if archetypeNames.contains(.self.rawValue) {
            return "integration"  // 整合阶段 (需要添加 self 原型)
        }
        
        return "initial"  // 初始阶段
    }
    
    private func calculateIntegrationLevel(archetypes: [ArchetypeInfo]) -> Double {
        // 基于原型多样性计算整合水平
        let uniqueCategories = Set(archetypes.map { $0.archetype }).count
        return min(Double(uniqueCategories) / 4.0, 1.0)  // 最多 4 种原型为完全整合
    }
    
    private func performShadowAnalysis(
        dream: Dream,
        emotions: EmotionProfile,
        archetypes: [ArchetypeInfo]
    ) -> ShadowAnalysisResult {
        var shadows: [ShadowAspectInfo] = []
        
        // 基于负面情绪识别阴影
        if emotions.primary == .fearful || emotions.primary == .angry || emotions.primary == .sad {
            shadows.append(ShadowAspectInfo(
                shadowType: .repressed,
                trait: "未处理的情绪创伤",
                confidence: 0.7,
                integrationAdvice: "尝试通过写作或对话表达这些情绪，允许自己感受它们。"
            ))
        }
        
        // 基于原型识别阴影
        for archetype in archetypes {
            let shadow = getShadowForArchetype(archetype.archetype)
            if let shadow = shadow {
                shadows.append(shadow)
            }
        }
        
        return ShadowAnalysisResult(
            identifiedShadows: shadows,
            integrationSuggestions: shadows.map { $0.integrationAdvice },
            overallShadowWork: min(Double(shadows.count) * 0.2, 1.0)
        )
    }
    
    private func getShadowForArchetype(_ archetype: JungianArchetype) -> ShadowAspectInfo? {
        switch archetype {
        case .hero:
            return ShadowAspectInfo(
                shadowType: .denied,
                trait: "脆弱和无力感",
                confidence: 0.6,
                integrationAdvice: "承认自己的局限不是软弱，而是智慧。允许自己有时不够强大。"
            )
        case .caregiver:
            return ShadowAspectInfo(
                shadowType: .repressed,
                trait: "对自己需求的忽视",
                confidence: 0.7,
                integrationAdvice: "照顾他人前先照顾自己。设定健康的边界。"
            )
        case .ruler:
            return ShadowAspectInfo(
                shadowType: .projected,
                trait: "对失控的恐惧",
                confidence: 0.6,
                integrationAdvice: "学习信任他人，接受不完美和不确定性。"
            )
        default:
            return nil
        }
    }
    
    private func performFreudianAnalysis(dream: Dream, symbols: [SymbolInfo]) -> FreudianAnalysis {
        // 简化的弗洛伊德梦境工作分析
        let content = dream.content
        
        // 检测凝缩 (多个元素合并)
        let condensationScore = detectCondensation(symbols: symbols)
        
        // 检测置换 (情感转移)
        let displacementScore = detectDisplacement(dream: dream)
        
        // 检测象征化
        let symbolizationScore = Double(symbols.count) / 10.0
        
        // 愿望满足检测
        let wishFulfillment = detectWishFulfillment(content: content, emotions: dream.emotions)
        
        return FreudianAnalysis(
            condensationLevel: condensationScore,
            displacementLevel: displacementScore,
            symbolizationLevel: symbolizationScore,
            wishFulfillmentDetected: wishFulfillment,
            latentContent: generateLatentContentInterpretation(dream: dream, symbols: symbols)
        )
    }
    
    private func detectCondensation(symbols: [SymbolInfo]) -> Double {
        // 如果多个符号指向同一主题，可能存在凝缩
        let categories = symbols.map { $0.category }
        let categoryCounts: [String: Int] = categories.reduce(into: [:]) { $0[$1, default: 0] += 1 }
        
        let maxCount = categoryCounts.values.max() ?? 0
        return min(Double(maxCount) / 5.0, 1.0)
    }
    
    private func detectDisplacement(dream: Dream) -> Double {
        // 如果情绪强度与内容不匹配，可能存在置换
        let content = dream.content.lowercased()
        let intenseEmotions = dream.emotions.filter { $0.intensity > 7 }
        
        if !intenseEmotions.isEmpty && !content.contains("害怕") && !content.contains("恐惧") {
            return 0.7
        }
        
        return 0.3
    }
    
    private func detectWishFulfillment(content: String, emotions: [Emotion]) -> Bool {
        // 检测愿望满足迹象
        let wishKeywords = ["想要", "希望", "渴望", "梦想", "变成", "成为"]
        let positiveEmotions = emotions.filter { $0.type == .happy || $0.type == .excited }
        
        return wishKeywords.contains(where: { content.contains($0) }) ||
               (!positiveEmotions.isEmpty && positiveEmotions.reduce(0) { $0 + $1.intensity } > 15)
    }
    
    private func generateLatentContentInterpretation(dream: Dream, symbols: [SymbolInfo]) -> String {
        // 生成潜内容解读
        if symbols.isEmpty {
            return "梦境的潜内容需要更多符号信息来解读。"
        }
        
        let mainSymbol = symbols.first?.name ?? "未知符号"
        return "这个梦境可能反映了你内心深处对\(mainSymbol)所代表意义的渴望或恐惧。建议反思近期生活中与此相关的经历。"
    }
    
    // MARK: - 第 4 层：整合
    
    private func integrateAnalysis(
        dream: Dream,
        surfaceAnalysis: SurfaceAnalysis,
        middleAnalysis: MiddleAnalysis,
        deepAnalysis: DeepAnalysis
    ) -> DreamAnalysisResult {
        // 生成综合解读
        let fullInterpretation = """
        **梦境解读**
        
        \(deepAnalysis.integratedInterpretation)
        
        **核心原型**: \(deepAnalysis.jungianAnalysis.primaryArchetype?.localizedName ?? "未识别")
        \(deepAnalysis.jungianAnalysis.primaryArchetype.map { $0.interpretation } ?? "")
        
        **情绪模式**: \(surfaceAnalysis.emotionProfile.primary.localizedName) 为主导，强度 \(String(format: "%.1f", surfaceAnalysis.emotionProfile.intensity * 10))
        
        **建议**:
        \(generateActionableSuggestions(result: DreamAnalysisResult(
            surfaceAnalysis: surfaceAnalysis,
            middleAnalysis: middleAnalysis,
            deepAnalysis: deepAnalysis,
            actionableSuggestions: [],
            overallScore: 0.8
        )).joined(separator: "\n"))
        """
        
        // 生成可操作建议
        let suggestions = generateActionableSuggestions(result: DreamAnalysisResult(
            surfaceAnalysis: surfaceAnalysis,
            middleAnalysis: middleAnalysis,
            deepAnalysis: deepAnalysis,
            actionableSuggestions: [],
            overallScore: 0.8
        ))
        
        return DreamAnalysisResult(
            surfaceAnalysis: surfaceAnalysis,
            middleAnalysis: middleAnalysis,
            deepAnalysis: deepAnalysis,
            actionableSuggestions: suggestions,
            overallScore: calculateOverallScore(surfaceAnalysis, middleAnalysis, deepAnalysis)
        )
    }
    
    private func generateActionableSuggestions(result: DreamAnalysisResult) -> [String] {
        var suggestions: [String] = []
        
        // 基于原型建议
        if let archetype = result.deepAnalysis.jungianAnalysis.primaryArchetype {
            suggestions.append("🎭 探索\(archetype.localizedName)原型：\(getArchetypeAction(archetype))")
        }
        
        // 基于阴影建议
        if !result.deepAnalysis.shadowAnalysis.identifiedShadows.isEmpty {
            let shadowAdvice = result.deepAnalysis.shadowAnalysis.identifiedShadows.first?.integrationAdvice ?? "进行自我反思和接纳"
            suggestions.append("🌑 阴影工作：\(shadowAdvice)")
        }
        
        // 基于情绪建议
        let emotion = result.surfaceAnalysis.emotionProfile.primary
        suggestions.append("💫 情绪调节：\(getEmotionAction(emotion))")
        
        // 基于梦境类型建议
        suggestions.append("📝 记录建议：\(getRecordingAdvice(result.surfaceAnalysis.dreamType))")
        
        return suggestions
    }
    
    private func getArchetypeAction(_ archetype: JungianArchetype) -> String {
        switch archetype {
        case .hero: return "设定一个小挑战并克服它"
        case .explorer: return "尝试一条新的回家路线"
        case .caregiver: return "为他人做一件善事"
        case .creator: return "进行 15 分钟创意活动"
        case .sage: return "阅读一章有深度的书籍"
        default: return "反思这个原型在你生活中的体现"
        }
    }
    
    private func getEmotionAction(_ emotion: EmotionType) -> String {
        switch emotion {
        case .fearful: return "练习深呼吸，识别恐惧的来源"
        case .angry: return "通过运动释放愤怒能量"
        case .sad: return "允许自己感受悲伤，与信任的人交流"
        case .happy: return "记录这份喜悦，思考如何延续"
        case .anxious: return "列出担忧事项，区分可控与不可控"
        default: return "保持正念，观察当下的感受"
        }
    }
    
    private func getRecordingAdvice(_ dreamType: DreamType) -> String {
        switch dreamType {
        case .lucid: return "记录清醒梦中的控制技巧和触发点"
        case .recurring: return "对比每次重复梦境的差异和变化"
        case .nightmare: return "记录噩梦前的情绪和生活事件"
        default: return "记录梦境细节和醒来时的感受"
        }
    }
    
    private func calculateOverallScore(_ surface: SurfaceAnalysis, _ middle: MiddleAnalysis, _ deep: DeepAnalysis) -> Double {
        // 计算分析质量评分
        var score = 0.5  // 基础分
        
        // 符号丰富度
        score += min(Double(middle.symbols.count) / 10.0, 0.2)
        
        // 原型清晰度
        if let primary = deep.jungianAnalysis.primaryArchetype {
            score += 0.15
        }
        
        // 情绪清晰度
        score += surface.emotionProfile.intensity * 0.15
        
        return min(score, 1.0)
    }
    
    // MARK: - 保存结果
    
    private func saveAnalysisResult(dream: Dream, result: DreamAnalysisResult) async throws {
        // 保存原型出现记录
        if let primaryArchetype = result.deepAnalysis.jungianAnalysis.primaryArchetype {
            let occurrence = DreamArchetypeOccurrence(
                dreamId: dream.id,
                archetype: primaryArchetype,
                confidence: 0.8,
                symbols: result.middleAnalysis.symbols.map { $0.name }
            )
            modelContext.insert(occurrence)
        }
        
        // 保存阴影面记录
        for shadow in result.deepAnalysis.shadowAnalysis.identifiedShadows {
            let shadowAspect = DreamShadowAspect(
                dreamId: dream.id,
                shadowType: shadow.shadowType,
                trait: shadow.trait,
                triggerSymbols: result.middleAnalysis.symbols.map { $0.name },
                integrationAdvice: shadow.integrationAdvice
            )
            modelContext.insert(shadowAspect)
        }
        
        try modelContext.save()
    }
}

// MARK: - 分析结果模型

struct DreamAnalysisResult {
    let surfaceAnalysis: SurfaceAnalysis
    let middleAnalysis: MiddleAnalysis
    let deepAnalysis: DeepAnalysis
    let actionableSuggestions: [String]
    let overallScore: Double
    
    static func errorResult(error: String) -> DreamAnalysisResult {
        DreamAnalysisResult(
            surfaceAnalysis: SurfaceAnalysis(keywords: [], emotionProfile: EmotionProfile(primary: .neutral, secondary: [], intensity: 0, complexity: 0), themes: [], dreamType: .ordinary, clarity: 5, intensity: 5),
            middleAnalysis: MiddleAnalysis(symbols: [], archetypes: [], symbolNetwork: SymbolNetwork(symbols: [], connections: [])),
            deepAnalysis: DeepAnalysis(jungianAnalysis: JungianAnalysis(primaryArchetype: nil, secondaryArchetypes: [], individuationStage: "unknown", integrationLevel: 0), shadowAnalysis: ShadowAnalysisResult(identifiedShadows: [], integrationSuggestions: [], overallShadowWork: 0), freudianAnalysis: FreudianAnalysis(condensationLevel: 0, displacementLevel: 0, symbolizationLevel: 0, wishFulfillmentDetected: false, latentContent: "分析失败：\(error)"), integratedInterpretation: "分析失败：\(error)"),
            actionableSuggestions: [],
            overallScore: 0.0
        )
    }
}

struct SurfaceAnalysis {
    let keywords: [KeywordInfo]
    let emotionProfile: EmotionProfile
    let themes: [ThemeInfo]
    let dreamType: DreamType
    let clarity: Int
    let intensity: Int
}

struct MiddleAnalysis {
    let symbols: [SymbolInfo]
    let archetypes: [ArchetypeInfo]
    let symbolNetwork: SymbolNetwork
}

struct DeepAnalysis {
    let jungianAnalysis: JungianAnalysis
    let shadowAnalysis: ShadowAnalysisResult
    let freudianAnalysis: FreudianAnalysis
    let integratedInterpretation: String
}

// MARK: - 辅助模型

struct KeywordInfo: Codable {
    let word: String
    let frequency: Int
    let relevance: Double
}

struct EmotionProfile: Codable {
    let primary: EmotionType
    let secondary: [EmotionType]
    let intensity: Double
    let complexity: Double
}

struct ThemeInfo: Codable {
    let theme: DreamTheme
    let confidence: Double
    let matchedKeywords: [String]
}

struct SymbolInfo: Codable {
    let name: String
    let category: String
    let meanings: [String]
    let culturalVariants: [String]
    let confidence: Double
    let personalMeaning: String?
}

struct ArchetypeInfo: Codable {
    let archetype: JungianArchetype
    let confidence: Double
    let symbols: [String]
    let interpretation: String
}

struct SymbolNetwork: Codable {
    let symbols: [String]
    let connections: [SymbolConnection]
}

struct SymbolConnection: Codable {
    let symbol1: String
    let symbol2: String
    let strength: Double
    let relationship: SymbolRelationship
}

enum SymbolRelationship: String, Codable {
    case complementary
    case opposing
    case neutral
}

struct JungianAnalysis: Codable {
    let primaryArchetype: JungianArchetype?
    let secondaryArchetypes: [JungianArchetype]
    let individuationStage: String
    let integrationLevel: Double
}

struct ShadowAnalysisResult: Codable {
    let identifiedShadows: [ShadowAspectInfo]
    let integrationSuggestions: [String]
    let overallShadowWork: Double
}

struct ShadowAspectInfo: Codable {
    let shadowType: ShadowType
    let trait: String
    let confidence: Double
    let integrationAdvice: String
}

struct FreudianAnalysis: Codable {
    let condensationLevel: Double
    let displacementLevel: Double
    let symbolizationLevel: Double
    let wishFulfillmentDetected: Bool
    let latentContent: String
}

enum DreamType: String, Codable {
    case ordinary = "ordinary"
    case lucid = "lucid"
    case recurring = "recurring"
    case nightmare = "nightmare"
    case precognitive = "precognitive"
    case typical = "typical"
}

enum DreamTheme: String, Codable {
    case falling = "falling"
    case flying = "flying"
    case chasing = "chasing"
    case beingChased = "being_chased"
    case teeth = "teeth"
    case exam = "exam"
    case water = "water"
    case house = "house"
    case death = "death"
    case naked = "naked"
    case late = "late"
    case lost = "lost"
}

enum EmotionType: String, Codable {
    case happy = "happy"
    case sad = "sad"
    case fearful = "fearful"
    case angry = "angry"
    case excited = "excited"
    case anxious = "anxious"
    case neutral = "neutral"
    
    var localizedName: String {
        switch self {
        case .happy: return "快乐"
        case .sad: return "悲伤"
        case .fearful: return "恐惧"
        case .angry: return "愤怒"
        case .excited: return "兴奋"
        case .anxious: return "焦虑"
        case .neutral: return "平静"
        }
    }
}
