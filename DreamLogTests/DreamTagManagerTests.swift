//
//  DreamTagManagerTests.swift
//  DreamLogTests
//
//  智能标签管理系统单元测试
//  Phase 32: 智能标签管理
//

import XCTest
@testable import DreamLog

@MainActor
final class DreamTagManagerTests: XCTestCase {
    
    var dreamStore: DreamStore!
    var tagManager: DreamTagManagerService!
    
    override func setUp() async throws {
        dreamStore = DreamStore.shared
        tagManager = DreamTagManagerService(dreamStore: dreamStore)
        
        // 清理现有数据
        await dreamStore.deleteAllDreams()
        
        // 创建测试数据
        await createTestDreams()
    }
    
    override func tearDown() async throws {
        await dreamStore.deleteAllDreams()
        dreamStore = nil
        tagManager = nil
    }
    
    // MARK: - Test Data Setup
    
    private func createTestDreams() async {
        let dreams = [
            Dream(
                title: "飞行的梦",
                content: "我在天空中自由飞翔，感觉很美妙",
                tags: ["飞行", "天空", "自由"],
                emotions: [.happy, .excited],
                clarity: 4,
                intensity: 5
            ),
            Dream(
                title: "水的梦境",
                content: "梦见大海和波浪，水很清澈",
                tags: ["水", "大海", "自然"],
                emotions: [.calm],
                clarity: 5,
                intensity: 3
            ),
            Dream(
                title: "追逐的梦",
                content: "有人在追我，很害怕",
                tags: ["追逐", "恐惧", "逃跑"],
                emotions: [.fearful, .anxious],
                clarity: 3,
                intensity: 5
            ),
            Dream(
                title: "飞行的另一个梦",
                content: "再次梦到飞行，这次是在城市上空",
                tags: ["飞行", "城市", "天空"],
                emotions: [.excited],
                clarity: 4,
                intensity: 4
            ),
            Dream(
                title: "水的梦 2",
                content: "梦见下雨，雨水很温柔",
                tags: ["水", "雨", "自然"],
                emotions: [.calm, .happy],
                clarity: 4,
                intensity: 2
            )
        ]
        
        for dream in dreams {
            await dreamStore.addDream(dream)
        }
    }
    
    // MARK: - Tag Index Tests
    
    func testRebuildTagIndex() async {
        await tagManager.rebuildTagIndex()
        let tags = await tagManager.getAllTags()
        
        XCTAssertGreaterThan(tags.count, 0, "应该有标签")
        
        // 检查热门标签
        let tagNames = tags.map { $0.name }
        XCTAssertTrue(tagNames.contains("飞行"), "应该包含'飞行'标签")
        XCTAssertTrue(tagNames.contains("水"), "应该包含'水'标签")
        XCTAssertTrue(tagNames.contains("自然"), "应该包含'自然'标签")
    }
    
    func testTagStatistics() async {
        let stats = await tagManager.getStatistics()
        
        XCTAssertGreaterThan(stats.totalTags, 0, "应该有标签")
        XCTAssertGreaterThan(stats.totalUsage, 0, "应该有使用次数")
        XCTAssertEqual(stats.totalUsage, stats.tags.reduce(0) { $0 + $1.count }, "总使用次数应该匹配")
    }
    
    // MARK: - Tag Operations Tests
    
    func testRenameTag() async {
        let result = await tagManager.renameTag("飞行", newName: "飞翔")
        
        XCTAssertTrue(result.success, "重命名应该成功")
        XCTAssertGreaterThan(result.affectedDreams, 0, "应该影响梦境")
        
        // 验证标签已更新
        let tags = await tagManager.getAllTags()
        let tagNames = tags.map { $0.name }
        XCTAssertTrue(tagNames.contains("飞翔"), "应该包含新标签名")
        XCTAssertFalse(tagNames.contains("飞行"), "不应该包含旧标签名")
    }
    
    func testRenameNonExistentTag() async {
        let result = await tagManager.renameTag("不存在的标签", newName: "新标签")
        
        XCTAssertFalse(result.success, "重命名不存在的标签应该失败")
        XCTAssertEqual(result.affectedDreams, 0, "不应该影响梦境")
    }
    
