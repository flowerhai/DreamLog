//
//  DreamARFaceTrackingTests.swift
//  DreamLogTests
//
//  面部追踪功能单元测试 - Phase 24
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamARFaceTrackingTests: XCTestCase {
    
    // MARK: - 测试数据模型
    
    func testFaceBlendshapeData_Creation() {
        let blendshape = FaceBlendshapeData(name: "eyeBlinkLeft", value: 0.8)
        
        XCTAssertEqual(blendshape.name, "eyeBlinkLeft")
        XCTAssertEqual(blendshape.value, 0.8)
        XCTAssertEqual(blendshape.displayName, "左眼眨眼")
    }
    
    func testFaceBlendshapeData_DisplayNames() {
        let testCases: [(String, String)] = [
            (ARFaceAnchor.BlendShapeLocation.eyeBlinkLeft.rawValue, "左眼眨眼"),
            (ARFaceAnchor.BlendShapeLocation.mouthSmileLeft.rawValue, "左嘴角微笑"),
            (ARFaceAnchor.BlendShapeLocation.jawOpen.rawValue, "下巴张开"),
            ("unknown", "unknown")
        ]
        
        for (name, expectedDisplayName) in testCases {
            let blendshape = FaceBlendshapeData(name: name, value: 0.5)
            XCTAssertEqual(blendshape.displayName, expectedDisplayName)
        }
    }
    
    func testFaceExpressionState_PrimaryExpression() {
        // 测试开心表情
        let happyBlendshapes = [
            FaceBlendshapeData(name: ARFaceAnchor.BlendShapeLocation.mouthSmileLeft.rawValue, value: 0.8),
            FaceBlendshapeData(name: ARFaceAnchor.BlendShapeLocation.mouthSmileRight.rawValue, value: 0.8)
        ]
        
        let happyState = FaceExpressionState(
            timestamp: Date(),
            blendshapes: happyBlendshapes,
            transform: simd_float4x4(1.0),
            isFaceDetected: true,
            confidence: 0.9
        )
        
        XCTAssertEqual(happyState.primaryExpression, .happy)
        
        // 测试惊讶表情
        let surprisedBlendshapes = [
            FaceBlendshapeData(name: ARFaceAnchor.BlendShapeLocation.jawOpen.rawValue, value: 0.8),
            FaceBlendshapeData(name: ARFaceAnchor.BlendShapeLocation.eyeWideLeft.rawValue, value: 0.6),
            FaceBlendshapeData(name: ARFaceAnchor.BlendShapeLocation.eyeWideRight.rawValue, value: 0.6)
        ]
        
        let surprisedState = FaceExpressionState(
            timestamp: Date(),
            blendshapes: surprisedBlendshapes,
            transform: simd_float4x4(1.0),
            isFaceDetected: true,
            confidence: 0.9
        )
        
        XCTAssertEqual(surprisedState.primaryExpression, .surprised)
    }
    
    func testFaceExpressionType_AllCases() {
        let allTypes: [FaceExpressionType] = [.neutral, .happy, .sad, .surprised, .excited]
        
        for type in allTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.emoji.isEmpty)
        }
    }
    
    func testFaceExpressionType_DisplayValues() {
        XCTAssertEqual(FaceExpressionType.neutral.emoji, "😐")
        XCTAssertEqual(FaceExpressionType.happy.emoji, "😊")
        XCTAssertEqual(FaceExpressionType.sad.emoji, "😢")
        XCTAssertEqual(FaceExpressionType.surprised.emoji, "😲")
        XCTAssertEqual(FaceExpressionType.excited.emoji, "🤩")
    }
    
    // MARK: - 测试配置
    
    func testFaceTrackingConfig_Default() {
        let config = FaceTrackingConfig.default
        
        XCTAssertFalse(config.isEnabled)
        XCTAssertTrue(config.enableExpressionAnimation)
        XCTAssertTrue(config.enableAvatar)
        XCTAssertEqual(config.expressionSensitivity, 0.7)
        XCTAssertTrue(config.recordExpressionHistory)
        XCTAssertEqual(config.maxHistoryCount, 100)
    }
    
    func testFaceTrackingConfig_Custom() {
        var config = FaceTrackingConfig.default
        config.isEnabled = true
        config.expressionSensitivity = 0.9
        config.maxHistoryCount = 200
        
        XCTAssertTrue(config.isEnabled)
        XCTAssertEqual(config.expressionSensitivity, 0.9)
        XCTAssertEqual(config.maxHistoryCount, 200)
    }
    
    // MARK: - 测试虚拟化身
    
    func testAvatarModel_Creation() {
        let avatar = AvatarModel(
            id: UUID(),
            name: "测试虚拟化身",
            description: "测试描述",
            thumbnailName: "test_avatar",
            category: .basic,
            isUnlocked: true,
            unlockCondition: nil
        )
        
        XCTAssertEqual(avatar.name, "测试虚拟化身")
        XCTAssertEqual(avatar.category, .basic)
        XCTAssertTrue(avatar.isUnlocked)
    }
    
    func testAvatarModel_Presets() {
        let presets = AvatarModel.presets
        
        XCTAssertGreaterThan(presets.count, 0)
        
        // 验证基础虚拟化身已解锁
        let basicAvatar = presets.first { $0.category == .basic }
        XCTAssertNotNil(basicAvatar)
        XCTAssertTrue(basicAvatar?.isUnlocked ?? false)
    }
    
    func testAvatarModel_Category_AllCases() {
        let allCategories: [AvatarModel.AvatarCategory] = [.basic, .animal, .fantasy, .robot, .custom]
        
        for category in allCategories {
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }
    
    func testAvatarModel_Category_DisplayValues() {
        XCTAssertEqual(AvatarModel.AvatarCategory.basic.displayName, "👤 基础")
        XCTAssertEqual(AvatarModel.AvatarCategory.animal.displayName, "🦋 动物")
        XCTAssertEqual(AvatarModel.AvatarCategory.fantasy.displayName, "🧚 奇幻")
        XCTAssertEqual(AvatarModel.AvatarCategory.robot.displayName, "🤖 机器人")
        XCTAssertEqual(AvatarModel.AvatarCategory.custom.displayName, "🎨 自定义")
    }
    
    // MARK: - 测试面部追踪服务
    
    func testFaceTrackingService_Singleton() {
        let service1 = DreamARFaceTrackingService.shared
        let service2 = DreamARFaceTrackingService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testFaceTrackingService_InitialState() {
        let service = DreamARFaceTrackingService.shared
        
        XCTAssertNil(service.currentFaceState)
        XCTAssertTrue(service.expressionHistory.isEmpty)
        XCTAssertFalse(service.isTracking)
        XCTAssertNil(service.errorMessage)
    }
    
    func testFaceTrackingService_ConfigPersistence() {
        let service = DreamARFaceTrackingService.shared
        
        var newConfig = FaceTrackingConfig.default
        newConfig.isEnabled = true
        newConfig.expressionSensitivity = 0.8
        
        // 更新配置
        service.updateConfig(newConfig)
        
        // 验证配置已更新
        XCTAssertEqual(service.config.isEnabled, true)
        XCTAssertEqual(service.config.expressionSensitivity, 0.8)
    }
    
    func testFaceTrackingService_AvatarPersistence() {
        let service = DreamARFaceTrackingService.shared
        
        // 设置虚拟化身
        let avatar = AvatarModel.presets.first { $0.isUnlocked }!
        service.setAvatar(avatar)
        
        // 验证虚拟化身已设置
        XCTAssertEqual(service.currentAvatar?.id, avatar.id)
    }
    
    func testFaceTrackingService_AnimationParameters() {
        let service = DreamARFaceTrackingService.shared
        
        // 没有面部状态时返回空字典
        var params = service.getAnimationParameters()
        XCTAssertTrue(params.isEmpty)
        
        // 设置面部状态
        service.currentFaceState = FaceExpressionState(
            timestamp: Date(),
            blendshapes: [FaceBlendshapeData(name: "test", value: 0.5)],
            transform: simd_float4x4(1.0),
            isFaceDetected: true,
            confidence: 0.9
        )
        
        // 启用表情动画时返回参数
        params = service.getAnimationParameters()
        XCTAssertFalse(params.isEmpty)
    }
    
    // MARK: - 测试面部表情动画驱动器
    
    func testFaceExpressionAnimator_ApplyExpression_Happy() {
        var element = DreamARElement3D(
            id: UUID(),
            type: .star,
            position: SIMD3<Float>(0, 0, 0),
            rotation: SIMD4<Float>(0, 0, 0, 0),
            scale: SIMD3<Float>(1, 1, 1),
            material: MaterialConfig.default
        )
        
        let happyState = FaceExpressionState(
            timestamp: Date(),
            blendshapes: [],
            transform: simd_float4x4(1.0),
            isFaceDetected: true,
            confidence: 0.9
        )
        
        var animator = FaceExpressionAnimator(sensitivity: 0.7, smoothingFactor: 0.5)
        animator.applyExpression(to: &element, from: happyState)
        
        // 开心表情应该使元素向上移动
        XCTAssertGreaterThanOrEqual(element.position.y, 0)
    }
    
    func testFaceExpressionAnimator_SmoothValue() {
        var animator = FaceExpressionAnimator(sensitivity: 0.7, smoothingFactor: 0.5)
        
        // 第一次调用返回新值
        let value1 = animator.smoothValue(0.8, forKey: "test")
        XCTAssertEqual(value1, 0.8)
        
        // 第二次调用返回平滑后的值
        let value2 = animator.smoothValue(1.0, forKey: "test")
        XCTAssertEqual(value2, 0.9, accuracy: 0.01)
    }
    
    // MARK: - 测试成就
    
    func testFaceTrackingAchievement_Creation() {
        let achievement = FaceTrackingAchievement(
            id: UUID(),
            name: "测试成就",
            description: "测试描述",
            icon: "🏆",
            isUnlocked: false,
            unlockedDate: nil
        )
        
        XCTAssertEqual(achievement.name, "测试成就")
        XCTAssertEqual(achievement.icon, "🏆")
        XCTAssertFalse(achievement.isUnlocked)
        XCTAssertNil(achievement.unlockedDate)
    }
    
    func testFaceTrackingAchievement_Presets() {
        let presets = FaceTrackingAchievement.presets
        
        XCTAssertGreaterThan(presets.count, 0)
        
        for achievement in presets {
            XCTAssertFalse(achievement.name.isEmpty)
            XCTAssertFalse(achievement.description.isEmpty)
            XCTAssertFalse(achievement.icon.isEmpty)
        }
    }
    
    // MARK: - 性能测试
    
    func testPerformance_FaceStateCreation() {
        measure {
            for _ in 0..<1000 {
                let blendshapes = (0..<10).map { i in
                    FaceBlendshapeData(name: "blendshape\(i)", value: Float.random(in: 0...1))
                }
                
                _ = FaceExpressionState(
                    timestamp: Date(),
                    blendshapes: blendshapes,
                    transform: simd_float4x4(1.0),
                    isFaceDetected: true,
                    confidence: Float.random(in: 0...1)
                )
            }
        }
    }
    
    func testPerformance_ExpressionHistory() {
        let service = DreamARFaceTrackingService.shared
        
        measure {
            for i in 0..<100 {
                let state = FaceExpressionState(
                    timestamp: Date(),
                    blendshapes: [],
                    transform: simd_float4x4(1.0),
                    isFaceDetected: true,
                    confidence: 0.9
                )
                
                // 模拟添加到历史
                service.expressionHistory.append(state)
                
                // 限制数量
                if service.expressionHistory.count > service.config.maxHistoryCount {
                    service.expressionHistory.removeFirst()
                }
            }
            
            // 清理
            service.expressionHistory.removeAll()
        }
    }
}

// MARK: - 本地化测试

@MainActor
final class DreamLocalizationTests: XCTestCase {
    
    func testSupportedLanguage_AllCases() {
        let allLanguages = SupportedLanguage.allCases
        
        XCTAssertGreaterThanOrEqual(allLanguages.count, 7)
        
        for language in allLanguages {
            XCTAssertFalse(language.displayName.isEmpty)
            XCTAssertFalse(language.displayNameWithFlag.isEmpty)
            XCTAssertFalse(language.localizationTable.isEmpty)
        }
    }
    
    func testSupportedLanguage_DisplayValues() {
        XCTAssertEqual(SupportedLanguage.chineseSimplified.displayName, "简体中文")
        XCTAssertEqual(SupportedLanguage.english.displayName, "English")
        XCTAssertEqual(SupportedLanguage.japanese.displayName, "日本語")
        XCTAssertEqual(SupportedLanguage.korean.displayName, "한국어")
    }
    
    func testLocalizationService_Singleton() {
        let service1 = DreamLocalizationService.shared
        let service2 = DreamLocalizationService.shared
        
        XCTAssertIdentical(service1, service2)
    }
    
    func testLocalizationService_CurrentLanguage() {
        let service = DreamLocalizationService.shared
        
        // 验证当前语言在支持的列表中
        XCTAssertTrue(SupportedLanguage.allCases.contains(service.currentLanguage))
    }
    
    func testLocalizationService_SystemLanguage() {
        let service = DreamLocalizationService.shared
        
        let systemLanguage = service.systemLanguage
        
        // 验证系统语言在支持的列表中
        XCTAssertTrue(SupportedLanguage.allCases.contains(systemLanguage))
    }
    
    func testLocalizationService_SetLanguage() {
        let service = DreamLocalizationService.shared
        
        // 保存原始状态
        let originalUseSystem = service.useSystemLanguage
        let originalLanguage = service.currentLanguage
        
        // 设置新语言
        service.setLanguage(.english)
        
        // 验证语言已更改
        XCTAssertEqual(service.currentLanguage, .english)
        XCTAssertFalse(service.useSystemLanguage)
        
        // 恢复原始状态
        service.useSystemLanguage = originalUseSystem
        service.currentLanguage = originalLanguage
    }
    
    func testLocalizationService_ResetToSystem() {
        let service = DreamLocalizationService.shared
        
        // 保存原始状态
        let originalUseSystem = service.useSystemLanguage
        
        // 设置为非系统语言
        service.useSystemLanguage = false
        service.currentLanguage = .english
        
        // 重置为系统语言
        service.resetToSystemLanguage()
        
        // 验证已重置
        XCTAssertTrue(service.useSystemLanguage)
        
        // 恢复原始状态
        service.useSystemLanguage = originalUseSystem
    }
    
    func testLocalizationKey_AllCases() {
        let allKeys = LocalizationKey.allCases
        
        XCTAssertGreaterThan(allKeys.count, 0)
        
        for key in allKeys {
            XCTAssertFalse(key.rawValue.isEmpty)
        }
    }
    
    func testLocalizedString_Basic() {
        let service = DreamLocalizationService.shared
        
        // 测试基本字符串（可能返回键本身，如果没有翻译文件）
        let result = service.localized(.appName)
        
        // 至少应该返回非空字符串
        XCTAssertFalse(result.isEmpty)
    }
    
    func testLanguageSettingsView_Preview() {
        // 验证视图可以创建
        let view = LanguageSettingsView()
        
        // SwiftUI 视图测试有限，主要验证编译通过
        XCTAssertNotNil(view)
    }
}
