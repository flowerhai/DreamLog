//
//  DreamSceneAnalysisModels.swift
//  DreamLog
//
//  梦境场景分析模型：分析梦境发生的环境和场景
//

import Foundation
import SwiftUI

// MARK: - 场景类型枚举

/// 梦境场景类型
enum DreamSceneType: String, CaseIterable, Codable, Identifiable {
    case indoor = "indoor"           // 室内
    case outdoor = "outdoor"         // 室外
    case urban = "urban"             // 城市
    case nature = "nature"           // 自然
    case water = "water"             // 水域
    case sky = "sky"                 // 天空
    case underground = "underground" // 地下
    case fantastical = "fantastical" // 奇幻
    case familiar = "familiar"       // 熟悉的地方
    case unfamiliar = "unfamiliar"   // 陌生的地方
    case childhood = "childhood"     // 童年场所
    case school = "school"           // 学校
    case home = "home"               // 家
    case workplace = "workplace"     // 工作场所
    case transportation = "transportation" // 交通工具
    case other = "other"             // 其他
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .indoor: return "室内"
        case .outdoor: return "室外"
        case .urban: return "城市"
        case .nature: return "自然"
        case .water: return "水域"
        case .sky: return "天空"
        case .underground: return "地下"
        case .fantastical: return "奇幻"
        case .familiar: return "熟悉的地方"
        case .unfamiliar: return "陌生的地方"
        case .childhood: return "童年场所"
        case .school: return "学校"
        case .home: return "家"
        case .workplace: return "工作场所"
        case .transportation: return "交通工具"
        case .other: return "其他"
        }
    }
    
    var icon: String {
        switch self {
        case .indoor: return "house.fill"
        case .outdoor: return "tree.fill"
        case .urban: return "building.2.fill"
        case .nature: return "leaf.fill"
        case .water: return "drop.fill"
        case .sky: return "cloud.fill"
        case .underground: return "arrow.down.to.line"
        case .fantastical: return "sparkles"
        case .familiar: return "heart.fill"
        case .unfamiliar: return "questionmark.circle.fill"
        case .childhood: return "teddybear.fill"
        case .school: return "book.fill"
        case .home: return "house.circle.fill"
        case .workplace: return "briefcase.fill"
        case .transportation: return "car.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .indoor: return .brown
        case .outdoor: return .green
        case .urban: return .gray
        case .nature: return .mint
        case .water: return .blue
        case .sky: return .cyan
        case .underground: return .orange
        case .fantastical: return .purple
        case .familiar: return .pink
        case .unfamiliar: return .indigo
        case .childhood: return .yellow
        case .school: return .red
        case .home: return .orange
        case .workplace: return .blue
        case .transportation: return .teal
        case .other: return .gray
        }
    }
}

// MARK: - 场景分析数据模型

/// 梦境场景分析结果
struct DreamSceneAnalysis: Codable, Equatable, Hashable {
    let id: UUID
    let dreamId: UUID
    let detectedScenes: [DreamSceneType]
    let primaryScene: DreamSceneType
    let confidence: Double
    let sceneDescription: String
    let environmentalFactors: [EnvironmentalFactor]
    let createdAt: Date
    
    init(id: UUID = UUID(), dreamId: UUID, detectedScenes: [DreamSceneType], 
         primaryScene: DreamSceneType, confidence: Double, 
         sceneDescription: String, environmentalFactors: [EnvironmentalFactor] = []) {
        self.id = id
        self.dreamId = dreamId
        self.detectedScenes = detectedScenes
        self.primaryScene = primaryScene
        self.confidence = confidence
        self.sceneDescription = sceneDescription
        self.environmentalFactors = environmentalFactors
        self.createdAt = Date()
    }
}

/// 环境因素
struct EnvironmentalFactor: Codable, Equatable {
    let type: EnvironmentalFactorType
    let intensity: Double  // 0.0 - 1.0
    let description: String
    
