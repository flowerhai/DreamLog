//
//  DreamARService.swift
//  DreamLog - Phase 21: Dream AR Visualization
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import ARKit
import SwiftUI
import Combine

/// Dream AR 服务 - 梦境 AR 可视化核心服务
@MainActor
class DreamARService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var sessionState: ARSessionState = .idle
    @Published var currentScene: ARDreamScene?
    @Published var isRecording: Bool = false
    @Published var recordingProgress: Double = 0.0
    @Published var availableScenes: [ARDreamScene] = []
    @Published var errorMessage: String?
    
    // MARK: - ARKit Properties
    
    private var arView: ARSCNView?
    private var sceneView: ARView?
    private var anchorEntities: [UUID: AnchorEntity] = [:]
    
    // MARK: - Services
    
    private let dreamStore: DreamStore
    private let fileManager: FileManager
    private let archiveDirectory: URL
    
    // MARK: - Initialization
    
    init(dreamStore: DreamStore = DreamStore.shared) {
        self.dreamStore = dreamStore
        self.fileManager = FileManager.default
        
        // 创建 AR 存档目录
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        self.archiveDirectory = documentsPath.appendingPathComponent("ARScenes", isDirectory: true)
        
        try? fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        
        loadSavedScenes()
    }
    
    // MARK: - Scene Management
    
    /// 从梦境创建 AR 场景
    func createScene(from dream: Dream) async throws -> ARDreamScene {
        sessionState = .preparing
        
        do {
            // 分析梦境内容，提取 AR 元素
            let elements = try await analyzeDreamForARElements(dream: dream)
            
            // 创建场景
            var scene = ARDreamScene(dreamId: dream.id, dreamTitle: dream.title, elements: elements)
            
            // 根据梦境情绪设置环境
            scene.environment = determineEnvironment(from: dream)
            scene.lighting = determineLighting(from: dream)
            
            // 保存场景
            try saveScene(scene)
            availableScenes.append(scene)
            
            sessionState = .running
            currentScene = scene
            
            return scene
            
        } catch {
            sessionState = .error(error.localizedDescription)
            throw error
        }
    }
    
    /// 分析梦境内容，提取 AR 元素
    private func analyzeDreamForARElements(dream: Dream) async throws -> [ARDreamElement] {
        var elements: [ARDreamElement] = []
        
        // 从标签提取元素
        for tag in dream.tags {
            let element = tagToARElement(tag: tag)
            if let element = element {
                elements.append(element)
            }
        }
        
        // 从情绪提取元素
        for emotion in dream.emotions {
            let element = emotionToARElement(emotion: emotion)
            elements.append(element)
        }
        
        // 从内容关键词提取元素
        let keywords = extractKeywords(from: dream.content)
        for keyword in keywords {
            if let element = keywordToARElement(keyword: keyword) {
                elements.append(element)
            }
        }
        
        // 如果没有元素，创建默认元素
        if elements.isEmpty {
            elements.append(ARDreamElement(type: .abstract, name: "梦境核心", description: dream.title))
        }
        
        // 为元素分配位置 (环形布局)
        distributeElementsInCircle(&elements)
        
        return elements
    }
    
    /// 标签转 AR 元素
    private func tagToARElement(tag: String) -> ARDreamElement? {
        let lowerTag = tag.lowercased()
        
        // 水相关
        if ["水", "water", "海", "ocean", "河", "river", "雨", "rain"].contains(lowerTag) {
            return ARDreamElement(type: .water, name: tag, description: "水元素")
        }
        
        // 火相关
        if ["火", "fire", "火焰", "flame", "燃烧", "burn"].contains(lowerTag) {
            return ARDreamElement(type: .fire, name: tag, description: "火元素")
        }
        
        // 风相关
        if ["风", "wind", "空气", "air", "飞行", "fly", "云", "cloud"].contains(lowerTag) {
            return ARDreamElement(type: .wind, name: tag, description: "风元素")
        }
        
        // 自然相关
        if ["树", "tree", "森林", "forest", "花", "flower", "草", "grass", "自然", "nature"].contains(lowerTag) {
            return ARDreamElement(type: .nature, name: tag, description: "自然元素")
        }
        
        // 建筑相关
        if ["建筑", "building", "房子", "house", "城市", "city"].contains(lowerTag) {
            return ARDreamElement(type: .building, name: tag, description: "建筑元素")
        }
        
        return nil
    }
    
    /// 情绪转 AR 元素
    private func emotionToARElement(emotion: Emotion) -> ARDreamElement {
        let (type, name) = emotionToARType(emotion: emotion)
        return ARDreamElement(type: type, name: name, description: "情绪：\(emotion.rawValue)")
    }
    
    private func emotionToARType(emotion: Emotion) -> (ARDreamElementType, String) {
        switch emotion {
        case .calm: return (.light, "平静之光")
        case .happy: return (.light, "快乐之光")
        case .anxious: return (.wind, "焦虑之风")
        case .fearful: return (.dark, "恐惧之影")
        case .confused: return (.abstract, "困惑迷雾")
        case .excited: return (.fire, "兴奋之火")
        case .sad: return (.water, "悲伤之水")
        case .angry: return (.fire, "愤怒之火")
        case .surprised: return (.light, "惊讶闪光")
        case .neutral: return (.abstract, "中性元素")
        @unknown default: return (.abstract, "未知情绪")
        }
    }
    
    /// 从内容提取关键词
    private func extractKeywords(from content: String) -> [String] {
        // 简单的关键词提取 (实际应使用 NLP)
        let commonDreamWords = [
            "飞行", "fly", "坠落", "fall", "追逐", "chase", "水", "water",
            "火", "fire", "动物", "animal", "人", "person", "房子", "house"
        ]
        
        var keywords: [String] = []
        let lowerContent = content.lowercased()
        
        for word in commonDreamWords {
            if lowerContent.contains(word) {
                keywords.append(word)
            }
        }
        
        return keywords
    }
    
    /// 关键词转 AR 元素
    private func keywordToARElement(keyword: String) -> ARDreamElement? {
        return tagToARElement(tag: keyword)
    }
    
    /// 环形分布元素
    private func distributeElementsInCircle(_ elements: inout [ARDreamElement]) {
        let count = elements.count
        let radius: Float = 1.5 // 米
        
        for i in 0..<count {
            let angle = Float(i) * 2.0 * .pi / Float(count)
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            let y: Float = 0
            
            elements[i].position = SIMD3<Float>(x, y, z)
            
            // 随机缩放 (0.5-1.5)
            let scale = Float.random(in: 0.5...1.5)
            elements[i].scale = SIMD3<Float>(scale, scale, scale)
            
            // 添加动画
            if i % 2 == 0 {
                elements[i].animation = .float
            } else {
                elements[i].animation = .pulse
            }
        }
    }
    
    /// 根据梦境确定环境
    private func determineEnvironment(from dream: Dream) -> AREnvironmentType {
        // 根据情绪和标签决定环境
        let hasWater = dream.tags.contains { ["水", "water", "海", "ocean"].contains($0.lowercased()) }
        let hasNature = dream.tags.contains { ["树", "tree", "森林", "forest", "自然", "nature"].contains($0.lowercased()) }
        let hasDark = dream.emotions.contains(.恐惧) || dream.emotions.contains(.焦虑)
        
        if hasWater { return .ocean }
        if hasNature { return .forest }
        if hasDark { return .space }
        
        return .default
    }
    
    /// 根据梦境确定灯光
    private func determineLighting(from dream: Dream) -> ARLightingPreset {
        let avgClarity = dream.clarity
        
        if avgClarity >= 4 { return .natural }
        if avgClarity <= 2 { return .dark }
        if dream.isLucid { return .dreamy }
        
        return .soft
    }
    
    // MARK: - Scene Persistence
    
    /// 保存场景
    func saveScene(_ scene: ARDreamScene) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(scene)
        
        let fileURL = archiveDirectory.appendingPathComponent("\(scene.id.uuidString).json")
        try data.write(to: fileURL)
    }
    
    /// 加载已保存的场景
    func loadSavedScenes() {
        guard fileManager.fileExists(atPath: archiveDirectory.path) else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        availableScenes = []
        
        do {
            let files = try fileManager.contentsOfDirectory(at: archiveDirectory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "json" {
                let data = try Data(contentsOf: file)
                let scene = try decoder.decode(ARDreamScene.self, from: data)
                availableScenes.append(scene)
            }
        } catch {
            print("加载场景失败：\(error)")
        }
    }
    
    /// 删除场景
    func deleteScene(_ scene: ARDreamScene) throws {
        let fileURL = archiveDirectory.appendingPathComponent("\(scene.id.uuidString).json")
        try fileManager.removeItem(at: fileURL)
        availableScenes.removeAll { $0.id == scene.id }
    }
    
    // MARK: - Recording
    
    /// 开始录制 AR 场景
    func startRecording(config: ARRecordingConfig = ARRecordingConfig()) async throws -> URL {
        guard let scene = currentScene else {
            throw ARError.noActiveScene
        }
        
        isRecording = true
        recordingProgress = 0.0
        sessionState = .recording
        
        // 模拟录制进度 (实际应使用 ARView 的录制功能)
        let progressSteps = Int(config.duration / 0.1)
        
        for i in 0..<progressSteps {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 秒
            recordingProgress = Double(i + 1) / Double(progressSteps)
        }
        
        isRecording = false
        sessionState = .running
        
        // 返回录制的视频 URL (模拟)
        let videoURL = archiveDirectory.appendingPathComponent("\(scene.id.uuidString)_recording.mov")
        
        // 创建空文件作为占位符
        fileManager.createFile(atPath: videoURL.path, contents: nil)
        
        return videoURL
    }
    
    /// 停止录制
    func stopRecording() {
        isRecording = false
        sessionState = .running
    }
    
    // MARK: - Sharing
    
    /// 分享 AR 场景
    func shareScene(_ scene: ARDreamScene) async throws -> ARDreamShare {
        var share = ARDreamShare(sceneId: scene.id, dreamId: scene.dreamId)
        
        // 生成分享链接 (实际应上传到服务器)
        share.shareURL = "dreamlog://ar/\(scene.id.uuidString)"
        
        return share
    }
    
    // MARK: - AR View Setup
    
    /// 配置 AR 视图
    func setupARView() -> ARSCNView {
        let view = ARSCNView()
        view.autoenablesDefaultLighting = true
        view.automaticallyUpdatesLighting = true
        view.showsStatistics = true
        
        // 配置场景
        let scene = SCNScene()
        view.scene = scene
        
        arView = view
        
        return view
    }
    
    /// 在 AR 视图中显示场景
    func displayScene(_ scene: ARDreamScene, in arView: ARSCNView) {
        self.arView = arView
        
        // 清除现有节点
        arView.scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
        
        // 添加梦境元素
        for element in scene.elements {
            addElementNode(element, to: arView)
        }
    }
    
    /// 添加元素节点
    private func addElementNode(_ element: ARDreamElement, to arView: ARSCNView) {
        // 创建几何体 (根据元素类型)
        let geometry: SCNGeometry
        
        switch element.type {
        case .water:
            geometry = SCNSphere(radius: CGFloat(element.scale.x * 0.3))
            geometry.firstMaterial?.diffuse.contents = UIColor.systemBlue
            geometry.firstMaterial?.transparency = 0.7
        case .fire:
            geometry = SCNBox(width: CGFloat(element.scale.x * 0.4),
                             height: CGFloat(element.scale.y * 0.4),
                             length: CGFloat(element.scale.z * 0.4),
                             chamferRadius: 0.1)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemRed
            geometry.firstMaterial?.emission.contents = UIColor.orange
        case .nature:
            geometry = SCNCone(topRadius: 0.1, bottomRadius: 0.3, height: CGFloat(element.scale.y * 0.6))
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGreen
        default:
            geometry = SCNSphere(radius: CGFloat(element.scale.x * 0.3))
            geometry.firstMaterial?.diffuse.contents = UIColor.white
        }
        
        // 创建节点
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(element.position.x, element.position.y, element.position.z)
        
        // 添加动画
        if let animation = element.animation {
            addAnimation(to: node, type: animation)
        }
        
        arView.scene.rootNode.addChildNode(node)
    }
    
    /// 添加动画到节点
    private func addAnimation(to node: SCNNode, type: ARAnimationType) {
        switch type {
        case .float:
            let floatAction = SCNAction.repeatForever(
                SCNAction.sequence([
                    SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 2),
                    SCNAction.moveBy(x: 0, y: -0.2, z: 0, duration: 2)
                ])
            )
            node.runAction(floatAction)
            
        case .pulse:
            let pulseAction = SCNAction.repeatForever(
                SCNAction.sequence([
                    SCNAction.scale(to: 1.2, duration: 1),
                    SCNAction.scale(to: 1.0, duration: 1)
                ])
            )
            node.runAction(pulseAction)
            
        case .rotate:
            let rotateAction = SCNAction.repeatForever(
                SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 4)
            )
            node.runAction(rotateAction)
            
        default:
            break
        }
    }
    
    // MARK: - Utilities
    
    /// 检查 AR 可用性
    static func isARAvailable() -> Bool {
        return ARWorldTrackingConfiguration.isSupported
    }
    
    /// 检查相机权限
    static func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

// MARK: - AR Error

enum ARError: LocalizedError {
    case noActiveScene
    case arNotSupported
    case cameraPermissionDenied
    case recordingFailed
    case sharingFailed
    case modelContextNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .noActiveScene: return "没有活跃的场景"
        case .arNotSupported: return "设备不支持 AR"
        case .cameraPermissionDenied: return "相机权限被拒绝"
        case .recordingFailed: return "录制失败"
        case .sharingFailed: return "分享失败"
        case .modelContextNotConfigured: return "模型上下文未配置"
        }
    }
}
