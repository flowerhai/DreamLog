//
//  DreamPrivacyViewModel.swift
//  DreamLog - Privacy View Model
//
//  Phase 70: Dream Privacy Mode with Biometric Lock
//  Created: 2026-03-19
//

import Foundation
import SwiftData
import Combine

@MainActor
class DreamPrivacyViewModel: ObservableObject {
    @Published var settings: DreamPrivacySettings
    @Published var stats: DreamPrivacyStats?
    @Published var isEnabled: Bool = false
    @Published var isBiometricAvailable: Bool = false
    @Published var biometricType: String = "none"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var privacyService: DreamPrivacyService?
    private var modelContext: ModelContext?
    
    init() {
        // 创建临时设置用于预览
        self.settings = DreamPrivacySettings()
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.privacyService = DreamPrivacyService(modelContext: modelContext)
    }
    
    // MARK: - Load Settings
    
    func loadSettings() async {
        isLoading = true
        errorMessage = nil
        
        guard let service = privacyService else {
            errorMessage = "服务未初始化"
            isLoading = false
            return
        }
        
        do {
            let loadedSettings = try await service.getPrivacySettings()
            self.settings = loadedSettings
            self.isEnabled = loadedSettings.isEnabled
            
            // 检查生物识别
            self.isBiometricAvailable = await service.isBiometricAvailable()
            self.biometricType = await service.getBiometricType()
            
        } catch {
            errorMessage = "加载设置失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Update Settings
    
    func updateSettings(
        isEnabled: Bool? = nil,
        defaultLockType: DreamLockType? = nil,
        hideLockedFromWidgets: Bool? = nil,
        hideLockedFromNotifications: Bool? = nil,
        hideLockedFromStats: Bool? = nil,
        autoLockEnabled: Bool? = nil,
        autoLockKeywords: [String]? = nil,
        requireAuthOnAppLaunch: Bool? = nil,
        requireAuthAfterSeconds: Double? = nil
    ) async throws {
        guard let service = privacyService else {
            throw PrivacyError.serviceNotInitialized
        }
        
        let updatedSettings = try await service.updatePrivacySettings(
            isEnabled: isEnabled,
            defaultLockType: defaultLockType,
            hideLockedFromWidgets: hideLockedFromWidgets,
            hideLockedFromNotifications: hideLockedFromNotifications,
            hideLockedFromStats: hideLockedFromStats,
            autoLockEnabled: autoLockEnabled,
            autoLockKeywords: autoLockKeywords,
            requireAuthOnAppLaunch: requireAuthOnAppLaunch,
            requireAuthAfterSeconds: requireAuthAfterSeconds
        )
        
        self.settings = updatedSettings
        if let enabled = isEnabled {
            self.isEnabled = enabled
        }
        
        // 重新加载统计
        await loadStats()
    }
    
    // MARK: - Load Stats
    
    func loadStats() async {
        guard let service = privacyService else { return }
        
        do {
            self.stats = try await service.getPrivacyStats()
        } catch {
            print("加载统计失败：\(error)")
        }
    }
    
    // MARK: - Biometric Auth
    
    func testBiometricAuth() async -> AuthResult {
        guard let service = privacyService else {
            return .failure(reason: "服务未初始化")
        }
        
        return await service.authenticateBiometric()
    }
    
    // MARK: - Quick Actions
    
    func performQuickAction(_ action: PrivacyQuickAction, on dream: Dream) async throws {
        guard let service = privacyService else {
            throw PrivacyError.serviceNotInitialized
        }
        
        try await service.performQuickAction(action, on: dream)
        await loadStats()
    }
    
    // MARK: - App Lock
    
    func checkAppLock() async throws -> Bool {
        guard let service = privacyService else {
            throw PrivacyError.serviceNotInitialized
        }
        
        return try await service.needsAppLock()
    }
    
    func lockApp() async throws {
        guard let service = privacyService else {
            throw PrivacyError.serviceNotInitialized
        }
        
        try await service.lockApp()
    }
    
    func unlockApp() async throws {
        guard let service = privacyService else {
            throw PrivacyError.serviceNotInitialized
        }
        
        try await service.unlockApp()
    }
}

// MARK: - Privacy Error

enum PrivacyError: LocalizedError {
    case serviceNotInitialized
    case authenticationFailed
    case biometricNotAvailable
    case dreamNotFound
    
    var errorDescription: String? {
        switch self {
        case .serviceNotInitialized:
            return "隐私服务未初始化"
        case .authenticationFailed:
            return "认证失败"
        case .biometricNotAvailable:
            return "设备不支持生物识别"
        case .dreamNotFound:
            return "梦境不存在"
        }
    }
}
