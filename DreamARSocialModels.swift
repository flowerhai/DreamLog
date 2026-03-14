//
//  DreamARSocialModels.swift
//  DreamLog
//
//  Created for Phase 40 - AR 社交功能
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftUI
import ARKit
import MultipeerConnectivity
import SwiftData

// MARK: - AR 会话模型

/// AR 社交会话数据模型
@Model
final class ARSession: Identifiable, Hashable {
    var id: UUID
    var sessionCode: String  // 6 位邀请码
    var hostUserID: UUID
    var hostDisplayName: String
    var dreamID: UUID?
    var sceneTemplate: ARSceneTemplate
    var createdAt: Date
    var expiresAt: Date
    var maxParticipants: Int
    var isPublic: Bool
    var isActive: Bool
    var participantCount: Int
    
    @Relationship(deleteRule: .cascade)
    var participants: [ARParticipant]
    
    @Relationship(deleteRule: .cascade)
    var elements: [ARElement]
    
    @Relationship(deleteRule: .cascade)
    var messages: [ARMessage]
    
    init(
        id: UUID = UUID(),
        sessionCode: String,
        hostUserID: UUID,
        hostDisplayName: String,
        dreamID: UUID? = nil,
        sceneTemplate: ARSceneTemplate = .starryNight,
        maxParticipants: Int = 8,
        isPublic: Bool = false,
        durationMinutes: Int = 60
    ) {
        self.id = id
        self.sessionCode = sessionCode
        self.hostUserID = hostUserID
        self.hostDisplayName = hostDisplayName
        self.dreamID = dreamID
        self.sceneTemplate = sceneTemplate
        self.createdAt = Date()
        self.expiresAt = Date().addingTimeInterval(Double(durationMinutes) * 60)
        self.maxParticipants = maxParticipants
        self.isPublic = isPublic
        self.isActive = true
        self.participantCount = 1
        self.participants = []
        self.elements = []
        self.messages = []
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARSession, rhs: ARSession) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 检查会话是否有效
    var isValid: Bool {
        isActive && Date() < expiresAt && participantCount < maxParticipants
    }
    
    /// 检查是否可以加入
    func canJoin(for userID: UUID) -> Bool {
        isValid && !participants.contains { $0.userID == userID }
    }
}

// MARK: - AR 场景模板

/// AR 场景模板枚举
enum ARSceneTemplate: String, Codable, CaseIterable, Identifiable {
    case starryNight = "starry_night"      // 星空梦境
    case oceanWorld = "ocean_world"        // 海洋世界
    case mountainPeak = "mountain_peak"    // 雪山奇境
    case forestMyst = "forest_myst"        // 迷雾森林
    case crystalCave = "crystal_cave"      // 水晶洞穴
    case skyGarden = "sky_garden"          // 天空花园
    case desertOasis = "desert_oasis"      // 沙漠绿洲
    case auroraField = "aurora_field"      // 极光原野
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .starryNight: return "星空梦境"
        case .oceanWorld: return "海洋世界"
        case .mountainPeak: return "雪山奇境"
        case .forestMyst: return "迷雾森林"
        case .crystalCave: return "水晶洞穴"
        case .skyGarden: return "天空花园"
        case .desertOasis: return "沙漠绿洲"
        case .auroraField: return "极光原野"
        }
    }
    
    var icon: String {
        switch self {
        case .starryNight: return "star.fill"
        case .oceanWorld: return "water.waves"
        case .mountainPeak: return "mountain.fill"
        case .forestMyst: return "tree.fill"
        case .crystalCave: return "gemstone.fill"
        case .skyGarden: return "flower.open"
        case .desertOasis: return "sun.max.fill"
        case .auroraField: return "cloud.bolt.fill"
        }
    }
    
    var description: String {
        switch self {
        case .starryNight: return "在璀璨星空下探索梦境"
        case .oceanWorld: return "潜入深海的神秘世界"
        case .mountainPeak: return "站在雪山之巅俯瞰云海"
        case .forestMyst: return "穿梭于迷雾笼罩的森林"
        case .crystalCave: return "探索发光水晶的神秘洞穴"
        case .skyGarden: return "漂浮在云端的美丽花园"
        case .desertOasis: return "沙漠中的生命绿洲"
        case .auroraField: return "在极光下漫步原野"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .starryNight: return Color(red: 0.05, green: 0.05, blue: 0.15)
        case .oceanWorld: return Color(red: 0.0, green: 0.1, blue: 0.3)
        case .mountainPeak: return Color(red: 0.8, green: 0.9, blue: 1.0)
        case .forestMyst: return Color(red: 0.1, green: 0.2, blue: 0.1)
        case .crystalCave: return Color(red: 0.1, green: 0.05, blue: 0.2)
        case .skyGarden: return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .desertOasis: return Color(red: 0.9, green: 0.7, blue: 0.4)
        case .auroraField: return Color(red: 0.0, green: 0.15, blue: 0.1)
        }
    }
    
    var availableElements: [ARElementType] {
        switch self {
        case .starryNight:
            return [.star, .meteor, .planet, .nebula, .satellite]
        case .oceanWorld:
            return [.fish, .coral, .bubble, .seaweed, .treasure]
        case .mountainPeak:
            return [.snowflake, .cloud, .bird, .flag, .rock]
        case .forestMyst:
            return [.tree, .mushroom, .firefly, .flower, .butterfly]
        case .crystalCave:
            return [.crystal, .gem, .torch, .stalactite, .pool]
        case .skyGarden:
            return [.cloud, .flower, .butterfly, .bird, .rainbow]
        case .desertOasis:
            return [.cactus, .palm, .oasis, .sun, .camel]
        case .auroraField:
            return [.aurora, .star, .tree, .lake, .deer]
        }
    }
}

