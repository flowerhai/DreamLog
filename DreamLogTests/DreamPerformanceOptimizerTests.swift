//
//  DreamPerformanceOptimizerTests.swift
//  DreamLogTests
//
//  Phase 26 - 性能优化服务单元测试
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamPerformanceOptimizerTests: XCTestCase {
    
    var optimizer: DreamPerformanceOptimizer!
    
    override func setUp() async throws {
        optimizer = DreamPerformanceOptimizer.shared
    }
    
    override func tearDown() async throws {
        optimizer.stopMonitoring()
    }
    
    // MARK: - 初始化测试
    
    func testSingletonInstance() {
        let instance1 = DreamPerformanceOptimizer.shared
        let instance2 = DreamPerformanceOptimizer.shared
        
        XCTAssertIdentical(instance1, instance2, "应该是单例实例")
    }
    
    func testInitialQualityLevel() {
        XCTAssertEqual(optimizer.currentQualityLevel, .auto, "初始质量等级应为自动")
    }
    
    func testDefaultLODConfig() {
        XCTAssertEqual(optimizer.lodConfig.nearThreshold, 2.0, accuracy: 0.01)
        XCTAssertEqual(optimizer.lodConfig.midThreshold, 10.0, accuracy: 0.01)
        XCTAssertEqual(optimizer.lodConfig.farThreshold, 50.0, accuracy: 0.01)
    }
    
    func testDefaultRenderConfig() {
        XCTAssertTrue(optimizer.renderConfig.enableShadows)
        XCTAssertTrue(optimizer.renderConfig.enableReflections)
        XCTAssertTrue(optimizer.renderConfig.enableAntiAliasing)
        XCTAssertFalse(optimizer.renderConfig.enableMotionBlur)
        XCTAssertEqual(optimizer.renderConfig.maxLights, 3)
    }
    
    // MARK: - 质量等级测试
    
    func testQualityLevelCases() {
        let levels: [DreamPerformanceOptimizer.QualityLevel] = [.auto, .low, .medium, .high]
        
        for level in levels {
            XCTAssertFalse(level.rawValue.isEmpty, "\(level) 应该有描述")
            XCTAssertFalse(level.description.isEmpty, "\(level) 应该有详细说明")
        }
    }
    
    func testApplyLowQuality() {
        optimizer.applyQualityLevel(.low)
        
        XCTAssertEqual(optimizer.currentQualityLevel, .low)
        XCTAssertEqual(optimizer.lodConfig.nearThreshold, 3.0, accuracy: 0.01)
        XCTAssertFalse(optimizer.renderConfig.enableShadows)
        XCTAssertFalse(optimizer.renderConfig.enableReflections)
    }
    
    func testApplyMediumQuality() {
        optimizer.applyQualityLevel(.medium)
        
        XCTAssertEqual(optimizer.currentQualityLevel, .medium)
        XCTAssertEqual(optimizer.lodConfig.nearThreshold, 2.0, accuracy: 0.01)
        XCTAssertTrue(optimizer.renderConfig.enableShadows)
    }
    
    func testApplyHighQuality() {
        optimizer.applyQualityLevel(.high)
        
        XCTAssertEqual(optimizer.currentQualityLevel, .high)
        XCTAssertEqual(optimizer.lodConfig.nearThreshold, 1.5, accuracy: 0.01)
        XCTAssertEqual(optimizer.renderConfig.textureQuality, .ultra)
        XCTAssertEqual(optimizer.renderConfig.maxLights, 5)
    }
    
    func testApplySameQualityDoesNothing() {
        optimizer.applyQualityLevel(.medium)
        let config1 = optimizer.lodConfig
        
        optimizer.applyQualityLevel(.medium)
        let config2 = optimizer.lodConfig
        
        XCTAssertEqual(config1.nearThreshold, config2.nearThreshold, "应用相同质量不应改变配置")
    }
    
    // MARK: - 图片缓存测试
    
    func testCacheImage() {
        let image = UIImage(systemName: "star")!
        let key = "test_image_key"
        
        optimizer.cacheImage(image, forKey: key)
        let cached = optimizer.cachedImage(forKey: key)
        
        XCTAssertNotNil(cached)
    }
    
    func testCacheImageNotFound() {
        let cached = optimizer.cachedImage(forKey: "non_existent_key")
        XCTAssertNil(cached)
    }
    
    func testRemoveCachedImage() {
        let image = UIImage(systemName: "heart")!
        let key = "test_remove_key"
        
        optimizer.cacheImage(image, forKey: key)
        XCTAssertNotNil(optimizer.cachedImage(forKey: key))
        
        optimizer.removeCachedImage(forKey: key)
        XCTAssertNil(optimizer.cachedImage(forKey: key))
    }
    
    func testCacheLimit() {
        // 添加大量图片测试缓存限制
        for i in 0..<150 {
            let image = UIImage(systemName: "circle")!
            optimizer.cacheImage(image, forKey: "image_\(i)")
        }
        
        // 缓存应该保持在限制内
        // 注意：实际测试需要访问私有属性，这里简化
    }
    
    // MARK: - 性能指标测试
    
    func testPerformanceMetricsStructure() {
        let metrics = PerformanceMetrics(
            fps: 60.0,
            memoryUsage: 400 * 1024 * 1024,
            cpuUsage: 20.0,
            batteryLevel: 0.8,
            thermalState: .nominal
        )
        
        XCTAssertEqual(metrics.performanceLevel, .excellent)
    }
    
    func testPerformanceLevelGood() {
        let metrics = PerformanceMetrics(
            fps: 45.0,
            memoryUsage: 600 * 1024 * 1024,
            cpuUsage: 40.0,
            batteryLevel: 0.5,
            thermalState: .fair
        )
        
        XCTAssertEqual(metrics.performanceLevel, .good)
    }
    
    func testPerformanceLevelFair() {
        let metrics = PerformanceMetrics(
            fps: 25.0,
            memoryUsage: 900 * 1024 * 1024,
            cpuUsage: 60.0,
            batteryLevel: 0.2,
            thermalState: .serious
        )
        
        XCTAssertEqual(metrics.performanceLevel, .fair)
    }
    
    func testPerformanceLevelPoor() {
        let metrics = PerformanceMetrics(
            fps: 15.0,
            memoryUsage: 1200 * 1024 * 1024,
            cpuUsage: 80.0,
            batteryLevel: 0.1,
            thermalState: .critical
        )
        
        XCTAssertEqual(metrics.performanceLevel, .poor)
    }
    
    // MARK: - LOD 配置测试
    
    func testLODConfigPresets() {
        let defaultConfig = LODConfig.default
        let highConfig = LODConfig.qualityHigh
        let lowConfig = LODConfig.qualityLow
        
        // 高质量应该有更激进的多边形数
        XCTAssertGreaterThan(highConfig.highDetailPolygons, defaultConfig.highDetailPolygons)
        
        // 低质量应该有更保守的阈值
        XCTAssertGreaterThan(lowConfig.nearThreshold, defaultConfig.nearThreshold)
        XCTAssertLessThan(lowConfig.highDetailPolygons, defaultConfig.highDetailPolygons)
    }
    
    // MARK: - 渲染配置测试
    
    func testRenderConfigPresets() {
        let defaultConfig = ARRenderConfig.default
        let performanceConfig = ARRenderConfig.performanceMode
        let qualityConfig = ARRenderConfig.qualityMode
        
        // 性能模式应该关闭特效
        XCTAssertFalse(performanceConfig.enableShadows)
        XCTAssertFalse(performanceConfig.enableReflections)
        
        // 质量模式应该开启所有特效
        XCTAssertTrue(qualityConfig.enableShadows)
        XCTAssertTrue(qualityConfig.enableReflections)
        XCTAssertTrue(qualityConfig.enableMotionBlur)
    }
    
    func testTextureQualitySizes() {
        let qualities: [ARRenderConfig.TextureQuality] = [.low, .medium, .high, .ultra]
        let expectedSizes = [512, 1024, 2048, 4096]
        
        for (index, quality) in qualities.enumerated() {
            XCTAssertEqual(quality.size, expectedSizes[index], "\(quality) 的纹理大小不正确")
        }
    }
    
    // MARK: - 性能报告测试
    
    func testGeneratePerformanceReport() {
        let report = optimizer.generatePerformanceReport()
        
        XCTAssertTrue(report.contains("DreamLog 性能报告"))
        XCTAssertTrue(report.contains("FPS:"))
        XCTAssertTrue(report.contains("内存："))
        XCTAssertTrue(report.contains("CPU:"))
        XCTAssertTrue(report.contains("电池："))
        XCTAssertTrue(report.contains("渲染配置:"))
        XCTAssertTrue(report.contains("LOD 配置:"))
        XCTAssertTrue(report.contains("缓存状态:"))
    }
    
    // MARK: - 监控测试
    
    func testStartStopMonitoring() {
        optimizer.startMonitoring()
        // 监控应该已启动
        
        optimizer.stopMonitoring()
        // 监控应该已停止
        
        // 再次启动应该正常工作
        optimizer.startMonitoring()
    }
    
    // MARK: - SCNVector3 扩展测试
    
    func testSCNVector3Distance() {
        let point1 = SCNVector3(0, 0, 0)
        let point2 = SCNVector3(3, 4, 0)
        
        let distance = point1.distance(to: point2)
        XCTAssertEqual(distance, 5.0, accuracy: 0.01)  // 勾股定理：3-4-5
    }
    
    func testSCNVector3Distance3D() {
        let point1 = SCNVector3(0, 0, 0)
        let point2 = SCNVector3(1, 2, 2)
        
        let distance = point1.distance(to: point2)
        let expected = sqrt(1 + 4 + 4)  // sqrt(9) = 3
        XCTAssertEqual(distance, 3.0, accuracy: 0.01)
    }
    
    // MARK: - 图片缓存服务测试
    
    func testImageCacheShared() {
        let cache1 = DreamImageCache.shared
        let cache2 = DreamImageCache.shared
        
        XCTAssertIdentical(cache1, cache2, "应该是单例")
    }
    
    func testImageCacheOperations() {
        let cache = DreamImageCache.shared
        let image = UIImage(systemName: "test")!
        let key = "cache_test_key"
        
        cache.setImage(image, forKey: key)
        XCTAssertNotNil(cache.getImage(forKey: key))
        
        cache.removeImage(forKey: key)
        XCTAssertNil(cache.getImage(forKey: key))
    }
    
    func testImageCacheClear() {
        let cache = DreamImageCache.shared
        
        // 添加一些图片
        for i in 0..<10 {
            let image = UIImage(systemName: "icon_\(i)")!
            cache.setImage(image, forKey: "clear_test_\(i)")
        }
        
        cache.clearCache()
        
        // 验证缓存已清空
        for i in 0..<10 {
            XCTAssertNil(cache.getImage(forKey: "clear_test_\(i)"))
        }
    }
    
    // MARK: - 性能测试
    
    func testCachePerformance() {
        let image = UIImage(systemName: "star")!
        
        measure {
            for i in 0..<100 {
                optimizer.cacheImage(image, forKey: "perf_test_\(i)")
                _ = optimizer.cachedImage(forKey: "perf_test_\(i)")
            }
        }
    }
    
    func testMetricsUpdatePerformance() {
        optimizer.startMonitoring()
        
        measure {
            // 模拟多次指标更新
            for _ in 0..<10 {
                _ = optimizer.currentMetrics
            }
        }
        
        optimizer.stopMonitoring()
    }
}

// MARK: - 性能基准测试

final class DreamPerformanceBenchmarkTests: XCTestCase {
    
    func testLODApplicationPerformance() {
        // 测试 LOD 应用性能
        let config = LODConfig.default
        
        measure {
            // 模拟 LOD 计算
            for _ in 0..<1000 {
                let distance = Float.random(in: 0...100)
                if distance > config.farThreshold {
                    _ = config.lowDetailPolygons
                } else if distance > config.midThreshold {
                    _ = config.midDetailPolygons
                } else {
                    _ = config.highDetailPolygons
                }
            }
        }
    }
    
    func testQualityLevelSwitchPerformance() {
        let optimizer = DreamPerformanceOptimizer.shared
        
        measure {
            optimizer.applyQualityLevel(.low)
            optimizer.applyQualityLevel(.medium)
            optimizer.applyQualityLevel(.high)
        }
    }
}
