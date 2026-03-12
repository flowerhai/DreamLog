//
//  DreamOnboardingModels.swift
//  DreamLog
//
//  Phase 25 - App Store 发布准备
//  新用户引导流程数据模型
//

import Foundation
import SwiftUI

// MARK: - Onboarding 页面模型

/// Onboarding 页面信息
struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
    let accentColor: Color
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "moon.stars.fill",
            title: "欢迎来到 DreamLog",
            description: "记录你的梦境，探索潜意识的秘密。每晚的梦境都是一次心灵的冒险。",
            accentColor: .purple
        ),
        OnboardingPage(
            image: "mic.fill",
            title: "语音快速记录",
            description: "醒来后只需按住说话，AI 自动整理你的梦境。30 秒完成记录，不再遗忘。",
            accentColor: .blue
        ),
        OnboardingPage(
            image: "brain.head.profile",
            title: "AI 智能解析",
            description: "基于心理学和象征学，AI 为你解读梦境背后的含义，发现隐藏的模式。",
            accentColor: .indigo
        ),
        OnboardingPage(
            image: "chart.bar.fill",
            title: "深度洞察分析",
            description: "可视化你的梦境数据，发现情绪趋势、重复主题和睡眠模式。",
            accentColor: .pink
        ),
        OnboardingPage(
            image: "glasses",
            title: "AR 梦境世界",
            description: "将梦境带入现实，在 AR 中与你的梦境元素互动，创建 3D 梦境场景。",
            accentColor: .orange
        )
    ]
}

// MARK: - 权限说明模型

/// 权限信息
struct PermissionInfo: Identifiable {
    let id = UUID()
    let type: PermissionType
    let title: String
    let description: String
    let icon: String
    let required: Bool
    
    enum PermissionType: String, CaseIterable {
        case microphone = "microphone"
        case notifications = "notifications"
        case health = "health"
        case photos = "photos"
        
        var displayName: String {
            switch self {
            case .microphone: return "麦克风"
            case .notifications: return "通知"
            case .health: return "健康 App"
            case .photos: return "照片"
            }
        }
    }
    
    static let allPermissions: [PermissionInfo] = [
        PermissionInfo(
            type: .microphone,
            title: "麦克风访问",
            description: "用于语音记录梦境。醒来后无需打字，直接说话即可快速记录。",
            icon: "mic.fill",
            required: true
        ),
        PermissionInfo(
            type: .notifications,
            title: "通知权限",
            description: "用于智能提醒功能。在你最佳记录时间提醒你，不错过任何梦境。",
            icon: "bell.fill",
            required: false
        ),
        PermissionInfo(
            type: .health,
            title: "健康数据",
            description: "读取睡眠数据，分析梦境与睡眠质量的关系。完全可选，保护隐私。",
            icon: "heart.fill",
            required: false
        ),
        PermissionInfo(
            type: .photos,
            title: "照片访问",
            description: "保存梦境图片和视频到相册，方便分享和收藏。",
            icon: "photo.on.rectangle.fill",
            required: false
        )
    ]
}

// MARK: - 订阅层级模型

/// 订阅层级
enum SubscriptionTier: String, CaseIterable, Identifiable {
    case free = "free"
    case premium = "premium"
    case lifetime = "lifetime"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .free: return "免费版"
        case .premium: return "高级版"
        case .lifetime: return "终身版"
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "star.fill"
        case .premium: return "star.circle.fill"
        case .lifetime: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .gray
        case .premium: return .purple
        case .lifetime: return .gold
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "无限梦境记录",
                "每日 3 次 AI 解析",
                "基础统计分析",
                "标签和情绪标记",
                "本地数据存储"
            ]
        case .premium:
            return [
                "无限 AI 解析",
                "高级数据洞察",
                "AR 梦境世界",
                "梦境视频导出",
                "iCloud 云同步",
                "智能提醒功能",
                "梦境冥想音效",
                "优先客户支持",
                "无广告体验"
            ]
        case .lifetime:
            return [
                "所有高级版功能",
                "终身免费更新",
                "抢先体验新功能",
                "专属客服通道",
                "个性化主题",
                "导出所有数据"
            ]
        }
    }
    
    var price: String {
        switch self {
        case .free: return "免费"
        case .premium: return "¥18/月 或 ¥168/年"
        case .lifetime: return "¥328 一次性"
        }
    }
    
    var productId: String {
        switch self {
        case .free: return ""
        case .premium: return "com.dreamlog.premium.monthly"
        case .lifetime: return "com.dreamlog.lifetime"
        }
    }
}

