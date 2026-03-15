//
//  DreamVoiceJournalModels.swift
//  DreamLog
//
//  Phase 51: 梦境语音日记与 AI 摘要 - 数据模型
//

import Foundation
import SwiftData
import AVFoundation

// MARK: - 语音日记模型

/// 语音日记主模型
@Model
final class VoiceJournalEntry {
    var id: UUID
    var dreamId: UUID?
    var title: String
    var audioURL: URL
    var duration: TimeInterval  // 秒
    var transcript: String?
    var summary: String?
    var mood: VoiceMood?
    var keywords: [String]
    var isProcessed: Bool
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var isFavorite: Bool
    var playbackSpeed: Float  // 0.5x - 2.0x
    var lastPlayedAt: Date?
    var playCount: Int
    
    @Relationship var dream: Dream?
    
    init(
        id: UUID = UUID(),
        dreamId: UUID? = nil,
        title: String = "",
        audioURL: URL,
        duration: TimeInterval = 0,
        transcript: String? = nil,
        summary: String? = nil,
        mood: VoiceMood? = nil,
        keywords: [String] = [],
        isProcessed: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        isFavorite: Bool = false,
        playbackSpeed: Float = 1.0,
        lastPlayedAt: Date? = nil,
        playCount: Int = 0,
        dream: Dream? = nil
    ) {
        self.id = id
        self.dreamId = dreamId
        self.title = title
        self.audioURL = audioURL
        self.duration = duration
        self.transcript = transcript
        self.summary = summary
        self.mood = mood
        self.keywords = keywords
        self.isProcessed = isProcessed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.isFavorite = isFavorite
        self.playbackSpeed = playbackSpeed
        self.lastPlayedAt = lastPlayedAt
        self.playCount = playCount
        self.dream = dream
    }
}

// MARK: - 语音情绪分析

/// 语音情绪类型
enum VoiceMood: String, CaseIterable, Identifiable, Codable {
    var id: String { rawValue }
    
    case calm = "calm"          // 平静
    case excited = "excited"    // 兴奋
    case anxious = "anxious"    // 焦虑
    case sad = "sad"            // 悲伤
    case confused = "confused"  // 困惑
    case happy = "happy"        // 快乐
    case fearful = "fearful"    // 恐惧
    case neutral = "neutral"    // 中性
    
    var displayName: String {
        switch self {
        case .calm: return "平静"
        case .excited: return "兴奋"
        case .anxious: return "焦虑"
        case .sad: return "悲伤"
        case .confused: return "困惑"
        case .happy: return "快乐"
        case .fearful: return "恐惧"
        case .neutral: return "中性"
        }
    }
    
    var icon: String {
        switch self {
        case .calm: return "😌"
        case .excited: return "🤩"
        case .anxious: return "😰"
        case .sad: return "😢"
        case .confused: return "😕"
        case .happy: return "😊"
        case .fearful: return "😨"
        case .neutral: return "😐"
        }
    }
    
    var color: String {
        switch self {
        case .calm: return "5AC8FA"
        case .excited: return "FF9500"
        case .anxious: return "FF3B30"
        case .sad: return "5856D6"
        case .confused: return "FF2D55"
        case .happy: return "4CD964"
        case .fearful: return "8E8E93"
        case .neutral: return "C7C7CC"
        }
    }
}

// MARK: - 语音处理状态

