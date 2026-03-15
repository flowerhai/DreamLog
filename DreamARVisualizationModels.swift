//
//  DreamARVisualizationModels.swift
//  DreamLog
//
//  Created for Phase 48 - AR 梦境场景可视化
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftUI
import ARKit
import SwiftData

// MARK: - AR 梦境可视化数据模型

/// AR 梦境场景数据模型
@Model
final class ARDreamScene: Identifiable, Hashable {
    var id: UUID
    var dreamID: UUID
    var sceneName: String
    var sceneDescription: String
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var viewCount: Int
    var lastViewedAt: Date?
    
    @Relationship(deleteRule: .cascade)
    var elements: [ARDreamElement]
    
    @Relationship(deleteRule: .cascade)
    var anchors: [ARDreamAnchor]
    
    init(
        id: UUID = UUID(),
        dreamID: UUID,
        sceneName: String,
        sceneDescription: String,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.dreamID = dreamID
        self.sceneName = sceneName
        self.sceneDescription = sceneDescription
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFavorite = isFavorite
        self.viewCount = 0
        self.elements = []
        self.anchors = []
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARDreamScene, rhs: ARDreamScene) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 更新最后查看时间
    func recordView() {
        lastViewedAt = Date()
        viewCount += 1
        updatedAt = Date()
    }
}

// MARK: - AR 梦境元素

/// AR 梦境元素类型
enum ARDreamElementType: String, Codable, CaseIterable, Identifiable {
    case symbol = "symbol"           // 梦境符号
    case emotion = "emotion"         // 情绪光效
    case text = "text"               // 文字片段
    case image = "image"             // 梦境图片
    case soundscape = "soundscape"   // 环境音效
    case particle = "particle"       // 粒子效果
    case light = "light"             // 光源
    case model3D = "model3D"         // 3D 模型
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .symbol: return "梦境符号"
        case .emotion: return "情绪光效"
        case .text: return "文字片段"
        case .image: return "梦境图片"
        case .soundscape: return "环境音效"
        case .particle: return "粒子效果"
        case .light: return "光源"
        case .model3D: return "3D 模型"
        }
    }
    
    var icon: String {
        switch self {
        case .symbol: return "star.fill"
        case .emotion: return "heart.fill"
        case .text: return "text.bubble.fill"
        case .image: return "photo.fill"
        case .soundscape: return "speaker.wave.2.fill"
        case .particle: return "sparkles"
        case .light: return "lightbulb.fill"
        case .model3D: return "cube.fill"
        }
    }
}

/// AR 梦境元素数据模型
@Model
final class ARDreamElement: Identifiable, Hashable {
    var id: UUID
    var sceneID: UUID
    var type: ARDreamElementType
    var name: String
    var content: String  // 符号名称/文字内容/图片路径等
    var position: SIMD3<Float>  // 3D 位置
    var rotation: SIMD4<Float>  // 四元数旋转
    var scale: SIMD3<Float>     // 缩放
    var color: String?          // HEX 颜色
    var opacity: Float          // 透明度 0-1
    var duration: TimeInterval? // 持续时间 (nil=永久)
    var isAnimated: Bool
    var animationType: String?  // 动画类型
    var metadata: [String: String]?  // 额外元数据
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        sceneID: UUID,
        type: ARDreamElementType,
        name: String,
        content: String,
        position: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
        rotation: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1),
        scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
        color: String? = nil,
        opacity: Float = 1.0,
        duration: TimeInterval? = nil,
        isAnimated: Bool = false,
        animationType: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.sceneID = sceneID
        self.type = type
        self.name = name
        self.content = content
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.color = color
        self.opacity = opacity
        self.duration = duration
        self.isAnimated = isAnimated
        self.animationType = animationType
        self.metadata = metadata
        self.createdAt = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARDreamElement, rhs: ARDreamElement) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 获取 SF 符号名称 (用于符号元素)
    var sfSymbolName: String? {
        guard type == .symbol, let symbol = DreamSymbol(rawValue: content) else { return nil }
        return symbol.sfSymbol
    }
    
    /// 获取颜色值
    var colorValue: Color? {
        guard let hex = color else { return nil }
        return Color(hex: hex)
    }
}

