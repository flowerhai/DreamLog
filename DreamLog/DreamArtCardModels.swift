//
//  DreamArtCardModels.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片
//  梦境艺术卡片数据模型
//

import Foundation
import SwiftUI
import UIKit

// MARK: - 艺术卡片风格

/// 艺术卡片风格枚举 (12 种风格)
enum ArtCardStyle: String, CaseIterable, Identifiable {
    case starry = "starry"          // 星空
    case sunrise = "sunrise"        // 日出
    case ocean = "ocean"            // 海洋
    case forest = "forest"          // 森林
    case sakura = "sakura"          // 樱花
    case crystal = "crystal"        // 水晶
    case drama = "drama"            // 戏剧
    case abstract = "abstract"      // 抽象
    case classic = "classic"        // 古风
    case minimal = "minimal"        // 极简
    case dreamy = "dreamy"          // 梦幻
    case pop = "pop"                // 波普
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .starry: return "星空"
        case .sunrise: return "日出"
        case .ocean: return "海洋"
        case .forest: return "森林"
        case .sakura: return "樱花"
        case .crystal: return "水晶"
        case .drama: return "戏剧"
        case .abstract: return "抽象"
        case .classic: return "古风"
        case .minimal: return "极简"
        case .dreamy: return "梦幻"
        case .pop: return "波普"
        }
    }
    
    var icon: String {
        switch self {
        case .starry: return "🌌"
        case .sunrise: return "🌅"
        case .ocean: return "🌊"
        case .forest: return "🌲"
        case .sakura: return "🌸"
        case .crystal: return "🔮"
        case .drama: return "🎭"
        case .abstract: return "🎨"
        case .classic: return "📜"
        case .minimal: return "✨"
        case .dreamy: return "💭"
        case .pop: return "🎪"
        }
    }
    
    var description: String {
        switch self {
        case .starry: return "深蓝紫渐变，星星点缀，适合神秘梦境"
        case .sunrise: return "橙红渐变，充满希望，适合积极梦境"
        case .ocean: return "蓝色渐变，平静深邃，适合水相关梦境"
        case .forest: return "绿色渐变，自然清新，适合自然主题"
        case .sakura: return "粉色渐变，浪漫温柔，适合美好回忆"
        case .crystal: return "透明渐变，光斑闪烁，适合梦幻场景"
        case .drama: return "高对比阴影，戏剧张力，适合强烈情绪"
        case .abstract: return "多彩几何，艺术抽象，适合超现实梦境"
        case .classic: return "中国传统风格，古典雅致，适合文化主题"
        case .minimal: return "简洁留白，突出内容，适合文字为主"
        case .dreamy: return "柔和光晕，朦胧美感，适合梦幻氛围"
        case .pop: return "鲜艳色彩，波普艺术，适合活泼梦境"
        }
    }
    
    /// 主色调
    var primaryColors: [Color] {
        switch self {
        case .starry: return [Color("deepPurple"), Color("midnightBlue"), Color("indigo")]
        case .sunrise: return [Color("orange"), Color("pink"), Color("purple")]
        case .ocean: return [Color("deepBlue"), Color("turquoise"), Color("cyan")]
        case .forest: return [Color("forestGreen"), Color("emerald"), Color("lime")]
        case .sakura: return [Color("lightPink"), Color("pink"), Color("white")]
        case .crystal: return [Color("clear"), Color("lightBlue"), Color("white")]
        case .drama: return [Color("black"), Color("darkRed"), Color("gold")]
        case .abstract: return [Color("red"), Color("blue"), Color("yellow"), Color("green")]
        case .classic: return [Color("ricePaper"), Color("inkBlack"), Color("cinnabar")]
        case .minimal: return [Color("white"), Color("lightGray"), Color("black")]
        case .dreamy: return [Color("lavender"), Color("lightPurple"), Color("pink")]
        case .pop: return [Color("hotPink"), Color("cyan"), Color("yellow"), Color("magenta")]
        }
    }
    
    /// 渐变类型
    var gradientType: GradientType {
        switch self {
        case .starry, .ocean, .forest, .drama: return .linear(angle: 45)
        case .sunrise, .sakura, .dreamy: return .vertical
        case .crystal, .classic: return .radial
        case .abstract, .pop: return .diagonal
        case .minimal: return .horizontal
        }
    }
    
    /// 装饰元素
    var defaultDecorations: [DecorationType] {
        switch self {
        case .starry: return [.stars, .shootingStars]
        case .sunrise: return [.sunRays, .clouds]
        case .ocean: return [.waves, .bubbles]
        case .forest: return [.leaves, .fireflies]
        case .sakura: return [.petals, .sparkles]
        case .crystal: return [.lightSpots, .prism]
        case .drama: return [.shadows, .spotlight]
        case .abstract: return [.geometricShapes, .splashes]
        case .classic: return [.clouds, .mountains, .seal]
        case .minimal: return []
        case .dreamy: return [.softGlow, .blur]
        case .pop: return [.dots, .stripes, .stars]
        }
    }
    
    /// 推荐情绪匹配
    var recommendedEmotions: [Emotion] {
        switch self {
        case .starry: return [.平静，.困惑，.中性]
        case .sunrise: return [.快乐，.兴奋]
        case .ocean: return [.平静，.悲伤]
        case .forest: return [.平静，.快乐]
        case .sakura: return [.快乐，.平静]
        case .crystal: return [.惊讶，.兴奋]
        case .drama: return [.恐惧，.愤怒，.悲伤]
        case .abstract: return [.困惑，.惊讶]
        case .classic: return [.平静，.中性]
        case .minimal: return [.平静，.中性]
        case .dreamy: return [.平静，.困惑]
        case .pop: return [.快乐，.兴奋]
        }
    }
}

