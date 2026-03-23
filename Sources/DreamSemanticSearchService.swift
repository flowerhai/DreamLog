//
//  DreamSemanticSearchService.swift
//  DreamLog - 梦境语义搜索核心服务
//
//  Phase 88: 梦境语义搜索功能
//  使用 NaturalLanguage 框架实现智能化语义搜索
//

import Foundation
import SwiftData
import NaturalLanguage

@ModelActor
actor DreamSemanticSearchService {
    
    // MARK: - Properties
    
    private var config: SemanticSearchConfig
    private var tagIndex: [String: [UUID]] = [:]
    private var emotionIndex: [String: [UUID]] = [:]
    private var keywordIndex: [String: [UUID]] = [:]
    
    // 语义关联词库
    private let semanticAssociations: [String: [String]] = [
        "飞行": ["飞", "飞翔", "翱翔", "空中", "天空", "翅膀", "飞机", "鸟"],
        "水": ["海洋", "海", "河流", "河", "湖", "游泳", "潜水", "波浪", "雨", "下雨"],
        "追逐": ["追", "逃跑", "逃亡", "追赶", "追捕", "逃"],
        "坠落": ["掉", "落下", "跌落", "跳", "跳下"],
        "考试": ["测试", "测验", "学习", "学校", "作业", "成绩"],
        "牙齿": ["牙", "掉牙", "拔牙", "牙齿脱落"],
        "蛇": ["蟒蛇", "毒蛇", "爬行动物"],
        "死亡": ["死", "去世", "离去", "葬礼", "墓地"],
        "家": ["房子", "房间", "卧室", "客厅", "家乡", "老家"],
        "朋友": ["友人", "同伴", "伙伴", "同事", "同学"],
        "爱情": ["恋爱", "恋人", "情人", "浪漫", "约会"],
        "恐惧": ["害怕", "恐怖", "惊吓", "噩梦", "恐慌"],
        "快乐": ["开心", "高兴", "愉快", "喜悦", "兴奋"],
        "愤怒": ["生气", "怒火", "气愤", "暴躁"],
        "悲伤": ["难过", "伤心", "哭泣", "眼泪", "悲痛"]
    ]
    
    // 梦境符号库
    private let dreamSymbols: [String: [String]] = [
        "水": ["情绪", "潜意识", "变化", "流动"],
        "飞行": ["自由", "解脱", "控制", "野心"],
        "坠落": ["失控", "焦虑", "不安全感", "失败"],
        "牙齿": ["力量", "自信", "外表", "沟通"],
        "蛇": ["智慧", "转变", "恐惧", "诱惑"],
        "房屋": ["自我", "心灵", "安全感", "家庭"],
        "道路": ["人生方向", "选择", "旅程"],
        "桥": ["过渡", "连接", "改变"],
        "门": ["机会", "新开始", "通道"],
        "镜子": ["自我反思", "真相", "双重性"]
    ]
    
    // MARK: - Initialization
    
    init(config: SemanticSearchConfig = .default) {
        self.config = config
        Task.detached {
            await self.buildIndexes()
        }
    }
    
    // MARK: - Public Methods
    
    /// 执行语义搜索
    func search(query: String, filters: SearchFilters = SearchFilters()) async -> [DreamSearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return []
        }
        
        var results: [DreamSearchResult] = []
        
        // 1. 获取所有梦境
        let fetchDescriptor = FetchDescriptor<Dream>()
        guard let allDreams = try? modelContext.fetch(fetchDescriptor) else {
            return []
        }
        
        // 2. 应用基础过滤器
        let filteredDreams = applyFilters(dreams: allDreams, filters: filters)
        
        // 3. 对每个梦境进行评分
        for dream in filteredDreams {
            if let result = await scoreDream(dream: dream, query: query) {
                if result.relevanceScore >= config.minRelevanceScore {
                    results.append(result)
                }
            }
        }
        
        // 4. 按相关性排序
        results.sort { $0.relevanceScore > $1.relevanceScore }
        
        // 5. 限制结果数量
        results = Array(results.prefix(config.maxResults))
        
        // 6. 保存搜索历史
        await saveSearchHistory(query: query, resultCount: results.count)
        
        return results
    }
    
    /// 获取搜索建议
    func getSuggestions(for query: String) async -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            // 返回热门搜索和最近搜索
            return await getPopularSuggestions()
        }
        
        // 1. 关键词建议
        for keyword in keywordIndex.keys {
            if keyword.contains(trimmedQuery) && keyword != trimmedQuery {
                suggestions.append(SearchSuggestion(
                    text: keyword,
                    type: .keyword,
                    icon: "text.magnifyingglass",
                    count: keywordIndex[keyword]?.count
                ))
            }
        }
        
        // 2. 情绪建议
        let emotions = ["快乐", "悲伤", "恐惧", "愤怒", "惊讶", "厌恶", "平静", "兴奋", "焦虑", "期待"]
        for emotion in emotions {
            if emotion.contains(trimmedQuery) {
                suggestions.append(SearchSuggestion(
                    text: "情绪：\(emotion)",
                    type: .emotion,
                    icon: "face.smiling",
                    count: emotionIndex[emotion]?.count
                ))
            }
        }
        
        // 3. 语义关联建议
        for (keyword, associations) in semanticAssociations {
            if keyword.contains(trimmedQuery) || associations.contains(where: { $0.contains(trimmedQuery) }) {
                suggestions.append(SearchSuggestion(
                    text: keyword,
                    type: .concept,
                    icon: "brain.head.profile",
                    count: nil
                ))
            }
        }
        
        // 4. 符号建议
        for (symbol, meanings) in dreamSymbols {
            if symbol.contains(trimmedQuery) || meanings.contains(where: { $0.contains(trimmedQuery) }) {
                suggestions.append(SearchSuggestion(
                    text: "符号：\(symbol)",
                    type: .symbol,
                    icon: "star.fill",
                    count: nil
                ))
            }
        }
        
        // 限制建议数量
        suggestions = Array(suggestions.prefix(10))
        
        return suggestions
    }
    
    /// 保存搜索
    func saveSearch(name: String, query: String, filters: SearchFilters) async throws {
        let savedSearch = DreamSavedSearch(name: name, query: query, filters: filters)
        modelContext.insert(savedSearch)
        try modelContext.save()
    }
    
    /// 获取保存的搜索列表
    func getSavedSearches() async -> [DreamSavedSearch] {
        let fetchDescriptor = FetchDescriptor<DreamSavedSearch>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
    
    /// 删除保存的搜索
    func deleteSavedSearch(_ search: DreamSavedSearch) async throws {
        modelContext.delete(search)
        try modelContext.save()
    }
    
    /// 获取搜索历史
    func getSearchHistory(limit: Int = 20) async -> [DreamSearchHistory] {
        let fetchDescriptor = FetchDescriptor<DreamSearchHistory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
            fetchLimit: limit
        )
        return (try? modelContext.fetch(fetchDescriptor)) ?? []
    }
    
    /// 清除搜索历史
    func clearSearchHistory() async throws {
        let fetchDescriptor = FetchDescriptor<DreamSearchHistory>()
        let history = try modelContext.fetch(fetchDescriptor)
        for item in history {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
    
    /// 获取搜索统计
    func getSearchStatistics() async -> SearchStatistics {
        let historyFetch = FetchDescriptor<DreamSearchHistory>()
        let savedFetch = FetchDescriptor<DreamSavedSearch>()
        
        let history = (try? modelContext.fetch(historyFetch)) ?? []
        let saved = (try? modelContext.fetch(savedFetch)) ?? []
        
        let totalSearches = history.count
        let savedSearches = saved.count
        let averageResults = history.isEmpty ? 0 : Double(history.reduce(0) { $0 + $1.resultCount }) / Double(history.count)
        
        // 计算最常用的情绪和标签
        var emotionCounts: [String: Int] = [:]
        var tagCounts: [String: Int] = [:]
        
        for item in history {
            let query = item.query.lowercased()
            for emotion in emotionIndex.keys {
                if query.contains(emotion) {
                    emotionCounts[emotion, default: 0] += 1
                }
            }
            for tag in tagIndex.keys {
                if query.contains(tag) {
                    tagCounts[tag, default: 0] += 1
                }
            }
        }
        
        let mostUsedEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        let mostUsedTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        return SearchStatistics(
            totalSearches: totalSearches,
            savedSearches: savedSearches,
            averageResults: averageResults,
            mostUsedEmotions: mostUsedEmotions,
            mostUsedTags: mostUsedTags,
            searchTrends: [:]
        )
    }
    
    // MARK: - Private Methods
    
    /// 应用过滤器
    private func applyFilters(dreams: [Dream], filters: SearchFilters) -> [Dream] {
        return dreams.filter { dream in
            // 日期范围过滤
            if !passesDateFilter(dream: dream, filter: filters.dateRange) {
                return false
            }
            
            // 情绪过滤
            if !filters.emotions.isEmpty {
                let dreamEmotions = dream.emotions?.map { $0.name } ?? []
                if !filters.emotions.contains(where: { dreamEmotions.contains($0) }) {
                    return false
                }
            }
            
            // 标签过滤
            if !filters.tags.isEmpty {
                let dreamTags = dream.tags?.map { $0.name } ?? []
                if !filters.tags.contains(where: { dreamTags.contains($0) }) {
                    return false
                }
            }
            
            // 清晰度过滤
            if dream.clarity < filters.minClarity || dream.clarity > filters.maxClarity {
                return false
            }
            
            // 清醒梦过滤
            if filters.lucidOnly && !dream.isLucid {
                return false
            }
            
            // AI 解析过滤
            if filters.withAIAnalysis && (dream.aiAnalysis == nil || dream.aiAnalysis!.isEmpty) {
                return false
            }
            
            // 图片过滤
            if filters.withImages && (dream.images == nil || dream.images!.isEmpty) {
                return false
            }
            
            // 音频过滤
            if filters.withAudio && (dream.audioRecording == nil) {
                return false
            }
            
            return true
        }
    }
    
    /// 日期范围过滤
    private func passesDateFilter(dream: Dream, filter: DateRangeFilter) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        switch filter {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(dream.date)
        case .thisWeek:
            return calendar.isDateInThisWeek(dream.date)
        case .thisMonth:
            return calendar.isDateInThisMonth(dream.date)
        case .thisYear:
            return calendar.isDateInThisYear(dream.date)
        case .custom:
            return true // 自定义范围需要额外处理
        }
    }
    
    /// 对梦境进行评分
    private func scoreDream(dream: Dream, query: String) async -> DreamSearchResult? {
        let queryLower = query.lowercased()
        var score: Double = 0.0
        var matchType: SearchMatchType = .semantic
        var matchedKeywords: [String] = []
        
        // 1. 精确匹配 (权重：1.0)
        let exactMatch = exactMatchScore(dream: dream, query: queryLower)
        if exactMatch.score > 0 {
            score += exactMatch.score
            matchType = .exact
            matchedKeywords.append(contentsOf: exactMatch.keywords)
        }
        
        // 2. 语义匹配 (权重：0.8)
        if config.enableSemanticSearch {
            let semanticMatch = semanticMatchScore(dream: dream, query: queryLower)
            if semanticMatch.score > 0 {
                score += semanticMatch.score * 0.8
                if matchType != .exact {
                    matchType = .semantic
                }
                matchedKeywords.append(contentsOf: semanticMatch.keywords)
            }
        }
        
        // 3. 情绪匹配 (权重：0.7)
        if config.enableEmotionSearch {
            let emotionMatch = emotionMatchScore(dream: dream, query: queryLower)
            if emotionMatch.score > 0 {
                score += emotionMatch.score * 0.7
                if matchType == .semantic {
                    matchType = .emotion
                }
                matchedKeywords.append(contentsOf: emotionMatch.keywords)
            }
        }
        
        // 4. 主题匹配 (权重：0.6)
        if config.enableThemeSearch {
            let themeMatch = themeMatchScore(dream: dream, query: queryLower)
            if themeMatch.score > 0 {
                score += themeMatch.score * 0.6
                if matchType == .semantic || matchType == .emotion {
                    matchType = .theme
                }
                matchedKeywords.append(contentsOf: themeMatch.keywords)
            }
        }
        
        // 5. 符号匹配 (权重：0.5)
        if config.enableSymbolSearch {
            let symbolMatch = symbolMatchScore(dream: dream, query: queryLower)
            if symbolMatch.score > 0 {
                score += symbolMatch.score * 0.5
                if matchType == .semantic || matchType == .emotion || matchType == .theme {
                    matchType = .symbol
                }
                matchedKeywords.append(contentsOf: symbolMatch.keywords)
            }
        }
        
        guard score > 0 else { return nil }
        
        // 归一化分数到 0-1 范围
        let normalizedScore = min(score / 3.0, 1.0)
        
        return DreamSearchResult(
            query: query,
            dreamId: dream.id,
            relevanceScore: normalizedScore,
            matchType: matchType,
            matchedKeywords: Array(Set(matchedKeywords))
        )
    }
    
    /// 精确匹配评分
    private func exactMatchScore(dream: Dream, query: String) -> (score: Double, keywords: [String]) {
        var score: Double = 0.0
        var keywords: [String] = []
        
        let content = (dream.title ?? "" + " " + dream.content ?? "").lowercased()
        
        // 标题精确匹配
        if let title = dream.title, title.lowercased().contains(query) {
            score += 1.0
            keywords.append(query)
        }
        
        // 内容精确匹配
        if content.contains(query) {
            score += 0.8
            if !keywords.contains(query) {
                keywords.append(query)
            }
        }
        
        // 标签匹配
        if let tags = dream.tags {
            for tag in tags {
                if tag.name.lowercased().contains(query) {
                    score += 0.6
                    keywords.append(tag.name)
                }
            }
        }
        
        return (score, keywords)
    }
    
    /// 语义匹配评分
    private func semanticMatchScore(dream: Dream, query: String) -> (score: Double, keywords: [String]) {
        var score: Double = 0.0
        var keywords: [String] = []
        
        let content = (dream.title ?? "" + " " + dream.content ?? "").lowercased()
        
        // 使用 NaturalLanguage 进行词性标注和词干提取
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = content
        
        // 提取名词和动词
        var contentWords: Set<String> = []
        tagger.enumerateTags(in: content.startIndex..<content.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag, tag == .noun || tag == .verb {
                let word = String(content[range])
                contentWords.insert(word)
            }
        }
        
        // 检查语义关联
        for (keyword, associations) in semanticAssociations {
            if query.contains(keyword) || associations.contains(where: { query.contains($0) }) {
                // 检查梦境内容是否包含关联词
                for association in associations {
                    if content.contains(association) || contentWords.contains(association) {
                        score += 0.5
                        keywords.append(association)
                    }
                }
            }
        }
        
        return (score, keywords)
    }
    
    /// 情绪匹配评分
    private func emotionMatchScore(dream: Dream, query: String) -> (score: Double, keywords: [String]) {
        var score: Double = 0.0
        var keywords: [String] = []
        
        // 情绪关键词映射
        let emotionKeywords: [String: [String]] = [
            "快乐": ["开心", "高兴", "愉快", "喜悦", "兴奋", "幸福", "美好"],
            "悲伤": ["难过", "伤心", "哭泣", "眼泪", "悲痛", "失落", "沮丧"],
            "恐惧": ["害怕", "恐怖", "惊吓", "噩梦", "恐慌", "焦虑", "紧张"],
            "愤怒": ["生气", "怒火", "气愤", "暴躁", "愤怒", "恼火"],
            "惊讶": ["惊讶", "惊奇", "意外", "震惊", "吃惊"],
            "平静": ["平静", "安宁", "放松", "舒适", "宁静"]
        ]
        
        // 检查查询中的情绪词
        for (emotion, emotionWords) in emotionKeywords {
            if query.contains(emotion) || emotionWords.contains(where: { query.contains($0) }) {
                // 检查梦境情绪
                if let dreamEmotions = dream.emotions {
                    for dreamEmotion in dreamEmotions {
                        if dreamEmotion.name == emotion {
                            score += 1.0
                            keywords.append(emotion)
                        }
                    }
                }
                
                // 检查梦境内容中的情绪词
                let content = (dream.content ?? "").lowercased()
                for emotionWord in emotionWords {
                    if content.contains(emotionWord) {
                        score += 0.5
                        keywords.append(emotionWord)
                    }
                }
            }
        }
        
        return (score, keywords)
    }
    
    /// 主题匹配评分
    private func themeMatchScore(dream: Dream, query: String) -> (score: Double, keywords: [String]) {
        var score: Double = 0.0
        var keywords: [String] = []
        
        // 常见梦境主题
        let themes: [String: [String]] = [
            "飞行": ["飞", "飞翔", "空中", "天空", "翅膀", "漂浮"],
            "坠落": ["掉", "落下", "跌落", "跳下", "下沉"],
            "追逐": ["追", "逃跑", "追赶", "追捕", "逃亡"],
            "考试": ["考试", "测试", "测验", "学习", "学校"],
            "牙齿": ["牙齿", "牙", "掉牙", "拔牙"],
            "水": ["水", "海洋", "海", "河流", "湖", "游泳", "雨"],
            "蛇": ["蛇", "蟒蛇", "毒蛇"],
            "死亡": ["死", "去世", "葬礼", "墓地"],
            "爱情": ["爱情", "恋爱", "恋人", "浪漫"],
            "家": ["家", "房子", "房间", "家乡"]
        ]
        
        for (theme, themeWords) in themes {
            if query.contains(theme) || themeWords.contains(where: { query.contains($0) }) {
                let content = (dream.content ?? "").lowercased()
                for themeWord in themeWords {
                    if content.contains(themeWord) {
                        score += 0.4
                        keywords.append(themeWord)
                    }
                }
            }
        }
        
        return (score, keywords)
    }
    
    /// 符号匹配评分
    private func symbolMatchScore(dream: Dream, query: String) -> (score: Double, keywords: [String]) {
        var score: Double = 0.0
        var keywords: [String] = []
        
        for (symbol, meanings) in dreamSymbols {
            if query.contains(symbol) || query.contains(meanings.joined(separator: " ")) {
                let content = (dream.content ?? "").lowercased()
                if content.contains(symbol) {
                    score += 0.5
                    keywords.append(symbol)
                }
                
                for meaning in meanings {
                    if content.contains(meaning) {
                        score += 0.3
                        keywords.append(meaning)
                    }
                }
            }
        }
        
        return (score, keywords)
    }
    
    /// 保存搜索历史
    private func saveSearchHistory(query: String, resultCount: Int) async {
        let history = DreamSearchHistory(query: query, resultCount: resultCount)
        modelContext.insert(history)
        
        // 清理旧记录
        await cleanupOldHistory()
        
        try? modelContext.save()
    }
    
    /// 清理旧搜索历史
    private func cleanupOldHistory() async {
        let fetchDescriptor = FetchDescriptor<DreamSearchHistory>()
        guard let history = try? modelContext.fetch(fetchDescriptor) else { return }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -config.searchHistoryDays, to: Date()) ?? Date()
        
        for item in history {
            if item.createdAt < cutoffDate && !item.isSaved {
                modelContext.delete(item)
            }
        }
        
        try? modelContext.save()
    }
    
    /// 获取热门搜索建议
    private func getPopularSuggestions() async -> [SearchSuggestion] {
        var suggestions: [SearchSuggestion] = []
        
        // 热门标签
        for (tag, dreams) in tagIndex.prefix(5) {
            suggestions.append(SearchSuggestion(
                text: "#\(tag)",
                type: .keyword,
                icon: "tag",
                count: dreams.count
            ))
        }
        
        // 热门情绪
        for (emotion, dreams) in emotionIndex.prefix(3) {
            suggestions.append(SearchSuggestion(
                text: "情绪：\(emotion)",
                type: .emotion,
                icon: "face.smiling",
                count: dreams.count
            ))
        }
        
        return suggestions
    }
    
    /// 构建索引
    private func buildIndexes() async {
        tagIndex.removeAll()
        emotionIndex.removeAll()
        keywordIndex.removeAll()
        
        let fetchDescriptor = FetchDescriptor<Dream>()
        guard let dreams = try? modelContext.fetch(fetchDescriptor) else { return }
        
        for dream in dreams {
            // 构建标签索引
            if let tags = dream.tags {
                for tag in tags {
                    tagIndex[tag.name, default: []].append(dream.id)
                }
            }
            
            // 构建情绪索引
            if let emotions = dream.emotions {
                for emotion in emotions {
                    emotionIndex[emotion.name, default: []].append(dream.id)
                }
            }
            
            // 构建关键词索引
            let content = (dream.title ?? "" + " " + dream.content ?? "").lowercased()
            let tagger = NLTagger(tagSchemes: [.lexicalClass])
            tagger.string = content
            
            tagger.enumerateTags(in: content.startIndex..<content.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
                if let tag = tag, tag == .noun || tag == .verb {
                    let word = String(content[range])
                    if word.count > 1 { // 忽略单字符
                        keywordIndex[word, default: []].append(dream.id)
                    }
                }
            }
        }
    }
}
