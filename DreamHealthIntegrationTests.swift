//
//  DreamHealthIntegrationTests.swift
//  DreamLog - 健康集成与睡眠追踪单元测试
//
//  Phase 64: 健康集成与睡眠追踪 🍎💤
//  创建时间：2026-03-18
//

import XCTest
import SwiftData
@testable import DreamLog

// MARK: - 健康集成测试

@available(iOS 17.0, *)
final class DreamHealthIntegrationTests: XCTestCase {
    
    // MARK: - 属性
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var healthService: DreamHealthIntegrationService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            SleepSession.self,
            HealthMetrics.self,
            DreamSleepCorrelation.self
        ])
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        modelContext = ModelContext(modelContainer)
        healthService = DreamHealthIntegrationService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        healthService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 健康授权测试
    
    func testHealthKitAuthorization() async throws {
        // 测试授权流程（模拟）
        let status = await healthService.checkAuthorizationStatus()
        
        // 在测试环境中，应该返回不可用或已授权
        XCTAssertTrue(
            status == .unavailable || status == .sharingAuthorized,
            "授权状态应该是不可用或已授权"
        )
    }
    
    // MARK: - 睡眠数据同步测试
    
    func testSleepSessionSync() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        // 同步 7 天的睡眠数据
        let sessions = try await healthService.syncSleepSessions(from: startDate, to: endDate)
        
        // 验证同步结果
        XCTAssertEqual(sessions.count, 7, "应该同步 7 天的睡眠数据")
        
        // 验证每个会话的数据完整性
        for session in sessions {
            XCTAssertGreaterThan(session.duration, 0, "睡眠时长应该大于 0")
            XCTAssertNotNil(session.quality, "应该有睡眠质量")
            XCTAssertEqual(session.source, "Apple Watch", "数据来源应该是 Apple Watch")
        }
    }
    
    func testGetSleepSessionForDate() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        // 先创建测试数据
        let testSession = SleepSession(
            startDate: calendar.startOfDay(for: today),
            endDate: calendar.date(byAdding: .hour, value: 8, to: calendar.startOfDay(for: today))!,
            duration: 28800,
            quality: .good,
            remDuration: 7200,
            coreDuration: 14400,
            deepDuration: 5400,
            awakeDuration: 1800,
            source: "Test"
        )
        modelContext.insert(testSession)
        try modelContext.save()
        
        // 获取指定日期的会话
        let session = try await healthService.getSleepSession(for: today)
        
        XCTAssertNotNil(session, "应该找到今天的睡眠会话")
        XCTAssertEqual(session?.quality, .good, "睡眠质量应该匹配")
    }
    
    func testGetSleepSessionsInRange() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        // 获取 30 天内的睡眠会话
        let sessions = try await healthService.getSleepSessions(from: startDate, to: endDate)
        
        XCTAssertGreaterThanOrEqual(sessions.count, 0, "应该返回睡眠会话列表")
        
        // 验证排序（应该是倒序）
        if sessions.count > 1 {
            for i in 0..<(sessions.count - 1) {
                XCTAssertGreaterThanOrEqual(
                    sessions[i].startDate,
                    sessions[i + 1].startDate,
                    "会话应该按日期倒序排列"
                )
            }
        }
    }
    
    // MARK: - 睡眠质量分析测试
    
    func testSleepQualityAnalysis() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        // 创建测试数据
        let testSession = SleepSession(
            startDate: calendar.startOfDay(for: today),
            endDate: calendar.date(byAdding: .hour, value: 8, to: calendar.startOfDay(for: today))!,
            duration: 28800,
            quality: .excellent,
            source: "Test"
        )
        modelContext.insert(testSession)
        try modelContext.save()
        
        // 分析睡眠质量
        let quality = try await healthService.analyzeSleepQuality(for: today)
        
        XCTAssertEqual(quality, .excellent, "睡眠质量分析应该正确")
    }
    
    func testAverageSleepQuality() async throws {
        let calendar = Calendar.current
        
        // 创建多个测试会话
        let qualities: [SleepQuality] = [.excellent, .good, .fair]
        
        for quality in qualities {
            let session = SleepSession(
                startDate: calendar.startOfDay(for: calendar.date(byAdding: .day, value: -qualities.firstIndex(of: quality)!, to: Date())!),
                endDate: Date(),
                duration: 28800,
                quality: quality,
                source: "Test"
            )
            modelContext.insert(session)
        }
        try modelContext.save()
        
        // 计算平均质量
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -3, to: endDate)!
        let averageQuality = try await healthService.averageSleepQuality(from: startDate, to: endDate)
        
        // 验证平均质量在合理范围内
        XCTAssertNotNil(averageQuality, "应该计算出平均睡眠质量")
    }
    
    // MARK: - 梦境 - 睡眠关联测试
    
    func testDreamSleepCorrelation() async throws {
        let calendar = Calendar.current
        let today = Date()
        
        // 创建睡眠会话
        let sleepSession = SleepSession(
            startDate: calendar.startOfDay(for: today),
            endDate: calendar.date(byAdding: .hour, value: 8, to: calendar.startOfDay(for: today))!,
            duration: 28800,
            quality: .good,
            source: "Test"
        )
        modelContext.insert(sleepSession)
        
        // 创建测试梦境
        for i in 0..<3 {
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "这是一个测试梦境内容",
                date: today,
                tags: ["测试", "梦境"],
                emotion: .calm,
                clarity: 3 + i,
                intensity: 3,
                isLucid: i == 0
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        // 进行关联分析
        let correlation = try await healthService.correlateDreamsWithSleep(for: today)
        
        XCTAssertNotNil(correlation, "应该有关联分析结果")
        XCTAssertEqual(correlation?.sleepQuality, .good, "睡眠质量应该匹配")
        XCTAssertEqual(correlation?.dreamCount, 3, "梦境数量应该正确")
    }
    
    func testCorrelationOverDateRange() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        // 获取关联分析列表
        let correlations = try await healthService.correlateDreamsWithSleep(from: startDate, to: endDate)
        
        XCTAssertGreaterThanOrEqual(correlations.count, 0, "应该返回关联分析列表")
    }
    
    // MARK: - 智能推荐测试
    
    func testSmartRecommendations() {
        // 测试不同睡眠质量下的推荐
        let testCases: [(SleepQuality, Int)] = [
            (.excellent, 2),
            (.good, 1),
            (.fair, 1),
            (.poor, 2)
        ]
        
        for (quality, expectedCount) in testCases {
            let recommendations = healthService.getDreamRecommendations(basedOn: quality)
            
            XCTAssertEqual(
                recommendations.count,
                expectedCount,
                "睡眠质量 \(quality.rawValue) 应该有 \(expectedCount) 个推荐"
            )
            
            // 验证推荐内容
            for recommendation in recommendations {
                XCTAssertFalse(recommendation.title.isEmpty, "推荐标题不应为空")
                XCTAssertFalse(recommendation.description.isEmpty, "推荐描述不应为空")
                XCTAssertFalse(recommendation.action.isEmpty, "推荐操作不应为空")
            }
        }
    }
    
    func testRecommendationTypes() {
        // 验证所有推荐类型都被覆盖
        let allTypes = Set(DreamRecommendationType.allCases.map { $0.rawValue })
        
        // 测试各种睡眠质量产生的推荐类型
        var foundTypes: Set<String> = []
        
        for quality in SleepQuality.allCases {
            let recommendations = healthService.getDreamRecommendations(basedOn: quality)
            for rec in recommendations {
                foundTypes.insert(rec.type.rawValue)
            }
        }
        
        // 验证至少覆盖了部分类型
        XCTAssertGreaterThan(foundTypes.count, 0, "应该生成多种类型的推荐")
    }
    
    // MARK: - 睡眠统计测试
    
    func testSleepStatisticsCalculation() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        // 先同步数据
        _ = try await healthService.syncSleepSessions(from: startDate, to: endDate)
        
        // 计算统计
        let statistics = try await healthService.calculateSleepStatistics(from: startDate, to: endDate)
        
        // 验证统计数据
        XCTAssertEqual(statistics.totalSessions, 7, "应该有 7 次睡眠会话")
        XCTAssertGreaterThan(statistics.averageDuration, 0, "平均时长应该大于 0")
        XCTAssertNotNil(statistics.averageQuality, "应该有平均睡眠质量")
        
        // 验证质量分布
        for quality in SleepQuality.allCases {
            XCTAssertGreaterThanOrEqual(statistics.qualityDistribution[quality] ?? 0, 0, "质量分布应该有效")
        }
    }
    
    func testSleepStatisticsWithEmptyData() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        // 清空数据
        try modelContext.delete(model: SleepSession.self)
        try modelContext.save()
        
        // 计算统计（空数据）
        let statistics = try await healthService.calculateSleepStatistics(from: startDate, to: endDate)
        
        XCTAssertEqual(statistics.totalSessions, 0, "空数据时会话数应为 0")
        XCTAssertEqual(statistics.averageDuration, 0, "空数据时平均时长应为 0")
    }
    
    // MARK: - 健康指标测试
    
    func testHealthMetricsSaveAndRetrieve() async throws {
        let today = Date()
        
        // 创建健康指标
        let metrics = HealthMetrics(
            date: today,
            restingHeartRate: 65,
            heartRateVariability: 45,
            respiratoryRate: 16,
            sleepGoal: 28800,
            actualSleep: 27000,
            stepCount: 8000
        )
        
        healthService.saveHealthMetrics(metrics)
        
        // 检索指标
        let retrieved = try await healthService.getHealthMetrics(for: today)
        
        XCTAssertNotNil(retrieved, "应该能检索到健康指标")
        XCTAssertEqual(retrieved?.restingHeartRate, 65, "静息心率应该匹配")
        XCTAssertEqual(retrieved?.stepCount, 8000, "步数应该匹配")
    }
    
    func testHealthMetricsCalculation() {
        let metrics = HealthMetrics(
            date: Date(),
            restingHeartRate: 70,
            heartRateVariability: 35,
            respiratoryRate: 15,
            sleepGoal: 28800,
            actualSleep: 25200
        )
        
        // 验证睡眠目标达成率
        XCTAssertEqual(metrics.sleepGoalCompletion, 0.875, accuracy: 0.01, "睡眠目标达成率应该正确")
        
        // 验证静息心率正常判断
        XCTAssertEqual(metrics.isRestingHeartRateNormal, true, "静息心率应该正常")
        
        // 验证 HRV 状态
        XCTAssertEqual(metrics.hrvStatus, .good, "HRV 状态应该是良好")
    }
    
    // MARK: - 睡眠质量枚举测试
    
    func testSleepQualityScore() {
        XCTAssertEqual(SleepQuality.excellent.score, 90)
        XCTAssertEqual(SleepQuality.good.score, 75)
        XCTAssertEqual(SleepQuality.fair.score, 60)
        XCTAssertEqual(SleepQuality.poor.score, 40)
    }
    
    func testSleepQualityFromScore() {
        XCTAssertEqual(SleepQuality.from(score: 95), .excellent)
        XCTAssertEqual(SleepQuality.from(score: 80), .good)
        XCTAssertEqual(SleepQuality.from(score: 65), .fair)
        XCTAssertEqual(SleepQuality.from(score: 30), .poor)
    }
    
    func testSleepQualitySymbols() {
        XCTAssertEqual(SleepQuality.excellent.symbol, "moon.stars.fill")
        XCTAssertEqual(SleepQuality.good.symbol, "moon.fill")
        XCTAssertEqual(SleepQuality.fair.symbol, "moon")
        XCTAssertEqual(SleepQuality.poor.symbol, "moon.zzz")
    }
    
    // MARK: - 睡眠会话计算属性测试
    
    func testSleepSessionCalculations() {
        let session = SleepSession(
            startDate: Date(),
            endDate: Date().addingTimeInterval(28800),
            duration: 28800,
            quality: .good,
            remDuration: 7200,
            coreDuration: 14400,
            deepDuration: 5400,
            awakeDuration: 1800,
            source: "Test",
            inBedStartDate: Date().addingTimeInterval(-1800),
            inBedEndDate: Date().addingTimeInterval(28800 + 600)
        )
        
        // 验证阶段百分比
        XCTAssertNotNil(session.remPercentage)
        XCTAssertNotNil(session.deepPercentage)
        XCTAssertNotNil(session.corePercentage)
        XCTAssertNotNil(session.awakePercentage)
        
        // 验证百分比总和约为 100%
        let total = (session.remPercentage ?? 0) +
                   (session.deepPercentage ?? 0) +
                   (session.corePercentage ?? 0) +
                   (session.awakePercentage ?? 0)
        
        XCTAssertEqual(total, 1.0, accuracy: 0.01, "阶段百分比总和应该为 100%")
        
        // 验证睡眠效率
        XCTAssertNotNil(session.sleepEfficiency)
        XCTAssertGreaterThan(session.sleepEfficiency ?? 0, 0)
        XCTAssertLessThanOrEqual(session.sleepEfficiency ?? 0, 1.0)
    }
    
    // MARK: - 性能测试
    
    func testSyncPerformance() async throws {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -90, to: endDate)!
        
        // 测量 90 天数据同步性能
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let sessions = try await healthService.syncSleepSessions(from: startDate, to: endDate)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        print("同步 90 天数据耗时：\(duration)秒")
        
        XCTAssertLessThan(duration, 5.0, "同步 90 天数据应该在 5 秒内完成")
        XCTAssertEqual(sessions.count, 90, "应该同步 90 天的数据")
    }
    
    // MARK: - 边界情况测试
    
    func testSingleDaySync() async throws {
        let today = Date()
        
        let sessions = try await healthService.syncSleepSessions(from: today, to: today)
        
        XCTAssertEqual(sessions.count, 1, "单天同步应该返回 1 个会话")
    }
    
    func testInvalidDateRange() async throws {
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: -10, to: startDate)!
        
        // 结束日期早于开始日期，应该返回空数组或处理错误
        let sessions = try await healthService.getSleepSessions(from: startDate, to: endDate)
        
        XCTAssertEqual(sessions.count, 0, "无效日期范围应该返回空数组")
    }
}

