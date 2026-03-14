//
//  DreamShareHubModels.swift
//  DreamLog - 梦境分享中心数据模型
//
//  Created by DreamLog Team on 2026-03-14.
//  Phase 36: Dream Share Hub - 一键多平台分享中心
//

import Foundation
import SwiftData

// MARK: - 分享平台枚举

/// 支持的分享平台
enum SharePlatform: String, Codable, CaseIterable, Identifiable {
    case wechat = "wechat"           // 微信好友
    case wechatMoments = "wechat_moments"  // 朋友圈
    case weibo = "weibo"             // 微博
    case xiaohongshu = "xiaohongshu" // 小红书
    case qq = "qq"                   // QQ
    case telegram = "telegram"       // Telegram
    case instagram = "instagram"     // Instagram
    case twitter = "twitter"         // Twitter/X
    case facebook = "facebook"       // Facebook
    case copy = "copy"               // 复制链接
    case image = "image"             // 保存图片
    
    var id: String { rawValue }
    
    /// 平台显示名称
    var displayName: String {
        switch self {
        case .wechat: return "微信好友"
        case .wechatMoments: return "朋友圈"
        case .weibo: return "微博"
        case .xiaohongshu: return "小红书"
        case .qq: return "QQ"
        case .telegram: return "Telegram"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .facebook: return "Facebook"
        case .copy: return "复制链接"
        case .image: return "保存图片"
        }
    }
    
    /// 平台图标 (SF Symbol)
    var iconName: String {
        switch self {
        case .wechat: return "message.fill"
        case .wechatMoments: return "bubble.left.and.bubble.right.fill"
        case .weibo: return "square.grid.2x2.fill"
        case .xiaohongshu: return "book.fill"
        case .qq: return "quote.bubble.fill"
        case .telegram: return "paperplane.fill"
        case .instagram: return "camera.fill"
        case .twitter: return "x.circle.fill"
        case .facebook: return "f.circle.fill"
        case .copy: return "doc.on.doc.fill"
        case .image: return "photo.fill"
        }
    }
    
    /// 平台品牌色
    var brandColor: String {
        switch self {
        case .wechat: return "07C160"
        case .wechatMoments: return "07C160"
        case .weibo: return "E6162D"
        case .xiaohongshu: return "FF2442"
        case .qq: return "12B7F5"
        case .telegram: return "0088CC"
        case .instagram: return "E4405F"
        case .twitter: return "000000"
        case .facebook: return "1877F2"
        case .copy: return "8E8E93"
        case .image: return "007AFF"
        }
    }
    
    /// URL Scheme (用于直接跳转)
    var urlScheme: String? {
        switch self {
        case .wechat: return "weixin://"
        case .wechatMoments: return "weixin://"
        case .weibo: return "sinaweibo://"
        case .xiaohongshu: return "xhsdiscover://"
        case .qq: return "mqq://"
        case .telegram: return "tg://"
        case .instagram: return "instagram://"
        case .twitter: return "twitter://"
        case .facebook: return "facebook://"
        case .copy, .image: return nil
        }
    }
    
    /// 是否支持直接分享
    var supportsDirectShare: Bool {
        switch self {
        case .copy, .image: return true
        default: return false
        }
    }
}

// MARK: - 分享配置模型

