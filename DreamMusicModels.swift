//
//  DreamMusicModels.swift
//  DreamLog - 梦境音乐与氛围音景数据模型
//
//  Phase 86: 梦境音乐与氛围音景 🎵💤✨
//  创建时间：2026-03-21
//

import Foundation
import SwiftData

// MARK: - 音乐曲目模型

/// 音乐曲目数据模型
@Model
final class MusicTrack {
    var id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    var mood: String? // DreamEmotion .rawValue
    var themes: [String]
    var tags: [String]
    var audioURL: String
    var coverArtURL: String?
    var isPremium: Bool
    var isFavorite: Bool
    var playCount: Int
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "DreamLog AI",
        duration: TimeInterval,
        mood: DreamEmotion? = nil,
        themes: [String] = [],
        tags: [String] = [],
        audioURL: String,
        coverArtURL: String? = nil,
        isPremium: Bool = false,
        isFavorite: Bool = false,
        playCount: Int = 0,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.mood = mood?.rawValue
        self.themes = themes
        self.tags = tags
        self.audioURL = audioURL
        self.coverArtURL = coverArtURL
        self.isPremium = isPremium
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.createdDate = createdDate
    }
    
    // MARK: - 计算属性
    
    ///  formatted 时长
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// 情绪枚举
    var emotion: DreamEmotion? {
        get {
            guard let mood = mood else { return nil }
            return DreamEmotion(rawValue: mood)
        }
        set {
            mood = newValue?.rawValue
        }
    }
}

// MARK: - 氛围音景模型

/// 音景分类
enum SoundscapeCategory: String, CaseIterable, Codable {
    case nature = "自然"           // 雨声/海浪/森林
    case city = "城市"             // 交通/人群/咖啡馆
    case indoor = "室内"           // 壁炉/时钟/翻书
    case fantasy = "奇幻"          // 魔法/太空/梦境
    case whiteNoise = "白噪音"     // 粉红/棕色/白噪音
    case meditation = "冥想"       // 双耳节拍/引导音
}

/// 氛围音景数据模型
@Model
final class Soundscape {
    var id: UUID
    var name: String
    var category: String // SoundscapeCategory.rawValue
    var description: String
    var layers: [SoundscapeLayerData]
    var recommendedMoods: [String]
    var recommendedThemes: [String]
    var icon: String
    var color: String // HEX 颜色
    var isPremium: Bool
    var playCount: Int
    var averageRating: Double
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        category: SoundscapeCategory,
        description: String = "",
        layers: [SoundscapeLayerData] = [],
        recommendedMoods: [String] = [],
        recommendedThemes: [String] = [],
        icon: String = "🎵",
        color: String = "#6366F1",
        isPremium: Bool = false,
        playCount: Int = 0,
        averageRating: Double = 0.0,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category.rawValue
        self.description = description
        self.layers = layers
        self.recommendedMoods = recommendedMoods
        self.recommendedThemes = recommendedThemes
        self.icon = icon
        self.color = color
        self.isPremium = isPremium
        self.playCount = playCount
        self.averageRating = averageRating
        self.createdDate = createdDate
    }
    
    // MARK: - 计算属性
    
    /// 分类枚举
    var soundscapeCategory: SoundscapeCategory {
        get {
            SoundscapeCategory(rawValue: category) ?? .nature
        }
        set {
            category = newValue.rawValue
        }
    }
    
    /// 推荐情绪枚举
    var emotions: [DreamEmotion] {
        recommendedMoods.compactMap { DreamEmotion(rawValue: $0) }
    }
}

/// 音景层数据 (Codable, 非 Model)
struct SoundscapeLayerData: Codable, Identifiable {
    var id: UUID
    var soundId: String
    var soundName: String
    var volume: Float // 0.0 - 1.0
    var pan: Float // -1.0 (左) 到 1.0 (右)
    var fadeIn: TimeInterval
    var fadeOut: TimeInterval
    var loop: Bool
    var pitch: Float // 0.5 - 2.0
    
    init(
        id: UUID = UUID(),
        soundId: String,
        soundName: String,
        volume: Float = 0.7,
        pan: Float = 0.0,
        fadeIn: TimeInterval = 2.0,
        fadeOut: TimeInterval = 2.0,
        loop: Bool = true,
        pitch: Float = 1.0
    ) {
        self.id = id
        self.soundId = soundId
        self.soundName = soundName
        self.volume = volume
        self.pan = pan
        self.fadeIn = fadeIn
        self.fadeOut = fadeOut
        self.loop = loop
        self.pitch = pitch
    }
}