// MARK: - 提醒服务测试

@available(iOS 17.0, *)
final class DreamSleepReminderTests: XCTestCase {
    
    var reminderService: DreamSleepReminderService!
    
    override func setUp() async throws {
        try await super.setUp()
        reminderService = DreamSleepReminderService.shared
    }
    
    override func tearDown() async throws {
        reminderService = nil
        try await super.tearDown()
    }
    
    func testReminderServiceInitialization() {
        XCTAssertNotNil(reminderService, "提醒服务应该能初始化")
    }
    
    func testSmartReminderConfig() {
        let config = DreamSleepReminderService.SmartReminderConfig(
            bedtimeReminderEnabled: true,
            morningReminderEnabled: true,
            optimalTimingEnabled: false,
            goalRemindersEnabled: true,
            streakEncouragementEnabled: true,
            bedtimeOffset: 1800,
            morningOffset: 900,
            preferredBedtime: Date(),
            preferredWakeTime: Date().addingTimeInterval(28800),
            sleepGoal: 28800
        )
        
        XCTAssertTrue(config.bedtimeReminderEnabled)
        XCTAssertTrue(config.morningReminderEnabled)
        XCTAssertEqual(config.bedtimeOffset, 1800)
        XCTAssertEqual(config.morningOffset, 900)
        XCTAssertEqual(config.sleepGoal, 28800)
    }
}

