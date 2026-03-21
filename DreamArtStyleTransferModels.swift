//
//  DreamArtStyleTransferModels.swift
//  DreamLog
//
//  Phase 81: 梦境 AI 绘画增强 - 艺术风格迁移与滤镜系统
//  Created: 2026-03-21
//

import Foundation
import SwiftData

// MARK: - 艺术风格枚举

/// 艺术风格类型
enum ArtStyleType: String, Codable, CaseIterable, Identifiable {
    // 印象派
    case impressionist = "impressionist"
    // 后印象派 (梵高风格)
    case postImpressionist = "post_impressionist"
    // 立体主义 (毕加索风格)
    case cubist = "cubist"
    // 超现实主义
    case surrealist = "surrealist"
    // 抽象表现主义
    case abstractExpressionist = "abstract_expressionist"
    // 波普艺术
    case popArt = "pop_art"
    // 浮世绘
    case ukiyoe = "ukiyoe"
    // 水墨画
    case inkWash = "ink_wash"
    // 油画
    case oilPainting = "oil_painting"
    // 水彩画
    case watercolor = "watercolor"
    // 素描
    case sketch = "sketch"
    // 漫画风格
    case comic = "comic"
    // 像素艺术
    case pixelArt = "pixel_art"
    // 赛博朋克
    case cyberpunk = "cyberpunk"
    // 梦幻风格
    case dreamy = "dreamy"
    // 自定义
    case custom = "custom"
    
    var id: String { rawValue }
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .impressionist: return "印象派"
        case .postImpressionist: return "后印象派"
        case .cubist: return "立体主义"
        case .surrealist: return "超现实主义"
        case .abstractExpressionist: return "抽象表现主义"
        case .popArt: return "波普艺术"
        case .ukiyoe: return "浮世绘"
        case .inkWash: return "水墨画"
        case .oilPainting: return "油画"
        case .watercolor: return "水彩画"
        case .sketch: return "素描"
        case .comic: return "漫画"
        case .pixelArt: return "像素艺术"
        case .cyberpunk: return "赛博朋克"
        case .dreamy: return "梦幻风格"
        case .custom: return "自定义"
        }
    }
    
    /// 描述
    var description: String {
        switch self {
        case .impressionist: return "莫奈、雷诺阿风格，强调光影变化"
        case .postImpressionist: return "梵高风格，浓烈色彩与笔触"
        case .cubist: return "毕加索风格，几何分解重构"
        case .surrealist: return "达利风格，梦幻超现实"
        case .abstractExpressionist: return "抽象表现，情感宣泄"
        case .popArt: return "安迪沃霍尔风格，流行文化"
        case .ukiyoe: return "日本浮世绘，葛饰北斋风格"
        case .inkWash: return "中国传统水墨画"
        case .oilPainting: return "经典油画质感"
        case .watercolor: return "透明水彩效果"
        case .sketch: return "铅笔素描风格"
        case .comic: return "日式漫画风格"
        case .pixelArt: return "复古像素艺术"
        case .cyberpunk: return "霓虹赛博朋克美学"
        case .dreamy: return "柔和梦幻效果"
        case .custom: return "自定义艺术风格"
        }
    }
    
    /// 代表艺术家
    var artists: [String] {
        switch self {
        case .impressionist: return ["莫奈", "雷诺阿", "德加"]
        case .postImpressionist: return ["梵高", "高更", "塞尚"]
        case .cubist: return ["毕加索", "布拉克"]
        case .surrealist: return ["达利", "马格利特", "米罗"]
        case .abstractExpressionist: return ["波洛克", "罗斯科"]
        case .popArt: return ["安迪·沃霍尔", "利希滕斯坦"]
        case .ukiyoe: return ["葛饰北斋", "歌川广重"]
        case .inkWash: return ["齐白石", "张大千"]
        case .oilPainting: return ["伦勃朗", "维米尔"]
        case .watercolor: return ["透纳", "萨金特"]
        case .sketch: return ["达·芬奇", "米开朗基罗"]
        case .comic: return ["手冢治虫", "宫崎骏"]
        case .pixelArt: return ["复古游戏艺术"]
        case .cyberpunk: return ["赛博朋克 2077", "银翼杀手"]
        case .dreamy: return ["梦幻美学"]
        case .custom: return []
        }
    }
    
    /// 代表作品示例
    var exampleWorks: [String] {
        switch self {
        case .impressionist: return ["睡莲", "日出·印象"]
        case .postImpressionist: return ["星夜", "向日葵"]
        case .cubist: return ["格尔尼卡", "亚维农少女"]
        case .surrealist: return ["记忆的永恒", "人类之子"]
        case .abstractExpressionist: return ["第 31 号", "白色中心"]
        case .popArt: return ["玛丽莲梦露", "罐头汤"]
        case .ukiyoe: return ["神奈川冲浪里", "东海道五十三次"]
        case .inkWash: return ["虾", "庐山图"]
        case .oilPainting: return ["夜巡", "戴珍珠耳环的少女"]
        case .watercolor: return ["暴风雪", "威尼斯风景"]
        case .sketch: return ["维特鲁威人", "创世纪草图"]
        case .comic: return ["铁臂阿童木", "龙猫"]
        case .pixelArt: return ["超级马里奥", "塞尔达传说"]
        case .cyberpunk: return ["夜之城", "复制人"]
        case .dreamy: return ["梦幻场景", "朦胧美学"]
        case .custom: return []
        }
    }
    
    /// 风格强度预设
    var defaultIntensity: Double {
        switch self {
        case .impressionist, .watercolor, .dreamy: return 0.7
        case .postImpressionist, .oilPainting: return 0.8
        case .cubist, .abstractExpressionist: return 0.6
        case .surrealist, .cyberpunk: return 0.75
        case .popArt, .comic, .pixelArt: return 0.85
        case .ukiyoe, .inkWash, .sketch: return 0.65
        case .custom: return 0.5
        }
    }
}

