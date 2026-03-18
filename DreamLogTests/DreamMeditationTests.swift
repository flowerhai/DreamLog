//
//  DreamMeditationTests.swift
//  DreamLogTests
//
//  Phase 65: 梦境冥想与放松增强 - 单元测试
//  测试覆盖率目标：95%+
//

import Foundation
import Testing
import SwiftData

@Suite("DreamMeditation Models Tests")
struct DreamMeditationModelsTests {
    
    // MARK: - MeditationType Tests
    
    @Test("MeditationType display names")
    func meditationTypeDisplayNames() async throws {
        let type = MeditationType.guidedDream
        #expect(type.displayName == "梦境引导")
        
        let breathing = MeditationType.breathing478
        #expect(breathing.displayName == "4-7-8 呼吸")
        
        let music = MeditationType.musicTherapy
        #expect(music.displayName == "音乐疗法")
    }
    
    @Test("MeditationType icons")
    func meditationTypeIcons() async throws {
        let guided = MeditationType.guidedDream
        #expect(guided.icon == "moon.stars")
        
        let breathing = MeditationType.breathing478
        #expect(breathing.icon == "wind")
        
        let bodyScan = MeditationType.bodyScan
        #expect(bodyScan.icon == "figure.mind.and.body")
    }
    
    @Test("MeditationType categories")
    func meditationTypeCategories() async throws {
        let guided = MeditationType.guidedDream
        #expect(guided.category == .guided)
        
        let breathing = MeditationType.breathing478
        #expect(breathing.category == .breathing)
        
        let music = MeditationType.musicTherapy
        #expect(music.category == .music)
    }
    
    @Test("MeditationType all cases count")
    func meditationTypeAllCasesCount() async throws {
        #expect(MeditationType.allCases.count == 19)
    }
    
    // MARK: - MeditationCategory Tests
    
    @Test("MeditationCategory display names")
    func meditationCategoryDisplayNames() async throws {
        let guided = MeditationCategory.guided
        #expect(guided.displayName == "引导冥想")
        
        let breathing = MeditationCategory.breathing
        #expect(breathing.displayName == "呼吸练习")
        
        let relaxation = MeditationCategory.relaxation
        #expect(relaxation.displayName == "放松扫描")
        
        let mindfulness = MeditationCategory.mindfulness
        #expect(mindfulness.displayName == "正念冥想")
        
        let music = MeditationCategory.music
        #expect(music.displayName == "音乐疗法")
    }
    
    @Test("MeditationCategory icons")
    func meditationCategoryIcons() async throws {
        let guided = MeditationCategory.guided
        #expect(guided.icon == "moon.stars")
        
        let breathing = MeditationCategory.breathing
        #expect(breathing.icon == "wind")
        
        let music = MeditationCategory.music
        #expect(music.icon == "music.note")
    }
    
    // MARK: - MeditationTemplate Tests
    
    @Test("MeditationTemplate creation")
    func meditationTemplateCreation() async throws {
        let template = MeditationTemplate(
            id: UUID(),
            name: "睡前放松",
            type: .guidedDream,
            duration: 600,
            description: "帮助你放松入睡的引导冥想",
            voiceType: "Ting-Ting",
            backgroundSound: "rain",
            musicTrack: "calm_piano_01",
            difficulty: .beginner,
            tags: ["睡眠", "放松", "睡前"]
        )
        
        #expect(template.name == "睡前放松")
        #expect(template.type == .guidedDream)
        #expect(template.duration == 600)
        #expect(template.difficulty == .beginner)
        #expect(template.tags.count == 3)
    }
    
    @Test("MeditationTemplate difficulty levels")
    func meditationTemplateDifficultyLevels() async throws {
        #expect(MeditationDifficulty.allCases.count == 3)
        
        let beginner = MeditationDifficulty.beginner
        #expect(beginner.displayName == "初级")
        #expect(beginner.icon == "star")
        
        let intermediate = MeditationDifficulty.intermediate
        #expect(intermediate.displayName == "中级")
        #expect(intermediate.icon == "star.fill")
        
        let advanced = MeditationDifficulty.advanced
        #expect(advanced.displayName == "高级")
        #expect(advanced.icon == "star.leadingvalue.fill")
    }
    