// MARK: - AR 参与者模型

/// AR 会话参与者数据模型
@Model
final class ARParticipant: Identifiable, Hashable {
    var id: UUID
    var sessionID: UUID
    var userID: UUID
    var displayName: String
    var avatarColor: String  // Codable Color 存储为 String
    var joinedAt: Date
    var lastActiveAt: Date
    var isHost: Bool
    var isMuted: Bool
    var positionX: Double
    var positionY: Double
    var positionZ: Double
    var rotationX: Double
    var rotationY: Double
    var rotationZ: Double
    var rotationW: Double
    
    init(
        id: UUID = UUID(),
        sessionID: UUID,
        userID: UUID,
        displayName: String,
        avatarColor: Color = .blue,
        isHost: Bool = false
    ) {
        self.id = id
        self.sessionID = sessionID
        self.userID = userID
        self.displayName = displayName
        self.avatarColor = NSCoder.string(for: avatarColor) ?? "#007AFF"
        self.joinedAt = Date()
        self.lastActiveAt = Date()
        self.isHost = isHost
        self.isMuted = false
        self.positionX = 0
        self.positionY = 0
        self.positionZ = 0
        self.rotationX = 0
        self.rotationY = 0
        self.rotationZ = 0
        self.rotationW = 1
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARParticipant, rhs: ARParticipant) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 3D 位置
    var position: SIMD3<Float> {
        get { SIMD3<Float>(Float(positionX), Float(positionY), Float(positionZ)) }
        set {
            positionX = Double(newValue.x)
            positionY = Double(newValue.y)
            positionZ = Double(newValue.z)
        }
    }
    
    /// 四元数旋转
    var rotation: SIMD4<Float> {
        get { SIMD4<Float>(Float(rotationX), Float(rotationY), Float(rotationZ), Float(rotationW)) }
        set {
            rotationX = Double(newValue.x)
            rotationY = Double(newValue.y)
            rotationZ = Double(newValue.z)
            rotationW = Double(newValue.w)
        }
    }
    
    /// SwiftUI Color
    var color: Color {
        get { NSColor(hex: avatarColor) ?? .blue }
        set { avatarColor = NSCoder.string(for: newValue) ?? "#007AFF" }
    }
    
    /// 更新活跃时间
    func updateActivity() {
        lastActiveAt = Date()
    }
    
    /// 检查是否仍然活跃（30 秒内）
    var isActive: Bool {
        Date().timeIntervalSince(lastActiveAt) < 30
    }
}

// MARK: - AR 元素模型

