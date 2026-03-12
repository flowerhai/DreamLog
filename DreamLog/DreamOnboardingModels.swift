//
//  DreamOnboardingModels.swift
//  DreamLog
//
//  新手引导数据模型
//  Phase 30 - App Store 发布准备 - 用户体验优化
//

import Foundation
import SwiftUI

// MARK: - 引导页面模型

/// 引导页面内容模型
struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [String]
    let illustration: String
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars.fill",
            iconColor: Color.purple,
            title: "记录你的每一个梦境",
            description: "捕捉潜意识的秘密，探索内心深处的世界",
            features: ["语音快速记录", "AI 智能解析", "情绪标签分类"],
            illustration: "dream.record"
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            iconColor: Color.blue,
            title: "AI 梦境解析",
            description: "荣格心理学 + 跨文化解梦，深度解析梦境含义",
            features: ["3 层梦境解析", "12 种梦境类型", "50+ 符号知识库"],
            illustration: "dream.analyze"
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            iconColor: Color.green,
            title: "智能洞察与趋势",
            description: "发现梦境模式，追踪心理健康趋势",
            features: ["情绪趋势分析", "主题模式识别", "心理健康评估"],
            illustration: "dream.insights"
        ),
        OnboardingPage(
            icon: "clock.arrow.circlepath",
            iconColor: Color.orange,
            title: "梦境时间胶囊",
            description: "给未来的自己发送梦境，跨越时空的对话",
            features: ["定时解锁", "加密保存", "惊喜提醒"],
            illustration: "dream.capsule"
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: Color.teal,
            title: "隐私安全保护",
            description: "本地加密存储，你的梦境只属于你",
            features: ["AES-256 加密", "Face ID 保护", "本地备份"],
            illustration: "dream.security"
        )
    ]
}

// MARK: - 用户偏好设置

/// 新用户偏好设置
struct UserPreferences: Codable {
    /// 是否首次启动
    var isFirstLaunch: Bool
    /// 是否完成引导
    var hasCompletedOnboarding: Bool
    /// 记录提醒启用状态
    var reminderEnabled: Bool
    /// 提醒时间（小时）
    var reminderHour: Int
    /// 提醒时间（分钟）
    var reminderMinute: Int
    /// 首选记录时间
    var preferredRecordingTime: RecordingTimePreference
    /// 梦境解析深度
    var analysisDepth: AnalysisDepth
    /// 隐私模式
    var privacyMode: PrivacyMode
    
    enum RecordingTimePreference: String, Codable, CaseIterable {
        case morning = "morning"      // 早晨
        case afternoon = "afternoon"  // 下午
        case evening = "evening"      // 晚上
        case night = "night"          // 深夜
        case flexible = "flexible"    // 灵活
        
        var displayText: String {
            switch self {
            case .morning: return "早晨 (6:00-12:00)"
            case .afternoon: return "下午 (12:00-18:00)"
            case .evening: return "晚上 (18:00-23:00)"
            case .night: return "深夜 (23:00-6:00)"
            case .flexible: return "灵活时间"
            }
        }
        
        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.fill"
            case .flexible: return "clock.fill"
            }
        }
    }
    
    enum AnalysisDepth: String, Codable, CaseIterable {
        case basic = "basic"          // 基础解析
        case standard = "standard"    // 标准解析
        case deep = "deep"            // 深度解析
        
        var displayText: String {
            switch self {
            case .basic: return "基础解析（快速概览）"
            case .standard: return "标准解析（推荐）"
            case .deep: return "深度解析（详细分析）"
            }
        }
    }
    
    enum PrivacyMode: String, Codable, CaseIterable {
        case normal = "normal"        // 正常模式
        case privateMode = "private"  // 隐私模式（隐藏内容）
        
        var displayText: String {
            switch self {
            case .normal: return "正常模式"
            case .privateMode: return "隐私模式"
            }
        }
    }
    
    static let `default` = UserPreferences(
        isFirstLaunch: true,
        hasCompletedOnboarding: false,
        reminderEnabled: true,
        reminderHour: 8,
        reminderMinute: 0,
        preferredRecordingTime: .morning,
        analysisDepth: .standard,
        privacyMode: .normal
    )
}

// MARK: - 引导状态

/// 引导流程状态
enum OnboardingState {
    case notStarted
    case inProgress(currentPage: Int)
    case completed
}

// MARK: - 快捷方式配置

/// 主屏幕快捷方式
struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let action: QuickActionType
}

enum QuickActionType: String, Codable {
    case recordDream = "record"
    case viewInsights = "insights"
    case dreamGallery = "gallery"
    case timeCapsule = "capsule"
    
    var destination: String {
        switch self {
        case .recordDream: return "dreamlog://record"
        case .viewInsights: return "dreamlog://insights"
        case .dreamGallery: return "dreamlog://gallery"
        case .timeCapsule: return "dreamlog://capsule"
        }
    }
}
