//
//  DreamArtCardService.swift
//  DreamLog
//
//  Phase 54 - AI 梦境艺术分享卡片
//  艺术卡片核心服务
//

import Foundation
import SwiftUI
import NaturalLanguage
import SwiftData

@ModelActor
actor DreamArtCardService {
    
    // MARK: - 单例
    
    static var shared: DreamArtCardService?
    
    static func initialize(modelContainer: ModelContainer) -> DreamArtCardService {
        let instance = DreamArtCardService(modelContainer: modelContainer)
        self.shared = instance
        return instance
    }
    
    // MARK: - 属性
    
    private var templateCache: [UUID: ArtCardTemplate] = [:]
    private var generationQueue: [UUID] = []
    
    // MARK: - 模板管理
    
    /// 获取所有模板
    func getAllTemplates() async throws -> [ArtCardTemplate] {
        let descriptor = FetchDescriptor<ArtCardTemplate>()
        return try modelContext.fetch(descriptor).sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// 获取预设模板
    func getPresetTemplates() async throws -> [ArtCardTemplate] {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { $0.isPreset }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取自定义模板
    func getCustomTemplates() async throws -> [ArtCardTemplate] {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { !$0.isPreset }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取收藏模板
    func getFavoriteTemplates() async throws -> [ArtCardTemplate] {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { $0.isFavorite }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按分类获取模板
    func getTemplates(by category: TemplateCategory) async throws -> [ArtCardTemplate] {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { $0.category == category }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 按平台获取模板
    func getTemplates(for platform: String) async throws -> [ArtCardTemplate] {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { $0.platform == platform }
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// 获取单个模板
    func getTemplate(id: UUID) async throws -> ArtCardTemplate? {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// 创建模板
    func createTemplate(_ template: ArtCardTemplate) async throws {
        modelContext.insert(template)
        try modelContext.save()
        templateCache[template.id] = template
    }
    
    /// 更新模板
    func updateTemplate(_ template: ArtCardTemplate) async throws {
        template.updatedAt = Date()
        try modelContext.save()
        templateCache[template.id] = template
    }
    
    /// 删除模板
    func deleteTemplate(id: UUID) async throws {
        let descriptor = FetchDescriptor<ArtCardTemplate>(
            predicate: #Predicate { $0.id == id }
        )
        let templates = try modelContext.fetch(descriptor)
        templates.forEach { modelContext.delete($0) }
        try modelContext.save()
        templateCache.removeValue(forKey: id)
    }
    
    /// 切换收藏状态
    func toggleFavorite(id: UUID) async throws {
        guard let template = try await getTemplate(id: id) else { return }
        template.isFavorite.toggle()
        template.updatedAt = Date()
        try modelContext.save()
        templateCache[id] = template
    }
    
    /// 增加使用次数
    func incrementUsage(id: UUID) async throws {
        guard let template = try await getTemplate(id: id) else { return }
        template.usageCount += 1
        template.updatedAt = Date()
        try modelContext.save()
    }
    
    // MARK: - 卡片生成
    
    /// 生成艺术卡片
    func generateArtCard(config: CardGenerationConfig) async throws -> ArtCardGenerationResult {
        let startTime = Date()
        
        // 获取梦境数据
        guard let dream = try await getDream(id: config.dreamId) else {
            return ArtCardGenerationResult(
                success: false,
                errorMessage: "梦境不存在",
                metadata: CardMetadata.empty
            )
        }
        
        // 获取或创建模板
        let template: ArtCardTemplate
        if let templateId = config.templateId,
           let cachedTemplate = try await getTemplate(id: templateId) {
            template = cachedTemplate
        } else {
            template = createTemplateFromStyle(config.style)
        }
        
        // AI 文本增强
        let enhancedText = try await enhanceText(
            dream.content,
            mode: config.textEnhancementMode
        )
        
        // 生成卡片
        let generator = DreamArtCardGenerator()
        let result = try await generator.renderCard(
            dream: dream,
            template: template,
            enhancedText: enhancedText,
            config: config
        )
        
        // 更新统计
        if result.success {
            try await incrementUsage(id: template.id)
        }
        
        return ArtCardGenerationResult(
            success: result.success,
            imagePath: result.imagePath,
            imageData: result.imageData,
            thumbnailPath: result.thumbnailPath,
            processingTime: Date().timeIntervalSince(startTime),
            errorMessage: result.errorMessage,
            metadata: CardMetadata(
                dreamId: config.dreamId,
                style: config.style,
                templateId: config.templateId,
                platform: config.platform,
                dimensions: result.dimensions,
                fileSize: result.fileSize,
                createdAt: Date(),
                enhancementMode: config.textEnhancementMode
            )
        )
    }
    
    /// 批量生成卡片
    func batchGenerateCards(configs: [CardGenerationConfig]) async throws -> [ArtCardGenerationResult] {
        var results: [ArtCardGenerationResult] = []
        
        for config in configs {
            do {
                let result = try await generateArtCard(config: config)
                results.append(result)
            } catch {
                results.append(ArtCardGenerationResult(
                    success: false,
                    errorMessage: error.localizedDescription,
                    metadata: CardMetadata.empty
                ))
            }
        }
        
        return results
    }
    
    // MARK: - AI 文本增强
    
    /// 增强文本
    func enhanceText(_ text: String, mode: TextEnhancementMode) async throws -> AITextEnhancement {
        guard mode != .none else {
            return AITextEnhancement(
                originalText: text,
                enhancedText: text,
                mode: mode,
                keywords: extractKeywords(from: text),
                suggestedEmojis: suggestEmojis(for: text),
                confidence: 1.0,
                processingTime: 0
            )
        }
        
        let startTime = Date()
        
        // 提取关键词
        let keywords = extractKeywords(from: text)
        
        // 根据模式增强文本
        let enhancedText: String
        switch mode {
        case .poetic:
            enhancedText = makePoetic(text)
        case .concise:
            enhancedText = makeConcise(text)
        case .vivid:
            enhancedText = makeVivid(text)
        case .none:
            enhancedText = text
        }
        
        // 建议 emoji
        let emojis = suggestEmojis(for: enhancedText)
        
        return AITextEnhancement(
            originalText: text,
            enhancedText: enhancedText,
            mode: mode,
            keywords: keywords,
            suggestedEmojis: emojis,
            confidence: 0.85,
            processingTime: Date().timeIntervalSince(startTime)
        )
    }
    
    /// 提取关键词
    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        
        var keywords: [String] = []
        
        // 提取名词
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType) { tag, range in
            if let tag = tag, [.personalName, .organizationName, .placeName].contains(tag) {
                let keyword = String(text[range])
                if !keywords.contains(keyword) && keyword.count > 1 {
                    keywords.append(keyword)
                }
            }
        }
        
        // 如果关键词太少，使用简单的词频分析
        if keywords.count < 3 {
            let words = text
                .lowercased()
                .components(separatedBy: CharacterSet.whitespacesAndNewlines)
                .filter { $0.count > 2 }
            
            let frequency = Dictionary(grouping: words, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            keywords.append(contentsOf: frequency.prefix(5).map { $0.key })
        }
        
        return Array(keywords.prefix(10))
    }
    
    /// 建议 emoji
    private func suggestEmojis(for text: String) -> [String] {
        var emojis: [String] = []
        
        let lowercased = text.lowercased()
        
        // 梦境相关
        if lowercased.contains("梦") { emojis.append("🌙") }
        if lowercased.contains("睡") { emojis.append("💤") }
        
        // 情绪相关
        if lowercased.contains("快乐") || lowercased.contains("开心") { emojis.append("😊") }
        if lowercased.contains("悲伤") { emojis.append("😢") }
        if lowercased.contains("害怕") || lowercased.contains("恐惧") { emojis.append("😱") }
        if lowercased.contains("惊讶") { emojis.append("😲") }
        if lowercased.contains("平静") { emojis.append("😌") }
        
        // 元素相关
        if lowercased.contains("水") || lowercased.contains("海") || lowercased.contains("河") { emojis.append("🌊") }
        if lowercased.contains("火") { emojis.append("🔥") }
        if lowercased.contains("风") { emojis.append("💨") }
        if lowercased.contains("土") || lowercased.contains("山") { emojis.append("🏔️") }
        
        // 自然相关
        if lowercased.contains("树") || lowercased.contains("森林") { emojis.append("🌲") }
        if lowercased.contains("花") { emojis.append("🌸") }
        if lowercased.contains("天空") || lowercased.contains("云") { emojis.append("☁️") }
        if lowercased.contains("星星") || lowercased.contains("星") { emojis.append("⭐") }
        
        // 动作相关
        if lowercased.contains("飞") { emojis.append("✈️") }
        if lowercased.contains("跑") { emojis.append("🏃") }
        if lowercased.contains("跳") { emojis.append("🦘") }
        
        return Array(emojis.prefix(5))
    }
    
    /// 诗意化文本
    private func makePoetic(_ text: String) -> String {
        // 简单的诗意化处理
        var result = text
        
        // 添加修辞
        if !result.hasPrefix("在") && !result.hasPrefix("我") {
            result = "在那" + result
        }
        
        // 添加结尾
        if !result.hasSuffix("。") && !result.hasSuffix("…") {
            result += "……"
        }
        
        return result
    }
    
    /// 精简文本
    private func makeConcise(_ text: String) -> String {
        // 截取前 100 个字符
        if text.count > 100 {
            return String(text.prefix(100)) + "..."
        }
        return text
    }
    
    /// 生动化文本
    private func makeVivid(_ text: String) -> String {
        // 添加感官描述
        var result = text
        
        // 添加视觉描述
        if !result.contains("看见") && !result.contains("看到") {
            result = "仿佛看见，" + result
        }
        
        return result
    }
    
    // MARK: - 智能背景匹配
    
    /// 根据梦境内容智能匹配背景风格
    func matchStyle(for dream: Dream) async -> ArtCardStyle {
        // 基于情绪匹配
        if let primaryEmotion = dream.emotions.first {
            let style = ArtCardStyle.allCases.first {
                $0.recommendedEmotions.contains(primaryEmotion)
            }
            if let style = style {
                return style
            }
        }
        
        // 基于标签匹配
        for tag in dream.tags {
            let lowercased = tag.lowercased()
            
            if lowercased.contains("星空") || lowercased.contains("宇宙") {
                return .starry
            }
            if lowercased.contains("海洋") || lowercased.contains("水") {
                return .ocean
            }
            if lowercased.contains("森林") || lowercased.contains("自然") {
                return .forest
            }
            if lowercased.contains("樱花") || lowercased.contains("花") {
                return .sakura
            }
        }
        
        // 基于内容匹配
        let content = dream.content.lowercased()
        
        if content.contains("飞") || content.contains("天空") {
            return .sunrise
        }
        if content.contains("神秘") || content.contains("未知") {
            return .starry
        }
        if content.contains("平静") || content.contains("安静") {
            return .ocean
        }
        
        // 默认返回梦幻风格
        return .dreamy
    }
    
    // MARK: - 辅助方法
    
    /// 从风格创建模板
    private func createTemplateFromStyle(_ styleName: String) -> ArtCardTemplate {
        let style = ArtCardStyle(rawValue: styleName) ?? .starry
        
        return ArtCardTemplate(
            name: style.displayName + "模板",
            description: style.description,
            style: styleName,
            background: BackgroundConfig(
                colors: style.primaryColors.map { "\($0)" },
                gradientType: "linear",
                gradientAngle: 45,
                opacity: 0.9,
                blurRadius: 0,
                noiseIntensity: 0
            ),
            textConfig: .default,
            decorations: style.defaultDecorations.map {
                DecorationConfig(type: $0.rawValue, count: 20, size: 8, opacity: 0.8, animation: nil)
            },
            isPreset: true,
            category: .artistic
        )
    }
    
    /// 获取梦境
    private func getDream(id: UUID) async throws -> Dream? {
        let descriptor = FetchDescriptor<Dream>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - 统计
    
    /// 获取统计信息
    func getStats() async throws -> ArtCardStats {
        let allTemplates = try await getAllTemplates()
        
        var cardsByStyle: [String: Int] = [:]
        var cardsByPlatform: [String: Int] = [:]
        
        for template in allTemplates {
            cardsByStyle[template.style, default: 0] += 1
            if let platform = template.platform {
                cardsByPlatform[platform, default: 0] += 1
            }
        }
        
        let favoriteTemplates = allTemplates.filter { $0.isFavorite }.map { $0.id }
        let mostUsedStyle = cardsByStyle.max(by: { $0.value < $1.value })?.key
        let mostUsedPlatform = cardsByPlatform.max(by: { $0.value < $1.value })?.key
        
        return ArtCardStats(
            totalCards: allTemplates.count,
            cardsByStyle: cardsByStyle,
            cardsByPlatform: cardsByPlatform,
            favoriteTemplates: favoriteTemplates,
            recentCards: [],
            totalShares: 0,
            mostUsedStyle: mostUsedStyle,
            mostUsedPlatform: mostUsedPlatform
        )
    }
}
