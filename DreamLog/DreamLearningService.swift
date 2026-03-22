//
//  DreamLearningService.swift
//  DreamLog - Dream Learning Path Service
//
//  Phase 82: Dream Learning & Education System
//  Core service for managing courses, progress, and achievements
//

import Foundation
import SwiftData

@MainActor
class DreamLearningService {
    
    // MARK: - Singleton
    
    static let shared = DreamLearningService()
    
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private let userId: String = "current_user"
    
    // MARK: - Initialization
    
    func initialize(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedDefaultCoursesIfNeeded()
    }
    
    // MARK: - Course Management
    
    func getAllCourses(sortBy: CourseSortOption = .popularity) async -> [DreamLearningCourse] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<DreamLearningCourse>(
            predicate: #Predicate { $0.isPublished },
            sortBy: getSortDescriptors(for: sortBy)
        )
        
        return try? context.fetch(descriptor) ?? []
    }
    
    func getCourse(by id: UUID) async -> DreamLearningCourse? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<DreamLearningCourse>(
            predicate: #Predicate { $0.id == id }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    func getCourses(by category: DreamLearningCategory) async -> [DreamLearningCourse] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<DreamLearningCourse>(
            predicate: #Predicate { $0.category == category.rawValue && $0.isPublished },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        return try? context.fetch(descriptor) ?? []
    }
    
    func getRecommendedCourses() async -> [DreamLearningCourse] {
        guard let context = modelContext else { return [] }
        
        let allCourses = await getAllCourses()
        let profile = await getUserProfile()
        
        // Recommend beginner courses if new user
        if profile.totalXP < 100 {
            return allCourses.filter { $0.difficultyEnum == .beginner }.prefix(3).map { $0 }
        }
        
        // Otherwise recommend based on completed categories
        let completedCategories = Set(profile.hasBadge.map { $0.rawValue })
        return allCourses.filter { !completedCategories.contains($0.category) }.prefix(5).map { $0 }
    }
    
    // MARK: - Enrollment Management
    
    func enroll(in courseId: UUID) async -> Bool {
        guard let context = modelContext,
              let course = await getCourse(by: courseId) else {
            return false
        }
        
        // Check if already enrolled
        let existingEnrollment = course.enrollments.first { $0.userId == userId }
        if existingEnrollment != nil {
            return true // Already enrolled
        }
        
        let enrollment = DreamLearningEnrollment(userId: userId)
        enrollment.course = course
        context.insert(enrollment)
        
        try? context.save()
        return true
    }
    
    func getEnrollment(for courseId: UUID) async -> DreamLearningEnrollment? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<DreamLearningEnrollment>(
            predicate: #Predicate { $0.course?.id == courseId && $0.userId == userId }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    func getUserEnrollments() async -> [DreamLearningEnrollment] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<DreamLearningEnrollment>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.enrolledAt, order: .reverse)]
        )
        
        return try? context.fetch(descriptor) ?? []
    }
    
    // MARK: - Lesson Completion
    
    func completeLesson(_ lessonId: UUID, score: Double? = nil, duration: Int = 0) async -> Bool {
        guard let context = modelContext,
              let lesson = await getLesson(by: lessonId),
              let course = lesson.course else {
            return false
        }
        
        // Check if already completed
        let existingCompletion = lesson.completions.first { $0.userId == userId }
        if existingCompletion != nil {
            return true // Already completed
        }
        
        // Create completion record
        let xpEarned = calculateXPEarned(for: lesson, score: score)
        let completion = DreamLearningCompletion(
            userId: userId,
            lessonId: lessonId,
            score: score,
            xpEarned: xpEarned,
            duration: duration
        )
        completion.lesson = lesson
        
        // Get or create enrollment
        var enrollment = await getEnrollment(for: course.id)
        if enrollment == nil {
            let newEnrollment = DreamLearningEnrollment(userId: userId)
            newEnrollment.course = course
            context.insert(newEnrollment)
            enrollment = newEnrollment
        }
        
        if let enrollment = enrollment {
            completion.enrollment = enrollment
            context.insert(completion)
            
            // Update enrollment progress
            updateEnrollmentProgress(enrollment)
        }
        
        // Update user profile
        await updateUserProfile(xpEarned: xpEarned, lessonCompleted: true)
        
        // Check for achievements
        await checkAndAwardBadges()
        
        try? context.save()
        return true
    }
    
    func getLessonCompletion(_ lessonId: UUID) async -> DreamLearningCompletion? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<DreamLearningCompletion>(
            predicate: #Predicate { $0.lessonId == lessonId && $0.userId == userId }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    // MARK: - Progress Tracking
    
    func getCourseProgress(_ courseId: UUID) async -> Double {
        guard let enrollment = await getEnrollment(for: courseId) else {
            return 0.0
        }
        return enrollment.progress
    }
    
    func updateEnrollmentProgress(_ enrollment: DreamLearningEnrollment) {
        guard let course = enrollment.course,
              !course.lessons.isEmpty else {
            return
        }
        
        let completedCount = course.lessons.filter { lesson in
            lesson.completions.contains { $0.userId == userId }
        }.count
        
        enrollment.progress = Double(completedCount) / Double(course.lessons.count)
        
        if enrollment.progress >= 1.0 && !enrollment.isCompleted {
            enrollment.isCompleted = true
            enrollment.completedAt = Date()
            Task {
                await updateUserProfile(courseCompleted: true)
            }
        }
    }
    
    // MARK: - User Profile
    
    func getUserProfile() async -> DreamLearningProfile {
        guard let context = modelContext else {
            return DreamLearningProfile(userId: userId)
        }
        
        let descriptor = FetchDescriptor<DreamLearningProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        
        if let profile = try? context.fetch(descriptor).first {
            return profile
        }
        
        // Create new profile
        let profile = DreamLearningProfile(userId: userId)
        context.insert(profile)
        try? context.save()
        return profile
    }
    
    func updateUserProfile(xpEarned: Int = 0, lessonCompleted: Bool = false, courseCompleted: Bool = false) async {
        guard let context = modelContext else { return }
        
        let profile = await getUserProfile()
        
        profile.totalXP += xpEarned
        profile.level = calculateLevel(from: profile.totalXP)
        
        if lessonCompleted {
            profile.lessonsCompleted += 1
            updateStreak(for: profile)
        }
        
        if courseCompleted {
            profile.coursesCompleted += 1
        }
        
        profile.lastLearningAt = Date()
        
        try? context.save()
    }
    
    // MARK: - Badge System
    
    func checkAndAwardBadges() async {
        guard let context = modelContext else { return }
        
        let profile = await getUserProfile()
        var newBadges: [DreamLearningBadge] = []
        
        // First lesson badge
        if profile.lessonsCompleted >= 1 && !profile.hasBadge.contains(.firstLesson) {
            newBadges.append(.firstLesson)
        }
        
        // Week streak badge
        if profile.currentStreak >= 7 && !profile.hasBadge.contains(.weekStreak) {
            newBadges.append(.weekStreak)
        }
        
        // Month streak badge
        if profile.currentStreak >= 30 && !profile.hasBadge.contains(.monthStreak) {
            newBadges.append(.monthStreak)
        }
        
        // Course completed badge
        if profile.coursesCompleted >= 1 && !profile.hasBadge.contains(.courseCompleted) {
            newBadges.append(.courseCompleted)
        }
        
        // All courses badge
        let allCourses = await getAllCourses()
        if profile.coursesCompleted >= allCourses.count && !profile.hasBadge.contains(.allCourses) {
            newBadges.append(.allCourses)
        }
        
        // Explorer badge (all categories)
        let completedCategories = Set(profile.hasBadge.map { $0.rawValue })
        if DreamLearningCategory.allCases.allSatisfy({ completedCategories.contains($0.rawValue) })
            && !profile.hasBadge.contains(.explorer) {
            newBadges.append(.explorer)
        }
        
        // Award badges
        for badge in newBadges {
            profile.addBadge(badge)
            profile.totalXP += badge.points
        }
        
        profile.level = calculateLevel(from: profile.totalXP)
        
        try? context.save()
        
        // Notify user of new badges
        for badge in newBadges {
            await notifyBadgeEarned(badge)
        }
    }
    
    func getEarnedBadges() async -> [DreamLearningBadge] {
        let profile = await getUserProfile()
        return profile.hasBadge
    }
    
    func getAvailableBadges() async -> [(badge: DreamLearningBadge, earned: Bool)] {
        let earned = await getEarnedBadges()
        return DreamLearningBadge.allCases.map { badge in
            (badge, earned.contains(badge))
        }
    }
    
    // MARK: - Statistics
    
    func getLearningStats() async -> DreamLearningStats {
        guard let context = modelContext else {
            return DreamLearningStats(
                totalEnrollments: 0,
                activeLearners: 0,
                averageCompletionRate: 0,
                totalLessonsCompleted: 0,
                totalXPEarned: 0,
                popularCourses: [],
                categoryDistribution: [:]
            )
        }
        
        let profile = await getUserProfile()
        let enrollments = await getUserEnrollments()
        
        let activeLearners = enrollments.filter { enrollment in
            guard let lastAccessed = enrollment.lastAccessedAt else { return false }
            return lastAccessed.timeIntervalSinceNow > -7 * 24 * 60 * 60 // Last 7 days
        }.count
        
        let averageCompletionRate = enrollments.isEmpty ? 0 :
            enrollments.map { $0.progress }.reduce(0, +) / Double(enrollments.count)
        
        var categoryDistribution: [String: Int] = [:]
        for enrollment in enrollments where enrollment.isCompleted {
            if let category = enrollment.course?.category {
                categoryDistribution[category, default: 0] += 1
            }
        }
        
        return DreamLearningStats(
            totalEnrollments: enrollments.count,
            activeLearners: activeLearners,
            averageCompletionRate: averageCompletionRate,
            totalLessonsCompleted: profile.lessonsCompleted,
            totalXPEarned: profile.totalXP,
            popularCourses: [],
            categoryDistribution: categoryDistribution
        )
    }
    
    // MARK: - Helper Methods
    
    private func getLesson(by id: UUID) async -> DreamLearningLesson? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<DreamLearningLesson>(
            predicate: #Predicate { $0.id == id }
        )
        
        return try? context.fetch(descriptor).first
    }
    
    private func calculateXPEarned(for lesson: DreamLearningLesson, score: Double?) -> Int {
        let baseXP = lesson.duration * 2 // 2 XP per minute
        
        let scoreMultiplier: Double = {
            guard let score = score else { return 1.0 }
            if score >= 0.9 { return 1.5 }
            if score >= 0.7 { return 1.2 }
            if score >= 0.5 { return 1.0 }
            return 0.5
        }()
        
        return Int(Double(baseXP) * scoreMultiplier)
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        // Level formula: level = floor(sqrt(xp / 100)) + 1
        return Int(sqrt(Double(xp) / 100.0)) + 1
    }
    
    private func updateStreak(for profile: DreamLearningProfile) {
        guard let lastLearning = profile.lastLearningAt else {
            profile.currentStreak = 1
            profile.longestStreak = 1
            return
        }
        
        let daysSinceLastLearning = lastLearning.timeIntervalSinceNow / (24 * 60 * 60)
        
        if daysSinceLastLearning < 1.5 { // Within ~36 hours
            profile.currentStreak += 1
        } else {
            profile.currentStreak = 1
        }
        
        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
    }
    
    private func getSortDescriptors(for option: CourseSortOption) -> [SortDescriptor<DreamLearningCourse>] {
        switch option {
        case .popularity:
            return [SortDescriptor(\.enrollments.count, order: .reverse)]
        case .newest:
            return [SortDescriptor(\.createdAt, order: .reverse)]
        case .difficulty:
            return [SortDescriptor(\.difficulty)]
        case .alphabetical:
            return [SortDescriptor(\.title)]
        }
    }
    
    private func notifyBadgeEarned(_ badge: DreamLearningBadge) {
        // Send notification about earned badge
        // Implementation depends on notification system
        print("🏆 Badge earned: \(badge.displayName)")
    }
    
    // MARK: - Seed Data
    
    private func seedDefaultCoursesIfNeeded() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<DreamLearningCourse>()
        let count = try? context.fetch(descriptor).count
        
        if count == 0 || count == nil {
            createDefaultCourses()
        }
    }
    
    private func createDefaultCourses() {
        guard let context = modelContext else { return }
        
        // Course 1: Lucid Dreaming Basics
        let lucidCourse = DreamLearningCourse(
            title: "清醒梦入门",
            description: "学习如何意识到自己在做梦，并掌握控制梦境的基础技巧",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 3.5,
            thumbnail: "lucid_intro"
        )
        context.insert(lucidCourse)
        
        // Add lessons to lucid course
        let lucidLessons = [
            DreamLearningLesson(title: "什么是清醒梦？", content: "清醒梦基础介绍...", lessonType: .video, duration: 10, orderIndex: 0),
            DreamLearningLesson(title: "现实检查技巧", content: "学习 5 种现实检查方法...", lessonType: .exercise, duration: 15, orderIndex: 1),
            DreamLearningLesson(title: "MILD 技巧", content: "记忆诱导清醒梦法详解...", lessonType: .article, duration: 20, orderIndex: 2),
            DreamLearningLesson(title: "WBTB 方法", content: "醒来再睡技巧...", lessonType: .article, duration: 15, orderIndex: 3),
            DreamLearningLesson(title: "清醒梦实践", content: "第一次清醒梦练习...", lessonType: .practice, duration: 30, orderIndex: 4)
        ]
        
        for lesson in lucidLessons {
            lesson.course = lucidCourse
            context.insert(lesson)
        }
        
        lucidCourse.lessonCount = lucidLessons.count
        
        // Course 2: Dream Interpretation
        let interpretationCourse = DreamLearningCourse(
            title: "梦境解析基础",
            description: "理解梦境中的象征意义，发现潜意识传递的信息",
            category: .dreamInterpretation,
            difficulty: .beginner,
            estimatedHours: 4.0,
            thumbnail: "interpretation_intro"
        )
        context.insert(interpretationCourse)
        
        let interpretationLessons = [
            DreamLearningLesson(title: "梦境语言入门", content: "梦境如何表达象征...", lessonType: .video, duration: 12, orderIndex: 0),
            DreamLearningLesson(title: "常见梦境符号", content: "水、飞行、追逐等符号解析...", lessonType: .article, duration: 25, orderIndex: 1),
            DreamLearningLesson(title: "情绪与梦境", content: "梦境情绪的意义...", lessonType: .article, duration: 18, orderIndex: 2),
            DreamLearningLesson(title: "个人符号词典", content: "创建你的符号词典...", lessonType: .exercise, duration: 30, orderIndex: 3),
            DreamLearningLesson(title: "解析实践", content: "实际梦境解析练习...", lessonType: .practice, duration: 40, orderIndex: 4)
        ]
        
        for lesson in interpretationLessons {
            lesson.course = interpretationCourse
            context.insert(lesson)
        }
        
        interpretationCourse.lessonCount = interpretationLessons.count
        
        // Course 3: Dream Recall Enhancement
        let recallCourse = DreamLearningCourse(
            title: "梦境回忆强化",
            description: "提高梦境回忆能力，不再忘记醒来时的梦境",
            category: .dreamRecall,
            difficulty: .beginner,
            estimatedHours: 2.5,
            thumbnail: "recall_intro"
        )
        context.insert(recallCourse)
        
        let recallLessons = [
            DreamLearningLesson(title: "为什么记不住梦", content: "梦境遗忘的科学...", lessonType: .video, duration: 10, orderIndex: 0),
            DreamLearningLesson(title: "睡前设定意图", content: "提高回忆的睡前技巧...", lessonType: .meditation, duration: 15, orderIndex: 1),
            DreamLearningLesson(title: "晨间记录法", content: "最佳记录时间和方法...", lessonType: .exercise, duration: 20, orderIndex: 2),
            DreamLearningLesson(title: "回忆训练", content: "7 天回忆强化计划...", lessonType: .practice, duration: 35, orderIndex: 3)
        ]
        
        for lesson in recallLessons {
            lesson.course = recallCourse
            context.insert(lesson)
        }
        
        recallCourse.lessonCount = recallLessons.count
        
        // Course 4: Mindfulness for Dreamers
        let mindfulnessCourse = DreamLearningCourse(
            title: "正念冥想指南",
            description: "通过正念冥想提升梦境觉察力和生活质量",
            category: .mindfulness,
            difficulty: .beginner,
            estimatedHours: 3.0,
            thumbnail: "mindfulness_intro"
        )
        context.insert(mindfulnessCourse)
        
        let mindfulnessLessons = [
            DreamLearningLesson(title: "正念基础", content: "什么是正念...", lessonType: .video, duration: 12, orderIndex: 0),
            DreamLearningLesson(title: "呼吸冥想", content: "基础呼吸练习...", lessonType: .meditation, duration: 20, orderIndex: 1),
            DreamLearningLesson(title: "身体扫描", content: "渐进式放松...", lessonType: .meditation, duration: 25, orderIndex: 2),
            DreamLearningLesson(title: "梦境觉察", content: "将正念带入梦境...", lessonType: .article, duration: 18, orderIndex: 3),
            DreamLearningLesson(title: "日常正念", content: "生活中的正念练习...", lessonType: .practice, duration: 30, orderIndex: 4)
        ]
        
        for lesson in mindfulnessLessons {
            lesson.course = mindfulnessCourse
            context.insert(lesson)
        }
        
        mindfulnessCourse.lessonCount = mindfulnessLessons.count
        
        // Course 5: Creativity from Dreams
        let creativityCourse = DreamLearningCourse(
            title: "梦境创意启发",
            description: "从梦境中获取创意灵感，用于艺术、写作和问题解决",
            category: .creativity,
            difficulty: .intermediate,
            estimatedHours: 4.5,
            thumbnail: "creativity_intro"
        )
        context.insert(creativityCourse)
        
        let creativityLessons = [
            DreamLearningLesson(title: "梦境与创造力", content: "历史名人的梦境灵感...", lessonType: .video, duration: 15, orderIndex: 0),
            DreamLearningLesson(title: "创意孵化技巧", content: "睡前设定创意问题...", lessonType: .article, duration: 20, orderIndex: 1),
            DreamLearningLesson(title: "梦境素材收集", content: "建立创意素材库...", lessonType: .exercise, duration: 25, orderIndex: 2),
            DreamLearningLesson(title: "从梦到作品", content: "将梦境转化为创作...", lessonType: .practice, duration: 40, orderIndex: 3),
            DreamLearningLesson(title: "创意突破", content: "解决创作瓶颈...", lessonType: .reflection, duration: 30, orderIndex: 4)
        ]
        
        for lesson in creativityLessons {
            lesson.course = creativityCourse
            context.insert(lesson)
        }
        
        creativityCourse.lessonCount = creativityLessons.count
        
        // Course 6: Sleep Science
        let sleepScienceCourse = DreamLearningCourse(
            title: "睡眠科学基础",
            description: "了解睡眠周期、REM 睡眠与梦境的科学原理",
            category: .sleepScience,
            difficulty: .intermediate,
            estimatedHours: 5.0,
            thumbnail: "sleep_science_intro"
        )
        context.insert(sleepScienceCourse)
        
        let sleepScienceLessons = [
            DreamLearningLesson(title: "睡眠周期详解", content: "4 个睡眠阶段...", lessonType: .video, duration: 18, orderIndex: 0),
            DreamLearningLesson(title: "REM 睡眠与梦境", content: "快速眼动期的秘密...", lessonType: .article, duration: 22, orderIndex: 1),
            DreamLearningLesson(title: "睡眠质量优化", content: "改善睡眠的科学方法...", lessonType: .article, duration: 25, orderIndex: 2),
            DreamLearningLesson(title: "生物钟调节", content: "调整作息的科学...", lessonType: .exercise, duration: 20, orderIndex: 3),
            DreamLearningLesson(title: "睡眠与记忆", content: "睡眠如何巩固记忆...", lessonType: .video, duration: 20, orderIndex: 4),
            DreamLearningLesson(title: "梦境功能理论", content: "为什么我们会做梦...", lessonType: .article, duration: 30, orderIndex: 5)
        ]
        
        for lesson in sleepScienceLessons {
            lesson.course = sleepScienceCourse
            context.insert(lesson)
        }
        
        sleepScienceCourse.lessonCount = sleepScienceLessons.count
        
        try? context.save()
    }
}

// MARK: - Sort Options

enum CourseSortOption {
    case popularity
    case newest
    case difficulty
    case alphabetical
}