// MARK: - 渐变类型

enum GradientType {
    case linear(angle: CGFloat)
    case vertical
    case horizontal
    case radial
    case diagonal
    
    var startPoint: UnitPoint {
        switch self {
        case .linear(let angle):
            return UnitPoint(x: CGFloat(cos(angle * .pi / 180)), y: CGFloat(sin(angle * .pi / 180)))
        case .vertical: return .top
        case .horizontal: return .leading
        case .radial: return .center
        case .diagonal: return .topLeading
        }
    }
    
    var endPoint: UnitPoint {
        switch self {
        case .linear(let angle):
            return UnitPoint(x: CGFloat(-cos(angle * .pi / 180)), y: CGFloat(-sin(angle * .pi / 180)))
        case .vertical: return .bottom
        case .horizontal: return .trailing
        case .radial: return .center
        case .diagonal: return .bottomTrailing
        }
    }
}

// MARK: - 装饰元素类型

enum DecorationType: String, CaseIterable, Identifiable {
    case stars = "stars"
    case shootingStars = "shootingStars"
    case sunRays = "sunRays"
    case clouds = "clouds"
    case waves = "waves"
    case bubbles = "bubbles"
    case leaves = "leaves"
    case fireflies = "fireflies"
    case petals = "petals"
    case sparkles = "sparkles"
    case lightSpots = "lightSpots"
    case prism = "prism"
    case shadows = "shadows"
    case spotlight = "spotlight"
    case geometricShapes = "geometricShapes"
    case splashes = "splashes"
    case mountains = "mountains"
    case seal = "seal"
    case softGlow = "softGlow"
    case blur = "blur"
    case dots = "dots"
    case stripes = "stripes"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .stars: return "星星"
        case .shootingStars: return "流星"
        case .sunRays: return "阳光"
        case .clouds: return "云朵"
        case .waves: return "波浪"
        case .bubbles: return "气泡"
        case .leaves: return "树叶"
        case .fireflies: return "萤火虫"
        case .petals: return "花瓣"
        case .sparkles: return "闪光"
        case .lightSpots: return "光斑"
        case .prism: return "棱镜"
        case .shadows: return "阴影"
        case .spotlight: return "聚光灯"
        case .geometricShapes: return "几何图形"
        case .splashes: return "泼溅"
        case .mountains: return "山峦"
        case .seal: return "印章"
        case .softGlow: return "柔光"
        case .blur: return "模糊"
        case .dots: return "圆点"
        case .stripes: return "条纹"
        }
    }
}

// MARK: - 背景配置

struct BackgroundConfig: Codable, Equatable {
    var colors: [String]  // 颜色名称
    var gradientType: String
    var gradientAngle: CGFloat
    var opacity: Double
    var blurRadius: CGFloat
    var noiseIntensity: Double
    
    static let `default` = BackgroundConfig(
        colors: ["deepPurple", "midnightBlue"],
        gradientType: "linear",
        gradientAngle: 45,
        opacity: 0.9,
        blurRadius: 0,
        noiseIntensity: 0
    )
}

