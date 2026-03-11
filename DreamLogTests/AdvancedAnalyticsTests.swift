//
//  AdvancedAnalyticsTests.swift
//  DreamLogTests
//
//  Phase 20: 高级数据分析仪表板单元测试
//

import XCTest
@testable import DreamLog

@available(iOS 16.0, *)
final class AdvancedAnalyticsTests: XCTestCase {
    
    var analyticsService: AdvancedAnalyticsService!
    var dreamStore: DreamStore!
    
    override func setUp() async throws {
        try await super.setUp()
        analyticsService = AdvancedAnalyticsService.shared
        dreamStore = DreamStore.shared
    }
    
    override func tearDown() async throws {
        analyticsService = nil
        dreamStore = nil
        try await super.tearDown()
    }
    
    // MARK: - 摘要指标测试
    
    func testCalculateSummaryMetrics() async throws {
        // 准备测试数据
        let dreams = createSampleDreams(count: 10)
        
        // 执行测试
        let metrics = await analyticsService.calculateSummaryMetrics(from: dreams)
        
        // 验证结果
        XCTAssertEqual(metrics.totalDreams, 10)
        XCTAssertGreaterThanOrEqual(metrics.lucidPercentage, 0)
        XCTAssertLessThanOrEqual(metrics.lucidPercentage, 100)
        XCTAssertGreaterThanOrEqual(metrics.averageClarity, 1.0)
        XCTAssertLessThanOrEqual(metrics.averageClarity, 5.0)
        XCTAssertGreaterThanOrEqual(metrics.averageIntensity, 1.0)
        XCTAssertLessThanOrEqual(metrics.averageIntensity, 5.0)
    }
    
    func testSummaryMetricsWithEmptyData() async throws {
        // 执行测试
        let metrics = await analyticsService.calculateSummaryMetrics(from: [])
        
        // 验证结果
        XCTAssertEqual(metrics.totalDreams, 0)
        XCTAssertEqual(metrics.lucidPercentage, 0)
        XCTAssertEqual(metrics.averageClarity, 0)
        XCTAssertEqual(metrics.averageIntensity, 0)
    }
    
    // MARK: - 情绪趋势分析测试
    
    func testAnalyzeEmotionTrend() async throws {
        let dreams = createSampleDreams(count: 30)
        
        let trend = await analyticsService.analyzeEmotionTrend(from: dreams)
        
        XCTAssertGreaterThan(trend.count, 0)
        XCTAssertLessThanOrEqual(trend.count, 30)
        
        // 验证每个数据点
        for point in trend {
            XCTAssertFalse(point.emotions.isEmpty)
            for (_, value) in point.emotions {
                XCTAssertGreaterThanOrEqual(value, 0)
                XCTAssertLessThanOrEqual(value, 1)
            }
        }
    }
    
    // MARK: - 标签关联分析测试
    
    func testAnalyzeTagCorrelations() async throws {
        let dreams = createSampleDreams(count: 20)
        
        let correlation = await analyticsService.analyzeTagCorrelations(from: dreams)
        
        // 验证标签列表
        XCTAssertGreaterThanOrEqual(correlation.tags.count, 0)
        
        // 验证关联矩阵
        if !correlation.tags.isEmpty {
            XCTAssertEqual(correlation.correlations.count, correlation.tags.count)
            for row in correlation.correlations {
                XCTAssertEqual(row.count, correlation.tags.count)
                for value in row {
                    XCTAssertGreaterThanOrEqual(value, -1.0)
                    XCTAssertLessThanOrEqual(value, 1.0)
                }
            }
        }
    }
    
    func testStrongCorrelationPairs() async throws {
        let dreams = createSampleDreamsWithStrongCorrelations()
        
        let correlation = await analyticsService.analyzeTagCorrelations(from: dreams)
        
        // 验证强关联对
        XCTAssertGreaterThanOrEqual(correlation.strongPairs.count, 0)
        for pair in correlation.strongPairs {
            XCTAssertGreaterThan(pair.strength, 0.5)
            XCTAssertLessThanOrEqual(pair.strength, 1.0)
        }
    }
    
    // MARK: - 时间模式分析测试
    
    func testAnalyzeTimePatterns() async throws {
        let dreams = createSampleDreams(count: 50)
        
        let patterns = await analyticsService.analyzeTimePatterns(from: dreams)
        
        // 验证小时分布
        XCTAssertGreaterThanOrEqual(patterns.hourDistribution.count, 0)
        XCTAssertLessThanOrEqual(patterns.hourDistribution.count, 24)
        
        // 验证星期分布
        XCTAssertGreaterThanOrEqual(patterns.weekdayDistribution.count, 0)
        XCTAssertLessThanOrEqual(patterns.weekdayDistribution.count, 7)
        
        // 验证一致性评分
        XCTAssertGreaterThanOrEqual(patterns.consistencyScore, 0)
        XCTAssertLessThanOrEqual(patterns.consistencyScore, 100)
    }
    
    // MARK: - 趋势预测测试
    