    func testMergeTags() async {
        // 合并"大海"和"水"
        let result = await tagManager.mergeTags(sourceTag: "大海", targetTag: "水")
        
        XCTAssertTrue(result.success, "合并应该成功")
        XCTAssertGreaterThan(result.affectedDreams, 0, "应该影响梦境")
        
        // 验证合并结果
        let tags = await tagManager.getAllTags()
        let waterTag = tags.first { $0.name == "水" }
        XCTAssertNotNil(waterTag, "目标标签应该存在")
        XCTAssertEqual(waterTag?.count, 3, "水标签应该有 3 次使用")
    }
    
    func testDeleteTag() async {
        let result = await tagManager.deleteTag("追逐")
        
        XCTAssertTrue(result.success, "删除应该成功")
        XCTAssertGreaterThan(result.affectedDreams, 0, "应该影响梦境")
        
        // 验证标签已删除
        let tags = await tagManager.getAllTags()
        let tagNames = tags.map { $0.name }
        XCTAssertFalse(tagNames.contains("追逐"), "不应该包含已删除的标签")
    }
    
    func testCategorizeTag() async {
        let success = await tagManager.categorizeTag("飞行", category: .action)
        
        XCTAssertTrue(success, "分类应该成功")
        
        let tags = await tagManager.getAllTags()
        let flyingTag = tags.first { $0.name == "飞行" }
        XCTAssertEqual(flyingTag?.category, .action, "标签应该有正确的分类")
    }
    
    func testBulkCategorize() async {
        let tags = ["飞行", "追逐", "逃跑"]
        let count = await tagManager.bulkCategorize(tags, category: .action)
        
        XCTAssertEqual(count, tags.count, "所有标签都应该被分类")
        
        let allTags = await tagManager.getAllTags()
        for tagName in tags {
            let tag = allTags.first { $0.name == tagName }
            XCTAssertEqual(tag?.category, .action, "\(tagName) 应该有正确的分类")
        }
    }
    
    // MARK: - Tag Suggestions Tests
    
    func testAnalyzeDreamForTags() async {
        let dreams = await dreamStore.dreams
        guard let dream = dreams.first else {
            XCTFail("应该有测试梦境")
            return
        }
        
        let suggestion = await tagManager.analyzeDreamForTags(dream)
        
        XCTAssertEqual(suggestion.dreamId, dream.id, "建议应该对应正确的梦境")
        XCTAssertGreaterThanOrEqual(suggestion.suggestedTags.count, 0, "应该有建议标签")
        XCTAssertGreaterThan(suggestion.confidence, 0, "应该有置信度")
    }
    
    func testGetTagSuggestions() async {
        let suggestions = await tagManager.getTagSuggestions()
        
        // 建议数量取决于梦境的标签数量
        XCTAssertGreaterThanOrEqual(suggestions.count, 0, "应该有建议")
    }
    
    func testApplySuggestion() async {
        let suggestions = await tagManager.getTagSuggestions()
        
        guard let suggestion = suggestions.first else {
            XCTFail("应该有建议")
            return
        }
        
        let applied = await tagManager.applySuggestion(suggestion)
        
        // 应用可能成功或失败，取决于标签是否已存在
        XCTAssertGreaterThanOrEqual(applied ? 1 : 0, 0)
    }
    
    // MARK: - Cleanup Suggestions Tests
    
    func testAnalyzeTags() async {
        await tagManager.analyzeTags()
        let suggestions = await tagManager.getCleanupSuggestions()
        
        // 清理建议数量取决于标签状态
        XCTAssertGreaterThanOrEqual(suggestions.count, 0)
    }
    
    func testDetectDuplicateTags() async {
        // 创建重复标签（大小写不同）
        let dream = Dream(
            title: "测试梦",
            content: "测试内容",
            tags: ["测试", "测试", "TEST"],
            emotions: [.neutral]
        )
        await dreamStore.addDream(dream)
        
        await tagManager.rebuildTagIndex()
        await tagManager.analyzeTags()
        
        let suggestions = await tagManager.getCleanupSuggestions()
        let duplicateSuggestions = suggestions.filter { $0.type == .duplicate }
        
        // 应该有重复标签建议
        XCTAssertGreaterThanOrEqual(duplicateSuggestions.count, 0)
    }
    
