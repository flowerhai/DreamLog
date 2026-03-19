//
//  DreamWeatherService.swift
//  DreamLog
//
//  Phase 66: Dream Weather & Environmental Correlation Service
//  Analyzing how weather, moon phases, and environmental factors affect dreams
//

import Foundation
import SwiftData

@ModelActor
actor DreamWeatherService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Weather Data Management
    
    /// Fetch or create weather data for a specific date
    func getWeatherData(for date: Date) async throws -> DreamWeatherData? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        // Calendar.date(byAdding:...) with valid inputs never fails
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let descriptor = FetchDescriptor<DreamWeatherData>(
            predicate: #Predicate<DreamWeatherData> {
                $0.date >= startOfDay && $0.date < endOfDay
            }
        )
        
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    /// Save weather data for a date
    func saveWeatherData(_ weatherData: DreamWeatherData) async throws {
        // Check if exists
        if let existing = try getWeatherData(for: weatherData.date) {
            // Update existing
            existing.temperature = weatherData.temperature
            existing.condition = weatherData.condition
            existing.humidity = weatherData.humidity
            existing.pressure = weatherData.pressure
            existing.windSpeed = weatherData.windSpeed
            existing.precipitation = weatherData.precipitation
            existing.cloudCover = weatherData.cloudCover
            existing.visibility = weatherData.visibility
            existing.uvIndex = weatherData.uvIndex
            existing.moonPhase = weatherData.moonPhase
            existing.moonIllumination = weatherData.moonIllumination
            existing.sunrise = weatherData.sunrise
            existing.sunset = weatherData.sunset
        } else {
            // Insert new
            modelContext.insert(weatherData)
        }
        
        try modelContext.save()
    }
    
    /// Fetch weather data for date range
    func getWeatherData(for dateRange: ClosedRange<Date>) async throws -> [DreamWeatherData] {
        let descriptor = FetchDescriptor<DreamWeatherData>(
            predicate: #Predicate<DreamWeatherData> {
                $0.date >= dateRange.lowerBound && $0.date <= dateRange.upperBound
            },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Delete weather data for a date
    func deleteWeatherData(for date: Date) async throws {
        if let weatherData = try getWeatherData(for: date) {
            modelContext.delete(weatherData)
            try modelContext.save()
        }
    }
    
    // MARK: - Correlation Analysis
    
    /// Analyze weather-dream correlations
    func analyzeWeatherCorrelations(dateRange: ClosedRange<Date>) async throws -> [DreamWeatherCorrelation] {
        let weatherData = try getWeatherData(for: dateRange)
        var correlations: [WeatherCondition: DreamCorrelationBuilder] = [:]
        
        for weather in weatherData {
            guard let condition = weather.condition else { continue }
            
            if correlations[condition] == nil {
                correlations[condition] = DreamCorrelationBuilder()
            }
            
            // Find dreams for this date
            let dreams = try getDreams(for: weather.date)
            correlations[condition]?.addDreams(dreams)
        }
        
        return correlations.compactMap { condition, builder in
            builder.build(condition: condition)
        }.sorted { $0.dreamCount > $1.dreamCount }
    }
    
    /// Analyze moon phase-dream correlations
    func analyzeMoonCorrelations(dateRange: ClosedRange<Date>) async throws -> [DreamMoonCorrelation] {
        let weatherData = try getWeatherData(for: dateRange)
        var correlations: [MoonPhase: DreamMoonCorrelationBuilder] = [:]
        
        for weather in weatherData {
            guard let moonPhase = weather.moonPhase else { continue }
            
            if correlations[moonPhase] == nil {
                correlations[moonPhase] = DreamMoonCorrelationBuilder()
            }
            
            let dreams = try getDreams(for: weather.date)
            correlations[moonPhase]?.addDreams(dreams)
        }
        
        return correlations.compactMap { moonPhase, builder in
            builder.build(moonPhase: moonPhase)
        }.sorted { $0.dreamCount > $1.dreamCount }
    }
    
    /// Generate environmental insights
    func generateInsights(dateRange: ClosedRange<Date>) async throws -> [DreamEnvironmentalInsight] {
        var insights: [DreamEnvironmentalInsight] = []
        
        let weatherCorrelations = try analyzeWeatherCorrelations(dateRange: dateRange)
        let moonCorrelations = try analyzeMoonCorrelations(dateRange: dateRange)
        
        // Weather pattern insights
        for correlation in weatherCorrelations where correlation.correlationStrength != .none {
            let insight = DreamEnvironmentalInsight(
                id: UUID(),
                type: .weatherPattern,
                title: "\(correlation.weatherCondition.displayName)与梦境",
                description: "在\(correlation.weatherCondition.displayName)天气下，您记录了\(correlation.dreamCount)个梦境，平均清晰度为\(String(format: "%.1f", correlation.averageClarity))。",
                confidence: calculateConfidence(for: correlation),
                supportingData: [
                    "梦境数量：\(correlation.dreamCount)",
                    "平均清晰度：\(String(format: "%.1f", correlation.averageClarity))",
                    "清醒梦比例：\(String(format: "%.1f%%", correlation.lucidDreamRate * 100))"
                ],
                recommendations: generateRecommendations(for: correlation),
                createdAt: Date()
            )
            insights.append(insight)
        }
        
        // Moon phase insights
        for correlation in moonCorrelations where correlation.correlationStrength != .none {
            let insight = DreamEnvironmentalInsight(
                id: UUID(),
                type: .moonInfluence,
                title: "\(correlation.moonPhase.displayName)与梦境",
                description: "在\(correlation.moonPhase.displayName)期间，您的清醒梦比例为\(String(format: "%.1f%%", correlation.lucidDreamRate * 100))。",
                confidence: calculateConfidence(for: correlation),
                supportingData: [
                    "梦境数量：\(correlation.dreamCount)",
                    "清醒梦数量：\(correlation.lucidDreamCount)",
                    "平均清晰度：\(String(format: "%.1f", correlation.averageClarity))"
                ],
                recommendations: generateMoonRecommendations(for: correlation),
                createdAt: Date()
            )
            insights.append(insight)
        }
        
        return insights.sorted { $0.confidence > $1.confidence }
    }
    
    /// Get comprehensive weather statistics
    func getStatistics(dateRange: ClosedRange<Date>) async throws -> DreamWeatherStatistics {
        let weatherData = try getWeatherData(for: dateRange)
        let weatherCorrelations = try analyzeWeatherCorrelations(dateRange: dateRange)
        let moonCorrelations = try analyzeMoonCorrelations(dateRange: dateRange)
        let insights = try generateInsights(dateRange: dateRange)
        
        var weatherDistribution: [WeatherCondition: Int] = [:]
        var moonPhaseDistribution: [MoonPhase: Int] = [:]
        var temperatures: [Double] = []
        var humidities: [Double] = []
        var pressures: [Double] = []
        
        for weather in weatherData {
            if let condition = weather.condition {
                weatherDistribution[condition, default: 0] += 1
            }
            if let moonPhase = weather.moonPhase {
                moonPhaseDistribution[moonPhase, default: 0] += 1
            }
            if let temp = weather.temperature { temperatures.append(temp) }
            if let humidity = weather.humidity { humidities.append(humidity) }
            if let pressure = weather.pressure { pressures.append(pressure) }
        }
        
        return DreamWeatherStatistics(
            totalDreamsWithWeather: weatherData.count,
            dateRange: dateRange,
            weatherDistribution: weatherDistribution,
            moonPhaseDistribution: moonPhaseDistribution,
            averageTemperature: temperatures.isEmpty ? nil : temperatures.reduce(0, +) / Double(temperatures.count),
            averageHumidity: humidities.isEmpty ? nil : humidities.reduce(0, +) / Double(humidities.count),
            averagePressure: pressures.isEmpty ? nil : pressures.reduce(0, +) / Double(pressures.count),
            topCorrelations: Array(weatherCorrelations.prefix(5)),
            moonCorrelations: Array(moonCorrelations.prefix(5)),
            insights: insights
        )
    }
    
    // MARK: - Helper Methods
    
    private func getDreams(for date: Date) async throws -> [Dream] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        // Calendar.date(byAdding:...) with valid inputs never fails
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> {
                $0.date >= startOfDay && $0.date < endOfDay
            }
        )
        return try modelContext.fetch(descriptor)
    }
    
    private func calculateConfidence(for correlation: DreamWeatherCorrelation) -> Double {
        // Confidence based on sample size and correlation strength
        let sampleFactor = min(Double(correlation.dreamCount) / 20.0, 1.0)
        let strengthFactor: Double = {
            switch correlation.correlationStrength {
            case .strong: return 1.0
            case .moderate: return 0.7
            case .weak: return 0.4
            case .none: return 0.0
            }
        }()
        return sampleFactor * strengthFactor
    }
    
    private func calculateConfidence(for correlation: DreamMoonCorrelation) -> Double {
        let sampleFactor = min(Double(correlation.dreamCount) / 20.0, 1.0)
        let strengthFactor: Double = {
            switch correlation.correlationStrength {
            case .strong: return 1.0
            case .moderate: return 0.7
            case .weak: return 0.4
            case .none: return 0.0
            }
        }()
        return sampleFactor * strengthFactor
    }
    
    private func generateRecommendations(for correlation: DreamWeatherCorrelation) -> [String] {
        var recommendations: [String] = []
        
        switch correlation.weatherCondition {
        case .thunderstorm, .heavyRain:
            if correlation.lucidDreamRate > 0.3 {
                recommendations.append("雷雨天似乎容易引发您的清醒梦，可以尝试在这些天气进行清醒梦练习。")
            }
        case .clear:
            if correlation.averageClarity > 4.0 {
                recommendations.append("晴朗天气下您的梦境更清晰，适合进行梦境记录和回顾。")
            }
        case .fullMoon:
            if correlation.lucidDreamRate > 0.25 {
                recommendations.append("满月期间清醒梦比例较高，可以尝试设置清醒梦意图。")
            }
        default:
            break
        }
        
        if correlation.dreamCount < 5 {
            recommendations.append("数据量较少，继续记录以获得更准确的分析。")
        }
        
        return recommendations.isEmpty ? ["继续记录梦境以获取更准确的环境关联分析。"] : recommendations
    }
    
    private func generateMoonRecommendations(for correlation: DreamMoonCorrelation) -> [String] {
        var recommendations: [String] = []
        
        switch correlation.moonPhase {
        case .fullMoon:
            recommendations.append("满月期间梦境通常更生动，适合进行梦境创作和探索。")
            if correlation.lucidDreamRate > 0.3 {
                recommendations.append("您在满月时清醒梦比例很高，可以尝试深度清醒梦练习。")
            }
        case .newMoon:
            recommendations.append("新月是设定梦境意图的好时机，尝试在睡前设定主题。")
        case .firstQuarter, .waxingGibbous:
            recommendations.append("月亮渐盈期间，梦境能量逐渐增强，适合创意探索。")
        case .lastQuarter, .waningGibbous:
            recommendations.append("月亮渐亏期间，适合进行梦境反思和整合。")
        default:
            break
        }
        
        return recommendations.isEmpty ? ["继续追踪月相与梦境的关联。"] : recommendations
    }
}

