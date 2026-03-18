//
//  DreamAIAnalysisTests.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  单元测试
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Testing
import Foundation
import SwiftData
@testable import DreamLog

// MARK: - DreamAIAnalysisService 测试

@Suite("DreamAIAnalysisService Tests")
struct DreamAIAnalysisServiceTests {
    
    var service: DreamAIAnalysisService!
    var modelContext: ModelContext!
    
    init() async throws {
        // 创建内存中的 ModelContainer
        let container = try ModelContainer(
            for: DreamEntry.self, DreamAnalysis.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        self.modelContext = ModelContext(container)
        self.service = DreamAIAnalysisService(modelContext: modelContext)
    }
    
    @Test("分析简单梦境")
    func analyzeSimpleDream() async throws {
        // 创建测试梦境
        let dream = DreamEntry(
            title: "飞行的梦",
            content: "我在天空中自由飞翔，感觉非常快乐和解放。",
            date: Date(),
            emotions: [.joy, .excitement],
            tags: ["飞行", "自由"],
            clarity: 4,
            intensity: 4,
            isLucid: false
        )
        
        // 执行分析
        let analysis = await service.analyzeDream(dream)
        
        // 验证结果
        #expect(analysis.dreamId == dream.id)
        #expect(analysis.confidence >= 0.5)
        #expect(analysis.confidence <= 1.0)
        #expect(!analysis.symbols.isEmpty)
        #expect(!analysis.surfaceLayer.content.isEmpty)
        #expect(!analysis.psychologicalLayer.content.isEmpty)
        #expect(!analysis.spiritualLayer.content.isEmpty)
    }
    
    @Test("分析包含历史梦境")
    func analyzeDreamWithHistory() async throws {
        // 创建历史梦境
        let historicalDreams: [DreamEntry] = [
            DreamEntry(
                title: "梦境 1",
                content: "我梦见了水，大海很平静。",
                date: Date().addingTimeInterval(-86400 * 7),
                emotions: [.calm],
                tags: ["水", "海"],
                clarity: 3,
                intensity: 3
            ),
            DreamEntry(
                title: "梦境 2",
                content: "又梦见了水，这次是河流。",
                date: Date().addingTimeInterval(-86400 * 3),
                emotions: [.curiosity],
                tags: ["水", "河"],
                clarity: 4,
                intensity: 3
            )
        ]
        
        // 创建当前梦境
        let currentDream = DreamEntry(
            title: "再次梦见水",
            content: "我在河边散步，水流很清澈。",
            date: Date(),
            emotions: [.calm, .joy],
            tags: ["水", "河"],
            clarity: 4,
            intensity: 3
        )
        
        // 执行分析
        let analysis = await service.analyzeDream(currentDream, historicalDreams: historicalDreams)
        
        // 验证识别了重复符号
        #expect(analysis.patterns.contains { $0.type == .recurringSymbol })
        
        // 验证有趋势预测
        #expect(analysis.trendPrediction != nil)
    }
    
    @Test("保存分析结果")
    func saveAnalysis() async throws {
        let dream = DreamEntry(
            title: "测试梦境",
            content: "测试内容",
            date: Date(),
            emotions: [.neutral],
            tags: ["测试"],
            clarity: 3,
            intensity: 3
        )
        
        // 创建梦境到模型上下文
        modelContext.insert(dream)
        try modelContext.save()
        
        // 执行分析并保存
        let analysis = await service.analyzeDream(dream)
        try await service.saveAnalysis(analysis)
        
        // 验证保存成功
        let descriptor = FetchDescriptor<DreamAnalysis>()
        let savedAnalyses = try modelContext.fetch(descriptor)
        #expect(savedAnalyses.count == 1)
        #expect(savedAnalyses.first?.dreamId == dream.id)
    }
    
    @Test("获取梦境分析历史")
    func getAnalysisHistory() async throws {
        let dream = DreamEntry(
            title: "测试梦境",
            content: "测试内容",
            date: Date(),
            emotions: [.neutral],
            tags: ["测试"],
            clarity: 3,
            intensity: 3
        )
        
        modelContext.insert(dream)
        try modelContext.save()
        
        // 创建并保存分析
        let analysis = await service.analyzeDream(dream)
        try await service.saveAnalysis(analysis)
        
        // 获取分析历史
        let history = await service.getAnalysisHistory(for: dream.id)
        #expect(!history.isEmpty)
    }
}

// MARK: - DreamInsightGenerator 测试

@Suite("DreamInsightGenerator Tests")
struct DreamInsightGeneratorTests {
    
