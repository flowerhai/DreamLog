//
//  DreamTimelineTests.swift
//  DreamLogTests
//
//  Phase 86: Dream Timeline & Life Events Tests
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamTimelineTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let schema = Schema([
            Dream.self,
            LifeEvent.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    // MARK: - Life Event Tests
    
    func testCreateLifeEvent() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        let event = try await service.createLifeEvent(
            title: "新工作开始",
            description: "开始了新的职业生涯",
            date: Date(),
            category: .career,
            impactLevel: .high,
            emotions: [.excited, .nervous],
            tags: ["工作", "新开始"]
        )
        
        XCTAssertEqual(event.title, "新工作开始")
        XCTAssertEqual(event.category, .career)
        XCTAssertEqual(event.impactLevel, .high)
        XCTAssertEqual(event.emotions.count, 2)
        XCTAssertEqual(event.tags.count, 2)
    }
    
    func testUpdateLifeEvent() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        let event = try await service.createLifeEvent(
            title: "原始标题",
            date: Date(),
            category: .personal
        )
        
        event.title = "更新后的标题"
        event.description = "新描述"
        
        try await service.updateLifeEvent(event)
        
        let fetched = try await service.getLifeEvent(id: event.id)
        XCTAssertEqual(fetched?.title, "更新后的标题")
        XCTAssertEqual(fetched?.description, "新描述")
    }
    
    func testDeleteLifeEvent() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        let event = try await service.createLifeEvent(
            title: "要删除的事件",
            date: Date(),
            category: .other
        )
        
        try await service.deleteLifeEvent(event)
        
        let fetched = try await service.getLifeEvent(id: event.id)
        XCTAssertNil(fetched)
    }
    
    func testGetLifeEventsByDateRange() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        let calendar = Calendar.current
        
        // Create events on different dates
        let today = Date()
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            XCTFail("Failed to create dates")
            return
        }
        
        _ = try await service.createLifeEvent(title: "昨天", date: yesterday, category: .personal)
        _ = try await service.createLifeEvent(title: "今天", date: today, category: .personal)
        _ = try await service.createLifeEvent(title: "明天", date: tomorrow, category: .personal)
        
        let range = today...today
        let events = try await service.getLifeEvents(dateRange: range)
        
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.title, "今天")
    }
    
    func testGetLifeEventsByCategory() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        _ = try await service.createLifeEvent(title: "工作事件", date: Date(), category: .career)
        _ = try await service.createLifeEvent(title: "个人事件", date: Date(), category: .personal)
        _ = try await service.createLifeEvent(title: "另一个工作事件", date: Date(), category: .career)
        
        let careerEvents = try await service.getLifeEvents(
            category: .career,
            dateRange: Date.distantPast...Date()
        )
        
        XCTAssertEqual(careerEvents.count, 2)
    }
    
    func testGetLifeEventsByImpactLevel() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        _ = try await service.createLifeEvent(title: "低影响", date: Date(), category: .other, impactLevel: .low)
        _ = try await service.createLifeEvent(title: "高影响", date: Date(), category: .other, impactLevel: .high)
        _ = try await service.createLifeEvent(title: "变革性", date: Date(), category: .other, impactLevel: .transformative)
        
        let highImpact = try await service.getLifeEvents(
            impactLevel: .high,
            dateRange: Date.distantPast...Date()
        )
        
        XCTAssertEqual(highImpact.count, 1)
        XCTAssertEqual(highImpact.first?.title, "高影响")
    }
    
    // MARK: - Timeline Generation Tests
    
    func testGenerateTimelineWithDreamsAndEvents() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create dreams
        let dream1 = Dream(title: "梦境 1", content: "内容", date: Date().addingTimeInterval(-86400))
        let dream2 = Dream(title: "梦境 2", content: "内容", date: Date())
        modelContext.insert(dream1)
        modelContext.insert(dream2)
        
        // Create life event
        _ = try await service.createLifeEvent(title: "事件", date: Date(), category: .personal)
        
        try modelContext.save()
        
        var config = TimelineConfig.default
        config.dateRange = .last7Days
        
        let entries = try await service.generateTimeline(config: config)
        
        XCTAssertGreaterThanOrEqual(entries.count, 3)
        
        let dreamEntries = entries.filter { $0.type == .dream }
        let eventEntries = entries.filter { $0.type == .lifeEvent }
        
        XCTAssertEqual(dreamEntries.count, 2)
        XCTAssertEqual(eventEntries.count, 1)
    }
    
    func testGenerateTimelineWithFilters() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create events in different categories
        _ = try await service.createLifeEvent(title: "个人事件", date: Date(), category: .personal)
        _ = try await service.createLifeEvent(title: "工作事件", date: Date(), category: .career)
        
        var config = TimelineConfig.default
        config.dateRange = .last7Days
        config.showDreams = false
        config.selectedCategories = [.personal]
        
        let entries = try await service.generateTimeline(config: config)
        
        // Should only include personal events
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "个人事件")
    }
    
    func testGenerateTimelineWithImpactFilter() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        _ = try await service.createLifeEvent(title: "低影响", date: Date(), category: .other, impactLevel: .low)
        _ = try await service.createLifeEvent(title: "高影响", date: Date(), category: .other, impactLevel: .high)
        
        var config = TimelineConfig.default
        config.dateRange = .last7Days
        config.showDreams = false
        config.minImpactLevel = .high
        
        let entries = try await service.generateTimeline(config: config)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "高影响")
    }
    
    // MARK: - Correlation Analysis Tests
    
    func testAnalyzeCorrelations() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        let calendar = Calendar.current
        
        // Create life event
        let eventDate = Date()
        let event = try await service.createLifeEvent(
            title: "重要事件",
            date: eventDate,
            category: .career,
            impactLevel: .transformative
        )
        
        // Create dreams around the event
        guard let beforeDate = calendar.date(byAdding: .day, value: -3, to: eventDate),
              let afterDate = calendar.date(byAdding: .day, value: 2, to: eventDate) else {
            XCTFail("Failed to create dates")
            return
        }
        
        for i in 0..<5 {
            let dreamDate = calendar.date(byAdding: .day, value: i - 3, to: eventDate) ?? eventDate
            let dream = Dream(
                title: "梦境 \(i)",
                content: "内容",
                date: dreamDate,
                clarity: 4,
                isLucid: i % 2 == 0
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        let correlations = try await service.analyzeCorrelations(dateRange: Date.distantPast...Date())
        
        XCTAssertGreaterThan(correlations.count, 0)
        let eventCorrelation = correlations.first { $0.lifeEvent.id == event.id }
        XCTAssertNotNil(eventCorrelation)
        XCTAssertEqual(eventCorrelation?.relatedDreams.count, 5)
    }
    
    func testCorrelationPatternDetection() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create high-impact event
        let event = try await service.createLifeEvent(
            title: "变革性事件",
            date: Date(),
            category: .personal,
            impactLevel: .transformative
        )
        
        // Create many lucid dreams around the event
        let calendar = Calendar.current
        for i in 0..<10 {
            let dreamDate = calendar.date(byAdding: .day, value: i - 5, to: event.date) ?? event.date
            let dream = Dream(
                title: "清醒梦 \(i)",
                content: "内容",
                date: dreamDate,
                clarity: 5,
                isLucid: true
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        let correlations = try await service.analyzeCorrelations(dateRange: Date.distantPast...Date())
        
        if let correlation = correlations.first(where: { $0.lifeEvent.id == event.id }) {
            XCTAssertEqual(correlation.patternType, .lucidIncrease)
            XCTAssertGreaterThan(correlation.correlationScore, 0.5)
        }
    }
    
    // MARK: - Statistics Tests
    
    func testGetStatistics() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create dreams
        for i in 0..<20 {
            let dream = Dream(
                title: "梦境 \(i)",
                content: "内容",
                date: Date().addingTimeInterval(Double(i) * -86400),
                clarity: 3,
                isLucid: i % 3 == 0
            )
            modelContext.insert(dream)
        }
        
        // Create life events
        _ = try await service.createLifeEvent(title: "事件 1", date: Date(), category: .career)
        _ = try await service.createLifeEvent(title: "事件 2", date: Date(), category: .personal)
        _ = try await service.createLifeEvent(title: "事件 3", date: Date(), category: .health, impactLevel: .high)
        
        try modelContext.save()
        
        let stats = try await service.getStatistics(dateRange: Date.distantPast...Date())
        
        XCTAssertEqual(stats.totalDreams, 20)
        XCTAssertEqual(stats.totalLifeEvents, 3)
        XCTAssertEqual(stats.categoryDistribution[.career], 1)
        XCTAssertEqual(stats.categoryDistribution[.personal], 1)
        XCTAssertEqual(stats.categoryDistribution[.health], 1)
        XCTAssertEqual(stats.impactDistribution[.high], 1)
        XCTAssertEqual(stats.impactDistribution[.medium], 2)
    }
    
    func testGetMilestones() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create enough dreams for milestone
        for i in 0..<15 {
            let dream = Dream(
                title: "梦境 \(i)",
                content: "内容",
                date: Date().addingTimeInterval(Double(i) * -86400)
            )
            modelContext.insert(dream)
        }
        
        try modelContext.save()
        
        let milestones = try await service.getAchievedMilestones()
        
        // Should have dream count milestone (10 dreams)
        let dreamMilestone = milestones.first { 
            switch $0.requirement {
            case .dreamCount(let count): return count == 10
            default: return false
            }
        }
        XCTAssertNotNil(dreamMilestone)
    }
    
    // MARK: - Link Event to Dreams Tests
    
    func testLinkEventToDreams() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create event
        let event = try await service.createLifeEvent(
            title: "关联事件",
            date: Date(),
            category: .personal
        )
        
        // Create dreams
        var dreamIds: [UUID] = []
        for i in 0..<3 {
            let dream = Dream(
                title: "梦境 \(i)",
                content: "内容",
                date: Date()
            )
            modelContext.insert(dream)
            dreamIds.append(dream.id)
        }
        
        try modelContext.save()
        
        try await service.linkEventToDreams(eventId: event.id, dreamIds: dreamIds)
        
        let updatedEvent = try await service.getLifeEvent(id: event.id)
        XCTAssertEqual(updatedEvent?.relatedDreamIds.count, 3)
    }
    
    // MARK: - Life Event Category Tests
    
    func testLifeEventCategoryProperties() {
        for category in LifeEventCategory.allCases {
            XCTAssertFalse(category.displayName.isEmpty)
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.color.isEmpty)
        }
    }
    
    func testImpactLevelProperties() {
        for level in ImpactLevel.allCases {
            XCTAssertFalse(level.displayName.isEmpty)
            XCTAssertFalse(level.color.isEmpty)
        }
        
        // Test ordering
        XCTAssertLessThan(ImpactLevel.low.rawValue, ImpactLevel.medium.rawValue)
        XCTAssertLessThan(ImpactLevel.medium.rawValue, ImpactLevel.high.rawValue)
        XCTAssertLessThan(ImpactLevel.high.rawValue, ImpactLevel.transformative.rawValue)
    }
    
    // MARK: - Timeline Entry Tests
    
    func testTimelineEntryCreation() {
        let dreamEntry = TimelineEntry(
            id: UUID(),
            date: Date(),
            type: .dream,
            title: "测试梦境",
            subtitle: "副标题",
            description: "描述",
            category: nil,
            impactLevel: nil,
            emotions: [.happy],
            tags: ["标签"],
            clarity: 4,
            isLucid: true
        )
        
        XCTAssertEqual(dreamEntry.type, .dream)
        XCTAssertEqual(dreamEntry.clarity, 4)
        XCTAssertEqual(dreamEntry.isLucid, true)
        XCTAssertNil(dreamEntry.impactLevel)
        
        let eventEntry = TimelineEntry(
            id: UUID(),
            date: Date(),
            type: .lifeEvent,
            title: "测试事件",
            subtitle: "事件副标题",
            description: "事件描述",
            category: "personal",
            impactLevel: .high,
            emotions: [],
            tags: [],
            clarity: nil,
            isLucid: nil
        )
        
        XCTAssertEqual(eventEntry.type, .lifeEvent)
        XCTAssertEqual(eventEntry.impactLevel, .high)
        XCTAssertNil(eventEntry.clarity)
    }
    
    // MARK: - Config Tests
    
    func testTimelineConfigDefault() {
        let config = TimelineConfig.default
        
        XCTAssertTrue(config.showDreams)
        XCTAssertTrue(config.showLifeEvents)
        XCTAssertEqual(config.selectedCategories.count, LifeEventCategory.allCases.count)
        XCTAssertEqual(config.minImpactLevel, .low)
        XCTAssertEqual(config.dateRange, .last90Days)
        XCTAssertEqual(config.groupByTime, .week)
    }
    
    func testDateRangeCalculations() {
        let now = Date()
        
        let range30Days = TimelineConfig.DateRange.last30Days.dateRange
        XCTAssertNotNil(range30Days)
        
        let rangeAll = TimelineConfig.DateRange.all.dateRange
        XCTAssertNil(rangeAll)
    }
    
    // MARK: - Error Tests
    
    func testTimelineErrorMessages() {
        XCTAssertEqual(TimelineError.eventNotFound.errorDescription, "未找到该生活事件")
        XCTAssertEqual(TimelineError.invalidDateRange.errorDescription, "无效的日期范围")
        XCTAssertEqual(TimelineError.correlationAnalysisFailed.errorDescription, "关联分析失败")
    }
    
    // MARK: - Performance Tests
    
    func testTimelineGenerationPerformance() async throws {
        let service = DreamTimelineService(modelContext: modelContext)
        
        // Create 100 dreams
        for i in 0..<100 {
            let dream = Dream(
                title: "梦境 \(i)",
                content: "内容 \(i)",
                date: Date().addingTimeInterval(Double(i) * -86400)
            )
            modelContext.insert(dream)
        }
        
        // Create 20 life events
        for i in 0..<20 {
            _ = try await service.createLifeEvent(
                title: "事件 \(i)",
                date: Date().addingTimeInterval(Double(i) * -86400 * 5),
                category: LifeEventCategory.allCases[i % LifeEventCategory.allCases.count]
            )
        }
        
        try modelContext.save()
        
        var config = TimelineConfig.default
        config.dateRange = .all
        
        measure {
            let expectation = XCTestExpectation(description: "Timeline generation")
            
            Task {
                _ = try? await service.generateTimeline(config: config)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}
