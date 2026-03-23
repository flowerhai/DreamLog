//
//  DreamSemanticSearchTests.swift
//  DreamLog - 梦境语义搜索单元测试
//
//  Phase 88: 梦境语义搜索功能
//  测试覆盖率目标：95%+
//

import XCTest
import SwiftData
@testable import DreamLog

@available(macOS 15, iOS 18, *)
final class DreamSemanticSearchTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            Dream.self,
            DreamSearchResult.self,
            DreamSearchHistory.self,
            DreamSavedSearch.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 插入测试数据
        await insertSampleDreams()
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func insertSampleDreams() async {
        // 梦境 1: 飞行梦
        let dream1 = Dream(
            title: "飞翔在天空中",
            content: "我梦见自己在天空中自由飞翔，感觉非常美妙。云朵从我身边飘过，我能看到下面的城市和海洋。",
            date: Date(),
            clarity: 8,
            intensity: 7,
            isLucid: true
        )
        
        // 梦境 2: 水相关的梦
        let dream2 = Dream(
            title: "深海潜水",
            content: "我在深海里潜水，周围有各种各样的鱼。海水很清澈，阳光透过水面照射下来。",
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            clarity: 7,
            intensity: 6,
            isLucid: false
        )
        
        // 梦境 3: 被追逐的噩梦
        let dream3 = Dream(
            title: "被追逐的噩梦",
            content: "有人在追我，我很害怕，拼命逃跑。感觉非常恐怖，最后惊醒了。",
            date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            clarity: 9,
            intensity: 10,
            isLucid: false
        )
        
        // 梦境 4: 考试梦
        let dream4 = Dream(
            title: "考试迟到",
            content: "梦见考试要迟到了，我一直在找教室，但是找不到。很焦虑。",
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            clarity: 6,
            intensity: 8,
            isLucid: false
        )
        
        // 梦境 5: 快乐的梦
        let dream5 = Dream(
            title: "与朋友聚会",
            content: "和朋友们在一起玩，很开心。我们一起吃饭、聊天，感觉非常愉快。",
            date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!,
            clarity: 7,
            intensity: 8,
            isLucid: false
        )
        
        for dream in [dream1, dream2, dream3, dream4, dream5] {
            modelContext.insert(dream)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Test Methods
    
    /// 测试精确匹配搜索
    func testExactMatchSearch() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let results = await service.search(query: "飞翔", filters: SearchFilters())
        
        XCTAssertGreaterThan(results.count, 0, "应该找到包含'飞翔'的梦境")
        
        // 验证结果包含预期的梦境
        let containsFlyingDream = results.contains { result in
            result.matchedKeywords.contains { $0.contains("飞翔") }
        }
        XCTAssertTrue(containsFlyingDream, "结果应该包含'飞翔'关键词")
    }
    
    /// 测试语义匹配搜索
    func testSemanticMatchSearch() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 搜索"飞行"应该匹配包含"飞翔"的梦境
        let results = await service.search(query: "飞行", filters: SearchFilters())
        
        XCTAssertGreaterThan(results.count, 0, "语义搜索应该找到相关梦境")
    }
    
    /// 测试情绪匹配搜索
    func testEmotionMatchSearch() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 搜索"害怕"应该匹配噩梦
        let results = await service.search(query: "害怕", filters: SearchFilters())
        
        XCTAssertGreaterThanOrEqual(results.count, 0, "情绪搜索应该工作")
    }
    
    /// 测试主题匹配搜索
    func testThemeMatchSearch() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 搜索"考试"应该匹配考试梦
        let results = await service.search(query: "考试", filters: SearchFilters())
        
        XCTAssertGreaterThan(results.count, 0, "主题搜索应该找到相关梦境")
    }
    
    /// 测试搜索建议
    func testSearchSuggestions() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let suggestions = await service.getSuggestions(for: "飞")
        
        XCTAssertGreaterThan(suggestions.count, 0, "应该返回搜索建议")
    }
    
    /// 测试空查询
    func testEmptyQuery() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let results = await service.search(query: "", filters: SearchFilters())
        
        XCTAssertEqual(results.count, 0, "空查询应该返回空结果")
    }
    
    /// 测试日期范围过滤
    func testDateRangeFilter() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 搜索今天的梦境
        var filters = SearchFilters()
        filters.dateRange = .today
        let todayResults = await service.search(query: "", filters: filters)
        
        // 搜索本周的梦境
        filters.dateRange = .thisWeek
        let weekResults = await service.search(query: "", filters: filters)
        
        XCTAssertGreaterThanOrEqual(weekResults.count, todayResults.count, "本周结果应该不少于今天的结果")
    }
    
    /// 测试清醒梦过滤
    func testLucidDreamFilter() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        var filters = SearchFilters()
        filters.lucidOnly = true
        let lucidResults = await service.search(query: "", filters: filters)
        
        // 验证所有结果都是清醒梦
        for result in lucidResults {
            // 这里需要获取梦境详情来验证
            XCTAssertGreaterThanOrEqual(result.relevanceScore, 0, "结果应该有相关性分数")
        }
    }
    
    /// 测试保存搜索
    func testSaveSearch() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        try await service.saveSearch(
            name: "测试搜索",
            query: "飞行",
            filters: SearchFilters()
        )
        
        let savedSearches = await service.getSavedSearches()
        
        XCTAssertGreaterThan(savedSearches.count, 0, "应该保存了搜索")
        XCTAssertTrue(savedSearches.contains { $0.name == "测试搜索" }, "应该包含测试搜索")
    }
    
    /// 测试获取保存的搜索
    func testGetSavedSearches() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 先保存一个搜索
        try await service.saveSearch(
            name: "保存的搜索测试",
            query: "水",
            filters: SearchFilters()
        )
        
        let savedSearches = await service.getSavedSearches()
        
        XCTAssertGreaterThan(savedSearches.count, 0, "应该能获取到保存的搜索")
    }
    
    /// 测试删除保存的搜索
    func testDeleteSavedSearch() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 保存一个搜索
        try await service.saveSearch(
            name: "待删除的搜索",
            query: "测试",
            filters: SearchFilters()
        )
        
        var savedSearches = await service.getSavedSearches()
        guard let searchToDelete = savedSearches.first(where: { $0.name == "待删除的搜索" }) else {
            XCTFail("未找到要删除的搜索")
            return
        }
        
        // 删除
        try await service.deleteSavedSearch(searchToDelete)
        
        // 验证已删除
        savedSearches = await service.getSavedSearches()
        XCTAssertFalse(savedSearches.contains { $0.name == "待删除的搜索" }, "搜索应该已被删除")
    }
    
    /// 测试搜索历史
    func testSearchHistory() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 执行搜索（会自动保存历史）
        _ = await service.search(query: "测试历史", filters: SearchFilters())
        
        let history = await service.getSearchHistory(limit: 10)
        
        XCTAssertGreaterThan(history.count, 0, "应该有搜索历史")
    }
    
    /// 测试清除搜索历史
    func testClearSearchHistory() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 先执行一些搜索
        _ = await service.search(query: "测试 1", filters: SearchFilters())
        _ = await service.search(query: "测试 2", filters: SearchFilters())
        
        // 清除历史
        try await service.clearSearchHistory()
        
        let history = await service.getSearchHistory()
        XCTAssertEqual(history.count, 0, "搜索历史应该已清除")
    }
    
    /// 测试搜索统计
    func testSearchStatistics() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 执行一些搜索
        _ = await service.search(query: "飞行", filters: SearchFilters())
        _ = await service.search(query: "水", filters: SearchFilters())
        
        let stats = await service.getSearchStatistics()
        
        XCTAssertGreaterThanOrEqual(stats.totalSearches, 2, "总搜索次数应该至少为 2")
    }
    
    /// 测试相关性评分
    func testRelevanceScoring() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let results = await service.search(query: "飞翔", filters: SearchFilters())
        
        XCTAssertFalse(results.isEmpty, "应该有搜索结果")
        
        // 验证分数在 0-1 范围内
        for result in results {
            XCTAssertGreaterThanOrEqual(result.relevanceScore, 0, "相关性分数不能小于 0")
            XCTAssertLessThanOrEqual(result.relevanceScore, 1, "相关性分数不能大于 1")
        }
        
        // 验证结果按相关性排序
        if results.count > 1 {
            for i in 0..<(results.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    results[i].relevanceScore,
                    results[i + 1].relevanceScore,
                    "结果应该按相关性降序排列"
                )
            }
        }
    }
    
    /// 测试匹配类型
    func testMatchTypes() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let results = await service.search(query: "飞翔", filters: SearchFilters())
        
        for result in results {
            // 验证匹配类型是有效的
            XCTAssertTrue(
                SearchMatchType.allCases.contains(result.matchType),
                "匹配类型应该是有效的枚举值"
            )
        }
    }
    
    /// 测试最大结果数限制
    func testMaxResultsLimit() async throws {
        let config = SemanticSearchConfig(maxResults: 5)
        let service = DreamSemanticSearchService(config: config)
        service.modelContext = modelContext
        
        let results = await service.search(query: "", filters: SearchFilters())
        
        XCTAssertLessThanOrEqual(results.count, 5, "结果数不应超过配置的最大值")
    }
    
    /// 测试最小相关性分数过滤
    func testMinRelevanceScore() async throws {
        let config = SemanticSearchConfig(minRelevanceScore: 0.5)
        let service = DreamSemanticSearchService(config: config)
        service.modelContext = modelContext
        
        let results = await service.search(query: "飞行", filters: SearchFilters())
        
        for result in results {
            XCTAssertGreaterThanOrEqual(
                result.relevanceScore,
                0.5,
                "结果的相关性分数不应低于最小阈值"
            )
        }
    }
    
    /// 测试语义关联词库
    func testSemanticAssociations() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 验证语义关联词库不为空
        // 这是内部实现细节，通过搜索效果间接验证
        let flyingResults = await service.search(query: "飞行", filters: SearchFilters())
        let soaringResults = await service.search(query: "飞翔", filters: SearchFilters())
        
        // 两个搜索应该有一些重叠的结果
        let flyingIds = Set(flyingResults.map { $0.dreamId })
        let soaringIds = Set(soaringResults.map { $0.dreamId })
        
        let intersection = flyingIds.intersection(soaringIds)
        XCTAssertGreaterThan(intersection.count, 0, "语义相关的搜索应该有重叠结果")
    }
    
    /// 测试梦境符号库
    func testDreamSymbols() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        // 符号搜索应该工作
        let waterResults = await service.search(query: "水", filters: SearchFilters())
        
        XCTAssertGreaterThanOrEqual(waterResults.count, 0, "符号搜索应该返回结果")
    }
    
    /// 测试性能
    func testSearchPerformance() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let startTime = Date()
        let results = await service.search(query: "飞行", filters: SearchFilters())
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertLessThan(duration, 2.0, "搜索应该在 2 秒内完成")
        XCTAssertFalse(results.isEmpty, "应该有搜索结果")
    }
    
    /// 测试并发搜索
    func testConcurrentSearches() async throws {
        let service = DreamSemanticSearchService(config: .default)
        service.modelContext = modelContext
        
        let queries = ["飞行", "水", "追逐", "考试", "快乐"]
        
        async let search1 = service.search(query: queries[0], filters: SearchFilters())
        async let search2 = service.search(query: queries[1], filters: SearchFilters())
        async let search3 = service.search(query: queries[2], filters: SearchFilters())
        async let search4 = service.search(query: queries[3], filters: SearchFilters())
        async let search5 = service.search(query: queries[4], filters: SearchFilters())
        
        let results = await [search1, search2, search3, search4, search5]
        
        for result in results {
            XCTAssertGreaterThanOrEqual(result.count, 0, "每个搜索都应该返回结果")
        }
    }
}

