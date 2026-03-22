//
//  DreamPrivacyTests.swift
//  DreamLog - Phase 92: Privacy & Security Suite Tests
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import CryptoKit
@testable import DreamLog

// MARK: - Biometric Lock Tests

final class DreamBiometricLockTests: XCTestCase {
    
    var lockService: DreamBiometricLockService!
    
    override func setUp() async throws {
        lockService = DreamBiometricLockService.shared
    }
    
    override func tearDown() async throws {
        // 重置状态
        lockService.authenticationState = .locked
    }
    
    /// 测试生物识别可用性检测
    func testBiometricAvailability() {
        // 注意：在模拟器上可能不可用
        let isAvailable = lockService.isBiometricAvailable
        XCTAssertNotNil(lockService.biometricType)
        XCTAssertNotNil(lockService.biometricTypeName)
    }
    
    /// 测试锁定超时配置
    func testLockTimeoutConfiguration() {
        let timeouts: [LockTimeout] = [.immediate, .after1Minute, .after5Minutes, .after15Minutes, .after1Hour]
        
        for timeout in timeouts {
            XCTAssertGreaterThanOrEqual(timeout.seconds, 0)
            XCTAssertFalse(timeout.displayName.isEmpty)
        }
        
        XCTAssertEqual(LockTimeout.immediate.seconds, 0)
        XCTAssertEqual(LockTimeout.after1Minute.seconds, 60)
        XCTAssertEqual(LockTimeout.after5Minutes.seconds, 300)
    }
    
    /// 测试认证状态
    func testAuthenticationState() {
        let locked = AuthenticationState.locked
        let unlocked = AuthenticationState.unlocked
        let authenticating = AuthenticationState.authenticating
        let error = AuthenticationState.error("Test error")
        
        XCTAssertFalse(locked.isUnlocked)
        XCTAssertTrue(unlocked.isUnlocked)
        XCTAssertFalse(authenticating.isUnlocked)
        XCTAssertFalse(error.isUnlocked)
    }
}

// MARK: - Encryption Service Tests

final class DreamEncryptionTests: XCTestCase {
    
    var encryptionService: DreamEncryptionService!
    
    override func setUp() async throws {
        encryptionService = DreamEncryptionService.shared
    }
    
    /// 测试加密和解密流程
    func testEncryptDecryptCycle() throws {
        let originalTitle = "测试梦境"
        let originalContent = "这是一个测试梦境内容，包含一些敏感信息。"
        
        // 加密
        let encryptedData = try encryptionService.encryptDreamContent(
            originalContent,
            title: originalTitle
        )
        
        // 验证加密数据不为空
        XCTAssertFalse(encryptedData.ciphertext.isEmpty)
        XCTAssertFalse(encryptedData.nonce.isEmpty)
        XCTAssertFalse(encryptedData.tag.isEmpty)
        XCTAssertEqual(encryptedData.version, 1)
        
        // 解密
        let decrypted = try encryptionService.decryptDreamContent(encryptedData)
        
        // 验证解密后的内容
        XCTAssertEqual(decrypted.title, originalTitle)
        XCTAssertEqual(decrypted.content, originalContent)
    }
    
    /// 测试加密标题
    func testEncryptTitle() throws {
        let originalTitle = "秘密梦境"
        
        let encryptedTitle = try encryptionService.encryptTitle(originalTitle)
        XCTAssertFalse(encryptedTitle.isEmpty)
        
        // 每次加密应该产生不同的结果 (因为使用随机 nonce)
        let encryptedTitle2 = try encryptionService.encryptTitle(originalTitle)
        XCTAssertNotEqual(encryptedTitle, encryptedTitle2)
    }
    
    /// 测试解密错误处理
    func testDecryptionErrorHandling() {
        let invalidData = EncryptedData(
            ciphertext: Data(),
            nonce: Data(),
            tag: Data(),
            version: 1
        )
        
        XCTAssertThrowsError(try encryptionService.decryptDreamContent(invalidData)) { error in
            XCTAssertEqual(error as? EncryptionError, EncryptionError.decryptionFailed)
        }
    }
    