/// AR 元素数据类型模型
@Model
final class ARElement: Identifiable, Hashable {
    var id: UUID
    var sessionID: UUID
    var creatorID: UUID
    var creatorName: String
    var elementType: ARElementType
    var positionX: Double
    var positionY: Double
    var positionZ: Double
    var rotationX: Double
    var rotationY: Double
    var rotationZ: Double
    var rotationW: Double
    var scaleX: Double
    var scaleY: Double
    var scaleZ: Double
    var colorR: Double
    var colorG: Double
    var colorB: Double
    var colorA: Double
    var metadata: [String: String]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        sessionID: UUID,
        creatorID: UUID,
        creatorName: String,
        elementType: ARElementType,
        position: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
        rotation: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1),
        scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1),
        color: Color = .white,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.sessionID = sessionID
        self.creatorID = creatorID
        self.creatorName = creatorName
        self.elementType = elementType
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.colorR = Double(color.components?.red ?? 1.0)
        self.colorG = Double(color.components?.green ?? 1.0)
        self.colorB = Double(color.components?.blue ?? 1.0)
        self.colorA = Double(color.components?.alpha ?? 1.0)
        self.metadata = metadata
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARElement, rhs: ARElement) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 3D 位置
    var position: SIMD3<Float> {
        get { SIMD3<Float>(Float(positionX), Float(positionY), Float(positionZ)) }
        set {
            positionX = Double(newValue.x)
            positionY = Double(newValue.y)
            positionZ = Double(newValue.z)
        }
    }
    
    /// 四元数旋转
    var rotation: SIMD4<Float> {
        get { SIMD4<Float>(Float(rotationX), Float(rotationY), Float(rotationZ), Float(rotationW)) }
        set {
            rotationX = Double(newValue.x)
            rotationY = Double(newValue.y)
            rotationZ = Double(newValue.z)
            rotationW = Double(newValue.w)
        }
    }
    
    /// 缩放
    var scale: SIMD3<Float> {
        get { SIMD3<Float>(Float(scaleX), Float(scaleY), Float(scaleZ)) }
        set {
            scaleX = Double(newValue.x)
            scaleY = Double(newValue.y)
            scaleZ = Double(newValue.z)
        }
    }
    
    /// SwiftUI Color
    var color: Color {
        get { Color(red: colorR, green: colorG, blue: colorB, opacity: colorA) }
        set {
            let components = newValue.components
            colorR = Double(components?.red ?? 1.0)
            colorG = Double(components?.green ?? 1.0)
            colorB = Double(components?.blue ?? 1.0)
            colorA = Double(components?.alpha ?? 1.0)
        }
    }
    
    /// 更新元素
    func update(
        position: SIMD3<Float>? = nil,
        rotation: SIMD4<Float>? = nil,
        scale: SIMD3<Float>? = nil,
        color: Color? = nil,
        metadata: [String: String]? = nil
    ) {
        if let position = position { self.position = position }
        if let rotation = rotation { self.rotation = rotation }
        if let scale = scale { self.scale = scale }
        if let color = color { self.color = color }
        if let metadata = metadata { self.metadata = metadata }
        updatedAt = Date()
    }
}

// MARK: - AR 元素类型

/// AR 元素类型枚举
enum ARElementType: String, Codable, CaseIterable, Identifiable {
    // 星空主题
    case star = "star"
    case meteor = "meteor"
    case planet = "planet"
    case nebula = "nebula"
    case satellite = "satellite"
    
    // 海洋主题
    case fish = "fish"
    case coral = "coral"
    case bubble = "bubble"
    case seaweed = "seaweed"
    case treasure = "treasure"
    
    // 雪山主题
    case snowflake = "snowflake"
    case cloud = "cloud"
    case bird = "bird"
    case flag = "flag"
    case rock = "rock"
    
    // 森林主题
    case tree = "tree"
    case mushroom = "mushroom"
    case firefly = "firefly"
    case flower = "flower"
    case butterfly = "butterfly"
    
    // 水晶洞穴主题
    case crystal = "crystal"
    case gem = "gem"
    case torch = "torch"
    case stalactite = "stalactite"
    case pool = "pool"
    
    // 天空花园主题
    case rainbow = "rainbow"
    
    // 沙漠主题
    case cactus = "cactus"
    case palm = "palm"
    case oasis = "oasis"
    case sun = "sun"
    case camel = "camel"
    
