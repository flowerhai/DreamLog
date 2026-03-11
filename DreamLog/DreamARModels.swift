//
//  DreamARModels.swift
//  DreamLog - Phase 21: Dream AR Visualization
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import ARKit
import SwiftUI

// MARK: - AR Dream Element Types

/// AR 梦境元素类型
enum ARDreamElementType: String, Codable, CaseIterable {
    case water = "water"        // 水/海洋/河流
    case fire = "fire"          // 火/火焰
    case wind = "wind"          // 风/气流
    case earth = "earth"        // 土地/岩石
    case light = "light"        // 光/光芒
    case dark = "dark"          // 黑暗/阴影
    case nature = "nature"      // 自然/植物
    case animal = "animal"      // 动物
    case human = "human"        // 人物
    case building = "building"  // 建筑
    case vehicle = "vehicle"    // 交通工具
    case abstract = "abstract"  // 抽象元素
    
    var displayName: String {
        switch self {
        case .water: return "💧 水元素"
        case .fire: return "🔥 火元素"
        case .wind: return "💨 风元素"
        case .earth: return "🪨 土元素"
        case .light: return "✨ 光元素"
        case .dark: return "🌑 暗元素"
        case .nature: return "🌿 自然元素"
        case .animal: return "🦋 动物元素"
        case .human: return "👤 人物元素"
        case .building: return "🏛️ 建筑元素"
        case .vehicle: return "🚗 交通元素"
        case .abstract: return "🌀 抽象元素"
        }
    }
    
    var color: Color {
        switch self {
        case .water: return .blue
        case .fire: return .red
        case .wind: return .cyan
        case .earth: return .brown
        case .light: return .yellow
        case .dark: return .purple
        case .nature: return .green
        case .animal: return .orange
        case .human: return .pink
        case .building: return .gray
        case .vehicle: return .indigo
        case .abstract: return .mint
        }
    }
}

// MARK: - AR Dream Scene

/// AR 梦境场景配置
struct ARDreamScene: Codable, Identifiable {
    let id: UUID
    let dreamId: UUID
    let sceneName: String
    var elements: [ARDreamElement]
    var environment: AREnvironmentType
    var lighting: ARLightingPreset
    var createdAt: Date
    
    init(dreamId: UUID, dreamTitle: String, elements: [ARDreamElement] = []) {
        self.id = UUID()
        self.dreamId = dreamId
        self.sceneName = dreamTitle
        self.elements = elements
        self.environment = .default
        self.lighting = .natural
        self.createdAt = Date()
    }
}

// MARK: - AR Dream Element

/// AR 梦境元素
struct ARDreamElement: Codable, Identifiable {
    let id: UUID
    let type: ARDreamElementType
    let name: String
    let description: String
    var position: SIMD3<Float>
    var scale: SIMD3<Float>
    var rotation: SIMD4<Float>
    var color: String // HEX color
    var intensity: Float // 0-1
    var animation: ARAnimationType?
    var soundEffect: String?
    
    init(type: ARDreamElementType, name: String, description: String) {
        self.id = UUID()
        self.type = type
        self.name = name
        self.description = description
        self.position = SIMD3<Float>(0, 0, 0)
        self.scale = SIMD3<Float>(1, 1, 1)
        self.rotation = SIMD4<Float>(0, 1, 0, 0)
        self.color = type.color.toHex()
        self.intensity = 0.8
        self.animation = nil
        self.soundEffect = nil
    }
}

// MARK: - AR Environment Types

/// AR 环境类型
enum AREnvironmentType: String, Codable, CaseIterable {
    case `default` = "default"
    case sky = "sky"
    case ocean = "ocean"
    case forest = "forest"
    case space = "space"
    case abstract = "abstract"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .default: return "默认"
        case .sky: return "天空"
        case .ocean: return "海洋"
        case .forest: return "森林"
        case .space: return "太空"
        case .abstract: return "抽象"
        case .custom: return "自定义"
        }
    }
}

