//
//  DreamMoodBoardModels.swift
//  DreamLog
//
//  梦境情绪板数据模型
//  Phase 76 - 梦境情绪板功能
//

import Foundation
import SwiftData

// MARK: - 情绪板数据模型

@Model
final class DreamMoodBoard {
    var id: UUID
    var title: String
    var description: String
    var theme: MoodBoardTheme
    var layout: MoodBoardLayout
    var dreamIds: [UUID]
    var customNotes: [MoodBoardNote]
    var backgroundImage: Data?
    var isPublic: Bool
    var shareCount: Int
    var viewCount: Int
    var createdAt: Date
    var updatedAt: Date
    var lastSharedAt: Date?
    
    // 关联的梦境（通过 dreamIds 查找）
    var dreams: [Dream] {
        // 在实际使用中通过 Service 加载
        []
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        theme: MoodBoardTheme = .starry,
        layout: MoodBoardLayout = .grid,
        dreamIds: [UUID] = [],
        customNotes: [MoodBoardNote] = [],
        backgroundImage: Data? = nil,
        isPublic: Bool = false,
        shareCount: Int = 0,
        viewCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSharedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.theme = theme
        self.layout = layout
        self.dreamIds = dreamIds
        self.customNotes = customNotes
        self.backgroundImage = backgroundImage
        self.isPublic = isPublic
        self.shareCount = shareCount
        self.viewCount = viewCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSharedAt = lastSharedAt
    }
}

// MARK: - 情绪板主题

enum MoodBoardTheme: String, Codable, CaseIterable, Identifiable {
    case starry = "starry"          // 星空紫
    case sunset = "sunset"          // 日落橙
    case ocean = "ocean"            // 海洋蓝
    case forest = "forest"          // 森林绿
    case midnight = "midnight"      // 午夜黑
    case rose = "rose"              // 玫瑰粉
    case gold = "gold"              // 奢华金
    case lavender = "lavender"      // 薰衣草
    case aurora = "aurora"          // 极光绿
    case crystal = "crystal"        // 水晶蓝
    case minimal = "minimal"        // 极简白
    case custom = "custom"          // 自定义
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .starry: return "星空紫"
        case .sunset: return "日落橙"
        case .ocean: return "海洋蓝"
        case .forest: return "森林绿"
        case .midnight: return "午夜黑"
        case .rose: return "玫瑰粉"
        case .gold: return "奢华金"
        case .lavender: return "薰衣草"
        case .aurora: return "极光绿"
        case .crystal: return "水晶蓝"
        case .minimal: return "极简白"
        case .custom: return "自定义"
        }
    }
    
    var primaryColor: String {
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
        case .minimal: return "#F7FAFC"
        case .custom: return "#000000"
        }
    }
    
    var gradientColors: [String] {
        switch self {
        case .starry: return ["#1A1C3A", "#4C1D95", "#6B46C1"]
        case .sunset: return ["#C53030", "#DD6B20", "#ED8936"]
        case .ocean: return ["#1A365D", "#2C5282", "#4299E1"]
        case .forest: return ["#1A472A", "#2F855A", "#48BB78"]
        case .midnight: return ["#000000", "#1A202C", "#2D3748"]
        case .rose: return ["#831843", "#BE185D", "#EC4899"]
        case .gold: return ["#744210", "#B7791F", "#D69E2E"]
        case .lavender: return ["#44337A", "#6B46C1", "#9F7AEA"]
        case .aurora: return ["#234E52", "#319795", "#38B2AC"]
        case .crystal: return ["#2C5282", "#4299E1", "#63B3ED"]
        case .minimal: return ["#FFFFFF", "#F7FAFC", "#EDF2F7"]
        case .custom: return ["#000000", "#333333", "#666666"]
        }
    }
}

// MARK: - 情绪板布局

enum MoodBoardLayout: String, Codable, CaseIterable, Identifiable {
    case grid = "grid"              // 网格布局
    case freeform = "freeform"      // 自由布局
    case timeline = "timeline"      // 时间线布局
    case collage = "collage"        // 拼贴布局
    case masonry = "masonry"        // 瀑布流布局
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .grid: return "网格布局"
        case .freeform: return "自由布局"
        case .timeline: return "时间线"
        case .collage: return "拼贴画"
        case .masonry: return "瀑布流"
        }
    }
}

// MARK: - 情绪板笔记

struct MoodBoardNote: Codable, Identifiable, Hashable {
    var id: UUID
    var content: String
    var position: CGPointCodable
    var fontSize: CGFloat
    var fontColor: String
    var rotation: Double
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        content: String,
        position: CGPointCodable = CGPointCodable(x: 0, y: 0),
        fontSize: CGFloat = 16,
        fontColor: String = "#FFFFFF",
        rotation: Double = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.position = position
        self.fontSize = fontSize
        self.fontColor = fontColor
        self.rotation = rotation
        self.createdAt = createdAt
    }
}

