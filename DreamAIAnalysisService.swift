//
//  DreamAIAnalysisService.swift
//  DreamLog - Phase 28: AI 梦境解析增强与智能洞察 2.0
//
//  AI 梦境解析增强服务
//

import Foundation
import NaturalLanguage

@MainActor
class DreamAIAnalysisService: ObservableObject {
    static let shared = DreamAIAnalysisService()
    
    @Published var isAnalyzing = false
    @Published var currentProgress: Double = 0.0
    @Published var lastAnalysisResult: DreamAnalysisResult?
    
    // 梦境符号知识库
    private var symbolKnowledgeBase: [String: DreamSymbol] = [:]
    
    // 分析历史缓存
    private var analysisCache: [UUID: DreamAnalysisResult] = [:]
    
    // 配置
    var config: AnalysisConfig = .default
    
    init() {
        loadSymbolKnowledgeBase()
    }
    
    // MARK: - 知识库加载
    
    private func loadSymbolKnowledgeBase() {
        // 加载常见梦境符号
        let commonSymbols: [(String, SymbolCategory, [String])] = [
            // 自然元素
            ("水", .nature, ["情绪", "潜意识", "净化", "流动"]),
            ("火", .nature, ["激情", "转化", "毁灭", "重生"]),
            ("风", .nature, ["变化", "自由", "消息", "灵动"]),
            ("土", .nature, ["稳定", "实际", "成长", "根基"]),
            ("雨", .nature, ["净化", "悲伤", "滋养", "更新"]),
            ("雪", .nature, ["纯洁", "冷静", "停滞", "宁静"]),
            
            // 动物
            ("蛇", .animal, ["转化", "智慧", "危险", "性"]),
            ("鸟", .animal, ["自由", "精神", "消息", "超越"]),
            ("鱼", .animal, ["财富", "潜意识", "繁衍", "直觉"]),
            ("猫", .animal, ["独立", "神秘", "直觉", "女性"]),
            ("狗", .animal, ["忠诚", "友谊", "保护", "本能"]),
            ("马", .animal, ["力量", "自由", "激情", "旅行"]),
            
            // 人物
            ("母亲", .person, ["养育", "保护", "源头", "关爱"]),
            ("父亲", .person, ["权威", "保护", "指导", "规则"]),
            ("孩子", .person, ["纯真", "潜力", "新生", "脆弱"]),
            ("老人", .person, ["智慧", "经验", "指导", "传统"]),
            ("陌生人", .person, ["未知", "投射", "新机遇", "恐惧"]),
            
            // 地点
            ("家", .place, ["自我", "安全", "归属", "内心"]),
            ("学校", .place, ["学习", "成长", "测试", "社交"]),
            ("医院", .place, ["治疗", "脆弱", "关怀", "转变"]),
            ("森林", .place, ["潜意识", "未知", "探索", "神秘"]),
            ("海洋", .place, ["潜意识", "无限", "情绪", "深度"]),
            ("山", .place, ["挑战", "成就", "稳定", "精神"]),
            
            // 动作
            ("飞行", .action, ["自由", "逃避", "超越", "控制"]),
            ("坠落", .action, ["失控", "恐惧", "失败", "放手"]),
            ("奔跑", .action, ["逃避", "追求", "活力", "紧迫"]),
            ("游泳", .action, ["情绪处理", "适应", "前进", "沉浸"]),
            ("战斗", .action, ["冲突", "抗争", "力量", "防御"]),
            
            // 物体
            ("门", .object, ["机会", "选择", "过渡", "未知"]),
            ("窗户", .object, ["视角", "机会", "观察", "光明"]),
            ("钥匙", .object, ["解答", "机会", "控制", "访问"]),
            ("镜子", .object, ["自我反思", "真相", "双重", "虚荣"]),
            ("书", .object, ["知识", "智慧", "学习", "秘密"]),
            ("手机", .object, ["沟通", "联系", "信息", "依赖"]),
            
            // 身体
            ("牙齿", .body, ["力量", "自信", "变化", "焦虑"]),
            ("头发", .body, ["力量", "美丽", "身份", "成长"]),
            ("眼睛", .body, ["洞察", "真相", "灵魂", "观察"]),
            ("手", .body, ["行动", "创造", "给予", "接受"]),
            ("脚", .body, ["基础", "前进", "稳定", "方向"]),
        ]
        
        for (name, category, meanings) in commonSymbols {
            let symbol = DreamSymbol(
                name: name,
                category: category,
                meanings: meanings.map { meaning in
                    SymbolMeaning(
                        interpretation: "\(name)象征\(meaning)",
                        context: "在梦境中出现",
                        psychological: "反映内心对\(meaning)的关注",
                        spiritual: "精神层面的\(meaning)启示",
                        positive: ["自由", "智慧", "成长", "机会", "力量"].contains(meaning)
                    )
                },
                culturalInterpretations: [
                    CulturalInterpretation(
                        culture: "中国",
                        interpretation: getChineseInterpretation(for: name),
                        significance: "传统文化视角"
                    )
                ]
            )
            symbolKnowledgeBase[name] = symbol
        }
    }
    
