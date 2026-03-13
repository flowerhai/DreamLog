//
//  DreamPredictionMLTests.swift
//  DreamLogTests
//
//  AI 梦境预测 2.0 - ML 预测单元测试
//  Phase 35 - Core ML 集成与性能优化 ✨🧠
//

import XCTest
@testable import DreamLog

// MARK: - ML 预测服务测试

@MainActor
final class DreamPredictionMLTests: XCTestCase {
    
    var mlService: DreamPredictionMLService!
    var mockModelContext: MockModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        mlService = DreamPredictionMLService.shared
        mockModelContext = MockModelContext()
    }
    
    override func tearDown() async throws {
        mlService = nil
        mockModelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 配置测试
    
    /// 测试默认配置加载
    func testDefaultConfig() {
        let config = MLPredictionConfig.default
        
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.minTrainingData, 10)
        XCTAssertEqual(config.updateFrequency, 7)
        XCTAssertTrue(config.showFeatureImportance)
        XCTAssertTrue(config.includeSuggestions)
        XCTAssertTrue(config.trackAccuracy)
    }
    
    /// 测试配置保存和加载
    func testConfigPersistence() {
        // 修改配置
        var config = MLPredictionConfig.default
        config.enabled = false
        config.minTrainingData = 20
        config.modelType = .emotion
        
        // 保存配置
        UserDefaults.standard.set(try? JSONEncoder().encode(config), forKey: "mlPredictionConfig")
        
        // 加载配置
        if let data = UserDefaults.standard.data(forKey: "mlPredictionConfig"),
           let loadedConfig = try? JSONDecoder().decode(MLPredictionConfig.self, from: data) {
            XCTAssertFalse(loadedConfig.enabled)
            XCTAssertEqual(loadedConfig.minTrainingData, 20)
            XCTAssertEqual(loadedConfig.modelType, .emotion)
        } else {
            XCTFail("Failed to load config")
        }
        
        // 清理
        UserDefaults.standard.removeObject(forKey: "mlPredictionConfig")
    }
    
    // MARK: - 预测模型测试
    
    /// 测试预测类型枚举
    func testPredictionTypes() {
        let types = MLPredictionType.allCases
        
        XCTAssertEqual(types.count, 6)
        XCTAssertTrue(types.contains(.emotionTrend))
        XCTAssertTrue(types.contains(.themeEvolution))
        XCTAssertTrue(types.contains(.lucidProbability))
        XCTAssertTrue(types.contains(.clarityLevel))
        XCTAssertTrue(types.contains(.recallQuality))
        XCTAssertTrue(types.contains(.dreamFrequency))
    }
    
    /// 测试预测类型显示名称
    func testPredictionTypeDisplayNames() {
        XCTAssertEqual(MLPredictionType.emotionTrend.displayName, "情绪趋势")
        XCTAssertEqual(MLPredictionType.themeEvolution.displayName, "主题演变")
        XCTAssertEqual(MLPredictionType.lucidProbability.displayName, "清醒梦概率")
        XCTAssertEqual(MLPredictionType.clarityLevel.displayName, "清晰度")
        XCTAssertEqual(MLPredictionType.recallQuality.displayName, "回忆质量")
        XCTAssertEqual(MLPredictionType.dreamFrequency.displayName, "梦境频率")
    }
    
    /// 测试预测类型图标
    func testPredictionTypeIcons() {
        XCTAssertEqual(MLPredictionType.emotionTrend.icon, "📈")
        XCTAssertEqual(MLPredictionType.themeEvolution.icon, "🎬")
        XCTAssertEqual(MLPredictionType.lucidProbability.icon, "💡")
        XCTAssertEqual(MLPredictionType.clarityLevel.icon, "✨")
    }
    
    // MARK: - 预测结果测试
    
    /// 测试预测结果创建
    func testPredictionResultCreation() {
        let prediction = MLPredictionResult(
            type: .emotionTrend,
            confidence: 0.85,
            prediction: "情绪将趋于稳定",
            featureImportance: [
                FeatureImportance(name: "睡眠时长", importance: 0.6),
                FeatureImportance(name: "压力水平", importance: 0.4)
            ],
            suggestions: ["保持规律作息", "减少睡前刺激"],
            generatedAt: Date()
        )
        
        XCTAssertEqual(prediction.type, .emotionTrend)
        XCTAssertEqual(prediction.confidence, 0.85)
        XCTAssertEqual(prediction.prediction, "情绪将趋于稳定")
        XCTAssertEqual(prediction.featureImportance.count, 2)
        XCTAssertEqual(prediction.suggestions.count, 2)
    }
    
    /// 测试预测结果序列化
    func testPredictionResultCodable() {
        let original = MLPredictionResult(
            type: .lucidProbability,
            confidence: 0.72,
            prediction: "今晚清醒梦概率较高",
            featureImportance: [
                FeatureImportance(name: "梦境回忆", importance: 0.8)
            ],
            suggestions: ["尝试清醒梦技巧"],
            generatedAt: Date()
        )
        
        // 编码
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try? encoder.encode(original)
        XCTAssertNotNil(data)
        
        // 解码
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = data,
           let decoded = try? decoder.decode(MLPredictionResult.self, from: data) {
            XCTAssertEqual(decoded.type, original.type)
            XCTAssertEqual(decoded.confidence, original.confidence)
            XCTAssertEqual(decoded.prediction, original.prediction)
        } else {
            XCTFail("Failed to decode prediction")
        }
    }
    
    // MARK: - 特征工程测试
    
    /// 测试特征提取
    func testFeatureExtraction() {
        let extractor = FeatureExtractor()
        
        // 测试时间特征
        let timeFeatures = extractor.extractTimeFeatures(from: Date())
        XCTAssertGreaterThanOrEqual(timeFeatures.count, 3)
        
        // 测试情绪特征
        let emotionFeatures = extractor.extractEmotionFeatures(from: ["快乐", "兴奋"])
        XCTAssertGreaterThan(emotionFeatures.count, 0)
        
        // 测试内容特征
        let contentFeatures = extractor.extractContentFeatures(from: "这是一个测试梦境")
        XCTAssertGreaterThan(contentFeatures.count, 0)
    }
    
    /// 测试特征标准化
    func testFeatureNormalization() {
        let features: [Double] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let normalized = FeatureExtractor.normalize(features)
        
        XCTAssertEqual(normalized.count, features.count)
        XCTAssertTrue(normalized.allSatisfy { $0 >= 0 && $0 <= 1 })
    }
    
    // MARK: - 预测引擎测试
    
    /// 测试基于规则的预测引擎
    func testRuleBasedPrediction() {
        let engine = RuleBasedPredictionEngine()
        
        // 准备测试数据
        let dreams = createMockDreams(count: 15)
        
        // 生成预测
        let prediction = engine.predictEmotionTrend(from: dreams)
        
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThanOrEqual(prediction?.confidence ?? 0, 0)
        XCTAssertLessThanOrEqual(prediction?.confidence ?? 1, 1)
    }
    
    /// 测试情绪趋势预测
    func testEmotionTrendPrediction() {
        let engine = RuleBasedPredictionEngine()
        let dreams = createMockDreamsWithEmotions([
            .positive, .positive, .neutral,
            .positive, .positive, .positive,
            .neutral, .positive, .positive
        ])
        
        let prediction = engine.predictEmotionTrend(from: dreams)
        
        XCTAssertNotNil(prediction)
        XCTAssertTrue(prediction?.prediction.contains("积极") ?? false)
    }
    
    /// 测试清醒梦概率预测
    func testLucidProbabilityPrediction() {
        let engine = RuleBasedPredictionEngine()
        let dreams = createMockDreams(count: 20)
        
        let prediction = engine.predictLucidProbability(from: dreams)
        
        XCTAssertNotNil(prediction)
        XCTAssertGreaterThanOrEqual(prediction?.confidence ?? 0, 0)
        XCTAssertLessThanOrEqual(prediction?.confidence ?? 1, 1)
    }
    
    // MARK: - 准确度追踪测试
    
    /// 测试准确度统计初始化
    func testAccuracyStatsInitialization() {
        let stats = PredictionAccuracyStats()
        
        XCTAssertEqual(stats.totalPredictions, 0)
        XCTAssertEqual(stats.validatedPredictions, 0)
        XCTAssertEqual(stats.averageAccuracy, 0)
        XCTAssertTrue(stats.accuracyByType.isEmpty)
    }
    
    /// 测试准确度更新
    func testAccuracyUpdate() {
        var stats = PredictionAccuracyStats()
        
        // 添加预测记录
        stats.addPrediction(type: .emotionTrend, confidence: 0.8)
        XCTAssertEqual(stats.totalPredictions, 1)
        
        // 验证准确度
        stats.validatePrediction(type: .emotionTrend, accurate: true)
        XCTAssertEqual(stats.validatedPredictions, 1)
        XCTAssertEqual(stats.averageAccuracy, 1.0)
    }
    
    /// 测试准确度持久化
    func testAccuracyPersistence() {
        var stats = PredictionAccuracyStats()
        stats.addPrediction(type: .emotionTrend, confidence: 0.75)
        stats.validatePrediction(type: .emotionTrend, accurate: true)
        
        // 保存
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: "predictionAccuracyStats")
            
            // 加载
            if let data = UserDefaults.standard.data(forKey: "predictionAccuracyStats"),
               let loaded = try? JSONDecoder().decode(PredictionAccuracyStats.self, from: data) {
                XCTAssertEqual(loaded.totalPredictions, 1)
                XCTAssertEqual(loaded.validatedPredictions, 1)
            }
            
            // 清理
            UserDefaults.standard.removeObject(forKey: "predictionAccuracyStats")
        }
    }
    
    // MARK: - 模型类型测试
    
    /// 测试模型类型枚举
    func testModelTypes() {
        XCTAssertEqual(MLModelType.auto.displayName, "自动选择")
        XCTAssertEqual(MLModelType.emotion.displayName, "情绪预测")
        XCTAssertEqual(MLModelType.theme.displayName, "主题演变")
        XCTAssertEqual(MLModelType.lucid.displayName, "清醒梦概率")
    }
    
    // MARK: - 性能测试
    
    /// 测试预测生成性能
    func testPredictionGenerationPerformance() {
        measure {
            let engine = RuleBasedPredictionEngine()
            let dreams = createMockDreams(count: 50)
            _ = engine.predictEmotionTrend(from: dreams)
        }
    }
    
    /// 测试特征提取性能
    func testFeatureExtractionPerformance() {
        let extractor = FeatureExtractor()
        let text = "这是一个测试梦境，包含多个关键词和情绪描述"
        
        measure {
            _ = extractor.extractContentFeatures(from: text)
        }
    }
    
    // MARK: - 边界条件测试
    
    /// 测试数据不足时的处理
    func testInsufficientDataHandling() {
        let engine = RuleBasedPredictionEngine()
        let dreams = createMockDreams(count: 5) // 少于最小要求
        
        let prediction = engine.predictEmotionTrend(from: dreams)
        
        // 应该返回低置信度或空预测
        XCTAssertNotNil(prediction)
        XCTAssertTrue(prediction?.confidence ?? 1 < 0.5)
    }
    
    /// 测试空数据处理
    func testEmptyDataHandling() {
        let engine = RuleBasedPredictionEngine()
        let dreams: [Dream] = []
        
        let prediction = engine.predictEmotionTrend(from: dreams)
        
        XCTAssertNotNil(prediction)
        XCTAssertEqual(prediction?.confidence, 0)
    }
    
    // MARK: - 辅助方法
    
    private func createMockDreams(count: Int) -> [Dream] {
        (0..<count).map { index in
            Dream(
                title: "测试梦境 \(index)",
                content: "这是一个测试梦境内容",
                date: Date().addingTimeInterval(Double(-index) * 86400),
                emotions: [.neutral],
                tags: ["测试"]
            )
        }
    }
    
    private func createMockDreamsWithEmotions(_ emotions: [DreamEmotion]) -> [Dream] {
        zip(0..<emotions.count, emotions).map { index, emotion in
            Dream(
                title: "测试梦境 \(index)",
                content: "这是一个测试梦境内容",
                date: Date().addingTimeInterval(Double(-index) * 86400),
                emotions: [emotion],
                tags: ["测试"]
            )
        }
    }
}

