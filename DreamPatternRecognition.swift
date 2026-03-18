//
//  DreamPatternRecognition.swift
//  DreamLog
//
//  Phase 66: AI 梦境解析增强 🧠✨
//  模式识别引擎 - 识别梦境中的重复模式和关联
//
//  Created: 2026-03-18
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - 模式识别引擎

/// 梦境模式识别引擎
public actor DreamPatternRecognition {
    /// 共享实例
    public static let shared = DreamPatternRecognition()
    
    private init() {}
    
    // MARK: - 公共方法
    
    /// 识别梦境模式
    public func identifyPatterns(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> [DreamPattern] {
        var patterns: [DreamPattern] = []
        
        // 1. 识别重复符号
        if let symbolPatterns = await identifyRecurringSymbols(dream: dream, in: context) {
            patterns.append(contentsOf: symbolPatterns)
        }
        
        // 2. 识别重复主题
        if let themePatterns = await identifyRecurringThemes(dream: dream, in: context) {
            patterns.append(contentsOf: themePatterns)
        }
        
        // 3. 识别情绪模式
        if let emotionPatterns = await identifyEmotionalPatterns(dream: dream, in: context) {
            patterns.append(contentsOf: emotionPatterns)
        }
        
        // 4. 识别时间模式
        if let temporalPatterns = await identifyTemporalPatterns(dream: dream, in: context) {
            patterns.append(contentsOf: temporalPatterns)
        }
        
        // 5. 识别清醒梦模式
        if let lucidPatterns = await identifyLucidPatterns(dream: dream, in: context) {
            patterns.append(contentsOf: lucidPatterns)
        }
        
        return patterns
    }
    
    /// 获取梦境关联
    public func findRelatedDreams(
        for dream: DreamEntry,
        in context: ModelContext,
        maxResults: Int = 10
    ) async -> [DreamEntry] {
        var relatedDreams: [(DreamEntry, Double)] = []
        
        do {
            // 获取所有梦境
            let descriptor = FetchDescriptor<DreamEntry>()
            let allDreams = try context.fetch(descriptor)
            
            for otherDream in allDreams {
                if otherDream.id == dream.id {
                    continue
                }
                
                // 计算相似度
                let similarity = calculateSimilarity(between: dream, and: otherDream)
                
                if similarity > 0.3 {
                    relatedDreams.append((otherDream, similarity))
                }
            }
            
            // 按相似度排序
            relatedDreams.sort { $0.1 > $1.1 }
            
            return relatedDreams.prefix(maxResults).map { $0.0 }
        } catch {
            return []
        }
    }
    
    // MARK: - 模式识别方法
    
    /// 识别重复符号
    private func identifyRecurringSymbols(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> [DreamPattern]? {
        // 提取当前梦境的关键词
        let keywords = extractKeywords(from: dream.content)
        
        guard !keywords.isEmpty else { return nil }
        
        var patterns: [DreamPattern] = []
        
        do {
            let descriptor = FetchDescriptor<DreamEntry>()
            let allDreams = try context.fetch(descriptor)
            
            for keyword in keywords {
                var relatedDreamIds: [UUID] = []
                var firstOccurrence: Date?
                var lastOccurrence: Date?
                
                for otherDream in allDreams {
                    if otherDream.content.contains(keyword) {
                        relatedDreamIds.append(otherDream.id)
                        
                        if firstOccurrence == nil || otherDream.createdAt < firstOccurrence {
                            firstOccurrence = otherDream.createdAt
                        }
                        if lastOccurrence == nil || otherDream.createdAt > lastOccurrence {
                            lastOccurrence = otherDream.createdAt
                        }
                    }
                }
                
                // 如果出现次数 >= 3，认为是重复符号
                if relatedDreamIds.count >= 3 {
                    let strength = min(Double(relatedDreamIds.count) / 10.0, 1.0)
                    let trend = calculateTrend(dates: relatedDreamIds.map { _ in Date() })
                    
                    patterns.append(DreamPattern(
                        patternType: .recurringSymbol,
                        name: "\"\(keyword)\" 重复出现",
                        description: "符号\"\(keyword)\"在你的梦境中重复出现了\(relatedDreamIds.count)次",
                        relatedDreamIds: relatedDreamIds,
                        occurrenceCount: relatedDreamIds.count,
                        firstOccurrence: firstOccurrence ?? Date(),
                        lastOccurrence: lastOccurrence ?? Date(),
                        strength: strength,
                        trend: trend
                    ))
                }
            }
        } catch {
            return nil
        }
        
        return patterns.isEmpty ? nil : patterns
    }
    
    /// 识别重复主题
    private func identifyRecurringThemes(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> [DreamPattern]? {
        // 主题关键词映射
        let themeKeywords: [String: [String]] = [
            "追逐": ["追逐", "逃跑", "追赶", "被追"],
            "坠落": ["坠落", "掉落", "跌落", "下坠"],
            "飞行": ["飞行", "飞翔", "飞", "飘浮"],
            "考试": ["考试", "测验", "考场", "答题"],
            "迷路": ["迷路", "找不到", "迷失", "走失"],
            "迟到": ["迟到", "来不及", "晚了", "错过"],
            "掉落牙齿": ["牙齿", "掉牙", "牙掉"],
            "裸体": ["裸体", "没穿衣服", "光着"]
        ]
        
        var patterns: [DreamPattern] = []
        
        do {
            let descriptor = FetchDescriptor<DreamEntry>()
            let allDreams = try context.fetch(descriptor)
            
            for (theme, keywords) in themeKeywords {
                var relatedDreamIds: [UUID] = []
                var dates: [Date] = []
                
                for otherDream in allDreams {
                    for keyword in keywords {
                        if otherDream.content.contains(keyword) {
                            if !relatedDreamIds.contains(otherDream.id) {
                                relatedDreamIds.append(otherDream.id)
                                dates.append(otherDream.createdAt)
                            }
                            break
                        }
                    }
                }
                
                if relatedDreamIds.count >= 2 {
                    let strength = min(Double(relatedDreamIds.count) / 5.0, 1.0)
                    let trend = calculateTrend(dates: dates)
                    
                    patterns.append(DreamPattern(
                        patternType: .recurringTheme,
                        name: "\(theme)主题",
                        description: "\(theme)主题的梦境出现了\(relatedDreamIds.count)次",
                        relatedDreamIds: relatedDreamIds,
                        occurrenceCount: relatedDreamIds.count,
                        firstOccurrence: dates.min() ?? Date(),
                        lastOccurrence: dates.max() ?? Date(),
                        strength: strength,
                        trend: trend
                    ))
                }
            }
        } catch {
            return nil
        }
        
        return patterns.isEmpty ? nil : patterns
    }
    
    /// 识别情绪模式
    private func identifyEmotionalPatterns(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> [DreamPattern]? {
        guard let emotion = dream.emotions.first else { return nil }
        
        do {
            let descriptor = FetchDescriptor<DreamEntry>(
                predicate: #Predicate { $0.emotions.contains(emotion) }
            )
            let similarDreams = try context.fetch(descriptor)
            
            if similarDreams.count >= 3 {
                let strength = min(Double(similarDreams.count) / 10.0, 1.0)
                let dates = similarDreams.map { $0.createdAt }
                let trend = calculateTrend(dates: dates)
                
                return [DreamPattern(
                    patternType: .emotionalPattern,
                    name: "\(emotion)情绪模式",
                    description: "你最近经常做带有\"\(emotion)\"情绪的梦境",
                    relatedDreamIds: similarDreams.map { $0.id },
                    occurrenceCount: similarDreams.count,
                    firstOccurrence: dates.min() ?? Date(),
                    lastOccurrence: dates.max() ?? Date(),
                    strength: strength,
                    trend: trend
                )]
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// 识别时间模式
    private func identifyTemporalPatterns(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> [DreamPattern]? {
        // 检查是否在特定时间段经常做梦
        let hour = Calendar.current.component(.hour, from: dream.createdAt)
        
        do {
            let descriptor = FetchDescriptor<DreamEntry>()
            let allDreams = try context.fetch(descriptor)
            
            let sameHourDreams = allDreams.filter {
                Calendar.current.component(.hour, from: $0.createdAt) == hour
            }
            
            if sameHourDreams.count >= 3 {
                let strength = min(Double(sameHourDreams.count) / 5.0, 1.0)
                let dates = sameHourDreams.map { $0.createdAt }
                let trend = calculateTrend(dates: dates)
                
                return [DreamPattern(
                    patternType: .temporalPattern,
                    name: "\(hour)点梦境模式",
                    description: "你经常在\(hour)点左右记录梦境",
                    relatedDreamIds: sameHourDreams.map { $0.id },
                    occurrenceCount: sameHourDreams.count,
                    firstOccurrence: dates.min() ?? Date(),
                    lastOccurrence: dates.max() ?? Date(),
                    strength: strength,
                    trend: trend
                )]
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    /// 识别清醒梦模式
    private func identifyLucidPatterns(
        dream: DreamEntry,
        in context: ModelContext
    ) async -> [DreamPattern]? {
        do {
            let descriptor = FetchDescriptor<DreamEntry>(
                predicate: #Predicate { $0.isLucid == true }
            )
            let lucidDreams = try context.fetch(descriptor)
            
            if lucidDreams.count >= 2 {
                let strength = min(Double(lucidDreams.count) / 5.0, 1.0)
                let dates = lucidDreams.map { $0.createdAt }
                let trend = calculateTrend(dates: dates)
                
                return [DreamPattern(
                    patternType: .lucidPattern,
                    name: "清醒梦模式",
                    description: "你已经记录了\(lucidDreams.count)个清醒梦",
                    relatedDreamIds: lucidDreams.map { $0.id },
                    occurrenceCount: lucidDreams.count,
                    firstOccurrence: dates.min() ?? Date(),
                    lastOccurrence: dates.max() ?? Date(),
                    strength: strength,
                    trend: trend
                )]
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    // MARK: - 辅助方法
    
    /// 提取关键词
    private func extractKeywords(from text: String) -> [String] {
        // 简单实现：按空格分词并过滤
        let words = text.split(separator: " ")
            .map { String($0).trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 1 }
        
        // 过滤常见停用词
        let stopWords = Set(["的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "一个"])
        return words.filter { !stopWords.contains($0) }
    }
    
    /// 计算趋势
    private func calculateTrend(dates: [Date]) -> PatternTrend {
        guard dates.count >= 2 else { return .stable }
        
        let sortedDates = dates.sorted()
        let recentCount = dates.filter { $0 > Date().addingTimeInterval(-7 * 24 * 60 * 60) }.count
        let olderCount = dates.count - recentCount
        
        if recentCount > olderCount * 2 {
            return .increasing
        } else if recentCount < olderCount / 2 {
            return .decreasing
        } else if recentCount == olderCount {
            return .stable
        } else {
            return .fluctuating
        }
    }
    
    /// 计算相似度
    private func calculateSimilarity(between dream1: DreamEntry, and dream2: DreamEntry) -> Double {
        var similarity = 0.0
        
        // 情绪相似度
        let commonEmotions = Set(dream1.emotions).intersection(Set(dream2.emotions))
        if !commonEmotions.isEmpty {
            similarity += 0.3
        }
        
        // 标签相似度
        let commonTags = Set(dream1.tags).intersection(Set(dream2.tags))
        if !commonTags.isEmpty {
            similarity += Double(commonTags.count) * 0.1
        }
        
        // 内容相似度（简单关键词重叠）
        let keywords1 = Set(extractKeywords(from: dream1.content))
        let keywords2 = Set(extractKeywords(from: dream2.content))
        let commonKeywords = keywords1.intersection(keywords2)
        if !commonKeywords.isEmpty {
            similarity += min(Double(commonKeywords.count) / 5.0, 0.4)
        }
        
        // 清醒梦状态
        if dream1.isLucid && dream2.isLucid {
            similarity += 0.1
        }
        
        return min(similarity, 1.0)
    }
}