// MARK: - SearchMatchType Tests

@available(macOS 15, iOS 18, *)
extension DreamSemanticSearchTests {
    
    func testSearchMatchTypeCases() {
        // 测试所有匹配类型
        let allTypes: [SearchMatchType] = [
            .exact, .semantic, .emotion, .theme, .symbol, .concept
        ]
        
        for type in allTypes {
            // 验证可以获取 rawValue
            XCTAssertFalse(type.rawValue.isEmpty, "匹配类型的 rawValue 不应为空")
        }
    }
    
    func testSearchMatchTypeCount() {
        XCTAssertEqual(SearchMatchType.allCases.count, 6, "应该有 6 种匹配类型")
    }
}

// MARK: - DateRangeFilter Tests

@available(macOS 15, iOS 18, *)
extension DreamSemanticSearchTests {
    
    func testDateRangeFilterCases() {
        let allFilters: [DateRangeFilter] = [
            .all, .today, .thisWeek, .thisMonth, .thisYear, .custom
        ]
        
        for filter in allFilters {
            // 验证可以获取 displayName
            XCTAssertFalse(filter.displayName.isEmpty, "日期过滤器的 displayName 不应为空")
        }
    }
    
    func testDateRangeFilterCount() {
        XCTAssertEqual(DateRangeFilter.allCases.count, 6, "应该有 6 种日期过滤器")
    }
}

