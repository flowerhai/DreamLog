//
//  DreamLogPerformanceOptimizer.swift
//  DreamLog
//
//  性能优化服务 - 启动优化/内存管理/缓存策略/数据库优化
//  Phase 35 - 性能优化 ✨
//

import Foundation
import SwiftUI
import SwiftData

/// 性能优化服务单例
@MainActor
final class DreamLogPerformanceOptimizer {
    static let shared = DreamLogPerformanceOptimizer()
    
    // MARK: - 性能指标
    
    /// 启动时间记录
    private var launchTime: CFAbsoluteTime = 0
    private var isLaunchTimeRecorded = false
    
    /// 内存警告计数
    private var memoryWarningCount = 0
    
    /// 缓存统计
    private var cacheHitCount = 0
    private var cacheMissCount = 0
    
    // MARK: - 缓存配置
    
    /// 图片缓存 - 100MB 限制
    lazy var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100 // 最多 100 张图片
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
        return cache
    }()
    
    /// 数据缓存 - 50MB 限制
    lazy var dataCache: NSCache<NSString, NSData> = {
        let cache = NSCache<NSString, NSData>()
        cache.countLimit = 50
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        return cache
    }()
    
    /// 查询结果缓存
    private var queryCache: [String: Any] = [:]
    private let queryCacheQueue = DispatchQueue(label: "com.dreamlog.querycache", attributes: .concurrent)
    
    // MARK: - 初始化
    
    private init() {
        registerForMemoryWarnings()
        recordLaunchTime()
    }
    
    // MARK: - 启动优化
    
    /// 记录启动时间
    private func recordLaunchTime() {
        launchTime = CFAbsoluteTimeGetCurrent()
        isLaunchTimeRecorded = true
    }
    
    /// 获取启动时间（毫秒）
    func getLaunchTime() -> TimeInterval {
        guard isLaunchTimeRecorded else { return 0 }
        return (CFAbsoluteTimeGetCurrent() - launchTime) * 1000
    }
    
    /// 记录启动性能指标
    func logLaunchPerformance() {
        let launchTime = getLaunchTime()
        print("🚀 启动时间：\(String(format: "%.2f", launchTime))ms")
        
        if launchTime < 2000 {
            print("✅ 启动性能优秀 (< 2 秒)")
        } else if launchTime < 3000 {
            print("⚠️ 启动性能良好 (< 3 秒)")
        } else {
            print("🔴 启动性能需优化 (> 3 秒)")
        }
    }
    
    // MARK: - 内存管理
    
    /// 注册内存警告通知
    private func registerForMemoryWarnings() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        #endif
    }
    
    /// 处理内存警告
    @objc private func handleMemoryWarning() {
        memoryWarningCount += 1
        print("⚠️ 收到内存警告 #\(memoryWarningCount)")
        
        // 清空所有缓存
        clearAllCaches()
        
        // 报告内存使用
        reportMemoryUsage()
    }
    
    /// 清空所有缓存
    func clearAllCaches() {
        imageCache.removeAllObjects()
        dataCache.removeAllObjects()
        
        queryCacheQueue.async(flags: .barrier) {
            self.queryCache.removeAll()
        }
        
        print("🧹 已清空所有缓存")
    }
    
    /// 报告当前内存使用情况
    func reportMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        print("📊 内存使用：\(String(format: "%.2f", memoryUsage)) MB")
        
        if memoryUsage > 200 {
            print("🔴 内存使用过高 (> 200MB)")
        } else if memoryUsage > 100 {
            print("⚠️ 内存使用正常 (100-200MB)")
        } else {
            print("✅ 内存使用优秀 (< 100MB)")
        }
    }
    
    /// 获取当前内存使用（MB）
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return 0
        }
        
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
    
    // MARK: - 图片缓存
    
    /// 获取缓存的图片
    func getCachedImage(forKey key: String) -> UIImage? {
        let nsKey = key as NSString
        if let image = imageCache.object(forKey: nsKey) {
            cacheHitCount += 1
            return image
        }
        cacheMissCount += 1
        return nil
    }
    
    /// 缓存图片
    func cacheImage(_ image: UIImage, forKey key: String) {
        let nsKey = key as NSString
        // 估算图片大小（粗略）
        let cost = Int(image.pngData()?.count ?? 0)
        imageCache.setObject(image, forKey: nsKey, cost: cost)
    }
    
    /// 获取缓存命中率
    func getCacheHitRate() -> Double {
        let total = cacheHitCount + cacheMissCount
        guard total > 0 else { return 0 }
        return Double(cacheHitCount) / Double(total) * 100
    }
    
    // MARK: - 查询缓存
    
    /// 获取缓存的查询结果
    func getCachedQuery<T>(forKey key: String) -> T? {
        var result: T?
        queryCacheQueue.sync {
            result = queryCache[key] as? T
        }
        return result
    }
    
    /// 缓存查询结果
    func cacheQuery<T>(_ value: T, forKey key: String) {
        queryCacheQueue.async(flags: .barrier) {
            self.queryCache[key] = value
        }
    }
    
    /// 清除查询缓存
    func clearQueryCache() {
        queryCacheQueue.async(flags: .barrier) {
            self.queryCache.removeAll()
        }
    }
    
    // MARK: - 懒加载优化
    
    /// 懒加载配置
    struct LazyLoadConfig {
        /// 是否启用懒加载
        var enabled: Bool = true
        /// 预加载阈值（提前加载多少条）
        var prefetchThreshold: Int = 10
        /// 每页加载数量
        var pageSize: Int = 50
        /// 图片加载延迟（毫秒）
        var imageLoadDelay: Int = 50
    }
    
    /// 默认懒加载配置
    let defaultLazyLoadConfig = LazyLoadConfig(
        enabled: true,
        prefetchThreshold: 10,
        pageSize: 50,
        imageLoadDelay: 50
    )
    
    // MARK: - 数据库优化
    
    /// 优化 SwiftData 查询
    func optimizeQuery<T: PersistentModel>(_ type: T.Type) -> FetchDescriptor<T> {
        var descriptor = FetchDescriptor<T>()
        
        // 默认按日期排序（利用索引）
        descriptor.sortBy = [SortDescriptor(\T.self, keyPath: \.date, order: .reverse)]
        
        // 限制结果数量（分页）
        descriptor.fetchLimit = defaultLazyLoadConfig.pageSize
        
        return descriptor
    }
    
    /// 批量操作优化
    func performBatchOperation<T: PersistentModel>(
        in modelContext: ModelContext,
        count: Int,
        operation: @escaping (Int) -> T
    ) async {
        // 使用事务批量插入
        modelContext.beginTransaction()
        
        for i in 0..<count {
            let item = operation(i)
            modelContext.insert(item)
            
            // 每 100 条提交一次，避免内存峰值
            if (i + 1) % 100 == 0 {
                try? modelContext.save()
                modelContext.beginTransaction()
            }
        }
        
        // 提交剩余数据
        try? modelContext.save()
    }
    
    // MARK: - AR 性能优化
    
    /// AR 性能配置
    struct ARPerformanceConfig {
        /// LOD（细节层次）启用
        var lodEnabled: Bool = true
        /// LOD 距离阈值（米）
        var lodDistances: [Float] = [5.0, 15.0, 30.0]
        /// 纹理质量（0-1）
        var textureQuality: Float = 0.8
        /// 阴影质量（0-1）
        var shadowQuality: Float = 0.7
        /// 抗锯齿模式
        var antialiasing: Bool = true
        /// 目标帧率
        var targetFrameRate: Int = 60
    }
    
    /// 默认 AR 性能配置
    let defaultARPerformanceConfig = ARPerformanceConfig(
        lodEnabled: true,
        lodDistances: [5.0, 15.0, 30.0],
        textureQuality: 0.8,
        shadowQuality: 0.7,
        antialiasing: true,
        targetFrameRate: 60
    )
    
    // MARK: - 性能监控
    
    /// 性能监控数据
    struct PerformanceMetrics {
        /// 启动时间（毫秒）
        var launchTime: TimeInterval = 0
        /// 当前内存使用（MB）
        var memoryUsage: Double = 0
        /// 缓存命中率（%）
        var cacheHitRate: Double = 0
        /// 帧率（FPS）
        var frameRate: Int = 0
        /// 数据库查询时间（毫秒）
        var queryTime: TimeInterval = 0
    }
    
    /// 获取当前性能指标
    func getCurrentMetrics() -> PerformanceMetrics {
        return PerformanceMetrics(
            launchTime: getLaunchTime(),
            memoryUsage: getMemoryUsage(),
            cacheHitRate: getCacheHitRate(),
            frameRate: 60, // 需要从 CADisplayLink 获取
            queryTime: 0 // 需要从实际查询中获取
        )
    }
    
    /// 性能基准测试
    func runBenchmark() async -> PerformanceMetrics {
        print("🏃 开始性能基准测试...")
        
        let metrics = getCurrentMetrics()
        
        print("📊 性能基准测试结果:")
        print("  - 启动时间：\(String(format: "%.2f", metrics.launchTime))ms")
        print("  - 内存使用：\(String(format: "%.2f", metrics.memoryUsage))MB")
        print("  - 缓存命中率：\(String(format: "%.1f", metrics.cacheHitRate))%")
        
        return metrics
    }
}

// MARK: - 辅助扩展

extension UIImage {
    /// 压缩图片到指定大小
    func compressed(to maxSize: Int = 500 * 1024) -> Data? {
        var compression: CGFloat = 1.0
        var data = self.pngData()
        
        while let currentData = data, currentData.count > maxSize, compression > 0.1 {
            compression -= 0.1
            data = self.jpegData(compressionQuality: compression)
        }
        
        return data
    }
    
    /// 调整图片尺寸
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

// MARK: - 预览

#Preview {
    VStack {
        Text("性能优化服务")
            .font(.title)
        
        Button("运行基准测试") {
            Task {
                await DreamLogPerformanceOptimizer.shared.runBenchmark()
            }
        }
        
        Button("清空缓存") {
            Task {
                await DreamLogPerformanceOptimizer.shared.clearAllCaches()
            }
        }
        
        Button("报告内存") {
            Task {
                await DreamLogPerformanceOptimizer.shared.reportMemoryUsage()
            }
        }
    }
}