    // 极光主题
    case aurora = "aurora"
    case lake = "lake"
    case deer = "deer"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .star: return "星星"
        case .meteor: return "流星"
        case .planet: return "行星"
        case .nebula: return "星云"
        case .satellite: return "卫星"
        case .fish: return "鱼"
        case .coral: return "珊瑚"
        case .bubble: return "气泡"
        case .seaweed: return "海草"
        case .treasure: return "宝藏"
        case .snowflake: return "雪花"
        case .cloud: return "云朵"
        case .bird: return "鸟"
        case .flag: return "旗帜"
        case .rock: return "岩石"
        case .tree: return "树"
        case .mushroom: return "蘑菇"
        case .firefly: return "萤火虫"
        case .flower: return "花"
        case .butterfly: return "蝴蝶"
        case .crystal: return "水晶"
        case .gem: return "宝石"
        case .torch: return "火把"
        case .stalactite: return "钟乳石"
        case .pool: return "水池"
        case .rainbow: return "彩虹"
        case .cactus: return "仙人掌"
        case .palm: return "棕榈树"
        case .oasis: return "绿洲"
        case .sun: return "太阳"
        case .camel: return "骆驼"
        case .aurora: return "极光"
        case .lake: return "湖泊"
        case .deer: return "鹿"
        }
    }
    
    var icon: String {
        switch self {
        case .star, .meteor: return "star.fill"
        case .planet: return "circle.fill"
        case .nebula, .cloud: return "cloud.fill"
        case .satellite: return "antenna.radiowaves.left.and.right"
        case .fish: return "fish.fill"
        case .coral, .tree, .seaweed, .palm, .cactus: return "tree.fill"
        case .bubble: return "circle"
        case .treasure, .gem, .crystal: return "gemstone.fill"
        case .snowflake: return "snowflake"
        case .bird, .butterfly, .firefly: return "bird.fill"
        case .flag: return "flag.fill"
        case .rock, .stalactite: return "rock.fill"
        case .mushroom: return "circle.fill"
        case .flower: return "flower.open.fill"
        case .torch: return "light.beacon.min.fill"
        case .pool, .lake, .oasis: return "water.waves"
        case .rainbow: return "rainbow"
        case .sun: return "sun.max.fill"
        case .camel, .deer: return "hare.fill"
        case .aurora: return "cloud.bolt.fill"
        }
    }
}

// MARK: - AR 消息模型

/// AR 消息数据模型
@Model
final class ARMessage: Identifiable, Hashable {
    var id: UUID
    var sessionID: UUID
    var senderID: UUID
    var senderName: String
    var messageType: ARMessageType
    var content: String
    var positionX: Double?
    var positionY: Double?
    var positionZ: Double?
    var targetElementID: UUID?
    var createdAt: Date
    var expiresAt: Date?
    var isRead: Bool
    
    init(
        id: UUID = UUID(),
        sessionID: UUID,
        senderID: UUID,
        senderName: String,
        messageType: ARMessageType,
        content: String,
        position: SIMD3<Float>? = nil,
        targetElementID: UUID? = nil,
        expiresInSeconds: Int? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.senderID = senderID
        self.senderName = senderName
        self.messageType = messageType
        self.content = content
        self.positionX = position?.x.map { Double($0) }
        self.positionY = position?.y.map { Double($0) }
        self.positionZ = position?.z.map { Double($0) }
        self.targetElementID = targetElementID
        self.createdAt = Date()
        self.expiresAt = expiresInSeconds.map { Date().addingTimeInterval(Double($0)) }
        self.isRead = false
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARMessage, rhs: ARMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    /// 3D 位置（可选）
    var position: SIMD3<Float>? {
        get {
            guard let x = positionX, let y = positionY, let z = positionZ else { return nil }
            return SIMD3<Float>(Float(x), Float(y), Float(z))
        }
        set {
            positionX = newValue?.x.map { Double($0) }
            positionY = newValue?.y.map { Double($0) }
            positionZ = newValue?.z.map { Double($0) }
        }
    }
    
    /// 检查消息是否已过期
    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
}

// MARK: - AR 消息类型

/// AR 消息类型枚举
enum ARMessageType: String, Codable, CaseIterable {
    case text = "text"              // 文本消息
    case emoji = "emoji"            // 表情符号
    case reaction = "reaction"      // 反应（点赞/爱心等）
    case system = "system"          // 系统消息
    case interaction = "interaction" // 互动消息
    
