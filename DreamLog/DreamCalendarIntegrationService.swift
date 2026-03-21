//
//  DreamCalendarIntegrationService.swift
//  DreamLog
//
//  Phase 77: Dream Calendar Integration - Core Service
//  梦境与日历事件关联分析核心服务
//

import Foundation
import SwiftData
import EventKit
import NaturalLanguage

@MainActor
final class DreamCalendarIntegrationService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let eventStore = EKEventStore()
    private var config: CalendarIntegrationConfig
    private var lastSyncDate: Date?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.config = .default
        loadConfig()
    }
    
    // MARK: - Configuration
    
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "CalendarIntegrationConfig"),
           let decoded = try? JSONDecoder().decode(CalendarIntegrationConfig.self, from: data) {
            self.config = decoded
        }
    }
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "CalendarIntegrationConfig")
        }
    }
    
    func updateConfig(_ newConfig: CalendarIntegrationConfig) {
        self.config = newConfig
        saveConfig()
    }
    
    // MARK: - Permission Management
    
    /// 请求日历访问权限
    func requestPermission() async -> CalendarPermissionStatus {
        return await withCheckedContinuation { continuation in
            eventStore.requestFullAccessToEvents { granted, error in
                if granted {
                    continuation.resume(returning: .fullAccess)
                } else if let error = error {
                    print("Calendar permission error: \(error.localizedDescription)")
                    continuation.resume(returning: .denied)
                } else {
                    continuation.resume(returning: .denied)
                }
            }
        }
    }
    
    /// 检查当前权限状态
    func checkPermissionStatus() -> CalendarPermissionStatus {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .fullAccess:
            return .fullAccess
        @unknown default:
            return .notDetermined
        }
    }
    
    // MARK: - Event Sync
    
    /// 同步日历事件
    func syncEvents(dateRange: DateRange) async throws -> Int {
        guard config.enabled else {
            throw CalendarIntegrationError.featureDisabled
        }
        
        guard checkPermissionStatus().canAccess else {
            throw CalendarIntegrationError.permissionDenied
        }
        
        let calendars = config.allowedCalendars.isEmpty
            ? eventStore.calendars(for: .event)
            : eventStore.calendars(for: .event).filter { config.allowedCalendars.contains($0.title) }
        
        var syncedCount = 0
        
        for calendar in calendars {
            let predicate = eventStore.predicateForEvents(
                withStart: dateRange.start,
                end: dateRange.end,
                calendars: [calendar]
            )
            
            let events = eventStore.events(matching: predicate)
            
            for event in events {
                try await syncSingleEvent(event)
                syncedCount += 1
            }
        }
        
        lastSyncDate = Date()
        return syncedCount
    }
    
    /// 同步单个事件
    private func syncSingleEvent(_ ekEvent: EKEvent) async throws {
        // 检查是否已存在
        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.eventId == ekEvent.calendarItemIdentifier }
        )
        
        let existing = try modelContext.fetch(descriptor).first
        
        if let existing = existing {
            // 更新现有事件
            existing.title = ekEvent.title
            existing.startDate = ekEvent.startDate
            existing.endDate = ekEvent.endDate
            existing.location = ekEvent.location
            existing.notes = ekEvent.notes
            existing.calendarName = ekEvent.calendar.title
            existing.eventType = detectEventType(ekEvent)
            existing.isAllDay = ekEvent.isAllDay
            existing.lastSyncedAt = Date()
        } else {
            // 创建新事件
            let newEvent = CalendarEvent(
                eventId: ekEvent.calendarItemIdentifier,
                title: ekEvent.title,
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                location: ekEvent.location,
                notes: ekEvent.notes,
                calendarName: ekEvent.calendar.title,
                eventType: detectEventType(ekEvent),
                isAllDay: ekEvent.isAllDay
            )
            modelContext.insert(newEvent)
        }
        
        try modelContext.save()
    }
    
    /// 检测事件类型
    private func detectEventType(_ event: EKEvent) -> CalendarEventType {
        let title = event.title.lowercased()
        let notes = (event.notes ?? "").lowercased()
        let location = (event.location ?? "").lowercased()
        
        let combinedText = "\(title) \(notes) \(location)"
        
        // 关键词匹配
        let typeKeywords: [(CalendarEventType, [String])] = [
            (.work, ["工作", "会议", "project", "meeting", "deadline", "汇报", "演讲"]),
            (.meeting, ["会议", "meet", "讨论", "conference", "call", "zoom"]),
            (.personal, ["个人", "personal", "private", "自己"]),
            (.family, ["家庭", "家人", "family", "孩子", "父母", "配偶"]),
            (.social, ["聚会", "派对", "party", "朋友", "聚餐", "social"]),
            (.exercise, ["运动", "健身", "gym", "run", "yoga", "锻炼", "球"]),
            (.travel, ["旅行", "旅游", "trip", "travel", "flight", "酒店", "机场"]),
            (.medical, ["医院", "医生", "medical", "doctor", "检查", "体检"]),
            (.education, ["学习", "课程", "class", "study", "培训", "讲座", "学校"]),
            (.entertainment, ["电影", "娱乐", "movie", "concert", "演出", "游戏"]),
            (.sleep, ["睡眠", "睡觉", "sleep", "休息", "nap"]),
            (.meal, ["吃饭", "用餐", "meal", "lunch", "dinner", "早餐", "晚餐"])
        ]
        
        for (type, keywords) in typeKeywords {
            if keywords.contains(where: { combinedText.contains($0) }) {
                return type
            }
        }
        
        return .other
    }
    
    // MARK: - Dream-Event Linking
    
    /// 自动关联梦境与事件
    func autoLinkDreams(_ dreams: [Dream]) async {
        guard config.enabled else { return }
        
        for dream in dreams {
            await linkDreamToEvents(dream)
        }
    }
    
    /// 关联单个梦境到事件
    private func linkDreamToEvents(_ dream: Dream) async {
        let dreamDate = dream.date
        let windowHours = Double(config.defaultLinkWindow)
        
        // 查找时间窗口内的事件
        let startDate = dreamDate.addingTimeInterval(-windowHours * 3600)
        let endDate = dreamDate.addingTimeInterval(windowHours * 3600)
        
        let descriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate {
                $0.startDate >= startDate && $0.startDate <= endDate
            }
        )
        
        guard let events = try? modelContext.fetch(descriptor) else { return }
        
        for event in events {
            let correlation = calculateCorrelation(dream: dream, event: event)
            
            if correlation.strength > 0.3 { // 阈值
                linkDreamAndEvent(dream: dream, event: event, correlation: correlation)
            }
        }
    }
    
    /// 计算梦境与事件的关联强度
    private func calculateCorrelation(dream: Dream, event: EKEvent) -> (strength: Double, relation: TimeRelation) {
        let dreamDate = dream.date
        let eventDate = event.startDate
        
        // 计算时间关系
        let timeDiff = dreamDate.timeIntervalSince(eventDate)
        let hoursDiff = timeDiff / 3600
        
        let relation: TimeRelation
        if hoursDiff > 0 && hoursDiff < 12 {
            relation = .beforeNight // 事件在梦境前一晚
        } else if hoursDiff > -12 && hoursDiff < 0 {
            relation = .afterMorning // 事件在梦境次日早晨
        } else if hoursDiff >= 12 && hoursDiff < 24 {
            relation = .beforeSameDay // 事件在梦境当天之前
        } else if hoursDiff >= -24 && hoursDiff <= -12 {
            relation = .afterSameDay // 事件在梦境当天之后
        } else {
            relation = .recurring
        }
        
        // 计算关联强度
        var strength = 0.0
        
        // 时间接近度 (0-0.4)
        let timeProximity = max(0, 1 - abs(hoursDiff) / 48)
        strength += timeProximity * 0.4
        
        // 内容相关性 (0-0.4)
        let contentCorrelation = calculateContentCorrelation(dream: dream, event: event)
        strength += contentCorrelation * 0.4
        
        // 事件重要性 (0-0.2)
        let importance = calculateEventImportance(event)
        strength += importance * 0.2
        
        return (strength, relation)
    }
    
    /// 计算内容相关性
    private func calculateContentCorrelation(dream: Dream, event: EKEvent) -> Double {
        let dreamText = "\(dream.title) \(dream.content)".lowercased()
        let eventText = "\(event.title) \((event.notes ?? "")".lowercased()
        
        // 提取关键词
        let dreamKeywords = extractKeywords(from: dreamText)
        let eventKeywords = extractKeywords(from: eventText)
        
        // 计算重叠度
        let commonKeywords = Set(dreamKeywords).intersection(Set(eventKeywords))
        let totalKeywords = Set(dreamKeywords).union(Set(eventKeywords)).count
        
        guard totalKeywords > 0 else { return 0 }
        
        return Double(commonKeywords.count) / Double(totalKeywords)
    }
    
    /// 提取关键词
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag, [.personalName, .organizationName, .placeName].contains(tag) {
                let word = String(text[range])
                if word.count > 2 {
                    keywords.append(word.lowercased())
                }
            }
        }
        
        // 添加名词
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range])
                if word.count > 3 && !isStopWord(word) {
                    keywords.append(word.lowercased())
                }
            }
        }
        
        return keywords
    }
    
    /// 检查是否为停用词
    private func isStopWord(_ word: String) -> Bool {
        let stopWords = ["the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
                        "have", "has", "had", "do", "does", "did", "will", "would", "could", "should",
                        "的", "了", "是", "在", "我", "有", "和", "就", "不", "人", "都", "一", "一个"]
        return stopWords.contains(word.lowercased())
    }
    
    /// 计算事件重要性
    private func calculateEventImportance(_ event: EKEvent) -> Double {
        var importance = 0.5
        
        // 全天事件通常更重要
        if event.isAllDay {
            importance += 0.2
        }
        
        // 有地点的事件可能更重要
        if event.location != nil {
            importance += 0.1
        }
        
        // 有备注的事件可能更详细
        if !(event.notes ?? "").isEmpty {
            importance += 0.1
        }
        
        // 特定类型事件更重要
        let importantTypes: [CalendarEventType] = [.medical, .travel, .work, .family]
        if importantTypes.contains(detectEventType(event)) {
            importance += 0.1
        }
        
        return min(1.0, importance)
    }
    
    /// 创建梦境与事件的关联
    private func linkDreamAndEvent(dream: Dream, event: CalendarEvent, correlation: (strength: Double, relation: TimeRelation)) {
        // 添加关联记录
        let correlationRecord = DreamEventCorrelation(
            dreamId: dream.persistentModelID,
            eventId: event.eventId,
            timeRelation: correlation.relation,
            correlationStrength: correlation.strength
        )
        modelContext.insert(correlationRecord)
        
        // 关联梦境和事件
        if !event.linkedDreams.contains(where: { $0.persistentModelID == dream.persistentModelID }) {
            event.linkedDreams.append(dream)
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Statistics
    
    /// 获取关联统计
    func getCorrelationStats(dateRange: DateRange) async -> CalendarCorrelationStats {
        // 获取关联记录
        let correlationDescriptor = FetchDescriptor<DreamEventCorrelation>(
            predicate: #Predicate { $0.createdAt >= dateRange.start && $0.createdAt <= dateRange.end }
        )
        
        let correlations = (try? modelContext.fetch(correlationDescriptor)) ?? []
        
        // 获取事件
        let eventDescriptor = FetchDescriptor<CalendarEvent>()
        let events = (try? modelContext.fetch(eventDescriptor)) ?? []
        
        // 计算统计
        let totalLinkedDreams = Set(correlations.map { $0.dreamId }).count
        let totalEvents = events.count
        let averageStrength = correlations.isEmpty ? 0 : correlations.map { $0.correlationStrength }.reduce(0, +) / Double(correlations.count)
        
        // 事件类型统计
        var eventTypeCounts: [CalendarEventType: Int] = [:]
        for event in events {
            eventTypeCounts[event.eventType, default: 0] += 1
        }
        let topEventTypes = eventTypeCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        
        // 时间关系统计
        var relationCounts: [TimeRelation: Int] = [:]
        for correlation in correlations {
            relationCounts[correlation.timeRelation, default: 0] += 1
        }
        let topRelations = relationCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
        
        // 每周模式
        var weeklyPattern = [Int](repeating: 0, count: 7)
        for correlation in correlations {
            let dayOfWeek = Calendar.current.component(.weekday, from: correlation.createdAt) - 1
            weeklyPattern[dayOfWeek] += 1
        }
        
        // 最近关联
        let recentCorrelations = correlations.prefix(10).map { correlation in
            DreamEventCorrelationInfo(
                dreamTitle: "梦境", // 需要从 dreamId 获取
                eventTitle: "事件", // 需要从 eventId 获取
                eventType: "事件类型",
                timeRelation: correlation.timeRelation.rawValue,
                date: correlation.createdAt
            )
        }
        
        return CalendarCorrelationStats(
            totalLinkedDreams: totalLinkedDreams,
            totalEvents: totalEvents,
            averageCorrelationStrength: averageStrength,
            topEventTypes: topEventTypes,
            topTimeRelations: topRelations,
            weeklyPattern: weeklyPattern,
            recentCorrelations: Array(recentCorrelations)
        )
    }
    
    // MARK: - Suggestions
    
    /// 生成基于日历的建议
    func generateSuggestions() async -> [CalendarBasedSuggestion] {
        var suggestions: [CalendarBasedSuggestion] = []
        
        // 获取 upcoming events
        let tomorrow = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let nextWeek = Date().addingTimeInterval(7 * 86400)
        
        let upcomingDescriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.startDate >= tomorrow && $0.startDate <= nextWeek }
        )
        
        guard let upcomingEvents = try? modelContext.fetch(upcomingDescriptor) else { return [] }
        
        // 高压力事件建议
        let highStressEvents = upcomingEvents.filter {
            [.work, .meeting, .medical].contains($0.eventType)
        }
        
        if !highStressEvents.isEmpty {
            suggestions.append(CalendarBasedSuggestion(
                title: "压力管理建议",
                description: "您即将有 \(highStressEvents.count) 个高压力事件，建议睡前进行放松冥想",
                suggestionType: .stress,
                priority: .high,
                relatedEvents: highStressEvents.map { $0.eventId },
                actionItems: [
                    "睡前进行 10 分钟冥想",
                    "记录担忧事项，避免带入梦境",
                    "尝试梦境孵育技巧"
                ]
            ))
        }
        
        // 创意机会建议
        let creativeEvents = upcomingEvents.filter {
            [.education, .entertainment, .social].contains($0.eventType)
        }
        
        if !creativeEvents.isEmpty {
            suggestions.append(CalendarBasedSuggestion(
                title: "创意灵感机会",
                description: " upcoming 创意活动可能激发有趣梦境，建议记录",
                suggestionType: .opportunity,
                priority: .medium,
                relatedEvents: creativeEvents.map { $0.eventId },
                actionItems: [
                    "活动前设定梦境意图",
                    "床头准备记录工具",
                    "醒后立即记录梦境"
                ]
            ))
        }
        
        return suggestions
    }
    
    // MARK: - Timeline
    
    /// 生成时间线索引
    func generateTimeline(dateRange: DateRange) async -> [TimelineItem] {
        var items: [TimelineItem] = []
        
        // 获取梦境
        let dreamDescriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.date >= dateRange.start && $0.date <= dateRange.end }
        )
        let dreams = (try? modelContext.fetch(dreamDescriptor)) ?? []
        
        // 获取事件
        let eventDescriptor = FetchDescriptor<CalendarEvent>(
            predicate: #Predicate { $0.startDate >= dateRange.start && $0.startDate <= dateRange.end }
        )
        let events = (try? modelContext.fetch(eventDescriptor)) ?? []
        
        // 添加梦境项
        for dream in dreams {
            items.append(TimelineItem(
                id: UUID(),
                date: dream.date,
                itemType: .dream,
                title: dream.title,
                subtitle: dream.tags.first,
                icon: "🌙",
                color: dream.primaryEmotion?.color ?? "9B59B6",
                isLinked: !dream.linkedEvents.isEmpty
            ))
        }
        
        // 添加事件项
        for event in events {
            items.append(TimelineItem(
                id: UUID(),
                date: event.startDate,
                itemType: .event,
                title: event.title,
                subtitle: event.eventType.rawValue,
                icon: event.eventType.icon,
                color: "#" + event.eventType.color,
                isLinked: !event.linkedDreams.isEmpty
            ))
        }
        
        // 按日期排序
        items.sort { $0.date < $1.date }
        
        return items
    }
    
    // MARK: - Manual Linking
    
    /// 手动关联梦境和事件
    func manuallyLink(dream: Dream, event: CalendarEvent) {
        if !event.linkedDreams.contains(where: { $0.persistentModelID == dream.persistentModelID }) {
            event.linkedDreams.append(dream)
            
            let correlation = DreamEventCorrelation(
                dreamId: dream.persistentModelID,
                eventId: event.eventId,
                timeRelation: .beforeSameDay, // 默认
                correlationStrength: 1.0 // 手动关联设为最高
            )
            modelContext.insert(correlation)
            
            try? modelContext.save()
        }
    }
    
    /// 取消关联
    func unlink(dream: Dream, event: CalendarEvent) {
        event.linkedDreams.removeAll { $0.persistentModelID == dream.persistentModelID }
        
        let descriptor = FetchDescriptor<DreamEventCorrelation>(
            predicate: #Predicate { $0.dreamId == dream.persistentModelID && $0.eventId == event.eventId }
        )
        
        if let correlations = try? modelContext.fetch(descriptor) {
            for correlation in correlations {
                modelContext.delete(correlation)
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - Date Range

struct DateRange {
    var start: Date
    var end: Date
    
    static func thisWeek() -> DateRange {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? now
        return DateRange(start: startOfWeek, end: endOfWeek)
    }
    
    static func thisMonth() -> DateRange {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now
        return DateRange(start: startOfMonth, end: endOfMonth)
    }
    
    static func last30Days() -> DateRange {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -30, to: end) ?? end
        return DateRange(start: start, end: end)
    }
}

// MARK: - Errors

enum CalendarIntegrationError: LocalizedError {
    case featureDisabled
    case permissionDenied
    case syncFailed(String)
    case eventNotFound
    
    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "日历集成功能已禁用"
        case .permissionDenied:
            return "没有日历访问权限"
        case .syncFailed(let reason):
            return "同步失败：\(reason)"
        case .eventNotFound:
            return "未找到指定事件"
        }
    }
}

// MARK: - Dream Extension

extension Dream {
    var linkedEvents: [CalendarEvent] {
        // 通过 DreamEventCorrelation 获取关联事件
        // 实际实现需要在 Dream 模型中添加 relationship
        return []
    }
}
