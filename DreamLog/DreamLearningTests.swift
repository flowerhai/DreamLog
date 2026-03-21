//
//  DreamLearningTests.swift
//  DreamLogTests
//
//  Phase 82: Dream Learning & Education System - Unit Tests
//  Test coverage for course management, enrollment, progress tracking, and achievements
//

import XCTest
import SwiftData
@testable import DreamLog

@available(iOS 17.0, *)
final class DreamLearningTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: DreamLearningService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([
            DreamLearningCourse.self,
            DreamLearningLesson.self,
            DreamLearningEnrollment.self,
            DreamLearningCompletion.self,
            DreamLearningProfile.self
        ])
        
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        service = DreamLearningService.shared
        service.initialize(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        service = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Course Management Tests
    
    func testCreateCourse() async throws {
        let course = DreamLearningCourse(
            title: "清醒梦入门",
            description: "学习如何进入清醒梦的基础知识",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 2.5,
            lessonCount: 5
        )
        
        modelContext.insert(course)
        try modelContext.save()
        
        let fetched = await service.getCourse(by: course.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.title, "清醒梦入门")
        XCTAssertEqual(fetched?.categoryEnum, .lucidDreaming)
        XCTAssertEqual(fetched?.difficultyEnum, .beginner)
    }
    
    func testGetAllCourses() async throws {
        // Create multiple courses
        let courses = [
            DreamLearningCourse(title: "Course 1", description: "Desc 1", category: .lucidDreaming, difficulty: .beginner, estimatedHours: 1.0),
            DreamLearningCourse(title: "Course 2", description: "Desc 2", category: .dreamInterpretation, difficulty: .intermediate, estimatedHours: 2.0),
            DreamLearningCourse(title: "Course 3", description: "Desc 3", category: .mindfulness, difficulty: .advanced, estimatedHours: 3.0)
        ]
        
        courses.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        let fetched = await service.getAllCourses()
        XCTAssertEqual(fetched.count, 3)
    }
    
    func testGetCoursesByCategory() async throws {
        let lucidCourse = DreamLearningCourse(
            title: "Lucid Dreaming",
            description: "Learn lucid dreaming",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 2.0
        )
        
        let interpretationCourse = DreamLearningCourse(
            title: "Dream Interpretation",
            description: "Interpret your dreams",
            category: .dreamInterpretation,
            difficulty: .intermediate,
            estimatedHours: 3.0
        )
        
        modelContext.insert(lucidCourse)
        modelContext.insert(interpretationCourse)
        try modelContext.save()
        
        let lucidCourses = await service.getCourses(by: .lucidDreaming)
        XCTAssertEqual(lucidCourses.count, 1)
        XCTAssertEqual(lucidCourses.first?.title, "Lucid Dreaming")
        
        let interpretationCourses = await service.getCourses(by: .dreamInterpretation)
        XCTAssertEqual(interpretationCourses.count, 1)
    }
    
    func testUnpublishedCoursesNotReturned() async throws {
        let published = DreamLearningCourse(
            title: "Published Course",
            description: "This is published",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0,
            isPublished: true
        )
        
        let unpublished = DreamLearningCourse(
            title: "Unpublished Course",
            description: "This is not published",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0,
            isPublished: false
        )
        
        modelContext.insert(published)
        modelContext.insert(unpublished)
        try modelContext.save()
        
        let fetched = await service.getAllCourses()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Published Course")
    }
    
    // MARK: - Lesson Management Tests
    
    func testCreateLesson() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test Description",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0
        )
        
        let lesson = DreamLearningLesson(
            title: "Introduction",
            content: "Welcome to the course",
            lessonType: .video,
            duration: 15,
            orderIndex: 0
        )
        
        lesson.course = course
        modelContext.insert(course)
        modelContext.insert(lesson)
        try modelContext.save()
        
        XCTAssertEqual(course.lessons.count, 1)
        XCTAssertEqual(lesson.course?.id, course.id)
    }
    
    func testLessonWithQuiz() async throws {
        let quizQuestions = [
            DreamQuizQuestion(
                id: "q1",
                question: "What is a lucid dream?",
                options: ["A dream where you know you're dreaming", "A nightmare", "A recurring dream", "A short dream"],
                correctIndex: 0,
                explanation: "In a lucid dream, you become aware that you are dreaming.",
                points: 10
            )
        ]
        
        let quizData = try JSONEncoder().encode(quizQuestions)
        let quizString = String(data: quizData, encoding: .utf8)
        
        let lesson = DreamLearningLesson(
            title: "Quiz Lesson",
            content: "Test your knowledge",
            lessonType: .quiz,
            duration: 10,
            orderIndex: 0,
            quizData: quizString
        )
        
        modelContext.insert(lesson)
        try modelContext.save()
        
        XCTAssertNotNil(lesson.quizData)
    }
    
    // MARK: - Enrollment Tests
    
    func testEnrollInCourse() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0
        )
        
        modelContext.insert(course)
        try modelContext.save()
        
        let success = await service.enroll(in: course.id)
        XCTAssertTrue(success)
        
        let enrollment = await service.getEnrollment(for: course.id)
        XCTAssertNotNil(enrollment)
        XCTAssertEqual(enrollment?.progress, 0.0)
        XCTAssertFalse(enrollment?.isCompleted ?? true)
    }
    
    func testEnrollAlreadyEnrolled() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0
        )
        
        modelContext.insert(course)
        try modelContext.save()
        
        // First enrollment
        _ = await service.enroll(in: course.id)
        
        // Second enrollment (should return true but not create duplicate)
        let success = await service.enroll(in: course.id)
        XCTAssertTrue(success)
        
        let enrollments = await service.getUserEnrollments()
        XCTAssertEqual(enrollments.count, 1) // Should still be 1
    }
    
    func testGetUserEnrollments() async throws {
        let courses = [
            DreamLearningCourse(title: "Course 1", description: "Desc", category: .lucidDreaming, difficulty: .beginner, estimatedHours: 1.0),
            DreamLearningCourse(title: "Course 2", description: "Desc", category: .dreamInterpretation, difficulty: .beginner, estimatedHours: 1.0)
        ]
        
        courses.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        _ = await service.enroll(in: courses[0].id)
        _ = await service.enroll(in: courses[1].id)
        
        let enrollments = await service.getUserEnrollments()
        XCTAssertEqual(enrollments.count, 2)
    }
    
    // MARK: - Completion Tests
    
    func testCompleteLesson() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0
        )
        
        let lesson = DreamLearningLesson(
            title: "Lesson 1",
            content: "Content",
            lessonType: .article,
            duration: 10,
            orderIndex: 0
        )
        
        lesson.course = course
        modelContext.insert(course)
        modelContext.insert(lesson)
        try modelContext.save()
        
        let success = await service.completeLesson(lesson.id, score: 0.9, duration: 12)
        XCTAssertTrue(success)
        
        let completion = await service.getLessonCompletion(lesson.id)
        XCTAssertNotNil(completion)
        XCTAssertEqual(completion?.score, 0.9)
        XCTAssertEqual(completion?.duration, 12)
    }
    
    func testCompleteLessonAlreadyCompleted() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0
        )
        
        let lesson = DreamLearningLesson(
            title: "Lesson 1",
            content: "Content",
            lessonType: .article,
            duration: 10,
            orderIndex: 0
        )
        
        lesson.course = course
        modelContext.insert(course)
        modelContext.insert(lesson)
        try modelContext.save()
        
        // First completion
        _ = await service.completeLesson(lesson.id, score: 0.8, duration: 10)
        
        // Second completion (should return true but not create duplicate)
        let success = await service.completeLesson(lesson.id, score: 0.9, duration: 15)
        XCTAssertTrue(success)
        
        let completions = lesson.completions.filter { $0.userId == service.userId }
        XCTAssertEqual(completions.count, 1) // Should still be 1
    }
    
    // MARK: - Progress Tracking Tests
    
    func testCourseProgressCalculation() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0,
            lessonCount: 4
        )
        
        let lessons = (0..<4).map { index in
            DreamLearningLesson(
                title: "Lesson \(index + 1)",
                content: "Content",
                lessonType: .article,
                duration: 10,
                orderIndex: index
            )
        }
        
        lessons.forEach { $0.course = course }
        modelContext.insert(course)
        lessons.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        _ = await service.enroll(in: course.id)
        
        // Complete 2 out of 4 lessons
        await service.completeLesson(lessons[0].id)
        await service.completeLesson(lessons[1].id)
        
        let progress = await service.getCourseProgress(course.id)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }
    
    func testCourseCompletion() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0,
            lessonCount: 2
        )
        
        let lessons = (0..<2).map { index in
            DreamLearningLesson(
                title: "Lesson \(index + 1)",
                content: "Content",
                lessonType: .article,
                duration: 10,
                orderIndex: index
            )
        }
        
        lessons.forEach { $0.course = course }
        modelContext.insert(course)
        lessons.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        _ = await service.enroll(in: course.id)
        
        // Complete all lessons
        await service.completeLesson(lessons[0].id)
        await service.completeLesson(lessons[1].id)
        
        let enrollment = await service.getEnrollment(for: course.id)
        XCTAssertTrue(enrollment?.isCompleted ?? false)
        XCTAssertNotNil(enrollment?.completedAt)
    }
    
    // MARK: - User Profile Tests
    
    func testUserProfileCreation() async throws {
        let profile = await service.getUserProfile()
        
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile.totalXP, 0)
        XCTAssertEqual(profile.level, 1)
        XCTAssertEqual(profile.coursesCompleted, 0)
        XCTAssertEqual(profile.lessonsCompleted, 0)
    }
    
    func testXPAndLevelCalculation() async throws {
        var profile = await service.getUserProfile()
        
        // Add XP
        await service.updateUserProfile(xpEarned: 100)
        
        profile = await service.getUserProfile()
        XCTAssertEqual(profile.totalXP, 100)
        XCTAssertGreaterThan(profile.level, 0)
    }
    
    func testStreakTracking() async throws {
        var profile = await service.getUserProfile()
        
        // Complete a lesson (should update streak)
        await service.updateUserProfile(xpEarned: 10, lessonCompleted: true)
        
        profile = await service.getUserProfile()
        XCTAssertEqual(profile.lessonsCompleted, 1)
        XCTAssertGreaterThanOrEqual(profile.currentStreak, 1)
    }
    
    // MARK: - Badge System Tests
    
    func testFirstLessonBadge() async throws {
        let course = DreamLearningCourse(
            title: "Test Course",
            description: "Test",
            category: .lucidDreaming,
            difficulty: .beginner,
            estimatedHours: 1.0
        )
        
        let lesson = DreamLearningLesson(
            title: "Lesson 1",
            content: "Content",
            lessonType: .article,
            duration: 10,
            orderIndex: 0
        )
        
        lesson.course = course
        modelContext.insert(course)
        modelContext.insert(lesson)
        try modelContext.save()
        
        _ = await service.enroll(in: course.id)
        await service.completeLesson(lesson.id)
        
        let profile = await service.getUserProfile()
        XCTAssertTrue(profile.hasBadge.contains(.firstLesson))
    }
    
    func testBadgePoints() {
        // Test that all badges have positive points
        for badge in DreamLearningBadge.allCases {
            XCTAssertGreaterThan(badge.points, 0, "Badge \(badge.displayName) should have positive points")
        }
    }
    
    // MARK: - Category Enum Tests
    
    func testLearningCategoryDisplayNames() {
        let categories: [(DreamLearningCategory, String)] = [
            (.lucidDreaming, "清醒梦训练"),
            (.dreamInterpretation, "梦境解析"),
            (.dreamRecall, "梦境回忆"),
            (.mindfulness, "正念冥想"),
            (.creativity, "创意启发"),
            (.sleepScience, "睡眠科学"),
            (.wellness, "健康福祉")
        ]
        
        for (category, expectedName) in categories {
            XCTAssertEqual(category.displayName, expectedName)
        }
    }
    
    func testLearningCategoryIcons() {
        for category in DreamLearningCategory.allCases {
            XCTAssertFalse(category.icon.isEmpty, "Category \(category.rawValue) should have an icon")
        }
    }
    
    // MARK: - Lesson Type Tests
    
    func testLessonTypeDisplayNames() {
        let types: [(DreamLessonType, String)] = [
            (.video, "视频课程"),
            (.article, "文章阅读"),
            (.exercise, "实践练习"),
            (.quiz, "小测验"),
            (.meditation, "冥想引导"),
            (.practice, "实修训练"),
            (.reflection, "反思日记")
        ]
        
        for (type, expectedName) in types {
            XCTAssertEqual(type.displayName, expectedName)
        }
    }
    
    // MARK: - Difficulty Level Tests
    
    func testDifficultyLevelRequiredXP() {
        XCTAssertEqual(DreamDifficultyLevel.beginner.requiredXP, 0)
        XCTAssertEqual(DreamDifficultyLevel.intermediate.requiredXP, 100)
        XCTAssertEqual(DreamDifficultyLevel.advanced.requiredXP, 300)
        XCTAssertEqual(DreamDifficultyLevel.expert.requiredXP, 600)
    }
    
    func testDifficultyLevelDisplayNames() {
        let levels: [(DreamDifficultyLevel, String)] = [
            (.beginner, "入门"),
            (.intermediate, "进阶"),
            (.advanced, "高级"),
            (.expert, "专家")
        ]
        
        for (level, expectedName) in levels {
            XCTAssertEqual(level.displayName, expectedName)
        }
    }
    
    // MARK: - Quiz Models Tests
    
    func testQuizQuestionEncoding() throws {
        let question = DreamQuizQuestion(
            id: "q1",
            question: "Test question?",
            options: ["A", "B", "C", "D"],
            correctIndex: 0,
            explanation: "Explanation",
            points: 10
        )
        
        let data = try JSONEncoder().encode(question)
        let decoded = try JSONDecoder().decode(DreamQuizQuestion.self, from: data)
        
        XCTAssertEqual(decoded.id, question.id)
        XCTAssertEqual(decoded.question, question.question)
        XCTAssertEqual(decoded.correctIndex, question.correctIndex)
    }
    
    // MARK: - Performance Tests
    
    func testFetchPerformance() async throws {
        // Create 100 courses
        for i in 0..<100 {
            let course = DreamLearningCourse(
                title: "Course \(i)",
                description: "Description \(i)",
                category: DreamLearningCategory.allCases[i % DreamLearningCategory.allCases.count],
                difficulty: DreamDifficultyLevel.allCases[i % DreamDifficultyLevel.allCases.count],
                estimatedHours: Double(i % 10 + 1)
            )
            modelContext.insert(course)
        }
        try modelContext.save()
        
        // Measure fetch performance
        let start = Date()
        let courses = await service.getAllCourses()
        let duration = Date().timeIntervalSince(start)
        
        XCTAssertEqual(courses.count, 100)
        XCTAssertLessThan(duration, 1.0, "Fetch should complete in under 1 second")
    }
}
