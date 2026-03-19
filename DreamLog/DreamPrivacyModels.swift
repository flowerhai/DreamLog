//
//  DreamPrivacyModels.swift
//  DreamLog - Privacy Mode Data Models
//
//  Phase 70: Dream Privacy Mode with Biometric Lock
//  Created: 2026-03-19
//

import Foundation
import SwiftData
import LocalAuthentication

// MARK: - Privacy Lock Type

/// 梦境隐私锁定类型
enum DreamLockType: String, Codable, CaseIterable {
    case none = "none"           // 无锁定
    case biometric = "biometric" // 生物识别 (Face ID/Touch ID)
    case passcode = "passcode"   // 密码锁定
    case hidden = "hidden"       // 隐藏 (不显示在列表中)
    case autoLock = "autoLock"   // 自动锁定 (基于关键词)
    
    var displayName: String {
        switch self {
        case .none: return "无"
        case .biometric: return "生物识别"
        case .passcode: return "密码"
        case .hidden: return "隐藏"
        case .autoLock: return "自动锁定"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "lock.open"
        case .biometric: return "faceid"
        case .passcode: return "lock.fill"
        case .hidden: return "eye.slash"
        case .autoLock: return "lock.shield"
        }
    }
    
    var color: String {
        switch self {
        case .none: return "gray"
        case .biometric: return "green"
        case .passcode: return "orange"
        case .hidden: return "purple"
        case .autoLock: return "blue"
        }
    }
}

// MARK: - Privacy Settings

/// 全局隐私设置模型
@Model
final class DreamPrivacySettings {
    @Attribute(.unique) var id: UUID
    var isEnabled: Bool                    // 是否启用隐私模式
    var defaultLockType: DreamLockType     // 默认锁定类型
    var hideLockedFromWidgets: Bool        // 在小组件中隐藏锁定梦境
    var hideLockedFromNotifications: Bool  // 在通知中隐藏锁定梦境
    var hideLockedFromStats: Bool          // 在统计中隐藏锁定梦境
    var autoLockEnabled: Bool              // 自动锁定新梦境
    var autoLockKeywords: [String]         // 自动锁定关键词
    var requireAuthOnAppLaunch: Bool       // 启动时需要认证
    var requireAuthAfterSeconds: Double    // 后台返回后要求认证的时间 (秒)
    var lastAuthTime: Date?                // 上次认证时间
    var failedAuthAttempts: Int            // 失败认证次数
    var isLocked: Bool                     // 当前是否锁定状态
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = false,
        defaultLockType: DreamLockType = .biometric,
        hideLockedFromWidgets: Bool = true,
        hideLockedFromNotifications: Bool = true,
        hideLockedFromStats: Bool = false,
        autoLockEnabled: Bool = false,
        autoLockKeywords: [String] = [],
        requireAuthOnAppLaunch: Bool = false,
        requireAuthAfterSeconds: Double = 300,
        lastAuthTime: Date? = nil,
        failedAuthAttempts: Int = 0,
        isLocked: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.defaultLockType = defaultLockType
        self.hideLockedFromWidgets = hideLockedFromWidgets
        self.hideLockedFromNotifications = hideLockedFromNotifications
        self.hideLockedFromStats = hideLockedFromStats
        self.autoLockEnabled = autoLockEnabled
        self.autoLockKeywords = autoLockKeywords
        self.requireAuthOnAppLaunch = requireAuthOnAppLaunch
        self.requireAuthAfterSeconds = requireAuthAfterSeconds
        self.lastAuthTime = lastAuthTime
        self.failedAuthAttempts = failedAuthAttempts
        self.isLocked = isLocked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 检查是否需要重新认证
    func needsReauthentication() -> Bool {
        guard isEnabled else { return false }
        
        if requireAuthOnAppLaunch && lastAuthTime == nil {
            return true
        }
        
        if let lastAuth = lastAuthTime {
            let timeSinceAuth = Date().timeIntervalSince(lastAuth)
            return timeSinceAuth > requireAuthAfterSeconds
        }
        
        return true
    }
    
    /// 检查关键词是否触发自动锁定
    func shouldAutoLock(content: String, title: String) -> Bool {
        guard isEnabled && autoLockEnabled else { return false }
        
        let text = (title + " " + content).lowercased()
        return autoLockKeywords.contains { keyword in
            text.contains(keyword.lowercased())
        }
    }
}

// MARK: - Privacy Stats

/// 隐私统计数据
struct DreamPrivacyStats {
    var totalLockedDreams: Int
    var lockedByType: [DreamLockType: Int]
    var lockedThisWeek: Int
    var lockedThisMonth: Int
    var mostLockedTag: String?
    var authSuccessCount: Int
    var authFailCount: Int
    
    init(
        totalLockedDreams: Int = 0,
        lockedByType: [DreamLockType: Int] = [:],
        lockedThisWeek: Int = 0,
        lockedThisMonth: Int = 0,
        mostLockedTag: String? = nil,
        authSuccessCount: Int = 0,
        authFailCount: Int = 0
    ) {
        self.totalLockedDreams = totalLockedDreams
        self.lockedByType = lockedByType
        self.lockedThisWeek = lockedThisWeek
        self.lockedThisMonth = lockedThisMonth
        self.mostLockedTag = mostLockedTag
        self.authSuccessCount = authSuccessCount
        self.authFailCount = authFailCount
    }
}

// MARK: - Auth Result

/// 认证结果
enum AuthResult {
    case success
    case failure(reason: String)
    case userFallback
    case userCancel
    case systemError
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// MARK: - Privacy Quick Action

/// 隐私快速操作
enum PrivacyQuickAction: String, CaseIterable {
    case lock = "lock"
    case unlock = "unlock"
    case hide = "hide"
    case unhide = "unhide"
    
    var displayName: String {
        switch self {
        case .lock: return "锁定"
        case .unlock: return "解锁"
        case .hide: return "隐藏"
        case .unhide: return "取消隐藏"
        }
    }
    
    var icon: String {
        switch self {
        case .lock: return "lock.fill"
        case .unlock: return "lock.open.fill"
        case .hide: return "eye.slash.fill"
        case .unhide: return "eye.fill"
        }
    }
}
