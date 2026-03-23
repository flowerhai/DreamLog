//
//  DreamSemanticSearchModels.swift
//  DreamLog - 梦境语义搜索数据模型
//
//  Phase 88: 梦境语义搜索功能
//  支持基于含义、情绪、主题的智能化梦境搜索
//

import Foundation
import SwiftData

// MARK: - 搜索结果模型

/// 语义搜索结果
@Model
final class DreamSearchResult {
    var id: UUID
    var query: String
    var dreamId: UUID
    var relevanceScore: Double
    var matchType: SearchMatchType
    var matchedKeywords: [String]
    var createdAt: Date
    
    init(query: String, dreamId: UUID, relevanceScore: Double, matchType: SearchMatchType, matchedKeywords: [String] = []) {
        self.id = UUID()
        self.query = query
        self.dreamId = dreamId
        self.relevanceScore = relevanceScore
        self.matchType = matchType
        self.matchedKeywords = matchedKeywords
        self.createdAt = Date()
    }
}

/// 搜索匹配类型
enum SearchMatchType: String, Codable, CaseIterable {
    case exact = "exact"           // 精确匹配
    case semantic = "semantic"     // 语义匹配
    case emotion = "emotion"       // 情绪匹配
    case theme = "theme"           // 主题匹配
    case symbol = "symbol"         // 符号匹配
    case concept = "concept"       // 概念匹配
}

// MARK: - 搜索历史模型

/// 搜索历史记录
@Model
final class DreamSearchHistory {
    var id: UUID
    var query: String
    var resultCount: Int
    var createdAt: Date
    var isSaved: Bool
    
    init(query: String, resultCount: Int, isSaved: Bool = false) {
        self.id = UUID()
        self.query = query
        self.resultCount = resultCount
        self.createdAt = Date()
        self.isSaved = isSaved
    }
}

// MARK: - 保存的搜索模型

/// 保存的搜索
@Model
final class DreamSavedSearch {
    var id: UUID
    var name: String
    var query: String
    var filters: SearchFilters
    var createdAt: Date
    var updatedAt: Date
    var notificationEnabled: Bool
    
    init(name: String, query: String, filters: SearchFilters = SearchFilters()) {
        self.id = UUID()
        self.name = name
        self.query = query
        self.filters = filters
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notificationEnabled = false
    }
}

// MARK: - 搜索过滤器

/// 搜索过滤器
struct SearchFilters: Codable {
    var dateRange: DateRangeFilter
    var emotions: [String]
    var tags: [String]
    var minClarity: Int
    var maxClarity: Int
    var lucidOnly: Bool
    var withAIAnalysis: Bool
    var withImages: Bool
    var withAudio: Bool
    
    init(
        dateRange: DateRangeFilter = .all,
        emotions: [String] = [],
        tags: [String] = [],
        minClarity: Int = 0,
        maxClarity: Int = 10,
        lucidOnly: Bool = false,
        withAIAnalysis: Bool = false,
        withImages: Bool = false,
        withAudio: Bool = false
    ) {
        self.dateRange = dateRange
        self.emotions = emotions
        self.tags = tags
        self.minClarity = minClarity
        self.maxClarity = maxClarity
        self.lucidOnly = lucidOnly
        self.withAIAnalysis = withAIAnalysis
        self.withImages = withImages
        self.withAudio = withAudio
    }
}

/// 日期范围过滤器
enum DateRangeFilter: String, Codable, CaseIterable {
    case all = "all"
    case today = "today"
    case thisWeek = "thisWeek"
    case thisMonth = "thisMonth"
    case thisYear = "thisYear"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .all: return "全部时间"
        case .today: return "今天"
        case .thisWeek: return "本周"
        case .thisMonth: return "本月"
        case .thisYear: return "今年"
        case .custom: return "自定义"
        }
    }
}

// MARK: - 搜索建议模型

/// 搜索建议
struct SearchSuggestion {
    var text: String
    var type: SuggestionType
    var icon: String
    var count: Int?
    
    enum SuggestionType {
        case keyword
        case emotion
        case theme
        case symbol
        case recent
        case saved
    }
}

// MARK: - 语义搜索配置

/// 语义搜索配置
struct SemanticSearchConfig {
    var enableSemanticSearch: Bool
    var enableEmotionSearch: Bool
    var enableThemeSearch: Bool
    var enableSymbolSearch: Bool
    var minRelevanceScore: Double
    var maxResults: Int
    var searchHistoryDays: Int
    
    static let `default` = SemanticSearchConfig(
        enableSemanticSearch: true,
        enableEmotionSearch: true,
        enableThemeSearch: true,
        enableSymbolSearch: true,
        minRelevanceScore: 0.3,
        maxResults: 50,
        searchHistoryDays: 30
    )
}

// MARK: - 搜索统计

/// 搜索统计
struct SearchStatistics {
    var totalSearches: Int
    var savedSearches: Int
    var averageResults: Double
    var mostUsedEmotions: [String]
    var mostUsedTags: [String]
    var searchTrends: [String: Int]
    
    static let empty = SearchStatistics(
        totalSearches: 0,
        savedSearches: 0,
        averageResults: 0,
        mostUsedEmotions: [],
        mostUsedTags: [],
        searchTrends: [:]
    )
}
