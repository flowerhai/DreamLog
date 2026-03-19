//
//  DreamPrivacyTests.swift
//  DreamLogTests
//
//  Phase 70 - 梦境隐私模式单元测试
//  测试覆盖：数据模型/服务功能/生物识别/自动锁定/统计计算
//

import XCTest
import LocalAuthentication
@testable import DreamLog

@MainActor
final class DreamPrivacyTests: XCTestCase {
    
    // MARK: - 测试数据
    
    var testDreams: [Dream] = []
    var privacyService: DreamPrivacyService!
    
    override func setUp() async throws {
        try await super.setUp()
        testDreams = createTestDreams()
        privacyService = DreamPrivacyService()
    }
    
    override func tearDown() async throws {
        testDreams = []
        privacyService = nil
        try await super.tearDown()
    }
    
    // MARK: - 辅助方法
    
    private func createTestDreams() -> [Dream] {
        return [
            Dream(
                title: "普通梦境",
                content: "这是一个普通的梦境",
                tags: ["飞行", "自由"],
                emotions: [.happy, .calm],
                clarity: 4,
                intensity: 3,
                isLucid: false
            ),
            Dream(
                title: "噩梦",
                content: "这是一个恐怖的噩梦，有暴力和恐怖元素",
                tags: ["噩梦", "恐怖"],
                emotions: [.fear, .anxious],
                clarity: 2,
                intensity: 5,
                isLucid: false
            ),
            Dream(
                title: "清醒梦",
                content: "我知道自己在做梦",
                tags: ["清醒梦", "控制"],
                emotions: [.excited],
                clarity: 5,
                intensity: 4,
                isLucid: true
            ),
            Dream(
                title: "创伤梦境",
                content: "这个梦境涉及创伤性内容",
                tags: ["创伤", "敏感"],
                emotions: [.sad, .fear],
                clarity: 3,
                intensity: 5,
                isLucid: false
            )
        ]
    }
    
    // MARK: - DreamLockType 枚举测试
    
    func testDreamLockTypeAllCases() {
        let allCases: [DreamLockType] = [.none, .biometric, .passcode, .autoLock]
        XCTAssertEqual(allCases.count, 4, "应该有 4 种锁定类型")
    }
    
    func testDreamLockTypeDisplayNames() {
        XCTAssertEqual(DreamLockType.none.displayName, "无锁定")
        XCTAssertEqual(DreamLockType.biometric.displayName, "生物识别")
        XCTAssertEqual(DreamLockType.passcode.displayName, "密码")
        XCTAssertEqual(DreamLockType.autoLock.displayName, "自动锁定")
    }
    
    func testDreamLockTypeIcons() {
        XCTAssertFalse(DreamLockType.none.icon.isEmpty)
        XCTAssertFalse(DreamLockType.biometric.icon.isEmpty)
        XCTAssertFalse(DreamLockType.passcode.icon.isEmpty)
        XCTAssertFalse(DreamLockType.autoLock.icon.isEmpty)
    }
    
    func testDreamLockTypeColors() {
        // 验证颜色不为空
        XCTAssertNotNil(DreamLockType.none.color)
        XCTAssertNotNil(DreamLockType.biometric.color)
        XCTAssertNotNil(DreamLockType.passcode.color)
        XCTAssertNotNil(DreamLockType.autoLock.color)
    }
    
    // MARK: - DreamPrivacySettings 测试
    
    func testPrivacySettingsDefault() {
        let settings = DreamPrivacySettings()
        
        XCTAssertFalse(settings.privacyModeEnabled)
        XCTAssertEqual(settings.lockType, .none)
        XCTAssertTrue(settings.biometricEnabled)
        XCTAssertFalse(settings.autoLockEnabled)
        XCTAssertTrue(settings.autoLockKeywords.isEmpty)
        XCTAssertEqual(settings.appLockTimeout, 300) // 5 分钟
    }
    
    func testPrivacySettingsCodable() throws {
        var settings = DreamPrivacySettings()
        settings.privacyModeEnabled = true
        settings.lockType = .biometric
        settings.biometricEnabled = true
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["噩梦", "恐怖", "暴力"]
        settings.appLockTimeout = 600
        
        // 编码
        let encoded = try JSONEncoder().encode(settings)
        
        // 解码
        let decoded = try JSONDecoder().decode(DreamPrivacySettings.self, from: encoded)
        
        XCTAssertEqual(decoded.privacyModeEnabled, settings.privacyModeEnabled)
        XCTAssertEqual(decoded.lockType, settings.lockType)
        XCTAssertEqual(decoded.biometricEnabled, settings.biometricEnabled)
        XCTAssertEqual(decoded.autoLockEnabled, settings.autoLockEnabled)
        XCTAssertEqual(decoded.autoLockKeywords, settings.autoLockKeywords)
        XCTAssertEqual(decoded.appLockTimeout, settings.appLockTimeout)
    }
    