// MARK: - 播放列表模型

/// 播放列表数据模型
@Model
final class DreamMusicPlaylist {
    var id: UUID
    var name: String
    var description: String?
    var trackIds: [UUID]
    var soundscapeIds: [UUID]
    var mood: String? // DreamEmotion.rawValue
    var theme: String?
    var coverArtURL: String?
    var isFavorite: Bool
    var playCount: Int
    var createdDate: Date
    var modifiedDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        trackIds: [UUID] = [],
        soundscapeIds: [UUID] = [],
        mood: DreamEmotion? = nil,
        theme: String? = nil,
        coverArtURL: String? = nil,
        isFavorite: Bool = false,
        playCount: Int = 0,
        createdDate: Date = Date(),
        modifiedDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.trackIds = trackIds
        self.soundscapeIds = soundscapeIds
        self.mood = mood?.rawValue
        self.theme = theme
        self.coverArtURL = coverArtURL
        self.isFavorite = isFavorite
        self.playCount = playCount
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
    }
    
    // MARK: - 计算属性
    
    /// 情绪枚举
    var emotion: DreamEmotion? {
        get {
            guard let mood = mood else { return nil }
            return DreamEmotion(rawValue: mood)
        }
        set {
            mood = newValue?.rawValue
        }
    }
}

// MARK: - 播放历史模型

/// 播放历史数据模型
@Model
final class MusicPlaybackHistory {
    var id: UUID
    var trackId: UUID?
    var soundscapeId: UUID?
    var playlistId: UUID?
    var dreamId: UUID?
    var playedDate: Date
    var playDuration: TimeInterval
    var completed: Bool
    var rating: Int? // 1-5
    var context: String? // 播放上下文
    
    init(
        id: UUID = UUID(),
        trackId: UUID? = nil,
        soundscapeId: UUID? = nil,
        playlistId: UUID? = nil,
        dreamId: UUID? = nil,
        playedDate: Date = Date(),
        playDuration: TimeInterval = 0,
        completed: Bool = false,
        rating: Int? = nil,
        context: String? = nil
    ) {
        self.id = id
        self.trackId = trackId
        self.soundscapeId = soundscapeId
        self.playlistId = playlistId
        self.dreamId = dreamId
        self.playedDate = playedDate
        self.playDuration = playDuration
        self.completed = completed
        self.rating = rating
        self.context = context
    }
}

// MARK: - 音频导出模型

/// 音频导出配置
struct AudioExportConfig: Codable {
    var format: AudioExportFormat
    var quality: AudioQuality
    var includeMetadata: Bool
    var coverArt: Bool
    var fadeOut: TimeInterval
    
    init(
        format: AudioExportFormat = .mp3,
        quality: AudioQuality = .high,
        includeMetadata: Bool = true,
        coverArt: Bool = true,
        fadeOut: TimeInterval = 3.0
    ) {
        self.format = format
        self.quality = quality
        self.includeMetadata = includeMetadata
        self.coverArt = coverArt
        self.fadeOut = fadeOut
    }
}

/// 音频导出格式
enum AudioExportFormat: String, Codable, CaseIterable {
    case mp3 = "MP3"
    case m4a = "M4A"
    case wav = "WAV"
    
    var fileExtension: String {
        rawValue.lowercased()
    }
    
    var mimeType: String {
        switch self {
        case .mp3: return "audio/mpeg"
        case .m4a: return "audio/mp4"
        case .wav: return "audio/wav"
        }
    }
}

/// 音频质量
enum AudioQuality: String, Codable, CaseIterable {
    case low = "低"      // 128 kbps
    case medium = "中"   // 256 kbps
    case high = "高"     // 320 kbps
    case lossless = "无损" // WAV
    
    var bitrate: Int? {
        switch self {
        case .low: return 128
        case .medium: return 256
        case .high: return 320
        case .lossless: return nil
        }
    }
}

// MARK: - 睡眠定时器模型

/// 睡眠定时器配置
struct SleepTimerConfig: Codable {
    var enabled: Bool
    var duration: TimeInterval // 秒
    var fadeOutDuration: TimeInterval
    var action: SleepTimerAction
    
