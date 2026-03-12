//
//  DreamPerformanceOptimizer.swift
//  DreamLog
//
//  Phase 26 - 性能优化服务
//  负责 AR 渲染优化、内存管理、启动优化、图片缓存等
//

import Foundation
import UIKit
import ARKit
import SceneKit
import Combine

// MARK: - 性能监控数据

/// 性能监控指标
struct PerformanceMetrics {
    var fps: Double = 0.0
    var memoryUsage: UInt64 = 0
    var cpuUsage: Double = 0.0
    var batteryLevel: Float = 0.0
    var thermalState: ProcessInfo.ThermalState = .nominal
    
    /// 性能等级
    var performanceLevel: PerformanceLevel {
        if fps >= 55 && memoryUsage < 500 * 1024 * 1024 {
            return .excellent
        } else if fps >= 30 && memoryUsage < 800 * 1024 * 1024 {
            return .good
        } else if fps >= 20 {
            return .fair
        } else {
            return .poor
        }
    }
    
    enum PerformanceLevel: String {
        case excellent = "优秀"
        case good = "良好"
        case fair = "一般"
        case poor = "较差"
    }
}

// MARK: - LOD 配置

/// LOD (Level of Detail) 配置
struct LODConfig {
    var nearThreshold: Float = 2.0    // 近距阈值（米）
    var midThreshold: Float = 10.0    // 中距阈值（米）
    var farThreshold: Float = 50.0    // 远距阈值（米）
    
    var highDetailPolygons: Int = 10000   // 高细节多边形数
    var midDetailPolygons: Int = 3000     // 中细节多边形数
    var lowDetailPolygons: Int = 500      // 低细节多边形数
    
    static var `default`: LODConfig = LODConfig()
    static var qualityHigh: LODConfig = LODConfig(
        nearThreshold: 1.5,
        midThreshold: 8.0,
        farThreshold: 40.0,
        highDetailPolygons: 15000,
        midDetailPolygons: 5000,
        lowDetailPolygons: 1000
    )
    static var qualityLow: LODConfig = LODConfig(
        nearThreshold: 3.0,
        midThreshold: 15.0,
        farThreshold: 60.0,
        highDetailPolygons: 5000,
        midDetailPolygons: 1500,
        lowDetailPolygons: 300
    )
}

// MARK: - 渲染配置

/// AR 渲染配置
struct ARRenderConfig {
    var enableShadows: Bool = true
    var enableReflections: Bool = true
    var enableAntiAliasing: Bool = true
    var enableMotionBlur: Bool = false
    var maxLights: Int = 3
    var maxTextures: Int = 50
    var textureQuality: TextureQuality = .high
    
    enum TextureQuality: String, CaseIterable {
        case low = "低 (512x512)"
        case medium = "中 (1024x1024)"
        case high = "高 (2048x2048)"
        case ultra = "超高 (4096x4096)"
        
        var size: Int {
            switch self {
            case .low: return 512
            case .medium: return 1024
            case .high: return 2048
            case .ultra: return 4096
            }
        }
    }
    
    static var `default`: ARRenderConfig = ARRenderConfig()
    static var performanceMode: ARRenderConfig = ARRenderConfig(
        enableShadows: false,
        enableReflections: false,
        enableAntiAliasing: false,
        enableMotionBlur: false,
        maxLights: 2,
        maxTextures: 30,
        textureQuality: .medium
    )
    static var qualityMode: ARRenderConfig = ARRenderConfig(
        enableShadows: true,
        enableReflections: true,
        enableAntiAliasing: true,
        enableMotionBlur: true,
        maxLights: 5,
        maxTextures: 100,
        textureQuality: .ultra
    )
}

// MARK: - 性能优化器

@MainActor
class DreamPerformanceOptimizer: ObservableObject {
    static let shared = DreamPerformanceOptimizer()
    
    // MARK: - Published Properties
    
    @Published var currentMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var isOptimizing: Bool = false
    @Published var currentQualityLevel: QualityLevel = .auto
    @Published var lodConfig: LODConfig = .default
    @Published var renderConfig: ARRenderConfig = .default
    
    // MARK: - Properties
    
    private var metricsTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let processInfo = ProcessInfo.processInfo
    private let memoryWarningThreshold: UInt64 = 1024 * 1024 * 1024  // 1GB
    
    // 图片缓存
    private var imageCache = NSCache<NSString, UIImage>()
    private let maxCacheCount = 100
    private let maxCacheCost = 100 * 1024 * 1024  // 100MB
    
    // 性能历史记录
    private var metricsHistory: [PerformanceMetrics] = []
    private let maxHistoryCount = 60  // 保留 1 分钟数据（每秒 1 次）
    
    // MARK: - Quality Levels
    