    enum EnvironmentalFactorType: String, Codable, CaseIterable {
        case lighting = "lighting"           // 光线
        case weather = "weather"             // 天气
        case temperature = "temperature"     // 温度
        case sound = "sound"                 // 声音
        case crowding = "crowding"           // 拥挤程度
        case familiarity = "familiarity"     // 熟悉度
        case safety = "safety"               // 安全感
        case openness = "openness"           // 开放度
        
        var displayName: String {
            switch self {
            case .lighting: return "光线"
            case .weather: return "天气"
            case .temperature: return "温度"
            case .sound: return "声音"
            case .crowding: return "拥挤程度"
            case .familiarity: return "熟悉度"
            case .safety: return "安全感"
            case .openness: return "开放度"
            }
        }
    }
}

// MARK: - 场景统计模型

/// 场景分布统计
struct SceneDistribution: Codable, Equatable {
    let sceneType: DreamSceneType
    let count: Int
    let percentage: Double
    let trend: TrendDirection  // 上升/下降/稳定
    
    enum TrendDirection: String, Codable {
        case increasing = "increasing"
        case decreasing = "decreasing"
        case stable = "stable"
    }
}

/// 场景分析统计摘要
struct SceneAnalysisSummary: Codable, Equatable {
    let totalDreams: Int
    let analyzedDreams: Int
    let topScenes: [SceneDistribution]
    let sceneDiversity: Double  // 场景多样性指数 (0-1)
    let favoriteScene: DreamSceneType?
    let rareScene: DreamSceneType?
    let averageConfidence: Double
    let timeRange: DateRange
    
    struct DateRange: Codable, Equatable {
        let startDate: Date
        let endDate: Date
    }
}

// MARK: - 场景洞察模型

/// 场景洞察
struct SceneInsight: Identifiable, Codable, Equatable {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let icon: String
    let color: Color
    let relatedScenes: [DreamSceneType]
    let actionable: Bool
    let suggestion: String?
    
    enum InsightType: String, Codable, CaseIterable {
        case pattern = "pattern"               // 模式发现
        case correlation = "correlation"       // 关联发现
        case anomaly = "anomaly"               // 异常检测
        case trend = "trend"                   // 趋势分析
        case preference = "preference"         // 偏好分析
        case emotional = "emotional"           // 情绪关联
        
        var displayName: String {
            switch self {
            case .pattern: return "模式发现"
            case .correlation: return "关联发现"
            case .anomaly: return "异常检测"
            case .trend: return "趋势分析"
            case .preference: return "偏好分析"
            case .emotional: return "情绪关联"
            }
        }
    }
}

// MARK: - 场景与情绪关联

/// 场景 - 情绪关联
struct SceneEmotionCorrelation: Codable, Equatable {
    let sceneType: DreamSceneType
    let emotion: DreamEmotion
    let correlationStrength: Double  // -1.0 to 1.0
    let occurrenceCount: Int
    let averageIntensity: Double
    
    var correlationDescription: String {
        if correlationStrength > 0.7 {
            return "强正相关"
        } else if correlationStrength > 0.3 {
            return "中等正相关"
        } else if correlationStrength > -0.3 {
            return "弱相关"
        } else if correlationStrength > -0.7 {
            return "中等负相关"
        } else {
            return "强负相关"
        }
    }
}

// MARK: - 场景分析配置

/// 场景分析配置
struct SceneAnalysisConfig: Codable {
    var autoAnalyze: Bool
    var minConfidence: Double
    var enabledSceneTypes: [DreamSceneType]
    var showInsights: Bool
    var notifyOnPattern: Bool
    
    static let `default` = SceneAnalysisConfig(
        autoAnalyze: true,
        minConfidence: 0.6,
        enabledSceneTypes: DreamSceneType.allCases,
        showInsights: true,
        notifyOnPattern: false
    )
}