// MARK: - Helper Builders

private class DreamCorrelationBuilder {
    private var dreams: [Dream] = []
    
    func addDreams(_ newDreams: [Dream]) {
        dreams.append(contentsOf: newDreams)
    }
    
    func build(condition: WeatherCondition) -> DreamWeatherCorrelation {
        let dreamCount = dreams.count
        let avgClarity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(dreamCount)
        let avgIntensity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.intensity }) / Double(dreamCount)
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidRate = dreamCount > 0 ? Double(lucidCount) / Double(dreamCount) : 0
        
        // Common emotions
        var emotionCounts: [String: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionCounts[emotion.rawValue, default: 0] += 1
            }
        }
        let commonEmotions = emotionCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
        
        // Common tags
        var tagCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        let commonTags = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        // Determine correlation strength
        let strength: DreamWeatherCorrelation.CorrelationStrength = {
            if dreamCount >= 10 && (lucidRate > 0.3 || avgClarity > 4.0) {
                return .strong
            } else if dreamCount >= 5 && (lucidRate > 0.2 || avgClarity > 3.5) {
                return .moderate
            } else if dreamCount >= 3 {
                return .weak
            } else {
                return .none
            }
        }()
        
        return DreamWeatherCorrelation(
            weatherCondition: condition,
            dreamCount: dreamCount,
            averageClarity: avgClarity,
            averageIntensity: avgIntensity,
            lucidDreamCount: lucidCount,
            lucidDreamRate: lucidRate,
            commonEmotions: commonEmotions,
            commonTags: commonTags,
            correlationStrength: strength
        )
    }
}

