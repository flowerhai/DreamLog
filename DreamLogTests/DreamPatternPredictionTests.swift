//
//  DreamPatternPredictionTests.swift
//  DreamLogTests - Dream Pattern Prediction Unit Tests
//
//  Created by DreamLog AI on 2026/3/17.
//  Phase 55: Dream Pattern Prediction & Forecasting
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamPatternPredictionTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var predictionService: DreamPatternPredictionService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([
            Dream.self,
            DreamPatternPrediction.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = ModelContext(modelContainer)
        
        predictionService = DreamPatternPredictionService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        predictionService = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Data Quality Tests
    
    func testEvaluateDataQuality_Excellent() async throws {
        // Given: 50+ dreams
        try createSampleDreams(count: 55)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertEqual(response.dataQuality, .excellent)
    }
    
    func testEvaluateDataQuality_Good() async throws {
        // Given: 30-49 dreams
        try createSampleDreams(count: 35)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertEqual(response.dataQuality, .good)
    }
    
    func testEvaluateDataQuality_Fair() async throws {
        // Given: 15-29 dreams
        try createSampleDreams(count: 20)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertEqual(response.dataQuality, .fair)
    }
    
    func testEvaluateDataQuality_Poor() async throws {
        // Given: 7-14 dreams
        try createSampleDreams(count: 10)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertEqual(response.dataQuality, .poor)
    }
    
    func testEvaluateDataQuality_Insufficient() async throws {
        // Given: < 7 dreams
        try createSampleDreams(count: 5)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        
        // Then
        do {
            _ = try await predictionService.generatePrediction(request: request)
            XCTFail("Expected insufficientData error")
        } catch PredictionError.insufficientData {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Statistics Tests
    
    func testCalculateStatistics_BasicMetrics() async throws {
        // Given
        try createSampleDreams(count: 20)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertEqual(response.statistics.totalDreams, 20)
        XCTAssertGreaterThanOrEqual(response.statistics.averageClarity, 1)
        XCTAssertLessThanOrEqual(response.statistics.averageClarity, 5)
        XCTAssertGreaterThanOrEqual(response.statistics.lucidDreamPercentage, 0)
        XCTAssertLessThanOrEqual(response.statistics.lucidDreamPercentage, 100)
    }
    
    func testCalculateStatistics_EmotionCounts() async throws {
        // Given
        try createSampleDreamsWithEmotions()
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertFalse(response.statistics.mostCommonEmotions.isEmpty)
    }
    
    func testCalculateStatistics_TagCounts() async throws {
        // Given
        try createSampleDreamsWithTags()
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertFalse(response.statistics.mostCommonTags.isEmpty)
    }
    
    func testCalculateRecordingStreak() async throws {
        // Given: Dreams on consecutive days
        let calendar = Calendar.current
        let today = Date()
        
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dream = Dream(
                title: "Test Dream \(dayOffset)",
                content: "Test content",
                tags: ["test"],
                emotions: [.calm],
                clarity: 3,
                intensity: 3,
                isLucid: false,
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertEqual(response.statistics.recordingStreak, 7)
    }
    
    // MARK: - Prediction Tests
    
    func testGenerateThemePrediction() async throws {
        // Given
        try createSampleDreamsWithTags()
        
        // When
        let request = PredictionRequest(
            timeRange: .next7days,
            predictionTypes: [.theme]
        )
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let themePredictions = response.prediction.predictions.filter { $0.type == .theme }
        XCTAssertFalse(themePredictions.isEmpty)
        
        for prediction in themePredictions {
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1)
            XCTAssertFalse(prediction.value.isEmpty)
        }
    }
    
    func testGenerateEmotionPrediction() async throws {
        // Given
        try createSampleDreamsWithEmotions()
        
        // When
        let request = PredictionRequest(
            timeRange: .next7days,
            predictionTypes: [.emotion]
        )
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let emotionPredictions = response.prediction.predictions.filter { $0.type == .emotion }
        XCTAssertFalse(emotionPredictions.isEmpty)
        
        for prediction in emotionPredictions {
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1)
        }
    }
    
    func testGenerateClarityPrediction() async throws {
        // Given
        try createSampleDreams(count: 20)
        
        // When
        let request = PredictionRequest(
            timeRange: .next7days,
            predictionTypes: [.clarity]
        )
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let clarityPredictions = response.prediction.predictions.filter { $0.type == .clarity }
        XCTAssertEqual(clarityPredictions.count, 7) // 7 days
        
        for prediction in clarityPredictions {
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1)
            XCTAssertTrue(prediction.value.contains("/5"))
        }
    }
    
    func testGenerateLucidPrediction() async throws {
        // Given
        try createSampleDreams(count: 20)
        
        // When
        let request = PredictionRequest(
            timeRange: .next7days,
            predictionTypes: [.lucid]
        )
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let lucidPredictions = response.prediction.predictions.filter { $0.type == .lucid }
        XCTAssertFalse(lucidPredictions.isEmpty)
    }
    
    func testGenerateMultiplePredictionTypes() async throws {
        // Given
        try createSampleDreamsWithTags()
        
        // When
        let request = PredictionRequest(
            timeRange: .next3days,
            predictionTypes: [.theme, .emotion, .clarity]
        )
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let predictionCount = response.prediction.predictions.count
        XCTAssertEqual(predictionCount, 9) // 3 types × 3 days
    }
    
    // MARK: - Insights Tests
    
    func testGenerateInsights_WithSufficientData() async throws {
        // Given: Dreams with good streak
        try createSampleDreams(count: 30)
        
        // When
        let request = PredictionRequest(
            timeRange: .next7days,
            includeInsights: true
        )
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        XCTAssertFalse(response.prediction.insights.isEmpty)
    }
    
    func testGenerateInsights_WithHighLucidPercentage() async throws {
        // Given: Dreams with high lucid percentage
        let calendar = Calendar.current
        for i in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dream = Dream(
                title: "Lucid Dream \(i)",
                content: "I knew I was dreaming",
                tags: ["lucid"],
                emotions: [.excited],
                clarity: 4,
                intensity: 4,
                isLucid: true, // All lucid
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let lucidInsights = response.prediction.insights.filter { $0.type == .opportunity }
        XCTAssertFalse(lucidInsights.isEmpty)
    }
    
    // MARK: - Suggestions Tests
    
    func testGenerateSuggestions_WithLowClarity() async throws {
        // Given: Dreams with low clarity
        let calendar = Calendar.current
        for i in 0..<15 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dream = Dream(
                title: "Blurry Dream \(i)",
                content: "Can't remember well",
                tags: ["blurry"],
                emotions: [.confused],
                clarity: 1, // Very low
                intensity: 2,
                isLucid: false,
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let recordingSuggestions = response.prediction.suggestions.filter { $0.type == .recording }
        XCTAssertFalse(recordingSuggestions.isEmpty)
    }
    
    func testGenerateSuggestions_WithLowLucidPercentage() async throws {
        // Given: Dreams with no lucid dreams
        try createSampleDreams(count: 20)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let lucidSuggestions = response.prediction.suggestions.filter { $0.type == .lucid }
        XCTAssertFalse(lucidSuggestions.isEmpty)
    }
    
    // MARK: - Pattern Detection Tests
    
    func testDetectRecurringPatterns() async throws {
        // Given: Dreams with recurring tag patterns
        let calendar = Calendar.current
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dream = Dream(
                title: "Pattern Dream \(i)",
                content: "Dream with recurring pattern",
                tags: ["flying", "freedom"], // Recurring pattern
                emotions: [.excited],
                clarity: 4,
                intensity: 4,
                isLucid: i % 2 == 0,
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        let patternPredictions = response.prediction.predictions.filter { $0.type == .pattern }
        XCTAssertFalse(patternPredictions.isEmpty)
    }
    
    // MARK: - Time Range Tests
    
    func testPredictionTimeRanges() async throws {
        // Given
        try createSampleDreams(count: 30)
        
        // When & Then
        for timeRange in PredictionTimeRange.allCases {
            let request = PredictionRequest(timeRange: timeRange)
            let response = try await predictionService.generatePrediction(request: request)
            
            // Should have predictions for each day in range
            let expectedPredictions = timeRange.days * 4 // 4 prediction types
            XCTAssertEqual(response.prediction.predictions.count, expectedPredictions)
        }
    }
    
    // MARK: - Confidence Tests
    
    func testPredictionConfidence_Range() async throws {
        // Given
        try createSampleDreams(count: 50)
        
        // When
        let request = PredictionRequest(timeRange: .next7days)
        let response = try await predictionService.generatePrediction(request: request)
        
        // Then
        for prediction in response.prediction.predictions {
            XCTAssertGreaterThanOrEqual(prediction.confidence, 0)
            XCTAssertLessThanOrEqual(prediction.confidence, 1)
        }
    }
    
    func testPredictionConfidence_MoreDataHigherConfidence() async throws {
        // Given: Small dataset
        try createSampleDreams(count: 10)
        let request = PredictionRequest(timeRange: .next7days)
        let smallResponse = try await predictionService.generatePrediction(request: request)
        
        // Clear and create larger dataset
        try modelContext.delete(model: Dream.self)
        try createSampleDreams(count: 50)
        let largeResponse = try await predictionService.generatePrediction(request: request)
        
        // Then: Larger dataset should have higher or equal confidence
        let smallAvgConfidence = smallResponse.prediction.predictions.map { $0.confidence }.reduce(0, +) / Double(smallResponse.prediction.predictions.count)
        let largeAvgConfidence = largeResponse.prediction.predictions.map { $0.confidence }.reduce(0, +) / Double(largeResponse.prediction.predictions.count)
        
        XCTAssertGreaterThanOrEqual(largeAvgConfidence, smallAvgConfidence)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleDreams(count: Int) throws {
        let calendar = Calendar.current
        let emotions: [DreamEmotion] = [.calm, .happy, .anxious, .fearful, .confused, .excited]
        
        for i in 0..<count {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dream = Dream(
                title: "Test Dream \(i)",
                content: "This is a test dream content for prediction testing. " +
                        "It contains enough text to simulate a real dream record. " +
                        "The dream was vivid and memorable.",
                tags: ["test", "sample", "prediction"].shuffled().prefix(Int.random(in: 1...3)).map { String($0) },
                emotions: [emotions.randomElement()!],
                clarity: Int.random(in: 1...5),
                intensity: Int.random(in: 1...5),
                isLucid: Bool.random(),
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
    }
    
    private func createSampleDreamsWithEmotions() throws {
        let calendar = Calendar.current
        let emotions: [DreamEmotion] = [.calm, .happy, .anxious]
        
        for i in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let dream = Dream(
                title: "Emotion Dream \(i)",
                content: "Dream with specific emotions",
                tags: ["emotion"],
                emotions: [emotions[i % emotions.count]],
                clarity: 3,
                intensity: 3,
                isLucid: false,
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
    }
    
    private func createSampleDreamsWithTags() throws {
        let calendar = Calendar.current
        let tagSets = [
            ["flying", "freedom", "sky"],
            ["water", "ocean", "swimming"],
            ["chase", "running", "fear"]
        ]
        
        for i in 0..<20 {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            let tags = tagSets[i % tagSets.count]
            let dream = Dream(
                title: "Tag Dream \(i)",
                content: "Dream with specific tags: \(tags.joined(separator: ", "))",
                tags: tags,
                emotions: [.calm],
                clarity: 3,
                intensity: 3,
                isLucid: false,
                createdAt: date
            )
            modelContext.insert(dream)
        }
        try modelContext.save()
    }
}

// MARK: - PredictionType Tests

@available(iOS 17.0, *)
extension DreamPatternPredictionTests {
    
    func testPredictionType_DisplayNames() {
        // Test all prediction types have display names
        for type in PredictionType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.icon.isEmpty)
        }
    }
    
    func testPredictionTimeRange_Days() {
        // Test time range day calculations
        XCTAssertEqual(PredictionTimeRange.next24h.days, 1)
        XCTAssertEqual(PredictionTimeRange.next3days.days, 3)
        XCTAssertEqual(PredictionTimeRange.next7days.days, 7)
        XCTAssertEqual(PredictionTimeRange.next14days.days, 14)
        XCTAssertEqual(PredictionTimeRange.next30days.days, 30)
    }
    
    func testDataQualityScore_MinDreams() {
        // Test data quality minimum dreams
        XCTAssertEqual(DataQualityScore.excellent.minDreams, 50)
        XCTAssertEqual(DataQualityScore.good.minDreams, 30)
        XCTAssertEqual(DataQualityScore.fair.minDreams, 15)
        XCTAssertEqual(DataQualityScore.poor.minDreams, 7)
        XCTAssertEqual(DataQualityScore.insufficient.minDreams, 0)
    }
    
    func testTrendDirection_Icons() {
        // Test trend direction icons
        for trend in TrendDirection.allCases {
            XCTAssertFalse(trend.icon.isEmpty)
            XCTAssertFalse(trend.displayName.isEmpty)
        }
    }
    
    func testInsightType_Icons() {
        // Test insight type icons
        for type in InsightType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
    
    func testSuggestionType_Icons() {
        // Test suggestion type icons
        for type in SuggestionType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }
}
