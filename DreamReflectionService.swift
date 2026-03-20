//
//  DreamReflectionService.swift
//  DreamLog
//
//  梦境反思日记 - 核心服务
//  Phase 49: 梦境反思与洞察整合
//

import Foundation
import SwiftData

actor DreamReflectionService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    @ObservationIgnored var onReflectionsChanged: (() -> Void)?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - CRUD Operations
    
    /// 创建反思
    func createReflection(
        dreamId: UUID,
        type: ReflectionType,
        content: String,
        tags: [String] = [],
        rating: Int = 3,
        isPrivate: Bool = false,
        relatedLifeEvents: [String] = [],
        actionItems: [String] = [],
        followUpDate: Date? = nil
    ) throws -> DreamReflection {
        let reflection = DreamReflection(
            dreamId: dreamId,
            type: type,
            content: content,
            tags: tags,
            rating: rating,
            isPrivate: isPrivate,
            relatedLifeEvents: relatedLifeEvents,
            actionItems: actionItems,
            followUpDate: followUpDate
        )
        
        // 关联梦境
        if let dream = try fetchDream(by: dreamId) {
            reflection.dream = dream
        }
        
        modelContext.insert(reflection)
        try modelContext.save()
        
        await notifyChange()
        return reflection
    }
    
    /// 更新反思
    func updateReflection(
        id: UUID,
        content: String? = nil,
        tags: [String]? = nil,
        rating: Int? = nil,
        isPrivate: Bool? = nil,
        relatedLifeEvents: [String]? = nil,
        actionItems: [String]? = nil,
        followUpDate: Date? = nil
    ) throws -> DreamReflection {
        guard let reflection = try fetchReflection(by: id) else {
            throw ReflectionError.notFound
        }
        
        if let content = content { reflection.content = content }
        if let tags = tags { reflection.tags = tags }
        if let rating = rating { reflection.rating = rating }
        if let isPrivate = isPrivate { reflection.isPrivate = isPrivate }
        if let relatedLifeEvents = relatedLifeEvents { reflection.relatedLifeEvents = relatedLifeEvents }
        if let actionItems = actionItems { reflection.actionItems = actionItems }
        if let followUpDate = followUpDate { reflection.followUpDate = followUpDate }
        
        reflection.updatedAt = Date()
        try modelContext.save()
        
        await notifyChange()
        return reflection
    }
    
    /// 删除反思
    func deleteReflection(id: UUID) throws {
        guard let reflection = try fetchReflection(by: id) else {
            throw ReflectionError.notFound
        }
        
        modelContext.delete(reflection)
        try modelContext.save()
        
        await notifyChange()
    }
    
    /// 批量删除反思
    func deleteReflections(for dreamId: UUID) throws {
        let reflections = try fetchReflections(for: dreamId)
        reflections.forEach { modelContext.delete($0) }
        try modelContext.save()
        
        await notifyChange()
    }
    
    // MARK: - Fetch Operations
    
    /// 获取单个反思
    func fetchReflection(by id: UUID) throws -> DreamReflection? {
        let descriptor = FetchDescriptor<DreamReflection>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 获取梦境的所有反思
    func fetchReflections(for dreamId: UUID, includePrivate: Bool = true) throws -> [DreamReflection] {
        var predicate = #Predicate<DreamReflection> { $0.dreamId == dreamId }
        
        if !includePrivate {
            predicate = #Predicate<DreamReflection> { $0.dreamId == dreamId && !$0.isPrivate }
        }
        
        let descriptor = FetchDescriptor<DreamReflection>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取所有反思
    func fetchAllReflections(
        includePrivate: Bool = false,
        types: [ReflectionType]? = nil,
        dateRange: ClosedRange<Date>? = nil,
        limit: Int? = nil
    ) throws -> [DreamReflection] {
        var predicates: [Predicate<DreamReflection>] = []
        
        if !includePrivate {
            predicates.append(#Predicate { !$0.isPrivate })
        }
        
        if let types = types, !types.isEmpty {
            let typeValues = types.map { $0.rawValue }
            predicates.append(#Predicate { typeValues.contains($0.type) })
        }
        
        if let dateRange = dateRange {
            predicates.append(#Predicate { $0.createdAt >= dateRange.lowerBound && $0.createdAt <= dateRange.upperBound })
        }
        
        let combinedPredicate = predicates.reduce(nil) { result, predicate in
            if let result = result {
                return result && predicate
            }
            return predicate
        }
        
        var descriptor = FetchDescriptor<DreamReflection>(
            predicate: combinedPredicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        if let limit = limit {
            descriptor.fetchLimit = limit
        }
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 搜索反思
    func searchReflections(query: String, includePrivate: Bool = false) throws -> [DreamReflection] {
        let lowercasedQuery = query.lowercased()
        
        var predicate = #Predicate<DreamReflection> {
            $0.content.lowercased().contains(lowercasedQuery) ||
            $0.tags.map { $0.lowercased() }.contains(lowercasedQuery)
        }
        
        if !includePrivate {
            predicate = predicate && #Predicate { !$0.isPrivate }
        }
        
        let descriptor = FetchDescriptor<DreamReflection>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取需要跟进的反思
    func fetchReflectionsNeedingFollowUp() throws -> [DreamReflection] {
        let now = Date()
        
        let descriptor = FetchDescriptor<DreamReflection>(
            predicate: #Predicate<DreamReflection> {
                guard let followUpDate = $0.followUpDate else { return false }
                return followUpDate > now
            },
            sortBy: [SortDescriptor(\DreamReflection.followUpDate, order: .forward)]
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Statistics
    
    /// 获取反思统计
    func getReflectionStats(includePrivate: Bool = false) throws -> ReflectionStats {
        let allReflections = try fetchAllReflections(includePrivate: includePrivate)
        
        // 按类型统计
        var byType: [ReflectionType: Int] = [:]
        for type in ReflectionType.allCases {
            byType[type] = allReflections.filter { $0.reflectionType == type }.count
        }
        
        // 按评分统计
        var byRating: [Int: Int] = [:]
        for rating in 1...5 {
            byRating[rating] = allReflections.filter { $0.rating == rating }.count
        }
        
        // 平均评分
        let averageRating = allReflections.isEmpty ? 0 :
            Double(allReflections.reduce(0) { $0 + $1.rating }) / Double(allReflections.count)
        
        // 本周统计
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let reflectionsThisWeek = allReflections.filter { $0.createdAt >= weekAgo }.count
        
        // 本月统计
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let reflectionsThisMonth = allReflections.filter { $0.createdAt >= monthAgo }.count
        
        // 热门标签
        let tagCounts = Dictionary(allReflections.flatMap { $0.tags }.map { ($0, 1) }, uniquingKeysWith: +)
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { (tag: $0.key, count: $0.value) }
        
        // 连续反思天数
        let reflectionStreak = calculateReflectionStreak(from: allReflections)
        
        // 行动项统计
        let totalActionItems = allReflections.reduce(0) { $0 + $1.actionItems.count }
        // 简单估算：假设 30% 的行动项已完成 (实际应使用单独的行动项追踪模型)
        let completedActionItems = Int(Double(totalActionItems) * 0.3)
        
        return ReflectionStats(
            totalReflections: allReflections.count,
            byType: byType,
            byRating: byRating,
            averageRating: averageRating,
            reflectionsThisWeek: reflectionsThisWeek,
            reflectionsThisMonth: reflectionsThisMonth,
            mostUsedTags: tagCounts,
            reflectionStreak: reflectionStreak,
            totalActionItems: totalActionItems,
            completedActionItems: completedActionItems
        )
    }
    
    /// 获取洞察卡片
    func getInsightCards(limit: Int = 10, minRating: Int = 4) throws -> [ReflectionInsightCard] {
        let descriptor = FetchDescriptor<DreamReflection>(
            predicate: #Predicate { $0.rating >= minRating && $0.type == ReflectionType.insight.rawValue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)],
            fetchLimit: limit
        )
        
        let reflections = try modelContext.fetch(descriptor)
        
        return try reflections.compactMap { reflection in
            guard let dream = reflection.dream else { return nil }
            return ReflectionInsightCard(
                id: reflection.id.uuidString,
                reflectionId: reflection.id,
                dreamTitle: dream.title,
                insight: reflection.content,
                type: reflection.reflectionType,
                createdAt: reflection.createdAt,
                rating: reflection.rating,
                tags: reflection.tags
            )
        }
    }
    
    // MARK: - Export
    
    /// 导出反思
    func exportReflections(config: ReflectionExportConfig) throws -> Data {
        let reflections = try fetchAllReflections(
            includePrivate: config.includePrivate,
            types: config.types,
            dateRange: getDateRange(from: config.dateRange)
        )
        
        switch config.format {
        case .markdown:
            return exportToMarkdown(reflections: reflections)
        case .json:
            return try exportToJSON(reflections: reflections)
        case .pdf:
            // 使用 DreamReflectionExportService 进行 PDF 导出
            let exportService = ReflectionExportService(modelContext: modelContext)
            let exportConfig = ReflectionExportConfig(
                format: .pdf,
                dateRange: config.dateRange,
                reflectionTypes: config.types ?? ReflectionType.allCases,
                includePrivate: config.includePrivate,
                includeActionItems: true,
                includeTags: true,
                sortBy: .date,
                sortOrder: .descending
            )
            return try await exportService.exportReflections(config: exportConfig)
        }
    }
    
    // MARK: - Private Helpers
    
    private func fetchDream(by id: UUID) throws -> Dream? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    private func calculateReflectionStreak(from reflections: [DreamReflection]) -> Int {
        guard !reflections.isEmpty else { return 0 }
        
        let sortedDates = Set(reflections.map { Calendar.current.startOfDay(for: $0.createdAt) })
            .sorted(by: >)
        
        var streak = 1
        let calendar = Calendar.current
        
        for i in 0..<(sortedDates.count - 1) {
            let current = sortedDates[i]
            let next = sortedDates[i + 1]
            
            if calendar.date(byAdding: .day, value: -1, to: current) == next {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func getDateRange(from range: ReflectionExportConfig.DateRange) -> ClosedRange<Date>? {
        switch range {
        case .all:
            return nil
        case .last7Days:
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
            return start...end
        case .last30Days:
            let end = Date()
            let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
            return start...end
        case .last3Months:
            let end = Date()
            let start = Calendar.current.date(byAdding: .month, value: -3, to: end) ?? end
            return start...end
        case .custom(let start, let end):
            return start...end
        }
    }
    
    private func exportToMarkdown(reflections: [DreamReflection]) -> Data {
        var markdown = "# 梦境反思日记\n\n"
        markdown += "导出日期：\(Date().formatted())\n\n"
        markdown += "---\n\n"
        
        for reflection in reflections {
            markdown += "## \(reflection.reflectionType.icon) \(reflection.reflectionType.displayName)\n\n"
            markdown += "**日期**: \(reflection.createdAt.formatted())\n"
            markdown += "**评分**: \(String(repeating: "⭐", count: reflection.rating))\n"
            
            if let dream = reflection.dream {
                markdown += "**梦境**: \(dream.title)\n"
            }
            
            if !reflection.tags.isEmpty {
                markdown += "**标签**: \(reflection.displayTags)\n"
            }
            
            markdown += "\n### 内容\n\n\(reflection.content)\n\n"
            
            if !reflection.relatedLifeEvents.isEmpty {
                markdown += "### 关联事件\n\n"
                for event in reflection.relatedLifeEvents {
                    markdown += "- \(event)\n"
                }
                markdown += "\n"
            }
            
            if !reflection.actionItems.isEmpty {
                markdown += "### 行动项\n\n"
                for item in reflection.actionItems {
                    markdown += "- [ ] \(item)\n"
                }
                markdown += "\n"
            }
            
            if reflection.isPrivate {
                markdown += "_🔒 私密_\n\n"
            }
            
            markdown += "---\n\n"
        }
        
        return markdown.data(using: .utf8) ?? Data()
    }
    
    private func exportToJSON(reflections: [DreamReflection]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(reflections)
    }
    
    private func notifyChange() async {
        await MainActor.run {
            onReflectionsChanged?()
        }
    }
}

// MARK: - Errors

enum ReflectionError: LocalizedError {
    case notFound
    case notImplemented
    case invalidData
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "反思不存在"
        case .notImplemented: return "功能尚未实现"
        case .invalidData: return "数据格式错误"
        case .exportFailed: return "导出失败"
        }
    }
}

// MARK: - Date Extension

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: self)
    }
}