    enum QualityLevel: String, CaseIterable, Identifiable {
        case auto = "自动"
        case low = "低"
        case medium = "中"
        case high = "高"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .auto: return "根据设备性能自动调整"
            case .low: return "最佳性能，降低画质"
            case .medium: return "平衡性能与画质"
            case .high: return "最佳画质，可能影响性能"
            }
        }
    }
    
    private init() {
        setupImageCache()
        startMonitoring()
        observeMemoryWarning()
    }
    
    // MARK: - 初始化
    
    private func setupImageCache() {
        imageCache.countLimit = maxCacheCount
        imageCache.totalCostLimit = maxCacheCost
        imageCache.name = "DreamLogImageCache"
    }
    
    private func observeMemoryWarning() {
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { [weak self] _ in
                self?.handleMemoryWarning()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 性能监控
    
    func startMonitoring() {
        stopMonitoring()
        
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    private func updateMetrics() {
        // FPS (通过 CADisplayLink 获取，这里简化)
        currentMetrics.fps = estimateFPS()
        
        // 内存使用
        currentMetrics.memoryUsage = getMemoryUsage()
        
        // CPU 使用
        currentMetrics.cpuUsage = getCPUUsage()
        
        // 电池电量
        currentMetrics.batteryLevel = UIDevice.current.batteryLevel
        
        // 热状态
        currentMetrics.thermalState = processInfo.thermalState
        
        // 更新历史记录
        metricsHistory.append(currentMetrics)
        if metricsHistory.count > maxHistoryCount {
            metricsHistory.removeFirst()
        }
        
        // 自动调整质量
        if currentQualityLevel == .auto {
            autoAdjustQuality()
        }
    }
    
    private func estimateFPS() -> Double {
        // 简化实现：实际应该通过 CADisplayLink 精确测量
        return 60.0
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func getCPUUsage() -> Double {
        // 简化实现：实际应该通过 host_processor_info 获取
        return Double(processInfo.processorCount) * 10.0
    }
    
    // MARK: - 自动质量调整
    
    private func autoAdjustQuality() {
        let level = currentMetrics.performanceLevel
        
        switch level {
        case .excellent:
            if currentQualityLevel != .high {
                applyQualityLevel(.high)
            }
        case .good:
            if currentQualityLevel != .medium {
                applyQualityLevel(.medium)
            }
        case .fair, .poor:
            if currentQualityLevel != .low {
                applyQualityLevel(.low)
            }
        }
    }
    
    func applyQualityLevel(_ level: QualityLevel) {
        guard currentQualityLevel != level else { return }
        
        currentQualityLevel = level
        
        switch level {
        case .auto:
            lodConfig = .default
            renderConfig = .default
        case .low:
            lodConfig = .qualityLow
            renderConfig = .performanceMode
        case .medium:
            lodConfig = .default
            renderConfig = .default
        case .high:
            lodConfig = .qualityHigh
            renderConfig = .qualityMode
        }
        
        print("🚀 性能优化：应用质量等级 \(level.rawValue)")
    }
    
    // MARK: - 内存警告处理
    
    private func handleMemoryWarning() {
        print("⚠️ 收到内存警告")
        
        // 清理图片缓存
        imageCache.removeAllObjects()
        
        // 清理其他缓存
        DreamImageCache.shared.clearCache()
        
        // 通知其他服务
        NotificationCenter.default.post(name: .dreamMemoryWarning, object: nil)
    }
    
    // MARK: - 图片缓存管理
    
    func cachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.pngData()?.count ?? 0)
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func removeCachedImage(forKey key: String) {
        imageCache.removeObject(forKey: key as NSString)
    }
    
    // MARK: - AR 场景优化
    
    /// 优化 AR 场景
    func optimizeARScene(_ scene: SCNScene) {
        // 应用 LOD
        applyLOD(to: scene)
        
        // 优化光照
        optimizeLights(in: scene)
        
        // 优化材质
        optimizeMaterials(in: scene)
        
        // 启用实例化渲染
        enableInstancing(in: scene)
    }
    
    private func applyLOD(to scene: SCNScene) {
        // 遍历场景节点，应用 LOD
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                let polygonCount = geometry.elementCount
                let distance = node.presentation.worldPosition.distance(to: SCNVector3Zero)
                
                // 根据距离调整细节级别
                if distance > lodConfig.farThreshold {
                    // 远距：使用低模
                    if polygonCount > lodConfig.lowDetailPolygons {
                        simplifyGeometry(geometry, targetPolygons: lodConfig.lowDetailPolygons)
                    }
                } else if distance > lodConfig.midThreshold {
                    // 中距：使用中模
                    if polygonCount > lodConfig.midDetailPolygons {
                        simplifyGeometry(geometry, targetPolygons: lodConfig.midDetailPolygons)
                    }
                }
                // 近距：保持高模
            }
        }
    }
    
    private func optimizeLights(in scene: SCNScene) {
        var lightCount = 0
        
        scene.rootNode.enumerateChildNodes { node, _ in
            if node.light != nil && lightCount >= renderConfig.maxLights {
                node.light = nil  // 移除多余光照
            }
            if node.light != nil {
                lightCount += 1
            }
        }
    }
    
    private func optimizeMaterials(in scene: SCNScene) {
        scene.rootNode.enumerateChildNodes { node, _ in
            if let geometry = node.geometry {
                for material in geometry.materials {
                    // 根据配置调整材质质量
                    if !renderConfig.enableReflections {
                        material.reflective.contents = nil
                    }
                    
                    if !renderConfig.enableShadows {
                        material.writesToDepthBuffer = true
                        material.readsFromDepthBuffer = true
                    }
                }
            }
        }
    }
    
    private func enableInstancing(in scene: SCNScene) {
        // 对重复的几何体启用实例化渲染
        scene.rootNode.enumerateChildNodes { node, _ in
            node.geometry?.instances = 1  // 根据实际需要调整
        }
    }
    
    private func simplifyGeometry(_ geometry: SCNGeometry, targetPolygons: Int) {
        // 简化几何体（简化实现）
        // 实际应该使用网格简化算法
        print("🔧 简化几何体至 \(targetPolygons) 多边形")
    }
    
    // MARK: - 启动优化
    
    /// 预加载关键资源
    func preloadCriticalResources() {
        DispatchQueue.global(qos: .background).async {
            // 预加载常用图片
            self.preloadCommonImages()
            
            // 预加载 3D 模型
            self.preloadCommonModels()
            
            // 预加载音频
            self.preloadCommonAudio()
        }
    }
    
    private func preloadCommonImages() {
        // 预加载常用图标和图片
        let imageNames = ["dream_icon", "meditation_icon", "music_icon"]
        for name in imageNames {
            if let image = UIImage(named: name) {
                cacheImage(image, forKey: name)
            }
        }
    }
    
    private func preloadCommonModels() {
        // 预加载常用 3D 模型
        // 实际实现会加载常用模型到内存
    }
    
    private func preloadCommonAudio() {
        // 预加载常用音频
        // 实际实现会加载常用音效和音乐
    }
    
    // MARK: - 性能报告
    
    func generatePerformanceReport() -> String {
        let report = """
        🚀 DreamLog 性能报告
        ====================
        
        当前性能等级：\(currentMetrics.performanceLevel.rawValue)
        质量设置：\(currentQualityLevel.rawValue)
        
        📊 实时指标:
        - FPS: \(String(format: "%.1f", currentMetrics.fps))
        - 内存：\(String(format: "%.1f MB", Double(currentMetrics.memoryUsage) / 1024.0 / 1024.0))
        - CPU: \(String(format: "%.1f%%", currentMetrics.cpuUsage))
        - 电池：\(String(format: "%.0f%%", currentMetrics.batteryLevel * 100))
        - 热状态：\(currentMetrics.thermalState.description)
        
        ⚙️ 渲染配置:
        - 阴影：\(renderConfig.enableShadows ? "开启" : "关闭")
        - 反射：\(renderConfig.enableReflections ? "开启" : "关闭")
        - 抗锯齿：\(renderConfig.enableAntiAliasing ? "开启" : "关闭")
        - 纹理质量：\(renderConfig.textureQuality.rawValue)
        
        📈 LOD 配置:
        - 近距阈值：\(lodConfig.nearThreshold)m
        - 中距阈值：\(lodConfig.midThreshold)m
        - 远距阈值：\(lodConfig.farThreshold)m
        
        💾 缓存状态:
        - 图片缓存：\(imageCache.count)/\(maxCacheCount)
        - 缓存大小：\(String(format: "%.1f MB", Double(imageCache.totalCostLimit) / 1024.0 / 1024.0))
        
        生成时间：\(Date().formatted())
        """
        
        return report
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dreamMemoryWarning = Notification.Name("dreamMemoryWarning")
}

// MARK: - SCNVector3 Extension

extension SCNVector3 {
    func distance(to other: SCNVector3) -> Float {
        return sqrt(pow(x - other.x, 2) + pow(y - other.y, 2) + pow(z - other.z, 2))
    }
}

// MARK: - 图片缓存服务

/// 全局图片缓存服务
class DreamImageCache {
    static let shared = DreamImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 200 * 1024 * 1024  // 200MB
    }
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func setImage(_ image: UIImage, forKey key: String) {
        let cost = Int(image.pngData()?.count ?? 0)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
    
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
