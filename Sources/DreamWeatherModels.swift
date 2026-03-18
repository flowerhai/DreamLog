//
//  DreamWeatherModels.swift
//  DreamLog
//
//  Phase 66: Dream Weather & Environmental Correlation
//  Analyzing how weather, moon phases, and environmental factors affect dreams
//

import Foundation
import SwiftData

// MARK: - Weather Data Models

/// Weather conditions during dream date
@Model
final class DreamWeatherData {
    var id: UUID
    var date: Date
    var temperature: Double?  // Celsius
    var condition: WeatherCondition?
    var humidity: Double?  // Percentage
    var pressure: Double?  // hPa
    var windSpeed: Double?  // km/h
    var precipitation: Double?  // mm
    var cloudCover: Double?  // Percentage
    var visibility: Double?  // km
    var uvIndex: Int?
    var moonPhase: MoonPhase?
    var moonIllumination: Double?  // Percentage
    var sunrise: Date?
    var sunset: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date,
        temperature: Double? = nil,
        condition: WeatherCondition? = nil,
        humidity: Double? = nil,
        pressure: Double? = nil,
        windSpeed: Double? = nil,
        precipitation: Double? = nil,
        cloudCover: Double? = nil,
        visibility: Double? = nil,
        uvIndex: Int? = nil,
        moonPhase: MoonPhase? = nil,
        moonIllumination: Double? = nil,
        sunrise: Date? = nil,
        sunset: Date? = nil
    ) {
        self.id = id
        self.date = date
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.pressure = pressure
        self.windSpeed = windSpeed
        self.precipitation = precipitation
        self.cloudCover = cloudCover
        self.visibility = visibility
        self.uvIndex = uvIndex
        self.moonPhase = moonPhase
        self.moonIllumination = moonIllumination
        self.sunrise = sunrise
        self.sunset = sunset
        self.createdAt = Date()
    }
}

// MARK: - Enums

/// Weather conditions
enum WeatherCondition: String, Codable, CaseIterable {
    case clear = "clear"
    case partlyCloudy = "partly_cloudy"
    case cloudy = "cloudy"
    case overcast = "overcast"
    case fog = "fog"
    case mist = "mist"
    case drizzle = "drizzle"
    case lightRain = "light_rain"
    case rain = "rain"
    case heavyRain = "heavy_rain"
    case thunderstorm = "thunderstorm"
    case snow = "snow"
    case lightSnow = "light_snow"
    case heavySnow = "heavy_snow"
    case hail = "hail"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .clear: return "晴朗"
        case .partlyCloudy: return "多云"
        case .cloudy: return "阴天"
        case .overcast: return "阴霾"
        case .fog: return "雾"
        case .mist: return "薄雾"
        case .drizzle: return "毛毛雨"
        case .lightRain: return "小雨"
        case .rain: return "中雨"
        case .heavyRain: return "大雨"
        case .thunderstorm: return "雷暴"
        case .snow: return "雪"
        case .lightSnow: return "小雪"
        case .heavySnow: return "大雪"
        case .hail: return "冰雹"
        case .unknown: return "未知"
        }
    }
    
    var icon: String {
        switch self {
        case .clear: return "☀️"
        case .partlyCloudy: return "⛅"
        case .cloudy, .overcast: return "☁️"
        case .fog, .mist: return "🌫️"
        case .drizzle, .lightRain, .rain: return "🌧️"
        case .heavyRain: return "⛈️"
        case .thunderstorm: return "⚡"
        case .snow, .lightSnow, .heavySnow: return "❄️"
        case .hail: return "🌨️"
        case .unknown: return "❓"
        }
    }
}

/// Moon phases
enum MoonPhase: String, Codable, CaseIterable {
    case newMoon = "new_moon"
    case waxingCrescent = "waxing_crescent"
    case firstQuarter = "first_quarter"
    case waxingGibbous = "waxing_gibbous"
    case fullMoon = "full_moon"
    case waningGibbous = "waning_gibbous"
    case lastQuarter = "last_quarter"
    case waningCrescent = "waning_crescent"
    
    var displayName: String {
        switch self {
        case .newMoon: return "新月"
        case .waxingCrescent: return "蛾眉月"
        case .firstQuarter: return "上弦月"
        case .waxingGibbous: return "盈凸月"
        case .fullMoon: return "满月"
        case .waningGibbous: return "亏凸月"
        case .lastQuarter: return "下弦月"
        case .waningCrescent: return "残月"
        }
    }
    
