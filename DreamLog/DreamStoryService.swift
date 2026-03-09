//
//  DreamStoryService.swift
//  DreamLog
//
//  梦境故事生成服务 - 将简短梦境扩展为完整故事
//  Phase 8 - AI 增强功能
//

import Foundation
import NaturalLanguage

// MARK: - 梦境故事模型

/// 梦境故事
struct DreamStory: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dreamId: UUID
    var title: String
    var content: String
    var narrativeStyle: NarrativeStyle
    var wordCount: Int
    var chapters: [StoryChapter]
    var themes: [String]
    var mood: String
    var createdAt: Date
    var isFavorite: Bool = false
    
    /// 叙事风格
    enum NarrativeStyle: String, Codable, CaseIterable, Identifiable {
        case firstPerson = "第一人称"
        case thirdPerson = "第三人称"
        case diary = "日记体"
        case fairyTale = "童话风格"
        case suspense = "悬疑风格"
        case poetic = "诗歌体"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .firstPerson: return "以"我"的视角讲述，身临其境"
            case .thirdPerson: return "客观叙述，如旁观者视角"
            case .diary: return "私人日记格式，情感丰富"
            case .fairyTale: return "童话般梦幻，充满魔法与奇迹"
            case .suspense: return "悬疑紧张，层层递进"
            case .poetic: return "诗意盎然，韵律优美"
            }
        }
        
        var openingPhrase: String {
            switch self {
            case .firstPerson: return "我发现自己置身于"
            case .thirdPerson: return "在梦境的深处，"
            case .diary: return "亲爱的日记，"
            case .fairyTale: return "很久很久以前，在一个遥远的梦境世界里，"
            case .suspense: return "一切开始得如此突然，"
            case .poetic: return "在夜的帷幕下，"
            }
        }
        
        var icon: String {
            switch self {
            case .firstPerson: return "person.fill"
            case .thirdPerson: return "eye.fill"
            case .diary: return "book.fill"
            case .fairyTale: return "wand.and.stars"
            case .suspense: return "magnifyingglass"
            case .poetic: return "quote.opening"
            }
        }
    }
    
    /// 故事章节
    struct StoryChapter: Identifiable, Codable {
        var id: UUID = UUID()
        var title: String
        var content: String
        var wordCount: Int
        var mood: String
    }
}

// MARK: - 梦境故事生成服务

@MainActor
class DreamStoryService: ObservableObject {
    static let shared = DreamStoryService()
    
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0.0
    @Published var currentStory: DreamStory?
    @Published var errorMessage: String?
    
    // 本地存储的故事
    @Published var stories: [DreamStory] = []
    
    // 生成历史记录
    @Published var generationHistory: [GenerationRecord] = []
    
    private let fileManager = FileManager.default
    private var storiesDirectory: URL {
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("DreamStories", isDirectory: true)
    }
    
    private init() {
        loadStories()
        loadGenerationHistory()
    }
    
    // MARK: - 故事生成
    
    /// 为梦境生成完整故事
    func generateStory(for dream: Dream, style: DreamStory.NarrativeStyle) async {
        let startTime = Date()
        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil
        
        defer {
            isGenerating = false
        }
        
        print("📖 开始生成梦境故事 - 风格：\(style.rawValue)")
        
        do {
            // 步骤 1: 分析梦境内容
            generationProgress = 0.1
            let analysis = analyzeDreamContent(dream)
            print("📊 梦境分析完成：\(analysis.themes.count) 个主题，情绪：\(analysis.mood)")
            
            // 步骤 2: 扩展故事情节
            generationProgress = 0.3
            let plotElements = expandPlotElements(dream: dream, analysis: analysis)
            print("📝 情节扩展完成：\(plotElements.count) 个情节元素")
            
            // 步骤 3: 生成故事结构
            generationProgress = 0.5
            let chapters = generateStoryStructure(dream: dream, analysis: analysis, plotElements: plotElements, style: style)
            print("📚 故事结构完成：\(chapters.count) 个章节")
            
            // 步骤 4: 编写完整故事
            generationProgress = 0.7
            let fullContent = assembleFullStory(chapters: chapters, style: style)
            
            // 步骤 5: 创建故事对象
            generationProgress = 0.9
            let totalWordCount = fullContent.count / 2 // 估算中文字数
            
            let story = DreamStory(
                dreamId: dream.id,
                title: generateStoryTitle(dream: dream, style: style),
                content: fullContent,
                narrativeStyle: style,
                wordCount: totalWordCount,
                chapters: chapters,
                themes: analysis.themes,
                mood: analysis.mood,
                createdAt: Date()
            )
            
            currentStory = story
            stories.insert(story, at: 0)
            saveStories()
            
            generationProgress = 1.0
            
            // 记录生成历史
            let duration = Date().timeIntervalSince(startTime)
            recordGeneration(dream: dream, style: style, wordCount: totalWordCount, duration: duration, isSuccess: true)
            
            print("✅ 故事生成完成 - 总字数：\(totalWordCount) - 耗时：\(String(format: "%.2f", duration))秒")
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            errorMessage = error.localizedDescription
            recordGeneration(dream: dream, style: style, wordCount: 0, duration: duration, isSuccess: false, errorMessage: error.localizedDescription)
            print("❌ 故事生成失败：\(error)")
        }
    }
    