// MARK: - 文字配置

struct TextConfig: Codable, Equatable {
    var fontName: String
    var fontSize: CGFloat
    var textColor: String
    var shadowColor: String
    var shadowRadius: CGFloat
    var alignment: NSTextAlignment
    var lineHeight: CGFloat
    var letterSpacing: CGFloat
    
    static let `default` = TextConfig(
        fontName: "PingFangSC-Regular",
        fontSize: 18,
        textColor: "white",
        shadowColor: "black",
        shadowRadius: 2,
        alignment: .center,
        lineHeight: 1.5,
        letterSpacing: 0
    )
}

// MARK: - 装饰配置

struct DecorationConfig: Codable, Equatable {
    var type: String
    var count: Int
    var size: CGFloat
    var opacity: Double
    var animation: String?
    
    static let `default` = DecorationConfig(
        type: "stars",
        count: 20,
        size: 8,
        opacity: 0.8,
        animation: nil
    )
}

// MARK: - 艺术卡片模板

struct ArtCardTemplate: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var style: String  // ArtCardStyle.rawValue
    var platform: String?  // SocialPlatform.rawValue?
    var background: BackgroundConfig
    var textConfig: TextConfig
    var decorations: [DecorationConfig]
    var isPreset: Bool
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date
    var usageCount: Int
    var category: TemplateCategory
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        style: String,
        platform: String? = nil,
        background: BackgroundConfig = .default,
        textConfig: TextConfig = .default,
        decorations: [DecorationConfig] = [],
        isPreset: Bool = false,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        usageCount: Int = 0,
        category: TemplateCategory = .general
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.style = style
        self.platform = platform
        self.background = background
        self.textConfig = textConfig
        self.decorations = decorations
        self.isPreset = isPreset
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.usageCount = usageCount
        self.category = category
    }
}

// MARK: - 模板分类

enum TemplateCategory: String, CaseIterable, Identifiable, Codable {
    case general = "general"          // 通用
    case social = "social"            // 社交
    case artistic = "artistic"        // 艺术
    case minimal = "minimal"          // 极简
    case festive = "festive"          // 节日
    case seasonal = "seasonal"        // 季节
    case custom = "custom"            // 自定义
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .general: return "通用"
        case .social: return "社交"
        case .artistic: return "艺术"
        case .minimal: return "极简"
        case .festive: return "节日"
        case .seasonal: return "季节"
        case .custom: return "自定义"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "📋"
        case .social: return "📱"
        case .artistic: return "🎨"
        case .minimal: return "✨"
        case .festive: return "🎉"
        case .seasonal: return "🍂"
        case .custom: return "⚙️"
        }
    }
}

// MARK: - 卡片生成配置

struct CardGenerationConfig: Codable {
    var dreamId: UUID
    var style: String
    var templateId: UUID?
    var platform: String?
    var textEnhancementMode: TextEnhancementMode
    var showWatermark: Bool
    var customText: String?
    var includeTags: Bool
    var includeEmotions: Bool
    var includeDate: Bool
    
    static let `default` = CardGenerationConfig(
        dreamId: UUID(),
        style: "starry",
        templateId: nil,
        platform: nil,
        textEnhancementMode: .none,
        showWatermark: true,
        customText: nil,
        includeTags: true,
        includeEmotions: true,
        includeDate: false
    )
}

// MARK: - AI 文本增强模式

enum TextEnhancementMode: String, CaseIterable, Identifiable, Codable {
    case none = "none"              // 无增强
    case poetic = "poetic"          // 诗意化
    case concise = "concise"        // 精简版
    case vivid = "vivid"            // 生动版
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none: return "原文"
        case .poetic: return "诗意"
        case .concise: return "精简"
        case .vivid: return "生动"
        }
    }
    
    var description: String {
        switch self {
        case .none: return "保持原始内容"
        case .poetic: return "添加修辞，增强画面感"
        case .concise: return "去除冗余，突出核心"
        case .vivid: return "添加细节，强化情绪"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "📝"
        case .poetic: return "🎭"
        case .concise: return "✂️"
        case .vivid: return "🌟"
        }
    }
}

// MARK: - AI 文本增强结果

struct AITextEnhancement: Codable {
    var originalText: String
    var enhancedText: String
    var mode: TextEnhancementMode
    var keywords: [String]
    var suggestedEmojis: [String]
    var confidence: Double
    var processingTime: TimeInterval
    
