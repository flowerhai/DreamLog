//
//  DreamCorrelationTests.swift
//  DreamLogTests
//
//  Phase 20: 梦境关联服务单元测试
//

import XCTest
@testable import DreamLog

@available(iOS 16.0, *)
final class DreamCorrelationTests: XCTestCase {
    
    var correlationService: DreamCorrelationService!
    
    override func setUp() async throws {
        try await super.setUp()
        correlationService = DreamCorrelationService.shared
    }
    
    override func tearDown() async throws {
        correlationService = nil
        try await super.tearDown()
    }
    
    // MARK: - 标签关联测试
    
    func testCalculateTagCorrelations() async throws {
        let dreams = createSampleDreams(count: 30)
        
        let correlations = await correlationService.calculateTagCorrelations(from: dreams)
        
        // 验证关联矩阵
        XCTAssertGreaterThanOrEqual(correlations.tags.count, 0)
        
        if !correlations.tags.isEmpty {
            // 矩阵应该是方阵
            XCTAssertEqual(correlations.correlations.count, correlations.tags.count)
            for row in correlations.correlations {
                XCTAssertEqual(row.count, correlations.tags.count)
            }
            
            // 对角线应该是 1.0 (自相关)
            for i in 0..<min(correlations.tags.count, correlations.correlations.count) {
                XCTAssertEqual(correlations.correlations[i][i], 1.0, accuracy: 0.01)
            }
            
            // 矩阵应该是对称的
            for i in 0..<correlations.correlations.count {
                for j in 0..<correlations.correlations[i].count {
                    XCTAssertEqual(
                        correlations.correlations[i][j],
                        correlations.correlations[j][i],
                        accuracy: 0.01
                    )
                }
            }
        }
    }
    
    func testTagCorrelationsWithEmptyData() async throws {
        let correlations = await correlationService.calculateTagCorrelations(from: [])
        
        XCTAssertEqual(correlations.tags.count, 0)
        XCTAssertEqual(correlations.correlations.count, 0)
        XCTAssertEqual(correlations.strongPairs.count, 0)
    }
    
    func testTagCorrelationsWithSingleTag() async throws {
        let dreams = createDreamsWithSingleTag()
        let correlations = await correlationService.calculateTagCorrelations(from: dreams)
        
        XCTAssertEqual(correlations.tags.count, 1)
        XCTAssertEqual(correlations.correlations.count, 1)
        XCTAssertEqual(correlations.correlations[0][0], 1.0, accuracy: 0.01)
    }
    
    // MARK: - 强关联对测试
    
    func testFindStrongCorrelationPairs() async throws {
        let dreams = createDreamsWithStrongCorrelations()
        let correlations = await correlationService.calculateTagCorrelations(from: dreams)
        
        // 应该找到强关联对
        XCTAssertGreaterThan(correlations.strongPairs.count, 0)
        
        // 验证强关联对的强度
        for pair in correlations.strongPairs {
            XCTAssertGreaterThan(pair.strength, 0.5)
            XCTAssertLessThanOrEqual(pair.strength, 1.0)
            XCTAssertFalse(pair.tag1.isEmpty)
            XCTAssertFalse(pair.tag2.isEmpty)
        }
    }
    
    // MARK: - 情绪 - 标签关联测试
    
    func testAnalyzeEmotionTagCorrelations() async throws {
        let dreams = createSampleDreams(count: 40)
        
        let emotionTagCorr = await correlationService.analyzeEmotionTagCorrelations(from: dreams)
        
        XCTAssertGreaterThan(emotionTagCorr.count, 0)
        
        for corr in emotionTagCorr {
            XCTAssertFalse(corr.emotion.rawValue.isEmpty)
            XCTAssertFalse(corr.tags.isEmpty)
            XCTAssertGreaterThanOrEqual(corr.strength, 0)
            XCTAssertLessThanOrEqual(corr.strength, 1)
        }
    }
    
    // MARK: - 时间 - 主题关联测试
    
    func testAnalyzeTimeThemeCorrelations() async throws {
        let dreams = createSampleDreams(count: 50)
        
        let timeThemeCorr = await correlationService.analyzeTimeThemeCorrelations(from: dreams)
        
        XCTAssertGreaterThan(timeThemeCorr.count, 0)
        
        for corr in timeThemeCorr {
            XCTAssertGreaterThanOrEqual(corr.hour, 0)
            XCTAssertLessThan(corr.hour, 24)
            XCTAssertFalse(corr.themes.isEmpty)
            XCTAssertGreaterThanOrEqual(corr.frequency, 0)
        }
    }
    
    // MARK: - 星期模式测试
    