    // MARK: - 梦境分析
    
    /// 分析梦境内容
    private func analyzeDreamContent(_ dream: Dream) -> DreamAnalysis {
        let content = dream.content.lowercased()
        
        // 提取主题
        var themes: [String] = []
        let themeKeywords: [String: [String]] = [
            "冒险": ["冒险", "探索", "旅程", "发现", "未知"],
            "爱情": ["爱", "喜欢", "心动", "浪漫", "温柔"],
            "恐惧": ["害怕", "恐惧", "紧张", "逃跑", "追逐"],
            "自由": ["飞翔", "自由", "解放", "无拘无束", "翱翔"],
            "失落": ["失去", "寻找", "迷茫", "孤独", "分离"],
            "成长": ["成长", "学习", "变化", "蜕变", "领悟"],
            "神秘": ["神秘", "魔法", "超自然", "奇迹", "不可思议"],
            "怀旧": ["回忆", "过去", "童年", "故乡", "老朋友"]
        ]
        
        for (theme, keywords) in themeKeywords {
            for keyword in keywords {
                if content.contains(keyword) {
                    if !themes.contains(theme) {
                        themes.append(theme)
                    }
                    break
                }
            }
        }
        
        // 如果没找到主题，使用默认
        if themes.isEmpty {
            themes = ["梦境", "潜意识"]
        }
        
        // 分析情绪
        let mood = analyzeMood(from: dream)
        
        return DreamAnalysis(themes: themes, mood: mood)
    }
    
    /// 分析梦境情绪
    private func analyzeMood(from dream: Dream) -> String {
        if !dream.emotions.isEmpty {
            return dream.emotions.joined(separator: ", ")
        }
        
        // 根据内容推断情绪
        let content = dream.content.lowercased()
        if content.contains("快乐") || content.contains("开心") || content.contains("兴奋") {
            return "愉悦"
        } else if content.contains("害怕") || content.contains("恐惧") {
            return "紧张"
        } else if content.contains("悲伤") || content.contains("难过") {
            return "忧伤"
        } else if content.contains("平静") || content.contains("安宁") {
            return "平静"
        }
        
        return "神秘"
    }
    
    // MARK: - 情节扩展
    
    /// 扩展情节元素
    private func expandPlotElements(dream: Dream, analysis: DreamAnalysis) -> [PlotElement] {
        var elements: [PlotElement] = []
        
        // 开场
        elements.append(PlotElement(
            type: .opening,
            description: generateOpening(dream: dream, analysis: analysis),
            details: extractSensoryDetails(from: dream.content)
        ))
        
        // 发展
        elements.append(PlotElement(
            type: .development,
            description: generateDevelopment(dream: dream, analysis: analysis),
            details: extractCharacterInteractions(from: dream.content)
        ))
        
        // 高潮
        elements.append(PlotElement(
            type: .climax,
            description: generateClimax(dream: dream, analysis: analysis),
            details: extractEmotionalPeak(from: dream.content)
        ))
        
        // 结局
        elements.append(PlotElement(
            type: .resolution,
            description: generateResolution(dream: dream, analysis: analysis),
            details: extractReflection(from: dream.content)
        ))
        
        return elements
    }
    
