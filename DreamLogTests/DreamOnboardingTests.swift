//
//  DreamOnboardingTests.swift
//  DreamLogTests
//
//  新手引导功能单元测试
//  Phase 98 - 用户体验优化
//

import XCTest
import SwiftUI
@testable import DreamLog

@MainActor
final class DreamOnboardingTests: XCTestCase {
    
    var service: DreamOnboardingService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 UserDefaults
        testUserDefaults = UserDefaults(suiteName: "test.dreamlog.onboarding")
        testUserDefaults?.removePersistentDomain(forName: "test.dreamlog.onboarding")
        
        // 初始化服务
        service = DreamOnboardingService(userDefaults: testUserDefaults)
    }
    
    override func tearDown() async throws {
        service = nil
        testUserDefaults = nil
        try await super.tearDown()
    }
    
    // MARK: - 引导状态测试
    
    /// 测试首次启动检测
    func testIsFirstLaunch() {
        // 初始状态应该是首次启动
        XCTAssertTrue(service.isFirstLaunch, "新 UserDefaults 应该是首次启动")
        XCTAssertFalse(service.hasCompletedOnboarding, "新 UserDefaults 应该未完成引导")
    }
    
    /// 测试引导完成标记
    func testCompleteOnboarding() {
        // 标记引导完成
        service.completeOnboarding()
        
        XCTAssertFalse(service.isFirstLaunch, "引导完成后不应是首次启动")
        XCTAssertTrue(service.hasCompletedOnboarding, "引导应该标记为已完成")
    }
    
    /// 测试引导重置
    func testResetOnboarding() {
        // 先完成引导
        service.completeOnboarding()
        XCTAssertTrue(service.hasCompletedOnboarding)
        
        // 重置
        service.resetOnboarding()
        
        XCTAssertFalse(service.hasCompletedOnboarding, "重置后引导状态应清除")
        XCTAssertTrue(service.isFirstLaunch, "重置后应回到首次启动状态")
    }
    
    // MARK: - 用户偏好测试
    
    /// 测试默认偏好设置
    func testDefaultUserPreferences() {
        let prefs = service.userPreferences
        
        XCTAssertTrue(prefs.isFirstLaunch, "默认应该是首次启动")
        XCTAssertFalse(prefs.hasCompletedOnboarding, "默认应该未完成引导")
        XCTAssertTrue(prefs.reminderEnabled, "默认应该启用提醒")
        XCTAssertEqual(prefs.reminderHour, 8, "默认提醒时间应该是 8 点")
        XCTAssertEqual(prefs.reminderMinute, 0, "默认提醒分钟应该是 0")
        XCTAssertEqual(prefs.preferredRecordingTime, .morning, "默认记录时间应该是早晨")
        XCTAssertEqual(prefs.analysisDepth, .standard, "默认解析深度应该是标准")
        XCTAssertEqual(prefs.privacyMode, .normal, "默认隐私模式应该是正常")
    }
    
    /// 测试保存和读取偏好设置
    func testSaveAndLoadPreferences() {
        // 创建自定义偏好
        var customPrefs = UserPreferences.default
        customPrefs.preferredRecordingTime = .night
        customPrefs.analysisDepth = .deep
        customPrefs.privacyMode = .privateMode
        customPrefs.reminderHour = 22
        customPrefs.reminderMinute = 30
        
        // 保存
        service.savePreferences(customPrefs)
        
        // 读取
        let loadedPrefs = service.userPreferences
        
        XCTAssertEqual(loadedPrefs.preferredRecordingTime, .night, "记录时间应该保存正确")
        XCTAssertEqual(loadedPrefs.analysisDepth, .deep, "解析深度应该保存正确")
        XCTAssertEqual(loadedPrefs.privacyMode, .privateMode, "隐私模式应该保存正确")
        XCTAssertEqual(loadedPrefs.reminderHour, 22, "提醒小时应该保存正确")
        XCTAssertEqual(loadedPrefs.reminderMinute, 30, "提醒分钟应该保存正确")
    }
    
    /// 测试更新记录时间偏好
    func testUpdateRecordingTimePreference() {
        service.updateRecordingTimePreference(.evening)
        
        XCTAssertEqual(service.userPreferences.preferredRecordingTime, .evening)
        
        service.updateRecordingTimePreference(.flexible)
        XCTAssertEqual(service.userPreferences.preferredRecordingTime, .flexible)
    }
    
    /// 测试更新解析深度偏好
    func testUpdateAnalysisDepth() {
        service.updateAnalysisDepth(.basic)
        XCTAssertEqual(service.userPreferences.analysisDepth, .basic)
        
        service.updateAnalysisDepth(.deep)
        XCTAssertEqual(service.userPreferences.analysisDepth, .deep)
    }
    
    /// 测试更新隐私模式
    func testUpdatePrivacyMode() {
        service.updatePrivacyMode(.privateMode)
        XCTAssertEqual(service.userPreferences.privacyMode, .privateMode)
        
        service.updatePrivacyMode(.normal)
        XCTAssertEqual(service.userPreferences.privacyMode, .normal)
    }
    
    // MARK: - 权限管理测试
    
    /// 测试权限状态
    func testPermissionsGranted() {
        XCTAssertFalse(service.permissionsGranted, "初始状态权限应该未授予")
        
        service.permissionsGranted = true
        XCTAssertTrue(service.permissionsGranted, "设置后权限应该已授予")
        
        service.resetOnboarding()
        XCTAssertFalse(service.permissionsGranted, "重置后权限状态应该清除")
    }
    
    // MARK: - 引导进度追踪测试
    
    /// 测试步骤完成追踪
    func testStepCompletionTracking() {
        // 初始状态所有步骤都未完成
        for step in OnboardingStep.allCases {
            XCTAssertFalse(service.isStepCompleted(step), "步骤 \(step) 初始应该未完成")
        }
        
        // 标记部分步骤完成
        service.trackStepCompletion(.welcome)
        service.trackStepCompletion(.recordDream)
        service.trackStepCompletion(.aiAnalysis)
        
        XCTAssertTrue(service.isStepCompleted(.welcome))
        XCTAssertTrue(service.isStepCompleted(.recordDream))
        XCTAssertTrue(service.isStepCompleted(.aiAnalysis))
        XCTAssertFalse(service.isStepCompleted(.insights))
        XCTAssertFalse(service.isStepCompleted(.timeCapsule))
    }
    
    /// 测试引导进度计算
    func testOnboardingProgress() {
        // 初始进度为 0
        XCTAssertEqual(service.onboardingProgress, 0.0, accuracy: 0.01, "初始进度应该是 0")
        
        // 完成一半步骤
        let steps = OnboardingStep.allCases
        let halfway = steps.count / 2
        
        for i in 0..<halfway {
            service.trackStepCompletion(steps[i])
        }
        
        let expectedProgress = Double(halfway) / Double(steps.count)
        XCTAssertEqual(service.onboardingProgress, expectedProgress, accuracy: 0.01, "进度应该是一半")
        
        // 完成所有步骤
        for step in steps {
            service.trackStepCompletion(step)
        }
        
        XCTAssertEqual(service.onboardingProgress, 1.0, accuracy: 0.01, "完成所有步骤后进度应该是 100%")
    }
    
    // MARK: - 快捷操作测试
    
    /// 测试快捷操作保存和读取
    func testQuickActionSaveAndLoad() {
        // 保存快捷操作
        service.saveQuickAction(.recordDream, at: 0)
        service.saveQuickAction(.viewInsights, at: 1)
        service.saveQuickAction(.dreamGallery, at: 2)
        
        // 读取
        XCTAssertEqual(service.getQuickAction(at: 0), .recordDream)
        XCTAssertEqual(service.getQuickAction(at: 1), .viewInsights)
        XCTAssertEqual(service.getQuickAction(at: 2), .dreamGallery)
        XCTAssertNil(service.getQuickAction(at: 3), "未设置的快捷操作应该返回 nil")
    }
    
    // MARK: - 数据导出导入测试
    
    /// 测试数据导出
    func testExportOnboardingData() {
        // 设置一些数据
        service.completeOnboarding()
        service.permissionsGranted = true
        service.trackStepCompletion(.welcome)
        service.trackStepCompletion(.recordDream)
        
        var prefs = service.userPreferences
        prefs.preferredRecordingTime = .night
        service.savePreferences(prefs)
        
        // 导出
        let exported = service.exportOnboardingData()
        
        XCTAssertTrue(exported.hasCompleted)
        XCTAssertTrue(exported.permissionsGranted)
        XCTAssertEqual(exported.preferences.preferredRecordingTime, .night)
        XCTAssertEqual(exported.completedSteps.count, 2)
        XCTAssertTrue(exported.completedSteps.contains(0))
        XCTAssertTrue(exported.completedSteps.contains(1))
        XCTAssertLessThan(Date().timeIntervalSince(exported.exportDate), 1.0, "导出时间应该是现在")
    }
    
    /// 测试数据导入
    func testImportOnboardingData() {
        // 创建测试数据
        let importData = OnboardingDataExport(
            hasCompleted: true,
            preferences: UserPreferences.default,
            permissionsGranted: true,
            completedSteps: [0, 1, 2, 3],
            exportDate: Date()
        )
        
        // 导入
        service.importOnboardingData(importData)
        
        XCTAssertTrue(service.hasCompletedOnboarding)
        XCTAssertTrue(service.permissionsGranted)
        XCTAssertTrue(service.isStepCompleted(.welcome))
        XCTAssertTrue(service.isStepCompleted(.recordDream))
        XCTAssertTrue(service.isStepCompleted(.aiAnalysis))
        XCTAssertTrue(service.isStepCompleted(.insights))
        XCTAssertFalse(service.isStepCompleted(.timeCapsule))
    }
    
    // MARK: - 用户偏好扩展测试
    
    /// 测试推荐解析深度
    func testRecommendedDepth() {
        let prefs = UserPreferences.default
        
        // 复杂梦境类型应该推荐深度解析
        XCTAssertEqual(prefs.recommendedDepth(for: "清醒梦"), .deep)
        XCTAssertEqual(prefs.recommendedDepth(for: "预知梦"), .deep)
        XCTAssertEqual(prefs.recommendedDepth(for: "重复梦境"), .deep)
        XCTAssertEqual(prefs.recommendedDepth(for: "噩梦"), .deep)
        
        // 普通梦境类型使用默认深度
        XCTAssertEqual(prefs.recommendedDepth(for: "日常梦"), .standard)
        XCTAssertEqual(prefs.recommendedDepth(for: "其他"), .standard)
    }
    
    /// 测试提醒时间显示
    func testReminderTimeDisplay() {
        var prefs = UserPreferences.default
        prefs.reminderHour = 8
        prefs.reminderMinute = 30
        
        XCTAssertEqual(prefs.reminderTimeDisplay, "08:30")
        
        prefs.reminderHour = 22
        prefs.reminderMinute = 5
        
        XCTAssertEqual(prefs.reminderTimeDisplay, "22:05")
    }
    
    /// 测试提醒时间组件
    func testReminderTimeComponents() {
        var prefs = UserPreferences.default
        prefs.reminderHour = 14
        prefs.reminderMinute = 45
        
        let components = prefs.reminderTimeComponents
        XCTAssertEqual(components.hour, 14)
        XCTAssertEqual(components.minute, 45)
    }
    
    // MARK: - 性能测试
    
    /// 测试偏好保存性能
    func testPreferencesSavePerformance() {
        measure {
            for _ in 0..<100 {
                var prefs = service.userPreferences
                prefs.preferredRecordingTime = .night
                service.savePreferences(prefs)
            }
        }
    }
    
    /// 测试步骤追踪性能
    func testStepTrackingPerformance() {
        measure {
            for _ in 0..<100 {
                service.resetOnboarding()
                for step in OnboardingStep.allCases {
                    service.trackStepCompletion(step)
                }
            }
        }
    }
    
    // MARK: - 边界条件测试
    
    /// 测试空偏好设置
    func testEmptyPreferences() {
        // 清除所有偏好
        testUserDefaults?.removeObject(forKey: "userPreferences")
        
        // 应该返回默认值
        let prefs = service.userPreferences
        XCTAssertEqual(prefs.preferredRecordingTime, .morning)
        XCTAssertEqual(prefs.analysisDepth, .standard)
    }
    
    /// 测试快速连续操作
    func testRapidOperations() {
        // 快速连续保存偏好
        for i in 0..<10 {
            var prefs = service.userPreferences
            prefs.reminderHour = i
            service.savePreferences(prefs)
        }
        
        // 最后一次保存应该生效
        XCTAssertEqual(service.userPreferences.reminderHour, 9)
    }
}

