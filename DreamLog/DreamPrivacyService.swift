//
//  DreamPrivacyService.swift
//  DreamLog - Privacy Mode Core Service
//
//  Phase 70: Dream Privacy Mode with Biometric Lock
//  Created: 2026-03-19
//

import Foundation
import SwiftData
import LocalAuthentication

actor DreamPrivacyService {
    private let modelContext: ModelContext
    private let laContext: LAContext
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.laContext = LAContext()
    }
    
    // MARK: - Privacy Settings Management
    
    /// 获取或创建隐私设置
    func getPrivacySettings() async throws -> DreamPrivacySettings {
        let descriptor = FetchDescriptor<DreamPrivacySettings>()
        let settings = try modelContext.fetch(descriptor)
        
        if let existing = settings.first {
            return existing
        }
        
        // 创建默认设置
        let newSettings = DreamPrivacySettings()
        modelContext.insert(newSettings)
        try modelContext.save()
        return newSettings
    }
    
    /// 更新隐私设置
    func updatePrivacySettings(
        isEnabled: Bool? = nil,
        defaultLockType: DreamLockType? = nil,
        hideLockedFromWidgets: Bool? = nil,
        hideLockedFromNotifications: Bool? = nil,
        hideLockedFromStats: Bool? = nil,
        autoLockEnabled: Bool? = nil,
        autoLockKeywords: [String]? = nil,
        requireAuthOnAppLaunch: Bool? = nil,
        requireAuthAfterSeconds: Double? = nil
    ) async throws -> DreamPrivacySettings {
        let settings = try getPrivacySettings()
        
        if let isEnabled = isEnabled {
            settings.isEnabled = isEnabled
        }
        if let defaultLockType = defaultLockType {
            settings.defaultLockType = defaultLockType
        }
        if let hideLockedFromWidgets = hideLockedFromWidgets {
            settings.hideLockedFromWidgets = hideLockedFromWidgets
        }
        if let hideLockedFromNotifications = hideLockedFromNotifications {
            settings.hideLockedFromNotifications = hideLockedFromNotifications
        }
        if let hideLockedFromStats = hideLockedFromStats {
            settings.hideLockedFromStats = hideLockedFromStats
        }
        if let autoLockEnabled = autoLockEnabled {
            settings.autoLockEnabled = autoLockEnabled
        }
        if let autoLockKeywords = autoLockKeywords {
            settings.autoLockKeywords = autoLockKeywords
        }
        if let requireAuthOnAppLaunch = requireAuthOnAppLaunch {
            settings.requireAuthOnAppLaunch = requireAuthOnAppLaunch
        }
        if let requireAuthAfterSeconds = requireAuthAfterSeconds {
            settings.requireAuthAfterSeconds = requireAuthAfterSeconds
        }
        
        settings.updatedAt = Date()
        try modelContext.save()
        return settings
    }
    
    /// 记录认证成功
    func recordAuthSuccess() async throws {
        let settings = try getPrivacySettings()
        settings.lastAuthTime = Date()
        settings.failedAuthAttempts = 0
        settings.isLocked = false
        settings.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 记录认证失败
    func recordAuthFailure() async throws -> Int {
        let settings = try getPrivacySettings()
        settings.failedAuthAttempts += 1
        settings.updatedAt = Date()
        try modelContext.save()
        return settings.failedAuthAttempts
    }
    
    /// 重置失败计数
    func resetFailedAttempts() async throws {
        let settings = try getPrivacySettings()
        settings.failedAuthAttempts = 0
        try modelContext.save()
    }
    
    // MARK: - Biometric Authentication
    
    /// 检查是否支持生物识别
    func isBiometricAvailable() async -> Bool {
        var error: NSError?
        let canEvaluate = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate
    }
    
    /// 获取生物识别类型
    func getBiometricType() async -> String {
        var error: NSError?
        guard laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return "none"
        }
        
        switch laContext.biometryType {
        case .faceID:
            return "faceID"
        case .touchID:
            return "touchID"
        case .none:
            return "none"
        @unknown default:
            return "unknown"
        }
    }
    
    /// 执行生物识别认证
    func authenticateBiometric(reason: String = "需要验证您的身份以访问隐私梦境") async -> AuthResult {
        // 检查是否支持
        var error: NSError?
        guard laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let err = error {
                return .failure(reason: err.localizedDescription)
            }
            return .failure(reason: "设备不支持生物识别")
        }
        
        do {
            let success = try await laContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                await recordAuthSuccess()
                return .success
            } else {
                await recordAuthFailure()
                return .failure(reason: "认证失败")
            }
        } catch LAError.userCancel.rawValue {
            return .userCancel
        } catch LAError.userFallback.rawValue {
            return .userFallback
        } catch LAError.systemCancel.rawValue {
            return .userCancel
        } catch LAError.passcodeNotSet.rawValue {
            return .failure(reason: "设备未设置密码")
        } catch LAError.biometryNotAvailable.rawValue {
            return .failure(reason: "生物识别不可用")
        } catch LAError.biometryNotEnrolled.rawValue {
            return .failure(reason: "未录入生物特征")
        } catch LAError.lockout.rawValue {
            return .failure(reason: "认证次数过多，请稍后重试")
        } catch {
            await recordAuthFailure()
            return .systemError
        }
    }
    
    // MARK: - Dream Locking
    
    /// 锁定梦境
    func lockDream(_ dream: Dream, lockType: DreamLockType) async throws {
        dream.lockType = lockType
        dream.lockedAt = Date()
        dream.updatedAt = Date()
        try modelContext.save()
        print("已锁定梦境：\(dream.title ?? "Untitled"), 类型：\(lockType)")
    }
    
    /// 解锁梦境
    func unlockDream(_ dream: Dream) async throws {
        dream.lockType = .none
        dream.lockedAt = nil
        dream.isHidden = false
        dream.updatedAt = Date()
        try modelContext.save()
        print("已解锁梦境：\(dream.title ?? "Untitled")")
    }
    
    /// 检查梦境是否已锁定
    func isDreamLocked(_ dream: Dream) async -> Bool {
        return dream.lockType != .none
    }
    
    /// 隐藏梦境
    func hideDream(_ dream: Dream) async throws {
        dream.isHidden = true
        dream.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 取消隐藏梦境
    func unhideDream(_ dream: Dream) async throws {
        dream.isHidden = false
        dream.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 自动锁定检查
    func checkAutoLock(content: String, title: String) async throws -> Bool {
        let settings = try getPrivacySettings()
        return settings.shouldAutoLock(content: content, title: title)
    }
    
    // MARK: - Privacy Stats
    
    /// 获取隐私统计
    func getPrivacyStats() async throws -> DreamPrivacyStats {
        // 获取所有梦境
        let descriptor = FetchDescriptor<Dream>()
        let dreams = try modelContext.fetch(descriptor)
        
        // 统计锁定梦境
        var totalLocked = 0
        var lockedByType: [DreamLockType: Int] = [:]
        var lockedThisWeek = 0
        var lockedThisMonth = 0
        var tagCounts: [String: Int] = [:]
        
        let calendar = Calendar.current
        
        for dream in dreams {
            if dream.lockType != .none {
                totalLocked += 1
                lockedByType[dream.lockType, default: 0] += 1
                
                if let createdAt = dream.createdAt {
                    if calendar.isDateInThisWeek(createdAt) {
                        lockedThisWeek += 1
                    }
                    if calendar.isDateInThisMonth(createdAt) {
                        lockedThisMonth += 1
                    }
                }
                
                for tag in dream.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }
        }
        
        // 找出最多锁定的标签
        let mostLockedTag = tagCounts.max(by: { $0.value < $1.value })?.key
        
        return DreamPrivacyStats(
            totalLockedDreams: totalLocked,
            lockedByType: lockedByType,
            lockedThisWeek: lockedThisWeek,
            lockedThisMonth: lockedThisMonth,
            mostLockedTag: mostLockedTag,
            authSuccessCount: 0,
            authFailCount: 0
        )
    }
    
    // MARK: - Quick Actions
    
    /// 执行隐私快速操作
    func performQuickAction(_ action: PrivacyQuickAction, on dream: Dream) async throws {
        switch action {
        case .lock:
            try await lockDream(dream, lockType: .biometric)
        case .unlock:
            try await unlockDream(dream)
        case .hide:
            try await hideDream(dream)
        case .unhide:
            try await unhideDream(dream)
        }
    }
    
    // MARK: - App Lock
    
    /// 检查应用是否需要锁定
    func needsAppLock() async throws -> Bool {
        let settings = try getPrivacySettings()
        
        guard settings.isEnabled && settings.requireAuthOnAppLaunch else {
            return false
        }
        
        return settings.needsReauthentication()
    }
    
    /// 锁定应用
    func lockApp() async throws {
        let settings = try getPrivacySettings()
        settings.isLocked = true
        settings.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 解锁应用
    func unlockApp() async throws {
        let settings = try getPrivacySettings()
        settings.isLocked = false
        settings.lastAuthTime = Date()
        settings.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - Security
    
    /// 检查是否需要紧急锁定（多次失败后）
    func needsEmergencyLockout() async throws -> Bool {
        let settings = try getPrivacySettings()
        return settings.failedAuthAttempts >= 5
    }
    
    /// 清除所有认证数据（紧急情况下）
    func clearAuthData() async throws {
        let settings = try getPrivacySettings()
        settings.lastAuthTime = nil
        settings.failedAuthAttempts = 0
        settings.isLocked = true
        settings.updatedAt = Date()
        try modelContext.save()
    }
}
