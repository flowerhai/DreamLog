//
//  DreamARPerformanceOptimizer.swift
//  DreamLog - Phase 24: AR Performance & Advanced Features
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import SwiftUI

// MARK: - AR Performance Optimizer

/// AR 性能优化器 - 优化 AR 渲染性能和资源管理
@MainActor
class DreamARPerformanceOptimizer: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前帧率
    @Published var currentFPS: Int = 60
    
    /// 内存使用量 (MB)
    @Published var memoryUsageMB: Double = 0.0
    
    /// 渲染时间 (ms)
    @Published var renderTimeMS: Double = 0.0
    
    /// 是否启用性能优化
    @Published var isOptimizationEnabled: Bool = true
    
    /// 性能模式
    @Published var performanceMode: PerformanceMode = .balanced
    
    // MARK: - Configuration
    
    /// 最大同时渲染元素数
    var maxRenderElements: Int {
        switch performanceMode {
        case .quality: return 100
        case .balanced: return 50
        case .performance: return 25
        }
    }
    
    /// LOD 距离阈值 (米)
    var lodDistances: [Float] {
        switch performanceMode {
        case .quality: return [0, 5, 15, 30]
        case .balanced: return [0, 3, 10, 20]
        case .performance: return [0, 2, 5, 10]
        }
    }
    
    /// 是否启用遮挡剔除
    var isOcclusionCullingEnabled: Bool {
        performanceMode != .performance
    }
    
    // MARK: - Private Properties
    
    private var frameCounter: Int = 0
    private var lastFPSCalculationTime: CFAbsoluteTime = 0
    private var renderStartTime: CFAbsoluteTime = 0
    
    private var modelCache: DreamARModelCache?
    private var arView: ARView?
    
    // MARK: - Singleton
    
    static let shared = DreamARPerformanceOptimizer()
    
    private init() {}
    
    // MARK: - Setup
    
    /// 设置 ARView 进行性能监控
    func setup(arView: ARView) {
        self.arView = arView
        self.modelCache = DreamARModelCache.shared
        
        #if DEBUG
        showPerformanceOverlay()
        #endif
    }
    
    /// 显示性能覆盖层（仅调试）
    #if DEBUG
    private func showPerformanceOverlay() {
        // 在调试模式下显示性能信息
        ARDebugOverlay.showPerformanceMetrics(true)
    }
    #endif
    
    // MARK: - Frame Rate Monitoring
    
    /// 更新帧率计数
    func updateFrameStats() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        frameCounter += 1
        
        // 每秒计算一次 FPS
        if currentTime - lastFPSCalculationTime >= 1.0 {
            currentFPS = frameCounter
            frameCounter = 0
            lastFPSCalculationTime = currentTime
            
            // 根据 FPS 自动调整性能模式
            autoAdjustPerformanceMode()
        }
    }
    
    /// 开始渲染计时
    func beginRender() {
        renderStartTime = CFAbsoluteTimeGetCurrent()
    }
    
    /// 结束渲染计时
    func endRender() {
        renderTimeMS = (CFAbsoluteTimeGetCurrent() - renderStartTime) * 1000
    }
    
    /// 更新内存使用统计
    func updateMemoryStats() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            memoryUsageMB = Double(info.resident_size) / 1024.0 / 1024.0
        }
    }
    
    // MARK: - Auto Adjustment
    
    /// 根据性能自动调整模式
    private func autoAdjustPerformanceMode() {
        guard isOptimizationEnabled else { return }
        
        if currentFPS < 30 && performanceMode != .performance {
            // FPS 过低，降低质量
            performanceMode = .performance
        } else if currentFPS > 55 && performanceMode == .performance {
            // FPS 稳定，提升质量
            performanceMode = .balanced
        }
    }
    
    // MARK: - LOD Management
    
    /// 更新元素的 LOD 级别
    func updateLOD(for element: DreamARElement3D, cameraDistance: Float) -> LODLevel {
        let distances = lodDistances
        
        if cameraDistance < distances[1] {
            return .high
        } else if cameraDistance < distances[2] {
            return .medium
        } else if cameraDistance < distances[3] {
            return .low
        } else {
            return .cull
        }
    }
    
    /// 获取元素的 LOD 模型 URL
    func getLODModelURL(for element: DreamARElement3D, level: LODLevel) -> URL? {
        guard let cache = modelCache else { return nil }
        
        switch level {
        case .high:
            return cache.getHighDetailModel(for: element)
        case .medium:
            return cache.getMediumDetailModel(for: element)
        case .low:
            return cache.getLowDetailModel(for: element)
        case .cull:
            return nil
        }
    }
    
    // MARK: - Element Management
    
    /// 优化场景中的元素
    func optimizeElements(_ elements: inout [DreamARElement3D], cameraPosition: SIMD3<Float>) {
        guard isOptimizationEnabled else { return }
        
        var visibleElements: [DreamARElement3D] = []
        
        for element in elements {
            let distance = simd_distance(cameraPosition, element.position)
            let lodLevel = updateLOD(for: element, cameraDistance: distance)
            
            // 设置 LOD 级别
            element.currentLOD = lodLevel
            
            // 只添加可见元素
            if lodLevel != .cull {
                visibleElements.append(element)
            }
        }
        
        // 如果元素过多，优先保留近的
        if visibleElements.count > maxRenderElements {
            visibleElements.sort { e1, e2 in
                let d1 = simd_distance(cameraPosition, e1.position)
                let d2 = simd_distance(cameraPosition, e2.position)
                return d1 < d2
            }
            visibleElements = Array(visibleElements.prefix(maxRenderElements))
        }
        
        elements = visibleElements
    }
    
    // MARK: - Preloading
    
    /// 预加载常用模型
    func preloadModels(for elements: [DreamARElement3D]) async {
        guard let cache = modelCache else { return }
        
        let priorityElements = elements.filter { $0.isSelected || $0.isFavorite }
        
        for element in priorityElements {
            await cache.preloadModel(for: element)
        }
    }
    
    /// 清理未使用的缓存
    func clearUnusedCache() {
        modelCache?.clearUnusedModels()
    }
    
    // MARK: - Performance Tips
    
    /// 获取性能建议
    func getPerformanceTips() -> [PerformanceTip] {
        var tips: [PerformanceTip] = []
        
        if memoryUsageMB > 300 {
            tips.append(.init(
                type: .warning,
                title: "内存使用过高",
                description: "当前内存使用 \(String(format: "%.0f", memoryUsageMB))MB，建议减少场景中的元素数量",
                icon: "memorychip"
            ))
        }
        
        if currentFPS < 30 {
            tips.append(.init(
                type: .warning,
                title: "帧率较低",
                description: "当前帧率 \(currentFPS) FPS，建议切换到性能模式",
                icon: "gauge.badge.minus"
            ))
        }
        
        if renderTimeMS > 16.67 {
            tips.append(.init(
                type: .info,
                title: "渲染时间较长",
                description: "渲染耗时 \(String(format: "%.1f", renderTimeMS))ms，目标为 16.67ms (60 FPS)",
                icon: "clock"
            ))
        }
        
        if tips.isEmpty {
            tips.append(.init(
                type: .success,
                title: "性能良好",
                description: "AR 场景运行流畅，帧率稳定在 \(currentFPS) FPS",
                icon: "checkmark.circle"
            ))
        }
        
        return tips
    }
}

