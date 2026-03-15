//
//  DreamShareAnalyticsTests.swift
//  DreamLog - 梦境分享数据分析测试
//
//  Created by DreamLog Team on 2026-03-15.
//  Phase 46: Dream Share Analytics - 分享数据分析与洞察
//

import XCTest
import SwiftData
@testable import DreamLog

@available(macOS 13, iOS 17, *)
final class DreamShareAnalyticsTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            Dream.self,
            ShareHistory.self,
            ShareStatistics.self,
            ShareAchievement.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 统计数据测试
    
    /// 测试分享统计计算
    func testCalculateStatistics() async throws {
        // 创建测试数据
        try createTestShareHistory(count: 10)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let statistics = try await service.calculateStatistics(period: "all")
        
        XCTAssertEqual(statistics.totalShares, 10)
        XCTAssertEqual(statistics.uniqueDreamsShared, 5) // 5 个独特梦境
        XCTAssertGreaterThan(statistics.averageSharesPerDay, 0)
        XCTAssertNotNil(statistics.lastShareDate)
    }
    
    /// 测试周期统计
    func testPeriodStatistics() async throws {
        // 创建测试数据
        try createTestShareHistory(count: 20)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        
        // 测试不同周期
        let allStats = try await service.calculateStatistics(period: "all")
        let monthlyStats = try await service.calculateStatistics(period: "monthly")
        let weeklyStats = try await service.calculateStatistics(period: "weekly")
        
        XCTAssertGreaterThanOrEqual(allStats.totalShares, monthlyStats.totalShares)
        XCTAssertGreaterThanOrEqual(monthlyStats.totalShares, weeklyStats.totalShares)
    }
    
    /// 测试平台分布计算
    func testPlatformBreakdown() async throws {
        // 创建多平台分享数据
        try createMultiPlatformShareHistory()
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let statistics = try await service.calculateStatistics()
        
        XCTAssertFalse(statistics.platformBreakdown.isEmpty)
        XCTAssertEqual(statistics.platformBreakdown.count, 3) // 3 个平台
    }
    
    /// 测试连续天数计算
    func testStreakCalculation() async throws {
        // 创建连续分享数据
        try createConsecutiveShareHistory(days: 7)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let statistics = try await service.calculateStatistics()
        
        XCTAssertEqual(statistics.streakDays, 7)
        XCTAssertEqual(statistics.longestStreak, 7)
    }
    
    // MARK: - 趋势分析测试
    
    /// 测试分享趋势
    func testShareTrend() async throws {
        // 创建测试数据
        try createTestShareHistory(count: 30)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let trendPoints = try await service.getShareTrend(days: 30)
        
        XCTAssertEqual(trendPoints.count, 30)
        
        // 验证趋势点数据结构
        for point in trendPoints {
            XCTAssertGreaterThanOrEqual(point.shareCount, 0)
            XCTAssertGreaterThanOrEqual(point.uniqueDreams, 0)
        }
    }
    
    /// 测试平台使用详情
    func testPlatformUsageDetails() async throws {
        // 创建多平台分享数据
        try createMultiPlatformShareHistory()
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let details = try await service.getPlatformUsageDetails()
        
        XCTAssertFalse(details.isEmpty)
        
        // 验证百分比总和约为 100%
        let totalPercentage = details.reduce(0.0) { $0 + $1.percentage }
        XCTAssertGreaterThan(totalPercentage, 99.0)
        XCTAssertLessThan(totalPercentage, 101.0)
    }
    
    // MARK: - 成就系统测试
    
    /// 测试成就获取
    func testGetAllAchievements() async throws {
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let achievements = try await service.getAllAchievements()
        
        XCTAssertFalse(achievements.isEmpty)
        
        // 验证预定义成就存在
        let achievementIds = achievements.map { $0.achievementId }
        XCTAssertTrue(achievementIds.contains("share_1"))
        XCTAssertTrue(achievementIds.contains("share_10"))
        XCTAssertTrue(achievementIds.contains("streak_7"))
    }
    
    /// 测试成就进度更新
    func testAchievementProgressUpdate() async throws {
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        
        // 获取初始成就
        let achievements = try await service.getAllAchievements()
        let share1Achievement = achievements.first { $0.achievementId == "share_1" }
        XCTAssertNotNil(share1Achievement)
        
        // 创建分享数据
        try createTestShareHistory(count: 5)
        let statistics = try await service.calculateStatistics()
        
        // 更新成就进度
        try await service.updateAchievementProgress(
            totalShares: statistics.totalShares,
            streakDays: statistics.streakDays,
            platforms: Set(statistics.platformBreakdown.keys)
        )
        
        // 验证进度更新
        let updatedAchievements = try await service.getAllAchievements()
        let updatedShare1 = updatedAchievements.first { $0.achievementId == "share_1" }
        XCTAssertEqual(updatedShare1?.progress, 5)
        XCTAssertTrue(updatedShare1?.isUnlocked ?? false)
    }
    
    /// 测试里程碑成就解锁
    func testMilestoneAchievementUnlock() async throws {
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        
        // 创建 10 次分享
        try createTestShareHistory(count: 10)
        let statistics = try await service.calculateStatistics()
        
        // 更新成就
        try await service.updateAchievementProgress(
            totalShares: statistics.totalShares,
            streakDays: statistics.streakDays,
            platforms: Set(statistics.platformBreakdown.keys)
        )
        
        // 验证 share_10 成就解锁
        let achievements = try await service.getAllAchievements()
        let share10Achievement = achievements.first { $0.achievementId == "share_10" }
        XCTAssertEqual(share10Achievement?.progress, 10)
        XCTAssertTrue(share10Achievement?.isUnlocked ?? false)
        XCTAssertNotNil(share10Achievement?.unlockedAt)
    }
    
    // MARK: - 洞察生成测试
    
    /// 测试洞察生成
    func testGenerateInsights() async throws {
        // 创建丰富的测试数据
        try createRichShareHistory()
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let insights = try await service.generateInsights()
        
        XCTAssertFalse(insights.isEmpty)
        
        // 验证洞察数据结构
        for insight in insights {
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertFalse(insight.suggestion.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.confidence, 0)
            XCTAssertLessThanOrEqual(insight.confidence, 1)
        }
    }
    
    /// 测试最佳时间洞察
    func testBestTimeInsight() async throws {
        // 创建集中在特定时间的分享数据
        try createTimeSpecificShareHistory(hour: 20, count: 15)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let insights = try await service.generateInsights()
        
        // 应该包含最佳时间洞察
        let bestTimeInsights = insights.filter { $0.type == .bestTime }
        XCTAssertFalse(bestTimeInsights.isEmpty)
    }
    
    // MARK: - 数据模型测试
    
    /// 测试 ShareStatistics 模型
    func testShareStatisticsModel() {
        let statistics = ShareStatistics(
            period: "monthly",
            totalShares: 50,
            uniqueDreamsShared: 30,
            platformBreakdown: ["wechat": 20, "weibo": 15, "xiaohongshu": 15],
            streakDays: 5,
            longestStreak: 10
        )
        
        XCTAssertEqual(statistics.period, "monthly")
        XCTAssertEqual(statistics.totalShares, 50)
        XCTAssertEqual(statistics.uniqueDreamsShared, 30)
        XCTAssertEqual(statistics.streakDays, 5)
        XCTAssertEqual(statistics.longestStreak, 10)
        XCTAssertNotNil(statistics.id)
        XCTAssertNotNil(statistics.createdAt)
        XCTAssertNotNil(statistics.updatedAt)
    }
    
    /// 测试 ShareInsight 模型
    func testShareInsightModel() {
        let insight = ShareInsight(
            type: .bestTime,
            title: "最佳分享时间",
            description: "您在晚上 8-10 点分享获得最多互动",
            suggestion: "建议在这个时间段分享重要梦境",
            confidence: 0.85,
            dataPoints: 50
        )
        
        XCTAssertEqual(insight.type, .bestTime)
        XCTAssertEqual(insight.title, "最佳分享时间")
        XCTAssertEqual(insight.confidence, 0.85)
        XCTAssertEqual(insight.dataPoints, 50)
        XCTAssertNotNil(insight.id)
        XCTAssertNotNil(insight.createdAt)
    }
    
    /// 测试 ShareAchievement 模型
    func testShareAchievementModel() {
        let achievement = ShareAchievement(
            achievementId: "test_achievement",
            name: "测试成就",
            description: "这是一个测试成就",
            icon: "star.fill",
            category: .count,
            requirement: 10
        )
        
        XCTAssertEqual(achievement.achievementId, "test_achievement")
        XCTAssertEqual(achievement.name, "测试成就")
        XCTAssertEqual(achievement.category, .count)
        XCTAssertEqual(achievement.requirement, 10)
        XCTAssertEqual(achievement.progress, 0)
        XCTAssertFalse(achievement.isUnlocked)
    }
    
    // MARK: - 边界条件测试
    
    /// 测试空数据情况
    func testEmptyData() async throws {
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let statistics = try await service.calculateStatistics()
        
        XCTAssertEqual(statistics.totalShares, 0)
        XCTAssertEqual(statistics.uniqueDreamsShared, 0)
        XCTAssertEqual(statistics.averageSharesPerDay, 0)
        XCTAssertEqual(statistics.streakDays, 0)
    }
    
    /// 测试单次分享
    func testSingleShare() async throws {
        try createTestShareHistory(count: 1)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let statistics = try await service.calculateStatistics()
        
        XCTAssertEqual(statistics.totalShares, 1)
        XCTAssertEqual(statistics.uniqueDreamsShared, 1)
    }
    
    /// 测试大量数据
    func testLargeDataset() async throws {
        // 创建 100 次分享
        try createTestShareHistory(count: 100)
        
        let service = DreamShareAnalyticsService(modelContext: modelContext)
        let statistics = try await service.calculateStatistics()
        
        XCTAssertEqual(statistics.totalShares, 100)
        XCTAssertGreaterThan(statistics.averageSharesPerDay, 0)
    }
    
    // MARK: - 辅助方法
    
    private func createTestShareHistory(count: Int) throws {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<count {
            let dreamId = UUID()
            let shareDate = calendar.date(byAdding: .hour, value: -i, to: now) ?? now
            
            let history = ShareHistory(
                dreamId: dreamId,
                dreamTitle: "测试梦境 \(i % 5 + 1)", // 5 个独特梦境
                platform: ["wechat", "weibo", "xiaohongshu"][i % 3],
                sharedAt: shareDate,
                template: "default",
                interactions: ShareInteractions(likes: i * 10, comments: i * 2, shares: i)
            )
            
            modelContext.insert(history)
        }
        
        try modelContext.save()
    }
    
    private func createMultiPlatformShareHistory() throws {
        let platforms = ["wechat", "weibo", "xiaohongshu"]
        let now = Date()
        
        for (index, platform) in platforms.enumerated() {
            for i in 0..<5 {
                let history = ShareHistory(
                    dreamId: UUID(),
                    dreamTitle: "平台 \(platform) 分享",
                    platform: platform,
                    sharedAt: now,
                    template: "default",
                    interactions: ShareInteractions(likes: 10, comments: 2, shares: 1)
                )
                modelContext.insert(history)
            }
        }
        
        try modelContext.save()
    }
    
    private func createConsecutiveShareHistory(days: Int) throws {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<days {
            let shareDate = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let history = ShareHistory(
                dreamId: UUID(),
                dreamTitle: "第 \(days - i) 天分享",
                platform: "wechat",
                sharedAt: shareDate,
                template: "default",
                interactions: ShareInteractions(likes: 10, comments: 2, shares: 1)
            )
            modelContext.insert(history)
        }
        
        try modelContext.save()
    }
    
    private func createRichShareHistory() throws {
        let calendar = Calendar.current
        let now = Date()
        let tags = ["创意", "清醒梦", "情感", "工作", "生活"]
        let emotions = ["happy", "calm", "excited", "surprised"]
        
        for i in 0..<50 {
            let shareDate = calendar.date(byAdding: .hour, value: -i * 2, to: now) ?? now
            let hour = calendar.component(.hour, from: shareDate)
            
            // 集中在晚上 8-10 点
            let adjustedHour = (hour % 4) + 20
            let adjustedDate = calendar.date(bySettingHour: adjustedHour, minute: 0, second: 0, of: shareDate) ?? shareDate
            
            let history = ShareHistory(
                dreamId: UUID(),
                dreamTitle: "丰富数据分享 \(i)",
                platform: ["wechat", "weibo", "xiaohongshu"][i % 3],
                sharedAt: adjustedDate,
                template: ["minimalist", "detailed", "artistic"][i % 3],
                tags: [tags[i % tags.count]],
                emotion: emotions[i % emotions.count],
                interactions: ShareInteractions(likes: i * 5, comments: i, shares: i / 2)
            )
            modelContext.insert(history)
        }
        
        try modelContext.save()
    }
    
    private func createTimeSpecificShareHistory(hour: Int, count: Int) throws {
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<count {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = 0
            components.second = 0
            
            let shareDate = calendar.date(from: components) ?? now
            
            let history = ShareHistory(
                dreamId: UUID(),
                dreamTitle: "时间特定分享 \(i)",
                platform: "wechat",
                sharedAt: shareDate,
                template: "default",
                interactions: ShareInteractions(likes: 20, comments: 5, shares: 3)
            )
            modelContext.insert(history)
        }
        
        try modelContext.save()
    }
}

