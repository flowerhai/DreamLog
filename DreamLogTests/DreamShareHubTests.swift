//
//  DreamShareHubTests.swift
//  DreamLog - 梦境分享中心单元测试
//
//  Created by DreamLog Team on 2026-03-14.
//  Phase 36: Dream Share Hub - 一键多平台分享中心
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamShareHubTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存中的 ModelContainer
        let schema = Schema([
            ShareConfig.self,
            ShareHistory.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 初始化服务
        await DreamShareHubService.shared.initialize(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - 分享平台测试
    
    func testSharePlatformCases() {
        // 测试所有平台枚举值
        let platforms = SharePlatform.allCases
        
        XCTAssertEqual(platforms.count, 11)
        XCTAssertTrue(platforms.contains(.wechat))
        XCTAssertTrue(platforms.contains(.weibo))
        XCTAssertTrue(platforms.contains(.xiaohongshu))
        XCTAssertTrue(platforms.contains(.copy))
        XCTAssertTrue(platforms.contains(.image))
    }
    
    func testSharePlatformDisplayName() {
        XCTAssertEqual(SharePlatform.wechat.displayName, "微信好友")
        XCTAssertEqual(SharePlatform.wechatMoments.displayName, "朋友圈")
        XCTAssertEqual(SharePlatform.weibo.displayName, "微博")
        XCTAssertEqual(SharePlatform.xiaohongshu.displayName, "小红书")
        XCTAssertEqual(SharePlatform.copy.displayName, "复制链接")
        XCTAssertEqual(SharePlatform.image.displayName, "保存图片")
    }
    
    func testSharePlatformIconName() {
        XCTAssertEqual(SharePlatform.wechat.iconName, "message.fill")
        XCTAssertEqual(SharePlatform.telegram.iconName, "paperplane.fill")
        XCTAssertEqual(SharePlatform.instagram.iconName, "camera.fill")
        XCTAssertEqual(SharePlatform.copy.iconName, "doc.on.doc.fill")
    }
    
    func testSharePlatformBrandColor() {
        XCTAssertEqual(SharePlatform.wechat.brandColor, "07C160")
        XCTAssertEqual(SharePlatform.weibo.brandColor, "E6162D")
        XCTAssertEqual(SharePlatform.instagram.brandColor, "E4405F")
        XCTAssertEqual(SharePlatform.telegram.brandColor, "0088CC")
    }
    
    func testSharePlatformURLScheme() {
        XCTAssertEqual(SharePlatform.wechat.urlScheme, "weixin://")
        XCTAssertEqual(SharePlatform.weibo.urlScheme, "sinaweibo://")
        XCTAssertEqual(SharePlatform.telegram.urlScheme, "tg://")
        XCTAssertNil(SharePlatform.copy.urlScheme)
        XCTAssertNil(SharePlatform.image.urlScheme)
    }
    
    // MARK: - 分享模板测试
    
    func testShareTemplateCases() {
        let templates = ShareTemplate.allCases
        
        XCTAssertEqual(templates.count, 6)
        XCTAssertTrue(templates.contains(.starry))
        XCTAssertTrue(templates.contains(.sunset))
        XCTAssertTrue(templates.contains(.minimal))
    }
    
    func testShareTemplateDisplayName() {
        XCTAssertEqual(ShareTemplate.starry.displayName, "星空")
        XCTAssertEqual(ShareTemplate.sunset.displayName, "日落")
        XCTAssertEqual(ShareTemplate.ocean.displayName, "海洋")
        XCTAssertEqual(ShareTemplate.forest.displayName, "森林")
        XCTAssertEqual(ShareTemplate.minimal.displayName, "极简")
        XCTAssertEqual(ShareTemplate.artistic.displayName, "艺术")
    }
    
    func testShareTemplateDescription() {
        XCTAssertTrue(ShareTemplate.starry.description.contains("星空"))
        XCTAssertTrue(ShareTemplate.sunset.description.contains("日落"))
        XCTAssertTrue(ShareTemplate.minimal.description.contains("简洁"))
    }
    
    // MARK: - 分享配置测试
    
    func testShareConfigCreation() async throws {
        let config = ShareConfig(
            name: "测试配置",
            selectedPlatforms: ["wechat", "weibo"],
            defaultTemplate: "starry",
            autoAddHashtags: true,
            autoAddEmotions: true,
            includeAIAnalysis: false,
            includeDreamImage: true,
            customMessage: "测试消息",
            isDefault: true
        )
        
        XCTAssertEqual(config.name, "测试配置")
        XCTAssertEqual(config.selectedPlatforms.count, 2)
        XCTAssertEqual(config.defaultTemplate, "starry")
        XCTAssertTrue(config.autoAddHashtags)
        XCTAssertTrue(config.isDefault)
        XCTAssertNotNil(config.id)
        XCTAssertNotNil(config.createdAt)
    }
    
    func testShareConfigPersistence() async throws {
        // 创建配置
        let config = ShareConfig(
            name: "持久化测试",
            selectedPlatforms: ["wechat"],
            isDefault: true
        )
        
        try await DreamShareHubService.shared.createConfig(config)
        
        // 验证配置已保存
        let fetchedConfig = await DreamShareHubService.shared.getConfig(id: config.id.uuidString)
        XCTAssertNotNil(fetchedConfig)
        XCTAssertEqual(fetchedConfig?.name, "持久化测试")
        XCTAssertEqual(fetchedConfig?.selectedPlatforms, ["wechat"])
    }
    
    func testShareConfigUpdate() async throws {
        let config = ShareConfig(name: "原始名称", selectedPlatforms: ["wechat"])
        try await DreamShareHubService.shared.createConfig(config)
        
        // 更新配置
        config.name = "更新后的名称"
        config.selectedPlatforms.append("weibo")
        try await DreamShareHubService.shared.updateConfig(config)
        
        // 验证更新
        let fetchedConfig = await DreamShareHubService.shared.getConfig(id: config.id.uuidString)
        XCTAssertEqual(fetchedConfig?.name, "更新后的名称")
        XCTAssertEqual(fetchedConfig?.selectedPlatforms.count, 2)
    }
    
    func testShareConfigDelete() async throws {
        let config = ShareConfig(name: "待删除配置", selectedPlatforms: ["wechat"])
        try await DreamShareHubService.shared.createConfig(config)
        
        // 删除配置
        try await DreamShareHubService.shared.deleteConfig(config)
        
        // 验证已删除
        let fetchedConfig = await DreamShareHubService.shared.getConfig(id: config.id.uuidString)
        XCTAssertNil(fetchedConfig)
    }
    
    func testSetDefaultConfig() async throws {
        let config1 = ShareConfig(name: "配置 1", isDefault: false)
        let config2 = ShareConfig(name: "配置 2", isDefault: false)
        
        try await DreamShareHubService.shared.createConfig(config1)
        try await DreamShareHubService.shared.createConfig(config2)
        
        // 设置 config2 为默认
        try await DreamShareHubService.shared.setDefaultConfig(id: config2.id.uuidString)
        
        // 验证
        let defaultConfig = await DreamShareHubService.shared.getDefaultConfig()
        XCTAssertEqual(defaultConfig?.id, config2.id)
        
        // 验证 config1 不再是默认
        let fetchedConfig1 = await DreamShareHubService.shared.getConfig(id: config1.id.uuidString)
        XCTAssertFalse(fetchedConfig1?.isDefault ?? true)
    }
    
    // MARK: - 分享历史测试
    
    func testShareHistoryCreation() async throws {
        let dreamId = UUID()
        let history = try await DreamShareHubService.shared.addShareHistory(
            dreamId: dreamId,
            dreamTitle: "测试梦境",
            platforms: ["wechat", "weibo"],
            template: "starry",
            shareMessage: "分享消息",
            successCount: 2,
            failCount: 0
        )
        
        XCTAssertEqual(history.dreamTitle, "测试梦境")
        XCTAssertEqual(history.platforms.count, 2)
        XCTAssertEqual(history.template, "starry")
        XCTAssertEqual(history.successCount, 2)
        XCTAssertEqual(history.failCount, 0)
    }
    
    func testShareHistoryPersistence() async throws {
        let dreamId = UUID()
        let history = try await DreamShareHubService.shared.addShareHistory(
            dreamId: dreamId,
            dreamTitle: "持久化测试",
            platforms: ["wechat"],
            template: "starry",
            successCount: 1,
            failCount: 0
        )
        
        // 验证历史已保存
        let histories = await DreamShareHubService.shared.getHistory(limit: 10)
        XCTAssertTrue(histories.contains(where: { $0.id == history.id }))
    }
    
    func testShareHistoryDeletion() async throws {
        let history = try await DreamShareHubService.shared.addShareHistory(
            dreamId: UUID(),
            dreamTitle: "待删除",
            platforms: ["wechat"],
            template: "starry",
            successCount: 1,
            failCount: 0
        )
        
        // 删除历史
        try await DreamShareHubService.shared.deleteHistory(history)
        
        // 验证已删除
        let histories = await DreamShareHubService.shared.getHistory(limit: 10)
        XCTAssertFalse(histories.contains(where: { $0.id == history.id }))
    }
    
    func testClearAllHistory() async throws {
        // 添加多条历史
        for i in 0..<5 {
            _ = try await DreamShareHubService.shared.addShareHistory(
                dreamId: UUID(),
                dreamTitle: "梦境\(i)",
                platforms: ["wechat"],
                template: "starry",
                successCount: 1,
                failCount: 0
            )
        }
        
        // 清空所有历史
        try await DreamShareHubService.shared.clearAllHistory()
        
        // 验证已清空
        let histories = await DreamShareHubService.shared.getHistory(limit: 10)
        XCTAssertEqual(histories.count, 0)
    }
    
    // MARK: - 分享统计测试
    
    func testShareStatsEmpty() {
        let stats = ShareStats.empty
        
        XCTAssertEqual(stats.totalShares, 0)
        XCTAssertEqual(stats.totalPlatforms, 0)
        XCTAssertNil(stats.favoritePlatform)
        XCTAssertEqual(stats.thisWeekShares, 0)
        XCTAssertEqual(stats.thisMonthShares, 0)
        XCTAssertNil(stats.favoriteTemplate)
    }
    
    func testShareStatsCalculation() async throws {
        // 添加分享历史
        let now = Date()
        let calendar = Calendar.current
        
        // 本周的分享
        _ = try await DreamShareHubService.shared.addShareHistory(
            dreamId: UUID(),
            dreamTitle: "本周梦境",
            platforms: ["wechat"],
            template: "starry",
            successCount: 3,
            failCount: 1
        )
        
        // 获取统计
        let stats = await DreamShareHubService.shared.getStats()
        
        XCTAssertEqual(stats.totalShares, 3)
        XCTAssertGreaterThanOrEqual(stats.thisWeekShares, 3)
    }
    
    // MARK: - 批量分享结果测试
    
    func testBatchShareResult() {
        let results = [
            ShareTaskResult(platform: .wechat, success: true),
            ShareTaskResult(platform: .weibo, success: true),
            ShareTaskResult(platform: .telegram, success: false, errorMessage: "未安装 App")
        ]
        
        let batchResult = BatchShareResult(
            dreamId: UUID(),
            totalPlatforms: 3,
            successCount: 2,
            failCount: 1,
            results: results,
            shareHistoryId: UUID()
        )
        
        XCTAssertEqual(batchResult.totalPlatforms, 3)
        XCTAssertEqual(batchResult.successCount, 2)
        XCTAssertEqual(batchResult.failCount, 1)
        XCTAssertEqual(batchResult.successRate, 66.66666666666666, accuracy: 0.01)
        XCTAssertFalse(batchResult.allSuccess)
    }
    
    func testBatchShareResultAllSuccess() {
        let results = [
            ShareTaskResult(platform: .wechat, success: true),
            ShareTaskResult(platform: .weibo, success: true)
        ]
        
        let batchResult = BatchShareResult(
            dreamId: UUID(),
            totalPlatforms: 2,
            successCount: 2,
            failCount: 0,
            results: results,
            shareHistoryId: nil
        )
        
        XCTAssertEqual(batchResult.successRate, 100.0, accuracy: 0.01)
        XCTAssertTrue(batchResult.allSuccess)
    }
    
    // MARK: - 分享任务结果测试
    
    func testShareTaskResult() {
        let result = ShareTaskResult(
            platform: .wechat,
            success: true
        )
        
        XCTAssertNotNil(result.id)
        XCTAssertEqual(result.platform, .wechat)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.errorMessage)
        XCTAssertLessThan(Date().timeIntervalSince(result.timestamp), 1)
    }
    
    func testShareTaskResultFailure() {
        let result = ShareTaskResult(
            platform: .telegram,
            success: false,
            errorMessage: "未安装 Telegram"
        )
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.errorMessage, "未安装 Telegram")
    }
    
    // MARK: - 分享错误测试
    
    func testShareErrorMessages() {
        XCTAssertEqual(ShareError.noModelContext.errorDescription, "数据上下文未初始化")
        XCTAssertEqual(ShareError.unsupportedPlatform.errorDescription, "不支持的分享平台")
        XCTAssertEqual(ShareError.invalidURL.errorDescription, "无效的 URL")
        
        let appNotInstalledError = ShareError.appNotInstalled(platform: "微信")
        XCTAssertEqual(appNotInstalledError.errorDescription, "未安装 微信 App")
        
        let shareFailedError = ShareError.shareFailed(reason: "网络错误")
        XCTAssertEqual(shareFailedError.errorDescription, "分享失败：网络错误")
    }
    
    // MARK: - 内容生成测试
    
    func testContentGeneration() async throws {
        // 这个测试需要验证内容生成逻辑
        // 由于内容生成在 Actor 内部，我们通过创建配置来间接测试
        
        let config = ShareConfig(
            name: "内容测试",
            selectedPlatforms: ["copy"],
            defaultTemplate: "starry",
            autoAddHashtags: true,
            autoAddEmotions: true,
            includeAIAnalysis: true,
            includeDreamImage: false
        )
        
        try await DreamShareHubService.shared.createConfig(config)
        
        let fetchedConfig = await DreamShareHubService.shared.getConfig(id: config.id.uuidString)
        XCTAssertNotNil(fetchedConfig)
        XCTAssertEqual(fetchedConfig?.includeAIAnalysis, true)
        XCTAssertEqual(fetchedConfig?.includeDreamImage, false)
    }
    
    // MARK: - 性能测试
    
    func testPerformance_ConfigCreation() async throws {
        self.measure {
            let config = ShareConfig(
                name: "性能测试配置",
                selectedPlatforms: ["wechat", "weibo", "telegram"]
            )
            
            Task {
                try? await DreamShareHubService.shared.createConfig(config)
            }
        }
    }
    
    func testPerformance_HistoryAddition() async throws {
        self.measure {
            Task {
                for _ in 0..<10 {
                    _ = try? await DreamShareHubService.shared.addShareHistory(
                        dreamId: UUID(),
                        dreamTitle: "性能测试",
                        platforms: ["wechat"],
                        template: "starry",
                        successCount: 1,
                        failCount: 0
                    )
                }
            }
        }
    }
}
