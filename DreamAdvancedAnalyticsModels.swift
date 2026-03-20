//
//  DreamAdvancedAnalyticsModels.swift
//  DreamLog
//
//  Phase 74: 梦境数据分析增强 📊🔍
//  高级分析数据模型
//
//  Created: 2026-03-20
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - 多维度交叉分析模型

/// 交叉分析维度
public enum CrossAnalysisDimension: String, Codable, CaseIterable {
    case emotionSymbol = "emotion_symbol"
    case emotionTime = "emotion_time"
    case weatherContent = "weather_content"
    case sleepQualityClarity = "sleep_clarity"
    case dayOfWeekEmotion = "day_emotion"
    case hourOfDayEmotion = "hour_emotion"
    
    public var displayName: String {
        switch self {
        case .emotionSymbol: return "情绪 × 符号"
        case .emotionTime: return "情绪 × 时间"
        case .weatherContent: return "天气 × 内容"
        case .sleepQualityClarity: return "睡眠 × 清晰度"
        case .dayOfWeekEmotion: return "星期 × 情绪"
        case .hourOfDayEmotion: return "时段 × 情绪"
        }
    }
}

/// 交叉分析结果
public struct CrossAnalysisResult: Codable {
    /// 分析维度
    public let dimension: CrossAnalysisDimension
    
    /// 数据点总数
    public let totalDataPoints: Int
    
    /// 关联矩阵（行×列）
    public let correlationMatrix: [[Double]]
    
    /// 行标签
    public let rowLabels: [String]
    
    /// 列标签
    public let columnLabels: [String]
    
    /// 显著关联（关联强度 > 0.7）
    public let significantCorrelations: [SignificantCorrelation]
    
    /// 分析时间戳
    public let analyzedAt: Date
    
    /// 显著关联
    public struct SignificantCorrelation: Codable {
        public let rowLabel: String
        public let columnLabel: String
        public let strength: Double
        public let count: Int
        
        public var strengthLevel: String {
            switch strength {
            case 0.9...: return "极强"
            case 0.8..<0.9: return "很强"
            case 0.7..<0.8: return "强"
            default: return "中等"
            }
        }
    }
}

// MARK: - 时间序列预测模型

/// 时间序列数据点
public struct TimeSeriesDataPoint: Codable {
    /// 时间戳
    public let timestamp: Date
    
    /// 数值
    public let value: Double
    
    /// 标签（可选）
    public let label: String?
}

/// 时间序列预测结果
public struct TimeSeriesForecast: Codable {
    /// 预测类型
    public let forecastType: ForecastType
    
    /// 历史数据点
    public let historicalData: [TimeSeriesDataPoint]
    
    /// 预测数据点
    public let forecastedData: [TimeSeriesDataPoint]
    
    /// 置信区间（下限）
    public let lowerBound: [Double]
    
    /// 置信区间（上限）
    public let upperBound: [Double]
    
    /// 趋势方向
    public let trendDirection: TrendDirection
    
    /// 趋势强度（0-1）
    public let trendStrength: Double
    
    /// 预测准确率（基于回测）
    public let accuracy: Double?
    
    /// 生成时间
    public let generatedAt: Date
    
    /// 预测类型
    public enum ForecastType: String, Codable, CaseIterable {
        case dreamFrequency = "frequency"
        case emotionTrend = "emotion"
        case lucidProbability = "lucid"
        case symbolOccurrence = "symbol"
        case sleepQuality = "sleep_quality"
        
        public var displayName: String {
            switch self {
            case .dreamFrequency: return "梦境频率"
            case .emotionTrend: return "情绪趋势"
            case .lucidProbability: return "清醒梦概率"
            case .symbolOccurrence: return "符号出现"
            case .sleepQuality: return "睡眠质量"
            }
        }
    }
    
    /// 趋势方向
    public enum TrendDirection: String, Codable {
        case increasing = "increasing"
        case decreasing = "decreasing"
        case stable = "stable"
        case volatile = "volatile"
        
        public var displayName: String {
            switch self {
            case .increasing: return "上升 ↗"
            case .decreasing: return "下降 ↘"
            case .stable: return "平稳 →"
            case .volatile: return "波动 〰"
            }
        }
    }
}

