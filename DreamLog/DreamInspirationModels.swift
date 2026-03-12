//
//  DreamInspirationModels.swift
//  DreamLog - Phase 23: Dream Inspiration & Creative Prompts
//
//  梦境灵感与创意提示数据模型
//  将梦境内容转化为创意写作、艺术创作和个人项目的灵感
//

import Foundation
import SwiftData

// MARK: - 创意提示类型

/// 创意提示的类型分类
enum InspirationType: String, Codable, CaseIterable, Identifiable {
    case writing = "写作"
    case art = "艺术"
    case music = "音乐"
    case photography = "摄影"
    case meditation = "冥想"
    case project = "项目"
    case reflection = "反思"
    case challenge = "挑战"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .writing: return "📝"
        case .art: return "🎨"
        case .music: return "🎵"
        case .photography: return "📷"
        case .meditation: return "🧘"
        case .project: return "🚀"
        case .reflection: return "💭"
        case .challenge: return "🎯"
        }
    }
    
    var color: String {
        switch self {
        case .writing: return "8B5CF6"
        case .art: return "EC4899"
        case .music: return "10B981"
        case .photography: return "3B82F6"
        case .meditation: return "F59E0B"
        case .project: return "EF4444"
        case .reflection: return "6366F1"
        case .challenge: return "F97316"
        }
    }
}

// MARK: - 创意提示模型

/// 创意提示数据模型
@Model
final class CreativePrompt: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var description: String
    var type: String
    var difficulty: Int // 1-5
    var estimatedTime: Int // 分钟
    var tags: [String]
    var sourceDreamId: UUID?
    var isFavorite: Bool
    var isCompleted: Bool
    var completedDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: InspirationType,
        difficulty: Int = 3,
        estimatedTime: Int = 30,
        tags: [String] = [],
        sourceDreamId: UUID? = nil,
        isFavorite: Bool = false,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type.rawValue
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.tags = tags
        self.sourceDreamId = sourceDreamId
        self.isFavorite = isFavorite
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var inspirationType: InspirationType {
        InspirationType(rawValue: type) ?? .writing
    }
}

// MARK: - 每日灵感

/// 每日灵感模型
@Model
final class DailyInspiration: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var quote: String
    var prompt: String
    var theme: String
    var relatedDreamIds: [UUID]
    var isViewed: Bool
    var isSaved: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        date: Date = Date(),
        quote: String,
        prompt: String,
        theme: String = "每日灵感",
        relatedDreamIds: [UUID] = [],
        isViewed: Bool = false,
        isSaved: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.quote = quote
        self.prompt = prompt
        self.theme = theme
        self.relatedDreamIds = relatedDreamIds
        self.isViewed = isViewed
        self.isSaved = isSaved
        self.createdAt = createdAt
    }
}

// MARK: - 灵感集合

/// 灵感集合（用于项目或主题）
@Model
final class InspirationCollection: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var theme: String
    var promptIds: [UUID]
    var dreamIds: [UUID]
    var color: String
    var icon: String
    var isPublic: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        theme: String = "",
        promptIds: [UUID] = [],
        dreamIds: [UUID] = [],
        color: String = "8B5CF6",
        icon: String = "✨",
        isPublic: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.theme = theme
        self.promptIds = promptIds
        self.dreamIds = dreamIds
        self.color = color
        self.icon = icon
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - 创意挑战

/// 创意挑战模型（限时挑战）
@Model
final class CreativeChallenge: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var description: String
    var type: String
    var duration: Int // 天数
    var startDate: Date
    var endDate: Date
    var totalPrompts: Int
    var completedPrompts: Int
    var promptIds: [UUID]
    var isCompleted: Bool
    var badge: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: InspirationType,
        duration: Int = 7,
        startDate: Date = Date(),
        totalPrompts: Int = 7,
        completedPrompts: Int = 0,
        promptIds: [UUID] = [],
        isCompleted: Bool = false,
        badge: String = "🏆",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type.rawValue
        self.duration = duration
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate) ?? Date()
        self.totalPrompts = totalPrompts
        self.completedPrompts = completedPrompts
        self.promptIds = promptIds
        self.isCompleted = isCompleted
        self.badge = badge
        self.createdAt = createdAt
    }
    
    var progress: Double {
        guard totalPrompts > 0 else { return 0 }
        return Double(completedPrompts) / Double(totalPrompts)
    }
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

// MARK: - 提示模板

/// 创意提示模板（用于生成提示）
struct PromptTemplate: Codable, Identifiable {
    let id: UUID
    let category: String
    let title: String
    let template: String
    let variables: [String]
    let difficulty: Int
    let estimatedTime: Int
    let tags: [String]
    
    init(
        id: UUID = UUID(),
        category: String,
        title: String,
        template: String,
        variables: [String] = [],
        difficulty: Int = 3,
        estimatedTime: Int = 30,
        tags: [String] = []
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.template = template
        self.variables = variables
        self.difficulty = difficulty
        self.estimatedTime = estimatedTime
        self.tags = tags
    }
}

// MARK: - 灵感统计

/// 灵感使用统计
struct InspirationStatistics: Codable {
    var totalPrompts: Int
    var completedPrompts: Int
    var favoritePrompts: Int
    var totalChallenges: Int
    var completedChallenges: Int
    var activeChallenges: Int
    var streakDays: Int
    var lastPromptDate: Date?
    var promptsByType: [String: Int]
    var averageCompletionTime: Int // 分钟
    
    static var empty: InspirationStatistics {
        InspirationStatistics(
            totalPrompts: 0,
            completedPrompts: 0,
            favoritePrompts: 0,
            totalChallenges: 0,
            completedChallenges: 0,
            activeChallenges: 0,
            streakDays: 0,
            lastPromptDate: nil,
            promptsByType: [:],
            averageCompletionTime: 0
        )
    }
}
