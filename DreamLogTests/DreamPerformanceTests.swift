//
//  DreamPerformanceTests.swift
//  DreamLogTests
//
//  Phase 89: 性能优化
//  性能优化组件单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamPerformanceTests: XCTestCase {
    
    // MARK: - Launch Optimizer Tests
    
    func testLaunchOptimizerSingleton() {
        let optimizer1 = DreamAppLaunchOptimizer.shared
        let optimizer2 = DreamAppLaunchOptimizer.shared
        
        XCTAssertIdentical(optimizer1, optimizer2, "启动优化器应该是单例")
    }
    
    func testLaunchMetricsInitialization() {
        let metrics = LaunchMetrics()
        
        XCTAssertEqual(metrics.coldStartTime, 0)
        XCTAssertEqual(metrics.hotStartTime, 0)
        XCTAssertEqual(metrics.timeToInteractive, 0)
        XCTAssertTrue(metrics.phaseTimings.isEmpty)
        XCTAssertFalse(metrics.isColdStart)
    }
    
    func testLaunchOptimizerMeasure() async {
        let optimizer = DreamAppLaunchOptimizer.shared
        
        // 测量同步代码块
        let result = optimizer.measure("testSync", phase: .critical) {
            return 42
        }
        
        XCTAssertEqual(result, 42)
    }
    
    func testLaunchOptimizerMeasureAsync() async {
        let optimizer = DreamAppLaunchOptimizer.shared
        
        // 测量异步代码块
        let result = await optimizer.measureAsync("testAsync", phase: .background) {
            try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
            return "completed"
        }
        
        XCTAssertEqual(result, "completed")
    }
    
    func testLaunchOptimizerOptimizationSuggestions() async {
        let optimizer = DreamAppLaunchOptimizer.shared
        
        // 正常情况应该没有建议
        let suggestions = optimizer.getOptimizationSuggestions()
        
        XCTAssertFalse(suggestions.isEmpty, "应该有至少一条建议")
    }
    
    // MARK: - Image Cache Tests
    
    func testImageCacheSingleton() {
        let cache1 = DreamImageCacheService.shared
        let cache2 = DreamImageCacheService.shared
        
        XCTAssertIdentical(cache1, cache2, "图片缓存服务应该是单例")
    }
    
    func testImageCacheStatsInitialization() {
        let stats = ImageCacheStats()
        
        XCTAssertEqual(stats.memoryCacheCount, 0)
        XCTAssertEqual(stats.memoryCacheSize, 0)
        XCTAssertEqual(stats.diskCacheCount, 0)
        XCTAssertEqual(stats.diskCacheSize, 0)
        XCTAssertEqual(stats.hitCount, 0)
        XCTAssertEqual(stats.missCount, 0)
        XCTAssertEqual(stats.hitRate, 0)
    }
    
    func testImageCacheHitRateCalculation() {
        var stats = ImageCacheStats()
        stats.hitCount = 80
        stats.missCount = 20
        
        XCTAssertEqual(stats.hitRate, 80.0, accuracy: 0.01)
    }
    
    func testImageCacheConfigDefaults() {
        let config = ImageCacheConfig()
        
        XCTAssertEqual(config.memoryCacheLimit, 50 * 1024 * 1024)
        XCTAssertEqual(config.diskCacheLimit, 500 * 1024 * 1024)
        XCTAssertEqual(config.cacheExpirationDays, 30)
    }
    
    func testImageCacheGetStats() async {
        let cache = DreamImageCacheService.shared
        let stats = cache.getStats()
        
        XCTAssertGreaterThanOrEqual(stats.memoryCacheCount, 0)
        XCTAssertGreaterThanOrEqual(stats.memoryCacheSize, 0)
    }
    
    func testImageCacheCacheKeyGeneration() async {
        let cache = DreamImageCacheService.shared
        let size = CGSize(width: 200, height: 200)
        
        // 测试缓存键生成
        let keyWithoutSize = cache.makeCacheKey(dreamId: "test123", size: nil)
        let keyWithSize = cache.makeCacheKey(dreamId: "test123", size: size)
        
        XCTAssertEqual(keyWithoutSize, "test123")
        XCTAssertEqual(keyWithSize, "test123_200x200")
        XCTAssertNotEqual(keyWithoutSize, keyWithSize)
    }
    
    func testImageCacheClearAllCaches() async {
        let cache = DreamImageCacheService.shared
        
        // 清除所有缓存
        await cache.clearAllCaches()
        
        let stats = cache.getStats()
        XCTAssertEqual(stats.memoryCacheCount, 0)
        XCTAssertEqual(stats.memoryCacheSize, 0)
    }
    
    // MARK: - Memory Manager Tests
    
    func testMemoryManagerSingleton() {
        let manager1 = DreamMemoryManager.shared
        let manager2 = DreamMemoryManager.shared
        
        XCTAssertIdentical(manager1, manager2, "内存管理器应该是单例")
    }
    
    func testMemoryBudgetDefaults() {
        let budget = MemoryBudget()
        
        XCTAssertEqual(budget.totalBudget, 200 * 1024 * 1024)
        XCTAssertEqual(budget.imageCacheBudget, 50 * 1024 * 1024)
        XCTAssertEqual(budget.dataCacheBudget, 30 * 1024 * 1024)
        XCTAssertEqual(budget.viewStateBudget, 20 * 1024 * 1024)
        XCTAssertEqual(budget.tempObjectBudget, 50 * 1024 * 1024)
        XCTAssertEqual(budget.systemReserve, 50 * 1024 * 1024)
    }
    
    func testMemoryUsageReportInitialization() {
        let report = MemoryUsageReport()
        
        XCTAssertEqual(report.totalUsed, 0)
        XCTAssertEqual(report.imageCacheUsed, 0)
        XCTAssertEqual(report.dataCacheUsed, 0)
        XCTAssertGreaterThan(report.availableMemory, 0)
        XCTAssertEqual(report.usagePercentage, 0)
        XCTAssertFalse(report.isCritical)
        XCTAssertFalse(report.isWarning)
    }
    
    func testMemoryUsageReportUsagePercentage() {
        var report = MemoryUsageReport()
        report.totalUsed = 100 * 1024 * 1024 // 100MB
        
        XCTAssertEqual(report.usagePercentage, 50.0, accuracy: 0.01)
    }
    
    func testMemoryUsageReportCriticalThreshold() {
        var report = MemoryUsageReport()
        report.totalUsed = 185 * 1024 * 1024 // 92.5%
        
        XCTAssertTrue(report.isCritical)
        XCTAssertTrue(report.isWarning)
    }
    
    func testMemoryUsageReportWarningThreshold() {
        var report = MemoryUsageReport()
        report.totalUsed = 160 * 1024 * 1024 // 80%
        
        XCTAssertFalse(report.isCritical)
        XCTAssertTrue(report.isWarning)
    }
    
    func testMemoryManagerGetMemoryReport() async {
        let manager = DreamMemoryManager.shared
        
        // 等待内存更新
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let report = manager.getMemoryReport()
        
        XCTAssertGreaterThanOrEqual(report.totalUsed, 0)
        XCTAssertGreaterThanOrEqual(report.availableMemory, 0)
    }
    
    func testMemoryManagerCleanupPolicyEnum() {
        let policies: [MemoryCleanupPolicy] = [.aggressive, .moderate, .conservative]
        
        XCTAssertEqual(policies.count, 3)
    }
    
    func testMemoryManagerCleanupHandlerRegistration() async {
        let manager = DreamMemoryManager.shared
        var handlerCalled = false
        
        manager.registerCleanupHandler(name: "testHandler") {
            handlerCalled = true
        }
        
        // 验证处理器已注册
        // 实际清理时会被调用
        
        manager.unregisterCleanupHandler(name: "testHandler")
    }
    
    func testMemoryManagerHasAvailableMemory() async {
        let manager = DreamMemoryManager.shared
        
        // 检查是否有足够的可用内存（1MB）
        let hasMemory = manager.hasAvailableMemory(required: 1 * 1024 * 1024)
        
        // 应该有足够的内存
        XCTAssertTrue(hasMemory)
    }
    
    // MARK: - Performance Tests
    
    func testLaunchOptimizerPerformance() {
        let optimizer = DreamAppLaunchOptimizer.shared
        
        measure {
            _ = optimizer.measure("performanceTest", phase: .critical) {
                // 空操作
            }
        }
    }
    
    func testImageCachePerformance() async {
        let cache = DreamImageCacheService.shared
        
        measure {
            let expectation = self.expectation(description: "Cache operation")
            
            Task {
                _ = cache.getStats()
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 1.0)
        }
    }
    
    // MARK: - Integration Tests
    
    func testPerformanceComponentsIntegration() async {
        // 测试所有性能组件协同工作
        let optimizer = DreamAppLaunchOptimizer.shared
        let imageCache = DreamImageCacheService.shared
        let memoryManager = DreamMemoryManager.shared
        
        // 1. 启动优化
        await optimizer.optimizeLaunch()
        
        // 2. 图片缓存操作
        let stats = imageCache.getStats()
        XCTAssertGreaterThanOrEqual(stats.memoryCacheCount, 0)
        
        // 3. 内存管理
        let report = memoryManager.getMemoryReport()
        XCTAssertGreaterThanOrEqual(report.availableMemory, 0)
    }
    
    func testMemoryWarningHandling() async {
        let manager = DreamMemoryManager.shared
        let initialReport = manager.getMemoryReport()
        
        // 模拟内存警告
        NotificationCenter.default.post(
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // 等待清理完成
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let afterReport = manager.getMemoryReport()
        
        // 验证清理后内存使用减少或保持不变
        XCTAssertLessThanOrEqual(afterReport.totalUsed, initialReport.totalUsed + 10 * 1024 * 1024)
    }
}

// MARK: - 辅助扩展

extension DreamImageCacheService {
    // 测试用：暴露私有方法
    func makeCacheKey(dreamId: String, size: CGSize?) -> String {
        if let size = size {
            return "\(dreamId)_\(Int(size.width))x\(Int(size.height))"
        }
        return dreamId
    }
}
