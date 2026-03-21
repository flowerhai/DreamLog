//
//  DreamArtStyleTransferTests.swift
//  DreamLogTests
//
//  Phase 81: 梦境 AI 绘画增强 - 艺术风格迁移与滤镜系统
//  Created: 2026-03-21
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamArtStyleTransferTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var service: DreamArtStyleTransferService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存存储容器
        let schema = Schema([
            DreamArtStyleTransfer.self,
            CustomArtStyle.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        service = DreamArtStyleTransferService(modelContainer: modelContainer)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Art Style Type Tests
    
    func testArtStyleTypeCases() {
        // 测试所有风格类型
        XCTAssertEqual(ArtStyleType.allCases.count, 16)
        
        // 测试显示名称
        XCTAssertEqual(ArtStyleType.impressionist.displayName, "印象派")
        XCTAssertEqual(ArtStyleType.postImpressionist.displayName, "后印象派")
        XCTAssertEqual(ArtStyleType.cubist.displayName, "立体主义")
        XCTAssertEqual(ArtStyleType.surrealist.displayName, "超现实主义")
        XCTAssertEqual(ArtStyleType.dreamy.displayName, "梦幻风格")
        
        // 测试描述
        XCTAssertFalse(ArtStyleType.impressionist.description.isEmpty)
        XCTAssertFalse(ArtStyleType.postImpressionist.description.isEmpty)
        
        // 测试艺术家列表
        XCTAssertTrue(ArtStyleType.postImpressionist.artists.contains("梵高"))
        XCTAssertTrue(ArtStyleType.cubist.artists.contains("毕加索"))
        
        // 测试代表作品
        XCTAssertTrue(ArtStyleType.postImpressionist.exampleWorks.contains("星夜"))
        XCTAssertTrue(ArtStyleType.impressionist.exampleWorks.contains("睡莲"))
    }
    
    func testArtStyleTypeDefaultIntensity() {
        // 测试默认强度值
        XCTAssertEqual(ArtStyleType.impressionist.defaultIntensity, 0.7, accuracy: 0.01)
        XCTAssertEqual(ArtStyleType.postImpressionist.defaultIntensity, 0.8, accuracy: 0.01)
        XCTAssertEqual(ArtStyleType.custom.defaultIntensity, 0.5, accuracy: 0.01)
    }
    
    func testArtStyleTypeCodable() throws {
        // 测试 Codable 编码解码
        let style = ArtStyleType.postImpressionist
        let encoded = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(ArtStyleType.self, from: encoded)
        
        XCTAssertEqual(style, decoded)
    }
    
    func testAllStylesWithPreview() {
        // 测试所有风格预览数据
        let previewData = ArtStyleType.allStylesWithPreview
        
        XCTAssertEqual(previewData.count, 15)
        
        for (style, gradient) in previewData {
            XCTAssertEqual(gradient.count, 3, "风格 \(style.displayName) 应该有 3 个渐变色")
            
            for color in gradient {
                XCTAssertTrue(color.hasPrefix("#"), "颜色应该是十六进制格式")
            }
        }
    }
    
    // MARK: - Style Transfer Config Tests
    
    func testStyleTransferConfigDefault() {
        let config = StyleTransferConfig(styleType: .impressionist)
        
        XCTAssertEqual(config.styleType, .impressionist)
        XCTAssertEqual(config.intensity, 0.7, accuracy: 0.01)
        XCTAssertEqual(config.preserveContent, 0.5, accuracy: 0.01)
        XCTAssertTrue(config.colorTransfer)
        XCTAssertEqual(config.resolution, .high)
    }
    
    func testStyleTransferConfigCustom() {
        let config = StyleTransferConfig(
            styleType: .cubist,
            intensity: 0.6,
            preserveContent: 0.7,
            colorTransfer: false,
            resolution: .medium
        )
        
        XCTAssertEqual(config.styleType, .cubist)
        XCTAssertEqual(config.intensity, 0.6, accuracy: 0.01)
        XCTAssertEqual(config.preserveContent, 0.7, accuracy: 0.01)
        XCTAssertFalse(config.colorTransfer)
        XCTAssertEqual(config.resolution, .medium)
    }
    
    func testImageResolutionRawValues() {
        XCTAssertEqual(StyleTransferConfig.ImageResolution.low.rawValue, "512x512")
        XCTAssertEqual(StyleTransferConfig.ImageResolution.medium.rawValue, "768x768")
        XCTAssertEqual(StyleTransferConfig.ImageResolution.high.rawValue, "1024x1024")
        XCTAssertEqual(StyleTransferConfig.ImageResolution.ultra.rawValue, "2048x2048")
    }
    
    // MARK: - Style Mix Config Tests
    
    func testStyleMixConfigDefault() {
        let config = StyleMixConfig(
            style1: .impressionist,
            style2: .postImpressionist
        )
        
        XCTAssertEqual(config.style1, .impressionist)
        XCTAssertEqual(config.style2, .postImpressionist)
        XCTAssertEqual(config.mixRatio, 0.5, accuracy: 0.01)
        XCTAssertEqual(config.blendMode, .linear)
    }
    
    func testStyleMixConfigCustom() {
        let config = StyleMixConfig(
            style1: .cyberpunk,
            style2: .dreamy,
            mixRatio: 0.7,
            blendMode: .overlay
        )
        
        XCTAssertEqual(config.style1, .cyberpunk)
        XCTAssertEqual(config.style2, .dreamy)
        XCTAssertEqual(config.mixRatio, 0.7, accuracy: 0.01)
        XCTAssertEqual(config.blendMode, .overlay)
    }
    
    func testBlendModeRawValues() {
        XCTAssertEqual(StyleMixConfig.BlendMode.linear.rawValue, "linear")
        XCTAssertEqual(StyleMixConfig.BlendMode.overlay.rawValue, "overlay")
        XCTAssertEqual(StyleMixConfig.BlendMode.multiply.rawValue, "multiply")
        XCTAssertEqual(StyleMixConfig.BlendMode.screen.rawValue, "screen")
        XCTAssertEqual(StyleMixConfig.BlendMode.softLight.rawValue, "soft_light")
    }
    
    // MARK: - DreamArtStyleTransfer Model Tests
    
    func testDreamArtStyleTransferInitialization() {
        let transfer = DreamArtStyleTransfer(
            dreamId: UUID(),
            originalImageId: "original_123",
            styleType: "post_impressionist",
            styleIntensity: 0.8,
            resultImageId: "result_456",
            processingTime: 2.5
        )
        
        XCTAssertNotNil(transfer.id)
        XCTAssertNotNil(transfer.createdAt)
        XCTAssertFalse(transfer.isFavorite)
        XCTAssertEqual(transfer.styleType, "post_impressionist")
        XCTAssertEqual(transfer.styleIntensity, 0.8, accuracy: 0.01)
        XCTAssertEqual(transfer.processingTime, 2.5, accuracy: 0.01)
    }
    
    func testDreamArtStyleTransferFavorite() {
        let transfer = DreamArtStyleTransfer(
            dreamId: UUID(),
            originalImageId: "original_123",
            styleType: "impressionist",
            styleIntensity: 0.7,
            resultImageId: "result_456"
        )
        
        XCTAssertFalse(transfer.isFavorite)
        transfer.isFavorite = true
        XCTAssertTrue(transfer.isFavorite)
    }
    
    // MARK: - CustomArtStyle Model Tests
    
    func testCustomArtStyleInitialization() {
        let customStyle = CustomArtStyle(
            name: "我的风格",
            description: "自定义艺术风格",
            baseStyleType: "custom"
        )
        
        XCTAssertNotNil(customStyle.id)
        XCTAssertEqual(customStyle.name, "我的风格")
        XCTAssertEqual(customStyle.description, "自定义艺术风格")
        XCTAssertEqual(customStyle.baseStyleType, "custom")
        XCTAssertEqual(customStyle.usageCount, 0)
    }
    
    func testCustomArtStyleUsageCount() {
        let customStyle = CustomArtStyle(name: "测试风格")
        
        XCTAssertEqual(customStyle.usageCount, 0)
        customStyle.usageCount += 1
        XCTAssertEqual(customStyle.usageCount, 1)
    }
    
    // MARK: - Style Transfer Stats Tests
    
    func testStyleTransferStatsDefault() {
        let stats = StyleTransferStats()
        
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.favoriteCount, 0)
        XCTAssertTrue(stats.byStyleType.isEmpty)
        XCTAssertEqual(stats.averageProcessingTime, 0, accuracy: 0.01)
        XCTAssertNil(stats.mostUsedStyle)
        XCTAssertTrue(stats.recentTransfers.isEmpty)
    }
    
    func testStyleTransferStatsWithData() async throws {
        // 创建测试数据
        let dreamId = UUID()
        let transfer1 = DreamArtStyleTransfer(
            dreamId: dreamId,
            originalImageId: "1",
            styleType: "post_impressionist",
            styleIntensity: 0.8,
            resultImageId: "r1",
            processingTime: 2.0
        )
        transfer1.isFavorite = true
        
        let transfer2 = DreamArtStyleTransfer(
            dreamId: dreamId,
            originalImageId: "2",
            styleType: "post_impressionist",
            styleIntensity: 0.7,
            resultImageId: "r2",
            processingTime: 3.0
        )
        
        let transfer3 = DreamArtStyleTransfer(
            dreamId: dreamId,
            originalImageId: "3",
            styleType: "impressionist",
            styleIntensity: 0.6,
            resultImageId: "r3",
            processingTime: 2.5
        )
        
        modelContext.insert(transfer1)
        modelContext.insert(transfer2)
        modelContext.insert(transfer3)
        try modelContext.save()
        
        // 获取统计
        let stats = try await service.getStatistics()
        
        XCTAssertEqual(stats.totalCount, 3)
        XCTAssertEqual(stats.favoriteCount, 1)
        XCTAssertEqual(stats.byStyleType["post_impressionist"], 2)
        XCTAssertEqual(stats.byStyleType["impressionist"], 1)
        XCTAssertEqual(stats.averageProcessingTime, 2.5, accuracy: 0.01)
        XCTAssertEqual(stats.mostUsedStyle, .postImpressionist)
        XCTAssertEqual(stats.recentTransfers.count, 3)
    }
    
    // MARK: - Service CRUD Tests
    
    func testSaveStyleTransfer() async throws {
        let dreamId = UUID()
        let transfer = try await service.saveStyleTransfer(
            dreamId: dreamId,
            originalImageId: "test_original",
            styleType: "cyberpunk",
            styleIntensity: 0.75,
            resultImageId: "test_result",
            processingTime: 1.5
        )
        
        XCTAssertNotNil(transfer.id)
        XCTAssertEqual(transfer.dreamId, dreamId)
        XCTAssertEqual(transfer.styleType, "cyberpunk")
        XCTAssertEqual(transfer.styleIntensity, 0.75, accuracy: 0.01)
        XCTAssertEqual(transfer.processingTime, 1.5, accuracy: 0.01)
        XCTAssertFalse(transfer.isFavorite)
    }
    
    func testGetStyleTransfers() async throws {
        // 创建测试数据
        let dreamId = UUID()
        for i in 0..<5 {
            _ = try await service.saveStyleTransfer(
                dreamId: dreamId,
                originalImageId: "original_\(i)",
                styleType: "dreamy",
                styleIntensity: 0.5,
                resultImageId: "result_\(i)",
                processingTime: Double(i)
            )
        }
        
        // 获取迁移记录
        let transfers = try await service.getStyleTransfers(dreamId: dreamId, limit: 10)
        
        XCTAssertEqual(transfers.count, 5)
    }
    
    func testGetStyleTransfersWithLimit() async throws {
        // 创建测试数据
        let dreamId = UUID()
        for i in 0..<20 {
            _ = try await service.saveStyleTransfer(
                dreamId: dreamId,
                originalImageId: "original_\(i)",
                styleType: "sketch",
                styleIntensity: 0.6,
                resultImageId: "result_\(i)",
                processingTime: 1.0
            )
        }
        
        // 限制获取数量
        let transfers = try await service.getStyleTransfers(dreamId: dreamId, limit: 10)
        
        XCTAssertEqual(transfers.count, 10)
    }
    
    func testToggleFavorite() async throws {
        let transfer = try await service.saveStyleTransfer(
            dreamId: UUID(),
            originalImageId: "test",
            styleType: "pop_art",
            styleIntensity: 0.8,
            resultImageId: "test_result",
            processingTime: 2.0
        )
        
        XCTAssertFalse(transfer.isFavorite)
        
        try await service.toggleFavorite(id: transfer.id)
        
        let updated = try await service.getStyleTransfers(limit: 1)
        XCTAssertTrue(updated.first?.isFavorite ?? false)
    }
    
    func testDeleteStyleTransfer() async throws {
        let transfer = try await service.saveStyleTransfer(
            dreamId: UUID(),
            originalImageId: "test",
            styleType: "watercolor",
            styleIntensity: 0.7,
            resultImageId: "test_result",
            processingTime: 1.5
        )
        
        var transfers = try await service.getStyleTransfers(limit: 10)
        XCTAssertEqual(transfers.count, 1)
        
        try await service.deleteStyleTransfer(id: transfer.id)
        
        transfers = try await service.getStyleTransfers(limit: 10)
        XCTAssertEqual(transfers.count, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testStyleTransferErrorMessages() {
        XCTAssertEqual(StyleTransferError.invalidImage.errorDescription, "无效的图像数据")
        XCTAssertEqual(StyleTransferError.processingFailed.errorDescription, "风格迁移处理失败")
        XCTAssertEqual(StyleTransferError.notFound.errorDescription, "未找到风格迁移记录")
        XCTAssertEqual(StyleTransferError.cacheError.errorDescription, "缓存操作失败")
    }
    
    // MARK: - Performance Tests
    
    func testSaveMultipleTransfersPerformance() async throws {
        measure {
            let expectation = expectation(description: "Save transfers")
            
            Task {
                for i in 0..<50 {
                    _ = try await service.saveStyleTransfer(
                        dreamId: UUID(),
                        originalImageId: "perf_\(i)",
                        styleType: "oil_painting",
                        styleIntensity: 0.6,
                        resultImageId: "result_\(i)",
                        processingTime: 1.0
                    )
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testZeroIntensity() async throws {
        let transfer = try await service.saveStyleTransfer(
            dreamId: UUID(),
            originalImageId: "test",
            styleType: "abstract_expressionist",
            styleIntensity: 0.0,
            resultImageId: "test_result",
            processingTime: 1.0
        )
        
        XCTAssertEqual(transfer.styleIntensity, 0.0, accuracy: 0.01)
    }
    
    func testMaximumIntensity() async throws {
        let transfer = try await service.saveStyleTransfer(
            dreamId: UUID(),
            originalImageId: "test",
            styleType: "pixel_art",
            styleIntensity: 1.0,
            resultImageId: "test_result",
            processingTime: 1.0
        )
        
        XCTAssertEqual(transfer.styleIntensity, 1.0, accuracy: 0.01)
    }
    
    func testEmptyStats() async throws {
        let stats = try await service.getStatistics()
        
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.favoriteCount, 0)
        XCTAssertTrue(stats.byStyleType.isEmpty)
        XCTAssertNil(stats.mostUsedStyle)
    }
    
    // MARK: - Cache Management Tests
    
    func testClearCache() async {
        await service.clearCache()
        // 缓存清理不抛出异常即为成功
    }
}
