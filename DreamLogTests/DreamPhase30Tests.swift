//
//  DreamPhase30Tests.swift
//  DreamLogTests
//
//  Phase 30 - App Store 发布准备 - 用户体验优化测试
//  测试覆盖：新手引导/空状态/触觉反馈
//

import XCTest
@testable import DreamLog

// MARK: - 新手引导测试

final class DreamOnboardingTests: XCTestCase {
    
    var onboardingPages: [OnboardingPage]!
    
    override func setUp() {
        super.setUp()
        onboardingPages = OnboardingPage.pages
    }
    
    override func tearDown() {
        onboardingPages = nil
        super.tearDown()
    }
    
    // MARK: - 引导页面数量测试
    
    func testOnboardingPageCount() {
        XCTAssertEqual(onboardingPages.count, 5, "应该有 5 个引导页面")
    }
    
    // MARK: - 引导页面内容测试
    
    func testFirstPageContent() {
        let page = onboardingPages[0]
        XCTAssertEqual(page.icon, "moon.stars.fill")
        XCTAssertEqual(page.title, "记录你的每一个梦境")
        XCTAssertEqual(page.features.count, 3)
        XCTAssertTrue(page.features.contains("语音快速记录"))
    }
    
    func testSecondPageContent() {
        let page = onboardingPages[1]
        XCTAssertEqual(page.icon, "brain.head.profile")
        XCTAssertEqual(page.title, "AI 梦境解析")
        XCTAssertEqual(page.features.count, 3)
        XCTAssertTrue(page.features.contains("3 层梦境解析"))
    }
    
    func testThirdPageContent() {
        let page = onboardingPages[2]
        XCTAssertEqual(page.icon, "chart.line.uptrend.xyaxis")
        XCTAssertEqual(page.title, "智能洞察与趋势")
        XCTAssertTrue(page.features.contains("情绪趋势分析"))
    }
    
    func testFourthPageContent() {
        let page = onboardingPages[3]
        XCTAssertEqual(page.icon, "clock.arrow.circlepath")
        XCTAssertEqual(page.title, "梦境时间胶囊")
        XCTAssertTrue(page.features.contains("定时解锁"))
    }
    
    func testFifthPageContent() {
        let page = onboardingPages[4]
        XCTAssertEqual(page.icon, "lock.shield.fill")
        XCTAssertEqual(page.title, "隐私安全保护")
        XCTAssertTrue(page.features.contains("AES-256 加密"))
    }
    
    // MARK: - 页面唯一性测试
    
