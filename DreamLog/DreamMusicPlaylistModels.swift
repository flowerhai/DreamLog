//
//  DreamMusicPlaylistModels.swift
//  DreamLog - Phase 9: AI Dream Music Enhancement
//
//  Created by DreamLog Team on 2026-03-13
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation

// MARK: - Playlist Models

/// 梦境音乐播放列表
struct DreamMusicPlaylist: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var musicIds: [UUID]  // 音乐 ID 列表
    var coverMood: DreamMusic.DreamMusicMood?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool = false
    var sleepTimer: SleepTimerConfig?
    var playOrder: PlayOrder = .sequential
    var isShared: Bool = false
    var shareCode: String?
    
    /// 播放顺序
    enum PlayOrder: String, Codable, CaseIterable, Identifiable {
        case sequential = "顺序播放"
        case shuffle = "随机播放"
        case repeatOne = "单曲循环"
        case repeatAll = "列表循环"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .sequential: return "arrow.down.to.line"
            case .shuffle: return "shuffle"
            case .repeatOne: return "repeat.1"
            case .repeatAll: return "repeat"
            }
        }
    }
    
    var musicCount: Int {
        musicIds.count
    }
    
    var totalDuration: TimeInterval {
        // 实际实现中从音乐服务获取
        TimeInterval(musicIds.count * 180)  // 假设平均每首 3 分钟
    }
    
    var formattedTotalDuration: String {
        let minutes = Int(totalDuration / 60)
        if minutes < 60 {
            return "\(minutes) 分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)小时\(mins)分钟"
        }
    }
}

/// 睡眠定时器配置
struct SleepTimerConfig: Codable, Equatable {
    var duration: SleepTimerDuration
    var fadeOut: Bool
    var fadeOutDuration: TimeInterval
    var action: SleepTimerAction
    
    /// 睡眠时长选项
    enum SleepTimerDuration: String, Codable, CaseIterable, Identifiable {
        case off = "关闭"
        case minutes15 = "15 分钟"
        case minutes30 = "30 分钟"
        case minutes45 = "45 分钟"
        case minutes60 = "60 分钟"
        case minutes90 = "90 分钟"
        case untilEnd = "播放完毕"
        
        var id: String { rawValue }
        
        var seconds: TimeInterval? {
            switch self {
            case .off: return nil
            case .minutes15: return 15 * 60
            case .minutes30: return 30 * 60
            case .minutes45: return 45 * 60
            case .minutes60: return 60 * 60
            case .minutes90: return 90 * 60
            case .untilEnd: return nil
            }
        }
        
        var icon: String {
            switch self {
            case .off: return "moon.zzz"
            case .minutes15: return "clock.fill"
            case .minutes30: return "clock.fill"
            case .minutes45: return "clock.fill"
            case .minutes60: return "clock.fill"
            case .minutes90: return "clock.fill"
            case .untilEnd: return "play.circle"
            }
        }
    }
    
    /// 定时器结束动作
    enum SleepTimerAction: String, Codable {
        case stop = "停止播放"
        case pause = "暂停播放"
        case lowerVolume = "降低音量"
    }
    
    static var `default`: SleepTimerConfig {
        SleepTimerConfig(
            duration: .off,
            fadeOut: true,
            fadeOutDuration: 30,
            action: .pause
        )
    }
}

/// 播放状态
enum PlaybackState: Equatable {
    case stopped
    case playing(index: Int, progress: TimeInterval)
    case paused(index: Int, progress: TimeInterval)
    case loading(index: Int)
    case error(String)
    
    var isPlaying: Bool {
        if case .playing = self { return true }
        return false
    }
    
    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }
    
    var currentIndex: Int? {
        switch self {
        case .playing(let index, _), .paused(let index, _), .loading(let index):
            return index
        default:
            return nil
        }
    }
}

/// 播放历史
struct PlaybackHistory: Identifiable, Codable {
    let id: UUID
    let playlistId: UUID
    let musicId: UUID
    let playedAt: Date
    var completed: Bool
    var playDuration: TimeInterval
    
    init(playlistId: UUID, musicId: UUID) {
        self.id = UUID()
        self.playlistId = playlistId
        self.musicId = musicId
        self.playedAt = Date()
        self.completed = false
        self.playDuration = 0
    }
}

/// 分享的音乐
struct SharedDreamMusic: Identifiable, Codable {
    let id: UUID
    let musicId: UUID
    let shareCode: String
    let expiresAt: Date
    var viewCount: Int
    var downloadCount: Int
    let createdAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var daysUntilExpiry: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt)
        return components.day ?? 0
    }
}

// MARK: - Playlist Templates

/// 预设播放列表模板
struct PlaylistTemplate: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let mood: DreamMusic.DreamMusicMood
    let suggestedDuration: SleepTimerConfig.SleepTimerDuration
    let iconName: String
    let color: String
    
    static var templates: [PlaylistTemplate] {
        [
            PlaylistTemplate(
                id: UUID(),
                name: "深度睡眠",
                description: "帮助进入深度睡眠的平静音乐",
                mood: .peaceful,
                suggestedDuration: .minutes90,
                iconName: "moon.fill",
                color: "5B91F5"
            ),
            PlaylistTemplate(
                id: UUID(),
                name: "快速入眠",
                description: "15 分钟快速入睡",
                mood: .ethereal,
                suggestedDuration: .minutes15,
                iconName: "moon.stars.fill",
                color: "8B5CF6"
            ),
            PlaylistTemplate(
                id: UUID(),
                name: "午间小憩",
                description: "30 分钟午休音乐",
                mood: .dreamy,
                suggestedDuration: .minutes30,
                iconName: "sun.max.fill",
                color: "F59E0B"
            ),
            PlaylistTemplate(
                id: UUID(),
                name: "冥想放松",
                description: "配合冥想的空灵音乐",
                mood: .mysterious,
                suggestedDuration: .minutes45,
                iconName: "figure.mind.and.body",
                color: "EC4899"
            ),
            PlaylistTemplate(
                id: UUID(),
                name: "清晨唤醒",
                description: "温和的晨间唤醒音乐",
                mood: .joyful,
                suggestedDuration: .minutes30,
                iconName: "sunrise.fill",
                color: "10B981"
            ),
            PlaylistTemplate(
                id: UUID(),
                name: "梦境回顾",
                description: "睡前回顾梦境的音乐",
                mood: .melancholic,
                suggestedDuration: .minutes60,
                iconName: "brain.head.profile",
                color: "64748B"
            )
        ]
    }
}
