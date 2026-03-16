//
//  DreamPredictionMLModels.swift
//  DreamLog
//
//  AI 梦境预测 2.0 - 机器学习数据模型
//  Phase 35 - AI 预测增强 ✨
//

import Foundation
import SwiftData

// MARK: - 预测模型数据

/// ML 预测结果
@Model
final class MLPredictionResult {
    var id: UUID
    var predictionDate: Date
    var predictionType: MLPredictionType
    var predictedValue: Double
    var confidence: Double
    var explanation: String
    var actualValue: Double? // 用于验证预测准确度
    var isAccurate: Bool? // 预测是否准确
    
    @Relationship(deleteRule: .cascade)
    var features: [MLPredictionFeature]
    
    init(
        id: UUID = UUID(),
        predictionDate: Date = Date(),
        predictionType: MLPredictionType,
        predictedValue: Double,
        confidence: Double,
        explanation: String,
        features: [MLPredictionFeature] = []
    ) {
        self.id = id
        self.predictionDate = predictionDate
        self.predictionType = predictionType
        self.predictedValue = predictedValue
        self.confidence = confidence
        self.explanation = explanation
        self.features = features
    }
}

/// ML 预测特征
@Model
final class MLPredictionFeature {
    var id: UUID
    var name: String
    var value: Double
    var weight: Double // 特征权重
    var category: FeatureCategory
    
    enum FeatureCategory: String, Codable, CaseIterable {
        case temporal = "时间特征"
        case emotional = "情绪特征"
        case content = "内容特征"
        case behavioral = "行为特征"
        case environmental = "环境特征"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        value: Double,
        weight: Double,
        category: FeatureCategory
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.weight = weight
        self.category = category
    }
}

// MARK: - 预测类型

/// ML 预测类型
enum MLPredictionType: String, Codable, CaseIterable {
    case emotionTrend = "情绪趋势"
    case lucidProbability = "清醒梦概率"
    case dreamClarity = "梦境清晰度"
    case themeEvolution = "主题演变"
    case recallQuality = "回忆质量"
    case sleepQuality = "睡眠质量"
    
    var displayName: String {
        rawValue
    }
    
    var icon: String {
        switch self {
        case .emotionTrend: return "heart.fill"
        case .lucidProbability: return "brain.head.profile"
        case .dreamClarity: return "eye.fill"
        case .themeEvolution: return "chart.line.uptrend.xyaxis"
        case .recallQuality: return "memorychip"
        case .sleepQuality: return "moon.stars.fill"
        }
    }
    
    var description: String {
        switch self {
        case .emotionTrend:
            return "预测未来 7 天的情绪趋势变化"
        case .lucidProbability:
            return "预测未来做清醒梦的概率"
        case .dreamClarity:
            return "预测未来梦境的清晰度"
        case .themeEvolution:
            return "预测梦境主题的演变方向"
        case .recallQuality:
            return "预测梦境回忆的质量"
        case .sleepQuality:
            return "预测睡眠质量评分"
        }
    }
}

// MARK: - 模型类型

/// ML 模型类型
enum MLModelType: String, Codable, CaseIterable {
    case auto = "auto"
    case emotion = "emotion"
    case theme = "theme"
    case lucid = "lucid"
    
    var displayName: String {
        switch self {
        case .auto: return "自动选择"
        case .emotion: return "情绪预测"
        case .theme: return "主题演变"
        case .lucid: return "清醒梦概率"
        }
    }
}

// MARK: - 预测配置

/// ML 预测配置
struct MLPredictionConfig: Codable {
    /// 是否启用 ML 预测
    var enabled: Bool = true
    /// 预测时间范围（天数）
    var predictionHorizon: Int = 7
    /// 最小训练数据量（梦境数量）
    var minTrainingData: Int = 10
    /// 模型自动更新
    var autoUpdateModel: Bool = true
    /// 更新频率（天）
    var updateFrequency: Int = 7
    /// 置信度阈值
    var confidenceThreshold: Double = 0.6
    /// 使用本地 Core ML 模型
    var useLocalModel: Bool = true
    /// 预测模型类型
    var modelType: MLModelType = .auto
    /// 显示特征重要性
    var showFeatureImportance: Bool = true
    /// 包含个性化建议
    var includeSuggestions: Bool = true
    /// 追踪预测准确度
    var trackAccuracy: Bool = true
    
    static let `default` = MLPredictionConfig()
}

