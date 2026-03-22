//
//  DreamBiometricModels.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import LocalAuthentication
import SwiftData

// MARK: - Biometric Configuration

/// 生物识别配置模型
@Model
final class BiometricConfig {
    var id: UUID
    var isEnabled: Bool
    var lockTimeout: LockTimeout
    var requireOnLaunch: Bool
    var requireOnBackground: Bool
    var fallbackToPasscode: Bool
    var lastAuthDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        isEnabled: Bool = false,
        lockTimeout: LockTimeout = .immediate,
        requireOnLaunch: Bool = true,
        requireOnBackground: Bool = true,
        fallbackToPasscode: Bool = true
    ) {
        self.id = UUID()
        self.isEnabled = isEnabled
        self.lockTimeout = lockTimeout
        self.requireOnLaunch = requireOnLaunch
        self.requireOnBackground = requireOnBackground
        self.fallbackToPasscode = fallbackToPasscode
        self.lastAuthDate = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Lock Timeout

/// 锁定超时设置
enum LockTimeout: String, Codable, CaseIterable {
    case immediate = "immediate"
    case after1Minute = "after1Minute"
    case after5Minutes = "after5Minutes"
    case after15Minutes = "after15Minutes"
    case after1Hour = "after1Hour"
    
    var displayName: String {
        switch self {
        case .immediate: return "立即"
        case .after1Minute: return "1 分钟后"
        case .after5Minutes: return "5 分钟后"
        case .after15Minutes: return "15 分钟后"
        case .after1Hour: return "1 小时后"
        }
    }
    
    var seconds: TimeInterval {
        switch self {
        case .immediate: return 0
        case .after1Minute: return 60
        case .after5Minutes: return 300
        case .after15Minutes: return 900
        case .after1Hour: return 3600
        }
    }
}

// MARK: - Authentication State

/// 认证状态
enum AuthenticationState: Equatable {
    case locked
    case unlocked
    case authenticating
    case error(String)
    
    var isUnlocked: Bool {
        if case .unlocked = self { return true }
        return false
    }
}

// MARK: - Privacy Level

/// 隐私级别
enum PrivacyLevel: Int, Codable, CaseIterable {
    case normal = 0
    case private = 1
    case hidden = 2
    
    var displayName: String {
        switch self {
        case .normal: return "普通"
        case .private: return "私密"
        case .hidden: return "隐藏"
        }
    }
    
    var description: String {
        switch self {
        case .normal: return "所有人可见"
        case .private: return "需要验证查看"
        case .hidden: return "仅在隐藏列表中显示"
        }
    }
    
    var iconName: String {
        switch self {
        case .normal: return "eye"
        case .private: return "eye.slash"
        case .hidden: return "lock.shield"
        }
    }
}

// MARK: - Lock Settings

/// 应用锁设置
@Model
final class LockSettings {
    var id: UUID
    var isAppLockEnabled: Bool
    var biometricType: LABiometryType
    var passcodeHash: String?
    var maxFailedAttempts: Int
    var wipeAfterFailedAttempts: Bool
    var showFailedAttemptsWarning: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        isAppLockEnabled: Bool = false,
        biometricType: LABiometryType = .none,
        passcodeHash: String? = nil,
        maxFailedAttempts: Int = 5,
        wipeAfterFailedAttempts: Bool = false,
        showFailedAttemptsWarning: Bool = true
    ) {
        self.id = UUID()
        self.isAppLockEnabled = isAppLockEnabled
        self.biometricType = biometricType
        self.passcodeHash = passcodeHash
        self.maxFailedAttempts = maxFailedAttempts
        self.wipeAfterFailedAttempts = wipeAfterFailedAttempts
        self.showFailedAttemptsWarning = showFailedAttemptsWarning
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Encrypted Dream Metadata

/// 加密梦境元数据 (不加密内容，只加密敏感信息)
@Model
final class EncryptedDreamMetadata {
    var id: UUID
    var dreamId: UUID
    var privacyLevel: Int
    var encryptedTitle: Data?
    var encryptedContent: Data?
    var encryptionVersion: Int
    var iv: Data?
    var isEncrypted: Bool
    var lastAccessDate: Date?
    var accessCount: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        dreamId: UUID,
        privacyLevel: Int = PrivacyLevel.normal.rawValue,
        isEncrypted: Bool = false
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.privacyLevel = privacyLevel
        self.encryptedTitle = nil
        self.encryptedContent = nil
        self.encryptionVersion = 1
        self.iv = nil
        self.isEncrypted = isEncrypted
        self.lastAccessDate = nil
        self.accessCount = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Dream Trash Item

/// 梦境回收站项目
@Model
final class DreamTrashItem {
    var id: UUID
    var dreamId: UUID
    var dreamTitle: String
    var dreamContent: String
    var dreamData: Data
    var deletedDate: Date
    var willBePermanentlyDeletedOn: Date
    var isRecovered: Bool
    var recoveryDate: Date?
    
    init(
        dreamId: UUID,
        dreamTitle: String,
        dreamContent: String,
        dreamData: Data,
        retentionDays: Int = 30
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.dreamTitle = dreamTitle
        self.dreamContent = dreamContent
        self.dreamData = dreamData
        self.deletedDate = Date()
        self.willBePermanentlyDeletedOn = Calendar.current.date(byAdding: .day, value: retentionDays, to: self.deletedDate) ?? Date()
        self.isRecovered = false
        self.recoveryDate = nil
    }
    
    var daysUntilDeletion: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: willBePermanentlyDeletedOn)
        return components.day ?? 0
    }
    
    var isExpired: Bool {
        Date() > willBePermanentlyDeletedOn
    }
}

// MARK: - Privacy Settings

/// 隐私设置
@Model
final class PrivacySettings {
    var id: UUID
    var hideNotificationContent: Bool
    var hideWidgetContent: Bool
    var hideLockScreenPreview: Bool
    var showOnlyGenericNotifications: Bool
    var blurAppInSwitcher: Bool
    var preventScreenshots: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        hideNotificationContent: Bool = false,
        hideWidgetContent: Bool = false,
        hideLockScreenPreview: Bool = true,
        showOnlyGenericNotifications: Bool = false,
        blurAppInSwitcher: Bool = false,
        preventScreenshots: Bool = false
    ) {
        self.id = UUID()
        self.hideNotificationContent = hideNotificationContent
        self.hideWidgetContent = hideWidgetContent
        self.hideLockScreenPreview = hideLockScreenPreview
        self.showOnlyGenericNotifications = showOnlyGenericNotifications
        self.blurAppInSwitcher = blurAppInSwitcher
        self.preventScreenshots = preventScreenshots
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Secure Backup Config

/// 安全备份配置
@Model
final class SecureBackupConfig {
    var id: UUID
    var isEnabled: Bool
    var encryptionEnabled: Bool
    var backupPassword: String?
    var lastBackupDate: Date?
    var lastBackupSize: Int64
    var backupLocation: String
    var autoBackupEnabled: Bool
    var autoBackupFrequency: BackupFrequency
    var verifyBackupAfterCreation: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        isEnabled: Bool = false,
        encryptionEnabled: Bool = true,
        backupLocation: String = "iCloud",
        autoBackupEnabled: Bool = true,
        autoBackupFrequency: BackupFrequency = .weekly,
        verifyBackupAfterCreation: Bool = true
    ) {
        self.id = UUID()
        self.isEnabled = isEnabled
        self.encryptionEnabled = encryptionEnabled
        self.backupPassword = nil
        self.lastBackupDate = nil
        self.lastBackupSize = 0
        self.backupLocation = backupLocation
        self.autoBackupEnabled = autoBackupEnabled
        self.autoBackupFrequency = autoBackupFrequency
        self.verifyBackupAfterCreation = verifyBackupAfterCreation
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Backup Frequency

/// 备份频率
enum BackupFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    
    var displayName: String {
        switch self {
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
}
