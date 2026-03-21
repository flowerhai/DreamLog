//
//  DreamVoiceCommandModels.swift
//  DreamLog - 梦境语音命令数据模型
//  Phase 84: 梦境语音命令系统
//
//  Created by DreamLog Team on 2026/3/21.
//

import Foundation
import SwiftData

// MARK: - 语音命令类型

/// 语音命令类型枚举
enum VoiceCommandType: String, Codable, CaseIterable {
    // 记录类命令
    case recordDream = "record_dream"          // 记录梦境
    case quickNote = "quick_note"              // 快速备注
    
    // 查询类命令
    case searchDream = "search_dream"          // 搜索梦境
    case showStats = "show_stats"              // 显示统计
    case showRecent = "show_recent"            // 显示最近梦境
    case showCalendar = "show_calendar"        // 显示日历
    
    // 分析类命令
    case showInsights = "show_insights"        // 显示洞察
    case showTrends = "show_trends"            // 显示趋势
    case showPatterns = "show_patterns"        // 显示模式
    
    // 功能类命令
    case startMeditation = "start_meditation"  // 开始冥想
    case playMusic = "play_music"              // 播放音乐
    case showGallery = "show_gallery"          // 显示画廊
    case exportData = "export_data"            // 导出数据
    
    // 设置类命令
    case openSettings = "open_settings"        // 打开设置
    case setReminder = "set_reminder"          // 设置提醒
    
    // 帮助类命令
    case help = "help"                         // 帮助
    case whatCanIDo = "what_can_i_do"          // 我能做什么
    
    var displayName: String {
        switch self {
        case .recordDream: return "记录梦境"
        case .quickNote: return "快速备注"
        case .searchDream: return "搜索梦境"
        case .showStats: return "显示统计"
        case .showRecent: return "最近梦境"
        case .showCalendar: return "梦境日历"
        case .showInsights: return "智能洞察"
        case .showTrends: return "梦境趋势"
        case .showPatterns: return "梦境模式"
        case .startMeditation: return "开始冥想"
        case .playMusic: return "播放音乐"
        case .showGallery: return "梦境画廊"
        case .exportData: return "导出数据"
        case .openSettings: return "打开设置"
        case .setReminder: return "设置提醒"
        case .help: return "帮助"
        case .whatCanIDo: return "功能列表"
        }
    }
    
    var icon: String {
        switch self {
        case .recordDream: return "🎤"
        case .quickNote: return "📝"
        case .searchDream: return "🔍"
        case .showStats: return "📊"
        case .showRecent: return "🌙"
        case .showCalendar: return "📅"
        case .showInsights: return "💡"
        case .showTrends: return "📈"
        case .showPatterns: return "🔗"
        case .startMeditation: return "🧘"
        case .playMusic: return "🎵"
        case .showGallery: return "🎨"
        case .exportData: return "📤"
        case .openSettings: return "⚙️"
        case .setReminder: return "🔔"
        case .help: return "❓"
        case .whatCanIDo: return "📋"
        }
    }
}

// MARK: - 语音命令触发词

/// 语音触发词配置
struct VoiceTrigger: Codable, Identifiable {
    let id: UUID
    var commandType: VoiceCommandType
    var triggers: [String]           // 触发词列表
    var isEnabled: Bool              // 是否启用
    var confidence: Double           // 置信度阈值 (0-1)
    
    init(id: UUID = UUID(), 
         commandType: VoiceCommandType,
         triggers: [String],
         isEnabled: Bool = true,
         confidence: Double = 0.7) {
        self.id = id
        self.commandType = commandType
        self.triggers = triggers
        self.isEnabled = isEnabled
        self.confidence = confidence
    }
    
    /// 检查文本是否匹配触发词
    func matches(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return triggers.contains { trigger in
            lowercasedText.contains(trigger.lowercased())
        }
    }
}

// MARK: - 语音命令执行结果

/// 语音命令执行结果
struct VoiceCommandResult: Codable, Identifiable {
    let id: UUID
    let commandType: VoiceCommandType
    let recognizedText: String       // 识别的文本
    let confidence: Double           // 置信度
    let success: Bool                // 是否成功执行
    let message: String              // 结果消息
    let timestamp: Date              // 执行时间
    var data: [String: AnyCodable]?  // 附加数据
    
    init(id: UUID = UUID(),
         commandType: VoiceCommandType,
         recognizedText: String,
         confidence: Double,
         success: Bool,
         message: String,
         timestamp: Date = Date(),
         data: [String: AnyCodable]? = nil) {
        self.id = id
        self.commandType = commandType
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.success = success
        self.message = message
        self.timestamp = timestamp
        self.data = data
    }
}

// MARK: - 语音命令历史

/// 语音命令历史记录
@Model
final class VoiceCommandHistory {
    var id: UUID
    var commandType: String          // 命令类型
    var recognizedText: String       // 识别文本
    var confidence: Double           // 置信度
    var success: Bool                // 是否成功
    var message: String              // 结果消息
    var timestamp: Date              // 时间戳
    var responseTime: Double         // 响应时间 (秒)
    
    init(commandType: String,
         recognizedText: String,
         confidence: Double,
         success: Bool,
         message: String,
         responseTime: Double) {
        self.id = UUID()
        self.commandType = commandType
        self.recognizedText = recognizedText
        self.confidence = confidence
        self.success = success
        self.message = message
        self.timestamp = Date()
        self.responseTime = responseTime
    }
}

// MARK: - 语音命令配置

/// 语音命令配置
struct VoiceCommandConfig: Codable {
    var isEnabled: Bool                      // 是否启用语音命令
    var wakeWord: String                     // 唤醒词
    var language: String                     // 语言 (zh-CN/en-US)
    var autoExecute: Bool                    // 自动执行 (无需确认)
    var showConfirmation: Bool               // 显示确认
    var hapticFeedback: Bool                 // 触觉反馈
    var voiceFeedback: Bool                  // 语音反馈
    var maxHistoryDays: Int                  // 历史记录保留天数
    var minConfidence: Double                // 最低置信度
    
    static var `default`: VoiceCommandConfig {
        VoiceCommandConfig(
            isEnabled: true,
            wakeWord: "嗨 DreamLog",
            language: "zh-CN",
            autoExecute: false,
            showConfirmation: true,
            hapticFeedback: true,
            voiceFeedback: false,
            maxHistoryDays: 30,
            minConfidence: 0.6
        )
    }
}

// MARK: - 语音命令统计

/// 语音命令统计
struct VoiceCommandStats {
    let totalCommands: Int           // 总命令数
    let successfulCommands: Int      // 成功命令数
    let failedCommands: Int          // 失败命令数
    let averageConfidence: Double    // 平均置信度
    let averageResponseTime: Double  // 平均响应时间
    let mostUsedCommand: VoiceCommandType?  // 最常用命令
    let todayCommands: Int           // 今日命令数
    let weeklyCommands: Int          // 本周命令数
    
    var successRate: Double {
        guard totalCommands > 0 else { return 0 }
        return Double(successfulCommands) / Double(totalCommands)
    }
}

// MARK: - 辅助类型

/// 任意可编码类型 (用于 JSON 存储)
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode value"
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unable to encode value"
                )
            )
        }
    }
}
