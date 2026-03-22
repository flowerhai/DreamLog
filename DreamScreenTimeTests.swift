//
//  DreamScreenTimeTests.swift
//  DreamLogTests
//
//  Phase 93: 屏幕时间追踪单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamScreenTimeTests: XCTestCase {
    
    var service: DreamScreenTimeService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.dreamlog.screentime")
        testUserDefaults?.removePersistentDomain(forName: "test.dreamlog.screentime")
        service = DreamScreenTimeService(userDefaults: testUserDefaults)
    }
    
    override func tearDown() async throws {
        service = nil
        testUserDefaults = nil
        try await super.tearDown()
    }
    
    // MARK: - 设置测试
    
    func testSettingsDefault() {
        XCTAssertEqual(service.settings.dailyLimitMinutes, 360)
        XCTAssertEqual(service.settings.pickupLimit, 50)
        XCTAssertEqual(service.settings.windDownMinutes, 60)
        XCTAssertTrue(service.settings.autoImport)
    }
    
    func testSettingsPersistence() {
        service.updateSettings { settings in
            settings.dailyLimitMinutes = 240
            settings.pickupLimit = 30
        }
        
        let newService = DreamScreenTimeService(userDefaults: testUserDefaults)
        XCTAssertEqual(newService.settings.dailyLimitMinutes, 240)
        XCTAssertEqual(newService.settings.pickupLimit, 30)
    }
    
    // MARK: - 会话记录测试
    
    func testLogSession() async {
        await service.logSession(
            duration: 1800,
            category: .socialMedia,
            appName: "微信",
            minutesBeforeSleep: 30
        )
        
        XCTAssertNotNil(service.todayStats)
        XCTAssertEqual(service.todayStats?.sessionCount, 1)
        XCTAssertEqual(service.todayStats?.totalDuration, 1800)
    }
    
    func testLogSessionBeforeBedDetection() async {
        await service.logSession(
            duration: 1800,
            category: .games,
            appName: "王者荣耀",
            minutesBeforeSleep: 45
        )
        
        XCTAssertEqual(service.todayStats?.beforeBedDuration, 1800)
    }
    
    func testLogSessionNotBeforeBed() async {
        await service.logSession(
            duration: 1800,
            category: .productivity,
            appName: "Pages",
            minutesBeforeSleep: 120
        )
        
        XCTAssertEqual(service.todayStats?.beforeBedDuration, 0)
    }
    
    // MARK: - 统计测试
    
    func testTodayStatsCalculation() async {
        await service.logSession(duration: 1800, category: .socialMedia, appName: "微信")
        await service.logSession(duration: 3600, category: .entertainment, appName: "抖音")
        await service.logSession(duration: 900, category: .games, appName: "原神")
        
        XCTAssertEqual(service.todayStats?.sessionCount, 3)
        XCTAssertEqual(service.todayStats?.totalDuration, 6300)
        XCTAssertEqual(service.todayStats?.categoryBreakdown.count, 3)
    }
    
    func testCategoryBreakdown() async {
        await service.logSession(duration: 3600, category: .socialMedia, appName: "微信")
        await service.logSession(duration: 1800, category: .socialMedia, appName: "微博")
        await service.logSession(duration: 900, category: .games, appName: "王者荣耀")
        
        let socialMediaDuration = service.todayStats?.categoryBreakdown[.socialMedia] ?? 0
        XCTAssertEqual(socialMediaDuration, 5400)
    }
    
    // MARK: - 周报测试
    
    func testWeeklyReportGeneration() async {
        let today = Date()
        let weekStart = Calendar.current.date(byAdding: .day, value: -6, to: today) ?? today
        
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: i - 6, to: today) ?? today
            await service.logSession(duration: 3600, category: .socialMedia, appName: "微信")
        }
        
        let report = service.generateWeeklyReport(for: weekStart)
        XCTAssertEqual(report.dailyStats.count, 1)
    }
    
    // MARK: - 关联分析测试
    
    func testCorrelationAnalysis() async {
        // 模拟高屏幕时间 + 低睡眠质量
        await service.logSession(duration: 7200, category: .games, appName: "游戏", minutesBeforeSleep: 30)
        
        await service.analyzeCorrelations()
        
        XCTAssertNotNil(service.correlation)
    }
    
    func testCorrelationStrength() async {
        await service.logSession(duration: 300, category: .reading, appName: "微信读书", minutesBeforeSleep: 120)
        
        await service.analyzeCorrelations()
        
        XCTAssertEqual(service.correlation?.strength, .weak)
    }
    
    // MARK: - 成就系统测试
    
    func testAchievementUnlock() async {
        // 模拟第一天使用
        await service.logSession(duration: 1800, category: .productivity, appName: "Notes")
        
        let achievements = service.checkAndUnlockAchievements()
        XCTAssertNotNil(achievements)
    }
    
    // MARK: - 数据导入测试
    
    func testBatchImport() async {
        let sessions = (0..<10).map { i in
            ScreenTimeSession(
                duration: 1800,
                category: ScreenTimeCategory.allCases[i % ScreenTimeCategory.allCases.count],
                appName: "App\(i)"
            )
        }
        
        await service.importScreenTimeData(sessions)
        
        XCTAssertEqual(service.todayStats?.sessionCount, 10)
    }
    
    func testImportDeduplication() async {
        let session = ScreenTimeSession(duration: 1800, category: .socialMedia, appName: "微信")
        
        await service.importScreenTimeData([session])
        await service.importScreenTimeData([session])
        
        XCTAssertEqual(service.todayStats?.sessionCount, 1)
    }
    
    // MARK: - 辅助方法测试
    
    func testQuickStatsCalculation() async {
        await service.logSession(duration: 3600, category: .socialMedia, appName: "微信")
        await service.logSession(duration: 1800, category: .beforeBed: true, appName: "抖音", minutesBeforeSleep: 30)
        
        await service.updateQuickStats()
        
        XCTAssertNotNil(service.quickStats)
        XCTAssertEqual(service.quickStats?.todayTotalDuration, 5400)
    }
    
    func testDateRangeStats() {
        let end = Date()
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end) ?? end
        
        let stats = service.getStatsForDateRange(start: start, end: end)
        XCTAssertNotNil(stats)
    }
}

// MARK: - 性能测试

final class DreamScreenTimePerformanceTests: XCTestCase {
    
    var service: DreamScreenTimeService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.dreamlog.screentime.perf")
        testUserDefaults?.removePersistentDomain(forName: "test.dreamlog.screentime.perf")
        service = DreamScreenTimeService(userDefaults: testUserDefaults)
    }
    
    func testLogSessionPerformance() async throws {
        let sessions = (0..<100).map { i in
            ScreenTimeSession(
                duration: 1800,
                category: ScreenTimeCategory.allCases[i % ScreenTimeCategory.allCases.count],
                appName: "App\(i)"
            )
        }
        
        measure {
            Task {
                await service.importScreenTimeData(sessions)
            }
        }
    }
    
    func testStatsCalculationPerformance() async throws {
        let sessions = (0..<1000).map { i in
            ScreenTimeSession(
                duration: 1800,
                category: ScreenTimeCategory.allCases[i % ScreenTimeCategory.allCases.count],
                appName: "App\(i)"
            )
        }
        
        await service.importScreenTimeData(sessions)
        
        measure {
            Task {
                await service.updateTodayStats()
            }
        }
    }
}
