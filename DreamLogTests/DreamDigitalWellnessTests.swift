//
//  DreamDigitalWellnessTests.swift
//  DreamLogTests
//
//  数字健康功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamDigitalWellnessTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        let schema = Schema([
            ScreenTimeRecord.self,
            PreSleepScreenTime.self,
            DigitalWellnessInsight.self,
            Dream.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
    }
    
    override func tearDown() async throws {
        modelContainer = nil
    }
    
    // MARK: - 数据模型测试
    
    func testScreenTimeRecordCreation() async throws {
        let context = ModelContext(modelContainer)
        
        let record = ScreenTimeRecord(
            date: Date(),
            totalMinutes: 45,
            category: AppCategory.socialMedia.rawValue,
            topApps: ["微信", "微博"],
            pickups: 20,
            notifications: 50
        )
        
        context.insert(record)
        try context.save()
        
        XCTAssertEqual(record.totalMinutes, 45)
        XCTAssertEqual(record.category, AppCategory.socialMedia.rawValue)
        XCTAssertEqual(record.topApps.count, 2)
    }
    
    func testPreSleepScreenTimeCreation() async throws {
        let context = ModelContext(modelContainer)
        
        let record = PreSleepScreenTime(
            date: Date(),
            minutesBeforeSleep: 60,
            lastUseTime: Date(),
            blueLightExposure: "高",
            stimulatingContent: true
        )
        
        context.insert(record)
        try context.save()
        
        XCTAssertEqual(record.minutesBeforeSleep, 60)
        XCTAssertEqual(record.blueLightExposure, "高")
        XCTAssertTrue(record.stimulatingContent)
    }
    
    func testDigitalWellnessInsightCreation() async throws {
        let context = ModelContext(modelContainer)
        
        let insight = DigitalWellnessInsight(
            type: WellnessInsightType.screenTimeImpact.rawValue,
            title: "睡前屏幕时间过长",
            description: "测试描述",
            severity: "high",
            recommendations: ["建议 1", "建议 2"]
        )
        
        context.insert(insight)
        try context.save()
        
        XCTAssertEqual(insight.type, WellnessInsightType.screenTimeImpact.rawValue)
        XCTAssertEqual(insight.severity, "high")
        XCTAssertEqual(insight.recommendations.count, 2)
        XCTAssertFalse(insight.isRead)
    }
    
    // MARK: - 枚举测试
    
    func testAppCategoryCases() {
        let categories = AppCategory.allCases
        XCTAssertEqual(categories.count, 9)
        
        XCTAssertEqual(AppCategory.socialMedia.icon, "📱")
        XCTAssertEqual(AppCategory.games.icon, "🎮")
        XCTAssertEqual(AppCategory.entertainment.icon, "🎬")
    }
    
    func testWellnessInsightTypeCases() {
        let types = WellnessInsightType.allCases
        XCTAssertEqual(types.count, 6)
        
        XCTAssertEqual(WellnessInsightType.blueLightEffect.icon, "💡")
        XCTAssertEqual(WellnessInsightType.contentStimulation.icon, "🎬")
    }
    
    // MARK: - 配置测试
    
    func testDefaultConfig() {
        let config = DigitalWellnessConfig.default
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.targetBedtime, "23:00")
        XCTAssertEqual(config.screenTimeLimit, 30)
        XCTAssertTrue(config.blueLightFilterReminder)
        XCTAssertTrue(config.windDownReminder)
        XCTAssertEqual(config.windDownDuration, 60)
    }
    
    func testConfigCodable() async throws {
        let config = DigitalWellnessConfig(
            isEnabled: false,
            targetBedtime: "22:30",
            screenTimeLimit: 45,
            blueLightFilterReminder: false,
            windDownReminder: true,
            windDownDuration: 90,
            excludedApps: ["TestApp"]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DigitalWellnessConfig.self, from: data)
        
        XCTAssertEqual(decoded.targetBedtime, config.targetBedtime)
        XCTAssertEqual(decoded.screenTimeLimit, config.screenTimeLimit)
        XCTAssertEqual(decoded.excludedApps, config.excludedApps)
    }
    
    // MARK: - 服务层测试
    
    func testServiceInitialization() async throws {
        let service = DreamDigitalWellnessService()
        let config = await service.getConfig()
        
        XCTAssertEqual(config.screenTimeLimit, 30)
    }
    
    func testServiceConfigUpdate() async throws {
        let service = DreamDigitalWellnessService()
        
        let newConfig = DigitalWellnessConfig(
            isEnabled: true,
            targetBedtime: "22:00",
            screenTimeLimit: 60,
            blueLightFilterReminder: true,
            windDownReminder: true,
            windDownDuration: 30,
            excludedApps: []
        )
        
        try await service.updateConfig(newConfig)
        let config = await service.getConfig()
        
        XCTAssertEqual(config.targetBedtime, "22:00")
        XCTAssertEqual(config.screenTimeLimit, 60)
    }
    
    // MARK: - 统计计算测试
    
    func testWeeklyStatsCalculation() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        // 添加测试数据
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let record = PreSleepScreenTime(
                    date: date,
                    minutesBeforeSleep: 30 + i * 10,
                    lastUseTime: date,
                    blueLightExposure: "中",
                    stimulatingContent: false
                )
                context.insert(record)
            }
        }
        
        try context.save()
        
        // 测试分析
        let stats = try await service.analyzeScreenTimeImpact(days: 7)
        
        XCTAssertGreaterThanOrEqual(stats.avgScreenTimeBeforeSleep, 30)
        XCTAssertGreaterThanOrEqual(stats.highScreenTimeDays, 0)
    }
    
    // MARK: - 洞察生成测试
    
    func testInsightGeneration() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        // 添加高屏幕时间记录
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<5 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let record = PreSleepScreenTime(
                    date: date,
                    minutesBeforeSleep: 90, // 超过限制
                    lastUseTime: date,
                    blueLightExposure: "高",
                    stimulatingContent: true
                )
                context.insert(record)
            }
        }
        
        try context.save()
        
        // 生成洞察
        let insights = try await service.generateInsights(days: 7)
        
        XCTAssertGreaterThan(insights.count, 0)
        
        // 验证至少有一个关于屏幕时间的洞察
        let hasScreenTimeInsight = insights.contains {
            $0.type == WellnessInsightType.screenTimeImpact.rawValue
        }
        XCTAssertTrue(hasScreenTimeInsight)
    }
    
    // MARK: - 建议生成测试
    
    func testRecommendationGeneration() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        let recommendations = try await service.getPersonalizedRecommendations()
        
        XCTAssertGreaterThan(recommendations.count, 0)
    }
    
    // MARK: - 清理测试
    
    func testCleanupOldRecords() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        // 添加旧记录
        let calendar = Calendar.current
        let oldDate = calendar.date(byAdding: .day, value: -100, to: Date())!
        
        let oldRecord = ScreenTimeRecord(
            date: oldDate,
            totalMinutes: 60,
            category: AppCategory.socialMedia.rawValue,
            topApps: [],
            pickups: 10,
            notifications: 20
        )
        context.insert(oldRecord)
        
        // 添加新记录
        let newRecord = ScreenTimeRecord(
            date: Date(),
            totalMinutes: 30,
            category: AppCategory.productivity.rawValue,
            topApps: [],
            pickups: 5,
            notifications: 10
        )
        context.insert(newRecord)
        
        try context.save()
        
        // 清理
        try await service.cleanupOldRecords(olderThan: 90)
        
        // 验证旧记录被删除，新记录保留
        let remainingRecords = try context.fetch(FetchDescriptor<ScreenTimeRecord>())
        XCTAssertEqual(remainingRecords.count, 1)
        XCTAssertEqual(remainingRecords.first?.totalMinutes, 30)
    }
    
    // MARK: - 性能测试
    
    func testPerformanceWithLargeDataset() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        // 添加 100 条记录
        let calendar = Calendar.current
        let today = Date()
        
        for i in 0..<100 {
            if let date = calendar.date(byAdding: .day, value: -i % 30, to: today) {
                let record = ScreenTimeRecord(
                    date: date,
                    totalMinutes: Int.random(in: 10...120),
                    category: AppCategory.allCases.randomElement()!.rawValue,
                    topApps: ["App\(i)"],
                    pickups: Int.random(in: 5...50),
                    notifications: Int.random(in: 10...100)
                )
                context.insert(record)
            }
        }
        
        try context.save()
        
        // 测试性能
        measure {
            let expectation = self.expectation(description: "Analysis complete")
            
            Task {
                _ = try? await service.analyzeScreenTimeImpact(days: 30)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - 边界情况测试
    
    func testEmptyDataAnalysis() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        let stats = try await service.analyzeScreenTimeImpact(days: 30)
        
        XCTAssertEqual(stats.avgScreenTimeBeforeSleep, 0)
        XCTAssertEqual(stats.highScreenTimeDays, 0)
        XCTAssertEqual(stats.correlationWithDreamQuality, 0.0)
    }
    
    func testSingleDayAnalysis() async throws {
        let context = ModelContext(modelContainer)
        let service = DreamDigitalWellnessService()
        service.modelContext = context
        
        let record = PreSleepScreenTime(
            date: Date(),
            minutesBeforeSleep: 45,
            lastUseTime: Date(),
            blueLightExposure: "中",
            stimulatingContent: false
        )
        context.insert(record)
        try context.save()
        
        let stats = try await service.analyzeScreenTimeImpact(days: 1)
        
        XCTAssertEqual(stats.avgScreenTimeBeforeSleep, 45)
    }
}
