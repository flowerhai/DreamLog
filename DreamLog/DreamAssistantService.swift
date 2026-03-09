//
//  DreamAssistantService.swift
//  DreamLog
//
//  梦境 AI 助手服务 - 自然语言查询梦境日记
//  Phase 13 - AI 助手
//

import Foundation
import Combine

@MainActor
class DreamAssistantService: ObservableObject {
    static let shared = DreamAssistantService()
    
    // MARK: - Published Properties
    
    @Published var messages: [ChatMessage] = []
    @Published var state: AssistantState = .idle
    @Published var suggestions: [SuggestionChip] = []
    @Published var quickActions: [QuickAction] = []
    @Published var isSpeaking: Bool = false
    @Published var isListening: Bool = false
    @Published var voiceModeEnabled: Bool = false
    @Published var predictionInsights: [DreamPrediction] = []
    
    // MARK: - Properties
    
    private var dreamStore: DreamStore { DreamStore.shared }
    private var speechService: SpeechSynthesisService { .shared }
    private var trendService: DreamTrendService { .shared }
    private var cancellables = Set<AnyCancellable>()
    private var speakQueue: [String] = []
    private var isProcessingSpeech = false
    
    // MARK: - Initialization
    
    private init() {
        setupSuggestions()
        setupQuickActions()
        loadDefaultGreeting()
    }
    
    // MARK: - Setup
    
    /// 设置建议芯片
    private func setupSuggestions() {
        suggestions = [
            SuggestionChip(title: "本周统计", query: "我这周记录了多少个梦？", icon: "chart.bar"),
            SuggestionChip(title: "常见主题", query: "我最近经常梦到什么？", icon: "tag"),
            SuggestionChip(title: "情绪分析", query: "我的梦境情绪分布是怎样的？", icon: "face.smiling"),
            SuggestionChip(title: "清醒梦", query: "我做过几次清醒梦？", icon: "sparkles"),
            SuggestionChip(title: "最佳时间", query: "我通常在什么时间记录梦境？", icon: "clock"),
            SuggestionChip(title: "连续记录", query: "我的连续记录天数是多少？", icon: "flame.fill")
        ]
    }
    
    /// 设置快速操作
    private func setupQuickActions() {
        quickActions = [
            QuickAction(title: "记录梦境", icon: "mic.fill", action: .recordDream),
            QuickAction(title: "查看统计", icon: "chart.line.uptrend.xyaxis", action: .viewStats),
            QuickAction(title: "梦境画廊", icon: "photo.on.rectangle", action: .browseGallery),
            QuickAction(title: "搜索", icon: "magnifyingglass", action: .searchDreams),
            QuickAction(title: "清醒梦", icon: "brain.head.profile", action: .lucidTraining),
            QuickAction(title: "冥想", icon: "figure.mind.and.body", action: .meditation)
        ]
    }
    
    /// 加载默认问候语
    private func loadDefaultGreeting() {
        if messages.isEmpty {
            let greeting = generateGreeting()
            messages.append(ChatMessage(
                content: greeting,
                sender: .assistant,
                type: .text
            ))
        }
    }
    
    // MARK: - Public Methods
    
    /// 发送用户消息并获取回复
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 添加用户消息
        let userMessage = ChatMessage(
            content: text,
            sender: .user,
            type: .text
        )
        messages.append(userMessage)
        
        // 设置为思考状态
        state = .thinking
        
        // 解析意图并生成回复
        let intent = QueryIntent.parse(text)
        let response = await generateResponse(for: intent, query: text)
        
        // 添加助手回复
        messages.append(response)
        
        // 恢复空闲状态
        state = .idle
        
