//
//  DreamARElement3D.swift
//  DreamLog
//
//  Phase 22 - 3D 梦境元素模型
//  创建时间：2026-03-12
//

import Foundation
import SwiftUI
import RealityKit

// MARK: - 3D 梦境元素模型

/// 3D 梦境元素 - 扩展自 Phase 21 的 ARElement
struct DreamARElement3D: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var nameLocalizable: String {
        return name
    }
    
    /// 元素类型
    var elementType: ARDreamElementType
    
    /// 3D 模型 URL（本地或远程）
    var modelURL: URL?
    
    /// 缩略图 URL
    var thumbnailURL: URL?
    
    /// 模型类别
    var category: ModelCategory
    
    /// 位置（世界坐标）
    var position: SIMD3<Float>
    
    /// 旋转（四元数）
    var rotation: SIMD4<Float>
    
    /// 缩放比例
    var scale: CGFloat
    
    /// 材质配置
    var material: MaterialConfig
    
    /// 动画配置
    var animation: ARAnimationType?
    
    /// 是否被选中
    var isSelected: Bool
    
    /// 是否可交互
    var isInteractive: Bool
    
    /// 是否已收藏
    var isFavorite: Bool
    
    /// 下载状态
    var downloadStatus: DownloadStatus
    
    /// 创建时间
    var createdAt: Date
    
    /// 最后修改时间
    var modifiedAt: Date
    
    /// 用户信息字典（用于存储额外数据，如 LOD 级别）
    var userInfo: [String: String] = [:]
    
    init(
        id: UUID = UUID(),
        name: String,
        elementType: ARDreamElementType,
        modelURL: URL? = nil,
        thumbnailURL: URL? = nil,
        category: ModelCategory,
        position: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
        rotation: SIMD4<Float> = SIMD4<Float>(0, 0, 0, 1),
        scale: CGFloat = 1.0,
        material: MaterialConfig = MaterialConfig(),
        animation: ARAnimationType? = nil,
        isSelected: Bool = false,
        isInteractive: Bool = true,
        isFavorite: Bool = false,
        downloadStatus: DownloadStatus = .notDownloaded,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.elementType = elementType
        self.modelURL = modelURL
        self.thumbnailURL = thumbnailURL
        self.category = category
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.material = material
        self.animation = animation
        self.isSelected = isSelected
        self.isInteractive = isInteractive
        self.isFavorite = isFavorite
        self.downloadStatus = downloadStatus
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.userInfo = [:]
    }
    
    /// 从 Phase 21 的 ARDreamElement 转换
    init(from arElement: ARDreamElement) {
        self.id = arElement.id
        self.name = arElement.name
        self.elementType = arElement.type
        self.category = ModelCategory(from: arElement.type)
        self.position = arElement.position
        self.rotation = arElement.rotation
        self.scale = CGFloat(arElement.scale.x)
        self.material = MaterialConfig()
        self.animation = arElement.animation
        self.isSelected = false
        self.isInteractive = true
        self.isFavorite = false
        self.downloadStatus = .notDownloaded
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.userInfo = [:]
    }
    
    /// 转换为 Phase 21 的 ARDreamElement
    func toARElement() -> ARDreamElement {
        var element = ARDreamElement(type: self.elementType, name: self.name, description: self.name)
        element.position = self.position
        element.scale = SIMD3<Float>(Float(self.scale), Float(self.scale), Float(self.scale))
        element.rotation = self.rotation
        element.animation = self.animation
        return element
    }
    
    /// 哈希值
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// 相等比较
    static func == (lhs: DreamARElement3D, rhs: DreamARElement3D) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 模型类别

enum ModelCategory: String, Codable, CaseIterable, Identifiable {
    case nature = "自然"
    case animal = "动物"
    case person = "人物"
    case building = "建筑"
    case abstract = "抽象"
    case dreamSymbol = "梦境符号"
    
    var id: String { rawValue }
    
    /// 类别显示名称
    var displayName: String { rawValue }
    
    /// 类别图标
    var icon: String {
        switch self {
        case .nature: return "leaf.fill"
        case .animal: return "paw.fill"
        case .person: return "person.fill"
        case .building: return "house.fill"
        case .abstract: return "cube.box.fill"
        case .dreamSymbol: return "moon.stars.fill"
        }
    }
    
