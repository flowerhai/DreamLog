//
//  DreamArtShareModels.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片
//  创建时间：2026-03-16
//

import Foundation
import SwiftData
import CoreGraphics

// MARK: - 分享卡片类型

/// 支持的分享卡片类型
enum ArtShareCardType: String, Codable, CaseIterable, Identifiable {
    case instagramStory = "instagramStory"
    case wechatMoment = "wechatMoment"
    case xiaohongshu = "xiaohongshu"
    case twitter = "twitter"
    case square = "square"
    case portrait = "portrait"
    case landscape = "landscape"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .instagramStory: return "Instagram 故事"
        case .wechatMoment: return "微信朋友圈"
        case .xiaohongshu: return "小红书"
        case .twitter: return "Twitter/X"
        case .square: return "正方形 (1:1)"
        case .portrait: return "竖版 (4:5)"
        case .landscape: return "横版 (16:9)"
        }
    }
    
    var aspectRatio: CGFloat {
        switch self {
        case .instagramStory: return 9.0 / 16.0
        case .wechatMoment: return 5.0 / 4.0
        case .xiaohongshu: return 3.0 / 4.0
        case .twitter: return 16.0 / 9.0
        case .square: return 1.0
        case .portrait: return 5.0 / 4.0
        case .landscape: return 16.0 / 9.0
        }
    }
    
    var size: CGSize {
        switch self {
        case .instagramStory: return CGSize(width: 1080, height: 1920)
        case .wechatMoment: return CGSize(width: 1200, height: 960)
        case .xiaohongshu: return CGSize(width: 1080, height: 1440)
        case .twitter: return CGSize(width: 1200, height: 675)
        case .square: return CGSize(width: 1080, height: 1080)
        case .portrait: return CGSize(width: 1080, height: 1350)
        case .landscape: return CGSize(width: 1920, height: 1080)
        }
    }
    
    var icon: String {
        switch self {
        case .instagramStory: return "📱"
        case .wechatMoment: return "💬"
        case .xiaohongshu: return "📕"
        case .twitter: return "🐦"
        case .square: return "⬜"
        case .portrait: return "📐"
        case .landscape: return "🖼️"
        }
    }
    
    var description: String {
        switch self {
        case .instagramStory: return "全屏竖版，适合 Instagram/抖音故事"
        case .wechatMoment: return "微信朋友圈优化尺寸"
        case .xiaohongshu: return "小红书笔记封面尺寸"
        case .twitter: return "Twitter/X 推文预览尺寸"
        case .square: return "通用正方形，适合 Instagram 帖子"
        case .portrait: return "竖版照片，适合 Instagram 人像"
        case .landscape: return "横版宽屏，适合 YouTube/视频封面"
        }
    }
}

// MARK: - 卡片模板

/// 分享卡片模板
@Model
final class ArtShareTemplate {
    var id: UUID
    var name: String
    var description: String
    var type: ArtShareCardType
    var category: TemplateCategory
    var isPreset: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // 样式配置
    var backgroundColor: String // Hex color
    var gradientStart: String? // Hex color
    var gradientEnd: String? // Hex color
    var textColor: String // Hex color
    var accentColor: String // Hex color
    
    // 字体配置
    var titleFont: String
    var titleSize: Double
    var contentFont: String
    var contentSize: Double
    
    // 布局配置
    var imagePosition: ImagePosition
    var showLogo: Bool
    var showDate: Bool
    var showTags: Bool
    var showEmotions: Bool
    var showAIAnalysis: Bool
    
    // 滤镜配置
    var imageFilter: ImageFilter
    var imageOpacity: Double
    var overlayPattern: OverlayPattern
    
    init(
        name: String,
        description: String,
        type: ArtShareCardType,
        category: TemplateCategory,
        isPreset: Bool = false,
        backgroundColor: String = "#1a1a2e",
        gradientStart: String? = nil,
        gradientEnd: String? = nil,
        textColor: String = "#ffffff",
        accentColor: String = "#ffd700",
        titleFont: String = "PingFang SC",
        titleSize: Double = 32,
        contentFont: String = "PingFang SC",
        contentSize: Double = 18,
        imagePosition: ImagePosition = .top,
        showLogo: Bool = true,
        showDate: Bool = true,
        showTags: Bool = true,
        showEmotions: Bool = true,
        showAIAnalysis: Bool = false,
        imageFilter: ImageFilter = .none,
        imageOpacity: Double = 1.0,
        overlayPattern: OverlayPattern = .none
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.type = type
        self.category = category
        self.isPreset = isPreset
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        
        self.backgroundColor = backgroundColor
        self.gradientStart = gradientStart
        self.gradientEnd = gradientEnd
        self.textColor = textColor
        self.accentColor = accentColor
        
        self.titleFont = titleFont
        self.titleSize = titleSize
        self.contentFont = contentFont
        self.contentSize = contentSize
        
        self.imagePosition = imagePosition
        self.showLogo = showLogo
        self.showDate = showDate
        self.showTags = showTags
        self.showEmotions = showEmotions
        self.showAIAnalysis = showAIAnalysis
        
        self.imageFilter = imageFilter
        self.imageOpacity = imageOpacity
        self.overlayPattern = overlayPattern
    }
}

