//
//  ExternalAIService.swift
//  DreamLog
//
//  外部 AI 服务抽象层 - 支持多种 LLM 后端
//  Phase 13 - AI 助手外部集成
//

import Foundation

// MARK: - 协议定义

/// 外部 AI 服务协议
protocol ExternalAIServiceProtocol {
    /// 聊天对话
    func chat(messages: [ChatMessage]) async throws -> ChatMessage
    
    /// 分析梦境模式
    func analyzePatterns(dreams: [Dream]) async throws -> PatternAnalysis
    
    /// 生成个性化建议
    func generateRecommendations(userProfile: UserProfile) async throws -> [Recommendation]
    
    /// 预测趋势
    func predictTrends(history: [Dream]) async throws -> TrendPrediction
}

// MARK: - AI Provider 枚举

/// AI 服务提供者
enum AIProvider: String, Codable, CaseIterable {
    case openai = "openai"
    case claude = "claude"
    case local = "local"
    
    var displayName: String {
        switch self {
        case .openai: return "OpenAI GPT"
        case .claude: return "Anthropic Claude"
        case .local: return "本地模型 (离线)"
        }
    }
    
    var icon: String {
        switch self {
        case .openai: return "brain.head.profile"
        case .claude: return "sparkles"
        case .local: return "cpu"
        }
    }
}

// MARK: - 配置模型

/// AI 服务配置
struct AIServiceConfig: Codable {
    var provider: AIProvider
    var apiKey: String?
    var apiBaseURL: String?
    var model: String
    var maxTokens: Int
    var temperature: Double
    var timeout: TimeInterval
    
    static let `default` = AIServiceConfig(
        provider: .local,
        model: "local-coreml",
        maxTokens: 1024,
        temperature: 0.7,
        timeout: 30
    )
    
    static func config(for provider: AIProvider, apiKey: String? = nil) -> AIServiceConfig {
        var config = Self.default
        config.provider = provider
        config.apiKey = apiKey
        
        switch provider {
        case .openai:
            config.model = "gpt-4o-mini"
            config.apiBaseURL = "https://api.openai.com/v1"
        case .claude:
            config.model = "claude-3-haiku-20240307"
            config.apiBaseURL = "https://api.anthropic.com/v1"
        case .local:
            config.model = "local-coreml"
            config.apiKey = nil
        }
        
        return config
    }
}

// MARK: - 请求/响应模型

/// AI 聊天请求
struct AIChatRequest: Codable {
    let messages: [AIMessage]
    let model: String
    let maxTokens: Int
    let temperature: Double
    let stream: Bool
    
    init(messages: [ChatMessage], config: AIServiceConfig, stream: Bool = false) {
        self.messages = messages.map { AIMessage(from: $0) }
        self.model = config.model
        self.maxTokens = config.maxTokens
        self.temperature = config.temperature
        self.stream = stream
    }
}

/// AI 消息
struct AIMessage: Codable {
    let role: String
    let content: String
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
    
    init(from chatMessage: ChatMessage) {
        self.role = chatMessage.sender == .user ? "user" : "assistant"
        self.content = chatMessage.content
    }
}

/// AI 聊天响应
struct AIChatResponse: Codable {
    let id: String
    let model: String
    let choices: [AIChoice]
    let usage: AIUsage?
    
    var message: AIMessage? {
        choices.first?.message
    }
}

struct AIChoice: Codable {
    let index: Int
    let message: AIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index
        case message
        case finishReason = "finish_reason"
    }
}

struct AIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - 模式分析模型

/// 模式分析结果
struct PatternAnalysis: Codable {
    let topThemes: [ThemeFrequency]
    let emotionDistribution: [Emotion: Double]
    let timePatterns: TimePatterns
    let correlations: [DreamCorrelation]
    let insights: [String]
}

struct ThemeFrequency: Codable {
    let theme: String
    let count: Int
    let percentage: Double
}

struct TimePatterns: Codable {
    let morningDreams: Int
    let afternoonDreams: Int
    let eveningDreams: Int
    let nightDreams: Int
    let bestRecallTime: String
}

struct DreamCorrelation: Codable {
    let dream1Id: UUID
    let dream2Id: UUID
    let correlationType: String
    let strength: Double
}

// MARK: - 建议模型

