//
//  DreamLearningModels.swift
//  DreamLog - Dream Learning Path Data Models
//
//  Phase 82: Dream Learning & Education System
//  Created for comprehensive dream education and skill development
//

import Foundation
import SwiftData

// MARK: - Course Categories

enum DreamLearningCategory: String, Codable, CaseIterable {
    case lucidDreaming = "lucid_dreaming"
    case dreamInterpretation = "dream_interpretation"
    case dreamRecall = "dream_recall"
    case mindfulness = "mindfulness"
    case creativity = "creativity"
    case sleepScience = "sleep_science"
    case wellness = "wellness"
    
    var displayName: String {
        switch self {
        case .lucidDreaming: return "清醒梦训练"
        case .dreamInterpretation: return "梦境解析"
        case .dreamRecall: return "梦境回忆"
        case .mindfulness: return "正念冥想"
        case .creativity: return "创意启发"
        case .sleepScience: return "睡眠科学"
        case .wellness: return "健康福祉"
        }
    }
    
    var icon: String {
        switch self {
        case .lucidDreaming: return "👁️"
        case .dreamInterpretation: return "🔮"
        case .dreamRecall: return "🧠"
        case .mindfulness: return "🧘"
        case .creativity: return "💡"
        case .sleepScience: return "🔬"
        case .wellness: return "💚"
        }
    }
    
    var color: String {
        switch self {
        case .lucidDreaming: return "purple"
        case .dreamInterpretation: return "indigo"
        case .dreamRecall: return "blue"
        case .mindfulness: return "green"
        case .creativity: return "orange"
        case .sleepScience: return "cyan"
        case .wellness: return "pink"
        }
    }
}

// MARK: - Lesson Types

enum DreamLessonType: String, Codable, CaseIterable {
    case video = "video"
    case article = "article"
    case exercise = "exercise"
    case quiz = "quiz"
    case meditation = "meditation"
    case practice = "practice"
    case reflection = "reflection"
    
    var displayName: String {
        switch self {
        case .video: return "视频课程"
        case .article: return "文章阅读"
        case .exercise: return "实践练习"
        case .quiz: return "小测验"
        case .meditation: return "冥想引导"
        case .practice: return "实修训练"
        case .reflection: return "反思日记"
        }
    }
    
    var icon: String {
        switch self {
        case .video: return "🎬"
        case .article: return "📖"
        case .exercise: return "✍️"
        case .quiz: return "📝"
        case .meditation: return "🧘"
        case .practice: return "🎯"
        case .reflection: return "💭"
        }
    }
}

// MARK: - Difficulty Levels

enum DreamDifficultyLevel: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "入门"
        case .intermediate: return "进阶"
        case .advanced: return "高级"
        case .expert: return "专家"
        }
    }
    
    var icon: String {
        switch self {
        case .beginner: return "🌱"
        case .intermediate: return "🌿"
        case .advanced: return "🌳"
        case .expert: return "🌟"
        }
    }
    
    var requiredXP: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 100
        case .advanced: return 300
        case .expert: return 600
        }
    }
}

// MARK: - Achievement Badges

enum DreamLearningBadge: String, Codable, CaseIterable {
    // 学习成就
    case firstLesson = "first_lesson"
    case weekStreak = "week_streak"
    case monthStreak = "month_streak"
    case courseCompleted = "course_completed"
    case allCourses = "all_courses"
    
    // 技能成就
    case lucidMaster = "lucid_master"
    case interpretationExpert = "interpretation_expert"
    case recallChampion = "recall_champion"
    
    // 特殊成就
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case perfectionist = "perfectionist"
    case explorer = "explorer"
    