    /// 生成开场
    private func generateOpening(dream: Dream, analysis: DreamAnalysis) -> String {
        let timePhrases = [
            "夜幕降临，",
            "在朦胧的睡意中，",
            "当钟声敲响午夜，",
            "星光闪烁的夜晚，",
            "月光如水的时刻，"
        ]
        
        let settingPhrases = [
            "我来到了一个陌生的地方",
            "周围的一切都变得模糊而神秘",
            "梦境的帷幕缓缓拉开",
            "意识飘向了未知的领域",
            "现实与幻想的边界开始消融"
        ]
        
        return timePhrases.randomElement()! + settingPhrases.randomElement()!
    }
    
    /// 生成发展
    private func generateDevelopment(dream: Dream, analysis: DreamAnalysis) -> String {
        let developmentTemplates = [
            "渐渐地，我发现",
            "就在这时，",
            " unexpected 地，",
            "随着脚步的前行，",
            "眼前的景象开始变化，"
        ]
        
        return developmentTemplates.randomElement()! + " 梦境中的元素开始交织，形成一幅奇异的画面"
    }
    
    /// 生成高潮
    private func generateClimax(dream: Dream, analysis: DreamAnalysis) -> String {
        let climaxTemplates = [
            "突然，一切都达到了顶点",
            "在那一瞬间，我明白了",
            "梦境的核心终于显现",
            "所有的线索汇聚成一点",
            "真相如闪电般划过脑海"
        ]
        
        return climaxTemplates.randomElement()! + "，这是整个梦境最关键的时刻"
    }
    
    /// 生成结局
    private func generateResolution(dream: Dream, analysis: DreamAnalysis) -> String {
        let resolutionTemplates = [
            "随着黎明的到来，梦境渐渐消散",
            "我带着这份感悟，从梦中醒来",
            "梦境虽已远去，但感受依然清晰",
            "这一切，将永远留在记忆深处",
            "梦醒了，但故事还在继续"
        ]
        
        return resolutionTemplates.randomElement()!
    }
    
    // MARK: - 故事结构生成
    
    /// 生成故事章节结构
    private func generateStoryStructure(dream: Dream, analysis: DreamAnalysis, plotElements: [PlotElement], style: DreamStory.NarrativeStyle) -> [DreamStory.StoryChapter] {
        var chapters: [DreamStory.StoryChapter] = []
        
        // 第一章：序幕
        let chapter1 = DreamStory.StoryChapter(
            title: generateChapterTitle(index: 1, style: style),
            content: buildChapterContent(element: plotElements[0], style: style, dream: dream),
            wordCount: 300,
            mood: "神秘"
        )
        chapters.append(chapter1)
        
        // 第二章：探索
        let chapter2 = DreamStory.StoryChapter(
            title: generateChapterTitle(index: 2, style: style),
            content: buildChapterContent(element: plotElements[1], style: style, dream: dream),
            wordCount: 400,
            mood: analysis.mood
        )
        chapters.append(chapter2)
        
        // 第三章：转折
        let chapter3 = DreamStory.StoryChapter(
            title: generateChapterTitle(index: 3, style: style),
            content: buildChapterContent(element: plotElements[2], style: style, dream: dream),
            wordCount: 350,
            mood: "紧张"
        )
        chapters.append(chapter3)
        
        // 第四章：终章
        let chapter4 = DreamStory.StoryChapter(
            title: generateChapterTitle(index: 4, style: style),
            content: buildChapterContent(element: plotElements[3], style: style, dream: dream),
            wordCount: 250,
            mood: "平静"
        )
        chapters.append(chapter4)
        
        return chapters
    }
    
    /// 生成章节标题
    private func generateChapterTitle(index: Int, style: DreamStory.NarrativeStyle) -> String {
        let titles: [[String]] = [
            ["序幕", "初探", "转折", "终章"],
            ["开始", "旅程", "发现", "归来"],
            ["入梦", "漫游", "觉醒", "回味"],
            ["第一章", "第二章", "第三章", "第四章"]
        ]
        
        let titleSet = titles.randomElement()!
        return titleSet[index - 1]
    }
    
