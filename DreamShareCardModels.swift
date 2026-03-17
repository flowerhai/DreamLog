//
//  DreamShareCardModels.swift
//  DreamLog
//
//  Phase 54 - Dream Share Cards (梦境分享卡片)
//  数据模型 - 支持 12 种卡片主题、自定义配置、多平台优化
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - 分享卡片数据模型

/// 分享卡片实体
@Model
final class DreamShareCard {
    var id: UUID
    var dreamId: UUID
    var templateId: String
    var theme: ShareCardTheme
    var customTitle: String?
    var customContent: String?
    var showTags: Bool
    var showEmotions: Bool
    var showDate: Bool
    var showWatermark: Bool
    var backgroundImage: Data?
    var generatedImageData: Data?
    var createdAt: Date
    var shareCount: Int
    var isFavorite: Bool
    
    init(
        dreamId: UUID,
        templateId: String = "default",
        theme: ShareCardTheme = .starry,
        customTitle: String? = nil,
        customContent: String? = nil,
        showTags: Bool = true,
        showEmotions: Bool = true,
        showDate: Bool = true,
        showWatermark: Bool = true,
        backgroundImage: Data? = nil,
        generatedImageData: Data? = nil
    ) {
        self.id = UUID()
        self.dreamId = dreamId
        self.templateId = templateId
        self.theme = theme
        self.customTitle = customTitle
        self.customContent = customContent
        self.showTags = showTags
        self.showEmotions = showEmotions
        self.showDate = showDate
        self.showWatermark = showWatermark
        self.backgroundImage = backgroundImage
        self.generatedImageData = generatedImageData
        self.createdAt = Date()
        self.shareCount = 0
        self.isFavorite = false
    }
}

// MARK: - 卡片主题枚举

/// 分享卡片主题 (12 种)
enum ShareCardTheme: String, CaseIterable, Identifiable, Codable {
    case starry = "starry"          // 星空紫
    case sunset = "sunset"          // 日落橙
    case ocean = "ocean"            // 海洋蓝
    case forest = "forest"          // 森林绿
    case midnight = "midnight"      // 午夜黑
    case rose = "rose"              // 玫瑰粉
    case gold = "gold"              // 奢华金
    case lavender = "lavender"      // 薰衣草紫
    case aurora = "aurora"          // 极光绿
    case crystal = "crystal"        // 水晶蓝
    case minimal = "minimal"        // 极简白
    case custom = "custom"          // 自定义
    
    var id: String { rawValue }
    
    /// 主题显示名称
    var displayName: String {
        switch self {
        case .starry: return "星空紫"
        case .sunset: return "日落橙"
        case .ocean: return "海洋蓝"
        case .forest: return "森林绿"
        case .midnight: return "午夜黑"
        case .rose: return "玫瑰粉"
        case .gold: return "奢华金"
        case .lavender: return "薰衣草"
        case .aurora: return "极光绿"
        case .crystal: return "水晶蓝"
        case .minimal: return "极简白"
        case .custom: return "自定义"
        }
    }
    
    /// 主题图标
    var icon: String {
        switch self {
        case .starry: return "🌙"
        case .sunset: return "🌅"
        case .ocean: return "🌊"
        case .forest: return "🌲"
        case .midnight: return "🌑"
        case .rose: return "🌹"
        case .gold: return "✨"
        case .lavender: return "💜"
        case .aurora: return "🌌"
        case .crystal: return "💎"
        case .minimal: return "⚪"
        case .custom: return "🎨"
        }
    }
    
    /// 渐变颜色配置
    var gradientColors: [Color] {
        switch self {
        case .starry:
            return [Color(hex: "1a1a3e"), Color(hex: "4a1c6e"), Color(hex: "6b2d8f")]
        case .sunset:
            return [Color(hex: "ff6b35"), Color(hex: "f7c548"), Color(hex: "ff9a3c")]
        case .ocean:
            return [Color(hex: "006994"), Color(hex: "40a4df"), Color(hex: "7ec8e3")]
        case .forest:
            return [Color(hex: "134e13"), Color(hex: "2d6e32"), Color(hex: "4a8c4a")]
        case .midnight:
            return [Color(hex: "000000"), Color(hex: "1a1a2e"), Color(hex: "16213e")]
        case .rose:
            return [Color(hex: "ff69b4"), Color(hex: "ffb6c1"), Color(hex: "ffc0cb")]
        case .gold:
            return [Color(hex: "ffd700"), Color(hex: "ffec8b"), Color(hex: "fff8dc")]
        case .lavender:
            return [Color(hex: "967bb6"), Color(hex: "b19cd9"), Color(hex: "d8bfd8")]
        case .aurora:
            return [Color(hex: "00ff87"), Color(hex: "60efff"), Color(hex: "00bcd4")]
        case .crystal:
            return [Color(hex: "7b68ee"), Color(hex: "87cefa"), Color(hex: "e0ffff")]
        case .minimal:
            return [Color(hex: "f5f5f5"), Color(hex: "ffffff"), Color(hex: "f8f8f8")]
        case .custom:
            return [Color(hex: "667eea"), Color(hex: "764ba2"), Color(hex: "a855f7")]
        }
    }
    