    var generator: DreamInsightGenerator!
    
    init() async throws {
        self.generator = DreamInsightGenerator()
    }
    
    @Test("生成洞察")
    func generateInsights() async throws {
        let dream = DreamEntry(
            title: "飞行的梦",
            content: "我在天空中飞翔，感觉很自由。",
            date: Date(),
            emotions: [.joy],
            tags: ["飞行"],
            clarity: 4,
            intensity: 4
        )
        
        let analysis = await generator.generateAnalysis(for: dream)
        
        #expect(!analysis.insights.isEmpty)
        #expect(!analysis.suggestions.isEmpty)
    }
    
    @Test("生成符号洞察")
    func generateSymbolInsight() async throws {
        let insight = await generator.generateSymbolInsight(symbol: "水")
        
        #expect(insight.symbol == "水")
        #expect(!insight.surfaceMeaning.isEmpty)
    }
    
    @Test("置信度计算合理")
    func confidenceCalculation() async throws {
        let dream = DreamEntry(
            title: "详细梦境",
            content: String(repeating: "这是一个非常详细的梦境描述。", count: 20),
            date: Date(),
            emotions: [.joy, .excitement],
            tags: ["测试", "详细", "梦境"],
            clarity: 5,
            intensity: 5
        )
        
        let analysis = await generator.generateAnalysis(for: dream)
        
        // 详细内容应该有较高置信度
        #expect(analysis.confidence >= 0.6)
    }
}

// MARK: - DreamPatternRecognition 测试

@Suite("DreamPatternRecognition Tests")
struct DreamPatternRecognitionTests {
    
    var recognition: DreamPatternRecognition!
    
    init() async throws {
        self.recognition = DreamPatternRecognition()
    }
    
    @Test("识别重复符号")
    func findRecurringSymbols() async throws {
        let dreams: [DreamEntry] = [
            DreamEntry(
                title: "梦境 1",
                content: "我梦见了蛇，一条大蛇。",
                date: Date().addingTimeInterval(-86400 * 10),
                emotions: [.fear],
                tags: ["蛇"],
                clarity: 3,
                intensity: 4
            ),
            DreamEntry(
                title: "梦境 2",
                content: "又梦见了蛇，这次是小蛇。",
                date: Date().addingTimeInterval(-86400 * 5),
                emotions: [.curiosity],
                tags: ["蛇"],
                clarity: 4,
                intensity: 3
            ),
            DreamEntry(
                title: "梦境 3",
                content: "蛇出现在梦里，在草地上。",
                date: Date(),
                emotions: [.neutral],
                tags: ["蛇", "草地"],
                clarity: 3,
                intensity: 3
            )
        ]
        
        let recurringSymbols = await recognition.findRecurringSymbols(in: dreams, minOccurrences: 2)
        
        #expect(recurringSymbols.contains { $0.key == "蛇" })
    }
    
    @Test("检测情绪模式")
    func detectEmotionPatterns() async throws {
        let dreams: [DreamEntry] = [
            DreamEntry(
                title: "梦境 1",
                content: "可怕的梦",
                date: Date().addingTimeInterval(-86400 * 7),
                emotions: [.fear, .anxiety],
                tags: [],
                clarity: 3,
                intensity: 5
            ),
            DreamEntry(
                title: "梦境 2",
                content: "还是很害怕",
                date: Date().addingTimeInterval(-86400 * 3),
                emotions: [.fear],
                tags: [],
                clarity: 3,
                intensity: 4
            ),
            DreamEntry(
                title: "梦境 3",
                content: "感觉好多了",
                date: Date(),
                emotions: [.calm],
                tags: [],
                clarity: 4,
                intensity: 2
            )
        ]
        
        let patterns = await recognition.detectEmotionPatterns(in: dreams)
        
        #expect(!patterns.isEmpty)
    }
    