    init(
        enabled: Bool = false,
        duration: TimeInterval = 1800, // 30 分钟
        fadeOutDuration: TimeInterval = 30,
        action: SleepTimerAction = .stop
    ) {
        self.enabled = enabled
        self.duration = duration
        self.fadeOutDuration = fadeOutDuration
        self.action = action
    }
    
    /// formatted 时长
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)小时\(remainingMinutes)分钟" : "\(hours)小时"
        }
        return "\(minutes)分钟"
    }
    
    /// 预设时长
    static let presets: [(TimeInterval, String)] = [
        (900, "15 分钟"),
        (1800, "30 分钟"),
        (3600, "1 小时"),
        (5400, "1.5 小时"),
        (7200, "2 小时")
    ]
}

/// 睡眠定时器动作
enum SleepTimerAction: String, Codable {
    case stop = "停止播放"
    case lowerVolume = "降低音量"
    case switchToWhiteNoise = "切换到白噪音"
}

// MARK: - 音乐推荐配置

/// 音乐推荐配置
struct MusicRecommendationConfig: Codable {
    var enableMoodMatching: Bool
    var enableThemeMatching: Bool
    var enableTimeMatching: Bool
    var enableHistoryLearning: Bool
    var diversityFactor: Double // 0.0 (完全匹配) - 1.0 (完全随机)
    
    init(
        enableMoodMatching: Bool = true,
        enableThemeMatching: Bool = true,
        enableTimeMatching: Bool = true,
        enableHistoryLearning: Bool = true,
        diversityFactor: Double = 0.2
    ) {
        self.enableMoodMatching = enableMoodMatching
        self.enableThemeMatching = enableThemeMatching
        self.enableTimeMatching = enableTimeMatching
        self.enableHistoryLearning = enableHistoryLearning
        self.diversityFactor = diversityFactor
    }
}

// MARK: - 音景预设模板

/// 音景预设模板
struct SoundscapePreset: Codable, Identifiable {
    var id: UUID
    var name: String
    var icon: String
    var layers: [SoundscapeLayerData]
    var recommendedMoods: [String]
    var color: String
    
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        layers: [SoundscapeLayerData],
        recommendedMoods: [String] = [],
        color: String = "#6366F1"
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.layers = layers
        self.recommendedMoods = recommendedMoods
        self.color = color
    }
    
    // MARK: - 预设模板
    
    static let stormyNight = SoundscapePreset(
        name: "暴风雨夜",
        icon: "⛈️",
        layers: [
            SoundscapeLayerData(soundId: "rain_heavy", soundName: "大雨", volume: 0.8),
            SoundscapeLayerData(soundId: "thunder_distant", soundName: "远雷", volume: 0.4, fadeIn: 5, fadeOut: 5),
            SoundscapeLayerData(soundId: "wind", soundName: "风声", volume: 0.3)
        ],
        recommendedMoods: ["平静", "中性"],
        color: "#4C1D95"
    )
    
    static let forestMorning = SoundscapePreset(
        name: "森林清晨",
        icon: "🌲",
        layers: [
            SoundscapeLayerData(soundId: "birds", soundName: "鸟鸣", volume: 0.6),
            SoundscapeLayerData(soundId: "leaves", soundName: "树叶沙沙", volume: 0.3),
            SoundscapeLayerData(soundId: "stream", soundName: "溪流", volume: 0.4)
        ],
        recommendedMoods: ["快乐", "平静"],
        color: "#059669"
    )
    
    static let oceanBeach = SoundscapePreset(
        name: "海边日落",
        icon: "🌊",
        layers: [
            SoundscapeLayerData(soundId: "waves", soundName: "海浪", volume: 0.7),
            SoundscapeLayerData(soundId: "seagulls", soundName: "海鸥", volume: 0.2),
            SoundscapeLayerData(soundId: "wind_light", soundName: "微风", volume: 0.2)
        ],
        recommendedMoods: ["平静", "快乐"],
        color: "#0891B2"
    )
    
    static let cozyFireplace = SoundscapePreset(
        name: "温暖壁炉",
        icon: "🔥",
        layers: [
            SoundscapeLayerData(soundId: "fireplace", soundName: "壁炉", volume: 0.7),
            SoundscapeLayerData(soundId: "clock", soundName: "时钟滴答", volume: 0.2)
        ],
        recommendedMoods: ["平静", "中性"],
        color: "#DC2626"
    )
    
    static let meditation = SoundscapePreset(
        name: "深度冥想",
        icon: "🧘",
        layers: [
            SoundscapeLayerData(soundId: "binaural_theta", soundName: "θ波双耳节拍", volume: 0.5),
            SoundscapeLayerData(soundId: "ambient_drone", soundName: "环境长音", volume: 0.3)
        ],
        recommendedMoods: ["平静"],
        color: "#7C3AED"
    )
    
    static let sleep = SoundscapePreset(
        name: "深度睡眠",
        icon: "😴",
        layers: [
            SoundscapeLayerData(soundId: "pink_noise", soundName: "粉红噪音", volume: 0.5),
            SoundscapeLayerData(soundId: "brown_noise", soundName: "棕色噪音", volume: 0.3)
        ],
        recommendedMoods: ["平静", "中性"],
        color: "#1E1B4B"
    )
    
    static let allPresets: [SoundscapePreset] = [
        .stormyNight, .forestMorning, .oceanBeach,
        .cozyFireplace, .meditation, .sleep
    ]
}