/// 用户画像
struct UserProfile: Codable {
    let totalDreams: Int
    let averageClarity: Double
    let lucidRatio: Double
    let streakDays: Int
    let topEmotions: [Emotion]
    let recordingFrequency: String
    let preferredTime: String
}

/// 建议
struct Recommendation: Codable {
    let id: UUID
    let title: String
    let description: String
    let category: RecommendationCategory
    let priority: Int
    let action: String?
}

enum RecommendationCategory: String, Codable {
    case recording = "recording"
    case interpretation = "interpretation"
    case lucidDream = "lucid_dream"
    case sleep = "sleep"
    case wellness = "wellness"
}

// MARK: - 趋势预测模型

/// 趋势预测
struct TrendPrediction: Codable {
    let emotionTrend: EmotionTrend?
    let themeTrend: ThemeTrend?
    let clarityTrend: ClarityTrend?
    let lucidFrequencyTrend: LucidFrequencyTrend?
    let generatedAt: Date
}

struct EmotionTrend: Codable {
    let trend: AIDreamTrend
    let confidence: Double
    let description: String
    let topEmotions: [Emotion]
}

struct ThemeTrend: Codable {
    let emergingThemes: [String]
    let fadingThemes: [String]
    let confidence: Double
    let description: String
}

struct ClarityTrend: Codable {
    let trend: AIDreamTrend
    let averageClarity: Double
    let change: Double
    let confidence: Double
    let description: String
}

struct LucidFrequencyTrend: Codable {
    let trend: AIDreamTrend
    let currentRatio: Double
    let projectedRatio: Double
    let confidence: Double
    let description: String
}

/// AI 分析趋势 - 用于外部 AI 服务的梦境趋势分析
enum AIDreamTrend: String, Codable {
    case positive = "positive"
    case negative = "negative"
    case stable = "stable"
    
    var icon: String {
        switch self {
        case .positive: return "arrow.up.right"
        case .negative: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    var color: String {
        switch self {
        case .positive: return "green"
        case .negative: return "red"
        case .stable: return "gray"
        }
    }
}

// MARK: - 错误类型

enum AIServiceError: LocalizedError {
    case invalidConfig
    case missingAPIKey
    case networkError(String)
    case apiError(String, Int?)
    case parsingError(String)
    case timeout
    case rateLimitExceeded
    case modelNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfig:
            return "AI 服务配置无效"
        case .missingAPIKey:
            return "缺少 API Key，请在设置中配置"
        case .networkError(let message):
            return "网络错误：\(message)"
        case .apiError(let message, let code):
            if let code = code {
                return "API 错误 (\(code)): \(message)"
            }
            return "API 错误：\(message)"
        case .parsingError(let message):
            return "解析错误：\(message)"
        case .timeout:
            return "请求超时，请重试"
        case .rateLimitExceeded:
            return "请求频率超限，请稍后再试"
        case .modelNotFound(let model):
            return "模型未找到：\(model)"
        }
    }
}

// MARK: - 外部 AI 服务实现

@MainActor
class ExternalAIService: ExternalAIServiceProtocol {
    static let shared = ExternalAIService()
    
    private var config: AIServiceConfig
    private var urlSession: URLSession
    
