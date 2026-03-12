//
//  DreamShareCardModels.swift
//  DreamLog
//
//  Phase 25 - Dream Sharing Cards & Social Templates
//  梦境分享卡片数据模型
//

import Foundation
import SwiftUI

// MARK: - 卡片类型枚举

/// 分享卡片类型
enum ShareCardType: String, CaseIterable, Identifiable {
    case minimalist = "minimalist"      // 简约风格
    case dreamy = "dreamy"              // 梦幻风格
    case artistic = "artistic"          // 艺术风格
    case social = "social"              // 社交媒体优化
    case story = "story"                // 故事卡片
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .minimalist: return "简约"
        case .dreamy: return "梦幻"
        case .artistic: return "艺术"
        case .social: return "社交"
        case .story: return "故事"
        }
    }
    
    var icon: String {
        switch self {
        case .minimalist: return "▭"
        case .dreamy: return "☁️"
        case .artistic: return "🎨"
        case .social: return "📱"
        case .story: return "📖"
        }
    }
    
    var description: String {
        switch self {
        case .minimalist: return "简洁优雅，突出内容"
        case .dreamy: return "星空渐变，梦幻氛围"
        case .artistic: return "艺术质感，独特风格"
        case .social: return "适配各平台，最佳展示"
        case .story: return "叙事风格，引人入胜"
        }
    }
}

// MARK: - 社交媒体平台

/// 社交媒体平台
enum SocialPlatform: String, CaseIterable, Identifiable {
    case wechat = "wechat"          // 微信朋友圈
    case weibo = "weibo"            // 微博
    case xiaohongshu = "xiaohongshu" // 小红书
    case instagram = "instagram"    // Instagram
    case twitter = "twitter"        // Twitter/X
    case qq = "qq"                  // QQ 空间
    case telegram = "telegram"      // Telegram
    case douban = "douban"          // 豆瓣
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .wechat: return "微信朋友圈"
        case .weibo: return "微博"
        case .xiaohongshu: return "小红书"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .qq: return "QQ 空间"
        case .telegram: return "Telegram"
        case .douban: return "豆瓣"
        }
    }
    
    var icon: String {
        switch self {
        case .wechat: return "💚"
        case .weibo: return "🔴"
        case .xiaohongshu: return "📕"
        case .instagram: return "📸"
        case .twitter: return "🐦"
        case .qq: return "🐧"
        case .telegram: return "✈️"
        case .douban: return "🟢"
        }
    }
    
    /// 推荐图片尺寸 (宽度 x 高度)
    var recommendedSize: CGSize {
        switch self {
        case .wechat: return CGSize(width: 1080, height: 1080)  // 正方形
        case .weibo: return CGSize(width: 1080, height: 1440)   // 竖版
        case .xiaohongshu: return CGSize(width: 1080, height: 1440) // 3:4
        case .instagram: return CGSize(width: 1080, height: 1350) // 4:5
        case .twitter: return CGSize(width: 1200, height: 675)  // 16:9
        case .qq: return CGSize(width: 1080, height: 1080)      // 正方形
        case .telegram: return CGSize(width: 1280, height: 720) // 16:9
        case .douban: return CGSize(width: 1080, height: 1080)  // 正方形
        }
    }
    
    /// 最大文字长度
    var maxTextLength: Int {
        switch self {
        case .wechat: return 500
        case .weibo: return 2000
        case .xiaohongshu: return 1000
        case .instagram: return 2200
        case .twitter: return 280
        case .qq: return 500
        case .telegram: return 4096
        case .douban: return 10000
        }
    }
}

// MARK: - 卡片配置

/// 分享卡片配置
struct ShareCardConfig: Codable, Equatable {
    var cardType: ShareCardType
    var platform: SocialPlatform
    var showDreamTitle: Bool
    var showDreamContent: Bool
    var showTags: Bool
    var showEmotions: Bool
    var showClarity: Bool
    var showDate: Bool
    var showAILogo: Bool
    var customQuote: String?
    var backgroundColor: String
    var textColor: String
    var fontName: String
    var fontSize: CGFloat
    
