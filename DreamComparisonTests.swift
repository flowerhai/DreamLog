//
//  DreamComparisonTests.swift
//  DreamLogTests
//
//  Dream Comparison Feature - Unit Tests
//  Phase 77: Dream Comparison Tool
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamComparisonTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存存储容器
        let schema = Schema([
            Dream.self,
            DreamComparisonResult.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Helper Functions
    
    func createDream(
        title: String = "测试梦境",
        content: String = "这是一个测试梦境内容",
        tags: [String] = ["测试"],
        emotions: [Emotion] = [.平静],
        clarity: Int = 3,
        intensity: Int = 3,
        isLucid: Bool = false,
        aiAnalysis: String? = nil,
        date: Date = Date()
    ) -> Dream {
        let dream = Dream(
            title: title,
            content: content,
            tags: tags,
            emotions: emotions,
            clarity: clarity,
            intensity: intensity,
            isLucid: isLucid,
            aiAnalysis: aiAnalysis,
            date: date
        )
        
        modelContainer.mainContext.insert(dream)
        try? modelContainer.mainContext.save()
        
        return dream
    }
    
    // MARK: - Model Tests
    
    func testComparisonResultModel() throws {
        let dreamIds = [UUID(), UUID()]
        let result = DreamComparisonResult(
            dreamIds: dreamIds,
            comparisonType: .twoDreams,
            similarities: [],
            differences: [],
            insights: ["测试洞察"],
            similarityScore: 0.75
        )
        
        XCTAssertEqual(result.dreamIds.count, 2)
        XCTAssertEqual(result.comparisonType, .twoDreams)
        XCTAssertEqual(result.insights.count, 1)
        XCTAssertEqual(result.similarityScore, 0.75)
        XCTAssertNotNil(result.id)
        XCTAssertNotNil(result.createdAt)
    }
    
    func testComparisonTypeCases() {
        let allCases = ComparisonType.allCases
        XCTAssertEqual(allCases.count, 4)
        
        XCTAssertEqual(ComparisonType.twoDreams.rawValue, "双梦对比")
        XCTAssertEqual(ComparisonType.multiDreams.rawValue, "多梦对比")
        XCTAssertEqual(ComparisonType.timePeriod.rawValue, "时间段对比")
        XCTAssertEqual(ComparisonType.themeEvolution.rawValue, "主题演变")
    }
    
    func testSimilarityTypeCases() {
        let allCases = SimilarityType.allCases
        XCTAssertEqual(allCases.count, 8)
        
        XCTAssertEqual(SimilarityType.commonTags.rawValue, "共同标签")
        XCTAssertEqual(SimilarityType.commonEmotions.rawValue, "共同情绪")
        XCTAssertEqual(SimilarityType.commonThemes.rawValue, "共同主题")
    }
    
    func testDifferenceTypeCases() {
        let allCases = DifferenceType.allCases
        XCTAssertEqual(allCases.count, 8)
        
        XCTAssertEqual(DifferenceType.emotionChange.rawValue, "情绪变化")
        XCTAssertEqual(DifferenceType.clarityChange.rawValue, "清晰度变化")
        XCTAssertEqual(DifferenceType.intensityChange.rawValue, "强度变化")
    }
    
    func testSimilarityCategoryCodable() throws {
        let category = SimilarityCategory(
            category: .commonTags,
            items: ["标签 1", "标签 2"],
            confidence: 0.8
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SimilarityCategory.self, from: data)
        
        XCTAssertEqual(decoded.category, .commonTags)
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.confidence, 0.8)
    }
    
    func testDifferenceCategoryCodable() throws {
        let difference = DifferenceCategory(
            category: .emotionChange,
            dreamAValue: "平静",
            dreamBValue: "焦虑",
            significance: "情绪从平静变为焦虑"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(difference)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DifferenceCategory.self, from: data)
        
        XCTAssertEqual(decoded.category, .emotionChange)
        XCTAssertEqual(decoded.dreamAValue, "平静")
        XCTAssertEqual(decoded.dreamBValue, "焦虑")
    }
    
    func testComparisonConfigCodable() throws {
        let dreamIds = [UUID(), UUID()]
        let config = DreamComparisonConfig(
            dreamIds: dreamIds,
            comparisonType: .multiDreams,
            includeAIAnalysis: true,
            includeEmotions: true,
            includeTags: true,
            includeSymbols: false
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DreamComparisonConfig.self, from: data)
        
        XCTAssertEqual(decoded.dreamIds.count, 2)
        XCTAssertEqual(decoded.comparisonType, .multiDreams)
        XCTAssertTrue(decoded.includeAIAnalysis)
        XCTAssertFalse(decoded.includeSymbols)
    }
    
    func testComparisonStatisticsCodable() throws {
        let stats = ComparisonStatistics(
            totalComparisons: 10,
            averageSimilarity: 0.65,
            mostCommonSimilarity: .commonTags,
            mostCommonDifference: .emotionChange,
            recentComparisons: [Date()]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(stats)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ComparisonStatistics.self, from: data)
        
        XCTAssertEqual(decoded.totalComparisons, 10)
        XCTAssertEqual(decoded.averageSimilarity, 0.65)
        XCTAssertEqual(decoded.mostCommonSimilarity, .commonTags)
        XCTAssertEqual(decoded.mostCommonDifference, .emotionChange)
    }
    
    // MARK: - Service Tests
    
    func testCompareTwoDreamsWithCommonTags() async throws {
        let dreamA = createDream(
            title: "梦境 A",
            tags: ["飞行", "自由", "天空"],
            emotions: [.快乐],
            clarity: 4,
            intensity: 4
        )
        
        let dreamB = createDream(
            title: "梦境 B",
            tags: ["飞行", "自由", "鸟"],
            emotions: [.快乐],
            clarity: 4,
            intensity: 3
        )
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        XCTAssertEqual(result.dreamIds.count, 2)
        XCTAssertGreaterThan(result.similarityScore, 0.5)
        
        // 应该找到共同标签
        let commonTagsSimilarity = result.similarities.first { $0.category == .commonTags }
        XCTAssertNotNil(commonTagsSimilarity)
        XCTAssertTrue(commonTagsSimilarity?.items.contains("飞行") ?? false)
        XCTAssertTrue(commonTagsSimilarity?.items.contains("自由") ?? false)
    }
    
    func testCompareTwoDreamsWithDifferentEmotions() async throws {
        let dreamA = createDream(
            title: "梦境 A",
            emotions: [.快乐],
            clarity: 4,
            intensity: 4
        )
        
        let dreamB = createDream(
            title: "梦境 B",
            emotions: [.焦虑],
            clarity: 2,
            intensity: 2
        )
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        // 应该找到情绪差异
        let emotionDifference = result.differences.first { $0.category == .emotionChange }
        XCTAssertNotNil(emotionDifference)
        
        // 应该找到清晰度差异
        let clarityDifference = result.differences.first { $0.category == .clarityChange }
        XCTAssertNotNil(clarityDifference)
    }
    
    func testCompareMultipleDreams() async throws {
        let dreamA = createDream(title: "梦境 A", tags: ["水", "海洋"], emotions: [.平静])
        let dreamB = createDream(title: "梦境 B", tags: ["水", "河流"], emotions: [.平静])
        let dreamC = createDream(title: "梦境 C", tags: ["水", "湖泊"], emotions: [.快乐])
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareMultipleDreams(dreamIds: [dreamA.id, dreamB.id, dreamC.id])
        
        XCTAssertEqual(result.dreamIds.count, 3)
        XCTAssertEqual(result.comparisonType, .multiDreams)
        
        // 应该找到共同标签"水"
        let commonTagsSimilarity = result.similarities.first { $0.category == .commonTags }
        XCTAssertNotNil(commonTagsSimilarity)
        XCTAssertTrue(commonTagsSimilarity?.items.contains("水") ?? false)
    }
    
    func testCompareDreamsInvalidCount() async {
        let dreamIds: [UUID] = []
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        
        do {
            _ = try await service.compareMultipleDreams(dreamIds: dreamIds)
            XCTFail("应该抛出错误")
        } catch ComparisonError.invalidDreamCount {
            // 预期错误
        } catch {
            XCTFail("抛出错误类型不正确")
        }
    }
    
    func testCompareDreamsNotFound() async {
        let service = DreamComparisonService(modelContainer: modelContainer)
        let nonExistentId = UUID()
        
        do {
            _ = try await service.compareTwoDreams(dreamAId: nonExistentId, dreamBId: nonExistentId)
            XCTFail("应该抛出错误")
        } catch ComparisonError.dreamNotFound {
            // 预期错误
        } catch {
            XCTFail("抛出错误类型不正确")
        }
    }
    
    // MARK: - Similarity Detection Tests
    
    func testFindCommonTags() async throws {
        let dreamA = createDream(tags: ["标签 1", "标签 2", "标签 3"])
        let dreamB = createDream(tags: ["标签 2", "标签 3", "标签 4"])
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let commonTagsSimilarity = result.similarities.first { $0.category == .commonTags }
        XCTAssertNotNil(commonTagsSimilarity)
        XCTAssertTrue(commonTagsSimilarity?.items.contains("标签 2") ?? false)
        XCTAssertTrue(commonTagsSimilarity?.items.contains("标签 3") ?? false)
        XCTAssertFalse(commonTagsSimilarity?.items.contains("标签 1") ?? true)
    }
    
    func testFindCommonEmotions() async throws {
        let dreamA = createDream(emotions: [.快乐, .平静])
        let dreamB = createDream(emotions: [.快乐, .焦虑])
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let commonEmotionsSimilarity = result.similarities.first { $0.category == .commonEmotions }
        XCTAssertNotNil(commonEmotionsSimilarity)
        XCTAssertTrue(commonEmotionsSimilarity?.items.contains("快乐") ?? false)
    }
    
    func testFindClaritySimilarity() async throws {
        // 相似清晰度
        let dreamA = createDream(clarity: 4)
        let dreamB = createDream(clarity: 4)
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let claritySimilarity = result.similarities.first { $0.category == .similarClarity }
        XCTAssertNotNil(claritySimilarity)
    }
    
    func testFindIntensitySimilarity() async throws {
        // 相似强度
        let dreamA = createDream(intensity: 3)
        let dreamB = createDream(intensity: 3)
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let intensitySimilarity = result.similarities.first { $0.category == .similarIntensity }
        XCTAssertNotNil(intensitySimilarity)
    }
    
    // MARK: - Difference Detection Tests
    
    func testFindEmotionDifference() async throws {
        let dreamA = createDream(emotions: [.快乐])
        let dreamB = createDream(emotions: [.焦虑])
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let emotionDifference = result.differences.first { $0.category == .emotionChange }
        XCTAssertNotNil(emotionDifference)
        XCTAssertEqual(emotionDifference?.dreamAValue, "快乐")
        XCTAssertEqual(emotionDifference?.dreamBValue, "焦虑")
    }
    
    func testFindClarityDifference() async throws {
        let dreamA = createDream(clarity: 5)
        let dreamB = createDream(clarity: 2)
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let clarityDifference = result.differences.first { $0.category == .clarityChange }
        XCTAssertNotNil(clarityDifference)
    }
    
    func testFindLucidDifference() async throws {
        let dreamA = createDream(isLucid: true)
        let dreamB = createDream(isLucid: false)
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        let lucidDifference = result.differences.first { $0.category == .lucidStatus }
        XCTAssertNotNil(lucidDifference)
        XCTAssertEqual(lucidDifference?.dreamAValue, "清醒梦")
        XCTAssertEqual(lucidDifference?.dreamBValue, "普通梦")
    }
    
    // MARK: - Statistics Tests
    
    func testGetComparisonStatistics() async throws {
        // 创建一些对比结果
        let result1 = DreamComparisonResult(
            dreamIds: [UUID(), UUID()],
            comparisonType: .twoDreams,
            similarities: [SimilarityCategory(category: .commonTags, items: ["标签"], confidence: 0.8)],
            differences: [],
            insights: [],
            similarityScore: 0.75
        )
        
        let result2 = DreamComparisonResult(
            dreamIds: [UUID(), UUID()],
            comparisonType: .twoDreams,
            similarities: [SimilarityCategory(category: .commonTags, items: ["标签"], confidence: 0.6)],
            differences: [],
            insights: [],
            similarityScore: 0.55
        )
        
        modelContainer.mainContext.insert(result1)
        modelContainer.mainContext.insert(result2)
        try? modelContainer.mainContext.save()
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let stats = await service.getComparisonStatistics()
        
        XCTAssertEqual(stats.totalComparisons, 2)
        XCTAssertEqual(stats.averageSimilarity, 0.65, accuracy: 0.01)
        XCTAssertEqual(stats.mostCommonSimilarity, .commonTags)
    }
    
    func testDeleteComparisonResult() async throws {
        let result = DreamComparisonResult(
            dreamIds: [UUID(), UUID()],
            comparisonType: .twoDreams,
            similarities: [],
            differences: [],
            insights: [],
            similarityScore: 0.5
        )
        
        modelContainer.mainContext.insert(result)
        try? modelContainer.mainContext.save()
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        await service.deleteComparisonResult(id: result.id)
        
        // 验证已删除
        let descriptor = FetchDescriptor<DreamComparisonResult>(
            predicate: #Predicate { $0.id == result.id }
        )
        let results = try? modelContainer.mainContext.fetch(descriptor)
        XCTAssertEqual(results?.count, 0)
    }
    
    // MARK: - Performance Tests
    
    func testComparisonPerformance() async throws {
        // 创建多个梦境
        var dreams: [Dream] = []
        for i in 0..<10 {
            let dream = createDream(
                title: "梦境 \(i)",
                tags: ["标签\(i % 3)"],
                emotions: i % 2 == 0 ? [.快乐] : [.焦虑],
                clarity: 3 + (i % 3),
                intensity: 3 + (i % 2)
            )
            dreams.append(dream)
        }
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        
        measure {
            let expectation = XCTestExpectation(description: "对比完成")
            
            Task {
                _ = try? await service.compareTwoDreams(dreamAId: dreams[0].id, dreamBId: dreams[1].id)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testEmptyTagsComparison() async throws {
        let dreamA = createDream(tags: [])
        let dreamB = createDream(tags: [])
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        let result = try await service.compareTwoDreams(dreamAId: dreamA.id, dreamBId: dreamB.id)
        
        // 不应该有共同标签相似性
        let commonTagsSimilarity = result.similarities.first { $0.category == .commonTags }
        XCTAssertNil(commonTagsSimilarity)
    }
    
    func testSingleDreamComparison() async {
        let dream = createDream()
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        
        do {
            _ = try await service.compareMultipleDreams(dreamIds: [dream.id])
            XCTFail("应该抛出错误")
        } catch ComparisonError.invalidDreamCount {
            // 预期错误
        } catch {
            XCTFail("抛出错误类型不正确")
        }
    }
    
    func testTooManyDreamsComparison() async {
        var dreamIds: [UUID] = []
        for _ in 0..<6 {
            let dream = createDream()
            dreamIds.append(dream.id)
        }
        
        let service = DreamComparisonService(modelContainer: modelContainer)
        
        do {
            _ = try await service.compareMultipleDreams(dreamIds: dreamIds)
            XCTFail("应该抛出错误")
        } catch ComparisonError.invalidDreamCount {
            // 预期错误
        } catch {
            XCTFail("抛出错误类型不正确")
        }
    }
}

// MARK: - Emotion Enum Mock

enum Emotion: String, Codable, CaseIterable {
    case 平静 = "平静"
    case 快乐 = "快乐"
    case 焦虑 = "焦虑"
    case 恐惧 = "恐惧"
    case 困惑 = "困惑"
    case 兴奋 = "兴奋"
    case 悲伤 = "悲伤"
    case 愤怒 = "愤怒"
    case 惊讶 = "惊讶"
    case 中性 = "中性"
}

// MARK: - Dream Model Mock

@Model
final class Dream {
    var id: UUID
    var title: String
    var content: String
    var tags: [String]
    var emotions: [Emotion]
    var clarity: Int
    var intensity: Int
    var isLucid: Bool
    var aiAnalysis: String?
    var date: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        tags: [String],
        emotions: [Emotion],
        clarity: Int,
        intensity: Int,
        isLucid: Bool,
        aiAnalysis: String?,
        date: Date
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.emotions = emotions
        self.clarity = clarity
        self.intensity = intensity
        self.isLucid = isLucid
        self.aiAnalysis = aiAnalysis
        self.date = date
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
