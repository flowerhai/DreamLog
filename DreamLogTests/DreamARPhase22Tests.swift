//
//  DreamARPhase22Tests.swift
//  DreamLogTests
//
//  Phase 22 - AR 增强功能单元测试
//  创建时间：2026-03-12
//

import XCTest
@testable import DreamLog

final class DreamARPhase22Tests: XCTestCase {
    
    // MARK: - 3D 元素模型测试
    
    func testDreamARElement3D_Creation() {
        let element = DreamARElement3D(
            name: "test_element",
            elementType: .nature,
            category: .nature,
            scale: 1.5
        )
        
        XCTAssertEqual(element.name, "test_element")
        XCTAssertEqual(element.elementType, .nature)
        XCTAssertEqual(element.category, .nature)
        XCTAssertEqual(element.scale, 1.5)
        XCTAssertEqual(element.position, SIMD3<Float>(0, 0, 0))
        XCTAssertEqual(element.rotation, SIMD4<Float>(0, 0, 0, 1))
        XCTAssertTrue(element.isInteractive)
        XCTAssertFalse(element.isFavorite)
    }
    
    func testDreamARElement3D_Conversion() {
        let arElement = ARElement(
            id: UUID(),
            type: .water,
            name: "water_element",
            position: .zero,
            animation: .float,
            color: .blue
        )
        
        let element3D = DreamARElement3D(from: arElement)
        
        XCTAssertEqual(element3D.id, arElement.id)
        XCTAssertEqual(element3D.name, arElement.name)
        XCTAssertEqual(element3D.elementType, arElement.type)
        XCTAssertEqual(element3D.animation, .float)
        
        // 转换回 ARElement
        let convertedBack = element3D.toARElement()
        XCTAssertEqual(convertedBack.id, arElement.id)
        XCTAssertEqual(convertedBack.type, arElement.type)
    }
    
    func testModelCategory_AllCases() {
        let categories: [ModelCategory] = [.nature, .animal, .person, .building, .abstract, .dreamSymbol]
        
        for category in categories {
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
            XCTAssertEqual(category.id, category.rawValue)
        }
    }
    
    func testModelCategory_FromARElementType() {
        XCTAssertEqual(ModelCategory(from: .water), .nature)
        XCTAssertEqual(ModelCategory(from: .animal), .animal)
        XCTAssertEqual(ModelCategory(from: .person), .person)
        XCTAssertEqual(ModelCategory(from: .building), .building)
        XCTAssertEqual(ModelCategory(from: .light), .abstract)
        XCTAssertEqual(ModelCategory(from: .fire), .dreamSymbol)
    }
    
    // MARK: - 材质配置测试
    
    func testMaterialConfig_Default() {
        let material = MaterialConfig.default
        
        XCTAssertEqual(material.metallic, 0.0)
        XCTAssertEqual(material.roughness, 0.5)
        XCTAssertEqual(material.opacity, 1.0)
        XCTAssertEqual(material.emissiveIntensity, 0.0)
    }
    
    func testMaterialConfig_Presets() {
        let metal = MaterialConfig.metal
        XCTAssertGreaterThan(metal.metallic, 0.5)
        XCTAssertLessThan(metal.roughness, 0.5)
        
        let glass = MaterialConfig.glass
        XCTAssertLessThan(glass.opacity, 0.5)
        
        let emissive = MaterialConfig.emissive
        XCTAssertGreaterThan(emissive.emissiveIntensity, 0.5)
    }
    
    // MARK: - 下载状态测试
    
    func testDownloadStatus() {
        let notDownloaded = DownloadStatus.notDownloaded
        XCTAssertFalse(notDownloaded.isDownloaded)
        XCTAssertFalse(notDownloaded.isDownloading)
        XCTAssertEqual(notDownloaded.progress, 0.0)
        
        let downloading = DownloadStatus.downloading(progress: 0.5)
        XCTAssertFalse(downloading.isDownloaded)
        XCTAssertTrue(downloading.isDownloading)
        XCTAssertEqual(downloading.progress, 0.5)
        
        let downloaded = DownloadStatus.downloaded
        XCTAssertTrue(downloaded.isDownloaded)
        XCTAssertFalse(downloaded.isDownloading)
        XCTAssertEqual(downloaded.progress, 1.0)
    }
    
    // MARK: - AR 模板测试
    
