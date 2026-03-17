//
//  DreamSystemIntegrationTests.swift
//  DreamLog - Phase 59: iOS System Integration Enhancement
//
//  Created by DreamLog Team on 2026-03-17.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import SwiftData
@testable import DreamLog

@MainActor
final class DreamSystemIntegrationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamSystemIntegrationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            DreamFocusModeConfig.self,
            DreamControlCenterConfig.self,
            DreamSiriSuggestionsConfig.self,
            DreamLockScreenConfig.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 创建服务实例
        service = DreamSystemIntegrationService(modelContext: modelContext)
        
        // 清理 UserDefaults
        UserDefaults.standard.removeObject(forKey: "SystemIntegrationStats")
        UserDefaults.standard.removeObject(forKey: "QuickAction_record_dream")
        UserDefaults.standard.removeObject(forKey: "QuickAction_view_stats")
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        
        // 清理 UserDefaults
        UserDefaults.standard.removeObject(forKey: "SystemIntegrationStats")
        UserDefaults.standard.removeObject(forKey: "QuickAction_record_dream")
        UserDefaults.standard.removeObject(forKey: "QuickAction_view_stats")
        
        try await super.tearDown()
    }
    
    // MARK: - Quick Action Tests
    
    func testGetEnabledQuickActions() {
        let enabledActions = service.getEnabledQuickActions()
        
        // 默认应该启用 recordDream 和 viewStats
        XCTAssertTrue(enabledActions.contains(.recordDream))
        XCTAssertTrue(enabledActions.contains(.viewStats))
        
        // 总数应该是 2 个（默认启用的）
        XCTAssertEqual(enabledActions.count, 2)
    }
    
    func testUpdateQuickAction() throws {
        // 初始状态
        var enabledActions = service.getEnabledQuickActions()
        XCTAssertTrue(enabledActions.contains(.recordDream))
        
        // 禁用 recordDream
        try service.updateQuickAction(.recordDream, isEnabled: false)
        
        enabledActions = service.getEnabledQuickActions()
        XCTAssertFalse(enabledActions.contains(.recordDream))
        
        // 重新启用
        try service.updateQuickAction(.recordDream, isEnabled: true)
        
        enabledActions = service.getEnabledQuickActions()
        XCTAssertTrue(enabledActions.contains(.recordDream))
    }
    
    func testHandleQuickAction() async {
        // 测试有效的快捷操作
        let result = await service.handleQuickAction("record_dream")
        
        switch result {
        case .success(.openRecordView):
            break // 正确
        default:
            XCTFail("Expected openRecordView destination")
        }
        
        // 测试无效的快捷操作
        let invalidResult = await service.handleQuickAction("invalid_action")
        
        switch invalidResult {
        case .failure(.unknownAction):
            break // 正确
        default:
            XCTFail("Expected unknownAction error")
        }
    }
    
    func testQuickActionStats() async {
        let initialStats = service.getStats()
        XCTAssertEqual(initialStats.quickActionUses, 0)
        
        // 执行快捷操作
        _ = await service.handleQuickAction("record_dream")
        _ = await service.handleQuickAction("view_stats")
        
        let updatedStats = service.getStats()
        XCTAssertEqual(updatedStats.quickActionUses, 2)
    }
    
    // MARK: - Focus Mode Config Tests
    
    func testCreateDefaultFocusModeConfig() {
        let config = service.createDefaultFocusModeConfig()
        
        XCTAssertEqual(config.autoRecordInSleepFocus, true)
        XCTAssertEqual(config.showWidgetInSleepFocus, true)
        XCTAssertEqual(config.disableNotificationsInWorkFocus, false)
        XCTAssertEqual(config.showInspirationInPersonalFocus, true)
        XCTAssertEqual(config.linkedFocusModes, ["sleep"])
    }
    
    func testSaveAndRetrieveFocusModeConfig() throws {
        // 创建配置
        let config = service.createDefaultFocusModeConfig()
        config.autoRecordInSleepFocus = false
        config.showWidgetInSleepFocus = false
        
        try service.saveFocusModeConfig(config)
        
        // 检索配置
        let retrievedConfig = service.getFocusModeConfig()
        
        XCTAssertNotNil(retrievedConfig)
        XCTAssertEqual(retrievedConfig?.autoRecordInSleepFocus, false)
        XCTAssertEqual(retrievedConfig?.showWidgetInSleepFocus, false)
    }
    
    func testGetFocusModeConfigWhenNoneExists() {
        let config = service.getFocusModeConfig()
        XCTAssertNil(config)
    }
    
    // MARK: - Control Center Config Tests
    
    func testCreateDefaultControlCenterConfig() {
        let config = service.createDefaultControlCenterConfig()
        
        XCTAssertEqual(config.isEnabled, true)
        XCTAssertEqual(config.quickActions.count, 3)
        XCTAssertEqual(config.showOnLockScreen, true)
        XCTAssertEqual(config.showInControlCenter, true)
    }
    
    func testSaveAndRetrieveControlCenterConfig() throws {
        let config = service.createDefaultControlCenterConfig()
        config.isEnabled = false
        config.showOnLockScreen = false
        
        try service.saveControlCenterConfig(config)
        
        let retrievedConfig = service.getControlCenterConfig()
        
        XCTAssertNotNil(retrievedConfig)
        XCTAssertEqual(retrievedConfig?.isEnabled, false)
        XCTAssertEqual(retrievedConfig?.showOnLockScreen, false)
    }
    
    func testControlCenterStats() {
        let initialStats = service.getStats()
        XCTAssertEqual(initialStats.controlCenterUses, 0)
        
        service.logControlCenterUse()
        service.logControlCenterUse()
        service.logControlCenterUse()
        
        let updatedStats = service.getStats()
        XCTAssertEqual(updatedStats.controlCenterUses, 3)
    }
    
    // MARK: - Siri Suggestions Config Tests
    
    func testCreateDefaultSiriSuggestionsConfig() {
        let config = service.createDefaultSiriSuggestionsConfig()
        
        XCTAssertEqual(config.isEnabled, true)
        XCTAssertEqual(config.showOnLockScreen, true)
        XCTAssertEqual(config.showInSpotlight, true)
        XCTAssertEqual(config.showInAppLibrary, true)
        XCTAssertEqual(config.timeBasedSuggestions, true)
        XCTAssertEqual(config.habitBasedSuggestions, true)
    }
    
    func testSaveAndRetrieveSiriSuggestionsConfig() throws {
        let config = service.createDefaultSiriSuggestionsConfig()
        config.isEnabled = false
        config.timeBasedSuggestions = false
        
        try service.saveSiriSuggestionsConfig(config)
        
        let retrievedConfig = service.getSiriSuggestionsConfig()
        
        XCTAssertNotNil(retrievedConfig)
        XCTAssertEqual(retrievedConfig?.isEnabled, false)
        XCTAssertEqual(retrievedConfig?.timeBasedSuggestions, false)
    }
    
    func testSiriSuggestionStats() {
        let initialStats = service.getStats()
        XCTAssertEqual(initialStats.siriSuggestionsShown, 0)
        XCTAssertEqual(initialStats.siriSuggestionsTapped, 0)
        XCTAssertEqual(initialStats.siriSuggestionTapRate, 0)
        
        // 模拟展示 10 次
        for _ in 0..<10 {
            service.logSiriSuggestionShown()
        }
        
        // 模拟点击 5 次
        for _ in 0..<5 {
            service.logSiriSuggestionTapped()
        }
        
        let updatedStats = service.getStats()
        XCTAssertEqual(updatedStats.siriSuggestionsShown, 10)
        XCTAssertEqual(updatedStats.siriSuggestionsTapped, 5)
        XCTAssertEqual(updatedStats.siriSuggestionTapRate, 50.0, accuracy: 0.1)
    }
    
    // MARK: - Lock Screen Config Tests
    
    func testCreateDefaultLockScreenConfig() {
        let config = service.createDefaultLockScreenConfig()
        
        XCTAssertEqual(config.isEnabled, true)
        XCTAssertEqual(config.quickActions.count, 2)
        XCTAssertEqual(config.showOnAlwaysOnDisplay, true)
        XCTAssertEqual(config.requireFaceID, false)
    }
    
    func testSaveAndRetrieveLockScreenConfig() throws {
        let config = service.createDefaultLockScreenConfig()
        config.isEnabled = false
        config.requireFaceID = true
        
        try service.saveLockScreenConfig(config)
        
        let retrievedConfig = service.getLockScreenConfig()
        
        XCTAssertNotNil(retrievedConfig)
        XCTAssertEqual(retrievedConfig?.isEnabled, false)
        XCTAssertEqual(retrievedConfig?.requireFaceID, true)
    }
    
    func testLockScreenActionStats() {
        let initialStats = service.getStats()
        XCTAssertEqual(initialStats.lockScreenActionUses, 0)
        
        service.logLockScreenActionUse()
        service.logLockScreenActionUse()
        
        let updatedStats = service.getStats()
        XCTAssertEqual(updatedStats.lockScreenActionUses, 2)
    }
    
    // MARK: - Initialize Default Configs Tests
    
    func testInitializeDefaultConfigs() {
        // 确保没有配置
        XCTAssertNil(service.getFocusModeConfig())
        XCTAssertNil(service.getControlCenterConfig())
        XCTAssertNil(service.getSiriSuggestionsConfig())
        XCTAssertNil(service.getLockScreenConfig())
        
        // 初始化默认配置
        service.initializeDefaultConfigs()
        
        // 验证配置已创建
        XCTAssertNotNil(service.getFocusModeConfig())
        XCTAssertNotNil(service.getControlCenterConfig())
        XCTAssertNotNil(service.getSiriSuggestionsConfig())
        XCTAssertNotNil(service.getLockScreenConfig())
    }
    
    func testInitializeDefaultConfigsWhenAlreadyExists() {
        // 先创建配置
        _ = service.createDefaultFocusModeConfig()
        _ = service.createDefaultControlCenterConfig()
        _ = service.createDefaultSiriSuggestionsConfig()
        _ = service.createDefaultLockScreenConfig()
        
        // 初始化（不应该创建重复配置）
        service.initializeDefaultConfigs()
        
        // 验证配置仍然存在
        XCTAssertNotNil(service.getFocusModeConfig())
        XCTAssertNotNil(service.getControlCenterConfig())
        XCTAssertNotNil(service.getSiriSuggestionsConfig())
        XCTAssertNotNil(service.getLockScreenConfig())
    }
    
    // MARK: - Stats Tests
    
    func testResetStats() {
        // 修改统计
        service.logControlCenterUse()
        service.logLockScreenActionUse()
        
        var stats = service.getStats()
        XCTAssertEqual(stats.controlCenterUses, 1)
        XCTAssertEqual(stats.lockScreenActionUses, 1)
        
        // 重置统计
        service.resetStats()
        
        stats = service.getStats()
        XCTAssertEqual(stats.controlCenterUses, 0)
        XCTAssertEqual(stats.lockScreenActionUses, 0)
        XCTAssertEqual(stats.quickActionUses, 0)
        XCTAssertEqual(stats.siriSuggestionsShown, 0)
    }
    
    func testStatsPersistence() {
        // 修改统计
        service.logControlCenterUse()
        service.logLockScreenActionUse()
        
        // 创建新服务实例（模拟应用重启）
        let newService = DreamSystemIntegrationService(modelContext: modelContext)
        let stats = newService.getStats()
        
        // 验证统计已持久化
        XCTAssertEqual(stats.controlCenterUses, 1)
        XCTAssertEqual(stats.lockScreenActionUses, 1)
    }
    
    // MARK: - Quick Action Type Tests
    
    func testQuickActionTypeProperties() {
        let recordDream = QuickActionType.recordDream
        
        XCTAssertEqual(recordDream.displayName, "快速记录梦境")
        XCTAssertEqual(recordDream.iconName, "mic.fill")
        XCTAssertEqual(recordDream.subtitle, "按住说话，快速记录")
        XCTAssertEqual(recordDream.isEnabled, true)
        
        let voiceJournal = QuickActionType.voiceJournal
        
        XCTAssertEqual(voiceJournal.displayName, "语音日记")
        XCTAssertEqual(voiceJournal.iconName, "waveform")
        XCTAssertEqual(voiceJournal.isEnabled, false) // 默认禁用
    }
    
    func testSiriSuggestionTypeProperties() {
        let recordDream = SiriSuggestionType.recordDream
        
        XCTAssertEqual(recordDream.displayName, "记录梦境")
        XCTAssertEqual(recordDream.iconName, "mic.fill")
        
        let weeklyReport = SiriSuggestionType.weeklyReport
        
        XCTAssertEqual(weeklyReport.displayName, "周报")
        XCTAssertEqual(weeklyReport.iconName, "chart.bar.fill")
    }
    
    func testLockScreenActionTypeProperties() {
        let recordDream = LockScreenActionType.recordDream
        
        XCTAssertEqual(recordDream.displayName, "记录梦境")
        XCTAssertEqual(recordDream.iconName, "mic.fill")
        
        let viewStats = LockScreenActionType.viewStats
        
        XCTAssertEqual(viewStats.displayName, "统计")
        XCTAssertEqual(viewStats.iconName, "chart.bar.fill")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceQuickActionHandling() async {
        self.measure {
            let expectation = self.expectation(description: "Handle quick actions")
            
            Task {
                for _ in 0..<100 {
                    _ = await service.handleQuickAction("record_dream")
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testPerformanceConfigRetrieval() {
        self.measure {
            for _ in 0..<100 {
                _ = service.getFocusModeConfig()
                _ = service.getControlCenterConfig()
                _ = service.getSiriSuggestionsConfig()
                _ = service.getLockScreenConfig()
            }
        }
    }
}