// MARK: - 模板分类

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case minimalist = "minimalist"
    case artistic = "artistic"
    case dreamy = "dreamy"
    case modern = "modern"
    case vintage = "vintage"
    case nature = "nature"
    case custom = "custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .minimalist: return "极简风格"
        case .artistic: return "艺术风格"
        case .dreamy: return "梦幻风格"
        case .modern: return "现代风格"
        case .vintage: return "复古风格"
        case .nature: return "自然风格"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .minimalist: return "⚪"
        case .artistic: return "🎨"
        case .dreamy: return "✨"
        case .modern: return "🔷"
        case .vintage: return "📜"
        case .nature: return "🌿"
        case .custom: return "⚙️"
        }
    }
}

// MARK: - 图片位置

enum ImagePosition: String, Codable, CaseIterable {
    case top = "top"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    case center = "center"
    case background = "background"
    
    var displayName: String {
        switch self {
        case .top: return "顶部"
        case .bottom: return "底部"
        case .left: return "左侧"
        case .right: return "右侧"
        case .center: return "居中"
        case .background: return "背景"
        }
    }
}

// MARK: - 图片滤镜

enum ImageFilter: String, Codable, CaseIterable {
    case none = "none"
    case blur = "blur"
    case sepia = "sepia"
    case grayscale = "grayscale"
    case vintage = "vintage"
    case dreamy = "dreamy"
    case vibrant = "vibrant"
    case noir = "noir"
    case fade = "fade"
    case instant = "instant"
    
    var displayName: String {
        switch self {
        case .none: return "无"
        case .blur: return "模糊"
        case .sepia: return "复古"
        case .grayscale: return "黑白"
        case .vintage: return "怀旧"
        case .dreamy: return "梦幻"
        case .vibrant: return "鲜艳"
        case .noir: return "黑色电影"
        case .fade: return "褪色"
        case .instant: return "即时"
        }
    }
}

// MARK: - 覆盖图案

enum OverlayPattern: String, Codable, CaseIterable {
    case none = "none"
    case stars = "stars"
    case dots = "dots"
    case lines = "lines"
    case gradient = "gradient"
    case noise = "noise"
    
    var displayName: String {
        switch self {
        case .none: return "无"
        case .stars: return "星星"
        case .dots: return "圆点"
        case .lines: return "线条"
        case .gradient: return "渐变"
        case .noise: return "噪点"
        }
    }
}

// MARK: - 分享卡片数据

struct ArtShareCardData {
    let dreamId: UUID
    let dreamTitle: String
    let dreamContent: String
    let dreamDate: Date
    let tags: [String]
    let emotions: [String]
    let aiAnalysis: String?
    let aiImageUrl: String?
    let template: ArtShareTemplate
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日"
        return formatter.string(from: dreamDate)
    }
    
    var emotionIcons: String {
        let emotionMap: [String: String] = [
            "平静": "😌", "快乐": "😊", "焦虑": "😰",
            "恐惧": "😱", "困惑": "😕", "兴奋": "🤩",
            "悲伤": "😢", "愤怒": "😠", "惊讶": "😲", "中性": "😐"
        ]
        return emotions.compactMap { emotionMap[$0] }.joined()
    }
}

// MARK: - 分享历史

@Model
final class ArtShareHistory {
    var id: UUID
    var dreamId: UUID
    var dreamTitle: String
    var templateId: UUID
    var templateName: String
    var cardType: ArtShareCardType
    var platform: SharePlatform
    var imageUrl: String
    var fileSize: Int64
    var createdAt: Date
    var shareCount: Int
    
