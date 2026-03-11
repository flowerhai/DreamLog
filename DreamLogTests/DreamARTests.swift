//
//  DreamARTests.swift
//  DreamLogTests - Phase 21: Dream AR Visualization
//
//  Created by DreamLog Team on 2026-03-12
//  Copyright © 2026 DreamLog. All rights reserved.
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamARTests: XCTestCase {
    
    var arService: DreamARService!
    var dreamStore: DreamStore!
    
    override func setUp() async throws {
        try await super.setUp()
        dreamStore = DreamStore.shared
        arService = DreamARService(dreamStore: dreamStore)
    }
    
    override func tearDown() async throws {
        arService = nil
        dreamStore = nil
        try await super.tearDown()
    }
    
    // MARK: - AR Element Type Tests
    
    func testARDreamElementTypeDisplayNames() {
        // 测试所有元素类型的显示名称
        let types: [(ARDreamElementType, String)] = [
            (.water, "💧 水元素"),
            (.fire, "🔥 火元素"),
            (.wind, "💨 风元素"),
            (.earth, "🪨 土元素"),
            (.light, "✨ 光元素"),
            (.dark, "🌑 暗元素"),
            (.nature, "🌿 自然元素"),
            (.animal, "🦋 动物元素"),
            (.human, "👤 人物元素"),
            (.building, "🏛️ 建筑元素"),
            (.vehicle, "🚗 交通元素"),
            (.abstract, "🌀 抽象元素")
        ]
        
        for (type, expectedName) in types {
            XCTAssertEqual(type.displayName, expectedName, "Display name mismatch for \(type)")
        }
    }
    
    func testARDreamElementTypeColors() {
        // 测试元素类型颜色映射
        XCTAssertEqual(ARDreamElementType.water.color, .blue)
        XCTAssertEqual(ARDreamElementType.fire.color, .red)
        XCTAssertEqual(ARDreamElementType.nature.color, .green)
        XCTAssertEqual(ARDreamElementType.light.color, .yellow)
        XCTAssertEqual(ARDreamElementType.dark.color, .purple)
    }
    
    // MARK: - AR Scene Tests
    
    func testARDreamSceneCreation() {
        let dreamId = UUID()
        let scene = ARDreamScene(dreamId: dreamId, dreamTitle: "测试梦境")
        
        XCTAssertEqual(scene.dreamId, dreamId)
        XCTAssertEqual(scene.sceneName, "测试梦境")
        XCTAssertEqual(scene.elements.count, 0)
        XCTAssertEqual(scene.environment, .default)
        XCTAssertEqual(scene.lighting, .natural)
        XCTAssertNotNil(scene.id)
        XCTAssertNotNil(scene.createdAt)
    }
    
    func testARDreamSceneWithElements() {
        let dreamId = UUID()
        var elements: [ARDreamElement] = []
        elements.append(ARDreamElement(type: .water, name: "水", description: "水元素"))
        elements.append(ARDreamElement(type: .fire, name: "火", description: "火元素"))
        
        var scene = ARDreamScene(dreamId: dreamId, dreamTitle: "水火之梦", elements: elements)
        
        XCTAssertEqual(scene.elements.count, 2)
        XCTAssertEqual(scene.elements[0].type, .water)
        XCTAssertEqual(scene.elements[1].type, .fire)
    }
    
    // MARK: - AR Element Tests
    
    func testARDreamElementCreation() {
        let element = ARDreamElement(type: .water, name: "海洋", description: "广阔的海洋")
        
        XCTAssertEqual(element.type, .water)
        XCTAssertEqual(element.name, "海洋")
        XCTAssertEqual(element.description, "广阔的海洋")
        XCTAssertEqual(element.position, SIMD3<Float>(0, 0, 0))
        XCTAssertEqual(element.scale, SIMD3<Float>(1, 1, 1))
        XCTAssertEqual(element.intensity, 0.8)
        XCTAssertNil(element.animation)
    }
    
    func testARDreamElementPosition() {
        var element = ARDreamElement(type: .nature, name: "树", description: "大树")
        
        element.position = SIMD3<Float>(1.0, 0.5, -2.0)
        element.scale = SIMD3<Float>(2.0, 2.0, 2.0)
        
        XCTAssertEqual(element.position.x, 1.0)
        XCTAssertEqual(element.position.y, 0.5)
        XCTAssertEqual(element.position.z, -2.0)
        XCTAssertEqual(element.scale.x, 2.0)
    }
    
    // MARK: - Environment Type Tests
    
    func testAREnvironmentTypeDisplayNames() {
        XCTAssertEqual(AREnvironmentType.default.displayName, "默认")
        XCTAssertEqual(AREnvironmentType.sky.displayName, "天空")
        XCTAssertEqual(AREnvironmentType.ocean.displayName, "海洋")
        XCTAssertEqual(AREnvironmentType.forest.displayName, "森林")
        XCTAssertEqual(AREnvironmentType.space.displayName, "太空")
        XCTAssertEqual(AREnvironmentType.abstract.displayName, "抽象")
    }
    
    // MARK: - Lighting Preset Tests
    
    func testARLightingPresetDisplayNames() {
        XCTAssertEqual(ARLightingPreset.natural.displayName, "自然光")
        XCTAssertEqual(ARLightingPreset.dramatic.displayName, "戏剧光")
        XCTAssertEqual(ARLightingPreset.soft.displayName, "柔光")
        XCTAssertEqual(ARLightingPreset.colorful.displayName, "彩色光")
        XCTAssertEqual(ARLightingPreset.dark.displayName, "暗光")
        XCTAssertEqual(ARLightingPreset.dreamy.displayName, "梦幻光")
    }
    
    // MARK: - Animation Type Tests
    
    func testARAnimationTypeDisplayNames() {
        XCTAssertEqual(ARAnimationType.none.displayName, "无动画")
        XCTAssertEqual(ARAnimationType.float.displayName, "漂浮")
        XCTAssertEqual(ARAnimationType.pulse.displayName, "脉冲")
        XCTAssertEqual(ARAnimationType.rotate.displayName, "旋转")
        XCTAssertEqual(ARAnimationType.sparkle.displayName, "闪烁")
        XCTAssertEqual(ARAnimationType.wave.displayName, "波动")
        XCTAssertEqual(ARAnimationType.grow.displayName, "生长")
        XCTAssertEqual(ARAnimationType.fade.displayName, "淡入淡出")
        XCTAssertEqual(ARAnimationType.orbit.displayName, "轨道")
    }
    
    // MARK: - Recording Config Tests
    
    func testARRecordingConfigDefault() {
        let config = ARRecordingConfig()
        
        XCTAssertEqual(config.duration, 30)
        XCTAssertEqual(config.includeAudio, true)
        XCTAssertEqual(config.quality, .high)
        XCTAssertEqual(config.resolution, .hd1080p)
    }
    
    func testARRecordingConfigCustom() {
        let config = ARRecordingConfig(
            duration: 60,
            includeAudio: false,
            quality: .ultra,
            resolution: .hevc4k
        )
        
        XCTAssertEqual(config.duration, 60)
        XCTAssertEqual(config.includeAudio, false)
        XCTAssertEqual(config.quality, .ultra)
        XCTAssertEqual(config.resolution, .hevc4k)
    }
    
    // MARK: - AR Share Tests
    
    func testARDreamShareCreation() {
        let sceneId = UUID()
        let dreamId = UUID()
        let share = ARDreamShare(sceneId: sceneId, dreamId: dreamId)
        
        XCTAssertEqual(share.sceneId, sceneId)
        XCTAssertEqual(share.dreamId, dreamId)
        XCTAssertEqual(share.viewCount, 0)
        XCTAssertEqual(share.likeCount, 0)
        XCTAssertNil(share.shareURL)
        XCTAssertNotNil(share.id)
    }
    
    // MARK: - Session State Tests
    
    func testARSessionStateDescriptions() {
        XCTAssertEqual(ARSessionState.idle.description, "空闲")
        XCTAssertEqual(ARSessionState.preparing.description, "准备中...")
        XCTAssertEqual(ARSessionState.running.description, "运行中")
        XCTAssertEqual(ARSessionState.recording.description, "录制中")
        XCTAssertEqual(ARSessionState.paused.description, "已暂停")
        
        let errorState = ARSessionState.error("测试错误")
        XCTAssertEqual(errorState.description, "错误：测试错误")
    }
    
    func testARSessionStateEquatable() {
        XCTAssertEqual(ARSessionState.idle, ARSessionState.idle)
        XCTAssertEqual(ARSessionState.running, ARSessionState.running)
        XCTAssertNotEqual(ARSessionState.idle, ARSessionState.running)
        
        XCTAssertEqual(ARSessionState.error("test"), ARSessionState.error("test"))
        XCTAssertNotEqual(ARSessionState.error("test1"), ARSessionState.error("test2"))
    }
    
    // MARK: - AR Error Tests
    
    func testARErrorDescriptions() {
        XCTAssertEqual(ARError.noActiveScene.errorDescription, "没有活跃的场景")
        XCTAssertEqual(ARError.arNotSupported.errorDescription, "设备不支持 AR")
        XCTAssertEqual(ARError.cameraPermissionDenied.errorDescription, "相机权限被拒绝")
        XCTAssertEqual(ARError.recordingFailed.errorDescription, "录制失败")
        XCTAssertEqual(ARError.sharingFailed.errorDescription, "分享失败")
    }
    
    // MARK: - Tag to Element Conversion Tests
    
    func testTagToARElementWater() {
        let waterTags = ["水", "water", "海", "ocean", "河", "rain"]
        
        for tag in waterTags {
            let element = arService.tagToARElement(tag: tag)
            XCTAssertEqual(element?.type, .water, "Tag '\(tag)' should map to water element")
        }
    }
    
    func testTagToARElementFire() {
        let fireTags = ["火", "fire", "火焰", "flame", "燃烧"]
        
        for tag in fireTags {
            let element = arService.tagToARElement(tag: tag)
            XCTAssertEqual(element?.type, .fire, "Tag '\(tag)' should map to fire element")
        }
    }
    
    func testTagToARElementNature() {
        let natureTags = ["树", "tree", "森林", "forest", "花", "自然", "nature"]
        
        for tag in natureTags {
            let element = arService.tagToARElement(tag: tag)
            XCTAssertEqual(element?.type, .nature, "Tag '\(tag)' should map to nature element")
        }
    }
    
    func testTagToARElementInvalid() {
        let invalidTags = ["随机标签", "unknown", "xyz"]
        
        for tag in invalidTags {
            let element = arService.tagToARElement(tag: tag)
            XCTAssertNil(element, "Tag '\(tag)' should not map to any element")
        }
    }
    
    // MARK: - Emotion to Element Conversion Tests
    
    func testEmotionToARElement() {
        let emotions: [(Emotion, ARDreamElementType)] = [
            (.平静, .light),
            (.快乐, .light),
            (.焦虑, .wind),
            (.恐惧, .dark),
            (.困惑, .abstract),
            (.兴奋, .fire),
            (.悲伤, .water),
            (.愤怒, .fire),
            (.惊讶, .light),
            (.中性, .abstract)
        ]
        
        for (emotion, expectedType) in emotions {
            let element = arService.emotionToARElement(emotion: emotion)
            XCTAssertEqual(element.type, expectedType, "Emotion \(emotion) should map to \(expectedType)")
        }
    }
    
    // MARK: - Keyword Extraction Tests
    
    func testKeywordExtraction() {
        let content = "我梦见在水中飞行，追逐着一只动物，周围是森林和房子"
        let keywords = arService.extractKeywords(from: content)
        
        XCTAssertTrue(keywords.contains("飞行"), "Should extract '飞行'")
        XCTAssertTrue(keywords.contains("水"), "Should extract '水'")
        XCTAssertTrue(keywords.contains("追逐"), "Should extract '追逐'")
        XCTAssertTrue(keywords.contains("动物"), "Should extract '动物'")
    }
    
    // MARK: - Environment Determination Tests
    
    func testEnvironmentDeterminationWater() async {
        let dream = Dream(
            title: "海洋之梦",
            content: "我在海洋中游泳",
            tags: ["水", "海洋", "游泳"],
            emotions: [.平静],
            clarity: 4,
            intensity: 3,
            isLucid: false
        )
        
        let environment = arService.determineEnvironment(from: dream)
        XCTAssertEqual(environment, .ocean, "Water dream should have ocean environment")
    }
    
    func testEnvironmentDeterminationNature() async {
        let dream = Dream(
            title: "森林之梦",
            content: "我在森林中漫步",
            tags: ["树", "森林", "自然"],
            emotions: [.平静],
            clarity: 4,
            intensity: 3,
            isLucid: false
        )
        
        let environment = arService.determineEnvironment(from: dream)
        XCTAssertEqual(environment, .forest, "Nature dream should have forest environment")
    }
    
    func testEnvironmentDeterminationDark() async {
        let dream = Dream(
            title: "恐惧之梦",
            content: "我很害怕",
            tags: ["黑暗"],
            emotions: [.恐惧, .焦虑],
            clarity: 2,
            intensity: 5,
            isLucid: false
        )
        
        let environment = arService.determineEnvironment(from: dream)
        XCTAssertEqual(environment, .space, "Dark dream should have space environment")
    }
    
    // MARK: - Lighting Determination Tests
    
    func testLightingDeterminationHighClarity() {
        let dream = Dream(
            title: "清晰的梦",
            content: "非常清晰的梦境",
            tags: [],
            emotions: [.平静],
            clarity: 5,
            intensity: 3,
            isLucid: false
        )
        
        let lighting = arService.determineLighting(from: dream)
        XCTAssertEqual(lighting, .natural, "High clarity should have natural lighting")
    }
    
    func testLightingDeterminationLowClarity() {
        let dream = Dream(
            title: "模糊的梦",
            content: "模糊的梦境",
            tags: [],
            emotions: [.困惑],
            clarity: 1,
            intensity: 2,
            isLucid: false
        )
        
        let lighting = arService.determineLighting(from: dream)
        XCTAssertEqual(lighting, .dark, "Low clarity should have dark lighting")
    }
    
    func testLightingDeterminationLucid() {
        let dream = Dream(
            title: "清醒梦",
            content: "我知道我在做梦",
            tags: ["清醒梦"],
            emotions: [.兴奋],
            clarity: 5,
            intensity: 5,
            isLucid: true
        )
        
        let lighting = arService.determineLighting(from: dream)
        XCTAssertEqual(lighting, .dreamy, "Lucid dream should have dreamy lighting")
    }
    
    // MARK: - Element Distribution Tests
    
    func testElementDistributionInCircle() {
        var elements: [ARDreamElement] = [
            ARDreamElement(type: .water, name: "水", description: "水元素"),
            ARDreamElement(type: .fire, name: "火", description: "火元素"),
            ARDreamElement(type: .nature, name: "树", description: "树元素"),
            ARDreamElement(type: .light, name: "光", description: "光元素")
        ]
        
        arService.distributeElementsInCircle(&elements)
        
        // 验证所有元素都有位置
        for element in elements {
            XCTAssertNotEqual(element.position, SIMD3<Float>(0, 0, 0), "Element should have position")
            XCTAssertNotEqual(element.scale, SIMD3<Float>(1, 1, 1), "Element should have custom scale")
            XCTAssertNotNil(element.animation, "Element should have animation")
        }
        
        // 验证元素均匀分布 (检查角度)
        for i in 1..<elements.count {
            let prevAngle = atan2(elements[i-1].position.z, elements[i-1].position.x)
            let currAngle = atan2(elements[i].position.z, elements[i].position.x)
            // 角度应该有差异
            XCTAssertNotEqual(prevAngle, currAngle, "Elements should have different angles")
        }
    }
    
    // MARK: - Scene Persistence Tests
    
    func testSaveAndLoadScene() async throws {
        // 创建测试场景
        let dreamId = UUID()
        var elements: [ARDreamElement] = []
        elements.append(ARDreamElement(type: .water, name: "海洋", description: "广阔的海洋"))
        elements.append(ARDreamElement(type: .nature, name: "森林", description: "茂密的森林"))
        
        var scene = ARDreamScene(dreamId: dreamId, dreamTitle: "测试场景", elements: elements)
        scene.environment = .ocean
        scene.lighting = .dreamy
        
        // 保存场景
        try arService.saveScene(scene)
        
        // 验证文件存在
        let fileURL = arService.archiveDirectory.appendingPathComponent("\(scene.id.uuidString).json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "Scene file should exist")
        
        // 重新加载场景
        arService.loadSavedScenes()
        
        // 验证场景被加载
        let loadedScene = arService.availableScenes.first { $0.id == scene.id }
        XCTAssertNotNil(loadedScene, "Scene should be loaded")
        XCTAssertEqual(loadedScene?.sceneName, scene.sceneName)
        XCTAssertEqual(loadedScene?.elements.count, 2)
        
        // 清理
        try arService.deleteScene(scene)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path), "Scene file should be deleted")
    }
    
    // MARK: - AR Availability Tests
    
    func testARAvailabilityCheck() {
        // 测试 AR 可用性检查 (在模拟器中可能返回 false)
        let isAvailable = DreamARService.isARAvailable()
        // 不强制断言，因为取决于运行环境
        print("AR Available: \(isAvailable)")
    }
    
    // MARK: - Performance Tests
    
    func testSceneCreationPerformance() async throws {
        let dream = Dream(
            title: "性能测试梦境",
            content: "这是一个用于性能测试的梦境，包含多个元素和关键词",
            tags: ["水", "火", "树", "飞行", "动物", "房子"],
            emotions: [.平静, .快乐, .兴奋],
            clarity: 4,
            intensity: 4,
            isLucid: true
        )
        
        measure {
            let expectation = self.expectation(description: "Scene creation")
            
            Task {
                do {
                    _ = try await self.arService.createScene(from: dream)
                    expectation.fulfill()
                } catch {
                    XCTFail("Scene creation failed: \(error)")
                }
            }
            
            waitForExpectations(timeout: 5)
        }
    }
}