    static let empty = AITextEnhancement(
        originalText: "",
        enhancedText: "",
        mode: .none,
        keywords: [],
        suggestedEmojis: [],
        confidence: 0,
        processingTime: 0
    )
}

// MARK: - 平台优化配置

struct PlatformOptimization: Codable, Equatable {
    var platform: String  // SocialPlatform.rawValue
    var aspectRatio: CGFloat
    var resolution: CGSize
    var maxTextLength: Int
    var showWatermark: Bool
    var format: ImageFormat
    var quality: Double
    var colorSpace: String
    var safeArea: EdgeInsets
    
    static func `default`(for platform: String) -> PlatformOptimization {
        switch platform {
        case "wechat":
            return PlatformOptimization(
                platform: platform,
                aspectRatio: 1.0,
                resolution: CGSize(width: 1080, height: 1080),
                maxTextLength: 200,
                showWatermark: true,
                format: .png,
                quality: 1.0,
                colorSpace: "sRGB",
                safeArea: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
            )
        case "xiaohongshu":
            return PlatformOptimization(
                platform: platform,
                aspectRatio: 1.25,
                resolution: CGSize(width: 1080, height: 1350),
                maxTextLength: 500,
                showWatermark: true,
                format: .jpg,
                quality: 0.95,
                colorSpace: "sRGB",
                safeArea: EdgeInsets(top: 60, leading: 40, bottom: 60, trailing: 40)
            )
        case "instagram":
            return PlatformOptimization(
                platform: platform,
                aspectRatio: 1.0,
                resolution: CGSize(width: 1080, height: 1350),
                maxTextLength: 300,
                showWatermark: false,
                format: .jpg,
                quality: 1.0,
                colorSpace: "Display P3",
                safeArea: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
            )
        default:
            return PlatformOptimization(
                platform: platform,
                aspectRatio: 1.0,
                resolution: CGSize(width: 1080, height: 1080),
                maxTextLength: 300,
                showWatermark: true,
                format: .png,
                quality: 1.0,
                colorSpace: "sRGB",
                safeArea: EdgeInsets(top: 40, leading: 40, bottom: 40, trailing: 40)
            )
        }
    }
}

// MARK: - 图片格式

enum ImageFormat: String, Codable, CaseIterable {
    case png = "png"
    case jpg = "jpg"
    case heic = "heic"
    
    var displayName: String {
        switch self {
        case .png: return "PNG (无损)"
        case .jpg: return "JPEG (压缩)"
        case .heic: return "HEIC (高效)"
        }
    }
    
    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpg: return "image/jpeg"
        case .heic: return "image/heic"
        }
    }
}

// MARK: - 艺术卡片生成结果

struct ArtCardGenerationResult: Codable {
    var success: Bool
    var imagePath: String?
    var imageData: Data?
    var thumbnailPath: String?
    var processingTime: TimeInterval
    var errorMessage: String?
    var metadata: CardMetadata
    
    static let empty = ArtCardGenerationResult(
        success: false,
        imagePath: nil,
        imageData: nil,
        thumbnailPath: nil,
        processingTime: 0,
        errorMessage: nil,
        metadata: CardMetadata.empty
    )
}

// MARK: - 卡片元数据

struct CardMetadata: Codable {
    var dreamId: UUID
    var style: String
    var templateId: UUID?
    var platform: String?
    var dimensions: CGSize
    var fileSize: Int
    var createdAt: Date
    var enhancementMode: TextEnhancementMode
    
    static let empty = CardMetadata(
        dreamId: UUID(),
        style: "",
        templateId: nil,
        platform: nil,
        dimensions: .zero,
        fileSize: 0,
        createdAt: Date(),
        enhancementMode: .none
    )
}

// MARK: - 卡片统计

struct ArtCardStats {
    var totalCards: Int
    var cardsByStyle: [String: Int]
    var cardsByPlatform: [String: Int]
    var favoriteTemplates: [UUID]
    var recentCards: [ArtCardGenerationResult]
    var totalShares: Int
    var mostUsedStyle: String?
    var mostUsedPlatform: String?
    
    static let empty = ArtCardStats(
        totalCards: 0,
        cardsByStyle: [:],
        cardsByPlatform: [:],
        favoriteTemplates: [],
        recentCards: [],
        totalShares: 0,
        mostUsedStyle: nil,
        mostUsedPlatform: nil
    )
}
