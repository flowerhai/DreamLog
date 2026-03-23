//
//  DreamOnboardingService.swift
//  DreamLog
//
//  新手引导服务 - 管理引导状态、用户偏好和权限请求
//  Phase 98 - 用户体验优化
//

import Foundation
import SwiftUI
import UserNotifications

// MARK: - 引导服务

@MainActor
@ModelActor
final class DreamOnboardingService {
    static let shared = DreamOnboardingService()
    
    private let userDefaults: UserDefaults
    private static let hasCompletedKey = "hasCompletedOnboarding"
    private static let preferencesKey = "userPreferences"
    private static let permissionsGrantedKey = "onboardingPermissionsGranted"
    
    // MARK: - 初始化
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - 引导状态管理
    
    /// 检查是否已完成引导
    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Self.hasCompletedKey) }
        set { userDefaults.set(newValue, forKey: Self.hasCompletedKey) }
    }
    
    /// 检查是否首次启动
    var isFirstLaunch: Bool {
        userDefaults.object(forKey: Self.hasCompletedKey) == nil
    }
    
    /// 标记引导已完成
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    /// 重置引导状态（用于测试或重新引导）
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.removeObject(forKey: Self.preferencesKey)
        userDefaults.removeObject(forKey: Self.permissionsGrantedKey)
    }
    
    // MARK: - 用户偏好管理
    
    /// 获取用户偏好设置
    var userPreferences: UserPreferences {
        get {
            guard let data = userDefaults.data(forKey: Self.preferencesKey),
                  let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data) else {
                return .default
            }
            return prefs
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: Self.preferencesKey)
            }
        }
    }
    
    /// 保存用户偏好设置
    func savePreferences(_ preferences: UserPreferences) {
        userPreferences = preferences
    }
    
    /// 更新记录时间偏好
    func updateRecordingTimePreference(_ preference: UserPreferences.RecordingTimePreference) {
        var prefs = userPreferences
        prefs.preferredRecordingTime = preference
        savePreferences(prefs)
    }
    
    /// 更新解析深度偏好
    func updateAnalysisDepth(_ depth: UserPreferences.AnalysisDepth) {
        var prefs = userPreferences
        prefs.analysisDepth = depth
        savePreferences(prefs)
    }
    
    /// 更新隐私模式
    func updatePrivacyMode(_ mode: UserPreferences.PrivacyMode) {
        var prefs = userPreferences
        prefs.privacyMode = mode
        savePreferences(prefs)
    }
    
    // MARK: - 权限管理
    
    /// 检查权限是否已授予
    var permissionsGranted: Bool {
        get { userDefaults.bool(forKey: Self.permissionsGrantedKey) }
        set { userDefaults.set(newValue, forKey: Self.permissionsGrantedKey) }
    }
    
    /// 请求通知权限
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            if granted {
                permissionsGranted = true
            }
            return granted
        } catch {
            print("通知权限请求失败：\(error)")
            return false
        }
    }
    
    /// 请求所有必要权限
    func requestAllPermissions() async -> PermissionResult {
        var result = PermissionResult()
        
        // 通知权限
        result.notificationsGranted = await requestNotificationPermission()
        
        // 标记权限流程已完成
        if result.notificationsGranted {
            permissionsGranted = true
        }
        
        return result
    }
    
    // MARK: - 引导进度追踪
    
    /// 记录引导步骤完成情况
    func trackStepCompletion(_ step: OnboardingStep) {
        let key = "onboardingStep_\(step.rawValue)_completed"
        userDefaults.set(true, forKey: key)
    }
    
    /// 检查步骤是否已完成
    func isStepCompleted(_ step: OnboardingStep) -> Bool {
        let key = "onboardingStep_\(step.rawValue)_completed"
        return userDefaults.bool(forKey: key)
    }
    
    /// 获取引导进度百分比
    var onboardingProgress: Double {
        let totalSteps = OnboardingStep.allCases.count
        let completedSteps = OnboardingStep.allCases.filter { isStepCompleted($0) }.count
        return Double(completedSteps) / Double(totalSteps)
    }
    
    // MARK: - 快捷操作配置
    
    /// 保存用户选择的快捷操作
    func saveQuickAction(_ action: QuickActionType, at index: Int) {
        let key = "quickAction_\(index)"
        userDefaults.set(action.rawValue, forKey: key)
    }
    
    /// 获取保存的快捷操作
    func getQuickAction(at index: Int) -> QuickActionType? {
        let key = "quickAction_\(index)"
        guard let rawValue = userDefaults.string(forKey: key) else { return nil }
        return QuickActionType(rawValue: rawValue)
    }
    
    // MARK: - 数据导出
    
    /// 导出引导数据（用于备份）
    func exportOnboardingData() -> OnboardingDataExport {
        OnboardingDataExport(
            hasCompleted: hasCompletedOnboarding,
            preferences: userPreferences,
            permissionsGranted: permissionsGranted,
            completedSteps: OnboardingStep.allCases.filter { isStepCompleted($0) }.map(\.rawValue),
            exportDate: Date()
        )
    }
    
    /// 导入引导数据（用于恢复）
    func importOnboardingData(_ data: OnboardingDataExport) {
        hasCompletedOnboarding = data.hasCompleted
        userPreferences = data.preferences
        permissionsGranted = data.permissionsGranted
        
        for stepRaw in data.completedSteps {
            if let step = OnboardingStep(rawValue: stepRaw) {
                trackStepCompletion(step)
            }
        }
    }
}