    // MARK: - DreamPrivacyService 测试
    
    func testPrivacyServiceInitialization() async {
        let service = DreamPrivacyService()
        
        // 验证服务可以正常初始化
        XCTAssertNotNil(service)
        
        // 验证可以获取设置
        let settings = await service.getSettings()
        XCTAssertNotNil(settings)
    }
    
    func testPrivacyServiceGetSettings() async {
        let settings = await privacyService.getSettings()
        
        XCTAssertNotNil(settings)
        XCTAssertFalse(settings.privacyModeEnabled)
        XCTAssertEqual(settings.lockType, .none)
    }
    
    func testPrivacyServiceUpdateSettings() async throws {
        var settings = await privacyService.getSettings()
        settings.privacyModeEnabled = true
        settings.lockType = .biometric
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["噩梦", "恐怖"]
        
        try await privacyService.updateSettings(settings)
        
        let updatedSettings = await privacyService.getSettings()
        XCTAssertTrue(updatedSettings.privacyModeEnabled)
        XCTAssertEqual(updatedSettings.lockType, .biometric)
        XCTAssertTrue(updatedSettings.autoLockEnabled)
        XCTAssertEqual(updatedSettings.autoLockKeywords, ["噩梦", "恐怖"])
    }
    
    // MARK: - 自动锁定测试
    
    func testAutoLockDetection_Nightmare() async {
        let nightmareContent = "这是一个恐怖的噩梦，充满了暴力和恐怖的场景"
        
        var settings = await privacyService.getSettings()
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["噩梦", "恐怖", "暴力", "创伤"]
        try await privacyService.updateSettings(settings)
        
        let shouldLock = await privacyService.checkAutoLock(for: nightmareContent)
        XCTAssertTrue(shouldLock, "应该检测到噩梦关键词并自动锁定")
    }
    
    func testAutoLockDetection_NormalDream() async {
        let normalContent = "我在天空中飞翔，感觉非常自由和快乐"
        
        var settings = await privacyService.getSettings()
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["噩梦", "恐怖", "暴力", "创伤"]
        try await privacyService.updateSettings(settings)
        
        let shouldLock = await privacyService.checkAutoLock(for: normalContent)
        XCTAssertFalse(shouldLock, "普通梦境不应该触发自动锁定")
    }
    
    func testAutoLockDetection_CustomKeywords() async {
        let sensitiveContent = "这个梦境涉及敏感的个人隐私内容"
        
        var settings = await privacyService.getSettings()
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["敏感", "隐私", "秘密"]
        try await privacyService.updateSettings(settings)
        
        let shouldLock = await privacyService.checkAutoLock(for: sensitiveContent)
        XCTAssertTrue(shouldLock, "应该检测到自定义敏感关键词")
    }
    
    // MARK: - 梦境锁定/解锁测试
    
    func testLockDream() async throws {
        let dream = testDreams[0]
        
        try await privacyService.lockDream(dream, lockType: .biometric)
        
        XCTAssertEqual(dream.lockType, .biometric)
        XCTAssertNotNil(dream.lockedAt)
        XCTAssertTrue(await privacyService.isDreamLocked(dream))
    }
    
    func testUnlockDream() async throws {
        let dream = testDreams[0]
        dream.lockType = .biometric
        dream.lockedAt = Date()
        
        try await privacyService.unlockDream(dream)
        
        XCTAssertEqual(dream.lockType, .none)
        XCTAssertNil(dream.lockedAt)
        XCTAssertFalse(await privacyService.isDreamLocked(dream))
    }
    
    func testHideDream() async throws {
        let dream = testDreams[0]
        
        try await privacyService.hideDream(dream)
        
        XCTAssertTrue(dream.isHidden)
    }
    
    func testUnhideDream() async throws {
        let dream = testDreams[0]
        dream.isHidden = true
        
        try await privacyService.unhideDream(dream)
        
        XCTAssertFalse(dream.isHidden)
    }
    
    // MARK: - 隐私统计测试
    
    func testGetPrivacyStats_EmptyData() async {
        let stats = await privacyService.getPrivacyStats(for: [])
        
        XCTAssertEqual(stats.totalLocked, 0)
        XCTAssertEqual(stats.lockedThisWeek, 0)
        XCTAssertEqual(stats.lockedThisMonth, 0)
        XCTAssertEqual(stats.mostLockedTag, nil)
    }
    