    var displayName: String {
        switch self {
        case .firstLesson: return "第一课"
        case .weekStreak: return "周坚持者"
        case .monthStreak: return "月坚持者"
        case .courseCompleted: return "课程完成者"
        case .allCourses: return "全知学者"
        case .lucidMaster: return "清醒梦大师"
        case .interpretationExpert: return "解析专家"
        case .recallChampion: return "回忆冠军"
        case .earlyBird: return "晨间学习者"
        case .nightOwl: return "夜间学习者"
        case .perfectionist: return "完美主义者"
        case .explorer: return "探索者"
        }
    }
    
    var description: String {
        switch self {
        case .firstLesson: return "完成第一节课"
        case .weekStreak: return "连续学习 7 天"
        case .monthStreak: return "连续学习 30 天"
        case .courseCompleted: return "完成一门完整课程"
        case .allCourses: return "完成所有课程"
        case .lucidMaster: return "掌握所有清醒梦技巧"
        case .interpretationExpert: return "完成解析课程并获得高分"
        case .recallChampion: return "回忆练习达到 90% 以上"
        case .earlyBird: return "在早上 6-9 点学习 10 次"
        case .nightOwl: return "在晚上 10 点 - 凌晨 2 点学习 10 次"
        case .perfectionist: return "所有测验获得满分"
        case .explorer: return "学习所有类别的课程"
        }
    }
    
    var icon: String {
        switch self {
        case .firstLesson: return "🎉"
        case .weekStreak: return "🔥"
        case .monthStreak: return "💪"
        case .courseCompleted: return "🎓"
        case .allCourses: return "🏆"
        case .lucidMaster: return "👁️"
        case .interpretationExpert: return "🔮"
        case .recallChampion: return "🧠"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🌙"
        case .perfectionist: return "⭐"
        case .explorer: return "🗺️"
        }
    }
    
    var points: Int {
        switch self {
        case .firstLesson: return 10
        case .weekStreak: return 50
        case .monthStreak: return 200
        case .courseCompleted: return 100
        case .allCourses: return 500
        case .lucidMaster: return 300
        case .interpretationExpert: return 250
        case .recallChampion: return 250
        case .earlyBird: return 75
        case .nightOwl: return 75
        case .perfectionist: return 150
        case .explorer: return 200
        }
    }
}

// MARK: - Data Models

@Model
final class DreamLearningCourse {
    @Attribute(.unique) var id: UUID
    var title: String
    var description: String
    var category: String // DreamLearningCategory raw value
    var difficulty: String // DreamDifficultyLevel raw value
    var estimatedHours: Double
    var lessonCount: Int
    var isPublished: Bool
    var sortOrder: Int
    var thumbnail: String?
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade) var lessons: [DreamLearningLesson]
    @Relationship var enrollments: [DreamLearningEnrollment]
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: DreamLearningCategory,
        difficulty: DreamDifficultyLevel,
        estimatedHours: Double,
        lessonCount: Int = 0,
        isPublished: Bool = true,
        sortOrder: Int = 0,
        thumbnail: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category.rawValue
        self.difficulty = difficulty.rawValue
        self.estimatedHours = estimatedHours
        self.lessonCount = lessonCount
        self.isPublished = isPublished
        self.sortOrder = sortOrder
        self.thumbnail = thumbnail
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lessons = []
        self.enrollments = []
    }
    
    var categoryEnum: DreamLearningCategory {
        DreamLearningCategory(rawValue: category) ?? .mindfulness
    }
    
    var difficultyEnum: DreamDifficultyLevel {
        DreamDifficultyLevel(rawValue: difficulty) ?? .beginner
    }
}

@Model
final class DreamLearningLesson {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var lessonType: String // DreamLessonType raw value
    var duration: Int // in minutes
    var orderIndex: Int
    var videoURL: String?
    var audioURL: String?
    var quizData: String? // JSON encoded quiz questions
    var resources: String? // JSON encoded resource links
    var prerequisites: String? // JSON encoded lesson IDs
    
