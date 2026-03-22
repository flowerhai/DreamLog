//
//  DreamLogWidgetTests.swift
//  DreamLogTests
//
//  Phase 90 - 交互式小组件单元测试
//

import XCTest
import WidgetKit
@testable import DreamLog

@MainActor
final class DreamLogWidgetTests: XCTestCase {
    
    var widgetService: DreamWidgetService!
    
    override func setUp() async throws {
        try await super.setUp()
        widgetService = DreamWidgetService.shared
    }
    
    override func tearDown() async throws {
        widgetService = nil
        try await super.tearDown()
    }
    
    // MARK: - 快速记录小组件测试
    
    func testQuickRecordProvider() async throws {
        let provider = QuickRecordProvider()
        let context = Context(kind: "quick_record", family: .systemSmall)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertGreaterThanOrEqual(entry.todayCount, 0)
        XCTAssertGreaterThanOrEqual(entry.weeklyGoal, 0)
    }
    
    func testQuickRecordEntryPlaceholder() {
        let placeholder = QuickRecordEntry.placeholder
        
        XCTAssertEqual(placeholder.todayCount, 2)
        XCTAssertEqual(placeholder.weeklyGoal, 7)
        XCTAssertEqual(placeholder.weeklyProgress, 5)
    }
    
    // MARK: - 每日洞察小组件测试
    
    func testDailyInsightProvider() async throws {
        let provider = DailyInsightProvider()
        let context = Context(kind: "daily_insight", family: .systemMedium)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertFalse(entry.keywords.isEmpty || entry.keywords.count <= 3)
        XCTAssertGreaterThanOrEqual(entry.streakDays, 0)
    }
    
    func testDailyInsightEntryPlaceholder() {
        let placeholder = DailyInsightEntry.placeholder
        
        XCTAssertEqual(placeholder.keywords.count, 3)
        XCTAssertEqual(placeholder.streakDays, 12)
        XCTAssertEqual(placeholder.longestStreak, 28)
    }
    
    // MARK: - 统计小组件测试
    
    func testStatsProvider() async throws {
        let provider = StatsProvider()
        let context = Context(kind: "interactive_stats", family: .systemSmall)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertGreaterThanOrEqual(entry.totalCount, 0)
        XCTAssertGreaterThanOrEqual(entry.averageClarity, 0)
        XCTAssertLessThanOrEqual(entry.averageClarity, 5)
    }
    
    func testStatsEntryPlaceholder() {
        let placeholder = StatsEntry.placeholder
        
        XCTAssertEqual(placeholder.totalCount, 128)
        XCTAssertEqual(placeholder.emotionDistribution.count, 5)
        XCTAssertEqual(placeholder.averageClarity, 3.8, accuracy: 0.01)
    }
    
    // MARK: - 梦境卡片小组件测试
    
    func testDreamCardProvider() async throws {
        let provider = DreamCardProvider()
        let context = Context(kind: "dream_card", family: .systemMedium)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertFalse(entry.currentDream.id.isEmpty)
        XCTAssertGreaterThanOrEqual(entry.totalCount, 0)
    }
    
    func testDreamCardEntryPlaceholder() {
        let placeholder = DreamCardEntry.placeholder
        
        XCTAssertFalse(placeholder.currentDream.title.isEmpty)
        XCTAssertFalse(placeholder.currentDream.preview.isEmpty)
        XCTAssertEqual(placeholder.currentDream.clarity, 4)
    }
    
    func testDreamCardEmpty() {
        let empty = DreamCardEntry.DreamCard.empty
        
        XCTAssertEqual(empty.title, "无梦境")
        XCTAssertEqual(empty.clarity, 0)
        XCTAssertTrue(empty.emotions.isEmpty)
    }
    
    // MARK: - 锁屏小组件测试
    
    func testLockScreenCircularProvider() async throws {
        let provider = LockScreenCircularProvider()
        let context = Context(kind: "lock_screen_circular", family: .accessoryCircular)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertGreaterThanOrEqual(entry.streakDays, 0)
    }
    
    func testLockScreenRectangularProvider() async throws {
        let provider = LockScreenRectangularProvider()
        let context = Context(kind: "lock_screen_rectangular", family: .accessoryRectangular)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertFalse(entry.dreamTitle.isEmpty)
    }
    
    func testLockScreenCompactProvider() async throws {
        let provider = LockScreenCompactProvider()
        let context = Context(kind: "lock_screen_compact", family: .accessoryCircular)
        
        let entry = await provider.getTimeline(in: context) { timeline in
            return timeline.entries.first!
        }
        
        XCTAssertNotNil(entry)
        XCTAssertGreaterThanOrEqual(entry.totalCount, 0)
    }
    