// MARK: - Performance Mode

enum PerformanceMode: String, CaseIterable, Identifiable {
    case quality = "质量优先"
    case balanced = "平衡模式"
    case performance = "性能优先"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .quality: return "sparkles"
        case .balanced: return "scale.3d"
        case .performance: return "gauge.high"
        }
    }
    
    var description: String {
        switch self {
        case .quality: return "最高画质，适合高端设备"
        case .balanced: return "平衡画质和性能"
        case .performance: return "最佳性能，适合低端设备"
        }
    }
    
    var color: Color {
        switch self {
        case .quality: return .purple
        case .balanced: return .blue
        case .performance: return .green
        }
    }
}

// MARK: - LOD Level

enum LODLevel: Int, CaseIterable {
    case high = 3    // 高精度
    case medium = 2  // 中等精度
    case low = 1     // 低精度
    case cull = 0    // 剔除（不渲染）
}

// MARK: - Performance Tip

struct PerformanceTip: Identifiable {
    let id = UUID()
    let type: TipType
    let title: String
    let description: String
    let icon: String
}

enum TipType {
    case info
    case warning
    case success
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .success: return .green
        }
    }
}

// MARK: - AR Debug Overlay (Debug Only)

#if DEBUG
class ARDebugOverlay {
    static func showPerformanceMetrics(_ show: Bool) {
        // 调试模式下显示性能指标
        // 实际实现需要使用 ARView 的 debugOptions
    }
}
#endif

// MARK: - Extensions

extension DreamARElement3D {
    var currentLOD: LODLevel {
        get {
            // 从 userInfo 中读取 LOD 级别（存储为 rawValue 字符串）
            if let lodRaw = userInfo["lodLevel"], let lod = LODLevel(rawValue: Int(lodRaw) ?? 3) {
                return lod
            }
            return .high
        }
        set {
            userInfo["lodLevel"] = String(newValue.rawValue)
        }
    }
}