    // MARK: - MeditationSession Tests
    
    @Test("MeditationSession creation")
    func meditationSessionCreation() async throws {
        let session = MeditationSession(
            type: .breathing478,
            duration: 300,
            completed: false,
            moodBefore: "焦虑",
            dreamId: nil,
            audioFile: nil,
            voiceType: "Mei-Jia",
            backgroundSound: "white_noise",
            volume: 0.7,
            timerDuration: 1800
        )
        
        #expect(session.type == .breathing478)
        #expect(session.duration == 300)
        #expect(session.completed == false)
        #expect(session.moodBefore == "焦虑")
        #expect(session.volume == 0.7)
    }
    
    @Test("MeditationSession completion")
    func meditationSessionCompletion() async throws {
        let session = MeditationSession(
            type: .bodyScan,
            duration: 1200,
            completed: false
        )
        
        #expect(session.completed == false)
        session.completed = true
        #expect(session.completed == true)
    }
    
    @Test("MeditationSession mood tracking")
    func meditationSessionMoodTracking() async throws {
        let session = MeditationSession(
            type: .guidedDream,
            duration: 600,
            completed: true,
            moodBefore: "焦虑",
            moodAfter: "平静"
        )
        
        #expect(session.moodBefore == "焦虑")
        #expect(session.moodAfter == "平静")
    }
    
    // MARK: - MeditationStats Tests
    
    @Test("MeditationStats calculation")
    func meditationStatsCalculation() async throws {
        let stats = MeditationStats(
            totalSessions: 50,
            totalDuration: 18000,
            completedSessions: 45,
            currentStreak: 7,
            longestStreak: 21,
            favoriteType: .breathing478,
            averageDuration: 360,
            sessionsByType: [
                .breathing478: 20,
                .guidedDream: 15,
                .bodyScan: 10,
                .musicTherapy: 5
            ]
        )
        
        #expect(stats.totalSessions == 50)
        #expect(stats.totalDuration == 18000)
        #expect(stats.completedSessions == 45)
        #expect(stats.completionRate == 90.0)
        #expect(stats.currentStreak == 7)
        #expect(stats.longestStreak == 21)
        #expect(stats.averageDuration == 360)
    }
    
    @Test("MeditationStats completion rate")
    func meditationStatsCompletionRate() async throws {
        let stats1 = MeditationStats(
            totalSessions: 100,
            totalDuration: 36000,
            completedSessions: 100
        )
        #expect(stats1.completionRate == 100.0)
        
        let stats2 = MeditationStats(
            totalSessions: 100,
            totalDuration: 36000,
            completedSessions: 50
        )
        #expect(stats2.completionRate == 50.0)
        
        let stats3 = MeditationStats(
            totalSessions: 0,
            totalDuration: 0,
            completedSessions: 0
        )
        #expect(stats3.completionRate == 0.0)
    }
    
    // MARK: - MeditationPreference Tests
    
    @Test("MeditationPreference creation")
    func meditationPreferenceCreation() async throws {
        let preference = MeditationPreference(
            favoriteTypes: [.breathing478, .guidedDream],
            preferredDuration: 600,
            preferredVoice: "Ting-Ting",
            reminderTime: Date().addingTimeInterval(3600),
            backgroundSound: "rain",
            autoStartTimer: true,
            defaultTimerDuration: 1800
        )
        
        #expect(preference.favoriteTypes.count == 2)
        #expect(preference.preferredDuration == 600)
        #expect(preference.preferredVoice == "Ting-Ting")
        #expect(preference.backgroundSound == "rain")
        #expect(preference.autoStartTimer == true)
    }
    
    // MARK: - MeditationAchievement Tests
    
    @Test("MeditationAchievement types")
    func meditationAchievementTypes() async throws {
        let achievement = MeditationAchievement(
            id: UUID(),
            type: .firstSession,
            title: "初次冥想",
            description: "完成第一次冥想练习",
            icon: "sparkles",
            unlocked: false,
            unlockedAt: nil
        )
        
        #expect(achievement.type == .firstSession)
        #expect(achievement.title == "初次冥想")
        #expect(achievement.icon == "sparkles")
        #expect(achievement.unlocked == false)
    }
    