private class DreamMoonCorrelationBuilder {
    private var dreams: [Dream] = []
    
    func addDreams(_ newDreams: [Dream]) {
        dreams.append(contentsOf: newDreams)
    }
    
    func build(moonPhase: MoonPhase) -> DreamMoonCorrelation {
        let dreamCount = dreams.count
        let avgClarity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.clarity }) / Double(dreamCount)
        let avgIntensity = dreams.isEmpty ? 0 : Double(dreams.reduce(0) { $0 + $1.intensity }) / Double(dreamCount)
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidRate = dreamCount > 0 ? Double(lucidCount) / Double(dreamCount) : 0
        
        // Common themes (from tags)
        var tagCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        let commonThemes = tagCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        // Determine correlation strength
        let strength: DreamWeatherCorrelation.CorrelationStrength = {
            if dreamCount >= 10 && lucidRate > 0.35 {
                return .strong
            } else if dreamCount >= 5 && lucidRate > 0.25 {
                return .moderate
            } else if dreamCount >= 3 {
                return .weak
            } else {
                return .none
            }
        }()
        
        return DreamMoonCorrelation(
            moonPhase: moonPhase,
            dreamCount: dreamCount,
            averageClarity: avgClarity,
            lucidDreamCount: lucidCount,
            lucidDreamRate: lucidRate,
            averageIntensity: avgIntensity,
            commonThemes: commonThemes,
            correlationStrength: strength
        )
    }
}