    func testDreamARTemplate_Creation() {
        let template = DreamARTemplate(
            name: "test_template",
            description: "Test description",
            category: .starrySky,
            elements: [],
            difficulty: .easy,
            estimatedTime: 30
        )
        
        XCTAssertEqual(template.name, "test_template")
        XCTAssertEqual(template.category, .starrySky)
        XCTAssertEqual(template.difficulty, .easy)
        XCTAssertEqual(template.estimatedTime, 30)
        XCTAssertFalse(template.isPremium)
        XCTAssertEqual(template.rating, 0.0)
    }
    
    func testTemplateCategory_AllCases() {
        let categories: [TemplateCategory] = [
            .starrySky, .oceanWorld, .forestSecret,
            .magicSpace, .fairytaleCastle, .abstractArt
        ]
        
        for category in categories {
            XCTAssertFalse(category.icon.isEmpty)
            XCTAssertFalse(category.description.isEmpty)
        }
    }
    
    func testTemplateDifficulty() {
        XCTAssertEqual(TemplateDifficulty.easy.icon, "hare.fill")
        XCTAssertEqual(TemplateDifficulty.medium.icon, "tortoise.fill")
        XCTAssertEqual(TemplateDifficulty.hard.icon, "flame.fill")
        
        XCTAssertEqual(TemplateDifficulty.easy.elementCount, "5-10 个元素")
        XCTAssertEqual(TemplateDifficulty.hard.elementCount, "20+ 个元素")
    }
    
    // MARK: - AR 分享会话测试
    
    func testDreamARShareSession_Creation() {
        let session = DreamARShareSession(
            sceneID: UUID(),
            sceneName: "Test Scene",
            hostUserID: "user123",
            shareCode: "ABC123"
        )
        
        XCTAssertEqual(session.sceneName, "Test Scene")
        XCTAssertEqual(session.hostUserID, "user123")
        XCTAssertEqual(session.shareCode, "ABC123")
        XCTAssertEqual(session.maxParticipants, 10)
        XCTAssertTrue(session.isActive)
        XCTAssertFalse(session.isExpired)
    }
    
    func testShareCodeGeneration() {
        let code1 = DreamARShareSession.generateShareCode()
        let code2 = DreamARShareSession.generateShareCode()
        
        XCTAssertEqual(code1.count, 6)
        XCTAssertNotEqual(code1, code2) // 应该是唯一的
        
        // 只包含大写字母和数字（不含易混淆字符）
        let validChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        for char in code1 {
            XCTAssertTrue(validChars.contains(String(char)))
        }
    }
    
    func testShareSessionExpiration() {
        let expiredSession = DreamARShareSession(
            sceneID: UUID(),
            sceneName: "Test",
            hostUserID: "user1",
            shareCode: "TEST1",
            expireAt: Date().addingTimeInterval(-100) // 100 秒前过期
        )
        
        let activeSession = DreamARShareSession(
            sceneID: UUID(),
            sceneName: "Test",
            hostUserID: "user1",
            shareCode: "TEST2",
            expireAt: Date().addingTimeInterval(3600) // 1 小时后过期
        )
        
        XCTAssertTrue(expiredSession.isExpired)
        XCTAssertFalse(activeSession.isExpired)
    }
    
    // MARK: - 参与者测试
    
    func testARParticipant_Creation() {
        let participant = ARParticipant(
            userID: "user123",
            username: "TestUser",
            role: .editor
        )
        
        XCTAssertEqual(participant.userID, "user123")
        XCTAssertEqual(participant.username, "TestUser")
        XCTAssertEqual(participant.role, .editor)
        XCTAssertTrue(participant.isOnline)
    }
    
    // MARK: - 分享权限测试
    
    func testSharePermissions() {
        let viewer = SharePermissions.viewer
        XCTAssertTrue(viewer.canView)
        XCTAssertFalse(viewer.canEdit)
        XCTAssertFalse(viewer.canAddElements)
        XCTAssertTrue(viewer.canChat)
        
        let editor = SharePermissions.editor
        XCTAssertTrue(editor.canView)
        XCTAssertTrue(editor.canEdit)
        XCTAssertTrue(editor.canAddElements)
        XCTAssertTrue(editor.canChat)
        XCTAssertTrue(editor.canInvite)
    }
    
    // MARK: - 交互模式测试
    
    func testInteractionMode() {
        let modes: [InteractionMode] = [.view, .transform, .move, .rotate, .scale]
        
        for mode in modes {
            XCTAssertFalse(mode.icon.isEmpty)
            XCTAssertFalse(mode.description.isEmpty)
        }
    }
    
    // MARK: - 交互服务测试
    
