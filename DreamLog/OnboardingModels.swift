//
//  OnboardingModels.swift
//  DreamLog - 新手引导数据模型
//
//  Phase 87 - App Store 发布与高级功能
//  Created: 2026-03-23
//

import Foundation
import SwiftUI

// MARK: - 引导页面模型

/// 引导页面数据模型
struct OnboardingPage: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let features: [String]
    
    static let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "记录你的梦境",
            subtitle: "捕捉每一个奇幻的梦境瞬间",
            icon: "🌙",
            color: Color.purple.opacity(0.8),
            features: [
                "快速记录梦境细节",
                "语音输入解放双手",
                "智能标签自动分类",
                "支持添加图片和音频"
            ]
        ),
        OnboardingPage(
            title: "AI 智能解析",
            subtitle: "探索梦境背后的深层含义",
            icon: "🤖",
            color: Color.blue.opacity(0.8),
            features: [
                "AI 分析梦境象征意义",
                "识别情绪和主题模式",
                "提供个性化洞察",
                "发现潜意识信号"
            ]
        ),
        OnboardingPage(
            title: "追踪梦境模式",
            subtitle: "发现你的独特梦境规律",
            icon: "📊",
            color: Color.green.opacity(0.8),
            features: [
                "可视化数据统计",
                "识别重复出现的符号",
                "追踪情绪变化趋势",
                "生成月度/年度报告"
            ]
        ),
        OnboardingPage(
            title: "AI 艺术创作",
            subtitle: "将梦境转化为视觉艺术",
            icon: "🎨",
            color: Color.orange.opacity(0.8),
            features: [
                "AI 生成梦境艺术图",
                "多种艺术风格选择",
                "创建梦境艺术卡片",
                "与朋友分享创作"
            ]
        ),
        OnboardingPage(
            title: "云端同步",
            subtitle: "随时随地访问你的梦境",
            icon: "☁️",
            color: Color.cyan.opacity(0.8),
            features: [
                "iCloud 自动备份",
                "多设备无缝同步",
                "数据加密保护",
                "永不丢失珍贵记录"
            ]
        )
    ]
}

// MARK: - 权限类型

/// 需要请求的权限类型
enum PermissionType: String, CaseIterable {
    case notifications = "notifications"
    case health = "health"
    case speech = "speech"
    case photos = "photos"
    case location = "location"
    
    /// 权限标题
    var title: String {
        switch self {
        case .notifications: return "通知权限"
        case .health: return "健康数据"
        case .speech: return "语音识别"
        case .photos: return "照片访问"
        case .location: return "位置信息"
        }
    }
    
    /// 权限图标
    var icon: String {
        switch self {
        case .notifications: return "🔔"
        case .health: return "💚"
        case .speech: return "🎙️"
        case .photos: return "📷"
        case .location: return "📍"
        }
    }
    
    /// 权限描述
    var description: String {
        switch self {
        case .notifications:
            return "接收梦境提醒、睡眠提示和重要通知"
        case .health:
            return "分析睡眠质量与梦境的关联 (可选)"
        case .speech:
            return "使用语音输入快速记录梦境"
        case .photos:
            return "添加梦境截图和 related 图片"
        case .location:
            return "记录梦境发生地点，发现地理模式 (可选)"
        }
    }
    
    /// 是否必需
    var isRequired: Bool {
        switch self {
        case .notifications, .speech: return true
        case .health, .photos, .location: return false
        }
    }
    
    /// 权限益处
    var benefit: String {
        switch self {
        case .notifications: return "不错过任何重要提醒"
        case .health: return "更精准的健康洞察"
        case .speech: return "躺着也能记录梦境"
        case .photos: return "让梦境更生动"
        case .location: return "发现地点与梦境的关联"
        }
    }
}

// MARK: - 引导完成状态

/// 引导完成状态
struct OnboardingState: Codable {
    var isCompleted: Bool
    var completedDate: Date?
    var grantedPermissions: [String]
    var skippedPermissions: [String]
    var selectedInterests: [String]
    
    static let `default` = OnboardingState(
        isCompleted: false,
        completedDate: nil,
        grantedPermissions: [],
        skippedPermissions: [],
        selectedInterests: []
    )
}

// MARK: - 用户兴趣标签

/// 用户兴趣标签 (用于个性化推荐)
struct InterestTag: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let category: InterestCategory
    
    enum InterestCategory: String, CaseIterable {
        case dreamType = "梦境类型"
        case goal = "使用目标"
        case frequency = "记录频率"
        
        static let all: [InterestCategory] = [.dreamType, .goal, .frequency]
    }
    
    static let allTags: [InterestTag] = [
        // 梦境类型
        InterestTag(name: "清醒梦", icon: "😮", category: .dreamType),
        InterestTag(name: "预知梦", icon: "🔮", category: .dreamType),
        InterestTag(name: "美梦", icon: "😊", category: .dreamType),
        InterestTag(name: "噩梦", icon: "😱", category: .dreamType),
        InterestTag(name: "重复梦境", icon: "🔁", category: .dreamType),
        InterestTag(name: "创意梦境", icon: "🎨", category: .dreamType),
        
        // 使用目标
        InterestTag(name: "自我探索", icon: "🧘", category: .goal),
        InterestTag(name: "心理分析", icon: "🧠", category: .goal),
        InterestTag(name: "创意灵感", icon: "💡", category: .goal),
        InterestTag(name: "睡眠改善", icon: "😴", category: .goal),
        InterestTag(name: "记录回忆", icon: "📝", category: .goal),
        InterestTag(name: "纯粹好奇", icon: "🤔", category: .goal),
        
        // 记录频率
        InterestTag(name: "每天记录", icon: "📅", category: .frequency),
        InterestTag(name: "每周几次", icon: "📆", category: .frequency),
        InterestTag(name: "偶尔记录", icon: "⭐", category: .frequency),
        InterestTag(name: "特殊梦境", icon: "🌟", category: .frequency)
    ]
}
