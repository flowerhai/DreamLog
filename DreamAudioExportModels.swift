//
//  DreamAudioExportModels.swift
//  DreamLog
//
//  梦境音频导出 - 数据模型
//  Phase 39: 梦境播客/音频导出功能
//

import Foundation
import SwiftData

// MARK: - 音频导出配置

/// 音频导出格式
enum AudioExportFormat: String, Codable, CaseIterable {
    case m4a = "m4a"      // AAC 编码，iOS 原生支持
    case mp3 = "mp3"      // 通用格式
    case wav = "wav"      // 无损格式
    
    var displayName: String {
        switch self {
        case .m4a: return "M4A (推荐)"
        case .mp3: return "MP3"
        case .wav: return "WAV (无损)"
        }
    }
    
    var mimeType: String {
        switch self {
        case .m4a: return "audio/mp4"
        case .mp3: return "audio/mpeg"
        case .wav: return "audio/wav"
        }
    }
}

/// 音频质量设置
enum AudioQuality: String, Codable, CaseIterable {
    case low = "low"          // 64 kbps
    case medium = "medium"    // 128 kbps
    case high = "high"        // 256 kbps
    case lossless = "lossless" // 无损
    
    var displayName: String {
        switch self {
        case .low: return "标准 (64 kbps)"
        case .medium: return "高质量 (128 kbps)"
        case .high: return "最佳 (256 kbps)"
        case .lossless: return "无损 (WAV)"
        }
    }
    
    var bitRate: Int {
        switch self {
        case .low: return 64000
        case .medium: return 128000
        case .high: return 256000
        case .lossless: return 1411000
        }
    }
}

/// 音频导出范围
enum AudioExportRange: String, Codable, CaseIterable {
    case all = "all"              // 全部梦境
    case last7Days = "last7Days"  // 最近 7 天
    case last30Days = "last30Days" // 最近 30 天
    case custom = "custom"        // 自定义范围
    
    var displayName: String {
        switch self {
        case .all: return "全部梦境"
        case .last7Days: return "最近 7 天"
        case .last30Days: return "最近 30 天"
        case .custom: return "自定义范围"
        }
    }
}

/// 音频导出配置
@Model
final class AudioExportConfig {
    var id: UUID
    var name: String
    var format: String
    var quality: String
    var exportRange: String
    var includeTags: Bool
    var includeEmotions: Bool
    var includeAIAnalysis: Bool
    var includeIntro: Bool
    var includeOutro: Bool
    var voiceIdentifier: String
    var speechRate: Float
    var pitchMultiplier: Float
    var volume: Float
    var addBackgroundMusic: Bool
    var backgroundMusicVolume: Float
    var createdAt: Date
    
    init(
        name: String = "我的导出配置",
        format: AudioExportFormat = .m4a,
        quality: AudioQuality = .high,
        exportRange: AudioExportRange = .last7Days,
        includeTags: Bool = true,
        includeEmotions: Bool = true,
        includeAIAnalysis: Bool = true,
        includeIntro: Bool = true,
        includeOutro: Bool = true,
        voiceIdentifier: String = "com.apple.voice.compiled.zh-CN.Ting-Ting",
        speechRate: Float = 0.5,
        pitchMultiplier: Float = 1.0,
        volume: Float = 1.0,
        addBackgroundMusic: Bool = false,
        backgroundMusicVolume: Float = 0.3,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.format = format.rawValue
        self.quality = quality.rawValue
        self.exportRange = exportRange.rawValue
        self.includeTags = includeTags
        self.includeEmotions = includeEmotions
        self.includeAIAnalysis = includeAIAnalysis
        self.includeIntro = includeIntro
        self.includeOutro = includeOutro
        self.voiceIdentifier = voiceIdentifier
        self.speechRate = speechRate
        self.pitchMultiplier = pitchMultiplier
        self.volume = volume
        self.addBackgroundMusic = addBackgroundMusic
        self.backgroundMusicVolume = backgroundMusicVolume
        self.createdAt = createdAt
    }
}

// MARK: - 音频导出任务

/// 音频导出任务状态
enum AudioExportStatus: String, Codable {
    case pending = "pending"        // 等待中
    case processing = "processing"  // 处理中
    case completed = "completed"    // 已完成
    case failed = "failed"          // 失败
    case cancelled = "cancelled"    // 已取消
}

