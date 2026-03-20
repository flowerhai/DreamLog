//
//  DreamShareCardTemplates.swift
//  DreamLog - Phase 70: 梦境社交分享增强
//
//  Created by DreamLog Team on 2026-03-19.
//  Phase 70: Enhanced Share Card Templates - 20+ 卡片模板
//

import Foundation
import SwiftUI

// MARK: - 分享卡片模板库

/// 分享卡片模板库 - Phase 70 扩展至 24 种主题
enum ShareCardTemplateLibrary {
    
    // MARK: 自然主题 (1-6)
    
    /// 星空主题 - 经典深邃
    static let starry = ShareCardTemplate(
        id: "starry",
        name: "星空",
        description: "深邃星空背景，适合神秘梦境",
        category: .nature,
        gradientColors: ["1a1a2e", "16213e", "0f3460"],
        textColor: "ffffff",
        accentColor: "ffd700",
        iconName: "moon.stars.fill",
        isPremium: false
    )
    
    /// 日落主题 - 温暖橙红
    static let sunset = ShareCardTemplate(
        id: "sunset",
        name: "日落",
        description: "温暖日落色调，适合温馨梦境",
        category: .nature,
        gradientColors: ["ff6b6b", "feca57", "ff9ff3"],
        textColor: "ffffff",
        accentColor: "ffeaa7",
        iconName: "sun.max.fill",
        isPremium: false
    )
    
    /// 海洋主题 - 宁静蓝色
    static let ocean = ShareCardTemplate(
        id: "ocean",
        name: "海洋",
        description: "宁静海洋蓝色，适合平静梦境",
        category: .nature,
        gradientColors: ["0077b6", "00b4d8", "90e0ef"],
        textColor: "ffffff",
        accentColor: "caf0f8",
        iconName: "water.waves",
        isPremium: false
    )
    
    /// 森林主题 - 自然绿色
    static let forest = ShareCardTemplate(
        id: "forest",
        name: "森林",
        description: "自然森林绿色，适合成长梦境",
        category: .nature,
        gradientColors: ["2d6a4f", "40916c", "74c69d"],
        textColor: "ffffff",
        accentColor: "d8f3dc",
        iconName: "tree.fill",
        isPremium: false
    )
    
    /// 极光主题 - 梦幻渐变
    static let aurora = ShareCardTemplate(
        id: "aurora",
        name: "极光",
        description: "梦幻极光渐变，适合奇幻梦境",
        category: .nature,
        gradientColors: ["00ff87", "60efff", "0061ff"],
        textColor: "ffffff",
        accentColor: "e0ffff",
        iconName: "northern.lights",
        isPremium: true
    )
    
    /// 樱花主题 - 粉色浪漫
    static let sakura = ShareCardTemplate(
        id: "sakura",
        name: "樱花",
        description: "粉色樱花飘落，适合浪漫梦境",
        category: .nature,
        gradientColors: ["ffb7c5", "ff9eb5", "ff8da1"],
        textColor: "ffffff",
        accentColor: "ffc0cb",
        iconName: "flower.open",
        isPremium: true
    )
    
    // MARK: 情绪主题 (7-12)
    
    /// 极简主题 - 黑白经典
    static let minimal = ShareCardTemplate(
        id: "minimal",
        name: "极简",
        description: "简洁黑白设计，适合所有梦境",
        category: .emotion,
        gradientColors: ["000000", "333333", "666666"],
        textColor: "ffffff",
        accentColor: "ffffff",
        iconName: "circle",
        isPremium: false
    )
    
    /// 玫瑰主题 - 热情粉红
    static let rose = ShareCardTemplate(
        id: "rose",
        name: "玫瑰",
        description: "热情玫瑰粉色，适合爱情梦境",
        category: .emotion,
        gradientColors: ["c2185b", "d81b60", "ec407a"],
        textColor: "ffffff",
        accentColor: "f8bbd9",
        iconName: "heart.fill",
        isPremium: false
    )
    
    /// 薰衣草主题 - 宁静紫色
    static let lavender = ShareCardTemplate(
        id: "lavender",
        name: "薰衣草",
        description: "宁静薰衣草紫，适合放松梦境",
        category: .emotion,
        gradientColors: ["6a4c93", "8b5fbf", "b185db"],
        textColor: "ffffff",
        accentColor: "e6e6fa",
        iconName: "sparkles",
        isPremium: false
    )
    
    /// 火焰主题 - 激情红色
    static let flame = ShareCardTemplate(
        id: "flame",
        name: "火焰",
        description: "激情火焰红色，适合激烈梦境",
        category: .emotion,
        gradientColors: ["c0392b", "e74c3c", "f39c12"],
        textColor: "ffffff",
        accentColor: "f1c40f",
        iconName: "flame.fill",
        isPremium: true
    )
    