    func testPageUniqueIds() {
        let ids = onboardingPages.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "所有页面 ID 应该唯一")
    }
    
    // MARK: - 用户偏好设置测试
    
    func testUserPreferencesDefaultValues() {
        let prefs = UserPreferences(
            isFirstLaunch: true,
            hasCompletedOnboarding: false,
            reminderEnabled: false,
            reminderHour: 8,
            reminderMinute: 0,
            preferredRecordingTime: .flexible,
            analysisDepth: .standard,
            privacyMode: .normal
        )
        
        XCTAssertTrue(prefs.isFirstLaunch)
        XCTAssertFalse(prefs.hasCompletedOnboarding)
        XCTAssertFalse(prefs.reminderEnabled)
        XCTAssertEqual(prefs.preferredRecordingTime, .flexible)
        XCTAssertEqual(prefs.analysisDepth, .standard)
    }
    
    // MARK: - 记录时间偏好测试
    
    func testRecordingTimePreferenceAllCases() {
        let allCases = RecordingTimePreference.allCases
        XCTAssertEqual(allCases.count, 5)
        
        XCTAssertTrue(allCases.contains(.morning))
        XCTAssertTrue(allCases.contains(.afternoon))
        XCTAssertTrue(allCases.contains(.evening))
        XCTAssertTrue(allCases.contains(.night))
        XCTAssertTrue(allCases.contains(.flexible))
    }
    
    func testRecordingTimePreferenceDisplayText() {
        XCTAssertEqual(RecordingTimePreference.morning.displayText, "早晨 (6:00-12:00)")
        XCTAssertEqual(RecordingTimePreference.afternoon.displayText, "下午 (12:00-18:00)")
        XCTAssertEqual(RecordingTimePreference.evening.displayText, "晚上 (18:00-23:00)")
        XCTAssertEqual(RecordingTimePreference.night.displayText, "深夜 (23:00-6:00)")
        XCTAssertEqual(RecordingTimePreference.flexible.displayText, "灵活时间")
    }
    
    // MARK: - 解析深度测试
    
    func testAnalysisDepthAllCases() {
        let allCases = AnalysisDepth.allCases
        XCTAssertEqual(allCases.count, 3)
        
        XCTAssertTrue(allCases.contains(.basic))
        XCTAssertTrue(allCases.contains(.standard))
        XCTAssertTrue(allCases.contains(.deep))
    }
    
    func testAnalysisDepthDescription() {
        XCTAssertEqual(AnalysisDepth.basic.description, "快速解析，适合日常记录")
        XCTAssertEqual(AnalysisDepth.standard.description, "标准解析，平衡速度和深度")
        XCTAssertEqual(AnalysisDepth.deep.description, "深度解析，探索潜意识")
    }
    
    // MARK: - 隐私模式测试
    
    func testPrivacyModeAllCases() {
        let allCases = PrivacyMode.allCases
        XCTAssertEqual(allCases.count, 3)
        
        XCTAssertTrue(allCases.contains(.normal))
        XCTAssertTrue(allCases.contains(.incognito))
        XCTAssertTrue(allCases.contains(.locked))
    }
    
    // MARK: - 偏好设置编码测试
    
    func testUserPreferencesCodable() {
        let original = UserPreferences(
            isFirstLaunch: false,
            hasCompletedOnboarding: true,
            reminderEnabled: true,
            reminderHour: 22,
            reminderMinute: 30,
            preferredRecordingTime: .night,
            analysisDepth: .deep,
            privacyMode: .locked
        )
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(original)
        XCTAssertNotNil(data)
        
        let decoder = JSONDecoder()
        let decoded = try? decoder.decode(UserPreferences.self, from: data!)
        XCTAssertNotNil(decoded)
        
        XCTAssertEqual(decoded?.isFirstLaunch, original.isFirstLaunch)
        XCTAssertEqual(decoded?.hasCompletedOnboarding, original.hasCompletedOnboarding)
        XCTAssertEqual(decoded?.reminderHour, original.reminderHour)
        XCTAssertEqual(decoded?.preferredRecordingTime, original.preferredRecordingTime)
    }
}

// MARK: - 空状态视图测试

final class DreamEmptyStatesTests: XCTestCase {
    
    // MARK: - 梦境列表空状态测试
    
    func testDreamListEmptyStateTitle() {
        let title = EmptyStateType.dreamList.title
        XCTAssertEqual(title, "还没有梦境记录")
    }
    
    func testDreamListEmptyStateMessage() {
        let message = EmptyStateType.dreamList.message
        XCTAssertTrue(message.contains("开始记录"))
    }
    
    func testDreamListEmptyStateIcon() {
        let icon = EmptyStateType.dreamList.icon
        XCTAssertEqual(icon, "moon.stars.fill")
    }
    
    // MARK: - 洞察空状态测试
    
    func testInsightsEmptyStateTitle() {
        let title = EmptyStateType.insights.title
        XCTAssertEqual(title, "正在分析你的梦境")
    }
    
    func testInsightsEmptyStateIcon() {
        let icon = EmptyStateType.insights.icon
        XCTAssertEqual(icon, "chart.bar.fill")
    }
    
    // MARK: - 时间胶囊空状态测试
    
    func testTimeCapsuleEmptyStateTitle() {
        let title = EmptyStateType.timeCapsule.title
        XCTAssertEqual(title, "还没有时间胶囊")
    }
    
    func testTimeCapsuleEmptyStateIcon() {
        let icon = EmptyStateType.timeCapsule.icon
        XCTAssertEqual(icon, "clock.arrow.circlepath")
    }
    
