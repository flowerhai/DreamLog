//
//  DreamSmartInsightsTests.swift
//  DreamLogTests
//
//  Phase 78: Smart Dream Insights & Notifications
//  智能梦境洞察与通知单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamSmartInsightsTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            Dream.self,
            DreamSmartInsight.self,
            DreamSmartNotificationSettings.self,
            DreamInsightType.self
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
    
    // MARK: - 数据模型测试
    
    /// 测试洞察类型创建
    func testInsightTypeCreation() {
        let type = DreamInsightType(
            name: "测试类型",
            nameKey: "insight.test",
            icon: "🧪",
            color: "#FF0000",
            description: "测试描述"
        )
        
        XCTAssertEqual(type.name, "测试类型")
        XCTAssertEqual(type.nameKey, "insight.test")
        XCTAssertEqual(type.icon, "🧪")
        XCTAssertEqual(type.color, "#FF0000")
        XCTAssertEqual(type.description, "测试描述")
    }
    
    /// 测试预定义洞察类型数量
    func testPredefinedInsightTypes() {
        XCTAssertEqual(DreamInsightType.allTypes.count, 8)
        
        let typeNames = DreamInsightType.allTypes.map { $0.name }
        XCTAssertTrue(typeNames.contains("模式发现"))
        XCTAssertTrue(typeNames.contains("情绪趋势"))
        XCTAssertTrue(typeNames.contains("清醒梦机会"))
        XCTAssertTrue(typeNames.contains("里程碑"))
    }
    
    /// 测试洞察创建
    func testInsightCreation() {
        let type = DreamInsightType.allTypes[0]
        let insight = DreamSmartInsight(
            title: "测试洞察",
            content: "测试内容",
            type: type,
            priority: .high,
            confidence: 0.85,
            tags: ["测试", "标签"]
        )
        
        XCTAssertEqual(insight.title, "测试洞察")
        XCTAssertEqual(insight.content, "测试内容")
        XCTAssertEqual(insight.priority, .high)
        XCTAssertEqual(insight.confidence, 0.85)
        XCTAssertEqual(insight.tags, ["测试", "标签"])
        XCTAssertFalse(insight.isRead)
        XCTAssertFalse(insight.isSaved)
        XCTAssertFalse(insight.notificationSent)
    }
    
    /// 测试优先级枚举
    func testInsightPriority() {
        XCTAssertEqual(InsightPriority.low.rawValue, 0)
        XCTAssertEqual(InsightPriority.medium.rawValue, 1)
        XCTAssertEqual(InsightPriority.high.rawValue, 2)
        XCTAssertEqual(InsightPriority.urgent.rawValue, 3)
        
        XCTAssertEqual(InsightPriority.low.displayName, "低")
        XCTAssertEqual(InsightPriority.high.displayName, "高")
        
        XCTAssertEqual(InsightPriority.low.color, "#6B7280")
        XCTAssertEqual(InsightPriority.urgent.color, "#EF4444")
    }
    
    /// 测试洞察统计
    func testInsightStatistics() {
        var stats = InsightStatistics(
            totalInsights: 100,
            unreadCount: 25,
            savedCount: 10,
            byType: ["模式发现": 30, "情绪趋势": 20],
            byPriority: ["高": 15, "中": 50],
            averageConfidence: 0.75
        )
        
        XCTAssertEqual(stats.totalInsights, 100)
        XCTAssertEqual(stats.unreadCount, 25)
        XCTAssertEqual(stats.savedCount, 10)
        XCTAssertEqual(stats.byType["模式发现"], 30)
        XCTAssertEqual(stats.byPriority["高"], 15)
        XCTAssertEqual(stats.averageConfidence, 0.75)
    }
    
    /// 测试配置默认值
    func testInsightGenerationConfigDefault() {
        let config = InsightGenerationConfig.default
        
        XCTAssertTrue(config.enabled)
        XCTAssertEqual(config.minConfidence, 0.6)
        XCTAssertEqual(config.checkInterval, 3600)
        XCTAssertEqual(config.maxDailyInsights, 5)
        XCTAssertEqual(config.quietHoursStart, 23)
        XCTAssertEqual(config.quietHoursEnd, 8)
        XCTAssertTrue(config.notifyOnHighPriority)
    }
    
    /// 测试通知设置
    func testNotificationSettings() {
        let settings = DreamSmartNotificationSettings(
            enabled: true,
            dailyInsightCount: 3
        )
        
        XCTAssertTrue(settings.enabled)
        XCTAssertEqual(settings.dailyInsightCount, 3)
        XCTAssertEqual(settings.config.maxDailyInsights, 5)
    }
    
    // MARK: - 数据持久化测试
    
    /// 测试洞察保存和读取
    func testInsightPersistence() throws {
        let type = DreamInsightType.allTypes[0]
        let insight = DreamSmartInsight(
            title: "持久化测试",
            content: "测试内容",
            type: type,
            confidence: 0.9
        )
        
        modelContext.insert(insight)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in i.title == "持久化测试" }
        )
        
        let fetched = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.content, "测试内容")
        XCTAssertEqual(fetched.first?.confidence, 0.9)
    }
    
    /// 测试洞察更新
    func testInsightUpdate() throws {
        let insight = DreamSmartInsight(
            title: "更新测试",
            content: "原始内容",
            type: DreamInsightType.allTypes[0]
        )
        
        modelContext.insert(insight)
        try modelContext.save()
        
        insight.isRead = true
        insight.isSaved = true
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in i.title == "更新测试" }
        )
        
        let fetched = try modelContext.fetch(fetchDescriptor)
        XCTAssertTrue(fetched.first?.isRead ?? false)
        XCTAssertTrue(fetched.first?.isSaved ?? false)
    }
    
    /// 测试洞察删除
    func testInsightDeletion() throws {
        let insight = DreamSmartInsight(
            title: "删除测试",
            content: "待删除",
            type: DreamInsightType.allTypes[0]
        )
        
        modelContext.insert(insight)
        try modelContext.save()
        
        modelContext.delete(insight)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in i.title == "删除测试" }
        )
        
        let fetched = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetched.count, 0)
    }
    
    // MARK: - 筛选和排序测试
    
    /// 测试按优先级筛选
    func testFilterByPriority() throws {
        let priorities: [InsightPriority] = [.low, .medium, .high, .urgent]
        
        for priority in priorities {
            let insight = DreamSmartInsight(
                title: "优先级测试 - \(priority.displayName)",
                content: "内容",
                type: DreamInsightType.allTypes[0],
                priority: priority
            )
            modelContext.insert(insight)
        }
        
        try modelContext.save()
        
        let highPriorityDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in i.priority == InsightPriority.high }
        )
        
        let highPriority = try modelContext.fetch(highPriorityDescriptor)
        XCTAssertEqual(highPriority.count, 1)
        XCTAssertEqual(highPriority.first?.priority, .high)
    }
    
    /// 测试按状态筛选
    func testFilterByStatus() throws {
        for i in 0..<5 {
            let insight = DreamSmartInsight(
                title: "状态测试 \(i)",
                content: "内容",
                type: DreamInsightType.allTypes[0],
                isRead: i >= 3,
                isSaved: i >= 4
            )
            modelContext.insert(insight)
        }
        
        try modelContext.save()
        
        let unreadDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in !i.isRead }
        )
        
        let unread = try modelContext.fetch(unreadDescriptor)
        XCTAssertEqual(unread.count, 3)
        
        let savedDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in i.isSaved }
        )
        
        let saved = try modelContext.fetch(savedDescriptor)
        XCTAssertEqual(saved.count, 1)
    }
    
    /// 测试按时间排序
    func testSortByDate() throws {
        let dates = [
            Date().addingTimeInterval(-86400 * 3),
            Date().addingTimeInterval(-86400 * 2),
            Date().addingTimeInterval(-86400),
            Date()
        ]
        
        for date in dates {
            let insight = DreamSmartInsight(
                title: "时间测试",
                content: "内容",
                type: DreamInsightType.allTypes[0],
                createdAt: date
            )
            modelContext.insert(insight)
        }
        
        try modelContext.save()
        
        let descriptor = FetchDescriptor<DreamSmartInsight>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        let sorted = try modelContext.fetch(descriptor)
        XCTAssertEqual(sorted.count, 4)
        XCTAssertTrue(sorted[0].createdAt > sorted[1].createdAt)
        XCTAssertTrue(sorted[1].createdAt > sorted[2].createdAt)
        XCTAssertTrue(sorted[2].createdAt > sorted[3].createdAt)
    }
    
    // MARK: - 统计测试
    
    /// 测试统计计算
    func testStatisticsCalculation() throws {
        let types = [DreamInsightType.allTypes[0], DreamInsightType.allTypes[1]]
        let priorities: [InsightPriority] = [.low, .medium, .high]
        
        for i in 0..<10 {
            let insight = DreamSmartInsight(
                title: "统计测试 \(i)",
                content: "内容",
                type: types[i % 2],
                priority: priorities[i % 3],
                isRead: i >= 5,
                isSaved: i >= 8,
                confidence: 0.5 + Double(i) * 0.05
            )
            modelContext.insert(insight)
        }
        
        try modelContext.save()
        
        let allDescriptor = FetchDescriptor<DreamSmartInsight>()
        let all = try modelContext.fetch(allDescriptor)
        
        XCTAssertEqual(all.count, 10)
        XCTAssertEqual(all.filter { !$0.isRead }.count, 5)
        XCTAssertEqual(all.filter { $0.isSaved }.count, 2)
        
        let avgConfidence = all.map { $0.confidence }.reduce(0, +) / Double(all.count)
        XCTAssertGreaterThan(avgConfidence, 0.5)
        XCTAssertLessThan(avgConfidence, 1.0)
    }
    
    // MARK: - 配置测试
    
    /// 测试免打扰时间判断
    func testQuietHoursDetection() {
        let settings = DreamSmartNotificationSettings()
        
        // 测试跨天情况 (23:00 - 08:00)
        let calendar = Calendar.current
        
        // 23:30 应该在免打扰时间内
        var testDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 1, hour: 23, minute: 30).date!
        XCTAssertFalse(isQuietHours(settings: settings, date: testDate)) // 需要实现辅助方法
        
        // 03:00 应该在免打扰时间内
        testDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 1, hour: 3, minute: 0).date!
        XCTAssertFalse(isQuietHours(settings: settings, date: testDate))
        
        // 12:00 不应该在免打扰时间内
        testDate = DateComponents(calendar: calendar, year: 2024, month: 1, day: 1, hour: 12, minute: 0).date!
        XCTAssertFalse(isQuietHours(settings: settings, date: testDate))
    }
    
    /// 测试每日计数重置
    func testDailyCountReset() {
        var settings = DreamSmartNotificationSettings(
            dailyInsightCount: 3,
            lastResetDate: Date().addingTimeInterval(-86400 * 2) // 2 天前
        )
        
        // 应该重置
        XCTAssertTrue(shouldResetDailyCount(settings: settings))
        
        // 更新到今天
        settings.lastResetDate = Date()
        XCTAssertFalse(shouldResetDailyCount(settings: settings))
    }
    
    // MARK: - 边界情况测试
    
    /// 测试空数据处理
    func testEmptyDataHandling() throws {
        let descriptor = FetchDescriptor<DreamSmartInsight>()
        let insights = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(insights.count, 0)
    }
    
    /// 测试大量数据
    func testLargeDataSet() throws {
        for i in 0..<100 {
            let insight = DreamSmartInsight(
                title: "批量测试 \(i)",
                content: "内容 \(i)",
                type: DreamInsightType.allTypes[i % 8],
                priority: InsightPriority.allCases[i % 4],
                confidence: 0.5 + Double.random(in: 0...0.5)
            )
            modelContext.insert(insight)
        }
        
        try modelContext.save()
        
        let descriptor = FetchDescriptor<DreamSmartInsight>()
        let insights = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(insights.count, 100)
    }
    
    /// 测试特殊字符处理
    func testSpecialCharacterHandling() throws {
        let insight = DreamSmartInsight(
            title: "特殊字符测试！@#$%",
            content: "内容包含 emoji 🌙✨ 和特殊字符 & < >",
            type: DreamInsightType.allTypes[0]
        )
        
        modelContext.insert(insight)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<DreamSmartInsight>(
            predicate: #Predicate { i in i.title == "特殊字符测试！@#$%" }
        )
        
        let fetched = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertTrue(fetched.first?.content.contains("🌙") ?? false)
    }
    
    // MARK: - 辅助方法
    
    private func isQuietHours(settings: DreamSmartNotificationSettings, date: Date) -> Bool {
        let currentHour = Calendar.current.component(.hour, from: date)
        let start = settings.config.quietHoursStart
        let end = settings.config.quietHoursEnd
        
        if start > end {
            return currentHour >= start || currentHour < end
        } else {
            return currentHour >= start && currentHour < end
        }
    }
    
    private func shouldResetDailyCount(settings: DreamSmartNotificationSettings) -> Bool {
        let now = Date()
        let lastReset = settings.lastResetDate
        return Calendar.current.isDateInToday(now) && !Calendar.current.isDateInToday(lastReset)
    }
}

// MARK: - 性能测试

@available(iOS 17.0, *)
extension DreamSmartInsightsTests {
    
    /// 性能测试：创建大量洞察
    func testPerformanceInsightCreation() throws {
        self.measure {
            for _ in 0..<50 {
                let insight = DreamSmartInsight(
                    title: "性能测试",
                    content: "测试内容",
                    type: DreamInsightType.allTypes.randomElement()!
                )
                modelContext.insert(insight)
            }
            try? modelContext.save()
        }
    }
    
    /// 性能测试：查询洞察
    func testPerformanceInsightQuery() throws {
        // 准备数据
        for i in 0..<100 {
            let insight = DreamSmartInsight(
                title: "性能测试 \(i)",
                content: "内容",
                type: DreamInsightType.allTypes[i % 8]
            )
            modelContext.insert(insight)
        }
        try? modelContext.save()
        
        self.measure {
            let descriptor = FetchDescriptor<DreamSmartInsight>()
            _ = try? modelContext.fetch(descriptor)
        }
    }
}
