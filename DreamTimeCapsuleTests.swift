//
//  DreamTimeCapsuleTests.swift
//  DreamLog - Phase 27: 梦境时间胶囊
//
//  时间胶囊功能单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamTimeCapsuleTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamTimeCapsuleService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存中的 ModelContainer 用于测试
        let schema = Schema([
            DreamTimeCapsule.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        modelContext = ModelContext(modelContainer)
        service = DreamTimeCapsuleService(
            modelContext: modelContext,
            notificationService: MockNotificationService()
        )
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - 基础创建测试
    
    func testCreatePersonalCapsule() async throws {
        let config = TimeCapsuleConfig(
            title: "测试胶囊",
            message: "这是测试消息",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1", "dream-2"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertEqual(capsule.title, "测试胶囊")
        XCTAssertEqual(capsule.message, "这是测试消息")
        XCTAssertEqual(capsule.typedCapsuleType, .personal)
        XCTAssertEqual(capsule.dreamIds.count, 2)
        XCTAssertEqual(capsule.dreamCount, 2)
        XCTAssertEqual(capsule.typedStatus, .locked)
        XCTAssertTrue(capsule.notifyOnUnlock)
    }
    
    func testCreateFutureSelfCapsule() async throws {
        let config = TimeCapsuleConfig(
            title: "给未来的自己",
            message: "希望你好好的",
            capsuleType: .futureSelf,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            notifyOnUnlock: true
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertEqual(capsule.typedCapsuleType, .futureSelf)
        XCTAssertEqual(capsule.daysUntilUnlock, 30)
    }
    
    func testCreateYearlyReviewCapsule() async throws {
        let capsule = DreamTimeCapsule.createYearlyReviewCapsule(
            year: 2025,
            dreamIds: ["dream-1", "dream-2", "dream-3"],
            unlockDate: Date().addingTimeInterval(365 * 24 * 60 * 60)
        )
        
        XCTAssertEqual(capsule.title, "2025 年度梦境回顾")
        XCTAssertEqual(capsule.typedCapsuleType, .yearlyReview)
        XCTAssertEqual(capsule.dreamCount, 3)
    }
    
    func testCreateMilestoneCapsule() async throws {
        let futureDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())!
        
        let capsule = DreamTimeCapsule.createMilestoneCapsule(
            title: "生日纪念",
            message: "生日快乐！",
            dreamIds: ["dream-1"],
            milestoneDate: futureDate
        )
        
        XCTAssertEqual(capsule.typedCapsuleType, .milestone)
        XCTAssertEqual(capsule.unlockDate, futureDate)
    }
    
    // MARK: - 配置验证测试
    
    func testInvalidConfig_MissingTitle() async {
        let config = TimeCapsuleConfig(
            title: "",
            message: "消息",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        XCTAssertFalse(config.isValid)
    }
    
    func testInvalidConfig_NoDreams() async {
        let config = TimeCapsuleConfig(
            title: "标题",
            message: "消息",
            capsuleType: .personal,
            selectedDreamIds: [],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        XCTAssertFalse(config.isValid)
    }
    
    func testInvalidConfig_PastUnlockDate() async {
        let config = TimeCapsuleConfig(
            title: "标题",
            message: "消息",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 天前
        )
        
        XCTAssertFalse(config.isValid)
    }
    
    func testValidConfig() async {
        let config = TimeCapsuleConfig(
            title: "有效配置",
            message: "消息",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        XCTAssertTrue(config.isValid)
    }
    
    // MARK: - 状态管理测试
    
    func testCapsuleIsLocked() async throws {
        let config = TimeCapsuleConfig(
            title: "锁定胶囊",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertTrue(capsule.isLocked)
        XCTAssertFalse(capsule.isReadyToUnlock)
        XCTAssertEqual(capsule.typedStatus, .locked)
    }
    
    func testCapsuleReadyToUnlock() async throws {
        let config = TimeCapsuleConfig(
            title: "可解锁胶囊",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(-7 * 24 * 60 * 60) // 已过期
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertFalse(capsule.isLocked)
        XCTAssertTrue(capsule.isReadyToUnlock)
    }
    
    func testUnlockCapsule() async throws {
        let config = TimeCapsuleConfig(
            title: "待解锁胶囊",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(-1 * 24 * 60 * 60) // 1 天前
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertTrue(capsule.isReadyToUnlock)
        XCTAssertNil(capsule.unlockedAt)
        
        try await service.unlockCapsule(capsule)
        
        XCTAssertEqual(capsule.typedStatus, .unlocked)
        XCTAssertNotNil(capsule.unlockedAt)
        XCTAssertEqual(capsule.viewCount, 1)
    }
    
    func testUnlockNotReadyCapsule() async throws {
        let config = TimeCapsuleConfig(
            title: "未就绪胶囊",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        do {
            try await service.unlockCapsule(capsule)
            XCTFail("应该抛出错误")
        } catch TimeCapsuleError.notReadyToUnlock {
            // 预期错误
        } catch {
            XCTFail("抛出错误类型不正确")
        }
    }
    
    // MARK: - 收藏管理测试
    
    func testToggleFavorite() async throws {
        let config = TimeCapsuleConfig(
            title: "收藏测试",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertFalse(capsule.isFavorite)
        
        try await service.toggleFavorite(capsule)
        XCTAssertTrue(capsule.isFavorite)
        
        try await service.toggleFavorite(capsule)
        XCTAssertFalse(capsule.isFavorite)
    }
    
    // MARK: - 删除测试
    
    func testDeleteCapsule() async throws {
        let config = TimeCapsuleConfig(
            title: "待删除胶囊",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        XCTAssertEqual(service.capsules.count, 1)
        
        try await service.deleteCapsule(capsule)
        
        XCTAssertEqual(service.capsules.count, 0)
    }
    
    // MARK: - 统计测试
    
    func testCapsuleStats() async throws {
        // 创建不同类型的胶囊
        let configs = [
            TimeCapsuleConfig(title: "胶囊 1", message: "", capsuleType: .personal, selectedDreamIds: ["1"], unlockDate: Date().addingTimeInterval(7 * 24 * 60 * 60)),
            TimeCapsuleConfig(title: "胶囊 2", message: "", capsuleType: .futureSelf, selectedDreamIds: ["1", "2"], unlockDate: Date().addingTimeInterval(14 * 24 * 60 * 60)),
            TimeCapsuleConfig(title: "胶囊 3", message: "", capsuleType: .yearlyReview, selectedDreamIds: ["1", "2", "3"], unlockDate: Date().addingTimeInterval(-7 * 24 * 60 * 60))
        ]
        
        for config in configs {
            _ = try await service.createCapsule(config: config)
        }
        
        await service.loadCapsules()
        
        XCTAssertEqual(service.stats.totalCapsules, 3)
        XCTAssertEqual(service.stats.lockedCapsules, 2)
        XCTAssertEqual(service.stats.unlockedCapsules, 1)
        XCTAssertEqual(service.stats.totalDreams, 6)
    }
    
    // MARK: - 解锁进度测试
    
    func testUnlockProgress() async throws {
        let unlockDate = Date().addingTimeInterval(10 * 24 * 60 * 60) // 10 天后
        
        let config = TimeCapsuleConfig(
            title: "进度测试",
            message: "",
            capsuleType: .personal,
            selectedDreamIds: ["dream-1"],
            unlockDate: unlockDate
        )
        
        let capsule = try await service.createCapsule(config: config)
        
        // 刚创建时进度应该接近 0
        XCTAssertGreaterThanOrEqual(capsule.unlockProgress, 0)
        XCTAssertLessThan(capsule.unlockProgress, 0.2)
        
        XCTAssertEqual(capsule.daysUntilUnlock, 10)
    }
    
    // MARK: - 类型枚举测试
    
    func testTimeCapsuleTypeDisplayNames() {
        XCTAssertEqual(TimeCapsuleType.personal.displayName, "💭 个人回忆")
        XCTAssertEqual(TimeCapsuleType.futureSelf.displayName, "📮 给未来的自己")
        XCTAssertEqual(TimeCapsuleType.shareWithFriend.displayName, "👥 分享给朋友")
        XCTAssertEqual(TimeCapsuleType.yearlyReview.displayName, "📅 年度回顾")
        XCTAssertEqual(TimeCapsuleType.milestone.displayName, "🏆 里程碑纪念")
    }
    
    func testTimeCapsuleStatusDisplayNames() {
        XCTAssertEqual(TimeCapsuleStatus.locked.displayName, "🔒 已锁定")
        XCTAssertEqual(TimeCapsuleStatus.unlocked.displayName, "🔓 已解锁")
        XCTAssertEqual(TimeCapsuleStatus.expired.displayName, "⏰ 已过期")
    }
    
    // MARK: - 性能测试
    
    func testCreateMultipleCapsulesPerformance() async throws {
        measure {
            let expectation = XCTestExpectation(description: "创建多个胶囊")
            
            Task {
                for i in 0..<10 {
                    let config = TimeCapsuleConfig(
                        title: "性能测试胶囊 \(i)",
                        message: "",
                        capsuleType: .personal,
                        selectedDreamIds: ["dream-\(i)"],
                        unlockDate: Date().addingTimeInterval(Double(i + 1) * 24 * 60 * 60)
                    )
                    
                    _ = try? await service.createCapsule(config: config)
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
}

// MARK: - Mock 通知服务

@MainActor
final class MockNotificationService: NotificationServiceProtocol {
    var scheduledNotifications: [UNNotificationRequest] = []
    
    func scheduleNotification(_ request: UNNotificationRequest) async {
        scheduledNotifications.append(request)
    }
    
    func cancelNotifications(withIds ids: [String]) async {
        scheduledNotifications.removeAll { request in
            ids.contains(request.identifier)
        }
    }
    
    func cancelAllNotifications() async {
        scheduledNotifications.removeAll()
    }
}

// MARK: - 协议定义

protocol NotificationServiceProtocol {
    func scheduleNotification(_ request: UNNotificationRequest) async
    func cancelNotifications(withIds ids: [String]) async
    func cancelAllNotifications() async
}