/// 音频导出任务
@Model
final class AudioExportTask {
    var id: UUID
    var configId: UUID
    var name: String
    var status: String
    var progress: Double
    var totalDreams: Int
    var processedDreams: Int
    var outputURL: String?
    var fileSize: Int64
    var duration: TimeInterval
    var errorMessage: String?
    var createdAt: Date
    var completedAt: Date?
    
    init(
        configId: UUID,
        name: String,
        status: AudioExportStatus = .pending,
        progress: Double = 0,
        totalDreams: Int = 0,
        processedDreams: Int = 0,
        outputURL: String? = nil,
        fileSize: Int64 = 0,
        duration: TimeInterval = 0,
        errorMessage: String? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = UUID()
        self.configId = configId
        self.name = name
        self.status = status.rawValue
        self.progress = progress
        self.totalDreams = totalDreams
        self.processedDreams = processedDreams
        self.outputURL = outputURL
        self.fileSize = fileSize
        self.duration = duration
        self.errorMessage = errorMessage
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

// MARK: - 音频片段

/// 音频片段类型
enum AudioSegmentType: String, Codable {
    case intro = "intro"            // 片头
    case dream = "dream"            // 梦境内容
    case outro = "outro"            // 片尾
    case transition = "transition"  // 过渡音效
    case background = "background"  // 背景音乐
}

/// 音频片段
struct AudioSegment: Codable, Identifiable {
    let id: UUID
    let type: AudioSegmentType
    let text: String?
    let duration: TimeInterval
    let url: URL?
    let startTime: TimeInterval
    let endTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        type: AudioSegmentType,
        text: String? = nil,
        duration: TimeInterval,
        url: URL? = nil,
        startTime: TimeInterval,
        endTime: TimeInterval
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.duration = duration
        self.url = url
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - 导出统计

/// 音频导出统计
struct AudioExportStats: Codable {
    let totalExports: Int
    let totalDuration: TimeInterval
    let totalFileSize: Int64
    let averageDuration: TimeInterval
    let averageFileSize: Int64
    let exportsByFormat: [String: Int]
    let exportsByQuality: [String: Int]
    let lastExportDate: Date?
    
    static var empty: AudioExportStats {
        AudioExportStats(
            totalExports: 0,
            totalDuration: 0,
            totalFileSize: 0,
            averageDuration: 0,
            averageFileSize: 0,
            exportsByFormat: [:],
            exportsByQuality: [:],
            lastExportDate: nil
        )
    }
}

// MARK: - 预设配置

/// 预设音频导出配置
struct PresetAudioExportConfig: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let format: AudioExportFormat
    let quality: AudioQuality
    let includeTags: Bool
    let includeEmotions: Bool
    let includeAIAnalysis: Bool
    let includeIntro: Bool
    let includeOutro: Bool
    let addBackgroundMusic: Bool
    
    static let presets: [PresetAudioExportConfig] = [
        PresetAudioExportConfig(
            id: UUID(),
            name: "快速分享",
            description: "小文件，适合快速分享",
            icon: "🚀",
            format: .m4a,
            quality: .low,
            includeTags: true,
            includeEmotions: false,
            includeAIAnalysis: false,
            includeIntro: true,
            includeOutro: true,
            addBackgroundMusic: false
        ),
        PresetAudioExportConfig(
            id: UUID(),
            name: "高质量播客",
            description: "最佳音质，完整内容",
            icon: "🎙️",
            format: .m4a,
            quality: .high,
            includeTags: true,
            includeEmotions: true,
            includeAIAnalysis: true,
            includeIntro: true,
            includeOutro: true,
            addBackgroundMusic: true
        ),
        PresetAudioExportConfig(
            id: UUID(),
            name: "无损存档",
            description: "无损格式，永久保存",
            icon: "💾",
            format: .wav,
            quality: .lossless,
            includeTags: true,
            includeEmotions: true,
            includeAIAnalysis: true,
            includeIntro: false,
            includeOutro: false,
            addBackgroundMusic: false
        ),
        PresetAudioExportConfig(
            id: UUID(),
            name: "睡眠回顾",
            description: "柔和背景音乐，适合睡前回顾",
            icon: "🌙",
            format: .m4a,
            quality: .medium,
            includeTags: false,
            includeEmotions: true,
            includeAIAnalysis: false,
            includeIntro: true,
            includeOutro: true,
            addBackgroundMusic: true
        )
    ]
}