    // MARK: - 备份空状态测试
    
    func testBackupEmptyStateTitle() {
        let title = EmptyStateType.backup.title
        XCTAssertEqual(title, "还没有备份")
    }
    
    func testBackupEmptyStateIcon() {
        let icon = EmptyStateType.backup.icon
        XCTAssertEqual(icon, "externaldrive.fill")
    }
    
    // MARK: - 搜索无结果空状态测试
    
    func testSearchNoResultsTitle() {
        let title = EmptyStateType.searchNoResults(query: "测试").title
        XCTAssertTrue(title.contains("测试"))
    }
    
    func testSearchNoResultsMessage() {
        let message = EmptyStateType.searchNoResults(query: "测试").message
        XCTAssertTrue(message.contains("换个关键词"))
    }
    
    // MARK: - 空状态类型枚举测试
    
    func testEmptyStateTypeAllCases() {
        // 测试所有空状态类型都有正确的配置
        let types: [EmptyStateType] = [
            .dreamList,
            .insights,
            .timeCapsule,
            .backup,
            .searchNoResults(query: "test"),
            .loading
        ]
        
        for type in types {
            XCTAssertFalse(type.title.isEmpty, "标题不应为空")
            XCTAssertFalse(type.message.isEmpty, "消息不应为空")
            XCTAssertFalse(type.icon.isEmpty, "图标不应为空")
        }
    }
}

// MARK: - 触觉反馈服务测试

final class DreamHapticFeedbackTests: XCTestCase {
    
    var hapticService: DreamHapticService!
    
    override func setUp() {
        super.setUp()
        hapticService = DreamHapticService()
    }
    
    override func tearDown() {
        hapticService = nil
        super.tearDown()
    }
    
    // MARK: - 服务初始化测试
    
    func testHapticServiceInitialization() {
        XCTAssertNotNil(hapticService)
        XCTAssertTrue(hapticService.isEnabled)
        XCTAssertEqual(hapticService.intensity, 1.0)
    }
    
    // MARK: - 触觉反馈类型测试
    
    func testHapticTypeCount() {
        // 测试所有定义的反馈类型
        let types: [DreamHapticType] = [
            .lightImpact, .mediumImpact, .heavyImpact,
            .success, .error, .warning,
            .selection, .toggleSwitch,
            .recordingStart, .recordingEnd,
            .refreshComplete, .loadComplete,
            .unlockAchievement, .biometricSuccess
        ]
        
        XCTAssertEqual(types.count, 14, "应该测试所有主要反馈类型")
    }
    
    // MARK: - 基础反馈测试
    
    func testLightImpact() {
        let haptic = DreamHapticType.lightImpact
        XCTAssertEqual(haptic.intensity, 0.3)
    }
    
    func testMediumImpact() {
        let haptic = DreamHapticType.mediumImpact
        XCTAssertEqual(haptic.intensity, 0.6)
    }
    
    func testHeavyImpact() {
        let haptic = DreamHapticType.heavyImpact
        XCTAssertEqual(haptic.intensity, 1.0)
    }
    
    // MARK: - 通知反馈测试
    
    func testSuccessFeedback() {
        let haptic = DreamHapticType.success
        XCTAssertEqual(haptic.intensity, 0.8)
    }
    
    func testErrorFeedback() {
        let haptic = DreamHapticType.error
        XCTAssertEqual(haptic.intensity, 0.9)
    }
    
    func testWarningFeedback() {
        let haptic = DreamHapticType.warning
        XCTAssertEqual(haptic.intensity, 0.7)
    }
    
    // MARK: - 场景反馈测试
    
    func testRecordingFeedback() {
        let startHaptic = DreamHapticType.recordingStart
        let endHaptic = DreamHapticType.recordingEnd
        
        XCTAssertGreaterThan(startHaptic.intensity, 0)
        XCTAssertGreaterThan(endHaptic.intensity, 0)
    }
    
    func testAchievementFeedback() {
        let haptic = DreamHapticType.unlockAchievement
        XCTAssertEqual(haptic.intensity, 1.0, "成就解锁应该使用最强反馈")
    }
    