    private func getChineseInterpretation(for symbol: String) -> String {
        let chineseInterpretations: [String: String] = [
            "水": "水主财，也代表智慧和情感流动",
            "火": "火代表热情、活力，也象征冲突",
            "蛇": "蛇象征智慧、转化，也代表潜在危险",
            "鱼": "鱼象征财富、繁衍，年年有余",
            "龙": "龙是祥瑞之兆，代表权力和好运",
            "凤凰": "凤凰象征重生、高贵、吉祥",
            "门": "门代表机会和选择，开门迎福",
            "镜子": "镜子照见真相，也反映内心",
            "牙齿": "牙齿掉落可能预示亲人健康或自身变化",
        ]
        return chineseInterpretations[symbol] ?? "传统解梦中有多种解读"
    }
    
    // MARK: - 核心分析方法
    
    /// 执行深度梦境解析
    func analyzeDream(
        dreamId: UUID,
        title: String,
        content: String,
        emotions: [String],
        tags: [String],
        clarity: Int,
        isLucid: Bool,
        depth: AnalysisDepth = .deep
    ) async -> DreamAnalysisResult {
        let startTime = Date()
        isAnalyzing = true
        currentProgress = 0.1
        
        // 1. 表层解析
        updateProgress(0.2)
        let surfaceAnalysis = performSurfaceAnalysis(
            title: title,
            content: content,
            emotions: emotions,
            tags: tags
        )
        
        // 2. 深层解析
        updateProgress(0.4)
        let deepAnalysis = performDeepAnalysis(
            content: content,
            emotions: emotions,
            surfaceAnalysis: surfaceAnalysis
        )
        
        // 3. 原型层解析
        updateProgress(0.6)
        let archetypalAnalysis: String
        let identifiedArchetypes: [JungianArchetype]
        if depth == .archetypal || config.includeArchetypes {
            (archetypalAnalysis, identifiedArchetypes) = performArchetypalAnalysis(content: content)
        } else {
            archetypalAnalysis = "未进行原型层解析"
            identifiedArchetypes = []
        }
        
        // 4. 梦境类型识别
        updateProgress(0.7)
        let dreamType = identifyDreamType(
            content: content,
            emotions: emotions,
            isLucid: isLucid,
            clarity: clarity
        )
        
        // 5. 符号识别
        updateProgress(0.8)
        let keySymbols = identifyKeySymbols(content: content, tags: tags)
        
        // 6. 心理健康评估
        updateProgress(0.85)
        let mentalHealthMetrics = assessMentalHealth(
            emotions: emotions,
            dreamType: dreamType,
            clarity: clarity
        )
        
        // 7. 生成洞察
        updateProgress(0.9)
        let insights = generateInsights(
            dreamType: dreamType,
            symbols: keySymbols,
            metrics: mentalHealthMetrics,
            emotions: emotions
        )
        
        // 8. 生成建议
        updateProgress(0.93)
        let suggestions = generateSuggestions(
            dreamType: dreamType,
            insights: insights,
            metrics: mentalHealthMetrics
        )
        
        // 9. 生成预警
        updateProgress(0.96)
        let warnings = generateWarnings(
            dreamType: dreamType,
            metrics: mentalHealthMetrics,
            emotions: emotions
        )
        
        // 10. 计算置信度
        let confidence = calculateConfidence(
            contentLength: content.count,
            emotionCount: emotions.count,
            symbolCount: keySymbols.count,
            clarity: clarity
        )
        
        updateProgress(1.0)
        
        let processingTime = Int(Date().timeIntervalSince(startTime) * 1000)
        
        let result = DreamAnalysisResult(
            dreamId: dreamId,
            title: title,
            summary: generateSummary(surfaceAnalysis: surfaceAnalysis),
            surfaceAnalysis: surfaceAnalysis,
            deepAnalysis: deepAnalysis,
            archetypalAnalysis: archetypalAnalysis,
            dreamType: dreamType,
            identifiedArchetypes: identifiedArchetypes,
            keySymbols: keySymbols,
            mentalHealthMetrics: mentalHealthMetrics,
            insights: insights,
            suggestions: suggestions,
            warnings: warnings,
            confidence: confidence,
            analysisDepth: depth,
            processingTimeMs: processingTime
        )
        
        // 缓存结果
        analysisCache[dreamId] = result
        lastAnalysisResult = result
        isAnalyzing = false
        
        return result
    }
    