    /// 冰雪主题 - 冷静蓝色
    static let ice = ShareCardTemplate(
        id: "ice",
        name: "冰雪",
        description: "冷静冰雪蓝色，适合清醒梦境",
        category: .emotion,
        gradientColors: ["74b9ff", "a29bfe", "dfe6e9"],
        textColor: "2d3436",
        accentColor: "0984e3",
        iconName: "snowflake",
        isPremium: true
    )
    
    /// 黄金主题 - 奢华高贵
    static let gold = ShareCardTemplate(
        id: "gold",
        name: "黄金",
        description: "奢华黄金色调，适合重要梦境",
        category: .emotion,
        gradientColors: ["ffd700", "ffb347", "ff8c00"],
        textColor: "000000",
        accentColor: "fff8dc",
        iconName: "star.fill",
        isPremium: true
    )
    
    // MARK: 艺术主题 (13-18)
    
    /// 水彩主题 - 艺术晕染
    static let watercolor = ShareCardTemplate(
        id: "watercolor",
        name: "水彩",
        description: "艺术水彩晕染，适合创意梦境",
        category: .art,
        gradientColors: ["ff9a9e", "fad0c4", "ffd1ff"],
        textColor: "2d3436",
        accentColor: "6c5ce7",
        iconName: "paintbrush.fill",
        isPremium: true
    )
    
    /// 波普主题 - 潮流艺术
    static let popart = ShareCardTemplate(
        id: "popart",
        name: "波普",
        description: "潮流波普艺术，适合现代梦境",
        category: .art,
        gradientColors: ["ff6b6b", "4ecdc4", "ffe66d"],
        textColor: "000000",
        accentColor: "ff6b6b",
        iconName: "circle.grid.3x3.fill",
        isPremium: true
    )
    
    /// 赛博主题 - 未来科技
    static let cyberpunk = ShareCardTemplate(
        id: "cyberpunk",
        name: "赛博朋克",
        description: "未来科技风格，适合科幻梦境",
        category: .art,
        gradientColors: ["00f5ff", "ff00ff", "7928ca"],
        textColor: "ffffff",
        accentColor: "00f5ff",
        iconName: "cpu.fill",
        isPremium: true
    )
    
    /// 复古主题 - 怀旧色彩
    static let vintage = ShareCardTemplate(
        id: "vintage",
        name: "复古",
        description: "怀旧复古色彩，适合回忆梦境",
        category: .art,
        gradientColors: ["d4a574", "c4956a", "b3855d"],
        textColor: "f5f5dc",
        accentColor: "deb887",
        iconName: "film.fill",
        isPremium: true
    )
    
    /// 霓虹主题 - 夜店风格
    static let neon = ShareCardTemplate(
        id: "neon",
        name: "霓虹",
        description: "炫彩霓虹灯效，适合夜晚梦境",
        category: .art,
        gradientColors: ["ff00ff", "00ffff", "ff0080"],
        textColor: "ffffff",
        accentColor: "00ff00",
        iconName: "light.beacon.max.fill",
        isPremium: true
    )
    
    /// 水墨主题 - 中国风
    static let ink = ShareCardTemplate(
        id: "ink",
        name: "水墨",
        description: "中国传统水墨，适合古典梦境",
        category: .art,
        gradientColors: ["000000", "333333", "808080"],
        textColor: "ffffff",
        accentColor: "c0c0c0",
        iconName: "brush",
        isPremium: true
    )
    
    // MARK: 季节主题 (19-24)
    
    /// 春主题 - 生机盎然
    static let spring = ShareCardTemplate(
        id: "spring",
        name: "春",
        description: "春天生机勃勃，适合新生梦境",
        category: .season,
        gradientColors: ["98d8aa", "70c4bf", "7ab3ef"],
        textColor: "2d3436",
        accentColor: "fdcb6e",
        iconName: "leaf.fill",
        isPremium: false
    )
    
    /// 夏主题 - 热情似火
    static let summer = ShareCardTemplate(
        id: "summer",
        name: "夏",
        description: "夏天热情似火，适合活力梦境",
        category: .season,
        gradientColors: ["f0932b", "eb4d4b", "f78fb3"],
        textColor: "ffffff",
        accentColor: "ffeaa7",
        iconName: "sun.dust.fill",
        isPremium: false
    )
    
    /// 秋主题 - 丰收金黄
    static let autumn = ShareCardTemplate(
        id: "autumn",
        name: "秋",
        description: "秋天丰收金黄，适合收获梦境",
        category: .season,
        gradientColors: ["e17055", "fdcb6e", "f39c12"],
        textColor: "ffffff",
        accentColor: "ffeaa7",
        iconName: "leaf.arrow.triangle.circle",
        isPremium: false
    )
    
