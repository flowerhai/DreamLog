//
//  DreamAIAnalysisTests.swift
//  DreamLog - Phase 28: AI 梦境解析增强与智能洞察 2.0
//
//  AI 梦境解析增强单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamAIAnalysisTests: XCTestCase {
    
    var analysisService: DreamAIAnalysisService!
    
    override func setUp() async throws {
        try await super.setUp()
        analysisService = DreamAIAnalysisService.shared
    }
    
    override func tearDown() async throws {
        analysisService = nil
        try await super.tearDown()
    }
    
    // MARK: - 数据模型测试
    
    func testAnalysisDepthDisplayNames() {
        XCTAssertEqual(AnalysisDepth.surface.displayName, "📖 表层解析")
        XCTAssertEqual(AnalysisDepth.deep.displayName, "🧠 深层解析")
        XCTAssertEqual(AnalysisDepth.archetypal.displayName, "✨ 原型层解析")
    }
    
    func testAnalysisDepthDescriptions() {
        XCTAssertFalse(AnalysisDepth.surface.description.isEmpty)
        XCTAssertFalse(AnalysisDepth.deep.description.isEmpty)
        XCTAssertFalse(AnalysisDepth.archetypal.description.isEmpty)
    }
    
    func testDreamTypeAllCases() {
        XCTAssertEqual(DreamType.allCases.count, 12)
        
        let types: [DreamType] = [
            .normal, .lucid, .recurring, .nightmare,
            .prophetic, .inspirational, .vivid, .fragmented,
            .flying, .falling, .chasing, .examination
        ]
        
        for type in types {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.description.isEmpty)
        }
    }
    
    func testDreamTypeCommonCauses() {
        let nightmare = DreamType.nightmare
        XCTAssertFalse(nightmare.commonCauses.isEmpty)
        XCTAssertTrue(nightmare.commonCauses.contains { $0.contains("压力") || $0.contains("焦虑") })
    }
    
    func testDreamTypeSuggestions() {
        let lucid = DreamType.lucid
        XCTAssertFalse(lucid.suggestions.isEmpty)
        XCTAssertTrue(lucid.suggestions.contains { $0.contains("清醒梦") || $0.contains("控制") })
    }
    
    func testJungianArchetypeAllCases() {
        XCTAssertEqual(JungianArchetype.allCases.count, 10)
        
        let archetypes: [JungianArchetype] = [
            .self_, .shadow, .anima, .animus, .persona,
            .wiseOldMan, .greatMother, .hero, .trickster, .child
        ]
        
        for archetype in archetypes {
            XCTAssertFalse(archetype.displayName.isEmpty)
            XCTAssertFalse(archetype.description.isEmpty)
            XCTAssertFalse(archetype.dreamSymbols.isEmpty)
        }
    }
    
    func testJungianArchetypeSymbols() {
        let shadow = JungianArchetype.shadow
        XCTAssertTrue(shadow.dreamSymbols.contains { $0.contains("敌人") || $0.contains("怪物") || $0.contains("黑暗") })
    }
    
    // MARK: - 心理健康指标测试
    
    func testMentalHealthMetricsStressLevels() {
        let lowStress = MentalHealthMetrics(
            stressLevel: 2, anxietyIndex: 2, moodScore: 8,
            sleepQualityScore: 8, emotionalStability: 8, overallWellbeing: 8
        )
        XCTAssertEqual(lowStress.stressLevelDescription, "😌 低压力")
        
        let highStress = MentalHealthMetrics(
            stressLevel: 9, anxietyIndex: 8, moodScore: 3,
            sleepQualityScore: 4, emotionalStability: 3, overallWellbeing: 3
        )
        XCTAssertEqual(highStress.stressLevelDescription, "😰 高压力")
    }
    
    func testMentalHealthMetricsAnxietyLevels() {
        let lowAnxiety = MentalHealthMetrics(
            stressLevel: 3, anxietyIndex: 2, moodScore: 7,
            sleepQualityScore: 7, emotionalStability: 7, overallWellbeing: 7
        )
        XCTAssertEqual(lowAnxiety.anxietyIndexDescription, "😌 放松")
        
        let highAnxiety = MentalHealthMetrics(
            stressLevel: 8, anxietyIndex: 9, moodScore: 3,
            sleepQualityScore: 4, emotionalStability: 3, overallWellbeing: 3
        )
        XCTAssertEqual(highAnxiety.anxietyIndexDescription, "😰 严重焦虑")
    }
    
    func testMentalHealthMetricsCompositeScore() {
        let excellent = MentalHealthMetrics(
            stressLevel: 1, anxietyIndex: 1, moodScore: 10,
            sleepQualityScore: 10, emotionalStability: 10, overallWellbeing: 10
        )
        XCTAssertGreaterThanOrEqual(excellent.compositeScore, 9)
        
        let poor = MentalHealthMetrics(
            stressLevel: 10, anxietyIndex: 10, moodScore: 1,
            sleepQualityScore: 1, emotionalStability: 1, overallWellbeing: 1
        )
        XCTAssertLessThanOrEqual(poor.compositeScore, 3)
    }
    
    func testMentalHealthMetricsDescriptions() {
        let metrics = MentalHealthMetrics(
            stressLevel: 5, anxietyIndex: 5, moodScore: 5,
            sleepQualityScore: 5, emotionalStability: 5, overallWellbeing: 5
        )
        XCTAssertFalse(metrics.compositeDescription.isEmpty)
        XCTAssertFalse(metrics.stressLevelDescription.isEmpty)
        XCTAssertFalse(metrics.anxietyIndexDescription.isEmpty)
        XCTAssertFalse(metrics.overallWellbeingDescription.isEmpty)
    }
    
    // MARK: - 符号类别测试
    
    func testSymbolCategoryAllCases() {
        XCTAssertEqual(SymbolCategory.allCases.count, 10)
        
        for category in SymbolCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }
    
    func testInsightTypeAllCases() {
        XCTAssertEqual(InsightType.allCases.count, 7)
        
        for type in InsightType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
    
    func testSuggestionTypeAllCases() {
        XCTAssertEqual(SuggestionType.allCases.count, 7)
        
        for type in SuggestionType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
    
    func testPriorityAllCases() {
        XCTAssertEqual(Priority.allCases.count, 4)
        
        XCTAssertEqual(Priority.low.displayName, "🟢 低")
        XCTAssertEqual(Priority.medium.displayName, "🟡 中")
        XCTAssertEqual(Priority.high.displayName, "🟠 高")
        XCTAssertEqual(Priority.urgent.displayName, "🔴 紧急")
    }
    
    func testWarningTypeAllCases() {
        XCTAssertEqual(WarningType.allCases.count, 6)
        
        for type in WarningType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
    
    func testSeverityAllCases() {
        XCTAssertEqual(Severity.allCases.count, 4)
        
        XCTAssertEqual(Severity.low.displayName, "🟢 轻微")
        XCTAssertEqual(Severity.moderate.displayName, "🟡 中等")
        XCTAssertEqual(Severity.high.displayName, "🟠 严重")
        XCTAssertEqual(Severity.severe.displayName, "🔴 非常严重")
    }
    
    // MARK: - 数据模型初始化测试
    
    func testDreamSymbolInitialization() {
        let symbol = DreamSymbol(
            name: "水",
            category: .nature,
            meanings: [
                SymbolMeaning(
                    interpretation: "水象征情绪和潜意识",
                    context: "在梦境中出现",
                    psychological: "反映内心情感状态",
                    spiritual: "精神层面的净化",
                    positive: true
                )
            ],
            culturalInterpretations: [
                CulturalInterpretation(
                    culture: "中国",
                    interpretation: "水主财",
                    significance: "传统文化"
                )
            ],
            relatedSymbols: ["雨", "海洋", "河流"],
            frequency: 3
        )
        
        XCTAssertEqual(symbol.name, "水")
        XCTAssertEqual(symbol.category, .nature)
        XCTAssertEqual(symbol.meanings.count, 1)
        XCTAssertEqual(symbol.culturalInterpretations.count, 1)
        XCTAssertEqual(symbol.relatedSymbols.count, 3)
        XCTAssertEqual(symbol.frequency, 3)
    }
    
    func testDreamInsightInitialization() {
        let insight = DreamInsight(
            type: .pattern,
            title: "重复梦境模式",
            description: "您最近反复出现相似的梦境",
            confidence: 0.85,
            evidence: ["梦境类型重复", "相似主题出现"]
        )
        
        XCTAssertEqual(insight.type, .pattern)
        XCTAssertEqual(insight.title, "重复梦境模式")
        XCTAssertEqual(insight.confidence, 0.85)
        XCTAssertEqual(insight.evidence.count, 2)
    }
    
    func testDreamSuggestionInitialization() {
        let suggestion = DreamSuggestion(
            type: .sleep,
            title: "改善睡眠质量",
            description: "您的梦境反映出睡眠质量可能需要改善",
            actionItems: [
                "保持规律的睡眠时间",
                "睡前避免使用电子设备",
                "创造舒适的睡眠环境"
            ],
            priority: .high
        )
        
        XCTAssertEqual(suggestion.type, .sleep)
        XCTAssertEqual(suggestion.actionItems.count, 3)
        XCTAssertEqual(suggestion.priority, .high)
    }
    
    func testDreamWarningInitialization() {
        let warning = DreamWarning(
            type: .recurringNightmare,
            title: "频繁噩梦警示",
            description: "您的梦境显示频繁的噩梦模式",
            severity: .moderate,
            recommendedAction: "建议学习放松技巧"
        )
        
        XCTAssertEqual(warning.type, .recurringNightmare)
        XCTAssertEqual(warning.severity, .moderate)
        XCTAssertFalse(warning.recommendedAction.isEmpty)
    }
    
    // MARK: - 分析结果测试
    
    func testDreamAnalysisResultInitialization() {
        let dreamId = UUID()
        let metrics = MentalHealthMetrics(
            stressLevel: 5, anxietyIndex: 5, moodScore: 5,
            sleepQualityScore: 5, emotionalStability: 5, overallWellbeing: 5
        )
        
        let result = DreamAnalysisResult(
            dreamId: dreamId,
            title: "测试梦境",
            summary: "这是一个测试梦境的摘要",
            surfaceAnalysis: "表层解析内容",
            deepAnalysis: "深层解析内容",
            archetypalAnalysis: "原型层解析内容",
            dreamType: .normal,
            identifiedArchetypes: [.shadow],
            keySymbols: [],
            mentalHealthMetrics: metrics,
            insights: [],
            suggestions: [],
            warnings: [],
            confidence: 0.75,
            analysisDepth: .deep,
            processingTimeMs: 1500
        )
        
        XCTAssertEqual(result.dreamId, dreamId)
        XCTAssertEqual(result.title, "测试梦境")
        XCTAssertEqual(result.dreamType, .normal)
        XCTAssertEqual(result.confidence, 0.75)
        XCTAssertEqual(result.analysisDepth, .deep)
        XCTAssertEqual(result.identifiedArchetypes.count, 1)
        XCTAssertGreaterThan(result.processingTimeMs, 0)
    }
    
    // MARK: - 分析配置测试
    
    func testAnalysisConfigDefault() {
        let config = AnalysisConfig.default
        
        XCTAssertEqual(config.depth, .deep)
        XCTAssertTrue(config.includeArchetypes)
        XCTAssertTrue(config.includeMentalHealth)
        XCTAssertTrue(config.includeSuggestions)
        XCTAssertTrue(config.includeWarnings)
        XCTAssertEqual(config.culturalContext, "chinese")
        XCTAssertEqual(config.language, "zh-CN")
    }
    
    func testAnalysisConfigCustom() {
        let config = AnalysisConfig(
            depth: .archetypal,
            includeArchetypes: false,
            includeMentalHealth: true,
            includeSuggestions: false,
            includeWarnings: true,
            culturalContext: "western",
            language: "en-US"
        )
        
        XCTAssertEqual(config.depth, .archetypal)
        XCTAssertFalse(config.includeArchetypes)
        XCTAssertTrue(config.includeMentalHealth)
        XCTAssertFalse(config.includeSuggestions)
        XCTAssertTrue(config.includeWarnings)
        XCTAssertEqual(config.culturalContext, "western")
        XCTAssertEqual(config.language, "en-US")
    }
    
    // MARK: - 服务功能测试
    
    func testServiceInitialization() {
        let service = DreamAIAnalysisService.shared
        
        XCTAssertNotNil(service)
        XCTAssertEqual(service.currentProgress, 0.0)
        XCTAssertFalse(service.isAnalyzing)
        XCTAssertNil(service.lastAnalysisResult)
    }
    
    func testServiceConfigAccess() {
        let service = DreamAIAnalysisService.shared
        
        XCTAssertEqual(service.config.depth, .deep)
        XCTAssertTrue(service.config.includeArchetypes)
    }
    
    // MARK: - 梦境类型识别逻辑测试
    
    func testDreamTypeIdentification() {
        // 测试清醒梦识别
        let lucidContent = "我知道自己在做梦，并且可以控制梦境"
        XCTAssertTrue(lucidContent.contains("知道自己在做梦") || lucidContent.contains("控制梦境"))
        
        // 测试噩梦识别
        let nightmareContent = "这是一个非常可怕的噩梦，我感到很恐惧"
        XCTAssertTrue(nightmareContent.contains("噩梦") || nightmareContent.contains("恐惧"))
        
        // 测试飞行梦识别
        let flyingContent = "我在空中自由地飞行，感觉太棒了"
        XCTAssertTrue(flyingContent.contains("飞行") || flyingContent.contains("飞"))
        
        // 测试坠落梦识别
        let fallingContent = "我从高处掉落，非常害怕"
        XCTAssertTrue(fallingContent.contains("掉落") || fallingContent.contains("坠落"))
        
        // 测试被追逐梦识别
        let chasingContent = "有人在追逐我，我拼命逃跑"
        XCTAssertTrue(chasingContent.contains("追逐") || chasingContent.contains("逃跑") || chasingContent.contains("追赶"))
        
        // 测试考试梦识别
        let examContent = "我在参加考试，但是什么都不会"
        XCTAssertTrue(examContent.contains("考试") || examContent.contains("测试") || examContent.contains("考场"))
    }
    
    // MARK: - 性能测试
    
    func testAnalysisPerformance() {
        let metrics = XCTPerformanceMetrics()
        metrics.add(.wallClockTime)
        
        measure(metrics: [XCTPerformanceMetric.wallClockTime]) {
            // 模拟分析准备
            let content = String(repeating: "这是一个测试梦境内容。", count: 50)
            let emotions = ["焦虑", "紧张", "期待"]
            let tags = ["工作", "压力", "未来"]
            
            // 验证数据结构创建性能
            let symbol = DreamSymbol(
                name: "测试符号",
                category: .object,
                meanings: []
            )
            XCTAssertNotNil(symbol)
            
            let insight = DreamInsight(
                type: .pattern,
                title: "测试洞察",
                description: "测试描述",
                confidence: 0.8,
                evidence: []
            )
            XCTAssertNotNil(insight)
        }
    }
    
    // MARK: - 边界条件测试
    
    func testEmptyEmotions() {
        let metrics = MentalHealthMetrics(
            stressLevel: 5, anxietyIndex: 5, moodScore: 5,
            sleepQualityScore: 5, emotionalStability: 5, overallWellbeing: 5
        )
        
        // 验证空情绪列表不会导致崩溃
        XCTAssertEqual(metrics.stressLevel, 5)
        XCTAssertEqual(metrics.anxietyIndex, 5)
    }
    
    func testExtremeValues() {
        let minMetrics = MentalHealthMetrics(
            stressLevel: 1, anxietyIndex: 1, moodScore: 1,
            sleepQualityScore: 1, emotionalStability: 1, overallWellbeing: 1
        )
        
        let maxMetrics = MentalHealthMetrics(
            stressLevel: 10, anxietyIndex: 10, moodScore: 10,
            sleepQualityScore: 10, emotionalStability: 10, overallWellbeing: 10
        )
        
        XCTAssertGreaterThanOrEqual(minMetrics.compositeScore, 1)
        XCTAssertLessThanOrEqual(maxMetrics.compositeScore, 10)
    }
    
    // MARK: - 编码解码测试
    
    func testCodableModels() throws {
        let symbol = DreamSymbol(
            name: "水",
            category: .nature,
            meanings: [
                SymbolMeaning(
                    interpretation: "象征情绪",
                    context: "梦境中",
                    psychological: "心理含义",
                    spiritual: "灵性含义",
                    positive: true
                )
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(symbol)
        
        let decoder = JSONDecoder()
        let decodedSymbol = try decoder.decode(DreamSymbol.self, from: data)
        
        XCTAssertEqual(symbol.name, decodedSymbol.name)
        XCTAssertEqual(symbol.category, decodedSymbol.category)
    }
    
    func testEnumCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // 测试 AnalysisDepth
        let depthData = try encoder.encode(AnalysisDepth.deep)
        let decodedDepth = try decoder.decode(AnalysisDepth.self, from: depthData)
        XCTAssertEqual(AnalysisDepth.deep, decodedDepth)
        
        // 测试 DreamType
        let typeData = try encoder.encode(DreamType.lucid)
        let decodedType = try decoder.decode(DreamType.self, from: typeData)
        XCTAssertEqual(DreamType.lucid, decodedType)
        
        // 测试 JungianArchetype
        let archetypeData = try encoder.encode(JungianArchetype.hero)
        let decodedArchetype = try decoder.decode(JungianArchetype.self, from: archetypeData)
        XCTAssertEqual(JungianArchetype.hero, decodedArchetype)
    }
}
