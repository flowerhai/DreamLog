//
//  DreamStoryService.swift
//  DreamLog
//
//  梦境故事模式核心服务
//  Phase 70: Dream Story Mode - 将相关梦境串联成视觉故事
//

import Foundation
import SwiftData

@ModelActor
actor DreamStoryService {
    
    // MARK: - 属性
    
    private let modelContext: ModelContext
    private let aiArtService: AIArtService
    
    // MARK: - 初始化
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.aiArtService = AIArtService()
    }
    
    // MARK: - 故事创建
    
    /// 创建新的梦境故事
    func createStory(config: DreamStoryConfig) async throws -> DreamStory {
        let story = DreamStory(
            title: config.title,
            description: config.description,
            coverEmoji: config.coverEmoji,
            theme: config.theme,
            storyType: config.storyType,
            dreams: [],
            frames: [],
            tags: config.tags,
            isPublic: config.isPublic
        )
        
        modelContext.insert(story)
        
        // 添加梦境并生成帧
        try await addDreamsToStory(story: story, dreamIds: config.selectedDreams, config: config)
        
        // 计算总时长
        story.duration = story.frames.reduce(0) { $0 + $1.duration }
        
        try modelContext.save()
        
        return story
    }
    
    /// 为故事添加梦境
    func addDreamsToStory(story: DreamStory, dreamIds: [UUID], config: DreamStoryConfig) async throws {
        var order = story.frames.count
        
        for dreamId in dreamIds {
            guard let dream = try getDreamById(dreamId) else {
                continue
            }
            
            // 添加到故事
            story.dreams.append(dream)
            
            // 生成 AI 艺术提示词
            let artPrompt = generateArtPrompt(for: dream)
            
            // 生成旁白
            let narration = config.autoGenerateNarration ? generateNarration(for: dream, storyType: config.storyType) : nil
            
            // 创建帧
            let frame = DreamStoryFrame(
                storyId: story.id,
                dreamId: dream.id,
                order: order,
                title: dream.title,
                content: dream.content,
                aiArtPrompt: artPrompt,
                transition: config.transition,
                duration: config.frameDuration,
                narration: narration
            )
            
            modelContext.insert(frame)
            story.frames.append(frame)
            
            order += 1
            
            // 自动生成 AI 艺术
            if config.autoGenerateArt {
                try await generateArtForFrame(frame)
            }
        }
        
        story.updatedAt = Date()
    }
    
    /// 为帧生成 AI 艺术
    func generateArtForFrame(_ frame: DreamStoryFrame) async throws {
        // 调用 AI 艺术服务生成图片
        let artService = AIArtService()
        let image = try await artService.generateArt(
            prompt: frame.aiArtPrompt,
            style: .dreamlike,
            size: .square
        )
        
        frame.aiArtImage = image
        frame.updatedAt = Date()
        
        try modelContext.save()
    }
    
    // MARK: - 故事管理
    
    /// 获取所有故事
    func getAllStories() async throws -> [DreamStory] {
        let descriptor = FetchDescriptor<DreamStory>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取故事详情
    func getStoryById(_ id: UUID) async throws -> DreamStory? {
        let descriptor = FetchDescriptor<DreamStory>(
            predicate: #Predicate<DreamStory> { $0.id == id }
        )
        let stories = try modelContext.fetch(descriptor)
        return stories.first
    }
    
    /// 更新故事
    func updateStory(_ story: DreamStory, config: DreamStoryConfig) async throws {
        story.title = config.title
        story.description = config.description
        story.theme = config.theme
        story.storyType = config.storyType
        story.coverEmoji = config.coverEmoji
        story.tags = config.tags
        story.isPublic = config.isPublic
        story.updatedAt = Date()
        
        try modelContext.save()
    }
    
    /// 删除故事
    func deleteStory(_ story: DreamStory) async throws {
        // 删除所有关联的帧
        for frame in story.frames {
            modelContext.delete(frame)
        }
        
        modelContext.delete(story)
        try modelContext.save()
    }
    
    /// 重新排序帧
    func reorderFrames(story: DreamStory, frameIds: [UUID]) async throws {
        for (index, frameId) in frameIds.enumerated() {
            if let frame = story.frames.first(where: { $0.id == frameId }) {
                frame.order = index
            }
        }
        
        story.updatedAt = Date()
        try modelContext.save()
    }
    
    /// 删除帧
    func deleteFrame(_ frame: DreamStoryFrame, from story: DreamStory) async throws {
        // 从故事中移除梦境
        if let dreamIndex = story.dreams.firstIndex(where: { $0.id == frame.dreamId }) {
            story.dreams.remove(at: dreamIndex)
        }
        
        // 移除帧
        if let frameIndex = story.frames.firstIndex(where: { $0.id == frame.id }) {
            story.frames.remove(at: frameIndex)
        }
        
        modelContext.delete(frame)
        
        // 重新排序
        for (index, remainingFrame) in story.frames.enumerated() {
            remainingFrame.order = index
        }
        
        story.duration = story.frames.reduce(0) { $0 + $1.duration }
        story.updatedAt = Date()
        
        try modelContext.save()
    }
    
    // MARK: - 智能故事生成
    
    /// 基于标签自动生成故事
    func generateStoryByTag(tag: String, limit: Int = 10) async throws -> DreamStory? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { $0.tags.contains(tag) },
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: limit
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        guard !dreams.isEmpty else { return nil }
        
        let config = DreamStoryConfig(
            title: "「\(tag)」主题梦境集",
            description: "围绕「\(tag)」主题的梦境故事",
            selectedDreams: dreams.map { $0.id },
            theme: .starry,
            storyType: .thematic,
            autoGenerateArt: true,
            autoGenerateNarration: true,
            tags: [tag]
        )
        
        return try await createStory(config: config)
    }
    
    /// 基于情绪生成故事
    func generateStoryByEmotion(emotion: Emotion, limit: Int = 10) async throws -> DreamStory? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { $0.emotions.contains(emotion) },
            sortBy: [SortDescriptor(\.date, order: .reverse)],
            fetchLimit: limit
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        guard !dreams.isEmpty else { return nil }
        
        let theme: DreamStoryTheme = emotion == .fear || emotion == .anxiety ? .midnight : .starry
        
        let config = DreamStoryConfig(
            title: "「\(emotion.displayName)」情绪之旅",
            description: "探索「\(emotion.displayName)」情绪的梦境旅程",
            selectedDreams: dreams.map { $0.id },
            theme: theme,
            storyType: .emotional,
            autoGenerateArt: true,
            autoGenerateNarration: true,
            tags: ["情绪", emotion.rawValue]
        )
        
        return try await createStory(config: config)
    }
    
    /// 基于时间范围生成故事
    func generateStoryByDateRange(start: Date, end: Date) async throws -> DreamStory? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { $0.date >= start && $0.date <= end },
            sortBy: [SortDescriptor(\.date, order: .forward)],
            fetchLimit: 20
        )
        
        let dreams = try modelContext.fetch(descriptor)
        
        guard !dreams.isEmpty else { return nil }
        
        let config = DreamStoryConfig(
            title: "梦境时光机",
            description: "\(start.formatted()) - \(end.formatted()) 的梦境记录",
            selectedDreams: dreams.map { $0.id },
            theme: .lavender,
            storyType: .chronological,
            autoGenerateArt: true,
            autoGenerateNarration: true
        )
        
        return try await createStory(config: config)
    }
    
    // MARK: - 统计
    
    /// 获取故事统计
    func getStats() async throws -> DreamStoryStats {
        let allStories = try await getAllStories()
        
        let totalStories = allStories.count
        let totalFrames = allStories.reduce(0) { $0 + $1.frames.count }
        let totalViews = allStories.reduce(0) { $0 + $1.viewCount }
        let totalLikes = allStories.reduce(0) { $0 + $1.likeCount }
        let totalShares = allStories.reduce(0) { $0 + $1.shareCount }
        let totalDuration = allStories.reduce(0) { $0 + $1.duration }
        let averageDuration = totalStories > 0 ? totalDuration / Double(totalStories) : 0
        
        // 计算最受欢迎的主题和类型
        let themeCounts = Dictionary(grouping: allStories, by: { $0.theme })
            .mapValues { $0.count }
        let typeCounts = Dictionary(grouping: allStories, by: { $0.storyType })
            .mapValues { $0.count }
        
        let favoriteTheme = themeCounts.max(by: { $0.value < $1.value })?.key
        let favoriteType = typeCounts.max(by: { $0.value < $1.value })?.key
        
        let recentStories = allStories.prefix(5).map { $0 }
        
        return DreamStoryStats(
            totalStories: totalStories,
            totalFrames: totalFrames,
            totalViews: totalViews,
            totalLikes: totalLikes,
            totalShares: totalShares,
            averageDuration: averageDuration,
            favoriteTheme: favoriteTheme,
            favoriteType: favoriteType,
            recentStories: recentStories
        )
    }
    
    // MARK: - 分享
    
    /// 生成分享链接
    func generateShareLink(for story: DreamStory) async throws -> String {
        // 生成 8 位分享码
        let shareCode = String(UUID().uuidString.prefix(8).uppercased())
        
        // 在实际应用中，这里应该生成一个有效的 URL
        // 现在返回一个占位符
        return "dreamlog://story/\(shareCode)"
    }
    
    /// 创建分享卡片
    func createShareCard(for story: DreamStory) async throws -> DreamStoryShareCard {
        let shareUrl = try await generateShareLink(for: story)
        
        // 生成封面图（使用第一帧的 AI 艺术或默认封面）
        var coverImage: Data?
        if let firstFrame = story.frames.first, let artData = firstFrame.aiArtImage {
            coverImage = artData
        }
        
        return DreamStoryShareCard(
            storyId: story.id,
            title: story.title,
            coverImage: coverImage,
            frameCount: story.frames.count,
            duration: story.duration,
            theme: story.theme,
            shareUrl: shareUrl
        )
    }
    
    // MARK: - 辅助方法
    
    /// 获取梦境
    private func getDreamById(_ id: UUID) async throws -> Dream? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate<Dream> { $0.id == id }
        )
        let dreams = try modelContext.fetch(descriptor)
        return dreams.first
    }
    
    /// 生成 AI 艺术提示词
    private func generateArtPrompt(for dream: Dream) -> String {
        var prompt = "梦境场景，"
        
        // 添加情绪关键词
        if !dream.emotions.isEmpty {
            let emotionKeywords = dream.emotions.map { emotion in
                switch emotion {
                case .calm: return "平静祥和的氛围"
                case .happy: return "快乐明亮的色彩"
                case .anxiety: return "紧张不安的感觉"
                case .fear: return "恐惧神秘的元素"
                case .confused: return "模糊朦胧的视觉效果"
                case .excited: return "充满活力和动感"
                case .sad: return "忧郁悲伤的色调"
                case .angry: return "激烈冲突的画面"
                case .surprised: return "惊奇意外的元素"
                case .neutral: return "中性平和的场景"
                @unknown default: return ""
                }
            }
            prompt += emotionKeywords.joined(separator: ", ") + ", "
        }
        
        // 添加标签
        if !dream.tags.isEmpty {
            prompt += dream.tags.joined(separator: ", ") + ", "
        }
        
        // 添加清晰度影响
        if dream.clarity >= 4 {
            prompt += "清晰细腻的细节，"
        } else if dream.clarity <= 2 {
            prompt += "模糊梦幻的效果，"
        }
        
        // 添加清醒梦标识
        if dream.isLucid {
            prompt += "超现实清醒梦风格，"
        }
        
        prompt += "超现实主义艺术风格，梦幻般的氛围"
        
        return prompt
    }
    
    /// 生成旁白
    private func generateNarration(for dream: Dream, storyType: DreamStoryType) -> String {
        let dateStr = dream.date.formatted(.dateTime.year().month().day())
        
        switch storyType {
        case .chronological:
            return "在\(dateStr)的夜晚，我梦见了：\(dream.content.prefix(100))..."
            
        case .thematic:
            return "这个梦境围绕着\(dream.tags.first ?? "主题")展开，\(dream.content.prefix(80))..."
            
        case .emotional:
            let emotions = dream.emotions.map { $0.displayName }.joined(separator: "与")
            return "带着\(emotions)的情绪，我进入了这个梦境：\(dream.content.prefix(80))..."
            
        case .lucid:
            return "在清醒梦中，我意识到自己在做梦：\(dream.content.prefix(80))..."
            
        case .creative:
            return "这个梦境带来了创意灵感：\(dream.content.prefix(80))..."
            
        case .healing:
            return "在疗愈的梦境中，我经历了：\(dream.content.prefix(80))..."
        }
    }
}
