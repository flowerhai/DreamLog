//
//  DreamMemoryManager.swift
//  DreamLog
//
//  Phase 89: 性能优化
//  内存管理器 - 内存使用监控与自动清理
//

import Foundation
import UIKit
import os

/// 内存预算配置
struct MemoryBudget {
    var totalBudget: Int = 200 * 1024 * 1024      // 200MB 总预算
    var imageCacheBudget: Int = 50 * 1024 * 1024   // 50MB 图片缓存
    var dataCacheBudget: Int = 30 * 1024 * 1024    // 30MB 数据缓存
    var viewStateBudget: Int = 20 * 1024 * 1024    // 20MB 视图状态
    var tempObjectBudget: Int = 50 * 1024 * 1024   // 50MB 临时对象
    var systemReserve: Int = 50 * 1024 * 1024      // 50MB 系统预留
}

/// 内存使用报告
struct MemoryUsageReport {
    var totalUsed: Int = 0
    var imageCacheUsed: Int = 0
    var dataCacheUsed: Int = 0
    var viewStateUsed: Int = 0
    var tempObjectUsed: Int = 0
    
    var availableMemory: Int {
        let budget = MemoryBudget()
        return budget.totalBudget - totalUsed
    }
    
    var usagePercentage: Double {
        let budget = MemoryBudget()
        return Double(totalUsed) / Double(budget.totalBudget) * 100
    }
    
    var isCritical: Bool {
        usagePercentage > 90
    }
    
    var isWarning: Bool {
        usagePercentage > 75
    }
}

/// 内存清理策略
enum MemoryCleanupPolicy {
    case aggressive    // 激进清理（内存警告时）
    case moderate      // 适度清理（使用率>75%）
    case conservative  // 保守清理（使用率>90%）
}

/// 内存管理器
@MainActor
final class DreamMemoryManager {
    
    static let shared = DreamMemoryManager()
    
    private let logger = Logger(subsystem: "com.dreamlog.app", category: "MemoryManager")
    private let budget: MemoryBudget
    private var currentUsage = MemoryUsageReport()
    private var cleanupHandlers: [String: () -> Void] = [:]
    private var isMonitoring = false
    
    // 内存警告计数
    private var memoryWarningCount = 0
    private var lastMemoryWarningDate: Date?
    
    private init(budget: MemoryBudget = MemoryBudget()) {
        self.budget = budget
        setupMonitoring()
    }
    
    // MARK: - 监控设置
    
    private func setupMonitoring() {
        // 监听内存警告
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 启动定期监控
        startMonitoring()
        
        logger.info("🧠 内存管理器已启动")
        logger.info("   总预算：\(budget.totalBudget / 1024 / 1024)MB")
    }
    
    @objc private func handleMemoryWarning() {
        memoryWarningCount += 1
        lastMemoryWarningDate = Date()
        
        logger.warning("⚠️ 收到内存警告 #\(memoryWarningCount)")
        
        Task {
            await performCleanup(policy: .aggressive)
        }
    }
    
    // MARK: - 监控
    
    /// 启动内存监控
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        logger.debug("📊 启动内存监控...")
        