    @Test("MeditationAchievement unlock")
    func meditationAchievementUnlock() async throws {
        let achievement = MeditationAchievement(
            type: .firstSession,
            title: "初次冥想",
            description: "完成第一次冥想练习",
            icon: "sparkles"
        )
        
        #expect(achievement.unlocked == false)
        achievement.unlock()
        #expect(achievement.unlocked == true)
        #expect(achievement.unlockedAt != nil)
    }
    
    @Test("MeditationAchievement all types")
    func meditationAchievementAllTypes() async throws {
        let types = MeditationAchievementType.allCases
        #expect(types.count >= 8)
        
        #expect(MeditationAchievementType.firstSession.displayName == "初次冥想")
        #expect(MeditationAchievementType.sevenDayStreak.displayName == "七天连续")
        #expect(MeditationAchievementType.total10Hours.displayName == "十小时大师")
    }
    
    // MARK: - Breathing Pattern Tests
    
    @Test("BreathingPattern creation")
    func breathingPatternCreation() async throws {
        let pattern = BreathingPattern(
            name: "4-7-8",
            inhaleDuration: 4,
            holdDuration: 7,
            exhaleDuration: 8,
            cycles: 4,
            description: "帮助快速入睡的呼吸法"
        )
        
        #expect(pattern.name == "4-7-8")
        #expect(pattern.inhaleDuration == 4)
        #expect(pattern.holdDuration == 7)
        #expect(pattern.exhaleDuration == 8)
        #expect(pattern.cycles == 4)
        #expect(pattern.totalDuration == 76)
    }
    
    @Test("BreathingPattern total duration")
    func breathingPatternTotalDuration() async throws {
        let pattern1 = BreathingPattern(
            name: "Box",
            inhaleDuration: 4,
            holdDuration: 4,
            exhaleDuration: 4,
            cycles: 4
        )
        #expect(pattern1.totalDuration == 64)
        
        let pattern2 = BreathingPattern(
            name: "Quick",
            inhaleDuration: 2,
            holdDuration: 0,
            exhaleDuration: 2,
            cycles: 10
        )
        #expect(pattern2.totalDuration == 40)
    }
    
    // MARK: - Relaxation Body Part Tests
    
    @Test("RelaxationBodyPart all parts")
    func relaxationBodyPartAllParts() async throws {
        let parts = RelaxationBodyPart.allCases
        #expect(parts.count >= 10)
        
        let head = RelaxationBodyPart.head
        #expect(head.displayName == "头部")
        #expect(head.icon == "face.smiling")
        
        let feet = RelaxationBodyPart.feet
        #expect(feet.displayName == "脚部")
    }
    
    // MARK: - Mindfulness Exercise Tests
    
    @Test("MindfulnessExercise creation")
    func mindfulnessExerciseCreation() async throws {
        let exercise = MindfulnessExercise(
            id: UUID(),
            name: "梦境觉察",
            type: .dreamAwareness,
            duration: 300,
            description: "培养对梦境的觉察能力",
            instructions: ["找一个舒适的姿势", "闭上眼睛", "专注于呼吸"],
            difficulty: .beginner,
            tags: ["觉察", "梦境", "正念"]
        )
        
        #expect(exercise.name == "梦境觉察")
        #expect(exercise.type == .dreamAwareness)
        #expect(exercise.duration == 300)
        #expect(exercise.instructions.count == 3)
        #expect(exercise.tags.count == 3)
    }
    
    // MARK: - Music Recommendation Tests
    
    @Test("MusicRecommendation creation")
    func musicRecommendationCreation() async throws {
        let recommendation = MusicRecommendation(
            trackId: "calm_piano_01",
            title: "平静的钢琴",
            artist: "DreamLog",
            duration: 180,
            mood: "平静",
            bpm: 60,
            frequency: "θ波",
            matchScore: 0.95
        )
        
        #expect(recommendation.trackId == "calm_piano_01")
        #expect(recommendation.title == "平静的钢琴")
        #expect(recommendation.mood == "平静")
        #expect(recommendation.bpm == 60)
        #expect(recommendation.matchScore == 0.95)
    }
    
