//
//  DreamARFaceTracking.swift
//  DreamLog
//
//  面部追踪集成 - Phase 24
//  使用 ARKit 的面部追踪功能，实现表情驱动的 AR 元素动画
//

import Foundation
import ARKit
import Combine

// MARK: - 面部表情数据模型

/// 面部混合形状 (Blendshape) 数据
struct FaceBlendshapeData: Codable, Equatable {
    /// 混合形状名称
    let name: String
    
    /// 混合形状值 (0.0 - 1.0)
    let value: Float
    
    /// 显示名称
    var displayName: String {
        switch name {
        case ARFaceAnchor.BlendShapeLocation.eyeBlinkLeft.rawValue: return "左眼眨眼"
        case ARFaceAnchor.BlendShapeLocation.eyeBlinkRight.rawValue: return "右眼眨眼"
        case ARFaceAnchor.BlendShapeLocation.eyeLookInLeft.rawValue: return "左眼内转"
        case ARFaceAnchor.BlendShapeLocation.eyeLookInRight.rawValue: return "右眼内转"
        case ARFaceAnchor.BlendShapeLocation.eyeLookOutLeft.rawValue: return "左眼外转"
        case ARFaceAnchor.BlendShapeLocation.eyeLookOutRight.rawValue: return "右眼外转"
        case ARFaceAnchor.BlendShapeLocation.eyeLookDownLeft.rawValue: return "左眼下视"
        case ARFaceAnchor.BlendShapeLocation.eyeLookDownRight.rawValue: return "右眼下视"
        case ARFaceAnchor.BlendShapeLocation.eyeLookUpLeft.rawValue: return "左眼上视"
        case ARFaceAnchor.BlendShapeLocation.eyeLookUpRight.rawValue: return "右眼上视"
        case ARFaceAnchor.BlendShapeLocation.eyeSquintLeft.rawValue: return "左眼眯眼"
        case ARFaceAnchor.BlendShapeLocation.eyeSquintRight.rawValue: return "右眼眯眼"
        case ARFaceAnchor.BlendShapeLocation.eyeWideLeft.rawValue: return "左眼睁大"
        case ARFaceAnchor.BlendShapeLocation.eyeWideRight.rawValue: return "右眼睁大"
        case ARFaceAnchor.BlendShapeLocation.noseSneerLeft.rawValue: return "左鼻翼皱起"
        case ARFaceAnchor.BlendShapeLocation.noseSneerRight.rawValue: return "右鼻翼皱起"
        case ARFaceAnchor.BlendShapeLocation.cheekPuffLeft.rawValue: return "左腮鼓起"
        case ARFaceAnchor.BlendShapeLocation.cheekPuffRight.rawValue: return "右腮鼓起"
        case ARFaceAnchor.BlendShapeLocation.cheekSquintLeft.rawValue: return "左脸颊眯起"
        case ARFaceAnchor.BlendShapeLocation.cheekSquintRight.rawValue: return "右脸颊眯起"
        case ARFaceAnchor.BlendShapeLocation.lipsClose.rawValue: return "嘴唇闭合"
        case ARFaceAnchor.BlendShapeLocation.lipsPress.rawValue: return "嘴唇压紧"
        case ARFaceAnchor.BlendShapeLocation.lipsStretch.rawValue: return "嘴唇拉伸"
        case ARFaceAnchor.BlendShapeLocation.lipsFunnel.rawValue: return "嘴唇聚拢"
        case ARFaceAnchor.BlendShapeLocation.lipsPucker.rawValue: return "嘴唇撅起"
        case ARFaceAnchor.BlendShapeLocation.lipsPart.rawValue: return "嘴唇分开"
        case ARFaceAnchor.BlendShapeLocation.jawOpen.rawValue: return "下巴张开"
        case ARFaceAnchor.BlendShapeLocation.jawForward.rawValue: return "下巴前伸"
        case ARFaceAnchor.BlendShapeLocation.jawLeft.rawValue: return "下巴左移"
        case ARFaceAnchor.BlendShapeLocation.jawRight.rawValue: return "下巴右移"
        case ARFaceAnchor.BlendShapeLocation.mouthSmileLeft.rawValue: return "左嘴角微笑"
        case ARFaceAnchor.BlendShapeLocation.mouthSmileRight.rawValue: return "右嘴角微笑"
        case ARFaceAnchor.BlendShapeLocation.mouthFrownLeft.rawValue: return "左嘴角皱眉"
        case ARFaceAnchor.BlendShapeLocation.mouthFrownRight.rawValue: return "右嘴角皱眉"
        case ARFaceAnchor.BlendShapeLocation.mouthDimpleLeft.rawValue: return "左酒窝"
        case ARFaceAnchor.BlendShapeLocation.mouthDimpleRight.rawValue: return "右酒窝"
        case ARFaceAnchor.BlendShapeLocation.mouthUpperUpLeft.rawValue: return "左上唇上提"
        case ARFaceAnchor.BlendShapeLocation.mouthUpperUpRight.rawValue: return "右上唇上提"
        case ARFaceAnchor.BlendShapeLocation.mouthLowerDownLeft.rawValue: return "左下唇下拉"
        case ARFaceAnchor.BlendShapeLocation.mouthLowerDownRight.rawValue: return "右下唇下拉"
        case ARFaceAnchor.BlendShapeLocation.mouthPressLeft.rawValue: return "左嘴唇压紧"
        case ARFaceAnchor.BlendShapeLocation.mouthPressRight.rawValue: return "右嘴唇压紧"
        case ARFaceAnchor.BlendShapeLocation.mouthShrugLower.rawValue: return "下唇耸起"
        case ARFaceAnchor.BlendShapeLocation.mouthShrugUpper.rawValue: return "上唇耸起"
        case ARFaceAnchor.BlendShapeLocation.tongueOut.rawValue: return "伸舌头"
        default: return name
        }
    }
}

