//
//  DreamSystemIntegrationModels.swift
//  DreamLog - Phase 59: iOS System Integration Enhancement
//
//  Created by DreamLog Team on 2026-03-17.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData
import UIKit

// MARK: - Quick Action Types

/// 主屏幕快捷操作类型 (3D Touch / Haptic Touch)
enum QuickActionType: String, Codable, CaseIterable, Identifiable {
    case recordDream = "record_dream"
    case viewStats = "view_stats"
    case todayInspiration = "today_inspiration"
    case lucidTraining = "lucid_training"
    case voiceJournal = "voice_journal"
    
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .recordDream: return "快速记录梦境"
        case .viewStats: return "查看统计"
        case .todayInspiration: return "今日灵感"
        case .lucidTraining: return "清醒梦训练"
        case .voiceJournal: return "语音日记"
        }
    }
    
    /// SF Symbol 图标名称
    var iconName: String {
        switch self {
        case .recordDream: return "mic.fill"
        case .viewStats: return "chart.bar.fill"
        case .todayInspiration: return "lightbulb.fill"
        case .lucidTraining: return "brain.head.profile"
        case .voiceJournal: return "waveform"
        }
    }
    
    /// 快捷操作副标题
    var subtitle: String {
        switch self {
        case .recordDream: return "按住说话，快速记录"
        case .viewStats: return "查看梦境数据概览"
        case .todayInspiration: return "获取今日创意提示"
        case .lucidTraining: return "开始清醒梦练习"
        case .voiceJournal: return "语音记录梦境"
        }
    }
    
    /// 是否启用
    var isEnabled: Bool {
        switch self {
        case .recordDream, .viewStats: return true // 默认启用
        default: return false
        }
    }
}

// MARK: - Focus Mode Integration

/// 专注模式集成配置
@Model
final class DreamFocusModeConfig {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    /// 睡眠专注模式自动启用录音
    var autoRecordInSleepFocus: Bool
    
    /// 睡眠专注模式显示小组件
    var showWidgetInSleepFocus: Bool
    
    /// 工作专注模式禁用通知
    var disableNotificationsInWorkFocus: Bool
    
    /// 个人专注模式显示灵感
    var showInspirationInPersonalFocus: Bool
    
    /// 关联的专注模式标识符
    var linkedFocusModes: [String]
    
    /// 自定义专注模式名称
    var customFocusModeName: String?
    
    init(
        autoRecordInSleepFocus: Bool = true,
        showWidgetInSleepFocus: Bool = true,
        disableNotificationsInWorkFocus: Bool = false,
        showInspirationInPersonalFocus: Bool = true,
        linkedFocusModes: [String] = ["sleep"],
        customFocusModeName: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.autoRecordInSleepFocus = autoRecordInSleepFocus
        self.showWidgetInSleepFocus = showWidgetInSleepFocus
        self.disableNotificationsInWorkFocus = disableNotificationsInWorkFocus
        self.showInspirationInPersonalFocus = showInspirationInPersonalFocus
        self.linkedFocusModes = linkedFocusModes
        self.customFocusModeName = customFocusModeName
    }
}

// MARK: - Control Center Configuration

/// 控制中心配置
@Model
final class DreamControlCenterConfig {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    /// 启用控制中心快捷方式
    var isEnabled: Bool
    
    /// 快捷操作列表（按顺序）
    var quickActions: [QuickActionType]
    
    /// 显示在锁定屏幕
    var showOnLockScreen: Bool
    
    /// 显示在控制中心
    var showInControlCenter: Bool
    
    init(
        isEnabled: Bool = true,
        quickActions: [QuickActionType] = [.recordDream, .voiceJournal, .viewStats],
        showOnLockScreen: Bool = true,
        showInControlCenter: Bool = true
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isEnabled = isEnabled
        self.quickActions = quickActions
        self.showOnLockScreen = showOnLockScreen
        self.showInControlCenter = showInControlCenter
    }
}

// MARK: - Siri Suggestions

/// Siri 建议配置
@Model
final class DreamSiriSuggestionsConfig {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    /// 启用 Siri 建议
    var isEnabled: Bool
    
    /// 在锁屏显示建议
    var showOnLockScreen: Bool
    
    /// 在 Spotlight 显示建议
    var showInSpotlight: Bool
    
    /// 在 App 库显示建议
    var showInAppLibrary: Bool
    
    /// 建议类型
    var suggestionTypes: [SiriSuggestionType]
    
    /// 基于时间建议
    var timeBasedSuggestions: Bool
    
    /// 基于习惯建议
    var habitBasedSuggestions: Bool
    
    init(
        isEnabled: Bool = true,
        showOnLockScreen: Bool = true,
        showInSpotlight: Bool = true,
        showInAppLibrary: Bool = true,
        suggestionTypes: [SiriSuggestionType] = [.recordDream, .reviewDreams, .dailyInspiration],
        timeBasedSuggestions: Bool = true,
        habitBasedSuggestions: Bool = true
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isEnabled = isEnabled
        self.showOnLockScreen = showOnLockScreen
        self.showInSpotlight = showInSpotlight
        self.showInAppLibrary = showInAppLibrary
        self.suggestionTypes = suggestionTypes
        self.timeBasedSuggestions = timeBasedSuggestions
        self.habitBasedSuggestions = habitBasedSuggestions
    }
}