    @Test("检测主题模式")
    func detectThemePatterns() async throws {
        let dreams: [DreamEntry] = [
            DreamEntry(
                title: "被追赶",
                content: "有人在追我，我拼命逃跑。",
                date: Date().addingTimeInterval(-86400 * 7),
                emotions: [.fear],
                tags: ["追赶", "逃跑"],
                clarity: 4,
                intensity: 5
            ),
            DreamEntry(
                title: "逃跑",
                content: "我又在逃跑，这次是从怪物那里。",
                date: Date(),
                emotions: [.fear, .anxiety],
                tags: ["逃跑", "怪物"],
                clarity: 4,
                intensity: 5
            )
        ]
        
        let patterns = await recognition.detectThemePatterns(in: dreams)
        
        #expect(!patterns.isEmpty)
    }
    
    @Test("计算梦境相似度")
    func calculateSimilarity() async throws {
        let dream1 = DreamEntry(
            title: "海边的梦",
            content: "我在海边散步，海水很蓝。",
            date: Date(),
            emotions: [.calm],
            tags: ["海", "水"],
            clarity: 4,
            intensity: 3
        )
        
        let dream2 = DreamEntry(
            title: "海边的梦 2",
            content: "在海边看日落，很美。",
            date: Date(),
            emotions: [.calm, .joy],
            tags: ["海", "日落"],
            clarity: 4,
            intensity: 3
        )
        
        let dream3 = DreamEntry(
            title: "考试的梦",
            content: "我在参加考试，很紧张。",
            date: Date(),
            emotions: [.anxiety],
            tags: ["考试", "紧张"],
            clarity: 3,
            intensity: 4
        )
        
        let similarity12 = await recognition.calculateSimilarity(between: dream1, and: dream2)
        let similarity13 = await recognition.calculateSimilarity(between: dream1, and: dream3)
        
        // dream1 和 dream2 应该更相似（都有海）
        #expect(similarity12 > similarity13)
    }
}

// MARK: - DreamSymbolDictionary 测试

@Suite("DreamSymbolDictionary Tests")
struct DreamSymbolDictionaryTests {
    
    var dictionary: DreamSymbolDictionary!
    
    init() async throws {
        self.dictionary = DreamSymbolDictionary()
    }
    
    @Test("查找常见符号")
    func lookupCommonSymbols() async throws {
        let commonSymbols = ["水", "火", "飞", "蛇", "家", "学校"]
        
        for symbol in commonSymbols {
            let result = await dictionary.lookupSymbol(symbol)
            #expect(result != nil, "符号 '\(symbol)' 应该存在于词典中")
            #expect(result?.name == symbol)
        }
    }
    
    @Test("符号有三层级解读")
    func symbolHasThreeLayers() async throws {
        let symbol = await dictionary.lookupSymbol("水")
        
        #expect(symbol != nil)
        #expect(!symbol!.surfaceMeaning.isEmpty)
        #expect(!symbol!.psychologicalMeaning.isEmpty)
        #expect(!symbol!.spiritualMeaning.isEmpty)
    }
    
    @Test("符号有文化解读")
    func symbolHasCulturalInterpretations() async throws {
        let symbol = await dictionary.lookupSymbol("龙")
        
        #expect(symbol != nil)
        // 龙应该有中西方文化解读
        #expect(!symbol!.culturalInterpretations.isEmpty)
    }
    
    @Test("符号有相关符号")
    func symbolHasRelatedSymbols() async throws {
        let symbol = await dictionary.lookupSymbol("水")
        
        #expect(symbol != nil)
        #expect(!symbol!.relatedSymbols.isEmpty)
    }
    
    @Test("获取所有符号")
    func getAllSymbols() async throws {
        let allSymbols = await dictionary.getAllSymbols()
        
        #expect(allSymbols.count >= 100) // 至少有 100 个符号
    }
    