    // MARK: - 主题测试
    
    func testWidgetThemeColors() {
        let themes = WidgetTheme.allThemes
        
        XCTAssertFalse(themes.isEmpty)
        XCTAssertGreaterThanOrEqual(themes.count, 8)
        
        for theme in themes {
            XCTAssertFalse(theme.name.isEmpty)
            XCTAssertFalse(theme.backgroundColor.isEmpty)
            XCTAssertFalse(theme.textColor.isEmpty)
        }
    }
    
    func testWidgetThemeDefault() {
        let defaultTheme = WidgetTheme.default
        
        XCTAssertEqual(defaultTheme.name, "星空紫")
        XCTAssertTrue(defaultTheme.isDark)
    }
    
    // MARK: - 布局测试
    
    func testWidgetLayoutDefault() {
        let defaultLayout = WidgetLayout.default
        
        XCTAssertTrue(defaultLayout.showTitle)
        XCTAssertTrue(defaultLayout.showIcon)
        XCTAssertEqual(defaultLayout.fontSize, .medium)
        XCTAssertEqual(defaultLayout.cornerRadius, 16)
    }
    
    // MARK: - 小组件服务测试
    
    func testWidgetServiceThemeManagement() {
        let service = DreamWidgetService.shared
        
        let theme = service.getCurrentTheme()
        XCTAssertNotNil(theme)
        
        let layout = service.getCurrentLayout()
        XCTAssertNotNil(layout)
    }
    
    // MARK: - 实时活动属性测试
    
    func testDreamIncubationAttributes() {
        let attributes = DreamIncubationAttributes(
            dreamTitle: "问题解答孵育",
            startTime: Date()
        )
        
        XCTAssertEqual(attributes.dreamTitle, "问题解答孵育")
        XCTAssertNotNil(attributes.startTime)
    }
    
    func testMorningReflectionAttributes() {
        let attributes = MorningReflectionAttributes(
            reflectionDate: Date()
        )
        
        XCTAssertNotNil(attributes.reflectionDate)
    }
    
    // MARK: - 性能测试
    
    func testWidgetTimelineGeneration() async {
        let providers: [any TimelineProvider] = [
            QuickRecordProvider(),
            DailyInsightProvider(),
            StatsProvider(),
            DreamCardProvider()
        ]
        
        let context = Context(kind: "test", family: .systemSmall)
        
        let startTime = Date()
        
        for provider in providers {
            await provider.getTimeline(in: context) { _ in }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        // 所有提供者应在 1 秒内生成时间线
        XCTAssertLessThan(duration, 1.0)
    }
    
    // MARK: - 数据验证测试
    
    func testEmotionDistribution() {
        let placeholder = StatsEntry.placeholder
        
        for item in placeholder.emotionDistribution {
            XCTAssertFalse(item.name.isEmpty)
            XCTAssertGreaterThanOrEqual(item.count, 0)
        }
    }
    
    func testDreamCardContent() {
        let placeholder = DreamCardEntry.placeholder
        let dream = placeholder.currentDream
        
        XCTAssertFalse(dream.id.isEmpty)
        XCTAssertFalse(dream.title.isEmpty)
        XCTAssertFalse(dream.preview.isEmpty)
        XCTAssertGreaterThanOrEqual(dream.clarity, 0)
        XCTAssertLessThanOrEqual(dream.clarity, 5)
    }
}

// MARK: - 预览测试

final class DreamLogWidgetPreviewTests: XCTestCase {
    
    func testQuickRecordWidgetPreview() {
        let entry = QuickRecordEntry.placeholder
        let view = QuickRecordWidgetEntryView(entry: entry)
        
        XCTAssertNotNil(view)
    }
    
    func testDailyInsightWidgetPreview() {
        let entry = DailyInsightEntry.placeholder
        let view = DailyInsightWidgetEntryView(entry: entry)
        
        XCTAssertNotNil(view)
    }
    
    func testStatsWidgetPreview() {
        let entry = StatsEntry.placeholder
        let view = StatsWidgetEntryView(entry: entry)
        
        XCTAssertNotNil(view)
    }
    
    func testDreamCardWidgetPreview() {
        let entry = DreamCardEntry.placeholder
        let view = DreamCardWidgetEntryView(entry: entry)
        
        XCTAssertNotNil(view)
    }
}