// MARK: - 预测准确度追踪

/// 预测准确度统计
struct PredictionAccuracyStats: Codable {
    /// 总预测次数
    var totalPredictions: Int = 0
    /// 准确预测次数
    var accuratePredictions: Int = 0
    /// 按预测类型统计
    var accuracyByType: [String: TypeAccuracy] = [:]
    
    struct TypeAccuracy: Codable {
        var total: Int = 0
        var accurate: Int = 0
        var accuracy: Double {
            guard total > 0 else { return 0 }
            return Double(accurate) / Double(total) * 100
        }
    }
    
    /// 总体准确率
    var overallAccuracy: Double {
        guard totalPredictions > 0 else { return 0 }
        return Double(accuratePredictions) / Double(totalPredictions) * 100
    }
    
    /// 记录预测结果
    mutating func recordPrediction(type: MLPredictionType, isAccurate: Bool) {
        totalPredictions += 1
        if isAccurate {
            accuratePredictions += 1
        }
        
        if accuracyByType[type.rawValue] == nil {
            accuracyByType[type.rawValue] = TypeAccuracy()
        }
        accuracyByType[type.rawValue]?.total += 1
        if isAccurate {
            accuracyByType[type.rawValue]?.accurate += 1
        }
    }
}

// MARK: - 特征工程

/// 特征提取器
struct FeatureExtractor {
    /// 提取时间特征
    static func extractTemporalFeatures(from dreams: [Dream]) -> [MLPredictionFeature] {
        var features: [MLPredictionFeature] = []
        
        // 平均记录间隔（天）
        if dreams.count > 1 {
            let sortedDreams = dreams.sorted { $0.date < $1.date }
            var totalInterval: TimeInterval = 0
            for i in 1..<sortedDreams.count {
                totalInterval += sortedDreams[i].date.timeIntervalSince(sortedDreams[i-1].date)
            }
            let avgInterval = totalInterval / Double(sortedDreams.count - 1) / 86400 // 转换为天
            
            features.append(MLPredictionFeature(
                name: "平均记录间隔",
                value: avgInterval,
                weight: 0.3,
                category: .temporal
            ))
        }
        
        // 记录频率（每周）
        if let earliest = dreams.min(by: { $0.date < $1.date })?.date {
            let daysSinceFirst = Date().timeIntervalSince(earliest) / 86400
            let weeklyFrequency = Double(dreams.count) / (daysSinceFirst / 7)
            
            features.append(MLPredictionFeature(
                name: "每周记录频率",
                value: weeklyFrequency,
                weight: 0.4,
                category: .temporal
            ))
        }
        
        // 最近活跃度（近 7 天记录数）
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 86400)
        let recentCount = dreams.filter { $0.date >= sevenDaysAgo }.count
        
        features.append(MLPredictionFeature(
            name: "近 7 天活跃度",
            value: Double(recentCount),
            weight: 0.5,
            category: .temporal
        ))
        