    @Test("搜索符号")
    func searchSymbols() async throws {
        let results = await dictionary.searchSymbols(query: "水")
        
        #expect(!results.isEmpty)
        #expect(results.contains { $0.name.contains("水") })
    }
    
    @Test("按分类过滤符号")
    func filterSymbolsByCategory() async throws {
        let natureSymbols = await dictionary.getSymbols(in: .nature)
        
        #expect(!natureSymbols.isEmpty)
        #expect(natureSymbols.allSatisfy { $0.category == .nature })
    }
}

// MARK: - DreamAnalysis 模型测试

@Suite("DreamAnalysis Model Tests")
struct DreamAnalysisModelTests {
    
    @Test("创建分析模型")
    func createAnalysisModel() {
        let surfaceLayer = AnalysisLayerContent(
            title: "表面层",
            content: "表面内容",
            keyPoints: ["点 1", "点 2"],
            confidence: 0.9
        )
        
        let psychologicalLayer = AnalysisLayerContent(
            title: "心理层",
            content: "心理内容",
            keyPoints: ["点 1"],
            confidence: 0.75
        )
        
        let spiritualLayer = AnalysisLayerContent(
            title: "精神层",
            content: "精神内容",
            keyPoints: ["点 1"],
            confidence: 0.65
        )
        
        let analysis = DreamAnalysis(
            dreamId: UUID(),
            surfaceLayer: surfaceLayer,
            psychologicalLayer: psychologicalLayer,
            spiritualLayer: spiritualLayer
        )
        
        #expect(analysis.id != UUID())
        #expect(analysis.version == "1.0")
        #expect(analysis.language == "zh-CN")
        #expect(analysis.confidence >= 0.0)
        #expect(analysis.confidence <= 1.0)
    }
    
    @Test("分析模型包含符号")
    func analysisWithSymbols() {
        let symbol = DreamSymbolAnalysis(
            symbol: "fly",
            name: "飞行",
            category: .action,
            surfaceMeaning: "在空中移动",
            psychologicalMeaning: "渴望自由",
            spiritualMeaning: "精神提升",
            emotionalTone: "joy",
            prominence: 0.8,
            recurring: true
        )
        
        let analysis = DreamAnalysis(
            dreamId: UUID(),
            surfaceLayer: AnalysisLayerContent(title: "", content: "", keyPoints: [], confidence: 0.8),
            psychologicalLayer: AnalysisLayerContent(title: "", content: "", keyPoints: [], confidence: 0.7),
            spiritualLayer: AnalysisLayerContent(title: "", content: "", keyPoints: [], confidence: 0.6),
            symbols: [symbol]
        )
        
        #expect(analysis.symbols.count == 1)
        #expect(analysis.symbols.first?.name == "飞行")
        #expect(analysis.symbols.first?.recurring == true)
    }
}

// MARK: - 辅助测试
    
@Suite("DreamAIAnalysis Helpers")
struct DreamAIAnalysisHelpers {
    
    @Test("趋势方向枚举")
    func trendDirectionEnum() {
        let directions: [TrendDirection] = [.increasing, .decreasing, .stable]
        #expect(directions.count == 3)
    }
    
    @Test("符号分类枚举")
    func symbolCategoryEnum() {
        let categories: [SymbolCategory] = [
            .person, .place, .object, .action,
            .emotion, .nature, .animal, .other
        ]
        #expect(categories.count == 8)
    }
    
    @Test("洞察类型枚举")
    func insightTypeEnum() {
        let types: [InsightType] = [
            .symbolDiscovery, .patternRecognition,
            .trendAwareness, .lucidOpportunity, .emotionalInsight
        ]
        #expect(types.count == 5)
    }
    
    @Test("建议分类枚举")
    func suggestionCategoryEnum() {
        let categories: [SuggestionCategory] = [
            .recording, .meditation, .creative,
            .sleep, .selfExploration, .lifestyle
        ]
        #expect(categories.count == 6)
    }
}
