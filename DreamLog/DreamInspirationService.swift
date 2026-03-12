//
//  DreamInspirationService.swift
//  DreamLog - Phase 23: Dream Inspiration & Creative Prompts
//
//  梦境灵感服务 - 将梦境转化为创意提示和每日灵感
//

import Foundation
import SwiftData

// MARK: - 梦境灵感服务

@MainActor
final class DreamInspirationService {
    static let shared = DreamInspirationService()
    
    private let modelContext: ModelContext
    private var promptTemplates: [PromptTemplate] = []
    
    init(modelContext: ModelContext? = nil) {
        if let context = modelContext {
            self.modelContext = context
        } else if let app = DreamLogApp.shared {
            self.modelContext = ModelContext(app.modelContainer)
        } else {
            // Fallback: create a simple in-memory context
            do {
                let container = try ModelContainer(for: CreativePrompt.self)
                self.modelContext = ModelContext(container)
            } catch {
                // Last resort fallback: use shared container with minimal schema
                let container = ModelContainer(for: CreativePrompt.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                self.modelContext = ModelContext(container)
                print("[DreamInspirationService] Using in-memory ModelContext: \(error)")
            }
        }
        loadPromptTemplates()
    }
    
    // MARK: - 提示模板库
    
    private func loadPromptTemplates() {
        promptTemplates = [
            // 写作类
            PromptTemplate(
                category: "写作",
                title: "梦境续写",
                template: "如果这个梦继续下去，接下来会发生什么？写一个 500 字的续集。",
                variables: ["dreamContent"],
                difficulty: 2,
                estimatedTime: 30,
                tags: ["写作", "创意", "续写"]
            ),
            PromptTemplate(
                category: "写作",
                title: "角色探索",
                template: "选择梦中的一个角色，以 TA 的视角重写这个梦。",
                variables: ["dreamCharacters"],
                difficulty: 3,
                estimatedTime: 45,
                tags: ["写作", "角色", "视角"]
            ),
            PromptTemplate(
                category: "写作",
                title: "诗歌创作",
                template: "将这个梦的意境转化为一首诗（任何形式）。",
                variables: ["dreamEmotion", "dreamImagery"],
                difficulty: 3,
                estimatedTime: 20,
                tags: ["写作", "诗歌", "意境"]
            ),
            PromptTemplate(
                category: "写作",
                title: "微小说",
                template: "以这个梦为核心，创作一个 100 字以内的微小说。",
                variables: ["dreamCore"],
                difficulty: 4,
                estimatedTime: 25,
                tags: ["写作", "微小说", "精炼"]
            ),
            
            // 艺术类
            PromptTemplate(
                category: "艺术",
                title: "梦境速写",
                template: "快速 sketch 梦中最印象深刻的场景（5-10 分钟）。",
                variables: ["dreamScene"],
                difficulty: 2,
                estimatedTime: 10,
                tags: ["艺术", "速写", "视觉"]
            ),
            PromptTemplate(
                category: "艺术",
                title: "色彩情绪",
                template: "用抽象的色彩和形状表达这个梦的情绪。",
                variables: ["dreamEmotion"],
                difficulty: 2,
                estimatedTime: 15,
                tags: ["艺术", "抽象", "色彩"]
            ),
            PromptTemplate(
                category: "艺术",
                title: "符号设计",
                template: "为这个梦设计一个代表性的符号或标志。",
                variables: ["dreamSymbols"],
                difficulty: 3,
                estimatedTime: 30,
                tags: ["艺术", "设计", "符号"]
            ),
            PromptTemplate(
                category: "艺术",
                title: "拼贴艺术",
                template: "用现有图片/素材拼贴出梦境的视觉表达。",
                variables: ["dreamImagery"],
                difficulty: 3,
                estimatedTime: 45,
                tags: ["艺术", "拼贴", "混合媒体"]
            ),
            
            // 音乐类
            PromptTemplate(
                category: "音乐",
                title: "梦境配乐",
                template: "为这个梦选择/创作一段配乐（哼唱或使用乐器）。",
                variables: ["dreamMood"],
                difficulty: 3,
                estimatedTime: 20,
                tags: ["音乐", "配乐", "情绪"]
            ),
            PromptTemplate(
                category: "音乐",
                title: "声音地图",
                template: "记录梦中出现的所有声音，尝试重现或描述它们。",
                variables: ["dreamSounds"],
                difficulty: 2,
                estimatedTime: 15,
                tags: ["音乐", "声音", "记录"]
            ),
            
            // 摄影类
            PromptTemplate(
                category: "摄影",
                title: "场景重现",
                template: "在现实中寻找与梦境相似的场景并拍摄。",
                variables: ["dreamScene"],
                difficulty: 3,
                estimatedTime: 60,
                tags: ["摄影", "重现", "外拍"]
            ),
            PromptTemplate(
                category: "摄影",
                title: "情绪摄影",
                template: "拍摄一组照片表达这个梦的情绪。",
                variables: ["dreamEmotion"],
                difficulty: 3,
                estimatedTime: 45,
                tags: ["摄影", "情绪", "艺术"]
            ),
            
            // 冥想类
            PromptTemplate(
                category: "冥想",
                title: "梦境回顾",
                template: "闭眼回顾这个梦，专注于身体的感受。",
                variables: ["dreamContent"],
                difficulty: 1,
                estimatedTime: 10,
                tags: ["冥想", "回顾", "正念"]
            ),
            PromptTemplate(
                category: "冥想",
                title: "角色对话",
                template: "冥想中与梦中的角色进行对话。",
                variables: ["dreamCharacters"],
                difficulty: 3,
                estimatedTime: 20,
                tags: ["冥想", "对话", "内在"]
            ),
            
            // 项目类
            PromptTemplate(
                category: "项目",
                title: "故事大纲",
                template: "将这个梦发展成完整故事的 outline。",
                variables: ["dreamPlot"],
                difficulty: 4,
                estimatedTime: 60,
                tags: ["项目", "故事", "大纲"]
            ),
            PromptTemplate(
                category: "项目",
                title: "艺术系列",
                template: "基于这个梦开启一个艺术创作系列。",
                variables: ["dreamTheme"],
                difficulty: 4,
                estimatedTime: 120,
                tags: ["项目", "艺术", "系列"]
            ),
            
            // 反思类
            PromptTemplate(
                category: "反思",
                title: "情绪日记",
                template: "写下这个梦引发的所有情绪和联想。",
                variables: ["dreamEmotion"],
                difficulty: 1,
                estimatedTime: 15,
                tags: ["反思", "情绪", "日记"]
            ),
            PromptTemplate(
                category: "反思",
                title: "现实连接",
                template: "这个梦与你最近的生活有什么联系？",
                variables: ["dreamContent", "recentLife"],
                difficulty: 2,
                estimatedTime: 20,
                tags: ["反思", "连接", "洞察"]
            ),
            
            // 挑战类
            PromptTemplate(
                category: "挑战",
                title: "7 天创作",
                template: "连续 7 天，每天基于这个梦创作一件作品。",
                variables: ["dreamTheme"],
                difficulty: 5,
                estimatedTime: 30,
                tags: ["挑战", "创作", "连续"]
            ),
            PromptTemplate(
                category: "挑战",
                title: "多媒介表达",
                template: "用 3 种不同的媒介表达同一个梦。",
                variables: ["dreamContent"],
                difficulty: 4,
                estimatedTime: 90,
                tags: ["挑战", "多媒介", "表达"]
            )
        ]
    }
    
    // MARK: - 生成创意提示
    
    /// 根据梦境生成创意提示
    func generatePrompt(from dream: Dream, type: InspirationType? = nil) -> CreativePrompt {
        let selectedType = type ?? InspirationType.allCases.randomElement() ?? .writing
        let templates = promptTemplates.filter { $0.category == selectedType.rawValue }
        let template = templates.randomElement() ?? promptTemplates.first ?? PromptTemplate(
            category: "写作",
            title: "自由创作",
            template: "记录你的梦境和感受。",
            variables: [],
            difficulty: 1,
            estimatedTime: 15,
            tags: ["写作", "自由"]
        )
        
        var title = template.title
        var description = template.template
        
        // 个性化描述
        description = personalizeTemplate(description, dream: dream)
        
        let prompt = CreativePrompt(
            title: title,
            description: description,
            type: selectedType,
            difficulty: template.difficulty,
            estimatedTime: template.estimatedTime,
            tags: template.tags,
            sourceDreamId: dream.id
        )
        
        return prompt
    }
    
    /// 批量生成提示
    func generatePrompts(from dream: Dream, count: Int = 3) -> [CreativePrompt] {
        var prompts: [CreativePrompt] = []
        var usedTypes: Set<InspirationType> = []
        
        for _ in 0..<count {
            let availableTypes = InspirationType.allCases.filter { !usedTypes.contains($0) }
            guard let type = availableTypes.randomElement() else { break }
            usedTypes.insert(type)
            prompts.append(generatePrompt(from: dream, type: type))
        }
        
        return prompts
    }
    
    /// 生成每日灵感
    func generateDailyInspiration(for date: Date = Date()) -> DailyInspiration {
        let quotes = [
            "梦境是灵魂的私语，创意是它的回响。",
            "在梦与现实的边界，灵感悄然绽放。",
            "每一个梦，都是一颗创意的种子。",
            "潜意识是最伟大的艺术家。",
            "梦是夜晚的礼物，创意是白天的回应。",
            "在梦境深处，遇见最真实的自己。",
            "创意不是等待灵感，而是捕捉梦境。",
            "你的梦，是独一无二的艺术。",
            "醒来，但不要忘记梦中的魔法。",
            "梦境是指南针，创意是旅程。"
        ]
        
        let themes = [
            "自我探索", "创意表达", "情绪疗愈", "内在成长",
            "艺术灵感", "故事创作", "心灵对话", "觉知练习"
        ]
        
        // 获取最近的梦
        let recentDreams = fetchRecentDreams(limit: 5)
        let relatedDreamIds = recentDreams.map { $0.id }
        
        let quote = quotes.randomElement() ?? "在梦境深处，遇见最真实的自己。"
        let theme = themes.randomElement() ?? "自我探索"
        
        // 基于最近的梦生成提示
        let prompt: String
        if let dream = recentDreams.first {
            prompt = generatePrompt(from: dream).description
        } else {
            prompt = "今天，花 10 分钟记录一个你记得的梦，并思考它想告诉你什么。"
        }
        
        let inspiration = DailyInspiration(
            date: date,
            quote: quote,
            prompt: prompt,
            theme: theme,
            relatedDreamIds: relatedDreamIds
        )
        
        return inspiration
    }
    
    // MARK: - 创意挑战
    
    /// 创建创意挑战
    func createChallenge(type: InspirationType, duration: Int = 7) -> CreativeChallenge {
        let challengeNames: [InspirationType: String] = [
            .writing: "7 天写作挑战",
            .art: "7 天艺术挑战",
            .music: "7 天音乐挑战",
            .photography: "7 天摄影挑战",
            .meditation: "7 天冥想挑战",
            .project: "7 天项目挑战",
            .reflection: "7 天反思挑战",
            .challenge: "7 天极限挑战"
        ]
        
        let challengeDescriptions: [InspirationType: String] = [
            .writing: "连续 7 天，每天基于梦境创作一段文字。",
            .art: "连续 7 天，每天用艺术表达一个梦。",
            .music: "连续 7 天，每天为梦境创作/选择音乐。",
            .photography: "连续 7 天，每天拍摄与梦相关的照片。",
            .meditation: "连续 7 天，每天进行梦境冥想。",
            .project: "连续 7 天，每天推进一个梦境相关项目。",
            .reflection: "连续 7 天，每天深度反思一个梦。",
            .challenge: "连续 7 天，每天完成一个创意挑战。"
        ]
        
        let challenge = CreativeChallenge(
            name: challengeNames[type] ?? "7 天创意挑战",
            description: challengeDescriptions[type] ?? "连续 7 天的创意之旅。",
            type: type,
            duration: duration,
            totalPrompts: duration
        )
        
        // 为挑战生成提示
        let dreams = fetchRecentDreams(limit: duration)
        for dream in dreams {
            let prompt = generatePrompt(from: dream, type: type)
            challenge.promptIds.append(prompt.id)
        }
        
        return challenge
    }
    
    // MARK: - 数据操作
    
    /// 保存提示
    func savePrompt(_ prompt: CreativePrompt) {
        modelContext.insert(prompt)
        try? modelContext.save()
    }
    
    /// 保存每日灵感
    func saveDailyInspiration(_ inspiration: DailyInspiration) {
        modelContext.insert(inspiration)
        try? modelContext.save()
    }
    
    /// 保存挑战
    func saveChallenge(_ challenge: CreativeChallenge) {
        modelContext.insert(challenge)
        try? modelContext.save()
    }
    
    /// 标记提示为完成
    func markPromptAsCompleted(_ prompt: CreativePrompt) {
        prompt.isCompleted = true
        prompt.completedDate = Date()
        prompt.updatedAt = Date()
        try? modelContext.save()
    }
    
    /// 切换收藏状态
    func toggleFavorite(_ prompt: CreativePrompt) {
        prompt.isFavorite.toggle()
        prompt.updatedAt = Date()
        try? modelContext.save()
    }
    
    /// 获取所有提示
    func fetchAllPrompts() -> [CreativePrompt] {
        let descriptor = FetchDescriptor<CreativePrompt>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取收藏提示
    func fetchFavoritePrompts() -> [CreativePrompt] {
        let descriptor = FetchDescriptor<CreativePrompt>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取未完成的提示
    func fetchPendingPrompts() -> [CreativePrompt] {
        let descriptor = FetchDescriptor<CreativePrompt>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取所有挑战
    func fetchAllChallenges() -> [CreativeChallenge] {
        let descriptor = FetchDescriptor<CreativeChallenge>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取活跃挑战
    func fetchActiveChallenges() -> [CreativeChallenge] {
        let descriptor = FetchDescriptor<CreativeChallenge>(
            predicate: #Predicate { $0.isActive && !$0.isCompleted },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    /// 获取今日灵感
    func fetchTodayInspiration() -> DailyInspiration? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        let descriptor = FetchDescriptor<DailyInspiration>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
    
    /// 获取灵感统计
    func getStatistics() -> InspirationStatistics {
        let allPrompts = fetchAllPrompts()
        let allChallenges = fetchAllChallenges()
        
        let completedPrompts = allPrompts.filter { $0.isCompleted }
        let favoritePrompts = allPrompts.filter { $0.isFavorite }
        let activeChallenges = fetchActiveChallenges()
        let completedChallenges = allChallenges.filter { $0.isCompleted }
        
        // 计算连续天数
        let streakDays = calculateStreak(from: completedPrompts)
        
        // 按类型统计
        var promptsByType: [String: Int] = [:]
        for prompt in allPrompts {
            promptsByType[prompt.type, default: 0] += 1
        }
        
        // 平均完成时间
        let avgTime = completedPrompts.isEmpty ? 0 :
            Int(completedPrompts.map { $0.estimatedTime }.reduce(0, +) / completedPrompts.count)
        
        return InspirationStatistics(
            totalPrompts: allPrompts.count,
            completedPrompts: completedPrompts.count,
            favoritePrompts: favoritePrompts.count,
            totalChallenges: allChallenges.count,
            completedChallenges: completedChallenges.count,
            activeChallenges: activeChallenges.count,
            streakDays: streakDays,
            lastPromptDate: completedPrompts.map { $0.completedDate }.max(),
            promptsByType: promptsByType,
            averageCompletionTime: avgTime
        )
    }
    
    // MARK: - 辅助方法
    
    private func personalizeTemplate(_ template: String, dream: Dream) -> String {
        var result = template
        
        // 替换梦境相关的变量
        if result.contains("dreamContent") {
            let summary = String(dream.content.prefix(100))
            result = result.replacingOccurrences(of: "dreamContent", with: summary)
        }
        
        if result.contains("dreamEmotion") {
            let emotions = dream.moods.map { $0.rawValue }.joined(separator: "、")
            result = result.replacingOccurrences(of: "dreamEmotion", with: emotions.isEmpty ? "复杂" : emotions)
        }
        
        if result.contains("dreamScene") {
            result = result.replacingOccurrences(of: "dreamScene", with: "梦中的场景")
        }
        
        if result.contains("dreamCharacters") {
            result = result.replacingOccurrences(of: "dreamCharacters", with: "梦中的人物")
        }
        
        if result.contains("dreamSymbols") {
            result = result.replacingOccurrences(of: "dreamSymbols", with: "梦中的符号")
        }
        
        if result.contains("dreamImagery") {
            result = result.replacingOccurrences(of: "dreamImagery", with: "梦中的意象")
        }
        
        if result.contains("dreamMood") {
            result = result.replacingOccurrences(of: "dreamMood", with: dream.moods.first?.rawValue ?? "平静")
        }
        
        if result.contains("dreamSounds") {
            result = result.replacingOccurrences(of: "dreamSounds", with: "梦中的声音")
        }
        
        if result.contains("dreamPlot") {
            result = result.replacingOccurrences(of: "dreamPlot", with: "梦的情节")
        }
        
        if result.contains("dreamTheme") {
            result = result.replacingOccurrences(of: "dreamTheme", with: dream.tags.map { $0.name }.joined(separator: "、"))
        }
        
        if result.contains("dreamCore") {
            let words = dream.content.split(separator: " ").prefix(20)
            result = result.replacingOccurrences(of: "dreamCore", with: String(words))
        }
        
        if result.contains("recentLife") {
            result = result.replacingOccurrences(of: "recentLife", with: "最近的生活")
        }
        
        return result
    }
    
    private func fetchRecentDreams(limit: Int = 5) -> [Dream] {
        let descriptor = FetchDescriptor<Dream>(
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: limit
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private func calculateStreak(from completedPrompts: [CreativePrompt]) -> Int {
        guard !completedPrompts.isEmpty else { return 0 }
        
        let dates = completedPrompts
            .compactMap { $0.completedDate }
            .map { Calendar.current.startOfDay(for: $0) }
            .sorted(by: >)
        
        guard let latest = dates.first else { return 0 }
        
        var streak = 1
        
        for i in 1..<dates.count {
            guard let expectedDate = Calendar.current.date(byAdding: .day, value: -streak, to: latest) else { break }
            if Calendar.current.isDate(expectedDate, inSameDayAs: dates[i]) {
                streak += 1
            } else if dates[i] < expectedDate {
                break
            }
        }
        
        return streak
    }
}