/// 面部表情状态
struct FaceExpressionState: Codable, Equatable {
    /// 时间戳
    let timestamp: Date
    
    /// 所有混合形状数据
    let blendshapes: [FaceBlendshapeData]
    
    /// 面部变换矩阵
    let transform: simd_float4x4
    
    /// 是否检测到面部
    let isFaceDetected: Bool
    
    /// 面部置信度 (0.0 - 1.0)
    let confidence: Float
    
    /// 主要表情类型
    var primaryExpression: FaceExpressionType {
        // 分析混合形状确定主要表情
        let smileLeft = blendshapes.first { $0.name == ARFaceAnchor.BlendShapeLocation.mouthSmileLeft.rawValue }?.value ?? 0
        let smileRight = blendshapes.first { $0.name == ARFaceAnchor.BlendShapeLocation.mouthSmileRight.rawValue }?.value ?? 0
        let jawOpen = blendshapes.first { $0.name == ARFaceAnchor.BlendShapeLocation.jawOpen.rawValue }?.value ?? 0
        let eyeWideLeft = blendshapes.first { $0.name == ARFaceAnchor.BlendShapeLocation.eyeWideLeft.rawValue }?.value ?? 0
        let eyeWideRight = blendshapes.first { $0.name == ARFaceAnchor.BlendShapeLocation.eyeWideRight.rawValue }?.value ?? 0
        let browsInnerUp = blendshapes.first { $0.name == "browInnerUp" }?.value ?? 0
        
        let smileAverage = (smileLeft + smileRight) / 2
        
        if smileAverage > 0.5 {
            return .happy
        } else if jawOpen > 0.5 && eyeWideLeft > 0.3 && eyeWideRight > 0.3 {
            return .surprised
        } else if browsInnerUp > 0.4 {
            return .sad
        } else if jawOpen > 0.6 {
            return .excited
        } else {
            return .neutral
        }
    }
}