// MARK: - 数据模型

/// 艺术风格迁移记录
@Model
final class DreamArtStyleTransfer {
    var id: UUID
    var dreamId: UUID
    var originalImageId: String
    var styleType: String
    var styleIntensity: Double
    var resultImageId: String
    var createdAt: Date
    var isFavorite: Bool
    var processingTime: TimeInterval
    var customStyleConfig: Data?
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        originalImageId: String,
        styleType: String,
        styleIntensity: Double,
        resultImageId: String,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        processingTime: TimeInterval = 0,
        customStyleConfig: Data? = nil
    ) {
        self.id = id
        self.dreamId = dreamId
        self.originalImageId = originalImageId
        self.styleType = styleType
        self.styleIntensity = styleIntensity
        self.resultImageId = resultImageId
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.processingTime = processingTime
        self.customStyleConfig = customStyleConfig
    }
}

/// 自定义艺术风格配置
@Model
final class CustomArtStyle {
    var id: UUID
    var name: String
    var description: String
    var baseStyleType: String
    var colorPalette: Data
    var brushSettings: Data
    var textureSettings: Data
    var createdAt: Date
    var usageCount: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        baseStyleType: String = ArtStyleType.custom.rawValue,
        colorPalette: Data = Data(),
        brushSettings: Data = Data(),
        textureSettings: Data = Data(),
        createdAt: Date = Date(),
        usageCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.baseStyleType = baseStyleType
        self.colorPalette = colorPalette
        self.brushSettings = brushSettings
        self.textureSettings = textureSettings
        self.createdAt = createdAt
        self.usageCount = usageCount
    }
}

// MARK: - 配置模型

/// 风格迁移配置
struct StyleTransferConfig: Codable {
    var styleType: ArtStyleType
    var intensity: Double
    var preserveContent: Double
    var colorTransfer: Bool
    var resolution: ImageResolution
    