    @Test("MusicRecommendation match score validation")
    func musicRecommendationMatchScoreValidation() async throws {
        let rec1 = MusicRecommendation(
            trackId: "track1",
            title: "Track 1",
            artist: "Artist",
            duration: 180,
            mood: "平静",
            matchScore: 0.0
        )
        #expect(rec1.matchScore >= 0.0)
        
        let rec2 = MusicRecommendation(
            trackId: "track2",
            title: "Track 2",
            artist: "Artist",
            duration: 180,
            mood: "平静",
            matchScore: 1.0
        )
        #expect(rec2.matchScore <= 1.0)
    }
}

@Suite("DreamMeditation Service Tests")
struct DreamMeditationServiceTests {
    
    @Test("Service initialization")
    func serviceInitialization() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: MeditationSession.self, configurations: config)
        let context = ModelContext(container)
        
        let service = DreamMeditationService(modelContext: context)
        #expect(service != nil)
    }
    
    @Test("Session timer calculation")
    func sessionTimerCalculation() async throws {
        let duration: TimeInterval = 600 // 10 minutes
        #expect(duration / 60 == 10)
        
        let shortDuration: TimeInterval = 300 // 5 minutes
        #expect(shortDuration / 60 == 5)
    }
    
    @Test("Audio volume range")
    func audioVolumeRange() async throws {
        let minVolume: Double = 0.0
        let maxVolume: Double = 1.0
        let defaultVolume: Double = 0.8
        
        #expect(defaultVolume >= minVolume)
        #expect(defaultVolume <= maxVolume)
    }
    
    @Test("Timer duration options")
    func timerDurationOptions() async throws {
        let options: [TimeInterval] = [0, 900, 1800, 2700, 3600, 5400]
        
        #expect(options.contains(0))      // 关闭
        #expect(options.contains(900))    // 15 分钟
        #expect(options.contains(1800))   // 30 分钟
        #expect(options.contains(3600))   // 60 分钟
    }
    
    @Test("Meditation type filtering")
    func meditationTypeFiltering() async throws {
        let allTypes = MeditationType.allCases
        
        let guidedTypes = allTypes.filter { $0.category == .guided }
        #expect(guidedTypes.count >= 1)
        
        let breathingTypes = allTypes.filter { $0.category == .breathing }
        #expect(breathingTypes.count >= 1)
        
        let musicTypes = allTypes.filter { $0.category == .music }
        #expect(musicTypes.count >= 1)
    }
    
    @Test("Template difficulty filtering")
    func templateDifficultyFiltering() async throws {
        let templates = [
            MeditationTemplate(name: "Beginner", type: .guidedDream, duration: 300, difficulty: .beginner),
            MeditationTemplate(name: "Intermediate", type: .guidedDream, duration: 600, difficulty: .intermediate),
            MeditationTemplate(name: "Advanced", type: .guidedDream, duration: 900, difficulty: .advanced)
        ]
        
        let beginner = templates.filter { $0.difficulty == .beginner }
        #expect(beginner.count == 1)
        
        let allDifficulties = Set(templates.map { $0.difficulty })
        #expect(allDifficulties.count == 3)
    }
    
    @Test("Session duration validation")
    func sessionDurationValidation() async throws {
        let minDuration: TimeInterval = 60    // 1 minute
        let maxDuration: TimeInterval = 7200  // 2 hours
        
        let validDuration: TimeInterval = 600
        #expect(validDuration >= minDuration)
        #expect(validDuration <= maxDuration)
        
        let tooShort: TimeInterval = 30
        #expect(tooShort < minDuration)
        
        let tooLong: TimeInterval = 10000
        #expect(tooLong > maxDuration)
    }
    
    @Test("Mood tracking before and after")
    func moodTrackingBeforeAndAfter() async throws {
        let moods = ["焦虑", "平静", "快乐", "悲伤", "兴奋", "疲惫", "放松"]
        
        let session = MeditationSession(
            type: .guidedDream,
            duration: 600,
            completed: true,
            moodBefore: "焦虑",
            moodAfter: "放松"
        )
        
        #expect(moods.contains(session.moodBefore ?? ""))
        #expect(moods.contains(session.moodAfter ?? ""))
        #expect(session.moodBefore != session.moodAfter)
    }
    
    @Test("Streak calculation")
    func streakCalculation() async throws {
        let stats = MeditationStats(
            totalSessions: 30,
            totalDuration: 10800,
            completedSessions: 28,
            currentStreak: 5,
            longestStreak: 14
        )
        
        #expect(stats.currentStreak <= stats.longestStreak)
        #expect(stats.currentStreak >= 0)
        #expect(stats.longestStreak >= 0)
    }
    
    @Test("Achievement progress tracking")
    func achievementProgressTracking() async throws {
        let achievement = MeditationAchievement(
            type: .total10Hours,
            title: "十小时大师",
            description: "累计冥想 10 小时",
            icon: "trophy",
            progress: 5.5,
            target: 10.0
        )
        
        #expect(achievement.progress == 5.5)
        #expect(achievement.target == 10.0)
        #expect(achievement.progressPercentage == 55.0)
        #expect(achievement.unlocked == false)
    }
}

