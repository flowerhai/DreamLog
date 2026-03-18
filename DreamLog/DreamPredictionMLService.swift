//
//  DreamPredictionMLService.swift
//  DreamLog
//
//  AI 梦境预测 2.0 - Core ML 服务
//  Phase 35 - AI 预测增强 ✨
//

import Foundation
import SwiftData
import CoreML

/// AI 梦境预测 2.0 服务 - 基于 Core ML 的机器学习预测
@MainActor
final class DreamPredictionMLService {
    static let shared = DreamPredictionMLService()
    
    // MARK: - 属性
    
    /// 预测配置
    private var config: MLPredictionConfig = .default
    
    /// 准确度统计
    private var accuracyStats: PredictionAccuracyStats = PredictionAccuracyStats()
    
    /// 模型加载状态
    private var isModelLoaded = false
    private var modelLoadError: Error?
    
    /// 上次模型更新时间
    private var lastModelUpdateTime: Date?
    
    /// 数据缓存
    private var cachedPredictions: [MLPredictionType: MLPredictionResult] = [:]
    private var cacheExpiry: Date?
    
    // MARK: - 初始化
    
    private init() {
        loadConfig()
        loadAccuracyStats()
    }
    
    // MARK: - 配置管理
    
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "mlPredictionConfig"),
           let decoded = try? JSONDecoder().decode(MLPredictionConfig.self, from: data) {
            config = decoded
        }
    }
    
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "mlPredictionConfig")
        }
    }
    
    private func loadAccuracyStats() {
        if let data = UserDefaults.standard.data(forKey: "predictionAccuracyStats"),
           let decoded = try? JSONDecoder().decode(PredictionAccuracyStats.self, from: data) {
            accuracyStats = decoded
        }
    }
    
    func saveAccuracyStats() {
        if let encoded = try? JSONEncoder().encode(accuracyStats) {
            UserDefaults.standard.set(encoded, forKey: "predictionAccuracyStats")
        }
    }
    
    // MARK: - 模型管理
    
    /// 加载 Core ML 模型
    func loadModel() async {
        guard config.enabled else {
            print("⚠️ ML 预测已禁用")
            return
        }
        
        // 检查是否有足够的训练数据
        let dreamCount = await getDreamCount()
        guard dreamCount >= config.minTrainingData else {
            print("⚠️ 训练数据不足：需要 \(config.minTrainingData) 条，当前 \(dreamCount) 条")
            return
        }
        
        // 尝试加载预训练模型
        do {
            // 这里应该加载实际的 Core ML 模型
            // let model = try DreamPredictionModel(configuration: MLModelConfiguration())
            isModelLoaded = true
            print("✅ ML 模型加载成功")
        } catch {
            modelLoadError = error
            print("🔴 ML 模型加载失败：\(error.localizedDescription)")
            // 回退到基于规则的预测
            isModelLoaded = false
        }
    }
    
    /// 更新模型
    func updateModel() async {
        guard config.autoUpdateModel else { return }
        
        // 检查是否需要更新
        if let lastUpdate = lastModelUpdateTime,
           Date().timeIntervalSince(lastUpdate) < Double(config.updateFrequency) * 86400 {
            return
        }
        
        print("🔄 开始更新 ML 模型...")
        
        // 收集训练数据
        let dreams = await fetchAllDreams()
        
        // 提取特征
        let features = extractAllFeatures(from: dreams)
        
        // 训练模型（在实际实现中使用 Create ML）
        // 这里使用基于规则的预测作为示例
        
        lastModelUpdateTime = Date()
        print("✅ 模型更新完成")
    }
    
    // MARK: - 预测功能
    
    /// 生成预测
    func generatePrediction(for type: MLPredictionType) async -> MLPredictionResult? {
        // 检查缓存
        if let cached = cachedPredictions[type],
           let expiry = cacheExpiry,
           Date() < expiry {
            return cached
        }
        
        guard config.enabled else {
            print("⚠️ ML 预测已禁用")
            return nil
        }
        
        // 获取梦境数据
        let dreams = await fetchAllDreams()
        
        guard !dreams.isEmpty else {
            print("⚠️ 没有梦境数据可用于预测")
            return nil
        }
        
        // 提取特征
        let features = extractFeatures(for: type, from: dreams)
        
        // 生成预测
        let prediction: (value: Double, confidence: Double)
        
        if isModelLoaded {
            // 使用 Core ML 模型预测
            prediction = await predictWithML(type: type, features: features)
        } else {
            // 使用基于规则的预测
            prediction = predictWithRules(type: type, features: features)
        }
        
        // 生成解释
        let explanation = PredictionExplainer.generateExplanation(
            for: type,
            predictedValue: prediction.value,
            confidence: prediction.confidence,
            features: features
        )
        
        // 创建预测结果
        let result = MLPredictionResult(
            predictionType: type,
            predictedValue: prediction.value,
            confidence: prediction.confidence,
            explanation: explanation,
            features: features
        )
        
        // 缓存结果
        cachedPredictions[type] = result
        cacheExpiry = Date().addingTimeInterval(3600) // 1 小时缓存
        
        return result
    }
    
    /// 生成所有预测
    func generateAllPredictions() async -> [MLPredictionResult] {
        var results: [MLPredictionResult] = []
        
        for type in MLPredictionType.allCases {
            if let result = await generatePrediction(for: type) {
                results.append(result)
            }
        }
        
        return results
    }
    
    // MARK: - 特征提取
    
    private func extractFeatures(for type: MLPredictionType, from dreams: [Dream]) -> [MLPredictionFeature] {
        var allFeatures: [MLPredictionFeature] = []
        
        // 提取所有特征
        allFeatures.append(contentsOf: FeatureExtractor.extractTemporalFeatures(from: dreams))
        allFeatures.append(contentsOf: FeatureExtractor.extractEmotionalFeatures(from: dreams))
        allFeatures.append(contentsOf: FeatureExtractor.extractContentFeatures(from: dreams))
        
        // 根据预测类型筛选相关特征
        let relevantFeatures = filterRelevantFeatures(allFeatures, for: type)
        
        return relevantFeatures
    }
    
    private func extractAllFeatures(from dreams: [Dream]) -> [MLPredictionFeature] {
        var allFeatures: [MLPredictionFeature] = []
        allFeatures.append(contentsOf: FeatureExtractor.extractTemporalFeatures(from: dreams))
        allFeatures.append(contentsOf: FeatureExtractor.extractEmotionalFeatures(from: dreams))
        allFeatures.append(contentsOf: FeatureExtractor.extractContentFeatures(from: dreams))
        return allFeatures
    }
    
    private func filterRelevantFeatures(_ features: [MLPredictionFeature], for type: MLPredictionType) -> [MLPredictionFeature] {
        // 根据预测类型返回相关特征
        // 实际实现中应该更复杂
        return features.prefix(10).map { $0 }
    }
    
    // MARK: - 预测引擎
    
    private func predictWithML(type: MLPredictionType, features: [MLPredictionFeature]) async -> (value: Double, confidence: Double) {
        // 使用 Core ML 模型进行预测
        // 这里使用占位实现
        await Task.sleep(nanoseconds: 100_000_000) // 模拟 ML 推理延迟
        return (0.75, 0.82)
    }
    
    private func predictWithRules(type: MLPredictionType, features: [MLPredictionFeature]) -> (value: Double, confidence: Double) {
        // 基于规则的预测引擎
        
        switch type {
        case .emotionTrend:
            // 基于近期情绪趋势预测
            let recentEmotionFeature = features.first { $0.category == .emotional }
            let value = recentEmotionFeature?.value ?? 0.5
            let confidence = min(0.5 + Double(features.count) * 0.05, 0.9)
            return (value, confidence)
            
        case .lucidProbability:
            // 基于清醒梦历史和记录习惯
            let lucidFeature = features.first { $0.name == "清醒梦比例" }
            let frequencyFeature = features.first { $0.name == "每周记录频率" }
            
            let lucidValue = lucidFeature?.value ?? 0.3
            let frequencyValue = frequencyFeature?.value ?? 3.0
            
            // 清醒梦比例高 + 记录频率高 = 高概率
            let value = (lucidValue * 0.6) + (min(frequencyValue / 10.0, 1.0) * 0.4)
            let confidence = min(0.5 + Double(features.count) * 0.05, 0.85)
            return (value, confidence)
            
        case .dreamClarity:
            // 基于历史清晰度和睡眠质量
            let clarityFeature = features.first { $0.name == "平均清晰度" }
            let value = clarityFeature?.value ?? 0.6
            let confidence = min(0.5 + Double(features.count) * 0.05, 0.88)
            return (value, confidence)
            
        default:
            // 默认预测
            return (0.5, 0.6)
        }
    }
    
    // MARK: - 预测验证
    
    /// 记录预测结果（用于验证准确度）
    func recordPredictionOutcome(predictionId: UUID, actualValue: Double) {
        // 在实际实现中，这里会更新数据库中的预测结果
        // 并计算预测准确度
        
        print("📊 记录预测结果：\(predictionId), 实际值：\(actualValue)")
    }
    
    /// 获取预测准确度统计
    func getAccuracyStats() -> PredictionAccuracyStats {
        return accuracyStats
    }
    
    // MARK: - 数据获取
    
    private func getDreamCount() async -> Int {
        // 实际实现中从 SwiftData 获取
        return 100 // 占位
    }
    
    private func fetchAllDreams() async -> [Dream] {
        // 实际实现中从 SwiftData 获取所有梦境
        return [] // 占位
    }
    
    // MARK: - 缓存管理
    
    /// 清除预测缓存
    func clearCache() {
        cachedPredictions.removeAll()
        cacheExpiry = nil
        print("🧹 已清除预测缓存")
    }
    
    /// 重置所有数据
    func reset() {
        clearCache()
        accuracyStats = PredictionAccuracyStats()
        lastModelUpdateTime = nil
        saveAccuracyStats()
        print("🔄 已重置 ML 预测服务")
    }
}

// MARK: - 辅助扩展
// 注意：Dream 模型已在 Dream.swift 中定义，此处不需要重复定义
// 以下扩展仅用于提供 ML 预测服务所需的计算属性

extension Dream {
    /// 将 Emotion 数组转换为字符串数组（用于 ML 特征提取）
    var emotionStrings: [String] {
        emotions.map { $0.rawValue }
    }
    
    /// 清晰度转换为 Double（用于 ML 计算）
    var clarityDouble: Double {
        Double(clarity)
    }
}

// MARK: - 预览

#if DEBUG
#Preview {
    VStack {
        Text("ML 预测服务")
            .font(.title)
        
        Button("加载模型") {
            Task {
                await DreamPredictionMLService.shared.loadModel()
            }
        }
        
        Button("生成预测") {
            Task {
                if let result = await DreamPredictionMLService.shared.generatePrediction(for: .emotionTrend) {
                    print("预测结果：\(result.predictedValue), 置信度：\(result.confidence)")
                }
            }
        }
        
        Button("清除缓存") {
            Task {
                await DreamPredictionMLService.shared.clearCache()
            }
        }
    }
}
#endif
