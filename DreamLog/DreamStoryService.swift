//
//  DreamStoryService.swift
//  DreamLog
//
//  Dream Story Generation Service - Phase 14
//  Transforms dreams into engaging narrative stories with AI
//

import Foundation
import NaturalLanguage

/// Dream Story Generation Service
/// Converts dream records into polished narrative stories
@MainActor
class DreamStoryService: ObservableObject {
    
    static let shared = DreamStoryService()
    
    @Published var stories: [GeneratedStory] = []
    
    private init() {
        loadStories()
    }
    
    private func loadStories() {
        stories = getAllStories()
    }
    
    // MARK: - Story Templates
    
    enum StoryGenre: String, CaseIterable, Identifiable {
        case fantasy = "奇幻冒险"
        case mystery = "悬疑解谜"
        case sciFi = "科幻未来"
        case horror = "惊悚恐怖"
        case romance = "浪漫情感"
        case comedy = "幽默喜剧"
        case philosophical = "哲学思考"
        case poetic = "诗意散文"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .fantasy: return "🧙‍♂️"
            case .mystery: return "🔍"
            case .sciFi: return "🚀"
            case .horror: return "👻"
            case .romance: return "💕"
            case .comedy: return "😂"
            case .philosophical: return "🤔"
            case .poetic: return "📜"
            }
        }
        
        var description: String {
            switch self {
            case .fantasy: return "将梦境转化为一场奇幻冒险旅程"
            case .mystery: return "探索梦境中的谜团与秘密"
            case .sciFi: return "赋予梦境未来科技感"
            case .horror: return "营造紧张恐怖的氛围"
            case .romance: return "强调梦境中的情感连接"
            case .comedy: return "发掘梦境中的幽默元素"
            case .philosophical: return "深入探讨梦境的哲学意义"
            case .poetic: return "用诗意的语言重新诠释梦境"
            }
        }
    }
    
    // MARK: - Story Structure
    
    struct StorySection {
        let title: String
        let content: String
        let mood: String
        let order: Int
    }
    
    struct GeneratedStory {
        let id: UUID
        let dreamId: UUID
        let title: String
        let genre: StoryGenre
        let sections: [StorySection]
        let fullStory: String
        let wordCount: Int
        let readingTime: Int // minutes
        let coverImagePrompt: String
        let createdAt: Date
        let tags: [String]
        let mood: String
    }
    
    // MARK: - Story Generation
    
    /// Generate a story from a dream
    func generateStory(from dream: Dream, genre: StoryGenre) async throws -> GeneratedStory {
        let sections = await createStorySections(from: dream, genre: genre)
        let fullStory = combineSections(sections)
        let title = generateTitle(from: dream, genre: genre)
        
        return GeneratedStory(
            id: UUID(),
            dreamId: dream.id,
            title: title,
            genre: genre,
            sections: sections,
            fullStory: fullStory,
            wordCount: fullStory.count,
            readingTime: max(1, fullStory.count / 300), // ~300 chars per minute
            coverImagePrompt: generateCoverPrompt(from: dream, genre: genre),
            createdAt: Date(),
            tags: extractStoryTags(from: dream, genre: genre),
            mood: determineStoryMood(from: dream, genre: genre)
        )
    }
    
    /// Create story sections from dream content
    private func createStorySections(from dream: Dream, genre: StoryGenre) async -> [StorySection] {
        var sections: [StorySection] = []
        
        // Section 1: Opening
        let opening = createOpeningSection(from: dream, genre: genre)
        sections.append(opening)
        
        // Section 2: Development
        if let development = createDevelopmentSection(from: dream, genre: genre) {
            sections.append(development)
        }
        
        // Section 3: Climax
        if let climax = createClimaxSection(from: dream, genre: genre) {
            sections.append(climax)
        }
        
        // Section 4: Resolution
        let resolution = createResolutionSection(from: dream, genre: genre)
        sections.append(resolution)
        
        // Section 5: Reflection (optional based on genre)
        if shouldIncludeReflection(genre: genre),
           let reflection = createReflectionSection(from: dream, genre: genre) {
            sections.append(reflection)
        }
        
        return sections
    }
    
    private func createOpeningSection(from dream: Dream, genre: StoryGenre) -> StorySection {
        let openingTemplates = [
            "在那个\(describeTime(dream.createdAt))，\(dream.title)开始了...",
            "一切始于\(dream.title)。当\(describeEmotion(dream.emotions))的情绪笼罩着我...",
            "记忆中的那个夜晚，\(dream.content.prefix(50))...",
            "如果梦境有起点，那一定是从\(extractKeyElement(from: dream))开始的..."
        ]
        
        let content = applyGenreStyle(to: openingTemplates.randomElement() ?? "", genre: genre, dream: dream)
        
        return StorySection(
            title: "序章：\(genre.icon) \(generateSectionTitle(for: "opening", genre: genre))",
            content: content,
            mood: "引入",
            order: 1
        )
    }
    
    private func createDevelopmentSection(from dream: Dream, genre: StoryGenre) -> StorySection? {
        guard dream.content.count > 100 else { return nil }
        
        let keyElements = extractKeyElements(from: dream)
        let content = """
        随着梦境的深入，\(keyElements.joined(separator: "、")) 开始交织在一起。
        
        \(expandDreamContent(from: dream.content, genre: genre))
        
        每一个细节都在诉说着不同的故事，每一种情绪都在空气中弥漫。
        """
        
        return StorySection(
            title: "第一章：\(genre.icon) \(generateSectionTitle(for: "development", genre: genre))",
            content: content,
            mood: "发展",
            order: 2
        )
    }
    
    private func createClimaxSection(from dream: Dream, genre: StoryGenre) -> StorySection? {
        guard dream.intensity >= 3 else { return nil }
        
        let climaxContent = """
        就在那一刻，一切都达到了顶点。
        
        \(describeClimaxMoment(from: dream, genre: genre))
        
        时间仿佛静止了，只剩下\(extractMostVividElement(from: dream))在脑海中闪烁。
        """
        
        return StorySection(
            title: "高潮：\(genre.icon) \(generateSectionTitle(for: "climax", genre: genre))",
            content: climaxContent,
            mood: "高潮",
            order: 3
        )
    }
    
    private func createResolutionSection(from dream: Dream, genre: StoryGenre) -> StorySection {
        let resolutionTemplates = [
            "当醒来时，\(dream.title)的余韵仍在心头回荡...",
            "梦醒了，但\(extractKeyTheme(from: dream))却深深地印在了记忆里...",
            "睁开眼睛的那一刻，我明白了一些事情：\(generateInsight(from: dream, genre: genre))...",
            "梦境消散在晨光中，留下的是\(describeAftermath(from: dream, genre: genre))..."
        ]
        
        let content = applyGenreStyle(to: resolutionTemplates.randomElement() ?? "", genre: genre, dream: dream)
        
        return StorySection(
            title: "终章：\(genre.icon) \(generateSectionTitle(for: "resolution", genre: genre))",
            content: content,
            mood: "结局",
            order: 4
        )
    }
    
    private func createReflectionSection(from dream: Dream, genre: StoryGenre) -> StorySection? {
        guard genre == .philosophical || genre == .poetic else { return nil }
        
        let reflection = """
        这个梦，或许在告诉我一些什么。
        
        \(generatePhilosophicalReflection(from: dream, genre: genre))
        
        梦境如镜，映照的是内心深处的真相。
        """
        
        return StorySection(
            title: "后记：\(genre.icon) \(generateSectionTitle(for: "reflection", genre: genre))",
            content: reflection,
            mood: "反思",
            order: 5
        )
    }
    
    // MARK: - Helper Methods
    
    private func combineSections(_ sections: [StorySection]) -> String {
        return sections
            .sorted { $0.order < $1.order }
            .map { "## \($0.title)\n\n\($0.content)" }
            .joined(separator: "\n\n")
    }
    
    private func generateTitle(from dream: Dream, genre: StoryGenre) -> String {
        let baseTitle = dream.title.isEmpty ? "梦境" : dream.title
        
        let genrePrefixes: [StoryGenre: [String]] = [
            .fantasy: ["奇幻之旅：", "魔法梦境：", "冒险启程："],
            .mystery: ["谜案：", "未解之谜：", "秘密："],
            .sciFi: ["未来记录：", "赛博梦境：", "科技幻象："],
            .horror: ["恐怖之夜：", "噩梦：", "阴影："],
            .romance: ["心动时刻：", "情缘：", "梦中相遇："],
            .comedy: ["搞笑奇遇：", "欢乐梦境：", "笑料："],
            .philosophical: ["思考：", "哲思：", "启示："],
            .poetic: ["诗篇：", "吟唱：", "梦之韵："]
        ]
        
        let prefixes = genrePrefixes[genre] ?? [""]
        return (prefixes.randomElement() ?? "") + baseTitle
    }
    
    private func applyGenreStyle(to content: String, genre: StoryGenre, dream: Dream) -> String {
        var styledContent = content
        
        switch genre {
        case .fantasy:
            styledContent += " 仿佛置身于一个充满魔法与奇迹的世界。"
        case .mystery:
            styledContent += " 隐藏着不为人知的秘密，等待被揭开。"
        case .sciFi:
            styledContent += " 科技感十足，如同来自未来的记忆。"
        case .horror:
            styledContent += " 令人不寒而栗的氛围笼罩着一切。"
        case .romance:
            styledContent += " 心中涌动着难以言喻的情感。"
        case .comedy:
            styledContent += " 让人忍俊不禁，充满欢乐。"
        case .philosophical:
            styledContent += " 引发对存在与意义的深层思考。"
        case .poetic:
            styledContent += " 如诗如画，美轮美奂。"
        }
        
        return styledContent
    }
    
    private func expandDreamContent(from content: String, genre: StoryGenre) -> String {
        // Expand and enrich the original dream content with genre-specific details
        let expansions: [StoryGenre: [String]] = [
            .fantasy: ["光芒闪烁", "魔法涌动", "神秘力量", "古老传说"],
            .mystery: ["线索浮现", "真相隐约", "谜团重重", "秘密深藏"],
            .sciFi: ["数据流动", "机械运转", "未来科技", "虚拟现实"],
            .horror: ["阴影逼近", "寒意袭来", "不安蔓延", "恐惧滋生"],
            .romance: ["心跳加速", "温柔触碰", "深情凝望", "情感交融"],
            .comedy: ["滑稽场面", "意外转折", "欢乐气氛", "幽默对话"],
            .philosophical: ["深度思考", "意义探寻", "存在追问", "智慧启示"],
            .poetic: ["优美意象", "动人画面", "细腻情感", "诗意表达"]
        ]
        
        let genreWords = expansions[genre] ?? []
        let randomWord = genreWords.randomElement() ?? ""
        
        return "\(content)\n\n\(randomWord)的感觉在梦境中流转，每一个细节都被赋予了特殊的意义。"
    }
    
    private func describeClimaxMoment(from dream: Dream, genre: StoryGenre) -> String {
        let climaxDescriptions: [StoryGenre: [String]] = [
            .fantasy: ["魔法能量爆发", "命运转折点", "冒险达到巅峰", "奇迹出现"],
            .mystery: ["真相大白", "关键线索浮现", "谜底揭晓", "阴谋暴露"],
            .sciFi: ["科技力量释放", "虚拟现实崩溃", "未来显现", "数据洪流"],
            .horror: ["恐怖真相揭露", "最大恐惧降临", "绝望时刻", "生死一线"],
            .romance: ["情感爆发", "真心表白", "心灵相通", "爱的宣言"],
            .comedy: ["最大笑点", "意外反转", "欢乐高潮", "滑稽巅峰"],
            .philosophical: ["顿悟时刻", "真理显现", "智慧开启", "思想升华"],
            .poetic: ["情感巅峰", "意象交汇", "美感极致", "诗意爆发"]
        ]
        
        let descriptions = climaxDescriptions[genre] ?? ["高潮时刻"]
        return (descriptions.randomElement() ?? "高潮时刻") + "。" + (dream.aiAnalysis?.prefix(100) ?? "一切都达到了最强烈的状态")
    }
    
    private func generateInsight(from dream: Dream, genre: StoryGenre) -> String {
        let insights: [StoryGenre: [String]] = [
            .fantasy: ["每个人都有属于自己的魔法", "冒险才是生命的意义", "奇迹藏在平凡中"],
            .mystery: ["真相往往隐藏在细节里", "最大的秘密是自己", "解谜的过程就是成长"],
            .sciFi: ["科技改变不了人心", "未来由现在塑造", "虚拟与真实只在一念间"],
            .horror: ["恐惧源于未知", "最大的恐怖是内心", "面对才能超越"],
            .romance: ["爱是最强大的力量", "真心值得等待", "情感连接一切"],
            .comedy: ["快乐是一种选择", "幽默化解一切", "生活需要笑声"],
            .philosophical: ["存在即合理", "认识自己最重要", "意义由自己创造"],
            .poetic: ["美在眼中更在心中", "诗意栖居", "梦境即现实"]
        ]
        
        let genreInsights = insights[genre] ?? ["梦境教会我们一些东西"]
        return genreInsights.randomElement() ?? "梦境教会我们一些东西"
    }
    
    private func describeAftermath(from dream: Dream, genre: StoryGenre) -> String {
        let aftermaths: [StoryGenre: [String]] = [
            .fantasy: ["魔法的余温", "冒险的回忆", "奇迹的痕迹"],
            .mystery: ["未解的谜团", "探索的欲望", "真相的种子"],
            .sciFi: ["科技的回响", "未来的召唤", "数据的残影"],
            .horror: ["恐惧的阴影", "不安的余韵", "警惕的心"],
            .romance: ["心动的感觉", "温柔的回忆", "情感的纽带"],
            .comedy: ["欢乐的记忆", "笑声的回响", "轻松的心情"],
            .philosophical: ["思考的延续", "智慧的沉淀", "领悟的深刻"],
            .poetic: ["诗意的残留", "美感的延续", "情感的余韵"]
        ]
        
        let genreAftermaths = aftermaths[genre] ?? ["梦境的印记"]
        return genreAftermaths.randomElement() ?? "梦境的印记"
    }
    
    private func generatePhilosophicalReflection(from dream: Dream, genre: StoryGenre) -> String {
        let reflections = [
            "这个梦让我思考：什么是真实？什么是虚幻？",
            "或许梦境才是内心最真实的写照。",
            "每一个梦都是潜意识的低语，诉说着被忽略的真相。",
            "在梦与醒之间，存在着一个模糊的地带，那里藏着最深的自我。",
            "梦境如镜，映照出我们不愿面对的自己。"
        ]
        
        return reflections.randomElement() ?? ""
    }
    
    private func generateCoverPrompt(from dream: Dream, genre: StoryGenre) -> String {
        let genreStyles: [StoryGenre: String] = [
            .fantasy: "奇幻风格，魔法光芒，神秘氛围，梦幻色彩",
            .mystery: "悬疑风格，阴影对比，神秘感，深色调",
            .sciFi: "科幻风格，霓虹灯光，未来感，金属质感",
            .horror: "恐怖风格，黑暗氛围，紧张感，红色点缀",
            .romance: "浪漫风格，柔和光线，温暖色调，粉色系",
            .comedy: "喜剧风格，明亮色彩，欢快氛围，卡通感",
            .philosophical: "哲学风格，简约设计，深邃感，黑白灰",
            .poetic: "诗意风格，水彩效果，柔和渐变，艺术感"
        ]
        
        let keyElement = extractMostVividElement(from: dream)
        let style = genreStyles[genre] ?? "艺术风格"
        
        return "\(keyElement), \(style), 高质量，细节丰富，梦境氛围"
    }
    
    private func extractStoryTags(from dream: Dream, genre: StoryGenre) -> [String] {
        var tags = dream.tags
        tags.append(genre.rawValue)
        tags.append("梦境故事")
        
        if dream.isLucid {
            tags.append("清醒梦")
        }
        
        return Array(Set(tags))
    }
    
    private func determineStoryMood(from dream: Dream, genre: StoryGenre) -> String {
        let primaryEmotion = dream.emotions.first?.rawValue ?? "中性"
        return "\(primaryEmotion) - \(genre.rawValue)"
    }
    
    // MARK: - Extraction Helpers
    
    private func describeTime(_ date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 5 && hour < 12 { return "清晨" }
        if hour >= 12 && hour < 18 { return "午后" }
        if hour >= 18 && hour < 23 { return "夜晚" }
        return "深夜"
    }
    
    private func describeEmotion(_ emotions: [DreamEmotion]) -> String {
        guard !emotions.isEmpty else { return "复杂" }
        return emotions.map { $0.rawValue }.joined(separator: "与")
    }
    
    private func extractKeyElement(from dream: Dream) -> String {
        if let firstTag = dream.tags.first {
            return firstTag
        }
        let words = dream.content.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
        return words.first ?? "梦境"
    }
    
    private func extractKeyElements(from dream: Dream) -> [String] {
        var elements = dream.tags
        if elements.isEmpty {
            elements = ["场景", "人物", "事件"]
        }
        return Array(elements.prefix(3))
    }
    
    private func extractMostVividElement(from dream: Dream) -> String {
        if dream.clarity >= 4 {
            return extractKeyElement(from: dream)
        }
        return "模糊的影像"
    }
    
    private func extractKeyTheme(from dream: Dream) -> String {
        if let analysis = dream.aiAnalysis, analysis.count > 20 {
            return String(analysis.prefix(30)) + "..."
        }
        return "梦境的启示"
    }
    
    private func shouldIncludeReflection(genre: StoryGenre) -> Bool {
        return genre == .philosophical || genre == .poetic
    }
    
    private func generateSectionTitle(for section: String, genre: StoryGenre) -> String {
        let titles: [String: [StoryGenre: String]] = [
            "opening": [
                .fantasy: "启程", .mystery: "谜案开始", .sciFi: "未来开启",
                .horror: "恐怖降临", .romance: "相遇", .comedy: "欢乐开始",
                .philosophical: "思考起点", .poetic: "序诗"
            ],
            "development": [
                .fantasy: "冒险深入", .mystery: "线索浮现", .sciFi: "科技展开",
                .horror: "恐惧升级", .romance: "情感加深", .comedy: "笑料升级",
                .philosophical: "深度探讨", .poetic: "意境展开"
            ],
            "climax": [
                .fantasy: "魔法巅峰", .mystery: "真相揭晓", .sciFi: "力量释放",
                .horror: "恐怖顶点", .romance: "爱的宣言", .comedy: "欢乐高潮",
                .philosophical: "顿悟时刻", .poetic: "情感巅峰"
            ],
            "resolution": [
                .fantasy: "冒险结束", .mystery: "案件终结", .sciFi: "未来已来",
                .horror: "噩梦醒来", .romance: "美好结局", .comedy: "皆大欢喜",
                .philosophical: "思考总结", .poetic: "诗意收尾"
            ],
            "reflection": [
                .fantasy: "魔法启示", .mystery: "谜题反思", .sciFi: "科技思考",
                .horror: "恐惧意义", .romance: "情感感悟", .comedy: "欢乐哲理",
                .philosophical: "哲学总结", .poetic: "诗意升华"
            ]
        ]
        
        return titles[section]?[genre] ?? "章节"
    }
    
    // MARK: - Story Storage
    
    func saveStory(_ story: GeneratedStory) {
        // Save to user defaults or file system
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(story),
           let jsonString = String(data: data, encoding: .utf8) {
            UserDefaults.standard.set(jsonString, forKey: "story_\(story.id.uuidString)")
            stories.insert(story, at: 0)
        }
    }
    
    func loadStory(id: UUID) -> GeneratedStory? {
        guard let jsonString = UserDefaults.standard.string(forKey: "story_\(id.uuidString)"),
              let data = jsonString.data(using: .utf8) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(GeneratedStory.self, from: data)
    }
    
    func getAllStories() -> [GeneratedStory] {
        var stories: [GeneratedStory] = []
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.hasPrefix("story_"),
               let jsonString = UserDefaults.standard.string(forKey: key),
               let data = jsonString.data(using: .utf8),
               let story = try? decoder.decode(GeneratedStory.self, from: data) {
                stories.append(story)
            }
        }
        
        return stories.sorted { $0.createdAt > $1.createdAt }
    }
    
    func deleteStory(id: UUID) {
        UserDefaults.standard.removeObject(forKey: "story_\(id.uuidString)")
        stories.removeAll { $0.id == id }
    }
}