// MARK: - 功能对比项

/// 功能对比项
struct FeatureComparison: Identifiable {
    let id = UUID()
    let feature: String
    let free: Bool
    let premium: Bool
    
    static let comparisons: [FeatureComparison] = [
        FeatureComparison(feature: "梦境记录数量", free: true, premium: true),
        FeatureComparison(feature: "AI 解析次数", free: false, premium: true), // 免费每日 3 次
        FeatureComparison(feature: "数据统计", free: true, premium: true),
        FeatureComparison(feature: "高级洞察", free: false, premium: true),
        FeatureComparison(feature: "AR 梦境世界", free: false, premium: true),
        FeatureComparison(feature: "视频导出", free: false, premium: true),
        FeatureComparison(feature: "iCloud 同步", free: false, premium: true),
        FeatureComparison(feature: "智能提醒", free: false, premium: true),
        FeatureComparison(feature: "冥想音效", free: false, premium: true),
        FeatureComparison(feature: "无广告", free: false, premium: true)
    ]
}

// MARK: - 目标设置模型

/// 用户目标
struct UserGoal: Codable, Identifiable {
    let id = UUID()
    var goalType: GoalType
    var targetValue: Int
    var currentProgress: Int
    var startDate: Date
    var isActive: Bool
    
    enum GoalType: String, Codable, CaseIterable {
        case dreamsPerWeek = "dreamsPerWeek"
        case lucidDreams = "lucidDreams"
        case consecutiveDays = "consecutiveDays"
        case meditationMinutes = "meditationMinutes"
        
        var displayName: String {
            switch self {
            case .dreamsPerWeek: return "每周记录"
            case .lucidDreams: return "清醒梦目标"
            case .consecutiveDays: return "连续记录"
            case .meditationMinutes: return "冥想时长"
            }
        }
        
        var unit: String {
            switch self {
            case .dreamsPerWeek, .lucidDreams, .consecutiveDays: return "个"
            case .meditationMinutes: return "分钟"
            }
        }
        
        var icon: String {
            switch self {
            case .dreamsPerWeek: return "calendar"
            case .lucidDreams: return "brain.head.profile"
            case .consecutiveDays: return "flame.fill"
            case .meditationMinutes: return "timer"
            }
        }
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetValue), 1.0)
    }
    
    static let defaultGoals: [UserGoal] = [
        UserGoal(
            goalType: .dreamsPerWeek,
            targetValue: 3,
            currentProgress: 0,
            startDate: Date(),
            isActive: true
        ),
        UserGoal(
            goalType: .consecutiveDays,
            targetValue: 7,
            currentProgress: 0,
            startDate: Date(),
            isActive: true
        )
    ]
}

// MARK: - 示例梦境模型

/// 示例梦境（用于引导展示）
struct ExampleDream: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let tags: [String]
    let emotions: [String]
    let clarity: Int
    let isLucid: Bool
    
    static let examples: [ExampleDream] = [
        ExampleDream(
            title: "飞翔在城市上空",
            content: "我站在高楼顶端，突然身体变轻，缓缓飘向空中。俯瞰整个城市，灯火辉煌，车流如织。风从耳边吹过，感觉无比自由。",
            tags: ["飞行", "城市", "自由"],
            emotions: ["兴奋", "平静"],
            clarity: 4,
            isLucid: false
        ),
        ExampleDream(
            title: "迷失在森林中",
            content: "一片茂密的原始森林，阳光透过树叶洒下斑驳光影。我沿着小路走着，却发现自己一直在原地打转。周围传来鸟鸣和流水声。",
            tags: ["森林", "迷路", "自然"],
            emotions: ["困惑", "好奇"],
            clarity: 3,
            isLucid: false
        ),
        ExampleDream(
            title: " underwater 宫殿",
            content: "我潜入深海，发现一座发光的水晶宫殿。里面住着人鱼，她们邀请我参加晚宴。我能在水下自由呼吸，周围是五彩斑斓的珊瑚和鱼群。",
            tags: ["海洋", "奇幻", "人鱼"],
            emotions: ["惊奇", "快乐"],
            clarity: 5,
            isLucid: true
        )
    ]
}
