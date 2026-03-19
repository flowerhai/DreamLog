//
//  DreamStoryModels.swift
//  DreamLog
//
//  梦境故事模式数据模型
//  Phase 70: Dream Story Mode - 将相关梦境串联成视觉故事
//

import Foundation
import SwiftData

// MARK: - 梦境故事数据模型

/// 梦境故事主模型
@Model
final class DreamStory {
    var id: UUID
    var title: String
    var description: String
    var coverEmoji: String
    var theme: DreamStoryTheme
    var storyType: DreamStoryType
    var dreams: [Dream]
    var frames: [DreamStoryFrame]
    var createdAt: Date
    var updatedAt: Date
    var isPublic: Bool
    var viewCount: Int
    var likeCount: Int
    var shareCount: Int
    var tags: [String]
    var duration: TimeInterval // 故事总时长（秒）
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        coverEmoji: String = "🌙",
        theme: DreamStoryTheme = .starry,
        storyType: DreamStoryType = .chronological,
        dreams: [Dream] = [],
        frames: [DreamStoryFrame] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPublic: Bool = false,
        viewCount: Int = 0,
        likeCount: Int = 0,
        shareCount: Int = 0,
        tags: [String] = [],
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverEmoji = coverEmoji
        self.theme = theme
        self.storyType = storyType
        self.dreams = dreams
        self.frames = frames
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPublic = isPublic
        self.viewCount = viewCount
        self.likeCount = likeCount
        self.shareCount = shareCount
        self.tags = tags
        self.duration = duration
    }
}

/// 梦境故事主题
enum DreamStoryTheme: String, Codable, CaseIterable {
    case starry = "starry"          // 星空紫
    case sunset = "sunset"          // 日落橙
    case ocean = "ocean"            // 海洋蓝
    case forest = "forest"          // 森林绿
    case midnight = "midnight"      // 午夜黑
    case rose = "rose"              // 玫瑰粉
    case luxury = "luxury"          // 奢华金
    case lavender = "lavender"      // 薰衣草
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
        case .luxury: return "奢华金"
        case .lavender: return "薰衣草"
        case .aurora: return "极光绿"
        case .crystal: return "水晶蓝"
        }
    }
    
    var colors: [String] {
        switch self {
        case .starry: return ["#4A148C", "#7B1FA2", "#9C27B0"]
        case .sunset: return ["#FF6F00", "#FF8F00", "#FFA726"]
        case .ocean: return ["#0D47A1", "#1976D2", "#42A5F5"]
        case .forest: return ["#1B5E20", "#388E3C", "#66BB6A"]
        case .midnight: return ["#000000", "#1A1A2E", "#16213E"]
        case .rose: return ["#880E4F", "#C2185B", "#E91E63"]
        case .luxury: return ["#B8860B", "#DAA520", "#FFD700"]
        case .lavender: return ["#4A148C", "#7B5BA3", "#B39DDB"]
        case .aurora: return ["#004D40", "#00796B", "#4DB6AC"]
        case .crystal: return ["#01579B", "#0288D1", "#4FC3F7"]
        }
    }
}

/// 梦境故事类型
enum DreamStoryType: String, Codable, CaseIterable {
    case chronological = "chronological"    // 时间顺序
    case thematic = "thematic"              // 主题串联
    case emotional = "emotional"            // 情绪流动
    case lucid = "lucid"                    // 清醒梦之旅
    case creative = "creative"              // 创意灵感
    case healing = "healing"                // 疗愈转化
    
    var displayName: String {
        switch self {
        case .chronological: return "时间顺序"
        case .thematic: return "主题串联"
        case .emotional: return "情绪流动"
        case .lucid: return "清醒梦之旅"
        case .creative: return "创意灵感"
        case .healing: return "疗愈转化"
        }
    }
    
    var description: String {
        switch self {
        case .chronological: return "按时间顺序讲述梦境故事"
        case .thematic: return "围绕特定主题串联梦境"
        case .emotional: return "跟随情绪变化展开故事"
        case .lucid: return "记录清醒梦的探索旅程"
        case .creative: return "展现创意启发的梦境"
        case .healing: return "转化负面情绪的疗愈之旅"
        }
    }
}

/// 梦境故事帧（每一页）
@Model
final class DreamStoryFrame {
    var id: UUID
    var storyId: UUID
    var dreamId: UUID
    var order: Int
    var title: String
    var content: String
    var aiArtImage: Data?
    var aiArtPrompt: String
    var transition: DreamStoryTransition
    var duration: TimeInterval // 该帧显示时长
    var narration: String? // 旁白文本
    var backgroundMusic: String?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        storyId: UUID,
        dreamId: UUID,
        order: Int,
        title: String,
        content: String,
        aiArtImage: Data? = nil,
        aiArtPrompt: String = "",
        transition: DreamStoryTransition = .fade,
        duration: TimeInterval = 5.0,
        narration: String? = nil,
        backgroundMusic: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.storyId = storyId
        self.dreamId = dreamId
        self.order = order
        self.title = title
        self.content = content
        self.aiArtImage = aiArtImage
        self.aiArtPrompt = aiArtPrompt
        self.transition = transition
        self.duration = duration
        self.narration = narration
        self.backgroundMusic = backgroundMusic
        self.createdAt = createdAt
    }
}