/// 语音处理状态
enum VoiceProcessingStatus: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    
    case recording = "recording"      // 录音中
    case uploading = "uploading"      // 上传中
    case transcribing = "transcribing" // 转写中
    case analyzing = "analyzing"      // 分析中
    case completed = "completed"      // 已完成
    case failed = "failed"            // 失败
    
    var displayName: String {
        switch self {
        case .recording: return "录音中"
        case .uploading: return "上传中"
        case .transcribing: return "转写中"
        case .analyzing: return "分析中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }
}

// MARK: - 语音配置

/// 语音日记配置
struct VoiceJournalConfig: Codable {
    var audioQuality: AudioQuality
    var autoTranscribe: Bool
    var autoSummarize: Bool
    var autoMoodAnalysis: Bool
    var defaultPlaybackSpeed: Float
    var maxRecordingDuration: TimeInterval  // 秒
    var saveToCloud: Bool
    
    enum AudioQuality: String, CaseIterable, Codable {
        case low = "low"          // 64kbps
        case medium = "medium"    // 128kbps
        case high = "high"        // 256kbps
        case lossless = "lossless" // FLAC
        
        var displayName: String {
            switch self {
            case .low: return "低 (64kbps)"
            case .medium: return "中 (128kbps)"
            case .high: return "高 (256kbps)"
            case .lossless: return "无损 (FLAC)"
            }
        }
        
        var bitRate: Int {
            switch self {
            case .low: return 64
            case .medium: return 128
            case .high: return 256
            case .lossless: return 1411
            }
        }
    }
    
    static var `default`: VoiceJournalConfig {
        VoiceJournalConfig(
            audioQuality: .high,
            autoTranscribe: true,
            autoSummarize: true,
            autoMoodAnalysis: true,
            defaultPlaybackSpeed: 1.0,
            maxRecordingDuration: 300,  // 5 分钟
            saveToCloud: true
        )
    }
}

// MARK: - 语音转写结果

/// 语音转写结果
struct VoiceTranscript: Codable, Identifiable {
    var id: String
    var text: String
    var confidence: Double  // 0-1
    var language: String
    var words: [TranscriptWord]
    var segments: [TranscriptSegment]
    
    struct TranscriptWord: Codable {
        var text: String
        var startTime: TimeInterval
        var endTime: TimeInterval
        var confidence: Double
    }
    
    struct TranscriptSegment: Codable {
        var text: String
        var startTime: TimeInterval
        var endTime: TimeInterval
        var speaker: String?
    }
}

// MARK: - 语音摘要

/// 语音摘要结果
struct VoiceSummary: Codable {
    var title: String
    var summary: String
    var keyPoints: [String]
    var mood: VoiceMood
    var keywords: [String]
    var emotionScores: [String: Double]  // 情绪评分
    var generatedAt: Date
    
    init(
        title: String = "",
        summary: String = "",
        keyPoints: [String] = [],
        mood: VoiceMood = .neutral,
        keywords: [String] = [],
        emotionScores: [String: Double] = [:],
        generatedAt: Date = Date()
    ) {
        self.title = title
        self.summary = summary
        self.keyPoints = keyPoints
        self.mood = mood
        self.keywords = keywords
        self.emotionScores = emotionScores
        self.generatedAt = generatedAt
    }
}

// MARK: - 播放状态

/// 播放器状态
struct VoicePlaybackState: Codable {
    var isPlaying: Bool
    var currentTime: TimeInterval
    var duration: TimeInterval
    var speed: Float
    var volume: Float
    
    static var `default`: VoicePlaybackState {
        VoicePlaybackState(
            isPlaying: false,
            currentTime: 0,
            duration: 0,
            speed: 1.0,
            volume: 1.0
        )
    }
}

// MARK: - 统计数据

/// 语音日记统计
struct VoiceJournalStats: Codable {
    var totalEntries: Int
    var totalDuration: TimeInterval  // 秒
    var totalTranscripts: Int
    var averageDuration: TimeInterval
    var moodDistribution: [String: Int]
    var entriesByDate: [String: Int]  // YYYY-MM-DD: count
    var mostUsedKeywords: [String]
    var favoriteCount: Int
    
    static var empty: VoiceJournalStats {
        VoiceJournalStats(
            totalEntries: 0,
            totalDuration: 0,
            totalTranscripts: 0,
            averageDuration: 0,
            moodDistribution: [:],
            entriesByDate: [:],
            mostUsedKeywords: [],
            favoriteCount: 0
        )
    }
}
