//
//  DreamARInteractionService.swift
//  DreamLog
//
//  Phase 22 - AR 交互服务
//  创建时间：2026-03-12
//

import Foundation
import SwiftUI
import ARKit
import RealityKit
import Combine

// MARK: - AR 交互服务

@MainActor
class DreamARInteractionService: ObservableObject {
    static let shared = DreamARInteractionService()
    
    /// 当前选中的元素
    @Published var selectedElement: DreamARElement3D?
    
    /// 选中的元素 ID
    @Published var selectedElementID: UUID?
    
    /// 是否处于编辑模式
    @Published var isEditMode: Bool = false
    
    /// 交互模式
    @Published var interactionMode: InteractionMode = .view
    
    /// 当前场景中的元素
    @Published var sceneElements: [DreamARElement3D] = []
    
    /// 手势状态
    @Published var gestureState: GestureState = .idle
    
    /// 最后操作时间
    private var lastActionTime: Date = Date()
    
    /// 防抖定时器
    private var debounceTimer: Timer?
    
    private init() {}
    
    // MARK: - 元素选择
    
    /// 选择元素
    func selectElement(_ element: DreamARElement3D) {
        selectedElement = element
        selectedElementID = element.id
        
        // 更新元素选中状态
        if let index = sceneElements.firstIndex(where: { $0.id == element.id }) {
            sceneElements[index].isSelected = true
        }
    }
    
    /// 取消选择
    func deselectElement() {
        // 清除所有元素的选中状态
        for index in sceneElements.indices {
            sceneElements[index].isSelected = false
        }
        
        selectedElement = nil
        selectedElementID = nil
    }
    
    /// 切换元素选择
    func toggleSelection(_ element: DreamARElement3D) {
        if selectedElementID == element.id {
            deselectElement()
        } else {
            selectElement(element)
        }
    }
    
    // MARK: - 元素变换
    
    /// 移动元素
    func moveElement(_ element: DreamARElement3D, to newPosition: SIMD3<Float>) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        sceneElements[index].position = newPosition
        sceneElements[index].modifiedAt = Date()
        