/// 面部表情类型
enum FaceExpressionType: String, Codable, CaseIterable {
    case neutral = "neutral"           // 中性
    case happy = "happy"               // 开心
    case sad = "sad"                   // 悲伤
    case surprised = "surprised"       // 惊讶
    case excited = "excited"           // 兴奋
    
    var displayName: String {
        switch self {
        case .neutral: return "😐 中性"
        case .happy: return "😊 开心"
        case .sad: return "😢 悲伤"
        case .surprised: return "😲 惊讶"
        case .excited: return "🤩 兴奋"
        }
    }
    
    var emoji: String {
        switch self {
        case .neutral: return "😐"
        case .happy: return "😊"
        case .sad: return "😢"
        case .surprised: return "😲"
        case .excited: return "🤩"
        }
    }
}

// MARK: - 面部追踪配置

/// 面部追踪配置
struct FaceTrackingConfig: Codable {
    /// 是否启用面部追踪
    var isEnabled: Bool
    
    /// 是否启用表情驱动动画
    var enableExpressionAnimation: Bool
    
    /// 是否启用虚拟化身
    var enableAvatar: Bool
    
    /// 表情灵敏度 (0.0 - 1.0)
    var expressionSensitivity: Float
    
    /// 是否记录表情历史
    var recordExpressionHistory: Bool
    
    /// 最大历史记录数
    var maxHistoryCount: Int
    
    /// 默认配置
    static let `default` = FaceTrackingConfig(
        isEnabled: false,
        enableExpressionAnimation: true,
        enableAvatar: true,
        expressionSensitivity: 0.7,
        recordExpressionHistory: true,
        maxHistoryCount: 100
    )
}

// MARK: - 虚拟化身模型

/// 虚拟化身模型数据
struct AvatarModel: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let thumbnailName: String
    let category: AvatarCategory
    let isUnlocked: Bool
    let unlockCondition: String?
    
    enum AvatarCategory: String, Codable, CaseIterable {
        case basic = "basic"           // 基础
        case animal = "animal"         // 动物
        case fantasy = "fantasy"       // 奇幻
        case robot = "robot"           // 机器人
        case custom = "custom"         // 自定义
        
        var displayName: String {
            switch self {
            case .basic: return "👤 基础"
            case .animal: return "🦋 动物"
            case .fantasy: return "🧚 奇幻"
            case .robot: return "🤖 机器人"
            case .custom: return "🎨 自定义"
            }
        }
    }
    
    /// 预设虚拟化身
    static let presets: [AvatarModel] = [
        AvatarModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "基础人脸",
            description: "标准人脸模型，适合日常使用",
            thumbnailName: "avatar_basic",
            category: .basic,
            isUnlocked: true,
            unlockCondition: nil
        ),
        AvatarModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "快乐精灵",
            description: "带有翅膀的精灵形象",
            thumbnailName: "avatar_elf",
            category: .fantasy,
            isUnlocked: false,
            unlockCondition: "连续记录 7 天"
        ),
        AvatarModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "机械战警",
            description: "未来科技感机器人",
            thumbnailName: "avatar_robot",
            category: .robot,
            isUnlocked: false,
            unlockCondition: "创建 10 个 AR 场景"
        ),
        AvatarModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "熊猫宝宝",
            description: "可爱的熊猫形象",
            thumbnailName: "avatar_panda",
            category: .animal,
            isUnlocked: false,
            unlockCondition: "记录 50 个梦境"
        ),
        AvatarModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "星空使者",
            description: "星空主题的奇幻形象",
            thumbnailName: "avatar_stars",
            category: .fantasy,
            isUnlocked: false,
            unlockCondition: "完成所有清醒梦训练"
        )
    ]
}

// MARK: - 面部追踪服务

/// 面部追踪服务
@MainActor
final class DreamARFaceTrackingService: ObservableObject {
    static let shared = DreamARFaceTrackingService()
    
    // MARK: - Published Properties
    
    /// 当前面部表情状态
    @Published var currentFaceState: FaceExpressionState?
    