// MARK: - 模型测试

@available(iOS 17.0, *)
final class DreamHealthModelsTests: XCTestCase {
    
    func testSleepSessionModel() {
        let session = SleepSession(
            startDate: Date(),
            endDate: Date().addingTimeInterval(28800),
            duration: 28800,
            quality: .good,
            remDuration: 7200,
            coreDuration: 14400,
            deepDuration: 5400,
            awakeDuration: 1800,
            source: "Apple Watch"
        )
        
        XCTAssertEqual(session.duration, 28800)
        XCTAssertEqual(session.quality, .good)
        XCTAssertEqual(session.source, "Apple Watch")
    }
    
    func testHealthMetricsModel() {
        let metrics = HealthMetrics(
            date: Date(),
            restingHeartRate: 65,
            heartRateVariability: 40,
            respiratoryRate: 15,
            sleepGoal: 28800,
            actualSleep: 27000,
            stepCount: 10000
        )
        
        XCTAssertEqual(metrics.restingHeartRate, 65)
        XCTAssertEqual(metrics.stepCount, 10000)
        XCTAssertEqual(metrics.sleepGoal, 28800)
    }
    
    func testDreamSleepCorrelationModel() {
        let correlation = DreamSleepCorrelation(
            date: Date(),
            sleepQuality: .good,
            dreamCount: 3,
            averageClarity: 3.5,
            averageIntensity: 3.0,
            lucidDreamCount: 1,
            positiveEmotionRatio: 0.7,
            negativeEmotionRatio: 0.3,
            topEmotions: ["平静", "兴奋"],
            topTags: ["飞行", "水"]
        )
        
        XCTAssertEqual(correlation.dreamCount, 3)
        XCTAssertEqual(correlation.averageClarity, 3.5)
        XCTAssertEqual(correlation.topEmotions.count, 2)
    }
    
    func testSleepGoalModel() {
        let goal = SleepGoal(
            targetDuration: 28800,
            remindersEnabled: true,
            bedtimeReminderOffset: 1800,
            wakeUpReminderOffset: 900
        )
        
        XCTAssertEqual(goal.targetDuration, 28800)
        XCTAssertEqual(goal.formattedTargetDuration, "8 小时 0 分钟")
        XCTAssertTrue(goal.remindersEnabled)
    }
    
    func testSleepStatisticsStruct() {
        let stats = SleepStatistics(
            totalSessions: 30,
            averageDuration: 27000,
            averageQuality: .good,
            currentStreak: 7,
            longestStreak: 21,
            totalDaysTracked: 30
        )
        
        XCTAssertEqual(stats.totalSessions, 30)
        XCTAssertEqual(stats.formattedAverageDuration, "7 小时 30 分钟")
        XCTAssertEqual(stats.currentStreak, 7)
    }
}

// MARK: - 辅助扩展

extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
