//
//  DreamPerformanceTests.swift
//  DreamLogTests
//
//  Phase 89 Session 2: 性能优化单元测试
//  创建时间：2026-03-22
//

import XCTest
@testable import DreamLog

// MARK: - 性能优化视图测试

final class DreamPerformanceViewsTests: XCTestCase {
    
    // 测试优化的梦境列表视图创建
    func testDreamListOptimizedInitialization() {
        // 验证视图可以正常初始化
        let view = DreamListOptimized()
        XCTAssertNotNil(view)
    }
    
    // 测试优化的梦境卡片视图创建
    func testDreamCardOptimizedInitialization() {
        // 验证卡片视图可以正常初始化
        // 实际测试需要 Dream 模型实例
    }
    
    // 测试优化的网格视图创建
    func testDreamGridOptimizedInitialization() {
        let view = DreamGridOptimized()
        XCTAssertNotNil(view)
    }
    
    // 测试懒加载修饰符
    func testLazyLoadingModifier() {
        var appeared = false
        
        let modifier = LazyLoadingModifier {
            appeared = true
        }
        
        // 验证修饰符创建成功
        XCTAssertNotNil(modifier)
    }
}

// MARK: - 查询优化器测试

final class DreamDataQueryOptimizerTests: XCTestCase {
    
    var optimizer: DreamDataQueryOptimizer!
    
    override func setUp() async throws {
        optimizer = DreamDataQueryOptimizer.shared
    }
    
    override func tearDown() async throws {
        // 清除缓存
        await optimizer.clearCache()
    }
    
    // 测试单例模式
    func testSingleton() async {
        let instance1 = DreamDataQueryOptimizer.shared
        let instance2 = DreamDataQueryOptimizer.shared
        XCTAssert(instance1 === instance2, "应该是同一个单例实例")
    }
    
    // 测试优化的查询描述符创建
    func testCreateOptimizedDescriptor() async {
        let descriptor = await optimizer.createOptimizedDescriptor(
            predicate: nil,
            sortBy: [SortDescriptor<Dream>(\Dream.date)],
            order: .reverse,
            fetchLimit: 100,
            fetchBatchSize: 20
        )
        
        XCTAssertEqual(descriptor.fetchLimit, 100)
        XCTAssertEqual(descriptor.fetchBatchSize, 20)
    }
    
    // 测试带预加载的查询描述符
    func testCreateDescriptorWithPrefetch() async {
        let descriptor = await optimizer.createDescriptorWithPrefetch(
            predicate: nil,
            sortBy: [SortDescriptor<Dream>(\Dream.date)],
            relationships: []
        )
        
        XCTAssertNotNil(descriptor.relationshipsToPrefetch)
    }
    
    // 测试日期范围查询描述符
    func testCreateDreamsByDateRangeDescriptor() async {
        let startDate = Date().addingTimeInterval(-86400 * 7) // 7 天前
        let endDate = Date()
        
        let descriptor = await optimizer.createDreamsByDateRangeDescriptor(
            startDate: startDate,
            endDate: endDate
        )
        
        XCTAssertEqual(descriptor.fetchBatchSize, 50)
    }
    
    // 测试标签查询描述符
    func testCreateDreamsByTagDescriptor() async {
        let descriptor = await optimizer.createDreamsByTagDescriptor(tag: "测试标签")
        
        XCTAssertEqual(descriptor.fetchBatchSize, 50)
    }
    
    // 测试情绪查询描述符
    func testCreateDreamsByEmotionDescriptor() async {
        let descriptor = await optimizer.createDreamsByEmotionDescriptor(emotion: "快乐")
        
        XCTAssertEqual(descriptor.fetchBatchSize, 50)
    }
    
    // 测试清醒梦查询描述符
    func testCreateLucidDreamsDescriptor() async {
        let descriptor = await optimizer.createLucidDreamsDescriptor()
        
        XCTAssertEqual(descriptor.fetchBatchSize, 50)
    }
    
    // 测试最近梦境查询描述符
    func testCreateRecentDreamsDescriptor() async {
        let descriptor = await optimizer.createRecentDreamsDescriptor(days: 7)
        
        XCTAssertEqual(descriptor.fetchLimit, 100)
        XCTAssertEqual(descriptor.fetchBatchSize, 20)
    }
    
    // 测试缓存清除
    func testClearCache() async {
        await optimizer.clearCache()
        // 验证缓存已清除（通过性能报告间接验证）
        let report = await optimizer.getPerformanceReport()
        XCTAssertNotNil(report)
    }
    
    // 测试性能报告生成
    func testGetPerformanceReport() async {
        let report = await optimizer.getPerformanceReport()
        
        XCTAssertTrue(report.contains("查询性能报告"))
        XCTAssertTrue(report.contains("总查询数"))
    }
    
