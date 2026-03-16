//
//  DreamTagManagerService.swift
//  DreamLog
//
//  智能标签管理服务 - 核心业务逻辑
//  Phase 32: 智能标签管理
//

import Foundation
import NaturalLanguage
import Combine

@MainActor
class DreamTagManagerService: ObservableObject {
    
    // MARK: - Properties
    
    @Published private var dreamStore: DreamStore
    @Published private var tags: [String: TagInfo] = [:]  // normalized name -> TagInfo
    @Published private var suggestions: [TagSuggestion] = []
    @Published private var cleanupSuggestions: [TagCleanupSuggestion] = []
    private var config: TagManagerConfig = .default
    
    // MARK: - Initialization
    
    init(dreamStore: DreamStore) {
        self.dreamStore = dreamStore
        Task {
            await rebuildTagIndex()
            await analyzeTags()
        }
    }
    
    // MARK: - Tag Index Management
    
    /// 重建标签索引
    func rebuildTagIndex() async {
        tags.removeAll()
        
        let dreams = await dreamStore.dreams
        
        for dream in dreams {
            for tagName in dream.tags {
                let normalized = tagName.lowercased().trimmingCharacters(in: .whitespaces)
                
                if var existing = tags[normalized] {
                    existing.count += 1
                    existing.lastUsedAt = max(existing.lastUsedAt, dream.date)
                    tags[normalized] = existing
                } else {
                    tags[normalized] = TagInfo(
                        name: tagName,
                        count: 1,
                        lastUsedAt: dream.date
                    )
                }
            }
        }
    }
    
    /// 获取所有标签
    func getAllTags() async -> [TagInfo] {
        return Array(tags.values).sorted { $0.count > $1.count }
    }
    
    /// 获取标签统计
    func getStatistics() async -> TagStatistics {
        let allTags = Array(tags.values)
        let categorizedTags = allTags.filter { $0.category != nil }
        let topTags = allTags.sorted { $0.count > $1.count }.prefix(10).map { $0 }
        let recentTags = allTags.sorted { $0.lastUsedAt > $1.lastUsedAt }.prefix(10).map { $0 }
        let suggestedTags = allTags.filter { $0.isSuggested }
        
        var categoryDistribution: [TagCategory: Int] = [:]
        for tag in categorizedTags {
            if let category = tag.category {
                categoryDistribution[category, default: 0] += 1
            }
        }
        
        return TagStatistics(
            totalTags: allTags.count,
            totalUsage: allTags.reduce(0) { $0 + $1.count },
            categorizedTags: categorizedTags.count,
            uncategorizedTags: allTags.count - categorizedTags.count,
            topTags: topTags,
            recentTags: recentTags,
            suggestedTags: suggestedTags,
            categoryDistribution: categoryDistribution
        )
    }
    
    // MARK: - Tag Operations
    
    /// 重命名标签
    func renameTag(_ tagName: String, newName: String) async -> BulkOperationResult {
        let normalized = tagName.lowercased().trimmingCharacters(in: .whitespaces)
        let newNormalized = newName.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard var tag = tags[normalized] else {
            return BulkOperationResult(
                success: false,
                affectedDreams: 0,
                processedTags: 0,
                message: "标签不存在"
            )
        }
        
        // 检查新名称是否已存在
        if newNormalized != normalized && tags[newNormalized] != nil {
            return BulkOperationResult(
                success: false,
                affectedDreams: 0,
                processedTags: 0,
                message: "新标签名已存在"
            )
        }
        
        var affectedDreams = 0
        let dreams = await dreamStore.dreams
        
        for dream in dreams {
            if dream.tags.contains(tagName) {
                await dreamStore.updateDream(dream.id) { dream in
                    dream.tags = dream.tags.map { $0 == tagName ? newName : $0 }
                }
                affectedDreams += 1
            }
        }
        
        // 更新索引
        tags.removeValue(forKey: normalized)
        tag.name = newName
        tag.normalized = newNormalized
        tags[newNormalized] = tag
        
        return BulkOperationResult(
            success: true,
            affectedDreams: affectedDreams,
            processedTags: 1,
            message: "已更新 \(affectedDreams) 个梦境的标签"
        )
    }
    