/// 分享配置 - 用户预设的分享偏好
@Model
final class ShareConfig {
    var id: UUID
    var name: String                          // 配置名称 (如：默认配置、工作分享等)
    var selectedPlatforms: [String]           // 选中的平台 ID
    var defaultTemplate: String               // 默认模板 ID
    var autoAddHashtags: Bool                 // 自动添加标签
    var autoAddEmotions: Bool                 // 自动添加情绪
    var includeAIAnalysis: Bool               // 包含 AI 解析
    var includeDreamImage: Bool               // 包含梦境图片
    var customMessage: String?                // 自定义消息
    var isDefault: Bool                       // 是否为默认配置
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String = "默认配置",
        selectedPlatforms: [String] = [],
        defaultTemplate: String = "starry",
        autoAddHashtags: Bool = true,
        autoAddEmotions: Bool = true,
        includeAIAnalysis: Bool = false,
        includeDreamImage: Bool = true,
        customMessage: String? = nil,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.selectedPlatforms = selectedPlatforms
        self.defaultTemplate = defaultTemplate
        self.autoAddHashtags = autoAddHashtags
        self.autoAddEmotions = autoAddEmotions
        self.includeAIAnalysis = includeAIAnalysis
        self.includeDreamImage = includeDreamImage
        self.customMessage = customMessage
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - 分享历史记录

/// 分享历史记录
@Model
final class ShareHistory {
    var id: UUID
    var dreamId: UUID                         // 梦境 ID
    var dreamTitle: String                    // 梦境标题 (快照)
    var platforms: [String]                   // 分享的平台
    var template: String                      // 使用的模板
    var successCount: Int                     // 成功数量
    var failCount: Int                        // 失败数量
    var shareMessage: String?                 // 分享消息
    var createdAt: Date
    var metadata: [String: String]?           // 额外元数据
    
    init(
        dreamId: UUID,
        dreamTitle: String,
        platforms: [String],
        template: String,
        shareMessage: String? = nil
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.dreamTitle = dreamTitle
        self.platforms = platforms
        self.template = template
        self.successCount = 0
        self.failCount = 0
        self.shareMessage = shareMessage
        self.createdAt = Date()
        self.metadata = nil
    }
}

// MARK: - 分享模板

/// 分享卡片模板
enum ShareTemplate: String, Codable, CaseIterable, Identifiable {
    case starry = "starry"       // 星空
    case sunset = "sunset"       // 日落
    case ocean = "ocean"         // 海洋
    case forest = "forest"       // 森林
    case minimal = "minimal"     // 极简
    case artistic = "artistic"   // 艺术
    
    var id: String { rawValue }
    
    /// 模板显示名称
    var displayName: String {
        switch self {
        case .starry: return "星空"
        case .sunset: return "日落"
        case .ocean: return "海洋"
        case .forest: return "森林"
        case .minimal: return "极简"
        case .artistic: return "艺术"
        }
    }
    
    /// 模板描述
    var description: String {
        switch self {
        case .starry: return "深邃星空背景，适合神秘梦境"
        case .sunset: return "温暖日落色调，适合温馨梦境"
        case .ocean: return "宁静海洋蓝色，适合平静梦境"
        case .forest: return "自然森林绿色，适合成长梦境"
        case .minimal: return "简洁黑白设计，适合所有梦境"
        case .artistic: return "艺术渐变效果，适合创意梦境"
        }
    }
}

// MARK: - 分享统计

/// 分享统计数据
struct ShareStats {
    var totalShares: Int          // 总分享次数
    var totalPlatforms: Int       // 使用过的平台数
    var favoritePlatform: String? // 最常用平台
    var thisWeekShares: Int       // 本周分享次数
    var thisMonthShares: Int      // 本月分享次数
    var favoriteTemplate: String? // 最常用模板
    
    static var empty: ShareStats {
        ShareStats(
            totalShares: 0,
            totalPlatforms: 0,
            favoritePlatform: nil,
            thisWeekShares: 0,
            thisMonthShares: 0,
            favoriteTemplate: nil
        )
    }
}

// MARK: - 分享任务结果

/// 单次分享任务结果
struct ShareTaskResult: Identifiable {
    let id: UUID
    let platform: SharePlatform
    let success: Bool
    let errorMessage: String?
    let timestamp: Date
    
    init(platform: SharePlatform, success: Bool, errorMessage: String? = nil) {
        self.id = UUID()
        self.platform = platform
        self.success = success
        self.errorMessage = errorMessage
        self.timestamp = Date()
    }
}

// MARK: - 批量分享结果

/// 批量分享结果
struct BatchShareResult {
    let dreamId: UUID
    let totalPlatforms: Int
    let successCount: Int
    let failCount: Int
    let results: [ShareTaskResult]
    let shareHistoryId: UUID?
    
    var successRate: Double {
        guard totalPlatforms > 0 else { return 0 }
        return Double(successCount) / Double(totalPlatforms) * 100
    }
    
    var allSuccess: Bool {
        failCount == 0
    }
}
