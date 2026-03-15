//
//  DreamARVisualizationTests.swift
//  DreamLogTests
//
//  Created for Phase 48 - AR 梦境场景可视化
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 16.0, *)
final class DreamARVisualizationTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamARVisualizationService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建测试用的 ModelContainer
        let schema = Schema([
            ARDreamScene.self,
            ARDreamElement.self,
            ARDreamAnchor.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        modelContext = ModelContext(modelContainer)
        service = DreamARVisualizationService.shared
        service.configure(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        service = nil
        try await super.tearDown()
    }
    
    // MARK: - 场景创建测试
    
    func testCreateScene() async throws {
        let dreamID = UUID()
        let dreamContent = "我在星空下飞翔，感觉非常自由"
        let dreamSymbols = ["star", "flying", "night"]
        let dreamEmotions = ["平静", "自由"]
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: dreamContent,
            dreamSymbols: dreamSymbols,
            dreamEmotions: dreamEmotions
        )
        
        // 验证场景属性
        XCTAssertEqual(scene.dreamID, dreamID)
        XCTAssertTrue(scene.sceneName.contains("梦境 AR 场景"))
        XCTAssertFalse(scene.sceneDescription.isEmpty)
        XCTAssertFalse(scene.isFavorite)
        XCTAssertEqual(scene.viewCount, 0)
        
        // 验证元素已生成
        XCTAssertGreaterThan(scene.elements.count, 0)
        
        // 验证锚点已创建
        XCTAssertGreaterThan(scene.anchors.count, 0)
    }
    
    func testCreateSceneWithEmptySymbols() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "一个简单的梦",
            dreamSymbols: [],
            dreamEmotions: []
        )
        
        XCTAssertNotNil(scene)
        XCTAssertEqual(scene.dreamID, dreamID)
    }
    
    // MARK: - 场景查询测试
    
    func testGetScene() async throws {
        let dreamID = UUID()
        
        // 创建场景
        let createdScene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        // 查询场景
        let retrievedScene = try await service.getScene(for: dreamID)
        
        XCTAssertNotNil(retrievedScene)
        XCTAssertEqual(retrievedScene?.id, createdScene.id)
        XCTAssertEqual(retrievedScene?.dreamID, dreamID)
    }
    
    func testGetNonExistentScene() async throws {
        let dreamID = UUID()
        
        let scene = try await service.getScene(for: dreamID)
        
        XCTAssertNil(scene)
    }
    
    func testGetAllScenes() async throws {
        // 创建多个场景
        for i in 0..<3 {
            let dreamID = UUID()
            try await service.createScene(
                for: dreamID,
                dreamContent: "测试梦境 \(i)",
                dreamSymbols: ["star"],
                dreamEmotions: ["平静"]
            )
        }
        
        let scenes = try await service.getAllScenes()
        
        XCTAssertEqual(scenes.count, 3)
    }
    
    // MARK: - 场景管理测试
    
    func testDeleteScene() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        // 删除场景
        try await service.deleteScene(scene)
        
        // 验证已删除
        let retrievedScene = try await service.getScene(for: dreamID)
        XCTAssertNil(retrievedScene)
    }
    
    func testToggleFavorite() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        XCTAssertFalse(scene.isFavorite)
        
        // 切换收藏状态
        try await service.toggleFavorite(for: scene)
        XCTAssertTrue(scene.isFavorite)
        
        // 再次切换
        try await service.toggleFavorite(for: scene)
        XCTAssertFalse(scene.isFavorite)
    }
    
    func testRecordSceneView() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        XCTAssertEqual(scene.viewCount, 0)
        XCTAssertNil(scene.lastViewedAt)
        
        // 记录查看
        await service.recordSceneView(scene)
        
        XCTAssertEqual(scene.viewCount, 1)
        XCTAssertNotNil(scene.lastViewedAt)
    }
    
    // MARK: - 元素管理测试
    
    func testAddElement() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        let initialCount = scene.elements.count
        
        // 添加新元素
        let newElement = ARDreamElement(
            sceneID: scene.id,
            type: .symbol,
            name: "测试符号",
            content: "star",
            position: SIMD3<Float>(0, 0, 0)
        )
        
        try await service.addElement(to: scene, element: newElement)
        
        XCTAssertEqual(scene.elements.count, initialCount + 1)
    }
    
    func testDeleteElement() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        guard let element = scene.elements.first else {
            XCTFail("场景应该至少有一个元素")
            return
        }
        
        let initialCount = scene.elements.count
        
        // 删除元素
        try await service.deleteElement(element, from: scene)
        
        XCTAssertEqual(scene.elements.count, initialCount - 1)
    }
    
    func testUpdateElementPosition() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        guard let element = scene.elements.first else {
            XCTFail("场景应该至少有一个元素")
            return
        }
        
        let originalPosition = element.position
        let newPosition = SIMD3<Float>(1.0, 2.0, 3.0)
        
        // 更新位置
        try await service.updateElementPosition(element, to: newPosition)
        
        XCTAssertEqual(element.position, newPosition)
        XCTAssertNotEqual(element.position, originalPosition)
    }
    
    // MARK: - 锚点管理测试
    
    func testAddAnchor() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        let initialCount = scene.anchors.count
        
        // 添加新锚点
        let newAnchor = ARDreamAnchor(
            sceneID: scene.id,
            type: .plane,
            name: "测试锚点",
            anchorData: Data()
        )
        
        try await service.addAnchor(to: scene, anchor: newAnchor)
        
        XCTAssertEqual(scene.anchors.count, initialCount + 1)
    }
    
    func testDeleteAnchor() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        guard let anchor = scene.anchors.first else {
            XCTFail("场景应该至少有一个锚点")
            return
        }
        
        let initialCount = scene.anchors.count
        
        // 删除锚点
        try await service.deleteAnchor(anchor, from: scene)
        
        XCTAssertEqual(scene.anchors.count, initialCount - 1)
    }
    
    // MARK: - 梦境符号测试
    
    func testDreamSymbolCases() {
        let allSymbols = DreamSymbol.allCases
        
        // 验证符号数量
        XCTAssertGreaterThan(allSymbols.count, 30)
        
        // 验证每个符号都有 SF 符号
        for symbol in allSymbols {
            XCTAssertFalse(symbol.sfSymbol.isEmpty)
            XCTAssertFalse(symbol.displayName.isEmpty)
            XCTAssertFalse(symbol.defaultColor.isEmpty)
        }
    }
    
    func testDreamSymbolColor() {
        let waterSymbol = DreamSymbol.water
        XCTAssertEqual(waterSymbol.defaultColor, "#4A90E2")
        
        let fireSymbol = DreamSymbol.fire
        XCTAssertEqual(fireSymbol.defaultColor, "#E24A4A")
        
        let starSymbol = DreamSymbol.star
        XCTAssertEqual(starSymbol.defaultColor, "#FFD700")
    }
    
    // MARK: - AR 元素类型测试
    
    func testARElementTypeCases() {
        let allTypes = ARDreamElementType.allCases
        
        XCTAssertEqual(allTypes.count, 8)
        
        for type in allTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
    
    // MARK: - AR 锚点类型测试
    
    func testARAnchorTypeCases() {
        let allTypes = ARDreamAnchorType.allCases
        
        XCTAssertEqual(allTypes.count, 6)
        
        for type in allTypes {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
    
    // MARK: - 场景配置测试
    
    func testARSceneConfigurationDefault() {
        let config = ARSceneConfiguration.default
        
        XCTAssertTrue(config.enablePlaneDetection)
        XCTAssertTrue(config.enableLightEstimation)
        XCTAssertTrue(config.enableOcclusion)
        XCTAssertTrue(config.environmentTexturing)
        XCTAssertTrue(config.automaticLighting)
    }
    
    func testARSceneConfigurationMinimal() {
        let config = ARSceneConfiguration.minimal
        
        XCTAssertTrue(config.enablePlaneDetection)
        XCTAssertFalse(config.enableLightEstimation)
        XCTAssertFalse(config.enableOcclusion)
        XCTAssertFalse(config.environmentTexturing)
        XCTAssertFalse(config.automaticLighting)
    }
    
    // MARK: - 颜色扩展测试
    
    func testColorFromHex() {
        let color = Color(hex: "#FF6B6B")
        XCTAssertNotNil(color)
        
        let invalidColor = Color(hex: "invalid")
        XCTAssertNil(invalidColor)
    }
    
    // MARK: - 错误处理测试
    
    func testARErrorMessages() {
        let errors: [ARError] = [
            .modelContextNotConfigured,
            .sceneNotFound,
            .elementNotFound,
            .anchorNotFound,
            .arNotSupported,
            .cameraPermissionDenied,
            .sceneGenerationFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
        }
    }
    
    // MARK: - 性能测试
    
    func testSceneCreationPerformance() async throws {
        measure {
            let expectation = self.expectation(description: "Create scene")
            
            Task {
                let dreamID = UUID()
                _ = try? await self.service.createScene(
                    for: dreamID,
                    dreamContent: "性能测试梦境",
                    dreamSymbols: ["star", "flying", "night"],
                    dreamEmotions: ["平静"]
                )
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - 边界条件测试
    
    func testSceneWithMaxElements() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: Array(repeating: "star", count: 100),
            dreamEmotions: Array(repeating: "平静", count: 100)
        )
        
        // 验证元素数量被限制
        XCTAssertLessThanOrEqual(scene.elements.count, 10)
    }
    
    func testSceneIsValid() async throws {
        let dreamID = UUID()
        
        let scene = try await service.createScene(
            for: dreamID,
            dreamContent: "测试梦境",
            dreamSymbols: ["star"],
            dreamEmotions: ["平静"]
        )
        
        // 验证场景基本属性
        XCTAssertNotNil(scene.id)
        XCTAssertNotNil(scene.createdAt)
        XCTAssertEqual(scene.updatedAt, scene.createdAt)
    }
}

// MARK: - 测试辅助扩展

@available(iOS 16.0, *)
extension DreamARVisualizationTests {
    
    /// 创建测试用的梦境数据
    func createTestDream(
        content: String = "测试梦境内容",
        symbols: [String] = ["star"],
        emotions: [String] = ["平静"]
    ) -> (id: UUID, content: String, symbols: [String], emotions: [String]) {
        return (
            id: UUID(),
            content: content,
            symbols: symbols,
            emotions: emotions
        )
    }
}