        return features
    }
    
    /// 提取情绪特征
    static func extractEmotionalFeatures(from dreams: [Dream]) -> [MLPredictionFeature] {
        var features: [MLPredictionFeature] = []
        
        // 平均情绪评分
        let avgEmotionScore = dreams.map { $0.emotions.count }.isEmpty ? 0 :
            Double(dreams.map { $0.emotions.count }.reduce(0, +)) / Double(dreams.count)
        
        features.append(MLPredictionFeature(
            name: "平均情绪复杂度",
            value: avgEmotionScore,
            weight: 0.4,
            category: .emotional
        ))
        
        // 积极情绪比例
        let positiveEmotions = ["开心", "平静", "兴奋", "满足", "爱"]
        let positiveCount = dreams.flatMap { $0.emotions }.filter { positiveEmotions.contains($0) }.count
        let totalEmotions = dreams.flatMap { $0.emotions }.count
        let positiveRatio = totalEmotions > 0 ? Double(positiveCount) / Double(totalEmotions) : 0
        
        features.append(MLPredictionFeature(
            name: "积极情绪比例",
            value: positiveRatio,
            weight: 0.5,
            category: .emotional
        ))
        
        // 情绪波动性
        let emotionVariance = calculateVariance(from: dreams.map { Double($0.emotions.count) })
        features.append(MLPredictionFeature(
            name: "情绪波动性",
            value: emotionVariance,
            weight: 0.3,
            category: .emotional
        ))
        
        return features
    }
    
    /// 提取内容特征
    static func extractContentFeatures(from dreams: [Dream]) -> [MLPredictionFeature] {
        var features: [MLPredictionFeature] = []
        
        // 平均梦境长度
        let avgLength = dreams.map { $0.content.count }.isEmpty ? 0 :
            Double(dreams.map { $0.content.count }.reduce(0, +)) / Double(dreams.count)
        
        features.append(MLPredictionFeature(
            name: "平均梦境长度",
            value: avgLength / 100, // 归一化
            weight: 0.3,
            category: .content
        ))
        
        // 清醒梦比例
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidRatio = dreams.isEmpty ? 0 : Double(lucidCount) / Double(dreams.count)
        
        features.append(MLPredictionFeature(
            name: "清醒梦比例",
            value: lucidRatio,
            weight: 0.6,
            category: .content
        ))
        
        // 平均清晰度
        let avgClarity = dreams.map { $0.clarity }.isEmpty ? 0 :
            Double(dreams.map { $0.clarity }.reduce(0, +)) / Double(dreams.count)
        
        features.append(MLPredictionFeature(
            name: "平均清晰度",
            value: avgClarity / 5.0, // 归一化到 0-1
            weight: 0.5,
            category: .content
        ))
        
        // 标签多样性
        let allTags = Set(dreams.flatMap { $0.tags })
        let tagDiversity = dreams.isEmpty ? 0 : Double(allTags.count) / Double(dreams.count)
        
        features.append(MLPredictionFeature(
            name: "标签多样性",
            value: tagDiversity,
            weight: 0.2,
            category: .content
        ))
        
        return features
    }
    
    /// 计算方差
    private static func calculateVariance(from values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return variance
    }
}

// MARK: - 预测解释生成器

/// 预测解释生成器
struct PredictionExplainer {
    static func generateExplanation(
        for predictionType: MLPredictionType,
        predictedValue: Double,
        confidence: Double,
        features: [MLPredictionFeature]
    ) -> String {
        switch predictionType {
        case .emotionTrend:
            if predictedValue > 0.7 {
                return "基于你最近的梦境记录，情绪趋势呈现积极上升。这可能与你的 \(getTopFeature(from: features)) 有关。"
            } else if predictedValue > 0.4 {
                return "情绪趋势保持稳定，梦境内容反映当前的心理状态较为平衡。"
            } else {
                return "情绪趋势略有下降，建议关注梦境中反复出现的主题，可能反映潜在压力。"
            }
            
        case .lucidProbability:
            if predictedValue > 0.6 {
                return "清醒梦概率较高！你的 \(getTopFeature(from: features)) 为清醒梦创造了良好条件。"
            } else if predictedValue > 0.3 {
                return "清醒梦概率中等，继续练习现实检查技巧可以提高概率。"
            } else {
                return "清醒梦概率较低，建议加强睡前意图设定和现实检查练习。"
            }
            
        case .dreamClarity:
            if predictedValue > 0.7 {
                return "预计梦境清晰度很高，\(getTopFeature(from: features)) 有助于提升回忆质量。"
            } else if predictedValue > 0.4 {
                return "梦境清晰度正常，保持当前的记录习惯即可。"
            } else {
                return "梦境清晰度可能较低，建议改善睡眠质量和睡前放松。"
            }
            
        default:
            return "预测置信度：\(Int(confidence * 100))%。基于 \(features.count) 个特征分析得出。"
        }
    }
    
    private static func getTopFeature(from features: [MLPredictionFeature]) -> String {
        guard let top = features.max(by: { $0.weight < $1.weight }) else {
            return "记录习惯"
        }
        return top.name
    }
}

// MARK: - 预览数据

#if DEBUG
extension MLPredictionResult {
    static let sample: MLPredictionResult = {
        let result = MLPredictionResult(
            predictionType: .emotionTrend,
            predictedValue: 0.75,
            confidence: 0.82,
            explanation: "基于你最近的梦境记录，情绪趋势呈现积极上升。"
        )
        
        result.features = [
            MLPredictionFeature(name: "每周记录频率", value: 5.2, weight: 0.4, category: .temporal),
            MLPredictionFeature(name: "积极情绪比例", value: 0.68, weight: 0.5, category: .emotional),
            MLPredictionFeature(name: "平均清晰度", value: 0.72, weight: 0.5, category: .content)
        ]
        
        return result
    }()
}
#endif
