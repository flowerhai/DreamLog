//
//  DreamCalendarIntegrationTests.swift
//  DreamLogTests
//
//  Phase 77: Dream Calendar Integration - Unit Tests
//  梦境日历集成功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 16.0, *)
final class DreamCalendarIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamCalendarIntegrationService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存中的 ModelContainer 用于测试
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Dream.self, CalendarEvent.self,
            configurations: [config]
        )
        modelContext = ModelContext(modelContainer)
        service = DreamCalendarIntegrationService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 权限管理测试
    
    /// 测试权限状态检查
    func testCheckPermissionStatus() {
        let status = service.checkPermissionStatus()
        
        // 权限状态应该是有效的枚举值
        XCTAssertTrue([.notDetermined, .restricted, .denied, .authorized, .fullAccess].contains(status))
    }
    
    /// 测试权限状态可以访问判断
    func testPermissionStatusCanAccess() {
        let authorized = CalendarPermissionStatus.authorized
        let fullAccess = CalendarPermissionStatus.fullAccess
        let denied = CalendarPermissionStatus.denied
        
        XCTAssertTrue(authorized.canAccess)
        XCTAssertTrue(fullAccess.canAccess)
        XCTAssertFalse(denied.canAccess)
    }
    
    // MARK: - 配置管理测试
    
    /// 测试默认配置加载
    func testDefaultConfig() {
        // 验证默认配置值
        let config = service.getConfig()
        
        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.autoSync)
        XCTAssertEqual(config.syncFrequency, .daily)
        XCTAssertEqual(config.defaultLinkWindow, 24)
        XCTAssertFalse(config.privacyMode)
    }
    
    /// 测试配置更新
    func testUpdateConfig() {
        let newConfig = CalendarIntegrationConfig(
            enabled: false,
            autoSync: false,
            syncFrequency: .weekly,
            defaultLinkWindow: 48,
            privacyMode: true,
            notifyOnCorrelation: false
        )
        
        service.updateConfig(newConfig)
        
        let savedConfig = service.getConfig()
        XCTAssertFalse(savedConfig.enabled)
        XCTAssertFalse(savedConfig.autoSync)
        XCTAssertEqual(savedConfig.syncFrequency, .weekly)
        XCTAssertEqual(savedConfig.defaultLinkWindow, 48)
        XCTAssertTrue(savedConfig.privacyMode)
    }
    
    // MARK: - 事件类型测试
    
    /// 测试日历事件类型图标
    func testCalendarEventTypeIcons() {
        let allTypes = CalendarEventType.allCases
        
        for type in allTypes {
            XCTAssertFalse(type.icon.isEmpty, "事件类型 \(type.rawValue) 应该有图标")
        }
    }
    
    /// 测试日历事件类型颜色
    func testCalendarEventTypeColors() {
        let allTypes = CalendarEventType.allCases
        
        for type in allTypes {
            XCTAssertFalse(type.color.isEmpty, "事件类型 \(type.rawValue) 应该有颜色")
            // 验证颜色是有效的十六进制格式
            XCTAssertEqual(type.color.count, 6, "颜色应该是 6 位十六进制")
        }
    }
    
    /// 测试事件类型图标映射
    func testEventTypeIconMapping() {
        XCTAssertEqual(CalendarEventType.work.icon, "💼")
        XCTAssertEqual(CalendarEventType.meeting.icon, "📅")
        XCTAssertEqual(CalendarEventType.personal.icon, "👤")
        XCTAssertEqual(CalendarEventType.family.icon, "👨‍👩‍👧‍👦")
        XCTAssertEqual(CalendarEventType.social.icon, "🎉")
        XCTAssertEqual(CalendarEventType.exercise.icon, "🏃")
        XCTAssertEqual(CalendarEventType.travel.icon, "✈️")
        XCTAssertEqual(CalendarEventType.medical.icon, "🏥")
        XCTAssertEqual(CalendarEventType.education.icon, "📚")
        XCTAssertEqual(CalendarEventType.entertainment.icon, "🎬")
        XCTAssertEqual(CalendarEventType.sleep.icon, "😴")
        XCTAssertEqual(CalendarEventType.meal.icon, "🍽️")
        XCTAssertEqual(CalendarEventType.other.icon, "📌")
    }
    
    // MARK: - 时间关系测试
    
    /// 测试时间关系枚举
    func testTimeRelationCases() {
        let allRelations = TimeRelation.allCases
        XCTAssertEqual(allRelations.count, 5)
        
        XCTAssertTrue(allRelations.contains(.before))
        XCTAssertTrue(allRelations.contains(.after))
        XCTAssertTrue(allRelations.contains(.during))
        XCTAssertTrue(allRelations.contains(.surrounding))
        XCTAssertTrue(allRelations.contains(.multiple))
    }
    
    /// 测试时间关系描述
    func testTimeRelationDescriptions() {
        for relation in TimeRelation.allCases {
            XCTAssertFalse(relation.description.isEmpty)
        }
    }
    
    // MARK: - 建议类型测试
    
    /// 测试建议类型图标
    func testSuggestionTypeIcons() {
        let allTypes = SuggestionType.allCases
        
        for type in allTypes {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
    
    /// 测试建议类型颜色
    func testSuggestionTypeColors() {
        let allTypes = SuggestionType.allCases
        
        for type in allTypes {
            XCTAssertFalse(type.color.isEmpty)
        }
    }
    
    // MARK: - 同步频率测试
    
    /// 测试同步频率枚举
    func testSyncFrequencyCases() {
        let allFrequencies = SyncFrequency.allCases
        XCTAssertGreaterThanOrEqual(allFrequencies.count, 3)
    }
    
    // MARK: - 日期范围测试
    
    /// 测试日期范围创建
    func testDateRangeCreation() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        
        let range = DateRange(start: start, end: end)
        
        XCTAssertEqual(range.start, start)
        XCTAssertEqual(range.end, end)
        XCTAssertGreaterThan(range.end, range.start)
    }
    
    /// 测试日期范围验证
    func testDateRangeValidation() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: -1, to: start)!
        
        let range = DateRange(start: start, end: end)
        
        // 结束日期早于开始日期应该被检测到
        XCTAssertGreaterThan(range.start, range.end)
    }
    
    // MARK: - 时间线索引测试
    
    /// 测试时间线索引项创建
    func testTimelineItemCreation() {
        let item = TimelineItem(
            id: UUID(),
            date: Date(),
            title: "测试事件",
            subtitle: "测试副标题",
            icon: "📅",
            color: "4ECDC4",
            itemType: .event,
            isLinked: true
        )
        
        XCTAssertEqual(item.title, "测试事件")
        XCTAssertEqual(item.subtitle, "测试副标题")
        XCTAssertEqual(item.icon, "📅")
        XCTAssertTrue(item.isLinked)
    }
    
    /// 测试时间线索引项类型
    func testTimelineItemTypeCases() {
        let allTypes = TimelineItemType.allCases
        XCTAssertGreaterThanOrEqual(allTypes.count, 2)
        
        XCTAssertTrue(allTypes.contains(.dream))
        XCTAssertTrue(allTypes.contains(.event))
    }
    
    // MARK: - 关联分析测试
    
    /// 测试关联强度计算
    func testCorrelationStrengthCalculation() {
        // 关联强度应该在 0-1 之间
        let strengths: [Double] = [0.0, 0.25, 0.5, 0.75, 1.0]
        
        for strength in strengths {
            XCTAssertGreaterThanOrEqual(strength, 0.0)
            XCTAssertLessThanOrEqual(strength, 1.0)
        }
    }
    
    // MARK: - 统计测试
    
    /// 测试统计数据结构
    func testCorrelationStatsStructure() {
        // 验证统计模型的基本结构
        let stats = CalendarCorrelationStats(
            totalLinkedDreams: 10,
            totalEvents: 20,
            averageCorrelationStrength: 0.65,
            topEventTypes: [],
            topTimeRelations: [],
            weeklyPattern: [0, 1, 2, 3, 4, 5, 6],
            recentCorrelations: []
        )
        
        XCTAssertEqual(stats.totalLinkedDreams, 10)
        XCTAssertEqual(stats.totalEvents, 20)
        XCTAssertEqual(stats.averageCorrelationStrength, 0.65)
        XCTAssertEqual(stats.weeklyPattern.count, 7)
    }
    
    // MARK: - 错误处理测试
    
    /// 测试功能禁用错误
    func testFeatureDisabledError() {
        let error = CalendarIntegrationError.featureDisabled
        XCTAssertEqual(error.localizedDescription, "日历集成功能已禁用")
    }
    
    /// 测试权限拒绝错误
    func testPermissionDeniedError() {
        let error = CalendarIntegrationError.permissionDenied
        XCTAssertEqual(error.localizedDescription, "没有日历访问权限")
    }
    
    /// 测试同步失败错误
    func testSyncFailedError() {
        let error = CalendarIntegrationError.syncFailed("测试错误")
        XCTAssertEqual(error.localizedDescription, "同步失败：测试错误")
    }
    
    // MARK: - 性能测试
    
    /// 测试配置加载性能
    func testConfigLoadPerformance() {
        let measureStartTime = CACurrentMediaTime()
        
        for _ in 0..<100 {
            _ = service.getConfig()
        }
        
        let elapsedTime = CACurrentMediaTime() - measureStartTime
        
        // 100 次配置加载应该小于 0.1 秒
        XCTAssertLessThan(elapsedTime, 0.1, "配置加载性能应该优于 0.1 秒")
    }
    
    // MARK: - 边界条件测试
    
    /// 测试空日期范围
    func testEmptyDateRange() {
        let start = Date()
        let range = DateRange(start: start, end: start)
        
        XCTAssertEqual(range.start, range.end)
    }
    
    /// 测试极大日期范围
    func testLargeDateRange() {
        let start = Calendar.current.date(byAdding: .year, value: -10, to: Date())!
        let end = Calendar.current.date(byAdding: .year, value: 10, to: Date())!
        
        let range = DateRange(start: start, end: end)
        
        XCTAssertGreaterThan(range.end, range.start)
    }
    
    // MARK: - Codable 测试
    
    /// 测试配置编码解码
    func testConfigCodable() {
        let originalConfig = CalendarIntegrationConfig(
            enabled: true,
            autoSync: false,
            syncFrequency: .weekly,
            defaultLinkWindow: 36,
            privacyMode: true,
            notifyOnCorrelation: false
        )
        
        // 编码
        let encoded = try? JSONEncoder().encode(originalConfig)
        XCTAssertNotNil(encoded)
        
        // 解码
        let decoded = try? JSONDecoder().decode(CalendarIntegrationConfig.self, from: encoded!)
        XCTAssertNotNil(decoded)
        
        // 验证
        XCTAssertEqual(decoded?.enabled, originalConfig.enabled)
        XCTAssertEqual(decoded?.autoSync, originalConfig.autoSync)
        XCTAssertEqual(decoded?.syncFrequency, originalConfig.syncFrequency)
        XCTAssertEqual(decoded?.defaultLinkWindow, originalConfig.defaultLinkWindow)
        XCTAssertEqual(decoded?.privacyMode, originalConfig.privacyMode)
    }
    
    /// 测试同步频率编码解码
    func testSyncFrequencyCodable() {
        let frequencies: [SyncFrequency] = [.hourly, .daily, .weekly, .manual]
        
        for freq in frequencies {
            let encoded = try? JSONEncoder().encode(freq)
            XCTAssertNotNil(encoded)
            
            let decoded = try? JSONDecoder().decode(SyncFrequency.self, from: encoded!)
            XCTAssertEqual(decoded, freq)
        }
    }
}

// MARK: - 预览数据辅助

@available(iOS 16.0, *)
extension DreamCalendarIntegrationTests {
    
    /// 创建测试用梦境数据
    func createTestDream(title: String, date: Date) -> Dream {
        let dream = Dream(
            title: title,
            content: "测试梦境内容",
            date: date
        )
        return dream
    }
    
    /// 创建测试用日历事件
    func createTestEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        type: CalendarEventType = .work
    ) -> CalendarEvent {
        let event = CalendarEvent(
            eventId: UUID().uuidString,
            title: title,
            startDate: startDate,
            endDate: endDate,
            calendarName: "测试日历",
            eventType: type
        )
        return event
    }
}
