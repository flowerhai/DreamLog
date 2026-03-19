//
//  DreamSystemIntegrationService.swift
//  DreamLog - Phase 59: iOS System Integration Enhancement
//
//  Created by DreamLog Team on 2026-03-17.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData
import UIKit
import UserNotifications
import CoreSpotlight
import MobileCoreServices

@MainActor
class DreamSystemIntegrationService {
    
    // MARK: - Singleton
    
    static let shared = DreamSystemIntegrationService()
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var focusModeObserver: NSObjectProtocol?
    private var stats: SystemIntegrationStats
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext? = nil) {
        if let providedContext = modelContext {
            self.modelContext = providedContext
        } else if let container = DreamLogApp.shared.modelContainer,
                  let context = try? ModelContext(container) {
            self.modelContext = context
        } else {
            // Fallback: create a temporary in-memory context (should not happen in normal usage)
            // Using Dream as the model since it's the core model of the app
            do {
                let container = try ModelContainer(for: Dream.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                self.modelContext = ModelContext(container)
            } catch {
                // Last resort fallback - this should never happen in practice
                fatalError("Failed to create fallback ModelContext: \(error)")
            }
        }
        self.stats = SystemIntegrationStats()
        self.loadStats()
        self.setupFocusModeObserver()
    }
    
    // MARK: - Quick Actions Management
    
    /// 获取启用的快捷操作列表
    func getEnabledQuickActions() -> [QuickActionType] {
        return QuickActionType.allCases.filter { $0.isEnabled }
    }
    
    /// 更新快捷操作启用状态
    func updateQuickAction(_ type: QuickActionType, isEnabled: Bool) throws {
        // 这里应该更新 UserDefaults 或配置文件
        // 由于 QuickActionType 是枚举，我们使用 UserDefaults 存储状态
        UserDefaults.standard.set(isEnabled, forKey: "QuickAction_\(type.rawValue)")
        
        // 更新动态快捷方式
        try updateDynamicShortcuts()
    }
    
    /// 更新动态快捷方式
    func updateDynamicShortcuts() throws {
        var shortcutItems: [UIApplicationShortcutItem] = []
        
        let enabledActions = getEnabledQuickActions()
        for action in enabledActions.prefix(4) { // 最多 4 个快捷操作
            let shortcutItem = UIApplicationShortcutItem(
                type: "DreamLog.\(action.rawValue)",
                localizedTitle: action.displayName,
                localizedSubtitle: action.subtitle,
                icon: UIApplicationShortcutIcon(templateImageName: action.iconName),
                userInfo: nil
            )
            shortcutItems.append(shortcutItem)
        }
        
        UIApplication.shared.shortcutItems = shortcutItems
    }
    
    /// 处理快捷操作
    func handleQuickAction(_ type: String) async -> QuickActionResult {
        stats.quickActionUses += 1
        saveStats()
        
        guard let actionType = QuickActionType(rawValue: type) else {
            return .failure(.unknownAction)
        }
        
        switch actionType {
        case .recordDream:
            return .success(.openRecordView)
        case .viewStats:
            return .success(.openInsightsView)
        case .todayInspiration:
            return .success(.openInspirationView)
        case .lucidTraining:
            return .success(.openLucidTrainingView)
        case .voiceJournal:
            return .success(.openVoiceJournalView)
        }
    }
    
    // MARK: - Focus Mode Integration
    
    /// 获取专注模式配置
    func getFocusModeConfig() -> DreamFocusModeConfig? {
        let descriptor = FetchDescriptor<DreamFocusModeConfig>()
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 保存专注模式配置
    func saveFocusModeConfig(_ config: DreamFocusModeConfig) throws {
        config.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 创建默认专注模式配置
    func createDefaultFocusModeConfig() -> DreamFocusModeConfig {
        let config = DreamFocusModeConfig()
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    /// 设置专注模式观察者
    private func setupFocusModeObserver() {
        #if canImport(CoreFocus)
        // 监听专注模式变化
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSFocusStatusDidChange"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleFocusModeChange()
            }
        }
        #endif
    }
    
    /// 处理专注模式变化
    private func handleFocusModeChange() async {
        guard let config = getFocusModeConfig() else { return }
        
        // 检查当前专注模式
        let isSleepFocus = true // 需要实际检测
        
        if isSleepFocus && config.autoRecordInSleepFocus {
            // 自动启用录音准备
            await prepareForDreamRecording()
        }
        
        stats.focusModeTriggers += 1
        saveStats()
    }
    
    /// 准备梦境录音
    private func prepareForDreamRecording() async {
        // 预加载录音服务
        // 显示通知提醒用户
        await scheduleDreamRecordingReminder()
    }
    
    /// 调度梦境录音提醒
    private func scheduleDreamRecordingReminder() async {
        let content = UNMutableNotificationContent()
        content.title = "🌙 梦境记录准备就绪"
        content.body = "睡眠模式已开启，床头随时可以记录梦境"
        content.sound = .default
        content.categoryIdentifier = "DREAM_RECORDING"
        
        let request = UNNotificationRequest(
            identifier: "sleep_focus_recording",
            content: content,
            trigger: nil // 立即触发
        )
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Control Center Integration
    
    /// 获取控制中心配置
    func getControlCenterConfig() -> DreamControlCenterConfig? {
        let descriptor = FetchDescriptor<DreamControlCenterConfig>()
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 保存控制中心配置
    func saveControlCenterConfig(_ config: DreamControlCenterConfig) throws {
        config.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 创建默认控制中心配置
    func createDefaultControlCenterConfig() -> DreamControlCenterConfig {
        let config = DreamControlCenterConfig()
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    /// 记录控制中心使用
    func logControlCenterUse() {
        stats.controlCenterUses += 1
        saveStats()
    }
    
    // MARK: - Siri Suggestions
    
    /// 获取 Siri 建议配置
    func getSiriSuggestionsConfig() -> DreamSiriSuggestionsConfig? {
        let descriptor = FetchDescriptor<DreamSiriSuggestionsConfig>()
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 保存 Siri 建议配置
    func saveSiriSuggestionsConfig(_ config: DreamSiriSuggestionsConfig) throws {
        config.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 创建默认 Siri 建议配置
    func createDefaultSiriSuggestionsConfig() -> DreamSiriSuggestionsConfig {
        let config = DreamSiriSuggestionsConfig()
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    /// 更新 Siri 建议
    func updateSiriSuggestions() async {
        guard let config = getSiriSuggestionsConfig(), config.isEnabled else { return }
        
        // 清除旧建议
        CSSearchableIndex.default().deleteAllSearchableItems()
        
        var items: [CSSearchableItem] = []
        
        // 基于时间建议
        if config.timeBasedSuggestions {
            items.append(contentsOf: await createTimeBasedSuggestions())
        }
        
        // 基于习惯建议
        if config.habitBasedSuggestions {
            items.append(contentsOf: await createHabitBasedSuggestions())
        }
        
        // 索引建议
        if !items.isEmpty {
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error = error {
                    print("Siri Suggestions indexing error: \(error)")
                }
            }
        }
    }
    
    /// 创建基于时间的建议
    private func createTimeBasedSuggestions() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        let hour = Calendar.current.component(.hour, from: Date())
        
        // 早晨建议回顾梦境
        if hour >= 6 && hour <= 10 {
            let item = createSearchableItem(
                identifier: "morning_review",
                title: "回顾昨晚的梦境",
                description: "早晨是梦境回忆最清晰的时候",
                keywords: ["梦境", "回顾", "早晨", "记录"]
            )
            items.append(item)
        }
        
        // 晚上建议记录梦境
        if hour >= 20 || hour <= 6 {
            let item = createSearchableItem(
                identifier: "night_record",
                title: "准备记录梦境",
                description: "睡前准备好录音设备",
                keywords: ["梦境", "记录", "睡前", "录音"]
            )
            items.append(item)
        }
        
        return items
    }
    
    /// 创建基于习惯的建议
    private func createHabitBasedSuggestions() async -> [CSSearchableItem] {
        var items: [CSSearchableItem] = []
        
        // 获取用户习惯数据
        // 如果用户通常在某个时间记录，提前提醒
        
        // 检查连续记录
        let streakDays = await getCurrentStreakDays()
        if streakDays > 0 && streakDays % 7 == 0 {
            let item = createSearchableItem(
                identifier: "streak_milestone",
                title: "🎉 连续记录\(streakDays)天！",
                description: "继续保持，你已经养成了好习惯",
                keywords: ["连续", "记录", "成就", "习惯"]
            )
            items.append(item)
        }
        
        // 检查是否有未完成的挑战
        let hasPendingChallenges = await checkPendingChallenges()
        if hasPendingChallenges {
            let item = createSearchableItem(
                identifier: "pending_challenge",
                title: "挑战进行中",
                description: "继续完成你的梦境挑战",
                keywords: ["挑战", "任务", "完成"]
            )
            items.append(item)
        }
        
        return items
    }
    
    /// 创建可搜索项目
    private func createSearchableItem(
        identifier: String,
        title: String,
        description: String,
        keywords: [String]
    ) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeContent as String)
        attributeSet.title = title
        attributeSet.contentDescription = description
        attributeSet.keywords = keywords
        attributeSet.displayName = title
        
        let item = CSSearchableItem(
            uniqueIdentifier: identifier,
            domainIdentifier: "DreamLog.Suggestions",
            attributeSet: attributeSet
        )
        
        return item
    }
    
    /// 获取当前连续记录天数
    private func getCurrentStreakDays() async -> Int {
        // 从 DreamStore 获取
        return 0 // 占位实现
    }
    
    /// 检查是否有待完成的挑战
    private func checkPendingChallenges() async -> Bool {
        // 检查挑战状态
        return false // 占位实现
    }
    
    /// 记录 Siri 建议展示
    func logSiriSuggestionShown() {
        stats.siriSuggestionsShown += 1
        saveStats()
    }
    
    /// 记录 Siri 建议点击
    func logSiriSuggestionTapped() {
        stats.siriSuggestionsTapped += 1
        saveStats()
    }
    
    // MARK: - Lock Screen Integration
    
    /// 获取锁屏配置
    func getLockScreenConfig() -> DreamLockScreenConfig? {
        let descriptor = FetchDescriptor<DreamLockScreenConfig>()
        return try? modelContext.fetch(descriptor).first
    }
    
    /// 保存锁屏配置
    func saveLockScreenConfig(_ config: DreamLockScreenConfig) throws {
        config.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 创建默认锁屏配置
    func createDefaultLockScreenConfig() -> DreamLockScreenConfig {
        let config = DreamLockScreenConfig()
        modelContext.insert(config)
        try? modelContext.save()
        return config
    }
    
    /// 记录锁屏操作使用
    func logLockScreenActionUse() {
        stats.lockScreenActionUses += 1
        saveStats()
    }
    
    // MARK: - Statistics
    
    /// 获取集成统计
    func getStats() -> SystemIntegrationStats {
        return stats
    }
    
    /// 加载统计
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "SystemIntegrationStats"),
           let decoded = try? JSONDecoder().decode(SystemIntegrationStats.self, from: data) {
            self.stats = decoded
        }
    }
    
    /// 保存统计
    private func saveStats() {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: "SystemIntegrationStats")
        }
    }
    
    /// 重置统计
    func resetStats() {
        stats = SystemIntegrationStats()
        saveStats()
    }
    
    // MARK: - Initialization
    
    /// 初始化所有默认配置
    func initializeDefaultConfigs() {
        if getFocusModeConfig() == nil {
            _ = createDefaultFocusModeConfig()
        }
        if getControlCenterConfig() == nil {
            _ = createDefaultControlCenterConfig()
        }
        if getSiriSuggestionsConfig() == nil {
            _ = createDefaultSiriSuggestionsConfig()
        }
        if getLockScreenConfig() == nil {
            _ = createDefaultLockScreenConfig()
        }
        
        // 更新动态快捷方式
        try? updateDynamicShortcuts()
        
        // 更新 Siri 建议
        Task {
            await updateSiriSuggestions()
        }
    }
}

// MARK: - Quick Action Result

enum QuickActionResult {
    case success(QuickActionDestination)
    case failure(QuickActionError)
}

enum QuickActionDestination {
    case openRecordView
    case openInsightsView
    case openInspirationView
    case openLucidTrainingView
    case openVoiceJournalView
}

enum QuickActionError: Error, LocalizedError {
    case unknownAction
    case notConfigured
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .unknownAction: return "未知的快捷操作"
        case .notConfigured: return "功能未配置"
        case .permissionDenied: return "权限被拒绝"
        }
    }
}