    /// 类别颜色
    var color: Color {
        switch self {
        case .nature: return .green
        case .animal: return .orange
        case .person: return .blue
        case .building: return .gray
        case .abstract: return .purple
        case .dreamSymbol: return .indigo
        }
    }
    
    /// 从 ARDreamElementType 转换
    init(from arType: ARDreamElementType) {
        switch arType {
        case .water, .wind, .earth, .nature:
            self = .nature
        case .animal:
            self = .animal
        case .human:
            self = .person
        case .building, .vehicle:
            self = .building
        case .light, .dark, .abstract:
            self = .abstract
        case .fire:
            self = .dreamSymbol
        }
    }
    
    /// 类别描述
    var description: String {
        switch self {
        case .nature: return "树木、花草、山水等自然元素"
        case .animal: return "鸟类、昆虫、哺乳动物等"
        case .person: return "人形、手势、面部表情等"
        case .building: return "房屋、门窗、建筑等"
        case .abstract: return "几何体、粒子、光效等"
        case .dreamSymbol: return "月亮、星星、钥匙等梦境符号"
        }
    }
    
    /// 模型数量（动态获取）
    var modelCount: Int {
        // 实际实现中从模型库获取
        return 0
    }
}

// MARK: - 材质配置

struct MaterialConfig: Codable, Hashable {
    /// 基础颜色
    var color: ColorRepresentable
    
    /// 金属度 (0-1)
    var metallic: CGFloat
    
    /// 粗糙度 (0-1)
    var roughness: CGFloat
    
    /// 透明度 (0-1)
    var opacity: CGFloat
    
    /// 自发光强度 (0-1)
    var emissiveIntensity: CGFloat
    
    /// 自发光颜色
    var emissiveColor: ColorRepresentable?
    
    /// 法线贴图 URL
    var normalMapURL: URL?
    
    /// 粗糙度贴图 URL
    var roughnessMapURL: URL?
    
    /// 金属度贴图 URL
    var metallicMapURL: URL?
    
    init(
        color: ColorRepresentable = ColorRepresentable(.white),
        metallic: CGFloat = 0.0,
        roughness: CGFloat = 0.5,
        opacity: CGFloat = 1.0,
        emissiveIntensity: CGFloat = 0.0,
        emissiveColor: ColorRepresentable? = nil,
        normalMapURL: URL? = nil,
        roughnessMapURL: URL? = nil,
        metallicMapURL: URL? = nil
    ) {
        self.color = color
        self.metallic = metallic
        self.roughness = roughness
        self.opacity = opacity
        self.emissiveIntensity = emissiveIntensity
        self.emissiveColor = emissiveColor
        self.normalMapURL = normalMapURL
        self.roughnessMapURL = roughnessMapURL
        self.metallicMapURL = metallicMapURL
    }
    
    /// 预设材质
    static let `default` = MaterialConfig()
    
    static let metal = MaterialConfig(
        metallic: 0.9,
        roughness: 0.2
    )
    
    static let glass = MaterialConfig(
        opacity: 0.3,
        roughness: 0.1
    )
    
    static let emissive = MaterialConfig(
        emissiveIntensity: 1.0,
        emissiveColor: ColorRepresentable(.blue)
    )
    
    static let matte = MaterialConfig(
        roughness: 0.9
    )
}

// MARK: - 颜色表示（可编码）

struct ColorRepresentable: Codable, Hashable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat
    
    init(_ color: Color) {
        // 简化实现，实际需要使用 UIColor 转换
        self.red = 1.0
        self.green = 1.0
        self.blue = 1.0
        self.alpha = 1.0
    }
    
    init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    static let white = ColorRepresentable(red: 1, green: 1, blue: 1)
    static let black = ColorRepresentable(red: 0, green: 0, blue: 0)
    static let red = ColorRepresentable(red: 1, green: 0, blue: 0)
    static let green = ColorRepresentable(red: 0, green: 1, blue: 0)
    static let blue = ColorRepresentable(red: 0, green: 0, blue: 1)
}

// MARK: - 下载状态