    /// 测试大数据加密
    func testLargeDataEncryption() throws {
        let largeContent = String(repeating: "这是一个很长的梦境内容。", count: 1000)
        
        let encrypted = try encryptionService.encryptDreamContent(largeContent)
        let decrypted = try encryptionService.decryptDreamContent(encrypted)
        
        XCTAssertEqual(decrypted.content, largeContent)
    }
}

// MARK: - Privacy Models Tests

final class DreamPrivacyModelsTests: XCTestCase {
    
    /// 测试隐私级别
    func testPrivacyLevel() {
        let levels: [PrivacyLevel] = [.normal, .private, .hidden]
        
        for level in levels {
            XCTAssertFalse(level.displayName.isEmpty)
            XCTAssertFalse(level.description.isEmpty)
            XCTAssertFalse(level.iconName.isEmpty)
        }
        
        XCTAssertEqual(PrivacyLevel.normal.rawValue, 0)
        XCTAssertEqual(PrivacyLevel.private.rawValue, 1)
        XCTAssertEqual(PrivacyLevel.hidden.rawValue, 2)
    }
    
    /// 测试生物识别配置模型
    func testBiometricConfigModel() {
        let config = BiometricConfig(
            isEnabled: true,
            lockTimeout: .after5Minutes,
            requireOnLaunch: true,
            requireOnBackground: true,
            fallbackToPasscode: true
        )
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.lockTimeout, .after5Minutes)
        XCTAssertNotNil(config.id)
        XCTAssertNotNil(config.createdAt)
        XCTAssertNotNil(config.updatedAt)
    }
    
    /// 测试回收站项目模型
    func testDreamTrashItemModel() {
        let dreamId = UUID()
        let trashItem = DreamTrashItem(
            dreamId: dreamId,
            dreamTitle: "测试梦境",
            dreamContent: "测试内容",
            dreamData: Data("测试数据".utf8),
            retentionDays: 30
        )
        
        XCTAssertEqual(trashItem.dreamId, dreamId)
        XCTAssertEqual(trashItem.dreamTitle, "测试梦境")
        XCTAssertEqual(trashItem.retentionDays, 30)
        XCTAssertGreaterThanOrEqual(trashItem.daysUntilDeletion, 0)
        XCTAssertLessThanOrEqual(trashItem.daysUntilDeletion, 30)
        XCTAssertFalse(trashItem.isRecovered)
        XCTAssertNil(trashItem.recoveryDate)
    }
    
    /// 测试隐私设置模型
    func testPrivacySettingsModel() {
        let settings = PrivacySettings(
            hideNotificationContent: true,
            hideWidgetContent: true,
            hideLockScreenPreview: true,
            showOnlyGenericNotifications: true,
            blurAppInSwitcher: false,
            preventScreenshots: false
        )
        
        XCTAssertTrue(settings.hideNotificationContent)
        XCTAssertTrue(settings.hideWidgetContent)
        XCTAssertTrue(settings.hideLockScreenPreview)
        XCTAssertFalse(settings.blurAppInSwitcher)
    }
    
    /// 测试安全备份配置模型
    func testSecureBackupConfigModel() {
        let config = SecureBackupConfig(
            isEnabled: true,
            encryptionEnabled: true,
            backupLocation: "iCloud",
            autoBackupEnabled: true,
            autoBackupFrequency: .weekly,
            verifyBackupAfterCreation: true
        )
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertTrue(config.encryptionEnabled)
        XCTAssertEqual(config.backupLocation, "iCloud")
        XCTAssertEqual(config.autoBackupFrequency, .weekly)
    }
    
    /// 测试备份频率枚举
    func testBackupFrequency() {
        let frequencies: [BackupFrequency] = [.daily, .weekly, .monthly]
        
        for frequency in frequencies {
            XCTAssertFalse(frequency.displayName.isEmpty)
        }
    }
}

// MARK: - Trash Service Tests

final class DreamTrashServiceTests: XCTestCase {
    
    var trashService: DreamTrashService!
    
    override func setUp() async throws {
        trashService = DreamTrashService.shared
    }
    