    /// 构建章节内容
    private func buildChapterContent(element: PlotElement, style: DreamStory.NarrativeStyle, dream: Dream) -> String {
        var content = ""
        
        // 根据叙事风格调整开头
        content += style.openingPhrase + "\n\n"
        
        // 添加情节内容
        content += element.description + "\n\n"
        
        // 添加感官细节
        if !element.details.isEmpty {
            content += "周围充满了" + element.details.joined(separator: "、") + "的气息\n\n"
        }
        
        // 添加梦境原始内容
        if !dream.content.isEmpty {
            content += "我记得：\"\(dream.content)\"\n\n"
        }
        
        // 添加情绪描述
        if !dream.emotions.isEmpty {
            content += "心中涌动着\(dream.emotions.joined(separator: "与"))的情感"
        }
        
        return content
    }
    
    /// 组装完整故事
    private func assembleFullStory(chapters: [DreamStory.StoryChapter], style: DreamStory.NarrativeStyle) -> String {
        var fullStory = ""
        
        // 添加标题
        fullStory += "# 梦境故事\n\n"
        
        // 添加风格说明
        fullStory += "叙事风格：\(style.rawValue)\n\n"
        fullStory += "---\n\n"
        
        // 添加各章节
        for chapter in chapters {
            fullStory += "## \(chapter.title)\n\n"
            fullStory += chapter.content + "\n\n"
            fullStory += "---\n\n"
        }
        
        // 添加尾声
        fullStory += "## 尾声\n\n"
        fullStory += "这个梦境如同一面镜子，映照出内心深处的想法和情感。"
        fullStory += "无论它是快乐的、恐惧的，还是神秘的，都是我们潜意识的一部分，"
        fullStory += "值得我们去理解和珍惜。\n\n"
        fullStory += "*—— DreamLog 梦境故事生成*\n"
        
        return fullStory
    }
    
    // MARK: - 标题生成
    
    /// 生成故事标题
    private func generateStoryTitle(dream: Dream, style: DreamStory.NarrativeStyle) -> String {
        let baseTitles = [
            "梦境奇缘",
            "深夜漫游",
            "潜意识之旅",
            "梦境探秘",
            "夜的启示",
            "梦中的风景",
            "心灵奇境",
            "梦境手记"
        ]
        
        let baseTitle = baseTitles.randomElement()!
        
        // 根据梦境情绪添加副标题
        if !dream.emotions.isEmpty {
            let emotion = dream.emotions.first ?? ""
            return "\(baseTitle)：\(emotion)之梦"
        }
        
        return baseTitle
    }
    
    // MARK: - 辅助方法
    
    /// 提取感官细节
    private func extractSensoryDetails(from content: String) -> [String] {
        var details: [String] = []
        
        let sensoryKeywords: [String: [String]] = [
            "视觉": ["看见", "看到", "眼前", "景象", "颜色", "光影"],
            "听觉": ["听到", "声音", "响起", "寂静", "音乐"],
            "触觉": ["感觉", "触摸", "温暖", "寒冷", "柔软"],
            "嗅觉": ["闻到", "气息", "香味", "味道"],
            "味觉": ["尝到", "味道", "甜美", "苦涩"]
        ]
        
        for (sense, keywords) in sensoryKeywords {
            for keyword in keywords {
                if content.contains(keyword) {
                    details.append("\(sense)细节")
                    break
                }
            }
        }
        
        return details.isEmpty ? ["神秘氛围"] : details
    }
    
    /// 提取角色互动
    private func extractCharacterInteractions(from content: String) -> [String] {
        let interactionKeywords = ["遇见", "对话", "一起", "跟随", "帮助", "告别"]
        
        for keyword in interactionKeywords {
            if content.contains(keyword) {
                return ["人物互动", "情感交流"]
            }
        }
        
        return ["独自探索"]
    }
    
    /// 提取情感高峰
    private func extractEmotionalPeak(from content: String) -> [String] {
        let peakKeywords = ["突然", "瞬间", "终于", "此刻", "那一刻"]
        
        for keyword in peakKeywords {
            if content.contains(keyword) {
                return ["情感爆发", "关键时刻"]
            }
        }
        
        return ["平静流淌"]
    }
    