    init(
        cardType: ShareCardType = .dreamy,
        platform: SocialPlatform = .wechat,
        showDreamTitle: Bool = true,
        showDreamContent: Bool = true,
        showTags: Bool = true,
        showEmotions: Bool = true,
        showClarity: Bool = false,
        showDate: Bool = true,
        showAILogo: Bool = true,
        customQuote: String? = nil,
        backgroundColor: String = "auto",
        textColor: String = "auto",
        fontName: String = "PingFang SC",
        fontSize: CGFloat = 16
    ) {
        self.cardType = cardType
        self.platform = platform
        self.showDreamTitle = showDreamTitle
        self.showDreamContent = showDreamContent
        self.showTags = showTags
        self.showEmotions = showEmotions
        self.showClarity = showClarity
        self.showDate = showDate
        self.showAILogo = showAILogo
        self.customQuote = customQuote
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontName = fontName
        self.fontSize = fontSize
    }
}

// MARK: - 生成的卡片

/// 生成的分享卡片
struct GeneratedShareCard: Identifiable {
    let id: UUID
    let dreamId: UUID
    let config: ShareCardConfig
    let imageUrl: URL
    let createdAt: Date
    var shareCount: Int
    var platform: SocialPlatform?
    
    init(
        dreamId: UUID,
        config: ShareCardConfig,
        imageUrl: URL,
        createdAt: Date = Date(),
        shareCount: Int = 0,
        platform: SocialPlatform? = nil
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.config = config
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.shareCount = shareCount
        self.platform = platform
    }
}

// MARK: - 卡片模板

/// 卡片模板定义
struct CardTemplate: Identifiable {
    let id: String
    let name: String
    let nameEn: String
    let description: String
    let type: ShareCardType
    let gradientColors: [String]
    let backgroundImage: String?
    let textColor: String
    let accentColor: String
    let cornerRadius: CGFloat
    let padding: CGFloat
    let showDecorations: Bool
    let decorationElements: [String]
    