    private func updateProgress(_ progress: Double) {
        currentProgress = progress
    }
    
    // MARK: - 表层解析
    
    private func performSurfaceAnalysis(
        title: String,
        content: String,
        emotions: [String],
        tags: [String]
    ) -> String {
        var analysis = "## 表层解析\n\n"
        
        // 梦境概要
        analysis += "**梦境概要**: \(title)\n\n"
        
        // 情绪分析
        if !emotions.isEmpty {
            analysis += "**主要情绪**: \(emotions.joined(separator: "、"))\n"
            let dominantEmotion = emotions.first ?? "中性"
            analysis += "梦境整体情绪基调为**\(dominantEmotion)**，"
            
            if emotions.contains(where: ["焦虑", "恐惧", "紧张"].contains) {
                analysis += "可能反映近期的压力或担忧。\n"
            } else if emotions.contains(where: ["快乐", "兴奋", "平静"].contains) {
                analysis += "显示积极的心理状态。\n"
            } else {
                analysis += "情绪状态较为复杂。\n"
            }
        }
        
        // 标签分析
        if !tags.isEmpty {
            analysis += "\n**关键主题**: \(tags.joined(separator: "、"))\n"
        }
        
        // 清晰度分析
        analysis += "\n这个梦境的表层内容反映了您近期的生活经历和思绪。"
        
        return analysis
    }
    
    // MARK: - 深层解析
    
    private func performDeepAnalysis(
        content: String,
        emotions: [String],
        surfaceAnalysis: String
    ) -> String {
        var analysis = "## 深层解析\n\n"
        
        analysis += "从心理学角度来看，这个梦境可能反映了以下深层含义：\n\n"
        
        // 情绪深度分析
        if emotions.contains("焦虑") || emotions.contains("恐惧") {
            analysis += "### 压力与焦虑\n"
            analysis += "梦境中的焦虑情绪可能指向现实生活中的压力源。"
            analysis += "建议反思最近是否面临重要决定、工作压力或人际关系挑战。\n\n"
        }
        
        if emotions.contains("快乐") || emotions.contains("兴奋") {
            analysis += "### 积极情绪\n"
            analysis += "梦境中的愉悦感表明您的内心状态较为平衡，"
            analysis += "可能对近期发生的事情感到满意或期待。\n\n"
        }
        
        // 内容分析
        let lowercaseContent = content.lowercased()
        
        if lowercaseContent.contains("追逐") || lowercaseContent.contains("逃跑") {
            analysis += "### 逃避心理\n"
            analysis += "梦境中的追逐场景通常象征逃避某些问题或责任。"
            analysis += "思考一下是否有不愿面对的事情。\n\n"
        }
        
        if lowercaseContent.contains("飞行") || lowercaseContent.contains("飞") {
            analysis += "### 自由渴望\n"
            analysis += "飞行梦境往往代表对自由的渴望或想要超越现状的愿望。"
            analysis += "也可能表示您正在从新的角度看待问题。\n\n"
        }
        
        if lowercaseContent.contains("掉落") || lowercaseContent.contains("坠落") {
            analysis += "### 失控感\n"
            analysis += "坠落梦境常与失控感或不安全感相关。"
            analysis += "可能反映对某个情况的担忧或缺乏信心。\n\n"
        }
        
        if lowercaseContent.contains("考试") || lowercaseContent.contains("测试") {
            analysis += "### 表现焦虑\n"
            analysis += "考试梦境通常与被评价的焦虑有关。"
            analysis += "可能反映对工作能力或人际关系的担忧。\n\n"
        }
        
        analysis += "### 潜意识信息\n"
        analysis += "梦境是潜意识与我们对话的方式。"
        analysis += "这个梦境可能在提醒您关注某些被忽视的需求或情感。\n"
        
        return analysis
    }
    
