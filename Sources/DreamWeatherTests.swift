//
//  DreamWeatherTests.swift
//  DreamLogTests
//
//  Phase 66: Dream Weather & Environmental Correlation Tests
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamWeatherTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamWeatherService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container
        let schema = Schema([
            Dream.self,
            DreamWeatherData.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // Initialize service
        service = DreamWeatherService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Weather Data Management Tests
    
    func testSaveAndRetrieveWeatherData() async throws {
        let testDate = Date()
        let weatherData = DreamWeatherData(
            date: testDate,
            temperature: 25.5,
            condition: .clear,
            humidity: 60.0,
            pressure: 1013.25,
            moonPhase: .fullMoon,
            moonIllumination: 100.0
        )
        
        try await service.saveWeatherData(weatherData)
        
        let retrieved = try await service.getWeatherData(for: testDate)
        
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.temperature, 25.5)
        XCTAssertEqual(retrieved?.condition, .clear)
        XCTAssertEqual(retrieved?.humidity, 60.0)
        XCTAssertEqual(retrieved?.moonPhase, .fullMoon)
    }
    
    func testUpdateExistingWeatherData() async throws {
        let testDate = Date()
        
        // Save initial data
        let initialWeather = DreamWeatherData(
            date: testDate,
            temperature: 20.0,
            condition: .cloudy
        )
        try await service.saveWeatherData(initialWeather)
        
        // Update with new data
        let updatedWeather = DreamWeatherData(
            date: testDate,
            temperature: 25.0,
            condition: .clear,
            humidity: 50.0
        )
        try await service.saveWeatherData(updatedWeather)
        
        let retrieved = try await service.getWeatherData(for: testDate)
        
        XCTAssertEqual(retrieved?.temperature, 25.0)
        XCTAssertEqual(retrieved?.condition, .clear)
        XCTAssertEqual(retrieved?.humidity, 50.0)
    }
    
    func testDeleteWeatherData() async throws {
        let testDate = Date()
        let weatherData = DreamWeatherData(date: testDate, temperature: 20.0)
        
        try await service.saveWeatherData(weatherData)
        try await service.deleteWeatherData(for: testDate)
        
        let retrieved = try await service.getWeatherData(for: testDate)
        XCTAssertNil(retrieved)
    }
    
    func testGetWeatherDataForDateRange() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create weather data for multiple dates
        for day in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            let weather = DreamWeatherData(
                date: date,
                temperature: Double(20 + day),
                condition: .clear
            )
            try await service.saveWeatherData(weather)
        }
        
        let startDate = calendar.date(byAdding: .day, value: -5, to: now)!
        let endDate = now
        let weatherData = try await service.getWeatherData(for: startDate...endDate)
        
        XCTAssertEqual(weatherData.count, 5)
    }
    
    // MARK: - Correlation Analysis Tests
    
    func testWeatherCorrelationAnalysis() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create dreams and weather data for clear days
        for day in 0..<9 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            
            // Save weather
            let weather = DreamWeatherData(
                date: date,
                temperature: 25.0,
                condition: .clear
            )
            try await service.saveWeatherData(weather)
            
            // Create dreams
            for _ in 0..<2 {
                let dream = Dream(
                    title: "Clear Day Dream",
                    content: "A beautiful dream on a clear day",
                    date: date,
                    clarity: 5,
                    intensity: 4,
                    isLucid: true
                )
                dream.tags = ["flying", "nature"]
                dream.emotions = [.joy]
                modelContext.insert(dream)
            }
        }
        
        try modelContext.save()
        
        let startDate = calendar.date(byAdding: .day, value: -10, to: now)!
        let correlations = try await service.analyzeWeatherCorrelations(dateRange: startDate...now)
        
        XCTAssertFalse(correlations.isEmpty)
        let clearCorrelation = correlations.first { $0.weatherCondition == .clear }
        XCTAssertNotNil(clearCorrelation)
        XCTAssertEqual(clearCorrelation?.dreamCount, 18)
        XCTAssertGreaterThan(clearCorrelation?.lucidDreamRate ?? 0, 0.5)
    }
    
    func testMoonCorrelationAnalysis() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create dreams and weather data for full moon
        for day in 0..<4 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            
            let weather = DreamWeatherData(
                date: date,
                temperature: 20.0,
                moonPhase: .fullMoon,
                moonIllumination: 100.0
            )
            try await service.saveWeatherData(weather)
            
            // Create dreams with high lucid rate
            for _ in 0..<3 {
                let dream = Dream(
                    title: "Full Moon Dream",
                    content: "Dream during full moon",
                    date: date,
                    clarity: 4,
                    intensity: 5,
                    isLucid: true
                )
                modelContext.insert(dream)
            }
        }
        
        try modelContext.save()
        
        let startDate = calendar.date(byAdding: .day, value: -10, to: now)!
        let correlations = try await service.analyzeMoonCorrelations(dateRange: startDate...now)
        
        XCTAssertFalse(correlations.isEmpty)
        let fullMoonCorrelation = correlations.first { $0.moonPhase == .fullMoon }
        XCTAssertNotNil(fullMoonCorrelation)
        XCTAssertEqual(fullMoonCorrelation?.lucidDreamRate, 1.0) // All dreams are lucid
    }
    
    // MARK: - Statistics Tests
    
    func testGetStatistics() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create comprehensive test data
        for day in 0..<14 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            
            let weather = DreamWeatherData(
                date: date,
                temperature: 20.0 + Double(day),
                condition: day % 2 == 0 ? .clear : .cloudy,
                humidity: 50.0 + Double(day),
                pressure: 1010.0 + Double(day),
                moonPhase: MoonPhase.allCases[day % MoonPhase.allCases.count]
            )
            try await service.saveWeatherData(weather)
            
            // Create 1-2 dreams per day
            for _ in 0..<(day % 2 + 1) {
                let dream = Dream(
                    title: "Test Dream",
                    content: "Test content",
                    date: date,
                    clarity: 3 + (day % 3),
                    intensity: 3,
                    isLucid: day % 3 == 0
                )
                modelContext.insert(dream)
            }
        }
        
        try modelContext.save()
        
        let startDate = calendar.date(byAdding: .day, value: -15, to: now)!
        let stats = try await service.getStatistics(dateRange: startDate...now)
        
        XCTAssertEqual(stats.totalDreamsWithWeather, 15)
        XCTAssertNotNil(stats.averageTemperature)
        XCTAssertNotNil(stats.averageHumidity)
        XCTAssertNotNil(stats.averagePressure)
        XCTAssertFalse(stats.weatherDistribution.isEmpty)
        XCTAssertFalse(stats.moonPhaseDistribution.isEmpty)
    }
    
    // MARK: - Insight Generation Tests
    
    func testGenerateInsights() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create data that should generate insights
        for day in 0..<19 {
            let date = calendar.date(byAdding: .day, value: -day, to: now)!
            
            let weather = DreamWeatherData(
                date: date,
                temperature: 25.0,
                condition: .thunderstorm,
                moonPhase: .fullMoon
            )
            try await service.saveWeatherData(weather)
            
            // Create dreams with high lucid rate during thunderstorms
            for _ in 0..<2 {
                let dream = Dream(
                    title: "Thunderstorm Dream",
                    content: "Lucid dream during storm",
                    date: date,
                    clarity: 5,
                    intensity: 5,
                    isLucid: true
                )
                dream.emotions = [.excitement]
                modelContext.insert(dream)
            }
        }
        
        try modelContext.save()
        
        let startDate = calendar.date(byAdding: .day, value: -20, to: now)!
        let insights = try await service.generateInsights(dateRange: startDate...now)
        
        XCTAssertFalse(insights.isEmpty)
        
        // Should have weather pattern and moon influence insights
        let weatherInsight = insights.first { $0.type == .weatherPattern }
        let moonInsight = insights.first { $0.type == .moonInfluence }
        
        XCTAssertNotNil(weatherInsight)
        XCTAssertNotNil(moonInsight)
        XCTAssertGreaterThan(weatherInsight?.confidence ?? 0, 0.5)
    }
    
    // MARK: - Enum Tests
    
    func testWeatherConditionDisplayNames() {
        let conditions: [(WeatherCondition, String)] = [
            (.clear, "晴朗"),
            (.partlyCloudy, "多云"),
            (.cloudy, "阴天"),
            (.thunderstorm, "雷暴"),
            (.rain, "中雨"),
            (.snow, "雪")
        ]
        
        for (condition, expected) in conditions {
            XCTAssertEqual(condition.displayName, expected, "Failed for \(condition)")
        }
    }
    
    func testMoonPhaseDisplayNames() {
        let phases: [(MoonPhase, String)] = [
            (.newMoon, "新月"),
            (.fullMoon, "满月"),
            (.firstQuarter, "上弦月"),
            (.lastQuarter, "下弦月"),
            (.waxingCrescent, "蛾眉月"),
            (.waningGibbous, "亏凸月")
        ]
        
        for (phase, expected) in phases {
            XCTAssertEqual(phase.displayName, expected, "Failed for \(phase)")
        }
    }
    
    func testWeatherConditionIcons() {
        XCTAssertEqual(WeatherCondition.clear.icon, "☀️")
        XCTAssertEqual(WeatherCondition.cloudy.icon, "☁️")
        XCTAssertEqual(WeatherCondition.rain.icon, "🌧️")
        XCTAssertEqual(WeatherCondition.thunderstorm.icon, "⚡")
        XCTAssertEqual(WeatherCondition.snow.icon, "❄️")
    }
    
    func testMoonPhaseIcons() {
        XCTAssertEqual(MoonPhase.newMoon.icon, "🌑")
        XCTAssertEqual(MoonPhase.fullMoon.icon, "🌕")
        XCTAssertEqual(MoonPhase.firstQuarter.icon, "🌓")
        XCTAssertEqual(MoonPhase.lastQuarter.icon, "🌗")
    }
    
    // MARK: - Correlation Strength Tests
    
    func testCorrelationStrengthDisplayNames() {
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.strong.displayName, "强相关")
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.moderate.displayName, "中等相关")
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.weak.displayName, "弱相关")
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.none.displayName, "无相关")
    }
    
    func testCorrelationStrengthColors() {
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.strong.color, "FF6B6B")
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.moderate.color, "4ECDC4")
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.weak.color, "95E1D3")
        XCTAssertEqual(DreamWeatherCorrelation.CorrelationStrength.none.color, "D3D3D3")
    }
    
    // MARK: - Insight Type Tests
    
    func testInsightTypeDisplayNames() {
        let types: [(DreamEnvironmentalInsight.InsightType, String)] = [
            (.weatherPattern, "天气模式"),
            (.moonInfluence, "月球影响"),
            (.seasonalTrend, "季节趋势"),
            (.pressureEffect, "气压影响"),
            (.temperatureEffect, "温度影响"),
            (.precipitationEffect, "降水影响")
        ]
        
        for (type, expected) in types {
            XCTAssertEqual(type.displayName, expected, "Failed for \(type)")
        }
    }
    
    // MARK: - Config Tests
    
    func testDefaultConfig() {
        let config = DreamWeatherConfig.default
        
        XCTAssertTrue(config.enabled)
        XCTAssertTrue(config.autoFetch)
        XCTAssertEqual(config.units, .celsius)
        XCTAssertEqual(config.fetchHour, 8)
    }
    
    func testTemperatureUnitsDisplayNames() {
        XCTAssertEqual(DreamWeatherConfig.TemperatureUnits.celsius.displayName, "摄氏度 (°C)")
        XCTAssertEqual(DreamWeatherConfig.TemperatureUnits.fahrenheit.displayName, "华氏度 (°F)")
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithLargeDataset() async throws {
        let calendar = Calendar.current
        let now = Date()
        
        // Create 90 days of data
        measure {
            let expectation = self.expectation(description: "Large dataset")
            
            Task {
                for day in 0..<90 {
                    let date = calendar.date(byAdding: .day, value: -day, to: now)!
                    
                    let weather = DreamWeatherData(
                        date: date,
                        temperature: Double.random(in: 10...35),
                        condition: WeatherCondition.allCases.randomElement()!,
                        moonPhase: MoonPhase.allCases.randomElement()!
                    )
                    try? await service.saveWeatherData(weather)
                    
                    for _ in 0..<3 {
                        let dream = Dream(
                            title: "Test Dream",
                            content: "Content",
                            date: date,
                            clarity: Int.random(in: 1...5),
                            intensity: Int.random(in: 1...5),
                            isLucid: Bool.random()
                        )
                        modelContext.insert(dream)
                    }
                }
                
                try? modelContext.save()
                
                let startDate = calendar.date(byAdding: .day, value: -90, to: now)!
                _ = try? await service.getStatistics(dateRange: startDate...now)
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 30.0)
        }
    }
}