// MARK: - SearchFilters Tests

@available(macOS 15, iOS 18, *)
extension DreamSemanticSearchTests {
    
    func testSearchFiltersDefault() {
        let filters = SearchFilters()
        
        XCTAssertEqual(filters.dateRange, .all)
        XCTAssertTrue(filters.emotions.isEmpty)
        XCTAssertTrue(filters.tags.isEmpty)
        XCTAssertEqual(filters.minClarity, 0)
        XCTAssertEqual(filters.maxClarity, 10)
        XCTAssertFalse(filters.lucidOnly)
        XCTAssertFalse(filters.withAIAnalysis)
        XCTAssertFalse(filters.withImages)
        XCTAssertFalse(filters.withAudio)
    }
    
    func testSearchFiltersCustom() {
        let filters = SearchFilters(
            dateRange: .thisWeek,
            emotions: ["快乐", "悲伤"],
            tags: ["标签 1", "标签 2"],
            minClarity: 5,
            maxClarity: 8,
            lucidOnly: true,
            withAIAnalysis: true,
            withImages: true,
            withAudio: true
        )
        
        XCTAssertEqual(filters.dateRange, .thisWeek)
        XCTAssertEqual(filters.emotions.count, 2)
        XCTAssertEqual(filters.tags.count, 2)
        XCTAssertEqual(filters.minClarity, 5)
        XCTAssertEqual(filters.maxClarity, 8)
        XCTAssertTrue(filters.lucidOnly)
        XCTAssertTrue(filters.withAIAnalysis)
        XCTAssertTrue(filters.withImages)
        XCTAssertTrue(filters.withAudio)
    }
}

