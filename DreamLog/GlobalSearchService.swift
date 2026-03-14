//
//  GlobalSearchService.swift
//  DreamLog
//
//  Phase 43 - 全局搜索服务
//

import Foundation
import Combine

/// 全局搜索服务
class GlobalSearchService: ObservableObject {
    static let shared = GlobalSearchService()
    
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var searchQuery: String = ""
    @Published var searchHistory: [String] = []
    
    private var dreamStore: DreamStore { DreamStore.shared }
    private var cancellables = Set<AnyCancellable>()
    
    // 搜索缓存
    private var searchCache: NSCache<NSString, NSArray> = {
        let cache = NSCache<NSString, NSArray>()
        cache.countLimit = 100
        return cache
    }()
    
    init() {
        setupSearchHistory()
    }
    
    private func setupSearchHistory() {
        if let saved = UserDefaults.standard.array(forKey: "searchHistory") as? [String] {
            searchHistory = Array(saved.prefix(10))
        }
    }
    
    /// 执行搜索
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        // 检查缓存
        if let cached = searchCache.object(forKey: query as NSString) as? [SearchResult] {
            searchResults = cached
            return
        }
        
        isSearching = true
        searchQuery = query
        
        // 添加到搜索历史
        addToHistory(query)
        
        // 等待一小段时间以显示加载状态
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        var results: [SearchResult] = []
        
        // 搜索梦境
        let dreamResults = searchDreams(query: query)
        results.append(contentsOf: dreamResults)
        
        // 搜索标签
        let tagResults = searchTags(query: query)
        results.append(contentsOf: tagResults)
        
        // 搜索情绪
        let emotionResults = searchEmotions(query: query)
        results.append(contentsOf: emotionResults)
        
        // 搜索社区帖子
        let communityResults = searchCommunityPosts(query: query)
        results.append(contentsOf: communityResults)
        
        // 搜索挑战
        let challengeResults = searchChallenges(query: query)
        results.append(contentsOf: challengeResults)
        
        // 按相关性排序
        results.sort { $0.relevance > $1.relevance }
        
        // 限制结果数量
        searchResults = Array(results.prefix(50))
        
        // 缓存结果
        searchCache.setObject(searchResults as NSArray, forKey: query as NSString)
        
        isSearching = false
    }
    
    /// 搜索梦境
    private func searchDreams(query: String) -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        
        return dreamStore.dreams.compactMap { dream -> SearchResult? in
            var relevance: Double = 0.0
            
            // 标题匹配
            if dream.title.lowercased().contains(lowercaseQuery) {
                relevance += 0.5
            }
            
            // 内容匹配
            if dream.content.lowercased().contains(lowercaseQuery) {
                relevance += 0.3
            }
            
            // 标签匹配
            if dream.tags.contains(where: { $0.lowercased().contains(lowercaseQuery) }) {
                relevance += 0.4
            }
            
            // 情绪匹配
            if dream.emotions.contains(where: { $0.rawValue.lowercased().contains(lowercaseQuery) }) {
                relevance += 0.2
            }
            
            return relevance > 0 ? SearchResult(type: .dream(dream), relevance: relevance) : nil
        }
    }
    
    /// 搜索标签
    private func searchTags(query: String) -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        let allTags = dreamStore.dreams.flatMap { $0.tags }
        let uniqueTags = Set(allTags)
        
        return uniqueTags.compactMap { tag -> SearchResult? in
            if tag.lowercased().contains(lowercaseQuery) {
                let count = dreamStore.dreams.filter { $0.tags.contains(tag) }.count
                return SearchResult(
                    type: .tag(tag),
                    relevance: Double(count) / Double(dreamStore.dreams.count) * 0.5
                )
            }
            return nil
        }
    }
    
    /// 搜索情绪
    private func searchEmotions(query: String) -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        
        return Emotion.allCases.compactMap { emotion -> SearchResult? in
            if emotion.rawValue.lowercased().contains(lowercaseQuery) || emotion.rawValue.contains(lowercaseQuery) {
                let count = dreamStore.dreams.filter { $0.emotions.contains(emotion) }.count
                return SearchResult(
                    type: .emotion(emotion.rawValue),
                    relevance: Double(count) / Double(dreamStore.dreams.count) * 0.4
                )
            }
            return nil
        }
    }
    
    /// 搜索社区帖子
    private func searchCommunityPosts(query: String) -> [SearchResult] {
        // TODO: 实现社区帖子搜索
        return []
    }
    
    /// 搜索挑战
    private func searchChallenges(query: String) -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        let challengeService = DreamChallengeService.shared
        
        return challengeService.challenges.compactMap { challenge -> SearchResult? in
            var relevance: Double = 0.0
            
            if challenge.title.lowercased().contains(lowercaseQuery) {
                relevance += 0.5
            }
            
            if challenge.description.lowercased().contains(lowercaseQuery) {
                relevance += 0.3
            }
            
            return relevance > 0 ? SearchResult(type: .challenge(challenge), relevance: relevance) : nil
        }
    }
    
    /// 添加到搜索历史
    private func addToHistory(_ query: String) {
        // 移除重复项
        searchHistory.removeAll { $0 == query }
        // 添加到开头
        searchHistory.insert(query, at: 0)
        // 限制历史记录数量
        if searchHistory.count > 10 {
            searchHistory.removeLast()
        }
        // 保存
        UserDefaults.standard.set(searchHistory, forKey: "searchHistory")
    }
    
    /// 清除搜索历史
    func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "searchHistory")
    }
    
    /// 清除搜索缓存
    func clearCache() {
        searchCache.removeAllObjects()
    }
    
    /// 获取热门搜索
    func getPopularSearches() -> [String] {
        // TODO: 基于搜索频率返回热门搜索
        return ["清醒梦", "飞行", "坠落", "追逐", "考试"]
    }
}