    /// 文字颜色 (根据背景自动选择)
    var textColor: Color {
        switch self {
        case .midnight, .starry, .forest, .ocean:
            return .white
        case .minimal:
            return .black
        default:
            return .white
        }
    }
    
    /// 装饰元素
    var decorations: [String] {
        switch self {
        case .starry: return ["⭐", "✨", "💫", "🌟"]
        case .sunset: return ["☁️", "🌤️", "🧡"]
        case .ocean: return ["🌊", "💧", "🐚", "⭐"]
        case .forest: return ["🌲", "🌿", "🍃", "🦋"]
        case .midnight: return ["🌑", "⭐", "🌌"]
        case .rose: return ["🌹", "💕", "💖", "✨"]
        case .gold: return ["✨", "⭐", "💫", "🌟"]
        case .lavender: return ["💜", "🌸", "✨", "🦋"]
        case .aurora: return ["🌌", "⭐", "✨", "💫"]
        case .crystal: return ["💎", "✨", "❄️", "⭐"]
        case .minimal: return []
        case .custom: return ["✨", "⭐", "💫"]
        }
    }
}

// MARK: - 卡片模板

/// 分享卡片模板
struct ShareCardTemplate: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var theme: ShareCardTheme
    var layout: CardLayout
    var showDreamImage: Bool
    var showAIAnalysis: Bool
    var showQRCode: Bool
    var fontScheme: FontScheme
    var isPreset: Bool
    var isFavorite: Bool
    
    init(
        id: String,
        name: String,
        description: String,
        theme: ShareCardTheme,
        layout: CardLayout = .standard,
        showDreamImage: Bool = true,
        showAIAnalysis: Bool = false,
        showQRCode: Bool = false,
        fontScheme: FontScheme = .modern,
        isPreset: Bool = true,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.theme = theme
        self.layout = layout
        self.showDreamImage = showDreamImage
        self.showAIAnalysis = showAIAnalysis
        self.showQRCode = showQRCode
        self.fontScheme = fontScheme
        self.isPreset = isPreset
        self.isFavorite = isFavorite
    }
    
    /// 预设模板
    static let presets: [ShareCardTemplate] = [
        ShareCardTemplate(
            id: "elegant",
            name: "优雅经典",
            description: "经典布局，适合正式分享",
            theme: .starry,
            layout: .standard,
            showDreamImage: true,
            showAIAnalysis: true
        ),
        ShareCardTemplate(
            id: "minimal",
            name: "极简主义",
            description: "简洁干净，突出内容",
            theme: .minimal,
            layout: .minimal,
            showDreamImage: false,
            showAIAnalysis: false
        ),
        ShareCardTemplate(
            id: "artistic",
            name: "艺术风格",
            description: "创意布局，视觉冲击",
            theme: .aurora,
            layout: .artistic,
            showDreamImage: true,
            showAIAnalysis: true
        ),
        ShareCardTemplate(
            id: "social",
            name: "社交分享",
            description: "适配社交媒体尺寸",
            theme: .sunset,
            layout: .social,
            showDreamImage: true,
            showQRCode: true
        ),
        ShareCardTemplate(
            id: "dreamy",
            name: "梦幻风格",
            description: "浪漫梦幻，适合美梦",
            theme: .rose,
            layout: .standard,
            showDreamImage: true,
            showAIAnalysis: false
        ),
        ShareCardTemplate(
            id: "mysterious",
            name: "神秘深邃",
            description: "深色主题，适合神秘梦境",
            theme: .midnight,
            layout: .standard,
            showDreamImage: true,
            showAIAnalysis: true
        )
    ]
}