    /// 冬主题 - 纯净雪白
    static let winter = ShareCardTemplate(
        id: "winter",
        name: "冬",
        description: "冬天纯净雪白，适合宁静梦境",
        category: .season,
        gradientColors: ["dfe6e9", "b2bec3", "636e72"],
        textColor: "2d3436",
        accentColor: "74b9ff",
        iconName: "cloud.snow.fill",
        isPremium: false
    )
    
    /// 午夜主题 - 深邃神秘
    static let midnight = ShareCardTemplate(
        id: "midnight",
        name: "午夜",
        description: "午夜深邃神秘，适合深度梦境",
        category: .season,
        gradientColors: ["0c0c0c", "1a1a2e", "16213e"],
        textColor: "ffffff",
        accentColor: "9b59b6",
        iconName: "moon.fill",
        isPremium: false
    )
    
    /// 水晶主题 - 透明纯净
    static let crystal = ShareCardTemplate(
        id: "crystal",
        name: "水晶",
        description: "水晶透明纯净，适合清晰梦境",
        category: .season,
        gradientColors: ["e0ffff", "afeeee", "87cefa"],
        textColor: "2d3436",
        accentColor: "4169e1",
        iconName: "gemstone",
        isPremium: true
    )
    
    // MARK: 模板集合
    
    /// 所有免费模板
    static var freeTemplates: [ShareCardTemplate] {
        allTemplates.filter { !$0.isPremium }
    }
    
    /// 所有高级模板
    static var premiumTemplates: [ShareCardTemplate] {
        allTemplates.filter { $0.isPremium }
    }
    
    /// 所有模板
    static var allTemplates: [ShareCardTemplate] {
        [
            // 自然主题
            starry, sunset, ocean, forest, aurora, sakura,
            // 情绪主题
            minimal, rose, lavender, flame, ice, gold,
            // 艺术主题
            watercolor, popart, cyberpunk, vintage, neon, ink,
            // 季节主题
            spring, summer, autumn, winter, midnight, crystal
        ]
    }
    
    /// 按分类获取模板
    static func templates(in category: ShareCardTemplateCategory) -> [ShareCardTemplate] {
        allTemplates.filter { $0.category == category }
    }
    
    /// 根据 ID 获取模板
    static func template(id: String) -> ShareCardTemplate? {
        allTemplates.first { $0.id == id }
    }
}

// MARK: - 卡片模板模型

/// 分享卡片模板
struct ShareCardTemplate: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: ShareCardTemplateCategory
    let gradientColors: [String]      // 渐变颜色 (十六进制)
    let textColor: String             // 文字颜色
    let accentColor: String           // 强调色
    let iconName: String              // 图标名称
    let isPremium: Bool               // 是否高级模板
    
    /// 获取渐变颜色 (SwiftUI Color)
    var swiftUIGradients: [Color] {
        gradientColors.map { Color(hex: $0) }
    }
    
    /// 获取文字颜色
    var swiftUITextColor: Color {
        Color(hex: textColor)
    }
    
    /// 获取强调色
    var swiftUIAccentColor: Color {
        Color(hex: accentColor)
    }
}

// MARK: - 模板分类枚举

/// 模板分类
enum ShareCardTemplateCategory: String, Codable, CaseIterable, Identifiable {
    case nature = "nature"        // 自然主题
    case emotion = "emotion"      // 情绪主题
    case art = "art"              // 艺术主题
    case season = "season"        // 季节主题
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .nature: return "自然"
        case .emotion: return "情绪"
        case .art: return "艺术"
        case .season: return "季节"
        }
    }
    
    var iconName: String {
        switch self {
        case .nature: return "leaf.fill"
        case .emotion: return "heart.fill"
        case .art: return "paintpalette.fill"
        case .season: return "calendar"
        }
    }
}

// MARK: - 自定义布局配置

/// 自定义布局配置
struct CustomLayoutConfig: Codable {
    var layoutStyle: LayoutStyle
    var titlePosition: ElementPosition
    var contentPosition: ElementPosition
    var imagePosition: ElementPosition
    var tagsPosition: ElementPosition
    var watermarkPosition: ElementPosition
    var showBorder: Bool
    var borderRadius: CGFloat
    var padding: CGFloat
    var spacing: CGFloat
    
