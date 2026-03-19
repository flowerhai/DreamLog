//
//  DreamPrivacyTests.swift
//  DreamLog - Privacy Mode Unit Tests
//
//  Phase 70: Dream Privacy Mode with Biometric Lock
//  Created: 2026-03-19
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamPrivacyTests: XCTestCase {
    
    var modelContext: ModelContext!
    var privacyService: DreamPrivacyService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let container = try ModelContainer(
            for: DreamPrivacySettings.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        modelContext = ModelContext(container)
        privacyService = DreamPrivacyService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        privacyService = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Privacy Settings Tests
    
    /// 测试获取隐私设置 - 首次创建
    func testGetPrivacySettings_FirstTime() async throws {
        let settings = try await privacyService.getPrivacySettings()
        
        XCTAssertNotNil(settings)
        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.defaultLockType, .biometric)
        XCTAssertTrue(settings.hideLockedFromWidgets)
        XCTAssertTrue(settings.hideLockedFromNotifications)
        XCTAssertFalse(settings.hideLockedFromStats)
        XCTAssertFalse(settings.autoLockEnabled)
        XCTAssertTrue(settings.autoLockKeywords.isEmpty)
        XCTAssertFalse(settings.requireAuthOnAppLaunch)
        XCTAssertEqual(settings.requireAuthAfterSeconds, 300)
    }
    
    /// 测试获取隐私设置 - 已存在
    func testGetPrivacySettings_Existing() async throws {
        // 先创建设置
        let originalSettings = DreamPrivacySettings(isEnabled: true)
        modelContext.insert(originalSettings)
        try modelContext.save()
        
        // 获取设置
        let settings = try await privacyService.getPrivacySettings()
        
        XCTAssertEqual(settings.id, originalSettings.id)
        XCTAssertTrue(settings.isEnabled)
    }
    
    /// 测试更新隐私设置
    func testUpdatePrivacySettings() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            hideLockedFromWidgets: false,
            autoLockEnabled: true,
            autoLockKeywords: ["隐私", "秘密"],
            requireAuthOnAppLaunch: true,
            requireAuthAfterSeconds: 600
        )
        
        XCTAssertTrue(settings.isEnabled)
        XCTAssertFalse(settings.hideLockedFromWidgets)
        XCTAssertTrue(settings.autoLockEnabled)
        XCTAssertEqual(settings.autoLockKeywords, ["隐私", "秘密"])
        XCTAssertTrue(settings.requireAuthOnAppLaunch)
        XCTAssertEqual(settings.requireAuthAfterSeconds, 600)
    }
    
    /// 测试部分更新隐私设置
    func testUpdatePrivacySettings_Partial() async throws {
        // 先创建完整设置
        let originalSettings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            hideLockedFromWidgets: true
        )
        
        // 部分更新
        let updatedSettings = try await privacyService.updatePrivacySettings(
            hideLockedFromWidgets: false
        )
        
        // 验证未更新的字段保持不变
        XCTAssertTrue(updatedSettings.isEnabled)
        XCTAssertFalse(updatedSettings.hideLockedFromWidgets)
    }
    
    // MARK: - Authentication Tests
    
    /// 测试记录认证成功
    func testRecordAuthSuccess() async throws {
        // 先模拟失败
        try await privacyService.recordAuthFailure()
        try await privacyService.recordAuthFailure()
        
        // 记录成功
        try await privacyService.recordAuthSuccess()
        
        let settings = try await privacyService.getPrivacySettings()
        XCTAssertEqual(settings.failedAuthAttempts, 0)
        XCTAssertNotNil(settings.lastAuthTime)
        XCTAssertFalse(settings.isLocked)
    }
    
    /// 测试记录认证失败
    func testRecordAuthFailure() async throws {
        var failCount = try await privacyService.recordAuthFailure()
        XCTAssertEqual(failCount, 1)
        
        failCount = try await privacyService.recordAuthFailure()
        XCTAssertEqual(failCount, 2)
        
        failCount = try await privacyService.recordAuthFailure()
        XCTAssertEqual(failCount, 3)
    }
    
    /// 测试重置失败计数
    func testResetFailedAttempts() async throws {
        // 先记录失败
        try await privacyService.recordAuthFailure()
        try await privacyService.recordAuthFailure()
        
        // 重置
        try await privacyService.resetFailedAttempts()
        
        let settings = try await privacyService.getPrivacySettings()
        XCTAssertEqual(settings.failedAuthAttempts, 0)
    }
    
    // MARK: - Auto Lock Tests
    
    /// 测试自动锁定 - 关键词匹配
    func testShouldAutoLock_KeywordMatch() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            autoLockEnabled: true,
            autoLockKeywords: ["隐私", "秘密", "工作"]
        )
        
        XCTAssertTrue(settings.shouldAutoLock(content: "这是一个隐私的梦境", title: "梦"))
        XCTAssertTrue(settings.shouldAutoLock(content: "普通内容", title: "秘密计划"))
        XCTAssertFalse(settings.shouldAutoLock(content: "普通梦境", title: "美梦"))
    }
    
    /// 测试自动锁定 - 大小写不敏感
    func testShouldAutoLock_CaseInsensitive() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            autoLockEnabled: true,
            autoLockKeywords: ["隐私"]
        )
        
        XCTAssertTrue(settings.shouldAutoLock(content: "这是隐私内容", title: ""))
        XCTAssertTrue(settings.shouldAutoLock(content: "这是隱私內容", title: "")) // 繁体
    }
    
    /// 测试自动锁定 - 未启用时不锁定
    func testShouldAutoLock_NotEnabled() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: false,
            autoLockEnabled: true,
            autoLockKeywords: ["隐私"]
        )
        
        XCTAssertFalse(settings.shouldAutoLock(content: "这是隐私内容", title: ""))
    }
    
    // MARK: - Reauthentication Tests
    
    /// 测试需要重新认证 - 首次启动
    func testNeedsReauthentication_FirstLaunch() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            requireAuthOnAppLaunch: true,
            lastAuthTime: nil
        )
        
        XCTAssertTrue(settings.needsReauthentication())
    }
    
    /// 测试需要重新认证 - 已认证且在时间内
    func testNeedsReauthentication_WithinTime() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            requireAuthOnAppLaunch: true,
            lastAuthTime: Date(),
            requireAuthAfterSeconds: 300
        )
        
        XCTAssertFalse(settings.needsReauthentication())
    }
    
    /// 测试需要重新认证 - 已超时
    func testNeedsReauthentication_Timeout() async throws {
        let pastDate = Date().addingTimeInterval(-600) // 10 分钟前
        
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: true,
            requireAuthOnAppLaunch: true,
            lastAuthTime: pastDate,
            requireAuthAfterSeconds: 300
        )
        
        XCTAssertTrue(settings.needsReauthentication())
    }
    
    /// 测试需要重新认证 - 隐私模式未启用
    func testNeedsReauthentication_PrivacyDisabled() async throws {
        let settings = try await privacyService.updatePrivacySettings(
            isEnabled: false,
            requireAuthOnAppLaunch: true,
            lastAuthTime: nil
        )
        
        XCTAssertFalse(settings.needsReauthentication())
    }
    
    // MARK: - Lock Type Tests
    
    /// 测试锁定类型枚举
    func testDreamLockType_DisplayNames() {
        XCTAssertEqual(DreamLockType.none.displayName, "无")
        XCTAssertEqual(DreamLockType.biometric.displayName, "生物识别")
        XCTAssertEqual(DreamLockType.passcode.displayName, "密码")
        XCTAssertEqual(DreamLockType.hidden.displayName, "隐藏")
    }
    
    /// 测试锁定类型图标
    func testDreamLockType_Icons() {
        XCTAssertEqual(DreamLockType.none.icon, "lock.open")
        XCTAssertEqual(DreamLockType.biometric.icon, "faceid")
        XCTAssertEqual(DreamLockType.passcode.icon, "lock.fill")
        XCTAssertEqual(DreamLockType.hidden.icon, "eye.slash")
    }
    
    // MARK: - Quick Action Tests
    
    /// 测试快速操作枚举
    func testPrivacyQuickAction_DisplayNames() {
        XCTAssertEqual(PrivacyQuickAction.lock.displayName, "锁定")
        XCTAssertEqual(PrivacyQuickAction.unlock.displayName, "解锁")
        XCTAssertEqual(PrivacyQuickAction.hide.displayName, "隐藏")
        XCTAssertEqual(PrivacyQuickAction.unhide.displayName, "取消隐藏")
    }
    
    /// 测试快速操作图标
    func testPrivacyQuickAction_Icons() {
        XCTAssertEqual(PrivacyQuickAction.lock.icon, "lock.fill")
        XCTAssertEqual(PrivacyQuickAction.unlock.icon, "lock.open.fill")
        XCTAssertEqual(PrivacyQuickAction.hide.icon, "eye.slash.fill")
        XCTAssertEqual(PrivacyQuickAction.unhide.icon, "eye.fill")
    }
    
    // MARK: - Privacy Stats Tests
    
    /// 测试隐私统计结构
    func testDreamPrivacyStats_Init() {
        let stats = DreamPrivacyStats(
            totalLockedDreams: 10,
            lockedByType: [.biometric: 8, .passcode: 2],
            lockedThisWeek: 3,
            lockedThisMonth: 7,
            mostLockedTag: "工作",
            authSuccessCount: 50,
            authFailCount: 2
        )
        
        XCTAssertEqual(stats.totalLockedDreams, 10)
        XCTAssertEqual(stats.lockedByType[.biometric], 8)
        XCTAssertEqual(stats.lockedByType[.passcode], 2)
        XCTAssertEqual(stats.lockedThisWeek, 3)
        XCTAssertEqual(stats.lockedThisMonth, 7)
        XCTAssertEqual(stats.mostLockedTag, "工作")
        XCTAssertEqual(stats.authSuccessCount, 50)
        XCTAssertEqual(stats.authFailCount, 2)
    }
    
    /// 测试隐私统计默认值
    func testDreamPrivacyStats_Default() {
        let stats = DreamPrivacyStats()
        
        XCTAssertEqual(stats.totalLockedDreams, 0)
        XCTAssertTrue(stats.lockedByType.isEmpty)
        XCTAssertEqual(stats.lockedThisWeek, 0)
        XCTAssertEqual(stats.lockedThisMonth, 0)
        XCTAssertNil(stats.mostLockedTag)
        XCTAssertEqual(stats.authSuccessCount, 0)
        XCTAssertEqual(stats.authFailCount, 0)
    }
    
    // MARK: - Auth Result Tests
    
    /// 测试认证结果
    func testAuthResult_IsSuccess() {
        XCTAssertTrue(AuthResult.success.isSuccess)
        XCTAssertFalse(AuthResult.failure(reason: "test").isSuccess)
        XCTAssertFalse(AuthResult.userFallback.isSuccess)
        XCTAssertFalse(AuthResult.userCancel.isSuccess)
        XCTAssertFalse(AuthResult.systemError.isSuccess)
    }
    
    // MARK: - Emergency Lockout Tests
    
    /// 测试紧急锁定 - 未达到阈值
    func testNeedsEmergencyLockout_BelowThreshold() async throws {
        try await privacyService.recordAuthFailure()
        try await privacyService.recordAuthFailure()
        try await privacyService.recordAuthFailure()
        
        let needsLockout = try await privacyService.needsEmergencyLockout()
        XCTAssertFalse(needsLockout)
    }
    
    /// 测试紧急锁定 - 达到阈值
    func testNeedsEmergencyLockout_AtThreshold() async throws {
        for _ in 0..<5 {
            try await privacyService.recordAuthFailure()
        }
        
        let needsLockout = try await privacyService.needsEmergencyLockout()
        XCTAssertTrue(needsLockout)
    }
    
    /// 测试清除认证数据
    func testClearAuthData() async throws {
        // 先设置一些数据
        try await privacyService.recordAuthSuccess()
        try await privacyService.recordAuthFailure()
        try await privacyService.recordAuthFailure()
        
        // 清除
        try await privacyService.clearAuthData()
        
        let settings = try await privacyService.getPrivacySettings()
        XCTAssertNil(settings.lastAuthTime)
        XCTAssertEqual(settings.failedAuthAttempts, 0)
        XCTAssertTrue(settings.isLocked)
    }
    
    // MARK: - Performance Tests
    
    /// 测试获取设置性能
    func testGetPrivacySettings_Performance() async throws {
        self.measure {
            let expectation = self.expectation(description: "Get settings")
            
            Task {
                _ = try? await self.privacyService.getPrivacySettings()
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
        }
    }
    
    /// 测试更新设置性能
    func testUpdatePrivacySettings_Performance() async throws {
        self.measure {
            let expectation = self.expectation(description: "Update settings")
            
            Task {
                _ = try? await self.privacyService.updatePrivacySettings(isEnabled: true)
                expectation.fulfill()
            }
            
            self.wait(for: [expectation], timeout: 5.0)
        }
    }
}