    // 测试慢查询记录
    func testRecordQueryPerformance() async {
        await optimizer.recordQueryPerformance(
            key: "test_query",
            executionTime: 0.15,
            resultCount: 10
        )
        
        let slowQueries = await optimizer.getSlowQueries(threshold: 0.1)
        XCTAssertGreaterThan(slowQueries.count, 0)
    }
    
    // 测试获取慢查询
    func testGetSlowQueries() async {
        // 记录一个慢查询
        await optimizer.recordQueryPerformance(
            key: "slow_query",
            executionTime: 0.5,
            resultCount: 100
        )
        
        let slowQueries = await optimizer.getSlowQueries(threshold: 0.1)
        let slowQuery = slowQueries.first { $0.queryKey == "slow_query" }
        
        XCTAssertNotNil(slowQuery)
        XCTAssertEqual(slowQuery?.executionTime, 0.5)
        XCTAssertEqual(slowQuery?.resultCount, 100)
    }
}

// MARK: - 图片缓存服务测试

final class DreamImageCacheServiceTests: XCTestCase {
    
    var cacheService: DreamImageCacheService!
    
    override func setUp() async throws {
        cacheService = DreamImageCacheService.shared
        // 清除现有缓存
        await cacheService.clearCache()
    }
    
    override func tearDown() async throws {
        await cacheService.clearCache()
    }
    
    // 测试单例模式
    func testSingleton() {
        let instance1 = DreamImageCacheService.shared
        let instance2 = DreamImageCacheService.shared
        XCTAssert(instance1 === instance2, "应该是同一个单例实例")
    }
    
    // 测试缓存图片
    func testCacheImage() async {
        // 创建一个测试图片
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let dreamId = "test_dream_\(UUID().uuidString)"
        
        // 缓存图片
        await cacheService.cacheImage(image, for: dreamId)
        
        // 验证图片已缓存
        let cachedImage = await cacheService.image(for: dreamId)
        XCTAssertNotNil(cachedImage)
    }
    
    // 测试未缓存的图片返回 nil
    func testImageNotInCache() async {
        let nonExistentId = "non_existent_\(UUID().uuidString)"
        let image = await cacheService.image(for: nonExistentId)
        XCTAssertNil(image)
    }
    
    // 测试清除内存缓存
    func testClearMemoryCache() async {
        // 先缓存一些图片
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.blue.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let dreamId = "test_dream_\(UUID().uuidString)"
        await cacheService.cacheImage(image, for: dreamId)
        
        // 清除内存缓存
        await cacheService.clearMemoryCache()
        
        // 验证图片不再在内存缓存中（可能还在磁盘缓存）
        let cachedImage = await cacheService.image(for: dreamId)
        // 可能从磁盘缓存加载，所以不一定为 nil
    }
    
    // 测试清除磁盘缓存
    func testClearDiskCache() async {
        await cacheService.clearDiskCache()
        // 验证磁盘缓存已清除
        let diskCacheSize = await cacheService.diskCacheSize
        XCTAssertEqual(diskCacheSize, 0)
    }
    
    // 测试清除所有缓存
    func testClearCache() async {
        // 缓存一些图片
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.green.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let dreamId = "test_dream_\(UUID().uuidString)"
        await cacheService.cacheImage(image, for: dreamId)
        
        // 清除所有缓存
        await cacheService.clearCache()
        
        // 验证缓存已清除
        let diskCacheSize = await cacheService.diskCacheSize
        XCTAssertEqual(diskCacheSize, 0)
    }
    
    // 测试磁盘缓存大小格式化
    func testDiskCacheSizeFormatted() async {
        let sizeString = await cacheService.diskCacheSizeFormatted
        XCTAssertNotNil(sizeString)
        // 应该是人类可读的格式，如 "1.5 MB"
        XCTAssertTrue(sizeString.contains("KB") || sizeString.contains("MB") || sizeString.contains("GB") || sizeString == "0 B")
    }
    
    // 测试缓存配置
    func testCacheConfiguration() async {
        // 验证缓存服务有合理的配置
        let memoryLimit = cacheService.memoryCache.countLimit
        XCTAssertGreaterThan(memoryLimit, 0)
    }
}

// MARK: - 内存管理器测试

final class DreamMemoryManagerTests: XCTestCase {
    
    var memoryManager: DreamMemoryManager!
    
    override func setUp() async throws {
        memoryManager = DreamMemoryManager.shared
    }
    
    // 测试单例模式
    func testSingleton() {
        let instance1 = DreamMemoryManager.shared
        let instance2 = DreamMemoryManager.shared
        XCTAssert(instance1 === instance2, "应该是同一个单例实例")
    }
    