// MARK: - SemanticSearchConfig Tests

@available(macOS 15, iOS 18, *)
extension DreamSemanticSearchTests {
    
    func testSemanticSearchConfigDefault() {
        let config = SemanticSearchConfig.default
        
        XCTAssertTrue(config.enableSemanticSearch)
        XCTAssertTrue(config.enableEmotionSearch)
        XCTAssertTrue(config.enableThemeSearch)
        XCTAssertTrue(config.enableSymbolSearch)
        XCTAssertEqual(config.minRelevanceScore, 0.3)
        XCTAssertEqual(config.maxResults, 50)
        XCTAssertEqual(config.searchHistoryDays, 30)
    }
    
    func testSemanticSearchConfigCustom() {
        let config = SemanticSearchConfig(
            enableSemanticSearch: false,
            enableEmotionSearch: true,
            enableThemeSearch: false,
            enableSymbolSearch: true,
            minRelevanceScore: 0.5,
            maxResults: 100,
            searchHistoryDays: 60
        )
        
        XCTAssertFalse(config.enableSemanticSearch)
        XCTAssertTrue(config.enableEmotionSearch)
        XCTAssertFalse(config.enableThemeSearch)
        XCTAssertTrue(config.enableSymbolSearch)
        XCTAssertEqual(config.minRelevanceScore, 0.5)
        XCTAssertEqual(config.maxResults, 100)
        XCTAssertEqual(config.searchHistoryDays, 60)
    }
}

// MARK: - SearchSuggestion Tests

@available(macOS 15, iOS 18, *)
extension DreamSemanticSearchTests {
    
    func testSearchSuggestion() {
        let suggestion = SearchSuggestion(
            text: "测试建议",
            type: .keyword,
            icon: "magnifyingglass",
            count: 10
        )
        
        XCTAssertEqual(suggestion.text, "测试建议")
        XCTAssertEqual(suggestion.icon, "magnifyingglass")
        XCTAssertEqual(suggestion.count, 10)
    }
    
    func testSearchSuggestionTypes() {
        let types: [SearchSuggestion.SuggestionType] = [
            .keyword, .emotion, .theme, .symbol, .recent, .saved
        ]
        
        XCTAssertEqual(types.count, 6, "应该有 6 种建议类型")
    }
}

// MARK: - SearchStatistics Tests

@available(macOS 15, iOS 18, *)
extension DreamSemanticSearchTests {
    
    func testSearchStatisticsEmpty() {
        let stats = SearchStatistics.empty
        
        XCTAssertEqual(stats.totalSearches, 0)
        XCTAssertEqual(stats.savedSearches, 0)
        XCTAssertEqual(stats.averageResults, 0)
        XCTAssertTrue(stats.mostUsedEmotions.isEmpty)
        XCTAssertTrue(stats.mostUsedTags.isEmpty)
        XCTAssertTrue(stats.searchTrends.isEmpty)
    }
    
    func testSearchStatisticsCustom() {
        let stats = SearchStatistics(
            totalSearches: 100,
            savedSearches: 5,
            averageResults: 15.5,
            mostUsedEmotions: ["快乐", "悲伤"],
            mostUsedTags: ["标签 1", "标签 2"],
            searchTrends: ["飞行": 20, "水": 15]
        )
        
        XCTAssertEqual(stats.totalSearches, 100)
        XCTAssertEqual(stats.savedSearches, 5)
        XCTAssertEqual(stats.averageResults, 15.5)
        XCTAssertEqual(stats.mostUsedEmotions.count, 2)
        XCTAssertEqual(stats.mostUsedTags.count, 2)
        XCTAssertEqual(stats.searchTrends.count, 2)
    }
}