// MARK: - OnboardingStep 枚举测试

final class OnboardingStepTests: XCTestCase {
    
    /// 测试步骤数量
    func testStepCount() {
        XCTAssertEqual(OnboardingStep.allCases.count, 9, "应该有 9 个引导步骤")
    }
    
    /// 测试步骤原始值连续性
    func testStepRawValues() {
        let steps = OnboardingStep.allCases
        for (index, step) in steps.enumerated() {
            XCTAssertEqual(step.rawValue, index, "步骤 \(step) 的原始值应该是 \(index)")
        }
    }
    
    /// 测试步骤标题
    func testStepTitles() {
        XCTAssertEqual(OnboardingStep.welcome.title, "欢迎使用 DreamLog")
        XCTAssertEqual(OnboardingStep.recordDream.title, "记录梦境")
        XCTAssertEqual(OnboardingStep.aiAnalysis.title, "AI 解析")
        XCTAssertEqual(OnboardingStep.insights.title, "智能洞察")
        XCTAssertEqual(OnboardingStep.timeCapsule.title, "时间胶囊")
        XCTAssertEqual(OnboardingStep.privacy.title, "隐私保护")
        XCTAssertEqual(OnboardingStep.preferences.title, "个性化设置")
        XCTAssertEqual(OnboardingStep.permissions.title, "权限设置")
        XCTAssertEqual(OnboardingStep.complete.title, "完成")
    }
    