// MARK: - 特征重要性测试

final class FeatureImportanceTests: XCTestCase {
    
    func testFeatureImportanceCreation() {
        let feature = FeatureImportance(name: "睡眠时长", importance: 0.75)
        
        XCTAssertEqual(feature.name, "睡眠时长")
        XCTAssertEqual(feature.importance, 0.75)
        XCTAssertTrue(feature.importance >= 0 && feature.importance <= 1)
    }
    
    func testFeatureImportanceSorting() {
        let features = [
            FeatureImportance(name: "特征 A", importance: 0.3),
            FeatureImportance(name: "特征 B", importance: 0.8),
            FeatureImportance(name: "特征 C", importance: 0.5)
        ]
        
        let sorted = features.sorted { $0.importance > $1.importance }
        
        XCTAssertEqual(sorted[0].name, "特征 B")
        XCTAssertEqual(sorted[1].name, "特征 C")
        XCTAssertEqual(sorted[2].name, "特征 A")
    }
}

// MARK: - ML 预测配置测试

final class MLPredictionConfigTests: XCTestCase {
    
    func testConfigEncoding() {
        let config = MLPredictionConfig(
            enabled: true,
            minTrainingData: 15,
            updateFrequency: 14,
            modelType: .theme,
            showFeatureImportance: false,
            includeSuggestions: true,
            trackAccuracy: true
        )
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(config)
        XCTAssertNotNil(data)
    }
    