// MARK: - AR 锚点

/// AR 锚点类型
enum ARDreamAnchorType: String, Codable, CaseIterable {
    case plane = "plane"           // 水平/垂直平面
    case face = "face"             // 人脸
    case image = "image"           // 图像识别
    case object = "object"         // 3D 物体识别
    case location = "location"     // GPS 位置
    case world = "world"           // 世界坐标系
    
    var displayName: String {
        switch self {
        case .plane: return "平面"
        case .face: return "人脸"
        case .image: return "图像"
        case .object: return "物体"
        case .location: return "位置"
        case .world: return "世界"
        }
    }
}

/// AR 锚点数据模型
@Model
final class ARDreamAnchor: Identifiable, Hashable {
    var id: UUID
    var sceneID: UUID
    var type: ARDreamAnchorType
    var name: String
    var anchorData: Data  // 序列化的锚点数据
    var isPersistent: Bool  // 是否持久化
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        sceneID: UUID,
        type: ARDreamAnchorType,
        name: String,
        anchorData: Data,
        isPersistent: Bool = false
    ) {
        self.id = id
        self.sceneID = sceneID
        self.type = type
        self.name = name
        self.anchorData = anchorData
        self.isPersistent = isPersistent
        self.createdAt = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARDreamAnchor, rhs: ARDreamAnchor) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 梦境符号枚举

/// 梦境符号枚举 (与 AI 解析关联)
enum DreamSymbol: String, Codable, CaseIterable, Identifiable {
    // 自然元素
    case water = "water"
    case fire = "fire"
    case earth = "earth"
    case air = "air"
    case moon = "moon"
    case sun = "sun"
    case star = "star"
    case cloud = "cloud"
    case rainbow = "rainbow"
    
    // 动物
    case bird = "bird"
    case fish = "fish"
    case cat = "cat"
    case dog = "dog"
    case butterfly = "butterfly"
    case snake = "snake"
    case dragon = "dragon"
    
    // 人物
    case person = "person"
    case child = "child"
    case elder = "elder"
    case stranger = "stranger"
    
    // 场所
    case house = "house"
    case door = "door"
    case stairs = "stairs"
    case bridge = "bridge"
    case forest = "forest"
    case ocean = "ocean"
    case mountain = "mountain"
    
    // 物品
    case key = "key"
    case book = "book"
    case mirror = "mirror"
    case clock = "clock"
    case phone = "phone"
    