    /// 测试步骤图标
    func testStepIcons() {
        XCTAssertEqual(OnboardingStep.welcome.icon, "hand.wave")
        XCTAssertEqual(OnboardingStep.recordDream.icon, "moon.stars.fill")
        XCTAssertEqual(OnboardingStep.aiAnalysis.icon, "brain.head.profile")
        XCTAssertEqual(OnboardingStep.insights.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(OnboardingStep.timeCapsule.icon, "clock.arrow.circlepath")
        XCTAssertEqual(OnboardingStep.privacy.icon, "lock.shield.fill")
        XCTAssertEqual(OnboardingStep.preferences.icon, "slider.horizontal.3")
        XCTAssertEqual(OnboardingStep.permissions.icon, "checkmark.shield.fill")
        XCTAssertEqual(OnboardingStep.complete.icon, "star.fill")
    }
}

// MARK: - QuickActionType 枚举测试

final class QuickActionTypeTests: XCTestCase {
    
    /// 测试快捷操作目标 URL
    func testQuickActionDestinations() {
        XCTAssertEqual(QuickActionType.recordDream.destination, "dreamlog://record")
        XCTAssertEqual(QuickActionType.viewInsights.destination, "dreamlog://insights")
        XCTAssertEqual(QuickActionType.dreamGallery.destination, "dreamlog://gallery")
        XCTAssertEqual(QuickActionType.timeCapsule.destination, "dreamlog://capsule")
    }
}

// MARK: - UserPreferences 枚举测试

final class UserPreferencesEnumTests: XCTestCase {
    