// MARK: - 权限结果

struct PermissionResult {
    var notificationsGranted: Bool = false
    
    var allGranted: Bool {
        notificationsGranted
    }
}

// MARK: - 引导步骤枚举

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case recordDream = 1
    case aiAnalysis = 2
    case insights = 3
    case timeCapsule = 4
    case privacy = 5
    case preferences = 6
    case permissions = 7
    case complete = 8
    
    var title: String {
        switch self {
        case .welcome: return "欢迎使用 DreamLog"
        case .recordDream: return "记录梦境"
        case .aiAnalysis: return "AI 解析"
        case .insights: return "智能洞察"
        case .timeCapsule: return "时间胶囊"
        case .privacy: return "隐私保护"
        case .preferences: return "个性化设置"
        case .permissions: return "权限设置"
        case .complete: return "完成"
        }
    }
    
    var icon: String {
        switch self {
        case .welcome: return "hand.wave"
        case .recordDream: return "moon.stars.fill"
        case .aiAnalysis: return "brain.head.profile"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .timeCapsule: return "clock.arrow.circlepath"
        case .privacy: return "lock.shield.fill"
        case .preferences: return "slider.horizontal.3"
        case .permissions: return "checkmark.shield.fill"
        case .complete: return "star.fill"
        }
    }
}

// MARK: - 导出数据模型

struct OnboardingDataExport: Codable {
    var hasCompleted: Bool
    var preferences: UserPreferences
    var permissionsGranted: Bool
    var completedSteps: [Int]
    var exportDate: Date
}

// MARK: - 用户偏好扩展

extension UserPreferences {
    /// 根据梦境类型推荐解析深度
    func recommendedDepth(for dreamType: String) -> AnalysisDepth {
        // 复杂的梦境类型推荐深度解析
        let complexTypes = ["清醒梦", "预知梦", "重复梦境", "噩梦"]
        if complexTypes.contains(dreamType) {
            return .deep
        }
        return analysisDepth
    }
    
    /// 获取提醒时间（DateComponents）
    var reminderTimeComponents: DateComponents {
        DateComponents(hour: reminderHour, minute: reminderMinute)
    }
    
    /// 获取提醒时间的显示文本
    var reminderTimeDisplay: String {
        String(format: "%02d:%02d", reminderHour, reminderMinute)
    }
}

// MARK: - 调试支持

#if DEBUG
extension DreamOnboardingService {
    /// 调试模式：快速完成引导
    func debugCompleteOnboarding() {
        completeOnboarding()
        permissionsGranted = true
        for step in OnboardingStep.allCases {
            trackStepCompletion(step)
        }
    }
    
    /// 调试模式：重置所有状态
    func debugResetAll() {
        resetOnboarding()
        userDefaults.removeObject(forKey: "onboardingCompleted")
    }
}
#endif