    // MARK: - 原型层解析
    
    private func performArchetypalAnalysis(content: String) -> (String, [JungianArchetype]) {
        var analysis = "## 原型层解析\n\n"
        var identifiedArchetypes: [JungianArchetype] = []
        
        let lowercaseContent = content.lowercased()
        
        // 检测原型
        for archetype in JungianArchetype.allCases {
            let symbols = archetype.dreamSymbols
            let containsSymbol = symbols.contains { symbol in
                lowercaseContent.contains(symbol.lowercased())
            }
            
            if containsSymbol {
                identifiedArchetypes.append(archetype)
                analysis += "### \(archetype.displayName)\n"
                analysis += "\(archetype.description)\n\n"
            }
        }
        
        if identifiedArchetypes.isEmpty {
            analysis += "本次梦境中未检测到明显的荣格原型符号。\n"
            analysis += "这并不罕见，原型通常在重要的梦境中出现。\n"
        } else {
            analysis += "### 原型整合建议\n"
            analysis += "识别这些原型有助于理解梦境的深层含义。"
            analysis += "建议思考这些原型在您当前生活中的体现。\n"
        }
        
        return (analysis, identifiedArchetypes)
    }
    
    // MARK: - 梦境类型识别
    
    private func identifyDreamType(
        content: String,
        emotions: [String],
        isLucid: Bool,
        clarity: Int
    ) -> DreamType {
        let lowercaseContent = content.lowercased()
        
        // 清醒梦
        if isLucid || lowercaseContent.contains("知道自己在做梦") || lowercaseContent.contains("控制梦境") {
            return .lucid
        }
        
        // 噩梦
        if emotions.contains("恐惧") || emotions.contains("恐怖") || lowercaseContent.contains("噩梦") {
            return .nightmare
        }
        
        // 飞行梦
        if lowercaseContent.contains("飞行") || lowercaseContent.contains("飞") {
            return .flying
        }
        
        // 坠落梦
        if lowercaseContent.contains("掉落") || lowercaseContent.contains("坠落") {
            return .falling
        }
        
        // 被追逐梦
        if lowercaseContent.contains("追逐") || lowercaseContent.contains("逃跑") || lowercaseContent.contains("追赶") {
            return .chasing
        }
        
        // 考试梦
        if lowercaseContent.contains("考试") || lowercaseContent.contains("测试") || lowercaseContent.contains("考场") {
            return .examination
        }
        
        // 生动梦
        if clarity >= 4 {
            return .vivid
        }
        
        // 默认普通梦
        return .normal
    }
    
    // MARK: - 符号识别
    
    private func identifyKeySymbols(content: String, tags: [String]) -> [DreamSymbol] {
        var symbols: [DreamSymbol] = []
        let lowercaseContent = content.lowercased()
        
        // 从知识库中匹配符号
        for (symbolName, symbol) in symbolKnowledgeBase {
            if lowercaseContent.contains(symbolName.lowercased()) || tags.contains(symbolName) {
                var updatedSymbol = symbol
                updatedSymbol.frequency = 1
                symbols.append(updatedSymbol)
            }
        }
        
        // 限制返回数量
        return Array(symbols.prefix(10))
    }
    
    // MARK: - 心理健康评估
    