// MARK: - 异常检测模型

/// 异常检测结果
public struct AnomalyDetectionResult: Codable {
    /// 梦境 ID
    public let dreamId: UUID
    
    /// 异常类型
    public let anomalyType: AnomalyType
    
    /// 异常分数（0-1，越高越异常）
    public let anomalyScore: Double
    
    /// 异常描述
    public let description: String
    
    /// 相关指标
    public let metrics: [String: Double]
    
    /// 建议操作
    public let suggestedAction: String?
    
    /// 检测时间
    public let detectedAt: Date
    
    /// 异常类型
    public enum AnomalyType: String, Codable, CaseIterable {
        case emotionExtreme = "emotion_extreme"
        case symbolRare = "symbol_rare"
        case timeUnusual = "time_unusual"
        case contentLength = "content_length"
        case clarityExtreme = "clarity_extreme"
        case patternBreak = "pattern_break"
        
        public var displayName: String {
            switch self {
            case .emotionExtreme: return "情绪异常"
            case .symbolRare: return "稀有符号"
            case .timeUnusual: return "时间异常"
            case .contentLength: return "内容长度异常"
            case .clarityExtreme: return "清晰度异常"
            case .patternBreak: return "模式打破"
            }
        }
        
        public var icon: String {
            switch self {
            case .emotionExtreme: return "face.expression"
            case .symbolRare: return "star.fill"
            case .timeUnusual: return "clock.fill"
            case .contentLength: return "text.alignleft"
            case .clarityExtreme: return "eye.fill"
            case .patternBreak: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - 聚类分析模型

/// 聚类分析结果
public struct ClusteringResult: Codable {
    /// 聚类算法
    public let algorithm: ClusteringAlgorithm
    
    /// 聚类数量
    public let clusterCount: Int
    
    /// 梦境分组
    public let clusters: [DreamCluster]
    
    /// 聚类质量分数（0-1）
    public let qualityScore: Double
    
    /// 分析时间
    public let analyzedAt: Date
    
    /// 聚类算法
    public enum ClusteringAlgorithm: String, Codable {
        case kmeans = "kmeans"
        case hierarchical = "hierarchical"
        case dbscan = "dbscan"
        
        public var displayName: String {
            switch self {
            case .kmeans: return "K-Means"
            case .hierarchical: return "层次聚类"
            case .dbscan: return "DBSCAN"
            }
        }
    }
    
    /// 梦境分组
    public struct DreamCluster: Codable, Identifiable {
        public let id: UUID
        public let name: String
        public let dreamIds: [UUID]
        public let size: Int
        public let centroid: ClusterCentroid
        public let characteristics: [String]
        public let dominantEmotion: DreamEmotion?
        public let commonSymbols: [String]
        public let timeRange: ClosedRange<Date>?
        
        public var sizeCategory: String {
            switch size {
            case ..<5: return "小型"
            case 5..<15: return "中型"
            case 15..<30: return "大型"
            default: return "超大型"
            }
        }
    }
    
    /// 聚类中心
    public struct ClusterCentroid: Codable {
        public let emotionDistribution: [String: Double]
        public let averageClarity: Double
        public let averageLength: Double
        public let commonKeywords: [String]
    }
}

// MARK: - 报告模型

/// 报告类型
public enum ReportType: String, Codable, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .weekly: return "周报"
        case .monthly: return "月报"
        case .yearly: return "年报"
        case .custom: return "自定义报告"
        }
    }
    
    public var icon: String {
        switch self {
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly: return "calendar.badge.checkmark"
        case .custom: return "doc.badge.plus"
        }
    }
}

/// 梦境报告
public struct DreamReport: Codable, Identifiable {
    public let id: UUID
    public let type: ReportType
    public let title: String
    public let periodStart: Date
    public let periodEnd: Date
    public let generatedAt: Date
    
    /// 报告摘要
    public let summary: ReportSummary
    
    /// 统计数据
    public let statistics: ReportStatistics
    
    /// 洞察列表
    public let insights: [ReportInsight]
    
    /// 可视化数据
    public let visualizations: [ReportVisualization]
    
    /// 推荐内容
    public let recommendations: [String]
    