    /// 面部表情历史
    @Published var expressionHistory: [FaceExpressionState] = []
    
    /// 是否正在追踪面部
    @Published var isTracking: Bool = false
    
    /// 当前虚拟化身
    @Published var currentAvatar: AvatarModel?
    
    /// 配置
    @Published var config: FaceTrackingConfig = .default
    
    /// 错误信息
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let session = ARFaceTrackingSession()
    private var cancellables = Set<AnyCancellable>()
    private let historyQueue = DispatchQueue(label: "com.dreamlog.faceTracking.history")
    
    // MARK: - 初始化
    
    private init() {
        setupSession()
        loadConfig()
    }
    
    // MARK: - 会话设置
    
    private func setupSession() {
        session.delegate = self
        session.runConfiguration = {
            let configuration = ARFaceTrackingConfiguration()
            configuration.isLightEstimationEnabled = true
            return configuration
        }()
    }
    
    // MARK: - 公共方法
    
    /// 开始面部追踪
    func startTracking() {
        guard config.isEnabled else {
            errorMessage = "面部追踪未启用"
            return
        }
        
        guard ARFaceTrackingConfiguration.isSupported else {
            errorMessage = "设备不支持面部追踪"
            return
        }
        
        session.run()
        isTracking = true
        errorMessage = nil
    }
    
    /// 停止面部追踪
    func stopTracking() {
        session.pause()
        isTracking = false
    }
    
    /// 更新配置
    func updateConfig(_ newConfig: FaceTrackingConfig) {
        config = newConfig
        saveConfig()
        
        if !config.isEnabled && isTracking {
            stopTracking()
        }
    }
    
    /// 设置虚拟化身
    func setAvatar(_ avatar: AvatarModel?) {
        currentAvatar = avatar
        UserDefaults.standard.set(avatar?.id.uuidString, forKey: "DreamARFaceTracking.currentAvatarId")
    }
    
    /// 获取表情驱动的动画参数
    func getAnimationParameters() -> [String: Float] {
        guard let faceState = currentFaceState,
              config.enableExpressionAnimation else {
            return [:]
        }
        
        var params: [String: Float] = [:]
        
        // 提取关键表情参数
        for blendshape in faceState.blendshapes {
            let adjustedValue = blendshape.value * config.expressionSensitivity
            params[blendshape.name] = adjustedValue
        }
        
        return params
    }
    
    /// 记录表情到历史
    private func recordToHistory(_ state: FaceExpressionState) {
        guard config.recordExpressionHistory else { return }
        
        historyQueue.async { [weak self] in
            guard let self = self else { return }
            
            var history = self.expressionHistory
            history.append(state)
            
            // 限制历史记录数量
            if history.count > self.config.maxHistoryCount {
                history.removeFirst(history.count - self.config.maxHistoryCount)
            }
            
            DispatchQueue.main.async {
                self.expressionHistory = history
            }
        }
    }
    
    // MARK: - 配置管理
    
    private func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "DreamARFaceTracking.config")
        }
    }
    
    private func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "DreamARFaceTracking.config"),
           let decoded = try? JSONDecoder().decode(FaceTrackingConfig.self, from: data) {
            config = decoded
        }
        
        // 加载虚拟化身
        if let avatarId = UserDefaults.standard.string(forKey: "DreamARFaceTracking.currentAvatarId"),
           let uuid = UUID(uuidString: avatarId) {
            currentAvatar = AvatarModel.presets.first { $0.id == uuid }
        }
    }
    
    // MARK: - 工具方法
    
    /// 检查设备是否支持面部追踪
    static var isSupported: Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    /// 检查面部追踪权限
    static func checkPermission() async -> Bool {
        // iOS 17+ 需要请求面部追踪权限
        if #available(iOS 17.0, *) {
            // 这里需要根据实际 API 实现
            return true
        }
        return true
    }
}

// MARK: - ARFaceTrackingSessionDelegate