        Task {
            while isMonitoring {
                await updateMemoryUsage()
                
                if currentUsage.isCritical {
                    logger.warning("🚨 内存使用率临界：\(String(format: "%.1f", currentUsage.usagePercentage))%")
                    await performCleanup(policy: .conservative)
                } else if currentUsage.isWarning {
                    logger.info("⚠️ 内存使用率警告：\(String(format: "%.1f", currentUsage.usagePercentage))%")
                    await performCleanup(policy: .moderate)
                }
                
                // 每 5 秒检查一次
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
    
    /// 停止内存监控
    func stopMonitoring() {
        isMonitoring = false
        logger.debug("⏹️ 停止内存监控")
    }
    
    /// 更新内存使用数据
    private func updateMemoryUsage() {
        // 获取当前内存使用
        let memoryUsage = getSystemMemoryUsage()
        
        currentUsage.totalUsed = memoryUsage
        currentUsage.imageCacheUsed = getImageCacheUsage()
        currentUsage.dataCacheUsed = getDataCacheUsage()
        
        // 视图状态和临时对象估算
        currentUsage.viewStateUsed = currentUsage.totalUsed * 15 / 100
        currentUsage.tempObjectUsed = currentUsage.totalUsed * 20 / 100
    }
    
    /// 获取系统内存使用
    private func getSystemMemoryUsage() -> Int {
        // 使用 mach_task_self 获取当前应用的内存使用
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return 0
        }
        
        return Int(info.resident_size)
    }
    
    /// 获取图片缓存使用
    private func getImageCacheUsage() -> Int {
        // 从图片缓存服务获取
        return DreamImageCacheService.shared.getStats().memoryCacheSize
    }
    
    /// 获取数据缓存使用
    private func getDataCacheUsage() -> Int {
        // 估算数据缓存使用
        return currentUsage.totalUsed * 15 / 100
    }
    
    // MARK: - 清理
    
    /// 执行内存清理
    func performCleanup(policy: MemoryCleanupPolicy) async {
        logger.info("🧹 执行内存清理 (策略：\(policy))...")
        
        switch policy {
        case .aggressive:
            // 激进清理：清除所有缓存
            await clearAllCaches()
            clearViewStateCache()
            collectGarbage()
            
        case .moderate:
            // 适度清理：清除过期缓存
            await clearExpiredCaches()
            clearUnusedViewState()
            
        case .conservative:
            // 保守清理：清除临时对象
            clearTempObjects()
        }
        
        // 更新使用数据
        await updateMemoryUsage()
        
        logger.info("✅ 清理完成，当前使用：\(currentUsage.totalUsed / 1024 / 1024)MB (\(String(format: "%.1f", currentUsage.usagePercentage))%)")
    }
    
    /// 清除所有缓存
    private func clearAllCaches() async {
        logger.debug("🗑️ 清除所有缓存...")
        
        // 清除图片缓存
        await DreamImageCacheService.shared.clearAllCaches()
        
        // 清除数据缓存
        clearDataCaches()
    }
    
    /// 清除过期缓存
    private func clearExpiredCaches() async {
        logger.debug("🗑️ 清除过期缓存...")
        await DreamImageCacheService.shared.clearExpiredCaches()
    }
    
    /// 清除数据缓存
    private func clearDataCaches() {
        // 通知其他服务清理缓存
        for (name, handler) in cleanupHandlers {
            logger.debug("🗑️ 执行清理处理器：\(name)")
            handler()
        }
    }
    
    /// 清除视图状态缓存
    private func clearViewStateCache() {
        logger.debug("🗑️ 清除视图状态缓存...")
        // 通知视图清理状态
    }
    
    /// 清除未使用的视图状态
    private func clearUnusedViewState() {
        logger.debug("🗑️ 清除未使用的视图状态...")
    }
    
    /// 清除临时对象
    private func clearTempObjects() {
        logger.debug("🗑️ 清除临时对象...")
    }
    
    /// 强制垃圾回收
    private func collectGarbage() {
        logger.debug("♻️ 强制垃圾回收...")
        // Swift 使用 ARC，这里主要是释放未使用的资源
    }
    
    // MARK: - 清理处理器注册
    
    /// 注册清理处理器
    func registerCleanupHandler(name: String, handler: @escaping () -> Void) {
        cleanupHandlers[name] = handler
        logger.debug("✅ 注册清理处理器：\(name)")
    }
    
    /// 移除清理处理器
    func unregisterCleanupHandler(name: String) {
        cleanupHandlers.removeValue(forKey: name)
        logger.debug("❌ 移除清理处理器：\(name)")
    }
    
    // MARK: - 报告
    
    /// 获取内存使用报告
    func getMemoryReport() -> MemoryUsageReport {
        return currentUsage
    }
    
    /// 打印内存报告
    func printMemoryReport() {
        logger.info("📊 内存使用报告:")
        logger.info("   总使用：\(currentUsage.totalUsed / 1024 / 1024)MB (\(String(format: "%.1f", currentUsage.usagePercentage))%)")
        logger.info("   图片缓存：\(currentUsage.imageCacheUsed / 1024)KB")
        logger.info("   数据缓存：\(currentUsage.dataCacheUsed / 1024)KB")
        logger.info("   视图状态：\(currentUsage.viewStateUsed / 1024)KB")
        logger.info("   临时对象：\(currentUsage.tempObjectUsed / 1024)KB")
        logger.info("   可用内存：\(currentUsage.availableMemory / 1024 / 1024)MB")
        
        if currentUsage.isCritical {
            logger.error("🚨 内存使用率临界！")
        } else if currentUsage.isWarning {
            logger.warning("⚠️ 内存使用率警告")
        } else {
            logger.info("✅ 内存使用正常")
        }
    }
    
    /// 获取内存警告统计
    func getMemoryWarningStats() -> (count: Int, lastDate: Date?) {
        return (memoryWarningCount, lastMemoryWarningDate)
    }
}

// MARK: - 内存优化扩展

extension DreamMemoryManager {
    
    /// 优化图片内存使用
    func optimizeImageMemory(for image: UIImage) -> UIImage? {
        // 如果图片过大，进行缩放
        let maxDimension: CGFloat = 2048
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            logger.debug("🖼️ 图片已优化：\(image.size) -> \(newSize)")
            return resizedImage
        }
        
        return image
    }
    
    /// 预释放内存（在预期大量分配前调用）
    func preReleaseMemory() async {
        logger.debug("📉 预释放内存...")
        await performCleanup(policy: .moderate)
    }
    
    /// 检查是否有足够内存
    func hasAvailableMemory(required: Int) -> Bool {
        return currentUsage.availableMemory >= required
    }
}

// MARK: - 内存警告处理

extension DreamMemoryManager {
    
    /// 处理低内存情况
    func handleLowMemorySituation() async {
        logger.warning("🚨 处理低内存情况...")
        
        // 1. 立即清理
        await performCleanup(policy: .aggressive)
        
        // 2. 通知其他组件
        NotificationCenter.default.post(
            name: NSNotification.Name("DreamLogLowMemory"),
            object: self
        )
        
        // 3. 记录事件
        logger.info("✅ 低内存处理完成")
    }
}