// MARK: - 播放状态模型

/// 播放器状态
struct PlayerState: Codable {
    var isPlaying: Bool
    var currentTime: TimeInterval
    var volume: Float
    var shuffle: Bool
    var repeatMode: RepeatMode
    var sleepTimer: SleepTimerConfig?
    
    init(
        isPlaying: Bool = false,
        currentTime: TimeInterval = 0,
        volume: Float = 0.7,
        shuffle: Bool = false,
        repeatMode: RepeatMode = .off,
        sleepTimer: SleepTimerConfig? = nil
    ) {
        self.isPlaying = isPlaying
        self.currentTime = currentTime
        self.volume = volume
        self.shuffle = shuffle
        self.repeatMode = repeatMode
        self.sleepTimer = sleepTimer
    }
}

/// 循环模式
enum RepeatMode: String, Codable, CaseIterable {
    case off = "关闭"
    case one = "单曲循环"
    case all = "列表循环"
}

// MARK: - 梦境 - 音乐关联

/// 梦境与音乐的关联
@Model
final class DreamMusicAssociation {
    var id: UUID
    var dreamId: UUID
    var trackId: UUID?
    var soundscapeId: UUID?
    var playlistId: UUID?
    var autoGenerated: Bool
    var userSelected: Bool
    var createdDate: Date
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        trackId: UUID? = nil,
        soundscapeId: UUID? = nil,
        playlistId: UUID? = nil,
        autoGenerated: Bool = false,
        userSelected: Bool = false,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.dreamId = dreamId
        self.trackId = trackId
        self.soundscapeId = soundscapeId
        self.playlistId = playlistId
        self.autoGenerated = autoGenerated
        self.userSelected = userSelected
        self.createdDate = createdDate
    }
}

// MARK: - 辅助扩展

extension DreamEmotion {
    /// 获取情绪对应的推荐音景分类
    var recommendedSoundscapeCategories: [SoundscapeCategory] {
        switch self {
        case .平静:
            return [.nature, .meditation, .whiteNoise]
        case .快乐:
            return [.nature, .fantasy]
        case .焦虑:
            return [.whiteNoise, .meditation, .nature]
        case .悲伤:
            return [.nature, .indoor]
        case .困惑:
            return [.meditation, .whiteNoise]
        case .恐惧:
            return [.whiteNoise, .indoor]
        case .兴奋:
            return [.fantasy, .city]
        case .中性:
            return [.nature, .indoor, .whiteNoise]
        }
    }
    
    /// 获取情绪对应的推荐音乐标签
    var recommendedMusicTags: [String] {
        switch self {
        case .平静:
            return ["ambient", "meditation", "soft", "calm"]
        case .快乐:
            return ["upbeat", "cheerful", "bright", "energetic"]
        case .焦虑:
            return ["calming", "soothing", "gentle", "relaxing"]
        case .悲伤:
            return ["melancholic", "emotional", "soft", "reflective"]
        case .困惑:
            return ["mysterious", "ambient", "contemplative"]
        case .恐惧:
            return ["calming", "reassuring", "gentle"]
        case .兴奋:
            return ["energetic", "dynamic", "uplifting"]
        case .中性:
            return ["neutral", "ambient", "background"]
        }
    }
}
