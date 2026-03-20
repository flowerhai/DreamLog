//
//  DreamComparisonModels.swift
//  DreamLog
//
//  Dream Comparison Feature - Data Models
//  Phase 77: Dream Comparison Tool
//

import Foundation
import SwiftData

// MARK: - Dream Comparison Models

/// 梦境对比结果
@Model
final class DreamComparisonResult {
    var id: UUID
    var dreamIds: [UUID]
    var createdAt: Date
    var comparisonType: ComparisonType
    var similarities: [SimilarityCategory]
    var differences: [DifferenceCategory]
    var insights: [String]
    var similarityScore: Double
    
    init(
        id: UUID = UUID(),
        dreamIds: [UUID],
        createdAt: Date = Date(),
        comparisonType: ComparisonType,
        similarities: [SimilarityCategory] = [],
        differences: [DifferenceCategory] = [],
        insights: [String] = [],
        similarityScore: Double = 0.0
    ) {
        self.id = id
        self.dreamIds = dreamIds
        self.createdAt = createdAt
        self.comparisonType = comparisonType
        self.similarities = similarities
        self.differences = differences
        self.insights = insights
        self.similarityScore = similarityScore
    }
}

/// 对比类型
enum ComparisonType: String, Codable, CaseIterable {
    case twoDreams = "双梦对比"
    case multiDreams = "多梦对比"
    case timePeriod = "时间段对比"
    case themeEvolution = "主题演变"
    
    var icon: String {
        switch self {
        case .twoDreams: return "doc.text"
        case .multiDreams: return "doc.text.fill"
        case .timePeriod: return "calendar"
        case .themeEvolution: return "arrow.up.arrow.down"
        }
    }
    
    var description: String {
        switch self {
        case .twoDreams: return "选择两个梦境进行详细对比"
        case .multiDreams: return "选择多个梦境 (3-5 个) 进行对比"
        case .timePeriod: return "对比不同时间段的梦境模式"
        case .themeEvolution: return "追踪特定主题的演变历程"
        }
    }
}

/// 相似性类别
struct SimilarityCategory: Codable, Identifiable {
    let id: UUID
    let category: SimilarityType
    let items: [String]
    let confidence: Double
    
    init(id: UUID = UUID(), category: SimilarityType, items: [String], confidence: Double) {
        self.id = id
        self.category = category
        self.items = items
        self.confidence = confidence
    }
}

/// 相似性类型
enum SimilarityType: String, Codable, CaseIterable {
    case commonTags = "共同标签"
    case commonEmotions = "共同情绪"
    case commonThemes = "共同主题"
    case commonSymbols = "共同符号"
    case similarClarity = "相似清晰度"
    case similarIntensity = "相似强度"
    case timeProximity = "时间接近"
    case locationProximity = "地点接近"
    
    var icon: String {
        switch self {
        case .commonTags: return "tag.fill"
        case .commonEmotions: return "heart.fill"
        case .commonThemes: return "lightbulb.fill"
        case .commonSymbols: return "star.fill"
        case .similarClarity: return "eye.fill"
        case .similarIntensity: return "flame.fill"
        case .timeProximity: return "clock.fill"
        case .locationProximity: return "location.fill"
        }
    }
    
    var color: String {
        switch self {
        case .commonTags: return "blue"
        case .commonEmotions: return "pink"
        case .commonThemes: return "orange"
        case .commonSymbols: return "yellow"
        case .similarClarity: return "green"
        case .similarIntensity: return "red"
        case .timeProximity: return "purple"
        case .locationProximity: return "teal"
        }
    }
}

/// 差异类别
struct DifferenceCategory: Codable, Identifiable {
    let id: UUID
    let category: DifferenceType
    let dreamAValue: String
    let dreamBValue: String
    let significance: String
    
    init(
        id: UUID = UUID(),
        category: DifferenceType,
        dreamAValue: String,
        dreamBValue: String,
        significance: String
    ) {
        self.id = id
        self.category = category
        self.dreamAValue = dreamAValue
        self.dreamBValue = dreamBValue
        self.significance = significance
    }
}

/// 差异类型
enum DifferenceType: String, Codable, CaseIterable {
    case emotionChange = "情绪变化"
    case clarityChange = "清晰度变化"
    case intensityChange = "强度变化"
    case themeShift = "主题转变"
    case lucidStatus = "清醒梦状态"
    case timeOfDay = "时间段差异"
    case contentLength = "内容长度差异"
    case symbolEvolution = "符号演变"
    
    var icon: String {
        switch self {
        case .emotionChange: return "face.smiling.inverse"
        case .clarityChange: return "eye"
        case .intensityChange: return "flame"
        case .themeShift: return "arrow.left.arrow.right"
        case .lucidStatus: return "brain.head.profile"
        case .timeOfDay: return "sun.max"
        case .contentLength: return "text.justify"
        case .symbolEvolution: return "star"
        }
    }
}

/// 梦境对比配置
struct DreamComparisonConfig: Codable {
    var dreamIds: [UUID]
    var comparisonType: ComparisonType
    var includeAIAnalysis: Bool
    var includeEmotions: Bool
    var includeTags: Bool
    var includeSymbols: Bool
    var timeRange: DateInterval?
    
    init(
        dreamIds: [UUID],
        comparisonType: ComparisonType = .twoDreams,
        includeAIAnalysis: Bool = true,
        includeEmotions: Bool = true,
        includeTags: Bool = true,
        includeSymbols: Bool = true,
        timeRange: DateInterval? = nil
    ) {
        self.dreamIds = dreamIds
        self.comparisonType = comparisonType
        self.includeAIAnalysis = includeAIAnalysis
        self.includeEmotions = includeEmotions
        self.includeTags = includeTags
        self.includeSymbols = includeSymbols
        self.timeRange = timeRange
    }
}

/// 对比统计数据
struct ComparisonStatistics: Codable, Identifiable {
    let id: UUID
    let totalComparisons: Int
    let averageSimilarity: Double
    let mostCommonSimilarity: SimilarityType?
    let mostCommonDifference: DifferenceType?
    let recentComparisons: [Date]
    
    init(
        id: UUID = UUID(),
        totalComparisons: Int = 0,
        averageSimilarity: Double = 0.0,
        mostCommonSimilarity: SimilarityType? = nil,
        mostCommonDifference: DifferenceType? = nil,
        recentComparisons: [Date] = []
    ) {
        self.id = id
        self.totalComparisons = totalComparisons
        self.averageSimilarity = averageSimilarity
        self.mostCommonSimilarity = mostCommonSimilarity
        self.mostCommonDifference = mostCommonDifference
        self.recentComparisons = recentComparisons
    }
}

// MARK: - Dream Comparison Preview Data

struct DreamComparisonPreview {
    let dreamA: DreamPreview
    let dreamB: DreamPreview
    let similarityScore: Double
    let topSimilarities: [SimilarityCategory]
    let topDifferences: [DifferenceCategory]
}

struct DreamPreview: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let date: Date
    let tags: [String]
    let emotions: [String]
    let clarity: Int
    let intensity: Int
    let isLucid: Bool
}