    /// 测试记录时间偏好显示文本
    func testRecordingTimePreferenceDisplay() {
        XCTAssertEqual(UserPreferences.RecordingTimePreference.morning.displayText, "早晨 (6:00-12:00)")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.afternoon.displayText, "下午 (12:00-18:00)")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.evening.displayText, "晚上 (18:00-23:00)")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.night.displayText, "深夜 (23:00-6:00)")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.flexible.displayText, "灵活时间")
    }
    
    /// 测试记录时间偏好图标
    func testRecordingTimePreferenceIcons() {
        XCTAssertEqual(UserPreferences.RecordingTimePreference.morning.icon, "sunrise.fill")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.afternoon.icon, "sun.max.fill")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.evening.icon, "sunset.fill")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.night.icon, "moon.fill")
        XCTAssertEqual(UserPreferences.RecordingTimePreference.flexible.icon, "clock.fill")
    }
    
    /// 测试解析深度显示文本
    func testAnalysisDepthDisplay() {
        XCTAssertEqual(UserPreferences.AnalysisDepth.basic.displayText, "基础解析（快速概览）")
        XCTAssertEqual(UserPreferences.AnalysisDepth.standard.displayText, "标准解析（推荐）")
        XCTAssertEqual(UserPreferences.AnalysisDepth.deep.displayText, "深度解析（详细分析）")
    }
    
    /// 测试隐私模式显示文本
    func testPrivacyModeDisplay() {
        XCTAssertEqual(UserPreferences.PrivacyMode.normal.displayText, "正常模式")
        XCTAssertEqual(UserPreferences.PrivacyMode.privateMode.displayText, "隐私模式")
    }
}
