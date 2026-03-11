//
//  DreamWeeklyReportModels.swift
//  DreamLog
//
//  梦境周报数据模型
//  Phase 18 - 梦境周报功能
//

import Foundation

// MARK: - 周报数据类型

/// 梦境周报数据结构
struct DreamWeeklyReport: Codable, Identifiable {
    var id: UUID = UUID()
    var weekStartDate: Date       // 周开始日期（周一）
    var weekEndDate: Date         // 周结束日期（周日）
    var generatedAt: Date         // 生成时间
    
    // 基础统计
    var totalDreams: Int          // 本周梦境总数
    var lucidDreams: Int          // 清醒梦数量
    var averageClarity: Double    // 平均清晰度 (1-5)
    var averageIntensity: Double  // 平均强度 (1-5)
    var recordingStreak: Int      // 连续记录天数
    
    // 情绪分析
    var emotionDistribution: [String: Int]  // 情绪分布
    var dominantEmotion: String             // 主导情绪
    var moodTrend: MoodTrend                // 情绪趋势
    
    // 主题分析
    var topTags: [TagFrequency]   // 热门标签
    var emergingThemes: [String]  // 新兴主题
    var fadingThemes: [String]    // 减弱主题
    
    // 时间分析
    var dreamsByTimeOfDay: [String: Int]  // 按时间段分布
    var dreamsByWeekday: [Int: Int]       // 按星期分布
    var mostActiveDay: Int                // 最活跃的星期
    var bestRecallHour: Int               // 最佳回忆时段
    
    // 亮点梦境
    var highlightDreams: [DreamHighlight] // 本周亮点梦境
    
    // 洞察与建议
    var insights: [ReportInsight]  // 智能洞察
    var suggestions: [String]      // 个性化建议
    
    // 对比数据
    var lastWeekComparison: WeekComparison?  // 与上周对比
    
    enum MoodTrend: String, Codable, CaseIterable {
        case improving = "improving"     // 情绪改善
        case stable = "stable"           // 情绪稳定
        case declining = "declining"     // 情绪下降
        case fluctuating = "fluctuating" // 情绪波动
        
        var displayName: String {
            switch self {
            case .improving: return "情绪改善"
            case .stable: return "情绪稳定"
            case .declining: return "情绪下降"
            case .fluctuating: return "情绪波动"
            }
        }
        
        var icon: String {
            switch self {
            case .improving: return "arrow.up.right.circle.fill"
            case .stable: return "minus.circle.fill"
            case .declining: return "arrow.down.right.circle.fill"
            case .fluctuating: return "arrow.left.and.right.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .improving: return "green"
            case .stable: return "blue"
            case .declining: return "orange"
            case .fluctuating: return "purple"
            }
        }
    }
}

// MARK: - 标签频率

/// 标签频率数据
struct TagFrequency: Codable, Identifiable {
    var id: String { tag }
    var tag: String
    var count: Int
    var change: Int?  // 与上周相比的变化
}

// MARK: - 亮点梦境

/// 亮点梦境数据
struct DreamHighlight: Codable, Identifiable {
    var id: UUID
    var dreamId: UUID
    var title: String
    var date: Date
    var type: HighlightType
    var reason: String
    
    enum HighlightType: String, Codable, CaseIterable {
        case mostLucid = "mostLucid"        // 最清晰的清醒梦
        case highestClarity = "highestClarity"  // 最高清晰度
        case mostEmotional = "mostEmotional"    // 情绪最强烈
        case longest = "longest"            // 最长梦境
        case mostTags = "mostTags"          // 标签最多
        case earliest = "earliest"          // 最早记录
        case latest = "latest"              // 最晚记录
        
        var displayName: String {
            switch self {
            case .mostLucid: return "👁️ 最佳清醒梦"
            case .highestClarity: return "⭐ 最清晰的梦"
            case .mostEmotional: return "💖 情绪最强烈"
            case .longest: return "📝 最详细的梦"
            case .mostTags: return "🏷️ 主题最丰富"
            case .earliest: return "🌅 最早的记录"
            case .latest: return "🌙 最晚的记录"
            }
        }
    }
}

// MARK: - 报告洞察

/// 智能洞察数据
struct ReportInsight: Codable, Identifiable {
    var id: UUID = UUID()
    var type: InsightType
    var title: String
    var description: String
    var icon: String
    var confidence: Double  // 置信度 0-1
    
    enum InsightType: String, Codable, CaseIterable {
        case pattern = "pattern"           // 发现模式
        case trend = "trend"               // 趋势分析
        case anomaly = "anomaly"           // 异常检测
        case achievement = "achievement"   // 成就认可
        case suggestion = "suggestion"     // 改进建议
        
        var displayName: String {
            switch self {
            case .pattern: return "🔍 模式发现"
            case .trend: return "📈 趋势分析"
            case .anomaly: return "⚠️ 异常检测"
            case .achievement: return "🏆 成就认可"
            case .suggestion: return "💡 改进建议"
            }
        }
    }
}

// MARK: - 周对比数据

/// 周对比数据
struct WeekComparison: Codable {
    var dreamsChange: Int           // 梦境数量变化
    var dreamsChangePercent: Double // 变化百分比
    var clarityChange: Double       // 清晰度变化
    var lucidChange: Int            // 清醒梦变化
    var streakChange: Int           // 连续天数变化
    
    var isBetter: Bool {
        dreamsChange >= 0 && clarityChange >= 0
    }
}

// MARK: - 周报配置

/// 周报生成配置
struct WeeklyReportConfig: Codable {
    var isEnabled: Bool = true
    var autoGenerate: Bool = true       // 每周日自动生成
    var generateDay: Int = 0            // 生成日期 (0=周日)
    var generateHour: Int = 20          // 生成时间 (20:00)
    var includeSuggestions: Bool = true // 包含建议
    var includeHighlights: Bool = true  // 包含亮点
    var shareAutomatically: Bool = false // 自动分享
    
    static let `default` = WeeklyReportConfig()
}

// MARK: - 周报卡片数据

/// 可分享的周报卡片数据
struct WeeklyReportCard: Codable {
    var report: DreamWeeklyReport
    var theme: ReportCardTheme
    var backgroundImage: Data?
    
    enum ReportCardTheme: String, Codable, CaseIterable {
        case starry = "starry"       // 星空
        case sunset = "sunset"       // 日落
        case ocean = "ocean"         // 海洋
        case forest = "forest"       // 森林
        case minimal = "minimal"     // 简约
        case gradient = "gradient"   // 渐变
        
        var displayName: String {
            switch self {
            case .starry: return "星空"
            case .sunset: return "日落"
            case .ocean: return "海洋"
            case .forest: return "森林"
            case .minimal: return "简约"
            case .gradient: return "渐变"
            }
        }
    }
}