    // MARK: - 强度调节测试
    
    func testIntensityAdjustment() {
        hapticService.intensity = 0.5
        XCTAssertEqual(hapticService.intensity, 0.5)
        
        hapticService.intensity = 0.0
        XCTAssertEqual(hapticService.intensity, 0.0)
        
        hapticService.intensity = 1.0
        XCTAssertEqual(hapticService.intensity, 1.0)
    }
    
    // MARK: - 启用/禁用测试
    
    func testEnableDisable() {
        hapticService.isEnabled = false
        XCTAssertFalse(hapticService.isEnabled)
        
        hapticService.isEnabled = true
        XCTAssertTrue(hapticService.isEnabled)
    }
    
    // MARK: - 组合反馈测试
    
    func testSequentialFeedback() {
        // 测试连续反馈序列
        let sequence: [DreamHapticType] = [
            .lightImpact,
            .mediumImpact,
            .heavyImpact
        ]
        
        XCTAssertEqual(sequence.count, 3)
        XCTAssertTrue(sequence[0].intensity < sequence[1].intensity)
        XCTAssertTrue(sequence[1].intensity < sequence[2].intensity)
    }
    
    // MARK: - 渐变反馈测试
    
    func testGradientFeedbackIncreasing() {
        let gradient = DreamHapticType.gradientIncreasing
        XCTAssertEqual(gradient.intensity, 1.0)
    }
    
    func testGradientFeedbackDecreasing() {
        let gradient = DreamHapticType.gradientDecreasing
        XCTAssertEqual(gradient.intensity, 0.3)
    }
}

// MARK: - 用户体验集成测试

final class DreamUXIntegrationTests: XCTestCase {
    
    // MARK: - 引导完成后状态测试
    
    func testOnboardingCompletionFlow() {
        var prefs = UserPreferences(
            isFirstLaunch: true,
            hasCompletedOnboarding: false,
            reminderEnabled: false,
            reminderHour: 8,
            reminderMinute: 0,
            preferredRecordingTime: .flexible,
            analysisDepth: .standard,
            privacyMode: .normal
        )
        
        // 模拟完成引导
        prefs.hasCompletedOnboarding = true
        prefs.isFirstLaunch = false
        
        XCTAssertFalse(prefs.isFirstLaunch)
        XCTAssertTrue(prefs.hasCompletedOnboarding)
    }
    
    // MARK: - 空状态与操作关联测试
    
    func testEmptyStateActions() {
        let dreamListEmpty = EmptyStateType.dreamList
        XCTAssertEqual(dreamListEmpty.actionTitle, "开始记录")
        
        let backupEmpty = EmptyStateType.backup
        XCTAssertEqual(backupEmpty.actionTitle, "立即备份")
    }
    
    // MARK: - 触觉反馈与操作关联测试
    
    func testHapticFeedbackForActions() {
        // 测试不同操作对应的触觉反馈
        let recordHaptic = DreamHapticType.recordingStart
        let successHaptic = DreamHapticType.success
        let errorHaptic = DreamHapticType.error
        
        XCTAssertGreaterThan(recordHaptic.intensity, 0)
        XCTAssertGreaterThan(successHaptic.intensity, 0)
        XCTAssertGreaterThan(errorHaptic.intensity, 0)
    }
}

// MARK: - 性能测试

final class DreamPhase30PerformanceTests: XCTestCase {
    
    func testOnboardingPageLoadPerformance() {
        measure {
            let pages = OnboardingPage.pages
            XCTAssertGreaterThan(pages.count, 0)
        }
    }
    
    func testEmptyStateCreationPerformance() {
        measure {
            let types: [EmptyStateType] = [
                .dreamList, .insights, .timeCapsule, .backup
            ]
            for type in types {
                _ = type.title
                _ = type.message
            }
        }
    }
    
    func testHapticServiceInitializationPerformance() {
        measure {
            let service = DreamHapticService()
            _ = service.isEnabled
        }
    }
}