extension DreamARFaceTrackingService: ARFaceTrackingSessionDelegate {
    nonisolated func session(_ session: ARFaceTrackingSession, didUpdate faceAnchor: ARFaceAnchor) {
        // 创建面部表情状态
        let blendshapes = faceAnchor.blendShapes.compactMap { name, value -> FaceBlendshapeData? in
            guard let value = value as? Float else { return nil }
            return FaceBlendshapeData(name: name.rawValue, value: value)
        }
        
        let faceState = FaceExpressionState(
            timestamp: Date(),
            blendshapes: blendshapes,
            transform: faceAnchor.transform,
            isFaceDetected: true,
            confidence: faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.5
        )
        
        DispatchQueue.main.async { [weak self] in
            self?.currentFaceState = faceState
            self?.recordToHistory(faceState)
        }
    }
    
    nonisolated func session(_ session: ARFaceTrackingSession, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.isTracking = false
            self?.errorMessage = "面部追踪失败：\(error.localizedDescription)"
        }
    }
    
    nonisolated func sessionWasInterrupted(_ session: ARFaceTrackingSession) {
        DispatchQueue.main.async { [weak self] in
            self?.isTracking = false
        }
    }
    
    nonisolated func sessionInterruptionEnded(_ session: ARFaceTrackingSession) {
        // 尝试恢复追踪
        if let self = self, self.config.isEnabled {
            self.startTracking()
        }
    }
}

// MARK: - 面部表情动画驱动

/// 面部表情动画驱动器
struct FaceExpressionAnimator {
    /// 灵敏度
    let sensitivity: Float
    
    /// 平滑因子
    let smoothingFactor: Float
    
    /// 上一次的值
    var previousValues: [String: Float] = [:]
    
    /// 应用面部表情到 AR 元素
    func applyExpression(to element: inout DreamARElement3D, from faceState: FaceExpressionState) {
        // 根据表情类型调整元素属性
        switch faceState.primaryExpression {
        case .happy:
            // 开心表情 - 元素向上浮动，颜色变暖
            element.position.y += 0.1 * sensitivity
            element.material.emissiveColor = ColorRepresentable(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.5)
            
        case .sad:
            // 悲伤表情 - 元素向下移动，颜色变冷
            element.position.y -= 0.05 * sensitivity
            element.material.emissiveColor = ColorRepresentable(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.3)
            
        case .surprised:
            // 惊讶表情 - 元素放大，快速脉冲
            element.scale = SIMD3<Float>(repeating: 1.3 * sensitivity)
            
        case .excited:
            // 兴奋表情 - 元素快速旋转和闪烁
            element.animationType = .pulse
            element.animationSpeed = 2.0
            
        case .neutral:
            // 中性表情 - 恢复正常状态
            element.material.emissiveColor = ColorRepresentable(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2)
        }
    }
    
    /// 平滑混合形状值
    func smoothValue(_ newValue: Float, forKey key: String) -> Float {
        let oldValue = previousValues[key] ?? newValue
        let smoothed = oldValue + (newValue - oldValue) * smoothingFactor
        previousValues[key] = smoothed
        return smoothed
    }
}

// MARK: - 面部追踪成就

/// 面部追踪成就
struct FaceTrackingAchievement: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    static let presets: [FaceTrackingAchievement] = [
        FaceTrackingAchievement(
            id: UUID(),
            name: "初次表情",
            description: "首次使用面部追踪功能",
            icon: "😐",
            isUnlocked: false,
            unlockedDate: nil
        ),
        FaceTrackingAchievement(
            id: UUID(),
            name: "表情大师",
            description: "使用 10 种不同的表情",
            icon: "🎭",
            isUnlocked: false,
            unlockedDate: nil
        ),
        FaceTrackingAchievement(
            id: UUID(),
            name: "虚拟化身收藏家",
            description: "解锁所有虚拟化身",
            icon: "👤",
            isUnlocked: false,
            unlockedDate: nil
        )
    ]
}
