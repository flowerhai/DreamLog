//
//  DreamPlaylistModels.swift
//  DreamLog - Phase 59: Dream Playlist System
//
//  Created by DreamLog Team on 2026-03-17.
//  梦境播放列表数据模型
//

import Foundation
import SwiftData

// MARK: - DreamPlaylist (梦境播放列表)

@Model
final class DreamPlaylist {
    var id: UUID
    var title: String
    var description: String
    var coverEmoji: String
    var themeColor: PlaylistThemeColor
    var isPublic: Bool
    var createdAt: Date
    var updatedAt: Date
    var playCount: Int
    var shareCount: Int
    var orderType: PlaylistOrderType
    
    @Relationship(deleteRule: .cascade)
    var items: [DreamPlaylistItem]
    
    @Attribute(.unique) var remoteId: String?
    
    init(
        title: String,
        description: String = "",
        coverEmoji: String = "🎵",
        themeColor: PlaylistThemeColor = .starry,
        isPublic: Bool = false,
        orderType: PlaylistOrderType = .manual
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.coverEmoji = coverEmoji
        self.themeColor = themeColor
        self.isPublic = isPublic
        self.createdAt = Date()
        self.updatedAt = Date()
        self.playCount = 0
        self.shareCount = 0
        self.orderType = orderType
        self.items = []
    }
    
    var itemCount: Int {
        items.count
    }
    
    var totalDuration: TimeInterval {
        items.reduce(0) { $0 + ($1.dream?.audioDuration ?? 0) }
    }
    
    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        if minutes < 60 {
            return "\(minutes) 分钟"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return "\(hours)小时\(mins)分钟"
        }
    }
}

// MARK: - DreamPlaylistItem (播放列表项)

@Model
final class DreamPlaylistItem {
    var id: UUID
    var position: Int
    var addedAt: Date
    var notes: String?
    
    @Relationship var dream: Dream?
    @Relationship var playlist: DreamPlaylist?
    
    init(dream: Dream, position: Int = 0, notes: String? = nil) {
        self.id = UUID()
        self.dream = dream
        self.position = position
        self.addedAt = Date()
        self.notes = notes
    }
}

// MARK: - PlaylistThemeColor (播放列表主题色)

enum PlaylistThemeColor: String, Codable, CaseIterable {
    case starry = "starry"          // 星空紫
    case sunset = "sunset"          // 日落橙
    case ocean = "ocean"            // 海洋蓝
    case forest = "forest"          // 森林绿
    case midnight = "midnight"      // 午夜黑
    case rose = "rose"              // 玫瑰粉
    case gold = "gold"              // 奢华金
    case lavender = "lavender"      // 薰衣草紫
    case aurora = "aurora"          // 极光绿
    case crystal = "crystal"        // 水晶蓝
    
    var displayName: String {
        switch self {
        case .starry: return "星空紫"
        case .sunset: return "日落橙"
        case .ocean: return "海洋蓝"
        case .forest: return "森林绿"
        case .midnight: return "午夜黑"
        case .rose: return "玫瑰粉"
        case .gold: return "奢华金"
        case .lavender: return "薰衣草紫"
        case .aurora: return "极光绿"
        case .crystal: return "水晶蓝"
        }
    }
    
    var startColor: String {
        switch self {
        case .starry: return "#6B46C1"
        case .sunset: return "#ED8936"
        case .ocean: return "#4299E1"
        case .forest: return "#48BB78"
        case .midnight: return "#1A202C"
        case .rose: return "#EC4899"
        case .gold: return "#D69E2E"
        case .lavender: return "#9F7AEA"
        case .aurora: return "#38B2AC"
        case .crystal: return "#63B3ED"
        }
    }
    
    var endColor: String {
        switch self {
        case .starry: return "#4C1D95"
        case .sunset: return "#C05621"
        case .ocean: return "#2B6CB0"
        case .forest: return "#2F855A"
        case .midnight: return "#2D3748"
        case .rose: return "#BE185D"
        case .gold: return "#B7791F"
        case .lavender: return "#805AD5"
        case .aurora: return "#2C7A7B"
        case .crystal: return "#3182CE"
        }
    }
    
    var icon: String {
        switch self {
        case .starry: return "⭐"
        case .sunset: return "🌅"
        case .ocean: return "🌊"
        case .forest: return "🌲"
        case .midnight: return "🌙"
        case .rose: return "🌹"
        case .gold: return "✨"
        case .lavender: return "💜"
        case .aurora: return "🌈"
        case .crystal: return "💎"
        }
    }
}

// MARK: - PlaylistOrderType (排序类型)

enum PlaylistOrderType: String, Codable, CaseIterable {
    case manual = "manual"              // 手动排序
    case dateAsc = "dateAsc"            // 日期升序
    case dateDesc = "dateDesc"          // 日期降序
    case clarityAsc = "clarityAsc"      // 清晰度升序
    case clarityDesc = "clarityDesc"    // 清晰度降序
    case emotion = "emotion"            // 按情绪分组
    