// MARK: - 可编码的 CGPoint

struct CGPointCodable: Codable, Hashable {
    var x: CGFloat
    var y: CGFloat
    
    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        x = try container.decode(CGFloat.self, forKey: .x)
        y = try container.decode(CGFloat.self, forKey: .y)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

// MARK: - 情绪板梦境项

struct MoodBoardDreamItem: Identifiable, Hashable {
    let id: UUID
    let dreamId: UUID
    let title: String
    let content: String
    let emotions: [String]
    let tags: [String]
    let clarity: Int
    let isLucid: Bool
    let date: Date
    let aiArtImage: Data?
    var position: CGPointCodable
    var scale: CGFloat
    var rotation: Double
    
    init(
        id: UUID = UUID(),
        dreamId: UUID,
        title: String,
        content: String,
        emotions: [String],
        tags: [String],
        clarity: Int,
        isLucid: Bool,
        date: Date,
        aiArtImage: Data? = nil,
        position: CGPointCodable = CGPointCodable(x: 0, y: 0),
        scale: CGFloat = 1.0,
        rotation: Double = 0
    ) {
        self.id = id
        self.dreamId = dreamId
        self.title = title
        self.content = content
        self.emotions = emotions
        self.tags = tags
        self.clarity = clarity
        self.isLucid = isLucid
        self.date = date
        self.aiArtImage = aiArtImage
        self.position = position
        self.scale = scale
        self.rotation = rotation
    }
}

// MARK: - 情绪板统计

struct MoodBoardStats: Codable {
    let totalBoards: Int
    let publicBoards: Int
    let privateBoards: Int
    let totalShares: Int
    let totalViews: Int
    let favoriteTheme: MoodBoardTheme?
    let favoriteLayout: MoodBoardLayout?
    let averageDreamsPerBoard: Double
    let createdAt: Date
    let updatedAt: Date
    
    init(
        totalBoards: Int = 0,
        publicBoards: Int = 0,
        privateBoards: Int = 0,
        totalShares: Int = 0,
        totalViews: Int = 0,
        favoriteTheme: MoodBoardTheme? = nil,
        favoriteLayout: MoodBoardLayout? = nil,
        averageDreamsPerBoard: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.totalBoards = totalBoards
        self.publicBoards = publicBoards
        self.privateBoards = privateBoards
        self.totalShares = totalShares
        self.totalViews = totalViews
        self.favoriteTheme = favoriteTheme
        self.favoriteLayout = favoriteLayout
        self.averageDreamsPerBoard = averageDreamsPerBoard
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 情绪板分享卡片

struct MoodBoardShareCard: Codable {
    let boardId: UUID
    let boardTitle: String
    let boardDescription: String
    let theme: MoodBoardTheme
    let dreamCount: Int
    let previewImages: [Data]
    let shareCode: String
    let expiresAt: Date
    let createdAt: Date
    
    init(
        boardId: UUID,
        boardTitle: String,
        boardDescription: String,
        theme: MoodBoardTheme,
        dreamCount: Int,
        previewImages: [Data] = [],
        shareCode: String = "",
        expiresAt: Date = Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 天
        createdAt: Date = Date()
    ) {
        self.boardId = boardId
        self.boardTitle = boardTitle
        self.boardDescription = boardDescription
        self.theme = theme
        self.dreamCount = dreamCount
        self.previewImages = previewImages
        self.shareCode = shareCode.isEmpty ? generateShareCode() : shareCode
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
    
    private func generateShareCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).map { _ in chars.randomElement()! })
    }
}

// MARK: - 情绪板创建配置

struct MoodBoardCreationConfig: Codable {
    var title: String
    var description: String
    var theme: MoodBoardTheme
    var layout: MoodBoardLayout
    var dreamIds: [UUID]
    var isPublic: Bool
    var autoGenerateAI: Bool
    var includeEmotions: Bool
    var includeTags: Bool
    var includeDate: Bool
    
    init(
        title: String = "",
        description: String = "",
        theme: MoodBoardTheme = .starry,
        layout: MoodBoardLayout = .grid,
        dreamIds: [UUID] = [],
        isPublic: Bool = false,
        autoGenerateAI: Bool = true,
        includeEmotions: Bool = true,
        includeTags: Bool = true,
        includeDate: Bool = true
    ) {
        self.title = title
        self.description = description
        self.theme = theme
        self.layout = layout
        self.dreamIds = dreamIds
        self.isPublic = isPublic
        self.autoGenerateAI = autoGenerateAI
        self.includeEmotions = includeEmotions
        self.includeTags = includeTags
        self.includeDate = includeDate
    }
}