    @Relationship var course: DreamLearningCourse?
    @Relationship var completions: [DreamLearningCompletion]
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        lessonType: DreamLessonType,
        duration: Int,
        orderIndex: Int,
        videoURL: String? = nil,
        audioURL: String? = nil,
        quizData: String? = nil,
        resources: String? = nil,
        prerequisites: String? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.lessonType = lessonType.rawValue
        self.duration = duration
        self.orderIndex = orderIndex
        self.videoURL = videoURL
        self.audioURL = audioURL
        self.quizData = quizData
        self.resources = resources
        self.prerequisites = prerequisites
        self.completions = []
    }
    
    var typeEnum: DreamLessonType {
        DreamLessonType(rawValue: lessonType) ?? .article
    }
}

@Model
final class DreamLearningEnrollment {
    @Attribute(.unique) var id: UUID
    var userId: String
    var enrolledAt: Date
    var progress: Double // 0.0 to 1.0
    var lastAccessedAt: Date?
    var isCompleted: Bool
    var completedAt: Date?
    var totalXP: Int
    
    @Relationship var course: DreamLearningCourse?
    @Relationship(deleteRule: .cascade) var completions: [DreamLearningCompletion]
    
    init(
        id: UUID = UUID(),
        userId: String,
        enrolledAt: Date = Date(),
        progress: Double = 0.0,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.enrolledAt = enrolledAt
        self.progress = progress
        self.isCompleted = isCompleted
        self.totalXP = 0
        self.completions = []
    }
}

@Model
final class DreamLearningCompletion {
    @Attribute(.unique) var id: UUID
    var userId: String
    var lessonId: UUID
    var completedAt: Date
    var score: Double? // For quizzes (0.0 to 1.0)
    var xpEarned: Int
    var notes: String?
    var duration: Int // Actual time spent in minutes
    
    @Relationship var enrollment: DreamLearningEnrollment?
    @Relationship var lesson: DreamLearningLesson?
    
    init(
        id: UUID = UUID(),
        userId: String,
        lessonId: UUID,
        completedAt: Date = Date(),
        score: Double? = nil,
        xpEarned: Int = 10,
        notes: String? = nil,
        duration: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.lessonId = lessonId
        self.completedAt = completedAt
        self.score = score
        self.xpEarned = xpEarned
        self.notes = notes
        self.duration = duration
    }
}

@Model
final class DreamLearningProfile {
    @Attribute(.unique) var id: UUID
    var userId: String
    var totalXP: Int
    var level: Int
    var coursesCompleted: Int
    var lessonsCompleted: Int
    var currentStreak: Int
    var longestStreak: Int
    var totalLearningTime: Int // in minutes
    var badges: String? // JSON encoded badge IDs
    var lastLearningAt: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.totalXP = 0
        self.level = 1
        self.coursesCompleted = 0
        self.lessonsCompleted = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalLearningTime = 0
        self.badges = nil
        self.createdAt = createdAt
    }
    
    var badgeIds: [String] {
        guard let badges = badges,
              let data = badges.data(using: .utf8),
              let ids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return ids
    }
    
    func addBadge(_ badge: DreamLearningBadge) {
        var ids = badgeIds
        if !ids.contains(badge.rawValue) {
            ids.append(badge.rawValue)
            badges = try? JSONEncoder().encode(ids).flatMap { String(data: $0, encoding: .utf8) }
        }
    }
    
    var hasBadge: [DreamLearningBadge] {
        badgeIds.compactMap { DreamLearningBadge(rawValue: $0) }
    }
}

// MARK: - Quiz Models

struct DreamQuizQuestion: Codable {
    let id: String
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String?
    let points: Int
}

struct DreamQuizResult: Codable {
    let questionId: String
    let selectedIndex: Int
    let isCorrect: Bool
    let timeSpent: Int // seconds
}

// MARK: - Learning Stats

struct DreamLearningStats {
    let totalEnrollments: Int
    let activeLearners: Int
    let averageCompletionRate: Double
    let totalLessonsCompleted: Int
    let totalXPEarned: Int
    let popularCourses: [String] // course IDs
    let categoryDistribution: [String: Int]
}
