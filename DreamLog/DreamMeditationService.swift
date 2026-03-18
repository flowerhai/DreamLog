//
//  DreamMeditationService.swift
//  DreamLog
//
//  Phase 65: 梦境冥想与放松增强
//  冥想核心服务
//

import Foundation
import SwiftData
import AVFoundation

// MARK: - 冥想服务

@MainActor
final class DreamMeditationService {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var audioPlayer: AVAudioPlayer?
    private var isPlaying: Bool = false
    private var currentSession: MeditationSession?
    private var sessionStartTime: Date?
    private var timer: Timer?
    
    // 音频资源目录
    private let audioDirectory: String
    
    // 回调
    var onSessionStart: ((MeditationSession) -> Void)?
    var onSessionComplete: ((MeditationSession) -> Void)?
    var onSessionUpdate: ((MeditationSession) -> Void)?
    var onPlaybackStateChange: ((Bool) -> Void)?
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // 设置音频目录
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.audioDirectory = documentsPath.appendingPathComponent("MeditationAudio").path
        
        // 确保目录存在
        try? FileManager.default.createDirectory(atPath: audioDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Session Management
    
    /// 开始冥想会话
    func startSession(
        type: MeditationType,
        duration: TimeInterval,
        template: MeditationTemplate? = nil,
        voiceType: String? = nil,
        backgroundSound: String? = nil,
        volume: Double = 0.8,
        timerDuration: TimeInterval? = nil,
        moodBefore: String? = nil,
        dreamId: UUID? = nil
    ) async throws -> MeditationSession {
        
        // 创建会话记录
        let session = MeditationSession(
            type: type,
            duration: duration,
            completed: false,
            moodBefore: moodBefore,
            dreamId: dreamId,
            audioFile: template?.musicTrack,
            voiceType: voiceType ?? template?.voiceType,
            backgroundSound: backgroundSound ?? template?.backgroundSound,
            volume: volume,
            timerDuration: timerDuration
        )
        
        modelContext.insert(session)
        try modelContext.save()
        
        currentSession = session
        sessionStartTime = Date()
        
        // 开始播放音频
        try await startAudioPlayback(for: session, template: template)
        
        // 设置定时器
        setupSessionTimer(duration: duration)
        
        isPlaying = true
        onSessionStart?(session)
        onPlaybackStateChange?(true)
        
        return session
    }
    
    /// 暂停冥想会话
    func pauseSession() {
        audioPlayer?.pause()
        timer?.invalidate()
        isPlaying = false
        onPlaybackStateChange?(false)
    }
    
    /// 恢复冥想会话
    func resumeSession() async throws {
        try await audioPlayer?.play()
        isPlaying = true
        onPlaybackStateChange?(true)
    }
    
    /// 停止冥想会话
    func stopSession(completed: Bool = false) async {
        audioPlayer?.stop()
        timer?.invalidate()
        
        if var session = currentSession, let startTime = sessionStartTime {
            let actualDuration = Date().timeIntervalSince(startTime)
            session.duration = actualDuration
            session.completed = completed
            
            if completed {
                // 更新模板使用次数
                if let audioFile = session.audioFile {
                    await updateTemplateUsageCount(for: audioFile)
                }
                
                // 检查成就
                await checkAchievements(for: session)
                
                onSessionComplete?(session)
            }
            
            try? modelContext.save()
        }
        
        isPlaying = false
        currentSession = nil
        sessionStartTime = nil
        onPlaybackStateChange?(false)
    }
    
    /// 更新会话反馈
    func updateSessionFeedback(
        sessionId: UUID,
        moodAfter: String?,
        sleepQuality: Int?,
        focusLevel: Int?,
        relaxationLevel: Int?,
        wouldRecommend: Bool?,
        notes: String?
    ) async {
        let descriptor = FetchDescriptor<MeditationSession>(
            predicate: #Predicate { $0.id == sessionId }
        )
        
        if var session = (try? modelContext.fetch(descriptor))?.first {
            session.moodAfter = moodAfter
            session.sleepQuality = sleepQuality
            session.focusLevel = focusLevel
            session.relaxationLevel = relaxationLevel
            session.wouldRecommend = wouldRecommend
            session.notes = notes
            
            try? modelContext.save()
            onSessionUpdate?(session)
        }
    }
    
    // MARK: - Audio Playback
    
    /// 开始音频播放
    private func startAudioPlayback(
        for session: MeditationSession,
        template: MeditationTemplate?
    ) async throws {
        
        // 优先使用模板音频，否则使用默认音频
        let audioFile = session.audioFile ?? defaultAudioFile(for: session.meditationType)
        let audioURL = URL(fileURLWithPath: audioDirectory).appendingPathComponent(audioFile)
        
        // 检查文件是否存在，不存在则生成 TTS 音频
        if !FileManager.default.fileExists(atPath: audioURL.path) {
            try await generateTTSAudio(for: session, template: template, outputURL: audioURL)
        }
        
        // 播放音频
        let audioData = try Data(contentsOf: audioURL)
        audioPlayer = try AVAudioPlayer(data: audioData)
        audioPlayer?.volume = Float(session.volume)
        audioPlayer?.prepareToPlay()
        try await audioPlayer?.play()
    }
    
    /// 生成 TTS 音频（占位实现）
    private func generateTTSAudio(
        for session: MeditationSession,
        template: MeditationTemplate?,
        outputURL: URL
    ) async throws {
        
        // TODO: 集成 TTS 服务生成音频
        // 暂时创建空音频文件
        let silenceDuration: Double = session.duration
        // 实际实现需要调用 TTS API
        print("TTS 音频生成：\(template?.name ?? session.type)")
    }
    
    /// 获取默认音频文件
    private func defaultAudioFile(for type: MeditationType?) -> String {
        guard let type = type else { return "default_meditation.mp3" }
        
        switch type {
        case .guidedDream: return "guided_dream.mp3"
        case .sleepStory: return "sleep_story.mp3"
        case .lucidDreamInduction: return "lucid_induction.mp3"
        case .breathing478: return "breathing_478.mp3"
        case .boxBreathing: return "box_breathing.mp3"
        case .wildBreathing: return "wild_breathing.mp3"
        case .morningWake: return "morning_wake.mp3"
        case .bodyScan: return "body_scan.mp3"
        case .dreamRecall: return "dream_recall.mp3"
        case .stressRelief: return "stress_relief.mp3"
        case .dreamAwareness: return "dream_awareness.mp3"
        case .realityCheck: return "reality_check.mp3"
        case .emotionalAwareness: return "emotional_awareness.mp3"
        case .gratitude: return "gratitude.mp3"
        case .musicTherapy: return "music_therapy.mp3"
        case .whiteNoise: return "white_noise.mp3"
        case .binauralBeats: return "binaural_beats.mp3"
        case .customMix: return "custom_mix.mp3"
        }
    }
    
    // MARK: - Timer Management
    
    /// 设置会话定时器
    private func setupSessionTimer(duration: TimeInterval) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.onSessionTick?()
            }
        }
        
        // 设置自动停止定时器
        if let timerDuration = currentSession?.timerDuration {
            DispatchQueue.main.asyncAfter(deadline: .now() + timerDuration) { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.stopSession(completed: true)
                }
            }
        }
    }
    
    var onSessionTick: (() -> Void)?
    
    // MARK: - Template Management
    
    /// 更新模板使用次数
    private func updateTemplateUsageCount(for audioFile: String) async {
        let descriptor = FetchDescriptor<MeditationTemplate>(
            predicate: #Predicate { $0.musicTrack == audioFile || $0.id.UUIDString == audioFile }
        )
        
        if var template = (try? modelContext.fetch(descriptor))?.first {
            template.usageCount += 1
            template.updatedAt = Date()
            try? modelContext.save()
        }
    }
    
    // MARK: - Achievement System
    
    /// 检查成就
    private func checkAchievements(for session: MeditationSession) async {
        let descriptor = FetchDescriptor<MeditationAchievement>()
        
        if let achievements = try? modelContext.fetch(descriptor) {
            for var achievement in achievements {
                let shouldUnlock = checkAchievementCondition(achievement: achievement, session: session)
                
                if shouldUnlock && !achievement.isUnlocked {
                    achievement.isUnlocked = true
                    achievement.unlockedAt = Date()
                    try? modelContext.save()
                    
                    // 通知成就解锁
                    onAchievementUnlocked?(achievement)
                }
            }
        }
    }
    
    /// 检查成就条件
    private func checkAchievementCondition(achievement: MeditationAchievement, session: MeditationSession) -> Bool {
        switch achievement.type {
        case "first_session":
            return true // 第一次会话
            
        case "total_sessions":
            return getTotalSessionCount() >= achievement.requirement
            
        case "total_duration":
            return getTotalDuration() >= TimeInterval(achievement.requirement * 60) // 分钟转秒
            
        case "consecutive_days":
            return getCurrentStreak() >= achievement.requirement
            
        case "type_master":
            // 特定类型冥想大师
            return getSessionCount(for: session.meditationType) >= achievement.requirement
            
        default:
            return false
        }
    }
    
    var onAchievementUnlocked: ((MeditationAchievement) -> Void)?
    
    // MARK: - Statistics
    
    /// 获取总会话数
    func getTotalSessionCount() -> Int {
        let descriptor = FetchDescriptor<MeditationSession>()
        return (try? modelContext.fetch(descriptor))?.count ?? 0
    }
    
    /// 获取总时长
    func getTotalDuration() -> TimeInterval {
        let descriptor = FetchDescriptor<MeditationSession>()
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    /// 获取当前连续天数
    func getCurrentStreak() -> Int {
        // 计算连续练习天数
        let descriptor = FetchDescriptor<MeditationSession>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        
        guard let lastSession = sessions.first else { return 0 }
        
        var streak = 1
        var currentDate = Calendar.current.startOfDay(for: lastSession.createdAt)
        
        for session in sessions.dropFirst() {
            let sessionDate = Calendar.current.startOfDay(for: session.createdAt)
            let daysDiff = Calendar.current.dateComponents([.day], from: sessionDate, to: currentDate).day ?? 0
            
            if daysDiff == 1 {
                streak += 1
                currentDate = sessionDate
            } else if daysDiff > 1 {
                break
            }
        }
        
        return streak
    }
    
    /// 获取特定类型冥想次数
    func getSessionCount(for type: MeditationType?) -> Int {
        guard let type = type else { return 0 }
        
        let descriptor = FetchDescriptor<MeditationSession>(
            predicate: #Predicate { $0.type == type.rawValue }
        )
        return (try? modelContext.fetch(descriptor))?.count ?? 0
    }
    
    /// 获取冥想统计
    func getMeditationStats() -> MeditationStats {
        let descriptor = FetchDescriptor<MeditationSession>()
        let sessions = (try? modelContext.fetch(descriptor)) ?? []
        
        // 基础统计
        let totalSessions = sessions.count
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let averageDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        
        // 按类型统计
        var sessionsByType: [String: Int] = [:]
        var sessionsByCategory: [String: Int] = [:]
        
        for session in sessions {
            sessionsByType[session.type, default: 0] += 1
            if let category = session.meditationType?.category {
                sessionsByCategory[category.rawValue, default: 0] += 1
            }
        }
        
        // 情绪改善率
        let sessionsWithMood = sessions.filter { $0.moodBefore != nil && $0.moodAfter != nil }
        let moodImprovementRate = sessionsWithMood.isEmpty ? 0 :
            Double(sessionsWithMood.filter { $0.moodAfter ?? "" > $0.moodBefore ?? "" }.count) / Double(sessionsWithMood.count)
        
        // 周进度
        var weeklyProgress = Array(repeating: 0, count: 7)
        let calendar = Calendar.current
        let now = Date()
        
        for session in sessions {
            let daysAgo = calendar.dateComponents([.day], from: session.createdAt, to: now).day ?? 0
            if daysAgo < 7 {
                weeklyProgress[6 - daysAgo] += Int(session.duration / 60) // 分钟
            }
        }
        
        // 月进度
        var monthlyProgress = Array(repeating: 0, count: 30)
        for session in sessions {
            let daysAgo = calendar.dateComponents([.day], from: session.createdAt, to: now).day ?? 0
            if daysAgo < 30 {
                monthlyProgress[29 - daysAgo] += Int(session.duration / 60)
            }
        }
        
        return MeditationStats(
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            currentStreak: getCurrentStreak(),
            longestStreak: calculateLongestStreak(from: sessions),
            sessionsByType: sessionsByType,
            sessionsByCategory: sessionsByCategory,
            moodImprovementRate: moodImprovementRate,
            sleepQualityCorrelation: calculateSleepQualityCorrelation(from: sessions),
            dreamRecallCorrelation: 0, // TODO: 实现梦境回忆关联计算
            favoriteTimeOfDay: calculateFavoriteTimeOfDay(from: sessions),
            weeklyProgress: weeklyProgress,
            monthlyProgress: monthlyProgress
        )
    }
    
    private func calculateLongestStreak(from sessions: [MeditationSession]) -> Int {
        // 实现最长连续天数计算
        return getCurrentStreak() // 简化实现
    }
    
    private func calculateSleepQualityCorrelation(from sessions: [MeditationSession]) -> Double {
        // 实现睡眠质量关联计算
        return 0.0 // TODO
    }
    
    private func calculateFavoriteTimeOfDay(from sessions: [MeditationSession]) -> String {
        var morningCount = 0
        var afternoonCount = 0
        var eveningCount = 0
        var nightCount = 0
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.createdAt)
            switch hour {
            case 5..<12: morningCount += 1
            case 12..<17: afternoonCount += 1
            case 17..<22: eveningCount += 1
            default: nightCount += 1
            }
        }
        
        let maxCount = max(morningCount, afternoonCount, eveningCount, nightCount)
        
        if maxCount == morningCount { return "早晨" }
        if maxCount == afternoonCount { return "下午" }
        if maxCount == eveningCount { return "傍晚" }
        return "夜晚"
    }
    
    // MARK: - Preference Management
    
    /// 获取用户偏好
    func getPreference() -> MeditationPreference? {
        let descriptor = FetchDescriptor<MeditationPreference>()
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    /// 保存用户偏好
    func savePreference(_ preference: MeditationPreference) async {
        modelContext.insert(preference)
        try? modelContext.save()
    }
    
    // MARK: - Template Management
    
    /// 获取所有模板
    func getTemplates(
        category: MeditationCategory? = nil,
        type: MeditationType? = nil,
        difficulty: MeditationDifficulty? = nil
    ) -> [MeditationTemplate] {
        var predicates: [Predicate<MeditationTemplate>] = []
        
        if let category = category {
            predicates.append(#Predicate { $0.category == category.rawValue })
        }
        
        if let type = type {
            predicates.append(#Predicate { $0.type == type.rawValue })
        }
        
        if let difficulty = difficulty {
            predicates.append(#Predicate { $0.difficulty == difficulty.rawValue })
        }
        
        let predicate = predicates.reduce(nil) { $0 == nil ? $1 : $0 && $1 } as? Predicate<MeditationTemplate>
        
        let descriptor = FetchDescriptor<MeditationTemplate>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.usageCount, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取推荐模板
    func getRecommendedTemplates(config: MeditationRecommendationConfig) -> [MeditationTemplate] {
        let allTemplates = getTemplates()
        
        // 简单推荐算法：基于时间和类型偏好
        var scoredTemplates: [(MeditationTemplate, Double)] = []
        
        for template in allTemplates {
            var score: Double = 0
            
            // 时间匹配
            if matchesTimeOfDay(template: template, timeOfDay: config.timeOfDay) {
                score += 2.0
            }
            
            // 难度匹配
            if template.difficulty == MeditationDifficulty.beginner.rawValue {
                score += 1.0
            }
            
            // 使用次数（受欢迎程度）
            score += Double(template.usageCount) * 0.01
            
            // 评分
            score += template.averageRating * 0.5
            
            scoredTemplates.append((template, score))
        }
        
        // 按分数排序
        scoredTemplates.sort { $0.1 > $1.1 }
        
        return scoredTemplates.prefix(10).map { $0.0 }
    }
    
    private func matchesTimeOfDay(template: MeditationTemplate, timeOfDay: String) -> Bool {
        // 根据模板标签匹配时间段
        let templateTags = template.tags.map { $0.lowercased() }
        
        switch timeOfDay {
        case "morning":
            return templateTags.contains("早晨") || templateTags.contains("唤醒") || templateTags.contains("活力")
        case "afternoon":
            return templateTags.contains("下午") || templateTags.contains("专注") || templateTags.contains("能量")
        case "evening":
            return templateTags.contains("傍晚") || templateTags.contains("放松") || templateTags.contains("平静")
        case "night":
            return templateTags.contains("夜晚") || templateTags.contains("睡眠") || templateTags.contains("睡前")
        default:
            return true
        }
    }
}

// MARK: - Audio Player Delegate

extension DreamMeditationService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            if flag {
                await stopSession(completed: true)
            }
        }
    }
}