// MARK: - 卡片布局枚举

/// 卡片布局类型
enum CardLayout: String, CaseIterable, Codable {
    case standard = "standard"      // 标准布局
    case minimal = "minimal"        // 极简布局
    case artistic = "artistic"      // 艺术布局
    case social = "social"          // 社交布局 (1:1)
    case story = "story"            // 故事布局 (9:16)
    
    var displayName: String {
        switch self {
        case .standard: return "标准"
        case .minimal: return "极简"
        case .artistic: return "艺术"
        case .social: return "社交"
        case .story: return "故事"
        }
    }
    
    /// 宽高比
    var aspectRatio: CGFloat {
        switch self {
        case .standard: return 4.0 / 5.0
        case .minimal: return 1.0
        case .artistic: return 4.0 / 5.0
        case .social: return 1.0
        case .story: return 9.0 / 16.0
        }
    }
}

// MARK: - 字体方案

/// 字体方案
enum FontScheme: String, CaseIterable, Codable {
    case modern = "modern"          // 现代
    case classic = "classic"        // 经典
    case elegant = "elegant"        // 优雅
    case playful = "playful"        // 活泼
    
    var displayName: String {
        switch self {
        case .modern: return "现代"
        case .classic: return "经典"
        case .elegant: return "优雅"
        case .playful: return "活泼"
        }
    }
}

// MARK: - 分享平台配置

/// 分享平台配置
struct SharePlatformConfig: Codable {
    var platform: SharePlatform
    var optimizedSize: CGSize
    var maxFileSize: Int
    var supportsVideo: Bool
    var supportsQRCode: Bool
    
    enum SharePlatform: String, CaseIterable, Codable {
        case wechat = "wechat"          // 微信朋友圈
        case wechatMoment = "wechatMoment" // 微信公众号
        case xiaohongshu = "xiaohongshu" // 小红书
        case weibo = "weibo"            // 微博
        case instagram = "instagram"    // Instagram
        case twitter = "twitter"        // Twitter/X
        case qq = "qq"                  // QQ 空间
        case telegram = "telegram"      // Telegram
        case custom = "custom"          // 自定义
        
        var displayName: String {
            switch self {
            case .wechat: return "微信朋友圈"
            case .wechatMoment: return "微信公众号"
            case .xiaohongshu: return "小红书"
            case .weibo: return "微博"
            case .instagram: return "Instagram"
            case .twitter: return "Twitter/X"
            case .qq: return "QQ 空间"
            case .telegram: return "Telegram"
            case .custom: return "自定义"
            }
        }
        
        var icon: String {
            switch self {
            case .wechat: return "💚"
            case .wechatMoment: return "📱"
            case .xiaohongshu: return "📕"
            case .weibo: return "🧣"
            case .instagram: return "📸"
            case .twitter: return "🐦"
            case .qq: return "🐧"
            case .telegram: return "✈️"
            case .custom: return "🔗"
            }
        }
        
        /// 推荐尺寸
        var recommendedSize: CGSize {
            switch self {
            case .wechat: return CGSize(width: 1080, height: 1350)
            case .wechatMoment: return CGSize(width: 1080, height: 1920)
            case .xiaohongshu: return CGSize(width: 1080, height: 1440)
            case .weibo: return CGSize(width: 1080, height: 1080)
            case .instagram: return CGSize(width: 1080, height: 1080)
            case .twitter: return CGSize(width: 1200, height: 675)
            case .qq: return CGSize(width: 1080, height: 1080)
            case .telegram: return CGSize(width: 1080, height: 1080)
            case .custom: return CGSize(width: 1080, height: 1350)
            }
        }
    }
}

// MARK: - 分享统计

/// 分享统计数据
struct ShareCardStats: Codable {
    var totalCards: Int
    var totalShares: Int
    var favoriteCards: Int
    var mostUsedTheme: ShareCardTheme?
    var cardsByTheme: [String: Int]
    var cardsByPlatform: [String: Int]
    var recentShares: [ShareRecord]
    
    struct ShareRecord: Codable {
        var cardId: UUID
        var platform: String
        var timestamp: Date
    }
    
    static let empty = ShareCardStats(
        totalCards: 0,
        totalShares: 0,
        favoriteCards: 0,
        mostUsedTheme: nil,
        cardsByTheme: [:],
        cardsByPlatform: [:],
        recentShares: []
    )
}

// MARK: - 辅助扩展

extension Color {
    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