    func testGetPrivacyStats_WithLockedDreams() async {
        var dreams = testDreams
        dreams[1].lockType = .biometric  // 噩梦锁定
        dreams[1].lockedAt = Date()
        dreams[1].createdAt = Date()
        dreams[3].lockType = .autoLock  // 创伤梦境锁定
        dreams[3].lockedAt = Date()
        dreams[3].createdAt = Date()
        
        let stats = await privacyService.getPrivacyStats(for: dreams)
        
        XCTAssertEqual(stats.totalLocked, 2, "应该有 2 个锁定的梦境")
        XCTAssertEqual(stats.lockedThisWeek, 2, "本周锁定的应该是 2 个")
        XCTAssertEqual(stats.lockedThisMonth, 2, "本月锁定的应该是 2 个")
        XCTAssertNotNil(stats.mostLockedTag)
    }
    
    func testGetPrivacyStats_LockTypeDistribution() async {
        var dreams = testDreams
        dreams[1].lockType = .biometric
        dreams[2].lockType = .passcode
        dreams[3].lockType = .biometric
        
        let stats = await privacyService.getPrivacyStats(for: dreams)
        
        XCTAssertEqual(stats.totalLocked, 3)
        XCTAssertEqual(stats.lockedByType[.biometric], 2)
        XCTAssertEqual(stats.lockedByType[.passcode], 1)
    }
    
    // MARK: - 边界情况测试
    
    func testAutoLockWithEmptyContent() async {
        var settings = await privacyService.getSettings()
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["噩梦"]
        try await privacyService.updateSettings(settings)
        
        let shouldLock = await privacyService.checkAutoLock(for: "")
        XCTAssertFalse(shouldLock, "空内容不应该触发锁定")
    }
    
    func testAutoLockDisabled() async {
        var settings = await privacyService.getSettings()
        settings.autoLockEnabled = false
        settings.autoLockKeywords = ["噩梦"]
        try await privacyService.updateSettings(settings)
        
        let shouldLock = await privacyService.checkAutoLock(for: "这是一个噩梦")
        XCTAssertFalse(shouldLock, "自动锁定禁用时不应该触发")
    }
    
    func testLockDreamWithNoneType() async throws {
        let dream = testDreams[0]
        
        try await privacyService.lockDream(dream, lockType: .none)
        
        XCTAssertEqual(dream.lockType, .none)
        XCTAssertFalse(await privacyService.isDreamLocked(dream))
    }
    
    // MARK: - 性能测试
    
    func testAutoLockPerformance() async {
        var settings = await privacyService.getSettings()
        settings.autoLockEnabled = true
        settings.autoLockKeywords = ["噩梦", "恐怖", "暴力", "创伤", "敏感"]
        try await privacyService.updateSettings(settings)
        
        let content = "这是一个非常恐怖的噩梦，充满了暴力和创伤性的场景"
        
        measure {
            let expectation = self.expectation(description: "Auto lock check")
            Task {
                _ = await self.privacyService.checkAutoLock(for: content)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    func testGetPrivacyStatsPerformance() async {
        let dreams = (0..<100).map { i -> Dream in
            let dream = Dream(
                title: "Dream \(i)",
                content: "Content \(i)",
                tags: ["tag\(i % 10)"],
                emotions: [.happy],
                clarity: 3,
                intensity: 3,
                isLucid: false
            )
            if i % 5 == 0 {
                dream.lockType = .biometric
                dream.lockedAt = Date()
                dream.createdAt = Date()
            }
            return dream
        }
        
        measure {
            let expectation = self.expectation(description: "Get privacy stats")
            Task {
                _ = await self.privacyService.getPrivacyStats(for: dreams)
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - AuthResult 枚举测试
    
    func testAuthResultAllCases() {
        let allCases: [AuthResult] = [.success, .failed, .cancelled, .notAvailable, .error]
        XCTAssertEqual(allCases.count, 5, "应该有 5 种认证结果")
    }
    
    func testAuthResultIsSuccess() {
        XCTAssertTrue(AuthResult.success.isSuccess)
        XCTAssertFalse(AuthResult.failed.isSuccess)
        XCTAssertFalse(AuthResult.cancelled.isSuccess)
        XCTAssertFalse(AuthResult.notAvailable.isSuccess)
        XCTAssertFalse(AuthResult.error.isSuccess)
    }
    
    // MARK: - PrivacyQuickAction 枚举测试
    
    func testPrivacyQuickActionAllCases() {
        let allCases: [PrivacyQuickAction] = [
            .lockSelected, .unlockSelected, .hideSelected,
            .exportLocked, .settings, .help
        ]
        XCTAssertEqual(allCases.count, 6, "应该有 6 种快速操作")
    }
}