    /// 合并标签
    func mergeTags(sourceTag: String, targetTag: String) async -> BulkOperationResult {
        let sourceNormalized = sourceTag.lowercased().trimmingCharacters(in: .whitespaces)
        let targetNormalized = targetTag.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard tags[sourceNormalized] != nil else {
            return BulkOperationResult(
                success: false,
                affectedDreams: 0,
                processedTags: 0,
                message: "源标签不存在"
            )
        }
        
        guard var targetTagInfo = tags[targetNormalized] else {
            return BulkOperationResult(
                success: false,
                affectedDreams: 0,
                processedTags: 0,
                message: "目标标签不存在"
            )
        }
        
        var affectedDreams = 0
        let dreams = await dreamStore.dreams
        
        for dream in dreams {
            var updated = false
            var newTags = dream.tags
            
            if newTags.contains(sourceTag) && !newTags.contains(targetTag) {
                newTags = newTags.map { $0 == sourceTag ? targetTag : $0 }
                updated = true
            } else if newTags.contains(sourceTag) && newTags.contains(targetTag) {
                newTags.removeAll { $0 == sourceTag }
                updated = true
            }
            
            if updated {
                await dreamStore.updateDream(dream.id) { dream in
                    dream.tags = newTags
                }
                affectedDreams += 1
            }
        }
        
        // 更新索引
        if let sourceTagInfo = tags[sourceNormalized] {
            targetTagInfo.count += sourceTagInfo.count
            targetTagInfo.lastUsedAt = max(targetTagInfo.lastUsedAt, sourceTagInfo.lastUsedAt)
            targetTagInfo.aliases.append(sourceTagInfo.name)
            tags[targetNormalized] = targetTagInfo
            tags.removeValue(forKey: sourceNormalized)
        }
        
        return BulkOperationResult(
            success: true,
            affectedDreams: affectedDreams,
            processedTags: 2,
            message: "已合并标签，影响 \(affectedDreams) 个梦境"
        )
    }
    
    /// 删除标签
    func deleteTag(_ tagName: String) async -> BulkOperationResult {
        let normalized = tagName.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard tags[normalized] != nil else {
            return BulkOperationResult(
                success: false,
                affectedDreams: 0,
                processedTags: 0,
                message: "标签不存在"
            )
        }
        
        var affectedDreams = 0
        let dreams = await dreamStore.dreams
        
        for dream in dreams {
            if dream.tags.contains(tagName) {
                await dreamStore.updateDream(dream.id) { dream in
                    dream.tags.removeAll { $0 == tagName }
                }
                affectedDreams += 1
            }
        }
        
        tags.removeValue(forKey: normalized)
        
        return BulkOperationResult(
            success: true,
            affectedDreams: affectedDreams,
            processedTags: 1,
            message: "已删除标签，影响 \(affectedDreams) 个梦境"
        )
    }
    
    /// 为标签分类
    func categorizeTag(_ tagName: String, category: TagCategory) async -> Bool {
        let normalized = tagName.lowercased().trimmingCharacters(in: .whitespaces)
        
        guard var tag = tags[normalized] else { return false }
        
        tag.category = category
        tags[normalized] = tag
        
        return true
    }
    
    /// 批量分类标签
    func bulkCategorize(_ tagNames: [String], category: TagCategory) async -> Int {
        var count = 0
        for tagName in tagNames {
            if await categorizeTag(tagName, category: category) {
                count += 1
            }
        }
        return count
    }
    
    // MARK: - AI Tag Suggestions
    