    private func assessMentalHealth(
        emotions: [String],
        dreamType: DreamType,
        clarity: Int
    ) -> MentalHealthMetrics {
        var stressLevel = 5
        var anxietyIndex = 5
        var moodScore = 5
        var sleepQualityScore = 5
        var emotionalStability = 5
        
        // 基于情绪调整
        let negativeEmotions = ["焦虑", "恐惧", "紧张", "愤怒", "悲伤", "绝望"]
        let positiveEmotions = ["快乐", "兴奋", "平静", "满足", "爱", "喜悦"]
        
        let negativeCount = emotions.filter { negativeEmotions.contains($0) }.count
        let positiveCount = emotions.filter { positiveEmotions.contains($0) }.count
        
        stressLevel = max(1, min(10, 5 + negativeCount - positiveCount))
        anxietyIndex = max(1, min(10, 5 + (emotions.contains("焦虑") || emotions.contains("恐惧") ? 2 : 0)))
        moodScore = max(1, min(10, 5 + positiveCount - negativeCount))
        
        // 基于梦境类型调整
        switch dreamType {
        case .nightmare:
            stressLevel = max(stressLevel, 7)
            anxietyIndex = max(anxietyIndex, 6)
        case .lucid:
            emotionalStability = max(emotionalStability, 7)
        case .vivid:
            sleepQualityScore = max(sleepQualityScore, 6)
        default:
            break
        }
        
        // 基于清晰度调整
        if clarity >= 4 {
            sleepQualityScore = max(sleepQualityScore, 6)
        } else if clarity <= 2 {
            sleepQualityScore = min(sleepQualityScore, 4)
        }
        
        let overallWellbeing = (moodScore + sleepQualityScore + emotionalStability) / 3
        
        return MentalHealthMetrics(
            stressLevel: stressLevel,
            anxietyIndex: anxietyIndex,
            moodScore: moodScore,
            sleepQualityScore: sleepQualityScore,
            emotionalStability: emotionalStability,
            overallWellbeing: overallWellbeing
        )
    }
    
    // MARK: - 洞察生成
    