    func testAnalyzeWeekdayPatterns() async throws {
        let dreams = createSampleDreams(count: 70)
        
        let patterns = await correlationService.analyzeWeekdayPatterns(from: dreams)
        
        XCTAssertGreaterThan(patterns.count, 0)
        
        for pattern in patterns {
            XCTAssertGreaterThanOrEqual(pattern.weekday, 0)
            XCTAssertLessThan(pattern.weekday, 7)
            XCTAssertGreaterThanOrEqual(pattern.dreamCount, 0)
            XCTAssertFalse(pattern.commonThemes.isEmpty)
        }
    }
    
    // MARK: - 完整关联报告测试
    
    func testGenerateCorrelationReport() async throws {
        let dreams = createSampleDreams(count: 50)
        
        let report = await correlationService.generateCorrelationReport(from: dreams)
        
        // 验证报告完整性
        XCTAssertNotNil(report)
        XCTAssertEqual(report.totalDreams, dreams.count)
        XCTAssertGreaterThanOrEqual(report.tagCorrelations.tags.count, 0)
        XCTAssertGreaterThanOrEqual(report.emotionTagCorrelations.count, 0)
        XCTAssertGreaterThanOrEqual(report.timeThemeCorrelations.count, 0)
        XCTAssertGreaterThanOrEqual(report.weekdayPatterns.count, 0)
        XCTAssertGreaterThanOrEqual(report.insights.count, 0)
        
        // 验证洞察
        for insight in report.insights {
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.confidence, 0)
            XCTAssertLessThanOrEqual(insight.confidence, 1)
        }
    }
    
    func testGenerateCorrelationReportWithEmptyData() async throws {
        let report = await correlationService.generateCorrelationReport(from: [])
        
        XCTAssertEqual(report.totalDreams, 0)
        XCTAssertEqual(report.tagCorrelations.tags.count, 0)
        XCTAssertEqual(report.emotionTagCorrelations.count, 0)
        XCTAssertEqual(report.timeThemeCorrelations.count, 0)
        XCTAssertEqual(report.weekdayPatterns.count, 0)
    }
    
    // MARK: - 关联类型测试
    
    func testCorrelationTypeCases() async throws {
        // 测试所有关联类型
        let allTypes: [DreamCorrelationService.CorrelationType] = [
            .tagTag,
            .emotionTag,
            .timeTheme,
            .weekdayPattern,
            .clarityEmotion,
            .lucidPattern
        ]
        
        for type in allTypes {
            XCTAssertFalse(type.rawValue.isEmpty)
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
    
    // MARK: - 性能测试
    
    func testPerformanceWithLargeDataset() async throws {
        let dreams = createSampleDreams(count: 200)
        
        measure {
            let expectation = self.expectation(description: "Correlation analysis complete")
            
            Task {
                _ = await correlationService.generateCorrelationReport(from: dreams)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 15.0)
        }
    }
    
    // MARK: - 辅助方法
    
    private func createSampleDreams(count: Int) -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        let allTags = ["飞行", "水", "追逐", "房子", "门", "自由", "压力", "工作", "家庭", "朋友"]
        let allEmotions = Emotion.allCases
        
        for i in 0..<count {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let hour = Int.random(in: 0...23)
            let adjustedDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
            
            let tags = allTags.shuffled().prefix(Int.random(in: 2...4)).map { String($0) }
            let emotions = allEmotions.shuffled().prefix(Int.random(in: 1...3))
            
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "这是一个测试梦境内容。",
                tags: tags,
                emotions: emotions,
                clarity: Int32(Int.random(in: 1...5)),
                intensity: Int32(Int.random(in: 1...5)),
                isLucid: Bool.random(),
                date: adjustedDate
            )
            dreams.append(dream)
        }
        
        return dreams
    }
    
    private func createDreamsWithSingleTag() -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "测试内容",
                tags: ["唯一标签"],
                emotions: [.neutral],
                clarity: 3,
                intensity: 3,
                isLucid: false,
                date: date
            )
            dreams.append(dream)
        }
        
        return dreams
    }
    
    private func createDreamsWithStrongCorrelations() -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // 创建强关联的标签组合
            var tags: [String] = []
            if i % 3 == 0 {
                tags = ["飞行", "自由", "天空", "快乐"]
            } else if i % 3 == 1 {
                tags = ["水", "海洋", "情绪", "平静"]
            } else {
                tags = ["追逐", "压力", "工作", "焦虑"]
            }
            
            let emotions: [Emotion]
            if i % 3 == 0 {
                emotions = [.happy, .excited]
            } else if i % 3 == 1 {
                emotions = [.calm, .neutral]
            } else {
                emotions = [.anxious, .fearful]
            }
            
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "测试内容",
                tags: tags,
                emotions: emotions,
                clarity: Int32(3),
                intensity: Int32(3),
                isLucid: i % 2 == 0,
                date: date
            )
            dreams.append(dream)
        }
        
        return dreams
    }
}