    /// 分析梦境并生成标签建议
    func analyzeDreamForTags(_ dream: Dream) async -> TagSuggestion {
        let content = "\(dream.title) \(dream.content)"
        let existingTags = dream.tags
        
        // 使用 NaturalLanguage 框架提取关键词
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = content
        
        var suggestedTags: Set<String> = []
        
        // 提取名词
        guard let taggerString = tagger.string else { return [] }
        tagger.enumerateTags(in: taggerString.startIndex..<taggerString.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if let tag = tag, tag == .noun {
                let word = String(taggerString[range])
                if word.count > 2 && !existingTags.contains(where: { $0.lowercased() == word.lowercased() }) {
                    suggestedTags.insert(word)
                }
            }
        }
        
        // 基于 AI 分析添加标签
        if let aiAnalysis = dream.aiAnalysis {
            let keywords = extractKeywords(from: aiAnalysis)
            for keyword in keywords {
                if !existingTags.contains(where: { $0.lowercased() == keyword.lowercased() }) {
                    suggestedTags.insert(keyword)
                }
            }
        }
        
        // 基于情绪建议标签
        for emotion in dream.emotions {
            let emotionTag = emotion.rawValue
            if !existingTags.contains(emotionTag) {
                suggestedTags.insert(emotionTag)
            }
        }
        
        let confidence = min(Double(suggestedTags.count) * 0.2, 0.95)
        
        return TagSuggestion(
            dreamId: dream.id,
            dreamTitle: dream.title,
            suggestedTags: Array(suggestedTags.prefix(5)),
            confidence: confidence,
            reason: "基于梦境内容和 AI 分析生成"
        )
    }
    
    /// 获取所有待处理的标签建议
    func getTagSuggestions() async -> [TagSuggestion] {
        let dreams = await dreamStore.dreams
        var allSuggestions: [TagSuggestion] = []
        
        for dream in dreams {
            if dream.tags.count < 3 {  // 标签少于 3 个的建议补充
                let suggestion = await analyzeDreamForTags(dream)
                if !suggestion.suggestedTags.isEmpty {
                    allSuggestions.append(suggestion)
                }
            }
        }
        
        return allSuggestions.sorted { $0.confidence > $1.confidence }
    }
    
    /// 应用标签建议
    func applySuggestion(_ suggestion: TagSuggestion) async -> Bool {
        var applied = false
        
        await dreamStore.updateDream(suggestion.dreamId) { dream in
            for tag in suggestion.suggestedTags {
                if !dream.tags.contains(tag) {
                    dream.tags.append(tag)
                    applied = true
                }
            }
        }
        
        if applied {
            await rebuildTagIndex()
        }
        
        return applied
    }
    
    // MARK: - Cleanup Suggestions
    
    /// 分析标签并生成清理建议
    func analyzeTags() async {
        cleanupSuggestions.removeAll()
        
        let allTags = Array(tags.values)
        
        // 检测重复标签（大小写不同）
        await detectDuplicateTags(allTags)
        
        // 检测相似标签
        await detectSimilarTags(allTags)
        
        // 检测未使用标签
        await detectUnusedTags(allTags)
    }
    
    /// 检测重复标签
    private func detectDuplicateTags(_ tags: [TagInfo]) async {
        var groups: [String: [TagInfo]] = [:]
        
        for tag in tags {
            let key = tag.normalized
            if var group = groups[key] {
                group.append(tag)
                groups[key] = group
            } else {
                groups[key] = [tag]
            }
        }
        
        for (_, group) in groups where group.count > 1 {
            let impact = group.reduce(0) { $0 + $1.count }
            cleanupSuggestions.append(TagCleanupSuggestion(
                type: .duplicate,
                tags: group,
                recommendation: "建议合并为\"\(group.max(by: { $0.count < $1.count })?.name ?? "")\"",
                impact: impact
            ))
        }
    }
    