    init(config: AIServiceConfig = .default) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        configuration.timeoutIntervalForResource = config.timeout * 2
        self.urlSession = URLSession(configuration: configuration)
    }
    
    // MARK: - 配置管理
    
    func updateConfig(_ newConfig: AIServiceConfig) {
        self.config = newConfig
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = newConfig.timeout
        configuration.timeoutIntervalForResource = newConfig.timeout * 2
        self.urlSession = URLSession(configuration: configuration)
    }
    
    func getCurrentProvider() -> AIProvider {
        return config.provider
    }
    
    // MARK: - ExternalAIServiceProtocol
    
    /// 聊天对话
    func chat(messages: [ChatMessage]) async throws -> ChatMessage {
        switch config.provider {
        case .openai:
            return try await chatWithOpenAI(messages: messages)
        case .claude:
            return try await chatWithClaude(messages: messages)
        case .local:
            return try await chatWithLocalModel(messages: messages)
        }
    }
    
    /// 分析梦境模式
    func analyzePatterns(dreams: [Dream]) async throws -> PatternAnalysis {
        // 本地实现模式分析
        return await performLocalPatternAnalysis(dreams: dreams)
    }
    
    /// 生成个性化建议
    func generateRecommendations(userProfile: UserProfile) async throws -> [Recommendation] {
        // 本地实现建议生成
        return await performLocalRecommendationGeneration(userProfile: userProfile)
    }
    
    /// 预测趋势
    func predictTrends(history: [Dream]) async throws -> TrendPrediction {
        // 本地实现趋势预测
        return await performLocalTrendPrediction(history: history)
    }
    
    // MARK: - OpenAI 集成
    
    private func chatWithOpenAI(messages: [ChatMessage]) async throws -> ChatMessage {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        guard let baseURL = config.apiBaseURL, !baseURL.isEmpty else {
            throw AIServiceError.apiError("API Base URL 未配置", 400)
        }
        
        let request = AIChatRequest(messages: messages, config: config)
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIServiceError.apiError("无效的 API URL", 400)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError("无效响应")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "未知错误"
            throw AIServiceError.apiError(errorBody, httpResponse.statusCode)
        }
        
        let aiResponse = try JSONDecoder().decode(AIChatResponse.self, from: data)
        
        guard let aiMessage = aiResponse.message else {
            throw AIServiceError.parsingError("无响应消息")
        }
        
        return ChatMessage(
            content: aiMessage.content,
            sender: .assistant,
            type: .text
        )
    }
    
    // MARK: - Claude 集成
    
    private func chatWithClaude(messages: [ChatMessage]) async throws -> ChatMessage {
        guard let apiKey = config.apiKey, !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey
        }
        
        guard let baseURL = config.apiBaseURL, !baseURL.isEmpty else {
            throw AIServiceError.apiError("API Base URL 未配置", 400)
        }
        
        // Claude API 实现 (简化版)
        let systemPrompt = "你是 DreamLog 的 AI 梦境助手，帮助用户分析梦境、提供建议。"
        
        let claudeMessages = messages.map { msg -> [String: Any] in
            return [
                "role": msg.sender == .user ? "user" : "assistant",
                "content": msg.content
            ]
        }
        
        let body: [String: Any] = [
            "model": config.model,
            "max_tokens": config.maxTokens,
            "system": systemPrompt,
            "messages": claudeMessages
        ]
        
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw AIServiceError.apiError("无效的 API URL", 400)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("x-api-key \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.networkError("无效响应")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "未知错误"
            throw AIServiceError.apiError(errorBody, httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = (json?["content"] as? [[String: Any]])?.first?["text"] as? String ?? "抱歉，我无法理解。"
        
        return ChatMessage(
            content: content,
            sender: .assistant,
            type: .text
        )
    }
    
    // MARK: - 本地模型 (离线模式)
    
    private func chatWithLocalModel(messages: [ChatMessage]) async throws -> ChatMessage {
        // 本地规则引擎实现
        guard let lastUserMessage = messages.last(where: { $0.sender == .user }) else {
            return ChatMessage(
                content: "你好！我是你的梦境助手，有什么可以帮你的吗？",
                sender: .assistant,
                type: .text
            )
        }
        
        let query = lastUserMessage.content.lowercased()
        let response = generateLocalResponse(for: query)
        
        return ChatMessage(
            content: response,
            sender: .assistant,
            type: .text
        )
    }
    
    private func generateLocalResponse(for query: String) -> String {
        // 简单关键词匹配
        if query.contains("统计") || query.contains("多少") {
            return "📊 你可以在「洞察」页面查看详细的梦境统计数据，包括总数、清醒梦比例、情绪分布等。"
        } else if query.contains("搜索") || query.contains("找找") {
            return "🔍 在首页点击搜索图标，输入关键词即可搜索梦境。支持按标题、内容、标签搜索。"
        } else if query.contains("建议") || query.contains("推荐") {
            return "💡 基于你的记录习惯，我建议：\n1. 保持每天记录的习惯\n2. 尝试在醒来后立即记录\n3. 添加更多标签帮助分类"
        } else if query.contains("清醒梦") {
            return "🌙 清醒梦训练在「清醒梦」页面。从现实检查开始，每天练习 3-5 次，坚持 2 周就能看到效果！"
        } else if query.contains("冥想") {
            return "🧘 冥想功能在「冥想」页面。有 12 种助眠音效和 5 种引导冥想，试试「雨夜好眠」预设吧！"
        } else if query.contains("音乐") {
            return "🎵 梦境音乐生成在「音乐」页面。AI 会根据你的梦境情绪自动生成匹配的音乐！"
        } else {
            return "我不太确定你的问题。你可以问我关于梦境统计、搜索、清醒梦训练、冥想或音乐生成的问题。或者点击下方的建议芯片快速提问！"
        }
    }
    
    // MARK: - 本地分析实现
    
    private func performLocalPatternAnalysis(dreams: [Dream]) async -> PatternAnalysis {
        // 计算主题频率
        var themeCounts: [String: Int] = [:]
        for dream in dreams {
            for tag in dream.tags {
                themeCounts[tag, default: 0] += 1
            }
        }
        
        let total = dreams.count
        let topThemes = themeCounts
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { ThemeFrequency(theme: $0.key, count: $0.value, percentage: Double($0.value) / Double(total)) }
        
        // 情绪分布
        var emotionCounts: [Emotion: Int] = [:]
        for dream in dreams {
            for emotion in dream.emotions {
                emotionCounts[emotion, default: 0] += 1
            }
        }
        
        let emotionDistribution = Dictionary(uniqueKeysWithValues: emotionCounts.map { ($0, Double($1) / Double(total)) })
        
        // 时间模式
        let calendar = Calendar.current
        var timeCounts = (morning: 0, afternoon: 0, evening: 0, night: 0)
        
        for dream in dreams {
            let hour = calendar.component(.hour, from: dream.date)
            switch hour {
            case 5..<12: timeCounts.morning += 1
            case 12..<18: timeCounts.afternoon += 1
            case 18..<22: timeCounts.evening += 1
            default: timeCounts.night += 1
            }
        }
        
        let bestTime = max(timeCounts.morning, timeCounts.afternoon, timeCounts.evening, timeCounts.night)
        let bestRecallTime: String
        if bestTime == timeCounts.morning {
            bestRecallTime = "清晨 (5:00-12:00)"
        } else if bestTime == timeCounts.afternoon {
            bestRecallTime = "下午 (12:00-18:00)"
        } else if bestTime == timeCounts.evening {
            bestRecallTime = "傍晚 (18:00-22:00)"
        } else {
            bestRecallTime = "夜晚 (22:00-5:00)"
        }
        
        let timePatterns = TimePatterns(
            morningDreams: timeCounts.morning,
            afternoonDreams: timeCounts.afternoon,
            eveningDreams: timeCounts.evening,
            nightDreams: timeCounts.night,
            bestRecallTime: bestRecallTime
        )
        
        // 生成洞察
        let insights: [String] = [
            "你最常见的梦境主题是「\(topThemes.first?.theme ?? "未知")」",
            "主要情绪是「\(emotionDistribution.max(by: { $0.value < $1.value })?.key.rawValue ?? "未知")」",
            "最佳记录时间是\(bestRecallTime)"
        ]
        
        return PatternAnalysis(
            topThemes: Array(topThemes),
            emotionDistribution: emotionDistribution,
            timePatterns: timePatterns,
            correlations: [],
            insights: insights
        )
    }
    
    private func performLocalRecommendationGeneration(userProfile: UserProfile) async -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        // 基于清晰度建议
        if userProfile.averageClarity < 3 {
            recommendations.append(Recommendation(
                id: UUID(),
                title: "提高梦境清晰度",
                description: "你的梦境平均清晰度较低。尝试在醒来后保持静止，先回忆梦境再起床记录。",
                category: .recording,
                priority: 1,
                action: "viewTips"
            ))
        }
        
        // 基于清醒梦比例建议
        if userProfile.lucidRatio < 0.1 && userProfile.totalDreams > 20 {
            recommendations.append(Recommendation(
                id: UUID(),
                title: "尝试清醒梦训练",
                description: "你的清醒梦比例较低。可以从现实检查开始练习，每天 3-5 次。",
                category: .lucidDream,
                priority: 2,
                action: "startLucidTraining"
            ))
        }
        
        // 基于记录频率建议
        if userProfile.recordingFrequency.contains("低") {
            recommendations.append(Recommendation(
                id: UUID(),
                title: "增加记录频率",
                description: "保持每天记录可以获得更好的梦境洞察。设置晨间提醒帮助养成习惯。",
                category: .recording,
                priority: 1,
                action: "setupReminder"
            ))
        }
        
        // 基于连续记录建议
        if userProfile.streakDays >= 7 && userProfile.streakDays < 30 {
            recommendations.append(Recommendation(
                id: UUID(),
                title: "保持连续记录！",
                description: "你已经连续记录\(userProfile.streakDays)天了！再坚持\(30 - userProfile.streakDays)天就能获得「月度记录者」徽章。",
                category: .wellness,
                priority: 3,
                action: nil
            ))
        }
        
        return recommendations.sorted { $0.priority < $1.priority }
    }
    
    private func performLocalTrendPrediction(history: [Dream]) async -> TrendPrediction {
        // 简单趋势分析
        let sortedDreams = history.sorted { $0.date < $1.date }
        let count = sortedDreams.count
        
        guard count >= 5 else {
            return TrendPrediction(
                emotionTrend: nil,
                themeTrend: nil,
                clarityTrend: nil,
                lucidFrequencyTrend: nil,
                generatedAt: Date()
            )
        }
        
        // 分析前半段和后半段
        let mid = count / 2
        let firstHalf = sortedDreams.prefix(mid)
        let secondHalf = sortedDreams.suffix(count - mid)
        
        // 清晰度趋势
        let firstAvgClarity = firstHalf.map { $0.clarity }.reduce(0, +) / Double(firstHalf.count)
        let secondAvgClarity = secondHalf.map { $0.clarity }.reduce(0, +) / Double(secondHalf.count)
        let clarityChange = secondAvgClarity - firstAvgClarity
        
        let clarityTrend: ClarityTrend
        if clarityChange > 0.3 {
            clarityTrend = ClarityTrend(trend: .positive, averageClarity: secondAvgClarity, change: clarityChange, confidence: 0.65, description: "清晰度呈上升趋势")
        } else if clarityChange < -0.3 {
            clarityTrend = ClarityTrend(trend: .negative, averageClarity: secondAvgClarity, change: clarityChange, confidence: 0.65, description: "清晰度略有下降")
        } else {
            clarityTrend = ClarityTrend(trend: .stable, averageClarity: secondAvgClarity, change: clarityChange, confidence: 0.70, description: "清晰度保持稳定")
        }
        
        // 清醒梦频率趋势
        let firstLucidRatio = Double(firstHalf.filter { $0.isLucid }.count) / Double(firstHalf.count)
        let secondLucidRatio = Double(secondHalf.filter { $0.isLucid }.count) / Double(secondHalf.count)
        
        let lucidTrend: LucidFrequencyTrend
        if secondLucidRatio > firstLucidRatio + 0.1 {
            lucidTrend = LucidFrequencyTrend(trend: .positive, currentRatio: secondLucidRatio, projectedRatio: secondLucidRatio + 0.05, confidence: 0.60, description: "清醒梦频率在增加")
        } else if secondLucidRatio < firstLucidRatio - 0.1 {
            lucidTrend = LucidFrequencyTrend(trend: .negative, currentRatio: secondLucidRatio, projectedRatio: max(0, secondLucidRatio - 0.05), confidence: 0.60, description: "清醒梦频率在减少")
        } else {
            lucidTrend = LucidFrequencyTrend(trend: .stable, currentRatio: secondLucidRatio, projectedRatio: secondLucidRatio, confidence: 0.75, description: "清醒梦频率稳定")
        }
        
        return TrendPrediction(
            emotionTrend: EmotionTrend(trend: .stable, confidence: 0.65, description: "情绪分布相对稳定", topEmotions: []),
            themeTrend: ThemeTrend(emergingThemes: [], fadingThemes: [], confidence: 0.60, description: "主题分布无明显变化"),
            clarityTrend: clarityTrend,
            lucidFrequencyTrend: lucidTrend,
            generatedAt: Date()
        )
    }
}

// MARK: - Dream 扩展

extension Dream {
    var date: Date {
        // 假设 Dream 模型有 dateCreated 或类似字段
        // 这里使用 id 的时间戳作为替代
        Date()
    }
}