    var displayName: String {
        switch self {
        case .manual: return "手动排序"
        case .dateAsc: return "日期升序"
        case .dateDesc: return "日期降序"
        case .clarityAsc: return "清晰度升序"
        case .clarityDesc: return "清晰度降序"
        case .emotion: return "按情绪分组"
        }
    }
}

// MARK: - PlaylistPreset (预设播放列表模板)

struct PlaylistPreset: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let themeColor: PlaylistThemeColor
    let filterType: PlaylistFilterType
    let suggestedDreams: Int
    
    static let presets: [PlaylistPreset] = [
        PlaylistPreset(
            id: "best_of_week",
            title: "本周精选",
            description: "本周最清晰、最有趣的梦境",
            emoji: "⭐",
            themeColor: .starry,
            filterType: .recentDays(7),
            suggestedDreams: 5
        ),
        PlaylistPreset(
            id: "lucid_dreams",
            title: "清醒梦合集",
            description: "所有清醒梦体验",
            emoji: "🌟",
            themeColor: .crystal,
            filterType: .lucidOnly,
            suggestedDreams: 10
        ),
        PlaylistPreset(
            id: "nightmares",
            title: "噩梦转化",
            description: "面对并转化恐惧的梦境",
            emoji: "🌑",
            themeColor: .midnight,
            filterType: .emotion(.fear),
            suggestedDreams: 8
        ),
        PlaylistPreset(
            id: "flying_dreams",
            title: "飞行梦境",
            description: "自由飞翔的美妙体验",
            emoji: "🕊️",
            themeColor: .ocean,
            filterType: .keyword("飞行"),
            suggestedDreams: 5
        ),
        PlaylistPreset(
            id: "creative_inspiration",
            title: "创意灵感",
            description: "带来创意启发的梦境",
            emoji: "💡",
            themeColor: .gold,
            filterType: .tag("创意"),
            suggestedDreams: 10
        ),
        PlaylistPreset(
            id: "recurring_dreams",
            title: "重复梦境",
            description: "反复出现的梦境模式",
            emoji: "🔄",
            themeColor: .lavender,
            filterType: .recurring,
            suggestedDreams: 8
        ),
        PlaylistPreset(
            id: "peaceful_dreams",
            title: "平静梦境",
            description: "宁静祥和的梦境体验",
            emoji: "🕊️",
            themeColor: .forest,
            filterType: .emotion(.calm),
            suggestedDreams: 10
        ),
        PlaylistPreset(
            id: "adventure_dreams",
            title: "冒险梦境",
            description: "刺激有趣的冒险故事",
            emoji: "🗺️",
            themeColor: .sunset,
            filterType: .tag("冒险"),
            suggestedDreams: 8
        )
    ]
}

// MARK: - PlaylistFilterType (播放列表筛选类型)

enum PlaylistFilterType: Codable {
    case all
    case recentDays(Int)
    case lucidOnly
    case emotion(DreamEmotion)
    case tag(String)
    case keyword(String)
    case recurring
    case custom([UUID])
}

// MARK: - PlaylistExportFormat (播放列表导出格式)

enum PlaylistExportFormat: String, Codable, CaseIterable {
    case pdf = "pdf"
    case audio = "audio"
    case json = "json"
    case markdown = "markdown"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF 文档"
        case .audio: return "音频播客"
        case .json: return "JSON 数据"
        case .markdown: return "Markdown 文本"
        }
    }
    
    var fileExtension: String {
        rawValue
    }
}

// MARK: - PlaylistShareLink (播放列表分享链接)

struct PlaylistShareLink: Codable {
    let id: String
    let playlistId: UUID
    let expiresAt: Date
    var viewCount: Int
    let createdAt: Date
    
    init(playlistId: UUID, expiresAt: Date) {
        self.id = String(UUID().uuidString.prefix(8))
        self.playlistId = playlistId
        self.expiresAt = expiresAt
        self.viewCount = 0
        self.createdAt = Date()
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var shareURL: String {
        "dreamlog://playlist/\(id)"
    }
}

// MARK: - PlaylistStats (播放列表统计)

struct PlaylistStats: Codable {
    let totalPlaylists: Int
    let totalItems: Int
    let totalDuration: TimeInterval
    let mostUsedTheme: PlaylistThemeColor?
    let averageItemsPerPlaylist: Double
    let publicPlaylists: Int
    let totalPlays: Int
    let totalShares: Int
    
    static var empty: PlaylistStats {
        PlaylistStats(
            totalPlaylists: 0,
            totalItems: 0,
            totalDuration: 0,
            mostUsedTheme: nil,
            averageItemsPerPlaylist: 0,
            publicPlaylists: 0,
            totalPlays: 0,
            totalShares: 0
        )
    }
}
