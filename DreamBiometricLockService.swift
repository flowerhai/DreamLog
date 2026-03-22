//
//  DreamBiometricLockService.swift
//  DreamLog - Phase 92: Privacy & Security Suite
//
//  Created by DreamLog Team on 2026-03-22.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import LocalAuthentication
import CryptoKit
import Security

/// 生物识别锁定服务
@MainActor
final class DreamBiometricLockService {
    
    // MARK: - Singleton
    
    static let shared = DreamBiometricLockService()
    
    // MARK: - Properties
    
    private let context = LAContext()
    private var unlockTimer: Timer?
    private var failedAttempts = 0
    private let maxFailedAttempts = 5
    
    var authenticationState: AuthenticationState = .locked
    var lastUnlockDate: Date?
    
    var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    var biometricType: LABiometryType {
        context.biometryType
    }
    
    var biometricTypeName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .none: return "生物识别"
        @unknown default: return "生物识别"
        }
    }
    
    var isAppUnlocked: Bool {
        guard let config = fetchBiometricConfig() else { return true }
        guard config.isEnabled else { return true }
        
        if config.lockTimeout == .immediate {
            return authenticationState.isUnlocked
        }
        
        guard let lastUnlock = lastUnlockDate else { return false }
        let timeSinceUnlock = Date().timeIntervalSince(lastUnlock)
        return timeSinceUnlock <= config.lockTimeout.seconds
    }
    
    // MARK: - Initialization
    
    private init() {
        setupUnlockTimer()
    }
    
    // MARK: - Public Methods
    
    /// 配置生物识别锁
    func configure(isEnabled: Bool) async throws {
        let config = fetchBiometricConfig() ?? BiometricConfig()
        config.isEnabled = isEnabled
        config.updatedAt = Date()
        
        if isEnabled {
            // 测试生物识别是否可用
            let success = try await authenticateWithBiometrics(reason: "配置应用锁")
            if !success {
                throw BiometricError.authenticationFailed
            }
        }
        
        authenticationState = isEnabled ? .locked : .unlocked
        try saveBiometricConfig(config)
    }
    
    /// 使用生物识别认证
    func authenticateWithBiometrics(reason: String = "验证身份以访问 DreamLog") async throws -> Bool {
        // 检查是否已解锁
        if isAppUnlocked {
            return true
        }
        
        // 检查生物识别是否可用
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.notAvailable
        }
        
        do {
            authenticationState = .authenticating
            
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            if success {
                authenticationState = .unlocked
                lastUnlockDate = Date()
                failedAttempts = 0
                return true
            } else {
                authenticationState = .locked
                failedAttempts += 1
                throw BiometricError.authenticationFailed
            }
        } catch LAError.errorDomain as LAError {
            authenticationState = .locked
            failedAttempts += 1
            throw BiometricError.authenticationFailed
        } catch {
            authenticationState = .locked
            throw BiometricError.systemError(error.localizedDescription)
        }
    }
    
    /// 使用密码认证 (备用方案)
    func authenticateWithPasscode(_ passcode: String) async throws -> Bool {
        guard let settings = fetchLockSettings(),
              let storedHash = settings.passcodeHash else {
            throw BiometricError.passcodeNotSet
        }
        
        let inputHash = SHA256.hash(data: Data(passcode.utf8))
        let inputHashString = inputHash.compactMap { String(format: "%02x", $0) }.joined()
        
        if inputHashString == storedHash {
            authenticationState = .unlocked
            lastUnlockDate = Date()
            failedAttempts = 0
            return true
        } else {
            failedAttempts += 1
            if failedAttempts >= maxFailedAttempts {
                throw BiometricError.tooManyFailedAttempts
            }
            throw BiometricError.incorrectPasscode
        }
    }
    
    /// 设置密码
    func setPasscode(_ passcode: String) async throws {
        let hash = SHA256.hash(data: Data(passcode.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        let settings = fetchLockSettings() ?? LockSettings()
        settings.passcodeHash = hashString
        settings.updatedAt = Date()
        
        try saveLockSettings(settings)
    }
    
    /// 更改密码
    func changePasscode(oldPasscode: String, newPasscode: String) async throws {
        // 验证旧密码
        let verified = try await authenticateWithPasscode(oldPasscode)
        guard verified else {
            throw BiometricError.incorrectPasscode
        }
        
        // 设置新密码
        try await setPasscode(newPasscode)
    }
    
    /// 移除密码
    func removePasscode() async throws {
        guard let settings = fetchLockSettings() else { return }
        settings.passcodeHash = nil
        settings.updatedAt = Date()
        try saveLockSettings(settings)
    }
    
    /// 锁定应用
    func lock() {
        authenticationState = .locked
        lastUnlockDate = nil
        unlockTimer?.invalidate()
        unlockTimer = nil
    }
    
    /// 解锁应用
    func unlock() {
        authenticationState = .unlocked
        lastUnlockDate = Date()
        startUnlockTimer()
    }
    
    /// 检查是否需要重新认证
    func checkAuthentication() async throws -> Bool {
        guard let config = fetchBiometricConfig(), config.isEnabled else {
            return true
        }
        
        if isAppUnlocked {
            return true
        }
        
        return try await authenticateWithBiometrics()
    }
    
    /// 获取失败尝试次数
    func getFailedAttempts() -> Int {
        return failedAttempts
    }
    
    /// 重置失败计数
    func resetFailedAttempts() {
        failedAttempts = 0
    }
    
    // MARK: - Private Methods
    
    private func setupUnlockTimer() {
        // 定时器定期检查是否需要锁定
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkLockTimeout()
            }
        }
    }
    
    private func startUnlockTimer() {
        unlockTimer?.invalidate()
        
        guard let config = fetchBiometricConfig() else { return }
        
        if config.lockTimeout != .immediate {
            unlockTimer = Timer.scheduledTimer(withTimeInterval: config.lockTimeout.seconds, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.lock()
                }
            }
        }
    }
    
    private func checkLockTimeout() {
        guard let config = fetchBiometricConfig(), config.isEnabled else { return }
        
        if config.lockTimeout != .immediate {
            guard let lastUnlock = lastUnlockDate else { return }
            let timeSinceUnlock = Date().timeIntervalSince(lastUnlock)
            
            if timeSinceUnlock > config.lockTimeout.seconds {
                lock()
            }
        }
    }
    
    // MARK: - Data Persistence
    
    private func fetchBiometricConfig() -> BiometricConfig? {
        // 在实际实现中，这里应该从 SwiftData 或 UserDefaults 读取
        // 简化实现：从 UserDefaults 读取
        guard let data = UserDefaults.standard.data(forKey: "BiometricConfig"),
              let config = try? JSONDecoder().decode(BiometricConfigCodable.self, from: data) else {
            return nil
        }
        
        let model = BiometricConfig()
        model.isEnabled = config.isEnabled
        model.lockTimeout = config.lockTimeout
        model.requireOnLaunch = config.requireOnLaunch
        model.requireOnBackground = config.requireOnBackground
        model.fallbackToPasscode = config.fallbackToPasscode
        return model
    }
    
    private func saveBiometricConfig(_ config: BiometricConfig) throws {
        let codable = BiometricConfigCodable(
            isEnabled: config.isEnabled,
            lockTimeout: config.lockTimeout,
            requireOnLaunch: config.requireOnLaunch,
            requireOnBackground: config.requireOnBackground,
            fallbackToPasscode: config.fallbackToPasscode
        )
        let data = try JSONEncoder().encode(codable)
        UserDefaults.standard.set(data, forKey: "BiometricConfig")
    }
    
    private func fetchLockSettings() -> LockSettings? {
        guard let data = UserDefaults.standard.data(forKey: "LockSettings"),
              let settings = try? JSONDecoder().decode(LockSettingsCodable.self, from: data) else {
            return nil
        }
        
        let model = LockSettings()
        model.isAppLockEnabled = settings.isAppLockEnabled
        model.maxFailedAttempts = settings.maxFailedAttempts
        model.wipeAfterFailedAttempts = settings.wipeAfterFailedAttempts
        return model
    }
    
    private func saveLockSettings(_ settings: LockSettings) throws {
        let codable = LockSettingsCodable(
            isAppLockEnabled: settings.isAppLockEnabled,
            maxFailedAttempts: settings.maxFailedAttempts,
            wipeAfterFailedAttempts: settings.wipeAfterFailedAttempts
        )
        let data = try JSONEncoder().encode(codable)
        UserDefaults.standard.set(data, forKey: "LockSettings")
    }
}

// MARK: - Codable Models for UserDefaults

struct BiometricConfigCodable: Codable {
    var isEnabled: Bool
    var lockTimeout: LockTimeout
    var requireOnLaunch: Bool
    var requireOnBackground: Bool
    var fallbackToPasscode: Bool
}

struct LockSettingsCodable: Codable {
    var isAppLockEnabled: Bool
    var maxFailedAttempts: Int
    var wipeAfterFailedAttempts: Bool
}

// MARK: - Biometric Errors

enum BiometricError: LocalizedError {
    case notAvailable
    case authenticationFailed
    case passcodeNotSet
    case incorrectPasscode
    case tooManyFailedAttempts
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "设备不支持生物识别"
        case .authenticationFailed:
            return "认证失败，请重试"
        case .passcodeNotSet:
            return "未设置密码"
        case .incorrectPasscode:
            return "密码错误"
        case .tooManyFailedAttempts:
            return "尝试次数过多，请稍后重试"
        case .systemError(let message):
            return "系统错误：\(message)"
        }
    }
}

// MARK: - LAContext Extension

extension LAContext {
    var biometryType: LABiometryType {
        var error: NSError?
        guard canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return self.biometryType
    }
}
