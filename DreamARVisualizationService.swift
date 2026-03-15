//
//  DreamARVisualizationService.swift
//  DreamLog
//
//  Created for Phase 48 - AR 梦境场景可视化
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import ARKit
import SwiftUI
import SwiftData

actor DreamARVisualizationService {
    
    // MARK: - 单例
    
    static let shared = DreamARVisualizationService()
    
    // MARK: - 属性
    
    private var modelContext: ModelContext?
    private var sceneCache: [UUID: ARDreamScene] = [:]
    private var configuration: ARSceneConfiguration = .default
    
    // MARK: - 初始化
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func setConfiguration(_ config: ARSceneConfiguration) {
        self.configuration = config
    }
    
    // MARK: - 场景管理
    
    /// 为梦境创建 AR 场景
    func createScene(for dreamID: UUID, dreamContent: String, dreamSymbols: [String], emotions: [String]) async throws -> ARDreamScene {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        let sceneName = "梦境 AR 场景 - \(formatDate(Date()))"
        let scene = ARDreamScene(
            dreamID: dreamID,
            sceneName: sceneName,
            sceneDescription: "基于梦境内容自动生成的 AR 场景"
        )
        
        context.insert(scene)
        
        // 根据梦境符号生成 AR 元素
        try await generateElements(for: scene, dreamContent: dreamContent, symbols: dreamSymbols, emotions: emotions)
        
        // 创建默认锚点
        createDefaultAnchors(for: scene)
        
        try context.save()
        
        sceneCache[dreamID] = scene
        
        return scene
    }
    
    /// 获取梦境的 AR 场景
    func getScene(for dreamID: UUID) async throws -> ARDreamScene? {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        // 先检查缓存
        if let cached = sceneCache[dreamID] {
            return cached
        }
        
        // 从数据库查询
        let descriptor = FetchDescriptor<ARDreamScene>(
            predicate: #Predicate { $0.dreamID == dreamID }
        )
        
        let scenes = try context.fetch(descriptor)
        return scenes.first
    }
    
    /// 获取所有 AR 场景
    func getAllScenes() async throws -> [ARDreamScene] {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        let descriptor = FetchDescriptor<ARDreamScene>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// 删除场景
    func deleteScene(_ scene: ARDreamScene) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        sceneCache.removeValue(forKey: scene.dreamID)
        context.delete(scene)
        try context.save()
    }
    
    /// 更新场景收藏状态
    func toggleFavorite(for scene: ARDreamScene) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        scene.isFavorite.toggle()
        try context.save()
    }
    
    /// 记录场景查看
    func recordSceneView(_ scene: ARDreamScene) async {
        scene.recordView()
        try? modelContext?.save()
    }
    
    // MARK: - 元素管理
    
    /// 添加元素到场景
    func addElement(to scene: ARDreamScene, element: ARDreamElement) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        context.insert(element)
        scene.elements.append(element)
        try context.save()
    }
    
    /// 删除元素
    func deleteElement(_ element: ARDreamElement, from scene: ARDreamScene) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        if let index = scene.elements.firstIndex(where: { $0.id == element.id }) {
            scene.elements.remove(at: index)
        }
        context.delete(element)
        try context.save()
    }
    
    /// 更新元素位置
    func updateElementPosition(_ element: ARDreamElement, to position: SIMD3<Float>) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        element.position = position
        element.createdAt = Date() // 触发 updatedAt 更新
        try context.save()
    }
    
    // MARK: - 锚点管理
    
    /// 添加锚点到场景
    func addAnchor(to scene: ARDreamScene, anchor: ARDreamAnchor) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        context.insert(anchor)
        scene.anchors.append(anchor)
        try context.save()
    }
    
    /// 删除锚点
    func deleteAnchor(_ anchor: ARDreamAnchor, from scene: ARDreamScene) async throws {
        guard let context = modelContext else {
            throw ARVisualizationError.modelContextNotConfigured
        }
        
        if let index = scene.anchors.firstIndex(where: { $0.id == anchor.id }) {
            scene.anchors.remove(at: index)
        }
        context.delete(anchor)
        try context.save()
    }
    
    // MARK: - 私有方法
    
    /// 根据梦境内容生成 AR 元素
    private func generateElements(for scene: ARDreamScene, dreamContent: String, symbols: [String], emotions: [String]) async throws {
        guard let context = modelContext else { return }
        
        // 添加符号元素
        for symbolKey in symbols.prefix(5) {
            guard let symbol = DreamSymbol(rawValue: symbolKey) else { continue }
            
            let element = ARDreamElement(
                sceneID: scene.id,
                type: .symbol,
                name: symbol.displayName,
                content: symbol.rawValue,
                position: SIMD3<Float>(
                    Float.random(in: -0.5...0.5),
                    Float.random(in: 0...1.5),
                    Float.random(in: -0.5...0.5)
                ),
                scale: SIMD3<Float>(0.3, 0.3, 0.3),
                color: symbol.defaultColor,
                opacity: 0.9,
                isAnimated: true,
                animationType: "float"
            )
            
            context.insert(element)
            scene.elements.append(element)
        }
        
        // 添加情绪光效
        for emotion in emotions.prefix(3) {
            let color = emotionColor(for: emotion)
            let element = ARDreamElement(
                sceneID: scene.id,
                type: .emotion,
                name: emotion,
                content: emotion,
                position: SIMD3<Float>(0, 0.5, 0),
                scale: SIMD3<Float>(0.8, 0.8, 0.8),
                color: color,
                opacity: 0.4,
                isAnimated: true,
                animationType: "pulse"
            )
            
            context.insert(element)
            scene.elements.append(element)
        }
        
        // 添加环境粒子效果
        let particleElement = ARDreamElement(
            sceneID: scene.id,
            type: .particle,
            name: "梦境粒子",
            content: "ambient_particles",
            position: SIMD3<Float>(0, 1, 0),
            scale: SIMD3<Float>(2, 2, 2),
            opacity: 0.3,
            isAnimated: true,
            animationType: "rise"
        )
        
        context.insert(particleElement)
        scene.elements.append(particleElement)
    }
    
    /// 创建默认锚点
    private func createDefaultAnchors(for scene: ARDreamScene) {
        // 创建地面平面锚点
        let planeData = Data() // 实际应用中会包含 ARPlaneAnchor 数据
        let planeAnchor = ARDreamAnchor(
            sceneID: scene.id,
            type: .plane,
            name: "地面平面",
            anchorData: planeData,
            isPersistent: true
        )
        
        modelContext?.insert(planeAnchor)
        scene.anchors.append(planeAnchor)
    }
    
    /// 获取情绪对应的颜色
    private func emotionColor(for emotion: String) -> String {
        switch emotion.lowercased() {
        case "快乐", "happy", "joy": return "#FFD700"
        case "悲伤", "sad": return "#4A90E2"
        case "恐惧", "fear": return "#8B0000"
        case "愤怒", "anger": return "#DC143C"
        case "惊讶", "surprise": return "#FF69B4"
        case "平静", "calm": return "#98FB98"
        case "焦虑", "anxiety": return "#D3D3D3"
        case "兴奋", "excitement": return "#FF4500"
        default: return "#FFFFFF"
        }
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - AR 可视化错误

enum ARVisualizationError: LocalizedError {
    case modelContextNotConfigured
    case sceneNotFound
    case elementNotFound
    case anchorNotFound
    case arNotSupported
    case cameraPermissionDenied
    case sceneGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelContextNotConfigured:
            return "模型上下文未配置"
        case .sceneNotFound:
            return "场景未找到"
        case .elementNotFound:
            return "元素未找到"
        case .anchorNotFound:
            return "锚点未找到"
        case .arNotSupported:
            return "设备不支持 AR"
        case .cameraPermissionDenied:
            return "相机权限被拒绝"
        case .sceneGenerationFailed:
            return "场景生成失败"
        }
    }
}

// MARK: - AR 视图协调器

/// AR 视图协调器 - 处理 ARKit 与 SwiftUI 的交互
class ARViewCoordinator: NSObject, ARSCNViewDelegate {
    
    var service: DreamARVisualizationService?
    var currentScene: ARDreamScene?
    var session: ARSCNView?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // 为锚点创建可视化节点
        let node = SCNNode()
        
        if let arAnchor = anchor as? ARPlaneAnchor {
            // 创建平面可视化
            let plane = SCNPlane(width: CGFloat(arAnchor.extent.x), height: CGFloat(arAnchor.extent.z))
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
            plane.materials = [material]
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
            node.addChildNode(planeNode)
        }
        
        return node
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR 会话失败：\(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("AR 会话被中断")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("AR 会话中断结束")
    }
}