    // 抽象概念
    case flying = "flying"
    case falling = "falling"
    case running = "running"
    case hiding = "hiding"
    case chasing = "chasing"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .water: return "水"
        case .fire: return "火"
        case .earth: return "土"
        case .air: return "风"
        case .moon: return "月亮"
        case .sun: return "太阳"
        case .star: return "星星"
        case .cloud: return "云"
        case .rainbow: return "彩虹"
        case .bird: return "鸟"
        case .fish: return "鱼"
        case .cat: return "猫"
        case .dog: return "狗"
        case .butterfly: return "蝴蝶"
        case .snake: return "蛇"
        case .dragon: return "龙"
        case .person: return "人"
        case .child: return "小孩"
        case .elder: return "老人"
        case .stranger: return "陌生人"
        case .house: return "房子"
        case .door: return "门"
        case .stairs: return "楼梯"
        case .bridge: return "桥"
        case .forest: return "森林"
        case .ocean: return "海洋"
        case .mountain: return "山"
        case .key: return "钥匙"
        case .book: return "书"
        case .mirror: return "镜子"
        case .clock: return "时钟"
        case .phone: return "手机"
        case .flying: return "飞翔"
        case .falling: return "坠落"
        case .running: return "奔跑"
        case .hiding: return "躲藏"
        case .chasing: return "追逐"
        }
    }
    
    var sfSymbol: String {
        switch self {
        case .water: return "drop.fill"
        case .fire: return "flame.fill"
        case .earth: return "globe"
        case .air: return "wind"
        case .moon: return "moon.fill"
        case .sun: return "sun.max.fill"
        case .star: return "star.fill"
        case .cloud: return "cloud.fill"
        case .rainbow: return "cloud.rainbow.fill"
        case .bird: return "bird.fill"
        case .fish: return "fish.fill"
        case .cat: return "cat.fill"
        case .dog: return "dog.fill"
        case .butterfly: return "ladybug.fill"
        case .snake: return "waveform.path.ecg"
        case .dragon: return "flame.circle.fill"
        case .person: return "person.fill"
        case .child: return "figure.child"
        case .elder: return "figure.arms.open"
        case .stranger: return "person.2.fill"
        case .house: return "house.fill"
        case .door: return "door.left.hand.open"
        case .stairs: return "staircase"
        case .bridge: return "bridge"
        case .forest: return "tree.fill"
        case .ocean: return "water.waves"
        case .mountain: return "mountain.fill"
        case .key: return "key.fill"
        case .book: return "book.fill"
        case .mirror: return "mirror"
        case .clock: return "clock.fill"
        case .phone: return "phone.fill"
        case .flying: return "airplane"
        case .falling: return "arrow.down.to.line"
        case .running: return "figure.run"
        case .hiding: return "eye.slash.fill"
        case .chasing: return "figure.2"
        }
    }
    
    var defaultColor: String {
        switch self {
        case .water: return "#4A90E2"
        case .fire: return "#E24A4A"
        case .earth: return "#8B4513"
        case .air: return "#87CEEB"
        case .moon: return "#F5F5DC"
        case .sun: return "#FFD700"
        case .star: return "#FFD700"
        case .cloud: return "#D3D3D3"
        case .rainbow: return "#FF6B6B"
        case .bird: return "#4A90E2"
        case .fish: return "#4A90E2"
        case .cat: return "#8B4513"
        case .dog: return "#D2691E"
        case .butterfly: return "#FF69B4"
        case .snake: return "#228B22"
        case .dragon: return "#DC143C"
        case .person: return "#DEB887"
        case .child: return "#FFB6C1"
        case .elder: return "#C0C0C0"
        case .stranger: return "#708090"
        case .house: return "#8B4513"
        case .door: return "#654321"
        case .stairs: return "#A9A9A9"
        case .bridge: return "#696969"
        case .forest: return "#228B22"
        case .ocean: return "#006994"
        case .mountain: return "#708090"
        case .key: return "#FFD700"
        case .book: return "#8B4513"
        case .mirror: return "#C0C0C0"
        case .clock: return "#2F4F4F"
        case .phone: return "#2F4F4F"
        case .flying: return "#87CEEB"
        case .falling: return "#696969"
        case .running: return "#FF4500"
        case .hiding: return "#483D8B"
        case .chasing: return "#DC143C"
        }
    }
}

// MARK: - AR 配置

/// AR 场景配置
struct ARSceneConfiguration: Codable {
    var enablePlaneDetection: Bool
    var enableFaceTracking: Bool
    var enableImageTracking: Bool
    var enableLightEstimation: Bool
    var enableOcclusion: Bool
    var environmentTexturing: Bool
    var automaticLighting: Bool
    
    static var `default`: ARSceneConfiguration {
        ARSceneConfiguration(
            enablePlaneDetection: true,
            enableFaceTracking: false,
            enableImageTracking: false,
            enableLightEstimation: true,
            enableOcclusion: true,
            environmentTexturing: true,
            automaticLighting: true
        )
    }
    
    static var minimal: ARSceneConfiguration {
        ARSceneConfiguration(
            enablePlaneDetection: true,
            enableFaceTracking: false,
            enableImageTracking: false,
            enableLightEstimation: false,
            enableOcclusion: false,
            environmentTexturing: false,
            automaticLighting: false
        )
    }
}

// MARK: - 颜色扩展

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