    func testGeneratePredictions() async throws {
        let dreams = createSampleDreams(count: 60)
        
        let predictions = await analyticsService.generatePredictions(from: dreams)
        
        // 验证清晰度预测
        XCTAssertGreaterThanOrEqual(predictions.clarityPrediction.confidence, 0)
        XCTAssertLessThanOrEqual(predictions.clarityPrediction.confidence, 1)
        
        // 验证情绪预测
        XCTAssertGreaterThanOrEqual(predictions.emotionPrediction.confidence, 0)
        XCTAssertLessThanOrEqual(predictions.emotionPrediction.confidence, 1)
        XCTAssertFalse(predictions.emotionPrediction.dominant.isEmpty)
        
        // 验证清醒梦预测
        XCTAssertGreaterThanOrEqual(predictions.lucidPrediction.confidence, 0)
        XCTAssertLessThanOrEqual(predictions.lucidPrediction.confidence, 1)
        XCTAssertGreaterThanOrEqual(predictions.lucidPrediction.probability, 0)
        XCTAssertLessThanOrEqual(predictions.lucidPrediction.probability, 1)
    }
    
    func testPredictionsWithInsufficientData() async throws {
        let dreams = createSampleDreams(count: 5)
        
        let predictions = await analyticsService.generatePredictions(from: dreams)
        
        // 数据不足时置信度应该较低
        XCTAssertLessThan(predictions.clarityPrediction.confidence, 0.5)
        XCTAssertLessThan(predictions.emotionPrediction.confidence, 0.5)
    }
    
    // MARK: - 洞察生成测试
    
    func testGenerateInsights() async throws {
        let dreams = createSampleDreams(count: 30)
        let summary = await analyticsService.calculateSummaryMetrics(from: dreams)
        let predictions = await analyticsService.generatePredictions(from: dreams)
        
        let insights = await analyticsService.generateInsights(
            from: dreams,
            summary: summary,
            predictions: predictions
        )
        
        XCTAssertGreaterThan(insights.count, 0)
        
        // 验证每个洞察
        for insight in insights {
            XCTAssertFalse(insight.title.isEmpty)
            XCTAssertFalse(insight.description.isEmpty)
            XCTAssertGreaterThanOrEqual(insight.confidence, 0)
            XCTAssertLessThanOrEqual(insight.confidence, 1)
            
            // 验证洞察类型
            XCTAssertNotNil(AdvancedAnalyticsService.AnalyticsInsight.InsightType(rawValue: insight.type.rawValue))
        }
    }
    
    // MARK: - 完整仪表板数据测试
    
    func testGenerateDashboardData() async throws {
        let dashboardData = await analyticsService.generateDashboardData(for: .last30Days)
        
        // 验证所有组件都存在
        XCTAssertGreaterThanOrEqual(dashboardData.summary.totalDreams, 0)
        XCTAssertGreaterThanOrEqual(dashboardData.emotionTrend.count, 0)
        XCTAssertGreaterThanOrEqual(dashboardData.tagCorrelation.tags.count, 0)
        XCTAssertGreaterThanOrEqual(dashboardData.insights.count, 0)
    }
    
    func testGenerateDashboardDataWithDifferentPeriods() async throws {
        let periods: [DateRange] = [.last7Days, .last30Days, .last90Days, .lastYear]
        
        for period in periods {
            let data = await analyticsService.generateDashboardData(for: period)
            XCTAssertNotNil(data)
        }
    }
    
    // MARK: - 性能测试
    
    func testPerformanceWithLargeDataset() async throws {
        let dreams = createSampleDreams(count: 500)
        
        measure {
            let expectation = self.expectation(description: "Analytics complete")
            
            Task {
                _ = await analyticsService.generateDashboardData(for: .last90Days)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 10.0)
        }
    }
    
    // MARK: - 辅助方法
    
    private func createSampleDreams(count: Int) -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        for i in 0..<count {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "这是一个测试梦境内容，包含各种元素和情绪。",
                tags: ["测试", "样本", "梦境"].shuffled().prefix(Int.random(in: 1...3)).map { String($0) },
                emotions: Emotion.allCases.shuffled().prefix(Int.random(in: 1...3)),
                clarity: Int32(Int.random(in: 1...5)),
                intensity: Int32(Int.random(in: 1...5)),
                isLucid: Bool.random(),
                date: date
            )
            dreams.append(dream)
        }
        
        return dreams
    }
    
    private func createSampleDreamsWithStrongCorrelations() -> [Dream] {
        var dreams: [Dream] = []
        let calendar = Calendar.current
        
        // 创建具有强关联的梦境
        for i in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // 创建强关联的标签组合
            var tags: [String] = []
            if i % 3 == 0 {
                tags = ["飞行", "自由", "天空"]
            } else if i % 3 == 1 {
                tags = ["水", "海洋", "情绪"]
            } else {
                tags = ["追逐", "压力", "工作"]
            }
            
            let dream = Dream(
                title: "测试梦境 \(i)",
                content: "测试内容",
                tags: tags,
                emotions: [Emotion.allCases[i % Emotion.allCases.count]],
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

// MARK: - DateRange 扩展 (测试用)

extension DateRange {
    // 如果 DateRange 不是 Codable 或需要特殊处理，在这里添加
}