    static let templates: [CardTemplate] = [
        // 简约风格
        CardTemplate(
            id: "minimalist_clean",
            name: "纯净",
            nameEn: "Clean",
            description: "极简设计，突出内容",
            type: .minimalist,
            gradientColors: ["#FFFFFF", "#F5F5F7"],
            backgroundImage: nil,
            textColor: "#1D1D1F",
            accentColor: "#007AFF",
            cornerRadius: 16,
            padding: 32,
            showDecorations: false,
            decorationElements: []
        ),
        CardTemplate(
            id: "minimalist_elegant",
            name: "优雅",
            nameEn: "Elegant",
            description: "优雅灰调，专业质感",
            type: .minimalist,
            gradientColors: ["#F8F8F8", "#E8E8E8"],
            backgroundImage: nil,
            textColor: "#2C2C2E",
            accentColor: "#5E5CE6",
            cornerRadius: 20,
            padding: 40,
            showDecorations: true,
            decorationElements: ["line"]
        ),
        
        // 梦幻风格
        CardTemplate(
            id: "dreamy_starry",
            name: "星空",
            nameEn: "Starry Night",
            description: "深邃星空，梦幻氛围",
            type: .dreamy,
            gradientColors: ["#1a1a2e", "#16213e", "#0f3460"],
            backgroundImage: "stars",
            textColor: "#FFFFFF",
            accentColor: "#FFD700",
            cornerRadius: 24,
            padding: 32,
            showDecorations: true,
            decorationElements: ["stars", "moon", "sparkles"]
        ),
        CardTemplate(
            id: "dreamy_sunset",
            name: "日落",
            nameEn: "Sunset Dream",
            description: "温暖日落，浪漫唯美",
            type: .dreamy,
            gradientColors: ["#FF6B6B", "#FFA07A", "#FFDAB9"],
            backgroundImage: "clouds",
            textColor: "#FFFFFF",
            accentColor: "#FF8C42",
            cornerRadius: 24,
            padding: 32,
            showDecorations: true,
            decorationElements: ["clouds", "sun"]
        ),
        CardTemplate(
            id: "dreamy_ocean",
            name: "海洋",
            nameEn: "Ocean Dream",
            description: "深邃海洋，宁静致远",
            type: .dreamy,
            gradientColors: ["#0077B6", "#00B4D8", "#90E0EF"],
            backgroundImage: "waves",
            textColor: "#FFFFFF",
            accentColor: "#CAF0F8",
            cornerRadius: 24,
            padding: 32,
            showDecorations: true,
            decorationElements: ["waves", "bubbles"]
        ),
        
        // 艺术风格
        CardTemplate(
            id: "artistic_watercolor",
            name: "水彩",
            nameEn: "Watercolor",
            description: "水彩晕染，艺术气息",
            type: .artistic,
            gradientColors: ["#FFE5D9", "#FFCDB2", "#FFB4A2"],
            backgroundImage: "watercolor",
            textColor: "#5D4E60",
            accentColor: "#D4A5A5",
            cornerRadius: 8,
            padding: 36,
            showDecorations: true,
            decorationElements: ["brush_strokes", "splashes"]
        ),
        CardTemplate(
            id: "artistic_abstract",
            name: "抽象",
            nameEn: "Abstract",
            description: "抽象艺术，独特表达",
            type: .artistic,
            gradientColors: ["#6A0572", "#AB83A1", "#E8DFF5"],
            backgroundImage: "abstract",
            textColor: "#FFFFFF",
            accentColor: "#F9C74F",
            cornerRadius: 12,
            padding: 32,
            showDecorations: true,
            decorationElements: ["shapes", "lines"]
        ),
        
        // 社交媒体优化
        CardTemplate(
            id: "social_instagram",
            name: "Ins 风",
            nameEn: "Instagram",
            description: "适配 Instagram，时尚潮流",
            type: .social,
            gradientColors: ["#833AB4", "#FD1D1D", "#FCAF45"],
            backgroundImage: nil,
            textColor: "#FFFFFF",
            accentColor: "#FFFFFF",
            cornerRadius: 0,
            padding: 48,
            showDecorations: false,
            decorationElements: []
        ),
        CardTemplate(
            id: "social_xiaohongshu",
            name: "小红书",
            nameEn: "Xiaohongshu",
            description: "适配小红书，清新可爱",
            type: .social,
            gradientColors: ["#FF2442", "#FF6B7A", "#FFB3C1"],
            backgroundImage: nil,
            textColor: "#FFFFFF",
            accentColor: "#FFFFFF",
            cornerRadius: 16,
            padding: 32,
            showDecorations: true,
            decorationElements: ["hearts", "sparkles"]
        ),
        
        // 故事风格
        CardTemplate(
            id: "story_book",
            name: "故事书",
            nameEn: "Story Book",
            description: "复古书籍，叙事风格",
            type: .story,
            gradientColors: ["#F5E6D3", "#E8D5C4", "#D4C4B0"],
            backgroundImage: "paper",
            textColor: "#3D2914",
            accentColor: "#8B4513",
            cornerRadius: 4,
            padding: 40,
            showDecorations: true,
            decorationElements: ["border", "ornament"]
        ),
        CardTemplate(
            id: "story_modern",
            name: "现代故事",
            nameEn: "Modern Story",
            description: "现代排版，清晰易读",
            type: .story,
            gradientColors: ["#FFFFFF", "#F8F9FA"],
            backgroundImage: nil,
            textColor: "#212529",
            accentColor: "#0D6EFD",
            cornerRadius: 12,
            padding: 36,
            showDecorations: true,
            decorationElements: ["quote_marks"]
        )
    ]
    
    static func template(for type: ShareCardType) -> [CardTemplate] {
        templates.filter { $0.type == type }
    }
    
    static func template(id: String) -> CardTemplate? {
        templates.first { $0.id == id }
    }
}

// MARK: - 分享历史统计

/// 分享统计
struct ShareStatistics {
    var totalShares: Int
    var sharesByPlatform: [SocialPlatform: Int]
    var sharesByCardType: [ShareCardType: Int]
    var mostSharedDream: Dream?
    var averageSharesPerWeek: Double
    var favoriteTemplate: String?
    
    init(
        totalShares: Int = 0,
        sharesByPlatform: [SocialPlatform: Int] = [:],
        sharesByCardType: [ShareCardType: Int] = [:],
        mostSharedDream: Dream? = nil,
        averageSharesPerWeek: Double = 0,
        favoriteTemplate: String? = nil
    ) {
        self.totalShares = totalShares
        self.sharesByPlatform = sharesByPlatform
        self.sharesByCardType = sharesByCardType
        self.mostSharedDream = mostSharedDream
        self.averageSharesPerWeek = averageSharesPerWeek
        self.favoriteTemplate = favoriteTemplate
    }
}