    init(
        layoutStyle: LayoutStyle = .classic,
        titlePosition: ElementPosition = .top,
        contentPosition: ElementPosition = .center,
        imagePosition: ElementPosition = .background,
        tagsPosition: ElementPosition = .bottom,
        watermarkPosition: ElementPosition = .bottomRight,
        showBorder: Bool = false,
        borderRadius: CGFloat = 16,
        padding: CGFloat = 20,
        spacing: CGFloat = 12
    ) {
        self.layoutStyle = layoutStyle
        self.titlePosition = titlePosition
        self.contentPosition = contentPosition
        self.imagePosition = imagePosition
        self.tagsPosition = tagsPosition
        self.watermarkPosition = watermarkPosition
        self.showBorder = showBorder
        self.borderRadius = borderRadius
        self.padding = padding
        self.spacing = spacing
    }
}

/// 布局样式
enum LayoutStyle: String, Codable, CaseIterable {
    case classic = "classic"          // 经典布局
    case modern = "modern"            // 现代布局
    case minimal = "minimal"          // 极简布局
    case artistic = "artistic"        // 艺术布局
    case magazine = "magazine"        // 杂志布局
    case polaroid = "polaroid"        // 拍立得布局
    
    var displayName: String {
        switch self {
        case .classic: return "经典"
        case .modern: return "现代"
        case .minimal: return "极简"
        case .artistic: return "艺术"
        case .magazine: return "杂志"
        case .polaroid: return "拍立得"
        }
    }
}

/// 元素位置
enum ElementPosition: String, Codable, CaseIterable {
    case top = "top"
    case center = "center"
    case bottom = "bottom"
    case left = "left"
    case right = "right"
    case topLeft = "topLeft"
    case topRight = "topRight"
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    case background = "background"
    case overlay = "overlay"
    
    var displayName: String {
        switch self {
        case .top: return "顶部"
        case .center: return "居中"
        case .bottom: return "底部"
        case .left: return "左侧"
        case .right: return "右侧"
        case .topLeft: return "左上"
        case .topRight: return "右上"
        case .bottomLeft: return "左下"
        case .bottomRight: return "右下"
        case .background: return "背景"
        case .overlay: return "覆盖"
        }
    }
}

// MARK: - 动态贴纸配置

/// 动态贴纸配置
struct DynamicStickerConfig: Codable, Identifiable {
    let id: UUID
    var stickerType: StickerType
    var position: CGPoint
    var scale: CGFloat
    var rotation: CGFloat
    var opacity: Double
    var animationType: StickerAnimation
    
    init(
        stickerType: StickerType = .star,
        position: CGPoint = .zero,
        scale: CGFloat = 1.0,
        rotation: CGFloat = 0,
        opacity: Double = 1.0,
        animationType: StickerAnimation = .none
    ) {
        self.id = UUID()
        self.stickerType = stickerType
        self.position = position
        self.scale = scale
        self.rotation = rotation
        self.opacity = opacity
        self.animationType = animationType
    }
}

/// 贴纸类型
enum StickerType: String, Codable, CaseIterable {
    case star = "star"
    case heart = "heart"
    case moon = "moon"
    case cloud = "cloud"
    case flower = "flower"
    case sparkle = "sparkle"
    case rainbow = "rainbow"
    case butterfly = "butterfly"
    case bird = "bird"
    case music = "music"
    
    var displayName: String {
        switch self {
        case .star: return "星星"
        case .heart: return "爱心"
        case .moon: return "月亮"
        case .cloud: return "云朵"
        case .flower: return "花朵"
        case .sparkle: return "闪光"
        case .rainbow: return "彩虹"
        case .butterfly: return "蝴蝶"
        case .bird: return "小鸟"
        case .music: return "音符"
        }
    }
    
    var sfSymbolName: String {
        switch self {
        case .star: return "star.fill"
        case .heart: return "heart.fill"
        case .moon: return "moon.fill"
        case .cloud: return "cloud.fill"
        case .flower: return "flower.fill"
        case .sparkle: return "sparkles"
        case .rainbow: return "cloud.rainbow.fill"
        case .butterfly: return "ladybug.fill"
        case .bird: return "bird.fill"
        case .music: return "music.note.fill"
        }
    }
}

/// 贴纸动画类型
enum StickerAnimation: String, Codable, CaseIterable {
    case none = "none"
    case bounce = "bounce"
    case rotate = "rotate"
    case scale = "scale"
    float = "float"
    pulse = "pulse"
    sparkle = "sparkle"
    
    var displayName: String {
        switch self {
        case .none: return "无"
        case .bounce: return "弹跳"
        case .rotate: return "旋转"
        case .scale: return "缩放"
        case .float: return "漂浮"
        case .pulse: return "脉冲"
        case .sparkle: return "闪光"
        }
    }
}

// MARK: - Color 扩展

extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
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