    /// 提取反思
    private func extractReflection(from content: String) -> [String] {
        let reflectionKeywords = ["明白", "理解", "感悟", "思考", "回忆"]
        
        for keyword in reflectionKeywords {
            if content.contains(keyword) {
                return ["深度反思", "内心感悟"]
            }
        }
        
        return ["余韵悠长"]
    }
    
    // MARK: - 数据持久化
    
    private func saveStories() {
        let storiesFile = storiesDirectory.appendingPathComponent("dream_stories.json")
        
        do {
            try fileManager.createDirectory(at: storiesDirectory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(stories)
            try data.write(to: storiesFile)
        } catch {
            print("❌ 保存故事失败：\(error)")
        }
    }
    
    private func loadStories() {
        let storiesFile = storiesDirectory.appendingPathComponent("dream_stories.json")
        
        guard let data = try? Data(contentsOf: storiesFile) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            stories = try decoder.decode([DreamStory].self, from: data)
        } catch {
            print("❌ 加载故事失败：\(error)")
        }
    }
    
    // MARK: - 导出功能
    
    /// 导出故事为纯文本
    func exportStoryAsText(_ story: DreamStory) -> String {
        var text = ""
        
        text += "《\(story.title)》\n\n"
        text += "叙事风格：\(story.narrativeStyle.rawValue)\n"
        text += "字数：\(story.wordCount)\n"
        text += "主题：\(story.themes.joined(separator: ", "))\n"
        text += "情绪：\(story.mood)\n"
        text += "创作时间：\(formatDate(story.createdAt))\n"
        text += "\n---\n\n"
        
        for chapter in story.chapters {
            text += "\(chapter.title)\n\n"
            text += chapter.content + "\n\n"
        }
        
        text += "\n—— 由 DreamLog 生成"
        
        return text
    }
    