    /// 检测相似标签
    private func detectSimilarTags(_ tags: [TagInfo]) async {
        // 简单的编辑距离检测
        let tagArray = Array(tags)
        var checked: Set<String> = []
        
        for i in 0..<tagArray.count {
            for j in (i+1)..<tagArray.count {
                let tag1 = tagArray[i]
                let tag2 = tagArray[j]
                
                if tag1.normalized != tag2.normalized && !checked.contains("\(tag1.normalized)-\(tag2.normalized)") {
                    let distance = levenshteinDistance(tag1.normalized, tag2.normalized)
                    
                    if distance <= 2 && tag1.normalized.count > 3 && tag2.normalized.count > 3 {
                        let impact = tag1.count + tag2.count
                        cleanupSuggestions.append(TagCleanupSuggestion(
                            type: .similar,
                            tags: [tag1, tag2],
                            recommendation: "这两个标签可能相似，建议合并",
                            impact: impact
                        ))
                        checked.insert("\(tag1.normalized)-\(tag2.normalized)")
                    }
                }
            }
        }
    }
    
    /// 检测未使用标签
    private func detectUnusedTags(_ tags: [TagInfo]) async {
        let unusedTags = tags.filter { $0.count == 0 }
        
        if !unusedTags.isEmpty {
            cleanupSuggestions.append(TagCleanupSuggestion(
                type: .unused,
                tags: unusedTags,
                recommendation: "这些标签未被使用，可以删除",
                impact: 0
            ))
        }
    }
    
    /// 获取清理建议
    func getCleanupSuggestions() async -> [TagCleanupSuggestion] {
        return cleanupSuggestions
    }
    
    // MARK: - Helper Methods
    
    /// 从文本提取关键词
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var keywords: [String] = []
        
        guard let taggerString = tagger.string else { return [] }
        tagger.enumerateTags(in: taggerString.startIndex..<taggerString.endIndex, unit: .word, scheme: .nameType) { tag, _ in
            if let tag = tag {
                keywords.append(tag.rawValue)
            }
        }
        
        return keywords
    }
    
    /// 计算编辑距离（Levenshtein Distance）
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[m][n]
    }
    
    /// 更新标签使用
    func updateTagUsage(_ tagName: String) async {
        let normalized = tagName.lowercased().trimmingCharacters(in: .whitespaces)
        
        if var tag = tags[normalized] {
            tag.count += 1
            tag.lastUsedAt = Date()
            tags[normalized] = tag
        } else {
            tags[normalized] = TagInfo(name: tagName)
        }
    }
    
    /// 批量添加标签到多个梦境
    func addTagToDreams(_ tagName: String, dreamIds: [UUID]) async -> BulkOperationResult {
        var affectedDreams = 0
        
        for dreamId in dreamIds {
            var updated = false
            await dreamStore.updateDream(dreamId) { dream in
                if !dream.tags.contains(tagName) {
                    dream.tags.append(tagName)
                    updated = true
                }
            }
            if updated {
                affectedDreams += 1
            }
        }
        
        if affectedDreams > 0 {
            await updateTagUsage(tagName)
        }
        
        return BulkOperationResult(
            success: affectedDreams > 0,
            affectedDreams: affectedDreams,
            processedTags: 1,
            message: "已添加到 \(affectedDreams) 个梦境"
        )
    }
    
    /// 批量删除标签从多个梦境
    func removeTagFromDreams(_ tagName: String, dreamIds: [UUID]) async -> BulkOperationResult {
        var affectedDreams = 0
        
        for dreamId in dreamIds {
            var updated = false
            await dreamStore.updateDream(dreamId) { dream in
                let index = dream.tags.firstIndex(of: tagName)
                if let index = index {
                    dream.tags.remove(at: index)
                    updated = true
                }
            }
            if updated {
                affectedDreams += 1
            }
        }
        
        if affectedDreams > 0 {
            await rebuildTagIndex()
        }
        
        return BulkOperationResult(
            success: affectedDreams > 0,
            affectedDreams: affectedDreams,
            processedTags: 1,
            message: "已从 \(affectedDreams) 个梦境移除"
        )
    }
}