// MARK: - 性能测试

@available(macOS 13, iOS 17, *)
final class DreamShareAnalyticsPerformanceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            Dream.self,
            ShareHistory.self,
            ShareStatistics.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    /// 测试大数据量统计计算性能
    func testStatisticsCalculationPerformance() throws {
        // 创建 1000 条分享记录
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<1000 {
            let shareDate = calendar.date(byAdding: .minute, value: -i, to: now) ?? now
            
            let history = ShareHistory(
                dreamId: UUID(),
                dreamTitle: "性能测试分享 \(i)",
                platform: ["wechat", "weibo", "xiaohongshu"][i % 3],
                sharedAt: shareDate,
                template: "default",
                interactions: ShareInteractions(likes: i, comments: i / 10, shares: i / 100)
            )
            modelContext.insert(history)
        }
        
        try modelContext.save()
        
        // 测量统计计算性能
        measure {
            let expectation = self.expectation(description: "Calculate statistics")
            
            Task {
                let service = DreamShareAnalyticsService(modelContext: modelContext)
                _ = try? await service.calculateStatistics()
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10)
        }
    }
    
    /// 测试趋势分析性能
    func testTrendAnalysisPerformance() throws {
        // 创建 365 条分享记录（一年）
        let calendar = Calendar.current
        let now = Date()
        
        for i in 0..<365 {
            let shareDate = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            for _ in 0..<3 {
                let history = ShareHistory(
                    dreamId: UUID(),
                    dreamTitle: "趋势测试分享",
                    platform: "wechat",
                    sharedAt: shareDate,
                    template: "default",
                    interactions: ShareInteractions(likes: 10, comments: 2, shares: 1)
                )
                modelContext.insert(history)
            }
        }
        
        try modelContext.save()
        
        // 测量趋势分析性能
        measure {
            let expectation = self.expectation(description: "Get trend")
            
            Task {
                let service = DreamShareAnalyticsService(modelContext: modelContext)
                _ = try? await service.getShareTrend(days: 365)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10)
        }
    }
}