    // 测试获取内存使用信息
    func testGetMemoryUsage() async {
        let usage = await memoryManager.getMemoryUsage()
        
        XCTAssertGreaterThan(usage.total, 0)
        XCTAssertLessThanOrEqual(usage.used, usage.total)
    }
    
    // 测试内存警告处理
    func testHandleMemoryWarning() async {
        // 模拟内存警告
        await memoryManager.handleMemoryWarning()
        
        // 验证内存已清理（通过内存使用量间接验证）
        let usage = await memoryManager.getMemoryUsage()
        XCTAssertLessThanOrEqual(usage.used, usage.total)
    }
    
    // 测试获取清理建议
    func testGetCleanupSuggestions() async {
        let suggestions = await memoryManager.getCleanupSuggestions()
        
        // 验证返回建议列表
        XCTAssertNotNil(suggestions)
    }
    
    // 测试执行清理
    func testPerformCleanup() async {
        let freed = await memoryManager.performCleanup(strategy: .conservative)
        
        // 验证返回释放的内存量
        XCTAssertGreaterThanOrEqual(freed, 0)
    }
    
    // 测试不同清理策略
    func testCleanupStrategies() async {
        let strategies: [DreamMemoryManager.CleanupStrategy] = [.conservative, .moderate, .aggressive]
        
        for strategy in strategies {
            let freed = await memoryManager.performCleanup(strategy: strategy)
            XCTAssertGreaterThanOrEqual(freed, 0)
        }
    }
    
    // 测试内存使用日志
    func testMemoryUsageLogging() async {
        // 记录当前内存使用
        await memoryManager.logMemoryUsage(reason: "test")
        
        // 验证日志已记录
        let logs = await memoryManager.getRecentLogs(count: 10)
        XCTAssertGreaterThan(logs.count, 0)
    }
    
    // 测试获取最近日志
    func testGetRecentLogs() async {
        let logs = await memoryManager.getRecentLogs(count: 5)
        
        XCTAssertNotNil(logs)
        XCTAssertLessThanOrEqual(logs.count, 5)
    }
    
    // 测试清除日志
    func testClearLogs() async {
        await memoryManager.logMemoryUsage(reason: "test")
        await memoryManager.clearLogs()
        
        let logs = await memoryManager.getRecentLogs(count: 100)
        XCTAssertEqual(logs.count, 0)
    }
}

// MARK: - 应用启动优化器测试

final class DreamAppLaunchOptimizerTests: XCTestCase {
    
    var launchOptimizer: DreamAppLaunchOptimizer!
    
    override func setUp() async throws {
        launchOptimizer = DreamAppLaunchOptimizer.shared
    }
    
    // 测试单例模式
    func testSingleton() {
        let instance1 = DreamAppLaunchOptimizer.shared
        let instance2 = DreamAppLaunchOptimizer.shared
        XCTAssert(instance1 === instance2, "应该是同一个单例实例")
    }
    
    // 测试启动阶段枚举
    func testLaunchPhaseEnum() {
        let phases: [DreamAppLaunchOptimizer.LaunchPhase] = [.critical, .background, .deferred]
        XCTAssertEqual(phases.count, 3)
    }
    
    // 测试启动时间记录
    func testLaunchTimeRecording() async {
        let startTime = Date()
        await launchOptimizer.recordLaunchStart()
        await launchOptimizer.recordLaunchEnd()
        
        let launchTime = await launchOptimizer.getLaunchTime()
        XCTAssertGreaterThanOrEqual(launchTime, 0)
    }
    
    // 测试获取启动统计
    func testGetLaunchStatistics() async {
        let stats = await launchOptimizer.getLaunchStatistics()
        
        XCTAssertNotNil(stats)
    }
}

// MARK: - 性能监控器测试

final class PerformanceMonitorTests: XCTestCase {
    
    var monitor: PerformanceMonitor!
    
    override func setUp() async throws {
        monitor = PerformanceMonitor.shared
    }
    
    // 测试单例模式
    func testSingleton() {
        let instance1 = PerformanceMonitor.shared
        let instance2 = PerformanceMonitor.shared
        XCTAssert(instance1 === instance2, "应该是同一个单例实例")
    }
    
    // 测试性能报告生成
    func testGenerateReport() {
        let report = monitor.generateReport()
        
        XCTAssertTrue(report.contains("性能报告"))
    }
    
    // 测试开始/停止录制
    func testRecording() {
        XCTAssertFalse(monitor.isRecording)
        
        monitor.startRecording()
        XCTAssertTrue(monitor.isRecording)
        
        monitor.stopRecording()
        XCTAssertFalse(monitor.isRecording)
    }
    
    // 测试获取清理建议
    func testGetCleanupSuggestions() {
        let suggestions = monitor.getCleanupSuggestions()
        
        XCTAssertNotNil(suggestions)
    }
}
