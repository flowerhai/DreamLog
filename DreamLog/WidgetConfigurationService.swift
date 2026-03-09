//
//  WidgetConfigurationService.swift
//  DreamLog
//
//  小组件配置服务 - 管理个性化设置
//

import Foundation
import SwiftUI

// MARK: - 小组件主题配置
struct WidgetTheme: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let gradientColors: [String] // HEX colors
    let iconSFSymbol: String
    let textColor: String // HEX
    
    static let `default` = WidgetTheme(
        id: "default",
        name: "星空紫",
        gradientColors: ["#7B61FF", "#4A90E2"],
        iconSFSymbol: "moon.stars.fill",
        textColor: "#FFFFFF"
    )
    
    static let themes: [WidgetTheme] = [
        `default`,
        WidgetTheme(
            id: "sunset",
            name: "日落橙",
            gradientColors: ["#FF6B6B", "#FFA500"],
            iconSFSymbol: "sun.max.fill",
            textColor: "#FFFFFF"
        ),
        WidgetTheme(
            id: "forest",
            name: "森林绿",
            gradientColors: ["#2ECC71", "#27AE60"],
            iconSFSymbol: "leaf.fill",
            textColor: "#FFFFFF"
        ),
        WidgetTheme(
            id: "ocean",
            name: "海洋蓝",
            gradientColors: ["#00B4DB", "#0083B0"],
            iconSFSymbol: "water.fill",
            textColor: "#FFFFFF"
        ),
        WidgetTheme(
            id: "midnight",
            name: "午夜黑",
            gradientColors: ["#2C3E50", "#4CA1AF"],
            iconSFSymbol: "moon.fill",
            textColor: "#FFFFFF"
        ),
        WidgetTheme(
            id: "rose",
            name: "玫瑰粉",
            gradientColors: ["#FF758C", "#FF7EB3"],
            iconSFSymbol: "heart.fill",
            textColor: "#FFFFFF"
        ),
        WidgetTheme(
            id: "gold",
            name: "奢华金",
            gradientColors: ["#FFD700", "#FFA500"],
            iconSFSymbol: "star.fill",
            textColor: "#000000"
        ),
        WidgetTheme(
            id: "lavender",
            name: "薰衣草",
            gradientColors: ["#B19CD9", "#C8A2C8"],
            iconSFSymbol: "flower.open",
            textColor: "#FFFFFF"
        ),
        // MARK: - Phase 6 新增主题
        WidgetTheme(
            id: "sakura",
            name: "樱花粉",
            gradientColors: ["#FFB7C5", "#FF69B4"],
            iconSFSymbol: "flower.open",
            textColor: "#FFFFFF"
        ),
        WidgetTheme(
            id: "mint",
            name: "薄荷绿",
            gradientColors: ["#98FF98", "#3EB489"],
            iconSFSymbol: "leaf.fill",
            textColor: "#000000"
        ),
        WidgetTheme(
            id: "lemon",
            name: "柠檬黄",
            gradientColors: ["#FFF700", "#FFD700"],
            iconSFSymbol: "sun.max.fill",
            textColor: "#000000"
        ),
        WidgetTheme(
            id: "lavender_purple",
            name: "薰衣草紫",
            gradientColors: ["#E6E6FA", "#967BB6"],
            iconSFSymbol: "moon.stars.fill",
            textColor: "#000000"
        )
    ]
    
    var colors: [Color] {
        gradientColors.map { Color(hex: $0) }
    }
    
    var textColorValue: Color {
        Color(hex: textColor)
    }
}

// MARK: - 小组件数据配置
struct WidgetDataConfig: Codable {
    var showDreamCount: Bool = true
    var showLastDreamTitle: Bool = true
    var showMood: Bool = true
    var showWeeklyGoal: Bool = false
    var showStreak: Bool = false
    var showQuote: Bool = false
    var customQuote: String = ""
    var displayMode: DisplayMode = .standard
    
    enum DisplayMode: String, Codable, CaseIterable {
        case standard = "标准"
        case minimal = "简约"
        case detailed = "详细"
    }
}

// MARK: - 小组件尺寸配置
struct WidgetSizeConfig: Codable {
    var preferredSize: WidgetSize = .systemSmall
    var allowMultipleSizes: Bool = true
    
    enum WidgetSize: String, Codable, CaseIterable {
        case systemSmall = "小"
        case systemMedium = "中"
        case systemLarge = "大"
    }
}

// MARK: - 完整小组件配置
struct WidgetCustomizationConfig: Codable {
    var theme: WidgetTheme = .default
    var dataConfig: WidgetDataConfig = WidgetDataConfig()
    var sizeConfig: WidgetSizeConfig = WidgetSizeConfig()
    var customName: String = ""
    var isFavorite: Bool = false
    
    static let `default` = WidgetCustomizationConfig()
}

// MARK: - 服务类
class WidgetConfigurationService {
    static let shared = WidgetConfigurationService()
    
    private let userDefaultsKey = "widgetCustomizationConfig"
    private let configsKey = "widgetCustomizationConfigs"
    
    // 当前激活的配置
    var currentConfig: WidgetCustomizationConfig {
        get {
            guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
                  let config = try? JSONDecoder().decode(WidgetCustomizationConfig.self, from: data)
            else {
                return .default
            }
            return config
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
                notifyWidgetUpdate()
            }
        }
    }
    
    // 保存的多个配置预设
    var savedConfigs: [String: WidgetCustomizationConfig] {
        get {
            guard let data = UserDefaults.standard.data(forKey: configsKey),
                  let configs = try? JSONDecoder().decode([String: WidgetCustomizationConfig].self, from: data)
            else {
                return [:]
            }
            return configs
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: configsKey)
            }
        }
    }
    
    // 保存配置预设
    func saveConfig(name: String, config: WidgetCustomizationConfig) {
        var configs = savedConfigs
        configs[name] = config
        savedConfigs = configs
    }
    
    // 加载配置预设
    func loadConfig(name: String) -> WidgetCustomizationConfig? {
        return savedConfigs[name]
    }
    
    // 删除配置预设
    func deleteConfig(name: String) {
        var configs = savedConfigs
        configs.removeValue(forKey: name)
        savedConfigs = configs
    }
    
    // 通知小组件更新
    private func notifyWidgetUpdate() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "DreamLogWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "DreamLogQuickWidget")
        #endif
    }
    
    // 导出配置
    func exportConfig() -> String? {
        let config = currentConfig
        guard let encoded = try? JSONEncoder().encode(config),
              let jsonString = String(data: encoded, encoding: .utf8)
        else {
            return nil
        }
        return jsonString
    }
    
    // 导入配置
    func importConfig(from jsonString: String) -> Bool {
        guard let data = jsonString.data(using: .utf8),
              let config = try? JSONDecoder().decode(WidgetCustomizationConfig.self, from: data)
        else {
            return false
        }
        currentConfig = config
        return true
    }
}

// MARK: - Color Extension for HEX
// Note: Color(hex:) is defined in Theme.swift to avoid redeclaration