// MARK: - AR Lighting Presets

/// AR 灯光预设
enum ARLightingPreset: String, Codable, CaseIterable {
    case natural = "natural"
    case dramatic = "dramatic"
    case soft = "soft"
    case colorful = "colorful"
    case dark = "dark"
    case dreamy = "dreamy"
    
    var displayName: String {
        switch self {
        case .natural: return "自然光"
        case .dramatic: return "戏剧光"
        case .soft: return "柔光"
        case .colorful: return "彩色光"
        case .dark: return "暗光"
        case .dreamy: return "梦幻光"
        }
    }
}

// MARK: - AR Animation Types

/// AR 动画类型
enum ARAnimationType: String, Codable, CaseIterable {
    case none = "none"
    case float = "float"          // 漂浮
    case pulse = "pulse"          // 脉冲
    case rotate = "rotate"        // 旋转
    case sparkle = "sparkle"      // 闪烁
    case wave = "wave"            // 波动
    case grow = "grow"            // 生长
    case fade = "fade"            // 淡入淡出
    case orbit = "orbit"          // 轨道运动
    
    var displayName: String {
        switch self {
        case .none: return "无动画"
        case .float: return "漂浮"
        case .pulse: return "脉冲"
        case .rotate: return "旋转"
        case .sparkle: return "闪烁"
        case .wave: return "波动"
        case .grow: return "生长"
        case .fade: return "淡入淡出"
        case .orbit: return "轨道"
        }
    }
}

// MARK: - AR Recording

/// AR 录制配置
struct ARRecordingConfig: Codable {
    var duration: TimeInterval // 录制时长 (秒)
    var includeAudio: Bool // 包含音频
    var quality: ARVideoQuality
    var resolution: ARVideoResolution
    
    init(duration: TimeInterval = 30, includeAudio: Bool = true, 
         quality: ARVideoQuality = .high, resolution: ARVideoResolution = .hd1080p) {
        self.duration = duration
        self.includeAudio = includeAudio
        self.quality = quality
        self.resolution = resolution
    }
}

enum ARVideoQuality: String, Codable {
    case low, medium, high, ultra
}

enum ARVideoResolution: String, Codable {
    case hd720p = "720p"
    case hd1080p = "1080p"
    case hevc4k = "4K"
}

// MARK: - AR Share

/// AR 梦境分享
struct ARDreamShare: Codable, Identifiable {
    let id: UUID
    let sceneId: UUID
    let dreamId: UUID
    var shareURL: String?
    var thumbnailURL: String?
    var viewCount: Int
    var likeCount: Int
    var createdAt: Date
    
    init(sceneId: UUID, dreamId: UUID) {
        self.id = UUID()
        self.sceneId = sceneId
        self.dreamId = dreamId
        self.viewCount = 0
        self.likeCount = 0
        self.createdAt = Date()
    }
}

// MARK: - Color Extension

extension Color {
    func toHex() -> String {
        // Simplified conversion - in production would use UIColor
        switch self {
        case .red: return "#FF0000"
        case .green: return "#00FF00"
        case .blue: return "#0000FF"
        case .yellow: return "#FFFF00"
        case .purple: return "#800080"
        case .pink: return "#FFC0CB"
        case .orange: return "#FFA500"
        case .cyan: return "#00FFFF"
        case .mint: return "#99FFCC"
        case .indigo: return "#4B0082"
        case .brown: return "#8B4513"
        case .gray: return "#808080"
        default: return "#FFFFFF"
        }
    }
}

// MARK: - AR Session State

/// AR 会话状态
enum ARSessionState: Equatable {
    case idle
    case preparing
    case running
    case recording
    case paused
    case error(String)
    
    var description: String {
        switch self {
        case .idle: return "空闲"
        case .preparing: return "准备中..."
        case .running: return "运行中"
        case .recording: return "录制中"
        case .paused: return "已暂停"
        case .error(let msg): return "错误：\(msg)"
        }
    }
}