    init(
        dreamId: UUID,
        dreamTitle: String,
        templateId: UUID,
        templateName: String,
        cardType: ArtShareCardType,
        platform: SharePlatform,
        imageUrl: String,
        fileSize: Int64
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.dreamTitle = dreamTitle
        self.templateId = templateId
        self.templateName = templateName
        self.cardType = cardType
        self.platform = platform
        self.imageUrl = imageUrl
        self.fileSize = fileSize
        self.createdAt = Date()
        self.shareCount = 0
    }
}

// MARK: - 分享平台

enum SharePlatform: String, Codable, CaseIterable, Identifiable {
    case wechat = "wechat"
    case wechatMoment = "wechatMoment"
    case weibo = "weibo"
    case xiaohongshu = "xiaohongshu"
    case qq = "qq"
    case qzone = "qzone"
    case instagram = "instagram"
    case twitter = "twitter"
    case facebook = "facebook"
    case telegram = "telegram"
    case save = "save"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .wechat: return "微信好友"
        case .wechatMoment: return "朋友圈"
        case .weibo: return "微博"
        case .xiaohongshu: return "小红书"
        case .qq: return "QQ"
        case .qzone: return "QQ 空间"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter/X"
        case .facebook: return "Facebook"
        case .telegram: return "Telegram"
        case .save: return "保存到相册"
        }
    }
    
    var icon: String {
        switch self {
        case .wechat: return "💚"
        case .wechatMoment: return "💬"
        case .weibo: return "🧣"
        case .xiaohongshu: return "📕"
        case .qq: return "🐧"
        case .qzone: return "🌌"
        case .instagram: return "📸"
        case .twitter: return "🐦"
        case .facebook: return "📘"
        case .telegram: return "✈️"
        case .save: return "💾"
        }
    }
}

// MARK: - 预设模板

extension ArtShareTemplate {
    static let presetTemplates: [ArtShareTemplate] = [
        ArtShareTemplate(
            name: "星空梦境",
            description: "深邃星空背景，适合梦幻梦境",
            type: .instagramStory,
            category: .dreamy,
            isPreset: true,
            backgroundColor: "#0f0f23",
            gradientStart: "#1a1a3e",
            gradientEnd: "#0f0f23",
            textColor: "#ffffff",
            accentColor: "#ffd700",
            imagePosition: .background,
            imageOpacity: 0.6,
            overlayPattern: .stars
        ),
        ArtShareTemplate(
            name: "极简白",
            description: "简洁白色背景，突出文字内容",
            type: .square,
            category: .minimalist,
            isPreset: true,
            backgroundColor: "#ffffff",
            textColor: "#1a1a1a",
            accentColor: "#007aff",
            imagePosition: .top,
            showLogo: false,
            showDate: true,
            showTags: true,
            showEmotions: true
        ),
        ArtShareTemplate(
            name: "日落橙",
            description: "温暖日落渐变，适合温馨梦境",
            type: .portrait,
            category: .nature,
            isPreset: true,
            backgroundColor: "#ff6b35",
            gradientStart: "#ff8c42",
            gradientEnd: "#ff6b35",
            textColor: "#ffffff",
            accentColor: "#fff3e0",
            imagePosition: .center,
            imageFilter: .vibrant,
            overlayPattern: .gradient
        ),
        ArtShareTemplate(
            name: "复古胶片",
            description: "复古胶片风格，怀旧质感",
            type: .square,
            category: .vintage,
            isPreset: true,
            backgroundColor: "#2c2c2c",
            textColor: "#f5e6d3",
            accentColor: "#d4af37",
            imagePosition: .center,
            imageFilter: .vintage,
            imageOpacity: 0.8,
            overlayPattern: .noise
        ),
        ArtShareTemplate(
            name: "森林绿",
            description: "清新自然，适合自然主题梦境",
            type: .xiaohongshu,
            category: .nature,
            isPreset: true,
            backgroundColor: "#2d5016",
            gradientStart: "#3a6b1f",
            gradientEnd: "#2d5016",
            textColor: "#ffffff",
            accentColor: "#90ee90",
            imagePosition: .top,
            showTags: true,
            showEmotions: true
        ),
        ArtShareTemplate(
            name: "海洋蓝",
            description: "深邃海洋，适合神秘梦境",
            type: .instagramStory,
            category: .dreamy,
            isPreset: true,
            backgroundColor: "#001f3f",
            gradientStart: "#003366",
            gradientEnd: "#001f3f",
            textColor: "#ffffff",
            accentColor: "#7fdbff",
            imagePosition: .background,
            imageOpacity: 0.5,
            overlayPattern: .dots
        )
    ]
}