    enum ImageResolution: String, Codable {
        case low = "512x512"
        case medium = "768x768"
        case high = "1024x1024"
        case ultra = "2048x2048"
    }
    
    init(
        styleType: ArtStyleType,
        intensity: Double? = nil,
        preserveContent: Double = 0.5,
        colorTransfer: Bool = true,
        resolution: ImageResolution = .high
    ) {
        self.styleType = styleType
        self.intensity = intensity ?? styleType.defaultIntensity
        self.preserveContent = preserveContent
        self.colorTransfer = colorTransfer
        self.resolution = resolution
    }
}

/// 风格混合配置
struct StyleMixConfig: Codable {
    var style1: ArtStyleType
    var style2: ArtStyleType
    var mixRatio: Double // 0.0-1.0, 0=全 style1, 1=全 style2
    var blendMode: BlendMode
    
    enum BlendMode: String, Codable {
        case linear = "linear"
        case overlay = "overlay"
        case multiply = "multiply"
        case screen = "screen"
        case softLight = "soft_light"
    }
    
    init(
        style1: ArtStyleType,
        style2: ArtStyleType,
        mixRatio: Double = 0.5,
        blendMode: BlendMode = .linear
    ) {
        self.style1 = style1
        self.style2 = style2
        self.mixRatio = mixRatio
        self.blendMode = blendMode
    }
}

/// 风格迁移统计
struct StyleTransferStats {
    var totalCount: Int
    var favoriteCount: Int
    var byStyleType: [String: Int]
    var averageProcessingTime: TimeInterval
    var mostUsedStyle: ArtStyleType?
    var recentTransfers: [DreamArtStyleTransfer]
    
    init(
        totalCount: Int = 0,
        favoriteCount: Int = 0,
        byStyleType: [String: Int] = [:],
        averageProcessingTime: TimeInterval = 0,
        mostUsedStyle: ArtStyleType? = nil,
        recentTransfers: [DreamArtStyleTransfer] = []
    ) {
        self.totalCount = totalCount
        self.favoriteCount = favoriteCount
        self.byStyleType = byStyleType
        self.averageProcessingTime = averageProcessingTime
        self.mostUsedStyle = mostUsedStyle
        self.recentTransfers = recentTransfers
    }
}

// MARK: - 预览数据

extension ArtStyleType {
    /// 获取所有风格的预览信息
    static var allStylesWithPreview: [(style: ArtStyleType, gradient: [String])] {
        return [
            (.impressionist, ["#A8D8EA", "#AA96DA", "#FCBAD3"]),
            (.postImpressionist, ["#FFD89B", "#19547B", "#FF6B6B"]),
            (.cubist, ["#2C3E50", "#E74C3C", "#ECF0F1"]),
            (.surrealist, ["#667EEA", "#764BA2", "#F093FB"]),
            (.abstractExpressionist, ["#000000", "#434343", "#FFFFFF"]),
            (.popArt, ["#FF6B6B", "#4ECDC4", "#FFE66D"]),
            (.ukiyoe, ["#2C5F2D", "#97BC62", "#F4E4C1"]),
            (.inkWash, ["#000000", "#434343", "#F5F5F5"]),
            (.oilPainting, ["#8B4513", "#D2691E", "#F4A460"]),
            (.watercolor, ["#A1C4FD", "#C2E9FB", "#E0C3FC"]),
            (.sketch, ["#BDC3C7", "#2C3E50", "#FFFFFF"]),
            (.comic, ["#FF6B6B", "#4ECDC4", "#45B7D1"]),
            (.pixelArt, ["#E74C3C", "#3498DB", "#2ECC71"]),
            (.cyberpunk, ["#00F5FF", "#FF00FF", "#1A1A2E"]),
            (.dreamy, ["#FAD0C4", "#FFD1FF", "#A8EDFE"])
        ]
    }
}
