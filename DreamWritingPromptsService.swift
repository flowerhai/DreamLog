//
//  DreamWritingPromptsService.swift
//  DreamLog - Phase 80: Dream Writing Prompts & Creative Exercises
//
//  Created by DreamLog Team on 2026-03-21.
//  Copyright © 2026 DreamLog. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Writing Prompts Service

/// 写作提示服务
@ModelActor
final actor DreamWritingPromptsService {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Prompt Generation
    
    /// 为梦境生成写作提示
    func generatePrompts(for dream: DreamRecord, count: Int = 3) async throws -> [WritingPrompt] {
        var prompts: [WritingPrompt] = []
        
        // 获取梦境信息
        let content = dream.content
        let emotions = dream.emotions.map { $0.rawValue }
        let tags = dream.tags
        
        // 生成不同类型的提示
        let promptTypes: [WritingPromptType] = [.continuation, .perspective, .emotion, .symbol, .dialogue, .alternative]
        let selectedTypes = Array(promptTypes.shuffled().prefix(count))
        
        for type in selectedTypes {
            let prompt = try await generatePrompt(
                type: type,
                dreamContent: content,
                dreamEmotions: emotions,
                dreamTags: tags,
                dreamId: dream.id
            )
            prompts.append(prompt)
        }
        
        return prompts
    }
    
    /// 生成单个写作提示
    private func generatePrompt(
        type: WritingPromptType,
        dreamContent: String,
        dreamEmotions: [String],
        dreamTags: [String],
        dreamId: UUID
    ) async throws -> WritingPrompt {
        
        let difficulty: PromptDifficulty = type.difficulty
        
        switch type {
        case .continuation:
            return generateContinuationPrompt(content: dreamContent, emotions: dreamEmotions, dreamId: dreamId, difficulty: difficulty)
        case .perspective:
            return generatePerspectivePrompt(content: dreamContent, tags: dreamTags, dreamId: dreamId, difficulty: difficulty)
        case .alternative:
            return generateAlternativePrompt(content: dreamContent, dreamId: dreamId, difficulty: difficulty)
        case .dialogue:
            return generateDialoguePrompt(content: dreamContent, dreamId: dreamId, difficulty: difficulty)
        case .emotion:
            return generateEmotionPrompt(emotions: dreamEmotions, dreamId: dreamId, difficulty: difficulty)
        case .symbol:
            return generateSymbolPrompt(tags: dreamTags, dreamId: dreamId, difficulty: difficulty)
        case .prequel:
            return generatePrequelPrompt(content: dreamContent, dreamId: dreamId, difficulty: difficulty)
        case .analysis:
            return generateAnalysisPrompt(content: dreamContent, emotions: dreamEmotions, dreamId: dreamId, difficulty: difficulty)
        case .creative:
            return generateCreativePrompt(content: dreamContent, tags: dreamTags, dreamId: dreamId, difficulty: difficulty)
        case .reflection:
            return generateReflectionPrompt(emotions: dreamEmotions, dreamId: dreamId, difficulty: difficulty)
        }
    }
    
    // MARK: - Prompt Generators
    
    private func generateContinuationPrompt(content: String, emotions: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "续写这个梦境"
        let content_prompt = """
        你的梦境在这里暂停了。现在，让我们想象如果梦境继续下去会发生什么：
        
        1. 主角接下来会遇到什么？
        2. 梦境的场景会如何变化？
        3. 情绪会如何发展？
        4. 会有新的角色出现吗？
        
        请继续书写这个梦境的后续故事，至少 200 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .continuation,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["续写", "创意", emotions.first ?? "未知"]
        )
    }
    
    private func generatePerspectivePrompt(content: String, tags: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "换个视角看这个梦"
        let content_prompt = """
        尝试从另一个角色的视角重新讲述这个梦境：
        
        • 如果你是梦中的另一个人物，你会看到什么？
        • 如果你是梦中的一个物体或场景，你会有什么感受？
        • 如果从旁观者的角度看，这个梦会是什么样子？
        
        选择一个不同的视角，重新描述这个梦境。至少 150 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .perspective,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["视角", "反思"] + tags.prefix(2)
        )
    }
    
    private func generateAlternativePrompt(content: String, dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "平行世界的梦境"
        let content_prompt = """
        想象在另一个平行世界中，这个梦境的关键节点发生了不同的选择：
        
        1. 找出梦中的一个关键决定或转折点
        2. 如果做了不同的选择，会发生什么？
        3. 梦境会如何发展？
        4. 结局会有什么不同？
        
        探索这个"如果...会怎样"的平行梦境。至少 200 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .alternative,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["平行世界", "创意", "选择"]
        )
    }
    
    private func generateDialoguePrompt(content: String, dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "扩展梦中对话"
        let content_prompt = """
        深入探索梦中角色之间的对话：
        
        • 选择梦中的两个角色（可以是你和另一个人，或两个其他角色）
        • 想象他们之间可能进行的更深层对话
        • 他们会讨论什么？
        • 有什么话想说但没有说出口？
        
        以对话形式书写，至少 10 轮对话。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .dialogue,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["对话", "角色", "交流"]
        )
    }
    
    private func generateEmotionPrompt(emotions: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let primaryEmotion = emotions.first ?? "复杂"
        let title = "探索\(primaryEmotion)情绪"
        let content_prompt = """
        深入探索你在梦中体验到的情绪：
        
        1. 这种情绪在身体的哪个部位感受最强烈？
        2. 它让你联想到什么颜色、形状或图像？
        3. 这种情绪想告诉你什么？
        4. 它在你的现实生活中是否熟悉？
        
        自由书写你对这种情绪的感受和联想。至少 150 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .emotion,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["情绪", "内省", primaryEmotion]
        )
    }
    
    private func generateSymbolPrompt(tags: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let primaryTag = tags.first ?? "符号"
        let title = "探索「\(primaryTag)」的象征意义"
        let content_prompt = """
        深入探索梦中出现的符号「\(primaryTag)」：
        
        • 这个符号让你联想到什么？
        • 它在你的生活中有什么特殊意义吗？
        • 如果这个符号会说话，它会说什么？
        • 它可能代表你内心的什么部分？
        
        自由书写你对这个符号的思考和联想。至少 150 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .symbol,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["符号", "象征", primaryTag]
        )
    }
    
    private func generatePrequelPrompt(content: String, dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "梦境前传"
        let content_prompt = """
        探索这个梦境发生之前的故事：
        
        1. 在梦境开始之前，主角在做什么？
        2. 是什么导致了这个梦境的发生？
        3. 梦中的场景是如何形成的？
        4. 角色们从哪里来？
        
        书写这个梦境的前传故事。至少 200 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .prequel,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["前传", "背景故事", "创意"]
        )
    }
    
    private func generateAnalysisPrompt(content: String, emotions: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "梦境深度分析"
        let content_prompt = """
        对这个梦境进行深度分析：
        
        • 这个梦境可能反映了你现实生活中的什么情况？
        • 梦中的情绪与你近期的情绪状态有什么关联？
        • 有什么重复出现的主题或符号吗？
        • 这个梦想告诉你什么？
        
        写下你的分析和洞察。至少 200 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .analysis,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["分析", "洞察", "反思"]
        )
    }
    
    private func generateCreativePrompt(content: String, tags: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "创意写作练习"
        let content_prompt = """
        基于你的梦境元素进行创意写作：
        
        选择梦中的 2-3 个元素（角色、场景、物体、情绪），
        用它们创作一个全新的故事。这个故事可以：
        
        • 是完全不同的类型（科幻、奇幻、悬疑等）
        • 发生在不同的时空
        • 有不同的人物和情节
        
        让想象力自由飞翔！至少 300 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .creative,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["创意", "故事", "想象"] + tags.prefix(2)
        )
    }
    
    private func generateReflectionPrompt(emotions: [String], dreamId: UUID, difficulty: PromptDifficulty) -> WritingPrompt {
        let title = "反思与感悟"
        let content_prompt = """
        记录你对这个梦的反思和感悟：
        
        1. 这个梦给你留下了什么印象？
        2. 它让你想到了什么？
        3. 你从中学到了什么？
        4. 它是否给你带来了什么启发？
        5. 你会如何将这个梦的智慧应用到现实生活中？
        
        自由书写你的思考。至少 150 字。
        """
        
        return WritingPrompt(
            title: title,
            content: content_prompt,
            type: .reflection,
            difficulty: difficulty,
            dreamId: dreamId,
            tags: ["反思", "感悟", "成长"]
        )
    }
    
    // MARK: - CRUD Operations
    
    /// 保存写作提示
    func savePrompt(_ prompt: WritingPrompt) throws {
        modelContext.insert(prompt)
        try modelContext.save()
    }
    
    /// 获取所有写作提示
    func getAllPrompts() throws -> [WritingPrompt] {
        let descriptor = FetchDescriptor<WritingPrompt>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取特定梦境的写作提示
    func getPrompts(for dreamId: UUID) throws -> [WritingPrompt] {
        let descriptor = FetchDescriptor<WritingPrompt>(
            predicate: #Predicate { $0.dreamId == dreamId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取未完成的提示
    func getIncompletePrompts() throws -> [WritingPrompt] {
        let descriptor = FetchDescriptor<WritingPrompt>(
            predicate: #Predicate { $0.isCompleted == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 标记提示为完成
    func completePrompt(_ prompt: WritingPrompt, wordCount: Int, notes: String? = nil) throws {
        prompt.isCompleted = true
        prompt.completedAt = Date()
        prompt.wordCount = wordCount
        prompt.userNotes = notes
        prompt.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 删除提示
    func deletePrompt(_ prompt: WritingPrompt) throws {
        modelContext.delete(prompt)
        try modelContext.save()
    }
    
    // MARK: - Writing Sessions
    
    /// 创建写作会话
    func createSession(for promptId: UUID) throws -> WritingSession {
        let session = WritingSession(promptId: promptId)
        modelContext.insert(session)
        try modelContext.save()
        return session
    }
    
    /// 更新写作会话
    func updateSession(_ session: WritingSession, content: String, wordCount: Int) throws {
        session.content = content
        session.wordCount = wordCount
        try modelContext.save()
    }
    
    /// 保存写作会话
    func saveSession(_ session: WritingSession, mood: String? = nil, tags: [String] = []) throws {
        session.isSaved = true
        session.endTime = Date()
        session.mood = mood
        session.tags = tags
        try modelContext.save()
    }
    
    /// 获取写作会话历史
    func getSessionHistory(limit: Int = 20) throws -> [WritingSession] {
        let descriptor = FetchDescriptor<WritingSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)],
            fetchLimit: limit
        )
        return try modelContext.fetch(descriptor)
    }
    
    // MARK: - Statistics
    
    /// 获取写作统计
    func getStatistics() throws -> WritingStatistics {
        let allPrompts = try getAllPrompts()
        let completedPrompts = allPrompts.filter { $0.isCompleted }
        let sessions = try getSessionHistory(limit: 1000)
        
        let totalWords = completedPrompts.reduce(0) { $0 + $1.wordCount }
        let promptsByType = Dictionary(grouping: completedPrompts, by: { $0.type })
            .mapValues { $0.count }
        
        // 计算连续天数
        let streakDays = calculateStreak(from: completedPrompts)
        
        // 计算平均字数
        let averageWords = completedPrompts.isEmpty ? 0 : totalWords / completedPrompts.count
        
        // 找出最喜欢的类型
        let favoriteTypeRaw = promptsByType.max(by: { $0.value < $1.value })?.key
        let favoriteType = favoriteTypeRaw.flatMap { WritingPromptType(rawValue: $0) }
        
        // 计算本周进度
        let weeklyProgress = calculateWeeklyProgress(from: completedPrompts)
        
        return WritingStatistics(
            totalPrompts: allPrompts.count,
            completedPrompts: completedPrompts.count,
            totalWords: totalWords,
            streakDays: streakDays,
            lastWritingDate: completedPrompts.first?.completedAt,
            promptsByType: promptsByType,
            averageWordsPerSession: averageWords,
            favoriteType: favoriteType,
            weeklyGoal: 3,
            weeklyProgress: weeklyProgress
        )
    }
    
    private func calculateStreak(from prompts: [WritingPrompt]) -> Int {
        guard !prompts.isEmpty else { return 0 }
        
        let sortedPrompts = prompts.sorted { $0.completedAt ?? .distantPast > $1.completedAt ?? .distantPast }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: sortedPrompts.first?.completedAt ?? Date())
        
        for prompt in sortedPrompts {
            guard let completedAt = prompt.completedAt else { continue }
            let promptDate = Calendar.current.startOfDay(for: completedAt)
            
            let daysDiff = Calendar.current.dateComponents([.day], from: promptDate, to: currentDate).day ?? 0
            
            if daysDiff <= 1 {
                streak += 1
                currentDate = promptDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateWeeklyProgress(from prompts: [WritingPrompt]) -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return prompts.filter { ($0.completedAt ?? .distantPast) >= weekAgo }.count
    }
    
    // MARK: - Preferences
    
    /// 获取写作偏好
    func getPreferences() throws -> WritingPreferences? {
        let descriptor = FetchDescriptor<WritingPreferences>()
        let prefs = try modelContext.fetch(descriptor)
        return prefs.first
    }
    
    /// 保存写作偏好
    func savePreferences(_ prefs: WritingPreferences) throws {
        let existing = try getPreferences()
        if let existing = existing {
            existing.dailyGoal = prefs.dailyGoal
            existing.weeklyGoal = prefs.weeklyGoal
            existing.preferredTypes = prefs.preferredTypes
            existing.reminderEnabled = prefs.reminderEnabled
            existing.reminderTime = prefs.reminderTime
            existing.autoSaveEnabled = prefs.autoSaveEnabled
            existing.showTips = prefs.showTips
            existing.defaultDifficulty = prefs.defaultDifficulty
        } else {
            modelContext.insert(prefs)
        }
        try modelContext.save()
    }
    
    // MARK: - Achievements
    
    /// 检查并更新成就
    func checkAchievements() throws -> [WritingAchievement] {
        let stats = try getStatistics()
        var achievements: [WritingAchievement] = []
        
        for var achievement in WritingAchievement.allAchievements {
            switch achievement.name {
            case "初次尝试":
                achievement.progress = min(stats.completedPrompts, achievement.requirement)
            case "持之以恒":
                achievement.progress = min(stats.streakDays, achievement.requirement)
            case "多产作家":
                achievement.progress = min(stats.completedPrompts, achievement.requirement)
            case "万字达人":
                achievement.progress = min(stats.totalWords, achievement.requirement)
            case "全能写手":
                achievement.progress = min(stats.promptsByType.count, achievement.requirement)
            default:
                achievement.progress = 0
            }
            
            achievement.progress = min(achievement.progress, achievement.requirement)
            achievements.append(achievement)
        }
        
        return achievements
    }
    
    // MARK: - Daily Prompt
    
    /// 生成每日提示
    func generateDailyPrompt() async throws -> WritingPrompt? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 检查今天是否已经生成过
        let descriptor = FetchDescriptor<WritingPrompt>(
            predicate: #Predicate { prompt in
                guard let createdAt = prompt.createdAt as Date? else { return false }
                return calendar.isDate(createdAt, inSameDayAs: today)
            }
        )
        
        let existingPrompts = try modelContext.fetch(descriptor)
        if !existingPrompts.isEmpty {
            return existingPrompts.first
        }
        
        // 生成新的每日提示
        let dailyTypes: [WritingPromptType] = [.reflection, .creative, .emotion]
        let type = dailyTypes.randomElement() ?? .reflection
        
        let prompt = WritingPrompt(
            title: "每日写作：\(type.displayName)",
            content: generateDailyPromptContent(for: type),
            type: type,
            difficulty: .easy,
            tags: ["每日", "推荐"]
        )
        
        try savePrompt(prompt)
        return prompt
    }
    
    private func generateDailyPromptContent(for type: WritingPromptType) -> String {
        switch type {
        case .reflection:
            return """
            今日的反思：
            
            回想一下你最近的梦境，有什么特别的印象或感受吗？
            写下你的思考和感悟。
            """
        case .creative:
            return """
            今日的创意：
            
            选择一个你喜欢的梦境元素，用它创作一个微型故事（100-200 字）。
            """
        case .emotion:
            return """
            今日的情绪：
            
            你今天的主要情绪是什么？它让你联想到什么样的梦境？
            描述一下这个想象中的梦。
            """
        default:
            return "今天的写作提示正在准备中..."
        }
    }
}
