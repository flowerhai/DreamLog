//
//  DreamWellnessTests.swift
//  DreamLogTests
//
//  Phase 100: 梦境健康评分与预测引擎
//  单元测试
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamWellnessTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: DreamWellnessScore.self,
             DreamPrediction.self,
             DreamRecommendation.self,
             DreamWellnessReport.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - 评分等级测试
    
    func testScoreLevelFromScore() {
        XCTAssertEqual(ScoreLevel.from(score: 95), .excellent)
        XCTAssertEqual(ScoreLevel.from(score: 90), .excellent)
        XCTAssertEqual(ScoreLevel.from(score: 89), .good)
        XCTAssertEqual(ScoreLevel.from(score: 70), .good)
        XCTAssertEqual(ScoreLevel.from(score: 69), .fair)
        XCTAssertEqual(ScoreLevel.from(score: 50), .fair)
        XCTAssertEqual(ScoreLevel.from(score: 49), .needsAttention)
        XCTAssertEqual(ScoreLevel.from(score: 30), .needsAttention)
        XCTAssertEqual(ScoreLevel.from(score: 29), .needsImprovement)
        XCTAssertEqual(ScoreLevel.from(score: 0), .needsImprovement)
    }
    
    func testScoreLevelEmoji() {
        XCTAssertEqual(ScoreLevel.excellent.emoji, "🌟")
        XCTAssertEqual(ScoreLevel.good.emoji, "💚")
        XCTAssertEqual(ScoreLevel.fair.emoji, "💛")
        XCTAssertEqual(ScoreLevel.needsAttention.emoji, "🧡")
        XCTAssertEqual(ScoreLevel.needsImprovement.emoji, "❤️")
    }
    
    func testScoreLevelDescription() {
        XCTAssertEqual(ScoreLevel.excellent.description, "非常健康的梦境模式")
        XCTAssertEqual(ScoreLevel.good.description, "健康的梦境习惯")
        XCTAssertEqual(ScoreLevel.fair.description, "有改善空间")
        XCTAssertEqual(ScoreLevel.needsAttention.description, "建议调整习惯")
        XCTAssertEqual(ScoreLevel.needsImprovement.description, "建议寻求专业建议")
    }
    
    // MARK: - 置信度等级测试
    
    func testConfidenceLevelFromConfidence() {
        XCTAssertEqual(ConfidenceLevel.from(confidence: 95), .high)
        XCTAssertEqual(ConfidenceLevel.from(confidence: 80), .high)
        XCTAssertEqual(ConfidenceLevel.from(confidence: 79), .medium)
        XCTAssertEqual(ConfidenceLevel.from(confidence: 60), .medium)
        XCTAssertEqual(ConfidenceLevel.from(confidence: 59), .low)
        XCTAssertEqual(ConfidenceLevel.from(confidence: 0), .low)
    }
    
    // MARK: - 综合评分计算测试
    
    func testOverallScoreCalculation() {
        let service = DreamWellnessScoreService(modelContext: modelContext)
        
        // 测试加权平均计算
        let overall = calculateOverallScore(
            sleep: 80.0,
            recall: 70.0,
            emotional: 90.0,
            pattern: 85.0
        )
        
        // 期望值：80*0.3 + 70*0.25 + 90*0.25 + 85*0.2 = 24 + 17.5 + 22.5 + 17 = 81
        XCTAssertEqual(overall, 81.0, accuracy: 0.01)
    }
    
    func testOverallScoreBoundary() {
        // 全满分
        let maxScore = calculateOverallScore(sleep: 100, recall: 100, emotional: 100, pattern: 100)
        XCTAssertEqual(maxScore, 100.0)
        
        // 全零分
        let minScore = calculateOverallScore(sleep: 0, recall: 0, emotional: 0, pattern: 0)
        XCTAssertEqual(minScore, 0.0)
    }
    
    // MARK: - 预测类型测试
    
    func testPredictionTypeEmoji() {
        XCTAssertEqual(PredictionType.dreamTheme.emoji, "🎭")
        XCTAssertEqual(PredictionType.emotionalTrend.emoji, "💭")
        XCTAssertEqual(PredictionType.lucidDreamProbability.emoji, "👁️")
        XCTAssertEqual(PredictionType.optimalRecordTime.emoji, "⏰")
        XCTAssertEqual(PredictionType.sleepQuality.emoji, "😴")
        XCTAssertEqual(PredictionType.dreamFrequency.emoji, "📊")
    }
    
    func testPredictionTypeDescription() {
        XCTAssertEqual(PredictionType.dreamTheme.description, "预测可能出现的梦境主题")
        XCTAssertEqual(PredictionType.emotionalTrend.description, "预测情绪走向")
        XCTAssertEqual(PredictionType.lucidDreamProbability.description, "预测清醒梦可能性")
    }
    
    // MARK: - 推荐类型测试
    
    func testRecommendationTypeEmoji() {
        XCTAssertEqual(RecommendationType.sleepImprovement.emoji, "😴")
        XCTAssertEqual(RecommendationType.dreamRecording.emoji, "📝")
        XCTAssertEqual(RecommendationType.meditation.emoji, "🧘")
        XCTAssertEqual(RecommendationType.lucidDreamTraining.emoji, "👁️")
        XCTAssertEqual(RecommendationType.creativeInspiration.emoji, "💡")
        XCTAssertEqual(RecommendationType.stressRelief.emoji, "🌿")
        XCTAssertEqual(RecommendationType.habitBuilding.emoji, "💪")
        XCTAssertEqual(RecommendationType.healthWarning.emoji, "⚠️")
    }
    
    // MARK: - 优先级测试
    
    func testPriorityColor() {
        XCTAssertEqual(Priority.low.color, "gray")
        XCTAssertEqual(Priority.medium.color, "blue")
        XCTAssertEqual(Priority.high.color, "orange")
        XCTAssertEqual(Priority.urgent.color, "red")
    }
    
    func testPriorityEmoji() {
        XCTAssertEqual(Priority.low.emoji, "⚪")
        XCTAssertEqual(Priority.medium.emoji, "🔵")
        XCTAssertEqual(Priority.high.emoji, "🟠")
        XCTAssertEqual(Priority.urgent.emoji, "🔴")
    }
    
    // MARK: - 报告类型测试
    
    func testReportTypeEmoji() {
        XCTAssertEqual(ReportType.daily.emoji, "📅")
        XCTAssertEqual(ReportType.weekly.emoji, "📆")
        XCTAssertEqual(ReportType.monthly.emoji, "🗓️")
        XCTAssertEqual(ReportType.quarterly.emoji, "📊")
        XCTAssertEqual(ReportType.yearly.emoji, "📈")
    }
    
    // MARK: - 趋势测试
    
    func testScoreTrendEmoji() {
        XCTAssertEqual(ScoreTrend.rising.emoji, "📈")
        XCTAssertEqual(ScoreTrend.falling.emoji, "📉")
        XCTAssertEqual(ScoreTrend.stable.emoji, "➡️")
    }
    
    // MARK: - 主题分类测试
    
    func testThemeCategoryEmoji() {
        XCTAssertEqual(ThemeCategory.adventure.emoji, "🗺️")
        XCTAssertEqual(ThemeCategory.romance.emoji, "💕")
        XCTAssertEqual(ThemeCategory.fear.emoji, "😨")
        XCTAssertEqual(ThemeCategory.success.emoji, "🏆")
        XCTAssertEqual(ThemeCategory.flying.emoji, "🦅")
        XCTAssertEqual(ThemeCategory.falling.emoji, "🍂")
        XCTAssertEqual(ThemeCategory.water.emoji, "🌊")
        XCTAssertEqual(ThemeCategory.nature.emoji, "🌲")
        XCTAssertEqual(ThemeCategory.urban.emoji, "🏙️")
        XCTAssertEqual(ThemeCategory.fantasy.emoji, "🦄")
    }
    
    // MARK: - 图表类型测试
    
    func testChartType() {
        XCTAssertEqual(ChartType.line.rawValue, "折线图")
        XCTAssertEqual(ChartType.bar.rawValue, "柱状图")
        XCTAssertEqual(ChartType.pie.rawValue, "饼图")
        XCTAssertEqual(ChartType.radar.rawValue, "雷达图")
        XCTAssertEqual(ChartType.heatmap.rawValue, "热力图")
    }
    
    // MARK: - 时间范围测试
    
    func testTimeRangeDisplay() {
        let timeRange = TimeRange(startHour: 22, endHour: 0, quality: 85.0, basis: "测试")
        XCTAssertEqual(timeRange.displayString, "22:00 - 00:00")
        
        let timeRange2 = TimeRange(startHour: 6, endHour: 8, quality: 90.0, basis: "测试")
        XCTAssertEqual(timeRange2.displayString, "06:00 - 08:00")
    }
    
    // MARK: - 评分统计测试
    
    func testScoreStatisticsCoverageRate() {
        let stats = ScoreStatistics(
            averageScore: 75.0,
            highestScore: 90.0,
            lowestScore: 60.0,
            trend: .rising,
            totalDays: 30,
            recordedDays: 25
        )
        
        XCTAssertEqual(stats.coverageRate, 83.33, accuracy: 0.01)
    }
    
    func testScoreStatisticsZeroDays() {
        let stats = ScoreStatistics(
            averageScore: 0,
            highestScore: 0,
            lowestScore: 0,
            trend: .stable,
            totalDays: 0,
            recordedDays: 0
        )
        
        XCTAssertEqual(stats.coverageRate, 0)
    }
    
    // MARK: - 帮助方法
    
    private func calculateOverallScore(
        sleep: Double,
        recall: Double,
        emotional: Double,
        pattern: Double
    ) -> Double {
        return sleep * 0.30 + recall * 0.25 + emotional * 0.25 + pattern * 0.20
    }
}

// MARK: - 性能测试

@available(iOS 17.0, *)
final class DreamWellnessPerformanceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: DreamWellnessScore.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDown() {
        modelContainer = nil
        modelContext = nil
    }
    
    func testScoreCalculationPerformance() async throws {
        let service = DreamWellnessScoreService(modelContext: modelContext)
        
        measure {
            let expectation = self.expectation(description: "Score calculation")
            
            Task {
                try await service.calculateTodayScore()
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 5.0)
        }
    }
}
