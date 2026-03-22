//
//  DreamTimelineService.swift
//  DreamLog
//
//  Phase 86: Dream Timeline & Life Events Service
//  Managing timeline data and correlations
//

import Foundation
import SwiftData

@ModelActor
actor DreamTimelineService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Life Event Management
    
    /// Create a new life event
    func createLifeEvent(
        title: String,
        description: String? = nil,
        date: Date,
        endDate: Date? = nil,
        category: LifeEventCategory,
        impactLevel: ImpactLevel = .medium,
        emotions: [Emotion] = [],
        tags: [String] = [],
        relatedDreamIds: [UUID] = []
    ) async throws -> LifeEvent {
        let event = LifeEvent(
            title: title,
            description: description,
            date: date,
            endDate: endDate,
            category: category,
            impactLevel: impactLevel,
            emotions: emotions,
            tags: tags,
            relatedDreamIds: relatedDreamIds
        )
        modelContext.insert(event)
        try modelContext.save()
        return event
    }
    
    /// Update existing life event
    func updateLifeEvent(_ event: LifeEvent) async throws {
        event.updatedAt = Date()
        try modelContext.save()
    }
    
    /// Delete life event
    func deleteLifeEvent(_ event: LifeEvent) async throws {
        modelContext.delete(event)
        try modelContext.save()
    }
    
    /// Get life event by ID
    func getLifeEvent(id: UUID) async throws -> LifeEvent? {
        let descriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate<LifeEvent> { $0.id == id }
        )
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    /// Get life events for date range
    func getLifeEvents(dateRange: ClosedRange<Date>) async throws -> [LifeEvent] {
        let descriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate<LifeEvent> {
                $0.date >= dateRange.lowerBound && $0.date <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get life events by category
    func getLifeEvents(category: LifeEventCategory, dateRange: ClosedRange<Date>) async throws -> [LifeEvent] {
        let descriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate<LifeEvent> {
                $0.category == category.rawValue &&
                $0.date >= dateRange.lowerBound &&
                $0.date <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Get life events by impact level
    func getLifeEvents(impactLevel: ImpactLevel, dateRange: ClosedRange<Date>) async throws -> [LifeEvent] {
        let descriptor = FetchDescriptor<LifeEvent>(
            predicate: #Predicate<LifeEvent> {
                $0.impactLevel == impactLevel.rawValue &&
                $0.date >= dateRange.lowerBound &&
                $0.date <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Timeline Generation
    
    /// Generate unified timeline entries
    func generateTimeline(config: TimelineConfig) async throws -> [TimelineEntry] {
        var entries: [TimelineEntry] = []
        
        guard let dateRange = config.dateRange.dateRange else {
            return entries
        }
        
        // Add dreams
        if config.showDreams {
            let dreams = try getDreams(dateRange: dateRange)
            for dream in dreams {
                let entry = TimelineEntry(
                    id: dream.id,
                    date: dream.date,
                    type: .dream,
                    title: dream.title.isEmpty ? "无标题梦境" : dream.title,
                    subtitle: formatDreamSubtitle(dream),
                    description: dream.content,
                    category: nil,
                    impactLevel: nil,
                    emotions: dream.emotions,
                    tags: dream.tags,
                    clarity: dream.clarity,
                    isLucid: dream.isLucid
                )
                entries.append(entry)
            }
        }
        
        // Add life events
        if config.showLifeEvents {
            let events = try getLifeEvents(dateRange: dateRange)
            for event in events where config.selectedCategories.contains(event.category) &&
                                         event.impactLevel.rawValue >= config.minImpactLevel.rawValue {
                let entry = TimelineEntry(
                    id: event.id,
                    date: event.date,
                    type: .lifeEvent,
                    title: event.title,
                    subtitle: event.category.displayName,
                    description: event.description,
                    category: event.category.rawValue,
                    impactLevel: event.impactLevel,
                    emotions: event.emotions,
                    tags: event.tags,
                    clarity: nil,
                    isLucid: nil
                )
                entries.append(entry)
            }
        }
        
        // Sort by date
        return entries.sorted { $0.date < $1.date }
    }
    
    // MARK: - Correlation Analysis
    
    /// Analyze correlations between life events and dreams
    func analyzeCorrelations(dateRange: ClosedRange<Date>) async throws -> [DreamLifeCorrelation] {
        let events = try getLifeEvents(dateRange: dateRange)
        var correlations: [DreamLifeCorrelation] = []
        
        for event in events {
            // Find dreams within 7 days before and after the event
            let calendar = Calendar.current
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: event.date),
                  let endDate = calendar.date(byAdding: .day, value: 7, to: event.date) else {
                continue
            }
            
            let relatedDreams = try getDreams(dateRange: startDate...endDate)
            
            guard !relatedDreams.isEmpty else { continue }
            
            let correlation = analyzeCorrelation(event: event, dreams: relatedDreams)
            correlations.append(correlation)
        }
        
        return correlations.sorted { $0.correlationScore > $1.correlationScore }
    }
    
    /// Get timeline statistics
    func getStatistics(dateRange: ClosedRange<Date>) async throws -> TimelineStatistics {
        let dreams = try getDreams(dateRange: dateRange)
        let events = try getLifeEvents(dateRange: dateRange)
        
        // Category distribution
        var categoryDist: [LifeEventCategory: Int] = [:]
        for event in events {
            categoryDist[event.category, default: 0] += 1
        }
        
        // Impact distribution
        var impactDist: [ImpactLevel: Int] = [:]
        for event in events {
            impactDist[event.impactLevel, default: 0] += 1
        }
        
        // Calculate dreams/events per month
        let months = max(1, Calendar.current.dateComponents([.month], from: dateRange.lowerBound, to: dateRange.upperBound).month ?? 1)
        let dreamsPerMonth = Double(dreams.count) / Double(months)
        let eventsPerMonth = Double(events.count) / Double(months)
        
        // Get correlations
        let correlations = try analyzeCorrelations(dateRange: dateRange)
        
        // Find milestone events (transformative or high impact)
        let milestones = events.filter { $0.impactLevel == .transformative || $0.impactLevel == .high }
        
        // Calculate trend
        let trend = calculateDreamFrequencyTrend(dreams: dreams, dateRange: dateRange)
        
        // Average correlation score
        let avgCorrelation = correlations.isEmpty ? 0 : correlations.reduce(0) { $0 + $1.correlationScore } / Double(correlations.count)
        
        return TimelineStatistics(
            totalDreams: dreams.count,
            totalLifeEvents: events.count,
            dateRange: dateRange,
            dreamsPerMonth: dreamsPerMonth,
            eventsPerMonth: eventsPerMonth,
            categoryDistribution: categoryDist,
            impactDistribution: impactDist,
            topCorrelations: Array(correlations.prefix(10)),
            milestoneEvents: milestones,
            dreamFrequencyTrend: trend,
            averageCorrelationScore: avgCorrelation
        )
    }
    
    /// Link life event to dreams
    func linkEventToDreams(eventId: UUID, dreamIds: [UUID]) async throws {
        guard let event = try getLifeEvent(id: eventId) else {
            throw TimelineError.eventNotFound
        }
        
        event.relatedDreamIds = dreamIds
        try modelContext.save()
    }
    
    /// Get milestones achieved
    func getAchievedMilestones() async throws -> [TimelineMilestone] {
        var milestones: [TimelineMilestone] = []
        
        // Get all dreams and events
        let allDreams = try getDreams(dateRange: Date.distantPast...Date())
        let allEvents = try getLifeEvents(dateRange: Date.distantPast...Date())
        
        // Dream count milestones
        let dreamCounts = [10, 50, 100, 500, 1000]
        for count in dreamCounts where allDreams.count >= count {
            milestones.append(TimelineMilestone(
                id: UUID(),
                title: "梦境记录者",
                description: "记录了 \(count) 个梦境",
                icon: "🌙",
                achievedDate: allDreams[count - 1].date,
                requirement: .dreamCount(count),
                reward: nil
            ))
        }
        
        // Life event milestones
        let eventCounts = [5, 10, 25, 50]
        for count in eventCounts where allEvents.count >= count {
            milestones.append(TimelineMilestone(
                id: UUID(),
                title: "生活记录者",
                description: "标记了 \(count) 个生活事件",
                icon: "📍",
                achievedDate: allEvents[count - 1].date,
                requirement: .lifeEventsCount(count),
                reward: nil
            ))
        }
        
        // Correlation milestone
        let correlations = try analyzeCorrelations(dateRange: Date.distantPast...Date())
        if !correlations.isEmpty {
            milestones.append(TimelineMilestone(
                id: UUID(),
                title: "洞察发现者",
                description: "发现了梦境与生活的关联",
                icon: "💡",
                achievedDate: Date(),
                requirement: .correlationDiscovered,
                reward: nil
            ))
        }
        
        return milestones
    }
    
    // MARK: - Private Helpers
    
    private func getDreams(dateRange: ClosedRange<Date>) async throws -> [Dream] {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> {
                $0.date >= dateRange.lowerBound && $0.date <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    private func formatDreamSubtitle(_ dream: Dream) -> String {
        var parts: [String] = []
        
        if dream.isLucid {
            parts.append("清醒梦")
        }
        
        let clarityText = ["", "非常模糊", "模糊", "一般", "清晰", "非常清晰"]
        if dream.clarity > 0 && dream.clarity <= 5 {
            parts.append(clarityText[dream.clarity])
        }
        
        if !dream.emotions.isEmpty {
            let emotionIcons = dream.emotions.prefix(3).map { $0.icon }.joined()
            parts.append(emotionIcons)
        }
        
        return parts.joined(separator: " · ")
    }
    
    private func analyzeCorrelation(event: LifeEvent, dreams: [Dream]) -> DreamLifeCorrelation {
        let dreamCount = dreams.count
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidRate = Double(lucidCount) / Double(dreamCount)
        let avgClarity = Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(dreamCount)
        
        // Calculate emotion distribution
        var emotionCounts: [String: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionCounts[emotion.rawValue, default: 0] += 1
            }
        }
        
        // Determine pattern type and score
        var score: Double = 0
        var patternType: DreamLifeCorrelation.PatternType = .none
        var insights: [String] = []
        var recommendations: [String] = []
        
        // Check for patterns
        if dreamCount >= 5 {
            score += 0.3
            insights.append("事件前后记录了\(dreamCount)个梦境，数据充足")
        }
        
        if lucidRate > 0.3 {
            score += 0.25
            patternType = .lucidIncrease
            insights.append("清醒梦比例较高 (\(String(format: "%.0f%%", lucidRate * 100)))")
            recommendations.append("这个时期适合进行清醒梦练习")
        }
        
        if avgClarity > 4.0 {
            score += 0.2
            if patternType == .none { patternType = .clarityChange }
            insights.append("梦境清晰度较高 (平均\(String(format: "%.1f", avgClarity))/5)")
        }
        
        // Check dominant emotions
        if let topEmotion = emotionCounts.max(by: { $0.value < $1.value }) {
            if topEmotion.value >= Int(Double(dreamCount) * 0.5) {
                score += 0.15
                if patternType == .none { patternType = .emotionalShift }
                insights.append("主导情绪：\(topEmotion.key)")
            }
        }
        
        // Event impact factor
        switch event.impactLevel {
        case .transformative:
            score += 0.3
            insights.append("这是一个变革性事件，可能对梦境产生深远影响")
        case .high:
            score += 0.2
            insights.append("这是一个重大事件，与梦境关联性强")
        case .medium:
            score += 0.1
        case .low:
            break
        }
        
        // Cap score at 1.0
        score = min(score, 1.0)
        
        if recommendations.isEmpty {
            recommendations.append("继续记录梦境和生活事件，以发现更多关联")
        }
        
        return DreamLifeCorrelation(
            lifeEvent: event,
            relatedDreams: dreams,
            correlationScore: score,
            patternType: patternType,
            insights: insights,
            recommendations: recommendations
        )
    }
    
    private func calculateDreamFrequencyTrend(dreams: [Dream], dateRange: ClosedRange<Date>) -> TimelineStatistics.TrendDirection {
        guard dreams.count >= 4 else { return .stable }
        
        let calendar = Calendar.current
        
        // Split into two halves
        let midPoint = calendar.date(byAdding: .day, value: Int(calendar.dateComponents([.day], from: dateRange.lowerBound, to: dateRange.upperBound).day ?? 0) / 2, to: dateRange.lowerBound) ?? dateRange.lowerBound
        
        let firstHalf = dreams.filter { $0.date < midPoint }.count
        let secondHalf = dreams.filter { $0.date >= midPoint }.count
        
        let change = Double(secondHalf - firstHalf) / Double(max(firstHalf, 1))
        
        if change > 0.3 {
            return .increasing
        } else if change < -0.3 {
            return .decreasing
        } else if abs(change) < 0.1 {
            return .stable
        } else {
            return .fluctuating
        }
    }
}

// MARK: - Errors

enum TimelineError: LocalizedError {
    case eventNotFound
    case invalidDateRange
    case correlationAnalysisFailed
    
    var errorDescription: String? {
        switch self {
        case .eventNotFound: return "未找到该生活事件"
        case .invalidDateRange: return "无效的日期范围"
        case .correlationAnalysisFailed: return "关联分析失败"
        }
    }
}