/// 转场效果
enum DreamStoryTransition: String, Codable, CaseIterable {
    case fade = "fade"                  // 淡入淡出
    case slide = "slide"                // 滑动
    case zoom = "zoom"                  // 缩放
    case dissolve = "dissolve"          // 溶解
    case pageTurn = "pageTurn"          // 翻页
    case morph = "morph"                // 变形
    
    var displayName: String {
        switch self {
        case .fade: return "淡入淡出"
        case .slide: return "滑动"
        case .zoom: return "缩放"
        case .dissolve: return "溶解"
        case .pageTurn: return "翻页"
        case .morph: return "变形"
        }
    }
}

// MARK: - 故事创建配置

/// 故事创建配置
struct DreamStoryConfig {
    var title: String
    var description: String
    var selectedDreams: [UUID]
    var theme: DreamStoryTheme
    var storyType: DreamStoryType
    var autoGenerateArt: Bool
    var autoGenerateNarration: Bool
    var frameDuration: TimeInterval
    var transition: DreamStoryTransition
    var backgroundMusic: String?
    var coverEmoji: String
    var tags: [String]
    var isPublic: Bool
    
    init(
        title: String,
        description: String = "",
        selectedDreams: [UUID] = [],
        theme: DreamStoryTheme = .starry,
        storyType: DreamStoryType = .chronological,
        autoGenerateArt: Bool = true,
        autoGenerateNarration: Bool = true,
        frameDuration: TimeInterval = 5.0,
        transition: DreamStoryTransition = .fade,
        backgroundMusic: String? = nil,
        coverEmoji: String = "🌙",
        tags: [String] = [],
        isPublic: Bool = false
    ) {
        self.title = title
        self.description = description
        self.selectedDreams = selectedDreams
        self.theme = theme
        self.storyType = storyType
        self.autoGenerateArt = autoGenerateArt
        self.autoGenerateNarration = autoGenerateNarration
        self.frameDuration = frameDuration
        self.transition = transition
        self.backgroundMusic = backgroundMusic
        self.coverEmoji = coverEmoji
        self.tags = tags
        self.isPublic = isPublic
    }
}

// MARK: - 故事统计

/// 梦境故事统计
struct DreamStoryStats {
    var totalStories: Int
    var totalFrames: Int
    var totalViews: Int
    var totalLikes: Int
    var totalShares: Int
    var averageDuration: TimeInterval
    var favoriteTheme: DreamStoryTheme?
    var favoriteType: DreamStoryType?
    var recentStories: [DreamStory]
    
    init(
        totalStories: Int = 0,
        totalFrames: Int = 0,
        totalViews: Int = 0,
        totalLikes: Int = 0,
        totalShares: Int = 0,
        averageDuration: TimeInterval = 0,
        favoriteTheme: DreamStoryTheme? = nil,
        favoriteType: DreamStoryType? = nil,
        recentStories: [DreamStory] = []
    ) {
        self.totalStories = totalStories
        self.totalFrames = totalFrames
        self.totalViews = totalViews
        self.totalLikes = totalLikes
        self.totalShares = totalShares
        self.averageDuration = averageDuration
        self.favoriteTheme = favoriteTheme
        self.favoriteType = favoriteType
        self.recentStories = recentStories
    }
}

// MARK: - 故事分享

/// 故事分享卡片数据
struct DreamStoryShareCard {
    var storyId: UUID
    var title: String
    var coverImage: Data?
    var frameCount: Int
    var duration: TimeInterval
    var theme: DreamStoryTheme
    var shareUrl: String
    var qrCode: Data?
    var expiresAt: Date
    
    init(
        storyId: UUID,
        title: String,
        coverImage: Data? = nil,
        frameCount: Int,
        duration: TimeInterval,
        theme: DreamStoryTheme,
        shareUrl: String = "",
        qrCode: Data? = nil,
        expiresAt: Date = Date().addingTimeInterval(7 * 24 * 3600)
    ) {
        self.storyId = storyId
        self.title = title
        self.coverImage = coverImage
        self.frameCount = frameCount
        self.duration = duration
        self.theme = theme
        self.shareUrl = shareUrl
        self.qrCode = qrCode
        self.expiresAt = expiresAt
    }
}