    private func generateInsights(
        dreamType: DreamType,
        symbols: [DreamSymbol],
        metrics: MentalHealthMetrics,
        emotions: [String]
    ) -> [DreamInsight] {
        var insights: [DreamInsight] = []
        
        // 模式发现
        if dreamType == .recurring {
            insights.append(DreamInsight(
                type: .pattern,
                title: "重复梦境模式",
                description: "您最近反复出现相似的梦境，这通常表示有未解决的心理议题需要关注。",
                confidence: 0.85,
                evidence: ["梦境类型重复", "相似主题出现"]
            ))
        }
        
        // 压力洞察
        if metrics.stressLevel >= 7 {
            insights.append(DreamInsight(
                type: .warning,
                title: "压力水平较高",
                description: "您的梦境反映出较高的压力水平，建议采取放松措施。",
                confidence: 0.75,
                evidence: ["梦境情绪分析", "梦境类型特征"]
            ))
        }
        
        // 积极洞察
        if metrics.moodScore >= 7 {
            insights.append(DreamInsight(
                type: .achievement,
                title: "心理状态良好",
                description: "您的梦境显示当前心理状态较为平衡和积极。",
                confidence: 0.80,
                evidence: ["积极情绪主导", "梦境内容健康"]
            ))
        }
        
        // 符号洞察
        for symbol in symbols.prefix(3) {
            if let meaning = symbol.meanings.first {
                insights.append(DreamInsight(
                    type: .opportunity,
                    title: "符号启示：\(symbol.name)",
                    description: meaning.interpretation,
                    confidence: 0.70,
                    evidence: ["梦境符号出现", "符号学分析"]
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - 建议生成
    
    private func generateSuggestions(
        dreamType: DreamType,
        insights: [DreamInsight],
        metrics: MentalHealthMetrics
    ) -> [DreamSuggestion] {
        var suggestions: [DreamSuggestion] = []
        
        // 睡眠建议
        if metrics.sleepQualityScore <= 5 {
            suggestions.append(DreamSuggestion(
                type: .sleep,
                title: "改善睡眠质量",
                description: "您的梦境反映出睡眠质量可能需要改善。",
                actionItems: [
                    "保持规律的睡眠时间",
                    "睡前避免使用电子设备",
                    "创造舒适的睡眠环境",
                    "尝试睡前冥想或深呼吸"
                ],
                priority: .high
            ))
        }
        
        // 压力管理
        if metrics.stressLevel >= 7 {
            suggestions.append(DreamSuggestion(
                type: .stress,
                title: "压力管理技巧",
                description: "学习有效的压力管理方法可以帮助改善梦境质量。",
                actionItems: [
                    "每天进行 10-15 分钟冥想",
                    "规律运动，如散步或瑜伽",
                    "与朋友或家人交流",
                    "记录压力源并寻找解决方案"
                ],
                priority: .high
            ))
        }
        
        // 记录建议
        suggestions.append(DreamSuggestion(
            type: .journaling,
            title: "持续记录梦境",
            description: "持续的梦境记录有助于发现模式和获得更深入的洞察。",
            actionItems: [
                "醒来后立即记录",
                "记录情绪和感受",
                "标注重要符号",
                "定期回顾梦境日记"
            ],
            priority: .medium
        ))
        
        // 噩梦建议
        if dreamType == .nightmare {
            suggestions.append(DreamSuggestion(
                type: .selfCare,
                title: "噩梦应对策略",
                description: "频繁的噩梦可能需要特别关注。",
                actionItems: [
                    "睡前进行放松练习",
                    "避免恐怖或刺激内容",
                    "尝试意象排练疗法",
                    "如持续困扰，考虑专业咨询"
                ],
                priority: .high
            ))
        }
        
        return suggestions
    }
    
    // MARK: - 预警生成
    
    private func generateWarnings(
        dreamType: DreamType,
        metrics: MentalHealthMetrics,
        emotions: [String]
    ) -> [DreamWarning] {
        var warnings: [DreamWarning] = []
        
        // 反复噩梦预警
        if dreamType == .nightmare && metrics.anxietyIndex >= 7 {
            warnings.append(DreamWarning(
                type: .recurringNightmare,
                title: "频繁噩梦警示",
                description: "您的梦境显示频繁的噩梦模式，可能与高焦虑水平相关。",
                severity: .moderate,
                recommendedAction: "建议学习放松技巧，如持续出现请考虑咨询专业人士。"
            ))
        }
        
        // 高压力预警
        if metrics.stressLevel >= 8 {
            warnings.append(DreamWarning(
                type: .highStress,
                title: "高压力状态",
                description: "梦境反映出您正处于高压力状态，需要关注心理健康。",
                severity: .high,
                recommendedAction: "建议立即采取减压措施，必要时寻求专业支持。"
            ))
        }
        
        // 专业帮助建议
        if metrics.overallWellbeing <= 4 {
            warnings.append(DreamWarning(
                type: .professionalHelp,
                title: "建议专业咨询",
                description: "梦境分析显示您的整体心理状态需要关注。",
                severity: .high,
                recommendedAction: "建议咨询心理咨询师或精神健康专业人士。"
            ))
        }
        
        return warnings
    }
    
    // MARK: - 置信度计算
    
    private func calculateConfidence(
        contentLength: Int,
        emotionCount: Int,
        symbolCount: Int,
        clarity: Int
    ) -> Double {
        var confidence = 0.5
        
        // 内容长度贡献
        if contentLength >= 200 { confidence += 0.2 }
        else if contentLength >= 100 { confidence += 0.1 }
        
        // 情绪信息贡献
        if emotionCount >= 3 { confidence += 0.15 }
        else if emotionCount >= 1 { confidence += 0.08 }
        
        // 符号识别贡献
        if symbolCount >= 5 { confidence += 0.1 }
        else if symbolCount >= 2 { confidence += 0.05 }
        
        // 清晰度贡献
        confidence += Double(clarity) * 0.05
        
        return min(confidence, 0.95)
    }
    
    // MARK: - 缓存管理
    
    func getCachedAnalysis(for dreamId: UUID) -> DreamAnalysisResult? {
        return analysisCache[dreamId]
    }
    
    func clearCache() {
        analysisCache.removeAll()
    }
    
    func getAnalysisHistory() -> [DreamAnalysisResult] {
        return Array(analysisCache.values).sorted { $0.analysisDate > $1.analysisDate }
    }
}