    var displayName: String {
        switch self {
        case .text: return "文本"
        case .emoji: return "表情"
        case .reaction: return "反应"
        case .system: return "系统"
        case .interaction: return "互动"
        }
    }
}

// MARK: - AR 互动模型

/// AR 互动数据模型
@Model
final class ARInteraction: Identifiable, Hashable {
    var id: UUID
    var sessionID: UUID
    var actorID: UUID
    var actorName: String
    var targetID: UUID
    var targetType: ARInteractionTargetType
    var interactionType: ARInteractionType
    var timestamp: Date
    var metadata: [String: String]
    
    init(
        id: UUID = UUID(),
        sessionID: UUID,
        actorID: UUID,
        actorName: String,
        targetID: UUID,
        targetType: ARInteractionTargetType,
        interactionType: ARInteractionType,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.sessionID = sessionID
        self.actorID = actorID
        self.actorName = actorName
        self.targetID = targetID
        self.targetType = targetType
        self.interactionType = interactionType
        self.timestamp = Date()
        self.metadata = metadata
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARInteraction, rhs: ARInteraction) -> Bool {
        lhs.id == rhs.id
    }
}

/// AR 互动目标类型
enum ARInteractionTargetType: String, Codable {
    case participant = "participant"  // 参与者
    case element = "element"          // 元素
    case session = "session"          // 会话
}

/// AR 互动类型
enum ARInteractionType: String, Codable, CaseIterable {
    case tap = "tap"                  // 点击
    case wave = "wave"                // 挥手
    case send = "send"                // 发送物品
    case invite = "invite"            // 邀请
    case join = "join"                // 加入
    case leave = "leave"              // 离开
    case create = "create"            // 创建
    case remove = "remove"            // 删除
    case transform = "transform"      // 变换
    
    var displayName: String {
        switch self {
        case .tap: return "点击"
        case .wave: return "挥手"
        case .send: return "发送"
        case .invite: return "邀请"
        case .join: return "加入"
        case .leave: return "离开"
        case .create: return "创建"
        case .remove: return "删除"
        case .transform: return "变换"
        }
    }
}

// MARK: - 辅助类型

/// 会话状态枚举
enum ARSessionState: String, Codable {
    case disconnected = "disconnected"  // 未连接
    case connecting = "connecting"      // 连接中
    case connected = "connected"        // 已连接
    case hosting = "hosting"            // 作为主机
    case joined = "joined"              // 已加入
    case error = "error"                // 错误
}

/// 参与者状态
struct ParticipantState: Codable {
    let participantID: UUID
    let displayName: String
    let position: SIMD3<Float>
    let rotation: SIMD4<Float>
    let lastActiveAt: Date
    let isHost: Bool
    let isMuted: Bool
    
    var isActive: Bool {
        Date().timeIntervalSince(lastActiveAt) < 30
    }
}

/// 同步数据包
struct ARSyncPacket: Codable {
    let type: ARSyncPacketType
    let sessionID: UUID
    let timestamp: Date
    let data: Data
    
    enum ARSyncPacketType: String, Codable {
        case participantUpdate = "participant_update"
        case elementCreate = "element_create"
        case elementUpdate = "element_update"
        case elementDelete = "element_delete"
        case message = "message"
        case interaction = "interaction"
        case sessionState = "session_state"
    }
}

// MARK: - Color 扩展

extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard let components = NSColor(self).cgColor.components else { return nil }
        
        if components.count == 2 {
            // Grayscale
            let value = components[0]
            return (red: value, green: value, blue: value, alpha: components[1])
        } else if components.count >= 3 {
            return (
                red: components[0],
                green: components[1],
                blue: components[2],
                alpha: components.count > 3 ? components[3] : 1.0
            )
        }
        
        return nil
    }
}

extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        let a = CGFloat(1.0)
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    var hexString: String {
        guard let components = cgColor.components else { return "#000000" }
        
        if components.count >= 3 {
            let r = Int(components[0] * 255)
            let g = Int(components[1] * 255)
            let b = Int(components[2] * 255)
            return String(format: "#%02X%02X%02X", r, g, b)
        }
        
        return "#000000"
    }
}