enum DownloadStatus: Codable, Hashable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(error: String)
    
    var isDownloaded: Bool {
        if case .downloaded = self { return true }
        return false
    }
    
    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
    
    var progress: Double {
        if case .downloading(let progress) = self { return progress }
        return isDownloaded ? 1.0 : 0.0
    }
}

// MARK: - AR 场景模板

struct DreamARTemplate: Codable, Identifiable {
    var id: UUID
    var name: String
    var nameLocalizable: String {
        return name
    }
    var description: String
    var category: TemplateCategory
    var thumbnailURL: URL?
    var previewImageURL: URL?
    
    /// 模板包含的元素
    var elements: [DreamARElement3D]
    
    /// 环境类型
    var environment: AREnvironmentType
    
    /// 灯光预设
    var lighting: ARLightingPreset
    
    /// 难度等级
    var difficulty: TemplateDifficulty
    
    /// 预计创建时间（秒）
    var estimatedTime: TimeInterval
    
    /// 是否付费模板
    var isPremium: Bool
    
    /// 下载次数
    var downloadCount: Int
    
    /// 评分 (0-5)
    var rating: Double
    
    /// 是否已收藏
    var isFavorite: Bool
    
    /// 创建者
    var creator: String?
    
    /// 创建时间
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: TemplateCategory,
        thumbnailURL: URL? = nil,
        previewImageURL: URL? = nil,
        elements: [DreamARElement3D] = [],
        environment: AREnvironmentType = .default,
        lighting: ARLightingPreset = .natural,
        difficulty: TemplateDifficulty = .easy,
        estimatedTime: TimeInterval = 30,
        isPremium: Bool = false,
        downloadCount: Int = 0,
        rating: Double = 0.0,
        isFavorite: Bool = false,
        creator: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.thumbnailURL = thumbnailURL
        self.previewImageURL = previewImageURL
        self.elements = elements
        self.environment = environment
        self.lighting = lighting
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.isPremium = isPremium
        self.downloadCount = downloadCount
        self.rating = rating
        self.isFavorite = isFavorite
        self.creator = creator
        self.createdAt = createdAt
    }
}

// MARK: - 模板类别

enum TemplateCategory: String, Codable, CaseIterable, Identifiable {
    case starrySky = "星空梦境"
    case oceanWorld = "海洋世界"
    case forestSecret = "森林秘境"
    case magicSpace = "魔法空间"
    case fairytaleCastle = "童话城堡"
    case abstractArt = "抽象艺术"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .starrySky: return "moon.stars.fill"
        case .oceanWorld: return "water.fill"
        case .forestSecret: return "tree.fill"
        case .magicSpace: return "wand.and.stars"
        case .fairytaleCastle: return "castle.fill"
        case .abstractArt: return "paintpalette.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .starrySky: return .indigo
        case .oceanWorld: return .blue
        case .forestSecret: return .green
        case .magicSpace: return .purple
        case .fairytaleCastle: return .pink
        case .abstractArt: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .starrySky: return "星星、月亮、银河组成的梦幻星空"
        case .oceanWorld: return "水母、鱼群、气泡的海洋世界"
        case .forestSecret: return "树木、花朵、小动物的森林秘境"
        case .magicSpace: return "水晶球、魔法阵、光效的魔法空间"
        case .fairytaleCastle: return "城堡、云朵、彩虹的童话世界"
        case .abstractArt: return "几何体、色彩、粒子的抽象艺术"
        }
    }
}

// MARK: - 模板难度

enum TemplateDifficulty: String, Codable, CaseIterable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    
    var icon: String {
        switch self {
        case .easy: return "hare.fill"
        case .medium: return "tortoise.fill"
        case .hard: return "flame.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    var elementCount: String {
        switch self {
        case .easy: return "5-10 个元素"
        case .medium: return "10-20 个元素"
        case .hard: return "20+ 个元素"
        }
    }
}

// MARK: - AR 分享会话

struct DreamARShareSession: Codable, Identifiable {
    var id: UUID
    var sceneID: UUID
    var sceneName: String
    
    /// 主机用户 ID
    var hostUserID: String
    
    /// 分享码（短码，方便输入）
    var shareCode: String
    
    /// 分享链接
    var shareURL: URL?
    
    /// 过期时间
    var expireAt: Date
    
    /// 最大参与人数
    var maxParticipants: Int
    