    func testConfigDecoding() {
        let jsonData = """
        {
            "enabled": false,
            "minTrainingData": 25,
            "updateFrequency": 30,
            "modelType": "lucid",
            "showFeatureImportance": true,
            "includeSuggestions": false,
            "trackAccuracy": true
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let config = try? decoder.decode(MLPredictionConfig.self, from: jsonData)
        
        XCTAssertNotNil(config)
        XCTAssertFalse(config?.enabled ?? true)
        XCTAssertEqual(config?.minTrainingData, 25)
        XCTAssertEqual(config?.modelType, .lucid)
    }
}

// MARK: - 预测准确度统计测试

final class PredictionAccuracyStatsTests: XCTestCase {
    
    func testStatsCalculation() {
        var stats = PredictionAccuracyStats()
        
        // 添加 10 个预测
        for _ in 0..<10 {
            stats.addPrediction(type: .emotionTrend, confidence: 0.8)
        }
        
        XCTAssertEqual(stats.totalPredictions, 10)
        
        // 验证 8 个准确，2 个不准确
        for _ in 0..<8 {
            stats.validatePrediction(type: .emotionTrend, accurate: true)
        }
        for _ in 0..<2 {
            stats.validatePrediction(type: .emotionTrend, accurate: false)
        }
        
        XCTAssertEqual(stats.validatedPredictions, 10)
        XCTAssertEqual(stats.averageAccuracy, 0.8, accuracy: 0.01)
    }
    
    func testStatsByType() {
        var stats = PredictionAccuracyStats()
        
        // 添加不同类型的预测
        stats.addPrediction(type: .emotionTrend, confidence: 0.7)
        stats.addPrediction(type: .lucidProbability, confidence: 0.8)
        stats.addPrediction(type: .themeEvolution, confidence: 0.9)
        
        // 验证
        stats.validatePrediction(type: .emotionTrend, accurate: true)
        stats.validatePrediction(type: .lucidProbability, accurate: true)
        stats.validatePrediction(type: .themeEvolution, accurate: false)
        
        XCTAssertEqual(stats.accuracyByType[.emotionTrend], 1.0)
        XCTAssertEqual(stats.accuracyByType[.lucidProbability], 1.0)
        XCTAssertEqual(stats.accuracyByType[.themeEvolution], 0.0)
    }
}

// MARK: - Mock 对象

@MainActor
final class MockModelContext {
    // Mock 实现用于测试
}

// MARK: - 预览提供者测试

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 17.0, *)
#Preview("ML 预测视图") {
    DreamPredictionMLView()
}

@available(iOS 17.0, *)
#Preview("ML 预测配置") {
    MLPredictionConfigView()
}

@available(iOS 17.0, *)
#Preview("准确度详情") {
    PredictionAccuracyDetailView()
}
#endif