    /// 报告摘要
    public struct ReportSummary: Codable {
        public let totalDreams: Int
        public let averageClarity: Double
        public let dominantEmotion: String
        public let lucidDreamCount: Int
        public let keyWords: [String]
        public let highlight: String
    }
    
    /// 统计数据
    public struct ReportStatistics: Codable {
        public let dreamsByDay: [String: Int]
        public let emotionDistribution: [String: Double]
        public let topSymbols: [(symbol: String, count: Int)]
        public let averageLength: Double
        public let sleepQualityCorrelation: Double?
    }
    
    /// 报告洞察
    public struct ReportInsight: Codable, Identifiable {
        public let id: UUID
        public let type: InsightType
        public let title: String
        public let description: String
        public let icon: String
        public let severity: InsightSeverity
        
        public enum InsightType: String, Codable {
            case pattern = "pattern"
            case trend = "trend"
            case anomaly = "anomaly"
            case achievement = "achievement"
            case suggestion = "suggestion"
        }
        
        public enum InsightSeverity: String, Codable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            
            public var color: String {
                switch self {
                case .low: return "secondary"
                case .medium: return "orange"
                case .high: return "red"
                }
            }
        }
    }
    
    /// 可视化数据
    public struct ReportVisualization: Codable, Identifiable {
        public let id: UUID
        public let type: VisualizationType
        public let title: String
        public let data: [String: CodableValue]
        
        public enum VisualizationType: String, Codable {
            case lineChart = "line"
            case barChart = "bar"
            case pieChart = "pie"
            case heatmap = "heatmap"
            case scatterPlot = "scatter"
        }
    }
}

// MARK: - 辅助类型

/// 梦境情绪（简化版，实际应引用主模型）
public enum DreamEmotion: String, Codable, CaseIterable {
    case happy = "happy"
    case sad = "sad"
    case anxious = "anxious"
    case calm = "calm"
    case excited = "excited"
    case fearful = "fearful"
    case neutral = "neutral"
    case confused = "confused"
    
    public var displayName: String {
        switch self {
        case .happy: return "快乐"
        case .sad: return "悲伤"
        case .anxious: return "焦虑"
        case .calm: return "平静"
        case .excited: return "兴奋"
        case .fearful: return "恐惧"
        case .neutral: return "中性"
        case .confused: return "困惑"
        }
    }
    
    public var icon: String {
        switch self {
        case .happy: return "face.smiling"
        case .sad: return "face.frowning"
        case .anxious: return "face.worried"
        case .calm: return "face.relaxed"
        case .excited: return "face.star.eyes"
        case .fearful: return "face.monocle"
        case .neutral: return "face.dashed"
        case .confused: return "questionmark"
        }
    }
}

/// 可编码值（用于 JSON 序列化）
public enum CodableValue: Codable {
    case int(Int)
    case double(Double)
    case string(String)
    case array([CodableValue])
    case dictionary([String: CodableValue])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([CodableValue].self) {
            self = .array(array)
        } else if let dict = try? container.decode([String: CodableValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "无法解码的值"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        }
    }
}

// MARK: - 分析配置

/// 高级分析配置
public struct AdvancedAnalyticsConfiguration: Codable {
    /// 启用交叉分析
    public var enableCrossAnalysis: Bool
    
    /// 启用时间序列预测
    public var enableTimeSeriesForecast: Bool
    
    /// 启用异常检测
    public var enableAnomalyDetection: Bool
    
    /// 启用聚类分析
    public var enableClustering: Bool
    
    /// 自动报告生成
    public var autoReportGeneration: Bool
    
    /// 报告类型
    public var reportTypes: [ReportType]
    
    /// 异常检测阈值
    public var anomalyThreshold: Double
    
    /// 聚类数量
    public var clusterCount: Int
    
    /// 预测天数
    public var forecastDays: Int
    
    public static let `default` = AdvancedAnalyticsConfiguration(
        enableCrossAnalysis: true,
        enableTimeSeriesForecast: true,
        enableAnomalyDetection: true,
        enableClustering: true,
        autoReportGeneration: true,
        reportTypes: [.weekly, .monthly, .yearly],
        anomalyThreshold: 0.85,
        clusterCount: 5,
        forecastDays: 7
    )
}