/// Siri 建议类型
enum SiriSuggestionType: String, Codable, CaseIterable, Identifiable {
    case recordDream = "record_dream"
    case reviewDreams = "review_dreams"
    case dailyInspiration = "daily_inspiration"
    case lucidTraining = "lucid_training"
    case weeklyReport = "weekly_report"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .recordDream: return "记录梦境"
        case .reviewDreams: return "回顾梦境"
        case .dailyInspiration: return "每日灵感"
        case .lucidTraining: return "清醒梦训练"
        case .weeklyReport: return "周报"
        }
    }
    
    var iconName: String {
        switch self {
        case .recordDream: return "mic.fill"
        case .reviewDreams: return "book.fill"
        case .dailyInspiration: return "lightbulb.fill"
        case .lucidTraining: return "brain.head.profile"
        case .weeklyReport: return "chart.bar.fill"
        }
    }
}

// MARK: - Lock Screen Configuration

/// 锁屏配置
@Model
final class DreamLockScreenConfig {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    
    /// 启用锁屏快捷操作
    var isEnabled: Bool
    
    /// 快捷操作（最多 4 个）
    var quickActions: [LockScreenQuickAction]
    
    /// 显示在始终显示屏幕上
    var showOnAlwaysOnDisplay: Bool
    
    /// 需要 Face ID 解锁
    var requireFaceID: Bool
    
    init(
        isEnabled: Bool = true,
        quickActions: [LockScreenQuickAction] = [
            LockScreenQuickAction(type: .recordDream, position: .topLeft),
            LockScreenQuickAction(type: .voiceJournal, position: .topRight)
        ],
        showOnAlwaysOnDisplay: Bool = true,
        requireFaceID: Bool = false
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isEnabled = isEnabled
        self.quickActions = quickActions
        self.showOnAlwaysOnDisplay = showOnAlwaysOnDisplay
        self.requireFaceID = requireFaceID
    }
}

/// 锁屏快捷操作
struct LockScreenQuickAction: Codable, Identifiable {
    var id: UUID
    var type: LockScreenActionType
    var position: LockScreenPosition
    
    init(type: LockScreenActionType, position: LockScreenPosition) {
        self.id = UUID()
        self.type = type
        self.position = position
    }
}

/// 锁屏操作类型
enum LockScreenActionType: String, Codable, CaseIterable {
    case recordDream = "record_dream"
    case voiceJournal = "voice_journal"
    case viewStats = "view_stats"
    case todayInspiration = "today_inspiration"
    
    var displayName: String {
        switch self {
        case .recordDream: return "记录梦境"
        case .voiceJournal: return "语音日记"
        case .viewStats: return "统计"
        case .todayInspiration: return "灵感"
        }
    }
    
    var iconName: String {
        switch self {
        case .recordDream: return "mic.fill"
        case .voiceJournal: return "waveform"
        case .viewStats: return "chart.bar.fill"
        case .todayInspiration: return "lightbulb.fill"
        }
    }
}

/// 锁屏位置
enum LockScreenPosition: String, Codable, CaseIterable {
    case topLeft = "top_left"
    case topRight = "top_right"
    case bottomLeft = "bottom_left"
    case bottomRight = "bottom_right"
}

// MARK: - Home Screen Quick Actions

/// 主屏幕快捷操作（用于 applicationShortcutItems）
struct HomeScreenQuickAction: Codable, Identifiable {
    var id: String
    var type: QuickActionType
    var title: String
    var subtitle: String
    var iconName: String
    var isEnabled: Bool
    
    init(type: QuickActionType) {
        self.id = type.rawValue
        self.type = type
        self.title = type.displayName
        self.subtitle = type.subtitle
        self.iconName = type.iconName
        self.isEnabled = type.isEnabled
    }
}

// MARK: - Integration Statistics

/// 系统集成统计
struct SystemIntegrationStats: Codable {
    /// 快捷操作使用次数
    var quickActionUses: Int
    
    /// 专注模式触发次数
    var focusModeTriggers: Int
    
    /// Siri 建议展示次数
    var siriSuggestionsShown: Int
    
    /// Siri 建议点击次数
    var siriSuggestionsTapped: Int
    
    /// 控制中心使用次数
    var controlCenterUses: Int
    
    /// 锁屏操作使用次数
    var lockScreenActionUses: Int
    
    /// 最后使用时间
    var lastUsedDate: Date?
    
    init() {
        self.quickActionUses = 0
        self.focusModeTriggers = 0
        self.siriSuggestionsShown = 0
        self.siriSuggestionsTapped = 0
        self.controlCenterUses = 0
        self.lockScreenActionUses = 0
        self.lastUsedDate = nil
    }
    
    /// Siri 建议点击率
    var siriSuggestionTapRate: Double {
        guard siriSuggestionsShown > 0 else { return 0 }
        return Double(siriSuggestionsTapped) / Double(siriSuggestionsShown) * 100
    }
}