    var icon: String {
        switch self {
        case .newMoon: return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter: return "🌓"
        case .waxingGibbous: return "🌔"
        case .fullMoon: return "🌕"
        case .waningGibbous: return "🌖"
        case .lastQuarter: return "🌗"
        case .waningCrescent: return "🌘"
        }
    }
}

// MARK: - Correlation Analysis Models

/// Weather-dream correlation data
struct DreamWeatherCorrelation {
    let weatherCondition: WeatherCondition
    let dreamCount: Int
    let averageClarity: Double
    let averageIntensity: Double
    let lucidDreamCount: Int
    let lucidDreamRate: Double
    let commonEmotions: [String]
    let commonTags: [String]
    let correlationStrength: CorrelationStrength
    
    enum CorrelationStrength: String {
        case strong = "strong"
        case moderate = "moderate"
        case weak = "weak"
        case none = "none"
        
        var displayName: String {
            switch self {
            case .strong: return "强相关"
            case .moderate: return "中等相关"
            case .weak: return "弱相关"
            case .none: return "无相关"
            }
        }
        
        var color: String {
            switch self {
            case .strong: return "FF6B6B"
            case .moderate: return "4ECDC4"
            case .weak: return "95E1D3"
            case .none: return "D3D3D3"
            }
        }
    }
}

/// Moon phase-dream correlation data
struct DreamMoonCorrelation {
    let moonPhase: MoonPhase
    let dreamCount: Int
    let averageClarity: Double
    let lucidDreamCount: Int
    let lucidDreamRate: Double
    let averageIntensity: Double
    let commonThemes: [String]
    let correlationStrength: DreamWeatherCorrelation.CorrelationStrength
}

/// Environmental insight
struct DreamEnvironmentalInsight {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let supportingData: [String]
    let recommendations: [String]
    let createdAt: Date
    
    enum InsightType: String, CaseIterable {
        case weatherPattern = "weather_pattern"
        case moonInfluence = "moon_influence"
        case seasonalTrend = "seasonal_trend"
        case pressureEffect = "pressure_effect"
        case temperatureEffect = "temperature_effect"
        case precipitationEffect = "precipitation_effect"
        
        var displayName: String {
            switch self {
            case .weatherPattern: return "天气模式"
            case .moonInfluence: return "月球影响"
            case .seasonalTrend: return "季节趋势"
            case .pressureEffect: return "气压影响"
            case .temperatureEffect: return "温度影响"
            case .precipitationEffect: return "降水影响"
            }
        }
    }
}

// MARK: - Statistics Models

/// Weather statistics summary
struct DreamWeatherStatistics {
    let totalDreamsWithWeather: Int
    let dateRange: ClosedRange<Date>
    let weatherDistribution: [WeatherCondition: Int]
    let moonPhaseDistribution: [MoonPhase: Int]
    let averageTemperature: Double?
    let averageHumidity: Double?
    let averagePressure: Double?
    let topCorrelations: [DreamWeatherCorrelation]
    let moonCorrelations: [DreamMoonCorrelation]
    let insights: [DreamEnvironmentalInsight]
    
    var weatherConditionWithMostDreams: WeatherCondition? {
        weatherDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    var moonPhaseWithMostDreams: MoonPhase? {
        moonPhaseDistribution.max(by: { $0.value < $1.value })?.key
    }
    
    var moonPhaseWithMostLucidDreams: MoonPhase? {
        moonCorrelations.max(by: { $0.lucidDreamRate < $1.lucidDreamRate })?.moonPhase
    }
}

// MARK: - Configuration

/// Weather data source configuration
struct DreamWeatherConfig {
    var enabled: Bool
    var autoFetch: Bool
    var location: String?
    var units: TemperatureUnits
    var fetchHour: Int  // Hour to fetch daily weather (0-23)
    
    enum TemperatureUnits: String, CaseIterable {
        case celsius = "celsius"
        case fahrenheit = "fahrenheit"
        
        var displayName: String {
            switch self {
            case .celsius: return "摄氏度 (°C)"
            case .fahrenheit: return "华氏度 (°F)"
            }
        }
    }
    
    static var `default`: DreamWeatherConfig {
        DreamWeatherConfig(
            enabled: true,
            autoFetch: true,
            location: nil,
            units: .celsius,
            fetchHour: 8
        )
    }
}