        // 更新建议
        updateSuggestions(for: intent)
    }
    
    /// 处理建议芯片点击
    func handleSuggestion(_ suggestion: SuggestionChip) async {
        await sendMessage(suggestion.query)
    }
    
    /// 处理快速操作
    func handleQuickAction(_ action: QuickAction) {
        // 快速操作由 UI 层处理，这里只做通知
        print("快速操作：\(action.title)")
    }
    
    /// 清除对话历史
    func clearHistory() {
        messages.removeAll()
        loadDefaultGreeting()
    }
    
    // MARK: - Response Generation
    
    /// 生成回复
    private func generateResponse(for intent: QueryIntent, query: String) async -> ChatMessage {
        switch intent {
        case .searchDreams(let keyword):
            return await handleSearch(keyword)
        case .askStats(let period):
            return await handleStatsQuery(period)
        case .askPattern(let topic):
            return await handlePatternQuery(topic)
        case .askRecommendation:
            return handleRecommendation()
        case .askHelp:
            return handleHelp()
        case .recordDream:
            return handleRecordDream()
        case .unknown:
            return await handleGeneralQuery(query)
        }
    }
    
    // MARK: - Intent Handlers
    
    /// 处理搜索查询
    private func handleSearch(_ keyword: String) async -> ChatMessage {
        let dreams = dreamStore.searchDreams(keyword: keyword)
        
        if dreams.isEmpty {
            return ChatMessage(
                content: "没有找到与\"\(keyword)\"相关的梦境。试试其他关键词？",
                sender: .assistant,
                type: .text
            )
        }
        
        let count = dreams.count
        let previewText = dreams.prefix(3).map { $0.title }.joined(separator: "、")
        
        var content = "找到 \(count) 个相关梦境：\n\n"
        content += previewText
        
        if count > 3 {
            content += "\n\n还有 \(count - 3) 个，可以在搜索结果中查看。"
        }
        
        return ChatMessage(
            content: content,
            sender: .assistant,
            type: .dreamCard,
            relatedDreams: dreams.map { $0.id }
        )
    }
    
    /// 处理统计查询
    private func handleStatsQuery(_ period: String) async -> ChatMessage {
        let allDreams = dreamStore.dreams
        let stats = calculateStats(for: period, dreams: allDreams)
        
        var content = "📊 **梦境统计**\n\n"
        
        if let total = stats["total"] {
            content += "• 总梦境数：\(total)\n"
        }
        if let lucidCount = stats["lucidCount"] {
            content += "• 清醒梦：\(lucidCount)\n"
        }
        if let avgClarity = stats["avgClarity"] {
            content += "• 平均清晰度：\(avgClarity)/5\n"
        }
        if let topEmotion = stats["topEmotion"] {
            content += "• 主要情绪：\(topEmotion)\n"
        }
        if let streak = stats["streak"] {
            content += "• 连续记录：\(streak) 天\n"
        }
        
        return ChatMessage(
            content: content,
            sender: .assistant,
            type: .insight
        )
    }
    
    /// 处理模式查询
    private func handlePatternQuery(_ topic: String) async -> ChatMessage {
        let patterns = analyzePatterns()
        
        var content = "🔍 **梦境模式分析**\n\n"
        
        if let topTags = patterns["topTags"] as? [String] {
            content += "🏷️ 常见主题：\(topTags.prefix(5).joined(separator: "、"))\n"
        }
        if let topEmotions = patterns["topEmotions"] as? [String] {
            content += "😊 主要情绪：\(topEmotions.joined(separator: "、"))\n"
        }
        if let timePattern = patterns["timePattern"] as? String {
            content += "🕐 最佳时间：\(timePattern)\n"
        }
        if let frequency = patterns["frequency"] as? String {
            content += "📅 记录频率：\(frequency)\n"
        }
        
        content += "\n这些模式可以帮助你更好地了解自己的梦境习惯。"
        
        return ChatMessage(
            content: content,
            sender: .assistant,
            type: .insight
        )
    }
    
    /// 处理推荐请求
    private func handleRecommendation() -> ChatMessage {
        let recommendations = generateRecommendations()
        
        var content = "💡 **个性化建议**\n\n"
        
        for (index, rec) in recommendations.enumerated() {
            content += "\(index + 1). \(rec)\n"
        }
        
        content += "\n希望这些建议对你有帮助！"
        
        return ChatMessage(
            content: content,
            sender: .assistant,
            type: .text
        )
    }
    
    /// 处理帮助请求
    private func handleHelp() -> ChatMessage {
        let helpText = """
        🌙 **DreamLog AI 助手**
        
        我可以帮你：
        
        📊 **查询统计**
        • "我这周记录了多少个梦？"
        • "我的清醒梦比例是多少？"
        
        🔍 **搜索梦境**
        • "搜索关于飞行的梦"
        • "找找有水的梦境"
        
        📈 **分析模式**
        • "我最近经常梦到什么？"
        • "我的梦境情绪趋势如何？"
        
        💡 **获取建议**
        • "给我一些记录建议"
        • "如何提高梦境清晰度？"
        
        或者直接点击下方建议芯片快速提问！
        """
        
        return ChatMessage(
            content: helpText,
            sender: .assistant,
            type: .text
        )
    }
    
    /// 处理记录梦境请求
    private func handleRecordDream() -> ChatMessage {
        return ChatMessage(
            content: "🎤 准备好记录你的梦境了吗？\n\n点击下方「记录梦境」按钮，或者长按主页的麦克风按钮开始语音输入。",
            sender: .assistant,
            type: .quickAction
        )
    }
    
    /// 处理一般查询
    private func handleGeneralQuery(_ query: String) async -> ChatMessage {
        // 尝试从梦境内容中匹配
        let matchingDreams = dreamStore.dreams.filter {
            $0.content.localizedCaseInsensitiveContains(query) ||
            $0.title.localizedCaseInsensitiveContains(query)
        }
        
        if !matchingDreams.isEmpty {
            let count = matchingDreams.count
            return ChatMessage(
                content: "我找到了 \(count) 个可能相关的梦境。你想看看吗？",
                sender: .assistant,
                type: .dreamCard,
                relatedDreams: matchingDreams.map { $0.id }
            )
        }
        
        // 默认回复
        return ChatMessage(
            content: "我不太确定你的问题。你可以问我关于梦境统计、搜索梦境、或者分析梦境模式。点击下方的建议芯片试试看！",
            sender: .assistant,
            type: .text
        )
    }
    
    // MARK: - Helper Methods
    
    /// 生成问候语
    private func generateGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        var greeting = ""
        
        if hour < 6 {
            greeting = "夜深了 🌙"
        } else if hour < 12 {
            greeting = "早上好 ☀️"
        } else if hour < 18 {
            greeting = "下午好 🌤️"
        } else {
            greeting = "晚上好 🌆"
        }
        
        let dreamCount = dreamStore.dreams.count
        let streak = calculateStreak()
        
        var message = "\(greeting)！我是你的梦境 AI 助手。\n\n"
        
        if dreamCount > 0 {
            message += "你已经记录了 \(dreamCount) 个梦境"
            if streak > 0 {
                message += "，连续记录 \(streak) 天 🔥"
            }
            message += "。\n\n"
        }
        
        message += "我可以帮你搜索梦境、分析模式、查看统计，或者给你一些记录建议。有什么我可以帮你的吗？"
        
        return message
    }
    
    /// 计算统计数据
    private func calculateStats(for period: String, dreams: [Dream]) -> [String: Any] {
        var filteredDreams = dreams
        
        // 根据时间段过滤
        let calendar = Calendar.current
        let now = Date()
        
        if period.contains("周") || period.contains("星期") {
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) {
                filteredDreams = dreams.filter { $0.date >= weekAgo }
            }
        } else if period.contains("月") {
            if let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) {
                filteredDreams = dreams.filter { $0.date >= monthAgo }
            }
        } else if period.contains("年") {
            if let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) {
                filteredDreams = dreams.filter { $0.date >= yearAgo }
            }
        }
        
        var stats: [String: Any] = [:]
        stats["total"] = filteredDreams.count
        stats["lucidCount"] = filteredDreams.filter { $0.isLucid }.count
        
        if !filteredDreams.isEmpty {
            let avgClarity = filteredDreams.map { $0.clarity }.reduce(0, +) / filteredDreams.count
            stats["avgClarity"] = String(format: "%.1f", Double(avgClarity))
            
            // 统计情绪
            let emotionCounts = Dictionary(grouping: filteredDreams.flatMap { $0.emotions }, by: { $0 })
            if let topEmotion = emotionCounts.max(by: { $0.value.count < $1.value.count })?.key {
                stats["topEmotion"] = topEmotion.displayName
            }
        }
        
        stats["streak"] = calculateStreak()
        
        return stats
    }
    
    /// 分析模式
    private func analyzePatterns() -> [String: Any] {
        let dreams = dreamStore.dreams
        
        var patterns: [String: Any] = [:]
        
        // 热门标签
        let tagCounts = Dictionary(grouping: dreams.flatMap { $0.tags }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        patterns["topTags"] = tagCounts.prefix(10).map { $0.key }
        
        // 主要情绪
        let emotionCounts = Dictionary(grouping: dreams.flatMap { $0.emotions }, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        patterns["topEmotions"] = emotionCounts.prefix(3).map { $0.key.displayName }
        
        // 时间模式
        let hourCounts = Dictionary(grouping: dreams, by: { Calendar.current.component(.hour, from: $0.date) })
            .mapValues { $0.count }
        if let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            patterns["timePattern"] = "\(peakHour):00 左右"
        }
        
        // 记录频率
        if let firstDate = dreams.map({ $0.date }).min(),
           let lastDate = dreams.map({ $0.date }).max() {
            let days = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
            let frequency = days > 0 ? String(format: "%.1f 梦/周", Double(dreams.count) / Double(days) * 7) : "新开始"
            patterns["frequency"] = frequency
        }
        
        return patterns
    }
    
    /// 生成个性化建议
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        let dreams = dreamStore.dreams
        
        // 基于记录频率
        if dreams.count < 5 {
            recommendations.append("刚开始记录梦境，建议每天早晨醒来后立即记录，抓住梦境的余温。")
        }
        
        // 基于清醒梦比例
        let lucidRatio = Double(dreams.filter { $0.isLucid }.count) / Double(max(dreams.count, 1))
        if lucidRatio < 0.1 {
            recommendations.append("尝试清醒梦训练，可以提高梦境意识和控制力。")
        }
        
        // 基于清晰度
        let avgClarity = dreams.map { $0.clarity }.reduce(0, +) / max(dreams.count, 1)
        if avgClarity < 3 {
            recommendations.append("记录时尽量回忆更多细节，可以提高梦境清晰度评分。")
        }
        
        // 基于情绪
        let negativeEmotions = dreams.flatMap { $0.emotions }.filter { [.fearful, .anxious, .sad, .angry].contains($0) }.count
        if Double(negativeEmotions) / Double(max(dreams.flatMap { $0.emotions }.count, 1)) > 0.5 {
            recommendations.append("注意到较多负面情绪，睡前冥想可能有助于改善梦境质量。")
        }
        
        // 默认建议
        if recommendations.isEmpty {
            recommendations.append("继续保持记录！尝试在梦境画廊中查看 AI 生成的梦境图像。")
            recommendations.append("可以试试梦境音乐功能，为你的梦境配上专属背景音乐。")
        }
        
        return recommendations
    }
    
    /// 计算连续记录天数
    private func calculateStreak() -> Int {
        let dreams = dreamStore.dreams.sorted { $0.date > $1.date }
        guard !dreams.isEmpty else { return 0 }
        
        var streak = 1
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: dreams[0].date)
        
        for i in 1..<dreams.count {
            let dreamDate = calendar.startOfDay(for: dreams[i].date)
            let daysDiff = calendar.dateComponents([.day], from: dreamDate, to: currentDate).day ?? 0
            
            if daysDiff == 1 {
                streak += 1
                currentDate = dreamDate
            } else if daysDiff > 1 {
                break
            }
        }
        
        return streak
    }
    
    /// 更新建议
    private func updateSuggestions(for intent: QueryIntent) {
        // 根据上下文动态调整建议
        switch intent {
        case .searchDreams:
            suggestions = [
                SuggestionChip(title: "查看统计", query: "我的梦境统计", icon: "chart.bar"),
                SuggestionChip(title: "分析模式", query: "我的梦境模式", icon: "tag"),
                SuggestionChip(title: "获取建议", query: "给我一些建议", icon: "lightbulb")
            ]
        case .askStats:
            suggestions = [
                SuggestionChip(title: "搜索梦境", query: "搜索梦境", icon: "magnifyingglass"),
                SuggestionChip(title: "查看画廊", query: "浏览梦境画廊", icon: "photo"),
                SuggestionChip(title: "清醒梦训练", query: "清醒梦技巧", icon: "sparkles")
            ]
        default:
            setupSuggestions()
        }
    }
    
    // MARK: - Voice Conversation
    
    /// 启用语音模式
    func enableVoiceMode(_ enabled: Bool) {
        voiceModeEnabled = enabled
        if enabled {
            loadDefaultGreeting()
            speakMessage("你好，我是你的梦境助手。有什么可以帮你的吗？")
        }
    }
    
    /// 朗读消息 (TTS)
    func speakMessage(_ text: String) {
        guard voiceModeEnabled else { return }
        
        // 清理文本 (移除 markdown 格式)
        let cleanText = text
            .replacingOccurrences(of: #"\*\*"#, with: "")
            .replacingOccurrences(of: #"•"#, with: "")
            .replacingOccurrences(of: #"\n"#, with: " ")
        
        speakQueue.append(cleanText)
        processSpeechQueue()
    }
    
    /// 处理语音队列
    private func processSpeechQueue() {
        guard !isProcessingSpeech, !speakQueue.isEmpty else { return }
        
        isProcessingSpeech = true
        let text = speakQueue.removeFirst()
        
        Task { @MainActor in
            isSpeaking = true
            speechService.speak(text)
            
            // 等待播放完成
            try? await Task.sleep(nanoseconds: UInt64(Double(text.count) * 50_000_000))
            
            isSpeaking = false
            isProcessingSpeech = false
            
            // 继续处理队列
            if !speakQueue.isEmpty {
                processSpeechQueue()
            }
        }
    }
    
    /// 停止语音播放
    func stopSpeaking() {
        speechService.stop()
        speakQueue.removeAll()
        isSpeaking = false
        isProcessingSpeech = false
    }
    
    /// 开始语音输入 (STT)
    func startListening() {
        guard !isListening else { return }
        isListening = true
        state = .listening
        // 实际 STT 由 UI 层调用 SpeechService 实现
    }
    
    /// 停止语音输入
    func stopListening() {
        isListening = false
        if state == .listening {
            state = .idle
        }
    }
    
    /// 处理语音识别结果
    func handleSpeechResult(_ text: String) async {
        stopListening()
        await sendMessage(text)
    }
    
    // MARK: - Dream Prediction
    
    /// 生成梦境预测洞察
    func generatePredictionInsights() {
        let dreams = dreamStore.dreams
        guard dreams.count >= 5 else {
            predictionInsights = []
            return
        }
        
        var insights: [DreamPrediction] = []
        
        // 情绪趋势预测
        if let emotionTrend = analyzeEmotionTrend() {
            insights.append(DreamPrediction(
                type: .emotionTrend,
                title: "情绪趋势",
                content: emotionTrend.description,
                confidence: emotionTrend.confidence,
                icon: "heart.fill"
            ))
        }
        
        // 主题趋势预测
        if let themeTrend = analyzeThemeTrend() {
            insights.append(DreamPrediction(
                type: .themeTrend,
                title: "主题趋势",
                content: themeTrend.description,
                confidence: themeTrend.confidence,
                icon: "tag.fill"
            ))
        }
        
        // 清晰度预测
        if let clarityPrediction = predictClarity() {
            insights.append(DreamPrediction(
                type: .clarity,
                title: "清晰度预测",
                content: clarityPrediction.description,
                confidence: clarityPrediction.confidence,
                icon: "eye.fill"
            ))
        }
        
        // 清醒梦预测
        if let lucidPrediction = predictLucidDreams() {
            insights.append(DreamPrediction(
                type: .lucidDream,
                title: "清醒梦机会",
                content: lucidPrediction.description,
                confidence: lucidPrediction.confidence,
                icon: "sparkles"
            ))
        }
        
        predictionInsights = insights
    }
    
    /// 分析情绪趋势
    private func analyzeEmotionTrend() -> DreamPredictionInfo? {
        let dreams = dreamStore.dreams.sorted { $0.date < $1.date }
        guard dreams.count >= 10 else { return nil }
        
        let recentDreams = Array(dreams.suffix(10))
        let olderDreams = Array(dreams.prefix(10))
        
        let recentEmotions = recentDreams.flatMap { $0.emotions }
        let olderEmotions = olderDreams.flatMap { $0.emotions }
        
        // 检测情绪变化
        let positiveEmotions = recentEmotions.filter { [.happy, .calm, .excited].contains($0) }.count
        let oldPositiveCount = olderEmotions.filter { [.happy, .calm, .excited].contains($0) }.count
        
        let trend: String
        let confidence: Double
        
        if positiveEmotions > oldPositiveCount + 2 {
            trend = "你的梦境情绪正在变得更加积极，这通常反映生活状态改善。"
            confidence = 0.75
        } else if positiveEmotions < oldPositiveCount - 2 {
            trend = "注意到梦境中负面情绪增加，可能需要关注压力管理。"
            confidence = 0.70
        } else {
            trend = "梦境情绪保持稳定，这是心理健康的良好迹象。"
            confidence = 0.65
        }
        
        return DreamPredictionInfo(description: trend, confidence: confidence)
    }
    
    /// 分析主题趋势
    private func analyzeThemeTrend() -> DreamPredictionInfo? {
        let dreams = dreamStore.dreams.sorted { $0.date < $1.date }
        guard dreams.count >= 10 else { return nil }
        
        let recentDreams = Array(dreams.suffix(10))
        let olderDreams = Array(dreams.prefix(10))
        
        let recentTags = Set(recentDreams.flatMap { $0.tags })
        let olderTags = Set(olderDreams.flatMap { $0.tags })
        
        let newTags = recentTags.subtracting(olderTags)
        
        if !newTags.isEmpty {
            let trend = "最近出现了新的梦境主题：\(newTags.prefix(3).joined(separator: "、"))，这可能反映新的生活体验。"
            return DreamPredictionInfo(description: trend, confidence: 0.72)
        }
        
        return nil
    }
    
    /// 预测清晰度趋势
    private func predictClarity() -> DreamPredictionInfo? {
        let dreams = dreamStore.dreams.sorted { $0.date < $1.date }
        guard dreams.count >= 7 else { return nil }
        
        let recentClarity = dreams.suffix(7).map { $0.clarity }.reduce(0, +) / 7
        let olderClarity = dreams.prefix(7).map { $0.clarity }.reduce(0, +) / min(7, dreams.count)
        
        let trend: String
        let confidence: Double
        
        if recentClarity > olderClarity + 0.5 {
            trend = "梦境清晰度正在提升，继续保持早晨记录的习惯！"
            confidence = 0.78
        } else if recentClarity < olderClarity - 0.5 {
            trend = "清晰度有所下降，尝试睡前放松练习可能有帮助。"
            confidence = 0.68
        } else {
            trend = "梦境清晰度保持稳定。"
            confidence = 0.60
        }
        
        return DreamPredictionInfo(description: trend, confidence: confidence)
    }
    
    /// 预测清醒梦机会
    private func predictLucidDreams() -> DreamPredictionInfo? {
        let dreams = dreamStore.dreams
        guard dreams.count >= 5 else { return nil }
        
        let lucidCount = dreams.filter { $0.isLucid }.count
        let lucidRatio = Double(lucidCount) / Double(dreams.count)
        
        let trend: String
        let confidence: Double
        
        if lucidRatio > 0.3 {
            trend = "清醒梦频率很高！你有很强的梦境意识，适合尝试进阶技巧。"
            confidence = 0.82
        } else if lucidRatio > 0.1 {
            trend = "清醒梦比例不错，继续练习现实检查可以提高频率。"
            confidence = 0.75
        } else {
            trend = "可以尝试清醒梦训练，从基本的现实检查开始。"
            confidence = 0.70
        }
        
        return DreamPredictionInfo(description: trend, confidence: confidence)
    }
    
    // MARK: - Enhanced Pattern Analysis
    
    /// 深度模式分析
    func performDeepAnalysis() -> DreamAnalysisReport {
        let dreams = dreamStore.dreams
        
        return DreamAnalysisReport(
            totalDreams: dreams.count,
            avgClarity: dreams.map { $0.clarity }.reduce(0, +) / max(dreams.count, 1),
            avgIntensity: dreams.map { $0.intensity }.reduce(0, +) / max(dreams.count, 1),
            lucidRatio: Double(dreams.filter { $0.isLucid }.count) / Double(max(dreams.count, 1)),
            topTags: Dictionary(grouping: dreams.flatMap { $0.tags }, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(5)
                .map { $0.key },
            topEmotions: Dictionary(grouping: dreams.flatMap { $0.emotions }, by: { $0 })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key.displayName },
            bestRecordingTime: findBestRecordingTime(),
            dreamFrequency: calculateDreamFrequency(),
            streakDays: calculateStreak()
        )
    }
    
    /// 找出最佳记录时间
    private func findBestRecordingTime() -> String {
        let dreams = dreamStore.dreams
        let hourCounts = Dictionary(grouping: dreams, by: { Calendar.current.component(.hour, from: $0.date) })
            .mapValues { $0.count }
        
        if let peakHour = hourCounts.max(by: { $0.value < $1.value })?.key {
            return "\(peakHour):00"
        }
        return "早晨"
    }
    
    /// 计算梦境频率
    private func calculateDreamFrequency() -> String {
        let dreams = dreamStore.dreams
        guard let firstDate = dreams.map({ $0.date }).min(),
              let lastDate = dreams.map({ $0.date }).max() else {
            return "新开始"
        }
        
        let days = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
        return String(format: "%.1f 梦/周", Double(dreams.count) / Double(days) * 7)
    }
}

// MARK: - Prediction Models

/// 梦境预测类型
enum DreamPredictionType {
    case emotionTrend
    case themeTrend
    case clarity
    case lucidDream
}

/// 梦境预测信息
struct DreamPrediction {
    let type: DreamPredictionType
    let title: String
    let content: String
    let confidence: Double
    let icon: String
}

/// 预测信息详情
struct DreamPredictionInfo {
    let description: String
    let confidence: Double
}

/// 梦境分析报告
struct DreamAnalysisReport {
    let totalDreams: Int
    let avgClarity: Int
    let avgIntensity: Int
    let lucidRatio: Double
    let topTags: [String]
    let topEmotions: [String]
    let bestRecordingTime: String
    let dreamFrequency: String
    let streakDays: Int
}