    func testARInteractionService_Singleton() {
        let service1 = DreamARInteractionService.shared
        let service2 = DreamARInteractionService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testARInteractionService_ElementSelection() async {
        let service = DreamARInteractionService.shared
        let element = DreamARElement3D(
            name: "test",
            elementType: .nature,
            category: .nature
        )
        
        // 初始状态
        XCTAssertNil(service.selectedElement)
        XCTAssertNil(service.selectedElementID)
        
        // 选择元素
        service.selectElement(element)
        
        XCTAssertEqual(service.selectedElement?.id, element.id)
        XCTAssertEqual(service.selectedElementID, element.id)
        
        // 取消选择
        service.deselectElement()
        
        XCTAssertNil(service.selectedElement)
        XCTAssertNil(service.selectedElementID)
    }
    
    func testARInteractionService_EditMode() async {
        let service = DreamARInteractionService.shared
        
        XCTAssertFalse(service.isEditMode)
        XCTAssertEqual(service.interactionMode, .view)
        
        // 切换编辑模式
        service.toggleEditMode()
        
        XCTAssertTrue(service.isEditMode)
        XCTAssertEqual(service.interactionMode, .transform)
        
        // 再次切换
        service.toggleEditMode()
        
        XCTAssertFalse(service.isEditMode)
        XCTAssertEqual(service.interactionMode, .view)
    }
    
    func testARInteractionService_AddRemoveElement() async {
        let service = DreamARInteractionService.shared
        let initialCount = service.sceneElements.count
        
        // 添加元素
        let element = DreamARElement3D(
            name: "test",
            elementType: .nature,
            category: .nature
        )
        service.addElement(element)
        
        XCTAssertEqual(service.sceneElements.count, initialCount + 1)
        XCTAssertNotNil(service.selectedElement)
        
        // 删除元素
        service.deleteSelectedElement()
        
        XCTAssertEqual(service.sceneElements.count, initialCount)
        XCTAssertNil(service.selectedElement)
    }
    
    func testARInteractionService_ClearScene() async {
        let service = DreamARInteractionService.shared
        
        // 添加多个元素
        for i in 0..<5 {
            let element = DreamARElement3D(
                name: "test_\(i)",
                elementType: .nature,
                category: .nature
            )
            service.addElement(element)
        }
        
        XCTAssertGreaterThan(service.sceneElements.count, 0)
        
        // 清空场景
        service.clearScene()
        
        XCTAssertEqual(service.sceneElements.count, 0)
        XCTAssertNil(service.selectedElement)
    }
    
    // MARK: - 模板服务测试
    
    func testARTemplateService_Singleton() {
        let service1 = DreamARTemplateService.shared
        let service2 = DreamARTemplateService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testARTemplateService_LoadTemplates() async {
        let service = DreamARTemplateService.shared
        
        // 等待模板加载
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 秒
        
        XCTAssertGreaterThan(service.availableTemplates.count, 0)
        
        // 验证模板类别
        let categories = Set(service.availableTemplates.map { $0.category })
        XCTAssertGreaterThanOrEqual(categories.count, 3) // 至少应该有 3 种不同类别
    }
    
    func testARTemplateService_FilterByCategory() async {
        let service = DreamARTemplateService.shared
        
        // 等待模板加载
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // 筛选星空类别
        service.selectedCategory = .starrySky
        let starryTemplates = service.filteredTemplates
        
        for template in starryTemplates {
            XCTAssertEqual(template.category, .starrySky)
        }
        
        // 重置筛选
        service.selectedCategory = nil
    }
    
    func testARTemplateService_Favorite() async {
        let service = DreamARTemplateService.shared
        
        // 等待模板加载
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        guard let template = service.availableTemplates.first else {
            XCTFail("No templates available")
            return
        }
        
        let initialFavoriteCount = service.favoriteTemplates.count
        
        // 收藏模板
        service.toggleFavorite(template)
        
        XCTAssertEqual(service.favoriteTemplates.count, initialFavoriteCount + 1)
        XCTAssertTrue(service.favoriteTemplates.contains { $0.id == template.id })
        
        // 取消收藏
        service.toggleFavorite(template)
        
        XCTAssertEqual(service.favoriteTemplates.count, initialFavoriteCount)
    }
    
    // MARK: - 性能测试
    
    func testPerformance_ElementCreation() {
        measure {
            for _ in 0..<100 {
                _ = DreamARElement3D(
                    name: "test_element",
                    elementType: .nature,
                    category: .nature,
                    scale: 1.0
                )
            }
        }
    }
    
    func testPerformance_TemplateFiltering() async {
        let service = DreamARTemplateService.shared
        
        // 等待模板加载
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        measure {
            _ = service.filteredTemplates
        }
    }
}