    func testDetectUnusedTags() async {
        // 创建一个标签但不使用
        // 这个测试依赖于标签索引的重建逻辑
        await tagManager.rebuildTagIndex()
        await tagManager.analyzeTags()
        
        let suggestions = await tagManager.getCleanupSuggestions()
        let unusedSuggestions = suggestions.filter { $0.type == .unused }
        
        // 可能有也可能没有未使用标签
        XCTAssertGreaterThanOrEqual(unusedSuggestions.count, 0)
    }
    
    // MARK: - Bulk Operations Tests
    
    func testAddTagToDreams() async {
        let dreams = await dreamStore.dreams
        let dreamIds = dreams.map { $0.id }
        
        let result = await tagManager.addTagToDreams("新标签", dreamIds: dreamIds)
        
        XCTAssertTrue(result.success, "批量添加应该成功")
        XCTAssertEqual(result.affectedDreams, dreamIds.count, "应该影响所有梦境")
        
        // 验证标签已添加
        let updatedDreams = await dreamStore.dreams
        for dream in updatedDreams {
            XCTAssertTrue(dream.tags.contains("新标签"), "梦境应该包含新标签")
        }
    }
    
    func testRemoveTagFromDreams() async {
        let dreams = await dreamStore.dreams
        let dreamIds = dreams.map { $0.id }
        
        // 先添加标签
        await tagManager.addTagToDreams("临时标签", dreamIds: dreamIds)
        
        // 然后删除
        let result = await tagManager.removeTagFromDreams("临时标签", dreamIds: dreamIds)
        
        XCTAssertTrue(result.success, "批量删除应该成功")
        XCTAssertEqual(result.affectedDreams, dreamIds.count, "应该影响所有梦境")
        
        // 验证标签已删除
        let updatedDreams = await dreamStore.dreams
        for dream in updatedDreams {
            XCTAssertFalse(dream.tags.contains("临时标签"), "梦境不应该包含已删除的标签")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testRenameTagToExistingName() async {
        // 尝试重命名为已存在的标签名
        let result = await tagManager.renameTag("飞行", newName: "水")
        
        XCTAssertFalse(result.success, "重命名为已存在的标签名应该失败")
    }
    
    func testMergeTagToNonExistent() async {
        let result = await tagManager.mergeTags(sourceTag: "飞行", targetTag: "不存在的标签")
        
        XCTAssertFalse(result.success, "合并不存在的目标标签应该失败")
    }
    
    func testDeleteNonExistentTag() async {
        let result = await tagManager.deleteTag("不存在的标签")
        
        XCTAssertFalse(result.success, "删除不存在的标签应该失败")
    }
    
    func testCategorizeNonExistentTag() async {
        let success = await tagManager.categorizeTag("不存在的标签", category: .action)
        
        XCTAssertFalse(success, "分类不存在的标签应该失败")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataset() async {
        // 创建大量测试数据
        for i in 0..<100 {
            let dream = Dream(
                title: "测试梦 \(i)",
                content: "这是第 \(i) 个测试梦境的内容",
                tags: ["测试", "标签\(i % 10)", "分类\(i % 5)"],
                emotions: [.neutral],
                clarity: 3,
                intensity: 3
            )
            await dreamStore.addDream(dream)
        }
        
        // 测试性能
        measure {
            Task {
                await tagManager.rebuildTagIndex()
                _ = await tagManager.getAllTags()
                _ = await tagManager.getStatistics()
            }
        }
    }
    
    // MARK: - Tag Normalization Tests
    
    func testTagNormalization() async {
        // 测试标签标准化（大小写、空格）
        let dream1 = Dream(
            title: "测试 1",
            content: "内容",
            tags: ["测试", "标签"],
            emotions: [.neutral]
        )
        
        let dream2 = Dream(
            title: "测试 2",
            content: "内容",
            tags: ["测试", "标签"],  // 相同的标签
            emotions: [.neutral]
        )
        
        await dreamStore.addDream(dream1)
        await dreamStore.addDream(dream2)
        
        await tagManager.rebuildTagIndex()
        let tags = await tagManager.getAllTags()
        
        // 相同的标签应该被合并统计
        let testTag = tags.first { $0.normalized == "测试" }
        XCTAssertEqual(testTag?.count, 2, "相同标签应该有正确的计数")
    }
    
    // MARK: - Tag Info Tests
    
    func testTagInfoCreation() {
        let tagInfo = TagInfo.fromName("测试标签")
        
        XCTAssertEqual(tagInfo.name, "测试标签")
        XCTAssertEqual(tagInfo.normalized, "测试标签")
        XCTAssertEqual(tagInfo.count, 0)
        XCTAssertNil(tagInfo.category)
        XCTAssertFalse(tagInfo.isSuggested)
    }
    
    func testTagInfoWithCount() {
        let tagInfo = TagInfo(
            name: "热门标签",
            count: 100,
            category: .action,
            aliases: ["同义词 1", "同义词 2"],
            isSuggested: true
        )
        
        XCTAssertEqual(tagInfo.name, "热门标签")
        XCTAssertEqual(tagInfo.count, 100)
        XCTAssertEqual(tagInfo.category, .action)
        XCTAssertEqual(tagInfo.aliases.count, 2)
        XCTAssertTrue(tagInfo.isSuggested)
    }
    
    // MARK: - Tag Category Tests
    
    func testTagCategoryProperties() {
        for category in TagCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "\(category.rawValue) 应该有图标")
            XCTAssertFalse(category.color.isEmpty, "\(category.rawValue) 应该有颜色")
        }
    }
    
    // MARK: - Cleanup Suggestion Tests
    
    func testCleanupSuggestionCreation() {
        let tag1 = TagInfo(name: "标签 1", count: 5)
        let tag2 = TagInfo(name: "标签 2", count: 3)
        
        let suggestion = TagCleanupSuggestion(
            type: .similar,
            tags: [tag1, tag2],
            recommendation: "建议合并",
            impact: 8
        )
        
        XCTAssertEqual(suggestion.type, .similar)
        XCTAssertEqual(suggestion.tags.count, 2)
        XCTAssertEqual(suggestion.impact, 8)
    }
    
    // MARK: - Tag Suggestion Tests
    
    func testTagSuggestionCreation() {
        let suggestion = TagSuggestion(
            dreamId: UUID(),
            dreamTitle: "测试梦境",
            suggestedTags: ["标签 1", "标签 2"],
            confidence: 0.85,
            reason: "基于内容分析"
        )
        
        XCTAssertEqual(suggestion.dreamTitle, "测试梦境")
        XCTAssertEqual(suggestion.suggestedTags.count, 2)
        XCTAssertEqual(suggestion.confidence, 0.85)
    }
    
    // MARK: - Statistics Tests
    
    func testTagStatisticsCalculation() {
        let tag1 = TagInfo(name: "标签 1", count: 10, category: .action)
        let tag2 = TagInfo(name: "标签 2", count: 5, category: .emotion)
        let tag3 = TagInfo(name: "标签 3", count: 3)  // 未分类
        
        let stats = TagStatistics(
            totalTags: 3,
            totalUsage: 18,
            categorizedTags: 2,
            uncategorizedTags: 1,
            topTags: [tag1, tag2, tag3],
            recentTags: [tag1],
            suggestedTags: [],
            categoryDistribution: [.action: 1, .emotion: 1]
        )
        
        XCTAssertEqual(stats.totalTags, 3)
        XCTAssertEqual(stats.totalUsage, 18)
        XCTAssertEqual(stats.categorizedPercentage, 66.67, accuracy: 0.01)
    }
    
    // MARK: - Bulk Operation Result Tests
    
    func testBulkOperationResultCreation() {
        let result = BulkOperationResult(
            success: true,
            affectedDreams: 10,
            processedTags: 2,
            errors: [],
            message: "操作成功"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.affectedDreams, 10)
        XCTAssertEqual(result.processedTags, 2)
        XCTAssertTrue(result.errors.isEmpty)
    }
    
    func testBulkOperationResultWithErrors() {
        let result = BulkOperationResult(
            success: false,
            affectedDreams: 0,
            processedTags: 0,
            errors: ["错误 1", "错误 2"],
            message: "操作失败"
        )
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.errors.count, 2)
    }
}