        // 通知 AR 视图更新
        notifyElementUpdated(element)
    }
    
    /// 旋转元素
    func rotateElement(_ element: DreamARElement3D, by newRotation: SIMD4<Float>) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        sceneElements[index].rotation = newRotation
        sceneElements[index].modifiedAt = Date()
        
        notifyElementUpdated(element)
    }
    
    /// 缩放元素
    func scaleElement(_ element: DreamARElement3D, to newScale: CGFloat) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        // 限制缩放范围
        let clampedScale = max(0.1, min(newScale, 10.0))
        
        sceneElements[index].scale = clampedScale
        sceneElements[index].modifiedAt = Date()
        
        notifyElementUpdated(element)
    }
    
    /// 重置元素变换
    func resetElementTransform(_ element: DreamARElement3D) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        sceneElements[index].position = SIMD3<Float>(0, 0, 0)
        sceneElements[index].rotation = SIMD4<Float>(0, 0, 0, 1)
        sceneElements[index].scale = 1.0
        sceneElements[index].modifiedAt = Date()
        
        notifyElementUpdated(element)
    }
    
    // MARK: - 元素管理
    
    /// 添加元素到场景
    func addElement(_ element: DreamARElement3D) {
        var newElement = element
        newElement.position = SIMD3<Float>(0, 0, -0.5) // 默认在前方 0.5 米
        sceneElements.append(newElement)
        
        // 自动选中新添加的元素
        selectElement(newElement)
    }
    
    /// 从场景移除元素
    func removeElement(_ element: DreamARElement3D) {
        sceneElements.removeAll { $0.id == element.id }
        
        if selectedElementID == element.id {
            deselectElement()
        }
    }
    
    /// 删除选中元素
    func deleteSelectedElement() {
        guard let selectedElement = selectedElement else { return }
        removeElement(selectedElement)
    }
    
    /// 清空场景
    func clearScene() {
        sceneElements.removeAll()
        deselectElement()
    }
    
    // MARK: - 交互模式
    
    /// 设置交互模式
    func setInteractionMode(_ mode: InteractionMode) {
        interactionMode = mode
        isEditMode = mode != .view
    }
    
    /// 切换编辑模式
    func toggleEditMode() {
        isEditMode.toggle()
        interactionMode = isEditMode ? .transform : .view
        
        if !isEditMode {
            deselectElement()
        }
    }
    
    // MARK: - 手势处理
    
    /// 处理点击手势
    func handleTap(on element: DreamARElement3D) {
        switch interactionMode {
        case .view:
            // 查看模式下显示元素详情
            selectElement(element)
            
        case .transform:
            // 编辑模式下选中元素
            toggleSelection(element)
            
        case .move:
            // 移动模式下准备移动
            if selectedElementID == element.id {
                gestureState = .moving
            }
            
        case .rotate:
            // 旋转模式下准备旋转
            if selectedElementID == element.id {
                gestureState = .rotating
            }
            
        case .scale:
            // 缩放模式下准备缩放
            if selectedElementID == element.id {
                gestureState = .scaling
            }
        }
    }
    
    /// 处理拖拽手势
    func handleDrag(_ translation: SIMD2<Float>, for element: DreamARElement3D) {
        guard selectedElementID == element.id else { return }
        
        switch interactionMode {
        case .move, .transform:
            // 移动元素
            let sensitivity: Float = 0.001
            let newPosition = SIMD3<Float>(
                element.position.x + Float(translation.x) * sensitivity,
                element.position.y - Float(translation.y) * sensitivity,
                element.position.z
            )
            moveElement(element, to: newPosition)
            
        default:
            break
        }
    }
    
    /// 处理缩放手势
    func handlePinch(_ scale: CGFloat, for element: DreamARElement3D) {
        guard selectedElementID == element.id else { return }
        
        let newScale = element.scale * scale
        scaleElement(element, to: newScale)
    }
    
    /// 处理旋转手势
    func handleRotation(_ rotation: CGFloat, for element: DreamARElement3D) {
        guard selectedElementID == element.id else { return }
        
        // 绕 Y 轴旋转
        let angle = Float(rotation) * .pi / 180.0
        let newRotation = SIMD4<Float>(0, 1, 0, angle)
        rotateElement(element, by: newRotation)
    }
    
    /// 手势结束
    func endGesture() {
        gestureState = .idle
        lastActionTime = Date()
    }
    
    // MARK: - 元素动画控制
    
    /// 播放元素动画
    func playAnimation(for element: DreamARElement3D) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        // 触发 AR 视图播放动画
        notifyAnimationPlay(element)
    }
    
    /// 暂停元素动画
    func pauseAnimation(for element: DreamARElement3D) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        notifyAnimationPause(element)
    }
    
    /// 停止元素动画
    func stopAnimation(for element: DreamARElement3D) {
        guard let index = sceneElements.firstIndex(where: { $0.id == element.id }) else { return }
        
        notifyAnimationStop(element)
    }
    
    // MARK: - 批量操作
    
    /// 批量选择元素
    func selectElements(_ elements: [DreamARElement3D]) {
        for element in elements {
            if let index = sceneElements.firstIndex(where: { $0.id == element.id }) {
                sceneElements[index].isSelected = true
            }
        }
    }
    
    /// 批量删除元素
    func deleteElements(_ elements: [DreamARElement3D]) {
        let idsToDelete = Set(elements.map { $0.id })
        sceneElements.removeAll { idsToDelete.contains($0.id) }
        
        if let selectedID = selectedElementID, idsToDelete.contains(selectedID) {
            deselectElement()
        }
    }
    
    /// 批量移动元素
    func moveElements(_ elements: [DreamARElement3D], by offset: SIMD3<Float>) {
        for element in elements {
            if let index = sceneElements.firstIndex(where: { $0.id == element.id }) {
                sceneElements[index].position += offset
                sceneElements[index].modifiedAt = Date()
            }
        }
    }
    
    // MARK: - 通知系统
    
    private func notifyElementUpdated(_ element: DreamARElement3D) {
        // 通知 AR 视图更新（通过 Combine 或其他机制）
        // 实际实现中会触发视图刷新
    }
    
    private func notifyAnimationPlay(_ element: DreamARElement3D) {
        // 通知 AR 视图播放动画
    }
    
    private func notifyAnimationPause(_ element: DreamARElement3D) {
        // 通知 AR 视图暂停动画
    }
    
    private func notifyAnimationStop(_ element: DreamARElement3D) {
        // 通知 AR 视图停止动画
    }
    
    // MARK: - 场景保存/加载
    
    /// 保存场景
    func saveScene(name: String) throws -> URL {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let sceneData = try encoder.encode(sceneElements)
        
        // 保存到 Documents 目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent("ARScenes/\(name).json")
        
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try sceneData.write(to: fileURL)
        
        return fileURL
    }
    
    /// 加载场景
    func loadScene(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let elements = try decoder.decode([DreamARElement3D].self, from: data)
        
        sceneElements = elements
    }
}

// MARK: - 交互模式

enum InteractionMode: String, CaseIterable {
    case view = "查看"
    case transform = "变换"
    case move = "移动"
    case rotate = "旋转"
    case scale = "缩放"
    
    var icon: String {
        switch self {
        case .view: return "eye"
        case .transform: return "move.3d"
        case .move: return "arrow.up.left.and.arrow.down.right"
        case .rotate: return "rotate.3d"
        case .scale: return "arrow.left.and.right"
        }
    }
    
    var description: String {
        switch self {
        case .view: return "点击查看元素详情"
        case .transform: return "拖拽移动、缩放、旋转元素"
        case .move: return "拖拽移动元素位置"
        case .rotate: return "拖拽旋转元素方向"
        case .scale: return "双指缩放元素大小"
        }
    }
}

// MARK: - 手势状态

enum GestureState {
    case idle
    case moving
    case rotating
    case scaling
    case tapping
}

// MARK: - 交互配置

struct InteractionConfig {
    /// 移动灵敏度
    var moveSensitivity: Float = 0.001
    
    /// 旋转灵敏度
    var rotateSensitivity: Float = 2.0
    
    /// 缩放灵敏度
    var scaleSensitivity: CGFloat = 0.01
    
    /// 最小缩放
    var minScale: CGFloat = 0.1
    
    /// 最大缩放
    var maxScale: CGFloat = 10.0
    
    /// 是否启用物理效果
    var enablePhysics: Bool = false
    
    /// 是否启用碰撞检测
    var enableCollision: Bool = true
    
    /// 是否显示变换控件
    var showTransformControls: Bool = true
    
    static let `default` = InteractionConfig()
    
    static let precise = InteractionConfig(
        moveSensitivity: 0.0005,
        rotateSensitivity: 1.0,
        scaleSensitivity: 0.005
    )
    
    static let fast = InteractionConfig(
        moveSensitivity: 0.002,
        rotateSensitivity: 4.0,
        scaleSensitivity: 0.02
    )
}