    /// 导出故事为 Markdown
    func exportStoryAsMarkdown(_ story: DreamStory) -> String {
        var md = "# \(story.title)\n\n"
        
        md += "**叙事风格**: \(story.narrativeStyle.rawValue)  \n"
        md += "**字数**: \(story.wordCount)  \n"
        md += "**主题**: \(story.themes.joined(separator: ", "))  \n"
        md += "**情绪**: \(story.mood)  \n"
        md += "**创作时间**: \(formatDate(story.createdAt))\n\n"
        md += "---\n\n"
        
        for chapter in story.chapters {
            md += "## \(chapter.title)\n\n"
            md += chapter.content + "\n\n"
        }
        
        md += "\n---\n\n*由 DreamLog 梦境故事生成器创建*"
        
        return md
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy 年 MM 月 dd 日 HH:mm"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

// MARK: - 导出功能增强

/// 导出故事为 PDF (生成 PDF 数据)
func exportStoryAsPDF(_ story: DreamStory) -> Data? {
    // 注意：实际 PDF 生成需要在 iOS 中使用 UIGraphicsPDFRenderer
    // 这里提供文本内容，实际渲染在视图中完成
    let content = exportStoryAsMarkdown(story)
    return content.data(using: .utf8)
}

/// 导出故事为 EPUB (简化版本)
func exportStoryAsEPUB(_ story: DreamStory) -> String {
    // EPUB 基本结构
    let epubContent = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>\(story.title)</title>
        <meta charset="utf-8"/>
    </head>
    <body>
        <h1>\(story.title)</h1>
        <p><strong>叙事风格</strong>: \(story.narrativeStyle.rawValue)</p>
        <p><strong>字数</strong>: \(story.wordCount)</p>
        <p><strong>主题</strong>: \(story.themes.joined(separator: ", "))</p>
        <hr/>
    \(story.chapters.map { chapter in
        """
        <h2>\(chapter.title)</h2>
        <p>\(chapter.content.replacingOccurrences(of: "\n", with: "<br/>"))</p>
        """
    }.joined(separator: "\n"))
    </body>
    </html>
    """
    return epubContent
}

/// 保存导出文件
func saveExportedFile(content: Data, fileName: String, directory: String = "Exports") -> URL? {
    let exportsDirectory = storiesDirectory.appendingPathComponent(directory, isDirectory: true)
    
    do {
        try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        let fileURL = exportsDirectory.appendingPathComponent(fileName)
        try content.write(to: fileURL)
        print("✅ 文件已保存：\(fileURL.path)")
        return fileURL
    } catch {
        print("❌ 保存文件失败：\(error)")
        return nil
    }
}

/// 保存导出文件 (文本)
func saveExportedFile(content: String, fileName: String, directory: String = "Exports") -> URL? {
    guard let data = content.data(using: .utf8) else {
        print("❌ 文本编码失败")
        return nil
    }
    return saveExportedFile(content: data, fileName: fileName, directory: directory)
}

// MARK: - 生成历史

/// 生成历史记录
struct GenerationRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var dreamId: UUID
    var dreamTitle: String
    var style: DreamStory.NarrativeStyle
    var wordCount: Int
    var createdAt: Date
    var duration: TimeInterval // 生成耗时 (秒)
    var isSuccess: Bool
    var errorMessage: String?
}

/// 记录生成历史
func recordGeneration(dream: Dream, style: DreamStory.NarrativeStyle, wordCount: Int, duration: TimeInterval, isSuccess: Bool, errorMessage: String? = nil) {
    let record = GenerationRecord(
        dreamId: dream.id,
        dreamTitle: dream.title.isEmpty ? "无题梦境" : dream.title,
        style: style,
        wordCount: wordCount,
        createdAt: Date(),
        duration: duration,
        isSuccess: isSuccess,
        errorMessage: errorMessage
    )
    
    generationHistory.insert(record, at: 0)
    
    // 保留最近 100 条记录
    if generationHistory.count > 100 {
        generationHistory.removeLast(generationHistory.count - 100)
    }
    
    saveGenerationHistory()
}

/// 保存生成历史
private func saveGenerationHistory() {
    let historyFile = storiesDirectory.appendingPathComponent("generation_history.json")
    
    do {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(generationHistory)
        try data.write(to: historyFile)
    } catch {
        print("❌ 保存生成历史失败：\(error)")
    }
}

/// 加载生成历史
private func loadGenerationHistory() {
    let historyFile = storiesDirectory.appendingPathComponent("generation_history.json")
    
    guard let data = try? Data(contentsOf: historyFile) else {
        return
    }
    
    do {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        generationHistory = try decoder.decode([GenerationRecord].self, from: data)
    } catch {
        print("❌ 加载生成历史失败：\(error)")
    }
}

/// 清除生成历史
func clearGenerationHistory() {
    generationHistory.removeAll()
    saveGenerationHistory()
}

/// 获取生成统计
func getGenerationStatistics() -> GenerationStatistics {
    let totalGenerations = generationHistory.count
    let successfulGenerations = generationHistory.filter { $0.isSuccess }.count
    let totalWords = generationHistory.reduce(0) { $0 + $1.wordCount }
    let avgDuration = generationHistory.isEmpty ? 0 : generationHistory.reduce(0) { $0 + $1.duration } / Double(totalGenerations)
    
    // 按风格统计
    var styleCounts: [DreamStory.NarrativeStyle: Int] = [:]
    for record in generationHistory {
        styleCounts[record.style, default: 0] += 1
    }
    
    return GenerationStatistics(
        totalGenerations: totalGenerations,
        successfulGenerations: successfulGenerations,
        totalWords: totalWords,
        averageDuration: avgDuration,
        styleCounts: styleCounts
    )
}

/// 生成统计
struct GenerationStatistics {
    var totalGenerations: Int
    var successfulGenerations: Int
    var totalWords: Int
    var averageDuration: TimeInterval
    var styleCounts: [DreamStory.NarrativeStyle: Int]
    
    var successRate: Double {
        guard totalGenerations > 0 else { return 0 }
        return Double(successfulGenerations) / Double(totalGenerations) * 100
    }
}

// MARK: - 辅助模型

/// 梦境分析结果
struct DreamAnalysis {
    var themes: [String]
    var mood: String
}

/// 情节元素
struct PlotElement {
    enum PlotType {
        case opening
        case development
        case climax
        case resolution
    }
    
    var type: PlotType
    var description: String
    var details: [String]
}