    /// 当前参与者
    var currentParticipants: [ARParticipant]
    
    /// 权限配置
    var permissions: SharePermissions
    
    /// 聊天消息
    var chatMessages: [ARChatMessage]
    
    /// 是否活跃
    var isActive: Bool
    
    /// 创建时间
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        sceneID: UUID,
        sceneName: String,
        hostUserID: String,
        shareCode: String,
        shareURL: URL? = nil,
        expireAt: Date = Date().addingTimeInterval(3600 * 24), // 默认 24 小时
        maxParticipants: Int = 10,
        currentParticipants: [ARParticipant] = [],
        permissions: SharePermissions = SharePermissions(),
        chatMessages: [ARChatMessage] = [],
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.sceneID = sceneID
        self.sceneName = sceneName
        self.hostUserID = hostUserID
        self.shareCode = shareCode
        self.shareURL = shareURL
        self.expireAt = expireAt
        self.maxParticipants = maxParticipants
        self.currentParticipants = currentParticipants
        self.permissions = permissions
        self.chatMessages = chatMessages
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    /// 生成随机分享码
    static func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let charArray = Array(chars)
        return String((0..<6).map { _ in charArray.randomElement() ?? "A" })
    }
    
    /// 是否已过期
    var isExpired: Bool {
        Date() > expireAt
    }
    
    /// 是否已满员
    var isFull: Bool {
        currentParticipants.count >= maxParticipants
    }
}

// MARK: - 参与者

struct ARParticipant: Codable, Identifiable {
    var id: UUID
    var userID: String
    var username: String
    var avatarURL: URL?
    var joinedAt: Date
    var role: ARParticipantRole
    var position: SIMD3<Float>?
    var isOnline: Bool
    
    init(
        id: UUID = UUID(),
        userID: String,
        username: String,
        avatarURL: URL? = nil,
        joinedAt: Date = Date(),
        role: ARParticipantRole = .viewer,
        position: SIMD3<Float>? = nil,
        isOnline: Bool = true
    ) {
        self.id = id
        self.userID = userID
        self.username = username
        self.avatarURL = avatarURL
        self.joinedAt = joinedAt
        self.role = role
        self.position = position
        self.isOnline = isOnline
    }
}

enum ARParticipantRole: String, Codable {
    case host = "主机"
    case editor = "编辑者"
    case viewer = "观看者"
}

// MARK: - 分享权限

struct SharePermissions: Codable {
    /// 允许查看
    var canView: Bool
    
    /// 允许编辑
    var canEdit: Bool
    
    /// 允许添加元素
    var canAddElements: Bool
    
    /// 允许删除元素
    var canDeleteElements: Bool
    
    /// 允许聊天
    var canChat: Bool
    
    /// 允许邀请他人
    var canInvite: Bool
    
    init(
        canView: Bool = true,
        canEdit: Bool = false,
        canAddElements: Bool = false,
        canDeleteElements: Bool = false,
        canChat: Bool = true,
        canInvite: Bool = false
    ) {
        self.canView = canView
        self.canEdit = canEdit
        self.canAddElements = canAddElements
        self.canDeleteElements = canDeleteElements
        self.canChat = canChat
        self.canInvite = canInvite
    }
    
    /// 编辑者权限
    static let editor = SharePermissions(
        canView: true,
        canEdit: true,
        canAddElements: true,
        canDeleteElements: true,
        canChat: true,
        canInvite: true
    )
    
    /// 观看者权限
    static let viewer = SharePermissions(
        canView: true,
        canEdit: false,
        canAddElements: false,
        canDeleteElements: false,
        canChat: true,
        canInvite: false
    )
}

// MARK: - 聊天消息

struct ARChatMessage: Codable, Identifiable {
    var id: UUID
    var userID: String
    var username: String
    var message: String
    var timestamp: Date
    var messageType: ChatMessageType
    
    init(
        id: UUID = UUID(),
        userID: String,
        username: String,
        message: String,
        timestamp: Date = Date(),
        messageType: ChatMessageType = .text
    ) {
        self.id = id
        self.userID = userID
        self.username = username
        self.message = message
        self.timestamp = timestamp
        self.messageType = messageType
    }
}

enum ChatMessageType: String, Codable {
    case text
    case system
    case emoji
}