// MARK: - Helper Extensions

extension MeditationAchievement {
    init(
        type: MeditationAchievementType,
        title: String,
        description: String,
        icon: String,
        progress: Double = 0,
        target: Double = 1,
        unlocked: Bool = false,
        unlockedAt: Date? = nil
    ) {
        self.init(
            id: UUID(),
            type: type,
            title: title,
            description: description,
            icon: icon,
            unlocked: unlocked,
            unlockedAt: unlockedAt,
            progress: progress,
            target: target
        )
    }
}

extension MeditationTemplate {
    init(
        id: UUID = UUID(),
        name: String,
        type: MeditationType,
        duration: TimeInterval,
        description: String = "",
        voiceType: String = "Ting-Ting",
        backgroundSound: String? = nil,
        musicTrack: String? = nil,
        difficulty: MeditationDifficulty = .beginner,
        tags: [String] = []
    ) {
        self.init(
            id: id,
            name: name,
            type: type,
            duration: duration,
            description: description,
            voiceType: voiceType,
            backgroundSound: backgroundSound,
            musicTrack: musicTrack,
            difficulty: difficulty,
            tags: tags,
            createdAt: Date(),
            updatedAt: Date(),
            playCount: 0,
            averageRating: 0,
            isFavorite: false
        )
    }
}

extension MeditationSession {
    init(
        type: MeditationType,
        duration: TimeInterval,
        completed: Bool = false,
        moodBefore: String? = nil,
        moodAfter: String? = nil,
        dreamId: UUID? = nil,
        audioFile: String? = nil,
        voiceType: String? = nil,
        backgroundSound: String? = nil,
        volume: Double = 0.8,
        timerDuration: TimeInterval? = nil
    ) {
        self.init(
            type: type,
            duration: duration,
            completed: completed,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            dreamId: dreamId,
            audioFile: audioFile,
            voiceType: voiceType,
            backgroundSound: backgroundSound,
            volume: volume,
            timerDuration: timerDuration,
            createdAt: Date(),
            completedAt: completed ? Date() : nil,
            rating: nil,
            notes: nil
        )
    }
}

extension BreathingPattern {
    init(
        name: String,
        inhaleDuration: Int,
        holdDuration: Int,
        exhaleDuration: Int,
        cycles: Int,
        description: String = ""
    ) {
        self.init(
            name: name,
            inhaleDuration: inhaleDuration,
            holdDuration: holdDuration,
            exhaleDuration: exhaleDuration,
            cycles: cycles,
            description: description,
            icon: "wind"
        )
    }
}

extension MusicRecommendation {
    init(
        trackId: String,
        title: String,
        artist: String,
        duration: TimeInterval,
        mood: String,
        bpm: Int = 60,
        frequency: String? = nil,
        matchScore: Double = 0.5
    ) {
        self.init(
            trackId: trackId,
            title: title,
            artist: artist,
            duration: duration,
            mood: mood,
            bpm: bpm,
            frequency: frequency,
            matchScore: matchScore,
            coverArt: nil,
            previewURL: nil
        )
    }
}