    /// 测试回收站统计
    func testTrashStats() {
        let stats = TrashStats(
            totalCount: 10,
            totalSize: 1024 * 1024, // 1 MB
            expiringSoonCount: 3,
            oldestDeletionDate: Date().addingTimeInterval(-86400 * 5)
        )
        
        XCTAssertEqual(stats.totalCount, 10)
        XCTAssertEqual(stats.expiringSoonCount, 3)
        XCTAssertFalse(stats.totalSizeFormatted.isEmpty)
        XCTAssertTrue(stats.totalSizeFormatted.contains("MB"))
    }
    
    /// 测试回收站错误
    func testTrashError() {
        let errors: [TrashError] = [
            .contextNotFound,
            .itemNotFound,
            .dreamNotFound,
            .recoveryFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - Backup Service Tests

final class DreamBackupServiceTests: XCTestCase {
    
    var backupService: DreamSecureBackupService!
    
    override func setUp() async throws {
        backupService = DreamSecureBackupService.shared
    }
    
    /// 测试备份结果
    func testBackupResult() {
        let url = URL(fileURLWithPath: "/tmp/test.dlbackup")
        let result = BackupResult(
            success: true,
            backupURL: url,
            dreamCount: 100,
            size: 10 * 1024 * 1024, // 10 MB
            createdAt: Date()
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.dreamCount, 100)
        XCTAssertFalse(result.sizeFormatted.isEmpty)
        XCTAssertTrue(result.sizeFormatted.contains("MB"))
    }
    
    /// 测试恢复结果
    func testRestoreResult() {
        let result = RestoreResult(
            success: true,
            restoredCount: 95,
            failedCount: 5
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.restoredCount, 95)
        XCTAssertEqual(result.failedCount, 5)
    }
    
    /// 测试备份信息
    func testBackupInfo() {
        let url = URL(fileURLWithPath: "/tmp/test.dlbackup")
        let info = BackupInfo(
            url: url,
            date: Date(),
            size: 5 * 1024 * 1024 // 5 MB
        )
        
        XCTAssertFalse(info.sizeFormatted.isEmpty)
        XCTAssertTrue(info.sizeFormatted.contains("MB"))
    }
    
    /// 测试备份错误
    func testBackupError() {
        let errors: [BackupError] = [
            .contextNotFound,
            .alreadyBackingUp,
            .keyNotFound,
            .keychainError,
            .invalidPassword,
            .invalidBackupURL,
            .backupNotFound,
            .restoreFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
}

// MARK: - Privacy Notification Tests

final class DreamPrivacyNotificationTests: XCTestCase {
    
    var notificationService: DreamPrivacyNotificationService!
    
    override func setUp() async throws {
        notificationService = DreamPrivacyNotificationService.shared
    }
    
    /// 测试隐私模式开关
    func testPrivacyModeToggle() async {
        // 测试隐私模式启用
        await notificationService.configurePrivacyMode(enabled: true)
        // 注意：实际测试需要 mock 通知中心
        
        // 测试隐私模式禁用
        await notificationService.configurePrivacyMode(enabled: false)
    }
    
    /// 测试文本截断
    func testTextTruncation() {
        let longTitle = String(repeating: "A", count: 50)
        let truncated = notificationService.getWidgetDreamTitle(longTitle)
        
        XCTAssertLessThanOrEqual(truncated.count, 33) // 30 + "..."
    }
}

// MARK: - Integration Tests

final class DreamPrivacyIntegrationTests: XCTestCase {
    
    /// 测试完整的隐私保护流程
    func testCompletePrivacyWorkflow() async throws {
        // 1. 配置生物识别锁
        let lockService = DreamBiometricLockService.shared
        XCTAssertNotNil(lockService.biometricTypeName)
        
        // 2. 加密梦境内容
        let encryptionService = DreamEncryptionService.shared
        let encrypted = try encryptionService.encryptDreamContent(
            "私密梦境内容",
            title: "私密梦境"
        )
        XCTAssertFalse(encrypted.ciphertext.isEmpty)
        
        // 3. 验证隐私级别
        XCTAssertEqual(PrivacyLevel.private.displayName, "私密")
        XCTAssertEqual(PrivacyLevel.hidden.displayName, "隐藏")
        
        // 4. 测试回收站统计
        let stats = TrashStats(
            totalCount: 5,
            totalSize: 1024,
            expiringSoonCount: 2,
            oldestDeletionDate: Date()
        )
        XCTAssertEqual(stats.totalCount, 5)
    }
}
